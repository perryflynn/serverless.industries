---
author: christian
title: "dingetun.net Lite: Yay or Nay?"
lang: en
ref: dingetun-yay-nay
tags: ['projects']
toc: true
---

As addition to [dingetun.net][dingetun] I've created yesterday the
mini-project [Yay or Nay?][yaynay]. A single page application
which allows you to ask simple yes/no questions.

This tool helps you to coordinate things through for example WhatsApp.

[dingetun]: https://dingetun.net/
[yaynay]: https://yaynay.dingetun.net/

## Allow Cookies

The tool uses cookies to store the current decision. This makes it
possible to change the decision later or reset it entirely.

Allowing cookies is mandatory.

## How it works

If you open [https://yaynay.dingetun.net/][yaynay], the application redirects
you automatically to a random url which stores your future votes.

But you can also choose any user defined string (`^[A-Za-z0-9\-_]{3,64}$`)
in the url.

## One-Click

To make it for your users easy as possible, you can post two urls.
One for yes, one for no.

- To vote yes: [https://yaynay.dingetun.net/changeme?yay](https://yaynay.dingetun.net/changeme?yay)
- To vote no: [https://yaynay.dingetun.net/changeme?nay](https://yaynay.dingetun.net/changeme?nay)

But the user can no longer see the votes without voting himself.

## Data privacy

The "allow cookies"-Cookiw is stored in your browser for one year and contains no
user data. Just a `1`.

The session cookie is stored 14 days in your browser and contains all votes
of the user.

A Yay/Nay voting page is deleted after 30 days of inactivity.
