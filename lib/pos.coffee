# 打印机处理模块


ffi = require 'ffi'
os = require 'os'
ref = require 'ref'
iconv = require 'iconv-lite'
util = require 'util'
path = require 'path'
# dll路径。
# 注：路径中不能包含中文，否则会无法加载dll，所以这里使用相对根目录的路径
dllPath = path.join __dirname , '/POSDLL.dll'
if /[\u0391-\uFFE5]+/g.test dllPath
    console.log '运行环境错误：app完整路径中不能包含中文。'
    throw 'error'


types = ref.types

# 只支持windows服务器，包括win32、win64
platform = os.platform()
enable = if platform.indexOf('win') is 0 then true else false
console.warn "Platform:#{platform} cant load #{dllPath}." if not enable


# 坑爹的ffi，传给要函数的参数是中文会导致编码问题。这里注入到ref模块，将默认编码改为gbk
# 注：nodejs本身不支持gbk编码，需要用iconv扩展nodejs支持的编码格式。
# 
# 扩展nodejs的编码库
iconv.extendNodeEncodings()
allocCString = ref.allocCString
ref.allocCString = (str,encoding='gbk')->
	allocCString.call ref,str,encoding




# 返回c++类型列表对象。入参为参数名称，随意定义，用于标识函数的参数名称。
t = (name)->
	types
# 函数库
Pos = if enable then ffi.Library dllPath,
	# System control
	'POS_Open':[types.long,[t('pszPortName').CString, t('nComBaudrate').long, t('nComDataBits').long, t('nComStopBits').long, t('nComParity').long, t('nComFlowControl').long]]
	'POS_Close':[types.long,[]]
	'POS_Reset':[types.long,[]]
	'POS_BeginSaveFile':[types.long,[t('lpFileName').CString, t('bToPrinter').bool]]
	'POS_EndSaveFile':[types.long,[]]
	'POS_SetMode':[types.long,[t('nPrintMode').long]]
	'POS_SetMotionUnit':[types.long,[t('nHorizontalMU').long, t('nVerticalMU').long]]
	'POS_SetCharSetAndCodePage':[types.long,[t('nCharSet').long, t('nCodePage').long]]
	'POS_FeedLine':[types.long,[]]
	'POS_SetLineSpacing':[types.long,[t('nDistance').long]]
	'POS_SetRightSpacing':[types.long,[t('nDistance').long]]
	'POS_CutPaper':[types.long,[t('nMode').long, t('nDistance').long]]
	'POS_PreDownloadBmpToRAM':[types.long,[t('pszPath').CString, t('nID').long]]
	'POS_PreDownloadBmpsToFlash':[types.long,[t('pszPaths').CString, t('nCount').long]]
	'POS_PreDownloadBmpsToFlash':[types.long,[t('pszPath()').CString, t('nCount').long]]
	'POS_QueryStatus':[types.long,[t('pszStatus').CString, t('nTimeouts').long]]
	'POS_RTQueryStatus':[types.long,[t('address').byte]]
	'POS_NETQueryStatus':[types.long,[t('pszPortName1').CString, 'pointer']]
	'POS_KickOutDrawer':[types.long,[t('nID').int32, t('nOnTimes').int32, t('nOffTimes').int32]]
	'POS_StartDoc':[types.long,[]]
	'POS_EndDoc':[types.long,[]]
	'POS_S_SetAlignMode':[types.long,[t('nMode').long]]
	# The functions only support standard mode (or line mode)
	'POS_S_SetAreaWidth':[types.long,[t('nWidth').long]]
	'POS_S_TextOut':[types.long,[t('text').CString, t('nOrgx').long, t('nWidthTimes').long, t('nHeightTimes').long, t('nFontType').long, t('nFontStyle').long]]
	'POS_S_DownloadAndPrintBmp':[types.long,[t('pszPath').CString, t('nOrgx').long, t('nMode').long]]
	'POS_S_PrintBmpInRAM':[types.long,[t('nID').long, t('nOrgx').long, t('nMode').long]]
	'POS_S_PrintBmpInFlash':[types.long,[t('nID').long, t('nOrgx').long, t('nMode').long]]
	'POS_S_SetBarcode':[types.long,[t('pszInfo').CString, t('nOrgx').long, t('nType').long, t('nWidthX').long, t('nheight').long, t('nHriFontType').long, t('nHriFontPosition').long, t('nBytesOfInfo').long]]
	# The functions only support paper mode and (or) label mode
	'POS_PL_SetArea':[types.long,[t('nOrgx').long, t('nOrgY').long, t('nWidth').long, t('nheight').long, t('nDirection').long]]
	'POS_PL_TextOut':[types.long,[types.CString, t('nOrgx').long, t('nOrgY').long, t('nWidthTimes').long, t('nHeightTimes').long, t('nFontType').long, t('nFontStyle').long]] 
	'POS_PL_DownloadAndPrintBmp':[types.long,[t('pszPath').CString, t('nOrgx').long, t('nOrgY').long, t('nMode').long]]
	'POS_PL_PrintBmpInRAM':[types.long,[t('nID').long, t('nOrgx').long, t('nOrgY').long, t('nMode').long]]
	'POS_PL_SetBarcode':[types.long,[t('pszInfo').CString, t('nOrgx').long, t('nOrgY').long, t('nType').long, t('nWidthX').long, t('nheight').long, t('nHriFontType').long, t('nHriFontPosition').long, t('nBytesOfInfo').long]]
	'POS_PL_Clear':[types.long,[]]
	'POS_PL_Print':[types.long,[]]
	# Data transmission
	'POS_WriteFile':[types.long,[t('hPort').long, t('pszData').CString, t('nBytesToWrite').long]]
	'POS_ReadFile':[types.long,[t('hPort').long, t('pszData').CString, t('nBytesToRead').CString, t('nTimeouts').long]]
	'POS_SetHandle':[types.long,[t('hNewHandle').long]]
	'POS_GetVersionInfo':[types.long,[t('nMajor').long, t('nMinor').long]] 


