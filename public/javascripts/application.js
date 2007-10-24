// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

window.onload = setScreenClass; 
window.onresize = setScreenClass;

//  Following transition classes will be declared:
//
//	classname		  screenwidth
//	------------------------------------------
//	.c240			  240px			
//	.c320			  320px			
//	.c320_640		  320px -  640px	
//	.c640_800		  640px -  800px	
//	.c800_1024		  800px - 1024px	
//	.c1024_1280		 1024px - 1280px	
//	.c1280				> 1280px			

function setScreenClass(){
	var fmt = document.documentElement.clientWidth;
	var cls = (fmt<=240)?'c240':(fmt>240&&fmt<=320)?'c240_320':(fmt>320&&fmt<=640)?'c320_640':(fmt>640&&fmt<=800)?'c640_800':(fmt>800&&fmt<=1024)?'c800_1024':(fmt>1024&&fmt<=1280)?'c1024_1280':'c1280';
	// document.getElementById('count').innerHTML=fmt+'px -> '+cls;
	document.body.className=cls;
};
