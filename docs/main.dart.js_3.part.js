((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
bvu(){var w=$.aN,v=(w==null?$.aN=$.cb():w).cp("[DEFAULT]")
B.bj(v,$.cG(),!0)
return A.bvv(new B.bX(v))},
bvv(d){var w,v,u,t,s=d.a,r=s.b.r
if(r==null){w=s.a
if(w==="[DEFAULT]")A.bna("No default storage bucket could be found. Ensure you have correctly followed the Getting Started guide.")
else A.bna("No storage bucket could be found for the app '"+w+"'. Ensure you have set the [storageBucket] on [FirebaseOptions] whilst initializing the secondary Firebase app.")}r.toString
if(C.p.cJ(r,"gs://"))v=C.p.rj(r,"gs://","")
else v=r
s=s.a
u=s+"|"+v
if($.baq.ag(0,u)){s=$.baq.h(0,u)
s.toString
return s}r=$.b8Q()
t=new A.Ce(d,v,s,"plugins.flutter.io/firebase_storage")
$.cx().l(0,t,r)
$.baq.l(0,u,t)
return t},
bna(d){throw B.c(B.tk("no-bucket",d,"firebase_storage"))},
a5Z(d,e){B.bj(e,$.b8V(),!0)
return new A.MZ(e,d)},
bbK(d,e){B.bj(e,$.VK(),!0)
return new A.uN(e,d)},
Ce:function Ce(d,e,f,g){var _=this
_.c=null
_.d=d
_.e=e
_.a=f
_.b=g},
MZ:function MZ(d,e){this.a=d
this.b=e},
a8p:function a8p(){},
aNO:function aNO(d,e,f){this.a=d
this.b=e
this.c=f},
a9b:function a9b(d,e){this.a=d
this.b=e},
uN:function uN(d,e){this.a=d
this.b=e},
awV:function awV(d){this.a=d},
bxl(d){var w=null
return new A.Mw(w,w,w,w,w,w)},
Lz:function Lz(d,e,f,g,h){var _=this
_.e=d
_.f=e
_.r=f
_.a=g
_.b=h},
bih(d,e){var w=B.biS(e),v=$.b8V()
w=new A.a48(w,d)
$.cx().l(0,w,v)
return w},
a48:function a48(d,e){this.a=d
this.b=e},
bxn(d,e,f,g,h){var w,v,u,t
if(B.bg()===C.dm)w=A.bxl(h)
else w=null
v=e.b
v=$.be4().IV(new A.DG(e.gle().a.a,null,v),new A.y8(v,f,"putFile"),g.gf2(0),w,d)
u=$.bed()
t=new A.aDE(v,e)
$.cx().l(0,t,u)
t.ah1(d,e,f,v)
return t},
aDM:function aDM(){},
aDP:function aDP(d,e){this.a=d
this.b=e},
aDN:function aDN(){},
aDO:function aDO(){},
aDQ:function aDQ(d){this.a=d},
aDE:function aDE(d,e){var _=this
_.b=null
_.c=!1
_.d=null
_.e=$
_.f=d
_.w=e
_.x=$},
bxp(d,e,f){var w=$.VK(),v=new A.xR(d,f,e,f)
$.cx().l(0,v,w)
return v},
xR:function xR(d,e,f,g){var _=this
_.c=d
_.d=e
_.a=f
_.b=g},
DG:function DG(d,e,f){this.a=d
this.b=e
this.c=f},
y8:function y8(d,e,f){this.a=d
this.b=e
this.c=f},
a5d:function a5d(d){this.a=d},
a5f:function a5f(d,e){this.a=d
this.b=e},
Mw:function Mw(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
a5g:function a5g(d,e,f){this.a=d
this.b=e
this.c=f},
aVp:function aVp(){},
avP:function avP(){},
aNN:function aNN(){},
ku:function ku(){},
uO:function uO(d,e){this.a=d
this.b=e},
bnt(d,e){if(!x.L.b(d)||!(d instanceof B.ns))B.lR(d,e)
B.lR(B.tk(d.a,d.b,"firebase_storage"),e)},
bGB(d,e,f){var w=B.GU(d,e),v=new B.aw($.aG,f.i("aw<0>"))
v.oN(w)
return v}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[6],A)
D=c[17]
A.Ce.prototype={
IT(d){var w,v=this,u=v.c
if(u==null){u=$.bap
if(u==null){u=$.ao8()
w=new A.Lz(12e4,6e5,6e5,null,"")
$.cx().l(0,w,u)
$.bap=w
u=w}u=v.c=u.a4K(v.d,v.e)}return A.a5Z(v,u.IT(d.length===0?"/":d))},
k(d,e){if(e==null)return!1
return e instanceof A.Ce&&e.d.a.a===this.d.a.a&&e.e===this.e},
gt(d){return B.X(this.d.a.a,this.e,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c)},
j(d){return D.bv_.j(0)+"(app: "+this.d.a.a+", bucket: "+this.e+")"}}
A.MZ.prototype={
kS(){return this.a.kS()},
aLQ(d){var w=this.a.a83(d,null)
B.bj(w,$.bed(),!0)
return new A.a9b(w,this.b)},
k(d,e){if(e==null)return!1
return e instanceof A.MZ&&e.a.a.a===this.a.a.a&&e.b.k(0,this.b)},
gt(d){return B.X(this.b,this.a.a.a,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c)},
j(d){return D.bvi.j(0)+"(app: "+this.b.d.a.a+", fullPath: "+this.a.a.a+")"}}
A.a8p.prototype={
lg(d,e){return this.aCo(d,e)},
lW(d){return this.lg(d,null)},
aCo(d,e){var w=0,v=B.M(x.h),u,t=this,s
var $async$lg=B.H(function(f,g){if(f===1)return B.J(g,v)
while(true)switch(w){case 0:s=t.a
w=3
return B.P(s.gBK(0).lg(d,e),$async$lg)
case 3:s=s.x
s===$&&B.a()
u=A.bbK(t.b,s)
w=1
break
case 1:return B.K(u,v)}})
return B.L($async$lg,v)},
fR(d,e,f){return this.a.gBK(0).fR(new A.aNO(this,d,f),e,f)},
cF(d,e){return this.fR(d,null,e)},
hr(d){var w=0,v=B.M(x.h),u,t=this,s
var $async$hr=B.H(function(e,f){if(e===1)return B.J(f,v)
while(true)switch(w){case 0:s=t.a
w=3
return B.P(s.gBK(0).hr(d),$async$hr)
case 3:s=s.x
s===$&&B.a()
u=A.bbK(t.b,s)
w=1
break
case 1:return B.K(u,v)}})
return B.L($async$hr,v)},
$iak:1}
A.a9b.prototype={}
A.uN.prototype={
k(d,e){var w,v
if(e==null)return!1
if(e instanceof A.uN){w=e.b
v=this.b
w=A.a5Z(w,e.a.gIS()).k(0,A.a5Z(v,this.a.gIS()))&&w.k(0,v)}else w=!1
return w},
gt(d){var w=this.b
return B.X(w,A.a5Z(w,this.a.gIS()),C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c)},
j(d){var w=this.a
return D.bvs.j(0)+"(ref: "+A.a5Z(this.b,w.gIS()).j(0)+", state: "+w.a.j(0)+")"}}
A.awV.prototype={}
A.Lz.prototype={
a4K(d,e){var w,v=d.a.a+"|"+e,u=$.bxk,t=u.h(0,v)
if(t==null){t=$.ao8()
w=new A.Lz(12e4,6e5,6e5,d,e)
$.cx().l(0,w,t)
u.l(0,v,w)
u=w}else u=t
return u},
IT(d){return A.bih(this,d)}}
A.a48.prototype={
gaLu(){var w=this.b
return new A.DG(w.gle().a.a,null,w.b)},
gaLv(){var w=this.a.a
return new A.y8(this.b.b,w,C.l.gaf(w.split("/")))},
kS(){var w=0,v=B.M(x.N),u,t=2,s=[],r=this,q,p,o,n,m
var $async$kS=B.H(function(d,e){if(d===1){s.push(e)
w=t}while(true)switch(w){case 0:t=4
w=7
return B.P($.be4().IU(r.gaLu(),r.gaLv()),$async$kS)
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
o=B.b_(m)
A.bnt(p,o)
w=6
break
case 3:w=2
break
case 6:case 1:return B.K(u,v)
case 2:return B.J(s.at(-1),v)}})
return B.L($async$kS,v)},
a83(d,e){var w=$.bie
$.bie=w+1
return A.bxn(w,this.b,this.a.a,d,e)}}
A.aDM.prototype={
ah1(d,e,f,g){var w=this,v=new A.aDP(w,f).$0()
w.e=B.bkX(v,new A.aDN(),new A.aDO(),B.m(v).i("cK.T"))
w.x=A.bxp(w.w,D.Bl,B.a6(["path",f,"bytesTransferred",0,"totalBytes",1],x.N,x.A))},
gBK(d){var w=0,v=B.M(x.i),u,t=this,s
var $async$gBK=B.H(function(e,f){if(e===1)return B.J(f,v)
while(true)switch(w){case 0:s=t.c
if(s&&t.b==null){s=t.x
s===$&&B.a()
u=B.dy(s,x.i)
w=1
break}else if(s&&t.b!=null){s=t.b
s.toString
u=A.bGB(s,B.z5(),x.i)
w=1
break}else{s=t.e
s===$&&B.a()
s.gaf(0).lW(new A.aDQ(t))
s=t.d
u=(s==null?t.d=new B.bG(new B.aw($.aG,x.v),x.M):s).a
w=1
break}case 1:return B.K(u,v)}})
return B.L($async$gBK,v)}}
A.aDE.prototype={}
A.xR.prototype={
gIS(){return A.bih(this.c,this.d.h(0,"path"))}}
A.DG.prototype={}
A.y8.prototype={}
A.a5d.prototype={}
A.a5f.prototype={}
A.Mw.prototype={}
A.a5g.prototype={}
A.aVp.prototype={
bG(d,e,f){var w=this
if(f instanceof A.a5d){e.bK(0,128)
w.bG(0,e,[f.a])}else if(f instanceof A.a5f){e.bK(0,129)
w.bG(0,e,[f.a,f.b])}else if(f instanceof A.a5g){e.bK(0,130)
w.bG(0,e,[f.a,f.b,f.c])}else if(f instanceof A.Mw){e.bK(0,131)
w.bG(0,e,[f.a,f.b,f.c,f.d,f.e,f.f])}else if(f instanceof A.DG){e.bK(0,132)
w.bG(0,e,[f.a,f.b,f.c])}else if(f instanceof A.y8){e.bK(0,133)
w.bG(0,e,[f.a,f.b,f.c])}else w.yc(0,e,f)},
jF(d,e){var w,v,u,t,s,r,q,p=this
switch(d){case 128:w=p.cr(0,e)
w.toString
w=x.H.a(J.p(x.W.a(w),0))
return new A.a5d(w==null?null:J.j6(w,x.T,x.X))
case 129:w=p.cr(0,e)
w.toString
x.W.a(w)
v=J.a4(w)
u=v.h(w,0)
u.toString
return new A.a5f(B.b6(u),B.ao(v.h(w,1)))
case 130:w=p.cr(0,e)
w.toString
x.W.a(w)
v=J.a4(w)
u=x.z
t=u.a(v.h(w,0))
t.toString
s=x.u
t=J.hz(t,s)
r=B.ao(v.h(w,1))
w=u.a(v.h(w,2))
w.toString
return new A.a5g(t,r,J.hz(w,s))
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
w=v}return new A.Mw(u,t,s,r,q,w)
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
return new A.DG(u,t,B.aY(w))
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
return new A.y8(u,t,B.aY(w))
default:return p.De(d,e)}}}
A.avP.prototype={
IU(d,e){return this.aM9(d,e)},
aM9(d,e){var w=0,v=B.M(x.N),u,t,s,r,q,p
var $async$IU=B.H(function(f,g){if(f===1)return B.J(g,v)
while(true)switch(w){case 0:p=x.z
w=3
return B.P(new B.eN("dev.flutter.pigeon.firebase_storage_platform_interface.FirebaseStorageHostApi.referenceGetDownloadURL",D.Dg,null,x.q).fk(0,[d,e]),$async$IU)
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
break}}case 1:return B.K(u,v)}})
return B.L($async$IU,v)},
IV(d,e,f,g,h){return this.aMa(d,e,f,g,h)},
aMa(d,e,f,g,h){var w=0,v=B.M(x.N),u,t,s,r,q,p
var $async$IV=B.H(function(i,j){if(i===1)return B.J(j,v)
while(true)switch(w){case 0:p=x.z
w=3
return B.P(new B.eN("dev.flutter.pigeon.firebase_storage_platform_interface.FirebaseStorageHostApi.referencePutFile",D.Dg,null,x.q).fk(0,[d,e,f,g,h]),$async$IV)
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
break}}case 1:return B.K(u,v)}})
return B.L($async$IV,v)}}
A.aNN.prototype={}
A.ku.prototype={}
A.uO.prototype={
G(){return"TaskState."+this.b}}
var z=a.updateTypes(["~(jA<ku>)","cK<ku>()","ak<ku>(@)"])
A.aNO.prototype={
$1(d){var w=this.a,v=w.a.x
v===$&&B.a()
return this.b.$1(A.bbK(w.b,v))},
$S(){return this.c.i("0/(ku)")}}
A.aDP.prototype={
$0(){var $async$$0=B.H(function(a9,b0){switch(a9){case 2:r=u
w=r.pop()
break
case 1:s.push(b0)
w=t}while(true)switch(w){case 0:a4=q.a
a7=B
a8="plugins.flutter.io/firebase_storage/taskEvent/"
w=3
return B.kG(a4.f,$async$$0,v)
case 3:a5=new a7.th(a8+b0,C.dl).aM8()
t=5
g=new B.Ag(B.ij(a5,"stream",x.K),x.y)
t=8
f=a4.w,e=x.N,d=x.A
case 11:w=13
return B.kG(g.p(),$async$$0,v)
case 13:if(!b0){w=12
break}p=g.gM(0)
o=D.ba_[J.p(p,"taskState")]
if(o===D.a3m){a4.c=!0
n=B.hJ(J.p(p,"error"),e,d)
m=J.p(n,"code")
a0=m
a1=J.p(n,"message")
l=new B.wK("firebase_storage",a1,a0==null?"unknown":a0)
if(!J.f(m,"canceled")){a0=a4.x
a0===$&&B.a()
a0=a0.b.h(0,"bytesTransferred")
a1=a4.x.b.h(0,"totalBytes")
a2=a4.x.b
a2=a2.h(0,"metadata")==null?null:new A.awV(B.hJ(a2.h(0,"metadata"),e,d))
a2=B.a6(["path",q.b,"bytesTransferred",a0,"totalBytes",a1,"metadata",a2],e,d)
a1=$.VK()
a2=new A.xR(f,a2,o,a2)
a0=$.cx()
a0.a.set(a2,a1)
a4.x=a2}a4.b=l
f=a4.d
if(f!=null){a4=f.a
if((a4.a&30)!==0)B.a1(B.aj("Future already completed"))
a4.oN(B.GU(l,null))}w=12
break}if(o===D.Bn){a4.c=!0
a0=B.hJ(J.p(p,"snapshot"),e,d)
a1=$.VK()
j=new A.xR(f,a0,o,a0)
a0=$.cx()
a0.a.set(j,a1)
k=j
a4.x=k
w=12
break}if(o===D.Bm||o===D.Bl||o===D.a3l){a0=a4.x
a0===$&&B.a()
a0=a0.a!==D.Bn}else a0=!1
w=a0?14:15
break
case 14:a0=B.hJ(J.p(p,"snapshot"),e,d)
a1=$.VK()
a3=new A.xR(f,a0,o,a0)
a0=$.cx()
a0.a.set(a3,a1)
j=a3
a4.x=j
w=16
u=[1,9]
return B.kG(B.bco(j),$async$$0,v)
case 16:case 15:if(o===D.Bm){a4.c=!0
f=a4.d
if(f!=null){e=a4.x
e===$&&B.a()
a4=f.a
if((a4.a&30)!==0)B.a1(B.aj("Future already completed"))
a4.jR(e)}w=12
break}w=11
break
case 12:r.push(10)
w=9
break
case 8:r=[5]
case 9:t=5
w=17
return B.kG(g.bz(0),$async$$0,v)
case 17:w=r.pop()
break
case 10:t=2
w=7
break
case 5:t=4
a6=s.pop()
i=B.ap(a6)
h=B.b_(a6)
A.bnt(i,h)
w=7
break
case 4:w=2
break
case 7:case 1:return B.kG(null,0,v)
case 2:return B.kG(s.at(-1),1,v)}})
var w=0,v=B.bd7($async$$0,x.i),u,t=2,s=[],r=[],q=this,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6,a7,a8
return B.bdc(v)},
$S:z+1}
A.aDN.prototype={
$1(d){return d.pI(0)},
$S:z+0}
A.aDO.prototype={
$1(d){return d.bz(0)},
$S:z+0}
A.aDQ.prototype={
$1(d){var w=this.a.x
w===$&&B.a()
return B.dy(w,x.i)},
$S:z+2};(function inheritance(){var w=a.inherit,v=a.inheritMany
w(A.Ce,B.a_K)
v(B.v,[A.MZ,A.a8p,A.uN,A.awV,A.DG,A.y8,A.a5d,A.a5f,A.Mw,A.a5g,A.avP])
v(B.ja,[A.aNO,A.aDN,A.aDO,A.aDQ])
w(A.a9b,A.a8p)
w(A.Lz,B.a_L)
w(A.a48,B.nu)
v(B.a5s,[A.aNN,A.ku])
w(A.aDM,A.aNN)
w(A.aDP,B.oi)
w(A.aDE,A.aDM)
w(A.xR,A.ku)
w(A.aVp,B.EA)
w(A.uO,B.vf)})()
B.Ai(b.typeUniverse,JSON.parse('{"a8p":{"ak":["uN"]},"a9b":{"ak":["uN"]},"a48":{"nu":[]},"xR":{"ku":[]}}'))
var y={f:"Host platform returned null value for non-null return value.",e:"Unable to establish connection on channel."}
var x=(function rtii(){var w=B.a5
return{q:w("eN<v?>"),L:w("c4"),W:w("y<v?>"),K:w("v"),N:w("d"),h:w("uN"),i:w("ku"),M:w("bG<ku>"),v:w("aw<ku>"),y:w("Ag<@>"),A:w("@"),z:w("y<v?>?"),H:w("af<v?,v?>?"),X:w("v?"),u:w("y8?"),T:w("d?")}})();(function constants(){var w=a.makeConstList
D.Dg=new A.aVp()
D.a3l=new A.uO(0,"paused")
D.Bl=new A.uO(1,"running")
D.Bm=new A.uO(2,"success")
D.Bn=new A.uO(3,"canceled")
D.a3m=new A.uO(4,"error")
D.ba_=w([D.a3l,D.Bl,D.Bm,D.Bn,D.a3m],B.a5("t<uO>"))
D.bv_=B.b2("Ce")
D.bvi=B.b2("MZ")
D.bvs=B.b2("uN")})();(function staticFields(){$.baq=B.r(x.N,B.a5("Ce"))
$.bxk=B.r(x.N,B.a5("Lz"))
$.bie=0})();(function lazyInitializers(){var w=a.lazyFinal
w($,"bMy","be4",()=>new A.avP())
w($,"bNs","bed",()=>new B.v())
w($,"bNt","VK",()=>new B.v())})()};
(a=>{a["kUrFho1QfsAtsnjzIdR14WhQN9w="]=a.current})($__dart_deferred_initializers__);