((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var J,B,C,A={
buX(){var w=$.aM,v=(w==null?$.aM=$.cb():w).cp("[DEFAULT]")
B.bh(v,$.cG(),!0)
return A.buY(new B.bX(v))},
buY(d){var w,v,u,t,s=d.a,r=s.b.r
if(r==null){w=s.a
if(w==="[DEFAULT]")A.bmF("No default storage bucket could be found. Ensure you have correctly followed the Getting Started guide.")
else A.bmF("No storage bucket could be found for the app '"+w+"'. Ensure you have set the [storageBucket] on [FirebaseOptions] whilst initializing the secondary Firebase app.")}r.toString
if(C.p.cJ(r,"gs://"))v=C.p.rh(r,"gs://","")
else v=r
s=s.a
u=s+"|"+v
if($.b9U.ad(0,u)){s=$.b9U.h(0,u)
s.toString
return s}r=$.b8l()
t=new A.Ca(d,v,s,"plugins.flutter.io/firebase_storage")
$.cw().l(0,t,r)
$.b9U.l(0,u,t)
return t},
bmF(d){throw B.c(B.tk("no-bucket",d,"firebase_storage"))},
a5N(d,e){B.bh(e,$.b8q(),!0)
return new A.MR(e,d)},
bbe(d,e){B.bh(e,$.Vz(),!0)
return new A.uO(e,d)},
Ca:function Ca(d,e,f,g){var _=this
_.c=null
_.d=d
_.e=e
_.a=f
_.b=g},
MR:function MR(d,e){this.a=d
this.b=e},
a8b:function a8b(){},
aNd:function aNd(d,e,f){this.a=d
this.b=e
this.c=f},
a8X:function a8X(d,e){this.a=d
this.b=e},
uO:function uO(d,e){this.a=d
this.b=e},
awx:function awx(d){this.a=d},
bwN(d){var w=null
return new A.Mp(w,w,w,w,w,w)},
Lr:function Lr(d,e,f,g,h){var _=this
_.e=d
_.f=e
_.r=f
_.a=g
_.b=h},
bhM(d,e){var w=B.bio(e),v=$.b8q()
w=new A.a3Y(w,d)
$.cw().l(0,w,v)
return w},
a3Y:function a3Y(d,e){this.a=d
this.b=e},
bwP(d,e,f,g,h){var w,v,u,t
if(B.bf()===C.cY)w=A.bwN(h)
else w=null
v=e.b
v=$.bdz().IN(new A.DA(e.glb().a.a,null,v),new A.y5(v,f,"putFile"),g.gf1(0),w,d)
u=$.bdI()
t=new A.aDc(v,e)
$.cw().l(0,t,u)
t.agM(d,e,f,v)
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
bwR(d,e,f){var w=$.Vz(),v=new A.xO(d,f,e,f)
$.cw().l(0,v,w)
return v},
xO:function xO(d,e,f,g){var _=this
_.c=d
_.d=e
_.a=f
_.b=g},
DA:function DA(d,e,f){this.a=d
this.b=e
this.c=f},
y5:function y5(d,e,f){this.a=d
this.b=e
this.c=f},
a52:function a52(d){this.a=d},
a54:function a54(d,e){this.a=d
this.b=e},
Mp:function Mp(d,e,f,g,h,i){var _=this
_.a=d
_.b=e
_.c=f
_.d=g
_.e=h
_.f=i},
a55:function a55(d,e,f){this.a=d
this.b=e
this.c=f},
aUN:function aUN(){},
avv:function avv(){},
aNc:function aNc(){},
kr:function kr(){},
uP:function uP(d,e){this.a=d
this.b=e},
bmY(d,e){if(!x.L.b(d)||!(d instanceof B.nq))B.lO(d,e)
B.lO(B.tk(d.a,d.b,"firebase_storage"),e)},
bG1(d,e,f){var w=B.GN(d,e),v=new B.av($.aF,f.i("av<0>"))
v.oJ(w)
return v}},D
J=c[1]
B=c[0]
C=c[2]
A=a.updateHolder(c[6],A)
D=c[17]
A.Ca.prototype={
IL(d){var w,v=this,u=v.c
if(u==null){u=$.b9T
if(u==null){u=$.anM()
w=new A.Lr(12e4,6e5,6e5,null,"")
$.cw().l(0,w,u)
$.b9T=w
u=w}u=v.c=u.a4w(v.d,v.e)}return A.a5N(v,u.IL(d.length===0?"/":d))},
k(d,e){if(e==null)return!1
return e instanceof A.Ca&&e.d.a.a===this.d.a.a&&e.e===this.e},
gq(d){return B.Y(this.d.a.a,this.e,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c)},
j(d){return D.brF.j(0)+"(app: "+this.d.a.a+", bucket: "+this.e+")"}}
A.MR.prototype={
kN(){return this.a.kN()},
aLe(d){var w=this.a.a7R(d,null)
B.bh(w,$.bdI(),!0)
return new A.a8X(w,this.b)},
k(d,e){if(e==null)return!1
return e instanceof A.MR&&e.a.a.a===this.a.a.a&&e.b.k(0,this.b)},
gq(d){return B.Y(this.b,this.a.a.a,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c)},
j(d){return D.brY.j(0)+"(app: "+this.b.d.a.a+", fullPath: "+this.a.a.a+")"}}
A.a8b.prototype={
ld(d,e){return this.aBS(d,e)},
lU(d){return this.ld(d,null)},
aBS(d,e){var w=0,v=B.K(x.h),u,t=this,s
var $async$ld=B.G(function(f,g){if(f===1)return B.H(g,v)
while(true)switch(w){case 0:s=t.a
w=3
return B.P(s.gBB(0).ld(d,e),$async$ld)
case 3:s=s.x
s===$&&B.a()
u=A.bbe(t.b,s)
w=1
break
case 1:return B.I(u,v)}})
return B.J($async$ld,v)},
fQ(d,e,f){return this.a.gBB(0).fQ(new A.aNd(this,d,f),e,f)},
cF(d,e){return this.fQ(d,null,e)},
hs(d){var w=0,v=B.K(x.h),u,t=this,s
var $async$hs=B.G(function(e,f){if(e===1)return B.H(f,v)
while(true)switch(w){case 0:s=t.a
w=3
return B.P(s.gBB(0).hs(d),$async$hs)
case 3:s=s.x
s===$&&B.a()
u=A.bbe(t.b,s)
w=1
break
case 1:return B.I(u,v)}})
return B.J($async$hs,v)},
$iak:1}
A.a8X.prototype={}
A.uO.prototype={
k(d,e){var w,v
if(e==null)return!1
if(e instanceof A.uO){w=e.b
v=this.b
w=A.a5N(w,e.a.gIK()).k(0,A.a5N(v,this.a.gIK()))&&w.k(0,v)}else w=!1
return w},
gq(d){var w=this.b
return B.Y(w,A.a5N(w,this.a.gIK()),C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c,C.c)},
j(d){var w=this.a
return D.bs6.j(0)+"(ref: "+A.a5N(this.b,w.gIK()).j(0)+", state: "+w.a.j(0)+")"}}
A.awx.prototype={}
A.Lr.prototype={
a4w(d,e){var w,v=d.a.a+"|"+e,u=$.bwM,t=u.h(0,v)
if(t==null){t=$.anM()
w=new A.Lr(12e4,6e5,6e5,d,e)
$.cw().l(0,w,t)
u.l(0,v,w)
u=w}else u=t
return u},
IL(d){return A.bhM(this,d)}}
A.a3Y.prototype={
gaKT(){var w=this.b
return new A.DA(w.glb().a.a,null,w.b)},
gaKU(){var w=this.a.a
return new A.y5(this.b.b,w,C.l.gaf(w.split("/")))},
kN(){var w=0,v=B.K(x.N),u,t=2,s=[],r=this,q,p,o,n,m
var $async$kN=B.G(function(d,e){if(d===1){s.push(e)
w=t}while(true)switch(w){case 0:t=4
w=7
return B.P($.bdz().IM(r.gaKT(),r.gaKU()),$async$kN)
case 7:q=e
u=q
w=1
break
t=2
w=6
break
case 4:t=3
m=s.pop()
p=B.ao(m)
o=B.b1(m)
A.bmY(p,o)
w=6
break
case 3:w=2
break
case 6:case 1:return B.I(u,v)
case 2:return B.H(s.at(-1),v)}})
return B.J($async$kN,v)},
a7R(d,e){var w=$.bhJ
$.bhJ=w+1
return A.bwP(w,this.b,this.a.a,d,e)}}
A.aDk.prototype={
agM(d,e,f,g){var w=this,v=new A.aDn(w,f).$0()
w.e=B.bks(v,new A.aDl(),new A.aDm(),B.n(v).i("cJ.T"))
w.x=A.bwR(w.w,D.vh,B.a4(["path",f,"bytesTransferred",0,"totalBytes",1],x.N,x.A))},
gBB(d){var w=0,v=B.K(x.i),u,t=this,s
var $async$gBB=B.G(function(e,f){if(e===1)return B.H(f,v)
while(true)switch(w){case 0:s=t.c
if(s&&t.b==null){s=t.x
s===$&&B.a()
u=B.dE(s,x.i)
w=1
break}else if(s&&t.b!=null){s=t.b
s.toString
u=A.bG1(s,B.z4(),x.i)
w=1
break}else{s=t.e
s===$&&B.a()
s.gaf(0).lU(new A.aDo(t))
s=t.d
u=(s==null?t.d=new B.bG(new B.av($.aF,x.v),x.M):s).a
w=1
break}case 1:return B.I(u,v)}})
return B.J($async$gBB,v)}}
A.aDc.prototype={}
A.xO.prototype={
gIK(){return A.bhM(this.c,this.d.h(0,"path"))}}
A.DA.prototype={}
A.y5.prototype={}
A.a52.prototype={}
A.a54.prototype={}
A.Mp.prototype={}
A.a55.prototype={}
A.aUN.prototype={
bF(d,e,f){var w=this
if(f instanceof A.a52){e.bJ(0,128)
w.bF(0,e,[f.a])}else if(f instanceof A.a54){e.bJ(0,129)
w.bF(0,e,[f.a,f.b])}else if(f instanceof A.a55){e.bJ(0,130)
w.bF(0,e,[f.a,f.b,f.c])}else if(f instanceof A.Mp){e.bJ(0,131)
w.bF(0,e,[f.a,f.b,f.c,f.d,f.e,f.f])}else if(f instanceof A.DA){e.bJ(0,132)
w.bF(0,e,[f.a,f.b,f.c])}else if(f instanceof A.y5){e.bJ(0,133)
w.bF(0,e,[f.a,f.b,f.c])}else w.y0(0,e,f)},
jx(d,e){var w,v,u,t,s,r,q,p=this
switch(d){case 128:w=p.cr(0,e)
w.toString
w=x.H.a(J.p(x.W.a(w),0))
return new A.a52(w==null?null:J.j6(w,x.T,x.X))
case 129:w=p.cr(0,e)
w.toString
x.W.a(w)
v=J.a2(w)
u=v.h(w,0)
u.toString
return new A.a54(B.b7(u),B.an(v.h(w,1)))
case 130:w=p.cr(0,e)
w.toString
x.W.a(w)
v=J.a2(w)
u=x.z
t=u.a(v.h(w,0))
t.toString
s=x.u
t=J.hA(t,s)
r=B.an(v.h(w,1))
w=u.a(v.h(w,2))
w.toString
return new A.a55(t,r,J.hA(w,s))
case 131:w=p.cr(0,e)
w.toString
x.W.a(w)
v=J.a2(w)
u=B.an(v.h(w,0))
t=B.an(v.h(w,1))
s=B.an(v.h(w,2))
r=B.an(v.h(w,3))
q=B.an(v.h(w,4))
w=x.H.a(v.h(w,5))
if(w==null)w=null
else{v=x.T
v=J.j6(w,v,v)
w=v}return new A.Mp(u,t,s,r,q,w)
case 132:w=p.cr(0,e)
w.toString
x.W.a(w)
v=J.a2(w)
u=v.h(w,0)
u.toString
B.aY(u)
t=B.an(v.h(w,1))
w=v.h(w,2)
w.toString
return new A.DA(u,t,B.aY(w))
case 133:w=p.cr(0,e)
w.toString
x.W.a(w)
v=J.a2(w)
u=v.h(w,0)
u.toString
B.aY(u)
t=v.h(w,1)
t.toString
B.aY(t)
w=v.h(w,2)
w.toString
return new A.y5(u,t,B.aY(w))
default:return p.D9(d,e)}}}
A.avv.prototype={
IM(d,e){return this.aLx(d,e)},
aLx(d,e){var w=0,v=B.K(x.N),u,t,s,r,q,p
var $async$IM=B.G(function(f,g){if(f===1)return B.H(g,v)
while(true)switch(w){case 0:p=x.z
w=3
return B.P(new B.eN("dev.flutter.pigeon.firebase_storage_platform_interface.FirebaseStorageHostApi.referenceGetDownloadURL",D.xe,null,x.q).fg(0,[d,e]),$async$IM)
case 3:q=p.a(g)
if(q==null)throw B.c(B.cT("channel-error",null,y.e,null))
else{t=J.a2(q)
if(t.gn(q)>1){s=t.h(q,0)
s.toString
B.aY(s)
r=B.an(t.h(q,1))
throw B.c(B.cT(s,t.h(q,2),r,null))}else if(t.h(q,0)==null)throw B.c(B.cT("null-error",null,y.f,null))
else{t=B.an(t.h(q,0))
t.toString
u=t
w=1
break}}case 1:return B.I(u,v)}})
return B.J($async$IM,v)},
IN(d,e,f,g,h){return this.aLy(d,e,f,g,h)},
aLy(d,e,f,g,h){var w=0,v=B.K(x.N),u,t,s,r,q,p
var $async$IN=B.G(function(i,j){if(i===1)return B.H(j,v)
while(true)switch(w){case 0:p=x.z
w=3
return B.P(new B.eN("dev.flutter.pigeon.firebase_storage_platform_interface.FirebaseStorageHostApi.referencePutFile",D.xe,null,x.q).fg(0,[d,e,f,g,h]),$async$IN)
case 3:q=p.a(j)
if(q==null)throw B.c(B.cT("channel-error",null,y.e,null))
else{t=J.a2(q)
if(t.gn(q)>1){s=t.h(q,0)
s.toString
B.aY(s)
r=B.an(t.h(q,1))
throw B.c(B.cT(s,t.h(q,2),r,null))}else if(t.h(q,0)==null)throw B.c(B.cT("null-error",null,y.f,null))
else{t=B.an(t.h(q,0))
t.toString
u=t
w=1
break}}case 1:return B.I(u,v)}})
return B.J($async$IN,v)}}
A.aNc.prototype={}
A.kr.prototype={}
A.uP.prototype={
H(){return"TaskState."+this.b}}
var z=a.updateTypes(["~(jB<kr>)","cJ<kr>()","ak<kr>(@)"])
A.aNd.prototype={
$1(d){var w=this.a,v=w.a.x
v===$&&B.a()
return this.b.$1(A.bbe(w.b,v))},
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
case 3:a5=new a7.th(a8+b0,C.cX).aLw()
t=5
g=new B.Ad(B.ij(a5,"stream",x.K),x.y)
t=8
f=a4.w,e=x.N,d=x.A
case 11:w=13
return B.kD(g.p(),$async$$0,v)
case 13:if(!b0){w=12
break}p=g.gM(0)
o=D.b67[J.p(p,"taskState")]
if(o===D.Wq){a4.c=!0
n=B.hK(J.p(p,"error"),e,d)
m=J.p(n,"code")
a0=m
a1=J.p(n,"message")
l=new B.wI("firebase_storage",a1,a0==null?"unknown":a0)
if(!J.f(m,"canceled")){a0=a4.x
a0===$&&B.a()
a0=a0.b.h(0,"bytesTransferred")
a1=a4.x.b.h(0,"totalBytes")
a2=a4.x.b
a2=a2.h(0,"metadata")==null?null:new A.awx(B.hK(a2.h(0,"metadata"),e,d))
a2=B.a4(["path",q.b,"bytesTransferred",a0,"totalBytes",a1,"metadata",a2],e,d)
a1=$.Vz()
a2=new A.xO(f,a2,o,a2)
a0=$.cw()
a0.a.set(a2,a1)
a4.x=a2}a4.b=l
f=a4.d
if(f!=null){a4=f.a
if((a4.a&30)!==0)B.a_(B.ah("Future already completed"))
a4.oJ(B.GN(l,null))}w=12
break}if(o===D.vj){a4.c=!0
a0=B.hK(J.p(p,"snapshot"),e,d)
a1=$.Vz()
j=new A.xO(f,a0,o,a0)
a0=$.cw()
a0.a.set(j,a1)
k=j
a4.x=k
w=12
break}if(o===D.vi||o===D.vh||o===D.Wp){a0=a4.x
a0===$&&B.a()
a0=a0.a!==D.vj}else a0=!1
w=a0?14:15
break
case 14:a0=B.hK(J.p(p,"snapshot"),e,d)
a1=$.Vz()
a3=new A.xO(f,a0,o,a0)
a0=$.cw()
a0.a.set(a3,a1)
j=a3
a4.x=j
w=16
u=[1,9]
return B.kD(B.bbT(j),$async$$0,v)
case 16:case 15:if(o===D.vi){a4.c=!0
f=a4.d
if(f!=null){e=a4.x
e===$&&B.a()
a4=f.a
if((a4.a&30)!==0)B.a_(B.ah("Future already completed"))
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
i=B.ao(a6)
h=B.b1(a6)
A.bmY(i,h)
w=7
break
case 4:w=2
break
case 7:case 1:return B.kD(null,0,v)
case 2:return B.kD(s.at(-1),1,v)}})
var w=0,v=B.bcC($async$$0,x.i),u,t=2,s=[],r=[],q=this,p,o,n,m,l,k,j,i,h,g,f,e,d,a0,a1,a2,a3,a4,a5,a6,a7,a8
return B.bcH(v)},
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
return B.dE(w,x.i)},
$S:z+2};(function inheritance(){var w=a.inherit,v=a.inheritMany
w(A.Ca,B.a_A)
v(B.w,[A.MR,A.a8b,A.uO,A.awx,A.DA,A.y5,A.a52,A.a54,A.Mp,A.a55,A.avv])
v(B.jb,[A.aNd,A.aDl,A.aDm,A.aDo])
w(A.a8X,A.a8b)
w(A.Lr,B.a_B)
w(A.a3Y,B.ns)
v(B.a5h,[A.aNc,A.kr])
w(A.aDk,A.aNc)
w(A.aDn,B.oe)
w(A.aDc,A.aDk)
w(A.xO,A.kr)
w(A.aUN,B.Et)
w(A.uP,B.ve)})()
B.Af(b.typeUniverse,JSON.parse('{"a8b":{"ak":["uO"]},"a8X":{"ak":["uO"]},"a3Y":{"ns":[]},"xO":{"kr":[]}}'))
var y={f:"Host platform returned null value for non-null return value.",e:"Unable to establish connection on channel."}
var x=(function rtii(){var w=B.a3
return{q:w("eN<w?>"),L:w("c3"),W:w("y<w?>"),K:w("w"),N:w("d"),h:w("uO"),i:w("kr"),M:w("bG<kr>"),v:w("av<kr>"),y:w("Ad<@>"),A:w("@"),z:w("y<w?>?"),H:w("ad<w?,w?>?"),X:w("w?"),u:w("y5?"),T:w("d?")}})();(function constants(){var w=a.makeConstList
D.xe=new A.aUN()
D.Wp=new A.uP(0,"paused")
D.vh=new A.uP(1,"running")
D.vi=new A.uP(2,"success")
D.vj=new A.uP(3,"canceled")
D.Wq=new A.uP(4,"error")
D.b67=w([D.Wp,D.vh,D.vi,D.vj,D.Wq],B.a3("r<uP>"))
D.brF=B.b5("Ca")
D.brY=B.b5("MR")
D.bs6=B.b5("uO")})();(function staticFields(){$.b9U=B.t(x.N,B.a3("Ca"))
$.bwM=B.t(x.N,B.a3("Lr"))
$.bhJ=0})();(function lazyInitializers(){var w=a.lazyFinal
w($,"bLW","bdz",()=>new A.avv())
w($,"bMQ","bdI",()=>new B.w())
w($,"bMR","Vz",()=>new B.w())})()};
(a=>{a["AIBHZY36uu0BwUOODOY/noZO8oY="]=a.current})($__dart_deferred_initializers__);