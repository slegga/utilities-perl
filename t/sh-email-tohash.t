use Test::More;
use Mojo::Base -strict;
use SH::Email::ToHash;
use Data::Dumper;
my $x = SH::Email::ToHash->new;
my $txt = <<'END_MESSAGE';
From root  Sat Feb 29 18:25:00 2020
Return-Path: <delivery_20200229172453.5e5a9e65773f844fc139bcbf@bounce.letsdeal.no>
Received: from nmspam3.e.nsc.no (nmspam3.e.nsc.no [148.123.163.134])
	by nmmx9.nsc.no (8.15.2/8.15.2) with ESMTPS id 01THOvPS064344
	(version=TLSv1.2 cipher=DHE-RSA-AES256-SHA256 bits=256 verify=NOT)
	for <steihamm@online.no>; Sat, 29 Feb 2020 18:25:00 +0100
Received: from nj2mta-116.sailthru.com (nj2mta-116.sailthru.com [204.153.121.116])
	by nmspam3.e.nsc.no  with ESMTP id 01THOrCl018126-01THOrCm018126
	for <steihamm@online.no>; Sat, 29 Feb 2020 18:24:57 +0100
DKIM-Signature: v=1; a=rsa-sha1; c=relaxed; s=sailthru; d=letsdeal.no;
 h=Date:From:To:Message-ID:Subject:MIME-Version:Content-Type:List-Unsubscribe; i=notice@letsdeal.no;
 bh=/fFYP26yDE+A4iYCt5JKxleZIJw=;
 b=uEG87uSrvncKN7ILtnPGGv6kaClqdn+GYrn6mV3vnvrj9A3NYMN0iL32nPmQXL+8loDTKYLdiq4i
   mAppod9jE3rZAJsYvsV5GVwEwET1wdxvl6fBhH8ccQnEZnh5fdG+Iaxh7xXQftwFu7vgJC/HD1fV
   itkRzw4QC8HS8kSwyx4=
Received: from nj1-ownlumber.flt (172.18.20.23) by nj2mta-116.sailthru.com id hbaf6i1qqbst for <steihamm@online.no>; Sat, 29 Feb 2020 12:24:53 -0500 (envelope-from <delivery_20200229172453.5e5a9e65773f844fc139bcbf@bounce.letsdeal.no>)
Date: Sat, 29 Feb 2020 17:24:53 +0000 (UTC)
From: "Let's deal" <notice@letsdeal.no>
To: steihamm@online.no
Message-ID: <20200229172453.5e5a9e65773f844fc139bcbf@sailthru.com>
Subject: Takk for din bestilling (ordre 27166529)
MIME-Version: 1.0
Content-Type: multipart/alternative;
	boundary="----=_Part_1369523_35859008.1582997093656"
X-Virtual-Mta: sharedpool-trans
x-job: 4249-transactional-20200229
X-TM-ID: 20200229172453.5e5a9e65773f844fc139bcbf
X-Sail-Id: 4249.5239044.28700238
X-Info: Message sent by sailthru.com customer Lets Deal AB (letsdeal.no)
X-Info: We do not permit unsolicited commercial email
X-Info: Please report abuse by forwarding complete headers to
X-Info: abuse@sailthru.com
X-Mailer: sailthru.com
X-JMailer: nj1-ownlumber.flt
X-Unsubscribe-Web: https://link.letsdeal.no/oc/51dd6f1d191b2a646debb1dd5e5a9e65773f844fc139bcbf/22f18734
List-Unsubscribe: <https://link.letsdeal.no/oc/51dd6f1d191b2a646debb1dd5e5a9e65773f844fc139bcbf/22f18734>, <mailto:unsubscribe_20200229172453.5e5a9e65773f844fc139bcbf@mx.sailthru.com>
Authentication-Results: nmspam3.e.nsc.no;
	spf=pass (nsc.no: domain of delivery_20200229172453.5e5a9e65773f844fc139bcbf@bounce.letsdeal.no designates 204.153.121.116 as permitted sender) smtp.mailfrom=delivery_20200229172453.5e5a9e65773f844fc139bcbf@bounce.letsdeal.no
X-XClient-IP-Addr: 204.153.121.116
X-Source-IP: 204.153.121.116
X-Scanned-By: MIMEDefang 2.78

bodybody

END_MESSAGE

die Dumper $x->parameterify($txt);
is_deeply ($x->parameterify($txt), {});