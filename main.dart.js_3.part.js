((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
buW(){var w=$.aN,v=(w==null?$.aN=$.cb():w).cp("[DEFAULT]")
B.bh(v,$.cF(),!0)
return A.buX(new B.bX(v))},
buX(d){var w,v,u,t,s=d.a,r=s.b.r
if(r==null){w=s.a
if(w==="[DEFAULT]")A.bmF("No default storage bucket could be found. Ensure you have correctly followed the Getting Started guide.")
else A.bmF("No storage bucket could be found for the app '"+w+"'. Ensure you have set the [storageBucket] on [FirebaseOptions] whilst initializing the secondary Firebase app.")}r.toString
if(C.p.cJ(r,"gs://"))v=C.p.rh(r,"gs://","")
else v=r
s=s.a
u=s+"|"+v
if($.b9T.ad(0,u)){s=$.b9T.h(0,u)
s.toString
return s}r=$.b8j()
t=new A.Cc(d,v,s,"plugins.flutter.io/firebase_storage")
$.cw().l(0,t,r)
$.b9T.l(0,u,t)
return t},
bmF(d){throw B.c(B.tk("no-bucket",d,"firebase_storage"))},
a5P(d,e){B.bh(e,$.b8o(),!0)
return new A.MS(e,d)},
bbd(d,e){B.bh(e,$.VA(),!0)
return new A.uO(e,d)},
Cc:function Cc(d,e,f,g){var _=this
_.c=null
_.d=d
_.e=e
_.a=f
_.b=g},
MS:function MS(d,e){this.a=d
this.b=e},
a8d:function a8d(){},
aNd:function aNd(d,e,f){this.a=d
this.b=e
this.c=f},
a8Z:function a8Z(d,e){this.a=d
this.b=e},
uO:function uO(d,e){this.a=d
this.b=e},
awx:function awx(d){this.a=d},
bwM(d){var w=null
return new A.Mq(w,w,w,w,w,w)},
Ls:function Ls(d,e,f,g,h){var _=this
_.e=d
_.f=e
_.r=f
_.a=g
_.b=h},
bhL(d,e){var w=B.bin(e),v=$.b8o()
w=new A.a4_(w,d)
$.cw().l(0,w,v)
return w},
a4_:function a4_(d,e){this.a=d
this.b=e},
bwO(d,e,f,g,h){var w,v,u,t
if(B.bf()===C.dn)w=A.bwM(h)
else w=null
v=e.b
v=$.bdy().IM(new A.DC(e.glb().a.a,null,v),new A.y6(v,f,"putFile"),g.gf1(0),w,d)
u=$.bdH()
t=new A.aDc(v,e)
$.cw().l(0,t,u)
t.agL(d,e,f,v)
return t},
aDk:function aDk(){},
aDn:function aDn(d,e){this.a=d
this.b=e},
aDl:function aDl(){},
aDm:function aDm(){},
aDo:function aDo(d){this.a=d},
aDc:function aDc(d,e){var _=this
_.b=null
_.c=!1
_.d=null
_.e=$
_.f=d
_.w=e
_.x=$},
bwQ(d,e,f){var w=$.VA(),v=new A.xP(d,f,e,f)
$.cw().l(0,v,w)
return v},
xP:function xP(d,e,f,g){var _=this
_.c=d
_.d=e
_.a=f
_.b=g},
DC:function DC(d,e,f){this.a=d
this.b=e
this.c=f},
y6:function y6(d,e,f){this.a=d
this.b=e
this.c=f},
a54:function a54(d){this.a=d},
a56:function a56(d,e){this.a=d
this.b=e},
Mq:function Mq(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
a57:function a57(d,e,f){this.a=d
this.b=e
this.c=f},
aUM:function aUM(){},
avv:function avv(){},
aNc:function aNc(){},
kr:function kr(){},
uP:function uP(d,e){this.a=d
this.b=e},
bmY(d,e){if(!x.L.b(d)||!(d instanceof B.nq))B.lO(d,e)
B.lO(B.tk(d.a,d.b,"firebase_storage"),e)},
bFY(d,e,f){var w=B.GO(d,e),v=new B.aw($.aG,f.i("aw<0>"))
v.oJ(w)
return v}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[6],A)
D=c[17]
A.Cc.prototype={
IK(d){var w,v=this,u=v.c
if(u==null){u=$.b9S
if(u==null){u=$.anO()
w=new A.Ls(12e4,6e5,6e5,null,"")
$.cw().l(0,w,u)
$.b9S=w
u=w}u=v.c=u.a4v(v.d,v.e)}return A.a5P(v,u.IK(d.length===0?"/":d))},
k(d,e){if(e==null)return!1
return e instanceof A.Cc&&e.d.a.a===this.d.a.a&&e.e===this.e},
gq(d){return B.Y(this.d.a.a,this.e,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c)},
j(d){return D.buV.j(0)+"(app: "+this.d.a.a+", bucket: "+this.e+")"}}
A.MS.prototype={
kN(){return this.a.kN()},
aLa(d){var w=this.a.a7Q(d,null)
B.bh(w,$.bdH(),!0)
return new A.a8Z(w,this.b)},
k(d,e){if(e==null)return!1
return e instanceof A.MS&&e.a.a.a===this.a.a.a&&e.b.k(0,this.b)},
gq(d){return B.Y(this.b,this.a.a.a,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c)},
j(d){return D.bvd.j(0)+"(app: "+this.b.d.a.a+", fullPath: "+this.a.a.a+")"}}
A.a8d.prototype={
ld(d,e){return this.aBP(d,e)},
lU(d){return this.ld(d,null)},
aBP(d,e){var w=0,v=B.K(x.h),u,t=this,s
var $async$ld=B.G(function(f,g){if(f===1)return B.H(g,v)
while(true)switch(w){case 0:s=t.a
w=3
return B.P(s.gBA(0).ld(d,e),$async$ld)
case 3:s=s.x
s===$&&B.a()
u=A.bbd(t.b,s)
w=1
break
case 1:return B.I(u,v)}})
return B.J($async$ld,v)},
fQ(d,e,f){return this.a.gBA(0).fQ(new A.aNd(this,d,f),e,f)},
cF(d,e){return this.fQ(d,null,e)},
hs(d){var w=0,v=B.K(x.h),u,t=this,s
var $async$hs=B.G(function(e,f){if(e===1)return B.H(f,v)
while(true)switch(w){case 0:s=t.a
w=3
return B.P(s.gBA(0).hs(d),$async$hs)
case 3:s=s.x
s===$&&B.a()
u=A.bbd(t.b,s)
w=1
break
case 1:return B.I(u,v)}})
return B.J($async$hs,v)},
$ial:1}
A.a8Z.prototype={}
A.uO.prototype={
k(d,e){var w,v
if(e==null)return!1
if(e instanceof A.uO){w=e.b
v=this.b
w=A.a5P(w,e.a.gIJ()).k(0,A.a5P(v,this.a.gIJ()))&&w.k(0,v)}else w=!1
return w},
gq(d){var w=this.b
return B.Y(w,A.a5P(w,this.a.gIJ()),C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c)},
j(d){var w=this.a
return D.bvm.j(0)+"(ref: "+A.a5P(this.b,w.gIJ()).j(0)+", state: "+w.a.j(0)+")"}}
A.awx.prototype={}
A.Ls.prototype={
a4v(d,e){var w,v=d.a.a+"|"+e,u=$.bwL,t=u.h(0,v)
if(t==null){t=$.anO()
w=new A.Ls(12e4,6e5,6e5,d,e)
$.cw().l(0,w,t)
u.l(0,v,w)
u=w}else u=t
return u},
IK(d){return A.bhL(this,d)}}
A.a4_.prototype={
gaKP(){var w=this.b
return new A.DC(w.glb().a.a,null,w.b)},
gaKQ(){var w=this.a.a
return new A.y6(this.b.b,w,C.l.gaf(w.split("/")))},
kN(){var w=0,v=B.K(x.N),u,t=2,s=[],r=this,q,p,o,n,m
var $async$kN=B.G(function(d,e){if(d===1){s.push(e)
w=t}while(true)switch(w){case 0:t=4
w=7
return B.P($.bdy().IL(r.gaKP(),r.gaKQ()),$async$kN)
case 7:q=e
u=q
w=1
break
t=2
w=6
break
case 4:t=3
m=s.pop()
p=B.ap(m)
o=B.b1(m)
A.bmY(p,o)
w=6
break
case 3:w=2
break
case 6:case 1:return B.I(u,v)
case 2:return B.H(s.at(-1),v)}})
return B.J($async$kN,v)},
a7Q(d,e){var w=$.bhI
$.bhI=w+1
return A.bwO(w,this.b,this.a.a,d,e)}}
A.aDk.prototype={
agL(d,e,f,g){var w=this,v=new A.aDn(w,f).$0()
w.e=B.bkr(v,new A.aDl(),new A.aDm(),B.n(v).i("cJ.T"))
w.x=A.bwQ(w.w,D.Bj,B.a6(["path",f,"bytesTransferred",0,"totalBytes",1],x.N,x.A))},
gBA(d){var w=0,v=B.K(x.i),u,t=this,s
var $async$gBA=B.G(function(e,f){if(e===1)return B.H(f,v)
while(true)switch(w){case 0:s=t.c
if(s&&t.b==null){s=t.x
s===$&&B.a()
u=B.dx(s,x.i)
w=1
break}else if(s&&t.b!=null){s=t.b
s.toString
u=A.bFY(s,B.z5(),x.i)
w=1
break}else{s=t.e
s===$&&B.a()
s.gaf(0).lU(new A.aDo(t))
s=t.d
u=(s==null?t.d=new B.bG(new B.aw($.aG,x.v),x.M):s).a
w=1
break}case 1:return B.I(u,v)}})
return B.J($async$gBA,v)}}
A.aDc.prototype={}
A.xP.prototype={
gIJ(){return A.bhL(this.c,this.d.h(0,"path"))}}
A.DC.prototype={}
A.y6.prototype={}
A.a54.prototype={}
A.a56.prototype={}
A.Mq.prototype={}
A.a57.prototype={}
A.aUM.prototype={
bF(d,e,f){var w=this
if(f instanceof A.a54){e.bJ(0,128)
w.bF(0,e,[f.a])}else if(f instanceof A.a56){e.bJ(0,129)
w.bF(0,e,[f.a,f.b])}else if(f instanceof A.a57){e.bJ(0,130)
w.bF(0,e,[f.a,f.b,f.c])}else if(f instanceof A.Mq){e.bJ(0,131)
w.bF(0,e,[f.a,f.b,f.c,f.d,f.e,f.f])}else if(f instanceof A.DC){e.bJ(0,132)
w.bF(0,e,[f.a,f.b,f.c])}else if(f instanceof A.y6){e.bJ(0,133)
w.bF(0,e,[f.a,f.b,f.c])}else w.y_(0,e,f)},
jx(d,e){var w,v,u,t,s,r,q,p=this
switch(d){case 128:w=p.cr(0,e)
w.toString
w=x.H.a(J.p(x.W.a(w),0))
return new A.a54(w==null?null:J.j6(w,x.T,x.X))
case 129:w=p.cr(0,e)
w.toString
x.W.a(w)
v=J.a4(w)
u=v.h(w,0)
u.toString
return new A.a56(B.b7(u),B.ao(v.h(w,1)))
case 130:w=p.cr(0,e)
w.toString
x.W.a(w)
v=J.a4(w)
u=x.z
t=u.a(v.h(w,0))
t.toString
s=x.u
t=J.hA(t,s)
r=B.ao(v.h(w,1))
w=u.a(v.h(w,2))
w.toString
return new A.a57(t,r,J.hA(w,s))
case 131:w=p.cr(0,e)
w.toString
x.W.a(w)
v=J.a4(w)
u=B.ao(v.h(w,0))
t=B.ao(v.h(w,1))
s=B.ao(v.h(w,2))
r=B.ao(v.h(w,3))
q=B.ao(v.h(w,4))
w=x.H.a(v.h(w,5))
if(w==null)w=null
else{v=x.T
v=J.j6(w,v,v)
w=v}return new A.Mq(u,t,s,r,q,w)
case 132:w=p.cr(0,e)
w.toString
x.W.a(w)
v=J.a4(w)
u=v.h(w,0)
u.toString
B.aY(u)
t=B.ao(v.h(w,1))
w=v.h(w,2)
w.toString
return new A.DC(u,t,B.aY(w))
case 133:w=p.cr(0,e)
w.toString
x.W.a(w)
v=J.a4(w)
u=v.h(w,0)
u.toString
B.aY(u)
t=v.h(w,1)
t.toString
B.aY(t)
w=v.h(w,2)
w.toString
return new A.y6(u,t,B.aY(w))
default:return p.D8(d,e)}}}
A.avv.prototype={
IL(d,e){return this.aLt(d,e)},
aLt(d,e){var w=0,v=B.K(x.N),u,t,s,r,q,p
var $async$IL=B.G(function(f,g){if(f===1)return B.H(g,v)
while(true)switch(w){case 0:p=x.z
w=3
return B.P(new B.eN("dev.flutter.pigeon.firebase_storage_platform_interface.FirebaseStorageHostApi.referenceGetDownloadURL",D.Dg,null,x.q).fg(0,[d,e]),$async$IL)
case 3:q=p.a(g)
if(q==null)throw B.c(B.cT("channel-error",null,y.e,null))
else{t=J.a4(q)
if(t.gn(q)>1){s=t.h(q,0)
s.toString
B.aY(s)
r=B.ao(t.h(q,1))
throw B.c(B.cT(s,t.h(q,2),r,null))}else if(t.h(q,0)==null)throw B.c(B.cT("null-error",null,y.f,null))
else{t=B.ao(t.h(q,0))
t.toString
u=t
w=1
break}}case 1:return B.I(u,v)}})
return B.J($async$IL,v)},
IM(d,e,f,g,h){return this.aLu(d,e,f,g,h)},
aLu(d,e,f,g,h){var w=0,v=B.K(x.N),u,t,s,r,q,p
var $async$IM=B.G(function(i,j){if(i===1)return B.H(j,v)
while(true)switch(w){case 0:p=x.z
w=3
return B.P(new B.eN("dev.flutter.pigeon.firebase_storage_platform_interface.FirebaseStorageHostApi.referencePutFile",D.Dg,null,x.q).fg(0,[d,e,f,g,h]),$async$IM)
case 3:q=p.a(j)
if(q==null)throw B.c(B.cT("channel-error",null,y.e,null))
else{t=J.a4(q)
if(t.gn(q)>1){s=t.h(q,0)
s.toString
B.aY(s)
r=B.ao(t.h(q,1))
throw B.c(B.cT(s,t.h(q,2),r,null))}else if(t.h(q,0)==null)throw B.c(B.cT("null-error",null,y.f,null))
else{t=B.ao(t.h(q,0))
t.toString
u=t
w=1
break}}case 1:return B.I(u,v)}})
return B.J($async$IM,v)}}
A.aNc.prototype={}
A.kr.prototype={}
A.uP.prototype={
H(){return"TaskState."+this.b}}
var z=a.updateTypes(["~(jB<kr>)","cJ<kr>()","al<kr>(@)"])
A.aNd.prototype={
$1(d){var w=this.a,v=w.a.x
v===$&&B.a()
return this.b.$1(A.bbd(w.b,v))},
$S(){return this.c.i("0/(kr)")}}
A.aDn.prototype={
$0(){var $async$$0=B.G(function(a9,b0){switch(a9){case 2:r=u
w=r.pop()
break
case 1:s.push(b0)
w=t}while(true)switch(w){case 0:a4=q.a
a7=B
a8="plugins.flutter.io/firebase_storage/taskEvent/"
w=3
return B.kD(a4.f,$async$$0,v)
case 3:a5=new a7.th(a8+b0,C.dm).aLs()
t=5
g=new B.Ae(B.ij(a5,"stream",x.K),x.y)
t=8
f=a4.w,e=x.N,d=x.A
case 11:w=13
return B.kD(g.p(),$async$$0,v)
case 13:if(!b0){w=12
break}p=g.gM(0)
o=D.b9Z[J.p(p,"taskState")]
if(o===D.a3q){a4.c=!0
n=B.hK(J.p(p,"error"),e,d)
m=J.p(n,"code")
a0=m
a1=J.p(n,"message")
l=new B.wJ("firebase_storage",a1,a0==null?"unknown":a0)
if(!J.f(m,"canceled")){a0=a4.x
a0===$&&B.a()
a0=a0.b.h(0,"bytesTransferred")
a1=a4.x.b.h(0,"totalBytes")
a2=a4.x.b
a2=a2.h(0,"metadata")==null?null:new A.awx(B.hK(a2.h(0,"metadata"),e,d))
a2=B.a6(["path",q.b,"bytesTransferred",a0,"totalBytes",a1,"metadata",a2],e,d)
a1=$.VA()
a2=new A.xP(f,a2,o,a2)
a0=$.cw()
a0.a.set(a2,a1)
a4.x=a2}a4.b=l
f=a4.d
if(f!=null){a4=f.a
if((a4.a&30)!==0)B.a1(B.aj("Future already completed"))
a4.oJ(B.GO(l,null))}w=12
break}if(o===D.Bl){a4.c=!0
a0=B.hK(J.p(p,"snapshot"),e,d)
a1=$.VA()
j=new A.xP(f,a0,o,a0)
a0=$.cw()
a0.a.set(j,a1)
k=j
a4.x=k
w=12
break}if(o===D.Bk||o===D.Bj||o===D.a3p){a0=a4.x
a0===$&&B.a()
a0=a0.a!==D.Bl}else a0=!1
w=a0?14:15
break
case 14:a0=B.hK(J.p(p,"snapshot"),e,d)
a1=$.VA()
a3=new A.xP(f,a0,o,a0)
a0=$.cw()
a0.a.set(a3,a1)
j=a3
a4.x=j
w=16
u=[1,9]
return B.kD(B.bbS(j),$async$$0,v)
case 16:case 15:if(o===D.Bk){a4.c=!0
f=a4.d
if(f!=null){e=a4.x
e===$&&B.a()
a4=f.a
if((a4.a&30)!==0)B.a1(B.aj("Future already completed"))
a4.jI(e)}w=12
break}w=11
break
case 12:r.push(10)
w=9
break
case 8:r=[5]
case 9:t=5
w=17
return B.kD(g.by(0),$async$$0,v)
case 17:w=r.pop()
break
case 10:t=2
w=7
break
case 5:t=4
a6=s.pop()
i=B.ap(a6)
h=B.b1(a6)
A.bmY(i,h)
w=7
break
case 4:w=2
break
case 7:case 1:return B.kD(null,0,v)
case 2:return B.kD(s.at(-1),1,v)}})
var w=0,v=B.bcB($async$$0,x.i),u,t=2,s=[],r=[],q=this,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6,a7,a8
return B.bcG(v)},
$S:z+1}
A.aDl.prototype={
$1(d){return d.pE(0)},
$S:z+0}
A.aDm.prototype={
$1(d){return d.by(0)},
$S:z+0}
A.aDo.prototype={
$1(d){var w=this.a.x
w===$&&B.a()
return B.dx(w,x.i)},
$S:z+2};(function inheritance(){var w=a.inherit,v=a.inheritMany
w(A.Cc,B.a_B)
v(B.w,[A.MS,A.a8d,A.uO,A.awx,A.DC,A.y6,A.a54,A.a56,A.Mq,A.a57,A.avv])
v(B.jb,[A.aNd,A.aDl,A.aDm,A.aDo])
w(A.a8Z,A.a8d)
w(A.Ls,B.a_C)
w(A.a4_,B.ns)
v(B.a5j,[A.aNc,A.kr])
w(A.aDk,A.aNc)
w(A.aDn,B.of)
w(A.aDc,A.aDk)
w(A.xP,A.kr)
w(A.aUM,B.Ev)
w(A.uP,B.vf)})()
B.Ag(b.typeUniverse,JSON.parse('{"a8d":{"al":["uO"]},"a8Z":{"al":["uO"]},"a4_":{"ns":[]},"xP":{"kr":[]}}'))
var y={f:"Host platform returned null value for non-null return value.",e:"Unable to establish connection on channel."}
var x=(function rtii(){var w=B.a5
return{q:w("eN<w?>"),L:w("c3"),W:w("y<w?>"),K:w("w"),N:w("d"),h:w("uO"),i:w("kr"),M:w("bG<kr>"),v:w("aw<kr>"),y:w("Ae<@>"),A:w("@"),z:w("y<w?>?"),H:w("af<w?,w?>?"),X:w("w?"),u:w("y6?"),T:w("d?")}})();(function constants(){var w=a.makeConstList
D.Dg=new A.aUM()
D.a3p=new A.uP(0,"paused")
D.Bj=new A.uP(1,"running")
D.Bk=new A.uP(2,"success")
D.Bl=new A.uP(3,"canceled")
D.a3q=new A.uP(4,"error")
D.b9Z=w([D.a3p,D.Bj,D.Bk,D.Bl,D.a3q],B.a5("r<uP>"))
D.buV=B.b5("Cc")
D.bvd=B.b5("MS")
D.bvm=B.b5("uO")})();(function staticFields(){$.b9T=B.t(x.N,B.a5("Cc"))
$.bwL=B.t(x.N,B.a5("Ls"))
$.bhI=0})();(function lazyInitializers(){var w=a.lazyFinal
w($,"bLT","bdy",()=>new A.avv())
w($,"bMN","bdH",()=>new B.w())
w($,"bMO","VA",()=>new B.w())})()};
(a=>{a["F3fLcOBi/7bgfzU9ZiqBI6843I4="]=a.current})($__dart_deferred_initializers__);