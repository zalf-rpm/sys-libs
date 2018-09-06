Red [
	Title:		"ZeroMQ Binding"
	Author:		"Kaj de Vos"
	Rights:		"Copyright (c) 2011-2016 Kaj de Vos. All rights reserved."
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
		Red >= 0.6
		%ZeroMQ-binding.reds
		%common.red
	}
	Tabs:		4
]


#system-global [#include %ZeroMQ-binding.reds]
#include %../common/common.red


; System interface

; status!
error-again:		11  ; EAGAIN: Linux, Windows; TODO: check for other platforms


; 0MQ interface

; socket-type!
zmq-pair!:			0
publish!:			1
subscribe!:			2
request!:			3
reply!:				4
dealer!:			5
router!:			6
pull!:				7
push!:				8
; For 0MQ >= 4:
stream!:			11

; socket-option!
max-messages:		1
min-messages:		2  ; Not always available
swap-size:			3
io-affinity:		4
identity:			5
filter:				6
unsubscribe:		7
max-rate:			8
recovery-interval:	9
loop-back?:			10
send-buffer:		11
receive-buffer:		12
receive-more?:		13
linger:				17
; For 0MQ >= 2.2
receive-timeout:	27
send-timeout:		28
last-endpoint:		32

; send-receive-flags!
zmq-none:			0
no-block:			1
send-more:			2

; wait-mask!
poll-in:			1
poll-out:			2
poll-error:			4


major-version: routine [								"Return 0MQ major version."
	return:			[integer!]
	/local major minor patch
][
	major: 0  minor: 0  patch: 0
	zmq/version :major :minor :patch
	major
]
minor-version: routine [								"Return 0MQ minor version."
	return:			[integer!]
	/local major minor patch
][
	major: 0  minor: 0  patch: 0
	zmq/version :major :minor :patch
	minor
]
patch-version: routine [								"Return 0MQ patch version."
	return:			[integer!]
	/local major minor patch
][
	major: 0  minor: 0  patch: 0
	zmq/version :major :minor :patch
	patch
]


; Error handling

system-error: routine [									"Return last status."
	return: 		[integer!]							"status!"
][
	zmq/system-error
]
form-error: routine [									"Return status message."
	code			[integer!]							"status!"
;	return:			[string!]
	/local			text
][
	text: zmq/form-error code
	SET_RETURN ((string/load text  length? text  UTF-8))
]


; Pool context management

make-pool: routine [									"Return new context handle."
	io-threads		[integer!]
	return: 		[integer!]							"pool!"
][
	as-integer zmq/make-pool io-threads
]
end-pool: routine [										"Clean up context."
	pool			[integer!]							"pool!"
	return:			[logic!]
][
	with zmq [zmq/end-pool as pool! pool]
]

open-socket: routine [									"Return a new socket."
	pool			[integer!]							"pool!"
	type			[integer!]							"socket-type!"
	return: 		[integer!]							"socket!"
][
	with zmq [as-integer zmq/open-socket as pool! pool  type]
]
close-socket: routine [									"Clean up socket from context."
	socket			[integer!]							"socket!"
	return:			[logic!]
][
	with zmq [zmq/close-socket as socket! socket]
]


; Socket options

set-integer: routine [									"Set integer socket option."
	socket			[integer!]							"socket!"
	name			[integer!]							"socket-option!"
	value			[integer!]
	return:			[logic!]
][
	with zmq [set as socket! socket name :value 4]
]
set-string: routine [									"Set string socket option."
	socket			[integer!]							"socket!"
	name			[integer!]							"socket-option!"
	value			[string!]
	return:			[logic!]
	/local string ok?
][
	string: to-UTF8 value

	either none? string [
		no
	][
		with zmq [ok?: set
			as socket! socket
			name
			as-handle string
			(length? string) + 1
		]
		free-any string
		ok?
	]
]

get-integer: routine [									"Return integer socket option, or NONE."
	socket			[integer!]							"socket!"
	name			[integer!]							"socket-option!, integer values only"
;	return:			[integer! none!]
	/local			value
][
	value: 0

	with zmq [
		either zmq/get-integer as socket! socket  name :value [
			integer/box value
		][
			RETURN_NONE
		]
	]
]
get-logic: routine [									"Return logic! socket option, or NONE."
	socket			[integer!]							"socket!"
	name			[integer!]							"socket-option!, logic! values only"
;	return:			[logic! none!]
	/local			value
][
	value: 0

	with zmq [
		either zmq/get-logic as socket! socket  name :value [
			logic/box as-logic value
		][
			RETURN_NONE
		]
	]
]

get-string: routine [									"Return status message."
	socket			[integer!]							"status!"
	name 			[integer!]
;	return:			[string!]
	/local			text ctext size
][
	text: as handle! allocate 256
	ctext: as c-string! text
	size: 256
	with zmq [
		either zmq/get as socket! socket name text :size [
			SET_RETURN ((string/load ctext length? ctext UTF-8))		
			free-any text
		][
			free-any text
			RETURN_NONE
		]

	]
]