# 会用到的常量
POSC = 
	# The return value
	'POS_SUCCESS':1001
	'POS_FAIL':1002
	'POS_ERROR_INVALID_HANDLE':1101
	'POS_ERROR_INVALID_PARAMETER':1102
	'POS_ERROR_NOT_BITMAP':1103
	'POS_ERROR_NOT_MONO_BITMAP':1104
	'POS_ERROR_BEYONG_AREA':1105
	'POS_ERROR_INVALID_PATH':1106

	# The number of stop bits options of serial port
	'POS_COM_ONESTOPBIT':0
	# 'POS_COM_ONE5STOPBITS':1
	'POS_COM_TWOSTOPBITS':2

	# Parity options of serial port
	'POS_COM_NOPARITY':0
	'POS_COM_ODDPARITY':1
	'POS_COM_EVENPARITY':2
	'POS_COM_MARKPARITY':3
	'POS_COM_SPACEPARITY':4

	# Flow control options of serial port
	'POS_COM_DTR_DSR':0
	'POS_COM_RTS_CTS':1
	'POS_COM_XON_XOFF':2
	'POS_COM_NO_HANDSHAKE':3
	'POS_OPEN_PARALLEL_PORT':18
	'POS_OPEN_BYUSB_PORT':19
	'POS_OPEN_PRINTNAME':20
	'POS_OPEN_NETPORT':21

	# Mode options of the way of paper leaving away from printer
	'POS_PAPER_OUT_MODE_CUT':0
	'POS_PAPER_OUT_MODE_PEEL':1
	'POS_PAPER_OUT_MODE_TEAR':2
	'POS_PAPER_OUT_MODE_OTHER':3

	# Print mode options
	'POS_PRINT_MODE_STANDARD':0
	'POS_PRINT_MODE_PAGE':1
	'POS_PRINT_MODE_BLACK_MARK_LABEL':2
	'POS_PRINT_MODE_WHITE_MARK_LABEL':3

	# Font type options
	'POS_FONT_TYPE_STANDARD':0
	'POS_FONT_TYPE_COMPRESSED':1
	'POS_FONT_TYPE_UDC':2
	'POS_FONT_TYPE_CHINESE':3

	# Font style options
	'POS_FONT_STYLE_NORMAL':0x0
	'POS_FONT_STYLE_BOLD':0x8
	'POS_FONT_STYLE_THIN_UNDERLINE':0x80
	'POS_FONT_STYLE_THICK_UNDERLINE':0x100
	'POS_FONT_STYLE_UPSIDEDOWN':0x200
	'POS_FONT_STYLE_REVERSE':0x400
	'POS_FONT_STYLE_SMOOTH':0x800
	'POS_FONT_STYLE_CLOCKWISE_90':0x1000

	# Specify the area direction of paper or lable
	'POS_AREA_LEFT_TO_RIGHT':0
	'POS_AREA_BOTTOM_TO_TOP':1
	'POS_AREA_RIGHT_TO_LEFT':2
	'POS_AREA_TOP_TO_BOTTOM':3

	# Cut mode options
	'POS_CUT_MODE_FULL':0
	'POS_CUT_MODE_PARTIAL':1

	# Mode options of printing bit image in RAM or Flash
	'POS_BITMAP_PRINT_NORMAL':0
	'POS_BITMAP_PRINT_DOUBLE_WIDTH':1
	'POS_BITMAP_PRINT_DOUBLE_HEIGHT':2
	'POS_BITMAP_PRINT_QUADRUPLE':3

	# Mode options of bit-image -- for download and print
	'POS_BITMAP_MODE_8SINGLE_DENSITY':0x0
	'POS_BITMAP_MODE_8DOUBLE_DENSITY':0x1
	'POS_BITMAP_MODE_24SINGLE_DENSITY':0x20
	'POS_BITMAP_MODE_24DOUBLE_DENSITY':0x21

	# Barcode's type
	'POS_BARCODE_TYPE_UPC_A':0x41
	'POS_BARCODE_TYPE_UPC_E':0x42
	'POS_BARCODE_TYPE_JAN13':0x43
	'POS_BARCODE_TYPE_JAN8':0x44
	'POS_BARCODE_TYPE_CODE39':0x45
	'POS_BARCODE_TYPE_ITF':0x46
	'POS_BARCODE_TYPE_CODEBAR':0x47
	'POS_BARCODE_TYPE_CODE93':0x48
	'POS_BARCODE_TYPE_CODE128':0x49

	# Barcode HRI's position
	'POS_HRI_POSITION_NONE':0x0
	'POS_HRI_POSITION_ABOVE':0x1
	'POS_HRI_POSITION_BELOW':0x2
	'POS_HRI_POSITION_BOTH':0x3


