import TeamTalkC

// Struct/enum types the Swift wrapper's own public API and .rawValue/.cValue
// interop expose directly - re-exported by name (not the whole TeamTalkC
// module) so raw SDK *functions* (TT_*) are not reachable from `import
// TeamTalkKit` alone, only these specific types. See Documentation/TODO.md's
// "Decide how much of TeamTalkC should remain re-exported long term".
public typealias Channel = TeamTalkC.Channel
public typealias User = TeamTalkC.User
public typealias ServerProperties = TeamTalkC.ServerProperties
public typealias UserAccount = TeamTalkC.UserAccount
public typealias TextMessage = TeamTalkC.TextMessage
public typealias AudioCodec = TeamTalkC.AudioCodec
public typealias OpusCodec = TeamTalkC.OpusCodec
public typealias SpeexCodec = TeamTalkC.SpeexCodec
public typealias SpeexVBRCodec = TeamTalkC.SpeexVBRCodec
public typealias Codec = TeamTalkC.Codec
public typealias TextMsgType = TeamTalkC.TextMsgType
public typealias TTBOOL = TeamTalkC.TTBOOL
public typealias INT32 = TeamTalkC.INT32

// Codec.* case constants and other value constants used directly by app code
// - typealias only re-exports types, so these need individual redeclaration.
public let OPUS_CODEC = TeamTalkC.OPUS_CODEC
public let SPEEX_CODEC = TeamTalkC.SPEEX_CODEC
public let SPEEX_VBR_CODEC = TeamTalkC.SPEEX_VBR_CODEC
public let NO_CODEC = TeamTalkC.NO_CODEC
public let OPUS_APPLICATION_VOIP = TeamTalkC.OPUS_APPLICATION_VOIP
public let OPUS_APPLICATION_AUDIO = TeamTalkC.OPUS_APPLICATION_AUDIO
public let OPUS_REALMAX_FRAMESIZE = TeamTalkC.OPUS_REALMAX_FRAMESIZE
public let OPUS_MIN_BITRATE = TeamTalkC.OPUS_MIN_BITRATE
public let OPUS_MAX_BITRATE = TeamTalkC.OPUS_MAX_BITRATE
public let SPEEX_UWB_MAX_BITRATE = TeamTalkC.SPEEX_UWB_MAX_BITRATE
public let MSGTYPE_USER = TeamTalkC.MSGTYPE_USER
public let MSGTYPE_CHANNEL = TeamTalkC.MSGTYPE_CHANNEL
public let SOUND_GAIN_DEFAULT = TeamTalkC.SOUND_GAIN_DEFAULT
public let SOUND_VOLUME_DEFAULT = TeamTalkC.SOUND_VOLUME_DEFAULT
public let WEBRTC_GAINCONTROLLER2_FIXEDGAIN_MAX = TeamTalkC.WEBRTC_GAINCONTROLLER2_FIXEDGAIN_MAX
public let TT_STRLEN = TeamTalkC.TT_STRLEN
public let TEAMTALK_VERSION = TeamTalkC.TEAMTALK_VERSION