; Connection management

serve*: routine [										"Set up server socket binding."
	socket			[integer!]							"socket!"
	end-point
	return:			[logic!]
	/local string ok?
][
	string: to-UTF8 as red-string! end-point

	either none? string [
		no
	][
		with zmq [ok?: zmq/serve as socket! socket  string]
		free-any string
		ok?
	]
]
serve: func [											"Set up server socket binding."
	socket			[integer!]							"socket!"
	end-point		[url! string!]
	return:			[logic!]
][
	serve* socket end-point
]
unbind: routine [										"Unbind server socket."
	socket			[integer!]							"socket!"
	end-point		;[url! string!]
	return:			[logic!]
	/local string ok?
][
	string: to-UTF8 as red-string! end-point

	either none? string [
		no
	][
		with zmq [ok?: zmq/unbind as socket! socket string]
		free-any string
		ok?
	]
]
comment {
unbind: func [											"Unbind server socket."
	socket			[integer!]							"socket!"
	end-point		[url! string!]
	return:			[logic!]
][
	unserve* socket end-point
]
}

connect*: routine [										"Connect to a server socket."
	socket			[integer!]							"socket!"
	destination
	return:			[logic!]
	/local string ok?
][
	string: to-UTF8 as red-string! destination

	either none? string [
		no
	][
		with zmq [ok?: zmq/connect as socket! socket  string]
		free-any string
		ok?
	]
]
connect: func [											"Connect to a server socket."
	socket			[integer!]							"socket!"
	destination		[url! string!]
	return:			[logic!]
][
	connect* socket destination
]

disconnect: routine [									"Disconnect from a server socket."
	socket			[integer!]							"socket!"
	destination		;[url! string!]
	return:			[logic!]
	/local string ok?
][
	string: to-UTF8 as red-string! destination

	either none? string [
		no
	][
		with zmq [ok?: zmq/disconnect as socket! socket  string]
		free-any string
		ok?
	]
]
comment {
disconnect: func [											"Connect to a server socket."
	socket			[integer!]							"socket!"
	destination		[url! string!]
	return:			[logic!]
][
	disconnect* socket destination
]
}


; Message management

;message?: function [									"Is value a message?"
;	value
;	return:			[logic!]
;][
;	integer? value
;]

end-message: routine [									"Clean up message."
	message			[integer!]							"message!"
	return:			[logic!]
][
	with zmq [
		either zmq/end-message as message! message [
			free-any message
			yes
		][
;			free-any message
			no
		]
	]
]
copy-message: routine [									"Return copy of message, or NONE."
	source			[integer!]							"message!"
;	return:			[integer! none!]					"message!"
	/local			target
][
	with zmq [
		target: as message! allocate size? message!

		either none? target [
			RETURN_NONE
		][
			either clear-message target [
				either zmq/copy-message as message! source  target [
					integer/box as-integer target
				][
					end-message as-integer target
					RETURN_NONE
				]
			][
				free-any target
				RETURN_NONE
			]
		]
	]
]

empty-message?: routine [								"Is message empty?"
	message			[integer!]							"message!"
	return:			[logic!]
][
	with zmq [zmq/empty-message? as message! message]
]
message-to-binary: routine [							"Free message, return content as binary!, or NONE."
	message			[integer!]							"message!"
	buffer			[binary!]
;	return:			[binary! none!]
	/local			data
][
	with zmq [
		data: data-of-message as message! message

		either none? data [
			end-message message
			RETURN_NONE
		][
			binary/rs-clear buffer
			binary/rs-append buffer data
				size-of-message as message! message

			either end-message message [
				SET_RETURN (buffer)
			][
				RETURN_NONE
			]
		]
	]
]
message-to-string: routine [							"Free binary message, return content converted into string, or NONE."
	message			[integer!]							"message!"
	buffer			[string!]
;	return:			[string! none!]
	/local text size series
][
	with zmq [
		text: as-c-string data-of-message as message! message

		either none? text [
			end-message message
			RETURN_NONE
		][
			string/rs-reset buffer  ; Ensure Latin 1
			size: size-of-message as message! message

			unless zero? size [
				series: GET_BUFFER (buffer)

				either text/size = null-byte [
					unicode/load-utf8-buffer
						text  size - 1
						series null
						no
				][
					unicode/load-utf8-buffer
						text size
						series null
						no
				]
				buffer/cache: null
			]
			either end-message message [
				SET_RETURN (buffer)
			][
				RETURN_NONE
			]
		]
	]
]


; Message transfer

;empty-socket?: routine ["Are no incoming messages available? WARNING: only valid immediately after a receive/no-wait error."
;	return:			[logic!]
;][
;	zmq/empty-socket?
;]

