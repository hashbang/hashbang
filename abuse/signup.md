# #! user signup — abuse handling

Since possession of an #! account let users run things, host services, send mail
and so on, signup is an attractive target for all sorts of abuses.

Here, the goal is to only enable sophonts to create accounts, not bots.


## Requirements

1. The abuse-limiting mechanisms must **not** reduce the accessibility of the
   system: any legitimate user able to create an account without them should
   still be able to create an account.

2. Exposure of privacy-relevant information should be as limited as possible.

3. Those mechanisms are implemented by the signup HTTP API:
   the SSH UI is not specially trusted.

4. No data must be recorded before a signup is successful:  doing otherwise
   opens up a DoS vector (and is inefficient) and a potential privacy issue.


## Implementation

The concrete implementation relies on two mechanisms:

- a textual captcha that is systematically sent to the user requesting the
  account creation, and the account creation can only be fulfilled if a valid
  answer is provided;
- hierarchical rate-limiting to limit the rate at which an adversary
  who can defeat the captcha (e.g. by employing humans) can create accounts.


### CAPTCHAs

Using a captcha is a low-overhead (both for the user and for #!) way to tell
apart legitimate users from automated signup.

The captcha is implemented using [TextCaptcha],
a service that provides English-language, text-based CAPTCHAs.
This is a compromise on the first requirement (accessibility), as it is only
accessible to English-speaking users; on the other hand, the entire signup process
is currently only accessible in English, and #!'s documentation and communication
channels are in English.


The addition of a CAPTCHA obviously requires an API change.
The design criteria for it are as follows:

- change as little as possible the current signup API;
- be secure, in the following ways:
  - allow a limited (configurable) time to solve the CAPTCHA;
  - prevent users from reusing CAPTCHA answers;
  - do not expose any information to the user that may facilitate
	automated CAPTCHA solving;
- be independent from [TextCaptcha]: the CAPTCHA-generating system
  must be replaceable without any change to the API.


#### Public API

A `/captcha` endpoint is added, expecting a JSON object with a single
`username` attribute.  The reply contains:

- a `challenge` string, the human-readable question;
- an opaque `token`, serialized as a string;
- an `expiration` time, serialized as an integer timestamp.

When using the `/user/create` endpoint for user creation, the client
must provide (in addition to the current requirements):

- the opaque `token` received from a previous call to `captcha`,
  for the `username` it is requesting;
- a matching `answer` string.

The `/user/create` implementation must perform all other validation
checks (and error-out accordingly) before validating the CAPTCHA.
Doing otherwise would expose an interactive verifier for the CAPTCHA
solution (which might or might not be an exploitable flaw).

If the answer did not match, the CAPTCHA is added to a set of invalid
CAPTCHAs until its expiration time, to prevent an attacker from trying
to brute-force a CAPTCHA.  The set does not need to be persisted to disk
or to a database, keeping it in an in-memory datastructure is enough.

The corresponding API is described as a
[JSON HyperSchema](https://github.com/hashbang/userdb-schemas/blob/refactor/api_schema.yml#L37-L58)


#### Opaque token

The CAPTCHA validation requires three pieces of information:

- the `a` value returned by [TextCaptcha];
- the expiration `timestamp`;
- the `username` requested during CAPTCHA generation.

This data needs to be integrity-protected, since an attacker able to modify
any of its parts would be able to violate the security requirements.

Moreover, it needs to be kept confidential: the `a` attribute is a hash of
the valid, lowercased answers: exposing it to the user reveals a *verifier*
for the valid answers, enabling a malicious user to bruteforce them offline.

As such, the `token` opaque value is generated as follows:

- The required data (`a`, `timestamp` and `username`) is serialized
  using an implementation-defined mechanism.
  [Snappy](https://github.com/golang/snappy)-compressed JSON is suitable.
- The serialized data is encrypted, using an authenticated encryption
  primitive such as AES-GCM, against a constant, symmetric key that is
  randomly generated when the API server starts (and never persisted to
  disk).
- The encrypted data is Base64-encoded, using the
  [RFC 4648 URL-safe alphabet](https://tools.ietf.org/html/rfc4648#section-5).

The use of a random, volatile key for token encryption implies two trade-offs:

- CAPTCHA tokens are implicitely expired when the application is restarted;
  they do expire within a short timeframe anyway, mitigating the issue;
- `api.hashbang.sh` can only be served by a single instance.

Switching to a persistent, shared key can be implemented at any time without
any visible change in the API; however, care must be taken to implement key
rollover procedures and secure key storage.


[TextCaptcha]: http://textcaptcha.com/


### Hierarchical rate-limiting

The intent behind rate-limiting is to prevent one single entity from creating
a disproportionate number of accounts over a given time-span.

There are several challenges inherent with this:

- Special care must be taken not to hinder legitimate users.
  This precludes, for instance, blocking any IP range except for a short period
  of time: dynamic IPs being as they are, the range block would most of the time
  be evaded by the abuser, yet impact unrelated users.
- Such a system must work at several scales:
  - multiple temporal scales are required to deal with both large automated signup
	spikes and slow-but-steady trickles of (automated) account creations;
  - multiple “spacial” scales are required to deal with both a few IPs abusing
	account creation, and an abuser using a larger pool of IPs (like the dynamic IP
	pool from their ISP).


This approach is governed by several tune-able parameters:

- `r [d⁻¹]`, an over-estimate of the legitimate signup rate, in users per day;
- `0 < α < 1`, an adimensional fudge factor for the space scale:
  closer to 0, it makes the rate-limit more forgiving of subnets with an
  above-expectation signup rate;
- a set of timescales that are considered;
- a pair of fudge factors for the temporal scales: `0< β` and `1 < c ≤ 1 + β⁻¹`;
  for simplicity, we set now `c = 1 + β⁻¹`.

Given some IP `host` (assuming for now IPv4), the request is accepted if, for every
timescale `t` and every space scale `s` from /8 to /24, the network `host/s`
performed at most `f(t)×r 2⁻ᵅˢ` successful signups over the last `t` days
with `f(t) = (1 + β×t⁻ᶜ) t`.


#### Rationale

`t×r` is the expected number of signups over the last `t` days, over the world.

The subnet `host/s` contains `2³²⁻ˢ` IPv4 addresses out of `2³²`,
hence the expected ratio of signups originating from it is `2⁻ˢ`.

The “fudge factor” `α` is a tune-able parameter that controls how strict
the dependency regarding network size is: it has less of an impact on large
networks (`s` goes to 0), and more on small networks (which are more likely
to have over-average legitimate behavior).

Lastly, the dependency on time (`t`) is replaced by `f(t)` with the following
properties:

1. `f(t)` is increasing: bigger sliding windows have bigger limits;
2. `f(t)/t` goes towards 1: the rate limit goes towards `r` when the timespan grows large;
3. `f(1) = β+1`: the parameter `β` controls the values of `f` for small timespans.

`f` was rewritten as `f(t) = (1 + g(t)) t`, transforming the constraints into:

1. `f'(t) = 1 + g + g'×t > 0`
2. `g(t)` goes towards 0
3. `g(1) = β`

By picking `g(t) = β×t⁻ᶜ` (which fulfills constraints 2 and 3), the first constraint
becomes `c ≤ 1 + β⁻¹`.


## Privacy concerns

Implementing rate-limiting requires keeping track of signup IPs and timestamps,
which is a compromise on the privacy requirement (2).

This is mitigated by the fact that this data doesn't need to be made available to
any other service than `api.hashbang.sh` (nor does it need to be part of the
replicated database), and `api.hashbang.sh` does not need to know the corresponding
username, nor does it need to have read access to historical data beyond the greatest
timescales considered.


## Security concerns

### CAPTCHAs

Let's assume that an adversary successfuly creates an account under the
following restrictions:

1. the adversary may not break the confidentiality or integrity of the AE;
2. the adversary does not have access to our communication channel with
   [TextCaptcha].

Since the account creation is predicated on receiving an `answer` matching
the verifier encapsulated in `token`, and `token` is integrity-protected,
then `answer` must be a valid answer to a CAPTCHA.

Furthermore, `token` (is integrity-protected and) contains `username` and
`timestamp`, which are validated against: `answer` must thus be an answer
to a CAPTCHA that has not expired yet, and was issued for the specified
`username`.

Since usernames are unique, a given answer can only be used for a single
account creation.

Lastly, the adversary must compute the answer with only access to `challenge`
and an online verifier (the API server).  The verifier refuses to answer to a
given CAPTCHA after one wrong answer, and the adversary may not violate the
confidentiality properties of `token` (which is encrypted).

It follows that the adversary must be able to compute the solution to the
CAPTCHA on the first attempt.


*NOTE:* Assumption 2 might be violated, given that [TextCaptcha]'s API doesn't
        use HTTPS.  This is very sad, but having MitM-resilient CAPTCHAs is
		overkill.


### Rate-limiting

#### Risk of bypassing the rate-limit

In the case of SSH-based signup, the SSH UI server needs to transmit the connecting
client's IP, possibly in a HTTP header. Special care must be taken that only the SSH
UI server is allowed to set the client IP to an arbitrary address, not the
directly-connecting users (if any).

In case of a compromise of the signup server, the attacker can bypass the
rate-limiting (by lying to the API server on the client's IP).  The alternative
(implementing rate-limitations in the signup server) does not solve that issue,
and exposes the privacy-sensitive data mentioned earlier to the attacker.

The compromise of the signup server is mitigated against by the CAPTCHA mechanism,
as an attacker still needs to solve CAPTCHAs to perform registration.


#### Potential DoS

An attacker may attempt to (ab)use the rate-limiting system to prevent users in
“neighboring” networks from using the service.

In order to block a number of size `s`, over a duration `t`, the attacker must:
- solve `t×r 2⁻ᵅˢ` CAPTCHAs;
- send requests from computers in `(t×r 2⁻ᵅˢ)/(t×r 2⁻²⁴ᵅ) = 2⁽²⁴⁻ˢ⁾ᵅ` different
  /24 networks.

For concrete values `t = 7 d`, `s = /16`, `r = 1000 d⁻¹` and `α = 90%`, this
means solving 2300 CAPTCHAs and having access to 147 different /24 networks.
