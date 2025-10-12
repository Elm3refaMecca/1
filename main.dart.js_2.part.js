((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var B,C,A={
bBZ(){throw B.c(B.aG("_Namespace"))},
bC6(){throw B.c(B.aG("Platform._operatingSystem"))},
bDi(d,e,f){switch(d[0]){case 1:throw B.c(B.c0(e+": "+f,null))
case 2:throw B.c(A.buP(new A.a4m(d[2],d[1]),e,f))
case 3:throw B.c(A.buO("File closed",f,null))
default:throw B.c(B.lz("Unknown error"))}},
buQ(d){var x
$.bqG()
B.pQ(d,"path")
x=A.buN(C.ca.cV(d))
return new A.ael(d,x)},
buO(d,e,f){return new A.wG(d,e,f)},
buP(d,e,f){if($.bpb())switch(d.b){case 5:case 16:case 19:case 24:case 32:case 33:case 65:case 108:return new A.M6(e,f,d)
case 80:case 183:return new A.M7(e,f,d)
case 2:case 3:case 15:case 123:case 18:case 53:case 67:case 161:case 206:return new A.M8(e,f,d)
default:return new A.wG(e,f,d)}else switch(d.b){case 1:case 13:return new A.M6(e,f,d)
case 17:return new A.M7(e,f,d)
case 2:return new A.M8(e,f,d)
default:return new A.wG(e,f,d)}},
bBJ(){return A.bBZ()},
bBI(d,e){e[0]=A.bBJ()},
buN(d){var x,w,v=d.length
if(v!==0)x=!C.E.ga4(d)&&C.E.gaf(d)!==0
else x=!0
if(x){w=new Uint8Array(v+1)
C.E.ee(w,0,v,d)
return w}else return d},
bC7(){return A.bC6()},
a4m:function a4m(d,e){this.a=d
this.b=e},
wG:function wG(d,e,f){this.a=d
this.b=e
this.c=f},
M6:function M6(d,e,f){this.a=d
this.b=e
this.c=f},
M7:function M7(d,e,f){this.a=d
this.b=e
this.c=f},
M8:function M8(d,e,f){this.a=d
this.b=e
this.c=f},
ael:function ael(d,e){this.a=d
this.b=e},
aUC:function aUC(d){this.a=d},
auZ:function auZ(){}}
B=c[0]
C=c[2]
A=a.updateHolder(c[8],A)
A.a4m.prototype={
j(d){var x=this.a
if(x.gcP(x))x="OS Error: "+B.o(x)+", errno = "+B.o(this.b.j(0))
else x="OS Error: errno = "+B.o(this.b.j(0))
return x.charCodeAt(0)==0?x:x},
$ic3:1}
A.wG.prototype={
Fm(d){var x,w=this,v=w.a
if(v.length!==0){v=d+(": "+v)+(", path = '"+w.b+"'")
x=w.c
if(x!=null)v+=" ("+x.j(0)+")"}else{v=w.c
if(v!=null)v=d+(": "+v.j(0))+(", path = '"+w.b+"'")
else v=d+(": "+w.b)}return v.charCodeAt(0)==0?v:v},
j(d){return this.Fm("FileSystemException")},
$ic3:1}
A.M6.prototype={
j(d){return this.Fm("PathAccessException")}}
A.M7.prototype={
j(d){return this.Fm("PathExistsException")}}
A.M8.prototype={
j(d){return this.Fm("PathNotFoundException")}}
A.ael.prototype={
gf1(d){return this.a},
r1(d){return A.bBI(12,[null,this.b]).cF(new A.aUC(this),y.a)},
j(d){return"File: '"+this.a+"'"}}
A.auZ.prototype={}
var z=a.updateTypes(["ak<k>()"])
A.aUC.prototype={
$1(d){A.bDi(d,"Cannot retrieve length of file",this.a.a)
return d},
$S:85};(function installTearOffs(){var x=a._instance_0i
x(A.ael.prototype,"gn","r1",0)})();(function inheritance(){var x=a.inheritMany,w=a.inherit
x(B.w,[A.a4m,A.wG,A.auZ])
x(A.wG,[A.M6,A.M7,A.M8])
w(A.ael,A.auZ)
w(A.aUC,B.jb)})()
B.Af(b.typeUniverse,JSON.parse('{"a4m":{"c3":[]},"wG":{"c3":[]},"M6":{"c3":[]},"M7":{"c3":[]},"M8":{"c3":[]}}'))
var y={a:B.a3("k")};(function lazyInitializers(){var x=a.lazyFinal,w=a.lazy
x($,"bOW","bqG",()=>new B.w())
x($,"bMc","bpc",()=>A.bC7())
w($,"bMb","bpb",()=>{$.bpc()
return!1})})()};
(a=>{a["D93AR278mWhJbjoKdmIHDk0y7Wc="]=a.current})($__dart_deferred_initializers__);