message-tail?: routine [								"Was last message the last part of a possibly multi-part message?"
	socket			[integer!]							"socket!"
;	return:			[logic! none!]
	/local			tail?
][
	with zmq [
		tail?: zmq/message-tail? as socket! socket

		either negative? tail? [  ; Error
			RETURN_NONE
		][
			logic/box as-logic tail?
		]
	]
]

send-message: routine [									"Send binary message."
	socket			[integer!]							"socket!"
	message			[integer!]							"message!"
	flags			[integer!]							"send-receive-flags!"
	return:			[logic!]
][
	with zmq [
		either zmq/send-message
			as socket! socket
			as message! message
			flags
		[
			end-message message
		][
			end-message message  ; FIXME: error code may get replaced
			no
		]
	]
]
receive-message: routine [								"Receive and return a binary message."
	socket			[integer!]							"socket!"
	flags			[integer!]							"send-receive-flags!"
;	return:			[integer! logic! none!]				"message!"
	/local			message
][
	with zmq [
		message: as message! allocate size? message!

		either none? message [
			RETURN_NONE
		][
			either receive as socket! socket  message flags [
				integer/box as-integer message
			][	; Error
				free-any message

				either zmq/empty-socket? [
					RETURN_NONE
				][
					logic/box no
				]
			]
		]
	]
]

send-empty: routine [									"Send empty message."
	socket			[integer!]							"socket!"
	flags			[integer!]							"send-receive-flags!"
	return:			[logic!]
][
	with zmq [zmq/send-empty as socket! socket  zmq/message flags]
]

send-binary: routine [									"Send binary message, then optionally free data."
	socket			[integer!]							"socket!"
	data			[integer!]							"binary!"
	size			[integer!]
	flags			[integer!]							"send-receive-flags!"
	free?			[logic!]							"Free binary data after sending?"
	return:			[logic!]
][
	with zmq [send
		as socket! socket
		zmq/message
		as-binary data
		size
		flags
		as-integer either free? [:free-message] [null]  ; WARN: ARM?
	]
]

send-string: routine [									"Send text message as UTF-8."
	socket			[integer!]							"socket!"
	string			[string!]
	flags			[integer!]							"send-receive-flags!"
	return:			[logic!]
	/local			text
][
	text: to-UTF8 string
	all [
		as-logic text
		send-binary socket  as-integer text  length? text  flags yes
	]
]
receive-string: routine [								"Receive and return a UTF-8 text message into BUFFER."
	socket			[integer!]							"socket!"
	buffer			[string!]
	flags			[integer!]							"send-receive-flags!"
;	return:			[string! logic! none!]
	/local text size series
][
	with zmq [either receive as socket! socket  zmq/message flags [
		text: as-c-string data-of-message zmq/message

		either none? text [  ; FIXME: there may be no error code
			zmq/end-message zmq/message  ; FIXME: error code may get replaced
			logic/box no
;			RETURN_NONE
		][
			string/rs-reset buffer  ; Ensure Latin 1
			size: size-of-message zmq/message

			unless zero? size [
				series: GET_BUFFER (buffer)

				either text/size = null-byte [
					unicode/load-utf8-buffer
						text  size - 1
						series null
						no
				][
					unicode/load-utf8-buffer
						text size
						series null
						no
				]
				buffer/cache: null
			]
			either zmq/end-message zmq/message [  ; FIXME: error code may get replaced
				SET_RETURN (buffer)
			][
				logic/box no
			]
		]
	][	; Error
		either zmq/empty-socket? [
			RETURN_NONE
		][
			logic/box no
		]
	]]
]

send: function [										"Send message."
	socket			[integer!]							"socket!"
	message			[integer! binary! string! none!]	"message!; NONE: send empty message."
	/binary												"Send (part of) binary data."
		size		[integer!]
	/free												"Free binary data after sending."
	/part												"Send part of a multi-part message."
	return:			[logic!]
][
	flags: either part [send-more] [zmq-none]

	switch type?/word message [
		integer!	[either binary [
						send-binary socket message size flags free
					][
						send-message socket message flags
					]]
		string!		[send-string  socket message flags]
		none!		[send-empty   socket		 flags]
	]
]
receive: function [										"Receive and return a message."
	socket			[integer!]							"socket!"
	/no-wait											"Don't wait for a message to arrive."
	/string												"Receive a UTF-8 text message."
	/over												"Receive a UTF-8 text message into a buffer."
		out			[binary! string!]					"Receive buffer"
	return:			[integer! string! logic! none!]		"message!; NO: error; NONE: no messages available"
][
	flags: either no-wait [no-block] [zmq-none]

	case [
		over	receive-string	socket	out				flags
		string	receive-string	socket	make string! 0	flags
		yes		receive-message	socket					flags
	]
]
