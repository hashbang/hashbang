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
   opens up a DoS vector (and is inefficient).


## Implementation

The concrete implementation relies on two mechanisms:
- a textual captcha is systematically sent to the user requesting the account
  creation, and the account creation can only be fulfilled if a valid answer
  is provided;
- hierarchical rate-limiting is employed to limit the rate at which an adversary
  who can defeat the captcha (e.g. by employing humans) can create accounts.


### CAPTCHAs

Using a captcha is a low-overhead (both for the user and for #!) way to tell
apart legitimate users from automated signup.

The captcha is implemented using [TextCaptcha](http://textcaptcha.com/),
a service that provides English-language, text-based CAPTCHAs.
This is a compromise on the first requirement (accessibility), as it is only
accessible to English-speaking users; on the other hand, the entire signup process
is currently only accessible in English, and #!'s documentation and communication
channels are in English.


The addition of a CAPTCHA obviously requires an API change.

XXXTODO: Describe the required API changes.


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
- a so-far unspecified fudge factor for the temporal scales.

Given some IP `host` (assuming for now IPv4), the request is accepted if, for every
timescale `t` and every space scale `s` from /8 to /24, the network `host/s`
performed at most `t×r 2⁻ᵅˢ` successful signups over the last `t` days.

XXXTODO: Figure out the time fudge-factor


#### Rationale

`t×r` is the expected number of signups over the last `t` days, over the world.

The subnet `host/s` contains `2³²⁻ˢ` IPv4 addresses out of `2³²`,
hence the expected ratio of signups originating from it is `2⁻ˢ`.

The “fudge factor” `α` is a tune-able parameter that controls how strict
the dependency regarding size is: it has less of an impact on large networks
(`s` goes to 0), and more on small networks (which are more likely to have
over-average legitimate behavior).


## Privacy concerns

Implementing rate-limiting requires keeping track of signup IPs and timestamps,
which is a compromise on the privacy requirement (2).

This is mitigated by the fact that this data doesn't need to be made available to
any other service than `api.hashbang.sh` (nor does it need to be part of the
replicated database), and `api.hashbang.sh` does not need to know the corresponding
username, nor does it need to have read access to historical data beyond the greatest
timescales considered.


## Security concerns

In the case of SSH-based signup, the SSH UI server needs to transmit the connecting
client's IP, possibly in a HTTP header. Special care must be taken that only the SSH
UI server is allowed to set the client IP to an arbitrary address, not the
directly-connecting users (if any).

In case of a compromise of the signup server, the attacker can bypass the
rate-limiting (by lying to the API server on the client's IP).  The alternative
(implementing rate-limitations in the signup server) does not solve that issue,
and exposes the privacy-sensitive data mentioned earlier to the attacker.

Even under those circumstances, the attacker cannot bypass the CAPTCHA,
as it is checked API-side.
