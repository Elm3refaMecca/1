((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={
bBN(){throw B.c(B.aH("_Namespace"))},
bBV(){throw B.c(B.aH("Platform._operatingSystem"))},
bD4(d,e,f){switch(d[0]){case 1:throw B.c(B.c0(e+": "+f,null))
case 2:throw B.c(A.buD(new A.a4o(d[2],d[1]),e,f))
case 3:throw B.c(A.buC("File closed",f,null))
default:throw B.c(B.lz("Unknown error"))}},
buE(d){var x
$.bqu()
B.pQ(d,"path")
x=A.buB(C.cr.cV(d))
return new A.aeo(d,x)},
buC(d,e,f){return new A.wH(d,e,f)},
buD(d,e,f){if($.bp_())switch(d.b){case 5:case 16:case 19:case 24:case 32:case 33:case 65:case 108:return new A.M7(e,f,d)
case 80:case 183:return new A.M8(e,f,d)
case 2:case 3:case 15:case 123:case 18:case 53:case 67:case 161:case 206:return new A.M9(e,f,d)
default:return new A.wH(e,f,d)}else switch(d.b){case 1:case 13:return new A.M7(e,f,d)
case 17:return new A.M8(e,f,d)
case 2:return new A.M9(e,f,d)
default:return new A.wH(e,f,d)}},
bBx(){return A.bBN()},
bBw(d,e){e[0]=A.bBx()},
buB(d){var x,w,v=d.length
if(v!==0)x=!C.F.ga4(d)&&C.F.gaf(d)!==0
else x=!0
if(x){w=new Uint8Array(v+1)
C.F.ed(w,0,v,d)
return w}else return d},
bBW(){return A.bBV()},
a4o:function a4o(d,e){this.a=d
this.b=e},
wH:function wH(d,e,f){this.a=d
this.b=e
this.c=f},
M7:function M7(d,e,f){this.a=d
this.b=e
this.c=f},
M8:function M8(d,e,f){this.a=d
this.b=e
this.c=f},
M9:function M9(d,e,f){this.a=d
this.b=e
this.c=f},
aeo:function aeo(d,e){this.a=d
this.b=e},
aUB:function aUB(d){this.a=d},
auZ:function auZ(){}}
B=c[0]
C=c[2]
A=a.updateHolder(c[8],A)
A.a4o.prototype={
j(d){var x=this.a
if(x.gcP(x))x="OS Error: "+B.o(x)+", errno = "+B.o(this.b.j(0))
else x="OS Error: errno = "+B.o(this.b.j(0))
return x.charCodeAt(0)==0?x:x},
$ic3:1}
A.wH.prototype={
Fk(d){var x,w=this,v=w.a
if(v.length!==0){v=d+(": "+v)+(", path = '"+w.b+"'")
x=w.c
if(x!=null)v+=" ("+x.j(0)+")"}else{v=w.c
if(v!=null)v=d+(": "+v.j(0))+(", path = '"+w.b+"'")
else v=d+(": "+w.b)}return v.charCodeAt(0)==0?v:v},
j(d){return this.Fk("FileSystemException")},
$ic3:1}
A.M7.prototype={
j(d){return this.Fk("PathAccessException")}}
A.M8.prototype={
j(d){return this.Fk("PathExistsException")}}
A.M9.prototype={
j(d){return this.Fk("PathNotFoundException")}}
A.aeo.prototype={
gf1(d){return this.a},
r0(d){return A.bBw(12,[null,this.b]).cF(new A.aUB(this),y.a)},
j(d){return"File: '"+this.a+"'"}}
A.auZ.prototype={}
var z=a.updateTypes(["al<k>()"])
A.aUB.prototype={
$1(d){A.bD4(d,"Cannot retrieve length of file",this.a.a)
return d},
$S:83};(function installTearOffs(){var x=a._instance_0i
x(A.aeo.prototype,"gn","r0",0)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.w,[A.a4o,A.wH,A.auZ])
x(A.wH,[A.M7,A.M8,A.M9])
w(A.aeo,A.auZ)
w(A.aUB,B.jb)})()
B.Ag(b.typeUniverse,JSON.parse('{"a4o":{"c3":[]},"wH":{"c3":[]},"M7":{"c3":[]},"M8":{"c3":[]},"M9":{"c3":[]}}'))
var y={a:B.a5("k")};(function lazyInitializers(){var x=a.lazyFinal,w=a.lazy
x($,"bOI","bqu",()=>new B.w())
x($,"bLZ","bp0",()=>A.bBW())
w($,"bLY","bp_",()=>{$.bp0()
return!1})})()};
(a=>{a["sC1vGmtnq3pd8mvuHcYiKVo2l4s="]=a.current})($__dart_deferred_initializers__);