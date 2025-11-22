((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={
bCB(){throw B.c(B.aH("_Namespace"))},
bCJ(){throw B.c(B.aH("Platform._operatingSystem"))},
bDT(d,e,f){switch(d[0]){case 1:throw B.c(B.c1(e+": "+f,null))
case 2:throw B.c(A.bvm(new A.a4w(d[2],d[1]),e,f))
case 3:throw B.c(A.bvl("File closed",f,null))
default:throw B.c(B.lD("Unknown error"))}},
bvn(d){var x
$.brb()
B.pS(d,"path")
x=A.bvk(C.cr.cW(d))
return new A.aeB(d,x)},
bvl(d,e,f){return new A.wI(d,e,f)},
bvm(d,e,f){if($.bpH())switch(d.b){case 5:case 16:case 19:case 24:case 32:case 33:case 65:case 108:return new A.Md(e,f,d)
case 80:case 183:return new A.Me(e,f,d)
case 2:case 3:case 15:case 123:case 18:case 53:case 67:case 161:case 206:return new A.Mf(e,f,d)
default:return new A.wI(e,f,d)}else switch(d.b){case 1:case 13:return new A.Md(e,f,d)
case 17:return new A.Me(e,f,d)
case 2:return new A.Mf(e,f,d)
default:return new A.wI(e,f,d)}},
bCl(){return A.bCB()},
bCk(d,e){e[0]=A.bCl()},
bvk(d){var x,w,v=d.length
if(v!==0)x=!C.F.ga4(d)&&C.F.gaf(d)!==0
else x=!0
if(x){w=new Uint8Array(v+1)
C.F.eg(w,0,v,d)
return w}else return d},
bCK(){return A.bCJ()},
a4w:function a4w(d,e){this.a=d
this.b=e},
wI:function wI(d,e,f){this.a=d
this.b=e
this.c=f},
Md:function Md(d,e,f){this.a=d
this.b=e
this.c=f},
Me:function Me(d,e,f){this.a=d
this.b=e
this.c=f},
Mf:function Mf(d,e,f){this.a=d
this.b=e
this.c=f},
aeB:function aeB(d,e){this.a=d
this.b=e},
aVe:function aVe(d){this.a=d},
avi:function avi(){}}
B=c[0]
C=c[2]
A=a.updateHolder(c[8],A)
A.a4w.prototype={
j(d){var x=this.a
if(x.gcP(x))x="OS Error: "+B.o(x)+", errno = "+B.o(this.b.j(0))
else x="OS Error: errno = "+B.o(this.b.j(0))
return x.charCodeAt(0)==0?x:x},
$ic4:1}
A.wI.prototype={
Ft(d){var x,w=this,v=w.a
if(v.length!==0){v=d+(": "+v)+(", path = '"+w.b+"'")
x=w.c
if(x!=null)v+=" ("+x.j(0)+")"}else{v=w.c
if(v!=null)v=d+(": "+v.j(0))+(", path = '"+w.b+"'")
else v=d+(": "+w.b)}return v.charCodeAt(0)==0?v:v},
j(d){return this.Ft("FileSystemException")},
$ic4:1}
A.Md.prototype={
j(d){return this.Ft("PathAccessException")}}
A.Me.prototype={
j(d){return this.Ft("PathExistsException")}}
A.Mf.prototype={
j(d){return this.Ft("PathNotFoundException")}}
A.aeB.prototype={
gf2(d){return this.a},
r3(d){return A.bCk(12,[null,this.b]).cF(new A.aVe(this),y.a)},
j(d){return"File: '"+this.a+"'"}}
A.avi.prototype={}
var z=a.updateTypes(["ak<k>()"])
A.aVe.prototype={
$1(d){A.bDT(d,"Cannot retrieve length of file",this.a.a)
return d},
$S:80};(function installTearOffs(){var x=a._instance_0i
x(A.aeB.prototype,"gn","r3",0)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.v,[A.a4w,A.wI,A.avi])
x(A.wI,[A.Md,A.Me,A.Mf])
w(A.aeB,A.avi)
w(A.aVe,B.ja)})()
B.Ai(b.typeUniverse,JSON.parse('{"a4w":{"c4":[]},"wI":{"c4":[]},"Md":{"c4":[]},"Me":{"c4":[]},"Mf":{"c4":[]}}'))
var y={a:B.a5("k")};(function lazyInitializers(){var x=a.lazyFinal,w=a.lazy
x($,"bPy","brb",()=>new B.v())
x($,"bMP","bpI",()=>A.bCK())
w($,"bMO","bpH",()=>{$.bpI()
return!1})})()};
(a=>{a["fe+MTJQHx5UPpOl/1/aZ6UxxgMM="]=a.current})($__dart_deferred_initializers__);