use Test::More;
use Mojo::Base -strict;
use SH::Email::ToHash;
use Data::Dumper;
my $x = SH::Email::ToHash->new;
my $txt = <<'END_MESSAGE';
From root  Sun Mar 15 09:32:20 2020
Return-Path: <norwegian@mailgb.custhelp.com>
Received: from nmspam3.e.nsc.no (nmspam3.e.nsc.no [148.123.163.134])
	by nmmx5.nsc.no (8.15.2/8.15.2) with ESMTPS id 02F8WHIu035184
	(version=TLSv1.2 cipher=DHE-RSA-AES256-SHA256 bits=256 verify=NOT)
	for <steihamm@online.no>; Sun, 15 Mar 2020 09:32:20 +0100
Received: from mailgwgb03.rightnowtech.com (mailgwgb03.rightnowtech.com [208.72.90.123])
	by nmspam3.e.nsc.no  with ESMTP id 02F8WDM2015002-02F8WDM4015002
	(version=TLSv1.2 cipher=ECDHE-RSA-AES256-GCM-SHA384 bits=256 verify=NO)
	for <steihamm@online.no>; Sun, 15 Mar 2020 09:32:16 +0100
Received: from access-gb.rightnowtech.com (10.80.0.83) by mailgwgb04.rightnowtech.com id hdnk102lr20g for <steihamm@online.no>; Sun, 15 Mar 2020 08:32:13 +0000 (envelope-from <norwegian@mailgb.custhelp.com>)
Received: from webgb20.int.rightnowtech.com (localhost [127.0.0.1])
	by access-gb.rightnowtech.com ("Mail Server") with SMTP id F1550EA03E
	for <steihamm@online.no>; Sun, 15 Mar 2020 08:32:12 +0000 (GMT)
Content-Type: Multipart/Alternative;
  boundary="------------Boundary-00=_OP78VA40000000000000"
From: "Norwegian Customer Relations"
    <customer.relations@norwegian.com>
Reply-To: "Norwegian Customer Relations"
    <customer.relations@norwegian.com>
To: steihamm@online.no
Date: Sun, 15 Mar 2020 09:32:12 +0100 (CET)
Subject: Cancelled flight claim for booking reference MJGH76 - Flight  DY1817 LPA-OSL 24.02.20 [Incident: 200307-001033]
MIME-Version: 1.0
Message-Id: <RNTT.AvPwaQoeDv8S~dlsGhEe~yL587cq1nj~H3uOXjj~PP9H.1584261132.3CPoG8Q1zC0j@webgb20.int.rightnowtech.com>
Authentication-Results: nmspam3.e.nsc.no;
	spf=pass (nsc.no: domain of norwegian@mailgb.custhelp.com designates 208.72.90.123 as permitted sender) smtp.mailfrom=norwegian@mailgb.custhelp.com
X-XClient-IP-Addr: 208.72.90.123
X-Source-IP: 208.72.90.123
X-Scanned-By: MIMEDefang 2.78
END_MESSAGE

die Dumper $x->parameterify($txt);
is_deeply ($x->parameterify($txt), {});