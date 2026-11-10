# Lito Research 1.8.3 (14): read-only diagnostics

This unofficial extension to Andrea Piani's FreeFCC has a separate app identity
(`com.jdesalas.litoresearch`). Its interface contains Research and Log only.
It cannot request a higher altitude setting. No new software has been installed
on the iPhone and no drone commands were executed during development.

## Purpose and limitations

The user's Lito X1 / RC-N3, aircraft firmware 01.00.0500, still shows 120 m in
DJI Fly. Existing logs did not verify a stored altitude value. Published RC 2
research uses a different transport from the iPhone's MFi connection to RC-N3.
There is no demonstrated altitude unlock for this exact setup here.

This extension supports a manual read of one selected parameter and connection
path. Replies must match sender, destination, sequence, command, parameter hash
and complete value. Bare acknowledgements and stale replies are not readings.
A timeout means unknown; it does not establish rejection or a stored value.
The short parameter name remains a hypothesis. Only a grounded diagnostic is
offered. There are no new parameter-write or service-mode operations.

Startup disables Auto-FCC; the root view exposes no upstream modification tools.
Upstream source remains in the project, but those tools are not reachable from
this variant's interface. The existing installed FCC Unlock app is unchanged.

## Build status

Source structural checks passed. Windows has no Xcode toolchain, so Swift
compilation and native tests have NOT run. No IPA has been built, installed or
hardware-tested. The macOS Actions workflow gates IPA generation on tests.
A free macOS CI build and subsequent SideStore installation remain necessary.
Publishing code to a GitHub account requires the account owner's approval.

## Attribution

Required Notice: Copyright (C) 2026 Andrea Piani (https://www.andreapiani.com)

Upstream code and this personal extension use PolyForm Noncommercial 1.0.0;
see LICENSE and NOTICE.md. This is not an official release or an endorsement.
No Android implementation was copied into the extension.