test = (ip)->
	res = Pos.POS_Open ip,0,0,0,0,POSC.POS_OPEN_NETPORT
	return 1 if res is -1
	res = Pos.POS_StartDoc()
	Pos.POS_SetMotionUnit 180,180
	Pos.POS_SetMode POSC.POS_PRINT_MODE_STANDARD
	Pos.POS_SetRightSpacing 0
	Pos.POS_SetLineSpacing 100
	Pos.POS_S_SetBarcode "1234567890123456789", 40, POSC.POS_BARCODE_TYPE_CODE93, 2, 50, POSC.POS_FONT_TYPE_COMPRESSED, POSC.POS_HRI_POSITION_BOTH, 19
	Pos.POS_SetLineSpacing 35
	Pos.POS_FeedLine()
	Pos.POS_FeedLine()
	Pos.POS_FeedLine()
	Pos.POS_FeedLine()
	Pos.POS_FeedLine()
	res = Pos.POS_EndDoc()
	res = Pos.POS_CutPaper(POSC.POS_CUT_MODE_FULL, 0)
	res = Pos.POS_Close()

Print = 
	# 打开连接，返回true/false
	open:(ip)->
		return false if not enable

		if Pos.POS_Open(ip,0,0,0,0,POSC.POS_OPEN_NETPORT) is -1 then false else true
	# 关闭连接，返回true/false
	close:->
		return false if not enable

		return if Pos.POS_Close() is Pos.POS_SUCCESS then true else false
	# 打开钱箱，返回true/false
	kickOutDrawer:(ip)->
		return false if not enable

		return false if not @open(ip)
		return false if Pos.POS_KickOutDrawer(0, 100, 100) isnt Pos.POS_SUCCESS
		@close()
	# 查询打印机状态，返回状态状态数组
	# 返回false:查询失败
	# 返回数组：长度为0，一切正常
	# 长度大于0：则包含多个错误信息
	query:(ip)->
		return false if not enable

		return false if not @open(ip)
		byte = new Buffer(1)
		byte[0] = 0x0
		# 第二个参数为指针类型
		return false if Pos.POS_NETQueryStatus(ip,byte) isnt POSC.POS_SUCCESS
		result = []
		result.push '有钱箱打开'	if (byte[0] & 0x1) isnt 0x1 #钱箱是否打开
		result.push '打印机脱机' if (byte[0] & 0x2) is 0x2 #打印机联机/脱机
		result.push '打印机上盖未关' if (byte[0] & 0x4) is 0x4 # 上盖关闭/打开
		result.push '正在进纸' if (byte[0] & 0x8) is 0x8 #没有/正在由feed键按下而进纸
		result.push '打印机出错' if (byte[0] & 0x10) is 0x10 #打印机没有/有出错
		result.push '切刀出错' if (byte[0] & 0x20) is 0x20 #切刀没有/有出错
		result.push '打印纸即将用完' if (byte[0] & 0x40) is 0x40 #有纸/纸即将用完
		result.push '缺纸' if (byte[0] & 0x80) is 0x80 #有纸/纸用尽
		@close()
		result
		
	# 打印，传入要打印的数组。返回0打印成功，其他错误
	print:(ip,lineList)->
		return 'Error' if not enable

		return 'ArgesError' if util.isArray(lineList) is false or not lineList
		return 'OpenError' if not @open(ip)
		return 'POS_SetMotionUnit' if Pos.POS_SetMotionUnit(180,180) isnt POSC.POS_SUCCESS
		return 'POS_SetMode' if Pos.POS_SetMode(POSC.POS_PRINT_MODE_STANDARD) isnt POSC.POS_SUCCESS
		if ip is '192.168.1.222'
			@close()
			return 0
			




		return 'POS_StartDoc' if not Pos.POS_StartDoc()
		for line in lineList
			lineType = line.linetype or 'txt'
			content = line.content or ''
			# 打印条码
			if lineType isnt 'txt'
				return 'POS_S_SetBarcode' if Pos.POS_S_SetBarcode("{A#{content}", 40, POSC.POS_BARCODE_TYPE_CODE128, 2, 50, POSC.POS_FONT_TYPE_COMPRESSED, POSC.POS_HRI_POSITION_BOTH, content.length + 2) isnt POSC.POS_SUCCESS
				continue;
			# 打印文本
			rightspace = line.rightspace
			lineheight = line.lineheight

			startposition = line.startposition or 20
			fonttype = line.fonttype or 0
			bold = if line.bold is 1 then 8 else 0
			underline1 = if line.underline1 is 1 then 80 else 0
			underline2 = if line.underline2 is 1 then 100 else 0
			reverse = if line.reverse is 1 then 400 else 0
			smooth = if line.smooth is 1 then 800 else 0
			clockwise = if line.clockwise is 1 then 1000 else 0
			upsidedown = if line.upsidedown is 1 then 200 else 0
			widthtimes = line.widthtimes or 1
			heighttimes = line.heighttimes or 1
			feedline = line.feedline or 0

			return 'POS_SetLineSpacing' if lineheight > 0 and Pos.POS_SetLineSpacing(lineheight) isnt POSC.POS_SUCCESS
			return 'POS_SetRightSpacing' if rightspace > 0 and Pos.POS_SetRightSpacing(rightspace) isnt POSC.POS_SUCCESS

			return 'POS_S_TextOut' + content + '123' if Pos.POS_S_TextOut(content, startposition, widthtimes, heighttimes, fonttype, bold | underline2 | underline1 | upsidedown | reverse | smooth | clockwise) isnt POSC.POS_SUCCESS if content
			return 'POS_FeedLine' if feedline is 0 and Pos.POS_FeedLine() isnt POSC.POS_SUCCESS

		return 'POS_FeedLine' if Pos.POS_FeedLine() isnt POSC.POS_SUCCESS
		return 'POS_FeedLine' if Pos.POS_FeedLine() isnt POSC.POS_SUCCESS
		return 'POS_EndDoc' if not Pos.POS_EndDoc()
		return 'POS_CutPaper' if Pos.POS_CutPaper(POSC.POS_CUT_MODE_PARTIAL,0) isnt POSC.POS_SUCCESS
		return 'POS_Close' if Pos.POS_Close() isnt POSC.POS_SUCCESS
		@close()
		return 0


module.exports = Print