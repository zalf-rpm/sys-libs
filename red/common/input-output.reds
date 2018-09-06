Red/System [
	Title:		"Input/Output"
	Author:		"Kaj de Vos"
	Rights:		"Copyright (c) 2013,2015 Kaj de Vos. All rights reserved."
	License: {
		Redistribution and use in source and binary forms, with or without modification,
		are permitted provided that the following conditions are met:

		    * Redistributions of source code must retain the above copyright notice,
		      this list of conditions and the following disclaimer.
		    * Redistributions in binary form must reproduce the above copyright notice,
		      this list of conditions and the following disclaimer in the documentation
		      and/or other materials provided with the distribution.

		THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
		ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
		WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
		DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
		FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
		DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
		SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
		CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
		OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
		OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
	}
	Needs: {
		%C-library/ANSI.reds
		%cURL/cURL.reds
	}
	Tabs:		4
]


;#include %../C-library/ANSI.reds
#include %../cURL/cURL.reds


read: function ["Read and return a text file."
	name			[c-string!]
	length			[pointer! [size!]]  "Size in bytes, excluding null tail marker"
	return:			[c-string!]
][
	case [
		none? name [
			null
		]
		zero? compare-string-part name "file:" 5 [
			read-file name + 5  length
		]
		as-logic find-string name "://" [
			read-url name length
		]
		yes [
			read-file name length
		]
	]
]
read-binary: function ["Read and return a binary file."
	name			[c-string!]
	size			[pointer! [size!]]
	return:			[binary!]
][
	case [
		none? name [
			null
		]
		zero? compare-string-part name "file:" 5 [
			read-file-binary name + 5  size
		]
		as-logic find-string name "://" [
			read-url-binary name size
		]
		yes [
			read-file-binary name size
		]
	]
]

write-string: function ["Write text file."
	name			[c-string!]
	text			[c-string!]
	return:			[logic!]
][
	case [
		none? name [
			no
		]
		zero? compare-string-part name "file:" 5 [
			write-file name + 5  text
		]
		as-logic find-string name "://" [
			write-url name  as-binary text  length? text
		]
		yes [
			write-file name text
		]
	]
]
write-binary-part: function ["Write binary file."
	name			[c-string!]
	data			[binary!]
	size			[size!]
	return:			[logic!]
][
	case [
		none? name [
			no
		]
		zero? compare-string-part name "file:" 5 [
			write-file-binary name + 5  data size
		]
		as-logic find-string name "://" [
			write-url name data size
		]
		yes [
			write-file-binary name data size
		]
	]
]
