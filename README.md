# Building a Home Data Centre

**Table of Contents**

   1. [Introduction](#1-introduction)
   2. [Setting up a Proxmox Cluster](https://github.com/authorTom/home-data-centre/blob/main/documentation/setting-up-a-proxmox-cluster.md)
   3. [Optimising Node Power](https://github.com/authorTom/home-data-centre/blob/main/documentation/optimising-node-power.md)
   4. [Resources](https://github.com/authorTom/home-data-centre/blob/main/documentation/resources.md)
## 1.0 Introduction
I’m planning to build a mini self hosted data centre. In my house. Yes, you read that correctly. Not just a fancy computer tucked under the stairs, but a proper (ish) setup with servers and networking gear.

And the first question that probably pops into your head, quite reasonably, is “Why on earth would you do that?“

It’s a fair question. It’s one my partner has asked, usually with a slightly raised eyebrow. And to be honest, it’s one I’ve asked myself a few times, when staring at a bewildering array of eBay server listings at 2 AM.

### The Allure of Doing It Yourself (When You Probably Shouldn’t)
So, why embark on this slightly unhinged quest? Well, it’s a few things, really.

I want to learn. I’ve always had this nagging curiosity about how the internet actually works. Not just the cat videos and angry political discussions, but the underlying nuts and bolts. I’ve tinkered with software, dabbled with coding, but the idea of running my own servers, managing my own little corner of the digital world, has always been there, lurking in the background.

I’ve set myself a bit of a challenge. It’s easy to throw money at a problem. Need more computing power? Spin up another instance on AWS. Need more storage? Click a button, enter your credit card details. And there’s nothing wrong with that – it’s incredibly convenient.

But I’m curious, how much can I achieve on a shoestring budget? How can I squeeze every last drop of performance out of my limited hardware. Can I build something that’s not just functional, but also power-efficient and relatively inexpensive to keep humming along 24/7?

And yes, okay, the thought of those ever-escalating cloud hosting bills does play a part. I know, you often get what you pay for, and the convenience of cloud services is undeniable. But for personal projects, for tinkering, for learning, the idea of having a fixed (and hopefully low) cost, rather than a meter constantly ticking, is quite appealing.

Plus, it sounds like a bit of fun. There’s a certain satisfaction in building something yourself, in understanding it from the ground up.

### Why a “Home Data Centre” and Not Just, You Know, a Server?
You might be thinking, “Okay, fine, you want to run a server. Why the grand ‘home data centre’ label?“

It’s because my ambition (or delusion) stretches a bit further than just one box. I want to learn it all – the hardware (what makes a good server? How does ZFS actually work? What’s ECC RAM and do I need it?), the software (operating systems, virtualisation, containers – it’s a whole new language), and the networking that glues it all together (VLANs, firewalls, VPNs). If I can get a better understanding of how all these pieces fit together, even on a small scale, that feels like a genuinely valuable skill.

### Constraints Breed Innovation
I don’t have deep pockets. I don’t have a dedicated, air-conditioned server room (my spare room will have to do). My thinking is that these limitations might just force me to find more creative, more innovative solutions to the problems I’ll inevitably encounter. It’s a challenge, and I’m (mostly) up for it.

### The Plan
It’s still evolving. But the core idea is to document this journey – the successes, the inevitable failures, the “aha!” moments, and the “why did I think this was a good idea?” moments. I’ll be sharing what I learn about choosing hardware, setting up operating systems, wrangling networks, and trying to get useful services up and running.

**Next...[Setting up a Proxmox Cluster](https://github.com/authorTom/home-data-centre/blob/main/documentation/setting-up-a-proxmox-cluster.md)**