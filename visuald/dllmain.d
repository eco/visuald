// This file is part of Visual D
//
// Visual D integrates the D programming language into Visual Studio
// Copyright (c) 2010 by Rainer Schuetze, All Rights Reserved
//
// License for redistribution is given by the Artistic License 2.0
// see file LICENSE for further details

module visuald.dllmain;

import stdwin = std.c.windows.windows;
import visuald.windows;
import visuald.comutil;
import visuald.logutil;
import visuald.register;
import visuald.dpackage;
import visuald.getmsobj;

import std.parallelism;

import core.runtime;
import core.memory;
import core.sys.windows.dll;
import threadaux = core.sys.windows.threadaux;

import std.conv;

__gshared HINSTANCE g_hInst;

///////////////////////////////////////////////////////////////////////
//version = MAIN;

version(MAIN)
{
	int main()
	{
		return VerifyMSObj(("Software\\Microsoft\\VisualStudio\\9.0D"w).ptr);
		//return VSDllRegisterServer(("Software\\Microsoft\\VisualStudio\\9.0D"w).ptr);
		//return VSDllUnregisterServerUser(("Software\\Microsoft\\VisualStudio\\9.0D"w).ptr);
	}
}
else version(TESTMAIN)
{
	import vdc.semantic;
	__gshared extern(C) extern long gcdump_userData;
	__gshared extern(C) extern bool gcdump_pools;

	int main()
	{
		Project prj = new Project;
		string[] imps = [ r"m:\s\d\rainers\druntime\import\", r"m:\s\d\rainers\phobos\" ];
		string fname = r"m:\s\d\rainers\phobos\std\datetime.d";
		
		prj.options.setImportDirs(imps);
		prj.addAndParseFile(fname);
		
//		gcdump_pools = true;
//		GC.collect();
//		gcdump_pools = false;

//		prj.semantic();

		foreach(i; 1..100)
		{
//			gcdump_userData = i;
			prj.addAndParseFile(fname);
		}
		return 0;
	}
}
else // !version(TESTMAIN)
{
} // !version(D_Version2)

extern extern(C) __gshared ModuleInfo D4core3sys7windows10stacktrace12__ModuleInfoZ;

void disableStacktrace()
{
	ModuleInfo* info = &D4core3sys7windows10stacktrace12__ModuleInfoZ;
static if(__traits(compiles,info.isNew))
{
	// dmd 2.063
	if (info.isNew)
	{
		enum
		{
			MItlsctor    = 8,
			MItlsdtor    = 0x10,
			MIctor       = 0x20,
			MIdtor       = 0x40,
			MIxgetMembers = 0x80,
		}
		if (info.n.flags & MIctor)
		{
			size_t off = info.New.sizeof;
			if (info.n.flags & MItlsctor)
				off += info.o.tlsctor.sizeof;
			if (info.n.flags & MItlsdtor)
				off += info.o.tlsdtor.sizeof;
			if (info.n.flags & MIxgetMembers)
				off += info.o.xgetMembers.sizeof;
			*cast(typeof(info.o.ctor)*)(cast(void*)info + off) = null;
		}
	}
	else
		info.o.ctor = null;
}
else 
{
	// dmd 2.064alpha
	enum
	{
		MItlsctor    = 8,
		MItlsdtor    = 0x10,
		MIctor       = 0x20,
		MIdtor       = 0x40,
		MIxgetMembers = 0x80,
	}
	if (info.flags & MIctor)
	{
		size_t off = info.sizeof;
		if (info.flags & MItlsctor)
			off += info.tlsctor.sizeof;
		if (info.flags & MItlsdtor)
			off += info.tlsdtor.sizeof;
		if (info.flags & MIxgetMembers)
			off += info.xgetMembers.sizeof;
		*cast(typeof(info.ctor)*)(cast(void*)info + off) = null;
	}
}
}

void clearStack()
{
	// fill stack with zeroes, so the chance of having false pointers is reduced
	int[1000] arr;
}

version(MAIN) {} else version(TESTMAIN) {} else
extern (Windows)
BOOL DllMain(stdwin.HINSTANCE hInstance, ULONG ulReason, LPVOID pvReserved)
{
	switch (ulReason)
	{
		case DLL_PROCESS_ATTACH:
			//MessageBoxA(cast(HANDLE)0, "Hi", "there", 0);
			disableStacktrace();
			if(!dll_process_attach(hInstance, true))
				return false;
			g_hInst = cast(HINSTANCE) hInstance;
//	GC.disable();
			global_init();

			logCall("DllMain(DLL_PROCESS_ATTACH, tid=%x)", GetCurrentThreadId());
			break;

		case DLL_PROCESS_DETACH:
			logCall("DllMain(DLL_PROCESS_DETACH, tid=%x)", GetCurrentThreadId());
			global_exit();
			debug clearStack();
			debug GC.collect();
			debug DComObject.showCOMleaks();
			dll_process_detach(hInstance, true);

			debug if(DComObject.sCountReferenced != 0 || DComObject.sCountInstances != 0)
				asm { int 3; } // use continue, not terminate in the debugger
			break;

		case DLL_THREAD_ATTACH:
			if(!dll_thread_attach(true, true))
				return false;
			logCall("DllMain(DLL_THREAD_ATTACH, id=%x)", GetCurrentThreadId());
			break;

		case DLL_THREAD_DETACH:
			if(threadaux.GetTlsDataAddress(GetCurrentThreadId())) //, _tls_index))
				logCall("DllMain(DLL_THREAD_DETACH, id=%x)", GetCurrentThreadId());
			dll_thread_detach(true, true);
			break;
			
		default:
			assert(_false);
			return false;
	
	}
	return true;
}

extern (Windows)
void RunDLLRegister(HWND hwnd, HINSTANCE hinst, LPSTR lpszCmdLine, int nCmdShow)
{
	wstring ws = to_wstring(lpszCmdLine) ~ cast(wchar)0;
	VSDllRegisterServer(ws.ptr);
}

extern (Windows)
void RunDLLUnregister(HWND hwnd, HINSTANCE hinst, LPSTR lpszCmdLine, int nCmdShow)
{
	wstring ws = to_wstring(lpszCmdLine) ~ cast(wchar)0;
	VSDllUnregisterServer(ws.ptr);
}

extern (Windows)
void RunDLLRegisterUser(HWND hwnd, HINSTANCE hinst, LPSTR lpszCmdLine, int nCmdShow)
{
	wstring ws = to_wstring(lpszCmdLine) ~ cast(wchar)0;
	VSDllRegisterServerUser(ws.ptr);
}

extern (Windows)
void RunDLLUnregisterUser(HWND hwnd, HINSTANCE hinst, LPSTR lpszCmdLine, int nCmdShow)
{
	wstring ws = to_wstring(lpszCmdLine) ~ cast(wchar)0;
	VSDllUnregisterServerUser(ws.ptr);
}

extern(Windows)
void VerifyMSObj(HWND hwnd, HINSTANCE hinst, LPSTR lpszCmdLine, int nCmdShow)
{
	wstring ws = to_wstring(lpszCmdLine);
	VerifyMSObjectParser(ws);
}

extern(Windows)
void WritePackageDef(HWND hwnd, HINSTANCE hinst, LPSTR lpszCmdLine, int nCmdShow)
{
	wstring ws = to_wstring(lpszCmdLine) ~ cast(wchar)0;
	WriteExtensionPackageDefinition(ws.ptr);
}

///////////////////////////////////////////////////////////////////////
// only the first export has a '_' prefix
//extern(C) export void dummy () { }

