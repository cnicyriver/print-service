// Generated by CoffeeScript 1.7.1
(function() {
  var POSC, Pos, Print, allocCString, dllPath, enable, ffi, iconv, os, path, platform, ref, t, test, types, util;

  ffi = require('ffi');

  os = require('os');

  ref = require('ref');

  iconv = require('iconv-lite');

  util = require('util');

  path = require('path');

  dllPath = path.join(__dirname, '/POSDLL.dll');

  if (/[\u0391-\uFFE5]+/g.test(dllPath)) {
    console.log('运行环境错误：app完整路径中不能包含中文。');
    throw 'error';
  }

  types = ref.types;

  platform = os.platform();

  enable = platform.indexOf('win') === 0 ? true : false;

  if (!enable) {
    console.warn("Platform:" + platform + " cant load " + dllPath + ".");
  }

  iconv.extendNodeEncodings();

  allocCString = ref.allocCString;

  ref.allocCString = function(str, encoding) {
    if (encoding == null) {
      encoding = 'gbk';
    }
    return allocCString.call(ref, str, encoding);
  };

  t = function(name) {
    return types;
  };

  Pos = enable ? ffi.Library(dllPath, {
    'POS_Open': [types.long, [t('pszPortName').CString, t('nComBaudrate').long, t('nComDataBits').long, t('nComStopBits').long, t('nComParity').long, t('nComFlowControl').long]],
    'POS_Close': [types.long, []],
    'POS_Reset': [types.long, []],
    'POS_BeginSaveFile': [types.long, [t('lpFileName').CString, t('bToPrinter').bool]],
    'POS_EndSaveFile': [types.long, []],
    'POS_SetMode': [types.long, [t('nPrintMode').long]],
    'POS_SetMotionUnit': [types.long, [t('nHorizontalMU').long, t('nVerticalMU').long]],
    'POS_SetCharSetAndCodePage': [types.long, [t('nCharSet').long, t('nCodePage').long]],
    'POS_FeedLine': [types.long, []],
    'POS_SetLineSpacing': [types.long, [t('nDistance').long]],
    'POS_SetRightSpacing': [types.long, [t('nDistance').long]],
    'POS_CutPaper': [types.long, [t('nMode').long, t('nDistance').long]],
    'POS_PreDownloadBmpToRAM': [types.long, [t('pszPath').CString, t('nID').long]],
    'POS_PreDownloadBmpsToFlash': [types.long, [t('pszPaths').CString, t('nCount').long]],
    'POS_PreDownloadBmpsToFlash': [types.long, [t('pszPath()').CString, t('nCount').long]],
    'POS_QueryStatus': [types.long, [t('pszStatus').CString, t('nTimeouts').long]],
    'POS_RTQueryStatus': [types.long, [t('address').byte]],
    'POS_NETQueryStatus': [types.long, [t('pszPortName1').CString, 'pointer']],
    'POS_KickOutDrawer': [types.long, [t('nID').int32, t('nOnTimes').int32, t('nOffTimes').int32]],
    'POS_StartDoc': [types.long, []],
    'POS_EndDoc': [types.long, []],
    'POS_S_SetAlignMode': [types.long, [t('nMode').long]],
    'POS_S_SetAreaWidth': [types.long, [t('nWidth').long]],
    'POS_S_TextOut': [types.long, [t('text').CString, t('nOrgx').long, t('nWidthTimes').long, t('nHeightTimes').long, t('nFontType').long, t('nFontStyle').long]],
    'POS_S_DownloadAndPrintBmp': [types.long, [t('pszPath').CString, t('nOrgx').long, t('nMode').long]],
    'POS_S_PrintBmpInRAM': [types.long, [t('nID').long, t('nOrgx').long, t('nMode').long]],
    'POS_S_PrintBmpInFlash': [types.long, [t('nID').long, t('nOrgx').long, t('nMode').long]],
    'POS_S_SetBarcode': [types.long, [t('pszInfo').CString, t('nOrgx').long, t('nType').long, t('nWidthX').long, t('nheight').long, t('nHriFontType').long, t('nHriFontPosition').long, t('nBytesOfInfo').long]],
    'POS_PL_SetArea': [types.long, [t('nOrgx').long, t('nOrgY').long, t('nWidth').long, t('nheight').long, t('nDirection').long]],
    'POS_PL_TextOut': [types.long, [types.CString, t('nOrgx').long, t('nOrgY').long, t('nWidthTimes').long, t('nHeightTimes').long, t('nFontType').long, t('nFontStyle').long]],
    'POS_PL_DownloadAndPrintBmp': [types.long, [t('pszPath').CString, t('nOrgx').long, t('nOrgY').long, t('nMode').long]],
    'POS_PL_PrintBmpInRAM': [types.long, [t('nID').long, t('nOrgx').long, t('nOrgY').long, t('nMode').long]],
    'POS_PL_SetBarcode': [types.long, [t('pszInfo').CString, t('nOrgx').long, t('nOrgY').long, t('nType').long, t('nWidthX').long, t('nheight').long, t('nHriFontType').long, t('nHriFontPosition').long, t('nBytesOfInfo').long]],
    'POS_PL_Clear': [types.long, []],
    'POS_PL_Print': [types.long, []],
    'POS_WriteFile': [types.long, [t('hPort').long, t('pszData').CString, t('nBytesToWrite').long]],
    'POS_ReadFile': [types.long, [t('hPort').long, t('pszData').CString, t('nBytesToRead').CString, t('nTimeouts').long]],
    'POS_SetHandle': [types.long, [t('hNewHandle').long]],
    'POS_GetVersionInfo': [types.long, [t('nMajor').long, t('nMinor').long]]
  }) : void 0;

  POSC = {
    'POS_SUCCESS': 1001,
    'POS_FAIL': 1002,
    'POS_ERROR_INVALID_HANDLE': 1101,
    'POS_ERROR_INVALID_PARAMETER': 1102,
    'POS_ERROR_NOT_BITMAP': 1103,
    'POS_ERROR_NOT_MONO_BITMAP': 1104,
    'POS_ERROR_BEYONG_AREA': 1105,
    'POS_ERROR_INVALID_PATH': 1106,
    'POS_COM_ONESTOPBIT': 0,
    'POS_COM_TWOSTOPBITS': 2,
    'POS_COM_NOPARITY': 0,
    'POS_COM_ODDPARITY': 1,
    'POS_COM_EVENPARITY': 2,
    'POS_COM_MARKPARITY': 3,
    'POS_COM_SPACEPARITY': 4,
    'POS_COM_DTR_DSR': 0,
    'POS_COM_RTS_CTS': 1,
    'POS_COM_XON_XOFF': 2,
    'POS_COM_NO_HANDSHAKE': 3,
    'POS_OPEN_PARALLEL_PORT': 18,
    'POS_OPEN_BYUSB_PORT': 19,
    'POS_OPEN_PRINTNAME': 20,
    'POS_OPEN_NETPORT': 21,
    'POS_PAPER_OUT_MODE_CUT': 0,
    'POS_PAPER_OUT_MODE_PEEL': 1,
    'POS_PAPER_OUT_MODE_TEAR': 2,
    'POS_PAPER_OUT_MODE_OTHER': 3,
    'POS_PRINT_MODE_STANDARD': 0,
    'POS_PRINT_MODE_PAGE': 1,
    'POS_PRINT_MODE_BLACK_MARK_LABEL': 2,
    'POS_PRINT_MODE_WHITE_MARK_LABEL': 3,
    'POS_FONT_TYPE_STANDARD': 0,
    'POS_FONT_TYPE_COMPRESSED': 1,
    'POS_FONT_TYPE_UDC': 2,
    'POS_FONT_TYPE_CHINESE': 3,
    'POS_FONT_STYLE_NORMAL': 0x0,
    'POS_FONT_STYLE_BOLD': 0x8,
    'POS_FONT_STYLE_THIN_UNDERLINE': 0x80,
    'POS_FONT_STYLE_THICK_UNDERLINE': 0x100,
    'POS_FONT_STYLE_UPSIDEDOWN': 0x200,
    'POS_FONT_STYLE_REVERSE': 0x400,
    'POS_FONT_STYLE_SMOOTH': 0x800,
    'POS_FONT_STYLE_CLOCKWISE_90': 0x1000,
    'POS_AREA_LEFT_TO_RIGHT': 0,
    'POS_AREA_BOTTOM_TO_TOP': 1,
    'POS_AREA_RIGHT_TO_LEFT': 2,
    'POS_AREA_TOP_TO_BOTTOM': 3,
    'POS_CUT_MODE_FULL': 0,
    'POS_CUT_MODE_PARTIAL': 1,
    'POS_BITMAP_PRINT_NORMAL': 0,
    'POS_BITMAP_PRINT_DOUBLE_WIDTH': 1,
    'POS_BITMAP_PRINT_DOUBLE_HEIGHT': 2,
    'POS_BITMAP_PRINT_QUADRUPLE': 3,
    'POS_BITMAP_MODE_8SINGLE_DENSITY': 0x0,
    'POS_BITMAP_MODE_8DOUBLE_DENSITY': 0x1,
    'POS_BITMAP_MODE_24SINGLE_DENSITY': 0x20,
    'POS_BITMAP_MODE_24DOUBLE_DENSITY': 0x21,
    'POS_BARCODE_TYPE_UPC_A': 0x41,
    'POS_BARCODE_TYPE_UPC_E': 0x42,
    'POS_BARCODE_TYPE_JAN13': 0x43,
    'POS_BARCODE_TYPE_JAN8': 0x44,
    'POS_BARCODE_TYPE_CODE39': 0x45,
    'POS_BARCODE_TYPE_ITF': 0x46,
    'POS_BARCODE_TYPE_CODEBAR': 0x47,
    'POS_BARCODE_TYPE_CODE93': 0x48,
    'POS_BARCODE_TYPE_CODE128': 0x49,
    'POS_HRI_POSITION_NONE': 0x0,
    'POS_HRI_POSITION_ABOVE': 0x1,
    'POS_HRI_POSITION_BELOW': 0x2,
    'POS_HRI_POSITION_BOTH': 0x3
  };

  test = function(ip) {
    var res;
    res = Pos.POS_Open(ip, 0, 0, 0, 0, POSC.POS_OPEN_NETPORT);
    if (res === -1) {
      return 1;
    }
    res = Pos.POS_StartDoc();
    Pos.POS_SetMotionUnit(180, 180);
    Pos.POS_SetMode(POSC.POS_PRINT_MODE_STANDARD);
    Pos.POS_SetRightSpacing(0);
    Pos.POS_SetLineSpacing(100);
    Pos.POS_S_SetBarcode("1234567890123456789", 40, POSC.POS_BARCODE_TYPE_CODE93, 2, 50, POSC.POS_FONT_TYPE_COMPRESSED, POSC.POS_HRI_POSITION_BOTH, 19);
    Pos.POS_SetLineSpacing(35);
    Pos.POS_FeedLine();
    Pos.POS_FeedLine();
    Pos.POS_FeedLine();
    Pos.POS_FeedLine();
    Pos.POS_FeedLine();
    res = Pos.POS_EndDoc();
    res = Pos.POS_CutPaper(POSC.POS_CUT_MODE_FULL, 0);
    return res = Pos.POS_Close();
  };

  Print = {
    open: function(ip) {
      if (!enable) {
        return false;
      }
      if (Pos.POS_Open(ip, 0, 0, 0, 0, POSC.POS_OPEN_NETPORT) === -1) {
        return false;
      } else {
        return true;
      }
    },
    close: function() {
      if (!enable) {
        return false;
      }
      if (Pos.POS_Close() === Pos.POS_SUCCESS) {
        return true;
      } else {
        return false;
      }
    },
    kickOutDrawer: function(ip) {
      if (!enable) {
        return false;
      }
      if (!this.open(ip)) {
        return false;
      }
      if (Pos.POS_KickOutDrawer(0, 100, 100) !== Pos.POS_SUCCESS) {
        return false;
      }
      return this.close();
    },
    query: function(ip) {
      var byte, result;
      if (!enable) {
        return false;
      }
      if (!this.open(ip)) {
        return false;
      }
      byte = new Buffer(1);
      byte[0] = 0x0;
      if (Pos.POS_NETQueryStatus(ip, byte) !== POSC.POS_SUCCESS) {
        return false;
      }
      result = [];
      if ((byte[0] & 0x1) !== 0x1) {
        result.push('有钱箱打开');
      }
      if ((byte[0] & 0x2) === 0x2) {
        result.push('打印机脱机');
      }
      if ((byte[0] & 0x4) === 0x4) {
        result.push('打印机上盖未关');
      }
      if ((byte[0] & 0x8) === 0x8) {
        result.push('正在进纸');
      }
      if ((byte[0] & 0x10) === 0x10) {
        result.push('打印机出错');
      }
      if ((byte[0] & 0x20) === 0x20) {
        result.push('切刀出错');
      }
      if ((byte[0] & 0x40) === 0x40) {
        result.push('打印纸即将用完');
      }
      if ((byte[0] & 0x80) === 0x80) {
        result.push('缺纸');
      }
      this.close();
      return result;
    },
    print: function(ip, lineList) {
      var bold, clockwise, content, feedline, fonttype, heighttimes, line, lineType, lineheight, reverse, rightspace, smooth, startposition, underline1, underline2, upsidedown, widthtimes, _i, _len;
      if (!enable) {
        return 'Error';
      }
      if (util.isArray(lineList) === false || !lineList) {
        return 'ArgesError';
      }
      if (!this.open(ip)) {
        return 'OpenError';
      }
      if (Pos.POS_SetMotionUnit(180, 180) !== POSC.POS_SUCCESS) {
        return 'POS_SetMotionUnit';
      }
      if (Pos.POS_SetMode(POSC.POS_PRINT_MODE_STANDARD) !== POSC.POS_SUCCESS) {
        return 'POS_SetMode';
      }
      if (!Pos.POS_StartDoc()) {
        return 'POS_StartDoc';
      }
      for (_i = 0, _len = lineList.length; _i < _len; _i++) {
        line = lineList[_i];
        lineType = line.linetype || 'txt';
        content = line.content || '';
        if (lineType !== 'txt') {
          if (Pos.POS_S_SetBarcode("{A" + content, 40, POSC.POS_BARCODE_TYPE_CODE128, 2, 50, POSC.POS_FONT_TYPE_COMPRESSED, POSC.POS_HRI_POSITION_BOTH, content.length + 2) !== POSC.POS_SUCCESS) {
            return 'POS_S_SetBarcode';
          }
          continue;
        }
        rightspace = line.rightspace;
        lineheight = line.lineheight;
        startposition = line.startposition || 20;
        fonttype = line.fonttype || 0;
        bold = line.bold === 1 ? 8 : 0;
        underline1 = line.underline1 === 1 ? 80 : 0;
        underline2 = line.underline2 === 1 ? 100 : 0;
        reverse = line.reverse === 1 ? 400 : 0;
        smooth = line.smooth === 1 ? 800 : 0;
        clockwise = line.clockwise === 1 ? 1000 : 0;
        upsidedown = line.upsidedown === 1 ? 200 : 0;
        widthtimes = line.widthtimes || 1;
        heighttimes = line.heighttimes || 1;
        feedline = line.feedline || 0;
        if (lineheight > 0 && Pos.POS_SetLineSpacing(lineheight) !== POSC.POS_SUCCESS) {
          return 'POS_SetLineSpacing';
        }
        if (rightspace > 0 && Pos.POS_SetRightSpacing(rightspace) !== POSC.POS_SUCCESS) {
          return 'POS_SetRightSpacing';
        }
        if (content) {
          if (Pos.POS_S_TextOut(content, startposition, widthtimes, heighttimes, fonttype, bold | underline2 | underline1 | upsidedown | reverse | smooth | clockwise) !== POSC.POS_SUCCESS) {
            return 'POS_S_TextOut' + content + '123';
          }
        }
        if (feedline === 0 && Pos.POS_FeedLine() !== POSC.POS_SUCCESS) {
          return 'POS_FeedLine';
        }
      }
      if (Pos.POS_FeedLine() !== POSC.POS_SUCCESS) {
        return 'POS_FeedLine';
      }
      if (Pos.POS_FeedLine() !== POSC.POS_SUCCESS) {
        return 'POS_FeedLine';
      }
      if (!Pos.POS_EndDoc()) {
        return 'POS_EndDoc';
      }
      if (Pos.POS_CutPaper(POSC.POS_CUT_MODE_PARTIAL, 0) !== POSC.POS_SUCCESS) {
        return 'POS_CutPaper';
      }
      if (Pos.POS_Close() !== POSC.POS_SUCCESS) {
        return 'POS_Close';
      }
      this.close();
      return 0;
    }
  };

  module.exports = Print;

}).call(this);
