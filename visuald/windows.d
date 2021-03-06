// This file is part of Visual D
//
// Visual D integrates the D programming language into Visual Studio
// Copyright (c) 2010 by Rainer Schuetze, All Rights Reserved
//
// License for redistribution is given by the Artistic License 2.0
// see file LICENSE for further details

module visuald.windows;

HRESULT HResultFromLastError()
{
	return HRESULT_FROM_WIN32(GetLastError());
}

int GET_X_LPARAM(LPARAM lp)
{
	return cast(int)cast(short)LOWORD(lp);
}

int GET_Y_LPARAM(LPARAM lp)
{
	return cast(int)cast(short)HIWORD(lp);
}

int MAKELPARAM(int lo, int hi)
{
	return (lo & 0xffff) | (hi << 16);
}

COLORREF RGB(int r, int g, int b)
{
	return cast(COLORREF)(cast(BYTE)r | ((cast(uint)cast(BYTE)g)<<8) | ((cast(uint)cast(BYTE)b)<<16));
}

public import sdk.win32.shellapi;

const WM_SYSTIMER = 0x118;

public import sdk.port.base;

extern(Windows)
{
	uint GetThreadLocale();
	
	UINT DragQueryFileW(HANDLE hDrop, UINT iFile, LPWSTR lpszFile, UINT cch);
	HINSTANCE ShellExecuteW(HWND hwnd, LPCWSTR lpOperation, LPCWSTR lpFile, LPCWSTR lpParameters, LPCWSTR lpDirectory, INT nShowCmd);
}
