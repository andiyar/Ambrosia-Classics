// Decompilation of Aki12_i386 (842 functions)

// ==== entry @ 00002760 ====

void entry(void)

{
  __start();
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== __start @ 0000278a ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __start(undefined4 param_1,undefined4 *param_2,int *param_3)

{
  int *piVar1;
  int iVar2;
  char *pcVar3;
  code *local_24;
  void *local_20 [4];
  
  __NXArgc = param_1;
  __NXArgv = param_2;
  __environ = param_3;
  ____progname = (char *)*param_2;
  pcVar3 = ____progname;
  piVar1 = param_3;
  if (____progname == (char *)0x0) {
    ____progname = "";
  }
  else {
    while (*pcVar3 != '\0') {
      if (*pcVar3 == '/') {
        ____progname = pcVar3 + 1;
        pcVar3 = ____progname;
      }
      else {
        pcVar3 = pcVar3 + 1;
      }
    }
  }
  for (; *piVar1 != 0; piVar1 = piVar1 + 1) {
  }
  if (*(code **)PTR_00038000 != (code *)0x0) {
    (**(code **)PTR_00038000)();
  }
  if (*(code **)PTR_00038008 != (code *)0x0) {
    (**(code **)PTR_00038008)();
  }
  ___keymgr_dwarf2_register_sections();
  __dyld_func_lookup("__dyld_make_delayed_module_initializer_calls",&local_24);
  (*local_24)();
  __dyld_func_lookup("__dyld_mod_term_funcs",local_20);
  if (local_20[0] != (void *)0x0) {
    _atexit(local_20[0]);
  }
  *(undefined4 *)PTR_00038004 = 0;
  iVar2 = _main(param_1,param_2,param_3,piVar1 + 1);
                    /* WARNING: Subroutine does not return */
  _exit(iVar2);
}


// ==== __dyld_func_lookup @ 00002878 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __dyld_func_lookup(void)

{
                    /* WARNING: Could not recover jumptable at 0x00002878. Too many branches */
                    /* WARNING: Treating indirect jump as call */
  (*_DAT_0003416c)();
  return;
}


// ==== _main @ 0000287e ====

void _main(void)

{
  _NSApplicationMain();
  return;
}


// ==== -[Controller_dealloc] @ 00002891 ====

void __Controller_dealloc_(int param_1)

{
  int local_14;
  undefined *local_10;
  
  _objc_msgSend(*(undefined4 *)(param_1 + 0x10),PTR_s_release_00036000);
  _objc_msgSend(*(undefined4 *)(param_1 + 0x14),PTR_s_release_00036000);
  _objc_msgSend(*(undefined4 *)(param_1 + 0x18),PTR_s_release_00036000);
  _objc_msgSend(*(undefined4 *)(param_1 + 0x1c),PTR_s_release_00036000);
  _objc_msgSend(*(undefined4 *)(param_1 + 0x20),PTR_s_release_00036000);
  local_14 = param_1;
  local_10 = PTR_s_NSObject_00036304;
  _objc_msgSendSuper(&local_14,PTR_s_dealloc_00036004);
  return;
}


// ==== -[Controller_awakeFromNib] @ 00002924 ====

void __Controller_awakeFromNib_(undefined4 param_1)

{
  uint uVar1;
  
  __sharedController = param_1;
  uVar1 = _time((time_t *)0x0);
  _srandom(uVar1);
  _Initialize();
  _RedrawMapScreen();
  return;
}


// ==== -[Controller_applicationDidFinishLaunching:] @ 00002951 ====

void __Controller_applicationDidFinishLaunching__(int param_1)

{
  undefined *puVar1;
  char cVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  int iVar5;
  undefined8 uVar6;
  
  uVar3 = _objc_msgSend(PTR_s_NSUserDefaults_000362a4,PTR_s_standardUserDefaults_00036008);
  _objc_msgSend(uVar3,PTR_s_setBool_forKey__0003600c,0,*(undefined4 *)PTR_0003801c);
  uVar3 = _objc_msgSend(PTR_s_NSNotificationCenter_000362a0,PTR_s_defaultCenter_00036010);
  _objc_msgSend(uVar3,PTR_s_addObserver_selector_name_object_00036018,param_1,
                PTR_s_updaterWillDisplay__00036014,*(undefined4 *)PTR_00038010,0);
  uVar3 = _objc_msgSend(PTR_s_SUUpdater_0003629c,PTR_s_alloc_0003601c);
  uVar3 = _objc_msgSend(uVar3,PTR_s_init_00036020);
  *(undefined4 *)(param_1 + 0x10) = uVar3;
  _objc_msgSend(uVar3,PTR_s_setModal__00036024,1);
  uVar4 = _objc_msgSend(PTR_s_NSUserDefaults_000362a4,PTR_s_standardUserDefaults_00036008);
  puVar1 = PTR_00038018;
  uVar3 = *(undefined4 *)PTR_00038018;
  iVar5 = _objc_msgSend(uVar4,PTR_s_objectForKey__00036028,uVar3);
  if (iVar5 == 0) {
    iVar5 = _SUInfoValueForKey(*(undefined4 *)puVar1);
    if (iVar5 == 0) {
      *(undefined1 *)(param_1 + 0xc) = 1;
      _objc_msgSend(*(undefined4 *)(param_1 + 0x10),PTR_s_performSelector__00036030,
                    PTR_s_showUserChoicePanel_0003602c);
      uVar3 = 0;
      _objc_msgSend(*(undefined4 *)(param_1 + 0x10),PTR_s_setModal__00036024,0);
    }
  }
  if (*(char *)(param_1 + 0xc) == '\0') {
    uVar4 = _objc_msgSend(PTR_s_NSUserDefaults_000362a4,PTR_s_standardUserDefaults_00036008,uVar3);
    uVar3 = *(undefined4 *)PTR_00038018;
    uVar4 = _objc_msgSend(uVar4,PTR_s_objectForKey__00036028,uVar3);
    cVar2 = _objc_msgSend(uVar4,PTR_s_boolValue_00036034);
    if (cVar2 != '\0') {
      _objc_msgSend(*(undefined4 *)(param_1 + 0x10),PTR_s_checkForUpdatesInBackground_00036038,uVar3
                   );
    }
  }
  iVar5 = _RT3_Open(1,0x8003,"Aki","Aki");
  if (iVar5 == 0) {
    iVar5 = _RT3_IsRegistered();
    if (iVar5 == 0) {
      uVar3 = _objc_msgSend(PTR_s_ASWRegistration_00036298,PTR_s_sharedRegistration_0003603c);
      _objc_msgSend(uVar3,PTR_s_runModal_00036040);
    }
  }
  puVar1 = PTR__g_00034014;
  iVar5 = *(int *)(PTR__g_00034014 + 0x54);
  uVar6 = _RT3_GetLicenseCode();
  *(undefined8 *)(iVar5 + 0x10c) = uVar6;
  iVar5 = *(int *)(puVar1 + 0x58);
  uVar3 = _RT3_GetLicenseCopies();
  *(undefined4 *)(iVar5 + 0x10c) = uVar3;
  uVar3 = _RT3_GetLicenseName();
  *(undefined4 *)(puVar1 + 0x44) = uVar3;
  _LoopMusic(1);
  _PlayMovie(0x80);
  _objc_msgSend(*(undefined4 *)(param_1 + 4),PTR_s_center_00036044);
  uVar3 = _TickCount();
  *(undefined4 *)(param_1 + 0x34) = uVar3;
  uVar3 = _TickCount();
  *(undefined4 *)(param_1 + 0x38) = uVar3;
  uVar3 = _TickCount();
  *(undefined4 *)(param_1 + 0x3c) = uVar3;
  uVar3 = _TickCount();
  *(undefined4 *)(param_1 + 0x44) = uVar3;
  uVar3 = _TickCount();
  *(undefined1 *)(param_1 + 0x4c) = 0;
  *(undefined4 *)(param_1 + 0x48) = 0;
  *(undefined1 *)(param_1 + 0x4d) = 1;
  *(undefined2 *)(param_1 + 0x4e) = 0xfff7;
  *(undefined4 *)(param_1 + 0x40) = uVar3;
  uVar3 = _objc_msgSend(PTR_s_NSTimer_00036294,PTR_s_scheduledTimerWithTimeInterval_t_0003604c,
                        0x9999999a,0x3fa99999,param_1,PTR_s_idleTimerFired__00036048,0,1);
  *(undefined4 *)(param_1 + 0x30) = uVar3;
  uVar3 = _objc_msgSend(PTR_s_NSRunLoop_00036290,PTR_s_currentRunLoop_00036050);
  _objc_msgSend(uVar3,PTR_s_addTimer_forMode__00036054,*(undefined4 *)(param_1 + 0x30),
                *(undefined4 *)PTR_00038020);
  uVar3 = _objc_msgSend(PTR_s_NSRunLoop_00036290,PTR_s_currentRunLoop_00036050);
  _objc_msgSend(uVar3,PTR_s_addTimer_forMode__00036054,*(undefined4 *)(param_1 + 0x30),
                *(undefined4 *)PTR_0003800c);
  _objc_msgSend(param_1,PTR_s_performSelector_withObject_after_0003605c,PTR_s_finishLaunch__00036058
                ,0,0,0x3fe00000);
  return;
}


// ==== -[Controller_applicationShouldTerminate:] @ 00002cf7 ====

bool __Controller_applicationShouldTerminate__(undefined4 param_1)

{
  undefined *puVar1;
  char cVar2;
  int iVar3;
  
  puVar1 = PTR__g_00034014;
  if (PTR__g_00034014[0x66] == '\0') {
    if (PTR__g_00034014[0x80] == '\0') {
      return true;
    }
  }
  else if (PTR__g_00034014[0x80] == '\0') {
    cVar2 = _objc_msgSend(param_1,PTR_s_abortGame_00036060);
    return cVar2 != '\0';
  }
  if (PTR__g_00034014[0x1f0] != '\0') {
    iVar3 = _RunModalSaveAlert();
    if (iVar3 == -1) {
      return false;
    }
    if (iVar3 == 1) {
      cVar2 = _DoSaveAs();
      if (cVar2 == '\0') {
        return false;
      }
      if (puVar1[0x228] != '\0') {
        _CreateNewDialog(0x50);
      }
    }
  }
  return true;
}


// ==== -[Controller_applicationWillTerminate:] @ 00002d7d ====

void __Controller_applicationWillTerminate__(int param_1)

{
  char cVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  
  if (*(short *)(PTR__p_00034010 + 0x20e) % 2 != 1) {
    *(undefined4 *)(PTR__g_00034014 + 0xcc) = 0;
    cVar1 = _objc_msgSend(param_1,PTR_s_isFullscreen_00036064);
    if (cVar1 == '\0') {
      _objc_msgSend(*(undefined4 *)(param_1 + 4),PTR_s_setContentView__00036068,
                    *(undefined4 *)(param_1 + 8));
      _objc_msgSend(*(undefined4 *)(param_1 + 4),PTR_s_makeFirstResponder__0003606c,
                    *(undefined4 *)(param_1 + 8));
      uVar3 = *(undefined4 *)PTR_00038014;
      uVar2 = *(undefined4 *)(param_1 + 4);
    }
    else {
      _objc_msgSend(*(undefined4 *)(param_1 + 0x24),PTR_s_setContentView__00036068,
                    *(undefined4 *)(param_1 + 8));
      _objc_msgSend(*(undefined4 *)(param_1 + 0x24),PTR_s_makeFirstResponder__0003606c,
                    *(undefined4 *)(param_1 + 8));
      _objc_msgSend(*(undefined4 *)(param_1 + 0x24),PTR_s_scheduleSetShieldingLevelNoCente_00036070)
      ;
      uVar3 = *(undefined4 *)PTR_00038014;
      uVar2 = *(undefined4 *)(param_1 + 0x24);
    }
    _objc_msgSend(uVar3,PTR_s_runModalForWindow__00036074,uVar2);
  }
  _objc_msgSend(*(undefined4 *)(param_1 + 0x30),PTR_s_invalidate_00036078);
  _ExitMovies();
  _RT3_Close();
  _FT_Close();
  cVar1 = _objc_msgSend(param_1,PTR_s_isFullscreen_00036064);
  if (cVar1 != '\0') {
    _objc_msgSend();
    return;
  }
  return;
}


// ==== -[Controller_applicationWillResignActive:] @ 00002ecb ====

void __Controller_applicationWillResignActive__(void)

{
  undefined1 uVar1;
  undefined *puVar2;
  
  puVar2 = PTR__g_00034014;
  uVar1 = PTR__g_00034014[0x67];
  PTR__g_00034014[0x67] = 1;
  _PlayMovie(0x80);
  puVar2[0x67] = uVar1;
  return;
}


// ==== -[Controller_applicationDidBecomeActive:] @ 00002efe ====

void __Controller_applicationDidBecomeActive__(int param_1)

{
  int iVar1;
  undefined *puVar2;
  undefined4 uVar3;
  undefined8 uVar4;
  
  if (*(char *)(param_1 + 0xe) != '\0') {
    _RT3_Idle();
    puVar2 = PTR__g_00034014;
    iVar1 = *(int *)(PTR__g_00034014 + 0x54);
    uVar4 = _RT3_GetLicenseCode();
    *(undefined8 *)(iVar1 + 0x10c) = uVar4;
    iVar1 = *(int *)(puVar2 + 0x58);
    uVar3 = _RT3_GetLicenseCopies();
    *(undefined4 *)(iVar1 + 0x10c) = uVar3;
    uVar3 = _RT3_GetLicenseName();
    *(undefined4 *)(puVar2 + 0x44) = uVar3;
    if ((puVar2[0x66] == '\0') || (puVar2[0x85] == '\0')) {
      _LoopMusic(1);
      _PlayMovie();
      return;
    }
  }
  return;
}


// ==== -[Controller_applicationShouldTerminateAfterLastWindowClosed:] @ 00002f7e ====

undefined4 __Controller_applicationShouldTerminateAfterLastWindowClosed__(int param_1)

{
  undefined4 uVar1;
  
  if ((*(char *)(param_1 + 0xe) == '\0') || (uVar1 = 1, *(char *)(param_1 + 0x2c) != '\0')) {
    uVar1 = 0;
  }
  return uVar1;
}


// ==== -[Controller_application:openFile:] @ 00002f99 ====

undefined4
__Controller_application_openFile__
          (undefined4 param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4)

{
  _objc_msgSend(param_1,PTR_s_performSelector_withObject_after_0003605c,PTR_s_openFile__00036080,
                param_4,0,0);
  return 1;
}


// ==== -[Controller_openFile:] @ 00002fda ====

void __Controller_openFile__(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  undefined *puVar1;
  char cVar2;
  undefined4 uVar3;
  undefined1 local_52 [70];
  
  if ((PTR__g_00034014[0x66] != '\0') && (PTR__g_00034014[0x80] != '\0')) {
    *(undefined4 *)(PTR__g_00034014 + 0xd0) = 0;
    cVar2 = _objc_msgSend(param_1,PTR_s_exitLevelEditor_00036084);
    if (cVar2 == '\0') {
      return;
    }
  }
  uVar3 = _objc_msgSend(param_3,PTR_s_UTF8String_00036088);
  _POSIXPathToFSSpec(uVar3,local_52);
  puVar1 = PTR__g_00034014;
  _FT_PathCreateFromMacFSSpec(local_52,PTR__g_00034014 + 0xd0,PTR__g_00034014 + 0xd8);
  if (*(short *)(PTR__p_00034010 + 0x20e) % 2 == 1) {
    if (puVar1[0x66] != '\0') {
      _CreateNewDialog(0x57);
      if (puVar1[0x81] != '\x01') {
        return;
      }
      puVar1[0x81] = 0;
      _TriggerGameToMap();
    }
    _LoadCustomLevel();
  }
  else {
    _CreateNewDialog(0x55);
  }
  return;
}


// ==== -[Controller_windowDidResignMain:] @ 000030c0 ====

void __Controller_windowDidResignMain__(int param_1)

{
  if ((*(char *)(param_1 + 0x2c) == '\0') && (PTR__g_00034014[0x67] == '\0')) {
    _objc_msgSend(param_1,PTR_s_pause_0003608c);
    *(undefined1 *)(param_1 + 0x2d) = 1;
  }
  return;
}


// ==== -[Controller_windowDidBecomeMain:] @ 000030f6 ====

void __Controller_windowDidBecomeMain__(int param_1)

{
  undefined *puVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  
  uVar3 = 0;
  uVar4 = 0;
  uVar2 = 0;
  puVar1 = PTR_s__redrawWindow_00036090;
  _objc_msgSend(param_1,PTR_s_performSelector_withObject_after_0003605c,PTR_s__redrawWindow_00036090
                ,0,0,0);
  if (*(char *)(param_1 + 0x2d) != '\0') {
    _objc_msgSend(param_1,PTR_s_unpause_00036094,puVar1,uVar2,uVar3,uVar4);
    *(undefined1 *)(param_1 + 0x2d) = 0;
  }
  return;
}


// ==== -[Controller_windowShouldClose:] @ 00003153 ====

undefined4 __Controller_windowShouldClose__(void)

{
  undefined *puVar1;
  char cVar2;
  int iVar3;
  
  puVar1 = PTR__g_00034014;
  if (((PTR__g_00034014[0x66] != '\0') && (PTR__g_00034014[0x80] != '\0')) &&
     (PTR__g_00034014[0x1f0] != '\0')) {
    iVar3 = _RunModalSaveAlert();
    if (iVar3 == 0) {
      puVar1[0x1f0] = 0;
    }
    else if (iVar3 == 1) {
      cVar2 = _DoSaveAs();
      if (cVar2 == '\0') {
        return 0;
      }
      if (puVar1[0x228] != '\0') {
        _CreateNewDialog(0x50);
      }
    }
    else if (iVar3 == -1) {
      return 0;
    }
  }
  return 1;
}


// ==== -[Controller_checkForUpdates:] @ 000031c1 ====

void __Controller_checkForUpdates__(void)

{
  undefined *puStack00000008;
  
  puStack00000008 = PTR_s_checkForUpdates__00036098;
  _objc_msgSend();
  return;
}


// ==== -[Controller_gameMenuAction:] @ 000031db ====

void __Controller_gameMenuAction__(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  _objc_msgSend(param_3,PTR_s_tag_0003609c);
  _HandleMenuCommand();
  return;
}


// ==== -[Controller_performClose:] @ 000031fe ====

void __Controller_performClose__(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  undefined *puVar1;
  char cVar2;
  undefined4 uVar3;
  undefined *puVar4;
  
  puVar1 = PTR_00038014;
  uVar3 = _objc_msgSend(*(undefined4 *)PTR_00038014,PTR_s_keyWindow_000360a0);
  puVar4 = PTR_s_performClose__000360a4;
  cVar2 = _objc_msgSend(uVar3,PTR_s_respondsToSelector__000360a8,PTR_s_performClose__000360a4);
  if (cVar2 != '\0') {
    uVar3 = _objc_msgSend(*(undefined4 *)puVar1,PTR_s_keyWindow_000360a0,puVar4);
    _objc_msgSend(uVar3,PTR_s_performSelector_withObject__000360ac,PTR_s_performClose__000360a4,
                  param_3);
  }
  return;
}


// ==== -[Controller_showAboutBox:] @ 0000327a ====

void __Controller_showAboutBox__(int param_1)

{
  undefined4 uVar1;
  
  if (*(int *)(param_1 + 0x14) == 0) {
    uVar1 = _objc_msgSend(PTR_s_ASWAboutBox_0003628c,PTR_s_sharedAboutBox_000360b0);
    *(undefined4 *)(param_1 + 0x14) = uVar1;
  }
  _objc_msgSend();
  return;
}


// ==== -[Controller_showAcknowledgements:] @ 000032bc ====

void __Controller_showAcknowledgements__(int param_1)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  if (*(int *)(param_1 + 0x18) == 0) {
    uVar1 = _objc_msgSend(PTR_s_ASWTextViewer_00036288,PTR_s_alloc_0003601c);
    uVar2 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
    uVar2 = _objc_msgSend(uVar2,PTR_s_pathForResource_ofType__000360bc,&cf_Acknowledgements,&cf_rtf)
    ;
    uVar1 = _objc_msgSend(uVar1,PTR_s_initWithPath__000360c0,uVar2);
    *(undefined4 *)(param_1 + 0x18) = uVar1;
    uVar2 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
    uVar2 = _objc_msgSend(uVar2,PTR_s_localizedStringForKey_value_tabl_000360c4,
                          &cf_AkiAcknowledgements,&cf___,0);
    _objc_msgSend(uVar1,PTR_s_setTitle__000360c8,uVar2);
  }
  _objc_msgSend();
  return;
}


// ==== -[Controller_showHandbook:] @ 000033b2 ====

void __Controller_showHandbook__(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  uVar1 = _objc_msgSend(PTR_s_NSWorkspace_00036280,PTR_s_sharedWorkspace_000360d0);
  uVar2 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
  uVar2 = _objc_msgSend(uVar2,PTR_s_pathForResource_ofType__000360bc,&cf_AkiHandbook,&cf_pdf);
  _objc_msgSend(uVar1,PTR_s_openFile_withApplication__000360d4,uVar2,&cf_Preview);
  return;
}


// ==== -[Controller_showHelp:] @ 0000342c ====

void __Controller_showHelp__(void)

{
  char *pcStack00000004;
  undefined4 uStack00000008;
  
  uStack00000008 = 0;
  pcStack00000004 = "guide";
  _SplashScreen();
  return;
}


// ==== -[Controller_showPreferences:] @ 00003443 ====

void __Controller_showPreferences__(int param_1)

{
  char cVar1;
  undefined4 uVar2;
  
  if (*(int *)(param_1 + 0x20) == 0) {
    uVar2 = _objc_msgSend(PTR_s_Preferences_0003627c,PTR_s_alloc_0003601c);
    uVar2 = _objc_msgSend(uVar2,PTR_s_init_00036020);
    *(undefined4 *)(param_1 + 0x20) = uVar2;
  }
  cVar1 = _objc_msgSend(param_1,PTR_s_isFullscreen_00036064);
  if (cVar1 != '\0') {
    _objc_msgSend(*(undefined4 *)(param_1 + 0x20),PTR_s_runModal_00036040);
    _objc_msgSend();
    return;
  }
  _objc_msgSend(param_1,PTR_s_pause_0003608c);
  _objc_msgSend(*(undefined4 *)(param_1 + 0x20),PTR_s_beginSheetModalForWindow_modalDe_000360e0,
                *(undefined4 *)(param_1 + 4),param_1,PTR_s_preferencesSheetDidEnd_returnCod_000360dc
                ,0);
  return;
}


// ==== -[Controller_showRegistration:] @ 0000350e ====

void __Controller_showRegistration__(undefined4 param_1)

{
  char cVar1;
  undefined4 uVar2;
  
  cVar1 = _objc_msgSend(param_1,PTR_s_isFullscreen_00036064);
  if (cVar1 != '\0') {
    _objc_msgSend(param_1,PTR_s__exitFullscreen_0003607c);
  }
  uVar2 = _objc_msgSend(PTR_s_ASWRegistration_00036298,PTR_s_sharedRegistration_0003603c);
  _objc_msgSend(uVar2,PTR_s_performSelector_withObject_after_0003605c,
                PTR_s_runWithoutCountDown_000360e4,0,0,0);
  return;
}


// ==== -[Controller_showReleaseNotes:] @ 0000358e ====

void __Controller_showReleaseNotes__(int param_1)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  if (*(int *)(param_1 + 0x1c) == 0) {
    uVar1 = _objc_msgSend(PTR_s_ASWTextViewer_00036288,PTR_s_alloc_0003601c);
    uVar2 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
    uVar2 = _objc_msgSend(uVar2,PTR_s_pathForResource_ofType__000360bc,&cf_ReleaseNotes,&cf_rtf);
    uVar1 = _objc_msgSend(uVar1,PTR_s_initWithPath__000360c0,uVar2);
    *(undefined4 *)(param_1 + 0x1c) = uVar1;
    uVar2 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
    uVar2 = _objc_msgSend(uVar2,PTR_s_localizedStringForKey_value_tabl_000360c4,&cf_AkiReleaseNotes,
                          &cf___,0);
    _objc_msgSend(uVar1,PTR_s_setTitle__000360c8,uVar2);
  }
  _objc_msgSend();
  return;
}


// ==== -[Controller_toggleFullscreen:] @ 00003684 ====

void __Controller_toggleFullscreen__(undefined4 param_1)

{
  char cVar1;
  
  cVar1 = _objc_msgSend(param_1,PTR_s_isFullscreen_00036064);
  if (cVar1 == '\0') {
    _objc_msgSend(param_1,PTR_s__enterFullscreen_000360e8);
    PTR__p_00034010[0x212] = 1;
  }
  else {
    _objc_msgSend(param_1,PTR_s__exitFullscreen_0003607c);
    PTR__p_00034010[0x212] = 0;
  }
  _SavePrefs();
  return;
}


// ==== -[Controller_isFullscreen] @ 000036ec ====

undefined1 __Controller_isFullscreen_(int param_1)

{
  return *(undefined1 *)(param_1 + 0x2c);
}


// ==== -[Controller__enterFullscreen] @ 000036f8 ====

void __Controller__enterFullscreen_(undefined4 *param_1)

{
  char cVar1;
  undefined4 uVar2;
  int iVar3;
  undefined4 *puVar4;
  undefined4 **ppuVar5;
  undefined4 *local_90;
  undefined4 *local_8c;
  undefined4 **local_88;
  cfstringStruct *local_84;
  undefined4 local_80;
  float local_7c;
  undefined4 local_78;
  undefined4 local_74;
  undefined4 local_70;
  undefined4 local_5c;
  float local_58;
  undefined4 local_54;
  float local_50;
  undefined4 local_40;
  float local_3c;
  undefined4 local_38;
  float local_34;
  undefined4 local_30;
  float local_2c;
  undefined4 local_28;
  float local_24;
  undefined4 *local_20 [4];
  
  ppuVar5 = &local_8c;
  local_8c = param_1;
  local_88 = (undefined4 **)PTR_s_isFullscreen_00036064;
  local_90 = (undefined4 *)0x3715;
  cVar1 = _objc_msgSend();
  if (cVar1 != '\0') {
    return;
  }
  local_90 = (undefined4 *)0x3722;
  local_8c = (undefined4 *)_CGMainDisplayID();
  local_90 = (undefined4 *)0x372a;
  local_8c = (undefined4 *)_CGDisplayCurrentMode();
  param_1[10] = local_8c;
  local_84 = &cf_BitsPerPixel;
  local_88 = (undefined4 **)PTR_s_objectForKey__00036028;
  local_90 = (undefined4 *)0x3747;
  local_8c = (undefined4 *)_objc_msgSend();
  local_88 = (undefined4 **)PTR_s_intValue_000360ec;
  local_90 = (undefined4 *)0x3759;
  uVar2 = _objc_msgSend();
  local_90 = (undefined4 *)0x3760;
  local_8c = (undefined4 *)_CGMainDisplayID();
  local_7c = 0.0;
  local_80 = 600;
  local_84 = (cfstringStruct *)0x320;
  local_90 = (undefined4 *)0x3786;
  local_88 = (undefined4 **)uVar2;
  uVar2 = _CGDisplayBestModeForParameters();
  *(undefined1 *)(param_1 + 0xb) = 1;
  local_8c = (undefined4 *)0x40a00000;
  local_88 = local_20;
  local_90 = (undefined4 *)0x379f;
  _CGAcquireDisplayFadeReservation();
  local_70 = 1;
  local_74 = 0;
  local_78 = 0;
  local_7c = 0.0;
  local_80 = 0x3f800000;
  local_84 = (cfstringStruct *)0x0;
  local_88 = (undefined4 **)0x3e800000;
  local_8c = local_20[0];
  local_90 = (undefined4 *)0x37d2;
  _CGDisplayFade();
  local_90 = (undefined4 *)0x37d7;
  iVar3 = _CGCaptureAllDisplays();
  if (iVar3 == 0) {
    local_8c = (undefined4 *)param_1[1];
    local_84 = (cfstringStruct *)0x0;
    local_88 = (undefined4 **)PTR_s_orderOut__000360f0;
    local_90 = (undefined4 *)0x37fb;
    _objc_msgSend();
    local_90 = (undefined4 *)0x3800;
    local_8c = (undefined4 *)_CGMainDisplayID();
    local_90 = (undefined4 *)0x380c;
    local_88 = (undefined4 **)uVar2;
    iVar3 = _CGDisplaySwitchToMode();
    if (iVar3 == 0) {
      local_88 = (undefined4 **)PTR_s_mainScreen_000360f4;
      local_8c = (undefined4 *)PTR_s_NSScreen_00036278;
      local_90 = (undefined4 *)0x382a;
      local_88 = (undefined4 **)_objc_msgSend();
      local_8c = &local_5c;
      local_84 = (cfstringStruct *)PTR_s_frame_000360f8;
      local_90 = (undefined4 *)0x3843;
      _objc_msgSend_stret();
      local_40 = local_5c;
      ppuVar5 = &local_90;
      local_3c = local_58;
      local_38 = local_54;
      local_34 = local_50;
      local_8c = (undefined4 *)PTR_s_alloc_0003601c;
      local_90 = (undefined4 *)PTR_s_AkiFullscreenWindow_00036274;
      local_90 = (undefined4 *)_objc_msgSend();
      local_30 = 0;
      local_28 = 0x44480000;
      local_24 = FLOAT_00033b1c;
      local_84 = (cfstringStruct *)((local_3c + local_34) - FLOAT_00033b1c);
      local_88 = (undefined4 **)0x0;
      local_70 = 0;
      local_74 = 2;
      local_78 = 0;
      local_80 = 0x44480000;
      local_7c = FLOAT_00033b1c;
      local_8c = (undefined4 *)PTR_s_initWithContentRect_styleMask_ba_000360fc;
      local_2c = (float)local_84;
      puVar4 = (undefined4 *)_objc_msgSend();
      param_1[9] = puVar4;
      local_8c = (undefined4 *)PTR_s_alloc_0003601c;
      local_90 = (undefined4 *)PTR_s_AkiView_00036270;
      local_90 = (undefined4 *)_objc_msgSend();
      local_8c = (undefined4 *)PTR_s_init_00036020;
      local_90 = (undefined4 *)_objc_msgSend();
      local_8c = (undefined4 *)PTR_s_autorelease_00036100;
      local_88 = (undefined4 **)_objc_msgSend();
      local_8c = (undefined4 *)PTR_s_setContentView__00036068;
      local_90 = puVar4;
      _objc_msgSend();
      local_90 = (undefined4 *)param_1[9];
      local_88 = (undefined4 **)0x0;
      local_8c = (undefined4 *)PTR_s_makeKeyAndOrderFront__000360d8;
      _objc_msgSend();
      local_90 = (undefined4 *)param_1[9];
      local_8c = (undefined4 *)PTR_s_windowRef_00036104;
      uVar2 = _objc_msgSend();
      *(undefined4 *)(PTR__g_00034014 + 0xcc) = uVar2;
      local_90 = param_1;
      local_8c = (undefined4 *)PTR_s__redrawWindow_00036090;
      _objc_msgSend();
      puVar4 = (undefined4 *)param_1[9];
      local_88 = (undefined4 **)_CGShieldingWindowLevel();
      local_8c = (undefined4 *)PTR_s_setLevel__00036108;
      local_90 = puVar4;
      goto LAB_0000399d;
    }
  }
  local_8c = (undefined4 *)param_1[1];
  local_84 = (cfstringStruct *)0x0;
  local_88 = (undefined4 **)PTR_s_makeKeyAndOrderFront__000360d8;
LAB_0000399d:
  ppuVar5[-1] = (undefined4 *)0x39a2;
  _objc_msgSend();
  ppuVar5[6] = (undefined4 *)0x0;
  ppuVar5[5] = (undefined4 *)0x0;
  ppuVar5[4] = (undefined4 *)0x0;
  ppuVar5[3] = (undefined4 *)0x0;
  ppuVar5[7] = (undefined4 *)0x0;
  ppuVar5[2] = (undefined4 *)0x3f800000;
  ppuVar5[1] = (undefined4 *)0x3f000000;
  *ppuVar5 = local_20[0];
  ppuVar5[-1] = (undefined4 *)0x39d7;
  _CGDisplayFade();
  *ppuVar5 = local_20[0];
  ppuVar5[-1] = (undefined4 *)0x39e2;
  _CGReleaseDisplayFadeReservation();
  return;
}


// ==== -[Controller__exitFullscreen] @ 00003a05 ====

void __Controller__exitFullscreen_(int param_1)

{
  undefined4 uVar1;
  char cVar2;
  undefined4 uVar3;
  undefined4 local_20 [4];
  
  cVar2 = _objc_msgSend(param_1,PTR_s_isFullscreen_00036064);
  if (cVar2 != '\0') {
    _CGAcquireDisplayFadeReservation(0x40a00000,local_20);
    _objc_msgSend(*(undefined4 *)(param_1 + 0x24),PTR_s_orderOut__000360f0,0);
    _CGDisplayFade(local_20[0],0x3e800000,0,0x3f800000,0,0,0,1);
    _objc_msgSend(*(undefined4 *)(param_1 + 0x24),PTR_s_release_00036000);
    uVar1 = *(undefined4 *)(param_1 + 0x28);
    *(undefined4 *)(param_1 + 0x24) = 0;
    uVar3 = _CGMainDisplayID();
    _CGDisplaySwitchToMode(uVar3,uVar1);
    _CGReleaseAllDisplays();
    *(undefined4 *)(PTR__g_00034014 + 0xcc) = 0;
    _objc_msgSend(param_1,PTR_s_performSelector_withObject_after_0003605c,
                  PTR_s__finishExitFullscreen__0003610c,0,0,0);
    _CGDisplayFade(local_20[0],0x3e800000,0x3f800000,0,0,0,0,0);
    _CGReleaseDisplayFadeReservation(local_20[0]);
  }
  return;
}


// ==== -[Controller__finishExitFullscreen:] @ 00003b52 ====

void __Controller__finishExitFullscreen__(int param_1)

{
  undefined4 uVar1;
  undefined1 local_14 [12];
  
  _SetRect(local_14,0,0,800,600);
  uVar1 = _objc_msgSend(*(undefined4 *)(param_1 + 4),PTR_s_windowRef_00036104);
  *(undefined4 *)(PTR__g_00034014 + 0xcc) = uVar1;
  _objc_msgSend(*(undefined4 *)(param_1 + 4),PTR_s_makeKeyAndOrderFront__000360d8,0);
  _objc_msgSend(param_1,PTR_s__redrawWindow_00036090);
  *(undefined1 *)(param_1 + 0x2c) = 0;
  return;
}


// ==== -[Controller__redrawWindow] @ 00003bde ====

void __Controller__redrawWindow_(void)

{
  if (PTR__g_00034014[0x66] == '\0') {
    return;
  }
  if (PTR__g_00034014[0x80] != '\0') {
    _RedrawLevelEditorScreen(0);
    _DrawTempToWindow();
    return;
  }
  _RedrawCustomGameScreen();
  return;
}


// ==== -[Controller_pause] @ 00003c1f ====

void __Controller_pause_(void)

{
  undefined *puVar1;
  
  puVar1 = PTR__g_00034014;
  if ((PTR__g_00034014[0x80] == '\0' & PTR__g_00034014[0x66]) != 0) {
    if (*(int *)(PTR__g_00034014 + 0xb8) < 0x10) {
      _StopSound(100,0x80);
    }
    if (*(short *)(puVar1 + 0x60) != 0) {
      if (puVar1[0x67] == '\0') {
        _PauseGame();
        return;
      }
      puVar1[0x7f] = 1;
    }
  }
  return;
}


// ==== -[Controller_abortGame] @ 00003cbc ====

undefined4 __Controller_abortGame_(void)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined4 uVar3;
  undefined4 *puVar4;
  
  _CreateNewDialog(0x57);
  puVar2 = PTR__g_00034014;
  uVar3 = 0;
  if (PTR__g_00034014[0x81] == '\x01') {
    puVar4 = *(undefined4 **)(PTR__g_00034014 + 0x58);
    PTR__g_00034014[0x81] = 0;
    puVar2[0x68] = 1;
    for (; puVar1 = PTR__p_00034010, puVar4 != (undefined4 *)0x0;
        puVar4 = (undefined4 *)puVar4[0x42]) {
      if (*(short *)(puVar4 + 1) == *(short *)(puVar2 + 0x5c)) {
        _StopMovie(*puVar4);
      }
    }
    if (*(short *)(puVar2 + 0x90) < 0xc) {
      *(short *)(PTR__p_00034010 + *(short *)(puVar2 + 0x90) * 2 + 0x248) =
           *(short *)(PTR__p_00034010 + *(short *)(puVar2 + 0x90) * 2 + 0x248) + 1;
    }
    _SavePrefs(puVar1);
    uVar3 = 1;
  }
  return uVar3;
}


// ==== -[Controller_exitLevelEditor] @ 00003d4b ====

undefined4 __Controller_exitLevelEditor_(void)

{
  undefined *puVar1;
  undefined *puVar2;
  char cVar3;
  int iVar4;
  undefined4 *puVar5;
  
  puVar1 = PTR__g_00034014;
  if (PTR__g_00034014[0x1f0] != '\0') {
    iVar4 = _RunModalSaveAlert();
    if (iVar4 == -1) {
      return 0;
    }
    if (iVar4 == 1) {
      cVar3 = _DoSaveAs();
      if (cVar3 == '\0') {
        return 0;
      }
      if (puVar1[0x228] != '\0') {
        _CreateNewDialog(0x50);
      }
      *(undefined4 *)(puVar1 + 0xd0) = *(undefined4 *)(puVar1 + 0xd4);
    }
  }
  puVar2 = PTR__g_00034014;
  for (puVar5 = *(undefined4 **)(puVar1 + 0x58); puVar5 != (undefined4 *)0x0;
      puVar5 = (undefined4 *)puVar5[0x42]) {
    if (*(short *)(puVar5 + 1) == *(short *)(puVar2 + 0x5c)) {
      _StopMovie(*puVar5);
    }
  }
  _AnimationEditorScreenToMap();
  PTR__g_00034014[0x68] = 0;
  _DeleteAllTiles();
  return 1;
}


// ==== -[Controller_validateMenuItem:] @ 00003de5 ====

bool __Controller_validateMenuItem__(int param_1,undefined4 param_2,undefined4 param_3)

{
  short sVar1;
  int iVar2;
  undefined4 uVar3;
  undefined *puVar4;
  undefined *puVar5;
  uint uVar6;
  cfstringStruct *pcVar7;
  cfstringStruct *pcVar8;
  undefined4 uVar9;
  
  iVar2 = _objc_msgSend(param_3,PTR_s_tag_0003609c);
  if (iVar2 < 1) {
    puVar4 = (undefined *)_objc_msgSend(param_3,PTR_s_action_00036118);
    if ((puVar4 == PTR_s_showHelp__0003611c) &&
       (iVar2 = _objc_msgSend(*(undefined4 *)PTR_00038014,PTR_s_modalWindow_00036120), iVar2 != 0))
    {
      return false;
    }
    puVar5 = (undefined *)_objc_msgSend(param_3,PTR_s_action_00036118);
    puVar4 = PTR_00038014;
    if (puVar5 != PTR_s_performClose__000360a4) {
      return true;
    }
    iVar2 = _objc_msgSend(*(undefined4 *)PTR_00038014,PTR_s_keyWindow_000360a0);
    if (iVar2 == *(int *)(param_1 + 4)) {
      return false;
    }
    uVar3 = _objc_msgSend(*(undefined4 *)puVar4,PTR_s_keyWindow_000360a0);
    uVar6 = _objc_msgSend(uVar3,PTR_s_styleMask_00036124);
    if ((uVar6 & 2) == 0) {
      return false;
    }
    return true;
  }
  if (PTR__g_00034014[0x66] == '\0') {
    uVar3 = _objc_msgSend(param_3,PTR_s_tag_0003609c);
    puVar4 = PTR_s_NSString_0003626c;
    switch(uVar3) {
    default:
switchD_00003e46_caseD_0:
      return false;
    case 2:
switchD_000041af_caseD_2:
      uVar3 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
      pcVar7 = &cf_NewGame;
LAB_00003eef:
      uVar3 = _objc_msgSend(uVar3,PTR_s_localizedStringForKey_value_tabl_000360c4,pcVar7,&cf___,0);
      _objc_msgSend(param_3,PTR_s_setTitle__000360c8,uVar3);
      return false;
    case 9:
    case 0xe:
    case 0xf:
      goto switchD_00003e46_caseD_7;
    case 10:
      uVar3 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
      pcVar8 = &cf_OpenLevelEditor;
      goto LAB_000040be;
    case 0x12:
      if (*(int *)(PTR__g_00034014 + 0xd0) == 0) goto switchD_000041af_caseD_12;
      pcVar7 = (cfstringStruct *)
               _objc_msgSend(PTR_s_NSString_0003626c,PTR_s_stringWithCString__00036110,
                             PTR__g_00034014 + 0xd8);
      uVar3 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
      uVar9 = 0;
      uVar3 = _objc_msgSend(uVar3,PTR_s_localizedStringForKey_value_tabl_000360c4,&cf_Replay__,
                            &cf___,0);
      uVar3 = _objc_msgSend(puVar4,PTR_s_stringWithFormat__00036114,uVar3,pcVar7);
    }
  }
  else {
    if (PTR__g_00034014[0x80] != '\0') {
      uVar3 = _objc_msgSend(param_3,PTR_s_tag_0003609c);
      switch(uVar3) {
      default:
        goto switchD_00003e46_caseD_0;
      case 2:
        goto switchD_000041af_caseD_2;
      case 3:
        goto switchD_00003e46_caseD_3;
      case 9:
      case 0xb:
        goto switchD_00003e46_caseD_7;
      case 10:
        uVar3 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
        pcVar8 = &cf_ExitLevelEditor;
        goto LAB_000040be;
      case 0xc:
      case 0xd:
        if (PTR__g_00034014[0x1f0] == '\0') {
          return false;
        }
        sVar1 = _CountTiles();
        if (sVar1 < 1) {
          return false;
        }
        return true;
      case 0x10:
        sVar1 = _CountTilesAtCurrentLayer();
        break;
      case 0x11:
        sVar1 = _CountTiles();
        break;
      case 0x12:
switchD_000041af_caseD_12:
        uVar3 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
        pcVar7 = &cf_ReplayLastLevel;
        goto LAB_00003eef;
      case 0x13:
        return (bool)PTR__g_00034014[0x1f2];
      }
      return 0 < sVar1;
    }
    uVar3 = _objc_msgSend(param_3,PTR_s_tag_0003609c);
    switch(uVar3) {
    default:
      return false;
    case 2:
      uVar3 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
      pcVar8 = &cf_GiveUp;
      break;
    case 3:
switchD_00003e46_caseD_3:
      return (bool)PTR__g_00034014[0x1f1];
    case 4:
    case 6:
      return PTR__g_00034014[0x67] == '\0';
    case 7:
    case 9:
      goto switchD_00003e46_caseD_7;
    case 10:
      uVar3 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
      pcVar7 = &cf_OpenLevelEditor;
      goto LAB_00003eef;
    }
LAB_000040be:
    uVar9 = 0;
    pcVar7 = &cf___;
    uVar3 = _objc_msgSend(uVar3,PTR_s_localizedStringForKey_value_tabl_000360c4,pcVar8,&cf___,0);
  }
  _objc_msgSend(param_3,PTR_s_setTitle__000360c8,uVar3,pcVar7,uVar9);
switchD_00003e46_caseD_7:
  return true;
}


// ==== -[Controller_finishLaunch:] @ 000041d4 ====

void __Controller_finishLaunch__(int param_1)

{
  undefined *puVar1;
  undefined4 uVar2;
  
  puVar1 = PTR__p_00034010;
  *(undefined1 *)(param_1 + 0xe) = 1;
  if ((puVar1[0x212] == '\0') || (*(char *)(param_1 + 0xd) != '\0')) {
    _objc_msgSend(*(undefined4 *)(param_1 + 4),PTR_s_makeKeyAndOrderFront__000360d8,0);
    uVar2 = _objc_msgSend(*(undefined4 *)(param_1 + 4),PTR_s_windowRef_00036104);
    *(undefined4 *)(PTR__g_00034014 + 0xcc) = uVar2;
  }
  else {
    _objc_msgSend(param_1,PTR_s__enterFullscreen_000360e8);
  }
  puVar1 = PTR__p_00034010;
  if (PTR__p_00034010[0x215] != '\0') {
    PTR__p_00034010[0x215] = 0;
    _SavePrefs(puVar1);
    _SplashScreen();
    return;
  }
  return;
}


// ==== -[Controller_updaterWillDisplay:] @ 00004280 ====

void __Controller_updaterWillDisplay__(int param_1)

{
  char cVar1;
  
  *(undefined1 *)(param_1 + 0xd) = 1;
  cVar1 = _objc_msgSend(param_1,PTR_s_isFullscreen_00036064);
  if (cVar1 != '\0') {
    _objc_msgSend();
    return;
  }
  return;
}


// ==== -[Controller_window] @ 000042be ====

undefined4 __Controller_window_(int param_1)

{
  char cVar1;
  undefined4 uVar2;
  
  cVar1 = _objc_msgSend(param_1,PTR_s_isFullscreen_00036064);
  if (cVar1 == '\0') {
    uVar2 = *(undefined4 *)(param_1 + 4);
  }
  else {
    uVar2 = *(undefined4 *)(param_1 + 0x24);
  }
  return uVar2;
}


// ==== -[Controller_keyDown:] @ 000042eb ====

void __Controller_keyDown__(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  short sVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  
  uVar2 = _objc_msgSend(param_3,PTR_s_characters_00036128);
  uVar3 = 0;
  sVar1 = _objc_msgSend(uVar2,PTR_s_characterAtIndex__0003612c,0);
  if (PTR__g_00034014[0x66] == '\0') {
    if (PTR__g_00034014[0x80] == '\0') {
      return;
    }
  }
  else if (PTR__g_00034014[0x80] == '\0') {
    if (sVar1 != 0x1b) {
      return;
    }
    _objc_msgSend();
    return;
  }
  if (sVar1 == 0x1b) {
    _objc_msgSend(param_1,PTR_s_exitLevelEditor_00036084,uVar3);
  }
  else if (sVar1 == -0x8fd) {
    _SlideRight();
  }
  else if (sVar1 == -0x8fe) {
    _SlideLeft();
  }
  else if (sVar1 == -0x8ff) {
    _SlideDown();
  }
  else if (sVar1 == -0x900) {
    _SlideUp();
  }
  _objc_msgSend(param_3,PTR_s_modifierFlags_00036130,uVar3);
  if ((((sVar1 != 0x31) && (sVar1 != 0x32)) && (sVar1 != 0x33)) &&
     (((sVar1 != 0x34 && (sVar1 != 0x35)) && ((sVar1 != 0x36 && (sVar1 != 0x37)))))) {
    return;
  }
  _SelectLevelButton();
  return;
}


// ==== -[Controller_mouseDown:] @ 00004489 ====

void __Controller_mouseDown__(int param_1)

{
  int iVar1;
  undefined *puVar2;
  undefined4 uVar3;
  int iVar4;
  uint uVar5;
  uint uVar6;
  undefined1 local_20 [7];
  byte local_19;
  undefined4 local_10;
  
  _GetMouseLocation(&local_10);
  puVar2 = PTR__g_00034014;
  if (PTR__g_00034014[0x66] == '\0') {
    if ((ushort)((short)local_10 - 0x22fU) < 0x1e) {
      if (*(int *)(PTR__g_00034014 + 0xc0) == 0) {
        uVar3 = _TickCount();
        *(undefined4 *)(puVar2 + 0xc0) = uVar3;
      }
      _SelectMenuOptions(local_10);
      if (*(int *)(puVar2 + 0xc0) != 0) {
        iVar1 = *(int *)(puVar2 + 0xa8);
        iVar4 = _TickCount();
        *(int *)(puVar2 + 0xa8) = iVar1 + (iVar4 - *(int *)(puVar2 + 0xc0));
      }
      *(undefined4 *)(puVar2 + 0xc0) = 0;
    }
    else {
      _SelectMapArea(local_10,0);
    }
  }
  else {
    uVar3 = _TickCount();
    *(undefined4 *)(puVar2 + 0x4c) = uVar3;
    if (puVar2[0x84] != '\0') {
      puVar2[0x84] = 0;
      _FlashCGButton(1,0);
    }
    if ((ushort)((short)local_10 - 0x22bU) < 0x21) {
      if (puVar2[0x80] == '\0') {
        _SelectCGButton(local_10);
      }
      else {
        _GetKeys(local_20);
        _SelectLevelButton(local_10,0,local_19 >> 2 & 1);
      }
    }
    else if (puVar2[0x67] == '\0') {
      if ((((puVar2[0x80] == '\x01') && (-1 < local_10)) && (-1 < (short)local_10)) &&
         ((local_10._2_2_ < 0x321 && ((short)local_10 < 600)))) {
        _CreateTile(local_10);
      }
      uVar5 = _TickCount();
      iVar1 = *(int *)(param_1 + 0x44);
      uVar6 = _GetDblTime();
      if (uVar5 < iVar1 + (uVar6 >> 1)) {
        if ((((*(short *)(param_1 + 0x50) + 1 < (int)(short)local_10 ||
              (int)(short)local_10 < *(short *)(param_1 + 0x50) + -1) &&
              (*(short *)(param_1 + 0x52) + 1 < (int)local_10._2_2_ ||
              (int)local_10._2_2_ < *(short *)(param_1 + 0x52) + -1)) &&
            (PTR__g_00034014[0x80] == '\0')) && (0 < *(short *)(PTR__g_00034014 + 0x60))) {
          _SelectCGTile(local_10);
        }
      }
      else {
        uVar3 = _TickCount();
        *(undefined4 *)(param_1 + 0x44) = uVar3;
        if (0 < *(short *)(PTR__g_00034014 + 0x60)) {
          _SelectCGTile(local_10);
        }
        *(int *)(param_1 + 0x50) = local_10;
      }
    }
  }
  return;
}


// ==== -[Controller_idleTimerFired:] @ 00004686 ====

void __Controller_idleTimerFired__(int param_1)

{
  if (PTR__g_00034014[0x66] == '\0') {
    _MapScreen(param_1 + 0x34,param_1 + 0x38,param_1 + 0x48,param_1 + 0x4d,param_1 + 0x4e,
               param_1 + 0x4c);
    return;
  }
  if (PTR__g_00034014[0x80] != '\0') {
    _EditorScreen();
    return;
  }
  _CustomGameScreen();
  return;
}


// ==== _GetMouseLocation @ 000046ee ====

undefined4 _GetMouseLocation(undefined2 *param_1)

{
  float fVar1;
  undefined *puVar2;
  char cVar3;
  undefined4 uVar4;
  int iVar5;
  undefined4 uVar6;
  undefined8 uVar7;
  
  uVar4 = _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
  uVar4 = _objc_msgSend(uVar4,PTR_s_window_00036138);
  puVar2 = PTR_00038014;
  cVar3 = _objc_msgSend(*(undefined4 *)PTR_00038014,PTR_s_isActive_0003613c);
  if ((cVar3 != '\0') &&
     (iVar5 = _objc_msgSend(*(undefined4 *)puVar2,PTR_s_modalWindow_00036120), iVar5 == 0)) {
    uVar6 = _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
    cVar3 = _objc_msgSend(uVar6,PTR_s_isFullscreen_00036064);
    if ((cVar3 != '\0') || (cVar3 = _objc_msgSend(uVar4,PTR_s_isKeyWindow_00036140), cVar3 != '\0'))
    {
      uVar7 = _objc_msgSend(PTR_s_NSEvent_000362a8,PTR_s_mouseLocation_00036144);
      uVar7 = _objc_msgSend(uVar4,PTR_s_convertScreenToBase__00036148,uVar7);
      uVar4 = _objc_msgSend(uVar4,PTR_s_contentView_0003614c);
      uVar7 = _objc_msgSend(uVar4,PTR_s_convertPoint_fromView__00036150,uVar7,0);
      fVar1 = FLOAT_00033b1c;
      param_1[1] = (short)(int)(float)uVar7;
      *param_1 = (short)(int)(fVar1 - (float)((ulonglong)uVar7 >> 0x20));
      return 1;
    }
  }
  param_1[1] = 0;
  *param_1 = 0;
  return 0;
}


// ==== _CreateGWorld @ 0000485c ====

void _CreateGWorld(int param_1,undefined4 *param_2,undefined4 param_3,undefined4 param_4)

{
  short sVar1;
  short sVar2;
  undefined4 uVar3;
  undefined4 unaff_ESI;
  undefined4 local_40;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20 [4];
  
  _GetGWorld(local_20,&local_24);
  if (param_1 != 0) {
    uVar3 = _CFBundleGetMainBundle();
    uVar3 = _CFBundleCopyResourceURL(uVar3,param_1,&cf_png,0);
    local_40 = _CGDataProviderCreateWithURL(uVar3);
    _CFRelease(uVar3);
    unaff_ESI = _CGImageCreateWithPNGDataProvider(local_40,0,0,0);
    sVar1 = _CGImageGetHeight(unaff_ESI);
    sVar2 = _CGImageGetWidth(unaff_ESI);
    _SetRect(&param_3,0,0,(int)sVar2,(int)sVar1);
  }
  _NewGWorld(param_2,0x20,&param_3,0,0,0x100);
  if (param_1 != 0) {
    _SetGWorld(*param_2,0);
    _QDBeginCGContext(*param_2,&local_28);
    _CGContextDrawImage(local_28,0,0,(float)(int)param_4._2_2_,(float)(int)(short)param_4,unaff_ESI)
    ;
    _CGDataProviderRelease(local_40);
    _CGImageRelease(unaff_ESI);
    _QDEndCGContext(*param_2,&local_28);
  }
  _SetGWorld(local_20[0],local_24);
  return;
}


// ==== _DrawToGWorld @ 00004a04 ====

void _DrawToGWorld(undefined4 *param_1,undefined4 *param_2,undefined4 *param_3)

{
  short sVar1;
  undefined4 *puVar2;
  undefined4 *puVar3;
  short in_stack_00000028;
  undefined4 *local_30;
  undefined4 local_24;
  undefined4 local_20 [4];
  
  sVar1 = in_stack_00000028;
  if (in_stack_00000028 != -9) {
    local_30 = (undefined4 *)_GetGWorldPixMap(*param_3);
    if (param_1 != param_3) {
      _LockPixels(local_30);
    }
  }
  puVar2 = (undefined4 *)_GetGWorldPixMap(*param_2);
  puVar3 = (undefined4 *)_GetGWorldPixMap(*param_1);
  _GetGWorld(&local_24,local_20);
  _SetGWorld(*param_2,0);
  _LockPixels(puVar3);
  _LockPixels(puVar2);
  if (sVar1 == -9) {
    _CopyBits(*puVar3,*puVar2,&stack0x00000010,&stack0x00000018,0,0);
  }
  else {
    _CopyDeepMask(*puVar3,*local_30,*puVar2,&stack0x00000010,&stack0x00000020,&stack0x00000018,0,0);
  }
  _UnlockPixels(puVar3);
  _UnlockPixels(puVar2);
  if (param_1 != param_3) {
    _UnlockPixels(local_30);
  }
  _SetGWorld(local_24,local_20[0]);
  return;
}


// ==== _DrawToWindow @ 00004b40 ====

void _DrawToWindow(undefined4 *param_1)

{
  undefined *puVar1;
  char cVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  undefined4 *puVar5;
  char in_stack_00000018;
  undefined4 local_24;
  undefined4 local_20 [4];
  
  cVar2 = in_stack_00000018;
  puVar1 = PTR__g_00038024;
  if (*(int *)(PTR__g_00038024 + 0xcc) != 0) {
    _GetGWorld(&local_24,local_20);
    uVar3 = _GetMainDevice();
    uVar4 = _GetWindowPort(*(undefined4 *)(puVar1 + 0xcc));
    _SetGWorld(uVar4,uVar3);
    uVar3 = _GetWindowPort(*(undefined4 *)(puVar1 + 0xcc));
    _LockPortBits(uVar3);
    puVar5 = (undefined4 *)_GetGWorldPixMap(*param_1);
    _LockPixels(puVar5);
    uVar4 = _GetWindowPort(*(undefined4 *)(puVar1 + 0xcc));
    uVar4 = _GetPortBitMapForCopyBits(uVar4);
    _CopyBits(*puVar5,uVar4,&stack0x00000008,&stack0x00000010,0,0);
    _UnlockPixels(puVar5);
    _UnlockPortBits(uVar3);
    if (cVar2 != '\0') {
      _QDFlushPortBuffer(uVar3,0);
    }
    _SetGWorld(local_24,local_20[0]);
  }
  return;
}


// ==== _DrawFromWindow @ 00004c48 ====

void _DrawFromWindow(undefined4 *param_1)

{
  undefined4 uVar1;
  undefined4 uVar2;
  undefined4 *puVar3;
  undefined4 uVar4;
  undefined4 local_24;
  undefined4 local_20 [4];
  
  _GetGWorld(&local_24,local_20);
  uVar2 = _GetWindowPort(*(undefined4 *)(PTR__g_00038024 + 0xcc));
  _LockPortBits(uVar2);
  puVar3 = (undefined4 *)_GetGWorldPixMap(*param_1);
  _LockPixels(puVar3);
  uVar1 = *puVar3;
  uVar4 = _GetWindowPort(*(undefined4 *)(PTR__g_00038024 + 0xcc));
  uVar4 = _GetPortBitMapForCopyBits(uVar4);
  _CopyBits(uVar4,uVar1,&stack0x00000008,&stack0x00000010,0,0);
  _UnlockPixels(puVar3);
  _UnlockPortBits(uVar2);
  _SetGWorld(local_24,local_20[0]);
  return;
}


// ==== _RunModalSaveAlert @ 00004d0a ====

void _RunModalSaveAlert(void)

{
  undefined *puVar1;
  char cVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  undefined4 uVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  undefined4 uVar8;
  undefined4 uVar9;
  
  puVar1 = PTR_s_NSAlert_000362b4;
  uVar3 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
  uVar3 = _objc_msgSend(uVar3,PTR_s_localizedStringForKey_value_tabl_000360c4,&cf_Y,&cf___,0);
  uVar4 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
  uVar4 = _objc_msgSend(uVar4,PTR_s_localizedStringForKey_value_tabl_000360c4,&cf_Cancel,&cf___,0);
  uVar5 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
  uVar5 = _objc_msgSend(uVar5,PTR_s_localizedStringForKey_value_tabl_000360c4,&cf_Don_tSave,&cf___,0
                       );
  uVar6 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
  uVar6 = _objc_msgSend(uVar6,PTR_s_localizedStringForKey_value_tabl_000360c4,&cf_Save,&cf___,0);
  uVar7 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
  uVar7 = _objc_msgSend(uVar7,PTR_s_localizedStringForKey_value_tabl_000360c4,
                        &cf_Doyouwanttosavethechangesyoumadetothiscustomlevel_,&cf___,0);
  uVar8 = _objc_msgSend(puVar1,PTR_s_alertWithMessageText_defaultButt_00036154,uVar7,uVar6,uVar5,
                        uVar4,uVar3);
  uVar9 = _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
  cVar2 = _objc_msgSend(uVar9,PTR_s_isFullscreen_00036064);
  if (cVar2 != '\0') {
    uVar9 = _objc_msgSend(uVar8,PTR_s_window_00036138,uVar7,uVar6,uVar5,uVar4,uVar3);
    _objc_msgSend(uVar9,PTR_s_scheduleSetShieldingLevel_00036158);
  }
  _objc_msgSend(uVar8,PTR_s_runModal_00036040,uVar7,uVar6,uVar5,uVar4,uVar3);
  return;
}


// ==== _CreateNewDialog @ 00004ef9 ====

void _CreateNewDialog(undefined2 param_1)

{
  int iVar1;
  short sVar2;
  char cVar3;
  int iVar4;
  undefined4 uVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  undefined4 uVar8;
  undefined4 uVar9;
  code *pcVar10;
  cfstringStruct *pcVar11;
  undefined4 local_bc;
  short local_b2;
  short local_b0;
  short local_ae;
  undefined *local_ac;
  int local_a8;
  undefined *local_a4;
  undefined4 local_94;
  undefined4 local_90;
  undefined4 local_8c;
  undefined4 local_88;
  undefined4 local_84;
  int local_80;
  undefined4 local_7c;
  int local_78;
  undefined4 local_74;
  int local_70;
  undefined4 local_6c;
  undefined4 local_68;
  undefined4 local_64;
  int local_60;
  undefined4 local_5c;
  undefined4 local_58;
  undefined4 local_54;
  int local_50;
  undefined4 local_4c;
  undefined4 local_48;
  undefined4 local_44;
  undefined4 local_40;
  undefined4 local_3c;
  undefined4 local_38;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20 [4];
  
  local_94 = 0x636d6473;
  local_90 = 1;
  switch(param_1) {
  case 0x1e:
    _CreateNibReference(&cf_Aki,&local_44);
    iVar4 = _CreateWindowFromNib(local_44,&cf_Warning,&local_48);
    if (iVar4 != 0) {
      _ExitToShell();
    }
    pcVar10 = _WarningEventHandler;
    break;
  default:
    goto switchD_00004f29_caseD_1f;
  case 0x28:
    _CreateNibReference(&cf_Aki,&local_44);
    iVar4 = _CreateWindowFromNib(local_44,&cf_Unavailable,&local_48);
    if (iVar4 != 0) {
      _ExitToShell();
    }
    pcVar10 = _NotOpenEventHandler;
    break;
  case 0x3c:
    _CreateNibReference(&cf_Aki,&local_44);
    iVar4 = _CreateWindowFromNib(local_44,&cf_Stats,&local_48);
    local_ac = PTR__p_00038028;
    local_a4 = PTR__p_00038028;
    local_b2 = 0;
    local_b0 = 0;
    local_ae = 0;
    local_a8 = 0x191;
    do {
      local_74 = 0;
      iVar1 = *(int *)(local_ac + 0x260);
      sVar2 = (short)(iVar1 / 0x3c);
      local_70 = local_a8;
      _GetControlByID(local_48,&local_74,&local_4c);
      local_28 = _CFStringCreateWithFormat(0,0,&cf__d,(int)sVar2);
      _SetControlData(local_4c,0,0x63667374,4,&local_28);
      _CFRelease(local_28);
      _Draw1Control(local_4c);
      local_84 = 0;
      local_80 = local_a8 + 0xc;
      _GetControlByID(local_48,&local_84,&local_4c);
      local_2c = _CFStringCreateWithFormat(0,0,&cf__d,(int)(short)((short)iVar1 + sVar2 * -0x3c));
      _SetControlData(local_4c,0,0x63667374,4,&local_2c);
      _CFRelease(local_2c);
      _Draw1Control(local_4c);
      local_54 = 0;
      local_50 = local_a8 + -400;
      _GetControlByID(local_48,&local_54,&local_4c);
      local_30 = _CFStringCreateWithFormat(0,0,&cf__d,(int)*(short *)(local_a4 + 0x218));
      _SetControlData(local_4c,0,0x63667374,4,&local_30);
      _CFRelease(local_30);
      _Draw1Control(local_4c);
      local_64 = 0;
      local_60 = local_a8 + -0x184;
      _GetControlByID(local_48,&local_64,&local_4c);
      local_34 = _CFStringCreateWithFormat(0,0,&cf__d,(int)*(short *)(local_a4 + 0x230));
      _SetControlData(local_4c,0,0x63667374,4,&local_34);
      _CFRelease(local_34);
      _Draw1Control(local_4c);
      local_7c = 0;
      local_78 = local_a8 + -0x178;
      _GetControlByID(local_48,&local_7c,&local_4c);
      local_38 = _CFStringCreateWithFormat(0,0,&cf__d,(int)*(short *)(local_a4 + 0x248));
      _SetControlData(local_4c,0,0x63667374,4,&local_38);
      _CFRelease(local_38);
      _Draw1Control(local_4c);
      local_5c = 0;
      local_b2 = local_b2 + *(short *)(local_a4 + 0x218);
      local_ae = local_ae + *(short *)(local_a4 + 0x248);
      local_b0 = local_b0 + *(short *)(local_a4 + 0x230);
      local_58 = 0x28;
      _GetControlByID(local_48,&local_5c,&local_4c);
      local_3c = _CFStringCreateWithFormat(0,0,&cf__d,(int)local_b2);
      _SetControlData(local_4c,0,0x63667374,4,&local_3c);
      _CFRelease(local_3c);
      _Draw1Control(local_4c);
      local_8c = 0;
      local_88 = 0x29;
      _GetControlByID(local_48,&local_8c,&local_4c);
      local_40 = _CFStringCreateWithFormat(0,0,&cf__d,(int)local_b0);
      _SetControlData(local_4c,0,0x63667374,4,&local_40);
      _CFRelease(local_40);
      _Draw1Control(local_4c);
      local_6c = 0;
      local_68 = 0x2a;
      _GetControlByID(local_48,&local_6c,&local_4c);
      local_20[0] = _CFStringCreateWithFormat(0,0,&cf__d,(int)local_ae);
      _SetControlData(local_4c,0,0x63667374,4,local_20);
      _CFRelease(local_20[0]);
      _Draw1Control(local_4c);
      local_a8 = local_a8 + 1;
      local_ac = local_ac + 4;
      local_a4 = local_a4 + 2;
    } while (local_a8 != 0x19d);
    if (iVar4 != 0) {
      _ExitToShell();
    }
    pcVar10 = _StatsEventHandler;
    break;
  case 0x47:
    _CreateNibReference(&cf_Aki,&local_44);
    iVar4 = _CreateWindowFromNib(local_44,&cf_Stacked,&local_48);
    if (iVar4 != 0) {
      _ExitToShell();
    }
    pcVar10 = _StackedEventHandler;
    break;
  case 0x50:
    _CreateNibReference(&cf_Aki,&local_44);
    iVar4 = _CreateWindowFromNib(local_44,&cf_Incomplete,&local_48);
    if (iVar4 != 0) {
      _ExitToShell();
    }
    pcVar10 = _InCompleteEventHandler;
    break;
  case 0x51:
    _CreateNibReference(&cf_Aki,&local_44);
    iVar4 = _CreateWindowFromNib(local_44,&cf_Transfer,&local_48);
    if (iVar4 != 0) {
      _ExitToShell();
    }
    pcVar10 = _TransferEventHandler;
    break;
  case 0x53:
    _CreateNibReference(&cf_Aki,&local_44);
    iVar4 = _CreateWindowFromNib(local_44,&cf_TryAgain,&local_48);
    if (iVar4 != 0) {
      _ExitToShell();
    }
    pcVar10 = _TryAgainEventHandler;
    break;
  case 0x55:
    _CreateNibReference(&cf_Aki,&local_44);
    iVar4 = _CreateWindowFromNib(local_44,&cf_PleaseReg,&local_48);
    if (iVar4 != 0) {
      _ExitToShell();
    }
    pcVar10 = _PleaseRegEventHandler;
    break;
  case 0x56:
    _CreateNibReference(&cf_Aki,&local_44);
    pcVar11 = &cf_Permissions;
    goto LAB_00004fb8;
  case 0x57:
    _CreateNibReference(&cf_Aki,&local_44);
    iVar4 = _CreateWindowFromNib(local_44,&cf_LoadLevel,&local_48);
    if (iVar4 != 0) {
      _ExitToShell();
    }
    pcVar10 = _LoadLevelEventHandler;
    break;
  case 0x58:
    _CreateNibReference(&cf_Aki,&local_44);
    pcVar11 = &cf_FileNotFound;
LAB_00004fb8:
    iVar4 = _CreateWindowFromNib(local_44,pcVar11,&local_48);
    if (iVar4 != 0) {
      _ExitToShell();
    }
    pcVar10 = _PermissionsEventHandler;
  }
  local_bc = _NewEventHandlerUPP(pcVar10);
switchD_00004f29_caseD_1f:
  uVar9 = local_48;
  uVar5 = _GetWindowEventTarget(local_48);
  _InstallEventHandler(uVar5,local_bc,1,&local_94,uVar9,0);
  local_24 = 0;
  uVar5 = _CFBundleGetMainBundle();
  uVar5 = _CFBundleCopyResourceURL(uVar5,&cf_paper,&cf_png,0);
  uVar6 = _CGDataProviderCreateWithURL(uVar5);
  uVar7 = _CGImageCreateWithPNGDataProvider(uVar6,0,0,0);
  uVar8 = _HIViewGetRoot(local_48);
  _HIViewFindByID(uVar8,0,200,&local_24);
  _HIImageViewSetImage(local_24,uVar7);
  _HIViewSetNeedsDisplay(local_24,1);
  _CFRelease(uVar5);
  _CFRelease(uVar6);
  _CGImageRelease(uVar7);
  uVar6 = _objc_msgSend(PTR_s_NSWindow_000362b0,PTR_s_alloc_0003601c);
  uVar5 = uVar9;
  uVar6 = _objc_msgSend(uVar6,PTR_s_initWithWindowRef__0003615c,uVar9);
  _objc_msgSend(uVar6,PTR_s_centerWithCGDisplaySize_00036160);
  uVar7 = _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
  cVar3 = _objc_msgSend(uVar7,PTR_s_isFullscreen_00036064);
  if (cVar3 != '\0') {
    uVar5 = _CGShieldingWindowLevel();
    _objc_msgSend(uVar6,PTR_s_setLevel__00036108,uVar5);
  }
  _objc_msgSend(uVar6,PTR_s_display_00036164,uVar5);
  _objc_msgSend(uVar6,PTR_s_makeKeyAndOrderFront__000360d8,0);
  _RunAppModalLoopForWindow(uVar9);
  _DisposeNibReference(local_44);
  _DisposeEventHandlerUPP(local_bc);
  _HideWindow(uVar9);
  _DisposeWindow(uVar9);
  _objc_msgSend(uVar6,PTR_s_release_00036000);
  uVar9 = _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
  uVar9 = _objc_msgSend(uVar9,PTR_s_window_00036138);
  _objc_msgSend(uVar9,PTR_s_makeKeyAndOrderFront__000360d8,0);
  return;
}


// ==== _WarningEventHandler @ 00005a87 ====

undefined4 _WarningEventHandler(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  undefined1 local_1a [4];
  int local_16;
  
  _GetEventParameter(param_2,0x2d2d2d2d,0x68636d64,0,0xe,0,local_1a);
  if (local_16 == 0x6e6f7421) {
    PTR__g_00038024[0x81] = 0;
  }
  else {
    if (local_16 != 0x6f6b2020) {
      return 0xffffd96e;
    }
    PTR__g_00038024[0x81] = 1;
  }
  _QuitAppModalLoopForWindow(param_3);
  return 0xffffd96e;
}


// ==== _PleaseRegEventHandler @ 00005b04 ====

undefined4 _PleaseRegEventHandler(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  undefined4 uVar1;
  undefined1 local_1a [4];
  int local_16;
  
  _GetEventParameter(param_2,0x2d2d2d2d,0x68636d64,0,0xe,0,local_1a);
  if ((local_16 == 0x6e6f7421) || (local_16 == 0x6f6b2020)) {
    _QuitAppModalLoopForWindow(param_3);
  }
  if (local_16 == 0x6f6b2020) {
    uVar1 = _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
    _objc_msgSend(uVar1,PTR_s_showRegistration__00036168,0);
  }
  return 0xffffd96e;
}


// ==== _StackedEventHandler @ 00005ba4 ====

undefined4 _StackedEventHandler(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  undefined1 local_1a [4];
  int local_16;
  
  _GetEventParameter(param_2,0x2d2d2d2d,0x68636d64,0,0xe,0,local_1a);
  if ((local_16 == 0x6e6f7421) || (local_16 == 0x6f6b2020)) {
    _QuitAppModalLoopForWindow(param_3);
  }
  return 0xffffd96e;
}


// ==== _StatsEventHandler @ 00005c07 ====

undefined4 _StatsEventHandler(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  undefined1 local_1a [4];
  int local_16;
  
  _GetEventParameter(param_2,0x2d2d2d2d,0x68636d64,0,0xe,0,local_1a);
  if (local_16 == 0x6e6f7421) {
    PTR__g_00038024[0x81] = 0;
  }
  else {
    if (local_16 != 0x6f6b2020) {
      return 0xffffd96e;
    }
    PTR__g_00038024[0x81] = 1;
  }
  _QuitAppModalLoopForWindow(param_3);
  return 0xffffd96e;
}


// ==== _NotOpenEventHandler @ 00005c84 ====

undefined4 _NotOpenEventHandler(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  undefined1 local_1a [4];
  int local_16;
  
  _GetEventParameter(param_2,0x2d2d2d2d,0x68636d64,0,0xe,0,local_1a);
  if (local_16 == 0x6f6b2020) {
    PTR__g_00038024[0x81] = 1;
    _QuitAppModalLoopForWindow(param_3);
  }
  return 0xffffd96e;
}


// ==== _InCompleteEventHandler @ 00005ceb ====

undefined4 _InCompleteEventHandler(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  undefined1 local_1a [4];
  int local_16;
  
  _GetEventParameter(param_2,0x2d2d2d2d,0x68636d64,0,0xe,0,local_1a);
  if (local_16 == 0x6f6b2020) {
    _QuitAppModalLoopForWindow(param_3);
  }
  return 0xffffd96e;
}


// ==== _TransferEventHandler @ 00005d46 ====

undefined4 _TransferEventHandler(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  undefined1 local_1a [4];
  int local_16;
  
  _GetEventParameter(param_2,0x2d2d2d2d,0x68636d64,0,0xe,0,local_1a);
  if (local_16 == 0x6f6b2020) {
    _QuitAppModalLoopForWindow(param_3);
  }
  return 0xffffd96e;
}


// ==== _TryAgainEventHandler @ 00005da1 ====

undefined4 _TryAgainEventHandler(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  undefined *puVar1;
  undefined4 uVar2;
  undefined1 local_1a [4];
  int local_16;
  
  puVar1 = PTR__g_00038024;
  PTR__g_00038024[0x22a] = 0;
  _GetEventParameter(param_2,0x2d2d2d2d,0x68636d64,0,0xe,0,local_1a);
  if (local_16 != 0x6e6f7421) {
    if (local_16 != 0x6f6b2020) goto LAB_00005e12;
    puVar1[0x22a] = 1;
  }
  _QuitAppModalLoopForWindow(param_3);
LAB_00005e12:
  uVar2 = _TickCount();
  *(undefined4 *)(PTR__g_00038024 + 0xa8) = uVar2;
  return 0xffffd96e;
}


// ==== _PermissionsEventHandler @ 00005e2e ====

undefined4 _PermissionsEventHandler(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  undefined1 local_1a [4];
  int local_16;
  
  _GetEventParameter(param_2,0x2d2d2d2d,0x68636d64,0,0xe,0,local_1a);
  if (local_16 == 0x6f6b2020) {
    _QuitAppModalLoopForWindow(param_3);
  }
  return 0xffffd96e;
}


// ==== _LoadLevelEventHandler @ 00005e89 ====

undefined4 _LoadLevelEventHandler(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  undefined1 local_1a [4];
  int local_16;
  
  _GetEventParameter(param_2,0x2d2d2d2d,0x68636d64,0,0xe,0,local_1a);
  if (local_16 == 0x6e6f7421) {
    PTR__g_00038024[0x81] = 0;
  }
  else {
    if (local_16 != 0x6f6b2020) {
      return 0xffffd96e;
    }
    PTR__g_00038024[0x81] = 1;
  }
  _QuitAppModalLoopForWindow(param_3);
  return 0xffffd96e;
}


// ==== _ShowSplashScreenWithImage @ 00005f06 ====

void _ShowSplashScreenWithImage(float *param_1,undefined4 param_2)

{
  undefined4 uVar1;
  char cVar2;
  undefined4 uVar3;
  undefined *puVar4;
  float **ppfVar5;
  undefined4 uStack_50;
  float *local_4c;
  undefined *local_48;
  undefined4 *local_44;
  undefined4 local_40;
  undefined *local_3c;
  undefined4 *local_38;
  undefined8 local_34;
  float local_2c;
  float local_28;
  float local_24;
  float local_20;
  float local_1c;
  float local_18;
  float local_14;
  float local_10;
  
  ppfVar5 = &local_4c;
  local_48 = PTR_s_alloc_0003601c;
  local_4c = (float *)PTR_s_AkiSplashWindow_000362b8;
  uStack_50 = 0x5f27;
  local_4c = (float *)_objc_msgSend();
  local_44 = param_1;
  local_40 = param_2;
  local_48 = PTR_s_initWithImage_timeout__00036184;
  uStack_50 = 0x5f44;
  uVar3 = _objc_msgSend();
  local_48 = PTR_s_sharedController_00036134;
  local_4c = (float *)PTR_s_Controller_000362ac;
  uStack_50 = 0x5f5c;
  local_4c = (float *)_objc_msgSend();
  local_48 = PTR_s_isFullscreen_00036064;
  uStack_50 = 0x5f6e;
  cVar2 = _objc_msgSend();
  puVar4 = PTR_s_scheduleSetShieldingLevel_00036158;
  if (cVar2 == '\0') {
    local_4c = param_1;
    local_48 = PTR_s_size_00036188;
    uStack_50 = 0x5f8d;
    local_34 = _objc_msgSend();
    local_48 = PTR_s_sharedController_00036134;
    local_4c = (float *)PTR_s_Controller_000362ac;
    uStack_50 = 0x5fa9;
    local_4c = (float *)_objc_msgSend();
    local_48 = PTR_s_window_00036138;
    uStack_50 = 0x5fbb;
    local_48 = (undefined *)_objc_msgSend();
    local_4c = &local_2c;
    local_44 = (undefined4 *)PTR_s_frame_000360f8;
    uStack_50 = 0x5fd4;
    _objc_msgSend_stret();
    local_1c = local_2c;
    ppfVar5 = (float **)&uStack_50;
    local_18 = local_28;
    local_14 = local_24;
    local_10 = local_20;
    local_48 = (undefined *)((local_24 - (float)local_34) * FLOAT_00033b20 + local_2c);
    local_44 = (undefined4 *)((local_20 - local_34._4_4_) * FLOAT_00033b20 + local_28);
    puVar4 = PTR_s_setFrameOrigin__0003618c;
    local_3c = local_48;
    local_38 = local_44;
  }
  ppfVar5[1] = (float *)puVar4;
  *ppfVar5 = (float *)uVar3;
  ppfVar5[-1] = (float *)0x6046;
  _objc_msgSend();
  uVar1 = *(undefined4 *)PTR_00038014;
  ppfVar5[2] = (float *)uVar3;
  *ppfVar5 = (float *)uVar1;
  ppfVar5[1] = (float *)PTR_s_runModalForWindow__00036074;
  ppfVar5[-1] = (float *)0x6062;
  _objc_msgSend();
  return;
}


// ==== _SplashScreen @ 00006069 ====

void _SplashScreen(undefined4 param_1)

{
  undefined *puVar1;
  undefined4 uVar2;
  int iVar3;
  
  puVar1 = PTR_s_NSImage_000362bc;
  uVar2 = _objc_msgSend(PTR_s_NSString_0003626c,PTR_s_stringWithUTF8String__0003616c,param_1);
  iVar3 = _objc_msgSend(puVar1,PTR_s_imageNamed__00036170,uVar2);
  if (iVar3 != 0) {
    _ShowSplashScreenWithImage();
    return;
  }
  return;
}


// ==== _RandomProverbScreen @ 000060c8 ====

void _RandomProverbScreen(void)

{
  float fVar1;
  long lVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  
  lVar2 = _random();
  uVar3 = _objc_msgSend(PTR_s_NSImage_000362bc,PTR_s_imageNamed__00036170,&cf_proverbs);
  uVar4 = _objc_msgSend(PTR_s_NSImage_000362bc,PTR_s_alloc_0003601c);
  fVar1 = FLOAT_00033b28;
  uVar4 = _objc_msgSend(uVar4,PTR_s_initWithSize__00036174,FLOAT_00033b28,FLOAT_00033b24);
  uVar4 = _objc_msgSend(uVar4,PTR_s_autorelease_00036100);
  _objc_msgSend(uVar4,PTR_s_lockFocus_00036178);
  _objc_msgSend(uVar3,PTR_s_drawInRect_fromRect_operation_fr_0003617c,0,0,fVar1,0x431d0000,0,
                (float)((lVar2 % 0xb & 0xffffU) * 0x9d),fVar1,0x431d0000,2,0x3f800000);
  _objc_msgSend(uVar4,PTR_s_unlockFocus_00036180);
  _ShowSplashScreenWithImage(uVar4,0x14);
  return;
}


// ==== -[Preferences_init] @ 00006232 ====

void __Preferences_init_(undefined4 param_1)

{
  undefined4 local_14;
  undefined *local_10;
  
  local_14 = param_1;
  local_10 = PTR_s_NSWindowController_00036344;
  _objc_msgSendSuper(&local_14,PTR_s_initWithWindowNibName__00036190,&cf_Preferences);
  return;
}


// ==== -[Preferences_cancel:] @ 00006264 ====

void __Preferences_cancel__(int param_1)

{
  undefined4 uVar1;
  undefined4 uVar2;
  undefined *puVar3;
  
  if (*(char *)(param_1 + 0x3c) == '\0') {
    uVar2 = *(undefined4 *)PTR_00038014;
    uVar1 = 1;
    puVar3 = PTR_s_stopModalWithCode__00036198;
  }
  else {
    uVar2 = *(undefined4 *)PTR_00038014;
    uVar1 = _objc_msgSend(param_1,PTR_s_window_00036138);
    puVar3 = PTR_s_endSheet__00036194;
  }
  _objc_msgSend(uVar2,puVar3,uVar1);
  _objc_msgSend(param_1,PTR_s_window_00036138);
  _objc_msgSend();
  return;
}


// ==== -[Preferences_save:] @ 000062ee ====

void __Preferences_save__(int param_1,undefined4 param_2,undefined4 param_3)

{
  char cVar1;
  short sVar2;
  short sVar3;
  undefined *puVar4;
  undefined *puVar5;
  int iVar6;
  undefined4 uVar7;
  
  _objc_msgSend(param_1,PTR_s_cancel__0003619c,param_3);
  sVar2 = *(short *)(PTR__p_00038028 + 0x210);
  iVar6 = _objc_msgSend(*(undefined4 *)(param_1 + 0x28),PTR_s_state_000361a0);
  sVar3 = *(short *)(PTR__p_00038028 + 0x20e);
  *(ushort *)(PTR__p_00038028 + 0x210) = sVar2 % 2 + (ushort)(iVar6 == 1) * 2;
  iVar6 = _objc_msgSend(*(undefined4 *)(param_1 + 0x34),PTR_s_state_000361a0);
  puVar5 = PTR__p_00038028;
  *(ushort *)(PTR__p_00038028 + 0x20e) = sVar3 % 2 + (ushort)(iVar6 == 1) * 2;
  iVar6 = _objc_msgSend(*(undefined4 *)(param_1 + 0x30),PTR_s_state_000361a0);
  puVar4 = PTR_s_state_000361a0;
  puVar5[0x213] = iVar6 == 1;
  iVar6 = _objc_msgSend(*(undefined4 *)(param_1 + 0x38),puVar4);
  puVar4 = PTR_s_state_000361a0;
  cVar1 = puVar5[0x212];
  puVar5[0x214] = iVar6 == 1;
  iVar6 = _objc_msgSend(*(undefined4 *)(param_1 + 0x2c),puVar4);
  if ((bool)cVar1 != (iVar6 == 1)) {
    iVar6 = _objc_msgSend(*(undefined4 *)(param_1 + 0x2c),PTR_s_state_000361a0);
    puVar4 = PTR_s_sharedController_00036134;
    puVar5[0x212] = iVar6 == 1;
    uVar7 = _objc_msgSend(PTR_s_Controller_000362ac,puVar4);
    _objc_msgSend(uVar7,PTR_s_performSelector_withObject_after_0003605c,
                  PTR_s_toggleFullscreen__000361a4,0,0,0);
  }
  _SavePrefs(PTR__p_00038028);
  _PlayMovie();
  return;
}


// ==== -[Preferences_beginSheetModalForWindow:modalDelegate:didEndSelector:contextInfo:] @ 0000647b ====

void __Preferences_beginSheetModalForWindow_modalDelegate_didEndSelector_contextInfo__
               (int param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6)

{
  undefined4 uVar1;
  undefined *puVar2;
  undefined4 uVar3;
  
  _objc_msgSend(param_1,PTR_s_window_00036138);
  _objc_msgSend(param_1,PTR_s__updateUI_000361a8);
  puVar2 = PTR_00038014;
  *(undefined1 *)(param_1 + 0x3c) = 1;
  uVar1 = *(undefined4 *)puVar2;
  uVar3 = _objc_msgSend(param_1,PTR_s_window_00036138);
  _objc_msgSend(uVar1,PTR_s_beginSheet_modalForWindow_modalD_000361ac,uVar3,param_3,param_4,param_5,
                param_6);
  return;
}


// ==== -[Preferences_runModal] @ 000064fc ====

void __Preferences_runModal_(int param_1)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  _objc_msgSend(param_1,PTR_s_window_00036138);
  _objc_msgSend(param_1,PTR_s__updateUI_000361a8);
  *(undefined1 *)(param_1 + 0x3c) = 0;
  uVar1 = _objc_msgSend(param_1,PTR_s_window_00036138);
  _objc_msgSend(uVar1,PTR_s_scheduleSetShieldingLevel_00036158);
  uVar1 = *(undefined4 *)PTR_00038014;
  uVar2 = _objc_msgSend(param_1,PTR_s_window_00036138);
  _objc_msgSend(uVar1,PTR_s_runModalForWindow__00036074,uVar2);
  return;
}


// ==== _MapScreen @ 00006652 ====

void _MapScreen(int *param_1,undefined4 param_2,int *param_3,char *param_4,short *param_5)

{
  int *piVar1;
  uint uVar2;
  int iVar3;
  uint uVar4;
  int iVar5;
  undefined *puVar6;
  short sVar7;
  int iVar8;
  int iVar9;
  undefined4 uVar10;
  undefined4 uVar11;
  undefined4 uVar12;
  undefined4 uVar13;
  int local_98 [12];
  int local_68 [13];
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  short local_20;
  short local_1e;
  
  local_68[0] = 0x2c9;
  local_68[1] = 0x193;
  local_68[2] = 0xe7;
  local_68[3] = 0x59;
  local_68[4] = 0xc;
  local_68[5] = 0xea;
  local_68[6] = 0x146;
  local_68[7] = 0x163;
  local_68[8] = 0x223;
  local_68[9] = 0x1b2;
  local_68[10] = 0x176;
  local_68[0xb] = 0x195;
  local_98[0] = 0x136;
  local_98[1] = 0xb0;
  local_98[2] = 0x73;
  local_98[3] = 0x2d;
  local_98[4] = 0x10d;
  local_98[5] = 0x164;
  local_98[6] = 0x119;
  local_98[7] = 0x126;
  local_98[8] = 0x13b;
  local_98[9] = 0xdf;
  local_98[10] = 0xd8;
  local_98[0xb] = 0xf4;
  _GetMouseLocation(&local_20);
  uVar2 = _TickCount();
  if (uVar2 <= *param_1 + 6U) {
    return;
  }
  uVar2 = 2;
  if (PTR__p_00038028[0x202] == '\0') {
    uVar2 = (uint)(PTR__p_00038028[0x201] != '\0');
  }
  uVar4 = 3;
  if (PTR__p_00038028[0x203] == '\0') {
    uVar4 = uVar2;
  }
  uVar2 = 4;
  if (PTR__p_00038028[0x204] == '\0') {
    uVar2 = uVar4;
  }
  uVar4 = 5;
  if (PTR__p_00038028[0x205] == '\0') {
    uVar4 = uVar2;
  }
  uVar2 = 6;
  if (PTR__p_00038028[0x206] == '\0') {
    uVar2 = uVar4;
  }
  uVar4 = 7;
  if (PTR__p_00038028[0x207] == '\0') {
    uVar4 = uVar2;
  }
  uVar2 = 8;
  if (PTR__p_00038028[0x208] == '\0') {
    uVar2 = uVar4;
  }
  uVar4 = 9;
  if (PTR__p_00038028[0x209] == '\0') {
    uVar4 = uVar2;
  }
  uVar2 = 10;
  if (PTR__p_00038028[0x20a] == '\0') {
    uVar2 = uVar4;
  }
  if (PTR__p_00038028[0x20b] != '\0') {
    uVar2 = 0xb;
  }
  if (*param_4 == '\0') {
    iVar3 = *param_3;
    *param_3 = iVar3 + -1;
    if (iVar3 + -1 == 0) {
      *param_4 = '\x01';
    }
  }
  else {
    iVar3 = *param_3;
    *param_3 = iVar3 + 1;
    if (iVar3 + 1 == 3) {
      *param_4 = '\0';
    }
  }
  iVar8 = (int)(short)local_98[uVar2];
  iVar3 = (int)(short)((short)local_98[uVar2] + 0x49);
  iVar5 = (int)(short)local_68[uVar2];
  iVar9 = (int)(short)((short)local_68[uVar2] + 0x4b);
  _SetRect(&local_28,iVar5,iVar8,iVar9,iVar3);
  piVar1 = local_68 + 0xc;
  _SetRect(piVar1,iVar5,iVar8,iVar9,iVar3);
  _DrawToGWorld(PTR__g_00038024 + 0x30,PTR__g_00038024 + 0x2c,PTR__g_00038024 + 0x30,local_28,
                local_24,local_68[0xc],local_34,local_30,local_2c,0xfffffff7);
  _SetRect(&local_28,0xcd,0x150,0x118,0x199);
  _SetRect(piVar1,iVar5,iVar8,iVar9,iVar3);
  iVar3 = *param_3;
  if (iVar3 == 1) {
    uVar13 = 0x199;
    uVar12 = 0x1ae;
    uVar11 = 0x150;
    uVar10 = 0x163;
LAB_00006918:
    _SetRect(&local_30,uVar10,uVar11,uVar12,uVar13);
  }
  else {
    if (1 < iVar3) {
      if (iVar3 == 2) {
        uVar13 = 0xde;
        uVar12 = 0x164;
        uVar11 = 0x95;
        uVar10 = 0x119;
      }
      else {
        if (iVar3 != 3) goto LAB_00006923;
        uVar13 = 0xde;
        uVar12 = 0x1af;
        uVar11 = 0x95;
        uVar10 = 0x164;
      }
      goto LAB_00006918;
    }
    if (iVar3 == 0) {
      uVar13 = 0x199;
      uVar12 = 0x163;
      uVar11 = 0x150;
      uVar10 = 0x118;
      goto LAB_00006918;
    }
  }
LAB_00006923:
  _DrawToGWorld(PTR__g_00038024,PTR__g_00038024 + 0x2c,PTR__g_00038024,local_28,local_24,
                local_68[0xc],local_34,local_30,local_2c,1);
  iVar3 = _TickCount();
  *param_1 = iVar3;
  iVar3 = (int)local_1e;
  iVar5 = (int)local_20;
  if ((local_68[0] + 0x34 < iVar3 || iVar3 < local_68[0] + 0x17) ||
     (sVar7 = 0, local_98[0] + 0x36 < iVar5 || iVar5 < local_98[0] + 0x11)) {
    sVar7 = -9;
  }
  if ((iVar3 <= local_68[1] + 0x34 && local_68[1] + 0x17 <= iVar3) &&
     (iVar5 <= local_98[1] + 0x36 && local_98[1] + 0x11 <= iVar5)) {
    sVar7 = 1;
  }
  if ((iVar3 <= local_68[2] + 0x34 && local_68[2] + 0x17 <= iVar3) &&
     (iVar5 <= local_98[2] + 0x36 && local_98[2] + 0x11 <= iVar5)) {
    sVar7 = 2;
  }
  if ((iVar3 <= local_68[3] + 0x34 && local_68[3] + 0x17 <= iVar3) &&
     (iVar5 <= local_98[3] + 0x36 && local_98[3] + 0x11 <= iVar5)) {
    sVar7 = 3;
  }
  if ((iVar3 <= local_68[4] + 0x34 && local_68[4] + 0x17 <= iVar3) &&
     (iVar5 <= local_98[4] + 0x36 && local_98[4] + 0x11 <= iVar5)) {
    sVar7 = 4;
  }
  if ((iVar3 <= local_68[5] + 0x34 && local_68[5] + 0x17 <= iVar3) &&
     (iVar5 <= local_98[5] + 0x36 && local_98[5] + 0x11 <= iVar5)) {
    sVar7 = 5;
  }
  if ((iVar3 <= local_68[6] + 0x34 && local_68[6] + 0x17 <= iVar3) &&
     (iVar5 <= local_98[6] + 0x36 && local_98[6] + 0x11 <= iVar5)) {
    sVar7 = 6;
  }
  if ((iVar3 <= local_68[7] + 0x34 && local_68[7] + 0x17 <= iVar3) &&
     (iVar5 <= local_98[7] + 0x36 && local_98[7] + 0x11 <= iVar5)) {
    sVar7 = 7;
  }
  if ((iVar3 <= local_68[8] + 0x34 && local_68[8] + 0x17 <= iVar3) &&
     (iVar5 <= local_98[8] + 0x36 && local_98[8] + 0x11 <= iVar5)) {
    sVar7 = 8;
  }
  if ((iVar3 <= local_68[9] + 0x34 && local_68[9] + 0x17 <= iVar3) &&
     (iVar5 <= local_98[9] + 0x36 && local_98[9] + 0x11 <= iVar5)) {
    sVar7 = 9;
  }
  if ((iVar3 <= local_68[10] + 0x34 && local_68[10] + 0x17 <= iVar3) &&
     (iVar5 <= local_98[10] + 0x36 && local_98[10] + 0x11 <= iVar5)) {
    sVar7 = 10;
  }
  if ((local_68[0xb] + 0x34 < iVar3 || iVar3 < local_68[0xb] + 0x17) ||
     (local_98[0xb] + 0x36 < iVar5 || iVar5 < local_98[0xb] + 0x11)) {
    if (sVar7 == -9) {
      _SetRect(&local_28,0x207,0x2b,0x2f3,0xdf);
      _SetRect(piVar1,0x207,0x2b,0x2f3,0xdf);
      _DrawToGWorld(PTR__g_00038024 + 0x20,PTR__g_00038024 + 0x2c,PTR__g_00038024 + 0x20,local_28,
                    local_24,local_68[0xc],local_34,local_30,local_2c,0xfffffff7);
      *param_5 = -9;
      goto LAB_00006ce2;
    }
  }
  else {
    sVar7 = 0xb;
  }
  if (*param_5 == sVar7) goto LAB_00006ce2;
  _PlaySound(0x3c,0x80);
  _SetRect(&local_28,0,(int)(short)(sVar7 * 0xb5),0xec,(int)(short)(sVar7 * 0xb5 + 0xb4));
  _SetRect(piVar1,0x207,0x2b,0x2f2,0xde);
  puVar6 = PTR__g_00038024 + 0x2c;
  _DrawToGWorld(PTR__g_00038024 + 0x18,puVar6,PTR__g_00038024 + 0x18,local_28,local_24,local_68[0xc]
                ,local_34,local_30,local_2c,0xfffffff7);
  if (sVar7 < 3 || *(short *)(PTR__p_00038028 + 0x20e) % 2 == 1) {
    if (PTR__p_00038028[sVar7 + 0x200] == '\0') {
      _SetRect(&local_28,0,100,0xf0,0x96);
      goto LAB_00006c62;
    }
  }
  else {
    _SetRect(&local_28,0,0,0xf0,0x32);
LAB_00006c62:
    _SetRect(piVar1,0x206,0x6e,0x2f6,0xa0);
    _SetRect(&local_30,0,0x32,0xf0,100);
    _DrawToGWorld(PTR__g_00038024 + 0x28,puVar6,PTR__g_00038024 + 0x28,local_28,local_24,
                  local_68[0xc],local_34,local_30,local_2c,1);
  }
  *param_5 = sVar7;
LAB_00006ce2:
  _LoopMusic(0);
  _SetRect(&local_28,0,0,800,600);
  _SetRect(piVar1,0,0,800,600);
  _DrawToWindow(PTR__g_00038024 + 0x2c,local_28,local_24,local_68[0xc],local_34,1);
  return;
}


// ==== _RedrawMapScreen @ 000070cd ====

void _RedrawMapScreen(void)

{
  ushort uVar1;
  undefined *puVar2;
  int iVar3;
  undefined *puVar4;
  uint uVar5;
  short local_94 [48];
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  local_94[0x18] = 0x2c9;
  local_94[0x19] = 0;
  local_94[0x1a] = 0x193;
  local_94[0x1b] = 0;
  local_94[0x1c] = 0xe7;
  local_94[0x1d] = 0;
  local_94[0x1e] = 0x59;
  local_94[0x1f] = 0;
  local_94[0x20] = 0xc;
  local_94[0x21] = 0;
  local_94[0x22] = 0xea;
  local_94[0x23] = 0;
  local_94[0x24] = 0x146;
  local_94[0x25] = 0;
  local_94[0x26] = 0x163;
  local_94[0x27] = 0;
  local_94[0x28] = 0x223;
  local_94[0x29] = 0;
  local_94[0x2a] = 0x1b2;
  local_94[0x2b] = 0;
  local_94[0x2c] = 0x176;
  local_94[0x2d] = 0;
  local_94[0x2e] = 0x195;
  local_94[0x2f] = 0;
  local_94[0] = 0x136;
  local_94[1] = 0;
  local_94[2] = 0xb0;
  local_94[3] = 0;
  local_94[4] = 0x73;
  local_94[5] = 0;
  local_94[6] = 0x2d;
  local_94[7] = 0;
  local_94[8] = 0x10d;
  local_94[9] = 0;
  local_94[10] = 0x164;
  local_94[0xb] = 0;
  local_94[0xc] = 0x119;
  local_94[0xd] = 0;
  local_94[0xe] = 0x126;
  local_94[0xf] = 0;
  local_94[0x10] = 0x13b;
  local_94[0x11] = 0;
  local_94[0x12] = 0xdf;
  local_94[0x13] = 0;
  local_94[0x14] = 0xd8;
  local_94[0x15] = 0;
  local_94[0x16] = 0xf4;
  local_94[0x17] = 0;
  _SetRect(&local_24,0,0,800,600);
  _SetRect(&local_34,0,0,800,600);
  puVar4 = PTR__g_00038024 + 0x2c;
  puVar2 = PTR__g_00038024 + 0x34;
  _DrawToGWorld(PTR__g_00038024 + 0x20,puVar4,PTR__g_00038024 + 0x20,local_24,local_20,local_34,
                local_30,local_2c,local_28,0xfffffff7);
  _SetRect(&local_24,0,0x55,0x21,0x71);
  _SetRect(&local_2c,0,0x71,0x21,0x8d);
  _SetRect(&local_34,0x118,0x232,0x139,0x24e);
  _DrawToGWorld(puVar2,puVar4,puVar2,local_24,local_20,local_34,local_30,local_2c,local_28,1);
  _SetRect(&local_24,0x21,0x55,0x42,0x71);
  _SetRect(&local_2c,0x21,0x71,0x42,0x8d);
  _SetRect(&local_34,0x1df,0x232,0x200,0x24e);
  _DrawToGWorld(puVar2,puVar4,puVar2,local_24,local_20,local_34,local_30,local_2c,local_28,1);
  uVar1 = -(ushort)(PTR__p_00038028[0x200] == '\0') & 0xc;
  if (PTR__p_00038028[0x201] != '\0') {
    uVar1 = 1;
  }
  if (PTR__p_00038028[0x202] != '\0') {
    uVar1 = 2;
  }
  if (PTR__p_00038028[0x203] != '\0') {
    uVar1 = 3;
  }
  if (PTR__p_00038028[0x204] != '\0') {
    uVar1 = 4;
  }
  if (PTR__p_00038028[0x205] != '\0') {
    uVar1 = 5;
  }
  if (PTR__p_00038028[0x206] != '\0') {
    uVar1 = 6;
  }
  if (PTR__p_00038028[0x207] != '\0') {
    uVar1 = 7;
  }
  if (PTR__p_00038028[0x208] != '\0') {
    uVar1 = 8;
  }
  if (PTR__p_00038028[0x209] != '\0') {
    uVar1 = 9;
  }
  if (PTR__p_00038028[0x20a] != '\0') {
    uVar1 = 10;
  }
  if (PTR__p_00038028[0x20b] != '\0') {
    uVar1 = 0xb;
  }
  uVar5 = (uint)(short)uVar1;
  iVar3 = 0;
  puVar4 = PTR__p_00038028;
  if ((uVar5 & 1) == 0) goto LAB_00007513;
  if (uVar5 != 0) {
    while( true ) {
      _SetRect(&local_24,0xcd,0x150,0x118,0x199);
      _SetRect(&local_34,(int)local_94[iVar3 * 2 + 0x18],(int)local_94[iVar3 * 2],
               (int)(short)(local_94[iVar3 * 2 + 0x18] + 0x4a),
               (int)(short)(local_94[iVar3 * 2] + 0x48));
      _SetRect(&local_2c,0x118,0x150,0x163,0x199);
      if (puVar4[0x200] != '\0') {
        _DrawToGWorld(PTR__g_00038024,PTR__g_00038024 + 0x2c,PTR__g_00038024,local_24,local_20,
                      local_34,local_30,local_2c,local_28,1);
      }
      iVar3 = iVar3 + 1;
      puVar4 = puVar4 + 1;
LAB_00007513:
      if ((int)uVar5 <= iVar3) break;
      _SetRect(&local_24,0xcd,0x150,0x118,0x199);
      _SetRect(&local_34,(int)local_94[iVar3 * 2 + 0x18],(int)local_94[iVar3 * 2],
               (int)(short)(local_94[iVar3 * 2 + 0x18] + 0x4a),
               (int)(short)(local_94[iVar3 * 2] + 0x48));
      _SetRect(&local_2c,0x118,0x150,0x163,0x199);
      if (puVar4[0x200] != '\0') {
        _DrawToGWorld(PTR__g_00038024,PTR__g_00038024 + 0x2c,PTR__g_00038024,local_24,local_20,
                      local_34,local_30,local_2c,local_28,1);
      }
      iVar3 = iVar3 + 1;
      puVar4 = puVar4 + 1;
    }
  }
  puVar4 = PTR__p_00038028;
  _SetRect(&local_24,0x128,(int)(short)(*(short *)(PTR__p_00038028 + 0x20c) * 0x17 + 0xf1),0x17b,
           (int)(short)(*(short *)(PTR__p_00038028 + 0x20c) * 0x17 + 0x108));
  _SetRect(&local_34,0x163,0x235,0x1b6,0x24c);
  _SetRect(&local_2c,0x17b,(int)(short)(*(short *)(puVar4 + 0x20c) * 0x17 + 0xf1),0x1ce,
           (int)(short)(*(short *)(puVar4 + 0x20c) * 0x17 + 0x108));
  puVar2 = PTR__g_00038024;
  puVar4 = PTR__g_00038024 + 0x2c;
  _DrawToGWorld(PTR__g_00038024,puVar4,PTR__g_00038024,local_24,local_20,local_34,local_30,local_2c,
                local_28,1);
  _SetRect(&local_24,0,0,800,600);
  _SetRect(&local_34,0,0,800,600);
  _DrawToGWorld(puVar4,puVar2 + 0x30,puVar4,local_24,local_20,local_34,local_30,local_2c,local_28,
                0xfffffff7);
  if (puVar2[0x7d] != '\0') {
    _RandomProverbScreen();
  }
  puVar2[0x7d] = 0;
  if (puVar2[0x229] != '\0') {
    _CreateNewDialog(0x53);
  }
  if (puVar2[0x22a] != '\0') {
    _LoadCustomLevel();
  }
  puVar2[0x229] = 0;
  puVar2[0x22a] = 0;
  return;
}


// ==== _SelectMapArea @ 000078c2 ====

/* WARNING: Removing unreachable block (ram,0x00007a05) */
/* WARNING: Restarted to delay deadcode elimination for space: stack */

void _SelectMapArea(undefined4 param_1)

{
  undefined *puVar1;
  char cVar2;
  short sVar3;
  short sVar4;
  uint uVar5;
  undefined *puVar6;
  undefined *puVar7;
  undefined4 uVar8;
  undefined4 uVar9;
  undefined4 uVar10;
  undefined4 uVar11;
  undefined4 uVar12;
  undefined4 uVar13;
  short sVar14;
  undefined *puVar15;
  int iVar16;
  int iVar17;
  undefined4 uVar18;
  int local_8c [24];
  undefined1 local_2c [7];
  byte local_25;
  
  local_8c[0xc] = 0x2c9;
  local_8c[0xd] = 0x193;
  local_8c[0xe] = 0xe7;
  sVar3 = (short)param_1;
  sVar4 = (short)((uint)param_1 >> 0x10);
  local_8c[0xf] = 0x59;
  local_8c[0x10] = 0xc;
  local_8c[0x11] = 0xea;
  local_8c[0x12] = 0x146;
  local_8c[0x13] = 0x163;
  local_8c[0x14] = 0x223;
  local_8c[0x15] = 0x1b2;
  local_8c[0x16] = 0x176;
  local_8c[0x17] = 0x195;
  local_8c[0] = 0x136;
  local_8c[1] = 0xb0;
  local_8c[2] = 0x73;
  local_8c[3] = 0x2d;
  local_8c[4] = 0x10d;
  local_8c[5] = 0x164;
  local_8c[6] = 0x119;
  local_8c[7] = 0x126;
  local_8c[8] = 0x13b;
  local_8c[9] = 0xdf;
  local_8c[10] = 0xd8;
  local_8c[0xb] = 0xf4;
  _GetKeys(local_2c);
  uVar5 = (int)(uint)local_25 >> 2;
  *(undefined2 *)(PTR__g_00038024 + 0x90) = 0xfff7;
  puVar7 = PTR__p_00038028;
  if ((uVar5 & 1) == 0 && PTR__p_00038028[0x200] == '\0') {
    if (((int)sVar4 <= local_8c[0xc] + 0x34 && local_8c[0xc] + 0x17 <= (int)sVar4) &&
       ((int)sVar3 <= local_8c[0] + 0x36 && local_8c[0] + 0x11 <= (int)sVar3)) {
      _CreateNewDialog(0x28);
    }
  }
  else if (((int)sVar4 <= local_8c[0xc] + 0x34 && local_8c[0xc] + 0x17 <= (int)sVar4) &&
          ((int)sVar3 <= local_8c[0] + 0x36 && local_8c[0] + 0x11 <= (int)sVar3)) {
    *(undefined2 *)(PTR__g_00038024 + 0x90) = 0;
  }
  iVar17 = 0;
  while( true ) {
    iVar16 = iVar17;
    puVar6 = puVar7;
    iVar17 = iVar16 + 1;
    sVar14 = *(short *)(PTR__p_00038028 + 0x20e) % 2;
    if (2 < iVar17 && sVar14 == 1 || iVar17 < 3) {
      if ((uVar5 & 1) == 0 && puVar6[0x201] == '\0') {
        if ((((int)sVar4 <= local_8c[iVar16 + 0xd] + 0x34 &&
              local_8c[iVar16 + 0xd] + 0x17 <= (int)sVar4) &&
            ((int)sVar3 <= local_8c[iVar17] + 0x36 && local_8c[iVar17] + 0x11 <= (int)sVar3)) &&
           (sVar14 != 1 && iVar17 < 3 || sVar14 == 1)) {
          _CreateNewDialog(0x28);
        }
      }
      else if (((int)sVar4 <= local_8c[iVar16 + 0xd] + 0x34 &&
                local_8c[iVar16 + 0xd] + 0x17 <= (int)sVar4) &&
              ((int)sVar3 <= local_8c[iVar17] + 0x36 && local_8c[iVar17] + 0x11 <= (int)sVar3)) {
        *(short *)(PTR__g_00038024 + 0x90) = (short)iVar17;
      }
    }
    puVar1 = PTR__p_00038028;
    puVar15 = PTR__g_00038024;
    iVar17 = iVar16 + 2;
    puVar7 = puVar6 + 2;
    if (iVar17 == 0xc) break;
    sVar14 = *(short *)(PTR__p_00038028 + 0x20e) % 2;
    if (2 < iVar17 && sVar14 == 1 || iVar17 < 3) {
      if ((uVar5 & 1) == 0 && puVar6[0x202] == '\0') {
        if ((((int)sVar4 <= local_8c[iVar16 + 0xe] + 0x34 &&
              local_8c[iVar16 + 0xe] + 0x17 <= (int)sVar4) &&
            ((int)sVar3 <= local_8c[iVar17] + 0x36 && local_8c[iVar17] + 0x11 <= (int)sVar3)) &&
           (sVar14 != 1 && iVar17 < 3 || sVar14 == 1)) {
          _CreateNewDialog(0x28);
        }
      }
      else if (((int)sVar4 <= local_8c[iVar16 + 0xe] + 0x34 &&
                local_8c[iVar16 + 0xe] + 0x17 <= (int)sVar4) &&
              ((int)sVar3 <= local_8c[iVar17] + 0x36 && local_8c[iVar17] + 0x11 <= (int)sVar3)) {
        *(short *)(PTR__g_00038024 + 0x90) = (short)iVar17;
      }
    }
  }
  if (*(short *)(PTR__g_00038024 + 0x90) == -9) {
    return;
  }
  if ((PTR__p_00038028[0x201] == '\0') && (PTR__g_00038024[0x22b] == '\x01')) {
    _SplashScreen("guide",0);
  }
  puVar7 = PTR_s_NSAlert_000362b4;
  if ((*(short *)(puVar1 + 0x20c) == 3) && (puVar1[*(short *)(puVar15 + 0x90) + 0x201] == '\0')) {
    uVar8 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
    uVar8 = _objc_msgSend(uVar8,PTR_s_localizedStringForKey_value_tabl_000360c4,
                          &cf_Youwillnotbeabletoprogresstothenextlevelwhenplayinginpracticemode_,
                          &cf___,0);
    uVar9 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
    uVar9 = _objc_msgSend(uVar9,PTR_s_localizedStringForKey_value_tabl_000360c4,&cf_Cancel,&cf___,0)
    ;
    uVar10 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
    uVar10 = _objc_msgSend(uVar10,PTR_s_localizedStringForKey_value_tabl_000360c4,&cf_PracticeLevel,
                           &cf___,0);
    uVar11 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
    uVar11 = _objc_msgSend(uVar11,PTR_s_localizedStringForKey_value_tabl_000360c4,&cf_PracticeMode,
                           &cf___,0);
    uVar18 = 0;
    uVar12 = _objc_msgSend(puVar7,PTR_s_alertWithMessageText_defaultButt_00036154,uVar11,uVar10,
                           uVar9,0,uVar8);
    uVar13 = _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
    cVar2 = _objc_msgSend(uVar13,PTR_s_isFullscreen_00036064);
    if (cVar2 != '\0') {
      uVar13 = _objc_msgSend(uVar12,PTR_s_window_00036138,uVar11,uVar10,uVar9,uVar18,uVar8);
      _objc_msgSend(uVar13,PTR_s_scheduleSetShieldingLevel_00036158);
    }
    iVar17 = _objc_msgSend(uVar12,PTR_s_runModal_00036040,uVar11,uVar10,uVar9,uVar18,uVar8);
    puVar15 = PTR__g_00038024;
    PTR__g_00038024[0x7c] = iVar17 == 0;
  }
  puVar7 = puVar15;
  if (puVar15[0x7c] == '\0') {
    if (PTR__p_00038028[0x214] != '\0') {
      _objc_msgSend(PTR_s_LevelDescriptionWindowController_000362c0,
                    PTR_s_runModalWithLayout_custom__000361b4,(int)*(short *)(puVar15 + 0x90),0);
    }
    puVar7 = PTR__g_00038024;
    if (puVar15[0x7c] == '\0') {
      _LoadLayout();
      puVar7 = PTR__g_00038024;
      goto LAB_00007dd2;
    }
  }
  puVar7[0x7c] = 0;
LAB_00007dd2:
  *(int *)(puVar7 + 0xc4) = *(int *)(puVar7 + 0xc4) + *(int *)(puVar7 + 0xb4) * -0x3c;
  return;
}


// ==== _SelectMenuOptions @ 00008041 ====

void _SelectMenuOptions(undefined4 param_1)

{
  undefined *puVar1;
  short sVar2;
  undefined4 uVar3;
  undefined *puVar4;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  sVar2 = (short)((uint)param_1 >> 0x10);
  if ((ushort)(sVar2 - 0x20U) < 0x9e) {
    uVar3 = _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
    _objc_msgSend(uVar3,PTR_s_showPreferences__000361b8,0);
  }
  else if ((ushort)(sVar2 - 0x256U) < 0xa8) {
    _objc_msgSend(*(undefined4 *)PTR_00038014,PTR_s_terminate__000361bc,0);
    PTR__g_00038024[100] = 1;
  }
  else {
    if ((ushort)(sVar2 - 0x140U) < 0xc4) {
      _SetRect(&local_24,0x1df,0x232,0x200,0x24e);
      _SetRect(&local_34,0x1df,0x232,0x200,0x24e);
      puVar1 = PTR__g_00038024 + 0x2c;
      puVar4 = PTR__g_00038024 + 0x34;
      _DrawToGWorld(PTR__g_00038024 + 0x20,puVar1,PTR__g_00038024 + 0x20,local_24,local_20,local_34,
                    local_30,local_2c,local_28,0xfffffff7);
      _SetRect(&local_24,0x21,0x55,0x42,0x71);
      _SetRect(&local_2c,0x21,0x71,0x42,0x8d);
      _SetRect(&local_34,0x1e1,0x234,0x202,0x250);
      _DrawToGWorld(puVar4,puVar1,puVar4,local_24,local_20,local_34,local_30,local_2c,local_28,1);
      _SetRect(&local_24,0x1df,0x232,0x200,0x24e);
      _SetRect(&local_34,0x1df,0x232,0x200,0x24e);
      _DrawToWindow(puVar1,local_24,local_20,local_34,local_30,1);
      _PlaySound(10,0x100);
      sVar2 = 3;
      if (-1 < (short)(*(short *)(PTR__p_00038028 + 0x20c) + -1)) {
        sVar2 = *(short *)(PTR__p_00038028 + 0x20c) + -1;
      }
    }
    else {
      if (0x1f < (ushort)(sVar2 - 0x11cU)) {
        return;
      }
      _SetRect(&local_24,0x118,0x232,0x139,0x24e);
      _SetRect(&local_34,0x118,0x232,0x139,0x24e);
      puVar1 = PTR__g_00038024 + 0x2c;
      puVar4 = PTR__g_00038024 + 0x34;
      _DrawToGWorld(PTR__g_00038024 + 0x20,puVar1,PTR__g_00038024 + 0x20,local_24,local_20,local_34,
                    local_30,local_2c,local_28,0xfffffff7);
      _SetRect(&local_24,0,0x55,0x21,0x71);
      _SetRect(&local_2c,0,0x71,0x21,0x8d);
      _SetRect(&local_34,0x11a,0x234,0x13b,0x250);
      _DrawToGWorld(puVar4,puVar1,puVar4,local_24,local_20,local_34,local_30,local_2c,local_28,1);
      _SetRect(&local_24,0x118,0x232,0x139,0x24e);
      _SetRect(&local_34,0x118,0x232,0x139,0x24e);
      _DrawToWindow(puVar1,local_24,local_20,local_34,local_30,1);
      _PlaySound(10,0x100);
      sVar2 = 0;
      if ((short)(*(short *)(PTR__p_00038028 + 0x20c) + 1) < 4) {
        sVar2 = *(short *)(PTR__p_00038028 + 0x20c) + 1;
      }
    }
    puVar1 = PTR__p_00038028;
    *(short *)(PTR__p_00038028 + 0x20c) = sVar2;
    _RedrawMapScreen();
    _SavePrefs(puVar1);
  }
  return;
}


// ==== _AnimationEditorScreenToMap @ 00008598 ====

void _AnimationEditorScreenToMap(void)

{
  undefined2 uVar1;
  int iVar2;
  undefined *puVar3;
  undefined4 uVar4;
  undefined4 uVar5;
  undefined4 *puVar6;
  int iVar7;
  int iVar8;
  short sVar9;
  undefined *puVar10;
  float fVar11;
  uint local_a4;
  short asStack_98 [50];
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  puVar3 = PTR__g_00038024;
  iVar7 = 1;
  asStack_98[0x1a] = 0x2c9;
  asStack_98[0x1b] = 0;
  asStack_98[0x1c] = 0x193;
  asStack_98[0x1d] = 0;
  asStack_98[0x1e] = 0xe7;
  asStack_98[0x1f] = 0;
  uVar1 = *(undefined2 *)(PTR__g_00038024 + 0x5c);
  asStack_98[0x20] = 0x59;
  asStack_98[0x21] = 0;
  *(undefined2 *)(PTR__g_00038024 + 0x5c) = 0;
  asStack_98[0x22] = 0xc;
  asStack_98[0x23] = 0;
  *(undefined2 *)(puVar3 + 0x5e) = uVar1;
  asStack_98[0x24] = 0xea;
  asStack_98[0x25] = 0;
  asStack_98[0x26] = 0x146;
  asStack_98[0x27] = 0;
  asStack_98[0x28] = 0x163;
  asStack_98[0x29] = 0;
  asStack_98[0x2a] = 0x223;
  asStack_98[0x2b] = 0;
  asStack_98[0x2c] = 0x1b2;
  asStack_98[0x2d] = 0;
  asStack_98[0x2e] = 0x176;
  asStack_98[0x2f] = 0;
  asStack_98[0x30] = 0x195;
  asStack_98[0x31] = 0;
  asStack_98[2] = 0x136;
  asStack_98[3] = 0;
  asStack_98[4] = 0xb0;
  asStack_98[5] = 0;
  asStack_98[6] = 0x73;
  asStack_98[7] = 0;
  asStack_98[8] = 0x2d;
  asStack_98[9] = 0;
  asStack_98[10] = 0x10d;
  asStack_98[0xb] = 0;
  asStack_98[0xc] = 0x164;
  asStack_98[0xd] = 0;
  asStack_98[0xe] = 0x119;
  asStack_98[0xf] = 0;
  asStack_98[0x10] = 0x126;
  asStack_98[0x11] = 0;
  asStack_98[0x12] = 0x13b;
  asStack_98[0x13] = 0;
  asStack_98[0x14] = 0xdf;
  asStack_98[0x15] = 0;
  asStack_98[0x16] = 0xd8;
  asStack_98[0x17] = 0;
  asStack_98[0x18] = 0xf4;
  asStack_98[0x19] = 0;
  _SetRect(&local_24,0,0,800,600);
  _SetRect(&local_34,0,0,800,600);
  _DrawToGWorld(puVar3 + 0x20,puVar3 + 0x2c,puVar3 + 0x20,local_24,local_20,local_34,local_30,
                local_2c,local_28,0xfffffff7);
  puVar10 = PTR__p_00038028;
  do {
    _SetRect(&local_24,0xcd,0x150,0x118,0x199);
    _SetRect(&local_34,(int)asStack_98[iVar7 * 2 + 0x18],(int)asStack_98[iVar7 * 2],
             (int)(short)(asStack_98[iVar7 * 2 + 0x18] + 0x4a),
             (int)(short)(asStack_98[iVar7 * 2] + 0x48));
    _SetRect(&local_2c,0x118,0x150,0x163,0x199);
    if (puVar10[0x200] != '\0') {
      _DrawToGWorld(puVar3,puVar3 + 0x2c,puVar3,local_24,local_20,local_34,local_30,local_2c,
                    local_28,1);
    }
    _SetRect(&local_24,0xcd,0x150,0x118,0x199);
    _SetRect(&local_34,(int)asStack_98[(iVar7 + 1) * 2 + 0x18],(int)asStack_98[(iVar7 + 1) * 2],
             (int)(short)(asStack_98[(iVar7 + 1) * 2 + 0x18] + 0x4a),
             (int)(short)(asStack_98[(iVar7 + 1) * 2] + 0x48));
    _SetRect(&local_2c,0x118,0x150,0x163,0x199);
    if (puVar10[0x201] != '\0') {
      _DrawToGWorld(puVar3,puVar3 + 0x2c,puVar3,local_24,local_20,local_34,local_30,local_2c,
                    local_28,1);
    }
    iVar7 = iVar7 + 2;
    puVar10 = puVar10 + 2;
  } while (iVar7 != 0xd);
  _SetRect(&local_24,0,0,800,600);
  _SetRect(&local_34,0,0,800,600);
  puVar3 = PTR__g_00038024;
  _DrawToGWorld(PTR__g_00038024 + 0x14,PTR__g_00038024 + 0x30,PTR__g_00038024 + 0x14,local_24,
                local_20,local_34,local_30,local_2c,local_28,0xfffffff7);
  puVar6 = *(undefined4 **)(puVar3 + 0x58);
  if (1 < *(short *)(PTR__p_00038028 + 0x20e)) {
    for (; puVar6 != (undefined4 *)0x0; puVar6 = (undefined4 *)puVar6[0x42]) {
      if (*(short *)(puVar6 + 1) == *(short *)(PTR__g_00038024 + 0x5c)) {
        _SetMovieVolume(*puVar6,0x80);
        _StartMovie(*puVar6);
      }
    }
  }
  iVar7 = _TickCount();
  do {
    iVar2 = _TickCount();
    if ((uint)(iVar2 - iVar7) < 0x3d) {
      iVar2 = _TickCount();
      local_a4 = iVar2 - iVar7;
      fVar11 = (float)(local_a4 >> 0x10) * FLOAT_00033b30 + (float)(local_a4 & 0xffff);
    }
    else {
      local_a4 = 0x3c;
      fVar11 = FLOAT_00033b2c;
    }
    sVar9 = (short)(int)((fVar11 / FLOAT_00033b2c) * FLOAT_00033b34 + FLOAT_00033b38);
    iVar2 = (int)(short)(400 - sVar9);
    iVar8 = (int)(short)(sVar9 + 400);
    _SetRect(&local_24,(int)sVar9,0,400,600);
    _SetRect(&local_34,0,0,iVar2,600);
    puVar3 = PTR__g_00038024 + 0x2c;
    _DrawToWindow(puVar3,local_24,local_20,local_34,local_30,0);
    _SetRect(&local_24,iVar2,0,iVar8,600);
    _SetRect(&local_34,iVar2,0,iVar8,600);
    _DrawToWindow(PTR__g_00038024 + 0x30,local_24,local_20,local_34,local_30,0);
    _SetRect(&local_24,400,0,(int)(short)(800 - sVar9),600);
    _SetRect(&local_34,iVar8,0,800,600);
    _DrawToWindow(puVar3,local_24,local_20,local_34,local_30,1);
    puVar3 = PTR__g_00038024;
  } while (local_a4 < 0x3c);
  PTR__g_00038024[0x80] = 0;
  puVar3[0x66] = 0;
  _RedrawMapScreen();
  puVar3[0x1f0] = 0;
  puVar3[0x1f1] = 0;
  uVar4 = _GetMenuHandle(2);
  uVar5 = _CFStringCreateMutable(*(undefined4 *)PTR_00038034,0);
  _CFStringAppendCString(uVar5,"Open Level Editor",0x600);
  _SetMenuItemTextWithCFString(uVar4,1,uVar5);
  _CFRelease(uVar5);
  return;
}


// ==== _RedrawLayerButtons @ 00008d0d ====

void _RedrawLayerButtons(undefined1 param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  short sVar3;
  short sVar4;
  short sVar5;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  _SetRect(&local_24,0x624,0,0x936,0x44);
  _SetRect(&local_34,7,0x214,0x319,600);
  _SetRect(&local_2c,0x312,0,0x624,0x44);
  puVar1 = PTR__g_00038024 + 0x30;
  puVar2 = PTR__g_00038024 + 0x40;
  _DrawToGWorld(PTR__g_00038024 + 0x1c,puVar1,PTR__g_00038024 + 0x1c,local_24,local_20,local_34,
                local_30,local_2c,local_28,1);
  sVar4 = 0x20;
  sVar5 = 0x40;
  if (_edlayer == 0) {
    sVar4 = 0;
    sVar5 = 0x20;
  }
  sVar3 = sVar5;
  if (_visibleLayer < 0) {
    sVar3 = sVar5 + 0x20;
    sVar4 = sVar5;
  }
  _SetRect(&local_24,0,sVar4,0x20,sVar3);
  _SetRect(&local_34,0x25,0x22b,0x45,0x24b);
  _SetRect(&local_2c,0,0x60,0x20,0x80);
  _DrawToGWorld(puVar2,puVar1,puVar2,local_24,local_20,local_34,local_30,local_2c,local_28,1);
  sVar4 = 0x20;
  sVar5 = 0x40;
  if (_edlayer == 1) {
    sVar4 = 0;
    sVar5 = 0x20;
  }
  sVar3 = sVar5;
  if (_visibleLayer < 1) {
    sVar3 = sVar5 + 0x20;
    sVar4 = sVar5;
  }
  _SetRect(&local_24,0x20,sVar4,0x40,sVar3);
  _SetRect(&local_34,0x4f,0x22b,0x6f,0x24b);
  _SetRect(&local_2c,0,0x60,0x20,0x80);
  _DrawToGWorld(puVar2,puVar1,puVar2,local_24,local_20,local_34,local_30,local_2c,local_28,1);
  sVar4 = 0x20;
  sVar5 = 0x40;
  if (_edlayer == 2) {
    sVar4 = 0;
    sVar5 = 0x20;
  }
  sVar3 = sVar5;
  if (_visibleLayer < 2) {
    sVar3 = sVar5 + 0x20;
    sVar4 = sVar5;
  }
  _SetRect(&local_24,0x40,sVar4,0x60,sVar3);
  _SetRect(&local_34,0x79,0x22b,0x99,0x24b);
  _SetRect(&local_2c,0,0x60,0x20,0x80);
  _DrawToGWorld(puVar2,puVar1,puVar2,local_24,local_20,local_34,local_30,local_2c,local_28,1);
  sVar4 = 0x20;
  sVar5 = 0x40;
  if (_edlayer == 3) {
    sVar4 = 0;
    sVar5 = 0x20;
  }
  sVar3 = sVar5;
  if (_visibleLayer < 3) {
    sVar3 = sVar5 + 0x20;
    sVar4 = sVar5;
  }
  _SetRect(&local_24,0x60,sVar4,0x80,sVar3);
  _SetRect(&local_34,0xa3,0x22b,0xc3,0x24b);
  _SetRect(&local_2c,0,0x60,0x20,0x80);
  _DrawToGWorld(puVar2,puVar1,puVar2,local_24,local_20,local_34,local_30,local_2c,local_28,1);
  sVar4 = 0x20;
  sVar5 = 0x40;
  if (_edlayer == 4) {
    sVar4 = 0;
    sVar5 = 0x20;
  }
  sVar3 = sVar5;
  if (_visibleLayer < 4) {
    sVar3 = sVar5 + 0x20;
    sVar4 = sVar5;
  }
  _SetRect(&local_24,0x80,sVar4,0xa0,sVar3);
  _SetRect(&local_34,0xcd,0x22b,0xed,0x24b);
  _SetRect(&local_2c,0,0x60,0x20,0x80);
  _DrawToGWorld(puVar2,puVar1,puVar2,local_24,local_20,local_34,local_30,local_2c,local_28,1);
  sVar4 = 0x20;
  sVar5 = 0x40;
  if (_edlayer == 5) {
    sVar4 = 0;
    sVar5 = 0x20;
  }
  sVar3 = sVar5;
  if (_visibleLayer < 5) {
    sVar3 = sVar5 + 0x20;
    sVar4 = sVar5;
  }
  _SetRect(&local_24,0xa0,sVar4,0xc0,sVar3);
  _SetRect(&local_34,0xf7,0x22b,0x117,0x24b);
  _SetRect(&local_2c,0,0x60,0x20,0x80);
  _DrawToGWorld(puVar2,puVar1,puVar2,local_24,local_20,local_34,local_30,local_2c,local_28,1);
  sVar4 = 0;
  sVar5 = 0x20;
  if (_edlayer != 6) {
    sVar4 = 0x20;
    sVar5 = 0x40;
  }
  sVar3 = sVar5;
  if (_visibleLayer < 6) {
    sVar3 = sVar5 + 0x20;
    sVar4 = sVar5;
  }
  _SetRect(&local_24,0xc0,sVar4,0xe0,sVar3);
  _SetRect(&local_34,0x121,0x22b,0x141,0x24b);
  _SetRect(&local_2c,0,0x60,0x20,0x80);
  _DrawToGWorld(puVar2,puVar1,puVar2,local_24,local_20,local_34,local_30,local_2c,local_28,1);
  _SetRect(&local_34,0x25,0x22b,0x141,0x24b);
  _DrawToWindow(puVar1,local_34,local_30,local_34,local_30,param_1);
  return;
}


// ==== _RedrawNudgeArrows @ 0000956a ====

void _RedrawNudgeArrows(short param_1,undefined1 param_2)

{
  undefined2 uVar1;
  undefined2 uVar2;
  undefined *puVar3;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  _SetRect(&local_24,0x624,0,0x936,0x44);
  _SetRect(&local_34,7,0x214,0x319,600);
  _SetRect(&local_2c,0x312,0,0x624,0x44);
  _DrawToGWorld(PTR__g_00038024 + 0x1c,PTR__g_00038024 + 0x30,PTR__g_00038024 + 0x1c,local_24,
                local_20,local_34,local_30,local_2c,local_28,1);
  uVar1 = 0xb4;
  uVar2 = 0x8b;
  if (param_1 != 0) {
    uVar1 = 0x8b;
    uVar2 = 0x62;
  }
  _SetRect(&local_24,0x3b,uVar2,100,uVar1);
  _SetRect(&local_34,0x16f,0x228,0x198,0x251);
  _SetRect(&local_2c,0x3b,0xdb,100,0x104);
  _DrawToGWorld(PTR__g_00038024 + 0x40,PTR__g_00038024 + 0x30,PTR__g_00038024 + 0x40,local_24,
                local_20,local_34,local_30,local_2c,local_28,1);
  uVar1 = 0x8b;
  uVar2 = 0x62;
  if (param_1 == 1) {
    uVar1 = 0xb4;
    uVar2 = 0x8b;
  }
  _SetRect(&local_24,100,uVar2,0x8d,uVar1);
  _SetRect(&local_34,0x19e,0x228,0x1c7,0x251);
  _SetRect(&local_2c,100,0xdb,0x8d,0x104);
  _DrawToGWorld(PTR__g_00038024 + 0x40,PTR__g_00038024 + 0x30,PTR__g_00038024 + 0x40,local_24,
                local_20,local_34,local_30,local_2c,local_28,1);
  uVar1 = 0x8b;
  uVar2 = 0x62;
  if (param_1 == 2) {
    uVar1 = 0xb4;
    uVar2 = 0x8b;
  }
  _SetRect(&local_24,0x8d,uVar2,0xb6,uVar1);
  _SetRect(&local_34,0x1cd,0x228,0x1f6,0x251);
  _SetRect(&local_2c,0x8d,0xdb,0xb6,0x104);
  _DrawToGWorld(PTR__g_00038024 + 0x40,PTR__g_00038024 + 0x30,PTR__g_00038024 + 0x40,local_24,
                local_20,local_34,local_30,local_2c,local_28,1);
  uVar1 = 0x8b;
  uVar2 = 0x62;
  if (param_1 == 3) {
    uVar1 = 0xb4;
    uVar2 = 0x8b;
  }
  _SetRect(&local_24,0xb6,uVar2,0xdf,uVar1);
  _SetRect(&local_34,0x1fc,0x228,0x225,0x251);
  _SetRect(&local_2c,0xb6,0xdb,0xdf,0x104);
  puVar3 = PTR__g_00038024 + 0x30;
  _DrawToGWorld(PTR__g_00038024 + 0x40,puVar3,PTR__g_00038024 + 0x40,local_24,local_20,local_34,
                local_30,local_2c,local_28,1);
  _SetRect(&local_34,0x16f,0x228,0x254,0x251);
  _DrawToWindow(puVar3,local_34,local_30,local_34,local_30,param_2);
  return;
}


// ==== _CountTiles @ 00009a39 ====

int _CountTiles(void)

{
  int iVar1;
  short sVar2;
  
  sVar2 = 0;
  for (iVar1 = *(int *)PTR__gFirstPtr_00034034; iVar1 != 0; iVar1 = *(int *)(iVar1 + 0x14)) {
    sVar2 = sVar2 + 1;
  }
  PTR__g_00038024[0x1f2] = sVar2 == 0x90;
  return (int)sVar2;
}


// ==== _DrawEditorTiles @ 00009a66 ====

void _DrawEditorTiles(void)

{
  short sVar1;
  undefined *puVar2;
  short sVar3;
  undefined *puVar4;
  short sVar5;
  undefined *puVar6;
  int iVar7;
  short sVar8;
  short sVar9;
  int iVar10;
  int iVar11;
  short *local_54;
  short local_4c;
  short local_4a;
  int local_48;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  _SetRect(&local_24,0,0,800,600);
  _SetRect(&local_2c,0,0,800,600);
  puVar2 = PTR__g_00038024;
  _DrawToGWorld(PTR__g_00038024 + 0x14,PTR__g_00038024 + 0x38,PTR__g_00038024 + 0x14,local_24,
                local_20,local_2c,local_28,local_34,local_30,0xfffffff7);
  sVar1 = 0;
  do {
    if (_visibleLayer < sVar1) {
      return;
    }
    local_48 = 0;
    do {
      local_4c = 0x20;
      local_4a = (short)local_48;
      do {
        if (local_4a < 0) break;
        puVar6 = puVar2 + 0x38;
        puVar4 = puVar2 + 4;
        for (local_54 = *(short **)PTR__gFirstPtr_00034034; local_54 != (short *)0x0;
            local_54 = *(short **)(local_54 + 10)) {
          sVar3 = *local_54;
          if (((double)(int)local_4a == *(double *)(local_54 + 2) &&
              (double)(int)local_4c == *(double *)(local_54 + 6)) && sVar3 == sVar1) {
            sVar8 = (short)(int)(*(double *)(local_54 + 2) * DOUBLE_00033f98 * DOUBLE_00033fa0) +
                    sVar3 * -10;
            sVar5 = (short)(int)(*(double *)(local_54 + 6) * DOUBLE_00033fa8 * DOUBLE_00033fa0) +
                    sVar3 * 5;
            _SetRect(&local_24,0,0,0x35,0x45);
            iVar7 = (int)sVar5;
            _SetRect(&local_2c,iVar7,(int)sVar8,(int)(short)(sVar5 + 0x35),
                     (int)(short)(sVar8 + 0x45));
            _SetRect(&local_34,0,0x114,0x36,0x159);
            _DrawToGWorld(puVar4,puVar6,puVar4,local_24,local_20,local_2c,local_28,local_34,local_30
                          ,1);
            sVar3 = *local_54;
            if (sVar3 != _edlayer) {
              _SetRect(&local_24,0,0xcf,0x35,0x114);
              _SetRect(&local_2c,iVar7,(int)sVar8,(int)(short)(sVar5 + 0x35),
                       (int)(short)(sVar8 + 0x45));
              _SetRect(&local_34,0,0x2f7,0x35,0x33c);
              _DrawToGWorld(puVar4,puVar6,puVar4,local_24,local_20,local_2c,local_28,local_34,
                            local_30,1);
              sVar3 = *local_54;
            }
            sVar9 = 10;
            if ((short)(sVar3 + 1) != 0) {
              sVar9 = sVar3 + 1;
            }
            iVar11 = (int)(short)(sVar9 * 0x1e + 0x75);
            iVar10 = (int)(short)(sVar9 * 0x1e + 0x57);
            _SetRect(&local_24,0x9b,iVar10,0xb3,iVar11);
            _SetRect(&local_2c,(int)(short)(sVar5 + 5),(int)(short)(sVar8 + 0x23),
                     (int)(short)(sVar5 + 0x19),(int)(short)(sVar8 + 0x37));
            _SetRect(&local_34,0xb4,iVar10,0xcc,iVar11);
            _DrawToGWorld(puVar2,puVar6,puVar2,local_24,local_20,local_2c,local_28,local_34,local_30
                          ,1);
            _SetRect(&local_24,iVar7,(int)(short)(sVar8 + 1),(int)(short)(sVar5 + 0x33),
                     (int)(short)(sVar8 + 0x43));
            _SetRect(&local_2c,iVar7,(int)(short)(sVar8 + 1),(int)(short)(sVar5 + 0x33),
                     (int)(short)(sVar8 + 0x43));
            _DrawToGWorld(puVar6,puVar2 + 0x2c,puVar6,local_24,local_20,local_2c,local_28,local_34,
                          local_30,0xfffffff7);
          }
        }
        local_4c = local_4c + -1;
        local_4a = local_4a + -1;
      } while (local_4c != -1);
      local_48 = local_48 + 1;
    } while (local_48 != 0x32);
    sVar1 = sVar1 + 1;
  } while( true );
}


// ==== _DrawTempToWindow @ 00009f92 ====

void _DrawTempToWindow(void)

{
  undefined *puVar1;
  undefined4 local_24;
  undefined4 local_20;
  undefined4 local_1c;
  undefined4 local_18;
  undefined4 local_14;
  undefined4 local_10;
  
  _SetRect(&local_24,0,0,800,0x213);
  _SetRect(&local_1c,0,0,800,0x213);
  puVar1 = PTR__g_00038024 + 0x2c;
  _DrawToGWorld(PTR__g_00038024 + 0x14,puVar1,PTR__g_00038024 + 0x14,local_24,local_20,local_1c,
                local_18);
  _DrawEditorTiles();
  _SetRect(&local_14,0,0,800,0x213);
  _DrawToWindow(puVar1,local_14,local_10,local_14,local_10,1);
  _RedrawNudgeArrows(9,1);
  return;
}


// ==== _SlideLeft @ 0000a0a9 ====

void _SlideLeft(void)

{
  double dVar1;
  int iVar2;
  
  iVar2 = *(int *)PTR__gFirstPtr_00034034;
  while( true ) {
    if (iVar2 == 0) {
      _RedrawNudgeArrows(0,1);
      dVar1 = DOUBLE_00033fb0;
      for (iVar2 = *(int *)PTR__gFirstPtr_00034034; iVar2 != 0; iVar2 = *(int *)(iVar2 + 0x14)) {
        *(double *)(iVar2 + 0xc) = *(double *)(iVar2 + 0xc) - dVar1;
      }
      PTR__g_00038024[0x1f0] = 1;
      _DrawTempToWindow();
      return;
    }
    if (*(double *)(iVar2 + 0xc) == 0.0) break;
    iVar2 = *(int *)(iVar2 + 0x14);
  }
  return;
}


// ==== _SlideUp @ 0000a120 ====

void _SlideUp(void)

{
  double dVar1;
  int iVar2;
  
  iVar2 = *(int *)PTR__gFirstPtr_00034034;
  while( true ) {
    if (iVar2 == 0) {
      _RedrawNudgeArrows(1,1);
      dVar1 = DOUBLE_00033fb0;
      for (iVar2 = *(int *)PTR__gFirstPtr_00034034; iVar2 != 0; iVar2 = *(int *)(iVar2 + 0x14)) {
        *(double *)(iVar2 + 4) = *(double *)(iVar2 + 4) - dVar1;
      }
      PTR__g_00038024[0x1f0] = 1;
      _DrawTempToWindow();
      return;
    }
    if (*(double *)(iVar2 + 4) == 0.0) break;
    iVar2 = *(int *)(iVar2 + 0x14);
  }
  return;
}


// ==== _SlideDown @ 0000a197 ====

void _SlideDown(void)

{
  double dVar1;
  int iVar2;
  
  iVar2 = *(int *)PTR__gFirstPtr_00034034;
  while( true ) {
    if (iVar2 == 0) {
      _RedrawNudgeArrows(2,1);
      dVar1 = DOUBLE_00033fb0;
      for (iVar2 = *(int *)PTR__gFirstPtr_00034034; iVar2 != 0; iVar2 = *(int *)(iVar2 + 0x14)) {
        *(double *)(iVar2 + 4) = *(double *)(iVar2 + 4) + dVar1;
      }
      PTR__g_00038024[0x1f0] = 1;
      _DrawTempToWindow();
      return;
    }
    if (DOUBLE_00033fb8 == *(double *)(iVar2 + 4)) break;
    iVar2 = *(int *)(iVar2 + 0x14);
  }
  return;
}


// ==== _SlideRight @ 0000a212 ====

void _SlideRight(void)

{
  double dVar1;
  int iVar2;
  
  iVar2 = *(int *)PTR__gFirstPtr_00034034;
  while( true ) {
    if (iVar2 == 0) {
      _RedrawNudgeArrows(3,1);
      dVar1 = DOUBLE_00033fb0;
      for (iVar2 = *(int *)PTR__gFirstPtr_00034034; iVar2 != 0; iVar2 = *(int *)(iVar2 + 0x14)) {
        *(double *)(iVar2 + 0xc) = *(double *)(iVar2 + 0xc) + dVar1;
      }
      PTR__g_00038024[0x1f0] = 1;
      _DrawTempToWindow();
      return;
    }
    if (DOUBLE_00033fc0 == *(double *)(iVar2 + 0xc)) break;
    iVar2 = *(int *)(iVar2 + 0x14);
  }
  return;
}


// ==== _SelectLevelButton @ 0000a28d ====

void _SelectLevelButton(undefined4 param_1,short param_2,char param_3)

{
  undefined *puVar1;
  short sVar2;
  
  if (param_2 == 0) {
    sVar2 = (short)((uint)param_1 >> 0x10);
    if (sVar2 < 0x46 && 0x24 < sVar2) {
      _edlayer = 0;
    }
    if (sVar2 < 0x70 && 0x4e < sVar2) {
      _edlayer = 1;
    }
    if (sVar2 < 0x9a && 0x78 < sVar2) {
      _edlayer = 2;
    }
    if (sVar2 < 0xc4 && 0xa2 < sVar2) {
      _edlayer = 3;
    }
    if (sVar2 < 0xee && 0xcc < sVar2) {
      _edlayer = 4;
    }
    if (sVar2 < 0x118 && 0xf6 < sVar2) {
      _edlayer = 5;
    }
    if (sVar2 < 0x142 && 0x120 < sVar2) {
      _edlayer = 6;
    }
    _visibleLayer = 6;
    if (param_3 != '\0') {
      _visibleLayer = _edlayer;
    }
    if (sVar2 < 0x199 && 0x16e < sVar2) {
      _SlideLeft();
    }
    if (sVar2 < 0x1c8 && 0x19d < sVar2) {
      _SlideUp();
    }
    if (sVar2 < 0x1f7 && 0x1cc < sVar2) {
      _SlideDown();
    }
    if (sVar2 < 0x226 && 0x1fb < sVar2) {
      _SlideRight();
    }
  }
  else {
    _edlayer = param_2 + -1;
    _visibleLayer = 6;
    if (param_3 != '\0') {
      _visibleLayer = _edlayer;
    }
  }
  puVar1 = PTR__g_00038024;
  *(undefined8 *)(PTR__g_00038024 + 0x74) = 0;
  *(undefined8 *)(puVar1 + 0x6c) = 0;
  _RedrawLayerButtons(0);
  _DrawTempToWindow();
  return;
}


// ==== _WriteStruct @ 0000a47a ====

void _WriteStruct(void)

{
  undefined *puVar1;
  undefined2 *puVar2;
  
  puVar2 = _malloc(0x1c);
  puVar1 = PTR__g_00038024;
  *puVar2 = *(undefined2 *)(PTR__g_00038024 + 0x1e8);
  *(undefined8 *)(puVar2 + 6) = *(undefined8 *)(puVar1 + 0x1d8);
  *(undefined8 *)(puVar2 + 2) = *(undefined8 *)(puVar1 + 0x1e0);
  return;
}


// ==== _RemoveTile @ 0000a531 ====

void _RemoveTile(undefined2 *param_1)

{
  int iVar1;
  int iVar2;
  undefined *puVar3;
  undefined *puVar4;
  
  *(short *)PTR__undoCol_0003402c = (short)(int)*(double *)(param_1 + 6);
  *(short *)PTR__undoRow_00034020 = (short)(int)*(double *)(param_1 + 2);
  *(undefined2 *)PTR__undoLayer_00034030 = *param_1;
  puVar4 = PTR__gFirstPtr_00034034;
  puVar3 = PTR__gLastPtr_00034024;
  iVar1 = *(int *)(param_1 + 0xc);
  iVar2 = *(int *)(param_1 + 10);
  if (iVar2 != 0 || iVar1 != 0) {
    if (iVar2 != 0) {
      if (iVar1 != 0) {
        *(int *)(iVar2 + 0x18) = iVar1;
        *(int *)(*(int *)(param_1 + 0xc) + 0x14) = iVar2;
      }
      else {
        *(undefined4 *)(iVar2 + 0x18) = 0;
        *(int *)puVar4 = iVar2;
      }
    }
    else {
      *(undefined4 *)(iVar1 + 0x14) = 0;
      *(int *)puVar3 = iVar1;
    }
  }
  else {
    *(undefined4 *)PTR__gLastPtr_00034024 = 0;
    *(undefined4 *)PTR__gFirstPtr_00034034 = 0;
  }
  _free((void *)0x0);
  _PlaySound(0x5a,0x80);
  return;
}


// ==== _CheckNotOverlap @ 0000a5e5 ====

undefined1 _CheckNotOverlap(undefined1 param_1)

{
  double dVar1;
  double dVar2;
  double dVar3;
  double dVar4;
  bool bVar5;
  bool bVar6;
  bool bVar7;
  bool bVar8;
  bool bVar9;
  bool bVar10;
  bool bVar11;
  short *local_20;
  
  local_20 = *(short **)PTR__gFirstPtr_00034034;
  dVar1 = *(double *)(PTR__g_00038024 + 0x1e0);
  dVar2 = *(double *)(PTR__g_00038024 + 0x1d8);
  while( true ) {
    if (local_20 == (short *)0x0) {
      return param_1;
    }
    dVar3 = *(double *)(local_20 + 2);
    bVar5 = dVar3 == dVar1;
    dVar4 = *(double *)(local_20 + 6);
    bVar6 = dVar4 == dVar2;
    bVar11 = *local_20 == *(short *)(PTR__g_00038024 + 0x1e8);
    if ((bVar5 && bVar6) && bVar11) {
      _RemoveTile(local_20);
      return 0;
    }
    bVar7 = dVar3 == dVar1 - DOUBLE_00033fb0;
    bVar8 = dVar4 == dVar2 - DOUBLE_00033fb0;
    if ((((bVar7 && bVar8) && bVar11) || ((bVar5 && bVar8) && bVar11)) ||
       ((bVar6 && bVar7) && bVar11)) break;
    bVar9 = dVar3 == dVar1 + DOUBLE_00033fb0;
    bVar10 = dVar4 == DOUBLE_00033fb0 + dVar2;
    if ((((bVar9 && bVar10) && bVar11) || ((bVar5 && bVar10) && bVar11)) ||
       (((bVar6 && bVar9) && bVar11 ||
        (((bVar7 && bVar10) && bVar11 || ((bVar8 && bVar9) && bVar11)))))) break;
    local_20 = *(short **)(local_20 + 10);
    param_1 = 1;
  }
  _PlaySound(0x50,0x80);
  return 0;
}


// ==== _DeleteAllTiles @ 0000a774 ====

void _DeleteAllTiles(void)

{
  int iVar1;
  int iVar2;
  undefined *puVar3;
  undefined *puVar4;
  void *pvVar5;
  
  puVar4 = PTR__gFirstPtr_00034034;
  for (pvVar5 = *(void **)PTR__gFirstPtr_00034034; puVar3 = PTR__gLastPtr_00034024,
      pvVar5 != (void *)0x0; pvVar5 = *(void **)((int)pvVar5 + 0x14)) {
    iVar1 = *(int *)((int)pvVar5 + 0x18);
    iVar2 = *(int *)((int)pvVar5 + 0x14);
    if (iVar2 != 0 || iVar1 != 0) {
      if (iVar2 != 0) {
        if (iVar1 != 0) {
          *(int *)(iVar2 + 0x18) = iVar1;
          *(int *)(*(int *)((int)pvVar5 + 0x18) + 0x14) = iVar2;
        }
        else {
          *(undefined4 *)(iVar2 + 0x18) = 0;
          *(int *)puVar4 = iVar2;
        }
      }
      else {
        *(undefined4 *)(iVar1 + 0x14) = 0;
        *(int *)puVar3 = iVar1;
      }
    }
    else {
      *(undefined4 *)puVar4 = 0;
      *(undefined4 *)puVar3 = 0;
    }
    _free(pvVar5);
  }
  return;
}


// ==== _DeleteAllUndoTiles @ 0000a802 ====

void _DeleteAllUndoTiles(void)

{
  int iVar1;
  int iVar2;
  undefined *puVar3;
  undefined *puVar4;
  void *pvVar5;
  
  puVar3 = PTR__gFirstUndoPtr_00034038;
  for (pvVar5 = *(void **)PTR__gFirstUndoPtr_00034038; puVar4 = PTR__gLastUndoPtr_0003403c,
      pvVar5 != (void *)0x0; pvVar5 = *(void **)((int)pvVar5 + 0x14)) {
    iVar1 = *(int *)((int)pvVar5 + 0x18);
    iVar2 = *(int *)((int)pvVar5 + 0x14);
    if (iVar2 != 0 || iVar1 != 0) {
      if (iVar2 != 0) {
        if (iVar1 != 0) {
          *(int *)(iVar2 + 0x18) = iVar1;
          *(int *)(*(int *)((int)pvVar5 + 0x18) + 0x14) = iVar2;
        }
        else {
          *(undefined4 *)(iVar2 + 0x18) = 0;
          *(int *)puVar3 = iVar2;
        }
      }
      else {
        *(undefined4 *)(iVar1 + 0x14) = 0;
        *(int *)puVar4 = iVar1;
      }
    }
    else {
      *(undefined4 *)puVar3 = 0;
      *(undefined4 *)puVar4 = 0;
    }
    _free(pvVar5);
  }
  return;
}


// ==== _WriteUndoStruct @ 0000a890 ====

void _WriteUndoStruct(void)

{
  undefined *puVar1;
  undefined2 *puVar2;
  
  puVar2 = _malloc(0x1c);
  puVar1 = PTR__g_00038024;
  *puVar2 = *(undefined2 *)(PTR__g_00038024 + 0x1e8);
  *(undefined8 *)(puVar2 + 6) = *(undefined8 *)(puVar1 + 0x1d8);
  *(undefined8 *)(puVar2 + 2) = *(undefined8 *)(puVar1 + 0x1e0);
  return;
}


// ==== FUN_0000a8d3 @ 0000a8d3 ====

void __regparm1 FUN_0000a8d3(int *param_1,int param_2)

{
  undefined4 uVar1;
  int *piVar2;
  
  piVar2 = (int *)PTR__gLastUndoPtr_0003403c;
  if (*param_1 == 0) {
    *(undefined4 *)(param_2 + 0x14) = 0;
    *(undefined4 *)(param_2 + 0x18) = 0;
    *param_1 = param_2;
    piVar2 = (int *)PTR__gLastUndoPtr_0003403c;
  }
  else {
    uVar1 = *(undefined4 *)PTR__gLastUndoPtr_0003403c;
    *(undefined4 *)(param_2 + 0x14) = 0;
    *(undefined4 *)(param_2 + 0x18) = uVar1;
    *(int *)(*piVar2 + 0x14) = param_2;
  }
  *piVar2 = param_2;
  return;
}


// ==== _CountTilesAtCurrentLayer @ 0000a910 ====

int _CountTilesAtCurrentLayer(void)

{
  short sVar1;
  short *psVar2;
  
  sVar1 = 0;
  for (psVar2 = *(short **)PTR__gFirstPtr_00034034; psVar2 != (short *)0x0;
      psVar2 = *(short **)(psVar2 + 10)) {
    sVar1 = sVar1 + (ushort)(*psVar2 == _edlayer);
  }
  return (int)sVar1;
}


// ==== _RedrawTileCount @ 0000a93d ====

void _RedrawTileCount(undefined1 param_1)

{
  undefined *puVar1;
  short sVar2;
  short sVar3;
  int iVar4;
  int iVar5;
  short sVar6;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  _SetRect(&local_24,0x624,0,0x936,0x44);
  _SetRect(&local_34,7,0x214,0x319,600);
  _SetRect(&local_2c,0x312,0,0x624,0x44);
  _DrawToGWorld(PTR__g_00038024 + 0x1c,PTR__g_00038024 + 0x30,PTR__g_00038024 + 0x1c,local_24,
                local_20,local_34,local_30,local_2c,local_28,1);
  sVar3 = 0;
  for (iVar4 = *(int *)PTR__gFirstPtr_00034034; iVar4 != 0; iVar4 = *(int *)(iVar4 + 0x14)) {
    sVar3 = sVar3 + 1;
  }
  PTR__g_00038024[0x1f2] = sVar3 == 0x90;
  sVar2 = (sVar3 / 10) % 10;
  sVar6 = sVar3 % 10;
  if (sVar3 % 10 == 0) {
    sVar6 = 10;
  }
  iVar5 = (int)(short)(sVar6 * 0x1e + 0x75);
  iVar4 = (int)(short)(sVar6 * 0x1e + 0x57);
  _SetRect(&local_24,0x9b,iVar4,0xb3,iVar5);
  _SetRect(&local_34,0x271,0x223,0x281,0x239);
  _SetRect(&local_2c,0xb4,iVar4,0xcc,iVar5);
  puVar1 = PTR__g_00038024 + 0x30;
  _DrawToGWorld(PTR__g_00038024,puVar1,PTR__g_00038024,local_24,local_20,local_34,local_30,local_2c,
                local_28,1);
  if (9 < sVar3) {
    if (sVar2 == 0) {
      sVar2 = 10;
    }
    iVar5 = (int)(short)(sVar2 * 0x1e + 0x75);
    iVar4 = (int)(short)(sVar2 * 0x1e + 0x57);
    _SetRect(&local_24,0x9b,iVar4,0xb3,iVar5);
    _SetRect(&local_34,0x261,0x223,0x271,0x239);
    _SetRect(&local_2c,0xb4,iVar4,0xcc,iVar5);
    _DrawToGWorld(PTR__g_00038024,puVar1,PTR__g_00038024,local_24,local_20,local_34,local_30,
                  local_2c,local_28,1);
  }
  if (99 < sVar3) {
    sVar2 = ((short)((sVar3 / 10) / 10) % 10) * 0x1e;
    iVar5 = (int)(short)(sVar2 + 0x75);
    iVar4 = (int)(short)(sVar2 + 0x57);
    _SetRect(&local_24,0x9b,iVar4,0xb3,iVar5);
    _SetRect(&local_34,0x251,0x223,0x261,0x239);
    _SetRect(&local_2c,0xb4,iVar4,0xcc,iVar5);
    _DrawToGWorld(PTR__g_00038024,puVar1,PTR__g_00038024,local_24,local_20,local_34,local_30,
                  local_2c,local_28,1);
  }
  sVar3 = 0x90 - sVar3;
  sVar6 = (sVar3 / 10) % 10;
  sVar2 = sVar3 % 10;
  if (sVar3 % 10 == 0) {
    sVar2 = 10;
  }
  iVar5 = (int)(short)(sVar2 * 0x1e + 0x75);
  iVar4 = (int)(short)(sVar2 * 0x1e + 0x57);
  _SetRect(&local_24,0x9b,iVar4,0xb3,iVar5);
  _SetRect(&local_34,0x271,0x23c,0x281,0x252);
  _SetRect(&local_2c,0xb4,iVar4,0xcc,iVar5);
  _DrawToGWorld(PTR__g_00038024,puVar1,PTR__g_00038024,local_24,local_20,local_34,local_30,local_2c,
                local_28,1);
  if (9 < sVar3) {
    if (sVar6 == 0) {
      sVar6 = 10;
    }
    iVar5 = (int)(short)(sVar6 * 0x1e + 0x75);
    iVar4 = (int)(short)(sVar6 * 0x1e + 0x57);
    _SetRect(&local_24,0x9b,iVar4,0xb3,iVar5);
    _SetRect(&local_34,0x261,0x23c,0x271,0x252);
    _SetRect(&local_2c,0xb4,iVar4,0xcc,iVar5);
    _DrawToGWorld(PTR__g_00038024,puVar1,PTR__g_00038024,local_24,local_20,local_34,local_30,
                  local_2c,local_28,1);
  }
  if (99 < sVar3) {
    sVar3 = ((short)((sVar3 / 10) / 10) % 10) * 0x1e;
    iVar5 = (int)(short)(sVar3 + 0x75);
    iVar4 = (int)(short)(sVar3 + 0x57);
    _SetRect(&local_24,0x9b,iVar4,0xb3,iVar5);
    _SetRect(&local_34,0x251,0x23c,0x261,0x252);
    _SetRect(&local_2c,0xb4,iVar4,0xcc,iVar5);
    _DrawToGWorld(PTR__g_00038024,puVar1,PTR__g_00038024,local_24,local_20,local_34,local_30,
                  local_2c,local_28,1);
  }
  _SetRect(&local_34,0x251,0x223,0x281,0x252);
  _DrawToWindow(puVar1,local_34,local_30,local_34,local_30,param_1);
  return;
}


// ==== _RedrawLevelEditorScreen @ 0000b0cd ====

void _RedrawLevelEditorScreen(undefined1 param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  _SetRect(&local_24,0,0x213,800,600);
  _SetRect(&local_34,0,0x213,800,600);
  puVar1 = PTR__g_00038024 + 0x30;
  puVar2 = PTR__g_00038024 + 0x1c;
  _DrawToGWorld(PTR__g_00038024 + 0x14,puVar1,PTR__g_00038024 + 0x14,local_24,local_20,local_34,
                local_30,local_2c,local_28,0xfffffff7);
  _SetRect(&local_24,0x624,0,0x936,0x44);
  _SetRect(&local_34,7,0x214,0x319,600);
  _SetRect(&local_2c,0x312,0,0x624,0x44);
  _DrawToGWorld(puVar2,puVar1,puVar2,local_24,local_20,local_34,local_30,local_2c,local_28,1);
  _SetRect(&local_34,0,0x213,800,600);
  _DrawToWindow(puVar1,local_34,local_30,local_34,local_30,param_1);
  _RedrawLayerButtons(param_1);
  _RedrawTileCount(param_1);
  _RedrawNudgeArrows(9,param_1);
  return;
}


// ==== _AnimationMapScreenToLevelEditor @ 0000b2c0 ====

void _AnimationMapScreenToLevelEditor(void)

{
  undefined *puVar1;
  undefined4 uVar2;
  int iVar3;
  int iVar4;
  undefined *puVar5;
  undefined4 uVar6;
  undefined4 *puVar7;
  undefined *puVar8;
  int iVar9;
  short sVar10;
  float fVar11;
  uint local_34;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  puVar8 = PTR__g_00038024;
  for (puVar7 = *(undefined4 **)(PTR__g_00038024 + 0x58); puVar7 != (undefined4 *)0x0;
      puVar7 = (undefined4 *)puVar7[0x42]) {
    if (*(short *)(puVar7 + 1) == *(short *)(puVar8 + 0x5c)) {
      _StopMovie(*puVar7);
      *(undefined2 *)(puVar8 + 0x5c) = *(undefined2 *)(puVar8 + 0x5e);
    }
  }
  _SetRect(&local_24,0,0,800,600);
  _SetRect(&local_2c,0,0,800,600);
  puVar1 = PTR__g_00038024;
  puVar5 = PTR__g_00038024 + 0x14;
  _DisposeGWorld(*(undefined4 *)(PTR__g_00038024 + 0x14));
  uVar2 = _objc_msgSend(PTR_s_NSString_0003626c,PTR_s_stringWithFormat__00036114,&cf_background_d,
                        (int)*(short *)(puVar1 + 0x8e));
  _CreateGWorld(uVar2,puVar5,local_24,local_20);
  _DrawToGWorld(puVar5,puVar1 + 0x2c,puVar5,local_24,local_20,local_2c,local_28,puVar5,puVar8,
                0xfffffff7);
  if (1 < *(short *)(PTR__p_00038028 + 0x20e)) {
    for (puVar7 = *(undefined4 **)(puVar1 + 0x58); puVar7 != (undefined4 *)0x0;
        puVar7 = (undefined4 *)puVar7[0x42]) {
      if (*(short *)(puVar7 + 1) == *(short *)(puVar1 + 0x5c)) {
        _SetMovieVolume(*puVar7,0x80);
        _GoToBeginningOfMovie(*puVar7);
        _StartMovie(*puVar7);
      }
    }
  }
  _PlaySound(0x32,0x100);
  iVar3 = _TickCount();
  do {
    iVar4 = _TickCount();
    if ((uint)(iVar4 - iVar3) < 0x3d) {
      iVar4 = _TickCount();
      local_34 = iVar4 - iVar3;
      fVar11 = (float)(local_34 >> 0x10) * FLOAT_00033b30 + (float)(local_34 & 0xffff);
    }
    else {
      local_34 = 0x3c;
      fVar11 = FLOAT_00033b2c;
    }
    sVar10 = (short)(int)((fVar11 / FLOAT_00033b2c) * FLOAT_00033b38);
    iVar4 = (int)(short)(400 - sVar10);
    iVar9 = (int)(short)(sVar10 + 400);
    _SetRect(&local_24,(int)sVar10,0,400,600);
    _SetRect(&local_2c,0,0,iVar4,600);
    puVar5 = PTR__g_00038024 + 0x30;
    _DrawToWindow(puVar5,local_24,local_20,local_2c,local_28,0);
    _SetRect(&local_24,iVar4,0,iVar9,600);
    _SetRect(&local_2c,iVar4,0,iVar9,600);
    _DrawToWindow(PTR__g_00038024 + 0x2c,local_24,local_20,local_2c,local_28,0);
    _SetRect(&local_24,400,0,(int)(short)(800 - sVar10),600);
    _SetRect(&local_2c,iVar9,0,800,600);
    _DrawToWindow(puVar5,local_24,local_20,local_2c,local_28,1);
    puVar8 = PTR__g_00038024;
  } while (local_34 < 0x3c);
  PTR__g_00038024[0x66] = 1;
  puVar8[0x1f0] = 0;
  puVar8[0x1f1] = 0;
  uVar2 = _GetMenuHandle(2);
  uVar6 = _CFStringCreateMutable(*(undefined4 *)PTR_00038034,0);
  _CFStringAppendCString(uVar6,"Exit Level Editor",0x600);
  _SetMenuItemTextWithCFString(uVar2,1,uVar6);
  _CFRelease(uVar6);
  _SetRect(&local_24,0,0,800,600);
  _SetRect(&local_2c,0,0,800,600);
  puVar8 = PTR__g_00038024 + 0x14;
  _DrawToGWorld(puVar8,PTR__g_00038024 + 0x38,puVar8,local_24,local_20,local_2c,local_28,uVar6,uVar2
                ,0xfffffff7);
  _DrawToGWorld(puVar8,puVar5,puVar8,local_24,local_20,local_2c,local_28,puVar8,uVar2,0xfffffff7);
  _SetRect(&local_24,0,0x28a,0x26,700);
  _SetRect(&local_2c,8,5,0x2e,0x36);
  _DrawToGWorld(PTR__g_00038024 + 0xc,PTR__g_00038024 + 4,PTR__g_00038024 + 0xc,local_24,local_20,
                local_2c,local_28,puVar8,uVar2,0xfffffff7);
  puVar8 = PTR__g_00038024;
  _edlayer = 0;
  *(undefined4 *)(PTR__g_00038024 + 0x94) = 0;
  *(undefined4 *)(puVar8 + 0x98) = 0;
  _RedrawLevelEditorScreen(1);
  PTR__g_00038024[0x80] = 1;
  return;
}


// ==== _DoSaveAs @ 0000b89d ====

undefined4 _DoSaveAs(void)

{
  undefined *puVar1;
  double dVar2;
  undefined *puVar3;
  char cVar4;
  undefined4 uVar5;
  undefined4 uVar6;
  int iVar7;
  undefined4 uVar8;
  undefined4 uVar9;
  undefined4 uVar10;
  short sVar11;
  short *psVar12;
  double dVar13;
  cfstringStruct *pcVar14;
  undefined1 local_584 [256];
  undefined1 local_484;
  undefined1 local_483;
  undefined1 local_482;
  undefined1 local_481;
  undefined4 local_47c;
  undefined4 local_470;
  undefined4 local_46c;
  undefined1 local_466 [256];
  undefined1 local_366 [256];
  undefined1 local_266 [256];
  undefined1 local_166 [256];
  undefined1 local_66 [70];
  undefined4 local_20 [4];
  
  sVar11 = 0;
  for (iVar7 = *(int *)PTR__gFirstPtr_00034034; iVar7 != 0; iVar7 = *(int *)(iVar7 + 0x14)) {
    sVar11 = sVar11 + 1;
  }
  PTR__g_00038024[0x1f2] = sVar11 == 0x90;
  if (sVar11 < 1) {
    return 1;
  }
  local_20[0] = 0;
  uVar5 = _objc_msgSend(PTR_s_NSSavePanel_000362d8,PTR_s_savePanel_000361c0);
  local_484 = 1;
  local_483 = 1;
  local_482 = 0;
  local_481 = 0;
  local_47c = 0;
  local_470 = 0x4c564c45;
  local_46c = 0x414b4949;
  if (*(int *)(PTR__g_00038024 + 0xd0) == 0) {
    pcVar14 = &cf_aki;
    _objc_msgSend(uVar5,PTR_s_setRequiredFileType__000361c4,&cf_aki);
    uVar6 = _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
    cVar4 = _objc_msgSend(uVar6,PTR_s_isFullscreen_00036064);
    if (cVar4 != '\0') {
      _objc_msgSend(uVar5,PTR_s_scheduleSetShieldingLevel_00036158,pcVar14);
    }
    pcVar14 = &cf_MyCustomLevel;
    uVar6 = 0;
    iVar7 = _objc_msgSend(uVar5,PTR_s_runModalForDirectory_file__000361c8,0,&cf_MyCustomLevel);
    if (iVar7 != 1) {
      return 0;
    }
    uVar6 = _objc_msgSend(PTR_s_NSFileManager_000362d4,PTR_s_defaultManager_000361cc,uVar6,pcVar14);
    uVar8 = _objc_msgSend(uVar5,PTR_s_filename_000361d0);
    cVar4 = _objc_msgSend(uVar6,PTR_s_fileExistsAtPath__000361d4,uVar8);
    if (cVar4 != '\0') {
      uVar6 = _objc_msgSend(PTR_s_NSFileManager_000362d4,PTR_s_defaultManager_000361cc,uVar8,pcVar14
                           );
      uVar8 = _objc_msgSend(uVar5,PTR_s_filename_000361d0);
      pcVar14 = (cfstringStruct *)0x0;
      _objc_msgSend(uVar6,PTR_s_removeFileAtPath_handler__000361d8,uVar8,0);
    }
    puVar3 = PTR_s_NSDictionary_000362d0;
    uVar6 = *(undefined4 *)PTR_00038030;
    uVar9 = _objc_msgSend(PTR_s_NSNumber_000362cc,PTR_s_numberWithLong__000361dc,0x414b4949,pcVar14)
    ;
    uVar8 = *(undefined4 *)PTR_0003802c;
    uVar10 = _objc_msgSend(PTR_s_NSNumber_000362cc,PTR_s_numberWithLong__000361dc,0x4c564c45);
    uVar6 = _objc_msgSend(puVar3,PTR_s_dictionaryWithObjectsAndKeys__000361e0,uVar10,uVar8,uVar9,
                          uVar6,0);
    uVar8 = _objc_msgSend(PTR_s_NSFileManager_000362d4,PTR_s_defaultManager_000361cc);
    uVar9 = _objc_msgSend(uVar5,PTR_s_filename_000361d0);
    _objc_msgSend(uVar8,PTR_s_createFileAtPath_contents_attrib_000361e4,uVar9,0,uVar6);
    uVar5 = _objc_msgSend(uVar5,PTR_s_filename_000361d0);
    uVar5 = _objc_msgSend(uVar5,PTR_s_UTF8String_00036088);
    _POSIXPathToFSSpec(uVar5,local_66);
    iVar7 = _FT_PathCreateFromMacFSSpec(local_66,PTR__g_00038024 + 0xd0,PTR__g_00038024 + 0xd8);
    if (iVar7 != 0) {
      return 1;
    }
  }
  _FT_FileOpen(*(undefined4 *)(PTR__g_00038024 + 0xd0),PTR__g_00038024 + 0xd8,1,local_20);
  sVar11 = 0;
  for (iVar7 = *(int *)PTR__gFirstPtr_00034034; iVar7 != 0; iVar7 = *(int *)(iVar7 + 0x14)) {
    sVar11 = sVar11 + 1;
  }
  PTR__g_00038024[0x1f2] = sVar11 == 0x90;
  _StringFromNumber(local_466,(int)sVar11);
  if (0x59 < (ushort)(sVar11 - 10U)) {
    if (9 < sVar11) goto LAB_0000bc69;
    uVar5 = _StringGetLength("0");
    _FT_FileWrite(local_20[0],uVar5,"0");
  }
  uVar5 = _StringGetLength("0");
  _FT_FileWrite(local_20[0],uVar5,"0");
LAB_0000bc69:
  uVar5 = _StringGetLength(local_466);
  _FT_FileWrite(local_20[0],uVar5,local_466);
  uVar5 = _StringGetLength("\n");
  _FT_FileWrite(local_20[0],uVar5,"\n");
  for (psVar12 = *(short **)PTR__gFirstPtr_00034034; puVar3 = PTR__g_00038024,
      psVar12 != (short *)0x0; psVar12 = *(short **)(psVar12 + 10)) {
    dVar2 = *(double *)(psVar12 + 6);
    dVar13 = dVar2;
    if (DAT_00033d10 <= dVar2) {
      dVar13 = DAT_00033d10;
    }
    if (dVar13 <= 0.0) {
      dVar13 = 0.0;
    }
    _StringFromNumber(local_166,
                      (int)(dVar13 - (double)(-(ulonglong)(DAT_00033d00 <= dVar2) &
                                             (ulonglong)DAT_00033d00)) ^
                      (uint)(DAT_00033d00 <= dVar2) * -0x80000000);
    dVar2 = *(double *)(psVar12 + 2);
    dVar13 = dVar2;
    if (DAT_00033d10 <= dVar2) {
      dVar13 = DAT_00033d10;
    }
    if (dVar13 <= 0.0) {
      dVar13 = 0.0;
    }
    _StringFromNumber(local_366,
                      (int)(dVar13 - (double)(-(ulonglong)(DAT_00033d00 <= dVar2) &
                                             (ulonglong)DAT_00033d00)) ^
                      (uint)(DAT_00033d00 <= dVar2) * -0x80000000);
    _StringFromNumber(local_266,(int)*psVar12);
    if (*(double *)(psVar12 + 6) <= DOUBLE_00033fc8 && DOUBLE_00033fc8 != *(double *)(psVar12 + 6))
    {
      uVar5 = _StringGetLength("0");
      _FT_FileWrite(local_20[0],uVar5,"0");
    }
    uVar5 = _StringGetLength(local_166);
    _FT_FileWrite(local_20[0],uVar5,local_166);
    uVar5 = _StringGetLength(" ");
    _FT_FileWrite(local_20[0],uVar5," ");
    if (*(double *)(psVar12 + 2) <= DOUBLE_00033fc8 && DOUBLE_00033fc8 != *(double *)(psVar12 + 2))
    {
      uVar5 = _StringGetLength("0");
      _FT_FileWrite(local_20[0],uVar5,"0");
    }
    uVar5 = _StringGetLength(local_366);
    _FT_FileWrite(local_20[0],uVar5,local_366);
    uVar5 = _StringGetLength(" ");
    _FT_FileWrite(local_20[0],uVar5," ");
    uVar5 = _StringGetLength(local_266);
    _FT_FileWrite(local_20[0],uVar5,local_266);
    uVar5 = _StringGetLength("\n");
    _FT_FileWrite(local_20[0],uVar5,"\n");
  }
  puVar1 = PTR__g_00038024 + 0xd8;
  _StringCopy(local_584,puVar1);
  _FT_FileSetFlags(*(undefined4 *)(puVar3 + 0xd0),puVar1,local_584);
  _FT_FileClose(local_20[0]);
  puVar3 = PTR__g_00038024;
  sVar11 = 0;
  for (iVar7 = *(int *)PTR__gFirstPtr_00034034; iVar7 != 0; iVar7 = *(int *)(iVar7 + 0x14)) {
    sVar11 = sVar11 + 1;
  }
  PTR__g_00038024[0x1f2] = sVar11 == 0x90;
  puVar3[0x228] = sVar11 < 0x90;
  puVar3[0x1f0] = 0;
  return 1;
}


// ==== _EditorScreen @ 0000bf37 ====

void _EditorScreen(void)

{
  double dVar1;
  short sVar2;
  char cVar3;
  int iVar4;
  int iVar5;
  int iVar6;
  int iVar7;
  int iVar8;
  ushort uVar9;
  short sVar10;
  short sVar11;
  undefined *puVar12;
  short *psVar13;
  undefined *puVar14;
  short sVar15;
  int iVar16;
  undefined4 local_3c;
  undefined4 local_38;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  puVar12 = PTR__mouseIsHere_00034028;
  cVar3 = _GetMouseLocation(PTR__mouseIsHere_00034028);
  sVar2 = _edlayer;
  if (cVar3 != '\0') {
    uVar9 = (ushort)(int)((double)(*(short *)(puVar12 + 2) + -0x14) / DOUBLE_00033fd0);
    _edcol = 0x20;
    if ((short)uVar9 < 0x21) {
      _edcol = uVar9;
    }
    sVar11 = (short)(int)((double)(*(short *)puVar12 + 7) / DOUBLE_00033fd8);
    _edrow = 0x11;
    if (sVar11 < 0x12) {
      _edrow = sVar11;
    }
    if (((_edcol < 0x21) && (_edrow < 0x12)) && (-1 < _edrow)) {
      dVar1 = *(double *)(PTR__g_00038024 + 0x74);
      if ((((double)(int)(short)_edcol != dVar1) || (NAN((double)(int)(short)_edcol) || NAN(dVar1)))
         || ((double)(int)_edrow != *(double *)(PTR__g_00038024 + 0x6c))) {
        sVar11 = _edlayer * 5;
        sVar10 = (short)(int)(dVar1 * DOUBLE_00033fa8 * DOUBLE_00033fa0) + sVar11;
        sVar15 = (short)(int)(DOUBLE_00033f98 * *(double *)(PTR__g_00038024 + 0x6c) *
                             DOUBLE_00033fa0) + _edlayer * -10;
        iVar4 = (int)sVar10;
        _SetRect(&local_24,iVar4,(int)sVar15,(int)(short)(sVar10 + 0x35),(int)(short)(sVar15 + 0x45)
                );
        _SetRect(&local_2c,iVar4,(int)sVar15,(int)(short)(sVar10 + 0x35),(int)(short)(sVar15 + 0x45)
                );
        puVar12 = PTR__g_00038024 + 0x38;
        puVar14 = PTR__g_00038024 + 0x30;
        _DrawToGWorld(puVar12,puVar14,puVar12,local_24,local_20,local_2c,local_28,local_34,local_30,
                      0xfffffff7);
        _SetRect(&local_3c,iVar4,(int)(short)(sVar15 + 1),(int)(short)(sVar10 + 0x33),
                 (int)(short)(sVar15 + 0x43));
        _DrawToWindow(puVar14,local_3c,local_38,local_3c,local_38,0);
        sVar11 = (short)(int)((double)((short)_edcol * 0x2e) * DOUBLE_00033fa0) + sVar11;
        sVar10 = (short)(int)((double)(_edrow * 0x37) * DOUBLE_00033fa0) + sVar2 * -10;
        iVar4 = (int)(short)(sVar10 + 0x45);
        iVar16 = (int)(short)(sVar11 + 0x35);
        iVar5 = (int)sVar10;
        iVar6 = (int)sVar11;
        _SetRect(&local_24,iVar6,iVar5,iVar16,iVar4);
        _SetRect(&local_2c,iVar6,iVar5,iVar16,iVar4);
        _DrawToGWorld(puVar12,puVar14,puVar12,local_24,local_20,local_2c,local_28,local_34,local_30,
                      0xfffffff7);
        _SetRect(&local_24,0,0,0x35,0x45);
        _SetRect(&local_2c,iVar6,iVar5,iVar16,iVar4);
        _SetRect(&local_34,0,0x1e3,0x36,0x228);
        _DrawToGWorld(PTR__g_00038024 + 4,puVar14,PTR__g_00038024 + 4,local_24,local_20,local_2c,
                      local_28,local_34,local_30,1);
        sVar2 = _edlayer;
        iVar7 = (int)(short)_edcol;
        *(double *)(PTR__g_00038024 + 0x74) = (double)iVar7;
        iVar8 = (int)_edrow;
        *(double *)(PTR__g_00038024 + 0x6c) = (double)iVar8;
        for (psVar13 = *(short **)PTR__gFirstPtr_00034034; psVar13 != (short *)0x0;
            psVar13 = *(short **)(psVar13 + 10)) {
          if (((double)iVar8 == *(double *)(psVar13 + 2) &&
              (double)iVar7 == *(double *)(psVar13 + 6)) && *psVar13 == sVar2) {
            _SetRect(&local_24,0,0x45,0x35,0x8a);
            _SetRect(&local_2c,iVar6,iVar5,iVar16,iVar4);
            _SetRect(&local_34,0,0x40b,0x36,0x450);
            _DrawToGWorld(PTR__g_00038024 + 4,PTR__g_00038024 + 0x30,PTR__g_00038024 + 4,local_24,
                          local_20,local_2c,local_28,local_34,local_30,1);
            break;
          }
        }
        _RedrawLevelEditorScreen(0);
        _SetRect(&local_3c,iVar6,(int)(short)(sVar10 + 1),(int)(short)(sVar11 + 0x33),
                 (int)(short)(sVar10 + 0x43));
        _DrawToWindow(PTR__g_00038024 + 0x30,local_3c,local_38,local_3c,local_38,1);
      }
    }
  }
  _LoopMusic(0);
  return;
}


// ==== _DoClearAll @ 0000c4c6 ====

void _DoClearAll(void)

{
  undefined4 uVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined2 *puVar5;
  undefined2 *puVar6;
  
  puVar2 = PTR__gFirstPtr_00034034;
  if (*(int *)PTR__gFirstPtr_00034034 != 0) {
    _DeleteAllUndoTiles();
    puVar4 = PTR__g_00038024;
    puVar3 = PTR__gLastUndoPtr_0003403c;
    for (puVar6 = *(undefined2 **)puVar2; puVar6 != (undefined2 *)0x0;
        puVar6 = *(undefined2 **)(puVar6 + 10)) {
      *(undefined8 *)(puVar4 + 0x1d8) = *(undefined8 *)(puVar6 + 6);
      *(undefined8 *)(puVar4 + 0x1e0) = *(undefined8 *)(puVar6 + 2);
      *(undefined2 *)(puVar4 + 0x1e8) = *puVar6;
      puVar5 = _malloc(0x1c);
      *puVar5 = *(undefined2 *)(puVar4 + 0x1e8);
      puVar2 = PTR__gFirstUndoPtr_00034038;
      *(undefined8 *)(puVar5 + 6) = *(undefined8 *)(puVar4 + 0x1d8);
      *(undefined8 *)(puVar5 + 2) = *(undefined8 *)(puVar4 + 0x1e0);
      if (*(int *)puVar2 == 0) {
        *(undefined4 *)(puVar5 + 10) = 0;
        *(undefined4 *)(puVar5 + 0xc) = 0;
        *(undefined2 **)puVar2 = puVar5;
      }
      else {
        uVar1 = *(undefined4 *)puVar3;
        *(undefined4 *)(puVar5 + 10) = 0;
        *(undefined4 *)(puVar5 + 0xc) = uVar1;
        *(undefined2 **)(*(int *)puVar3 + 0x14) = puVar5;
      }
      *(undefined2 **)puVar3 = puVar5;
    }
    _DeleteAllTiles();
    _DrawTempToWindow();
    _RedrawTileCount(1);
    puVar2 = PTR__g_00038024;
    PTR__g_00038024[0x1f0] = 1;
    puVar2[0x1f1] = 1;
    *(undefined2 *)PTR__undoLayer_00034030 = 9;
  }
  return;
}


// ==== _DoClearLayer @ 0000c5c3 ====

void _DoClearLayer(void)

{
  undefined4 uVar1;
  undefined *puVar2;
  undefined *puVar3;
  short *psVar4;
  undefined2 *puVar5;
  undefined4 *puVar6;
  
  psVar4 = *(short **)PTR__gFirstPtr_00034034;
  while( true ) {
    if (psVar4 == (short *)0x0) {
      return;
    }
    if (*psVar4 == _edlayer) break;
    psVar4 = *(short **)(psVar4 + 10);
  }
  _DeleteAllUndoTiles();
  for (psVar4 = *(short **)PTR__gFirstPtr_00034034; puVar3 = PTR__g_00038024, psVar4 != (short *)0x0
      ; psVar4 = *(short **)(psVar4 + 10)) {
    if (*psVar4 == _edlayer) {
      *(undefined8 *)(PTR__g_00038024 + 0x1d8) = *(undefined8 *)(psVar4 + 6);
      *(undefined8 *)(puVar3 + 0x1e0) = *(undefined8 *)(psVar4 + 2);
      *(short *)(puVar3 + 0x1e8) = *psVar4;
      puVar5 = _malloc(0x1c);
      *puVar5 = *(undefined2 *)(puVar3 + 0x1e8);
      puVar2 = PTR__gFirstUndoPtr_00034038;
      *(undefined8 *)(puVar5 + 6) = *(undefined8 *)(puVar3 + 0x1d8);
      *(undefined8 *)(puVar5 + 2) = *(undefined8 *)(puVar3 + 0x1e0);
      puVar6 = (undefined4 *)PTR__gLastUndoPtr_0003403c;
      if (*(int *)puVar2 == 0) {
        *(undefined4 *)(puVar5 + 10) = 0;
        *(undefined4 *)(puVar5 + 0xc) = 0;
        *(undefined2 **)puVar2 = puVar5;
        puVar6 = (undefined4 *)PTR__gLastUndoPtr_0003403c;
      }
      else {
        uVar1 = *(undefined4 *)PTR__gLastUndoPtr_0003403c;
        *(undefined4 *)(puVar5 + 10) = 0;
        *(undefined4 *)(puVar5 + 0xc) = uVar1;
        *(undefined2 **)(*puVar6 + 0x14) = puVar5;
      }
      *puVar6 = puVar5;
      _RemoveTile(psVar4);
    }
  }
  _DrawTempToWindow();
  _RedrawTileCount(1);
  puVar3 = PTR__g_00038024;
  PTR__g_00038024[0x1f0] = 1;
  puVar3[0x1f1] = 1;
  *(undefined2 *)PTR__undoLayer_00034030 = 9;
  return;
}


// ==== _CreateTile @ 0000c6ec ====

void _CreateTile(int param_1)

{
  undefined4 uVar1;
  undefined2 uVar2;
  undefined *puVar3;
  char cVar4;
  short sVar5;
  int iVar6;
  undefined2 *puVar7;
  undefined4 *puVar8;
  undefined *puVar9;
  
  puVar9 = PTR__g_00038024;
  uVar2 = _edlayer;
  sVar5 = (short)(int)((double)((param_1 >> 0x10) + -0x14) / DOUBLE_00033fd0);
  _edcol = 0x20;
  if (sVar5 < 0x21) {
    _edcol = sVar5;
  }
  sVar5 = (short)(int)((double)((short)param_1 + 7) / DOUBLE_00033fd8);
  _edrow = 0x11;
  if (sVar5 < 0x12) {
    _edrow = sVar5;
  }
  *(double *)(PTR__g_00038024 + 0x1e0) = (double)(int)_edrow;
  *(double *)(puVar9 + 0x1d8) = (double)(int)_edcol;
  *(undefined2 *)(puVar9 + 0x1e8) = uVar2;
  cVar4 = _CheckNotOverlap(1);
  puVar3 = PTR__g_00038024;
  if (cVar4 != '\0') {
    sVar5 = 0;
    for (iVar6 = *(int *)PTR__gFirstPtr_00034034; iVar6 != 0; iVar6 = *(int *)(iVar6 + 0x14)) {
      sVar5 = sVar5 + 1;
    }
    PTR__g_00038024[0x1f2] = sVar5 == 0x90;
    puVar9 = puVar3;
    if (sVar5 < 0x90) {
      puVar7 = _malloc(0x1c);
      *puVar7 = *(undefined2 *)(puVar3 + 0x1e8);
      puVar9 = PTR__undoCol_0003402c;
      *(undefined8 *)(puVar7 + 6) = *(undefined8 *)(puVar3 + 0x1d8);
      *(undefined8 *)(puVar7 + 2) = *(undefined8 *)(puVar3 + 0x1e0);
      *(short *)puVar9 = (short)(int)*(double *)(puVar3 + 0x1d8);
      *(short *)PTR__undoRow_00034020 = (short)(int)*(double *)(puVar3 + 0x1e0);
      *(undefined2 *)PTR__undoLayer_00034030 = *(undefined2 *)(puVar3 + 0x1e8);
      puVar9 = PTR__gFirstPtr_00034034;
      puVar8 = (undefined4 *)PTR__gLastPtr_00034024;
      if (*(int *)PTR__gFirstPtr_00034034 == 0) {
        *(undefined4 *)(puVar7 + 10) = 0;
        *(undefined4 *)(puVar7 + 0xc) = 0;
        *(undefined2 **)puVar9 = puVar7;
        puVar8 = (undefined4 *)PTR__gLastPtr_00034024;
      }
      else {
        uVar1 = *(undefined4 *)PTR__gLastPtr_00034024;
        *(undefined4 *)(puVar7 + 10) = 0;
        *(undefined4 *)(puVar7 + 0xc) = uVar1;
        *(undefined2 **)(*puVar8 + 0x14) = puVar7;
      }
      *puVar8 = puVar7;
      _PlaySound(10,0x80);
      puVar9 = PTR__g_00038024;
    }
  }
  puVar9[0x1f0] = 1;
  puVar9[0x1f1] = 1;
  _DrawEditorTiles();
  _RedrawTileCount(0);
  _DrawTempToWindow();
  return;
}


// ==== _UndoLastLEMove @ 0000c89b ====

void _UndoLastLEMove(void)

{
  short sVar1;
  short sVar2;
  undefined4 uVar3;
  bool bVar4;
  undefined *puVar5;
  undefined *puVar6;
  undefined2 *puVar7;
  undefined2 *puVar8;
  undefined4 *puVar9;
  short *psVar10;
  short *psVar11;
  double dVar12;
  
  puVar6 = PTR__g_00038024;
  sVar1 = *(short *)PTR__undoLayer_00034030;
  if (sVar1 == 9) {
    psVar11 = *(short **)PTR__gFirstUndoPtr_00034038;
    psVar10 = *(short **)PTR__gFirstPtr_00034034;
    bVar4 = false;
    while (psVar10 != (short *)0x0) {
      sVar1 = *psVar10;
      psVar10 = *(short **)(psVar10 + 10);
      if (sVar1 == *psVar11) {
        bVar4 = true;
      }
    }
    puVar7 = (undefined2 *)PTR__undoLayer_00034030;
    if (bVar4) {
      for (; puVar7 = (undefined2 *)PTR__undoLayer_00034030, psVar11 != (short *)0x0;
          psVar11 = *(short **)(psVar11 + 10)) {
        for (psVar10 = *(short **)PTR__gFirstPtr_00034034; psVar10 != (short *)0x0;
            psVar10 = *(short **)(psVar10 + 10)) {
          if ((*(double *)(psVar10 + 2) == *(double *)(psVar11 + 2)) &&
             (!NAN(*(double *)(psVar10 + 2)) && !NAN(*(double *)(psVar11 + 2)))) {
            if ((*(double *)(psVar10 + 6) == *(double *)(psVar11 + 6)) &&
               ((!NAN(*(double *)(psVar10 + 6)) && !NAN(*(double *)(psVar11 + 6)) &&
                (*psVar10 == *psVar11)))) {
              _RemoveTile(psVar10);
            }
          }
        }
      }
    }
    else {
      for (; puVar6 = PTR__g_00038024, psVar11 != (short *)0x0; psVar11 = *(short **)(psVar11 + 10))
      {
        *(undefined8 *)(PTR__g_00038024 + 0x1d8) = *(undefined8 *)(psVar11 + 6);
        *(undefined8 *)(puVar6 + 0x1e0) = *(undefined8 *)(psVar11 + 2);
        *(short *)(puVar6 + 0x1e8) = *psVar11;
        puVar8 = _malloc(0x1c);
        puVar7 = (undefined2 *)PTR__undoLayer_00034030;
        *puVar8 = *(undefined2 *)(puVar6 + 0x1e8);
        puVar5 = PTR__undoCol_0003402c;
        *(undefined8 *)(puVar8 + 6) = *(undefined8 *)(puVar6 + 0x1d8);
        *(undefined8 *)(puVar8 + 2) = *(undefined8 *)(puVar6 + 0x1e0);
        *(short *)puVar5 = (short)(int)*(double *)(puVar6 + 0x1d8);
        *(short *)PTR__undoRow_00034020 = (short)(int)*(double *)(puVar6 + 0x1e0);
        *puVar7 = *(undefined2 *)(puVar6 + 0x1e8);
        puVar6 = PTR__gFirstPtr_00034034;
        puVar9 = (undefined4 *)PTR__gLastPtr_00034024;
        if (*(int *)PTR__gFirstPtr_00034034 == 0) {
          *(undefined4 *)(puVar8 + 10) = 0;
          *(undefined4 *)(puVar8 + 0xc) = 0;
          *(undefined2 **)puVar6 = puVar8;
          puVar9 = (undefined4 *)PTR__gLastPtr_00034024;
        }
        else {
          uVar3 = *(undefined4 *)PTR__gLastPtr_00034024;
          *(undefined4 *)(puVar8 + 10) = 0;
          *(undefined4 *)(puVar8 + 0xc) = uVar3;
          *(undefined2 **)(*puVar9 + 0x14) = puVar8;
        }
        *puVar9 = puVar8;
      }
    }
    *puVar7 = 9;
  }
  else {
    dVar12 = (double)(int)*(short *)PTR__undoRow_00034020;
    sVar2 = *(short *)PTR__undoCol_0003402c;
    for (psVar10 = *(short **)PTR__gFirstPtr_00034034; psVar10 != (short *)0x0;
        psVar10 = *(short **)(psVar10 + 10)) {
      if (sVar1 == *psVar10) {
        if (((dVar12 == *(double *)(psVar10 + 2)) &&
            (!NAN(dVar12) && !NAN(*(double *)(psVar10 + 2)))) &&
           ((double)(int)sVar2 == *(double *)(psVar10 + 6))) {
          _RemoveTile(psVar10);
          goto LAB_0000cb2d;
        }
      }
    }
    *(double *)(PTR__g_00038024 + 0x1e0) = dVar12;
    *(short *)(puVar6 + 0x1e8) = sVar1;
    *(double *)(puVar6 + 0x1d8) = (double)(int)sVar2;
    puVar7 = _malloc(0x1c);
    *puVar7 = *(undefined2 *)(puVar6 + 0x1e8);
    puVar5 = PTR__undoCol_0003402c;
    *(undefined8 *)(puVar7 + 6) = *(undefined8 *)(puVar6 + 0x1d8);
    *(undefined8 *)(puVar7 + 2) = *(undefined8 *)(puVar6 + 0x1e0);
    *(short *)puVar5 = (short)(int)*(double *)(puVar6 + 0x1d8);
    *(short *)PTR__undoRow_00034020 = (short)(int)*(double *)(puVar6 + 0x1e0);
    *(undefined2 *)PTR__undoLayer_00034030 = *(undefined2 *)(puVar6 + 0x1e8);
    puVar6 = PTR__gFirstPtr_00034034;
    puVar9 = (undefined4 *)PTR__gLastPtr_00034024;
    if (*(int *)PTR__gFirstPtr_00034034 == 0) {
      *(undefined4 *)(puVar7 + 10) = 0;
      *(undefined4 *)(puVar7 + 0xc) = 0;
      *(undefined2 **)puVar6 = puVar7;
      puVar9 = (undefined4 *)PTR__gLastPtr_00034024;
    }
    else {
      uVar3 = *(undefined4 *)PTR__gLastPtr_00034024;
      *(undefined4 *)(puVar7 + 10) = 0;
      *(undefined4 *)(puVar7 + 0xc) = uVar3;
      *(undefined2 **)(*puVar9 + 0x14) = puVar7;
    }
    *puVar9 = puVar7;
    _PlaySound(10,0x80);
  }
LAB_0000cb2d:
  puVar6 = PTR__g_00038024;
  PTR__g_00038024[0x1f0] = 1;
  *(undefined8 *)(puVar6 + 0x74) = 0;
  *(undefined8 *)(puVar6 + 0x6c) = 0;
  _DrawTempToWindow();
  _RedrawTileCount(1);
  return;
}


// ==== _LoadFile @ 0000cb60 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _LoadFile(int param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  char cVar3;
  short sVar4;
  undefined2 uVar5;
  undefined4 uVar6;
  int iVar7;
  undefined4 uVar8;
  undefined *puVar9;
  undefined2 *puVar10;
  short *psVar11;
  short sVar12;
  undefined4 uVar13;
  undefined4 uVar14;
  undefined1 local_562 [256];
  undefined1 local_462;
  undefined1 local_461;
  undefined1 local_362 [3];
  undefined1 local_35f;
  undefined1 local_262 [3];
  undefined1 local_25f;
  undefined1 local_162 [4];
  undefined1 local_15e;
  undefined1 local_62 [82];
  
  uVar6 = _objc_msgSend(PTR_s_NSOpenPanel_000362c8,PTR_s_openPanel_000361e8);
  puVar9 = PTR__g_00038024;
  if (PTR__g_00038024[0x1f0] != '\0') {
    iVar7 = _RunModalSaveAlert();
    if (iVar7 == -1) {
      return;
    }
    if (iVar7 == 1) {
      cVar3 = _DoSaveAs();
      if (cVar3 == '\0') {
        return;
      }
      if (puVar9[0x228] != '\0') {
        _CreateNewDialog(0x50);
      }
      *(undefined4 *)(puVar9 + 0xd0) = 0;
    }
  }
  if (param_1 == 0) {
    uVar8 = _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
    cVar3 = _objc_msgSend(uVar8,PTR_s_isFullscreen_00036064);
    if (cVar3 != '\0') {
      _objc_msgSend(uVar6,PTR_s_scheduleSetShieldingLevel_00036158);
    }
    puVar9 = PTR_s_NSArray_000362c4;
    uVar8 = _NSFileTypeForHFSTypeCode(0x4c564c45);
    uVar8 = _objc_msgSend(puVar9,PTR_s_arrayWithObjects__000361ec,&cf_aki,uVar8,0);
    uVar14 = 0;
    uVar13 = 0;
    puVar9 = (undefined *)
             _objc_msgSend(uVar6,PTR_s_runModalForDirectory_file_types__000361f0,0,0,uVar8);
    if (puVar9 == (undefined *)0x1) {
      uVar6 = _objc_msgSend(uVar6,PTR_s_filename_000361d0,uVar13,uVar14,uVar8);
      uVar6 = _objc_msgSend(uVar6,PTR_s_UTF8String_00036088);
      iVar7 = _POSIXPathToFSSpec(uVar6,local_62);
      if (iVar7 != 0) {
        return;
      }
      iVar7 = _FT_PathCreateFromMacFSSpec(local_62,PTR__g_00038024 + 0xd0,PTR__g_00038024 + 0xd8);
      if (iVar7 != 0) {
        return;
      }
    }
  }
  if (param_1 != 0 || puVar9 == (undefined *)0x1) {
    _DeleteAllTiles();
    _DeleteAllUndoTiles();
    iVar7 = _FT_FileOpen(*(undefined4 *)(PTR__g_00038024 + 0xd0),PTR__g_00038024 + 0xd8,1,&param_1);
    if ((iVar7 == 0) || (iVar7 != -0x1c29)) {
      iVar7 = _FT_FileRead(param_1,4,local_162);
      if (iVar7 == 0) {
        local_15e = 0;
        sVar4 = _StringToNumber(local_162);
        puVar2 = PTR__g_00038024;
        puVar9 = PTR__gLastPtr_00034024;
        for (sVar12 = 0; sVar12 < sVar4; sVar12 = sVar12 + 1) {
          _FT_FileRead(param_1,3,local_262);
          _FT_FileRead(param_1,3,local_362);
          _FT_FileRead(param_1,1,&local_462);
          _FT_FileRead(param_1,1,local_562);
          local_25f = 0;
          local_35f = 0;
          local_461 = 0;
          iVar7 = _StringToNumber(local_262);
          *(double *)(puVar2 + 0x1d8) = (double)(iVar7 + -0x80000000) + _DAT_00033d20;
          iVar7 = _StringToNumber(local_362);
          *(double *)(puVar2 + 0x1e0) = (double)(iVar7 + -0x80000000) + _DAT_00033d20;
          uVar5 = _StringToNumber(&local_462);
          *(undefined2 *)(puVar2 + 0x1e8) = uVar5;
          puVar10 = _malloc(0x1c);
          puVar1 = PTR__undoCol_0003402c;
          *puVar10 = *(undefined2 *)(puVar2 + 0x1e8);
          *(undefined8 *)(puVar10 + 6) = *(undefined8 *)(puVar2 + 0x1d8);
          *(undefined8 *)(puVar10 + 2) = *(undefined8 *)(puVar2 + 0x1e0);
          *(short *)puVar1 = (short)(int)*(double *)(puVar2 + 0x1d8);
          *(short *)PTR__undoRow_00034020 = (short)(int)*(double *)(puVar2 + 0x1e0);
          *(undefined2 *)PTR__undoLayer_00034030 = *(undefined2 *)(puVar2 + 0x1e8);
          puVar1 = PTR__gFirstPtr_00034034;
          if (*(int *)PTR__gFirstPtr_00034034 == 0) {
            *(undefined4 *)(puVar10 + 10) = 0;
            *(undefined4 *)(puVar10 + 0xc) = 0;
            *(undefined2 **)puVar1 = puVar10;
          }
          else {
            uVar6 = *(undefined4 *)puVar9;
            *(undefined4 *)(puVar10 + 10) = 0;
            *(undefined4 *)(puVar10 + 0xc) = uVar6;
            *(undefined2 **)(*(int *)puVar9 + 0x14) = puVar10;
          }
          *(undefined2 **)puVar9 = puVar10;
        }
        _FT_FileClose(param_1);
        psVar11 = *(short **)PTR__gFirstPtr_00034034;
        _edlayer = 0;
        while (psVar11 != (short *)0x0) {
          sVar4 = *psVar11;
          psVar11 = *(short **)(psVar11 + 10);
          if (_edlayer < sVar4) {
            _edlayer = sVar4;
          }
        }
        PTR__g_00038024[0x1f0] = 0;
        _RedrawLevelEditorScreen(0);
        _DrawTempToWindow();
      }
    }
    else {
      _CreateNewDialog(0x56);
    }
  }
  return;
}


// ==== _AddSoundInfo @ 0000cfb7 ====

void _AddSoundInfo(int param_1,undefined2 param_2)

{
  int iVar1;
  undefined *puVar2;
  void *pvVar3;
  int iVar4;
  void *pvVar5;
  undefined8 uVar6;
  
  pvVar3 = _malloc(0x114);
  *(undefined2 *)((int)pvVar3 + 4) = param_2;
  uVar6 = _RT3_GetLicenseCode();
  iVar4 = 0;
  *(undefined8 *)((int)pvVar3 + 0x10c) = uVar6;
  pvVar5 = pvVar3;
  do {
    *(undefined1 *)((int)pvVar5 + 6) = *(undefined1 *)(param_1 + iVar4);
    *(undefined1 *)((int)pvVar5 + 7) = *(undefined1 *)(iVar4 + 1 + param_1);
    *(undefined1 *)((int)pvVar5 + 8) = *(undefined1 *)(iVar4 + 2 + param_1);
    *(undefined1 *)((int)pvVar5 + 9) = *(undefined1 *)(iVar4 + 3 + param_1);
    *(undefined1 *)((int)pvVar5 + 10) = *(undefined1 *)(iVar4 + 4 + param_1);
    *(undefined1 *)((int)pvVar5 + 0xb) = *(undefined1 *)(iVar4 + 5 + param_1);
    *(undefined1 *)((int)pvVar5 + 0xc) = *(undefined1 *)(iVar4 + 6 + param_1);
    iVar1 = iVar4 + 7;
    iVar4 = iVar4 + 8;
    *(undefined1 *)((int)pvVar5 + 0xd) = *(undefined1 *)(iVar1 + param_1);
    puVar2 = PTR__g_00038024;
    pvVar5 = (void *)((int)pvVar5 + 8);
  } while (iVar4 != 0x100);
  *(undefined4 *)((int)pvVar3 + 0x108) = 0;
  iVar4 = *(int *)(puVar2 + 0x54);
  if (iVar4 != 0) {
    *(int *)((int)pvVar3 + 0x108) = iVar4;
  }
  *(void **)(puVar2 + 0x54) = pvVar3;
  return;
}


// ==== _LoadSoundIntoMemory @ 0000d066 ====

void _LoadSoundIntoMemory(void)

{
  char cVar1;
  short sVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  int iVar5;
  undefined4 *puVar6;
  undefined1 local_be [80];
  undefined1 local_6e [70];
  undefined1 local_28 [8];
  undefined2 local_20;
  short local_1e [7];
  
  puVar6 = *(undefined4 **)(PTR__g_00038024 + 0x54);
  while( true ) {
    if (puVar6 == (undefined4 *)0x0) {
      return;
    }
    uVar3 = _CFBundleGetMainBundle();
    uVar4 = _CFStringGetSystemEncoding();
    uVar4 = _CFStringCreateWithPascalString(0,(int)puVar6 + 6,uVar4);
    iVar5 = _CFBundleCopyResourceURL(uVar3,uVar4,0,0);
    if (iVar5 == 0) {
      return;
    }
    cVar1 = _CFURLGetFSRef(iVar5,local_be);
    if (cVar1 == '\0') {
      return;
    }
    sVar2 = _FSGetCatalogInfo(local_be,0x3ffff,0,0,local_6e,0);
    if (sVar2 != 0) break;
    sVar2 = _OpenMovieFile(local_6e,local_1e,1);
    if (sVar2 != 0) {
      return;
    }
    local_20 = 0xffff;
    _NewMovieFromFile(puVar6,(int)local_1e[0],&local_20,0,1,0);
    _CloseMovieFile((int)local_1e[0]);
    _CFRelease(uVar4);
    _CFRelease(iVar5);
    _SetRect(local_28,0,0,0,0);
    _SetMovieBox(*puVar6,local_28);
    _GoToBeginningOfMovie(*puVar6);
    puVar6 = (undefined4 *)puVar6[0x42];
  }
  return;
}


// ==== _LoopSound @ 0000d21f ====

void _LoopSound(void)

{
  char cVar1;
  undefined4 *puVar2;
  
  if (*(short *)(PTR__p_00038028 + 0x210) != 0) {
    for (puVar2 = *(undefined4 **)(PTR__g_00038024 + 0x54); puVar2 != (undefined4 *)0x0;
        puVar2 = (undefined4 *)puVar2[0x42]) {
      if (*(short *)(puVar2 + 1) == 100) {
        cVar1 = _IsMovieDone(*puVar2);
        if (cVar1 != '\0') {
          _GoToBeginningOfMovie(*puVar2);
          _PlayMovie(0x80);
          _MoviesTask(*puVar2,0);
        }
      }
    }
  }
  return;
}


// ==== _PlaySound @ 0000d28c ====

void _PlaySound(short param_1,short param_2)

{
  undefined4 *puVar1;
  
  if (*(short *)(PTR__p_00038028 + 0x210) != 0) {
    for (puVar1 = *(undefined4 **)(PTR__g_00038024 + 0x54); puVar1 != (undefined4 *)0x0;
        puVar1 = (undefined4 *)puVar1[0x42]) {
      if (*(short *)(puVar1 + 1) == param_1) {
        _GoToBeginningOfMovie(*puVar1);
        _SetMovieVolume(*puVar1,(int)param_2);
        _StartMovie(*puVar1);
        _MoviesTask(*puVar1,100);
      }
    }
  }
  return;
}


// ==== _StopSound @ 0000d305 ====

void _StopSound(short param_1)

{
  undefined4 *puVar1;
  
  if (*(short *)(PTR__p_00038028 + 0x210) != 0) {
    for (puVar1 = *(undefined4 **)(PTR__g_00038024 + 0x54); puVar1 != (undefined4 *)0x0;
        puVar1 = (undefined4 *)puVar1[0x42]) {
      if (*(short *)(puVar1 + 1) == param_1) {
        _StopMovie(*puVar1);
      }
    }
  }
  return;
}


// ==== _PauseGame @ 0000d34b ====

void _PauseGame(char param_1)

{
  int iVar1;
  int iVar2;
  undefined4 uVar3;
  int iVar4;
  undefined *puVar5;
  
  puVar5 = PTR__g_00038024;
  if (PTR__g_00038024[0x7f] != '\0') {
    PTR__g_00038024[0x7f] = 0;
  }
  puVar5[0x67] = param_1;
  if (param_1 == '\0') {
    puVar5[0x86] = 0;
    if ((*(short *)(puVar5 + 0x60) != 0) && (*(int *)(puVar5 + 0xc0) != 0)) {
      iVar1 = *(int *)(puVar5 + 0xa8);
      iVar4 = _TickCount();
      iVar2 = *(int *)(puVar5 + 0xc0);
      *(undefined4 *)(puVar5 + 0xc0) = 0;
      *(int *)(puVar5 + 0xa8) = iVar1 + (iVar4 - iVar2);
    }
    if (*(short *)(puVar5 + 0x60) != 0 && *(int *)(puVar5 + 0xb8) < 0x10) {
      _PlaySound(100,0x80);
      puVar5 = PTR__g_00038024;
    }
  }
  else {
    puVar5[0x86] = 1;
    if ((*(short *)(puVar5 + 0x60) != 0) && (*(int *)(puVar5 + 0xc0) == 0)) {
      uVar3 = _TickCount();
      *(undefined4 *)(puVar5 + 0xc0) = uVar3;
    }
    if (*(int *)(puVar5 + 0xb8) < 0xf) {
      _StopSound(100,0x80);
      puVar5 = PTR__g_00038024;
    }
  }
  if (*(short *)(puVar5 + 0x60) != 0) {
    _PlayMovie(0x80);
    _RedrawCustomGameScreen(puVar5[0x67] == '\0');
  }
  if (puVar5[0x80] == '\0') {
    return;
  }
  _PlayMovie();
  return;
}


// ==== _HandleMenuCommand @ 0000d465 ====

void _HandleMenuCommand(undefined4 param_1)

{
  int iVar1;
  int iVar2;
  char cVar3;
  undefined2 uVar4;
  undefined4 uVar5;
  int iVar6;
  bool bVar7;
  undefined *puVar8;
  undefined1 local_11c [268];
  
  puVar8 = PTR__g_00038024;
  if (PTR__g_00038024[0x66] == 0) {
    switch(param_1) {
    case 9:
switchD_0000d498_caseD_9:
      cVar3 = PTR__g_00038024[0x67];
      _PauseGame(1);
      _CreateNewDialog(0x3c);
      if (cVar3 != '\0') {
        return;
      }
      bVar7 = false;
LAB_0000d7aa:
      _PauseGame(bVar7);
      break;
    case 10:
      uVar4 = _RandomBackground();
      puVar8 = PTR__g_00038024;
      *(undefined2 *)(PTR__g_00038024 + 0x8e) = uVar4;
      _AnimationMapScreenToLevelEditor();
      uVar5 = *(undefined4 *)(puVar8 + 0xd0);
      *(undefined4 *)(puVar8 + 0xd0) = 0;
      *(undefined4 *)(puVar8 + 0xd4) = uVar5;
      break;
    case 0xb:
switchD_0000d498_caseD_b:
      _LoadFile(0);
      break;
    case 0xe:
      if (*(short *)(PTR__p_00038028 + 0x20e) % 2 != 1) {
LAB_0000d641:
        _CreateNewDialog(0x55);
        return;
      }
      *(undefined4 *)(PTR__g_00038024 + 0xd0) = 0;
    case 0x12:
switchD_0000d498_caseD_12:
      _LoadCustomLevel();
      break;
    case 0xf:
      uVar5 = _objc_msgSend(PTR_s_NSWorkspace_00036280,PTR_s_sharedWorkspace_000360d0);
      _objc_msgSend(PTR_s_NSURL_000362dc,PTR_s_URLWithString__000361f4,
                    &cf_http___www_ambrosiasw_com_games_aki_addons);
      puVar8 = PTR_s_openURL__000361f8;
      goto LAB_0000d58d;
    }
  }
  else {
    switch(param_1) {
    case 2:
      cVar3 = PTR__g_00038024[0x80];
      if ((PTR__g_00038024[0x66] & cVar3 == '\0') != 0) {
        uVar5 = _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
        puVar8 = PTR_s_abortGame_00036060;
        goto LAB_0000d58d;
      }
      goto LAB_0000d564;
    case 3:
      if (PTR__g_00038024[0x80] != '\0') {
        _UndoLastLEMove();
      }
      if (1 < *(short *)(PTR__p_00038028 + 0x20c) && *(int *)(puVar8 + 0xb8) != 0) {
        if (*(short *)(puVar8 + 0x60) == 0) {
          iVar1 = *(int *)(puVar8 + 0xa8);
          iVar6 = _TickCount();
          iVar2 = *(int *)(puVar8 + 0xc0);
          *(undefined4 *)(puVar8 + 0xc0) = 0;
          *(int *)(puVar8 + 0xa8) = iVar1 + (iVar6 - iVar2);
        }
        _UndoLastCGMove();
      }
      break;
    case 4:
      if (*(short *)(PTR__g_00038024 + 0x60) != 0 && PTR__g_00038024[0x67] == '\0') {
        _ShowNextCGHint();
      }
      break;
    case 6:
      if (PTR__g_00038024[0x67] == '\0') {
        if (*(short *)(PTR__g_00038024 + 0x60) == 0) {
          iVar1 = *(int *)(PTR__g_00038024 + 0xa8);
          iVar6 = _TickCount();
          iVar2 = *(int *)(puVar8 + 0xc0);
          *(undefined4 *)(puVar8 + 0xc0) = 0;
          *(int *)(puVar8 + 0xa8) = iVar1 + (iVar6 - iVar2);
        }
        _ReshuffleCustomTiles();
      }
      break;
    case 7:
      _PlaySound(0x4b,0x40);
      bVar7 = PTR__g_00038024[0x67] == '\0';
      goto LAB_0000d7aa;
    case 9:
      goto switchD_0000d498_caseD_9;
    case 10:
      cVar3 = PTR__g_00038024[0x80];
LAB_0000d564:
      if (cVar3 != '\0') {
        uVar5 = _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
        puVar8 = PTR_s_exitLevelEditor_00036084;
LAB_0000d58d:
        _objc_msgSend(uVar5,puVar8);
      }
      break;
    case 0xb:
      goto switchD_0000d498_caseD_b;
    case 0xc:
      *(undefined4 *)(PTR__g_00038024 + 0xd0) = 0;
    case 0xd:
      _DoSaveAs();
      break;
    case 0x10:
      _DoClearLayer();
      break;
    case 0x11:
      _DoClearAll();
      break;
    case 0x13:
      if (*(short *)(PTR__p_00038028 + 0x20e) % 2 != 1) goto LAB_0000d641;
      if ((PTR__g_00038024[0x1f0] != '\0') && (cVar3 = _DoSaveAs(), cVar3 == '\0')) {
        return;
      }
      uVar5 = *(undefined4 *)(puVar8 + 0xd0);
      _StringCopy(local_11c,puVar8 + 0xd8);
      _AnimationEditorScreenToMap();
      *(undefined4 *)(puVar8 + 0xd0) = uVar5;
      _StringCopy(puVar8 + 0xd8,local_11c);
      puVar8[0x68] = 0;
      _DeleteAllTiles();
      goto switchD_0000d498_caseD_12;
    }
  }
  return;
}


// ==== _DeleteAllCGTiles @ 0000d7f2 ====

void _DeleteAllCGTiles(void)

{
  int iVar1;
  int iVar2;
  undefined *puVar3;
  undefined *puVar4;
  void *pvVar5;
  
  puVar4 = PTR__gCGFirstPtr_00034044;
  for (pvVar5 = *(void **)PTR__gCGFirstPtr_00034044; puVar3 = PTR__gCGLastPtr_00034040,
      pvVar5 != (void *)0x0; pvVar5 = *(void **)((int)pvVar5 + 0x20)) {
    iVar1 = *(int *)((int)pvVar5 + 0x24);
    iVar2 = *(int *)((int)pvVar5 + 0x20);
    if (iVar2 != 0 || iVar1 != 0) {
      if (iVar2 != 0) {
        if (iVar1 != 0) {
          *(int *)(iVar2 + 0x24) = iVar1;
          *(int *)(*(int *)((int)pvVar5 + 0x24) + 0x20) = iVar2;
        }
        else {
          *(undefined4 *)(iVar2 + 0x24) = 0;
          *(int *)puVar4 = iVar2;
        }
      }
      else {
        *(undefined4 *)(iVar1 + 0x20) = 0;
        *(int *)puVar3 = iVar1;
      }
    }
    else {
      *(undefined4 *)puVar4 = 0;
      *(undefined4 *)puVar3 = 0;
    }
    _free(pvVar5);
  }
  return;
}


// ==== _DeleteAllSTTiles @ 0000d880 ====

void _DeleteAllSTTiles(void)

{
  int iVar1;
  int iVar2;
  undefined *puVar3;
  undefined *puVar4;
  void *pvVar5;
  
  puVar4 = PTR__gSTFirstPtr_0003404c;
  for (pvVar5 = *(void **)PTR__gSTFirstPtr_0003404c; puVar3 = PTR__gSTLastPtr_00034048,
      pvVar5 != (void *)0x0; pvVar5 = *(void **)((int)pvVar5 + 0x20)) {
    iVar1 = *(int *)((int)pvVar5 + 0x24);
    iVar2 = *(int *)((int)pvVar5 + 0x20);
    if (iVar2 != 0 || iVar1 != 0) {
      if (iVar2 != 0) {
        if (iVar1 != 0) {
          *(int *)(iVar2 + 0x24) = iVar1;
          *(int *)(*(int *)((int)pvVar5 + 0x24) + 0x20) = iVar2;
        }
        else {
          *(undefined4 *)(iVar2 + 0x24) = 0;
          *(int *)puVar4 = iVar2;
        }
      }
      else {
        *(undefined4 *)(iVar1 + 0x20) = 0;
        *(int *)puVar3 = iVar1;
      }
    }
    else {
      *(undefined4 *)puVar4 = 0;
      *(undefined4 *)puVar3 = 0;
    }
    _free(pvVar5);
  }
  return;
}


// ==== _FlashCGButton @ 0000d90e ====

void _FlashCGButton(short param_1,char param_2)

{
  short sVar1;
  undefined *puVar2;
  short sVar3;
  int iVar4;
  int iVar5;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  sVar3 = (short)((param_1 + -1) / 2);
  sVar1 = sVar3 * 0x26;
  _SetRect(&local_24,(int)(short)(sVar1 + 7),0x11,(int)(short)(sVar1 + 0x34),0x3e);
  _SetRect(&local_2c,(int)(short)(sVar1 + 0xe),0x225,(int)(short)(sVar1 + 0x3b),0x252);
  _DrawToGWorld(PTR__g_00038024 + 0x1c,PTR__g_00038024 + 0x2c,PTR__g_00038024 + 0x1c,local_24,
                local_20,local_2c,local_28,local_34,local_30,0xfffffff7);
  if (param_1 == 5) {
    iVar5 = 0x163;
    iVar4 = 0x14a;
  }
  else {
    sVar3 = sVar3 * 0x19;
    iVar5 = (int)(short)(sVar3 + 0xe6);
    iVar4 = (int)(short)(sVar3 + 0xcd);
  }
  _SetRect(&local_24,iVar4,0x19b,iVar5,0x1b4);
  _SetRect(&local_2c,(int)(short)(sVar1 + 0x18),0x22f,(int)(short)(sVar1 + 0x31),0x248);
  _SetRect(&local_34,0x163,0x19b,0x17c,0x1b4);
  puVar2 = PTR__g_00038024;
  _DrawToGWorld(PTR__g_00038024,PTR__g_00038024 + 0x2c,PTR__g_00038024,local_24,local_20,local_2c,
                local_28,local_34,local_30,1);
  if (param_2 != '\0') {
    if (puVar2[0x87] == '\0') {
      iVar5 = *(int *)(puVar2 + 0x88);
      *(int *)(puVar2 + 0x88) = iVar5 + 1;
      if (iVar5 + 1 == 6) {
        puVar2[0x87] = 1;
      }
    }
    else {
      iVar5 = *(int *)(puVar2 + 0x88);
      *(int *)(puVar2 + 0x88) = iVar5 + -1;
      if (iVar5 + -1 == 1) {
        puVar2[0x87] = 0;
      }
    }
    _SetRect(&local_24,0xe9,0x95,0x102,0xae);
    _SetRect(&local_2c,(int)(short)(sVar1 + 0x18),0x22f,(int)(short)(sVar1 + 0x31),0x248);
    puVar2 = PTR__g_00038024;
    sVar3 = (short)*(undefined4 *)(PTR__g_00038024 + 0x88) * 0x19;
    _SetRect(&local_34,(int)local_24._2_2_,(int)(short)(sVar3 + (short)local_24),(int)local_20._2_2_
             ,(int)(short)(sVar3 + (short)local_20));
    _DrawToGWorld(puVar2,puVar2 + 0x2c,puVar2,local_24,local_20,local_2c,local_28,local_34,local_30,
                  1);
  }
  _SetRect(&local_24,(int)(short)(sVar1 + 7),0x11,(int)(short)(sVar1 + 0x34),0x3e);
  _SetRect(&local_2c,(int)(short)(sVar1 + 0xe),0x225,(int)(short)(sVar1 + 0x3b),0x252);
  _DrawToWindow(PTR__g_00038024 + 0x2c,local_2c,local_28,local_2c,local_28,1);
  return;
}


// ==== _AnimationCustomGameScreenToMap @ 0000dca0 ====

void _AnimationCustomGameScreenToMap(void)

{
  int *piVar1;
  undefined2 uVar2;
  int iVar3;
  undefined4 uVar4;
  undefined4 uVar5;
  undefined *puVar6;
  int iVar7;
  undefined4 *puVar8;
  int iVar9;
  undefined *puVar10;
  short sVar11;
  float fVar12;
  uint local_a4;
  short asStack_98 [50];
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  _StopSound(100,0x80);
  puVar6 = PTR__g_00038024;
  asStack_98[0x1a] = 0x2c9;
  asStack_98[0x1b] = 0;
  asStack_98[0x1c] = 0x193;
  asStack_98[0x1d] = 0;
  asStack_98[0x1e] = 0xe7;
  asStack_98[0x1f] = 0;
  uVar2 = *(undefined2 *)(PTR__g_00038024 + 0x5c);
  asStack_98[0x20] = 0x59;
  asStack_98[0x21] = 0;
  *(undefined2 *)(PTR__g_00038024 + 0x5c) = 0;
  asStack_98[0x22] = 0xc;
  asStack_98[0x23] = 0;
  *(undefined2 *)(puVar6 + 0x5e) = uVar2;
  asStack_98[0x24] = 0xea;
  asStack_98[0x25] = 0;
  asStack_98[0x26] = 0x146;
  asStack_98[0x27] = 0;
  asStack_98[0x28] = 0x163;
  asStack_98[0x29] = 0;
  asStack_98[0x2a] = 0x223;
  asStack_98[0x2b] = 0;
  asStack_98[0x2c] = 0x1b2;
  asStack_98[0x2d] = 0;
  asStack_98[0x2e] = 0x176;
  asStack_98[0x2f] = 0;
  asStack_98[0x30] = 0x195;
  asStack_98[0x31] = 0;
  asStack_98[2] = 0x136;
  asStack_98[3] = 0;
  asStack_98[4] = 0xb0;
  asStack_98[5] = 0;
  asStack_98[6] = 0x73;
  asStack_98[7] = 0;
  asStack_98[8] = 0x2d;
  asStack_98[9] = 0;
  asStack_98[10] = 0x10d;
  asStack_98[0xb] = 0;
  asStack_98[0xc] = 0x164;
  asStack_98[0xd] = 0;
  asStack_98[0xe] = 0x119;
  asStack_98[0xf] = 0;
  asStack_98[0x10] = 0x126;
  asStack_98[0x11] = 0;
  asStack_98[0x12] = 0x13b;
  asStack_98[0x13] = 0;
  asStack_98[0x14] = 0xdf;
  asStack_98[0x15] = 0;
  asStack_98[0x16] = 0xd8;
  asStack_98[0x17] = 0;
  asStack_98[0x18] = 0xf4;
  asStack_98[0x19] = 0;
  _SetRect(&local_24,0,0,800,600);
  _SetRect(&local_34,0,0,800,600);
  _DrawToGWorld(puVar6 + 0x20,puVar6 + 0x2c,puVar6 + 0x20,local_24,local_20,local_34,local_30,
                local_2c,local_28,0xfffffff7);
  if (puVar6[0x7d] != '\0') {
    _PlaySound(0x28,0x100);
  }
  iVar7 = 1;
  puVar10 = PTR__p_00038028;
  do {
    _SetRect(&local_24,0xcd,0x150,0x118,0x199);
    _SetRect(&local_34,(int)asStack_98[iVar7 * 2 + 0x18],(int)asStack_98[iVar7 * 2],
             (int)(short)(asStack_98[iVar7 * 2 + 0x18] + 0x4a),
             (int)(short)(asStack_98[iVar7 * 2] + 0x48));
    _SetRect(&local_2c,0x118,0x150,0x163,0x199);
    if (puVar10[0x200] != '\0') {
      _DrawToGWorld(puVar6,puVar6 + 0x2c,puVar6,local_24,local_20,local_34,local_30,local_2c,
                    local_28,1);
    }
    _SetRect(&local_24,0xcd,0x150,0x118,0x199);
    _SetRect(&local_34,(int)asStack_98[(iVar7 + 1) * 2 + 0x18],(int)asStack_98[(iVar7 + 1) * 2],
             (int)(short)(asStack_98[(iVar7 + 1) * 2 + 0x18] + 0x4a),
             (int)(short)(asStack_98[(iVar7 + 1) * 2] + 0x48));
    _SetRect(&local_2c,0x118,0x150,0x163,0x199);
    if (puVar10[0x201] != '\0') {
      _DrawToGWorld(puVar6,puVar6 + 0x2c,puVar6,local_24,local_20,local_34,local_30,local_2c,
                    local_28,1);
    }
    iVar7 = iVar7 + 2;
    puVar10 = puVar10 + 2;
  } while (iVar7 != 0xd);
  _SetRect(&local_24,0,0,800,600);
  _SetRect(&local_34,0,0,800,600);
  puVar6 = PTR__g_00038024;
  _DrawToGWorld(PTR__g_00038024 + 0x14,PTR__g_00038024 + 0x30,PTR__g_00038024 + 0x14,local_24,
                local_20,local_34,local_30,local_2c,local_28,0xfffffff7);
  puVar8 = *(undefined4 **)(puVar6 + 0x58);
  if (1 < *(short *)(PTR__p_00038028 + 0x20e)) {
    for (; puVar8 != (undefined4 *)0x0; puVar8 = (undefined4 *)puVar8[0x42]) {
      if (*(short *)(puVar8 + 1) == *(short *)(PTR__g_00038024 + 0x5c)) {
        _SetMovieVolume(*puVar8,0x80);
        _StartMovie(*puVar8);
      }
    }
  }
  iVar7 = _TickCount();
  do {
    iVar3 = _TickCount();
    if ((uint)(iVar3 - iVar7) < 0x3d) {
      iVar3 = _TickCount();
      local_a4 = iVar3 - iVar7;
      fVar12 = (float)(local_a4 >> 0x10) * FLOAT_00033b30 + (float)(local_a4 & 0xffff);
    }
    else {
      local_a4 = 0x3c;
      fVar12 = FLOAT_00033b2c;
    }
    sVar11 = (short)(int)((fVar12 / FLOAT_00033b2c) * FLOAT_00033b34 + FLOAT_00033b38);
    iVar3 = (int)(short)(400 - sVar11);
    _SetRect(&local_24,(int)sVar11,0,400,600);
    iVar9 = (int)(short)(sVar11 + 400);
    _SetRect(&local_34,0,0,iVar3,600);
    puVar6 = PTR__g_00038024 + 0x2c;
    _DrawToWindow(puVar6,local_24,local_20,local_34,local_30,0);
    _SetRect(&local_24,iVar3,0,iVar9,600);
    _SetRect(&local_34,iVar3,0,iVar9,600);
    _DrawToWindow(PTR__g_00038024 + 0x30,local_24,local_20,local_34,local_30,0);
    _SetRect(&local_24,400,0,(int)(short)(800 - sVar11),600);
    _SetRect(&local_34,iVar9,0,800,600);
    _DrawToWindow(puVar6,local_24,local_20,local_34,local_30,1);
    puVar6 = PTR__g_00038024;
  } while (local_a4 < 0x3c);
  *(int *)(PTR__g_00038024 + 0xc4) =
       *(int *)(PTR__g_00038024 + 0xc4) + *(int *)(PTR__g_00038024 + 0xb4) * -0x3c;
  *(undefined4 *)(puVar6 + 0xb4) = 0;
  *(undefined2 *)(puVar6 + 0x60) = 0;
  puVar6[100] = 0;
  puVar6[0x66] = 0;
  puVar6[0x68] = 0;
  _DisableMenuCommand(0,4);
  _DisableMenuCommand(0,6);
  _DisableMenuCommand(0,7);
  _DisableMenuCommand(0,3);
  _DisableMenuCommand(0,2);
  _EnableMenuCommand(0,10);
  _EnableMenuCommand(0,0xe);
  _EnableMenuCommand(0,0xf);
  piVar1 = (int *)(PTR__g_00038024 + 0xd0);
  PTR__g_00038024[0x1f1] = 0;
  if (*piVar1 != 0) {
    _EnableMenuCommand(0,0x12);
    uVar4 = _GetMenuHandle(1);
    uVar5 = _CFStringCreateMutable(*(undefined4 *)PTR_00038034,0);
    _CFStringAppendCString(uVar5,"Replay ",0x600);
    _CFStringAppendCString(uVar5,PTR__g_00038024 + 0xd8,0x600);
    _SetMenuItemTextWithCFString(uVar4,3,uVar5);
    _CFRelease(uVar5);
  }
  uVar4 = _GetMenuHandle(1);
  uVar5 = _CFStringCreateMutable(*(undefined4 *)PTR_00038034,0);
  _CFStringAppendCString(uVar5,"New Game",0x600);
  _SetMenuItemTextWithCFString(uVar4,1,uVar5);
  _CFRelease(uVar5);
  _RedrawMapScreen();
  return;
}


// ==== _TriggerGameToMap @ 0000e5a2 ====

void _TriggerGameToMap(void)

{
  undefined *puVar1;
  undefined4 *puVar2;
  
  puVar1 = PTR__g_00038024;
  for (puVar2 = *(undefined4 **)(PTR__g_00038024 + 0x58); puVar2 != (undefined4 *)0x0;
      puVar2 = (undefined4 *)puVar2[0x42]) {
    if (*(short *)(puVar2 + 1) == *(short *)(puVar1 + 0x5c)) {
      _StopMovie(*puVar2);
    }
  }
  _DeleteAllCGTiles();
  _AnimationCustomGameScreenToMap();
  return;
}


// ==== _CountOpenPairs @ 0000e5e4 ====

int _CountOpenPairs(void)

{
  short sVar1;
  ushort uVar2;
  int iVar3;
  int iVar4;
  uint uVar5;
  short sVar6;
  ushort local_28;
  short local_16;
  
  local_28 = 0;
  local_16 = 0;
  for (iVar3 = *(int *)PTR__gCGFirstPtr_00034044; iVar3 != 0; iVar3 = *(int *)(iVar3 + 0x20)) {
    if ((*(char *)(iVar3 + 0x18) != '\0') &&
       (sVar6 = 0, iVar4 = *(int *)PTR__gCGFirstPtr_00034044, *(char *)(iVar3 + 0x1c) == '\0')) {
      for (; iVar4 != 0; iVar4 = *(int *)(iVar4 + 0x20)) {
        if ((iVar3 != iVar4 && *(char *)(iVar4 + 0x18) != '\0') && (*(char *)(iVar4 + 0x1c) == '\0')
           ) {
          sVar1 = *(short *)(iVar4 + 2);
          if (*(short *)(iVar3 + 2) == sVar1) {
            sVar6 = sVar6 + 1;
          }
          else {
            sVar6 = (sVar6 + 1) -
                    (ushort)((sVar1 < 0xcd || 7 < (ushort)(*(short *)(iVar3 + 2) - 0xcdU)) ||
                            0xd4 < sVar1);
          }
        }
      }
      if (0 < sVar6) {
        local_28 = local_28 + 1;
        local_16 = local_16 + (ushort)(sVar6 == 2);
      }
    }
  }
  uVar5 = (uint)local_28;
  if (local_16 == 6) {
    uVar5 = local_28 - 2;
  }
  uVar2 = (ushort)(uVar5 >> 0xf) & 1;
  sVar6 = (short)uVar5;
  if ((ushort)((sVar6 + uVar2 & 1) - uVar2) == 1) {
    iVar3 = sVar6 + -1;
  }
  else {
    iVar3 = (int)sVar6;
  }
  sVar6 = (short)(int)((double)iVar3 * DOUBLE_00033fa0);
  *(short *)(PTR__g_00038024 + 0x60) = sVar6;
  return (int)sVar6;
}


// ==== _RedrawCustomTimeAccumulated @ 0000e6e4 ====

void _RedrawCustomTimeAccumulated(undefined1 param_1)

{
  short sVar1;
  short sVar2;
  short sVar3;
  undefined *puVar4;
  short sVar5;
  int iVar6;
  int iVar7;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  sVar1 = _CountOpenPairs();
  if (sVar1 != 0) {
    sVar3 = (short)(*(int *)(PTR__g_00038024 + 0xb4) / 0xe10);
    iVar6 = *(int *)(PTR__g_00038024 + 0xb4) % 0xe10;
    sVar2 = (short)(iVar6 / 0x3c);
    sVar5 = (short)iVar6 + sVar2 * -0x3c;
    _SetRect(&local_24,0x26c,0x26,0x2ed,0x3c);
    sVar1 = sVar5 / 10;
    _SetRect(&local_2c,0x273,0x23a,0x2f4,0x250);
    puVar4 = PTR__g_00038024 + 0x2c;
    _DrawToGWorld(PTR__g_00038024 + 0x1c,puVar4,PTR__g_00038024 + 0x1c,local_24,local_20,local_2c,
                  local_28,local_34,local_30,0xfffffff7);
    sVar5 = sVar5 % 10;
    if (sVar5 == 0) {
      sVar5 = 10;
    }
    iVar7 = (int)(short)(sVar5 * 0x1e + 0x75);
    iVar6 = (int)(short)(sVar5 * 0x1e + 0x57);
    _SetRect(&local_24,0x9b,iVar6,0xb3,iVar7);
    _SetRect(&local_2c,0x2d5,0x23a,0x2e5,0x250);
    _SetRect(&local_34,0xb4,iVar6,0xcc,iVar7);
    _DrawToGWorld(PTR__g_00038024,puVar4,PTR__g_00038024,local_24,local_20,local_2c,local_28,
                  local_34,local_30,1);
    if (sVar1 == 0) {
      sVar1 = 10;
    }
    iVar7 = (int)(short)(sVar1 * 0x1e + 0x75);
    iVar6 = (int)(short)(sVar1 * 0x1e + 0x57);
    _SetRect(&local_24,0x9b,iVar6,0xb3,iVar7);
    _SetRect(&local_2c,0x2c5,0x23a,0x2d5,0x250);
    _SetRect(&local_34,0xb4,iVar6,0xcc,iVar7);
    _DrawToGWorld(PTR__g_00038024,puVar4,PTR__g_00038024,local_24,local_20,local_2c,local_28,
                  local_34,local_30,1);
    _SetRect(&local_24,0x9b,0x1a1,0xb3,0x1bf);
    _SetRect(&local_2c,699,0x23a,0x2cb,0x250);
    _SetRect(&local_34,0xb4,0x1a1,0xcc,0x1bf);
    _DrawToGWorld(PTR__g_00038024,puVar4,PTR__g_00038024,local_24,local_20,local_2c,local_28,
                  local_34,local_30,1);
    sVar1 = sVar2 % 10;
    if (sVar2 % 10 == 0) {
      sVar1 = 10;
    }
    iVar7 = (int)(short)(sVar1 * 0x1e + 0x75);
    iVar6 = (int)(short)(sVar1 * 0x1e + 0x57);
    _SetRect(&local_24,0x9b,iVar6,0xb3,iVar7);
    _SetRect(&local_2c,0x2b1,0x23a,0x2c1,0x250);
    _SetRect(&local_34,0xb4,iVar6,0xcc,iVar7);
    _DrawToGWorld(PTR__g_00038024,puVar4,PTR__g_00038024,local_24,local_20,local_2c,local_28,
                  local_34,local_30,1);
    sVar1 = sVar2 / 10;
    if (sVar2 / 10 == 0) {
      sVar1 = 10;
    }
    iVar7 = (int)(short)(sVar1 * 0x1e + 0x75);
    iVar6 = (int)(short)(sVar1 * 0x1e + 0x57);
    _SetRect(&local_24,0x9b,iVar6,0xb3,iVar7);
    _SetRect(&local_2c,0x2a1,0x23a,0x2b1,0x250);
    _SetRect(&local_34,0xb4,iVar6,0xcc,iVar7);
    _DrawToGWorld(PTR__g_00038024,puVar4,PTR__g_00038024,local_24,local_20,local_2c,local_28,
                  local_34,local_30,1);
    _SetRect(&local_24,0x9b,0x1a1,0xb3,0x1bf);
    _SetRect(&local_2c,0x297,0x23a,0x2a7,0x250);
    _SetRect(&local_34,0xb4,0x1a1,0xcc,0x1bf);
    _DrawToGWorld(PTR__g_00038024,puVar4,PTR__g_00038024,local_24,local_20,local_2c,local_28,
                  local_34,local_30,1);
    sVar1 = sVar3 / 10;
    sVar3 = sVar3 % 10;
    if (sVar3 == 0) {
      sVar3 = 10;
    }
    iVar6 = (int)(short)(sVar3 * 0x1e + 0x57);
    iVar7 = (int)(short)(sVar3 * 0x1e + 0x75);
    _SetRect(&local_24,0x9b,iVar6,0xb3,iVar7);
    _SetRect(&local_2c,0x28d,0x23a,0x29d,0x250);
    _SetRect(&local_34,0xb4,iVar6,0xcc,iVar7);
    _DrawToGWorld(PTR__g_00038024,puVar4,PTR__g_00038024,local_24,local_20,local_2c,local_28,
                  local_34,local_30,1);
    if (sVar1 == 0) {
      sVar1 = 10;
    }
    iVar7 = (int)(short)(sVar1 * 0x1e + 0x57);
    iVar6 = (int)(short)(sVar1 * 0x1e + 0x75);
    _SetRect(&local_24,0x9b,iVar7,0xb3,iVar6);
    _SetRect(&local_2c,0x27d,0x23a,0x28d,0x250);
    _SetRect(&local_34,0xb4,iVar7,0xcc,iVar6);
    _DrawToGWorld(PTR__g_00038024,puVar4,PTR__g_00038024,local_24,local_20,local_2c,local_28,
                  local_34,local_30,1);
    _SetRect(&local_24,0x273,0x23a,0x2f4,0x250);
    _SetRect(&local_2c,0x273,0x23a,0x2f4,0x250);
    _DrawToWindow(puVar4,local_24,local_20,local_2c,local_28,param_1);
  }
  return;
}


// ==== _RedrawCustomTimeBar @ 0000efa0 ====

void _RedrawCustomTimeBar(int param_1,undefined1 param_2)

{
  short *psVar1;
  int iVar2;
  int iVar3;
  undefined *puVar4;
  short sVar5;
  short sVar6;
  undefined4 uVar7;
  int iVar8;
  undefined *puVar9;
  undefined4 *puVar10;
  int iVar11;
  undefined4 uVar12;
  undefined4 uVar13;
  undefined4 uVar14;
  short local_68;
  short local_4c;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  sVar5 = _CountOpenPairs();
  if (sVar5 != 0) {
    _SetRect(&local_2c,0x86,0x19,0x24e,0x38);
    _SetRect(&local_24,0x8d,0x22d,0x255,0x24c);
    puVar4 = PTR__g_00038024;
    _DrawToGWorld(PTR__g_00038024 + 0x1c,PTR__g_00038024 + 0x2c,PTR__g_00038024 + 0x1c,local_2c,
                  local_28,local_24,local_20,local_34,local_30,0xfffffff7);
    if (*(short *)(PTR__p_00038028 + 0x20c) == 3) {
      uVar7 = _TickCount();
      *(undefined4 *)(puVar4 + 0xa8) = uVar7;
    }
    if (300 < *(int *)(puVar4 + 0xb8)) {
      *(int *)(puVar4 + 0xac) = *(int *)(puVar4 + 0xb8) + *(int *)(puVar4 + 0xac) + -300;
    }
    puVar9 = PTR__g_00038024;
    if (puVar4[0x67] != '\0') {
      param_1 = *(int *)(puVar4 + 0xc0);
    }
    iVar3 = (int)&DAT_00002328 -
            ((param_1 - *(int *)(puVar4 + 0xa8)) + *(int *)(PTR__g_00038024 + 0xac) * 0x3c +
            *(int *)(PTR__g_00038024 + 0xb0) * -0x3c);
    iVar8 = (iVar3 * 0x1c2) / 18000;
    sVar5 = 0x11;
    if (0x1c2 < iVar8) {
      iVar8 = 0x1c2;
    }
    local_68 = (short)iVar8;
    while (0 < iVar3 && 0 < sVar5) {
      iVar2 = sVar5 * 0x18;
      if (sVar5 * 0x30 < iVar8 || iVar8 < iVar2) {
        if (iVar8 < 0x18) {
          _SetRect(&local_2c,3,0x27,0x1c,0x4e);
          _SetRect(&local_24,0x90,0x228,0xa9,0x24f);
          if (local_68 == 0x17) {
            uVar14 = 0xea;
            uVar12 = 0x1c;
            uVar13 = 0xc3;
            uVar7 = 3;
          }
          else {
            if (local_68 == 0x16) {
              _SetRect(&local_34,0x1c,0xc3,0x35,0xea);
LAB_0000f7a1:
              if (local_68 == 0x11) {
                _SetRect(&local_34,3,0xea,0x1c,0x111);
                goto LAB_0000f8cd;
              }
LAB_0000f7df:
              if (local_68 == 0x10) {
                _SetRect(&local_34,0x1c,0xea,0x35,0x111);
                goto LAB_0000f904;
              }
LAB_0000f81d:
              if (local_68 == 0xf) {
                _SetRect(&local_34,0x35,0xea,0x4e,0x111);
                goto LAB_0000f93b;
              }
LAB_0000f85f:
              if (local_68 != 0xe) goto LAB_0000f896;
              _SetRect(&local_34,0x4e,0xea,0x67,0x111);
LAB_0000f972:
              if (local_68 == 9) {
                _SetRect(&local_34,0x35,0x75,0x4e,0x9c);
                goto LAB_0000fa85;
              }
LAB_0000f9a9:
              if (local_68 == 8) {
                _SetRect(&local_34,0x4e,0x75,0x67,0x9c);
                goto LAB_0000fabc;
              }
LAB_0000f9e0:
              if (local_68 == 7) {
                _SetRect(&local_34,0x67,0x75,0x80,0x9c);
                goto LAB_0000faf3;
              }
LAB_0000fa17:
              if (local_68 != 6) goto LAB_0000fa4e;
              _SetRect(&local_34,0x80,0x75,0x99,0x9c);
LAB_0000fb2a:
              if (local_68 == 1) {
                uVar14 = 0xc3;
                uVar12 = 0x80;
                uVar13 = 0x9c;
                uVar7 = 0x67;
                goto LAB_0000fc28;
              }
LAB_0000fb61:
              if (local_68 != 0) goto LAB_0000fc70;
              uVar12 = 0x99;
              uVar7 = 0x80;
            }
            else {
              if (local_68 == 0x15) {
                _SetRect(&local_34,0x35,0xc3,0x4e,0xea);
                goto LAB_0000f7df;
              }
              if (local_68 == 0x14) {
                _SetRect(&local_34,0x4e,0xc3,0x67,0xea);
                goto LAB_0000f81d;
              }
              if (local_68 == 0x13) {
                _SetRect(&local_34,0x67,0xc3,0x80,0xea);
                goto LAB_0000f85f;
              }
              if (local_68 != 0x12) goto LAB_0000f7a1;
              _SetRect(&local_34,0x80,0xc3,0x99,0xea);
LAB_0000f896:
              if (local_68 == 0xd) {
                _SetRect(&local_34,0x67,0xea,0x80,0x111);
                goto LAB_0000f9a9;
              }
LAB_0000f8cd:
              if (local_68 == 0xc) {
                _SetRect(&local_34,0x80,0xea,0x99,0x111);
                goto LAB_0000f9e0;
              }
LAB_0000f904:
              if (local_68 == 0xb) {
                _SetRect(&local_34,3,0x75,0x1c,0x9c);
                goto LAB_0000fa17;
              }
LAB_0000f93b:
              if (local_68 != 10) goto LAB_0000f972;
              _SetRect(&local_34,0x1c,0x75,0x35,0x9c);
LAB_0000fa4e:
              if (local_68 == 5) {
                _SetRect(&local_34,3,0x9c,0x1c,0xc3);
                goto LAB_0000fb61;
              }
LAB_0000fa85:
              if (local_68 == 4) {
                uVar12 = 0x35;
                uVar7 = 0x1c;
              }
              else {
LAB_0000fabc:
                if (local_68 == 3) {
                  uVar14 = 0xc3;
                  uVar12 = 0x4e;
                  uVar13 = 0x9c;
                  uVar7 = 0x35;
                  goto LAB_0000fc28;
                }
LAB_0000faf3:
                if (local_68 != 2) goto LAB_0000fb2a;
                uVar12 = 0x67;
                uVar7 = 0x4e;
              }
            }
            uVar14 = 0xc3;
            uVar13 = 0x9c;
          }
LAB_0000fc28:
          _SetRect(&local_34,uVar7,uVar13,uVar12,uVar14);
          goto LAB_0000fc70;
        }
        sVar5 = sVar5 + -1;
      }
      else {
        sVar5 = sVar5 * 0x19;
        iVar11 = (int)(short)(sVar5 + 3);
        _SetRect(&local_2c,3,0x27,iVar11,0x4e);
        _SetRect(&local_24,0x90,0x228,(int)(short)(sVar5 + 0x90),0x24f);
        _SetRect(&local_34,3,0x4e,iVar11,0x75);
        _DrawToGWorld(puVar9,puVar9 + 0x2c,puVar9,local_2c,local_28,local_24,local_20,local_34,
                      local_30,1);
        local_4c = (short)iVar2;
        sVar6 = local_68 - local_4c;
        _SetRect(&local_2c,iVar11,0x27,(int)(short)(sVar5 + 0x1c),0x4e);
        _SetRect(&local_24,(int)(short)(sVar5 + 0x90),0x228,(int)(short)(sVar5 + 0xa9),0x24f);
        if (sVar6 == 0xb) {
          uVar13 = 0x9c;
          uVar7 = 0x75;
LAB_0000f5b5:
          uVar14 = 0x1c;
          uVar12 = 3;
        }
        else if (sVar6 == 10) {
          uVar13 = 0x9c;
          uVar7 = 0x75;
LAB_0000f5ea:
          uVar14 = 0x35;
          uVar12 = 0x1c;
        }
        else if (sVar6 == 9) {
          uVar13 = 0x9c;
          uVar7 = 0x75;
LAB_0000f60f:
          uVar14 = 0x4e;
          uVar12 = 0x35;
        }
        else if (sVar6 == 8) {
          uVar13 = 0x9c;
          uVar7 = 0x75;
LAB_0000f631:
          uVar14 = 0x67;
          uVar12 = 0x4e;
        }
        else if (sVar6 == 7) {
          uVar13 = 0x9c;
          uVar7 = 0x75;
LAB_0000f653:
          uVar14 = 0x80;
          uVar12 = 0x67;
        }
        else {
          if (sVar6 == 6) {
            uVar13 = 0x9c;
            uVar7 = 0x75;
            goto LAB_0000f67b;
          }
          if (sVar6 == 5) {
            uVar13 = 0xc3;
            uVar7 = 0x9c;
            goto LAB_0000f5b5;
          }
          if (sVar6 == 4) {
            uVar13 = 0xc3;
            uVar7 = 0x9c;
            goto LAB_0000f5ea;
          }
          if (sVar6 == 3) {
            uVar13 = 0xc3;
            uVar7 = 0x9c;
            goto LAB_0000f60f;
          }
          if (sVar6 == 2) {
            uVar13 = 0xc3;
            uVar7 = 0x9c;
            goto LAB_0000f631;
          }
          if (sVar6 == 1) {
            uVar13 = 0xc3;
            uVar7 = 0x9c;
            goto LAB_0000f653;
          }
          if (local_68 == local_4c) {
            uVar13 = 0xc3;
            uVar7 = 0x9c;
          }
          else {
            if (sVar6 < 0x17) {
              if (sVar6 == 0x16) {
                uVar13 = 0xea;
                uVar7 = 0xc3;
                goto LAB_0000f5ea;
              }
              if (sVar6 == 0x15) {
                uVar13 = 0xea;
                uVar7 = 0xc3;
                goto LAB_0000f60f;
              }
              if (sVar6 == 0x14) {
                uVar13 = 0xea;
                uVar7 = 0xc3;
                goto LAB_0000f631;
              }
              if (sVar6 == 0x13) {
                uVar13 = 0xea;
                uVar7 = 0xc3;
                goto LAB_0000f653;
              }
            }
            else {
              _SetRect(&local_34,3,0xc3,0x1c,0xea);
            }
            if (sVar6 != 0x12) {
              if (sVar6 == 0x11) {
                uVar13 = 0x111;
                uVar7 = 0xea;
                goto LAB_0000f5b5;
              }
              if (sVar6 == 0x10) {
                uVar13 = 0x111;
                uVar7 = 0xea;
                goto LAB_0000f5ea;
              }
              if (sVar6 == 0xf) {
                uVar13 = 0x111;
                uVar7 = 0xea;
                goto LAB_0000f60f;
              }
              if (sVar6 == 0xe) {
                uVar13 = 0x111;
                uVar7 = 0xea;
                goto LAB_0000f631;
              }
              if (sVar6 == 0xd) {
                uVar13 = 0x111;
                uVar7 = 0xea;
                goto LAB_0000f653;
              }
              if (sVar6 == 0xc) {
                uVar13 = 0x111;
                uVar7 = 0xea;
                goto LAB_0000f67b;
              }
              goto LAB_0000fc70;
            }
            uVar13 = 0xea;
            uVar7 = 0xc3;
          }
LAB_0000f67b:
          uVar14 = 0x99;
          uVar12 = 0x80;
        }
        _SetRect(&local_34,uVar12,uVar7,uVar14,uVar13);
LAB_0000fc70:
        sVar5 = -1;
        _DrawToGWorld(puVar9,puVar9 + 0x2c,puVar9,local_2c,local_28,local_24,local_20,local_34,
                      local_30,1);
      }
    }
    _SetRect(&local_2c,0x8d,0x22d,0x255,0x24c);
    _SetRect(&local_24,0x8d,0x22d,0x255,0x24c);
    puVar4 = PTR__g_00038024;
    _DrawToWindow(PTR__g_00038024 + 0x2c,local_2c,local_28,local_24,local_20,param_2);
    if (puVar4[0x82] == '\0') {
      if (0xf < *(int *)(puVar4 + 0xb8)) {
        puVar4[0x82] = 1;
        _StopSound(100,0x80);
      }
    }
    else if (*(int *)(puVar4 + 0xb8) < 0x10) {
      _PlaySound(100,0x80);
      puVar4[0x82] = 0;
    }
    puVar4 = PTR__g_00038024;
    if (*(int *)(PTR__g_00038024 + 0xb8) < 1) {
      for (puVar10 = *(undefined4 **)(PTR__g_00038024 + 0x58); puVar10 != (undefined4 *)0x0;
          puVar10 = (undefined4 *)puVar10[0x42]) {
        if (*(short *)(puVar10 + 1) == *(short *)(puVar4 + 0x5c)) {
          _StopMovie(*puVar10);
        }
      }
      _StopSound(100,0x80);
      puVar4 = PTR__g_00038024;
      psVar1 = (short *)(PTR__g_00038024 + 0x90);
      PTR__g_00038024[0x7d] = 1;
      puVar9 = PTR__p_00038028;
      if (*psVar1 < 0xc) {
        *(short *)(PTR__p_00038028 + *psVar1 * 2 + 0x230) =
             *(short *)(PTR__p_00038028 + *psVar1 * 2 + 0x230) + 1;
      }
      else {
        puVar4[0x229] = 1;
        puVar9 = PTR__p_00038028;
      }
      _SavePrefs(puVar9);
      PTR__g_00038024[0x68] = 1;
    }
  }
  return;
}


// ==== _DrawGameTiles @ 0000fe0a ====

void _DrawGameTiles(void)

{
  undefined *puVar1;
  int iVar2;
  short sVar3;
  short sVar4;
  int iVar5;
  undefined *puVar6;
  int iVar7;
  int iVar8;
  undefined4 uVar9;
  undefined4 uVar10;
  short *local_54;
  short local_4c;
  short local_4a;
  int local_48;
  int local_44;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  _SetRect(&local_24,0,0,800,600);
  _SetRect(&local_2c,0,0,800,600);
  puVar1 = PTR__g_00038024;
  _DrawToGWorld(PTR__g_00038024 + 0x14,PTR__g_00038024 + 0x3c,PTR__g_00038024 + 0x14,local_24,
                local_20,local_2c,local_28,local_34,local_30,0xfffffff7);
  local_44 = 0;
  do {
    local_48 = 0;
    do {
      local_4c = 0x20;
      local_4a = (short)local_48;
      do {
        if (local_4a < 0) break;
        puVar6 = puVar1 + 4;
        for (local_54 = *(short **)PTR__gCGFirstPtr_00034044; local_54 != (short *)0x0;
            local_54 = *(short **)(local_54 + 0x10)) {
          sVar3 = *local_54;
          if ((char)local_54[0xe] != '\x01' &&
              (sVar3 == (short)local_44 &&
              ((double)(int)local_4a == *(double *)(local_54 + 4) &&
              (double)(int)local_4c == *(double *)(local_54 + 8)))) {
            sVar4 = (short)(int)(*(double *)(local_54 + 4) * DOUBLE_00033f98 * DOUBLE_00033fa0) +
                    sVar3 * -10 + *(short *)(puVar1 + 0x98);
            sVar3 = (sVar3 * 5 - *(short *)(puVar1 + 0x94)) +
                    (short)(int)(*(double *)(local_54 + 8) * DOUBLE_00033fa8 * DOUBLE_00033fa0);
            _SetRect(&local_24,0,(int)(short)(local_54[1] * 0x32 + -10000),0x26,
                     (int)(short)(local_54[1] * 0x32 + -0x26de));
            _SetRect(&local_2c,8,5,0x2e,0x36);
            _DrawToGWorld(puVar1 + 0xc,puVar6,puVar1 + 0xc,local_24,local_20,local_2c,local_28,
                          local_34,local_30,0xfffffff7);
            _SetRect(&local_24,0,0,0x35,0x45);
            iVar7 = (int)sVar4;
            iVar8 = (int)(short)(sVar4 + 0x45);
            iVar5 = (int)(short)(sVar3 + 0x35);
            iVar2 = (int)sVar3;
            _SetRect(&local_2c,iVar2,iVar7,iVar5,iVar8);
            _SetRect(&local_34,0,0x114,0x35,0x159);
            _DrawToGWorld(puVar6,puVar1 + 0x3c,puVar6,local_24,local_20,local_2c,local_28,local_34,
                          local_30,1);
            if (*(short *)(puVar1 + 0x60) == 0) {
              uVar10 = 0x114;
              uVar9 = 0xcf;
LAB_00010262:
              _SetRect(&local_24,0,uVar9,0x35,uVar10);
              _SetRect(&local_2c,iVar2,iVar7,iVar5,iVar8);
              _SetRect(&local_34,0,0x40b,0x35,0x450);
LAB_00010301:
              _DrawToGWorld(puVar6,puVar1 + 0x3c,puVar6,local_24,local_20,local_2c,local_28,local_34
                            ,local_30,1);
            }
            else {
              if (*(char *)((int)local_54 + 0x1b) != '\0') {
                _SetRect(&local_24,0,0x45,0x35,0x8a);
                _SetRect(&local_2c,iVar2,iVar7,iVar5,iVar8);
                _SetRect(&local_34,0,0x40b,0x35,0x450);
                goto LAB_00010301;
              }
              if ((char)local_54[0xd] != '\0') {
                uVar10 = 0xcf;
                uVar9 = 0x8a;
                goto LAB_00010262;
              }
            }
            _SetRect(&local_24,iVar2,(int)(short)(sVar4 + 1),(int)(short)(sVar3 + 0x33),
                     (int)(short)(sVar4 + 0x43));
            _SetRect(&local_2c,iVar2,(int)(short)(sVar4 + 1),(int)(short)(sVar3 + 0x33),
                     (int)(short)(sVar4 + 0x43));
            _DrawToGWorld(puVar1 + 0x3c,puVar1 + 0x2c,puVar1 + 0x3c,local_24,local_20,local_2c,
                          local_28,local_34,local_30,0xfffffff7);
          }
        }
        local_4c = local_4c + -1;
        local_4a = local_4a + -1;
      } while (local_4c != -1);
      local_48 = local_48 + 1;
    } while (local_48 != 0x32);
    local_44 = local_44 + 1;
    if (local_44 == 7) {
      return;
    }
  } while( true );
}


// ==== _RedrawCustomOpenPairs @ 000103f5 ====

void _RedrawCustomOpenPairs(undefined1 param_1)

{
  short sVar1;
  undefined *puVar2;
  short sVar3;
  int iVar4;
  int iVar5;
  short sVar6;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  sVar1 = _CountOpenPairs();
  _SetRect(&local_24,0x271,10,0x2a1,0x21);
  _SetRect(&local_2c,0x278,0x21e,0x2a8,0x235);
  puVar2 = PTR__g_00038024 + 0x2c;
  _DrawToGWorld(PTR__g_00038024 + 0x1c,puVar2,PTR__g_00038024 + 0x1c,local_24,local_20,local_2c,
                local_28,local_34,local_30,0xfffffff7);
  sVar6 = (sVar1 / 10) % 10;
  sVar3 = sVar1 % 10;
  if (sVar1 % 10 == 0) {
    sVar3 = 10;
  }
  iVar5 = (int)(short)(sVar3 * 0x1e + 0x75);
  iVar4 = (int)(short)(sVar3 * 0x1e + 0x57);
  _SetRect(&local_24,0x9b,iVar4,0xb3,iVar5);
  _SetRect(&local_2c,0x291,0x220,0x2a1,0x236);
  _SetRect(&local_34,0xb4,iVar4,0xcc,iVar5);
  _DrawToGWorld(PTR__g_00038024,puVar2,PTR__g_00038024,local_24,local_20,local_2c,local_28,local_34,
                local_30,1);
  if (9 < sVar1) {
    if (sVar6 == 0) {
      sVar6 = 10;
    }
    iVar5 = (int)(short)(sVar6 * 0x1e + 0x75);
    iVar4 = (int)(short)(sVar6 * 0x1e + 0x57);
    _SetRect(&local_24,0x9b,iVar4,0xb3,iVar5);
    _SetRect(&local_2c,0x281,0x220,0x291,0x236);
    _SetRect(&local_34,0xb4,iVar4,0xcc,iVar5);
    _DrawToGWorld(PTR__g_00038024,puVar2,PTR__g_00038024,local_24,local_20,local_2c,local_28,
                  local_34,local_30,1);
  }
  if (99 < sVar1) {
    sVar3 = ((short)((sVar1 / 10) / 10) % 10) * 0x1e;
    iVar5 = (int)(short)(sVar3 + 0x75);
    iVar4 = (int)(short)(sVar3 + 0x57);
    _SetRect(&local_24,0x9b,iVar4,0xb3,iVar5);
    _SetRect(&local_2c,0x271,0x220,0x281,0x236);
    _SetRect(&local_34,0xb4,iVar4,0xcc,iVar5);
    _DrawToGWorld(PTR__g_00038024,puVar2,PTR__g_00038024,local_24,local_20,local_2c,local_28,
                  local_34,local_30,1);
  }
  _SetRect(&local_24,0x278,0x21e,0x2a8,0x235);
  _SetRect(&local_2c,0x278,0x21e,0x2a8,0x235);
  _DrawToWindow(puVar2,local_24,local_20,local_2c,local_28,param_1);
  return;
}


// ==== _RedrawNoMorePairs @ 00010854 ====

void _RedrawNoMorePairs(void)

{
  undefined *puVar1;
  undefined4 uVar2;
  undefined4 local_24;
  undefined4 local_20;
  undefined4 local_1c;
  undefined4 local_18;
  undefined4 local_14;
  undefined4 local_10;
  
  puVar1 = PTR__g_00038024;
  if (*(int *)(PTR__g_00038024 + 0xb8) < 0x10) {
    _StopSound(100,0x80);
  }
  _SetRect(&local_14,0,0,0xd0,0x1e0);
  _SetRect(&local_1c,0x128,0x1a,0x1f8,0x1fa);
  _SetRect(&local_24,0xd0,0,0x1a0,0x1e0);
  _DrawToGWorld(puVar1 + 0x24,puVar1 + 0x2c,puVar1 + 0x24,local_14,local_10,local_1c,local_18,
                local_24,local_20,1);
  puVar1[0x85] = 1;
  *(undefined4 *)(puVar1 + 0xbc) = *(undefined4 *)(puVar1 + 0xb8);
  if (*(int *)(puVar1 + 0xc0) == 0) {
    uVar2 = _TickCount();
    *(undefined4 *)(puVar1 + 0xc0) = uVar2;
  }
  return;
}


// ==== _RedrawEntireWindow @ 00010975 ====

void _RedrawEntireWindow(void)

{
  undefined4 local_1c;
  undefined4 local_18;
  undefined4 local_14;
  undefined4 local_10;
  
  _SetRect(&local_1c,0,0,800,600);
  _SetRect(&local_14,0,0,800,600);
  _DrawToWindow(PTR__g_00038024 + 0x2c,local_1c,local_18,local_14,local_10,1);
  return;
}


// ==== _RedrawCustomGameScreen @ 00010a07 ====

void _RedrawCustomGameScreen(char param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  _SetRect(&local_24,0,0,800,600);
  _SetRect(&local_34,0,0,800,600);
  puVar2 = PTR__g_00038024;
  puVar1 = PTR__g_00038024 + 0x2c;
  _DrawToGWorld(PTR__g_00038024 + 0x14,puVar1,PTR__g_00038024 + 0x14,local_24,local_20,local_34,
                local_30,local_2c,local_28,0xfffffff7);
  if (param_1 != '\0') {
    _DrawGameTiles();
  }
  _SetRect(&local_24,0,0,0x312,0x44);
  _SetRect(&local_34,7,0x214,0x319,600);
  _SetRect(&local_2c,(int)local_20._2_2_,(int)(short)local_24,(int)(short)(local_20._2_2_ * 2),
           (int)(short)local_20);
  _DrawToGWorld(puVar2 + 0x1c,puVar1,puVar2 + 0x1c,local_24,local_20,local_34,local_30,local_2c,
                local_28,1);
  _SetRect(&local_24,0xcd,0x19b,0xe6,0x1b4);
  _SetRect(&local_34,0x18,0x22f,0x31,0x248);
  _SetRect(&local_2c,0x163,0x19b,0x17c,0x1b4);
  _DrawToGWorld(puVar2,puVar1,puVar2,local_24,local_20,local_34,local_30,local_2c,local_28,1);
  _SetRect(&local_24,0xe6,0x19b,0xff,0x1b4);
  _SetRect(&local_34,0x3e,0x22f,0x57,0x248);
  _SetRect(&local_2c,0x163,0x19b,0x17c,0x1b4);
  _DrawToGWorld(puVar2,puVar1,puVar2,local_24,local_20,local_34,local_30,local_2c,local_28,1);
  if ((puVar2[0x67] & 1) == 0) {
    uVar4 = 0x118;
    uVar3 = 0xff;
  }
  else {
    uVar4 = 0x163;
    uVar3 = 0x14a;
  }
  _SetRect(&local_24,uVar3,0x19b,uVar4,0x1b4);
  _SetRect(&local_34,100,0x22f,0x7d,0x248);
  _SetRect(&local_2c,0x163,0x19b,0x17c,0x1b4);
  puVar2 = PTR__g_00038024;
  puVar1 = PTR__g_00038024 + 0x2c;
  _DrawToGWorld(PTR__g_00038024,puVar1,PTR__g_00038024,local_24,local_20,local_34,local_30,local_2c,
                local_28,1);
  uVar3 = _TickCount();
  _RedrawCustomTimeBar(uVar3,0);
  if (*(short *)(PTR__p_00038028 + 0x20c) == 3) {
    uVar3 = _TickCount();
    *(undefined4 *)(puVar2 + 0xa8) = uVar3;
  }
  if (300 < *(int *)(puVar2 + 0xb8)) {
    *(int *)(puVar2 + 0xac) = *(int *)(puVar2 + 0xb8) + *(int *)(puVar2 + 0xac) + -300;
  }
  _RedrawCustomOpenPairs(0);
  _RedrawCustomTimeAccumulated(0);
  if (puVar2[0x67] != '\0') {
    _SetRect(&local_24,0,0,0xd0,0x1e0);
    _SetRect(&local_34,0x128,0x1a,0x1f8,0x1fa);
    _SetRect(&local_2c,0xd0,0,0x1a0,0x1e0);
    _DrawToGWorld(puVar2 + 0x10,puVar1,puVar2 + 0x10,local_24,local_20,local_34,local_30,local_2c,
                  local_28,1);
  }
  if ((*(short *)(puVar2 + 0x60) == 0) && (0 < *(short *)(puVar2 + 0x62))) {
    _RedrawNoMorePairs();
  }
  _RedrawEntireWindow();
  return;
}


// ==== _AnimationMapScreenToCustom @ 00010f5f ====

void _AnimationMapScreenToCustom(void)

{
  undefined4 uVar1;
  int iVar2;
  int iVar3;
  undefined *puVar4;
  undefined4 uVar5;
  undefined4 *puVar6;
  undefined *puVar7;
  int iVar8;
  short sVar9;
  float fVar10;
  uint local_34;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  puVar4 = PTR__g_00038024;
  for (puVar6 = *(undefined4 **)(PTR__g_00038024 + 0x58); puVar6 != (undefined4 *)0x0;
      puVar6 = (undefined4 *)puVar6[0x42]) {
    if (*(short *)(puVar6 + 1) == *(short *)(puVar4 + 0x5c)) {
      _StopMovie(*puVar6);
      *(undefined2 *)(puVar4 + 0x5c) = *(undefined2 *)(puVar4 + 0x5e);
    }
  }
  _SetRect(&local_24,0,0,800,600);
  _SetRect(&local_2c,0,0,800,600);
  puVar4 = PTR__g_00038024;
  _DisposeGWorld(*(undefined4 *)(PTR__g_00038024 + 0x14));
  uVar1 = _objc_msgSend(PTR_s_NSString_0003626c,PTR_s_stringWithFormat__00036114,&cf_background_d,
                        (int)*(short *)(puVar4 + 0x8e));
  _CreateGWorld(uVar1,puVar4 + 0x14,local_24,local_20);
  if (1 < *(short *)(PTR__p_00038028 + 0x20e)) {
    for (puVar6 = *(undefined4 **)(puVar4 + 0x58); puVar6 != (undefined4 *)0x0;
        puVar6 = (undefined4 *)puVar6[0x42]) {
      if (*(short *)(puVar6 + 1) == *(short *)(puVar4 + 0x5c)) {
        _SetMovieVolume(*puVar6,0x80);
        _GoToBeginningOfMovie(*puVar6);
        _StartMovie(*puVar6);
      }
    }
  }
  _PlaySound(0x32,0x100);
  iVar2 = _TickCount();
  do {
    iVar3 = _TickCount();
    if ((uint)(iVar3 - iVar2) < 0x3d) {
      iVar3 = _TickCount();
      local_34 = iVar3 - iVar2;
      fVar10 = (float)(local_34 >> 0x10) * FLOAT_00033b30 + (float)(local_34 & 0xffff);
    }
    else {
      local_34 = 0x3c;
      fVar10 = FLOAT_00033b2c;
    }
    sVar9 = (short)(int)((fVar10 / FLOAT_00033b2c) * FLOAT_00033b38);
    iVar3 = (int)(short)(400 - sVar9);
    iVar8 = (int)(short)(sVar9 + 400);
    _SetRect(&local_24,(int)sVar9,0,400,600);
    _SetRect(&local_2c,0,0,iVar3,600);
    puVar4 = PTR__g_00038024 + 0x2c;
    _DrawToWindow(puVar4,local_24,local_20,local_2c,local_28,0);
    _SetRect(&local_24,iVar3,0,iVar8,600);
    _SetRect(&local_2c,iVar3,0,iVar8,600);
    puVar7 = PTR__g_00038024 + 0x14;
    _DrawToWindow(puVar7,local_24,local_20,local_2c,local_28,0);
    _SetRect(&local_24,400,0,(int)(short)(800 - sVar9),600);
    _SetRect(&local_2c,iVar8,0,800,600);
    _DrawToWindow(puVar4,local_24,local_20,local_2c,local_28,1);
  } while (local_34 < 0x3c);
  _DrawToGWorld(puVar7,puVar4,puVar7,local_24,local_20,local_2c,local_28,puVar7,iVar8,0xfffffff7);
  puVar4 = PTR__g_00038024;
  PTR__g_00038024[0x66] = 1;
  puVar4[0x67] = 0;
  puVar4[0x84] = 0;
  puVar4[0x85] = 0;
  puVar4[0x86] = 0;
  puVar4[0x87] = 0;
  *(undefined4 *)(puVar4 + 0x88) = 2;
  uVar1 = _TickCount();
  puVar4 = PTR__g_00038024;
  *(undefined4 *)(PTR__g_00038024 + 0xac) = 0;
  *(undefined4 *)(puVar4 + 0xb0) = 0;
  *(undefined4 *)(puVar4 + 0xa8) = uVar1;
  *(undefined4 *)(puVar4 + 0xb4) = 0;
  *(undefined4 *)(puVar4 + 0xb8) = 0x96;
  *(undefined4 *)(puVar4 + 0xc0) = 0;
  _RedrawCustomGameScreen(0);
  uVar1 = _TickCount();
  *(undefined4 *)(PTR__g_00038024 + 0x4c) = uVar1;
  _EnableMenuCommand(0,4);
  _EnableMenuCommand(0,6);
  _EnableMenuCommand(0,7);
  _EnableMenuCommand(0,2);
  _DisableMenuCommand(0,10);
  _DisableMenuCommand(0,0xe);
  _DisableMenuCommand(0,0xf);
  _DisableMenuCommand(0,0x12);
  uVar1 = _GetMenuHandle(1);
  uVar5 = _CFStringCreateMutable(*(undefined4 *)PTR_00038034,0);
  _CFStringAppendCString(uVar5,"Give Up",0x600);
  _SetMenuItemTextWithCFString(uVar1,1,uVar5);
  _CFRelease(uVar5);
  return;
}


// ==== _DrawBufferTiles @ 00011495 ====

void _DrawBufferTiles(short *param_1,int param_2)

{
  double dVar1;
  double dVar2;
  int iVar3;
  undefined *puVar4;
  undefined *puVar5;
  int iVar6;
  short sVar7;
  short sVar8;
  int iVar9;
  int iVar10;
  short *psVar11;
  short local_48;
  short local_46;
  int local_44;
  int local_40;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  sVar8 = (*param_1 * 5 - *(short *)(PTR__g_00038024 + 0x94)) +
          (short)(int)(*(double *)(param_1 + 8) * DOUBLE_00033fa8 * DOUBLE_00033fa0);
  sVar7 = (short)(int)(*(double *)(param_1 + 4) * DOUBLE_00033f98 * DOUBLE_00033fa0) -
          (*param_1 * 10 - *(short *)(PTR__g_00038024 + 0x98));
  iVar3 = (int)(short)(sVar8 + 0x35);
  iVar6 = (int)(short)(sVar8 + -0x35);
  iVar10 = (int)(short)(sVar7 + 0x45);
  iVar9 = (int)(short)(sVar7 + -0x45);
  _SetRect(&local_24,iVar6,iVar9,iVar3,iVar10);
  _SetRect(&local_2c,iVar6,iVar9,iVar3,iVar10);
  puVar4 = PTR__g_00038024 + 0x14;
  puVar5 = PTR__g_00038024 + 0x3c;
  _DrawToGWorld(puVar4,puVar5,puVar4,local_24,local_20,local_2c,local_28,local_34,local_30,
                0xfffffff7);
  if (param_2 != 0) {
    psVar11 = *(short **)(PTR__g_00038024 + 0x1ec);
    sVar8 = (*psVar11 * 5 - *(short *)(PTR__g_00038024 + 0x94)) +
            (short)(int)(DOUBLE_00033fa8 * *(double *)(psVar11 + 8) * DOUBLE_00033fa0);
    sVar7 = (short)(int)(DOUBLE_00033f98 * *(double *)(psVar11 + 4) * DOUBLE_00033fa0) -
            (*psVar11 * 10 - *(short *)(PTR__g_00038024 + 0x98));
    iVar3 = (int)(short)(sVar8 + 0x35);
    iVar6 = (int)(short)(sVar8 + -0x35);
    iVar10 = (int)(short)(sVar7 + 0x45);
    iVar9 = (int)(short)(sVar7 + -0x45);
    _SetRect(&local_24,iVar6,iVar9,iVar3,iVar10);
    _SetRect(&local_2c,iVar6,iVar9,iVar3,iVar10);
    _DrawToGWorld(puVar4,puVar5,puVar4,local_24,local_20,local_2c,local_28,local_34,local_30,
                  0xfffffff7);
  }
  local_40 = 0;
  do {
    local_44 = 0;
    do {
      local_48 = 0x20;
      local_46 = (short)local_44;
      do {
        if (local_46 < 0) break;
        for (psVar11 = *(short **)PTR__gCGFirstPtr_00034044; psVar11 != (short *)0x0;
            psVar11 = *(short **)(psVar11 + 0x10)) {
          dVar1 = *(double *)(psVar11 + 4);
          dVar2 = *(double *)(psVar11 + 8);
          sVar8 = *psVar11;
          if ((char)psVar11[0xe] != '\x01' &&
              (sVar8 == (short)local_40 &&
              ((double)(int)local_46 == dVar1 && (double)(int)local_48 == dVar2))) {
            if ((((dVar1 < *(double *)(param_1 + 4) - DOUBLE_00033fe0) ||
                 (*(double *)(param_1 + 4) + DOUBLE_00033fe0 < dVar1)) ||
                (dVar2 < *(double *)(param_1 + 8) - DOUBLE_00033fe0)) ||
               (*(double *)(param_1 + 8) + DOUBLE_00033fe0 < dVar2)) {
              if (param_2 != 0) {
                if (((*(double *)(param_2 + 8) - DOUBLE_00033fe0 <= dVar1) &&
                    (dVar1 <= *(double *)(param_2 + 8) + DOUBLE_00033fe0)) &&
                   ((*(double *)(param_2 + 0x10) - DOUBLE_00033fe0 <= dVar2 &&
                    (dVar2 <= *(double *)(param_2 + 0x10) + DOUBLE_00033fe0)))) goto LAB_000117d7;
              }
            }
            else {
LAB_000117d7:
              sVar7 = (sVar8 * 5 - *(short *)(PTR__g_00038024 + 0x94)) +
                      (short)(int)(dVar2 * DOUBLE_00033fa8 * DOUBLE_00033fa0);
              sVar8 = (short)(int)(dVar1 * DOUBLE_00033f98 * DOUBLE_00033fa0) -
                      (sVar8 * 10 - *(short *)(PTR__g_00038024 + 0x98));
              _SetRect(&local_24,0,(int)(short)(psVar11[1] * 0x32 + -10000),0x26,
                       (int)(short)(psVar11[1] * 0x32 + -0x26de));
              _SetRect(&local_2c,8,5,0x2e,0x36);
              puVar4 = PTR__g_00038024 + 4;
              _DrawToGWorld(PTR__g_00038024 + 0xc,puVar4,PTR__g_00038024 + 0xc,local_24,local_20,
                            local_2c,local_28,local_34,local_30,0xfffffff7);
              _SetRect(&local_24,0,0,0x35,0x45);
              iVar3 = (int)(short)(sVar8 + 0x45);
              iVar10 = (int)sVar8;
              iVar6 = (int)(short)(sVar7 + 0x35);
              iVar9 = (int)sVar7;
              _SetRect(&local_2c,iVar9,iVar10,iVar6,iVar3);
              _SetRect(&local_34,0,0x114,0x35,0x159);
              if (*(char *)((int)psVar11 + 0x1d) != '\0') {
                _SetRect(&local_34,0,(int)(short)(psVar11[2] * 0x45 + 0x114),0x35,
                         (int)(short)(psVar11[2] * 0x45 + 0x159));
              }
              puVar5 = PTR__g_00038024 + 0x3c;
              _DrawToGWorld(puVar4,puVar5,puVar4,local_24,local_20,local_2c,local_28,local_34,
                            local_30,1);
              if (*(short *)(PTR__g_00038024 + 0x60) == 0) {
                _SetRect(&local_24,0,0xcf,0x35,0x114);
                _SetRect(&local_2c,iVar9,iVar10,iVar6,iVar3);
                _SetRect(&local_34,0,0x40b,0x35,0x450);
              }
              else if (*(char *)((int)psVar11 + 0x1b) == '\0') {
                if ((char)psVar11[0xd] == '\0') goto LAB_00011c50;
                _SetRect(&local_24,0,0x8a,0x35,0xcf);
                _SetRect(&local_2c,iVar9,iVar10,iVar6,iVar3);
                _SetRect(&local_34,0,0x40b,0x35,0x450);
              }
              else {
                _SetRect(&local_24,0,0x45,0x35,0x8a);
                _SetRect(&local_2c,iVar9,iVar10,iVar6,iVar3);
                _SetRect(&local_34,0,0x40b,0x35,0x450);
              }
              _DrawToGWorld(puVar4,puVar5,puVar4,local_24,local_20,local_2c,local_28,local_34,
                            local_30,1);
            }
          }
LAB_00011c50:
        }
        local_48 = local_48 + -1;
        local_46 = local_46 + -1;
      } while (local_48 != -1);
      local_44 = local_44 + 1;
    } while (local_44 != 0x32);
    local_40 = local_40 + 1;
    if (local_40 == 7) {
      return;
    }
  } while( true );
}


// ==== _RedrawTile @ 00011c93 ====

void _RedrawTile(short *param_1)

{
  short *psVar1;
  short sVar2;
  int iVar3;
  undefined *puVar4;
  short sVar5;
  int iVar6;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  _DrawBufferTiles(param_1,*(undefined4 *)(PTR__g_00038024 + 0x1ec));
  sVar5 = (short)(int)(*(double *)(param_1 + 4) * DOUBLE_00033f98 * DOUBLE_00033fa0) +
          *param_1 * -10 + *(short *)(PTR__g_00038024 + 0x98);
  sVar2 = (*param_1 * 5 - *(short *)(PTR__g_00038024 + 0x94)) +
          (short)(int)(*(double *)(param_1 + 8) * DOUBLE_00033fa8 * DOUBLE_00033fa0);
  iVar3 = (int)(short)(sVar5 + 0x43);
  iVar6 = (int)(short)(sVar5 + 1);
  _SetRect(&local_2c,(int)sVar2,iVar6,(int)(short)(sVar2 + 0x33),iVar3);
  _SetRect(&local_24,(int)sVar2,iVar6,(int)(short)(sVar2 + 0x33),iVar3);
  puVar4 = PTR__g_00038024 + 0x3c;
  _DrawToWindow(puVar4,local_2c,local_28,local_24,local_20,1);
  psVar1 = *(short **)(PTR__g_00038024 + 0x1ec);
  if (psVar1 != (short *)0x0) {
    sVar2 = (short)(int)(DOUBLE_00033fa8 * *(double *)(psVar1 + 8) * DOUBLE_00033fa0) + *psVar1 * 5;
    sVar5 = (short)(int)(DOUBLE_00033f98 * *(double *)(psVar1 + 4) * DOUBLE_00033fa0) +
            *psVar1 * -10;
    iVar3 = (int)(short)(sVar5 + 0x43);
    iVar6 = (int)(short)(sVar5 + 1);
    _SetRect(&local_2c,(int)sVar2,iVar6,(int)(short)(sVar2 + 0x33),iVar3);
    _SetRect(&local_24,(int)sVar2,iVar6,(int)(short)(sVar2 + 0x33),iVar3);
    _DrawToWindow(puVar4,local_2c,local_28,local_24,local_20,1);
  }
  return;
}


// ==== _DrawFadeBufferTiles @ 00011e6d ====

void _DrawFadeBufferTiles(short param_1,short param_2,short param_3,short param_4)

{
  short sVar1;
  undefined *puVar2;
  short sVar3;
  undefined *puVar4;
  short *psVar5;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  _SetRect(&local_24,(int)(short)(param_1 + -0x35),(int)(short)(param_2 + -0x45),
           (int)(short)(param_1 + 0x35),(int)(short)(param_2 + 0x45));
  _SetRect(&local_2c,(int)(short)(param_1 + -0x35),(int)(short)(param_2 + -0x45),
           (int)(short)(param_1 + 0x35),(int)(short)(param_2 + 0x45));
  puVar4 = PTR__g_00038024 + 0x14;
  puVar2 = PTR__g_00038024 + 0x3c;
  _DrawToGWorld(puVar4,puVar2,puVar4,local_24,local_20,local_2c,local_28,local_34,local_30,
                0xfffffff7);
  _SetRect(&local_24,(int)(short)(param_3 + -0x35),(int)(short)(param_4 + -0x45),
           (int)(short)(param_3 + 0x35),(int)(short)(param_4 + 0x45));
  _SetRect(&local_2c,(int)(short)(param_3 + -0x35),(int)(short)(param_4 + -0x45),
           (int)(short)(param_3 + 0x35),(int)(short)(param_4 + 0x45));
  _DrawToGWorld(puVar4,puVar2,puVar4,local_24,local_20,local_2c,local_28,local_34,local_30,
                0xfffffff7);
  puVar2 = PTR__g_00038024;
  for (psVar5 = *(short **)PTR__gSTFirstPtr_0003404c; psVar5 != (short *)0x0;
      psVar5 = *(short **)(psVar5 + 0x10)) {
    sVar1 = (*psVar5 * 5 - *(short *)(puVar2 + 0x94)) +
            (short)(int)(DOUBLE_00033fa8 * *(double *)(psVar5 + 8) * DOUBLE_00033fa0);
    sVar3 = (short)(int)(DOUBLE_00033f98 * *(double *)(psVar5 + 4) * DOUBLE_00033fa0) -
            (*psVar5 * 10 - *(short *)(puVar2 + 0x98));
    _SetRect(&local_24,0,(int)(short)(psVar5[1] * 0x32 + -10000),0x26,
             (int)(short)(psVar5[1] * 0x32 + -0x26de));
    _SetRect(&local_2c,8,5,0x2e,0x36);
    puVar4 = puVar2 + 4;
    _DrawToGWorld(puVar2 + 0xc,puVar4,puVar2 + 0xc,local_24,local_20,local_2c,local_28,local_34,
                  local_30,0xfffffff7);
    _SetRect(&local_24,0,0,0x35,0x45);
    _SetRect(&local_2c,(int)sVar1,(int)sVar3,(int)(short)(sVar1 + 0x35),(int)(short)(sVar3 + 0x45));
    _SetRect(&local_34,0,0x114,0x35,0x159);
    if (*(char *)((int)psVar5 + 0x1d) != '\0') {
      _SetRect(&local_34,0,(int)(short)(psVar5[2] * 0x45 + 0x114),0x35,
               (int)(short)(psVar5[2] * 0x45 + 0x159));
      psVar5[2] = psVar5[2] + 1;
    }
    _DrawToGWorld(puVar4,puVar2 + 0x3c,puVar4,local_24,local_20,local_2c,local_28,local_34,local_30,
                  1);
    if ((char)psVar5[0xd] != '\0') {
      _SetRect(&local_24,0,0x8a,0x35,0xcf);
      _SetRect(&local_2c,(int)sVar1,(int)sVar3,(int)(short)(sVar1 + 0x35),(int)(short)(sVar3 + 0x45)
              );
      _SetRect(&local_34,0,0x40b,0x35,0x450);
      _DrawToGWorld(puVar4,puVar2 + 0x3c,puVar4,local_24,local_20,local_2c,local_28,local_34,
                    local_30,1);
    }
  }
  return;
}


// ==== _SetVisibleTiles @ 00012328 ====

void _SetVisibleTiles(void)

{
  double dVar1;
  double dVar2;
  double dVar3;
  undefined *puVar4;
  short *psVar5;
  short *psVar6;
  double dVar7;
  double dVar8;
  
  puVar4 = PTR__gCGFirstPtr_00034044;
  dVar3 = DOUBLE_00033fb0;
  psVar6 = *(short **)PTR__gCGFirstPtr_00034044;
  do {
    if (psVar6 == (short *)0x0) {
      return;
    }
    *(undefined1 *)((int)psVar6 + 0x19) = 1;
    for (psVar5 = *(short **)puVar4; psVar5 != (short *)0x0; psVar5 = *(short **)(psVar5 + 0x10)) {
      if ((char)psVar5[0xe] == '\0' && *psVar6 + 1 == (int)*psVar5) {
        dVar1 = *(double *)(psVar6 + 4);
        dVar2 = *(double *)(psVar5 + 4);
        if ((dVar1 == dVar2) || (dVar2 == dVar1 + dVar3)) {
LAB_0001239e:
          dVar8 = *(double *)(psVar6 + 8);
          dVar7 = *(double *)(psVar5 + 8);
          if ((dVar8 == dVar7) || (dVar7 == dVar8 + dVar3)) {
LAB_000123d4:
            *(undefined1 *)((int)psVar6 + 0x19) = 0;
            goto LAB_000123e4;
          }
          if ((dVar7 == dVar8 - dVar3) && (!NAN(dVar7) && !NAN(dVar8 - dVar3))) goto LAB_000123d4;
LAB_00012400:
          if ((dVar7 != dVar8 - dVar3) || (NAN(dVar7) || NAN(dVar8 - dVar3))) goto LAB_00012444;
        }
        else {
          if ((dVar2 == dVar1 - dVar3) && (!NAN(dVar2) && !NAN(dVar1 - dVar3))) goto LAB_0001239e;
          dVar8 = *(double *)(psVar6 + 8);
          dVar7 = *(double *)(psVar5 + 8);
LAB_000123e4:
          if ((dVar7 != dVar8) && (dVar7 != dVar8 + dVar3)) goto LAB_00012400;
        }
        if ((dVar1 != dVar2) && (dVar2 != dVar1 + DOUBLE_00033fb0)) {
          if ((dVar2 != dVar1 - DOUBLE_00033fb0) || (NAN(dVar2) || NAN(dVar1 - DOUBLE_00033fb0)))
          goto LAB_00012444;
        }
        *(undefined1 *)((int)psVar6 + 0x19) = 0;
      }
LAB_00012444:
    }
    psVar6 = *(short **)(psVar6 + 0x10);
  } while( true );
}


// ==== _SetOpenTiles @ 0001245e ====

void _SetOpenTiles(void)

{
  double dVar1;
  double dVar2;
  bool bVar3;
  bool bVar4;
  undefined *puVar5;
  short *psVar6;
  short *psVar7;
  double dVar8;
  
  puVar5 = PTR__gCGFirstPtr_00034044;
  psVar6 = *(short **)PTR__gCGFirstPtr_00034044;
  do {
    if (psVar6 == (short *)0x0) {
      return;
    }
    *(undefined1 *)(psVar6 + 0xc) = 0;
    if (*(char *)((int)psVar6 + 0x19) == '\x01') {
      bVar4 = false;
      bVar3 = false;
      for (psVar7 = *(short **)puVar5; psVar7 != (short *)0x0; psVar7 = *(short **)(psVar7 + 0x10))
      {
        if (*psVar6 == *psVar7) {
          dVar1 = *(double *)(psVar7 + 8);
          dVar8 = *(double *)(psVar6 + 8) - DOUBLE_00033fe8;
          if ((dVar8 == dVar1) && (!NAN(dVar8) && !NAN(dVar1))) {
            dVar8 = *(double *)(psVar6 + 4);
            dVar2 = *(double *)(psVar7 + 4);
            if ((dVar8 != dVar2) && (dVar2 != dVar8 + DOUBLE_00033fb0)) {
              if ((dVar2 != dVar8 - DOUBLE_00033fb0) || (NAN(dVar2) || NAN(dVar8 - DOUBLE_00033fb0))
                 ) goto LAB_00012502;
            }
            if ((char)psVar7[0xe] == '\0') {
              bVar4 = true;
            }
          }
LAB_00012502:
          dVar8 = DOUBLE_00033fe8 + *(double *)(psVar6 + 8);
          if ((dVar1 == dVar8) && (!NAN(dVar1) && !NAN(dVar8))) {
            dVar1 = *(double *)(psVar6 + 4);
            dVar8 = *(double *)(psVar7 + 4);
            if ((dVar1 != dVar8) && (dVar8 != dVar1 + DOUBLE_00033fb0)) {
              if ((dVar8 != dVar1 - DOUBLE_00033fb0) || (NAN(dVar8) || NAN(dVar1 - DOUBLE_00033fb0))
                 ) goto LAB_00012558;
            }
            if ((char)psVar7[0xe] == '\0') {
              bVar3 = true;
            }
          }
        }
LAB_00012558:
      }
      if (!bVar3) {
        *(undefined1 *)(psVar6 + 0xc) = 1;
      }
      if (!bVar4) {
        *(undefined1 *)(psVar6 + 0xc) = 1;
      }
    }
    psVar6 = *(short **)(psVar6 + 0x10);
  } while( true );
}


// ==== _ShowNextCGHint @ 00012622 ====

void _ShowNextCGHint(void)

{
  short sVar1;
  int iVar2;
  int iVar3;
  
  iVar3 = 0;
  for (iVar2 = *(int *)PTR__gCGFirstPtr_00034044; iVar2 != 0; iVar2 = *(int *)(iVar2 + 0x20)) {
    if (*(char *)(iVar2 + 0x1a) != '\0') {
      *(undefined1 *)(iVar2 + 0x1a) = 0;
      _RedrawTile(iVar2);
      if (iVar3 == 0) {
        iVar3 = iVar2;
      }
    }
  }
  sVar1 = *(short *)(PTR__p_00038028 + 0x20c);
  if (sVar1 == 1) {
    iVar2 = *(int *)(PTR__g_00038024 + 0xb8);
    if (iVar2 < 0) {
      iVar2 = iVar2 + 3;
    }
    iVar2 = iVar2 >> 2;
  }
  else if (sVar1 == 2) {
    iVar2 = *(int *)(PTR__g_00038024 + 0xb8);
    if (iVar2 < 0) {
      iVar2 = iVar2 + 7;
    }
    iVar2 = iVar2 >> 3;
  }
  else {
    if (sVar1 != 0) goto LAB_000126ba;
    iVar2 = *(int *)(PTR__g_00038024 + 0xb8) / 2;
  }
  *(int *)(PTR__g_00038024 + 0xac) = *(int *)(PTR__g_00038024 + 0xac) + iVar2;
LAB_000126ba:
  if (iVar3 == 0) {
    iVar2 = *(int *)PTR__gCGFirstPtr_00034044;
  }
  else {
    iVar2 = *(int *)(iVar3 + 0x20);
  }
  do {
    if (iVar2 == 0) {
      return;
    }
    if ((*(char *)(iVar2 + 0x18) != '\0') && (*(char *)(iVar2 + 0x1c) == '\0')) {
      for (iVar3 = *(int *)PTR__gCGFirstPtr_00034044; iVar3 != 0; iVar3 = *(int *)(iVar3 + 0x20)) {
        if (((iVar2 != iVar3 & *(byte *)(iVar3 + 0x18)) != 0) && (*(char *)(iVar3 + 0x1c) == '\0'))
        {
          sVar1 = *(short *)(iVar3 + 2);
          if (sVar1 == *(short *)(iVar2 + 2)) {
            *(undefined1 *)(iVar2 + 0x1a) = 1;
            *(undefined1 *)(iVar3 + 0x1a) = 1;
          }
          if (((ushort)(*(short *)(iVar2 + 2) - 0xcdU) < 8) && ((ushort)(sVar1 - 0xcdU) < 8)) {
            *(undefined1 *)(iVar2 + 0x1a) = 1;
            *(undefined1 *)(iVar3 + 0x1a) = 1;
          }
          if (*(char *)(iVar3 + 0x1a) == '\x01' && *(char *)(iVar2 + 0x1a) == '\x01') {
            _RedrawCustomGameScreen(1);
            return;
          }
        }
      }
    }
    iVar2 = *(int *)(iVar2 + 0x20);
  } while( true );
}


// ==== _ShuffleCustomTiles @ 00012763 ====

void _ShuffleCustomTiles(char param_1)

{
  short sVar1;
  short sVar2;
  uint uVar3;
  int iVar4;
  int iVar5;
  short asStackY_1013c [32760];
  short local_13c [158];
  
  do {
    _memcpy(local_13c,&_C_97_126381,0x120);
    uVar3 = _TickCount();
    _srand(uVar3);
    iVar4 = 0;
    if (param_1 != '\0') {
      do {
        local_13c[iVar4] = 0;
        local_13c[iVar4 + 1] = 0;
        local_13c[iVar4 + 2] = 0;
        local_13c[iVar4 + 3] = 0;
        local_13c[iVar4 + 4] = 0;
        local_13c[iVar4 + 5] = 0;
        local_13c[iVar4 + 6] = 0;
        local_13c[iVar4 + 7] = 0;
        iVar4 = iVar4 + 8;
      } while (iVar4 != 0x90);
      sVar2 = 0;
      for (iVar4 = *(int *)PTR__gCGFirstPtr_00034044; iVar4 != 0; iVar4 = *(int *)(iVar4 + 0x20)) {
        local_13c[sVar2] = *(short *)(iVar4 + 2);
        sVar2 = sVar2 + 1;
      }
    }
    for (iVar4 = *(int *)PTR__gCGFirstPtr_00034044; iVar4 != 0; iVar4 = *(int *)(iVar4 + 0x20)) {
      do {
        iVar5 = _rand();
        sVar2 = (short)iVar5 + (short)(iVar5 / 0x90) * -0x90;
      } while (local_13c[sVar2] == 0);
      sVar1 = local_13c[sVar2];
      *(undefined1 *)(iVar4 + 0x1b) = 0;
      *(undefined1 *)(iVar4 + 0x1a) = 0;
      *(short *)(iVar4 + 2) = sVar1;
      local_13c[sVar2] = 0;
    }
    _SetVisibleTiles();
    _SetOpenTiles();
    sVar2 = _CountOpenPairs();
    *(short *)(PTR__g_00038024 + 0x60) = sVar2;
  } while (sVar2 == 0);
  return;
}


// ==== _UndoLastCGMove @ 000128cb ====

void _UndoLastCGMove(void)

{
  short sVar1;
  short *psVar2;
  int iVar3;
  short sVar4;
  short sVar5;
  short sVar6;
  int iVar7;
  undefined *puVar8;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  puVar8 = PTR__g_00038024;
  sVar5 = 0;
  for (psVar2 = *(short **)PTR__gCGFirstPtr_00034044; psVar2 != (short *)0x0;
      psVar2 = *(short **)(psVar2 + 0x10)) {
    if ((char)psVar2[0xe] == '\x01') {
      sVar5 = sVar5 + 1;
      *(undefined1 *)(psVar2 + 0xe) = 0;
      *(undefined1 *)((int)psVar2 + 0x1b) = 0;
      if (sVar5 == 1) {
        *(short **)(puVar8 + 0x1ec) = psVar2;
      }
      else if (sVar5 == 2) goto LAB_00012918;
    }
  }
  if (sVar5 != 0) {
LAB_00012918:
    sVar5 = (*psVar2 * 5 - *(short *)(PTR__g_00038024 + 0x94)) +
            (short)(int)(*(double *)(psVar2 + 8) * DOUBLE_00033fa8 * DOUBLE_00033fa0);
    sVar6 = (short)(int)(*(double *)(psVar2 + 4) * DOUBLE_00033f98 * DOUBLE_00033fa0) -
            (*psVar2 * 10 - *(short *)(PTR__g_00038024 + 0x98));
    psVar2 = *(short **)(PTR__g_00038024 + 0x1ec);
    sVar4 = (short)(int)(DOUBLE_00033f98 * *(double *)(psVar2 + 4) * DOUBLE_00033fa0) +
            *psVar2 * -10 + *(short *)(PTR__g_00038024 + 0x98);
    sVar1 = (*psVar2 * 5 - *(short *)(PTR__g_00038024 + 0x94)) +
            (short)(int)(DOUBLE_00033fa8 * *(double *)(psVar2 + 8) * DOUBLE_00033fa0);
    _DrawGameTiles();
    iVar3 = (int)(short)(sVar6 + 1);
    iVar7 = (int)(short)(sVar6 + 0x43);
    _SetRect(&local_24,(int)sVar5,iVar3,(int)(short)(sVar5 + 0x33),iVar7);
    _SetRect(&local_2c,(int)sVar5,iVar3,(int)(short)(sVar5 + 0x33),iVar7);
    puVar8 = PTR__g_00038024 + 0x3c;
    _DrawToWindow(puVar8,local_24,local_20,local_2c,local_28,1);
    iVar3 = (int)(short)(sVar4 + 1);
    iVar7 = (int)(short)(sVar4 + 0x43);
    _SetRect(&local_24,(int)sVar1,iVar3,(int)(short)(sVar1 + 0x33),iVar7);
    _SetRect(&local_2c,(int)sVar1,iVar3,(int)(short)(sVar1 + 0x33),iVar7);
    _DrawToWindow(puVar8,local_24,local_20,local_2c,local_28,1);
    _SetVisibleTiles();
    _SetOpenTiles();
    _RedrawCustomOpenPairs(1);
    *(undefined4 *)(PTR__g_00038024 + 0x1ec) = 0;
    sVar5 = *(short *)(PTR__p_00038028 + 0x20c);
    if (sVar5 < 2) {
      PTR__g_00038024[0x1f1] = 0;
    }
    if (sVar5 == 1) {
      *(int *)(PTR__g_00038024 + 0xac) = *(int *)(PTR__g_00038024 + 0xac) + 6;
    }
    else if (sVar5 == 2) {
      *(int *)(PTR__g_00038024 + 0xac) = *(int *)(PTR__g_00038024 + 0xac) + 0xc;
    }
    else if (sVar5 == 0) {
      *(int *)(PTR__g_00038024 + 0xac) = *(int *)(PTR__g_00038024 + 0xac) + 3;
    }
  }
  return;
}


// ==== _WriteSurroundingTiles @ 00012b6f ====

void _WriteSurroundingTiles(void)

{
  undefined2 *puVar1;
  
  puVar1 = _malloc(0x28);
  *puVar1 = 0;
  *(undefined8 *)(puVar1 + 8) = 0;
  *(undefined8 *)(puVar1 + 4) = 0;
  *(undefined1 *)(puVar1 + 0xc) = 0;
  *(undefined1 *)((int)puVar1 + 0x19) = 1;
  *(undefined1 *)(puVar1 + 0xd) = 0;
  *(undefined1 *)((int)puVar1 + 0x1b) = 0;
  *(undefined1 *)(puVar1 + 0xe) = 0;
  *(undefined1 *)((int)puVar1 + 0x1d) = 0;
  puVar1[2] = 0;
  return;
}


// ==== FUN_00012bb9 @ 00012bb9 ====

void __regparm1 FUN_00012bb9(int *param_1,int param_2)

{
  int iVar1;
  undefined *puVar2;
  
  puVar2 = PTR__gSTLastPtr_00034048;
  if (*param_1 == 0) {
    *(undefined4 *)(param_2 + 0x20) = 0;
    *(undefined4 *)(param_2 + 0x24) = 0;
    *param_1 = param_2;
    *(int *)PTR__gSTLastPtr_00034048 = param_2;
  }
  else {
    *(int *)(*(int *)PTR__gSTLastPtr_00034048 + 0x20) = param_2;
    *(int *)(*(int *)(*(int *)puVar2 + 0x20) + 0x24) = *(int *)puVar2;
    iVar1 = *(int *)(*(int *)puVar2 + 0x20);
    *(int *)puVar2 = iVar1;
    *(undefined4 *)(iVar1 + 0x20) = 0;
  }
  return;
}


// ==== FUN_00012c06 @ 00012c06 ====

void __regparm1 FUN_00012c06(int *param_1,int param_2)

{
  int iVar1;
  undefined *puVar2;
  
  puVar2 = PTR__gCGLastPtr_00034040;
  if (*param_1 == 0) {
    *(undefined4 *)(param_2 + 0x20) = 0;
    *(undefined4 *)(param_2 + 0x24) = 0;
    *param_1 = param_2;
    *(int *)PTR__gCGLastPtr_00034040 = param_2;
  }
  else {
    *(int *)(*(int *)PTR__gCGLastPtr_00034040 + 0x20) = param_2;
    *(int *)(*(int *)(*(int *)puVar2 + 0x20) + 0x24) = *(int *)puVar2;
    iVar1 = *(int *)(*(int *)puVar2 + 0x20);
    *(int *)puVar2 = iVar1;
    *(undefined4 *)(iVar1 + 0x20) = 0;
  }
  return;
}


// ==== _WriteCustomStruct @ 00012c4e ====

void _WriteCustomStruct(void)

{
  undefined8 uVar1;
  undefined *puVar2;
  undefined2 *puVar3;
  
  puVar3 = _malloc(0x28);
  puVar2 = PTR__g_00038024;
  *puVar3 = *(undefined2 *)(PTR__g_00038024 + 0x1e8);
  *(undefined8 *)(puVar3 + 8) = *(undefined8 *)(puVar2 + 0x1d8);
  uVar1 = *(undefined8 *)(puVar2 + 0x1e0);
  *(undefined1 *)(puVar3 + 0xc) = 0;
  *(undefined8 *)(puVar3 + 4) = uVar1;
  *(undefined1 *)((int)puVar3 + 0x19) = 1;
  *(undefined1 *)(puVar3 + 0xd) = 0;
  *(undefined1 *)((int)puVar3 + 0x1b) = 0;
  *(undefined1 *)(puVar3 + 0xe) = 0;
  *(undefined1 *)((int)puVar3 + 0x1d) = 0;
  puVar3[2] = 0;
  return;
}


// ==== _DeleteTile @ 00012caa ====

void _DeleteTile(void *param_1)

{
  int iVar1;
  int iVar2;
  undefined *puVar3;
  undefined *puVar4;
  
  puVar4 = PTR__gCGFirstPtr_00034044;
  puVar3 = PTR__gCGLastPtr_00034040;
  iVar1 = *(int *)((int)param_1 + 0x24);
  iVar2 = *(int *)((int)param_1 + 0x20);
  if (iVar2 != 0 || iVar1 != 0) {
    if (iVar2 != 0) {
      if (iVar1 != 0) {
        *(int *)(iVar2 + 0x24) = iVar1;
        *(int *)(*(int *)((int)param_1 + 0x24) + 0x20) = iVar2;
      }
      else {
        *(undefined4 *)(iVar2 + 0x24) = 0;
        *(int *)puVar4 = iVar2;
      }
    }
    else {
      *(undefined4 *)(iVar1 + 0x20) = 0;
      *(int *)puVar3 = iVar1;
    }
  }
  else {
    *(undefined4 *)PTR__gCGLastPtr_00034040 = 0;
    *(undefined4 *)PTR__gCGFirstPtr_00034044 = 0;
  }
  _free(param_1);
  return;
}


// ==== _DeleteDeadTile @ 00012d35 ====

void _DeleteDeadTile(void)

{
  int iVar1;
  
  for (iVar1 = *(int *)PTR__gCGFirstPtr_00034044; iVar1 != 0; iVar1 = *(int *)(iVar1 + 0x20)) {
    if (*(char *)(iVar1 + 0x1c) == '\x01') {
      _DeleteTile(iVar1);
    }
  }
  return;
}


// ==== _RandomBackground @ 00012d60 ====

int _RandomBackground(void)

{
  short sVar1;
  uint uVar2;
  int iVar3;
  
  uVar2 = _TickCount();
  _srand(uVar2);
  iVar3 = _rand();
  sVar1 = (short)iVar3 + (short)(iVar3 / 5) * -5 + 0xd;
  *(short *)(PTR__g_00038024 + 0x90) = sVar1;
  return (int)sVar1;
}


// ==== _CustomGameScreen @ 00012dbc ====

void _CustomGameScreen(int *param_1,int *param_2)

{
  short *psVar1;
  short sVar2;
  undefined *puVar3;
  undefined *puVar4;
  char cVar5;
  uint uVar6;
  int iVar7;
  undefined4 uVar8;
  undefined4 uVar9;
  undefined4 uVar10;
  undefined4 uVar11;
  undefined4 uVar12;
  undefined4 uVar13;
  int iVar14;
  undefined4 *puVar15;
  undefined8 uVar16;
  undefined4 uVar17;
  undefined1 local_20 [16];
  
  _GetMouseLocation(local_20);
  uVar6 = _TickCount();
  puVar3 = PTR__g_00038024;
  if (*param_2 + 5U < uVar6) {
    if (PTR__g_00038024[0x86] != '\0') {
      _StopSound(100,0x80);
      _FlashCGButton(5,1);
    }
    if (puVar3[0x67] == '\0') {
      if ((*(short *)(puVar3 + 0x60) != 0 & puVar3[0x84]) != 0) {
        _FlashCGButton(1,1);
        puVar3[0x84] = 0;
      }
      if (puVar3[0x85] != '\0') {
        _FlashCGButton(3,1);
      }
    }
    iVar7 = _TickCount();
    *param_2 = iVar7;
  }
  uVar6 = _TickCount();
  puVar3 = PTR__g_00038024;
  if (*param_1 + 1U < uVar6) {
    if (*(short *)(PTR__g_00038024 + 0x62) == 0) {
      for (puVar15 = *(undefined4 **)(PTR__g_00038024 + 0x58); puVar15 != (undefined4 *)0x0;
          puVar15 = (undefined4 *)puVar15[0x42]) {
        if (*(short *)(puVar15 + 1) == *(short *)(puVar3 + 0x5c)) {
          _StopMovie(*puVar15);
        }
      }
      _PlaySound(0x1e,0x100);
      puVar4 = PTR__p_00038028;
      puVar3 = PTR__g_00038024;
      if (*(short *)(PTR__g_00038024 + 0x90) < 0xc) {
        iVar7 = (int)*(short *)(PTR__g_00038024 + 0x90);
        *(short *)(PTR__p_00038028 + iVar7 * 2 + 0x218) =
             *(short *)(PTR__p_00038028 + iVar7 * 2 + 0x218) + 1;
        if (*(short *)(puVar4 + 0x20c) != 3) {
          if (*(int *)(puVar4 + iVar7 * 4 + 0x260) == 0) {
            *(undefined4 *)(puVar4 + iVar7 * 4 + 0x260) = *(undefined4 *)(puVar3 + 0xb4);
          }
          else {
            iVar14 = *(int *)(puVar3 + 0xb4);
            if (iVar14 < *(int *)(puVar4 + iVar7 * 4 + 0x260)) {
              *(int *)(puVar4 + iVar7 * 4 + 0x260) = iVar14;
            }
          }
        }
      }
      _SavePrefs(puVar4);
      puVar3 = PTR__g_00038024;
      sVar2 = *(short *)(puVar4 + 0x20c);
      PTR__g_00038024[0x68] = 1;
      if (sVar2 != 3) {
        if (*(short *)(puVar3 + 0x90) < 0xb) {
          puVar4[*(short *)(puVar3 + 0x90) + 0x201] = 1;
        }
        _SavePrefs(puVar4);
        if (0xb < *(short *)(PTR__g_00038024 + 0x90)) {
          PTR__g_00038024[0x22b] = 0;
        }
      }
    }
    puVar3 = PTR__gCGFirstPtr_00034044;
    if (PTR__g_00038024[0x68] == '\0') {
      if (PTR__g_00038024[0x67] == '\0') {
        iVar14 = _TickCount();
        puVar3 = PTR__g_00038024;
        iVar7 = (iVar14 - *(int *)(PTR__g_00038024 + 0xa8)) / 0x3c;
        *(int *)(PTR__g_00038024 + 0xb4) = iVar7;
        *(int *)(PTR__g_00038024 + 0xb8) =
             0x96 - ((iVar7 + *(int *)(puVar3 + 0xac)) - *(int *)(puVar3 + 0xb0));
        iVar7 = _TickCount();
        *param_1 = iVar7;
        _RedrawCustomTimeAccumulated(0);
        _RedrawCustomTimeBar(iVar14,1);
        PTR__g_00038024[0x84] = *(int *)(PTR__g_00038024 + 0x4c) + 0x708 < iVar14;
      }
    }
    else {
      *(undefined4 *)(PTR__g_00038024 + 0x1ec) = 0;
      for (iVar7 = *(int *)puVar3; iVar7 != 0; iVar7 = *(int *)(iVar7 + 0x20)) {
        if (*(char *)(iVar7 + 0x1b) != '\0') {
          *(undefined1 *)(iVar7 + 0x1b) = 0;
        }
        if (*(char *)(iVar7 + 0x1a) != '\0') {
          *(undefined1 *)(iVar7 + 0x1a) = 0;
        }
      }
      _DeleteAllCGTiles();
      _DeleteAllSTTiles();
      _AnimationCustomGameScreenToMap();
      psVar1 = (short *)(PTR__g_00038024 + 0x90);
      PTR__g_00038024[0x68] = 0;
      puVar3 = PTR_s_NSAlert_000362b4;
      if ((*psVar1 == 2) && (*(short *)(PTR__p_00038028 + 0x20e) % 2 != 1)) {
        uVar8 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
        uVar8 = _objc_msgSend(uVar8,PTR_s_localizedStringForKey_value_tabl_000360c4,
                              &
                              cf_Youhavecompletedthelevelsavailableinthedemo_PleaseregisterAkitoplaymorelevels_
                              ,&cf___,0);
        uVar9 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
        uVar9 = _objc_msgSend(uVar9,PTR_s_localizedStringForKey_value_tabl_000360c4,&cf_OK,&cf___,0)
        ;
        uVar10 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
        uVar10 = _objc_msgSend(uVar10,PTR_s_localizedStringForKey_value_tabl_000360c4,&cf_Register,
                               &cf___,0);
        uVar11 = _objc_msgSend(PTR_s_NSBundle_00036284,PTR_s_mainBundle_000360b8);
        uVar11 = _objc_msgSend(uVar11,PTR_s_localizedStringForKey_value_tabl_000360c4,
                               &cf_CompletedDemo,&cf___,0);
        uVar17 = 0;
        uVar12 = _objc_msgSend(puVar3,PTR_s_alertWithMessageText_defaultButt_00036154,uVar11,uVar10,
                               uVar9,0,uVar8);
        uVar13 = _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
        cVar5 = _objc_msgSend(uVar13,PTR_s_isFullscreen_00036064);
        if (cVar5 != '\0') {
          uVar13 = _objc_msgSend(uVar12,PTR_s_window_00036138,uVar11,uVar10,uVar9,uVar17,uVar8);
          _objc_msgSend(uVar13,PTR_s_scheduleSetShieldingLevel_00036158);
        }
        iVar7 = _objc_msgSend(uVar12,PTR_s_runModal_00036040,uVar11,uVar10,uVar9,uVar17,uVar8);
        if (iVar7 == 1) {
          uVar8 = _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
          _objc_msgSend(uVar8,PTR_s_showRegistration__00036168,0);
        }
        for (iVar7 = *(int *)(PTR__g_00038024 + 0x58); iVar7 != 0; iVar7 = *(int *)(iVar7 + 0x108))
        {
          uVar8 = _RT3_GetLicenseCopies();
          *(undefined4 *)(iVar7 + 0x10c) = uVar8;
        }
        for (iVar7 = *(int *)(PTR__g_00038024 + 0x54); iVar7 != 0; iVar7 = *(int *)(iVar7 + 0x108))
        {
          uVar16 = _RT3_GetLicenseCode();
          *(undefined8 *)(iVar7 + 0x10c) = uVar16;
        }
        uVar8 = _RT3_GetLicenseName();
        *(undefined4 *)(PTR__g_00038024 + 0x44) = uVar8;
      }
    }
  }
  if (*(int *)(PTR__g_00038024 + 0xb8) < 0xf) {
    _LoopSound();
  }
  _LoopMusic(0);
  return;
}


// ==== _LoadLayout @ 000132f1 ====

void _LoadLayout(void)

{
  undefined *puVar1;
  undefined *puVar2;
  int iVar3;
  
  _DeleteAllCGTiles();
  _DeleteAllSTTiles();
  puVar2 = PTR__g_00038024;
  if (*(short *)(PTR__g_00038024 + 0x90) == 0) {
    _Layout1();
  }
  if (*(short *)(puVar2 + 0x90) == 1) {
    _Layout2();
  }
  if (*(short *)(puVar2 + 0x90) == 2) {
    _Layout3();
  }
  if (*(short *)(puVar2 + 0x90) == 3) {
    _Layout4();
  }
  if (*(short *)(puVar2 + 0x90) == 4) {
    _Layout5();
  }
  if (*(short *)(puVar2 + 0x90) == 5) {
    _Layout10();
  }
  if (*(short *)(puVar2 + 0x90) == 6) {
    _Layout7();
  }
  if (*(short *)(puVar2 + 0x90) == 7) {
    _Layout11();
  }
  if (*(short *)(puVar2 + 0x90) == 8) {
    _Layout9();
  }
  if (*(short *)(puVar2 + 0x90) == 9) {
    _Layout6();
  }
  puVar2 = PTR__g_00038024;
  if (*(short *)(PTR__g_00038024 + 0x90) == 10) {
    _Layout8();
  }
  if (*(short *)(puVar2 + 0x90) == 0xb) {
    _Layout12();
  }
  puVar1 = PTR__gCGFirstPtr_00034044;
  *(undefined2 *)(puVar2 + 0x62) = 0x90;
  puVar2[0x1f1] = 0;
  for (iVar3 = *(int *)puVar1; iVar3 != 0; iVar3 = *(int *)(iVar3 + 0x20)) {
  }
  _ShuffleCustomTiles(0);
  _AnimationMapScreenToCustom();
  _DrawGameTiles();
  _RedrawEntireWindow();
  return;
}


// ==== _ReshuffleCustomTiles @ 000133ff ====

void _ReshuffleCustomTiles(void)

{
  short sVar1;
  short sVar2;
  undefined *puVar3;
  undefined *puVar4;
  int iVar5;
  undefined4 *puVar6;
  
  sVar1 = *(short *)(PTR__g_00038024 + 0x60);
  *(undefined4 *)(PTR__g_00038024 + 0x1ec) = 0;
  puVar3 = PTR__gCGFirstPtr_00034044;
  for (iVar5 = *(int *)PTR__gCGFirstPtr_00034044; iVar5 != 0; iVar5 = *(int *)(iVar5 + 0x20)) {
    if (*(char *)(iVar5 + 0x1b) != '\0') {
      *(undefined1 *)(iVar5 + 0x1b) = 0;
    }
    if (*(char *)(iVar5 + 0x1a) != '\0') {
      *(undefined1 *)(iVar5 + 0x1a) = 0;
    }
  }
  for (iVar5 = *(int *)puVar3; iVar5 != 0; iVar5 = *(int *)(iVar5 + 0x20)) {
    if (*(char *)(iVar5 + 0x1c) == '\x01') {
      _DeleteTile(iVar5);
    }
  }
  _ShuffleCustomTiles(1);
  puVar3 = PTR__g_00038024;
  PTR__g_00038024[0x85] = 0;
  _FlashCGButton(3,0);
  puVar4 = PTR__p_00038028;
  iVar5 = *(int *)(puVar3 + 0xb8);
  if (iVar5 == 0) goto LAB_000134ed;
  sVar2 = *(short *)(PTR__p_00038028 + 0x20c);
  if (sVar2 == 1) {
    iVar5 = iVar5 / 2;
  }
  else {
    if (sVar2 == 2) {
      if (iVar5 < 0) {
        iVar5 = iVar5 + 3;
      }
      *(int *)(puVar3 + 0xac) = *(int *)(puVar3 + 0xac) + (iVar5 >> 2);
      goto LAB_000134ed;
    }
    if (sVar2 != 0) goto LAB_000134ed;
    iVar5 = iVar5 * 3;
    if (iVar5 < 0) {
      iVar5 = iVar5 + 3;
    }
    iVar5 = iVar5 >> 2;
  }
  *(int *)(puVar3 + 0xac) = *(int *)(puVar3 + 0xac) + iVar5;
LAB_000134ed:
  puVar3 = PTR__g_00038024;
  if (sVar1 == 0 && 1 < *(short *)(puVar4 + 0x20e)) {
    for (puVar6 = *(undefined4 **)(PTR__g_00038024 + 0x58); puVar6 != (undefined4 *)0x0;
        puVar6 = (undefined4 *)puVar6[0x42]) {
      if (*(short *)(puVar6 + 1) == *(short *)(puVar3 + 0x5c)) {
        _SetMovieVolume(*puVar6,0x80);
        _StartMovie(*puVar6);
      }
    }
  }
  _RedrawCustomGameScreen(1);
  if (*(int *)(PTR__g_00038024 + 0xb8) < 0x10) {
    _PlaySound(100,0x80);
  }
  return;
}


// ==== _SelectCGButton @ 0001356f ====

void _SelectCGButton(undefined4 param_1)

{
  short sVar1;
  undefined *puVar2;
  int iVar3;
  int iVar4;
  undefined *puVar5;
  int iVar6;
  int iVar7;
  short sVar8;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  iVar6 = (int)(short)((uint)param_1 >> 0x10);
  _SetRect(&local_34,0x163,0x19b,0x17c,0x1b4);
  puVar2 = PTR__g_00038024;
  for (sVar8 = (-(ushort)(PTR__g_00038024[0x67] == '\0') & 0xfffe) + 5; sVar8 < 6; sVar8 = sVar8 + 1
      ) {
    iVar4 = sVar8 * 0x26;
    if (iVar6 <= iVar4 + -0x41 && iVar4 + -0x5a <= iVar6) {
      if (sVar8 != 5 && *(short *)(puVar2 + 0x60) != 0) {
        sVar1 = (short)iVar4;
        _SetRect(&local_24,(int)(short)(sVar1 + -0x6a),10,(int)(short)(sVar1 + -0x34),0x40);
        _SetRect(&local_2c,(int)(short)(sVar1 + -99),0x21e,(int)(short)(sVar1 + -0x2d),0x254);
        puVar5 = puVar2 + 0x2c;
        _DrawToGWorld(puVar2 + 0x1c,puVar5,puVar2 + 0x1c,local_24,local_20,local_2c,local_28,
                      local_34,local_30,1);
        iVar7 = (int)(short)(sVar1 + -0x41);
        iVar4 = (int)(short)(sVar1 + -0x5a);
        _SetRect(&local_24,(int)(short)(sVar8 * 0x19 + 0xcd),0x19b,(int)(short)(sVar8 * 0x19 + 0xe6)
                 ,0x1b4);
        _SetRect(&local_2c,iVar4,0x22f,iVar7,0x248);
        _DrawToGWorld(puVar2,puVar5,puVar2,local_24,local_20,local_2c,local_28,local_34,local_30,1);
        _SetRect(&local_24,iVar4,0x22f,iVar7,0x248);
        _SetRect(&local_2c,iVar4,0x22f,iVar7,0x248);
        _DrawToWindow(puVar5,local_24,local_20,local_2c,local_28,1);
      }
      if (sVar8 == 3) {
        if (*(short *)(puVar2 + 0x60) != 0 && puVar2[0x67] == '\0') {
          _ShowNextCGHint();
        }
      }
      else if (sVar8 == 4) {
        if ((*(short *)(puVar2 + 0x60) == 0) && (*(int *)(puVar2 + 0xc0) != 0)) {
          iVar4 = *(int *)(puVar2 + 0xa8);
          iVar3 = _TickCount();
          iVar7 = *(int *)(puVar2 + 0xc0);
          *(undefined4 *)(puVar2 + 0xc0) = 0;
          *(int *)(puVar2 + 0xa8) = iVar4 + (iVar3 - iVar7);
          *(undefined4 *)(puVar2 + 0xb8) = *(undefined4 *)(puVar2 + 0xbc);
        }
        _ReshuffleCustomTiles();
      }
      else if ((sVar8 == 5) && (*(short *)(puVar2 + 0x60) != 0)) {
        _PlaySound(0x4b,0x40);
        _PauseGame(puVar2[0x67] == '\0');
      }
    }
  }
  return;
}


// ==== _CalculateSurroundingTiles @ 000138a7 ====

void _CalculateSurroundingTiles(int param_1,int param_2)

{
  double dVar1;
  double dVar2;
  int iVar3;
  short *psVar4;
  double dVar5;
  undefined *puVar6;
  undefined *puVar7;
  undefined2 *puVar8;
  short *psVar9;
  short sVar10;
  short local_26;
  int local_24;
  int local_20;
  
  local_20 = 0;
  do {
    local_24 = 0;
    do {
      local_26 = 0x20;
      sVar10 = (short)local_24;
      do {
        dVar5 = DOUBLE_00033fe0;
        if (sVar10 < 0) break;
        for (psVar9 = *(short **)PTR__gCGFirstPtr_00034044; psVar9 != (short *)0x0;
            psVar9 = *(short **)(psVar9 + 0x10)) {
          dVar1 = *(double *)(psVar9 + 4);
          dVar2 = *(double *)(psVar9 + 8);
          if ((char)psVar9[0xe] != '\x01' &&
              (*psVar9 == (short)local_20 &&
              ((double)(int)sVar10 == dVar1 && (double)(int)local_26 == dVar2))) {
            if ((((dVar1 < *(double *)(param_1 + 8) - dVar5) ||
                 (*(double *)(param_1 + 8) + dVar5 < dVar1)) ||
                (dVar2 < *(double *)(param_1 + 0x10) - dVar5)) ||
               (*(double *)(param_1 + 0x10) + dVar5 < dVar2)) {
              if (param_2 != 0) {
                if (((*(double *)(param_2 + 8) - dVar5 <= dVar1) &&
                    (dVar1 <= *(double *)(param_2 + 8) + dVar5)) &&
                   ((*(double *)(param_2 + 0x10) - dVar5 <= dVar2 &&
                    (dVar2 <= *(double *)(param_2 + 0x10) + dVar5)))) goto LAB_000139e2;
              }
            }
            else {
LAB_000139e2:
              puVar8 = _malloc(0x28);
              *puVar8 = 0;
              *(undefined8 *)(puVar8 + 8) = 0;
              *(undefined8 *)(puVar8 + 4) = 0;
              *(undefined1 *)(puVar8 + 0xc) = 0;
              *(undefined1 *)((int)puVar8 + 0x19) = 1;
              *(undefined1 *)(puVar8 + 0xd) = 0;
              *(undefined1 *)((int)puVar8 + 0x1b) = 0;
              *(undefined1 *)(puVar8 + 0xe) = 0;
              *(undefined1 *)((int)puVar8 + 0x1d) = 0;
              puVar8[2] = 0;
              puVar7 = PTR__gSTFirstPtr_0003404c;
              puVar6 = PTR__gSTLastPtr_00034048;
              if (*(int *)PTR__gSTFirstPtr_0003404c == 0) {
                *(undefined4 *)(puVar8 + 0x10) = 0;
                *(undefined4 *)(puVar8 + 0x12) = 0;
                *(undefined2 **)puVar7 = puVar8;
                *(undefined2 **)puVar6 = puVar8;
              }
              else {
                *(undefined2 **)(*(int *)PTR__gSTLastPtr_00034048 + 0x20) = puVar8;
                *(int *)(*(int *)(*(int *)puVar6 + 0x20) + 0x24) = *(int *)puVar6;
                iVar3 = *(int *)(*(int *)puVar6 + 0x20);
                *(int *)puVar6 = iVar3;
                *(undefined4 *)(iVar3 + 0x20) = 0;
              }
              psVar4 = *(short **)puVar6;
              *(undefined8 *)(psVar4 + 8) = *(undefined8 *)(psVar9 + 8);
              *(undefined8 *)(psVar4 + 4) = *(undefined8 *)(psVar9 + 4);
              *psVar4 = *psVar9;
              psVar4[1] = psVar9[1];
              *(undefined1 *)((int)psVar4 + 0x1d) = *(undefined1 *)((int)psVar9 + 0x1d);
              psVar4[2] = -(ushort)(PTR__p_00038028[0x213] == '\0') & 10;
              *(char *)(psVar4 + 0xd) = (char)psVar9[0xd];
            }
          }
        }
        local_26 = local_26 + -1;
        sVar10 = sVar10 + -1;
      } while (local_26 != -1);
      local_24 = local_24 + 1;
    } while (local_24 != 0x32);
    local_20 = local_20 + 1;
    if (local_20 == 7) {
      return;
    }
  } while( true );
}


// ==== _RedrawMatchedTiles @ 00013af5 ====

void _RedrawMatchedTiles(short *param_1)

{
  short *psVar1;
  int iVar2;
  undefined *puVar3;
  short sVar4;
  short sVar5;
  undefined4 *puVar6;
  short sVar7;
  int iVar8;
  int iVar9;
  undefined *puVar10;
  short sVar11;
  int iVar12;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  puVar3 = PTR__gCGFirstPtr_00034044;
  for (iVar2 = *(int *)PTR__gCGFirstPtr_00034044; iVar2 != 0; iVar2 = *(int *)(iVar2 + 0x20)) {
    if (*(char *)(iVar2 + 0x1a) == '\x01') {
      *(undefined1 *)(iVar2 + 0x1a) = 0;
    }
  }
  if (1 < *(short *)(PTR__p_00038028 + 0x20c)) {
    PTR__g_00038024[0x1f1] = 1;
  }
  for (iVar2 = *(int *)puVar3; puVar3 = PTR__g_00038024, iVar2 != 0; iVar2 = *(int *)(iVar2 + 0x20))
  {
    if (*(char *)(iVar2 + 0x1c) == '\x01') {
      _DeleteTile(iVar2);
    }
  }
  sVar4 = (short)(int)(*(double *)(param_1 + 4) * DOUBLE_00033f98 * DOUBLE_00033fa0) +
          *param_1 * -10 + *(short *)(PTR__g_00038024 + 0x98);
  psVar1 = *(short **)(PTR__g_00038024 + 0x1ec);
  sVar7 = (*param_1 * 5 - *(short *)(PTR__g_00038024 + 0x94)) +
          (short)(int)(*(double *)(param_1 + 8) * DOUBLE_00033fa8 * DOUBLE_00033fa0);
  sVar11 = (short)(int)(DOUBLE_00033f98 * *(double *)(psVar1 + 4) * DOUBLE_00033fa0) +
           *psVar1 * -10 + *(short *)(PTR__g_00038024 + 0x98);
  sVar5 = (*psVar1 * 5 - *(short *)(PTR__g_00038024 + 0x94)) +
          (short)(int)(DOUBLE_00033fa8 * *(double *)(psVar1 + 8) * DOUBLE_00033fa0);
  iVar12 = (int)sVar7;
  iVar8 = (int)(short)(sVar7 + 0x35);
  *(undefined1 *)((int)param_1 + 0x1d) = 1;
  *(undefined1 *)(*(int *)(puVar3 + 0x1ec) + 0x1d) = 1;
  *(undefined1 *)((int)param_1 + 0x1b) = 0;
  *(undefined1 *)(*(int *)(puVar3 + 0x1ec) + 0x1b) = 0;
  _CalculateSurroundingTiles(param_1,*(undefined4 *)(puVar3 + 0x1ec));
  param_1[2] = 0;
  iVar2 = (int)sVar5;
  iVar9 = (int)(short)(sVar5 + 0x35);
  puVar3 = PTR__g_00038024 + 0x3c;
  while (param_1[2] < 0xb) {
    _DrawFadeBufferTiles(iVar12,(int)sVar4,iVar2,(int)sVar11);
    _SetRect(&local_2c,iVar12,(int)(short)(sVar4 + 1),iVar8,(int)(short)(sVar4 + 0x45));
    _SetRect(&local_24,iVar12,(int)(short)(sVar4 + 1),iVar8,(int)(short)(sVar4 + 0x45));
    _DrawToWindow(puVar3,local_2c,local_28,local_24,local_20,1);
    _SetRect(&local_2c,iVar2,(int)(short)(sVar11 + 1),iVar9,(int)(short)(sVar11 + 0x45));
    _SetRect(&local_24,iVar2,(int)(short)(sVar11 + 1),iVar9,(int)(short)(sVar11 + 0x45));
    _DrawToWindow(puVar3,local_2c,local_28,local_24,local_20,1);
    if (PTR__p_00038028[0x213] == '\0') break;
    param_1[2] = param_1[2] + 1;
  }
  _DeleteAllSTTiles();
  puVar3 = PTR__g_00038024;
  *(undefined1 *)(param_1 + 0xe) = 1;
  *(undefined1 *)(*(int *)(puVar3 + 0x1ec) + 0x1c) = 1;
  *(undefined1 *)((int)param_1 + 0x1d) = 0;
  *(undefined1 *)(*(int *)(puVar3 + 0x1ec) + 0x1d) = 0;
  *(undefined4 *)(puVar3 + 0x1ec) = 0;
  _SetVisibleTiles();
  _SetOpenTiles();
  _RedrawCustomOpenPairs(0);
  puVar3 = PTR__g_00038024;
  sVar4 = 0;
  for (iVar2 = *(int *)PTR__gCGFirstPtr_00034044; iVar2 != 0; iVar2 = *(int *)(iVar2 + 0x20)) {
    sVar4 = sVar4 + (ushort)(*(char *)(iVar2 + 0x1c) == '\0');
  }
  psVar1 = (short *)(PTR__g_00038024 + 0x60);
  *(short *)(PTR__g_00038024 + 0x62) = sVar4;
  if (*psVar1 == 0) {
    for (puVar6 = *(undefined4 **)(puVar3 + 0x58); puVar6 != (undefined4 *)0x0;
        puVar6 = (undefined4 *)puVar6[0x42]) {
      if (*(short *)(puVar6 + 1) == *(short *)(puVar3 + 0x5c)) {
        _StopMovie(*puVar6);
      }
    }
    _PlaySound(0x14,0x100);
    puVar3 = PTR__g_00038024;
  }
  if (0 < *(short *)(puVar3 + 0x62)) {
    _RedrawCustomGameScreen(1);
    puVar3 = PTR__g_00038024;
  }
  sVar4 = 0;
  for (iVar2 = *(int *)PTR__gCGFirstPtr_00034044; iVar2 != 0; iVar2 = *(int *)(iVar2 + 0x20)) {
    if (*(char *)(iVar2 + 0x18) != '\0') {
      sVar4 = sVar4 + (ushort)(*(char *)(iVar2 + 0x1c) == '\0');
    }
  }
  puVar10 = puVar3;
  if (sVar4 == 1) {
    if (*(short *)(puVar3 + 0x62) == 0) goto LAB_00013ee0;
    _CreateNewDialog(0x47);
    puVar3[0x7d] = 1;
    puVar3[0x68] = 1;
    puVar10 = PTR__g_00038024;
    if (0xb < *(short *)(puVar3 + 0x90)) {
      puVar3[0x229] = 1;
      puVar10 = PTR__g_00038024;
    }
  }
  if (*(short *)(puVar10 + 0x62) != 0) {
    return;
  }
LAB_00013ee0:
  puVar10[0x68] = 1;
  return;
}


// ==== _SelectCGTile @ 00013eec ====

void _SelectCGTile(undefined4 param_1)

{
  short *psVar1;
  undefined *puVar2;
  short sVar3;
  short sVar4;
  short *psVar5;
  short sVar6;
  short local_40;
  short local_1e;
  
  puVar2 = PTR__g_00038024;
  local_40 = 6;
  local_1e = 0x1e;
  sVar3 = (short)((uint)param_1 >> 0x10);
  do {
    for (psVar5 = *(short **)PTR__gCGFirstPtr_00034044; psVar5 != (short *)0x0;
        psVar5 = *(short **)(psVar5 + 0x10)) {
      if ((((*psVar5 == local_40) &&
           (sVar6 = (short)(int)(DOUBLE_00033f98 * *(double *)(psVar5 + 4) * DOUBLE_00033fa0) -
                    (local_1e * 2 - *(short *)(puVar2 + 0x98)),
           sVar4 = (local_1e - *(short *)(puVar2 + 0x94)) +
                   (short)(int)(DOUBLE_00033fa8 * *(double *)(psVar5 + 8) * DOUBLE_00033fa0),
           (int)sVar3 <= sVar4 + 0x32 && sVar4 <= sVar3)) &&
          ((int)(short)param_1 <= sVar6 + 0x3b && sVar6 <= (short)param_1)) &&
         (((char)psVar5[0xc] != '\0' && ((char)psVar5[0xe] != '\x01')))) {
        psVar1 = *(short **)(puVar2 + 0x1ec);
        if (psVar1 == psVar5) {
          _PlaySound(0x5a,0x80);
          *(undefined1 *)((int)psVar5 + 0x1b) = 0;
          *(undefined4 *)(puVar2 + 0x1ec) = 0;
          _RedrawTile();
          return;
        }
        if (psVar1 == (short *)0x0) {
          _PlaySound(10,0x80);
          *(undefined1 *)((int)psVar5 + 0x1b) = 1;
          _RedrawTile(psVar5);
          *(short **)(puVar2 + 0x1ec) = psVar5;
          return;
        }
        if ((psVar1[1] == psVar5[1]) ||
           (((ushort)(psVar1[1] - 0xcdU) < 8 && ((ushort)(psVar5[1] - 0xcdU) < 8)))) {
          _StopSound(0x50,0x80);
          _PlaySound(0x46,0x80);
          *(undefined1 *)((int)psVar5 + 0x1b) = 1;
          _RedrawMatchedTiles(psVar5);
          sVar3 = *(short *)(PTR__p_00038028 + 0x20c);
          if (sVar3 == 1) {
            *(int *)(puVar2 + 0xb0) = *(int *)(puVar2 + 0xb0) + 6;
            return;
          }
          if (sVar3 != 2) {
            if (sVar3 != 0) {
              return;
            }
            *(int *)(puVar2 + 0xb0) = *(int *)(puVar2 + 0xb0) + 3;
            return;
          }
          *(int *)(puVar2 + 0xb0) = *(int *)(puVar2 + 0xb0) + 0xc;
          return;
        }
        _PlaySound(0x50,0x80);
        break;
      }
      if ((local_40 == 0 && *(int *)(psVar5 + 0x10) == 0) && (*(int *)(puVar2 + 0x1ec) != 0)) {
        _PlaySound(0x5a,0x80);
        *(undefined1 *)(*(int *)(puVar2 + 0x1ec) + 0x1b) = 0;
        psVar5 = *(short **)(puVar2 + 0x1ec);
        *(undefined4 *)(puVar2 + 0x1ec) = 0;
        _RedrawTile(psVar5);
      }
    }
    local_40 = local_40 + -1;
    local_1e = local_1e + -5;
    if (local_40 == -1) {
      return;
    }
  } while( true );
}


// ==== _LoadCustomLevel @ 00014177 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _LoadCustomLevel(void)

{
  undefined8 uVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined *puVar4;
  char cVar5;
  short sVar6;
  undefined2 uVar7;
  undefined4 uVar8;
  undefined4 uVar9;
  int iVar10;
  undefined2 *puVar11;
  undefined4 uVar12;
  undefined4 uVar13;
  undefined1 *local_6a0;
  undefined1 local_66a [4];
  undefined1 local_666;
  undefined1 local_56a [256];
  undefined1 local_46a [3];
  undefined1 local_467;
  undefined1 local_36a [256];
  undefined1 local_26a;
  undefined1 local_269;
  undefined1 local_16a [3];
  undefined1 local_167;
  undefined1 local_6a [70];
  undefined4 local_24;
  int local_20 [4];
  
  local_24 = 0;
  if (*(int *)(PTR__g_00038024 + 0xd0) == 0) {
    uVar8 = _objc_msgSend(PTR_s_NSOpenPanel_000362c8,PTR_s_openPanel_000361e8);
    uVar9 = _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
    cVar5 = _objc_msgSend(uVar9,PTR_s_isFullscreen_00036064);
    if (cVar5 != '\0') {
      _objc_msgSend(uVar8,PTR_s_scheduleSetShieldingLevel_00036158);
    }
    puVar2 = PTR_s_NSArray_000362c4;
    uVar9 = _NSFileTypeForHFSTypeCode(0x4c564c45);
    uVar9 = _objc_msgSend(puVar2,PTR_s_arrayWithObjects__000361ec,&cf_aki,uVar9,0);
    uVar13 = 0;
    uVar12 = 0;
    iVar10 = _objc_msgSend(uVar8,PTR_s_runModalForDirectory_file_types__000361f0,0,0,uVar9);
    if (iVar10 != 1) {
      return;
    }
    uVar8 = _objc_msgSend(uVar8,PTR_s_filename_000361d0,uVar12,uVar13,uVar9);
    uVar8 = _objc_msgSend(uVar8,PTR_s_UTF8String_00036088);
    _POSIXPathToFSSpec(uVar8,local_6a);
    iVar10 = _FT_PathCreateFromMacFSSpec(local_6a,local_20,local_56a);
    if (iVar10 != 0) {
      return;
    }
  }
  else {
    local_20[0] = *(int *)(PTR__g_00038024 + 0xd0);
    _StringCopy(local_56a,PTR__g_00038024 + 0xd8);
  }
  local_6a0 = local_56a;
  iVar10 = _FT_FileOpen(local_20[0],local_6a0,0,&local_24);
  if (iVar10 == 0) {
    _FT_FileRead(local_24,4,local_66a);
    local_666 = 0;
    sVar6 = _StringToNumber(local_66a);
    puVar4 = PTR__g_00038024;
    puVar2 = PTR__gCGLastPtr_00034040;
    if (sVar6 == 0x90) {
      sVar6 = 0;
      do {
        _FT_FileRead(local_24,3,local_46a);
        _FT_FileRead(local_24,3,local_16a);
        _FT_FileRead(local_24,1,&local_26a);
        _FT_FileRead(local_24,1,local_36a);
        local_467 = 0;
        local_167 = 0;
        local_269 = 0;
        iVar10 = _StringToNumber(local_46a);
        *(double *)(puVar4 + 0x1d8) = (double)(iVar10 + -0x80000000) + _DAT_00033ee0;
        iVar10 = _StringToNumber(local_16a);
        *(double *)(puVar4 + 0x1e0) = (double)(iVar10 + -0x80000000) + _DAT_00033ee0;
        uVar7 = _StringToNumber(&local_26a);
        *(undefined2 *)(puVar4 + 0x1e8) = uVar7;
        puVar11 = _malloc(0x28);
        *puVar11 = *(undefined2 *)(puVar4 + 0x1e8);
        puVar3 = PTR__gCGFirstPtr_00034044;
        *(undefined8 *)(puVar11 + 8) = *(undefined8 *)(puVar4 + 0x1d8);
        uVar1 = *(undefined8 *)(puVar4 + 0x1e0);
        *(undefined1 *)(puVar11 + 0xc) = 0;
        *(undefined8 *)(puVar11 + 4) = uVar1;
        *(undefined1 *)((int)puVar11 + 0x19) = 1;
        *(undefined1 *)(puVar11 + 0xd) = 0;
        *(undefined1 *)((int)puVar11 + 0x1b) = 0;
        *(undefined1 *)(puVar11 + 0xe) = 0;
        *(undefined1 *)((int)puVar11 + 0x1d) = 0;
        puVar11[2] = 0;
        if (*(int *)puVar3 == 0) {
          *(undefined4 *)(puVar11 + 0x10) = 0;
          *(undefined4 *)(puVar11 + 0x12) = 0;
          *(undefined2 **)puVar3 = puVar11;
          *(undefined2 **)puVar2 = puVar11;
        }
        else {
          *(undefined2 **)(*(int *)puVar2 + 0x20) = puVar11;
          *(int *)(*(int *)(*(int *)puVar2 + 0x20) + 0x24) = *(int *)puVar2;
          iVar10 = *(int *)(*(int *)puVar2 + 0x20);
          *(int *)puVar2 = iVar10;
          *(undefined4 *)(iVar10 + 0x20) = 0;
        }
        sVar6 = sVar6 + 1;
      } while (sVar6 != 0x90);
      _FT_FileClose(local_24);
      puVar2 = PTR__g_00038024;
      *(undefined4 *)(PTR__g_00038024 + 0x94) = 0;
      *(undefined4 *)(puVar2 + 0x98) = 0;
      *(int *)(puVar2 + 0xd0) = local_20[0];
      _StringCopy(puVar2 + 0xd8,local_6a0);
      *(undefined2 *)(puVar2 + 0x62) = 0x90;
      _ShuffleCustomTiles(0);
      uVar7 = _RandomBackground();
      puVar4 = PTR__p_00038028;
      cVar5 = PTR__p_00038028[0x201];
      *(undefined2 *)(puVar2 + 0x8e) = uVar7;
      if ((cVar5 == '\0') && (puVar2[0x22b] == '\x01')) {
        _SplashScreen("guide",0);
      }
      if (puVar4[0x214] != '\0') {
        _objc_msgSend(PTR_s_LevelDescriptionWindowController_000362c0,
                      PTR_s_runModalWithLayout_custom__000361b4,
                      *(short *)(PTR__g_00038024 + 0x8e) + -1,1);
      }
      if (PTR__g_00038024[0x7c] == '\0') {
        _AnimationMapScreenToCustom();
        _DrawGameTiles();
        _RedrawEntireWindow();
        return;
      }
      PTR__g_00038024[0x7c] = 0;
      _DeleteAllCGTiles();
      return;
    }
    _FT_FileClose(local_24);
    puVar2 = PTR__g_00038024;
    *(int *)(PTR__g_00038024 + 0xd0) = local_20[0];
    _StringCopy(puVar2 + 0xd8,local_6a0);
    uVar7 = _RandomBackground();
    *(undefined2 *)(puVar2 + 0x8e) = uVar7;
    _AnimationMapScreenToLevelEditor();
    _LoadFile(local_24);
    uVar8 = 0x51;
  }
  else {
    if (iVar10 != -0x1c29) {
      if (iVar10 != -0x1c23) {
        return;
      }
      _CreateNewDialog(0x58);
      *(undefined4 *)(PTR__g_00038024 + 0xd0) = 0;
      _DisableMenuCommand(0,0x12);
      return;
    }
    uVar8 = 0x56;
  }
  _CreateNewDialog(uVar8);
  return;
}


// ==== _AddTile @ 000146bc ====

void _AddTile(double param_1,double param_2,short param_3)

{
  undefined8 uVar1;
  int iVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined2 *puVar5;
  
  puVar3 = PTR__g_00038024;
  param_3 = param_3 + -1;
  if (param_3 == 0) {
    param_3 = 6;
  }
  else if (param_3 == 1) {
    param_3 = 5;
  }
  else if (param_3 == 2) {
    param_3 = 4;
  }
  else if (param_3 != 3) {
    if (param_3 == 4) {
      param_3 = 2;
    }
    else if (param_3 == 5) {
      param_3 = 1;
    }
    else if (param_3 == 6) {
      param_3 = 0;
    }
  }
  *(double *)(PTR__g_00038024 + 0x1d8) = param_1 + param_1;
  *(short *)(puVar3 + 0x1e8) = param_3;
  *(double *)(puVar3 + 0x1e0) = param_2 + param_2;
  puVar5 = _malloc(0x28);
  *puVar5 = *(undefined2 *)(puVar3 + 0x1e8);
  puVar4 = PTR__gCGFirstPtr_00034044;
  *(undefined8 *)(puVar5 + 8) = *(undefined8 *)(puVar3 + 0x1d8);
  uVar1 = *(undefined8 *)(puVar3 + 0x1e0);
  *(undefined1 *)(puVar5 + 0xc) = 0;
  *(undefined8 *)(puVar5 + 4) = uVar1;
  *(undefined1 *)((int)puVar5 + 0x19) = 1;
  *(undefined1 *)(puVar5 + 0xd) = 0;
  *(undefined1 *)((int)puVar5 + 0x1b) = 0;
  *(undefined1 *)(puVar5 + 0xe) = 0;
  *(undefined1 *)((int)puVar5 + 0x1d) = 0;
  puVar5[2] = 0;
  puVar3 = PTR__gCGLastPtr_00034040;
  if (*(int *)puVar4 == 0) {
    *(undefined4 *)(puVar5 + 0x10) = 0;
    *(undefined4 *)(puVar5 + 0x12) = 0;
    *(undefined2 **)puVar4 = puVar5;
    *(undefined2 **)PTR__gCGLastPtr_00034040 = puVar5;
  }
  else {
    *(undefined2 **)(*(int *)PTR__gCGLastPtr_00034040 + 0x20) = puVar5;
    *(int *)(*(int *)(*(int *)puVar3 + 0x20) + 0x24) = *(int *)puVar3;
    iVar2 = *(int *)(*(int *)puVar3 + 0x20);
    *(int *)puVar3 = iVar2;
    *(undefined4 *)(iVar2 + 0x20) = 0;
  }
  return;
}


// ==== _Layout7 @ 000147d6 ====

void _Layout7(void)

{
  undefined *puVar1;
  
  _AddTile(0,0x40000000,0,0x40200000,5);
  _AddTile(0,0x40080000,0,0x40200000,5);
  _AddTile(0,0x40100000,0,0x40200000,5);
  _AddTile(0,0x40140000,0,0x40200000,5);
  _AddTile(0,0x40180000,0,0x40200000,5);
  _AddTile(0,0x401c0000,0,0x40200000,5);
  _AddTile(0,0x40200000,0,0x40200000,5);
  _AddTile(0,0x40220000,0,0x40200000,5);
  _AddTile(0,0x40240000,0,0x40200000,5);
  _AddTile(0,0x40260000,0,0x40200000,5);
  _AddTile(0,0x40280000,0,0x40200000,5);
  _AddTile(0,0x402a0000,0,0x40200000,5);
  _AddTile(0,0x40100000,0,0x401c0000,5);
  _AddTile(0,0x40140000,0,0x401c0000,5);
  _AddTile(0,0x40180000,0,0x401c0000,5);
  _AddTile(0,0x401c0000,0,0x401c0000,5);
  _AddTile(0,0x40200000,0,0x401c0000,5);
  _AddTile(0,0x40220000,0,0x401c0000,5);
  _AddTile(0,0x40240000,0,0x401c0000,5);
  _AddTile(0,0x40260000,0,0x401c0000,5);
  _AddTile(0,0x40080000,0,0x40180000,5);
  _AddTile(0,0x40100000,0,0x40180000,5);
  _AddTile(0,0x40140000,0,0x40180000,5);
  _AddTile(0,0x40180000,0,0x40180000,5);
  _AddTile(0,0x401c0000,0,0x40180000,5);
  _AddTile(0,0x40200000,0,0x40180000,5);
  _AddTile(0,0x40220000,0,0x40180000,5);
  _AddTile(0,0x40240000,0,0x40180000,5);
  _AddTile(0,0x40260000,0,0x40180000,5);
  _AddTile(0,0x40280000,0,0x40180000,5);
  _AddTile(0,0x3ff00000,0,0x40120000,5);
  _AddTile(0,0x40000000,0,0x40140000,5);
  _AddTile(0,0x40080000,0,0x40140000,5);
  _AddTile(0,0x40100000,0,0x40140000,5);
  _AddTile(0,0x40140000,0,0x40140000,5);
  _AddTile(0,0x40180000,0,0x40140000,5);
  _AddTile(0,0x401c0000,0,0x40140000,5);
  _AddTile(0,0x40200000,0,0x40140000,5);
  _AddTile(0,0x40220000,0,0x40140000,5);
  _AddTile(0,0x40240000,0,0x40140000,5);
  _AddTile(0,0x40260000,0,0x40140000,5);
  _AddTile(0,0x40280000,0,0x40140000,5);
  _AddTile(0,0x402a0000,0,0x40140000,5);
  _AddTile(0,0x40000000,0,0x40100000,5);
  _AddTile(0,0x40080000,0,0x40100000,5);
  _AddTile(0,0x40100000,0,0x40100000,5);
  _AddTile(0,0x40140000,0,0x40100000,5);
  _AddTile(0,0x40180000,0,0x40100000,5);
  _AddTile(0,0x401c0000,0,0x40100000,5);
  _AddTile(0,0x40200000,0,0x40100000,5);
  _AddTile(0,0x40220000,0,0x40100000,5);
  _AddTile(0,0x40240000,0,0x40100000,5);
  _AddTile(0,0x40260000,0,0x40100000,5);
  _AddTile(0,0x40280000,0,0x40100000,5);
  _AddTile(0,0x402a0000,0,0x40100000,5);
  _AddTile(0,0x402c0000,0,0x40120000,5);
  _AddTile(0,0x402e0000,0,0x40120000,5);
  _AddTile(0,0x40080000,0,0x40080000,5);
  _AddTile(0,0x40100000,0,0x40080000,5);
  _AddTile(0,0x40140000,0,0x40080000,5);
  _AddTile(0,0x40180000,0,0x40080000,5);
  _AddTile(0,0x401c0000,0,0x40080000,5);
  _AddTile(0,0x40200000,0,0x40080000,5);
  _AddTile(0,0x40220000,0,0x40080000,5);
  _AddTile(0,0x40240000,0,0x40080000,5);
  _AddTile(0,0x40260000,0,0x40080000,5);
  _AddTile(0,0x40280000,0,0x40080000,5);
  _AddTile(0,0x40100000,0,0x40000000,5);
  _AddTile(0,0x40140000,0,0x40000000,5);
  _AddTile(0,0x40180000,0,0x40000000,5);
  _AddTile(0,0x401c0000,0,0x40000000,5);
  _AddTile(0,0x40200000,0,0x40000000,5);
  _AddTile(0,0x40220000,0,0x40000000,5);
  _AddTile(0,0x40240000,0,0x40000000,5);
  _AddTile(0,0x40260000,0,0x40000000,5);
  _AddTile(0,0x40000000,0,0x3ff00000,5);
  _AddTile(0,0x40080000,0,0x3ff00000,5);
  _AddTile(0,0x40100000,0,0x3ff00000,5);
  _AddTile(0,0x40140000,0,0x3ff00000,5);
  _AddTile(0,0x40180000,0,0x3ff00000,5);
  _AddTile(0,0x401c0000,0,0x3ff00000,5);
  _AddTile(0,0x40200000,0,0x3ff00000,5);
  _AddTile(0,0x40220000,0,0x3ff00000,5);
  _AddTile(0,0x40240000,0,0x3ff00000,5);
  _AddTile(0,0x40260000,0,0x3ff00000,5);
  _AddTile(0,0x40280000,0,0x3ff00000,5);
  _AddTile(0,0x402a0000,0,0x3ff00000,5);
  _AddTile(0,0x40140000,0,0x401c0000,4);
  _AddTile(0,0x40180000,0,0x401c0000,4);
  _AddTile(0,0x401c0000,0,0x401c0000,4);
  _AddTile(0,0x40200000,0,0x401c0000,4);
  _AddTile(0,0x40220000,0,0x401c0000,4);
  _AddTile(0,0x40240000,0,0x401c0000,4);
  _AddTile(0,0x40140000,0,0x40180000,4);
  _AddTile(0,0x40180000,0,0x40180000,4);
  _AddTile(0,0x401c0000,0,0x40180000,4);
  _AddTile(0,0x40200000,0,0x40180000,4);
  _AddTile(0,0x40220000,0,0x40180000,4);
  _AddTile(0,0x40240000,0,0x40180000,4);
  _AddTile(0,0x40140000,0,0x40140000,4);
  _AddTile(0,0x40180000,0,0x40140000,4);
  _AddTile(0,0x401c0000,0,0x40140000,4);
  _AddTile(0,0x40200000,0,0x40140000,4);
  _AddTile(0,0x40220000,0,0x40140000,4);
  _AddTile(0,0x40240000,0,0x40140000,4);
  _AddTile(0,0x40140000,0,0x40100000,4);
  _AddTile(0,0x40180000,0,0x40100000,4);
  _AddTile(0,0x401c0000,0,0x40100000,4);
  _AddTile(0,0x40200000,0,0x40100000,4);
  _AddTile(0,0x40220000,0,0x40100000,4);
  _AddTile(0,0x40240000,0,0x40100000,4);
  _AddTile(0,0x40140000,0,0x40080000,4);
  _AddTile(0,0x40180000,0,0x40080000,4);
  _AddTile(0,0x401c0000,0,0x40080000,4);
  _AddTile(0,0x40200000,0,0x40080000,4);
  _AddTile(0,0x40220000,0,0x40080000,4);
  _AddTile(0,0x40240000,0,0x40080000,4);
  _AddTile(0,0x40140000,0,0x40000000,4);
  _AddTile(0,0x40180000,0,0x40000000,4);
  _AddTile(0,0x401c0000,0,0x40000000,4);
  _AddTile(0,0x40200000,0,0x40000000,4);
  _AddTile(0,0x40220000,0,0x40000000,4);
  _AddTile(0,0x40240000,0,0x40000000,4);
  _AddTile(0,0x40180000,0,0x40180000,3);
  _AddTile(0,0x401c0000,0,0x40180000,3);
  _AddTile(0,0x40200000,0,0x40180000,3);
  _AddTile(0,0x40220000,0,0x40180000,3);
  _AddTile(0,0x40180000,0,0x40140000,3);
  _AddTile(0,0x401c0000,0,0x40140000,3);
  _AddTile(0,0x40200000,0,0x40140000,3);
  _AddTile(0,0x40220000,0,0x40140000,3);
  _AddTile(0,0x40180000,0,0x40100000,3);
  _AddTile(0,0x401c0000,0,0x40100000,3);
  _AddTile(0,0x40200000,0,0x40100000,3);
  _AddTile(0,0x40220000,0,0x40100000,3);
  _AddTile(0,0x40180000,0,0x40080000,3);
  _AddTile(0,0x401c0000,0,0x40080000,3);
  _AddTile(0,0x40200000,0,0x40080000,3);
  _AddTile(0,0x40220000,0,0x40080000,3);
  _AddTile(0,0x401c0000,0,0x40140000,2);
  _AddTile(0,0x40200000,0,0x40140000,2);
  _AddTile(0,0x401c0000,0,0x40100000,2);
  _AddTile(0,0x40200000,0,0x40100000,2);
  _AddTile(0,0x401e0000,0,0x40120000,1);
  puVar1 = PTR__g_00038024;
  *(undefined4 *)(PTR__g_00038024 + 0x94) = 0;
  *(undefined4 *)(puVar1 + 0x98) = 10;
  *(undefined2 *)(puVar1 + 0x8e) = 7;
  return;
}


// ==== _Layout3 @ 000160c0 ====

void _Layout3(void)

{
  undefined *puVar1;
  
  _AddTile(0,0x3ff00000,0,0x40200000,5);
  _AddTile(0,0x40000000,0,0x40200000,5);
  _AddTile(0,0x40080000,0,0x40200000,5);
  _AddTile(0,0x40100000,0,0x40200000,5);
  _AddTile(0,0x401a0000,0,0x40200000,5);
  _AddTile(0,0x40220000,0,0x40200000,5);
  _AddTile(0,0x40240000,0,0x40200000,5);
  _AddTile(0,0x40260000,0,0x40200000,5);
  _AddTile(0,0x40280000,0,0x40200000,5);
  _AddTile(0,0x3ff00000,0,0x401c0000,5);
  _AddTile(0,0x40000000,0,0x401c0000,5);
  _AddTile(0,0x40080000,0,0x401c0000,5);
  _AddTile(0,0x40160000,0,0x401c0000,5);
  _AddTile(0,0x401a0000,0,0x401c0000,5);
  _AddTile(0,0x401e0000,0,0x401c0000,5);
  _AddTile(0,0x40240000,0,0x401c0000,5);
  _AddTile(0,0x40260000,0,0x401c0000,5);
  _AddTile(0,0x40280000,0,0x401c0000,5);
  _AddTile(0,0x3ff00000,0,0x40180000,5);
  _AddTile(0,0x40000000,0,0x40180000,5);
  _AddTile(0,0x40120000,0,0x40180000,5);
  _AddTile(0,0x40160000,0,0x40180000,5);
  _AddTile(0,0x401a0000,0,0x40180000,5);
  _AddTile(0,0x401e0000,0,0x40180000,5);
  _AddTile(0,0x40210000,0,0x40180000,5);
  _AddTile(0,0x40260000,0,0x40180000,5);
  _AddTile(0,0x40280000,0,0x40180000,5);
  _AddTile(0,0x3ff00000,0,0x40140000,5);
  _AddTile(0,0x400c0000,0,0x40140000,5);
  _AddTile(0,0x40120000,0,0x40140000,5);
  _AddTile(0,0x40160000,0,0x40140000,5);
  _AddTile(0,0x401a0000,0,0x40140000,5);
  _AddTile(0,0x401e0000,0,0x40140000,5);
  _AddTile(0,0x40210000,0,0x40140000,5);
  _AddTile(0,0x40230000,0,0x40140000,5);
  _AddTile(0,0x40280000,0,0x40140000,5);
  _AddTile(0,0x40040000,0,0x40100000,5);
  _AddTile(0,0x400c0000,0,0x40100000,5);
  _AddTile(0,0x40120000,0,0x40100000,5);
  _AddTile(0,0x40160000,0,0x40100000,5);
  _AddTile(0,0x401a0000,0,0x40100000,5);
  _AddTile(0,0x401e0000,0,0x40100000,5);
  _AddTile(0,0x40210000,0,0x40100000,5);
  _AddTile(0,0x40230000,0,0x40100000,5);
  _AddTile(0,0x40250000,0,0x40100000,5);
  _AddTile(0,0x3ff00000,0,0x40080000,5);
  _AddTile(0,0x400c0000,0,0x40080000,5);
  _AddTile(0,0x40120000,0,0x40080000,5);
  _AddTile(0,0x40160000,0,0x40080000,5);
  _AddTile(0,0x401a0000,0,0x40080000,5);
  _AddTile(0,0x401e0000,0,0x40080000,5);
  _AddTile(0,0x40210000,0,0x40080000,5);
  _AddTile(0,0x40230000,0,0x40080000,5);
  _AddTile(0,0x40280000,0,0x40080000,5);
  _AddTile(0,0x3ff00000,0,0x40000000,5);
  _AddTile(0,0x40000000,0,0x40000000,5);
  _AddTile(0,0x40120000,0,0x40000000,5);
  _AddTile(0,0x40160000,0,0x40000000,5);
  _AddTile(0,0x401a0000,0,0x40000000,5);
  _AddTile(0,0x401e0000,0,0x40000000,5);
  _AddTile(0,0x40210000,0,0x40000000,5);
  _AddTile(0,0x40260000,0,0x40000000,5);
  _AddTile(0,0x40280000,0,0x40000000,5);
  _AddTile(0,0x3ff00000,0,0x3ff00000,5);
  _AddTile(0,0x40000000,0,0x3ff00000,5);
  _AddTile(0,0x40080000,0,0x3ff00000,5);
  _AddTile(0,0x40160000,0,0x3ff00000,5);
  _AddTile(0,0x401a0000,0,0x3ff00000,5);
  _AddTile(0,0x401e0000,0,0x3ff00000,5);
  _AddTile(0,0x40240000,0,0x3ff00000,5);
  _AddTile(0,0x40260000,0,0x3ff00000,5);
  _AddTile(0,0x40280000,0,0x3ff00000,5);
  _AddTile(0,0x3ff00000,0,0x40200000,4);
  _AddTile(0,0x40000000,0,0x40200000,4);
  _AddTile(0,0x40080000,0,0x40200000,4);
  _AddTile(0,0x40240000,0,0x40200000,4);
  _AddTile(0,0x40260000,0,0x40200000,4);
  _AddTile(0,0x40280000,0,0x40200000,4);
  _AddTile(0,0x3ff00000,0,0x401c0000,4);
  _AddTile(0,0x40000000,0,0x401c0000,4);
  _AddTile(0,0x401a0000,0,0x401c0000,4);
  _AddTile(0,0x40260000,0,0x401c0000,4);
  _AddTile(0,0x40280000,0,0x401c0000,4);
  _AddTile(0,0x3ff00000,0,0x40180000,4);
  _AddTile(0,0x40160000,0,0x40180000,4);
  _AddTile(0,0x401a0000,0,0x40180000,4);
  _AddTile(0,0x401e0000,0,0x40180000,4);
  _AddTile(0,0x40280000,0,0x40180000,4);
  _AddTile(0,0x40120000,0,0x40140000,4);
  _AddTile(0,0x40160000,0,0x40140000,4);
  _AddTile(0,0x401a0000,0,0x40140000,4);
  _AddTile(0,0x401e0000,0,0x40140000,4);
  _AddTile(0,0x40210000,0,0x40140000,4);
  _AddTile(0,0x400c0000,0,0x40100000,4);
  _AddTile(0,0x40120000,0,0x40100000,4);
  _AddTile(0,0x40160000,0,0x40100000,4);
  _AddTile(0,0x401a0000,0,0x40100000,4);
  _AddTile(0,0x401e0000,0,0x40100000,4);
  _AddTile(0,0x40210000,0,0x40100000,4);
  _AddTile(0,0x40230000,0,0x40100000,4);
  _AddTile(0,0x40120000,0,0x40080000,4);
  _AddTile(0,0x40160000,0,0x40080000,4);
  _AddTile(0,0x401a0000,0,0x40080000,4);
  _AddTile(0,0x401e0000,0,0x40080000,4);
  _AddTile(0,0x40210000,0,0x40080000,4);
  _AddTile(0,0x3ff00000,0,0x40000000,4);
  _AddTile(0,0x40160000,0,0x40000000,4);
  _AddTile(0,0x401a0000,0,0x40000000,4);
  _AddTile(0,0x401e0000,0,0x40000000,4);
  _AddTile(0,0x40280000,0,0x40000000,4);
  _AddTile(0,0x3ff00000,0,0x3ff00000,4);
  _AddTile(0,0x40000000,0,0x3ff00000,4);
  _AddTile(0,0x401a0000,0,0x3ff00000,4);
  _AddTile(0,0x40260000,0,0x3ff00000,4);
  _AddTile(0,0x40280000,0,0x3ff00000,4);
  _AddTile(0,0x3ff00000,0,0x40200000,3);
  _AddTile(0,0x40000000,0,0x40200000,3);
  _AddTile(0,0x40260000,0,0x40200000,3);
  _AddTile(0,0x40280000,0,0x40200000,3);
  _AddTile(0,0x3ff00000,0,0x401c0000,3);
  _AddTile(0,0x40280000,0,0x401c0000,3);
  _AddTile(0,0x401a0000,0,0x40180000,3);
  _AddTile(0,0x40160000,0,0x40140000,3);
  _AddTile(0,0x401a0000,0,0x40140000,3);
  _AddTile(0,0x401e0000,0,0x40140000,3);
  _AddTile(0,0x40120000,0,0x40100000,3);
  _AddTile(0,0x40160000,0,0x40100000,3);
  _AddTile(0,0x401a0000,0,0x40100000,3);
  _AddTile(0,0x401e0000,0,0x40100000,3);
  _AddTile(0,0x40210000,0,0x40100000,3);
  _AddTile(0,0x40160000,0,0x40080000,3);
  _AddTile(0,0x401a0000,0,0x40080000,3);
  _AddTile(0,0x401e0000,0,0x40080000,3);
  _AddTile(0,0x401a0000,0,0x40000000,3);
  _AddTile(0,0x3ff00000,0,0x3ff00000,3);
  _AddTile(0,0x40280000,0,0x3ff00000,3);
  _AddTile(0,0x3ff00000,0,0x40200000,2);
  _AddTile(0,0x40280000,0,0x40200000,2);
  _AddTile(0,0x401a0000,0,0x40140000,2);
  _AddTile(0,0x40160000,0,0x40100000,2);
  _AddTile(0,0x401a0000,0,0x40100000,2);
  _AddTile(0,0x401e0000,0,0x40100000,2);
  _AddTile(0,0x401a0000,0,0x40080000,2);
  _AddTile(0,0x401a0000,0,0x40100000,1);
  puVar1 = PTR__g_00038024;
  *(undefined4 *)(PTR__g_00038024 + 0x94) = 0xffffffbf;
  *(undefined4 *)(puVar1 + 0x98) = 0x12;
  *(undefined2 *)(puVar1 + 0x8e) = 3;
  return;
}


// ==== _Layout9 @ 000179aa ====

void _Layout9(void)

{
  undefined *puVar1;
  
  _AddTile(0,0x40080000,0,0x40200000,5);
  _AddTile(0,0x40140000,0,0x40200000,5);
  _AddTile(0,0x40180000,0,0x40200000,5);
  _AddTile(0,0x401c0000,0,0x40200000,5);
  _AddTile(0,0x40200000,0,0x40200000,5);
  _AddTile(0,0x40240000,0,0x40200000,5);
  _AddTile(0,0x40080000,0,0x401c0000,5);
  _AddTile(0,0x40140000,0,0x401c0000,5);
  _AddTile(0,0x40180000,0,0x401c0000,5);
  _AddTile(0,0x401c0000,0,0x401c0000,5);
  _AddTile(0,0x40200000,0,0x401c0000,5);
  _AddTile(0,0x40240000,0,0x401c0000,5);
  _AddTile(0,0x40080000,0,0x40180000,5);
  _AddTile(0,0x40140000,0,0x40180000,5);
  _AddTile(0,0x40180000,0,0x40180000,5);
  _AddTile(0,0x401c0000,0,0x40180000,5);
  _AddTile(0,0x40200000,0,0x40180000,5);
  _AddTile(0,0x40240000,0,0x40180000,5);
  _AddTile(0,0x3ff00000,0,0x40120000,5);
  _AddTile(0,0x40000000,0,0x40140000,5);
  _AddTile(0,0x40080000,0,0x40140000,5);
  _AddTile(0,0x40100000,0,0x40140000,5);
  _AddTile(0,0x40140000,0,0x40140000,5);
  _AddTile(0,0x40180000,0,0x40140000,5);
  _AddTile(0,0x401c0000,0,0x40140000,5);
  _AddTile(0,0x40200000,0,0x40140000,5);
  _AddTile(0,0x40220000,0,0x40140000,5);
  _AddTile(0,0x40240000,0,0x40140000,5);
  _AddTile(0,0x40260000,0,0x40140000,5);
  _AddTile(0,0x40000000,0,0x40100000,5);
  _AddTile(0,0x40080000,0,0x40100000,5);
  _AddTile(0,0x40100000,0,0x40100000,5);
  _AddTile(0,0x40140000,0,0x40100000,5);
  _AddTile(0,0x40180000,0,0x40100000,5);
  _AddTile(0,0x401c0000,0,0x40100000,5);
  _AddTile(0,0x40200000,0,0x40100000,5);
  _AddTile(0,0x40220000,0,0x40100000,5);
  _AddTile(0,0x40240000,0,0x40100000,5);
  _AddTile(0,0x40260000,0,0x40100000,5);
  _AddTile(0,0x40080000,0,0x40080000,5);
  _AddTile(0,0x40080000,0,0x40000000,5);
  _AddTile(0,0x40080000,0,0x3ff00000,5);
  _AddTile(0,0x40140000,0,0x40080000,5);
  _AddTile(0,0x40180000,0,0x40080000,5);
  _AddTile(0,0x401c0000,0,0x40080000,5);
  _AddTile(0,0x40200000,0,0x40080000,5);
  _AddTile(0,0x40140000,0,0x40000000,5);
  _AddTile(0,0x40180000,0,0x40000000,5);
  _AddTile(0,0x401c0000,0,0x40000000,5);
  _AddTile(0,0x40200000,0,0x40000000,5);
  _AddTile(0,0x40140000,0,0x3ff00000,5);
  _AddTile(0,0x40180000,0,0x3ff00000,5);
  _AddTile(0,0x401c0000,0,0x3ff00000,5);
  _AddTile(0,0x40200000,0,0x3ff00000,5);
  _AddTile(0,0x40280000,0,0x40120000,5);
  _AddTile(0,0x402a0000,0,0x40120000,5);
  _AddTile(0,0x40240000,0,0x40080000,5);
  _AddTile(0,0x40240000,0,0x40000000,5);
  _AddTile(0,0x40240000,0,0x3ff00000,5);
  _AddTile(0,0x40080000,0,0x40120000,4);
  _AddTile(0,0x40100000,0,0x40120000,4);
  _AddTile(0,0x40080000,0,0x40200000,4);
  _AddTile(0,0x40080000,0,0x401c0000,4);
  _AddTile(0,0x40080000,0,0x40180000,4);
  _AddTile(0,0x40200000,0,0x40200000,4);
  _AddTile(0,0x401a0000,0,0x40200000,4);
  _AddTile(0,0x40140000,0,0x40200000,4);
  _AddTile(0,0x40140000,0,0x401c0000,4);
  _AddTile(0,0x40180000,0,0x401c0000,4);
  _AddTile(0,0x401c0000,0,0x401c0000,4);
  _AddTile(0,0x40200000,0,0x401c0000,4);
  _AddTile(0,0x40140000,0,0x40180000,4);
  _AddTile(0,0x40180000,0,0x40180000,4);
  _AddTile(0,0x401c0000,0,0x40180000,4);
  _AddTile(0,0x40200000,0,0x40180000,4);
  _AddTile(0,0x40140000,0,0x40140000,4);
  _AddTile(0,0x40180000,0,0x40140000,4);
  _AddTile(0,0x401c0000,0,0x40140000,4);
  _AddTile(0,0x40200000,0,0x40140000,4);
  _AddTile(0,0x40140000,0,0x40100000,4);
  _AddTile(0,0x40180000,0,0x40100000,4);
  _AddTile(0,0x401c0000,0,0x40100000,4);
  _AddTile(0,0x40200000,0,0x40100000,4);
  _AddTile(0,0x40140000,0,0x40080000,4);
  _AddTile(0,0x40180000,0,0x40080000,4);
  _AddTile(0,0x401c0000,0,0x40080000,4);
  _AddTile(0,0x40200000,0,0x40080000,4);
  _AddTile(0,0x40140000,0,0x40000000,4);
  _AddTile(0,0x40180000,0,0x40000000,4);
  _AddTile(0,0x401c0000,0,0x40000000,4);
  _AddTile(0,0x40200000,0,0x40000000,4);
  _AddTile(0,0x40140000,0,0x3ff00000,4);
  _AddTile(0,0x401a0000,0,0x3ff00000,4);
  _AddTile(0,0x40200000,0,0x3ff00000,4);
  _AddTile(0,0x40240000,0,0x40200000,4);
  _AddTile(0,0x40240000,0,0x401c0000,4);
  _AddTile(0,0x40240000,0,0x40180000,4);
  _AddTile(0,0x40220000,0,0x40120000,4);
  _AddTile(0,0x40240000,0,0x40120000,4);
  _AddTile(0,0x40080000,0,0x40080000,4);
  _AddTile(0,0x40080000,0,0x40000000,4);
  _AddTile(0,0x40080000,0,0x3ff00000,4);
  _AddTile(0,0x40240000,0,0x40080000,4);
  _AddTile(0,0x40240000,0,0x40000000,4);
  _AddTile(0,0x40240000,0,0x3ff00000,4);
  _AddTile(0,0x40100000,0,0x40120000,3);
  _AddTile(0,0x40140000,0,0x401e0000,3);
  _AddTile(0,0x401a0000,0,0x401e0000,3);
  _AddTile(0,0x40200000,0,0x401e0000,3);
  _AddTile(0,0x40140000,0,0x401a0000,3);
  _AddTile(0,0x401a0000,0,0x401a0000,3);
  _AddTile(0,0x40200000,0,0x401a0000,3);
  _AddTile(0,0x40140000,0,0x40160000,3);
  _AddTile(0,0x401a0000,0,0x40160000,3);
  _AddTile(0,0x40200000,0,0x40160000,3);
  _AddTile(0,0x40140000,0,0x40120000,3);
  _AddTile(0,0x401a0000,0,0x40120000,3);
  _AddTile(0,0x40200000,0,0x40120000,3);
  _AddTile(0,0x40140000,0,0x400c0000,3);
  _AddTile(0,0x401a0000,0,0x400c0000,3);
  _AddTile(0,0x40200000,0,0x400c0000,3);
  _AddTile(0,0x40140000,0,0x40040000,3);
  _AddTile(0,0x401a0000,0,0x40040000,3);
  _AddTile(0,0x40200000,0,0x40040000,3);
  _AddTile(0,0x40140000,0,0x3ff80000,3);
  _AddTile(0,0x401a0000,0,0x3ff80000,3);
  _AddTile(0,0x40200000,0,0x3ff80000,3);
  _AddTile(0,0x40220000,0,0x40120000,3);
  _AddTile(0,0x40140000,0,0x401a0000,2);
  _AddTile(0,0x401a0000,0,0x401a0000,2);
  _AddTile(0,0x40200000,0,0x401a0000,2);
  _AddTile(0,0x40140000,0,0x40160000,2);
  _AddTile(0,0x401a0000,0,0x40160000,2);
  _AddTile(0,0x40200000,0,0x40160000,2);
  _AddTile(0,0x40140000,0,0x40120000,2);
  _AddTile(0,0x40180000,0,0x40120000,2);
  _AddTile(0,0x401c0000,0,0x40120000,2);
  _AddTile(0,0x40200000,0,0x40120000,2);
  _AddTile(0,0x40140000,0,0x400c0000,2);
  _AddTile(0,0x401a0000,0,0x400c0000,2);
  _AddTile(0,0x40200000,0,0x400c0000,2);
  _AddTile(0,0x40140000,0,0x40120000,1);
  _AddTile(0,0x401a0000,0,0x40120000,1);
  _AddTile(0,0x40200000,0,0x40120000,1);
  puVar1 = PTR__g_00038024;
  *(undefined4 *)(PTR__g_00038024 + 0x94) = 0xffffffd3;
  *(undefined4 *)(puVar1 + 0x98) = 0x14;
  *(undefined2 *)(puVar1 + 0x8e) = 9;
  return;
}


// ==== _Layout1 @ 00019294 ====

void _Layout1(void)

{
  undefined *puVar1;
  
  _AddTile(0,0x40140000,0,0x40200000,5);
  _AddTile(0,0x40180000,0,0x40200000,5);
  _AddTile(0,0x401c0000,0,0x40200000,5);
  _AddTile(0,0x40220000,0,0x40200000,5);
  _AddTile(0,0x40240000,0,0x40200000,5);
  _AddTile(0,0x40260000,0,0x40200000,5);
  _AddTile(0,0x40140000,0,0x401c0000,5);
  _AddTile(0,0x40180000,0,0x401c0000,5);
  _AddTile(0,0x401c0000,0,0x401c0000,5);
  _AddTile(0,0x40220000,0,0x401c0000,5);
  _AddTile(0,0x40240000,0,0x401c0000,5);
  _AddTile(0,0x40260000,0,0x401c0000,5);
  _AddTile(0,0x40140000,0,0x40180000,5);
  _AddTile(0,0x40180000,0,0x40180000,5);
  _AddTile(0,0x401c0000,0,0x40180000,5);
  _AddTile(0,0x40220000,0,0x40180000,5);
  _AddTile(0,0x40240000,0,0x40180000,5);
  _AddTile(0,0x40260000,0,0x40180000,5);
  _AddTile(0,0x40140000,0,0x40140000,5);
  _AddTile(0,0x40180000,0,0x40140000,5);
  _AddTile(0,0x401c0000,0,0x40140000,5);
  _AddTile(0,0x40220000,0,0x40140000,5);
  _AddTile(0,0x40240000,0,0x40140000,5);
  _AddTile(0,0x40260000,0,0x40140000,5);
  _AddTile(0,0x40140000,0,0x40100000,5);
  _AddTile(0,0x40180000,0,0x40100000,5);
  _AddTile(0,0x401c0000,0,0x40100000,5);
  _AddTile(0,0x40220000,0,0x40100000,5);
  _AddTile(0,0x40240000,0,0x40100000,5);
  _AddTile(0,0x40260000,0,0x40100000,5);
  _AddTile(0,0x40140000,0,0x40080000,5);
  _AddTile(0,0x40180000,0,0x40080000,5);
  _AddTile(0,0x401c0000,0,0x40080000,5);
  _AddTile(0,0x40220000,0,0x40080000,5);
  _AddTile(0,0x40240000,0,0x40080000,5);
  _AddTile(0,0x40260000,0,0x40080000,5);
  _AddTile(0,0x40140000,0,0x40200000,4);
  _AddTile(0,0x40180000,0,0x40200000,4);
  _AddTile(0,0x401c0000,0,0x40200000,4);
  _AddTile(0,0x40220000,0,0x40200000,4);
  _AddTile(0,0x40240000,0,0x40200000,4);
  _AddTile(0,0x40260000,0,0x40200000,4);
  _AddTile(0,0x40140000,0,0x401c0000,4);
  _AddTile(0,0x40180000,0,0x401c0000,4);
  _AddTile(0,0x401c0000,0,0x401c0000,4);
  _AddTile(0,0x40220000,0,0x401c0000,4);
  _AddTile(0,0x40240000,0,0x401c0000,4);
  _AddTile(0,0x40260000,0,0x401c0000,4);
  _AddTile(0,0x40140000,0,0x40180000,4);
  _AddTile(0,0x40180000,0,0x40180000,4);
  _AddTile(0,0x401c0000,0,0x40180000,4);
  _AddTile(0,0x40220000,0,0x40180000,4);
  _AddTile(0,0x40240000,0,0x40180000,4);
  _AddTile(0,0x40260000,0,0x40180000,4);
  _AddTile(0,0x40140000,0,0x40140000,4);
  _AddTile(0,0x40180000,0,0x40140000,4);
  _AddTile(0,0x401c0000,0,0x40140000,4);
  _AddTile(0,0x40220000,0,0x40140000,4);
  _AddTile(0,0x40240000,0,0x40140000,4);
  _AddTile(0,0x40260000,0,0x40140000,4);
  _AddTile(0,0x40140000,0,0x40100000,4);
  _AddTile(0,0x40180000,0,0x40100000,4);
  _AddTile(0,0x401c0000,0,0x40100000,4);
  _AddTile(0,0x40220000,0,0x40100000,4);
  _AddTile(0,0x40240000,0,0x40100000,4);
  _AddTile(0,0x40260000,0,0x40100000,4);
  _AddTile(0,0x40140000,0,0x40080000,4);
  _AddTile(0,0x40180000,0,0x40080000,4);
  _AddTile(0,0x401c0000,0,0x40080000,4);
  _AddTile(0,0x40220000,0,0x40080000,4);
  _AddTile(0,0x40240000,0,0x40080000,4);
  _AddTile(0,0x40260000,0,0x40080000,4);
  _AddTile(0,0x40140000,0,0x40200000,3);
  _AddTile(0,0x40180000,0,0x40200000,3);
  _AddTile(0,0x401c0000,0,0x40200000,3);
  _AddTile(0,0x40220000,0,0x40200000,3);
  _AddTile(0,0x40240000,0,0x40200000,3);
  _AddTile(0,0x40260000,0,0x40200000,3);
  _AddTile(0,0x40140000,0,0x401c0000,3);
  _AddTile(0,0x40180000,0,0x401c0000,3);
  _AddTile(0,0x401c0000,0,0x401c0000,3);
  _AddTile(0,0x40220000,0,0x401c0000,3);
  _AddTile(0,0x40240000,0,0x401c0000,3);
  _AddTile(0,0x40260000,0,0x401c0000,3);
  _AddTile(0,0x40140000,0,0x40180000,3);
  _AddTile(0,0x40180000,0,0x40180000,3);
  _AddTile(0,0x401c0000,0,0x40180000,3);
  _AddTile(0,0x40220000,0,0x40180000,3);
  _AddTile(0,0x40240000,0,0x40180000,3);
  _AddTile(0,0x40260000,0,0x40180000,3);
  _AddTile(0,0x40140000,0,0x40140000,3);
  _AddTile(0,0x40180000,0,0x40140000,3);
  _AddTile(0,0x401c0000,0,0x40140000,3);
  _AddTile(0,0x40220000,0,0x40140000,3);
  _AddTile(0,0x40240000,0,0x40140000,3);
  _AddTile(0,0x40260000,0,0x40140000,3);
  _AddTile(0,0x40140000,0,0x40100000,3);
  _AddTile(0,0x40180000,0,0x40100000,3);
  _AddTile(0,0x401c0000,0,0x40100000,3);
  _AddTile(0,0x40220000,0,0x40100000,3);
  _AddTile(0,0x40240000,0,0x40100000,3);
  _AddTile(0,0x40260000,0,0x40100000,3);
  _AddTile(0,0x40140000,0,0x40080000,3);
  _AddTile(0,0x40180000,0,0x40080000,3);
  _AddTile(0,0x401c0000,0,0x40080000,3);
  _AddTile(0,0x40220000,0,0x40080000,3);
  _AddTile(0,0x40240000,0,0x40080000,3);
  _AddTile(0,0x40260000,0,0x40080000,3);
  _AddTile(0,0x40140000,0,0x40200000,2);
  _AddTile(0,0x40180000,0,0x40200000,2);
  _AddTile(0,0x401c0000,0,0x40200000,2);
  _AddTile(0,0x40220000,0,0x40200000,2);
  _AddTile(0,0x40240000,0,0x40200000,2);
  _AddTile(0,0x40260000,0,0x40200000,2);
  _AddTile(0,0x40140000,0,0x401c0000,2);
  _AddTile(0,0x40180000,0,0x401c0000,2);
  _AddTile(0,0x401c0000,0,0x401c0000,2);
  _AddTile(0,0x40220000,0,0x401c0000,2);
  _AddTile(0,0x40240000,0,0x401c0000,2);
  _AddTile(0,0x40260000,0,0x401c0000,2);
  _AddTile(0,0x40140000,0,0x40180000,2);
  _AddTile(0,0x40180000,0,0x40180000,2);
  _AddTile(0,0x401c0000,0,0x40180000,2);
  _AddTile(0,0x40220000,0,0x40180000,2);
  _AddTile(0,0x40240000,0,0x40180000,2);
  _AddTile(0,0x40260000,0,0x40180000,2);
  _AddTile(0,0x40140000,0,0x40140000,2);
  _AddTile(0,0x40180000,0,0x40140000,2);
  _AddTile(0,0x401c0000,0,0x40140000,2);
  _AddTile(0,0x40220000,0,0x40140000,2);
  _AddTile(0,0x40240000,0,0x40140000,2);
  _AddTile(0,0x40260000,0,0x40140000,2);
  _AddTile(0,0x40140000,0,0x40100000,2);
  _AddTile(0,0x40180000,0,0x40100000,2);
  _AddTile(0,0x401c0000,0,0x40100000,2);
  _AddTile(0,0x40220000,0,0x40100000,2);
  _AddTile(0,0x40240000,0,0x40100000,2);
  _AddTile(0,0x40260000,0,0x40100000,2);
  _AddTile(0,0x40140000,0,0x40080000,2);
  _AddTile(0,0x40180000,0,0x40080000,2);
  _AddTile(0,0x401c0000,0,0x40080000,2);
  _AddTile(0,0x40220000,0,0x40080000,2);
  _AddTile(0,0x40240000,0,0x40080000,2);
  _AddTile(0,0x40260000,0,0x40080000,2);
  puVar1 = PTR__g_00038024;
  *(undefined4 *)(PTR__g_00038024 + 0x94) = 0;
  *(undefined4 *)(puVar1 + 0x98) = 0xffffffd8;
  *(undefined2 *)(puVar1 + 0x8e) = 1;
  return;
}


// ==== _Layout12 @ 0001ab7e ====

void _Layout12(void)

{
  undefined *puVar1;
  
  _AddTile(0,0x40000000,0,0x40200000,5);
  _AddTile(0,0x40080000,0,0x40200000,5);
  _AddTile(0,0x40100000,0,0x40200000,5);
  _AddTile(0,0x40140000,0,0x40200000,5);
  _AddTile(0,0x40180000,0,0x40200000,5);
  _AddTile(0,0x40000000,0,0x401c0000,5);
  _AddTile(0,0x40080000,0,0x401c0000,5);
  _AddTile(0,0x40100000,0,0x401c0000,5);
  _AddTile(0,0x40140000,0,0x401c0000,5);
  _AddTile(0,0x40180000,0,0x401c0000,5);
  _AddTile(0,0x40000000,0,0x40180000,5);
  _AddTile(0,0x40080000,0,0x40180000,5);
  _AddTile(0,0x40100000,0,0x40180000,5);
  _AddTile(0,0x40140000,0,0x40180000,5);
  _AddTile(0,0x40180000,0,0x40180000,5);
  _AddTile(0,0x401c0000,0,0x401e0000,5);
  _AddTile(0,0x401c0000,0,0x401a0000,5);
  _AddTile(0,0x40210000,0,0x40200000,5);
  _AddTile(0,0x40200000,0,0x401c0000,5);
  _AddTile(0,0x40220000,0,0x401c0000,5);
  _AddTile(0,0x40240000,0,0x401e0000,5);
  _AddTile(0,0x40240000,0,0x401a0000,5);
  _AddTile(0,0x40210000,0,0x40180000,5);
  _AddTile(0,0x40260000,0,0x40200000,5);
  _AddTile(0,0x40280000,0,0x40200000,5);
  _AddTile(0,0x402a0000,0,0x40200000,5);
  _AddTile(0,0x402c0000,0,0x40200000,5);
  _AddTile(0,0x402e0000,0,0x40200000,5);
  _AddTile(0,0x40260000,0,0x401c0000,5);
  _AddTile(0,0x40280000,0,0x401c0000,5);
  _AddTile(0,0x402a0000,0,0x401c0000,5);
  _AddTile(0,0x402c0000,0,0x401c0000,5);
  _AddTile(0,0x402e0000,0,0x401c0000,5);
  _AddTile(0,0x40260000,0,0x40180000,5);
  _AddTile(0,0x40280000,0,0x40180000,5);
  _AddTile(0,0x402a0000,0,0x40180000,5);
  _AddTile(0,0x402c0000,0,0x40180000,5);
  _AddTile(0,0x402e0000,0,0x40180000,5);
  _AddTile(0,0x40000000,0,0x40140000,5);
  _AddTile(0,0x402c0000,0,0x40120000,5);
  _AddTile(0,0x40000000,0,0x40100000,5);
  _AddTile(0,0x40080000,0,0x40120000,5);
  _AddTile(0,0x40210000,0,0x40140000,5);
  _AddTile(0,0x402e0000,0,0x40140000,5);
  _AddTile(0,0x40210000,0,0x40100000,5);
  _AddTile(0,0x402e0000,0,0x40100000,5);
  _AddTile(0,0x40000000,0,0x40080000,5);
  _AddTile(0,0x40080000,0,0x40080000,5);
  _AddTile(0,0x40100000,0,0x40080000,5);
  _AddTile(0,0x40140000,0,0x40080000,5);
  _AddTile(0,0x40180000,0,0x40080000,5);
  _AddTile(0,0x40000000,0,0x40000000,5);
  _AddTile(0,0x40080000,0,0x40000000,5);
  _AddTile(0,0x40100000,0,0x40000000,5);
  _AddTile(0,0x40140000,0,0x40000000,5);
  _AddTile(0,0x40180000,0,0x40000000,5);
  _AddTile(0,0x40000000,0,0x3ff00000,5);
  _AddTile(0,0x40080000,0,0x3ff00000,5);
  _AddTile(0,0x40100000,0,0x3ff00000,5);
  _AddTile(0,0x40140000,0,0x3ff00000,5);
  _AddTile(0,0x40180000,0,0x3ff00000,5);
  _AddTile(0,0x401c0000,0,0x40040000,5);
  _AddTile(0,0x401c0000,0,0x3ff80000,5);
  _AddTile(0,0x40210000,0,0x40080000,5);
  _AddTile(0,0x40200000,0,0x40000000,5);
  _AddTile(0,0x40220000,0,0x40000000,5);
  _AddTile(0,0x40240000,0,0x40040000,5);
  _AddTile(0,0x40240000,0,0x3ff80000,5);
  _AddTile(0,0x40210000,0,0x3ff00000,5);
  _AddTile(0,0x40260000,0,0x40080000,5);
  _AddTile(0,0x40280000,0,0x40080000,5);
  _AddTile(0,0x402a0000,0,0x40080000,5);
  _AddTile(0,0x402c0000,0,0x40080000,5);
  _AddTile(0,0x402e0000,0,0x40080000,5);
  _AddTile(0,0x40260000,0,0x40000000,5);
  _AddTile(0,0x40280000,0,0x40000000,5);
  _AddTile(0,0x402a0000,0,0x40000000,5);
  _AddTile(0,0x402c0000,0,0x40000000,5);
  _AddTile(0,0x402e0000,0,0x40000000,5);
  _AddTile(0,0x40260000,0,0x3ff00000,5);
  _AddTile(0,0x40280000,0,0x3ff00000,5);
  _AddTile(0,0x402a0000,0,0x3ff00000,5);
  _AddTile(0,0x402c0000,0,0x3ff00000,5);
  _AddTile(0,0x402e0000,0,0x3ff00000,5);
  _AddTile(0,0x40280000,0,0x40200000,4);
  _AddTile(0,0x402a0000,0,0x40200000,4);
  _AddTile(0,0x402c0000,0,0x40200000,4);
  _AddTile(0,0x40210000,0,0x401e0000,4);
  _AddTile(0,0x40080000,0,0x40200000,4);
  _AddTile(0,0x40100000,0,0x40200000,4);
  _AddTile(0,0x40140000,0,0x40200000,4);
  _AddTile(0,0x40280000,0,0x401c0000,4);
  _AddTile(0,0x402a0000,0,0x401c0000,4);
  _AddTile(0,0x402c0000,0,0x401c0000,4);
  _AddTile(0,0x40210000,0,0x401a0000,4);
  _AddTile(0,0x40080000,0,0x401c0000,4);
  _AddTile(0,0x40100000,0,0x401c0000,4);
  _AddTile(0,0x40140000,0,0x401c0000,4);
  _AddTile(0,0x40280000,0,0x40180000,4);
  _AddTile(0,0x402a0000,0,0x40180000,4);
  _AddTile(0,0x402c0000,0,0x40180000,4);
  _AddTile(0,0x40210000,0,0x40160000,4);
  _AddTile(0,0x40080000,0,0x40180000,4);
  _AddTile(0,0x40100000,0,0x40180000,4);
  _AddTile(0,0x40140000,0,0x40180000,4);
  _AddTile(0,0x40000000,0,0x40120000,4);
  _AddTile(0,0x40210000,0,0x40120000,4);
  _AddTile(0,0x402e0000,0,0x40120000,4);
  _AddTile(0,0x40280000,0,0x40080000,4);
  _AddTile(0,0x402a0000,0,0x40080000,4);
  _AddTile(0,0x402c0000,0,0x40080000,4);
  _AddTile(0,0x40080000,0,0x40080000,4);
  _AddTile(0,0x40100000,0,0x40080000,4);
  _AddTile(0,0x40140000,0,0x40080000,4);
  _AddTile(0,0x40280000,0,0x40000000,4);
  _AddTile(0,0x402a0000,0,0x40000000,4);
  _AddTile(0,0x402c0000,0,0x40000000,4);
  _AddTile(0,0x40210000,0,0x400c0000,4);
  _AddTile(0,0x40080000,0,0x40000000,4);
  _AddTile(0,0x40100000,0,0x40000000,4);
  _AddTile(0,0x40140000,0,0x40000000,4);
  _AddTile(0,0x40280000,0,0x3ff00000,4);
  _AddTile(0,0x402a0000,0,0x3ff00000,4);
  _AddTile(0,0x402c0000,0,0x3ff00000,4);
  _AddTile(0,0x40210000,0,0x40040000,4);
  _AddTile(0,0x40080000,0,0x3ff00000,4);
  _AddTile(0,0x40100000,0,0x3ff00000,4);
  _AddTile(0,0x40140000,0,0x3ff00000,4);
  _AddTile(0,0x40210000,0,0x3ff80000,4);
  _AddTile(0,0x402a0000,0,0x40200000,3);
  _AddTile(0,0x40100000,0,0x40200000,3);
  _AddTile(0,0x402a0000,0,0x401c0000,3);
  _AddTile(0,0x40100000,0,0x401c0000,3);
  _AddTile(0,0x402a0000,0,0x40180000,3);
  _AddTile(0,0x40100000,0,0x40180000,3);
  _AddTile(0,0x40210000,0,0x40140000,3);
  _AddTile(0,0x40210000,0,0x40100000,3);
  _AddTile(0,0x402a0000,0,0x40080000,3);
  _AddTile(0,0x40100000,0,0x40080000,3);
  _AddTile(0,0x402a0000,0,0x40000000,3);
  _AddTile(0,0x40100000,0,0x40000000,3);
  _AddTile(0,0x402a0000,0,0x3ff00000,3);
  _AddTile(0,0x40100000,0,0x3ff00000,3);
  _AddTile(0,0x40210000,0,0x40120000,2);
  puVar1 = PTR__g_00038024;
  *(undefined4 *)(PTR__g_00038024 + 0x94) = 0x19;
  *(undefined4 *)(puVar1 + 0x98) = 0x19;
  *(undefined2 *)(puVar1 + 0x8e) = 0xc;
  return;
}


// ==== _Layout11 @ 0001c468 ====

void _Layout11(void)

{
  undefined *puVar1;
  
  _AddTile(0,0x40240000,0,0x401c0000,7);
  _AddTile(0,0x40260000,0,0x401c0000,7);
  _AddTile(0,0x40280000,0,0x401c0000,7);
  _AddTile(0,0x3ff00000,0,0x401c0000,7);
  _AddTile(0,0x40000000,0,0x401c0000,7);
  _AddTile(0,0x40080000,0,0x401c0000,7);
  _AddTile(0,0x40240000,0,0x40180000,7);
  _AddTile(0,0x40260000,0,0x40180000,7);
  _AddTile(0,0x40280000,0,0x40180000,7);
  _AddTile(0,0x402a0000,0,0x40180000,7);
  _AddTile(0,0,0,0x40180000,7);
  _AddTile(0,0x3ff00000,0,0x40180000,7);
  _AddTile(0,0x40000000,0,0x40180000,7);
  _AddTile(0,0x40080000,0,0x40180000,7);
  _AddTile(0,0x40240000,0,0x40140000,7);
  _AddTile(0,0x40260000,0,0x40140000,7);
  _AddTile(0,0x40280000,0,0x40140000,7);
  _AddTile(0,0x402a0000,0,0x40140000,7);
  _AddTile(0,0,0,0x40140000,7);
  _AddTile(0,0x3ff00000,0,0x40140000,7);
  _AddTile(0,0x40000000,0,0x40140000,7);
  _AddTile(0,0x40080000,0,0x40140000,7);
  _AddTile(0,0x40240000,0,0x40100000,7);
  _AddTile(0,0x40260000,0,0x40100000,7);
  _AddTile(0,0x40280000,0,0x40100000,7);
  _AddTile(0,0x402a0000,0,0x40100000,7);
  _AddTile(0,0,0,0x40100000,7);
  _AddTile(0,0x3ff00000,0,0x40100000,7);
  _AddTile(0,0x40000000,0,0x40100000,7);
  _AddTile(0,0x40080000,0,0x40100000,7);
  _AddTile(0,0x40240000,0,0x40080000,7);
  _AddTile(0,0x40260000,0,0x40080000,7);
  _AddTile(0,0x40280000,0,0x40080000,7);
  _AddTile(0,0x3ff00000,0,0x40080000,7);
  _AddTile(0,0x40000000,0,0x40080000,7);
  _AddTile(0,0x40080000,0,0x40080000,7);
  _AddTile(0,0x40240000,0,0x401c0000,6);
  _AddTile(0,0x40260000,0,0x401c0000,6);
  _AddTile(0,0x40280000,0,0x401c0000,6);
  _AddTile(0,0x3ff00000,0,0x401c0000,6);
  _AddTile(0,0x40000000,0,0x401c0000,6);
  _AddTile(0,0x40080000,0,0x401c0000,6);
  _AddTile(0,0x40240000,0,0x40180000,6);
  _AddTile(0,0x40260000,0,0x40180000,6);
  _AddTile(0,0x40000000,0,0x40180000,6);
  _AddTile(0,0x40080000,0,0x40180000,6);
  _AddTile(0,0x40240000,0,0x40140000,6);
  _AddTile(0,0x40260000,0,0x40140000,6);
  _AddTile(0,0x40000000,0,0x40140000,6);
  _AddTile(0,0x40080000,0,0x40140000,6);
  _AddTile(0,0x40240000,0,0x40100000,6);
  _AddTile(0,0x40260000,0,0x40100000,6);
  _AddTile(0,0x40000000,0,0x40100000,6);
  _AddTile(0,0x40080000,0,0x40100000,6);
  _AddTile(0,0x40240000,0,0x40080000,6);
  _AddTile(0,0x40260000,0,0x40080000,6);
  _AddTile(0,0x40280000,0,0x40080000,6);
  _AddTile(0,0x3ff00000,0,0x40080000,6);
  _AddTile(0,0x40000000,0,0x40080000,6);
  _AddTile(0,0x40080000,0,0x40080000,6);
  _AddTile(0,0x40240000,0,0x401c0000,5);
  _AddTile(0,0x40240000,0,0x40180000,5);
  _AddTile(0,0x40240000,0,0x40140000,5);
  _AddTile(0,0x40240000,0,0x40100000,5);
  _AddTile(0,0x40240000,0,0x40080000,5);
  _AddTile(0,0x40260000,0,0x40080000,5);
  _AddTile(0,0x40260000,0,0x401c0000,5);
  _AddTile(0,0x40000000,0,0x401c0000,5);
  _AddTile(0,0x40080000,0,0x401c0000,5);
  _AddTile(0,0x40080000,0,0x40180000,5);
  _AddTile(0,0x40080000,0,0x40140000,5);
  _AddTile(0,0x40080000,0,0x40100000,5);
  _AddTile(0,0x40000000,0,0x40080000,5);
  _AddTile(0,0x40080000,0,0x40080000,5);
  _AddTile(0,0x40230000,0,0x401c0000,4);
  _AddTile(0,0x40230000,0,0x40180000,4);
  _AddTile(0,0x40230000,0,0x40140000,4);
  _AddTile(0,0x40230000,0,0x40100000,4);
  _AddTile(0,0x40230000,0,0x40080000,4);
  _AddTile(0,0x40250000,0,0x401c0000,4);
  _AddTile(0,0x40250000,0,0x40080000,4);
  _AddTile(0,0x40040000,0,0x401c0000,4);
  _AddTile(0,0x40040000,0,0x40080000,4);
  _AddTile(0,0x400c0000,0,0x401c0000,4);
  _AddTile(0,0x400c0000,0,0x40180000,4);
  _AddTile(0,0x400c0000,0,0x40140000,4);
  _AddTile(0,0x400c0000,0,0x40100000,4);
  _AddTile(0,0x400c0000,0,0x40080000,4);
  _AddTile(0,0x40200000,0,0x401c0000,3);
  _AddTile(0,0x40220000,0,0x401c0000,3);
  _AddTile(0,0x40240000,0,0x401c0000,3);
  _AddTile(0,0x40080000,0,0x401c0000,3);
  _AddTile(0,0x40100000,0,0x401c0000,3);
  _AddTile(0,0x40140000,0,0x401c0000,3);
  _AddTile(0,0x40200000,0,0x40180000,3);
  _AddTile(0,0x40220000,0,0x40180000,3);
  _AddTile(0,0x40100000,0,0x40180000,3);
  _AddTile(0,0x40140000,0,0x40180000,3);
  _AddTile(0,0x40200000,0,0x40140000,3);
  _AddTile(0,0x40220000,0,0x40140000,3);
  _AddTile(0,0x40100000,0,0x40140000,3);
  _AddTile(0,0x40140000,0,0x40140000,3);
  _AddTile(0,0x40200000,0,0x40100000,3);
  _AddTile(0,0x40220000,0,0x40100000,3);
  _AddTile(0,0x40100000,0,0x40100000,3);
  _AddTile(0,0x40140000,0,0x40100000,3);
  _AddTile(0,0x40200000,0,0x40080000,3);
  _AddTile(0,0x40220000,0,0x40080000,3);
  _AddTile(0,0x40240000,0,0x40080000,3);
  _AddTile(0,0x40080000,0,0x40080000,3);
  _AddTile(0,0x40100000,0,0x40080000,3);
  _AddTile(0,0x40140000,0,0x40080000,3);
  _AddTile(0,0x40100000,0,0x401c0000,2);
  _AddTile(0,0x40140000,0,0x401c0000,2);
  _AddTile(0,0x40180000,0,0x401c0000,2);
  _AddTile(0,0x401c0000,0,0x401c0000,2);
  _AddTile(0,0x40200000,0,0x401c0000,2);
  _AddTile(0,0x40220000,0,0x401c0000,2);
  _AddTile(0,0x40140000,0,0x40180000,2);
  _AddTile(0,0x40180000,0,0x40180000,2);
  _AddTile(0,0x401c0000,0,0x40180000,2);
  _AddTile(0,0x40200000,0,0x40180000,2);
  _AddTile(0,0x40140000,0,0x40140000,2);
  _AddTile(0,0x40180000,0,0x40140000,2);
  _AddTile(0,0x401c0000,0,0x40140000,2);
  _AddTile(0,0x40200000,0,0x40140000,2);
  _AddTile(0,0x40140000,0,0x40100000,2);
  _AddTile(0,0x40180000,0,0x40100000,2);
  _AddTile(0,0x401c0000,0,0x40100000,2);
  _AddTile(0,0x40200000,0,0x40100000,2);
  _AddTile(0,0x40100000,0,0x40080000,2);
  _AddTile(0,0x40140000,0,0x40080000,2);
  _AddTile(0,0x40180000,0,0x40080000,2);
  _AddTile(0,0x401c0000,0,0x40080000,2);
  _AddTile(0,0x40200000,0,0x40080000,2);
  _AddTile(0,0x40220000,0,0x40080000,2);
  _AddTile(0,0x40140000,0,0x40080000,1);
  _AddTile(0,0x40180000,0,0x40080000,1);
  _AddTile(0,0x401c0000,0,0x40080000,1);
  _AddTile(0,0x40200000,0,0x40080000,1);
  _AddTile(0,0x40140000,0,0x401c0000,1);
  _AddTile(0,0x40180000,0,0x401c0000,1);
  _AddTile(0,0x401c0000,0,0x401c0000,1);
  _AddTile(0,0x40200000,0,0x401c0000,1);
  puVar1 = PTR__g_00038024;
  *(undefined4 *)(PTR__g_00038024 + 0x94) = 0xffffffb5;
  *(undefined4 *)(puVar1 + 0x98) = 0xfffffff6;
  *(undefined2 *)(puVar1 + 0x8e) = 8;
  return;
}


// ==== _Layout10 @ 0001dd52 ====

void _Layout10(void)

{
  undefined *puVar1;
  
  _AddTile(0,0x402a0000,0,0x40220000,5);
  _AddTile(0,0x402c0000,0,0x40220000,5);
  _AddTile(0,0x40000000,0,0x40220000,5);
  _AddTile(0,0x40080000,0,0x40220000,5);
  _AddTile(0,0x402c0000,0,0x40200000,5);
  _AddTile(0,0x40000000,0,0x40200000,5);
  _AddTile(0,0x40100000,0,0x40200000,5);
  _AddTile(0,0x40140000,0,0x40200000,5);
  _AddTile(0,0x40180000,0,0x40200000,5);
  _AddTile(0,0x401c0000,0,0x40200000,5);
  _AddTile(0,0x40220000,0,0x40200000,5);
  _AddTile(0,0x40240000,0,0x40200000,5);
  _AddTile(0,0x40260000,0,0x40200000,5);
  _AddTile(0,0x40280000,0,0x40200000,5);
  _AddTile(0,0x40080000,0,0x401c0000,5);
  _AddTile(0,0x40080000,0,0x40180000,5);
  _AddTile(0,0x40080000,0,0x40140000,5);
  _AddTile(0,0x40080000,0,0x40100000,5);
  _AddTile(0,0x40080000,0,0x40080000,5);
  _AddTile(0,0x40000000,0,0x40000000,5);
  _AddTile(0,0x40140000,0,0x40140000,5);
  _AddTile(0,0x40180000,0,0x40180000,5);
  _AddTile(0,0x401c0000,0,0x40180000,5);
  _AddTile(0,0x40200000,0,0x40180000,5);
  _AddTile(0,0x40220000,0,0x40180000,5);
  _AddTile(0,0x40240000,0,0x40180000,5);
  _AddTile(0,0x40180000,0,0x40140000,5);
  _AddTile(0,0x401c0000,0,0x40140000,5);
  _AddTile(0,0x40200000,0,0x40140000,5);
  _AddTile(0,0x40220000,0,0x40140000,5);
  _AddTile(0,0x40240000,0,0x40140000,5);
  _AddTile(0,0x40180000,0,0x40100000,5);
  _AddTile(0,0x401c0000,0,0x40100000,5);
  _AddTile(0,0x40200000,0,0x40100000,5);
  _AddTile(0,0x40220000,0,0x40100000,5);
  _AddTile(0,0x40240000,0,0x40100000,5);
  _AddTile(0,0x40260000,0,0x40140000,5);
  _AddTile(0,0x402a0000,0,0x401c0000,5);
  _AddTile(0,0x402a0000,0,0x40180000,5);
  _AddTile(0,0x402a0000,0,0x40140000,5);
  _AddTile(0,0x402a0000,0,0x40100000,5);
  _AddTile(0,0x402a0000,0,0x40080000,5);
  _AddTile(0,0x402c0000,0,0x40000000,5);
  _AddTile(0,0x40000000,0,0x3ff00000,5);
  _AddTile(0,0x40100000,0,0x40000000,5);
  _AddTile(0,0x40140000,0,0x40000000,5);
  _AddTile(0,0x40180000,0,0x40000000,5);
  _AddTile(0,0x401c0000,0,0x40000000,5);
  _AddTile(0,0x40220000,0,0x40000000,5);
  _AddTile(0,0x40240000,0,0x40000000,5);
  _AddTile(0,0x40260000,0,0x40000000,5);
  _AddTile(0,0x40280000,0,0x40000000,5);
  _AddTile(0,0x40080000,0,0x3ff00000,5);
  _AddTile(0,0x402a0000,0,0x3ff00000,5);
  _AddTile(0,0x402c0000,0,0x3ff00000,5);
  _AddTile(0,0x402a0000,0,0x40220000,4);
  _AddTile(0,0x402c0000,0,0x40220000,4);
  _AddTile(0,0x40000000,0,0x40220000,4);
  _AddTile(0,0x40080000,0,0x40220000,4);
  _AddTile(0,0x402c0000,0,0x40200000,4);
  _AddTile(0,0x40000000,0,0x40200000,4);
  _AddTile(0,0x40100000,0,0x40200000,4);
  _AddTile(0,0x40140000,0,0x40200000,4);
  _AddTile(0,0x40180000,0,0x40200000,4);
  _AddTile(0,0x401c0000,0,0x40200000,4);
  _AddTile(0,0x40220000,0,0x40200000,4);
  _AddTile(0,0x40240000,0,0x40200000,4);
  _AddTile(0,0x40260000,0,0x40200000,4);
  _AddTile(0,0x40280000,0,0x40200000,4);
  _AddTile(0,0x401a0000,0,0x40160000,4);
  _AddTile(0,0x401e0000,0,0x40160000,4);
  _AddTile(0,0x40210000,0,0x40160000,4);
  _AddTile(0,0x40230000,0,0x40160000,4);
  _AddTile(0,0x401a0000,0,0x40120000,4);
  _AddTile(0,0x401e0000,0,0x40120000,4);
  _AddTile(0,0x40210000,0,0x40120000,4);
  _AddTile(0,0x40230000,0,0x40120000,4);
  _AddTile(0,0x40080000,0,0x401c0000,4);
  _AddTile(0,0x40080000,0,0x40180000,4);
  _AddTile(0,0x40080000,0,0x40140000,4);
  _AddTile(0,0x40080000,0,0x40100000,4);
  _AddTile(0,0x40080000,0,0x40080000,4);
  _AddTile(0,0x40000000,0,0x40000000,4);
  _AddTile(0,0x402a0000,0,0x401c0000,4);
  _AddTile(0,0x402a0000,0,0x40180000,4);
  _AddTile(0,0x402a0000,0,0x40140000,4);
  _AddTile(0,0x402a0000,0,0x40100000,4);
  _AddTile(0,0x402a0000,0,0x40080000,4);
  _AddTile(0,0x402c0000,0,0x40000000,4);
  _AddTile(0,0x40000000,0,0x3ff00000,4);
  _AddTile(0,0x40100000,0,0x40000000,4);
  _AddTile(0,0x40140000,0,0x40000000,4);
  _AddTile(0,0x40180000,0,0x40000000,4);
  _AddTile(0,0x401c0000,0,0x40000000,4);
  _AddTile(0,0x40220000,0,0x40000000,4);
  _AddTile(0,0x40240000,0,0x40000000,4);
  _AddTile(0,0x40260000,0,0x40000000,4);
  _AddTile(0,0x40280000,0,0x40000000,4);
  _AddTile(0,0x40080000,0,0x3ff00000,4);
  _AddTile(0,0x402a0000,0,0x3ff00000,4);
  _AddTile(0,0x402c0000,0,0x3ff00000,4);
  _AddTile(0,0x402a0000,0,0x40220000,3);
  _AddTile(0,0x402c0000,0,0x40220000,3);
  _AddTile(0,0x40000000,0,0x40220000,3);
  _AddTile(0,0x40080000,0,0x40220000,3);
  _AddTile(0,0x402c0000,0,0x40200000,3);
  _AddTile(0,0x40000000,0,0x40200000,3);
  _AddTile(0,0x40100000,0,0x40200000,3);
  _AddTile(0,0x40140000,0,0x40200000,3);
  _AddTile(0,0x40180000,0,0x40200000,3);
  _AddTile(0,0x401c0000,0,0x40200000,3);
  _AddTile(0,0x40220000,0,0x40200000,3);
  _AddTile(0,0x40240000,0,0x40200000,3);
  _AddTile(0,0x40260000,0,0x40200000,3);
  _AddTile(0,0x40280000,0,0x40200000,3);
  _AddTile(0,0x40080000,0,0x401c0000,3);
  _AddTile(0,0x40080000,0,0x40180000,3);
  _AddTile(0,0x40080000,0,0x40140000,3);
  _AddTile(0,0x40080000,0,0x40100000,3);
  _AddTile(0,0x40080000,0,0x40080000,3);
  _AddTile(0,0x40000000,0,0x40000000,3);
  _AddTile(0,0x401c0000,0,0x40140000,3);
  _AddTile(0,0x40200000,0,0x40140000,3);
  _AddTile(0,0x40220000,0,0x40140000,3);
  _AddTile(0,0x402a0000,0,0x401c0000,3);
  _AddTile(0,0x402a0000,0,0x40180000,3);
  _AddTile(0,0x402a0000,0,0x40140000,3);
  _AddTile(0,0x402a0000,0,0x40100000,3);
  _AddTile(0,0x402a0000,0,0x40080000,3);
  _AddTile(0,0x402c0000,0,0x40000000,3);
  _AddTile(0,0x40000000,0,0x3ff00000,3);
  _AddTile(0,0x40100000,0,0x40000000,3);
  _AddTile(0,0x40140000,0,0x40000000,3);
  _AddTile(0,0x40180000,0,0x40000000,3);
  _AddTile(0,0x401c0000,0,0x40000000,3);
  _AddTile(0,0x40220000,0,0x40000000,3);
  _AddTile(0,0x40240000,0,0x40000000,3);
  _AddTile(0,0x40260000,0,0x40000000,3);
  _AddTile(0,0x40280000,0,0x40000000,3);
  _AddTile(0,0x40080000,0,0x3ff00000,3);
  _AddTile(0,0x402a0000,0,0x3ff00000,3);
  _AddTile(0,0x402c0000,0,0x3ff00000,3);
  _AddTile(0,0x401e0000,0,0x40140000,2);
  _AddTile(0,0x40210000,0,0x40140000,2);
  puVar1 = PTR__g_00038024;
  *(undefined4 *)(PTR__g_00038024 + 0x94) = 8;
  *(undefined4 *)(puVar1 + 0x98) = 0xfffffff2;
  *(undefined2 *)(puVar1 + 0x8e) = 6;
  return;
}


// ==== _Layout8 @ 0001f63c ====

void _Layout8(void)

{
  undefined *puVar1;
  
  _AddTile(0,0x40220000,0,0x40220000,5);
  _AddTile(0,0x40240000,0,0x40220000,5);
  _AddTile(0,0x40180000,0,0x40220000,5);
  _AddTile(0,0x401c0000,0,0x40220000,5);
  _AddTile(0,0x40080000,0,0x40220000,5);
  _AddTile(0,0x40100000,0,0x40220000,5);
  _AddTile(0,0x40220000,0,0x40200000,5);
  _AddTile(0,0x40240000,0,0x40200000,5);
  _AddTile(0,0x40180000,0,0x40200000,5);
  _AddTile(0,0x401c0000,0,0x40200000,5);
  _AddTile(0,0x40080000,0,0x40200000,5);
  _AddTile(0,0x40100000,0,0x40200000,5);
  _AddTile(0,0x40220000,0,0x40180000,5);
  _AddTile(0,0x40240000,0,0x40180000,5);
  _AddTile(0,0x40080000,0,0x40180000,5);
  _AddTile(0,0x40100000,0,0x40180000,5);
  _AddTile(0,0x40220000,0,0x40140000,5);
  _AddTile(0,0x40240000,0,0x40140000,5);
  _AddTile(0,0x40080000,0,0x40140000,5);
  _AddTile(0,0x40100000,0,0x40140000,5);
  _AddTile(0,0x40220000,0,0x40080000,5);
  _AddTile(0,0x40240000,0,0x40080000,5);
  _AddTile(0,0x40180000,0,0x40080000,5);
  _AddTile(0,0x401c0000,0,0x40080000,5);
  _AddTile(0,0x40080000,0,0x40080000,5);
  _AddTile(0,0x40100000,0,0x40080000,5);
  _AddTile(0,0x40220000,0,0x40000000,5);
  _AddTile(0,0x40240000,0,0x40000000,5);
  _AddTile(0,0x40180000,0,0x40000000,5);
  _AddTile(0,0x401c0000,0,0x40000000,5);
  _AddTile(0,0x40080000,0,0x40000000,5);
  _AddTile(0,0x40100000,0,0x40000000,5);
  _AddTile(0,0x40280000,0,0x40220000,5);
  _AddTile(0,0x40280000,0,0x40200000,5);
  _AddTile(0,0x40280000,0,0x401c0000,5);
  _AddTile(0,0x40280000,0,0x40180000,5);
  _AddTile(0,0x40280000,0,0x40140000,5);
  _AddTile(0,0x40280000,0,0x40100000,5);
  _AddTile(0,0x40280000,0,0x40080000,5);
  _AddTile(0,0x40280000,0,0x40000000,5);
  _AddTile(0,0x40280000,0,0x3ff00000,5);
  _AddTile(0,0x402a0000,0,0x40180000,5);
  _AddTile(0,0x402a0000,0,0x40140000,5);
  _AddTile(0,0x402a0000,0,0x40100000,5);
  _AddTile(0,0,0,0x40180000,5);
  _AddTile(0,0,0,0x40140000,5);
  _AddTile(0,0,0,0x40100000,5);
  _AddTile(0,0x3ff00000,0,0x40220000,5);
  _AddTile(0,0x3ff00000,0,0x40200000,5);
  _AddTile(0,0x3ff00000,0,0x401c0000,5);
  _AddTile(0,0x3ff00000,0,0x40180000,5);
  _AddTile(0,0x3ff00000,0,0x40140000,5);
  _AddTile(0,0x3ff00000,0,0x40100000,5);
  _AddTile(0,0x3ff00000,0,0x40080000,5);
  _AddTile(0,0x3ff00000,0,0x40000000,5);
  _AddTile(0,0x3ff00000,0,0x3ff00000,5);
  _AddTile(0,0x40230000,0,0x40210000,4);
  _AddTile(0,0x401a0000,0,0x40210000,4);
  _AddTile(0,0x400c0000,0,0x40210000,4);
  _AddTile(0,0x40230000,0,0x40160000,4);
  _AddTile(0,0x400c0000,0,0x40160000,4);
  _AddTile(0,0x40230000,0,0x40040000,4);
  _AddTile(0,0x401a0000,0,0x40040000,4);
  _AddTile(0,0x400c0000,0,0x40040000,4);
  _AddTile(0,0x40230000,0,0x40210000,3);
  _AddTile(0,0x401a0000,0,0x40210000,3);
  _AddTile(0,0x400c0000,0,0x40210000,3);
  _AddTile(0,0x40230000,0,0x40160000,3);
  _AddTile(0,0x400c0000,0,0x40160000,3);
  _AddTile(0,0x40230000,0,0x40040000,3);
  _AddTile(0,0x401a0000,0,0x40040000,3);
  _AddTile(0,0x400c0000,0,0x40040000,3);
  _AddTile(0,0x40220000,0,0x40220000,2);
  _AddTile(0,0x40240000,0,0x40220000,2);
  _AddTile(0,0x40180000,0,0x40220000,2);
  _AddTile(0,0x401c0000,0,0x40220000,2);
  _AddTile(0,0x40080000,0,0x40220000,2);
  _AddTile(0,0x40100000,0,0x40220000,2);
  _AddTile(0,0x40220000,0,0x40200000,2);
  _AddTile(0,0x40240000,0,0x40200000,2);
  _AddTile(0,0x40180000,0,0x40200000,2);
  _AddTile(0,0x401c0000,0,0x40200000,2);
  _AddTile(0,0x40080000,0,0x40200000,2);
  _AddTile(0,0x40100000,0,0x40200000,2);
  _AddTile(0,0x40220000,0,0x40180000,2);
  _AddTile(0,0x40240000,0,0x40180000,2);
  _AddTile(0,0x40080000,0,0x40180000,2);
  _AddTile(0,0x40100000,0,0x40180000,2);
  _AddTile(0,0x40220000,0,0x40140000,2);
  _AddTile(0,0x40240000,0,0x40140000,2);
  _AddTile(0,0x40080000,0,0x40140000,2);
  _AddTile(0,0x40100000,0,0x40140000,2);
  _AddTile(0,0x40220000,0,0x40080000,2);
  _AddTile(0,0x40240000,0,0x40080000,2);
  _AddTile(0,0x40180000,0,0x40080000,2);
  _AddTile(0,0x401c0000,0,0x40080000,2);
  _AddTile(0,0x40080000,0,0x40080000,2);
  _AddTile(0,0x40100000,0,0x40080000,2);
  _AddTile(0,0x40220000,0,0x40000000,2);
  _AddTile(0,0x40240000,0,0x40000000,2);
  _AddTile(0,0x40180000,0,0x40000000,2);
  _AddTile(0,0x401c0000,0,0x40000000,2);
  _AddTile(0,0x40080000,0,0x40000000,2);
  _AddTile(0,0x40100000,0,0x40000000,2);
  _AddTile(0,0x400c0000,0,0x40210000,1);
  _AddTile(0,0x40120000,0,0x40210000,1);
  _AddTile(0,0x40160000,0,0x40210000,1);
  _AddTile(0,0x401a0000,0,0x40210000,1);
  _AddTile(0,0x401e0000,0,0x40210000,1);
  _AddTile(0,0x40210000,0,0x40210000,1);
  _AddTile(0,0x40230000,0,0x40210000,1);
  _AddTile(0,0x400c0000,0,0x401e0000,1);
  _AddTile(0,0x40120000,0,0x401e0000,1);
  _AddTile(0,0x40160000,0,0x401e0000,1);
  _AddTile(0,0x401a0000,0,0x401e0000,1);
  _AddTile(0,0x401e0000,0,0x401e0000,1);
  _AddTile(0,0x40210000,0,0x401e0000,1);
  _AddTile(0,0x40230000,0,0x401e0000,1);
  _AddTile(0,0x400c0000,0,0x401a0000,1);
  _AddTile(0,0x40120000,0,0x401a0000,1);
  _AddTile(0,0x40210000,0,0x401a0000,1);
  _AddTile(0,0x40230000,0,0x401a0000,1);
  _AddTile(0,0x400c0000,0,0x40160000,1);
  _AddTile(0,0x40120000,0,0x40160000,1);
  _AddTile(0,0x40210000,0,0x40160000,1);
  _AddTile(0,0x40230000,0,0x40160000,1);
  _AddTile(0,0x400c0000,0,0x40120000,1);
  _AddTile(0,0x40120000,0,0x40120000,1);
  _AddTile(0,0x40210000,0,0x40120000,1);
  _AddTile(0,0x40230000,0,0x40120000,1);
  _AddTile(0,0x400c0000,0,0x400c0000,1);
  _AddTile(0,0x40120000,0,0x400c0000,1);
  _AddTile(0,0x40160000,0,0x400c0000,1);
  _AddTile(0,0x401a0000,0,0x400c0000,1);
  _AddTile(0,0x401e0000,0,0x400c0000,1);
  _AddTile(0,0x40210000,0,0x400c0000,1);
  _AddTile(0,0x40230000,0,0x400c0000,1);
  _AddTile(0,0x400c0000,0,0x40040000,1);
  _AddTile(0,0x40120000,0,0x40040000,1);
  _AddTile(0,0x40160000,0,0x40040000,1);
  _AddTile(0,0x401a0000,0,0x40040000,1);
  _AddTile(0,0x401e0000,0,0x40040000,1);
  _AddTile(0,0x40210000,0,0x40040000,1);
  _AddTile(0,0x40230000,0,0x40040000,1);
  puVar1 = PTR__g_00038024;
  *(undefined4 *)(PTR__g_00038024 + 0x94) = 0xffffffbf;
  *(undefined4 *)(puVar1 + 0x98) = 0xffffffec;
  *(undefined2 *)(puVar1 + 0x8e) = 0xb;
  return;
}


// ==== _Layout6 @ 00020f26 ====

void _Layout6(void)

{
  undefined *puVar1;
  
  _AddTile(0,0x40280000,0,0x401e0000,7);
  _AddTile(0,0x40280000,0,0x401a0000,7);
  _AddTile(0,0x402a0000,0,0x40200000,7);
  _AddTile(0,0x401c0000,0,0x40200000,7);
  _AddTile(0,0x40200000,0,0x40210000,7);
  _AddTile(0,0x40000000,0,0x401c0000,7);
  _AddTile(0,0x40000000,0,0x40180000,7);
  _AddTile(0,0x40080000,0,0x40200000,7);
  _AddTile(0,0x40080000,0,0x401c0000,7);
  _AddTile(0,0x40080000,0,0x40180000,7);
  _AddTile(0,0x40100000,0,0x401e0000,7);
  _AddTile(0,0x40200000,0,0x401e0000,7);
  _AddTile(0,0x40220000,0,0x40200000,7);
  _AddTile(0,0x40100000,0,0x401a0000,7);
  _AddTile(0,0x402a0000,0,0x401c0000,7);
  _AddTile(0,0x40200000,0,0x401a0000,7);
  _AddTile(0,0x401c0000,0,0x40000000,7);
  _AddTile(0,0x402c0000,0,0x401c0000,7);
  _AddTile(0,0x402a0000,0,0x40180000,7);
  _AddTile(0,0x40000000,0,0x40140000,7);
  _AddTile(0,0x40080000,0,0x40140000,7);
  _AddTile(0,0x40100000,0,0x40140000,7);
  _AddTile(0,0x40140000,0,0x40140000,7);
  _AddTile(0,0x40180000,0,0x40140000,7);
  _AddTile(0,0x40200000,0,0x40160000,7);
  _AddTile(0,0x40000000,0,0x40100000,7);
  _AddTile(0,0x40080000,0,0x40100000,7);
  _AddTile(0,0x40200000,0,0x40120000,7);
  _AddTile(0,0x40240000,0,0x40140000,7);
  _AddTile(0,0x40260000,0,0x40140000,7);
  _AddTile(0,0x40280000,0,0x40140000,7);
  _AddTile(0,0x402a0000,0,0x40140000,7);
  _AddTile(0,0x402c0000,0,0x40140000,7);
  _AddTile(0,0x40180000,0,0x401a0000,7);
  _AddTile(0,0x40240000,0,0x401a0000,7);
  _AddTile(0,0x40180000,0,0x400c0000,7);
  _AddTile(0,0x40240000,0,0x400c0000,7);
  _AddTile(0,0x40280000,0,0x400c0000,7);
  _AddTile(0,0x40200000,0,0x400c0000,7);
  _AddTile(0,0x40200000,0,0x40040000,7);
  _AddTile(0,0x402c0000,0,0x40180000,7);
  _AddTile(0,0x40280000,0,0x40040000,7);
  _AddTile(0,0x402a0000,0,0x40100000,7);
  _AddTile(0,0x402a0000,0,0x40080000,7);
  _AddTile(0,0x402a0000,0,0x40000000,7);
  _AddTile(0,0x402c0000,0,0x40100000,7);
  _AddTile(0,0x402c0000,0,0x40080000,7);
  _AddTile(0,0x40000000,0,0x40080000,7);
  _AddTile(0,0x40080000,0,0x40080000,7);
  _AddTile(0,0x40080000,0,0x40000000,7);
  _AddTile(0,0x40200000,0,0x3ff80000,7);
  _AddTile(0,0x40100000,0,0x400c0000,7);
  _AddTile(0,0x40100000,0,0x40040000,7);
  _AddTile(0,0x40220000,0,0x40000000,7);
  _AddTile(0,0x40280000,0,0x401a0000,6);
  _AddTile(0,0x401c0000,0,0x40200000,6);
  _AddTile(0,0x40200000,0,0x40210000,6);
  _AddTile(0,0x40000000,0,0x401c0000,6);
  _AddTile(0,0x40000000,0,0x40180000,6);
  _AddTile(0,0x40080000,0,0x401c0000,6);
  _AddTile(0,0x40080000,0,0x40180000,6);
  _AddTile(0,0x40200000,0,0x401e0000,6);
  _AddTile(0,0x40220000,0,0x40200000,6);
  _AddTile(0,0x40100000,0,0x401a0000,6);
  _AddTile(0,0x402a0000,0,0x401c0000,6);
  _AddTile(0,0x40200000,0,0x401a0000,6);
  _AddTile(0,0x401c0000,0,0x40000000,6);
  _AddTile(0,0x402c0000,0,0x401c0000,6);
  _AddTile(0,0x402a0000,0,0x40180000,6);
  _AddTile(0,0x40080000,0,0x40140000,6);
  _AddTile(0,0x40100000,0,0x40140000,6);
  _AddTile(0,0x40140000,0,0x40140000,6);
  _AddTile(0,0x40180000,0,0x40140000,6);
  _AddTile(0,0x40200000,0,0x40160000,6);
  _AddTile(0,0x40000000,0,0x40100000,6);
  _AddTile(0,0x40080000,0,0x40100000,6);
  _AddTile(0,0x40200000,0,0x40120000,6);
  _AddTile(0,0x40240000,0,0x40140000,6);
  _AddTile(0,0x40260000,0,0x40140000,6);
  _AddTile(0,0x40280000,0,0x40140000,6);
  _AddTile(0,0x402a0000,0,0x40140000,6);
  _AddTile(0,0x40280000,0,0x400c0000,6);
  _AddTile(0,0x40200000,0,0x400c0000,6);
  _AddTile(0,0x40200000,0,0x40040000,6);
  _AddTile(0,0x402c0000,0,0x40180000,6);
  _AddTile(0,0x40280000,0,0x40040000,6);
  _AddTile(0,0x402a0000,0,0x40100000,6);
  _AddTile(0,0x402a0000,0,0x40080000,6);
  _AddTile(0,0x402a0000,0,0x40000000,6);
  _AddTile(0,0x402c0000,0,0x40100000,6);
  _AddTile(0,0x402c0000,0,0x40080000,6);
  _AddTile(0,0x40000000,0,0x40080000,6);
  _AddTile(0,0x40080000,0,0x40080000,6);
  _AddTile(0,0x40200000,0,0x3ff80000,6);
  _AddTile(0,0x40100000,0,0x400c0000,6);
  _AddTile(0,0x40100000,0,0x40040000,6);
  _AddTile(0,0x40220000,0,0x40000000,6);
  _AddTile(0,0x401c0000,0,0x40200000,5);
  _AddTile(0,0x40200000,0,0x40200000,5);
  _AddTile(0,0x40000000,0,0x401c0000,5);
  _AddTile(0,0x40000000,0,0x40180000,5);
  _AddTile(0,0x40080000,0,0x40180000,5);
  _AddTile(0,0x40200000,0,0x401c0000,5);
  _AddTile(0,0x40220000,0,0x40200000,5);
  _AddTile(0,0x40200000,0,0x40180000,5);
  _AddTile(0,0x401c0000,0,0x40000000,5);
  _AddTile(0,0x402a0000,0,0x40180000,5);
  _AddTile(0,0x400c0000,0,0x40140000,5);
  _AddTile(0,0x40120000,0,0x40140000,5);
  _AddTile(0,0x40160000,0,0x40140000,5);
  _AddTile(0,0x401e0000,0,0x40140000,5);
  _AddTile(0,0x40210000,0,0x40140000,5);
  _AddTile(0,0x40250000,0,0x40140000,5);
  _AddTile(0,0x40270000,0,0x40140000,5);
  _AddTile(0,0x40290000,0,0x40140000,5);
  _AddTile(0,0x40200000,0,0x40100000,5);
  _AddTile(0,0x402c0000,0,0x401c0000,5);
  _AddTile(0,0x40000000,0,0x40100000,5);
  _AddTile(0,0x40080000,0,0x40100000,5);
  _AddTile(0,0x40280000,0,0x400c0000,5);
  _AddTile(0,0x40200000,0,0x40080000,5);
  _AddTile(0,0x40200000,0,0x40000000,5);
  _AddTile(0,0x40220000,0,0x40000000,5);
  _AddTile(0,0x402c0000,0,0x40180000,5);
  _AddTile(0,0x402a0000,0,0x40100000,5);
  _AddTile(0,0x402c0000,0,0x40100000,5);
  _AddTile(0,0x402c0000,0,0x40080000,5);
  _AddTile(0,0x40000000,0,0x40080000,5);
  _AddTile(0,0x40100000,0,0x400c0000,5);
  _AddTile(0,0x40140000,0,0x40140000,4);
  _AddTile(0,0x40180000,0,0x40140000,4);
  _AddTile(0,0x401c0000,0,0x40140000,4);
  _AddTile(0,0x40200000,0,0x40140000,4);
  _AddTile(0,0x40220000,0,0x40140000,4);
  _AddTile(0,0x40240000,0,0x40140000,4);
  _AddTile(0,0x40260000,0,0x40140000,4);
  _AddTile(0,0x40160000,0,0x40140000,3);
  _AddTile(0,0x401a0000,0,0x40140000,3);
  _AddTile(0,0x401e0000,0,0x40140000,3);
  _AddTile(0,0x40210000,0,0x40140000,3);
  _AddTile(0,0x40230000,0,0x40140000,3);
  _AddTile(0,0x40250000,0,0x40140000,3);
  _AddTile(0,0x401a0000,0,0x40140000,2);
  _AddTile(0,0x40230000,0,0x40140000,2);
  puVar1 = PTR__g_00038024;
  *(undefined4 *)(PTR__g_00038024 + 0x94) = 0xfffffff6;
  *(undefined4 *)(puVar1 + 0x98) = 0xffffffe7;
  *(undefined2 *)(puVar1 + 0x8e) = 10;
  return;
}


// ==== _Layout5 @ 00022810 ====

void _Layout5(void)

{
  undefined *puVar1;
  
  _AddTile(0,0x3ff00000,0,0x40080000,7);
  _AddTile(0,0x3ff00000,0,0x40000000,7);
  _AddTile(0,0x40000000,0,0x40040000,7);
  _AddTile(0,0x40080000,0,0x40080000,7);
  _AddTile(0,0x40080000,0,0x40000000,7);
  _AddTile(0,0x402a0000,0,0x40080000,7);
  _AddTile(0,0x402a0000,0,0x40000000,7);
  _AddTile(0,0x402c0000,0,0x40040000,7);
  _AddTile(0,0x402e0000,0,0x40080000,7);
  _AddTile(0,0x402e0000,0,0x40000000,7);
  _AddTile(0,0x3ff80000,0,0x40160000,7);
  _AddTile(0,0x40040000,0,0x40180000,7);
  _AddTile(0,0x40040000,0,0x40140000,7);
  _AddTile(0,0x400c0000,0,0x401a0000,7);
  _AddTile(0,0x400c0000,0,0x40160000,7);
  _AddTile(0,0x400c0000,0,0x40120000,7);
  _AddTile(0,0x40120000,0,0x401c0000,7);
  _AddTile(0,0x40120000,0,0x40180000,7);
  _AddTile(0,0x40120000,0,0x40140000,7);
  _AddTile(0,0x40120000,0,0x40100000,7);
  _AddTile(0,0x40160000,0,0x401e0000,7);
  _AddTile(0,0x40160000,0,0x401a0000,7);
  _AddTile(0,0x40160000,0,0x40160000,7);
  _AddTile(0,0x40160000,0,0x40120000,7);
  _AddTile(0,0x40160000,0,0x400c0000,7);
  _AddTile(0,0x401c0000,0,0x40200000,7);
  _AddTile(0,0x401c0000,0,0x401c0000,7);
  _AddTile(0,0x401c0000,0,0x40100000,7);
  _AddTile(0,0x401c0000,0,0x40080000,7);
  _AddTile(0,0x40200000,0,0x40210000,7);
  _AddTile(0,0x40200000,0,0x401e0000,7);
  _AddTile(0,0x40200000,0,0x400c0000,7);
  _AddTile(0,0x40200000,0,0x40040000,7);
  _AddTile(0,0x40220000,0,0x40200000,7);
  _AddTile(0,0x40220000,0,0x401c0000,7);
  _AddTile(0,0x40220000,0,0x40100000,7);
  _AddTile(0,0x40220000,0,0x40080000,7);
  _AddTile(0,0x40250000,0,0x401e0000,7);
  _AddTile(0,0x40250000,0,0x401a0000,7);
  _AddTile(0,0x40250000,0,0x40160000,7);
  _AddTile(0,0x40250000,0,0x40120000,7);
  _AddTile(0,0x40250000,0,0x400c0000,7);
  _AddTile(0,0x40270000,0,0x401c0000,7);
  _AddTile(0,0x40270000,0,0x40180000,7);
  _AddTile(0,0x40270000,0,0x40140000,7);
  _AddTile(0,0x40270000,0,0x40100000,7);
  _AddTile(0,0x40290000,0,0x401a0000,7);
  _AddTile(0,0x40290000,0,0x40160000,7);
  _AddTile(0,0x40290000,0,0x40120000,7);
  _AddTile(0,0x402b0000,0,0x40180000,7);
  _AddTile(0,0x402b0000,0,0x40140000,7);
  _AddTile(0,0x402d0000,0,0x40160000,7);
  _AddTile(0,0x402c0000,0,0x40220000,7);
  _AddTile(0,0x402c0000,0,0x40200000,7);
  _AddTile(0,0x402e0000,0,0x40210000,7);
  _AddTile(0,0x3ff00000,0,0x40210000,7);
  _AddTile(0,0x40000000,0,0x40220000,7);
  _AddTile(0,0x40000000,0,0x40200000,7);
  _AddTile(0,0x402a0000,0,0x40080000,6);
  _AddTile(0,0x402a0000,0,0x40000000,6);
  _AddTile(0,0x402c0000,0,0x40040000,6);
  _AddTile(0,0x402e0000,0,0x40080000,6);
  _AddTile(0,0x402e0000,0,0x40000000,6);
  _AddTile(0,0x3ff00000,0,0x40080000,6);
  _AddTile(0,0x3ff00000,0,0x40000000,6);
  _AddTile(0,0x40000000,0,0x40040000,6);
  _AddTile(0,0x40080000,0,0x40080000,6);
  _AddTile(0,0x40080000,0,0x40000000,6);
  _AddTile(0,0x40040000,0,0x40160000,6);
  _AddTile(0,0x400c0000,0,0x40180000,6);
  _AddTile(0,0x400c0000,0,0x40140000,6);
  _AddTile(0,0x40120000,0,0x401a0000,6);
  _AddTile(0,0x40120000,0,0x40160000,6);
  _AddTile(0,0x40120000,0,0x40120000,6);
  _AddTile(0,0x40160000,0,0x401c0000,6);
  _AddTile(0,0x40160000,0,0x40180000,6);
  _AddTile(0,0x40160000,0,0x40140000,6);
  _AddTile(0,0x40160000,0,0x40100000,6);
  _AddTile(0,0x401c0000,0,0x40200000,6);
  _AddTile(0,0x401c0000,0,0x401c0000,6);
  _AddTile(0,0x401c0000,0,0x40100000,6);
  _AddTile(0,0x401c0000,0,0x40080000,6);
  _AddTile(0,0x40200000,0,0x40210000,6);
  _AddTile(0,0x40200000,0,0x401e0000,6);
  _AddTile(0,0x40200000,0,0x400c0000,6);
  _AddTile(0,0x40200000,0,0x40040000,6);
  _AddTile(0,0x40220000,0,0x40200000,6);
  _AddTile(0,0x40220000,0,0x401c0000,6);
  _AddTile(0,0x40220000,0,0x40100000,6);
  _AddTile(0,0x40220000,0,0x40080000,6);
  _AddTile(0,0x40250000,0,0x401c0000,6);
  _AddTile(0,0x40250000,0,0x40180000,6);
  _AddTile(0,0x40250000,0,0x40140000,6);
  _AddTile(0,0x40250000,0,0x40100000,6);
  _AddTile(0,0x40270000,0,0x401a0000,6);
  _AddTile(0,0x40270000,0,0x40160000,6);
  _AddTile(0,0x40270000,0,0x40120000,6);
  _AddTile(0,0x40290000,0,0x40180000,6);
  _AddTile(0,0x40290000,0,0x40140000,6);
  _AddTile(0,0x402b0000,0,0x40160000,6);
  _AddTile(0,0x402c0000,0,0x40220000,6);
  _AddTile(0,0x402c0000,0,0x40200000,6);
  _AddTile(0,0x402e0000,0,0x40210000,6);
  _AddTile(0,0x3ff00000,0,0x40210000,6);
  _AddTile(0,0x40000000,0,0x40220000,6);
  _AddTile(0,0x40000000,0,0x40200000,6);
  _AddTile(0,0x400c0000,0,0x40160000,5);
  _AddTile(0,0x40120000,0,0x40180000,5);
  _AddTile(0,0x40120000,0,0x40140000,5);
  _AddTile(0,0x40160000,0,0x401a0000,5);
  _AddTile(0,0x40160000,0,0x40160000,5);
  _AddTile(0,0x40160000,0,0x40120000,5);
  _AddTile(0,0x401c0000,0,0x40200000,5);
  _AddTile(0,0x401c0000,0,0x401c0000,5);
  _AddTile(0,0x401c0000,0,0x40100000,5);
  _AddTile(0,0x401c0000,0,0x40080000,5);
  _AddTile(0,0x40200000,0,0x40210000,5);
  _AddTile(0,0x40200000,0,0x401e0000,5);
  _AddTile(0,0x40200000,0,0x400c0000,5);
  _AddTile(0,0x40200000,0,0x40040000,5);
  _AddTile(0,0x40220000,0,0x40200000,5);
  _AddTile(0,0x40220000,0,0x401c0000,5);
  _AddTile(0,0x40220000,0,0x40100000,5);
  _AddTile(0,0x40220000,0,0x40080000,5);
  _AddTile(0,0x40250000,0,0x401a0000,5);
  _AddTile(0,0x40250000,0,0x40160000,5);
  _AddTile(0,0x40250000,0,0x40120000,5);
  _AddTile(0,0x40270000,0,0x40180000,5);
  _AddTile(0,0x40270000,0,0x40140000,5);
  _AddTile(0,0x40290000,0,0x40160000,5);
  _AddTile(0,0x40120000,0,0x40160000,4);
  _AddTile(0,0x40160000,0,0x40180000,4);
  _AddTile(0,0x40160000,0,0x40140000,4);
  _AddTile(0,0x40200000,0,0x40040000,4);
  _AddTile(0,0x40200000,0,0x40210000,4);
  _AddTile(0,0x40220000,0,0x401c0000,4);
  _AddTile(0,0x401c0000,0,0x401c0000,4);
  _AddTile(0,0x40220000,0,0x40100000,4);
  _AddTile(0,0x401c0000,0,0x40100000,4);
  _AddTile(0,0x40250000,0,0x40180000,4);
  _AddTile(0,0x40250000,0,0x40140000,4);
  _AddTile(0,0x40270000,0,0x40160000,4);
  _AddTile(0,0x40250000,0,0x40160000,3);
  _AddTile(0,0x40160000,0,0x40160000,3);
  puVar1 = PTR__g_00038024;
  *(undefined4 *)(PTR__g_00038024 + 0x94) = 0;
  *(undefined4 *)(puVar1 + 0x98) = 0xffffffc9;
  *(undefined2 *)(puVar1 + 0x8e) = 5;
  return;
}


// ==== _Layout4 @ 000240fa ====

void _Layout4(void)

{
  undefined *puVar1;
  
  _AddTile(0,0x40280000,0,0x40220000,6);
  _AddTile(0,0x402a0000,0,0x40220000,6);
  _AddTile(0,0x402c0000,0,0x40220000,6);
  _AddTile(0,0x40220000,0,0x40220000,6);
  _AddTile(0,0x40100000,0,0x40220000,6);
  _AddTile(0,0x40140000,0,0x40220000,6);
  _AddTile(0,0x40180000,0,0x40220000,6);
  _AddTile(0,0x40080000,0,0x40200000,6);
  _AddTile(0,0x40100000,0,0x40200000,6);
  _AddTile(0,0x40140000,0,0x40200000,6);
  _AddTile(0,0x40100000,0,0x401c0000,6);
  _AddTile(0,0x40140000,0,0x401c0000,6);
  _AddTile(0,0x40180000,0,0x401c0000,6);
  _AddTile(0,0x401c0000,0,0x401e0000,6);
  _AddTile(0,0x402a0000,0,0x40200000,6);
  _AddTile(0,0x402c0000,0,0x40200000,6);
  _AddTile(0,0x402e0000,0,0x40200000,6);
  _AddTile(0,0x40200000,0,0x40200000,6);
  _AddTile(0,0x40220000,0,0x40200000,6);
  _AddTile(0,0x40240000,0,0x40200000,6);
  _AddTile(0,0x40260000,0,0x401e0000,6);
  _AddTile(0,0x40280000,0,0x401c0000,6);
  _AddTile(0,0x402a0000,0,0x401c0000,6);
  _AddTile(0,0x402c0000,0,0x401c0000,6);
  _AddTile(0,0x40220000,0,0x401c0000,6);
  _AddTile(0,0x40200000,0,0x40180000,6);
  _AddTile(0,0x40220000,0,0x40180000,6);
  _AddTile(0,0x40240000,0,0x40180000,6);
  _AddTile(0,0x40220000,0,0x40140000,6);
  _AddTile(0,0x40280000,0,0x40120000,6);
  _AddTile(0,0x40180000,0,0x40120000,6);
  _AddTile(0,0x40080000,0,0x40100000,6);
  _AddTile(0,0x40080000,0,0x40080000,6);
  _AddTile(0,0x40100000,0,0x40120000,6);
  _AddTile(0,0x40140000,0,0x400c0000,6);
  _AddTile(0,0x40180000,0,0x400c0000,6);
  _AddTile(0,0x401c0000,0,0x400c0000,6);
  _AddTile(0,0x40200000,0,0x400c0000,6);
  _AddTile(0,0x40220000,0,0x40100000,6);
  _AddTile(0,0x40220000,0,0x40080000,6);
  _AddTile(0,0x40240000,0,0x400c0000,6);
  _AddTile(0,0x40260000,0,0x400c0000,6);
  _AddTile(0,0x40280000,0,0x400c0000,6);
  _AddTile(0,0x402a0000,0,0x400c0000,6);
  _AddTile(0,0x402c0000,0,0x40040000,6);
  _AddTile(0,0x402c0000,0,0x40120000,6);
  _AddTile(0,0x402e0000,0,0x40100000,6);
  _AddTile(0,0x402e0000,0,0x40080000,6);
  _AddTile(0,0x40100000,0,0x40040000,6);
  _AddTile(0,0x401c0000,0,0x40040000,6);
  _AddTile(0,0x40260000,0,0x40040000,6);
  _AddTile(0,0x40280000,0,0x40220000,5);
  _AddTile(0,0x402a0000,0,0x40220000,5);
  _AddTile(0,0x40220000,0,0x40220000,5);
  _AddTile(0,0x40140000,0,0x40220000,5);
  _AddTile(0,0x40180000,0,0x40220000,5);
  _AddTile(0,0x40100000,0,0x40200000,5);
  _AddTile(0,0x40140000,0,0x40200000,5);
  _AddTile(0,0x40140000,0,0x401c0000,5);
  _AddTile(0,0x40180000,0,0x401c0000,5);
  _AddTile(0,0x401c0000,0,0x401e0000,5);
  _AddTile(0,0x402a0000,0,0x40200000,5);
  _AddTile(0,0x402c0000,0,0x40200000,5);
  _AddTile(0,0x40200000,0,0x40200000,5);
  _AddTile(0,0x40220000,0,0x40200000,5);
  _AddTile(0,0x40240000,0,0x40200000,5);
  _AddTile(0,0x40260000,0,0x401e0000,5);
  _AddTile(0,0x40280000,0,0x401c0000,5);
  _AddTile(0,0x402a0000,0,0x401c0000,5);
  _AddTile(0,0x40220000,0,0x401c0000,5);
  _AddTile(0,0x40220000,0,0x40180000,5);
  _AddTile(0,0x40220000,0,0x40140000,5);
  _AddTile(0,0x40280000,0,0x40120000,5);
  _AddTile(0,0x40180000,0,0x40120000,5);
  _AddTile(0,0x40080000,0,0x40100000,5);
  _AddTile(0,0x40080000,0,0x40080000,5);
  _AddTile(0,0x40100000,0,0x40120000,5);
  _AddTile(0,0x40140000,0,0x400c0000,5);
  _AddTile(0,0x40180000,0,0x400c0000,5);
  _AddTile(0,0x401c0000,0,0x400c0000,5);
  _AddTile(0,0x40200000,0,0x400c0000,5);
  _AddTile(0,0x40220000,0,0x40100000,5);
  _AddTile(0,0x40220000,0,0x40080000,5);
  _AddTile(0,0x40240000,0,0x400c0000,5);
  _AddTile(0,0x40260000,0,0x400c0000,5);
  _AddTile(0,0x40280000,0,0x400c0000,5);
  _AddTile(0,0x402a0000,0,0x400c0000,5);
  _AddTile(0,0x402c0000,0,0x40040000,5);
  _AddTile(0,0x402c0000,0,0x40120000,5);
  _AddTile(0,0x402e0000,0,0x40100000,5);
  _AddTile(0,0x402e0000,0,0x40080000,5);
  _AddTile(0,0x40100000,0,0x40040000,5);
  _AddTile(0,0x401c0000,0,0x40040000,5);
  _AddTile(0,0x40260000,0,0x40040000,5);
  _AddTile(0,0x40280000,0,0x40220000,4);
  _AddTile(0,0x40220000,0,0x40220000,4);
  _AddTile(0,0x40180000,0,0x40220000,4);
  _AddTile(0,0x40140000,0,0x40200000,4);
  _AddTile(0,0x40180000,0,0x401c0000,4);
  _AddTile(0,0x401c0000,0,0x401e0000,4);
  _AddTile(0,0x402a0000,0,0x40200000,4);
  _AddTile(0,0x40200000,0,0x40200000,4);
  _AddTile(0,0x40220000,0,0x40200000,4);
  _AddTile(0,0x40240000,0,0x40200000,4);
  _AddTile(0,0x40260000,0,0x401e0000,4);
  _AddTile(0,0x40280000,0,0x401c0000,4);
  _AddTile(0,0x40220000,0,0x401c0000,4);
  _AddTile(0,0x40220000,0,0x40180000,4);
  _AddTile(0,0x40220000,0,0x40140000,4);
  _AddTile(0,0x40280000,0,0x40120000,4);
  _AddTile(0,0x40180000,0,0x40120000,4);
  _AddTile(0,0x40080000,0,0x400c0000,4);
  _AddTile(0,0x40100000,0,0x40120000,4);
  _AddTile(0,0x40140000,0,0x400c0000,4);
  _AddTile(0,0x401c0000,0,0x400c0000,4);
  _AddTile(0,0x40200000,0,0x400c0000,4);
  _AddTile(0,0x40220000,0,0x40100000,4);
  _AddTile(0,0x40220000,0,0x40080000,4);
  _AddTile(0,0x40240000,0,0x400c0000,4);
  _AddTile(0,0x40260000,0,0x400c0000,4);
  _AddTile(0,0x402a0000,0,0x400c0000,4);
  _AddTile(0,0x402c0000,0,0x40040000,4);
  _AddTile(0,0x402c0000,0,0x40120000,4);
  _AddTile(0,0x402e0000,0,0x400c0000,4);
  _AddTile(0,0x40100000,0,0x40040000,4);
  _AddTile(0,0x401c0000,0,0x40040000,4);
  _AddTile(0,0x40260000,0,0x40040000,4);
  _AddTile(0,0x401c0000,0,0x401e0000,3);
  _AddTile(0,0x401c0000,0,0x400c0000,3);
  _AddTile(0,0x40200000,0,0x400c0000,3);
  _AddTile(0,0x40200000,0,0x40200000,3);
  _AddTile(0,0x40220000,0,0x40210000,3);
  _AddTile(0,0x40220000,0,0x401e0000,3);
  _AddTile(0,0x40220000,0,0x401a0000,3);
  _AddTile(0,0x40220000,0,0x40160000,3);
  _AddTile(0,0x40220000,0,0x40120000,3);
  _AddTile(0,0x40240000,0,0x40200000,3);
  _AddTile(0,0x40260000,0,0x401e0000,3);
  _AddTile(0,0x40220000,0,0x400c0000,3);
  _AddTile(0,0x40240000,0,0x400c0000,3);
  _AddTile(0,0x40260000,0,0x400c0000,3);
  _AddTile(0,0x401c0000,0,0x40040000,3);
  _AddTile(0,0x40260000,0,0x40040000,3);
  _AddTile(0,0x40220000,0,0x401a0000,2);
  puVar1 = PTR__g_00038024;
  *(undefined4 *)(PTR__g_00038024 + 0x94) = 0x2c;
  *(undefined4 *)(puVar1 + 0x98) = 0xffffffc4;
  *(undefined2 *)(puVar1 + 0x8e) = 4;
  return;
}


// ==== _Layout2 @ 000259e4 ====

void _Layout2(void)

{
  undefined *puVar1;
  
  _AddTile(0,0x40200000,0,0x40220000,6);
  _AddTile(0,0x40180000,0,0x401e0000,6);
  _AddTile(0,0x40280000,0,0x401e0000,6);
  _AddTile(0,0x401c0000,0,0x40200000,6);
  _AddTile(0,0x40200000,0,0x40200000,6);
  _AddTile(0,0x40220000,0,0x40200000,6);
  _AddTile(0,0x40240000,0,0x401e0000,6);
  _AddTile(0,0x402a0000,0,0x401c0000,6);
  _AddTile(0,0x40200000,0,0x401c0000,6);
  _AddTile(0,0x40080000,0,0x401c0000,6);
  _AddTile(0,0x40100000,0,0x401e0000,6);
  _AddTile(0,0x3ff00000,0,0x401a0000,6);
  _AddTile(0,0x3ff00000,0,0x40160000,6);
  _AddTile(0,0x40000000,0,0x40160000,6);
  _AddTile(0,0x40100000,0,0x40160000,6);
  _AddTile(0,0x40140000,0,0x40160000,6);
  _AddTile(0,0x40260000,0,0x40160000,6);
  _AddTile(0,0x40280000,0,0x40160000,6);
  _AddTile(0,0x402e0000,0,0x401a0000,6);
  _AddTile(0,0x402c0000,0,0x40160000,6);
  _AddTile(0,0x402e0000,0,0x40160000,6);
  _AddTile(0,0x401c0000,0,0x40180000,6);
  _AddTile(0,0x40200000,0,0x40180000,6);
  _AddTile(0,0x40220000,0,0x40180000,6);
  _AddTile(0,0x401e0000,0,0x40140000,6);
  _AddTile(0,0x40210000,0,0x40140000,6);
  _AddTile(0,0x40280000,0,0x40100000,6);
  _AddTile(0,0x402e0000,0,0x40120000,6);
  _AddTile(0,0x402a0000,0,0x40120000,6);
  _AddTile(0,0x3ff00000,0,0x40120000,6);
  _AddTile(0,0x40080000,0,0x40120000,6);
  _AddTile(0,0x40100000,0,0x40100000,6);
  _AddTile(0,0x40200000,0,0x40100000,6);
  _AddTile(0,0x40180000,0,0x400c0000,6);
  _AddTile(0,0x401c0000,0,0x40080000,6);
  _AddTile(0,0x40200000,0,0x40080000,6);
  _AddTile(0,0x40220000,0,0x40080000,6);
  _AddTile(0,0x40240000,0,0x400c0000,6);
  _AddTile(0,0x40200000,0,0x40000000,6);
  _AddTile(0,0x3ff00000,0,0x40000000,6);
  _AddTile(0,0x40000000,0,0x40000000,6);
  _AddTile(0,0x40080000,0,0x40000000,6);
  _AddTile(0,0x40280000,0,0x40000000,6);
  _AddTile(0,0x402a0000,0,0x40000000,6);
  _AddTile(0,0x402c0000,0,0x40000000,6);
  _AddTile(0,0x3ff00000,0,0x40220000,6);
  _AddTile(0,0x40000000,0,0x40220000,6);
  _AddTile(0,0x40080000,0,0x40220000,6);
  _AddTile(0,0x40280000,0,0x40220000,6);
  _AddTile(0,0x402a0000,0,0x40220000,6);
  _AddTile(0,0x402c0000,0,0x40220000,6);
  _AddTile(0,0x40200000,0,0x40220000,5);
  _AddTile(0,0x40180000,0,0x401e0000,5);
  _AddTile(0,0x40280000,0,0x401e0000,5);
  _AddTile(0,0x401c0000,0,0x40200000,5);
  _AddTile(0,0x40200000,0,0x40200000,5);
  _AddTile(0,0x40220000,0,0x40200000,5);
  _AddTile(0,0x40240000,0,0x401e0000,5);
  _AddTile(0,0x402a0000,0,0x401c0000,5);
  _AddTile(0,0x40200000,0,0x401c0000,5);
  _AddTile(0,0x40080000,0,0x401c0000,5);
  _AddTile(0,0x40100000,0,0x401e0000,5);
  _AddTile(0,0x3ff00000,0,0x401a0000,5);
  _AddTile(0,0x3ff00000,0,0x40160000,5);
  _AddTile(0,0x40000000,0,0x40160000,5);
  _AddTile(0,0x40100000,0,0x40160000,5);
  _AddTile(0,0x40140000,0,0x40160000,5);
  _AddTile(0,0x40260000,0,0x40160000,5);
  _AddTile(0,0x40280000,0,0x40160000,5);
  _AddTile(0,0x402e0000,0,0x401a0000,5);
  _AddTile(0,0x402c0000,0,0x40160000,5);
  _AddTile(0,0x402e0000,0,0x40160000,5);
  _AddTile(0,0x401c0000,0,0x40180000,5);
  _AddTile(0,0x40200000,0,0x40180000,5);
  _AddTile(0,0x40220000,0,0x40180000,5);
  _AddTile(0,0x401e0000,0,0x40140000,5);
  _AddTile(0,0x40210000,0,0x40140000,5);
  _AddTile(0,0x40280000,0,0x40100000,5);
  _AddTile(0,0x402e0000,0,0x40120000,5);
  _AddTile(0,0x402a0000,0,0x40120000,5);
  _AddTile(0,0x3ff00000,0,0x40120000,5);
  _AddTile(0,0x40080000,0,0x40120000,5);
  _AddTile(0,0x40100000,0,0x40100000,5);
  _AddTile(0,0x40200000,0,0x40100000,5);
  _AddTile(0,0x40180000,0,0x400c0000,5);
  _AddTile(0,0x401c0000,0,0x40080000,5);
  _AddTile(0,0x40200000,0,0x40080000,5);
  _AddTile(0,0x40220000,0,0x40080000,5);
  _AddTile(0,0x40240000,0,0x400c0000,5);
  _AddTile(0,0x40200000,0,0x40000000,5);
  _AddTile(0,0x3ff00000,0,0x40000000,5);
  _AddTile(0,0x40000000,0,0x40000000,5);
  _AddTile(0,0x40080000,0,0x40000000,5);
  _AddTile(0,0x40280000,0,0x40000000,5);
  _AddTile(0,0x402a0000,0,0x40000000,5);
  _AddTile(0,0x402c0000,0,0x40000000,5);
  _AddTile(0,0x3ff00000,0,0x40220000,5);
  _AddTile(0,0x40000000,0,0x40220000,5);
  _AddTile(0,0x40080000,0,0x40220000,5);
  _AddTile(0,0x40280000,0,0x40220000,5);
  _AddTile(0,0x402a0000,0,0x40220000,5);
  _AddTile(0,0x402c0000,0,0x40220000,5);
  _AddTile(0,0x40200000,0,0x40220000,4);
  _AddTile(0,0x40180000,0,0x401e0000,4);
  _AddTile(0,0x40280000,0,0x401e0000,4);
  _AddTile(0,0x401c0000,0,0x40200000,4);
  _AddTile(0,0x40200000,0,0x40200000,4);
  _AddTile(0,0x40220000,0,0x40200000,4);
  _AddTile(0,0x40240000,0,0x401e0000,4);
  _AddTile(0,0x402a0000,0,0x401c0000,4);
  _AddTile(0,0x40200000,0,0x401c0000,4);
  _AddTile(0,0x40080000,0,0x401c0000,4);
  _AddTile(0,0x40100000,0,0x401e0000,4);
  _AddTile(0,0x40100000,0,0x40160000,4);
  _AddTile(0,0x40140000,0,0x40160000,4);
  _AddTile(0,0x40260000,0,0x40160000,4);
  _AddTile(0,0x40280000,0,0x40160000,4);
  _AddTile(0,0x401c0000,0,0x40180000,4);
  _AddTile(0,0x40220000,0,0x40180000,4);
  _AddTile(0,0x401e0000,0,0x40140000,4);
  _AddTile(0,0x40210000,0,0x40140000,4);
  _AddTile(0,0x40280000,0,0x40100000,4);
  _AddTile(0,0x402a0000,0,0x40120000,4);
  _AddTile(0,0x40080000,0,0x40120000,4);
  _AddTile(0,0x40100000,0,0x40100000,4);
  _AddTile(0,0x40200000,0,0x40100000,4);
  _AddTile(0,0x40180000,0,0x400c0000,4);
  _AddTile(0,0x401c0000,0,0x40080000,4);
  _AddTile(0,0x40200000,0,0x40080000,4);
  _AddTile(0,0x40220000,0,0x40080000,4);
  _AddTile(0,0x40240000,0,0x400c0000,4);
  _AddTile(0,0x40200000,0,0x40000000,4);
  _AddTile(0,0x3ff80000,0,0x40000000,4);
  _AddTile(0,0x40040000,0,0x40000000,4);
  _AddTile(0,0x40290000,0,0x40000000,4);
  _AddTile(0,0x402b0000,0,0x40000000,4);
  _AddTile(0,0x3ff80000,0,0x40220000,4);
  _AddTile(0,0x40040000,0,0x40220000,4);
  _AddTile(0,0x40290000,0,0x40220000,4);
  _AddTile(0,0x402b0000,0,0x40220000,4);
  _AddTile(0,0x3ff00000,0,0x40160000,4);
  _AddTile(0,0x402e0000,0,0x40160000,4);
  _AddTile(0,0x40000000,0,0x40000000,3);
  _AddTile(0,0x402a0000,0,0x40000000,3);
  puVar1 = PTR__g_00038024;
  *(undefined4 *)(PTR__g_00038024 + 0x94) = 0xfffffffc;
  *(undefined4 *)(puVar1 + 0x98) = 0xffffffd3;
  *(undefined2 *)(puVar1 + 0x8e) = 2;
  return;
}


// ==== _Useless8 @ 000272ce ====

int __regparm3 _Useless8(char param_1)

{
  int iVar1;
  
  iVar1 = 7;
  if (param_1 != '\0') {
    iVar1 = _Useless8();
    iVar1 = iVar1 * 3;
  }
  return iVar1;
}


// ==== _AddMusicInfo @ 000272ee ====

void _AddMusicInfo(int param_1,undefined2 param_2)

{
  int iVar1;
  undefined *puVar2;
  void *pvVar3;
  undefined4 uVar4;
  int iVar5;
  void *pvVar6;
  
  pvVar3 = _malloc(0x110);
  *(undefined2 *)((int)pvVar3 + 4) = param_2;
  uVar4 = _RT3_GetLicenseCopies();
  iVar5 = 0;
  *(undefined4 *)((int)pvVar3 + 0x10c) = uVar4;
  pvVar6 = pvVar3;
  do {
    *(undefined1 *)((int)pvVar6 + 6) = *(undefined1 *)(param_1 + iVar5);
    *(undefined1 *)((int)pvVar6 + 7) = *(undefined1 *)(iVar5 + 1 + param_1);
    *(undefined1 *)((int)pvVar6 + 8) = *(undefined1 *)(iVar5 + 2 + param_1);
    *(undefined1 *)((int)pvVar6 + 9) = *(undefined1 *)(iVar5 + 3 + param_1);
    *(undefined1 *)((int)pvVar6 + 10) = *(undefined1 *)(iVar5 + 4 + param_1);
    *(undefined1 *)((int)pvVar6 + 0xb) = *(undefined1 *)(iVar5 + 5 + param_1);
    *(undefined1 *)((int)pvVar6 + 0xc) = *(undefined1 *)(iVar5 + 6 + param_1);
    iVar1 = iVar5 + 7;
    iVar5 = iVar5 + 8;
    *(undefined1 *)((int)pvVar6 + 0xd) = *(undefined1 *)(iVar1 + param_1);
    puVar2 = PTR__g_00038024;
    pvVar6 = (void *)((int)pvVar6 + 8);
  } while (iVar5 != 0x100);
  *(undefined4 *)((int)pvVar3 + 0x108) = 0;
  iVar5 = *(int *)(puVar2 + 0x58);
  if (iVar5 != 0) {
    *(int *)((int)pvVar3 + 0x108) = iVar5;
  }
  *(void **)(puVar2 + 0x58) = pvVar3;
  return;
}


// ==== _MyGetMovie @ 00027397 ====

int _MyGetMovie(void)

{
  char cVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  int iVar4;
  undefined4 *puVar5;
  short local_ce;
  undefined1 local_be [80];
  undefined1 local_6e [70];
  undefined1 local_28 [8];
  undefined2 local_20;
  short local_1e [7];
  
  for (puVar5 = *(undefined4 **)(PTR__g_00038024 + 0x58); puVar5 != (undefined4 *)0x0;
      puVar5 = (undefined4 *)puVar5[0x42]) {
    uVar2 = _CFBundleGetMainBundle();
    uVar3 = _CFStringGetSystemEncoding();
    uVar3 = _CFStringCreateWithPascalString(0,(int)puVar5 + 6,uVar3);
    iVar4 = _CFBundleCopyResourceURL(uVar2,uVar3,0,0);
    if ((((iVar4 == 0) || (cVar1 = _CFURLGetFSRef(iVar4,local_be), cVar1 == '\0')) ||
        (local_ce = _FSGetCatalogInfo(local_be,0x3ffff,0,0,local_6e,0), local_ce != 0)) ||
       (local_ce = _OpenMovieFile(local_6e,local_1e,1), local_ce != 0)) break;
    local_20 = 0xffff;
    _NewMovieFromFile(puVar5,(int)local_1e[0],&local_20,0,1,0);
    local_ce = _CloseMovieFile((int)local_1e[0]);
    _CFRelease(uVar3);
    _CFRelease(iVar4);
    _SetRect(local_28,0,0,0,0);
    _SetMovieBox(*puVar5,local_28);
    _GoToBeginningOfMovie(*puVar5);
  }
  return (int)local_ce;
}


// ==== _PlayMovie @ 0002755c ====

void _PlayMovie(short param_1)

{
  undefined *puVar1;
  undefined4 *puVar2;
  
  puVar1 = PTR__g_00038024;
  for (puVar2 = *(undefined4 **)(PTR__g_00038024 + 0x58); puVar2 != (undefined4 *)0x0;
      puVar2 = (undefined4 *)puVar2[0x42]) {
    if (*(short *)(puVar2 + 1) == *(short *)(puVar1 + 0x5c)) {
      if (*(short *)(PTR__p_00038028 + 0x20e) < 2 || puVar1[0x67] != '\0') {
        _StopMovie(*puVar2);
      }
      else {
        _SetMovieVolume(*puVar2,(int)param_1);
        _StartMovie(*puVar2);
        _MoviesTask(*puVar2,0);
      }
    }
  }
  return;
}


// ==== _LoopMusic @ 000275e5 ====

char _LoopMusic(char param_1)

{
  short sVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  bool bVar4;
  undefined *puVar5;
  undefined *puVar6;
  char cVar7;
  byte bVar8;
  char *pcVar9;
  int iVar10;
  uint uVar11;
  byte bVar12;
  uint uVar13;
  undefined4 *puVar14;
  uint uVar15;
  uint local_50;
  ushort local_40;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined1 local_20;
  byte local_1f [15];
  
  puVar6 = PTR__p_00038028;
  puVar5 = PTR__g_00038024;
  if (param_1 == '\x01') {
    if (*(short *)(PTR__p_00038028 + 0x20e) == 3) {
      *(undefined2 *)(PTR__p_00038028 + 0x20e) = 2;
    }
    if (*(short *)(puVar6 + 0x20e) == 1) {
      *(undefined2 *)(puVar6 + 0x20e) = 0;
    }
    _RT3_Idle();
    cVar7 = _RT3_IsRegistered();
    puVar5 = PTR__g_00038024;
    if (cVar7 != '\0') {
      local_1f[0] = 0x49;
      local_1f[1] = 0x71;
      local_30 = DAT_00033ef0;
      local_1f[2] = 0xad;
      local_2c = DAT_00033ef4;
      local_28 = DAT_00033ef8;
      local_24 = DAT_00033efc;
      local_20 = DAT_00033f00;
      local_50 = *(uint *)(*(int *)(PTR__g_00038024 + 0x58) + 0x10c);
      pcVar9 = (char *)_RT3_CheckLicenseName(*(undefined4 *)(PTR__g_00038024 + 0x44));
      uVar2 = *(undefined4 *)(*(int *)(puVar5 + 0x54) + 0x10c);
      uVar3 = *(undefined4 *)(*(int *)(puVar5 + 0x54) + 0x110);
      if (pcVar9 != (char *)0x0) {
        if (('/' < *pcVar9) && (*pcVar9 < ':')) {
          local_50 = 1;
        }
        while( true ) {
          iVar10 = _StringGetLength(&local_30);
          if ((0x10 < iVar10 + 1U) || (*pcVar9 == '\0')) break;
          _StringAppendSafe(&local_30,pcVar9,0x11);
        }
      }
      bVar12 = local_30._3_1_;
      _TimerGetSeconds();
      uVar15 = local_50 & 0xff;
      bVar12 = (bVar12 ^ 0xc3) + 0x65 ^ (byte)local_50;
      local_40 = _RT3_ExtractLicenseBlock1(uVar2,uVar3);
      bVar8 = (byte)local_2c;
      bVar12 = (((bVar12 ^ 2) << 2 | bVar12 >> 6) ^ (byte)local_50) - 0x15 ^ 0x69 ^ (byte)local_50 ^
               0x69 ^ (byte)local_50;
      if (bVar12 < 0xbe) {
        bVar12 = bVar12 + 0x96;
      }
      bVar12 = (bVar12 + 0xc ^ bVar8) + 0x5a ^ (byte)local_50;
      if (0xc5 < bVar12) {
        bVar12 = bVar12 << 5 | bVar12 >> 3;
      }
      _TimerGetSeconds();
      _TimerGetSeconds();
      bVar12 = (bVar8 ^ (bVar12 << 7 | bVar12 >> 1) + 0x96) - 0x27;
      bVar12 = (bVar12 * -0x80 | bVar12 >> 1) + 0x86 ^ local_24._2_1_;
      _TimerGetSeconds();
      bVar12 = (((bVar12 << 1 | (char)bVar12 < '\0') ^ 0x69) + 0x66 ^ (byte)local_50) - 0x2d;
      bVar12 = ((bVar12 * -0x80 | bVar12 >> 1) + 0x9a ^ (byte)local_50 ^ 0x41) + 0x89;
      _Useless8();
      bVar12 = (bVar12 * ' ' | bVar12 >> 3) + 0xbc;
      bVar12 = ((bVar12 * ' ' | bVar12 >> 3) ^ (byte)local_50) + 100 ^ (byte)local_28;
      uVar13 = (byte)(bVar12 << 7 | bVar12 >> 1) - 0x12 ^ 0x41;
      if ((int)local_28._3_1_ < (int)(uVar13 & 0xff)) {
        uVar13 = uVar13 ^ uVar15;
      }
      uVar13 = uVar13 - 0x42 ^ 0x6b;
      bVar12 = (byte)uVar13;
      uVar13 = uVar13 & 0xff;
      if (uVar13 < 0x41) {
        bVar12 = bVar12 ^ (byte)local_2c;
        uVar13 = (uint)bVar12;
      }
      _Useless8();
      bVar12 = ((bVar12 >> 3 | (byte)(uVar13 << 5)) + 0x49 ^ 0x28 ^ (byte)local_50) + 0x70;
      bVar12 = (bVar12 * '\x04' | bVar12 >> 6) - 8 ^ (byte)local_24;
      bVar12 = ((byte)local_24 ^ ((bVar12 << 6 | bVar12 >> 2) ^ 0x69) + 0x4c ^ 0x41 ^ local_30._1_1_
               ) + 0x5b;
      uVar13 = (byte)(bVar12 * -0x80 | bVar12 >> 1) - 5;
      if ((uVar13 & 0xff) < 0x69) {
        uVar13 = uVar13 ^ uVar15;
      }
      uVar11 = uVar13 + 0x17 ^ uVar15;
      uVar13 = uVar11 + 3;
      cVar7 = (char)uVar13;
      if (0x6b < (uVar13 & 0xff)) {
        cVar7 = (char)uVar11 + -0x4b;
      }
      bVar12 = ((((cVar7 + 0x81U) * ' ' | (byte)(cVar7 + 0x81U) >> 3) ^ (byte)local_50) - 0x1c ^
               local_2c._2_1_) + 0xb3;
      if (0xb0 < bVar12) {
        bVar12 = bVar12 * ' ' | bVar12 >> 3;
      }
      bVar12 = bVar12 + 0x1d;
      if (bVar12 < 3) {
        bVar12 = local_1f[bVar12];
      }
      for (; bVar12 <= local_40; local_40 = local_40 - bVar12) {
      }
      bVar12 = ((bVar12 ^ local_2c._1_1_) << 3 | (bVar12 ^ local_2c._1_1_) >> 5) + 0x78 ^
               (byte)local_28 ^ (byte)local_50;
      bVar12 = (bVar12 << 2 | bVar12 >> 6) ^ (byte)local_50;
      bVar8 = bVar12 << 3 | bVar12 >> 5;
      uVar15 = bVar8 ^ uVar15;
      bVar12 = (byte)uVar15;
      if (uVar15 < 0x69) {
        bVar12 = bVar8;
      }
      if (bVar12 != 0xf3) {
        _IsPlatformOpen();
      }
      puVar5 = PTR__p_00038028;
      if (local_40 == 0 && local_50 != 0) {
        if (1 < *(short *)(PTR__p_00038028 + 0x20e)) {
          *(undefined2 *)(PTR__p_00038028 + 0x20e) = 3;
        }
        if (*(short *)(puVar5 + 0x20e) < 1) {
          *(undefined2 *)(puVar5 + 0x20e) = 1;
        }
      }
    }
    param_1 = '\0';
  }
  else if (1 < *(short *)(PTR__p_00038028 + 0x20e)) {
    bVar4 = false;
    for (puVar14 = *(undefined4 **)(PTR__g_00038024 + 0x58); puVar6 = PTR__g_00038024,
        puVar14 != (undefined4 *)0x0; puVar14 = (undefined4 *)puVar14[0x42]) {
      if ((*(short *)(puVar14 + 1) == *(short *)(puVar5 + 0x5c)) &&
         (cVar7 = _IsMovieDone(*puVar14), cVar7 != '\0')) {
        sVar1 = *(short *)(puVar5 + 0x5c);
        if (sVar1 == 0) {
          _GoToBeginningOfMovie(*puVar14);
          _PlayMovie(0x80);
        }
        else {
          if (sVar1 == 2) {
            *(undefined2 *)(puVar5 + 0x5c) = 1;
            puVar14 = (undefined4 *)puVar14[0x42];
          }
          else {
            if (sVar1 != 1) goto LAB_00027963;
            *(undefined2 *)(puVar5 + 0x5c) = 2;
          }
          bVar4 = true;
        }
      }
LAB_00027963:
    }
    if (bVar4) {
      for (puVar14 = *(undefined4 **)(PTR__g_00038024 + 0x58); puVar14 != (undefined4 *)0x0;
          puVar14 = (undefined4 *)puVar14[0x42]) {
        if (*(short *)(puVar14 + 1) == *(short *)(puVar6 + 0x5c)) {
          _GoToBeginningOfMovie(*puVar14);
          _PlayMovie(0x80);
        }
      }
    }
  }
  return param_1;
}


// ==== _InitializeGWorlds @ 00027a36 ====

void _InitializeGWorlds(void)

{
  undefined *puVar1;
  undefined4 local_14;
  undefined4 local_10;
  
  _SetRect(&local_14,0,0,800,600);
  puVar1 = PTR__g_00038024;
  _CreateGWorld(&cf_misc,PTR__g_00038024,local_14,local_10);
  _CreateGWorld(&cf_tiles,puVar1 + 4,local_14,local_10);
  _CreateGWorld(&cf_proverbs,puVar1 + 8,local_14,local_10);
  _CreateGWorld(&cf_tile_pictures,puVar1 + 0xc,local_14,local_10);
  _CreateGWorld(&cf_previews,puVar1 + 0x18,local_14,local_10);
  _CreateGWorld(&cf_arrow,puVar1 + 0x34,local_14,local_10);
  _CreateGWorld(&cf_pause,puVar1 + 0x10,local_14,local_10);
  _CreateGWorld(&cf_plate,puVar1 + 0x1c,local_14,local_10);
  _CreateGWorld(&cf_map,puVar1 + 0x20,local_14,local_10);
  _CreateGWorld(&cf_nopairs,puVar1 + 0x24,local_14,local_10);
  _CreateGWorld(&cf_notavail,puVar1 + 0x28,local_14,local_10);
  _CreateGWorld(0,puVar1 + 0x2c,local_14,local_10);
  _CreateGWorld(0,puVar1 + 0x30,local_14,local_10);
  _CreateGWorld(0,puVar1 + 0x38,local_14,local_10);
  _CreateGWorld(0,puVar1 + 0x3c,local_14,local_10);
  _CreateGWorld(&cf_background1,puVar1 + 0x14,local_14,local_10);
  _CreateGWorld(&cf_layer_buttons,puVar1 + 0x40,local_14,local_10);
  return;
}


// ==== _InitializeMusic @ 00027ca2 ====

void _InitializeMusic(void)

{
  _AddMusicInfo("\x0fAki Theme 3.mp3",0);
  _AddMusicInfo("\x0fAki Theme 1.mp3",1);
  _AddMusicInfo("\x0fAki Theme 2.mp3",2);
  _MyGetMovie();
  return;
}


// ==== _InitializeSound @ 00027cea ====

void _InitializeSound(void)

{
  _AddSoundInfo("\nchime.aiff",0x4b);
  _AddSoundInfo("\x0eReshuffle.aiff",0x14);
  _AddSoundInfo("\x12LevelComplete.aiff",0x1e);
  _AddSoundInfo("\rGameOver.aiff",0x28);
  _AddSoundInfo("\x0fLevelStart.aiff",0x32);
  _AddSoundInfo("\fPreview.aiff",0x3c);
  _AddSoundInfo("\x0eTileMatch.aiff",0x46);
  _AddSoundInfo("\vcancel.aiff",0x50);
  _AddSoundInfo("\funclick.aiff",0x5a);
  _AddSoundInfo("\btick.mp3",100);
  _AddSoundInfo("\vtilehit.mp3",10);
  _LoadSoundIntoMemory();
  return;
}


// ==== _Initialize @ 00027dd2 ====

void _Initialize(void)

{
  undefined *puVar1;
  undefined4 uVar2;
  
  _InitCursor();
  uVar2 = _TickCount();
  _SetQDGlobalsRandomSeed(uVar2);
  _LoadPrefs(PTR__p_00038028);
  _EnterMovies();
  _PlatformOpen();
  _FT_Open();
  _DT_Open();
  _IT_Open();
  _RT3_Open(1,3,"Aki","Aki");
  uVar2 = _RT3_GetLicenseName();
  puVar1 = PTR__g_00038024;
  *(undefined4 *)(PTR__g_00038024 + 0x44) = uVar2;
  _InitializeGWorlds();
  *(undefined4 *)(puVar1 + 0xc4) = 0x2a30;
  *(undefined2 *)(puVar1 + 0x5c) = 0;
  *(undefined2 *)(puVar1 + 0x5e) = 1;
  puVar1[0x83] = 0;
  puVar1[0x65] = 0;
  puVar1[0x7e] = 0;
  puVar1[0x7d] = 0;
  puVar1[0x7f] = 0;
  puVar1[100] = 0;
  puVar1[0x66] = 0;
  puVar1[0x68] = 0;
  puVar1[0x7c] = 0;
  puVar1[0x80] = 0;
  *(undefined4 *)(puVar1 + 0xd0) = 0;
  puVar1[0x229] = 0;
  puVar1[0x22b] = 1;
  _InitializeSound();
  _InitializeMusic();
  return;
}


// ==== _POSIXPathToFSSpec @ 000280f9 ====

int _POSIXPathToFSSpec(undefined4 param_1,int param_2)

{
  char cVar1;
  short sVar2;
  int iVar3;
  undefined4 uVar4;
  undefined4 uVar5;
  uint uVar6;
  uint uVar7;
  int iVar8;
  int iVar9;
  int local_118;
  int local_114;
  int local_110;
  undefined1 local_fe [8];
  undefined4 local_f6;
  undefined1 local_6e [81];
  undefined1 local_1d [13];
  
  iVar3 = _FSPathMakeRef(param_1,local_6e,local_1d);
  if (iVar3 == 0) {
    sVar2 = _FSGetCatalogInfo(local_6e,0,0,0,param_2,0);
    if (sVar2 != 0) {
      return (int)sVar2;
    }
    iVar9 = 0;
    local_110 = 0;
    local_114 = 0;
    local_118 = 0;
LAB_00028287:
    iVar3 = 0;
    iVar8 = 0;
    uVar7 = (uint)*(byte *)(param_2 + 6);
    uVar6 = uVar7 & 7;
    if ((*(byte *)(param_2 + 6) & 7) != 0) {
      if (uVar7 == 0) goto LAB_000282a3;
      iVar8 = 1;
      if (uVar6 != 1) {
        if (uVar6 != 2) {
          if (uVar6 != 3) {
            if (uVar6 != 4) {
              if (uVar6 != 5) {
                iVar8 = (uVar6 != 6) + 2;
              }
              iVar8 = iVar8 + 1;
            }
            iVar8 = iVar8 + 1;
          }
          iVar8 = iVar8 + 1;
        }
        iVar8 = iVar8 + 1;
      }
    }
    for (; iVar8 < (int)uVar7; iVar8 = iVar8 + 8) {
    }
LAB_000282a3:
    if (local_114 == 0) goto LAB_000282bb;
  }
  else {
    uVar4 = _CFStringGetSystemEncoding();
    uVar5 = _CFAllocatorGetDefault();
    local_110 = _CFStringCreateWithCString(uVar5,param_1,uVar4);
    if (local_110 == 0) {
      return -0x6c;
    }
    uVar4 = _CFAllocatorGetDefault();
    local_114 = _CFURLCreateWithFileSystemPath(uVar4,local_110,0,0);
    if (local_114 == 0) {
      iVar3 = -0x6c;
      local_118 = 0;
LAB_00028344:
      iVar9 = 0;
      goto LAB_000282a3;
    }
    uVar4 = _CFAllocatorGetDefault();
    local_118 = _CFURLCreateCopyDeletingLastPathComponent(uVar4,local_114);
    if (local_118 == 0) {
      iVar3 = -0x6c;
      goto LAB_00028344;
    }
    iVar3 = -0x2b;
    cVar1 = _CFURLGetFSRef(local_118,local_6e);
    if (cVar1 == '\0') goto LAB_00028344;
    sVar2 = _FSGetCatalogInfo(local_6e,0x12,local_fe,0,param_2,0);
    iVar3 = (int)sVar2;
    if (sVar2 == 0) {
      iVar3 = -0x6c;
      iVar9 = _CFURLCopyLastPathComponent(local_114);
      if (iVar9 != 0) {
        uVar4 = _CFStringGetSystemEncoding();
        iVar3 = -0x2b;
        cVar1 = _CFStringGetPascalString(local_110,param_2 + 6,0x40,uVar4);
        if (cVar1 != '\0') {
          *(undefined4 *)(param_2 + 2) = local_f6;
          goto LAB_00028287;
        }
        goto LAB_000282a3;
      }
    }
    else {
      iVar9 = 0;
    }
  }
  _CFRelease(local_114);
LAB_000282bb:
  if (local_110 != 0) {
    _CFRelease(local_110);
  }
  if (local_118 != 0) {
    _CFRelease(local_118);
  }
  if (iVar9 != 0) {
    _CFRelease(iVar9);
  }
  return iVar3;
}


// ==== _MakeRelativeAliasFile @ 000283a2 ====

int _MakeRelativeAliasFile(undefined4 param_1,int param_2)

{
  short sVar1;
  int iVar2;
  int local_30 [2];
  undefined2 local_28;
  int local_20 [4];
  
  local_20[0] = 0;
  sVar1 = _FSpGetFInfo(param_1,local_30);
  if (sVar1 == 0) {
    iVar2 = 0x61647270;
    if (local_30[0] != 0x4150504c) {
      iVar2 = local_30[0];
    }
    local_28 = 0x8000;
    local_30[0] = iVar2;
    _FSpCreateResFile(param_2,0x54454d50,0x54454d50,0xffffffff);
    sVar1 = _ResError();
    if (sVar1 == 0) {
      sVar1 = _FSpSetFInfo(param_2,local_30);
      if ((sVar1 == 0) && (sVar1 = _NewAlias(param_2,param_1,local_20), sVar1 == 0)) {
        sVar1 = _FSpOpenResFile(param_2,3);
        if (sVar1 == -1) {
          sVar1 = _ResError();
        }
        else {
          iVar2 = (int)sVar1;
          _UseResFile(iVar2);
          _AddResource(local_20[0],0x616c6973,0,param_2 + 6);
          sVar1 = _ResError();
          if (sVar1 == 0) {
            local_20[0] = 0;
            _CloseResFile(iVar2);
            sVar1 = _ResError();
            if (sVar1 == 0) {
              return 0;
            }
          }
          else {
            _CloseResFile(iVar2);
          }
        }
      }
      _FSpDelete(param_2);
    }
  }
  if (local_20[0] != 0) {
    _DisposeHandle(local_20[0]);
  }
  return (int)sVar1;
}


// ==== -[PaperBackgroundView_drawRect:] @ 0002850e ====

void __PaperBackgroundView_drawRect__
               (undefined4 param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6)

{
  undefined4 uVar1;
  undefined4 uVar2;
  undefined4 extraout_EDX;
  
  uVar1 = _objc_msgSend(PTR_s_NSImage_000362bc,PTR_s_imageNamed__00036170,&cf_paper);
  _objc_msgSend(uVar1,PTR_s_size_00036188);
  uVar2 = _objc_msgSend(uVar1,PTR_s_size_00036188);
  _objc_msgSend(uVar1,PTR_s_drawInRect_fromRect_operation_fr_0003617c,param_3,param_4,param_5,
                param_6,0,0,uVar2,extraout_EDX,2,0x3f800000);
  return;
}


// ==== _SavePrefs @ 0002882c ====

void _SavePrefs(void)

{
  uint uVar1;
  undefined *puVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  uint local_24;
  ushort local_20;
  undefined1 local_1d [13];
  
  uVar3 = _objc_msgSend(PTR_s_NSMutableData_000362e0,PTR_s_data_00036200);
  puVar2 = PTR__p_00038028;
  local_1d[0] = PTR__p_00038028[0x200];
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,local_1d,1);
  local_1d[0] = puVar2[0x201];
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,local_1d,1);
  local_1d[0] = puVar2[0x202];
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,local_1d,1);
  local_1d[0] = puVar2[0x203];
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,local_1d,1);
  local_1d[0] = puVar2[0x204];
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,local_1d,1);
  local_1d[0] = puVar2[0x205];
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,local_1d,1);
  local_1d[0] = puVar2[0x206];
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,local_1d,1);
  local_1d[0] = puVar2[0x207];
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,local_1d,1);
  local_1d[0] = puVar2[0x208];
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,local_1d,1);
  local_1d[0] = puVar2[0x209];
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,local_1d,1);
  local_1d[0] = puVar2[0x20a];
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,local_1d,1);
  local_1d[0] = puVar2[0x20b];
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,local_1d,1);
  local_20 = *(ushort *)(puVar2 + 0x20c) << 8 | *(ushort *)(puVar2 + 0x20c) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x20e) << 8 | *(ushort *)(puVar2 + 0x20e) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x210) << 8 | *(ushort *)(puVar2 + 0x210) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_1d[0] = puVar2[0x212];
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,local_1d,1);
  local_1d[0] = puVar2[0x213];
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,local_1d,1);
  local_1d[0] = puVar2[0x214];
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,local_1d,1);
  local_1d[0] = puVar2[0x215];
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,local_1d,1);
  local_1d[0] = puVar2[0x216];
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,local_1d,1);
  local_20 = *(ushort *)(puVar2 + 0x218) << 8 | *(ushort *)(puVar2 + 0x218) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x21a) << 8 | *(ushort *)(puVar2 + 0x21a) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x21c) << 8 | *(ushort *)(puVar2 + 0x21c) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x21e) << 8 | *(ushort *)(puVar2 + 0x21e) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x220) << 8 | *(ushort *)(puVar2 + 0x220) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x222) << 8 | *(ushort *)(puVar2 + 0x222) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x224) << 8 | *(ushort *)(puVar2 + 0x224) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x226) << 8 | *(ushort *)(puVar2 + 0x226) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x228) << 8 | *(ushort *)(puVar2 + 0x228) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x22a) << 8 | *(ushort *)(puVar2 + 0x22a) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x22c) << 8 | *(ushort *)(puVar2 + 0x22c) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x22e) << 8 | *(ushort *)(puVar2 + 0x22e) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x230) << 8 | *(ushort *)(puVar2 + 0x230) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x232) << 8 | *(ushort *)(puVar2 + 0x232) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x234) << 8 | *(ushort *)(puVar2 + 0x234) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x236) << 8 | *(ushort *)(puVar2 + 0x236) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x238) << 8 | *(ushort *)(puVar2 + 0x238) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x23a) << 8 | *(ushort *)(puVar2 + 0x23a) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x23c) << 8 | *(ushort *)(puVar2 + 0x23c) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x23e) << 8 | *(ushort *)(puVar2 + 0x23e) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x240) << 8 | *(ushort *)(puVar2 + 0x240) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x242) << 8 | *(ushort *)(puVar2 + 0x242) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x244) << 8 | *(ushort *)(puVar2 + 0x244) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x246) << 8 | *(ushort *)(puVar2 + 0x246) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x248) << 8 | *(ushort *)(puVar2 + 0x248) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x24a) << 8 | *(ushort *)(puVar2 + 0x24a) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x24c) << 8 | *(ushort *)(puVar2 + 0x24c) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x24e) << 8 | *(ushort *)(puVar2 + 0x24e) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x250) << 8 | *(ushort *)(puVar2 + 0x250) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x252) << 8 | *(ushort *)(puVar2 + 0x252) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x254) << 8 | *(ushort *)(puVar2 + 0x254) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x256) << 8 | *(ushort *)(puVar2 + 0x256) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 600) << 8 | *(ushort *)(puVar2 + 600) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x25a) << 8 | *(ushort *)(puVar2 + 0x25a) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x25c) << 8 | *(ushort *)(puVar2 + 0x25c) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  local_20 = *(ushort *)(puVar2 + 0x25e) << 8 | *(ushort *)(puVar2 + 0x25e) >> 8;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_20,2);
  uVar1 = *(uint *)(puVar2 + 0x260);
  local_24 = uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_24,4);
  uVar1 = *(uint *)(puVar2 + 0x264);
  local_24 = uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_24,4);
  uVar1 = *(uint *)(puVar2 + 0x268);
  local_24 = uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_24,4);
  uVar1 = *(uint *)(puVar2 + 0x26c);
  local_24 = uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_24,4);
  uVar1 = *(uint *)(puVar2 + 0x270);
  local_24 = uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_24,4);
  uVar1 = *(uint *)(puVar2 + 0x274);
  local_24 = uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_24,4);
  uVar1 = *(uint *)(puVar2 + 0x278);
  local_24 = uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_24,4);
  uVar1 = *(uint *)(puVar2 + 0x27c);
  local_24 = uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_24,4);
  uVar1 = *(uint *)(puVar2 + 0x280);
  local_24 = uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_24,4);
  uVar1 = *(uint *)(puVar2 + 0x284);
  local_24 = uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_24,4);
  uVar1 = *(uint *)(puVar2 + 0x288);
  local_24 = uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_24,4);
  uVar1 = *(uint *)(puVar2 + 0x28c);
  local_24 = uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  _objc_msgSend(uVar3,PTR_s_appendBytes_length__00036204,&local_24,4);
  uVar4 = _objc_msgSend(PTR_s_NSUserDefaults_000362a4,PTR_s_standardUserDefaults_00036008);
  _objc_msgSend(uVar4,PTR_s_setObject_forKey__00036208,uVar3,&cf_GameSettings);
  return;
}


// ==== _LoadPrefs @ 000293f6 ====

int _LoadPrefs(int param_1)

{
  ushort *puVar1;
  uint uVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  short sVar6;
  undefined4 uVar7;
  int iVar8;
  undefined1 *puVar9;
  cfstringStruct *pcVar10;
  undefined1 local_6a [70];
  undefined4 local_24;
  short local_1e [7];
  
  uVar7 = _objc_msgSend(PTR_s_NSUserDefaults_000362a4,PTR_s_standardUserDefaults_00036008);
  pcVar10 = &cf_GameSettings;
  iVar8 = _objc_msgSend(uVar7,PTR_s_objectForKey__00036028,&cf_GameSettings);
  puVar5 = PTR__p_00038028;
  if (iVar8 == 0) {
    PTR__p_00038028[0x215] = 1;
    *puVar5 = 0;
    puVar5[0x100] = 0;
    *(undefined2 *)(puVar5 + 0x218) = 0;
    *(undefined2 *)(puVar5 + 0x230) = 0;
    *(undefined2 *)(puVar5 + 0x248) = 0;
    *(undefined4 *)(puVar5 + 0x260) = 0;
    puVar5[0x201] = 0;
    *(undefined2 *)(puVar5 + 0x21a) = 0;
    *(undefined2 *)(puVar5 + 0x232) = 0;
    *(undefined2 *)(puVar5 + 0x24a) = 0;
    *(undefined4 *)(puVar5 + 0x264) = 0;
    puVar5[0x202] = 0;
    *(undefined2 *)(puVar5 + 0x21c) = 0;
    *(undefined2 *)(puVar5 + 0x234) = 0;
    *(undefined2 *)(puVar5 + 0x24c) = 0;
    *(undefined4 *)(puVar5 + 0x268) = 0;
    puVar5[0x203] = 0;
    *(undefined2 *)(puVar5 + 0x21e) = 0;
    *(undefined2 *)(puVar5 + 0x236) = 0;
    *(undefined2 *)(puVar5 + 0x24e) = 0;
    *(undefined4 *)(puVar5 + 0x26c) = 0;
    puVar5[0x204] = 0;
    *(undefined2 *)(puVar5 + 0x220) = 0;
    *(undefined2 *)(puVar5 + 0x238) = 0;
    *(undefined2 *)(puVar5 + 0x250) = 0;
    *(undefined4 *)(puVar5 + 0x270) = 0;
    puVar5[0x205] = 0;
    *(undefined2 *)(puVar5 + 0x222) = 0;
    *(undefined2 *)(puVar5 + 0x23a) = 0;
    *(undefined2 *)(puVar5 + 0x252) = 0;
    *(undefined4 *)(puVar5 + 0x274) = 0;
    puVar5[0x206] = 0;
    *(undefined2 *)(puVar5 + 0x224) = 0;
    *(undefined2 *)(puVar5 + 0x23c) = 0;
    *(undefined2 *)(puVar5 + 0x254) = 0;
    *(undefined4 *)(puVar5 + 0x278) = 0;
    puVar5[0x207] = 0;
    *(undefined2 *)(puVar5 + 0x226) = 0;
    *(undefined2 *)(puVar5 + 0x23e) = 0;
    *(undefined2 *)(puVar5 + 0x256) = 0;
    *(undefined4 *)(puVar5 + 0x27c) = 0;
    puVar5[0x208] = 0;
    *(undefined2 *)(puVar5 + 0x228) = 0;
    *(undefined2 *)(puVar5 + 0x240) = 0;
    *(undefined2 *)(puVar5 + 600) = 0;
    *(undefined4 *)(puVar5 + 0x280) = 0;
    puVar5[0x209] = 0;
    *(undefined2 *)(puVar5 + 0x22a) = 0;
    *(undefined2 *)(puVar5 + 0x242) = 0;
    *(undefined2 *)(puVar5 + 0x25a) = 0;
    *(undefined4 *)(puVar5 + 0x284) = 0;
    puVar5[0x20a] = 0;
    *(undefined2 *)(puVar5 + 0x22c) = 0;
    *(undefined2 *)(puVar5 + 0x244) = 0;
    *(undefined2 *)(puVar5 + 0x25c) = 0;
    *(undefined4 *)(puVar5 + 0x288) = 0;
    puVar5[0x20b] = 0;
    *(undefined2 *)(puVar5 + 0x22e) = 0;
    *(undefined2 *)(puVar5 + 0x246) = 0;
    *(undefined2 *)(puVar5 + 0x25e) = 0;
    *(undefined4 *)(puVar5 + 0x28c) = 0;
    puVar5[0x200] = 1;
    *(undefined2 *)(puVar5 + 0x20c) = 1;
    puVar5[0x214] = 1;
    *(undefined2 *)(puVar5 + 0x20e) = 2;
    *(undefined2 *)(puVar5 + 0x210) = 2;
    puVar4 = PTR__gPrefsFolderVRefNum_00034054;
    puVar3 = PTR__gPrefsFolderDirID_00034050;
    puVar5[0x213] = 1;
    puVar5[0x212] = 0;
    puVar5[0x216] = 1;
    _FindFolder(0xffff8000,0x70726566,0,puVar4,puVar3);
    _FSMakeFSSpec((int)*(short *)puVar4,*(undefined4 *)puVar3,"\n:Aki Prefs",local_6a);
    sVar6 = _FSpOpenDF(local_6a,1,local_1e);
    if (sVar6 != 0) {
      return (int)sVar6;
    }
    local_24 = 0x290;
    sVar6 = _FSRead((int)local_1e[0],&local_24,param_1);
    if (sVar6 != 0) {
      _FSClose((int)local_1e[0]);
      return (int)sVar6;
    }
    _FSClose((int)local_1e[0]);
    puVar1 = (ushort *)(param_1 + 0x218);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x230);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x248);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x20c);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x20e);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x210);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    uVar2 = *(uint *)(param_1 + 0x260);
    *(uint *)(param_1 + 0x260) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    puVar1 = (ushort *)(param_1 + 0x21a);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x232);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x24a);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    uVar2 = *(uint *)(param_1 + 0x264);
    *(uint *)(param_1 + 0x264) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    puVar1 = (ushort *)(param_1 + 0x21c);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x234);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x24c);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    uVar2 = *(uint *)(param_1 + 0x268);
    *(uint *)(param_1 + 0x268) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    puVar1 = (ushort *)(param_1 + 0x21e);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x24e);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x236);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    uVar2 = *(uint *)(param_1 + 0x26c);
    *(uint *)(param_1 + 0x26c) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    puVar1 = (ushort *)(param_1 + 0x220);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x250);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x238);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    uVar2 = *(uint *)(param_1 + 0x270);
    *(uint *)(param_1 + 0x270) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    puVar1 = (ushort *)(param_1 + 0x222);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x23a);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x252);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    uVar2 = *(uint *)(param_1 + 0x274);
    *(uint *)(param_1 + 0x274) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    puVar1 = (ushort *)(param_1 + 0x224);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x23c);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x254);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    uVar2 = *(uint *)(param_1 + 0x278);
    *(uint *)(param_1 + 0x278) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    puVar1 = (ushort *)(param_1 + 0x226);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x23e);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x256);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    uVar2 = *(uint *)(param_1 + 0x27c);
    *(uint *)(param_1 + 0x27c) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    puVar1 = (ushort *)(param_1 + 0x228);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x240);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 600);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    uVar2 = *(uint *)(param_1 + 0x280);
    *(uint *)(param_1 + 0x280) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    puVar1 = (ushort *)(param_1 + 0x22a);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x242);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x25a);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    uVar2 = *(uint *)(param_1 + 0x284);
    *(uint *)(param_1 + 0x284) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    puVar1 = (ushort *)(param_1 + 0x22c);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x244);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x25c);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    uVar2 = *(uint *)(param_1 + 0x288);
    *(uint *)(param_1 + 0x288) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    puVar1 = (ushort *)(param_1 + 0x22e);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x246);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    puVar1 = (ushort *)(param_1 + 0x25e);
    *puVar1 = *puVar1 << 8 | *puVar1 >> 8;
    uVar2 = *(uint *)(param_1 + 0x28c);
    *(uint *)(param_1 + 0x28c) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
  }
  else {
    puVar9 = (undefined1 *)_objc_msgSend(iVar8,PTR_s_bytes_000361fc,pcVar10);
    puVar5 = PTR__p_00038028;
    PTR__p_00038028[0x200] = *puVar9;
    puVar5[0x201] = puVar9[1];
    puVar5[0x202] = puVar9[2];
    puVar5[0x203] = puVar9[3];
    puVar5[0x204] = puVar9[4];
    puVar5[0x205] = puVar9[5];
    puVar5[0x206] = puVar9[6];
    puVar5[0x207] = puVar9[7];
    puVar5[0x208] = puVar9[8];
    puVar5[0x209] = puVar9[9];
    puVar5[0x20a] = puVar9[10];
    puVar5[0x20b] = puVar9[0xb];
    *(ushort *)(puVar5 + 0x20c) = *(ushort *)(puVar9 + 0xc) << 8 | *(ushort *)(puVar9 + 0xc) >> 8;
    *(ushort *)(puVar5 + 0x20e) = *(ushort *)(puVar9 + 0xe) << 8 | *(ushort *)(puVar9 + 0xe) >> 8;
    *(ushort *)(puVar5 + 0x210) = *(ushort *)(puVar9 + 0x10) << 8 | *(ushort *)(puVar9 + 0x10) >> 8;
    puVar5[0x212] = puVar9[0x12];
    puVar5[0x213] = puVar9[0x13];
    puVar5[0x214] = puVar9[0x14];
    puVar5[0x215] = puVar9[0x15];
    puVar5[0x216] = puVar9[0x16];
    *(ushort *)(puVar5 + 0x218) = *(ushort *)(puVar9 + 0x17) << 8 | *(ushort *)(puVar9 + 0x17) >> 8;
    *(ushort *)(puVar5 + 0x21a) = *(ushort *)(puVar9 + 0x19) << 8 | *(ushort *)(puVar9 + 0x19) >> 8;
    *(ushort *)(puVar5 + 0x21c) = *(ushort *)(puVar9 + 0x1b) << 8 | *(ushort *)(puVar9 + 0x1b) >> 8;
    *(ushort *)(puVar5 + 0x21e) = *(ushort *)(puVar9 + 0x1d) << 8 | *(ushort *)(puVar9 + 0x1d) >> 8;
    *(ushort *)(puVar5 + 0x220) = *(ushort *)(puVar9 + 0x1f) << 8 | *(ushort *)(puVar9 + 0x1f) >> 8;
    *(ushort *)(puVar5 + 0x222) = *(ushort *)(puVar9 + 0x21) << 8 | *(ushort *)(puVar9 + 0x21) >> 8;
    *(ushort *)(puVar5 + 0x224) = *(ushort *)(puVar9 + 0x23) << 8 | *(ushort *)(puVar9 + 0x23) >> 8;
    *(ushort *)(puVar5 + 0x226) = *(ushort *)(puVar9 + 0x25) << 8 | *(ushort *)(puVar9 + 0x25) >> 8;
    *(ushort *)(puVar5 + 0x228) = *(ushort *)(puVar9 + 0x27) << 8 | *(ushort *)(puVar9 + 0x27) >> 8;
    *(ushort *)(puVar5 + 0x22a) = *(ushort *)(puVar9 + 0x29) << 8 | *(ushort *)(puVar9 + 0x29) >> 8;
    *(ushort *)(puVar5 + 0x22c) = *(ushort *)(puVar9 + 0x2b) << 8 | *(ushort *)(puVar9 + 0x2b) >> 8;
    *(ushort *)(puVar5 + 0x22e) = *(ushort *)(puVar9 + 0x2d) << 8 | *(ushort *)(puVar9 + 0x2d) >> 8;
    *(ushort *)(puVar5 + 0x230) = *(ushort *)(puVar9 + 0x2f) << 8 | *(ushort *)(puVar9 + 0x2f) >> 8;
    *(ushort *)(puVar5 + 0x232) = *(ushort *)(puVar9 + 0x31) << 8 | *(ushort *)(puVar9 + 0x31) >> 8;
    *(ushort *)(puVar5 + 0x234) = *(ushort *)(puVar9 + 0x33) << 8 | *(ushort *)(puVar9 + 0x33) >> 8;
    *(ushort *)(puVar5 + 0x236) = *(ushort *)(puVar9 + 0x35) << 8 | *(ushort *)(puVar9 + 0x35) >> 8;
    *(ushort *)(puVar5 + 0x238) = *(ushort *)(puVar9 + 0x37) << 8 | *(ushort *)(puVar9 + 0x37) >> 8;
    *(ushort *)(puVar5 + 0x23a) = *(ushort *)(puVar9 + 0x39) << 8 | *(ushort *)(puVar9 + 0x39) >> 8;
    *(ushort *)(puVar5 + 0x23c) = *(ushort *)(puVar9 + 0x3b) << 8 | *(ushort *)(puVar9 + 0x3b) >> 8;
    *(ushort *)(puVar5 + 0x23e) = *(ushort *)(puVar9 + 0x3d) << 8 | *(ushort *)(puVar9 + 0x3d) >> 8;
    *(ushort *)(puVar5 + 0x240) = *(ushort *)(puVar9 + 0x3f) << 8 | *(ushort *)(puVar9 + 0x3f) >> 8;
    *(ushort *)(puVar5 + 0x242) = *(ushort *)(puVar9 + 0x41) << 8 | *(ushort *)(puVar9 + 0x41) >> 8;
    *(ushort *)(puVar5 + 0x244) = *(ushort *)(puVar9 + 0x43) << 8 | *(ushort *)(puVar9 + 0x43) >> 8;
    *(ushort *)(puVar5 + 0x246) = *(ushort *)(puVar9 + 0x45) << 8 | *(ushort *)(puVar9 + 0x45) >> 8;
    *(ushort *)(puVar5 + 0x248) = *(ushort *)(puVar9 + 0x47) << 8 | *(ushort *)(puVar9 + 0x47) >> 8;
    *(ushort *)(puVar5 + 0x24a) = *(ushort *)(puVar9 + 0x49) << 8 | *(ushort *)(puVar9 + 0x49) >> 8;
    *(ushort *)(puVar5 + 0x24c) = *(ushort *)(puVar9 + 0x4b) << 8 | *(ushort *)(puVar9 + 0x4b) >> 8;
    *(ushort *)(puVar5 + 0x24e) = *(ushort *)(puVar9 + 0x4d) << 8 | *(ushort *)(puVar9 + 0x4d) >> 8;
    *(ushort *)(puVar5 + 0x250) = *(ushort *)(puVar9 + 0x4f) << 8 | *(ushort *)(puVar9 + 0x4f) >> 8;
    *(ushort *)(puVar5 + 0x252) = *(ushort *)(puVar9 + 0x51) << 8 | *(ushort *)(puVar9 + 0x51) >> 8;
    *(ushort *)(puVar5 + 0x254) = *(ushort *)(puVar9 + 0x53) << 8 | *(ushort *)(puVar9 + 0x53) >> 8;
    *(ushort *)(puVar5 + 0x256) = *(ushort *)(puVar9 + 0x55) << 8 | *(ushort *)(puVar9 + 0x55) >> 8;
    *(ushort *)(puVar5 + 600) = *(ushort *)(puVar9 + 0x57) << 8 | *(ushort *)(puVar9 + 0x57) >> 8;
    *(ushort *)(puVar5 + 0x25a) = *(ushort *)(puVar9 + 0x59) << 8 | *(ushort *)(puVar9 + 0x59) >> 8;
    *(ushort *)(puVar5 + 0x25c) = *(ushort *)(puVar9 + 0x5b) << 8 | *(ushort *)(puVar9 + 0x5b) >> 8;
    *(ushort *)(puVar5 + 0x25e) = *(ushort *)(puVar9 + 0x5d) << 8 | *(ushort *)(puVar9 + 0x5d) >> 8;
    uVar2 = *(uint *)(puVar9 + 0x5f);
    *(uint *)(puVar5 + 0x260) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    uVar2 = *(uint *)(puVar9 + 99);
    *(uint *)(puVar5 + 0x264) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    uVar2 = *(uint *)(puVar9 + 0x67);
    *(uint *)(puVar5 + 0x268) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    uVar2 = *(uint *)(puVar9 + 0x6b);
    *(uint *)(puVar5 + 0x26c) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    uVar2 = *(uint *)(puVar9 + 0x6f);
    *(uint *)(puVar5 + 0x270) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    uVar2 = *(uint *)(puVar9 + 0x73);
    *(uint *)(puVar5 + 0x274) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    uVar2 = *(uint *)(puVar9 + 0x77);
    *(uint *)(puVar5 + 0x278) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    uVar2 = *(uint *)(puVar9 + 0x7b);
    *(uint *)(puVar5 + 0x27c) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    uVar2 = *(uint *)(puVar9 + 0x7f);
    *(uint *)(puVar5 + 0x280) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    uVar2 = *(uint *)(puVar9 + 0x83);
    *(uint *)(puVar5 + 0x284) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    uVar2 = *(uint *)(puVar9 + 0x87);
    *(uint *)(puVar5 + 0x288) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
    uVar2 = *(uint *)(puVar9 + 0x8b);
    *(uint *)(puVar5 + 0x28c) =
         uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
  }
  return 0;
}


// ==== +[LevelDescriptionWindowController_runModalWithTitle:description:image:] @ 00029e86 ====

void __LevelDescriptionWindowController_runModalWithTitle_description_image__
               (undefined4 param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,
               undefined4 param_5)

{
  char cVar1;
  undefined4 uVar2;
  
  if (__sharedController_124872 == 0) {
    uVar2 = _objc_msgSend(param_1,PTR_s_alloc_0003601c);
    __sharedController_124872 = _objc_msgSend(uVar2,PTR_s_init_00036020);
  }
  _objc_msgSend(__sharedController_124872,PTR_s__setupWithTitle_description_imag_00036210,param_3,
                param_4,param_5);
  uVar2 = _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
  cVar1 = _objc_msgSend(uVar2,PTR_s_isFullscreen_00036064);
  if (cVar1 != '\0') {
    uVar2 = _objc_msgSend(__sharedController_124872,PTR_s_window_00036138,param_3,param_4,param_5);
    _objc_msgSend(uVar2,PTR_s_scheduleSetShieldingLevel_00036158);
  }
  _objc_msgSend(__sharedController_124872,PTR_s_window_00036138,param_3,param_4,param_5);
  _objc_msgSend();
  return;
}


// ==== -[LevelDescriptionWindowController_init] @ 00029f79 ====

int __LevelDescriptionWindowController_init_(undefined4 param_1)

{
  int iVar1;
  undefined4 local_14;
  undefined *local_10;
  
  local_10 = PTR_s_NSWindowController_00036404;
  local_14 = param_1;
  iVar1 = _objc_msgSendSuper(&local_14,PTR_s_initWithWindowNibName_owner__00036214,
                             &cf_LevelDescription,param_1);
  if (iVar1 != 0) {
    _objc_msgSend(iVar1,PTR_s_window_00036138);
  }
  return iVar1;
}


// ==== -[LevelDescriptionWindowController_cancel:] @ 00029fcd ====

void __LevelDescriptionWindowController_cancel__(undefined4 param_1)

{
  PTR__g_00038024[0x7c] = 1;
  _objc_msgSend(*(undefined4 *)PTR_00038014,PTR_s_stopModalWithCode__00036198,0);
  _objc_msgSend(param_1,PTR_s_window_00036138);
  _objc_msgSend();
  return;
}


// ==== -[LevelDescriptionWindowController_continue:] @ 0002a02e ====

void __LevelDescriptionWindowController_continue__(int param_1)

{
  int iVar1;
  
  iVar1 = _objc_msgSend(*(undefined4 *)(param_1 + 0x28),PTR_s_state_000361a0);
  PTR__p_00038028[0x214] = iVar1 == 1;
  _objc_msgSend(*(undefined4 *)PTR_00038014,PTR_s_stopModalWithCode__00036198,1);
  _objc_msgSend(param_1,PTR_s_window_00036138);
  _objc_msgSend();
  return;
}


// ==== -[LevelDescriptionWindowController__setupWithTitle:description:image:] @ 0002a0a7 ====

void __LevelDescriptionWindowController__setupWithTitle_description_image__
               (int param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,
               undefined4 param_5)

{
  _objc_msgSend(*(undefined4 *)(param_1 + 0x30),PTR_s_setStringValue__00036218,param_3);
  _objc_msgSend(*(undefined4 *)(param_1 + 0x34),PTR_s_setStringValue__00036218,param_4);
  _objc_msgSend(*(undefined4 *)(param_1 + 0x2c),PTR_s_setImage__0003621c,param_5);
  _objc_msgSend();
  return;
}


// ==== -[AkiView_keyDown:] @ 0002a146 ====

void __AkiView_keyDown__(void)

{
  _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
  _objc_msgSend();
  return;
}


// ==== -[AkiView_mouseDown:] @ 0002a17f ====

void __AkiView_mouseDown__(void)

{
  _objc_msgSend(PTR_s_Controller_000362ac,PTR_s_sharedController_00036134);
  _objc_msgSend();
  return;
}


// ==== -[AkiView_drawGWorld:src:dst:display:] @ 0002a1b8 ====

void __AkiView_drawGWorld_src_dst_display__
               (undefined4 param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6,undefined4 param_7,char param_8)

{
  char cVar1;
  char cVar2;
  short sVar3;
  short sVar4;
  undefined4 *puVar5;
  undefined4 *puVar6;
  undefined4 uVar7;
  undefined4 uVar8;
  int iVar9;
  int iVar10;
  undefined4 uVar11;
  undefined4 uVar12;
  undefined4 uVar13;
  short sVar14;
  short sVar15;
  undefined1 local_30 [4];
  short local_2c;
  short local_2a;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20 [4];
  
  cVar1 = param_8;
  sVar3 = (short)param_6;
  if ((param_5._2_2_ != param_4._2_2_) && ((short)param_5 != (short)param_4)) {
    sVar4 = (short)((uint)param_7 >> 0x10);
    sVar15 = (short)((uint)param_6 >> 0x10);
    if ((sVar4 != sVar15) && (sVar14 = (short)param_7, sVar14 != sVar3)) {
      _GetGWorld(&local_24,local_20);
      _SetRect(local_30,0,0,(int)(short)(sVar4 - sVar15),(int)(short)(sVar14 - sVar3));
      sVar4 = _NewGWorld(&local_28,0x20,local_30,0,0,0x100);
      if (sVar4 == 0) {
        _SetGWorld(local_28,0);
        puVar5 = (undefined4 *)_GetGWorldPixMap(param_3);
        _LockPixels(puVar5);
        puVar6 = (undefined4 *)_GetGWorldPixMap(local_28);
        _LockPixels(puVar6);
        _CopyBits(*puVar5,*puVar6,&param_4,local_30,0,0);
        _UnlockPixels(puVar5);
        _UnlockPixels(puVar6);
        _SetGWorld(local_24,local_20[0]);
        _QDFlushPortBuffer(local_28,0);
        cVar2 = _LockPixels(puVar6);
        if (cVar2 != '\0') {
          _objc_msgSend(param_1,PTR_s_lockFocus_00036178);
          uVar7 = _objc_msgSend(PTR_s_NSGraphicsContext_000362e4,PTR_s_currentContext_00036228);
          uVar8 = _CGColorSpaceCreateDeviceRGB();
          iVar9 = _GetPixRowBytes(puVar6);
          iVar10 = (int)local_2c;
          uVar11 = _GetPixBaseAddr(puVar6);
          uVar11 = _CGDataProviderCreateWithData(0,uVar11,iVar9 * iVar10,0);
          uVar12 = _GetPixRowBytes(puVar6);
          uVar12 = _CGImageCreate((int)local_2a,(int)local_2c,8,0x20,uVar12,uVar8,0x2000,uVar11,0,0,
                                  0);
          uVar13 = _objc_msgSend(uVar7,PTR_s_graphicsPort_0003622c);
          _CGContextDrawImage(uVar13,(float)(int)sVar15,(float)(600 - ((int)sVar3 + (int)local_2c)),
                              (float)(int)local_2a,(float)(int)local_2c,uVar12);
          _CGColorSpaceRelease(uVar8);
          _CGImageRelease(uVar12);
          _CGDataProviderRelease(uVar11);
          _UnlockPixels(puVar6);
          _objc_msgSend(param_1,PTR_s_unlockFocus_00036180);
          if (cVar1 != '\0') {
            _objc_msgSend(uVar7,PTR_s_flushGraphics_00036230);
          }
        }
        _DisposeGWorld(local_28);
      }
    }
  }
  return;
}


// ==== -[NSWindow(AkiAdditions)_centerWithCGDisplaySize] @ 0002a4fb ====

void __NSWindow_AkiAdditions__centerWithCGDisplaySize_(undefined4 param_1)

{
  float fVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  uint uVar4;
  float local_4c;
  undefined4 local_48;
  float local_44;
  undefined4 local_40;
  float local_3c;
  undefined4 local_38;
  float local_34;
  undefined4 local_30;
  float local_2c;
  undefined4 local_28;
  float local_24;
  undefined4 local_20;
  
  uVar2 = _objc_msgSend(param_1,PTR_s_screen_00036234);
  uVar2 = _objc_msgSend(uVar2,PTR_s_deviceDescription_00036238);
  uVar2 = _objc_msgSend(uVar2,PTR_s_objectForKey__00036028,&cf_NSScreenNumber);
  uVar2 = _objc_msgSend(uVar2,PTR_s_intValue_000360ec);
  uVar3 = _objc_msgSend(param_1,PTR_s_screen_00036234);
  _objc_msgSend_stret(&local_4c,uVar3,PTR_s_frame_000360f8);
  local_2c = local_4c;
  local_28 = local_48;
  local_24 = local_44;
  local_20 = local_40;
  _objc_msgSend(param_1,PTR_s_center_00036044);
  _objc_msgSend_stret(&local_4c,param_1,PTR_s_frame_000360f8);
  fVar1 = local_24;
  local_3c = local_4c;
  local_38 = local_48;
  local_34 = local_44;
  local_30 = local_40;
  uVar4 = _CGDisplayPixelsWide(uVar2);
  local_3c = (fVar1 - ((float)(uVar4 >> 0x10) * FLOAT_00033b30 + (float)(uVar4 & 0xffff))) *
             FLOAT_00033b3c + local_4c;
  _objc_msgSend(param_1,PTR_s_setFrameOrigin__0003618c,local_3c,local_38);
  return;
}


// ==== -[NSWindow(AkiAdditions)_scheduleSetShieldingLevel] @ 0002a656 ====

void __NSWindow_AkiAdditions__scheduleSetShieldingLevel_(undefined4 param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  undefined4 local_20 [4];
  
  puVar2 = PTR_0003800c;
  uVar3 = _objc_msgSend(PTR_s_NSArray_000362c4,PTR_s_arrayWithObject__0003623c,
                        *(undefined4 *)PTR_0003800c);
  _objc_msgSend(param_1,PTR_s_performSelector_withObject_after_00036240,
                PTR_s_centerWithCGDisplaySize_00036160,0,0,0,uVar3);
  puVar1 = PTR_s_NSInvocation_000362e8;
  uVar3 = _objc_msgSend(param_1,PTR_s_methodSignatureForSelector__00036244,PTR_s_setLevel__00036108)
  ;
  uVar3 = _objc_msgSend(puVar1,PTR_s_invocationWithMethodSignature__00036248,uVar3);
  local_20[0] = _CGShieldingWindowLevel();
  _objc_msgSend(uVar3,PTR_s_setArgument_atIndex__0003624c,local_20,2);
  _objc_msgSend(uVar3,PTR_s_setSelector__00036250,PTR_s_setLevel__00036108);
  uVar4 = _objc_msgSend(PTR_s_NSArray_000362c4,PTR_s_arrayWithObject__0003623c,*(undefined4 *)puVar2
                       );
  _objc_msgSend(uVar3,PTR_s_performSelector_withObject_after_00036240,
                PTR_s_invokeWithTarget__00036254,param_1,0,0,uVar4);
  return;
}


// ==== -[NSWindow(AkiAdditions)_scheduleSetShieldingLevelNoCenter] @ 0002a789 ====

void __NSWindow_AkiAdditions__scheduleSetShieldingLevelNoCenter_(undefined4 param_1)

{
  undefined *puVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined4 local_10;
  
  puVar1 = PTR_s_NSInvocation_000362e8;
  uVar2 = _objc_msgSend(param_1,PTR_s_methodSignatureForSelector__00036244,PTR_s_setLevel__00036108)
  ;
  uVar2 = _objc_msgSend(puVar1,PTR_s_invocationWithMethodSignature__00036248,uVar2);
  local_10 = _CGShieldingWindowLevel();
  _objc_msgSend(uVar2,PTR_s_setArgument_atIndex__0003624c,&local_10,2);
  _objc_msgSend(uVar2,PTR_s_setSelector__00036250,PTR_s_setLevel__00036108);
  uVar3 = _objc_msgSend(PTR_s_NSArray_000362c4,PTR_s_arrayWithObject__0003623c,
                        *(undefined4 *)PTR_0003800c);
  _objc_msgSend(uVar2,PTR_s_performSelector_withObject_after_00036240,
                PTR_s_invokeWithTarget__00036254,param_1,0,0,uVar3);
  return;
}


// ==== -[AkiQuitView_drawRect:] @ 0002a867 ====

void __AkiQuitView_drawRect__(void)

{
  _objc_msgSend(PTR_s_NSImage_000362bc,PTR_s_imageNamed__00036170,&cf_buyaki);
  _objc_msgSend();
  return;
}


// ==== -[AkiQuitView_performKeyEquivalent:] @ 0002a8bf ====

undefined4 __AkiQuitView_performKeyEquivalent__(undefined4 param_1)

{
  _objc_msgSend(param_1,PTR_s__done_0003625c);
  return 1;
}


// ==== -[AkiQuitView__done] @ 0002a902 ====

void __AkiQuitView__done_(undefined4 param_1)

{
  undefined *puVar1;
  
  puVar1 = PTR_00038014;
  _objc_msgSend(*(undefined4 *)PTR_00038014,PTR_s_stopModalWithCode__00036198,1);
  _objc_msgSend(*(undefined4 *)puVar1,PTR_s_terminate__000361bc,param_1);
  return;
}


// ==== -[AkiSplashWindow_initWithImage:timeout:] @ 0002a94a ====

int __AkiSplashWindow_initWithImage_timeout__
              (undefined4 param_1,undefined4 param_2,undefined4 param_3,int param_4)

{
  int iVar1;
  undefined4 uVar2;
  int iVar3;
  undefined4 local_5c;
  undefined4 local_58;
  undefined4 local_54;
  undefined4 local_50;
  undefined4 local_44;
  undefined4 local_40;
  undefined8 local_3c;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined *local_20;
  
  local_3c = _objc_msgSend(param_3,PTR_s_size_00036188);
  local_24 = param_1;
  local_40 = 0;
  local_44 = 0;
  local_20 = PTR_s_NSWindow_000364c4;
  iVar1 = _objc_msgSendSuper(&local_24,PTR_s_initWithContentRect_styleMask_ba_000360fc,0,0,local_3c,
                             0,2,0);
  iVar3 = 0;
  if (iVar1 != 0) {
    _objc_msgSend(iVar1,PTR_s_setHasShadow__00036260,1);
    uVar2 = _objc_msgSend(PTR_s_AkiSplashView_000362ec,PTR_s_alloc_0003601c);
    _objc_msgSend_stret(&local_5c,iVar1,PTR_s_frame_000360f8);
    local_28 = local_50;
    local_30 = local_58;
    local_34 = local_5c;
    local_2c = local_54;
    uVar2 = _objc_msgSend(uVar2,PTR_s_initWithFrame__00036264,local_5c,local_58,local_54,local_50);
    uVar2 = _objc_msgSend(uVar2,PTR_s_autorelease_00036100);
    _objc_msgSend(uVar2,PTR_s_setImage__0003621c,param_3);
    _objc_msgSend(iVar1,PTR_s_setContentView__00036068,uVar2);
    iVar3 = iVar1;
    if (0 < param_4) {
      uVar2 = _objc_msgSend(PTR_s_NSTimer_00036294,PTR_s_scheduledTimerWithTimeInterval_t_0003604c,
                            (double)param_4,iVar1,PTR_s__done_0003625c,0,0);
      *(undefined4 *)(iVar1 + 0x84) = uVar2;
      uVar2 = _objc_msgSend(PTR_s_NSRunLoop_00036290,PTR_s_currentRunLoop_00036050);
      _objc_msgSend(uVar2,PTR_s_addTimer_forMode__00036054,*(undefined4 *)(iVar1 + 0x84),
                    *(undefined4 *)PTR_0003800c);
    }
  }
  return iVar3;
}


// ==== -[AkiSplashWindow_center] @ 0002ab35 ====

void __AkiSplashWindow_center_(undefined4 param_1)

{
  int iVar1;
  undefined4 local_14;
  undefined *local_10;
  
  iVar1 = _objc_msgSend(*(undefined4 *)PTR_00038014,PTR_s_modalWindow_00036120);
  if (iVar1 != 0) {
    local_14 = param_1;
    local_10 = PTR_s_NSWindow_000364c4;
    _objc_msgSendSuper(&local_14,PTR_s_center_00036044);
  }
  return;
}


// ==== -[AkiSplashWindow__done] @ 0002aba7 ====

void __AkiSplashWindow__done_(int param_1)

{
  if (*(int *)(param_1 + 0x84) != 0) {
    _objc_msgSend(*(int *)(param_1 + 0x84),PTR_s_invalidate_00036078);
  }
  _objc_msgSend(*(undefined4 *)PTR_00038014,PTR_s_stopModalWithCode__00036198,1);
  _objc_msgSend();
  return;
}


// ==== -[AkiSplashView_mouseDown:] @ 0002ac01 ====

void __AkiSplashView_mouseDown__(undefined4 param_1)

{
  _objc_msgSend(param_1,PTR_s_window_00036138);
  _objc_msgSend();
  return;
}


// ==== -[AkiWindow_setFrame:display:] @ 0002ac38 ====

void __AkiWindow_setFrame_display__(void)

{
  return;
}


// ==== __RT3_LicenseSwap @ 0002ac3d ====

void __RT3_LicenseSwap(int *param_1)

{
  uint uVar1;
  
  uVar1 = *(uint *)(*param_1 + 0x200);
  *(uint *)(*param_1 + 0x200) =
       uVar1 >> 0x18 | (int)uVar1 >> 8 & 0xff00U | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  uVar1 = *(uint *)(*param_1 + 0x204);
  *(uint *)(*param_1 + 0x204) =
       uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  uVar1 = *(uint *)(*param_1 + 0x208);
  *(uint *)(*param_1 + 0x208) =
       uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  uVar1 = *(uint *)(*param_1 + 0x20c);
  *(uint *)(*param_1 + 0x20c) =
       uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  uVar1 = *(uint *)(*param_1 + 0x210);
  *(uint *)(*param_1 + 0x210) =
       uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  uVar1 = *(uint *)(*param_1 + 0x214);
  *(uint *)(*param_1 + 0x214) =
       uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  return;
}


// ==== __RT3_LogInfoSwap @ 0002ad69 ====

void __RT3_LogInfoSwap(int param_1)

{
  uint uVar1;
  uint uVar2;
  
  uVar1 = *(uint *)(param_1 + 0xf0);
  uVar2 = *(uint *)(param_1 + 0xf4);
  *(uint *)(param_1 + 0xf0) =
       uVar2 >> 0x18 | uVar2 >> 8 & 0xff00 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
  *(uint *)(param_1 + 0xf4) =
       uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  uVar1 = *(uint *)(param_1 + 0xf8);
  uVar2 = *(uint *)(param_1 + 0xfc);
  *(uint *)(param_1 + 0xf8) =
       uVar2 >> 0x18 | uVar2 >> 8 & 0xff00 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
  *(uint *)(param_1 + 0xfc) =
       uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  uVar1 = *(uint *)(param_1 + 0x100);
  *(uint *)(param_1 + 0x100) =
       uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  uVar1 = *(uint *)(param_1 + 0x104);
  *(uint *)(param_1 + 0x104) =
       uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  uVar1 = *(uint *)(param_1 + 0x108);
  *(uint *)(param_1 + 0x108) =
       uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  uVar1 = *(uint *)(param_1 + 0x10c);
  *(uint *)(param_1 + 0x10c) =
       uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  uVar1 = *(uint *)(param_1 + 0x110);
  *(uint *)(param_1 + 0x110) =
       uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  uVar1 = *(uint *)(param_1 + 0x114);
  *(uint *)(param_1 + 0x114) =
       uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  uVar1 = *(uint *)(param_1 + 0x118);
  *(uint *)(param_1 + 0x118) =
       uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  return;
}


// ==== __RT3_CalcLoginHash @ 0002b08d ====

int __RT3_CalcLoginHash(void)

{
  uid_t uVar1;
  int *piVar2;
  undefined4 uVar3;
  int iVar4;
  
  uVar1 = _getuid();
  piVar2 = (int *)_getpwuid(uVar1);
  if ((piVar2 == (int *)0x0) || (iVar4 = *piVar2, iVar4 == 0)) {
    iVar4 = 0;
  }
  else {
    uVar3 = _StringGetLength(iVar4);
    iVar4 = _MemoryChecksum(iVar4,uVar3);
    if (iVar4 == 0) {
      iVar4 = -1;
    }
  }
  return iVar4;
}


// ==== __RT3_RemoveFSEventCallback @ 0002b0d2 ====

void __RT3_RemoveFSEventCallback(void)

{
  if (_gRT3_FSEventStream != 0) {
    (*_gMyFSEventStreamStop)(_gRT3_FSEventStream);
    (*_gMyFSEventStreamInvalidate)(_gRT3_FSEventStream);
    (*_gMyFSEventStreamRelease)(_gRT3_FSEventStream);
    _gRT3_FSEventStream = 0;
  }
  return;
}


// ==== __RT3_InstallFSEventCallback @ 0002b120 ====

int __RT3_InstallFSEventCallback(void)

{
  undefined4 uVar1;
  code *pcVar2;
  short sVar3;
  undefined4 uVar4;
  int iVar5;
  int iVar6;
  int local_480;
  undefined1 local_474 [1024];
  undefined1 local_74 [76];
  int iStack_28;
  cfstringStruct *local_24;
  cfstringStruct *local_20;
  undefined4 uStack_14;
  
  uStack_14 = 0x2b12b;
  local_24 = &cf___;
  local_20 = local_24;
  if ((((((_gMyFSEventStreamCreate == (code *)0x0) &&
         (_gMyFSEventStreamCreate =
               (code *)_SystemLoadMachOSymbol(&cf_CoreServices_framework,&cf_FSEventStreamCreate),
         _gMyFSEventStreamCreate == (code *)0x0)) ||
        ((_gMyFSEventStreamScheduleWithRunLoop == (code *)0x0 &&
         (_gMyFSEventStreamScheduleWithRunLoop =
               (code *)_SystemLoadMachOSymbol
                                 (&cf_CoreServices_framework,&cf_FSEventStreamScheduleWithRunLoop),
         _gMyFSEventStreamScheduleWithRunLoop == (code *)0x0)))) ||
       ((_gMyFSEventStreamStart == (code *)0x0 &&
        (_gMyFSEventStreamStart =
              (code *)_SystemLoadMachOSymbol(&cf_CoreServices_framework,&cf_FSEventStreamStart),
        _gMyFSEventStreamStart == (code *)0x0)))) ||
      ((_gMyFSEventStreamStop == 0 &&
       (_gMyFSEventStreamStop =
             _SystemLoadMachOSymbol(&cf_CoreServices_framework,&cf_FSEventStreamStop),
       _gMyFSEventStreamStop == 0)))) ||
     (((_gMyFSEventStreamInvalidate == 0 &&
       (_gMyFSEventStreamInvalidate =
             _SystemLoadMachOSymbol(&cf_CoreServices_framework,&cf_FSEventStreamInvalidate),
       _gMyFSEventStreamInvalidate == 0)) ||
      ((_gMyFSEventStreamRelease == 0 &&
       (_gMyFSEventStreamRelease =
             _SystemLoadMachOSymbol(&cf_CoreServices_framework,&cf_FSEventStreamRelease),
       _gMyFSEventStreamRelease == 0)))))) {
    iVar5 = -0x1b5b;
LAB_0002b42b:
    local_480 = 0;
    goto LAB_0002b45f;
  }
  if ((_gMyFSEventCallback == 0) &&
     (_gMyFSEventCallback = _SystemCreateMachOWrapper(__RT3_FSEventCallback),
     _gMyFSEventCallback == 0)) {
LAB_0002b440:
    iVar5 = -0x1b5c;
  }
  else {
    sVar3 = _FSFindFolder(0xffff8005,0x70726566,0,local_74);
    if (sVar3 == 0) {
      iVar5 = _FSRefMakePath(local_74,local_474,0x400);
      if (iVar5 != 0) goto LAB_0002b42b;
      local_24 = (cfstringStruct *)_CFStringCreateWithCString(0,local_474,0x8000100);
      if (local_24 != (cfstringStruct *)0x0) {
        sVar3 = _FSFindFolder(0xffff8003,0x70726566,0,local_74);
        if (sVar3 != 0) goto LAB_0002b318;
        iVar5 = _FSRefMakePath(local_74,local_474,0x400);
        if (iVar5 != 0) goto LAB_0002b42b;
        local_20 = (cfstringStruct *)_CFStringCreateWithCString(0,local_474,0x8000100);
        if (local_20 != (cfstringStruct *)0x0) {
          local_480 = _CFArrayCreate(0,&local_24,2,0);
          if ((local_480 == 0) ||
             (_gRT3_FSEventStream =
                   (*_gMyFSEventStreamCreate)
                             (0,_gMyFSEventCallback,0,local_480,0xffffffff,0xffffffff,0,0x40000000,0
                             ), pcVar2 = _gMyFSEventStreamScheduleWithRunLoop,
             _gRT3_FSEventStream == 0)) {
            iVar5 = -0x1b5c;
          }
          else {
            uVar1 = *(undefined4 *)PTR_00038088;
            uVar4 = _CFRunLoopGetCurrent();
            (*pcVar2)(_gRT3_FSEventStream,uVar4,uVar1);
            iVar5 = 0;
            (*_gMyFSEventStreamStart)(_gRT3_FSEventStream);
          }
          goto LAB_0002b45f;
        }
      }
      goto LAB_0002b440;
    }
LAB_0002b318:
    iVar5 = (int)sVar3;
  }
  local_480 = 0;
LAB_0002b45f:
  iVar6 = 1;
  do {
    if ((&iStack_28)[iVar6] != 0) {
      _CFRelease((&iStack_28)[iVar6]);
    }
    iVar6 = iVar6 + 1;
  } while (iVar6 != 3);
  if (local_480 != 0) {
    _CFRelease(local_480);
  }
  if (iVar5 != 0) {
    __RT3_RemoveFSEventCallback();
  }
  return iVar5;
}


// ==== _RT3_GetLicenseCopies @ 0002b4ae ====

int _RT3_GetLicenseCopies(void)

{
  int iVar1;
  
  iVar1 = 0;
  if (0 < *(int *)(PTR__gRT3_License_00038074 + 0x200)) {
    iVar1 = *(int *)(PTR__gRT3_License_00038074 + 0x200);
  }
  return iVar1;
}


// ==== FUN_0002b4b3 @ 0002b4b3 ====

int FUN_0002b4b3(void)

{
  int iVar1;
  int iVar2;
  int unaff_retaddr;
  
  iVar1 = *(int *)(*(int *)(unaff_retaddr + 0xcbc1) + 0x200);
  iVar2 = 0;
  if (0 < iVar1) {
    iVar2 = iVar1;
  }
  return iVar2;
}


// ==== _RT3_IsOpen @ 0002b4cc ====

undefined1 _RT3_IsOpen(void)

{
  return _gRT3_Open;
}


// ==== FUN_0002b4d1 @ 0002b4d1 ====

undefined1 FUN_0002b4d1(void)

{
  int unaff_retaddr;
  
  return *(undefined1 *)(unaff_retaddr + 0x8c1f);
}


// ==== _RT3_GetDisplayName @ 0002b4de ====

undefined * _RT3_GetDisplayName(void)

{
  undefined *puVar1;
  
  puVar1 = PTR__gRT3_License_00038074;
  if (*PTR__gRT3_License_00038074 == '\0') {
    puVar1 = PTR__gDefaultLicenseName_00038094;
  }
  return puVar1;
}


// ==== FUN_0002b4e3 @ 0002b4e3 ====

char * FUN_0002b4e3(void)

{
  char *pcVar1;
  int unaff_retaddr;
  
  pcVar1 = *(char **)(unaff_retaddr + 0xcb91);
  if (*pcVar1 == '\0') {
    pcVar1 = *(char **)(unaff_retaddr + 0xcbb1);
  }
  return pcVar1;
}


// ==== _RT3_GetDisplayCode @ 0002b4fa ====

undefined * _RT3_GetDisplayCode(void)

{
  undefined *puVar1;
  
  puVar1 = PTR__gRT3_License_00038074 + 0x100;
  if (PTR__gRT3_License_00038074[0x100] == '\0') {
    puVar1 = PTR__gDefaultLicenseCode_00038058;
  }
  return puVar1;
}


// ==== FUN_0002b4ff @ 0002b4ff ====

int FUN_0002b4ff(void)

{
  int iVar1;
  int unaff_retaddr;
  
  iVar1 = *(int *)(unaff_retaddr + 0xcb75) + 0x100;
  if (*(char *)(*(int *)(unaff_retaddr + 0xcb75) + 0x100) == '\0') {
    iVar1 = *(int *)(unaff_retaddr + 0xcb59);
  }
  return iVar1;
}


// ==== _RT3_GetDisplayCopies @ 0002b522 ====

void _RT3_GetDisplayCopies(void)

{
  if (*(int *)(PTR__gRT3_License_00038074 + 0x200) < 1) {
    _StringCopy(PTR__gDisplayLicenseCopies_0003807c,PTR__gDefaultLicenseCopies_00038040);
  }
  else {
    _StringFromNumber(PTR__gDisplayLicenseCopies_0003807c,
                      *(int *)(PTR__gRT3_License_00038074 + 0x200));
  }
  return;
}


// ==== _RT3_GetLicenseCode @ 0002b571 ====

undefined8 _RT3_GetLicenseCode(void)

{
  uint uVar1;
  uint local_24;
  uint local_20;
  
  local_24 = 0;
  local_20 = 0;
  if (PTR__gRT3_License_00038074[0x100] == '\0') {
    local_24 = 0;
    local_20 = 0;
  }
  else {
    _RT3_LicenseTextToCode(PTR__gRT3_License_00038074 + 0x100,&local_24);
    uVar1 = _TimerGetMicroseconds();
    local_24 = local_24 ^ *(uint *)PTR__gMainHash_00038064;
    local_20 = local_20 ^ *(uint *)(PTR__gMainHash_00038064 + 4) |
               *(int *)(&_table_72031 + (uVar1 & 7) * 8) << 0x1c;
  }
  return CONCAT44(local_20,local_24);
}


// ==== _RT3_GetLicenseName @ 0002b621 ====

undefined * _RT3_GetLicenseName(void)

{
  return PTR__gPrivateLicenseName_00038054;
}


// ==== FUN_0002b626 @ 0002b626 ====

undefined4 FUN_0002b626(void)

{
  int unaff_retaddr;
  
  return *(undefined4 *)(unaff_retaddr + 0xca2e);
}


// ==== _RT3_IsRegistered @ 0002b632 ====

int _RT3_IsRegistered(void)

{
  int iVar1;
  
  iVar1 = 0;
  if (0 < *(int *)(PTR__gRT3_License_00038074 + 0x200)) {
    iVar1 = 1 << ((byte)*(undefined4 *)(PTR__gRT3_License_00038074 + 0x208) & 0x1f);
  }
  return iVar1;
}


// ==== _RT3_IsRetailLicense @ 0002b65b ====

bool _RT3_IsRetailLicense(void)

{
  char local_10c [256];
  undefined4 uStack_c;
  
  uStack_c = 0x2b664;
  _RT3_FixLicenseName(local_10c,PTR__gRT3_License_00038074);
  return (byte)(local_10c[0] - 0x30U) < 10;
}


// ==== _RT3_IsSystemLicense @ 0002b69e ====

undefined1 _RT3_IsSystemLicense(void)

{
  return *PTR__gRT3_SystemWide_0003805c;
}


// ==== FUN_0002b6a3 @ 0002b6a3 ====

undefined1 FUN_0002b6a3(void)

{
  int unaff_retaddr;
  
  return **(undefined1 **)(unaff_retaddr + 0xc9b9);
}


// ==== _RT3_CanSetSystemLicense @ 0002b6b2 ====

bool _RT3_CanSetSystemLicense(void)

{
  char cVar1;
  
  cVar1 = _SystemMacOSXOrLater();
  return cVar1 != '\0';
}


// ==== _RT3_GetDaysHad @ 0002b6c7 ====

int _RT3_GetDaysHad(void)

{
  uint uVar1;
  uint uVar2;
  int iVar3;
  
  uVar1 = _TimerGetUTCSeconds();
  uVar2 = 0;
  if (1000 < _gLicenseFileReset) {
    uVar2 = _gLicenseFileReset;
  }
  _gLicenseFileReset = uVar2;
  iVar3 = 0x5a;
  if (*(uint *)(PTR__gLogEntry_00038070 + 0x100) <= uVar1) {
    iVar3 = (uVar1 - *(uint *)(PTR__gLogEntry_00038070 + 0x100)) / 0x15180 + 1;
  }
  return iVar3;
}


// ==== _RT3_GetHoursUsed @ 0002b720 ====

uint _RT3_GetHoursUsed(void)

{
  int iVar1;
  uint uVar2;
  
  iVar1 = _TimerGetElapsedSeconds();
  if (_gRT3_StartupTime == 0) {
    uVar2 = (uint)((ulonglong)*(uint *)(PTR__gLogEntry_00038070 + 0x104) * 0x91a2b3c5 >> 0x20);
  }
  else {
    uVar2 = (uint)((ulonglong)
                   (uint)((iVar1 + *(int *)(PTR__gLogEntry_00038070 + 0x104)) - _gRT3_StartupTime) *
                   0x91a2b3c5 >> 0x20);
  }
  return uVar2 >> 0xb;
}


// ==== _RT3_GetNumLaunches @ 0002b771 ====

undefined4 _RT3_GetNumLaunches(void)

{
  return *(undefined4 *)(PTR__gLogEntry_00038070 + 0x108);
}


// ==== FUN_0002b776 @ 0002b776 ====

undefined4 FUN_0002b776(void)

{
  int unaff_retaddr;
  
  return *(undefined4 *)(*(int *)(unaff_retaddr + 0xc8fa) + 0x108);
}


// ==== __RT3_IdleNetworkClock @ 0002b788 ====

void __RT3_IdleNetworkClock(void)

{
  byte *pbVar1;
  byte bVar2;
  undefined *puVar3;
  bool bVar4;
  int iVar5;
  uint uVar6;
  int *piVar7;
  uint uVar8;
  bool bVar9;
  byte local_11c [264];
  undefined4 uStack_14;
  
  uStack_14 = 0x2b793;
  if (_gRT3_ClockCompleted != 0) {
    return;
  }
  piVar7 = (int *)PTR__gRT3_ClockResponses_0003808c;
  do {
    if (piVar7[1] != 0 || *piVar7 != 0) {
      bVar4 = true;
      goto LAB_0002b7cf;
    }
    piVar7 = piVar7 + 2;
  } while (piVar7 != (int *)(PTR__gRT3_ClockResponses_0003808c + 0x20));
  bVar4 = false;
LAB_0002b7cf:
  bVar9 = _gRT3_ClockLastTick == 0;
  iVar5 = _TimerGetTicks();
  uVar8 = iVar5 - _gRT3_ClockLastTick;
  uVar6 = _TimerGetTickRate();
  if (uVar8 < uVar6) {
    if (bVar9) goto LAB_0002b7ff;
  }
  else {
    bVar9 = true;
LAB_0002b7ff:
    if (_gRT3_ClockLastIndex == 4) goto LAB_0002b811;
  }
  if (!bVar4) {
    if (!bVar9) {
      return;
    }
    uVar6 = 0;
    puVar3 = (&_gRT3_ClockStrings)[_gRT3_ClockLastIndex];
    do {
      bVar2 = puVar3[uVar6];
      pbVar1 = local_11c + uVar6;
      *pbVar1 = bVar2;
      if (bVar2 == 0) break;
      uVar8 = uVar6 & 1;
      uVar6 = uVar6 + 1;
      *pbVar1 = (-(uVar8 == 0) & 0x1cU) + 0xa9 ^ bVar2;
    } while (uVar6 != 0x100);
    _ClockQueryServer(local_11c,0,0,0,PTR__gRT3_ClockResponses_0003808c + _gRT3_ClockLastIndex * 8,0
                     );
    _gRT3_ClockLastTick = _TimerGetTicks();
    _gRT3_ClockLastIndex = _gRT3_ClockLastIndex + 1;
    return;
  }
LAB_0002b811:
  _ClockQueryDispose();
  _gRT3_ClockCompleted = _TimerGetElapsedSeconds();
  return;
}


// ==== _RT3_BeginNetworkClock @ 0002b8e0 ====

undefined4 _RT3_BeginNetworkClock(void)

{
  char cVar1;
  undefined4 uVar2;
  
  uVar2 = 0xffffe4a6;
  if (_gRT3_Open != '\0') {
    cVar1 = _NetworkStackGetActive(0);
    uVar2 = 0;
    if (cVar1 != '\0') {
      _SystemSetIdleProc(__RT3_IdleNetworkClock);
      __RT3_IdleNetworkClock();
      uVar2 = 0;
    }
  }
  return uVar2;
}


// ==== _RT3_GetNetworkClock @ 0002b92a ====

int _RT3_GetNetworkClock(void)

{
  int iVar1;
  int iVar2;
  int *piVar3;
  int iVar4;
  
  if (_gRT3_Open != '\0') {
    iVar4 = 0;
    piVar3 = (int *)PTR__gRT3_ClockResponses_0003808c;
    do {
      if (piVar3[1] != 0 || *piVar3 != 0) {
        iVar1 = _TimerGetElapsedSeconds();
        iVar1 = iVar1 - _gRT3_ClockCompleted;
        iVar2 = _TimerGetUTCOffset(0);
        return (iVar1 - iVar2) +
               *(int *)(PTR__gRT3_ClockResponses_0003808c + iVar4 * 8 + 4) + 0x7c558180;
      }
      iVar4 = iVar4 + 1;
      piVar3 = piVar3 + 2;
    } while (iVar4 != 4);
    if (_gRT3_ClockCompleted != 0) {
      iVar4 = _TimerGetLocalSeconds();
      return iVar4;
    }
  }
  return 0;
}


// ==== _RT3_CheckLicenseName @ 0002b9b7 ====

undefined1 * _RT3_CheckLicenseName(undefined4 param_1)

{
  undefined1 *puVar1;
  
  _RT3_FixLicenseName(&_buffer_72207,param_1);
  puVar1 = (undefined1 *)0x0;
  if (_buffer_72207 != '\0') {
    puVar1 = &_buffer_72207;
  }
  return puVar1;
}


// ==== _RT3_CheckLicenseCode @ 0002b9f2 ====

undefined8 _RT3_CheckLicenseCode(byte *param_1)

{
  int iVar1;
  byte *pbVar2;
  undefined4 local_24;
  undefined4 local_20;
  undefined4 uStack_14;
  
  iVar1 = 0;
  uStack_14 = 0x2b9ff;
  local_24 = 0;
  local_20 = 0;
  for (pbVar2 = param_1; *pbVar2 != 0; pbVar2 = pbVar2 + 1) {
    iVar1 = iVar1 + (uint)(PTR__gRT3_EightBitToFiveBitChars_00038044[*pbVar2] != -1);
  }
  if (iVar1 == 0xc) {
    _RT3_LicenseTextToCode(param_1,&local_24);
  }
  return CONCAT44(local_20,local_24);
}


// ==== __RT3_LoadCFPrefs @ 0002ba57 ====

uint __regparm3 __RT3_LoadCFPrefs(int *param_1,int param_2,int param_3)

{
  char cVar1;
  int iVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  uint uVar5;
  undefined4 local_20 [4];
  
  local_20[0] = 0;
  if (((param_1 == (int *)0x0) || (param_2 == 0)) || (param_3 == 0)) {
    uVar5 = 0xffffe4a7;
  }
  else {
    *param_1 = 0;
    iVar2 = _CFPreferencesCopyValue
                      (param_2,*(undefined4 *)PTR_0003806c,*(undefined4 *)PTR_00038090,
                       *(undefined4 *)PTR_00038078);
    if (((iVar2 != 0) &&
        (cVar1 = _CFDictionaryGetValueIfPresent(iVar2,param_3,local_20), cVar1 != '\0')) &&
       ((iVar2 = _CFDataGetBytePtr(local_20[0]), iVar2 != 0 &&
        (iVar2 = _CFDataGetLength(local_20[0]), iVar2 != 0)))) {
      uVar3 = _CFDataGetLength(local_20[0]);
      uVar4 = _CFDataGetBytePtr(local_20[0]);
      iVar2 = _IndirectInitialize(uVar4,uVar3);
      *param_1 = iVar2;
      return -(uint)(iVar2 == 0) & 0xffffe4a4;
    }
    uVar5 = 0xffffe3dd;
  }
  return uVar5;
}


// ==== __RT3_CalcHashedStamp @ 0002bb45 ====

uint __RT3_CalcHashedStamp(void)

{
  uint uVar1;
  uint uVar2;
  byte *pbVar3;
  
  uVar1 = _TimerGetUTCSeconds();
  uVar2 = 0;
  for (pbVar3 = PTR__gPrivateProductName_00038068; *pbVar3 != 0; pbVar3 = pbVar3 + 1) {
    uVar2 = uVar2 >> 0x1d ^ uVar2 * 4 ^ (uint)*pbVar3;
  }
  uVar1 = uVar1 ^ uVar2;
  if (uVar1 == 0) {
    uVar1 = 1;
  }
  return uVar1;
}


// ==== __RT3_CalcIdentifier @ 0002bb92 ====

uint __regparm3 __RT3_CalcIdentifier(int param_1)

{
  int iVar1;
  byte *pbVar2;
  uint uVar3;
  undefined1 local_138 [268];
  uint local_2c;
  undefined4 uStack_14;
  
  uVar3 = 0;
  uStack_14 = 0x2bba1;
  for (pbVar2 = PTR__gPrivateProductName_00038068; *pbVar2 != 0; pbVar2 = pbVar2 + 1) {
    uVar3 = uVar3 >> 0x1d ^ uVar3 * 4 ^ (uint)*pbVar2;
  }
  if (param_1 != 0) {
    iVar1 = _FT_FileGetFlags(param_1,0,local_138,0);
    if (iVar1 != 0) {
      return uVar3;
    }
    uVar3 = uVar3 ^ local_2c;
  }
  if (uVar3 == 0) {
    uVar3 = 0xffffffff;
  }
  return uVar3;
}


// ==== _RT3_RenewLicenseCode @ 0002bc0d ====

int _RT3_RenewLicenseCode
              (undefined4 param_1,byte *param_2,int param_3,char *param_4,undefined1 *param_5)

{
  int iVar1;
  int iVar2;
  byte *pbVar3;
  char local_42c;
  undefined1 local_42b [255];
  char local_32c;
  undefined1 local_32b [255];
  char local_22c;
  undefined1 local_22b [255];
  char local_12c;
  undefined1 local_12b [255];
  int local_2c;
  int local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  local_12c = s__00032084[0];
  _memset(local_12b,0,0xff);
  local_22c = s__00032084[0];
  _memset(local_22b,0,0xff);
  local_32c = s__00032084[0];
  _memset(local_32b,0,0xff);
  local_42c = s__00032084[0];
  _memset(local_42b,0,0xff);
  iVar1 = -0x1b5a;
  if (_gRT3_Open != '\0') {
    *param_4 = '\0';
    *param_5 = 0;
    _RT3_FixLicenseName(&_buffer_72207,param_1);
    if (_buffer_72207 != '\0') {
      iVar1 = 0;
      local_2c = 0;
      local_28 = 0;
      for (pbVar3 = param_2; *pbVar3 != 0; pbVar3 = pbVar3 + 1) {
        iVar1 = iVar1 + (uint)(PTR__gRT3_EightBitToFiveBitChars_00038044[*pbVar3] != -1);
      }
      if (iVar1 == 0xc) {
        _RT3_LicenseTextToCode(param_2,&local_2c);
      }
      if ((local_28 != 0 || local_2c != 0) && (param_3 != 0)) {
        _RT3_LicenseTextToCode(param_2,&local_24);
        _RT3_LicenseCodeToText(local_24,local_20,&local_22c);
        _RT3_FixLicenseName(&local_12c,param_1);
        _StringFromNumber(&local_32c,param_3);
        if (9 < (byte)(local_12c - 0x30U)) {
          iVar1 = _GetHTTPProxy(&local_42c,0,0);
          iVar2 = _RenewLicenseTCP("register.ambrosiasw.com:80",&local_42c,
                                   PTR__gPrivateProductName_00038068,param_1,&local_32c,param_2,
                                   param_4,param_5);
          if (iVar2 != 0) {
            return iVar2;
          }
          if (*param_4 == '\0') {
            return -0x1b62;
          }
          return iVar1;
        }
      }
    }
    iVar1 = -0x1b59;
  }
  return iVar1;
}


// ==== __RT3_WriteLogEntry @ 0002be67 ====

int __regparm3 __RT3_WriteLogEntry(void *param_1)

{
  undefined4 uVar1;
  undefined4 uVar2;
  int *piVar3;
  byte bVar4;
  char cVar5;
  int iVar6;
  uint uVar7;
  undefined4 uVar8;
  int iVar9;
  byte bVar10;
  byte *pbVar11;
  uint uVar12;
  int local_340;
  undefined1 local_33c [256];
  undefined1 local_23c;
  undefined1 local_23b;
  char local_239;
  undefined1 local_220 [256];
  byte local_120 [256];
  int *local_20 [3];
  undefined4 uStack_14;
  
  uStack_14 = 0x2be72;
  _memset(local_120,0,0x100);
  local_120[0] = 0x54;
  local_120[1] = 0x33;
  local_120[2] = 0x27;
  local_120[3] = 0x2e;
  local_120[4] = 0x3d;
  local_120[5] = 0x1f;
  local_120[6] = 7;
  local_120[7] = 0x17;
  local_120[8] = 7;
  local_120[9] = 0x7f;
  local_20[0] = (int *)0x0;
  uVar7 = *(uint *)((int)param_1 + 0xf0);
  uVar12 = *(uint *)((int)param_1 + 0xf4);
  *(uint *)((int)param_1 + 0xf0) =
       uVar12 >> 0x18 | uVar12 >> 8 & 0xff00 | (uVar12 & 0xff00) << 8 | uVar12 << 0x18;
  *(uint *)((int)param_1 + 0xf4) =
       uVar7 >> 0x18 | (uVar7 & 0xff0000) >> 8 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)param_1 + 0xf8);
  uVar12 = *(uint *)((int)param_1 + 0xfc);
  *(uint *)((int)param_1 + 0xf8) =
       uVar12 >> 0x18 | uVar12 >> 8 & 0xff00 | (uVar12 & 0xff00) << 8 | uVar12 << 0x18;
  *(uint *)((int)param_1 + 0xfc) =
       uVar7 >> 0x18 | (uVar7 & 0xff0000) >> 8 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)param_1 + 0x100);
  *(uint *)((int)param_1 + 0x100) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)param_1 + 0x104);
  *(uint *)((int)param_1 + 0x104) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)param_1 + 0x108);
  *(uint *)((int)param_1 + 0x108) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)param_1 + 0x10c);
  *(uint *)((int)param_1 + 0x10c) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)param_1 + 0x110);
  *(uint *)((int)param_1 + 0x110) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)param_1 + 0x114);
  *(uint *)((int)param_1 + 0x114) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)param_1 + 0x118);
  *(uint *)((int)param_1 + 0x118) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  bVar10 = 0x7a;
  pbVar11 = local_120;
  while( true ) {
    if (*pbVar11 == 0) break;
    bVar4 = *pbVar11 ^ bVar10;
    bVar10 = bVar10 - 3;
    *pbVar11 = bVar4;
    pbVar11 = pbVar11 + 1;
  }
  iVar6 = _FT_FileLoad(0xfffffffd,local_120,0x32000,0,local_20);
  if ((iVar6 == -0x1c23) || (uVar7 = _IndirectGetSize(local_20[0]), uVar7 < 8)) {
    if (local_20[0] != (int *)0x0) {
      _IndirectDeallocate(local_20[0]);
      local_20[0] = (int *)0x0;
    }
    iVar6 = __RT3_LoadCFPrefs();
  }
  if (iVar6 == 0) {
    local_340 = _IndirectDecompress(local_20[0],0x7a6c6962,0);
    if (local_340 != -0x1b5a && local_340 != 0) goto LAB_0002c64c;
    if (local_340 != 0) goto LAB_0002c437;
    uVar7 = _IndirectGetSize(local_20[0]);
    iVar6 = 0;
    for (uVar12 = 0; uVar12 < uVar7 / 0x11c; uVar12 = uVar12 + 1) {
      iVar9 = iVar6 + *local_20[0];
      iVar6 = iVar6 + 0x11c;
      _StringCopySafe(local_220,iVar9,0x100);
      iVar9 = _StringCompare(PTR__gPrivateProductName_00038068,local_220);
      if (iVar9 == 0) break;
    }
    if (uVar7 / 0x11c == uVar12) {
      local_340 = _IndirectAppendData(local_20[0],param_1,0x11c);
      if (local_340 != 0) goto LAB_0002c64c;
    }
    else {
      _memcpy((void *)(uVar12 * 0x11c + *local_20[0]),param_1,0x11c);
    }
  }
  else {
LAB_0002c437:
    local_20[0] = (int *)_IndirectInitialize(param_1,0x11c);
    local_340 = -0x1b5c;
    if (local_20[0] == (int *)0x0) goto LAB_0002c64c;
  }
  local_340 = _IndirectCompress(local_20[0],0x7a6c6962,0);
  piVar3 = local_20[0];
  if (local_340 == 0) {
    if (local_20[0] != (int *)0x0) {
      cVar5 = _IndirectSetLock(local_20[0],1);
      uVar8 = _IndirectGetSize(piVar3);
      iVar6 = _CFDataCreate(0,*piVar3,uVar8);
      if (cVar5 == '\0') {
        _IndirectSetLock(piVar3,0);
      }
      if (iVar6 != 0) {
        iVar9 = _CFDictionaryCreateMutable(0,0,PTR_00038084,PTR_00038048);
        if (iVar9 != 0) {
          _CFDictionarySetValue(iVar9,&cf_RT3,iVar6);
          uVar8 = *(undefined4 *)PTR_00038078;
          uVar1 = *(undefined4 *)PTR_00038090;
          uVar2 = *(undefined4 *)PTR_0003806c;
          _CFPreferencesSetValue(&cf_com_ambrosiasw,iVar9,uVar2,uVar1,uVar8);
          _CFPreferencesSynchronize(uVar2,uVar1,uVar8);
          _CFRelease(iVar9);
        }
        _CFRelease(iVar6);
      }
    }
    local_340 = _FT_FileSave(0xfffffffd,local_120,1,0x3f3f3f3f,0x3f3f3f3f,local_20[0]);
    if (local_340 == 0) {
      iVar6 = _FT_FileGetFlags(0xfffffffd,local_120,local_33c,0);
      if ((iVar6 == 0) && (local_239 == '\0')) {
        local_23c = 1;
        local_23b = 1;
        local_239 = '\x01';
        _FT_FileSetFlags(0xfffffffd,local_120,local_33c);
      }
      local_340 = 0;
    }
  }
LAB_0002c64c:
  if (local_20[0] != (int *)0x0) {
    _IndirectDeallocate(local_20[0]);
  }
  uVar7 = *(uint *)((int)param_1 + 0xf0);
  uVar12 = *(uint *)((int)param_1 + 0xf4);
  *(uint *)((int)param_1 + 0xf0) =
       uVar12 >> 0x18 | uVar12 >> 8 & 0xff00 | (uVar12 & 0xff00) << 8 | uVar12 << 0x18;
  *(uint *)((int)param_1 + 0xf4) =
       uVar7 >> 0x18 | (uVar7 & 0xff0000) >> 8 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)param_1 + 0xf8);
  uVar12 = *(uint *)((int)param_1 + 0xfc);
  *(uint *)((int)param_1 + 0xf8) =
       uVar12 >> 0x18 | uVar12 >> 8 & 0xff00 | (uVar12 & 0xff00) << 8 | uVar12 << 0x18;
  *(uint *)((int)param_1 + 0xfc) =
       uVar7 >> 0x18 | (uVar7 & 0xff0000) >> 8 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)param_1 + 0x100);
  *(uint *)((int)param_1 + 0x100) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)param_1 + 0x104);
  *(uint *)((int)param_1 + 0x104) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)param_1 + 0x108);
  *(uint *)((int)param_1 + 0x108) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)param_1 + 0x10c);
  *(uint *)((int)param_1 + 0x10c) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)param_1 + 0x110);
  *(uint *)((int)param_1 + 0x110) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)param_1 + 0x114);
  *(uint *)((int)param_1 + 0x114) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)param_1 + 0x118);
  *(uint *)((int)param_1 + 0x118) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  return local_340;
}


// ==== __RT3_ReadLogEntry @ 0002c9e6 ====

int __regparm3 __RT3_ReadLogEntry(void *param_1)

{
  bool bVar1;
  bool bVar2;
  byte bVar3;
  int iVar4;
  uint uVar5;
  undefined4 uVar6;
  int iVar7;
  uint uVar8;
  byte bVar9;
  byte *pbVar10;
  bool bVar11;
  uint local_344;
  undefined1 local_33c [256];
  undefined1 local_23c;
  undefined1 local_23b;
  char local_239;
  undefined1 local_220 [256];
  byte local_120 [256];
  int *local_20 [3];
  undefined4 uStack_14;
  
  uStack_14 = 0x2c9f1;
  _memset(local_120,0,0x100);
  bVar9 = 0x7a;
  local_120[0] = 0x54;
  local_120[1] = 0x33;
  local_120[2] = 0x27;
  local_120[3] = 0x2e;
  local_120[4] = 0x3d;
  local_120[5] = 0x1f;
  local_120[6] = 7;
  local_120[7] = 0x17;
  local_120[8] = 7;
  local_120[9] = 0x7f;
  local_20[0] = (int *)0x0;
  pbVar10 = local_120;
  while( true ) {
    if (*pbVar10 == 0) break;
    bVar3 = *pbVar10 ^ bVar9;
    bVar9 = bVar9 - 3;
    *pbVar10 = bVar3;
    pbVar10 = pbVar10 + 1;
  }
  iVar4 = _FT_FileLoad(0xfffffffd,local_120,0x32000,0,local_20);
  if ((iVar4 == -0x1c23) || (uVar5 = _IndirectGetSize(local_20[0]), uVar5 < 8)) {
    if (local_20[0] != (int *)0x0) {
      _IndirectDeallocate(local_20[0]);
      local_20[0] = (int *)0x0;
    }
    iVar4 = __RT3_LoadCFPrefs();
    bVar1 = true;
    if (local_20[0] == (int *)0x0) goto LAB_0002cb0b;
  }
  else {
LAB_0002cb0b:
    bVar1 = false;
  }
  if (iVar4 == 0) {
    iVar4 = _IndirectDecompress(local_20[0],0x7a6c6962,0);
    if (iVar4 != -0x1b5a && iVar4 != 0) goto LAB_0002d1e6;
    if (iVar4 != 0) goto LAB_0002d005;
    uVar5 = _IndirectGetSize(local_20[0]);
    iVar4 = 0;
    for (local_344 = 0; local_344 < uVar5 / 0x11c; local_344 = local_344 + 1) {
      iVar7 = iVar4 + *local_20[0];
      iVar4 = iVar4 + 0x11c;
      _StringCopySafe(local_220,iVar7,0x100);
      iVar7 = _StringCompare(PTR__gPrivateProductName_00038068,local_220);
      if (iVar7 == 0) break;
    }
    bVar11 = uVar5 / 0x11c == local_344;
    if (!bVar11) {
      _memcpy(param_1,(void *)(local_344 * 0x11c + *local_20[0]),0x11c);
      uVar5 = *(uint *)((int)param_1 + 0xf0);
      uVar8 = *(uint *)((int)param_1 + 0xf4);
      *(uint *)((int)param_1 + 0xf0) =
           uVar8 >> 0x18 | uVar8 >> 8 & 0xff00 | (uVar8 & 0xff00) << 8 | uVar8 << 0x18;
      *(uint *)((int)param_1 + 0xf4) =
           uVar5 >> 0x18 | (uVar5 & 0xff0000) >> 8 | (uVar5 & 0xff00) << 8 | uVar5 << 0x18;
      uVar5 = *(uint *)((int)param_1 + 0xf8);
      uVar8 = *(uint *)((int)param_1 + 0xfc);
      *(uint *)((int)param_1 + 0xf8) =
           uVar8 >> 0x18 | uVar8 >> 8 & 0xff00 | (uVar8 & 0xff00) << 8 | uVar8 << 0x18;
      *(uint *)((int)param_1 + 0xfc) =
           uVar5 >> 0x18 | (uVar5 & 0xff0000) >> 8 | (uVar5 & 0xff00) << 8 | uVar5 << 0x18;
      uVar5 = *(uint *)((int)param_1 + 0x100);
      *(uint *)((int)param_1 + 0x100) =
           uVar5 >> 0x18 | uVar5 >> 8 & 0xff00 | (uVar5 & 0xff00) << 8 | uVar5 << 0x18;
      uVar5 = *(uint *)((int)param_1 + 0x104);
      *(uint *)((int)param_1 + 0x104) =
           uVar5 >> 0x18 | uVar5 >> 8 & 0xff00 | (uVar5 & 0xff00) << 8 | uVar5 << 0x18;
      uVar5 = *(uint *)((int)param_1 + 0x108);
      *(uint *)((int)param_1 + 0x108) =
           uVar5 >> 0x18 | uVar5 >> 8 & 0xff00 | (uVar5 & 0xff00) << 8 | uVar5 << 0x18;
      uVar5 = *(uint *)((int)param_1 + 0x10c);
      *(uint *)((int)param_1 + 0x10c) =
           uVar5 >> 0x18 | uVar5 >> 8 & 0xff00 | (uVar5 & 0xff00) << 8 | uVar5 << 0x18;
      uVar5 = *(uint *)((int)param_1 + 0x110);
      *(uint *)((int)param_1 + 0x110) =
           uVar5 >> 0x18 | uVar5 >> 8 & 0xff00 | (uVar5 & 0xff00) << 8 | uVar5 << 0x18;
      uVar5 = *(uint *)((int)param_1 + 0x114);
      *(uint *)((int)param_1 + 0x114) =
           uVar5 >> 0x18 | uVar5 >> 8 & 0xff00 | (uVar5 & 0xff00) << 8 | uVar5 << 0x18;
      uVar5 = *(uint *)((int)param_1 + 0x118);
      *(uint *)((int)param_1 + 0x118) =
           uVar5 >> 0x18 | uVar5 >> 8 & 0xff00 | (uVar5 & 0xff00) << 8 | uVar5 << 0x18;
    }
    _IndirectDeallocate(local_20[0]);
    local_20[0] = (int *)0x0;
    iVar4 = _FT_FileGetFlags(0xfffffffd,local_120,local_33c,0);
    if ((iVar4 == 0) && (!bVar11)) {
      bVar2 = false;
      bVar11 = false;
      if (local_239 != '\0') goto LAB_0002d01f;
      local_23c = 1;
      local_23b = 1;
      local_239 = '\x01';
      _FT_FileSetFlags(0xfffffffd,local_120,local_33c);
    }
    bVar2 = false;
  }
  else {
LAB_0002d005:
    bVar11 = false;
    bVar2 = true;
    if (iVar4 != -0x1c29) {
      bVar2 = false;
      bVar11 = true;
    }
  }
LAB_0002d01f:
  if (bVar1) {
LAB_0002d0fa:
    iVar4 = __RT3_WriteLogEntry();
    if (((char *)0x4 <
         "@executable_path/../Frameworks/ASWAppKit.framework/Versions/A/ASWAppKit" + iVar4 + 0xd) ||
       ((1 << ((byte)("@executable_path/../Frameworks/ASWAppKit.framework/Versions/A/ASWAppKit" +
                     iVar4 + 0xd) & 0x1f) & 0x13U) == 0)) goto LAB_0002d1e6;
  }
  else {
    if (bVar11) {
      _StringCopySafe(param_1,PTR__gPrivateProductName_00038068,0xf0);
      uVar6 = _TimerGetUTCSeconds();
      *(undefined4 *)((int)param_1 + 0x104) = 0;
      *(undefined4 *)((int)param_1 + 0x108) = 0;
      *(undefined4 *)((int)param_1 + 0x100) = uVar6;
      if (_gSavedWhenFirstRun < *(uint *)((int)param_1 + 0x100)) {
        *(uint *)((int)param_1 + 0x100) = _gSavedWhenFirstRun;
      }
      if (*(uint *)((int)param_1 + 0x108) < _gSavedNumLaunches) {
        *(uint *)((int)param_1 + 0x108) = _gSavedNumLaunches;
      }
      if (*(uint *)((int)param_1 + 0x104) < _gSavedUsageClock) {
        *(uint *)((int)param_1 + 0x104) = _gSavedUsageClock;
      }
      *(undefined4 *)((int)param_1 + 0x10c) = 0;
      *(undefined4 *)((int)param_1 + 0x110) = 0;
      *(undefined4 *)((int)param_1 + 0x114) = 0;
      *(undefined4 *)((int)param_1 + 0x118) = 0;
      goto LAB_0002d0fa;
    }
    if (!bVar2) {
      uVar5 = *(uint *)((int)param_1 + 0x100);
      if (_gSavedWhenFirstRun <= *(uint *)((int)param_1 + 0x100)) {
        uVar5 = _gSavedWhenFirstRun;
      }
      uVar8 = *(uint *)((int)param_1 + 0x108);
      if (*(uint *)((int)param_1 + 0x108) <= _gSavedNumLaunches) {
        uVar8 = _gSavedNumLaunches;
      }
      iVar4 = 0;
      _gSavedNumLaunches = uVar8;
      _gSavedWhenFirstRun = uVar5;
      if (_gSavedUsageClock < *(uint *)((int)param_1 + 0x104)) {
        _gSavedUsageClock = *(uint *)((int)param_1 + 0x104);
      }
      goto LAB_0002d1e6;
    }
  }
  iVar4 = 0;
  _StringCopySafe(param_1,PTR__gPrivateProductName_00038068,0xf0);
  iVar7 = _TimerGetUTCSeconds();
  *(undefined4 *)((int)param_1 + 0x104) = 360000;
  *(undefined4 *)((int)param_1 + 0x108) = 100;
  *(int *)((int)param_1 + 0x100) = iVar7 + -0x755580;
  *(undefined4 *)((int)param_1 + 0x10c) = 0;
  *(undefined4 *)((int)param_1 + 0x110) = 0;
  *(undefined4 *)((int)param_1 + 0x114) = 0;
  *(undefined4 *)((int)param_1 + 0x118) = 0;
LAB_0002d1e6:
  if (local_20[0] != (int *)0x0) {
    _IndirectDeallocate(local_20[0]);
  }
  return iVar4;
}


// ==== __RT3_LicenseSave @ 0002d202 ====

int __regparm3 __RT3_LicenseSave(int *param_1,uint param_2,int param_3,char param_4)

{
  int iVar1;
  undefined *puVar2;
  char cVar3;
  int *piVar4;
  int iVar5;
  int iVar6;
  undefined4 uVar7;
  uint uVar8;
  byte *pbVar9;
  undefined1 local_11c [264];
  undefined4 uStack_14;
  
  uStack_14 = 0x2d20f;
  _StringCopySafe(local_11c,PTR__gPrivateProductName_00038068,0x100);
  _StringAppendSafe(local_11c," License",0x100);
  iVar1 = *(int *)(*param_1 + 0x200);
  piVar4 = (int *)_IndirectDuplicate(param_1);
  if (piVar4 == (int *)0x0) {
    return -0x1b5c;
  }
  if (param_2 == 0) {
    iVar5 = *piVar4;
    uVar7 = __RT3_CalcIdentifier();
    *(undefined4 *)(iVar5 + 0x204) = uVar7;
    if (param_4 != '\0') goto LAB_0002d311;
    iVar5 = *piVar4;
    uVar7 = __RT3_CalcLoginHash();
    *(undefined4 *)(iVar5 + 0x20c) = uVar7;
  }
  else {
    uVar8 = 0;
    for (pbVar9 = PTR__gPrivateProductName_00038068; *pbVar9 != 0; pbVar9 = pbVar9 + 1) {
      uVar8 = uVar8 >> 0x1d ^ uVar8 * 4 ^ (uint)*pbVar9;
    }
    *(uint *)(*piVar4 + 0x204) = uVar8 ^ param_2;
LAB_0002d311:
    *(undefined4 *)(*piVar4 + 0x20c) = 0;
  }
  uVar8 = *(uint *)(*piVar4 + 0x200);
  *(uint *)(*piVar4 + 0x200) =
       uVar8 >> 0x18 | (int)uVar8 >> 8 & 0xff00U | (uVar8 & 0xff00) << 8 | uVar8 << 0x18;
  uVar8 = *(uint *)(*piVar4 + 0x204);
  *(uint *)(*piVar4 + 0x204) =
       uVar8 >> 0x18 | uVar8 >> 8 & 0xff00 | (uVar8 & 0xff00) << 8 | uVar8 << 0x18;
  uVar8 = *(uint *)(*piVar4 + 0x208);
  *(uint *)(*piVar4 + 0x208) =
       uVar8 >> 0x18 | uVar8 >> 8 & 0xff00 | (uVar8 & 0xff00) << 8 | uVar8 << 0x18;
  uVar8 = *(uint *)(*piVar4 + 0x20c);
  *(uint *)(*piVar4 + 0x20c) =
       uVar8 >> 0x18 | uVar8 >> 8 & 0xff00 | (uVar8 & 0xff00) << 8 | uVar8 << 0x18;
  uVar8 = *(uint *)(*piVar4 + 0x210);
  *(uint *)(*piVar4 + 0x210) =
       uVar8 >> 0x18 | uVar8 >> 8 & 0xff00 | (uVar8 & 0xff00) << 8 | uVar8 << 0x18;
  uVar8 = *(uint *)(*piVar4 + 0x214);
  *(uint *)(*piVar4 + 0x214) =
       uVar8 >> 0x18 | uVar8 >> 8 & 0xff00 | (uVar8 & 0xff00) << 8 | uVar8 << 0x18;
  iVar5 = _IndirectCompress(piVar4,0x7a6c6962,0);
  if (iVar5 == 0) {
    if ((param_4 == '\0') || (cVar3 = _SystemRunningAsAdmin(), cVar3 != '\0')) {
      iVar5 = _FT_FileSave((-(uint)(param_4 == '\0') & 4) - 7,local_11c,1,0x416c6963,0x41726567,
                           piVar4);
    }
    else {
      iVar5 = -0x1b5c;
      _IndirectSetLock(piVar4,1);
      iVar6 = _GetPathToSystemPreferences(local_11c);
      if (iVar6 == 0) goto LAB_0002d598;
      uVar7 = _IndirectGetSize(piVar4);
      iVar5 = _WriteToFileAsSuperUser(iVar6,*piVar4,uVar7);
    }
    if (iVar5 == 0) {
      _gLicenseFileReset = _gLicenseFileReset + 1;
      _gRT3_LicenseDates = 0;
      __RT3_ReadLogEntry();
      iVar5 = _TimerGetUTCSeconds();
      puVar2 = PTR__gLogEntry_00038070;
      if ((param_4 == '\0') && (0x2a2ff < (param_3 - iVar5) + 0x15180U)) {
        uVar7 = 0;
        if (iVar1 != 0) {
          uVar7 = __RT3_CalcHashedStamp();
        }
        *(undefined4 *)(PTR__gLogEntry_00038070 + 0x110) = uVar7;
      }
      else {
        *(undefined4 *)(PTR__gLogEntry_00038070 + 0x110) = 0;
        *(undefined4 *)(puVar2 + 0x10c) = 0;
      }
      iVar5 = 0;
      __RT3_WriteLogEntry();
    }
  }
LAB_0002d598:
  _IndirectDeallocate(piVar4);
  return iVar5;
}


// ==== __RT3_LicenseLoad @ 0002d5ad ====

int __regparm3 __RT3_LicenseLoad(undefined4 *param_1,undefined1 *param_2,undefined1 *param_3)

{
  undefined *puVar1;
  int iVar2;
  uint uVar3;
  uint uVar4;
  uint uVar5;
  byte *pbVar6;
  int *piVar7;
  uint uVar8;
  bool bVar9;
  uint uVar10;
  bool bVar11;
  int local_154;
  int *local_150;
  int local_14c;
  int *local_13c;
  int local_130;
  undefined1 local_12c [256];
  uint local_2c;
  uint local_28;
  int *local_20 [4];
  
  local_20[0] = (int *)0x0;
  *param_1 = 0;
  *param_2 = 0;
  if (param_3 != (undefined1 *)0x0) {
    *param_3 = 0;
  }
  uVar10 = 0;
  for (pbVar6 = PTR__gPrivateProductName_00038068; *pbVar6 != 0; pbVar6 = pbVar6 + 1) {
    uVar10 = uVar10 >> 0x1d ^ uVar10 * 4 ^ (uint)*pbVar6;
  }
  _StringCopySafe(local_12c,PTR__gPrivateProductName_00038068,0x100);
  _StringAppendSafe(local_12c," License",0x100);
  local_13c = &_gRT3_LicensePaths;
  local_150 = (int *)0x0;
  local_14c = 0;
  do {
    iVar2 = _FT_FileGetFlags(*local_13c,local_12c,0,0);
    if (iVar2 == 0) {
      iVar2 = _FT_FileLoad(*local_13c,local_12c,0x5000,0,local_20);
    }
    if (iVar2 == -0x1b5c) {
      local_130 = -0x1b5c;
      iVar2 = local_130;
      goto LAB_0002dd03;
    }
    if (iVar2 == 0) {
      local_130 = _IndirectDecompress(local_20[0],0x7a6c6962,0);
      if (local_130 != -0x1b5a && local_130 != 0) {
        local_154 = 0;
        goto LAB_0002dcf9;
      }
      if ((((local_130 == 0) && (local_20[0] != (int *)0x0)) &&
          (uVar3 = _IndirectGetSize(local_20[0]), 0x217 < uVar3)) &&
         (iVar2 = *local_20[0], *(int *)(iVar2 + 0x204) != 0)) {
        uVar3 = *(uint *)(iVar2 + 0x200);
        *(uint *)(iVar2 + 0x200) =
             uVar3 >> 0x18 | (int)uVar3 >> 8 & 0xff00U | (uVar3 & 0xff00) << 8 | uVar3 << 0x18;
        uVar3 = *(uint *)(*local_20[0] + 0x204);
        *(uint *)(*local_20[0] + 0x204) =
             uVar3 >> 0x18 | uVar3 >> 8 & 0xff00 | (uVar3 & 0xff00) << 8 | uVar3 << 0x18;
        uVar3 = *(uint *)(*local_20[0] + 0x208);
        *(uint *)(*local_20[0] + 0x208) =
             uVar3 >> 0x18 | uVar3 >> 8 & 0xff00 | (uVar3 & 0xff00) << 8 | uVar3 << 0x18;
        uVar3 = *(uint *)(*local_20[0] + 0x20c);
        *(uint *)(*local_20[0] + 0x20c) =
             uVar3 >> 0x18 | uVar3 >> 8 & 0xff00 | (uVar3 & 0xff00) << 8 | uVar3 << 0x18;
        uVar3 = *(uint *)(*local_20[0] + 0x210);
        *(uint *)(*local_20[0] + 0x210) =
             uVar3 >> 0x18 | uVar3 >> 8 & 0xff00 | (uVar3 & 0xff00) << 8 | uVar3 << 0x18;
        uVar3 = *(uint *)(*local_20[0] + 0x214);
        *(uint *)(*local_20[0] + 0x214) =
             uVar3 >> 0x18 | uVar3 >> 8 & 0xff00 | (uVar3 & 0xff00) << 8 | uVar3 << 0x18;
        uVar3 = *(uint *)(*local_20[0] + 0x204);
        uVar4 = __RT3_CalcIdentifier();
        if ((uVar3 != (uVar10 ^ 0xa5a5a5a5)) && (uVar3 != uVar4)) {
          iVar2 = (uVar3 ^ uVar10) - (uVar4 ^ uVar10);
          if (iVar2 < 0) {
            iVar2 = -iVar2;
          }
          if ((0x15180 < iVar2) || ((iVar2 % 0xf) * 0x3c != 0)) goto LAB_0002d991;
        }
        if ((*local_13c == -7) ||
           (((*(int *)(*local_20[0] + 0x20c) == 0 || (iVar2 = __RT3_CalcLoginHash(), iVar2 == 0)) ||
            (iVar2 == *(int *)(*local_20[0] + 0x20c))))) {
          piVar7 = local_20[0];
          if (local_150 != (int *)0x0) {
            if (((*(int *)(*local_150 + 0x200) != 0) || (*(int *)(*local_20[0] + 0x200) == 0)) &&
               (*(uint *)(*local_20[0] + 0x208) <= *(uint *)(*local_150 + 0x208)))
            goto LAB_0002d991;
            _IndirectDeallocate(local_150);
            piVar7 = local_20[0];
          }
          local_20[0] = (int *)0x0;
          local_14c = *local_13c;
          local_150 = piVar7;
        }
      }
    }
LAB_0002d991:
    local_13c = local_13c + 1;
  } while (local_13c != &_gRT3_LicenseHdl);
  local_154 = 0;
  bVar11 = local_150 != (int *)0x0;
  if (bVar11) {
    local_20[0] = local_150;
    local_154 = local_14c;
  }
  if (((*PTR__gLogStuff_0003803c == '\0' || !bVar11) || (*(int *)(*local_20[0] + 0x200) == 0)) ||
     (local_130 = __RT3_ReadLogEntry(), local_130 == 0)) {
    local_130 = 0;
  }
  if ((bVar11 && *PTR__gLogStuff_0003803c != '\0') && (*(int *)(*local_20[0] + 0x200) != 0)) {
    uVar3 = *(uint *)(PTR__gLogEntry_00038070 + 0x10c);
    uVar4 = *(uint *)(PTR__gLogEntry_00038070 + 0x110);
    uVar5 = _TimerGetUTCSeconds();
    puVar1 = PTR__gLogEntry_00038070;
    uVar8 = 0;
    if (uVar3 != 0) {
      uVar8 = uVar3 ^ uVar10;
    }
    uVar10 = uVar10 ^ uVar4;
    if (uVar4 == 0) {
      uVar10 = 0;
    }
    if ((local_154 != -7) || (bVar9 = true, uVar10 == 0 && uVar8 == 0)) {
      if (uVar10 == 0 || uVar8 == 0) {
        bVar9 = false;
        if (uVar8 == 0 && uVar10 != 0) {
          if (0x24e9ff < (int)(uVar5 - uVar10)) goto LAB_0002db42;
          bVar9 = 0 < (int)(uVar5 - uVar10);
        }
      }
      else if ((uVar5 - uVar8 < 0x93a81) && (uVar10 + 0x15180 < uVar8 || uVar5 < uVar10)) {
LAB_0002db42:
        bVar11 = false;
        bVar9 = false;
      }
      else {
        bVar9 = 0x93a80 < (int)(uVar5 - uVar8);
      }
    }
    if ((bool)(bVar11 & bVar9)) {
      *(undefined4 *)(PTR__gLogEntry_00038070 + 0x10c) = 0;
      *(undefined4 *)(puVar1 + 0x110) = 0;
      iVar2 = __RT3_WriteLogEntry();
      if (iVar2 != 0) {
        local_130 = iVar2;
      }
    }
  }
  if (((((bool)(bVar11 & *PTR__gLogStuff_0003803c != '\0')) && (*(int *)(*local_20[0] + 0x200) != 0)
       ) && (uVar10 = *(uint *)(PTR__gLogEntry_00038070 + 0x108), uVar10 != 0)) &&
     (uVar10 == (uVar10 / 3) * 3)) {
    _RT3_LicenseTextToCode(*local_20[0] + 0x100,&local_2c);
    if ((((*(uint *)(PTR__gLogEntry_00038070 + 0xf4) ^ local_28) & 0x7bdfef7) == 0 &&
         ((*(uint *)(PTR__gLogEntry_00038070 + 0xf0) ^ local_2c) & 0xfbdfef78) == 0) ||
       (((*(uint *)(PTR__gLogEntry_00038070 + 0xfc) ^ local_28) & 0x7bdfef7) == 0 &&
        ((*(uint *)(PTR__gLogEntry_00038070 + 0xf8) ^ local_2c) & 0xfbdfef78) == 0)) {
LAB_0002dc4e:
      if (local_20[0] == (int *)0x0) {
        local_20[0] = (int *)_IndirectAllocate(0x218);
        if (local_20[0] == (int *)0x0) {
          return -0x1b5c;
        }
      }
      else {
        iVar2 = _IndirectSetSize(local_20[0],0x218);
        if (iVar2 != 0) goto LAB_0002dd03;
      }
      _MemoryClear(*local_20[0],0x218);
      *(undefined4 *)(*local_20[0] + 0x200) = 0;
      *(undefined4 *)(*local_20[0] + 0x208) = 0;
      *(undefined4 *)(*local_20[0] + 0x20c) = 0;
      *param_2 = 1;
    }
  }
  else if (!bVar11) goto LAB_0002dc4e;
LAB_0002dcf9:
  iVar2 = local_130;
  if (local_130 == 0) {
    if (local_20[0] == (int *)0x0) {
      return 0;
    }
    *param_1 = local_20[0];
    if (local_154 == -7 && param_3 != (undefined1 *)0x0) {
      *param_3 = 1;
    }
    _IndirectSetLock(local_20[0],1);
    *(int *)PTR_00038080 = *local_20[0];
    return 0;
  }
LAB_0002dd03:
  local_130 = iVar2;
  if (local_20[0] != (int *)0x0) {
    _IndirectDeallocate(local_20[0]);
  }
  return local_130;
}


// ==== __RT3_LicenseRefresh @ 0002dd74 ====

int __RT3_LicenseRefresh(void)

{
  bool bVar1;
  undefined *puVar2;
  int iVar3;
  int *piVar4;
  undefined4 *puVar5;
  undefined8 uVar6;
  int *piVar7;
  int *piVar8;
  undefined1 *puVar9;
  undefined1 *puVar10;
  int local_254;
  int *local_250;
  undefined1 local_244 [272];
  int local_134;
  undefined1 local_128 [256];
  int local_28 [2];
  char local_1d;
  undefined4 uStack_14;
  
  uStack_14 = 0x2dd7f;
  local_28[0] = 1;
  local_28[1] = 1;
  local_1d = '\0';
  puVar5 = &_gRT3_LicensePaths;
  puVar9 = local_128;
  _StringCopySafe(puVar9,PTR__gPrivateProductName_00038068,0x100);
  _StringAppendSafe(puVar9," License",0x100);
  piVar8 = &_gRT3_LicenseDates;
  piVar4 = local_28;
  puVar10 = local_244;
  bVar1 = false;
  local_254 = 1;
  piVar7 = piVar4;
  local_250 = piVar8;
  do {
    iVar3 = _FT_FileGetFlags(*puVar5,puVar9,0,0,piVar7,piVar8,puVar9,puVar10);
    if ((iVar3 == 0) && (iVar3 = _FT_FileGetFlags(*puVar5,puVar9,puVar10,0), iVar3 == 0)) {
      *piVar4 = local_134;
    }
    if (*piVar4 != *local_250) {
      bVar1 = true;
    }
    local_250 = local_250 + 1;
    local_254 = local_254 + 1;
    piVar4 = piVar4 + 1;
    puVar5 = puVar5 + 1;
  } while (local_254 != 3);
  if (bVar1 && _gRT3_LicenseHdl != (undefined4 *)0x0) {
    _IndirectDeallocate(_gRT3_LicenseHdl);
    _gRT3_LicenseHdl = (undefined4 *)0x0;
  }
  if (_gRT3_LicenseHdl == (undefined4 *)0x0) {
    iVar3 = __RT3_LicenseLoad();
    if (iVar3 != 0) {
      return iVar3;
    }
    _MemoryCopy(PTR__gRT3_License_00038074,*_gRT3_LicenseHdl,0x218);
    _MemoryCopy(piVar8,piVar7,8);
  }
  else if (!bVar1) {
    return 0;
  }
  if (*PTR__gRT3_License_00038074 == '\0') {
    _StringCopy(PTR__gPrivateLicenseName_00038054,PTR__gRT3_License_00038074);
  }
  else {
    _RT3_FixLicenseName(PTR__gPrivateLicenseName_00038054,PTR__gRT3_License_00038074);
  }
  if (*(int *)(PTR__gRT3_License_00038074 + 0x200) < 1) {
    _StringCopy(PTR__gDisplayLicenseCopies_0003807c,PTR__gDefaultLicenseCopies_00038040);
  }
  else {
    _StringFromNumber(PTR__gDisplayLicenseCopies_0003807c,
                      *(int *)(PTR__gRT3_License_00038074 + 0x200));
  }
  puVar2 = PTR__gRT3_License_00038074;
  *(bool *)*(undefined4 *)PTR_0003804c = 0 < *(int *)(PTR__gRT3_License_00038074 + 0x200);
  uVar6 = _RT3_CalcMainHash(PTR__gPrivateProductName_00038068,PTR__gPrivateLicenseName_00038054,
                            *(undefined4 *)(puVar2 + 0x200));
  *(undefined8 *)PTR__gMainHash_00038064 = uVar6;
  if (local_1d != '\0') {
    __RT3_LicenseSave(0);
  }
  return 0;
}


// ==== _RT3_ResetLicenseInfo @ 0002e03b ====

int _RT3_ResetLicenseInfo(void)

{
  undefined4 *puVar1;
  int iVar2;
  int iVar3;
  
  iVar3 = -0x1b5a;
  if (_gRT3_Open != '\0') {
    iVar3 = -0x1b5c;
    puVar1 = (undefined4 *)_IndirectAllocate(0x218);
    if (puVar1 != (undefined4 *)0x0) {
      _MemoryClear(*puVar1,0x218);
      iVar3 = __RT3_LicenseSave(0);
      iVar2 = __RT3_LicenseRefresh();
      if (iVar2 != 0) {
        iVar3 = iVar2;
      }
      _IndirectDeallocate(puVar1);
    }
  }
  return iVar3;
}


// ==== _RT3_EnableCrackDetection @ 0002e0b9 ====

void _RT3_EnableCrackDetection(char param_1)

{
  if (param_1 != '\0') {
    *(char **)PTR_00038080 = "";
    _MemoryClear(PTR__gRT3_License_00038074,0x218);
    _MemoryClear(&_gRT3_LicenseDates,8);
    _MemoryClear(*(undefined4 *)PTR_0003804c,1);
    _MemoryClear(PTR__gPrivateLicenseName_00038054,0x100);
    return;
  }
  __RT3_LicenseRefresh();
  return;
}


// ==== _RT3_Idle @ 0002e144 ====

void _RT3_Idle(void)

{
  int iVar1;
  uint uVar2;
  
  if (_gRT3_Open != '\0') {
    iVar1 = _TimerGetTicks();
    uVar2 = iVar1 - _lastCheck_71900;
    if ((_lastCheck_71900 == 0) || (iVar1 = _TimerGetTickRate(), (uint)(iVar1 * 2) < uVar2)) {
      __RT3_LicenseRefresh();
      _lastCheck_71900 = _TimerGetTicks();
    }
    *(uint *)(*(int *)PTR_0003804c + -3) =
         *(uint *)(*(int *)PTR_0003804c + -3) ^ _lastCheck_71900 >> 8;
    return;
  }
  return;
}


// ==== __RT3_FSEventCallback @ 0002e1ab ====

void __RT3_FSEventCallback(void)

{
  __RT3_LicenseRefresh();
  return;
}


// ==== _RT3_SetLicenseInfo @ 0002e1b5 ====

int _RT3_SetLicenseInfo(undefined4 param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,
                       undefined4 param_5,undefined4 param_6,undefined1 param_7)

{
  int iVar1;
  undefined4 uVar2;
  int iVar3;
  undefined1 local_12c [256];
  undefined4 local_2c;
  undefined4 local_28;
  int *local_24;
  undefined1 local_1d;
  
  local_24 = (int *)0x0;
  local_1d = 0;
  local_2c = 0;
  local_28 = 0;
  iVar1 = -0x1b5a;
  if (_gRT3_Open != '\0') {
    _RT3_LicenseTextToCode(param_2,&local_2c);
    _RT3_LicenseCodeToText(local_2c,local_28,local_12c);
    iVar1 = __RT3_LicenseLoad();
    if (iVar1 == 0) {
      _StringCopySafe(*local_24,param_1,0x100);
      _StringCopySafe(*local_24 + 0x100,local_12c,0x100);
      *(undefined4 *)(*local_24 + 0x200) = param_3;
      iVar1 = *local_24;
      uVar2 = __RT3_CalcIdentifier();
      *(undefined4 *)(iVar1 + 0x204) = uVar2;
      *(undefined4 *)(*local_24 + 0x208) = param_4;
      iVar1 = *local_24;
      uVar2 = __RT3_CalcLoginHash();
      *(undefined4 *)(iVar1 + 0x20c) = uVar2;
      iVar1 = __RT3_LicenseSave(param_7);
      if (iVar1 == 0) {
        iVar3 = __RT3_LicenseRefresh();
        if (iVar3 != 0) {
          iVar1 = iVar3;
        }
      }
    }
  }
  if (local_24 != (int *)0x0) {
    _IndirectDeallocate(local_24);
  }
  return iVar1;
}


// ==== _RT3_CreateLicenseFile @ 0002e307 ====

undefined4
_RT3_CreateLicenseFile
          (undefined4 param_1,byte *param_2,undefined4 param_3,undefined4 param_4,undefined1 param_5
          )

{
  undefined4 uVar1;
  undefined4 uVar2;
  byte *pbVar3;
  int iVar4;
  char local_124 [256];
  int local_24;
  int local_20;
  
  uVar1 = 0xffffe4a6;
  if (_gRT3_Open != '\0') {
    _RT3_FixLicenseName(&_buffer_72207,param_1);
    if (_buffer_72207 != '\0') {
      iVar4 = 0;
      local_24 = 0;
      local_20 = 0;
      for (pbVar3 = param_2; *pbVar3 != 0; pbVar3 = pbVar3 + 1) {
        iVar4 = iVar4 + (uint)(PTR__gRT3_EightBitToFiveBitChars_00038044[*pbVar3] != -1);
      }
      if (iVar4 == 0xc) {
        _RT3_LicenseTextToCode(param_2,&local_24);
      }
      if (local_20 != 0 || local_24 != 0) {
        _RT3_FixLicenseName(local_124,param_1);
        uVar1 = 1;
        if (9 < (byte)(local_124[0] - 0x30U)) {
          uVar1 = param_3;
        }
        uVar2 = _TimerGetUTCSeconds();
        uVar1 = _RT3_SetLicenseInfo(param_1,param_2,uVar1,param_4,0,uVar2,param_5);
        return uVar1;
      }
    }
    uVar1 = 0xffffe4a7;
  }
  return uVar1;
}


// ==== _RT3_IncNumLaunches @ 0002e423 ====

void _RT3_IncNumLaunches(void)

{
  __RT3_ReadLogEntry();
  _gSavedNumLaunches = _gSavedNumLaunches + 1;
  *(int *)(PTR__gLogEntry_00038070 + 0x108) = *(int *)(PTR__gLogEntry_00038070 + 0x108) + 1;
  __RT3_WriteLogEntry();
  return;
}


// ==== _RT3_Close @ 0002e458 ====

void _RT3_Close(void)

{
  undefined *puVar1;
  uint uVar2;
  int iVar3;
  int iVar4;
  undefined4 uVar5;
  
  if (_gRT3_Open != '\0') {
    if (*PTR__gLogStuff_0003803c != '\0') {
      __RT3_ReadLogEntry();
      puVar1 = PTR__gLogEntry_00038070;
      uVar2 = _gRT3_StartupTime;
      _gSavedNumLaunches = _gSavedNumLaunches + 1;
      *(int *)(PTR__gLogEntry_00038070 + 0x108) = *(int *)(PTR__gLogEntry_00038070 + 0x108) + 1;
      if (uVar2 != 0) {
        uVar2 = _TimerGetElapsedSeconds();
        if (_gRT3_StartupTime < uVar2) {
          iVar4 = *(int *)(puVar1 + 0x104);
          iVar3 = _TimerGetElapsedSeconds();
          *(uint *)(puVar1 + 0x104) = iVar4 + (iVar3 - _gRT3_StartupTime);
          iVar4 = _TimerGetElapsedSeconds();
          _gSavedUsageClock = _gSavedUsageClock + (iVar4 - _gRT3_StartupTime);
        }
      }
      if (*(int *)(PTR__gRT3_License_00038074 + 0x200) < 1) {
        uVar5 = __RT3_CalcHashedStamp();
        *(undefined4 *)(PTR__gLogEntry_00038070 + 0x10c) = uVar5;
      }
      __RT3_WriteLogEntry();
    }
    *(char **)PTR_00038080 = "";
    if (_gRT3_LicenseHdl != 0) {
      _IndirectDeallocate(_gRT3_LicenseHdl);
      _gRT3_LicenseHdl = 0;
    }
    _MemoryClear(*(undefined4 *)PTR_0003804c,1);
    _gRT3_Open = '\0';
  }
  return;
}


// ==== _RT3_Open @ 0002e567 ====

int _RT3_Open(char param_1,short param_2,undefined4 param_3,undefined4 param_4)

{
  int iVar1;
  
  iVar1 = 0;
  if (_gRT3_Open == '\0') {
    iVar1 = _PlatformOpen();
    if (iVar1 == 0) {
      iVar1 = _FT_Open();
      if (iVar1 == 0) {
        iVar1 = -0x1b5a;
        if (param_2 == -0x7ffd || param_2 == 3) {
          _RT3_InitTables();
          if (param_1 != '\0') {
            _StringCopySafe(PTR__gDefaultLicenseName_00038094,"NOT REGISTERED",0x100);
            _StringCopySafe(PTR__gDefaultLicenseCopies_00038040,"N/A",0x100);
            _StringCopySafe(PTR__gDefaultLicenseCode_00038058,"N/A",0x100);
          }
          *(short *)PTR__gRT3_CodeVersion_00038050 = param_2;
          _StringCopy(PTR__gDisplayProductName_00038060,param_4);
          _StringCopy(PTR__gDisplayLicenseCopies_0003807c,PTR__gDefaultLicenseCopies_00038040);
          _StringCopy(PTR__gPrivateProductName_00038068,param_3);
          _MemoryClear(PTR__gPrivateLicenseName_00038054,0x100);
          _gLicenseFileReset = 0;
          *PTR__gLogStuff_0003803c = param_1;
          if (param_1 != '\0') {
            _gRT3_StartupTime = _TimerGetElapsedSeconds();
          }
          iVar1 = __RT3_ReadLogEntry();
          if (iVar1 == 0) {
            iVar1 = __RT3_LicenseRefresh();
            if (iVar1 == 0) {
              iVar1 = __RT3_InstallFSEventCallback();
              if (iVar1 != 0) {
                _SystemSetIdleProc(_RT3_Idle);
              }
              _gRT3_Open = '\x01';
              iVar1 = 0;
            }
          }
        }
      }
    }
  }
  return iVar1;
}


// ==== _RT3_InitTables @ 0002e707 ====

void _RT3_InitTables(void)

{
  int iVar1;
  char *pcVar2;
  undefined *puVar3;
  int iVar4;
  undefined *puVar5;
  
  puVar3 = PTR__gRT3_EightBitToFiveBitChars_00038044;
  if (_gInited_70503 == '\0') {
    iVar4 = 0;
    puVar5 = PTR__gRT3_EightBitToFiveBitChars_00038044;
    do {
      *puVar5 = 0xff;
      iVar1 = 0;
      pcVar2 = _gRT3_FiveBitToEightBitChars;
      do {
        if (*pcVar2 == iVar4) {
          *puVar5 = (char)iVar1;
        }
        iVar1 = iVar1 + 1;
        pcVar2 = pcVar2 + 1;
      } while (iVar1 != 0x20);
      iVar4 = iVar4 + 1;
      puVar5 = puVar5 + 1;
    } while (iVar4 != 0x100);
    puVar5 = PTR__gRT3_EightBitToFiveBitChars_00038044 + 0x1a;
    do {
      puVar3[0x61] = puVar3[0x41];
      puVar3 = puVar3 + 1;
    } while (puVar5 != puVar3);
    _gInited_70503 = '\x01';
  }
  return;
}


// ==== _RT3_CalcTimePeriod @ 0002e77e ====

uint _RT3_CalcTimePeriod(uint param_1)

{
  uint uVar1;
  
  uVar1 = 0;
  if (0x3a500ecf < param_1) {
    uVar1 = (param_1 + 0xc5b92bb0) / 0x127500 & 0xff;
  }
  return uVar1;
}


// ==== _RT3_FixProductName @ 0002e7a3 ====

void _RT3_FixProductName(char *param_1,char *param_2)

{
  char cVar1;
  char *pcVar2;
  
  for (pcVar2 = param_1; (uint)((int)pcVar2 - (int)param_1) < 0xff; pcVar2 = pcVar2 + 1) {
    cVar1 = *param_2;
    param_2 = param_2 + 1;
    *pcVar2 = cVar1;
    if (cVar1 == '\0') break;
    if ((byte)(cVar1 + 0x9fU) < 0x1a) {
      *pcVar2 = cVar1 + -0x20;
    }
    else if ((0x19 < (byte)(cVar1 + 0xbfU)) && (9 < (byte)(cVar1 - 0x30U))) {
      *pcVar2 = '_';
    }
  }
  if ((int)pcVar2 - (int)param_1 == 0xff) {
    *pcVar2 = '\0';
  }
  return;
}


// ==== _RT3_FixLicenseName @ 0002e7f5 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _RT3_FixLicenseName(char *param_1,char *param_2)

{
  char cVar1;
  uint uVar2;
  char *pcVar3;
  char *pcVar4;
  uint local_14;
  
  local_14 = 0;
  for (pcVar3 = param_2;
      ((cVar1 = *pcVar3, local_14 < 0xff && cVar1 != '\0' && (0x19 < (byte)(cVar1 + 0x9fU))) &&
      (0x19 < (byte)(cVar1 + 0xbfU))); pcVar3 = pcVar3 + 1) {
    if ((byte)(cVar1 - 0x30U) < 10) {
      param_1[local_14] = cVar1;
      local_14 = local_14 + 1;
    }
  }
  pcVar4 = param_1;
  if ((ram0x00034160 == -0x7ffd) && (local_14 == 6 && *pcVar3 == '\0')) {
    pcVar4 = param_1 + local_14;
    uVar2 = (int)pcVar4 - (int)param_1;
  }
  else {
    while (uVar2 = (int)pcVar4 - (int)param_1, uVar2 < 0xff) {
      cVar1 = *param_2;
      param_2 = param_2 + 1;
      *pcVar4 = cVar1;
      if (cVar1 == '\0') goto LAB_0002e8b2;
      if ((byte)(cVar1 + 0x9fU) < 0x1a) {
        *pcVar4 = cVar1 + -0x20;
        pcVar4 = pcVar4 + 1;
      }
      else {
        pcVar4 = pcVar4 + ((byte)(cVar1 + 0xbfU) < 0x1a);
      }
    }
  }
  if (uVar2 < 0x100) {
LAB_0002e8b2:
    *pcVar4 = '\0';
  }
  return;
}


// ==== _RT3_CalcMainHash @ 0002e8bd ====

undefined8 _RT3_CalcMainHash(char *param_1,char *param_2,int param_3)

{
  char cVar1;
  uint uVar2;
  uint uVar3;
  uint local_34;
  uint local_1c;
  uint local_18;
  int local_10;
  
  local_1c = 0;
  local_18 = 0;
  local_34 = param_3 * 7;
  for (; cVar1 = *param_1, cVar1 != '\0'; param_1 = param_1 + 1) {
    uVar2 = (local_18 >> 0x1c | local_1c << 4) ^ (int)cVar1;
    uVar3 = (local_1c >> 0x1c | local_18 << 4) ^ (int)cVar1 >> 0x1f;
    local_18 = uVar2 >> 0x1f | uVar3 * 2;
    local_1c = (uVar3 >> 0x1f | uVar2 * 2) ^ local_34;
    local_34 = local_34 + param_3;
  }
  local_10 = 0x27;
  for (; cVar1 = *param_2, cVar1 != '\0'; param_2 = param_2 + 1) {
    uVar2 = (local_18 >> 0x1d | local_1c << 3) ^ (int)cVar1;
    uVar3 = (local_1c >> 0x1d | local_18 << 3) ^ (int)cVar1 >> 0x1f;
    local_18 = uVar2 >> 0x1f | uVar3 * 2;
    local_1c = local_10 * param_3;
    local_10 = local_10 + 3;
    local_1c = (uVar3 >> 0x1f | uVar2 * 2) ^ local_1c;
  }
  uVar3 = 0;
  uVar2 = 1;
  if (local_18 != 0 || local_1c != 0) {
    uVar3 = local_18 & 0xfffffff;
    uVar2 = local_1c;
  }
  return CONCAT44(uVar3,uVar2);
}


// ==== _RT3_LicenseCodeToText @ 0002e9ea ====

void _RT3_LicenseCodeToText(uint param_1,uint param_2,char *param_3)

{
  byte bVar1;
  uint uVar2;
  char *pcVar3;
  uint local_1c;
  int local_18;
  
  if (param_3 != (char *)0x0) {
    local_18 = 4;
    local_1c = 0;
    bVar1 = 0x37;
    do {
      uVar2 = param_1 >> (bVar1 & 0x1f) | (param_2 & 0xfffffff) << 0x20 - (bVar1 & 0x1f);
      if ((bVar1 & 0x20) != 0) {
        uVar2 = (param_2 & 0xfffffff) >> (bVar1 & 0x1f);
      }
      *param_3 = _gRT3_FiveBitToEightBitChars[uVar2 & 0x1f];
      pcVar3 = param_3 + 1;
      local_18 = local_18 + -1;
      if (local_18 == 0) {
        param_3[1] = -(local_1c < 0xb) & 0x2d;
        pcVar3 = param_3 + 2;
        local_18 = 4;
      }
      local_1c = local_1c + 1;
      bVar1 = bVar1 - 5;
      param_3 = pcVar3;
    } while (local_1c != 0xc);
  }
  return;
}


// ==== _RT3_LicenseCodeEnswizzle @ 0002ea85 ====

undefined8 _RT3_LicenseCodeEnswizzle(ushort param_1,ushort param_2,ushort param_3,byte param_4)

{
  byte bVar1;
  uint uVar2;
  uint uVar3;
  uint uVar4;
  uint uVar5;
  uint uVar6;
  int iVar7;
  uint uVar8;
  undefined4 local_b0;
  undefined4 local_a8;
  
  uVar5 = (uint)(param_1 >> 0xc) * 2;
  uVar6 = (((((((uVar5 | param_4 & 1) << 4 | param_2 >> 8 & 0xf) * 2 | param_4 >> 1 & 1) << 4 |
             param_3 >> 4 & 0xf) << 4 | param_1 & 0xf) * 2 | param_4 >> 2 & 1) << 4 |
          (uint)(param_2 >> 0xc)) * 2;
  uVar3 = (((uVar6 | param_4 >> 3 & 1) << 4 | param_3 >> 8 & 0xf) << 4 | param_1 >> 4 & 0xf) * 2;
  uVar8 = ((uVar3 | param_4 >> 4 & 1) << 4 | param_2 & 0xf) * 2;
  uVar4 = (((uVar8 | param_4 >> 5 & 1) << 4 | (uint)(param_3 >> 0xc)) << 4 | param_1 >> 8 & 0xf) * 2
  ;
  local_a8 = 0;
  uVar2 = ((uVar4 | param_4 >> 6 & 1) << 4 | param_2 >> 4 & 0xf) * 2;
  uVar8 = (((((((uVar5 & 0xfffffff0 | (uVar6 & 0x7fffff) >> 0x13) << 1 | (uVar3 & 0xfffffff) >> 0x1b
               ) << 4 | (uVar3 & 0x7ffffff) >> 0x17) << 4 | (uVar8 & 0xfffffff) >> 0x18) << 1 |
            (uVar8 & 0xffffff) >> 0x17) << 4 | (uVar8 & 0x7fffff) >> 0x13) << 1 |
          (uVar4 & 0xfffffff) >> 0x1b) << 4 | (uVar4 & 0x7ffffff) >> 0x17;
  uVar5 = (uVar2 | param_4 >> 7) << 4 | param_3 & 0xf;
  uVar6 = 0;
  do {
    bVar1 = (byte)uVar6 & 0x1f;
    uVar4 = uVar5 >> bVar1 | uVar8 << 0x20 - bVar1;
    if ((uVar6 & 0x20) != 0) {
      uVar4 = uVar8 >> ((byte)uVar6 & 0x1f);
    }
    uVar6 = uVar6 + 3;
    local_a8 = local_a8 + (uVar4 & 7);
  } while (uVar6 != 0x39);
  local_b0 = uVar8 << 3 | (uVar2 & 0xfffffff) >> 0x19;
  uVar5 = uVar5 << 3 | local_a8 & 7;
  iVar7 = 1;
  for (uVar6 = uVar5 ^ local_b0; uVar6 != 0; uVar6 = uVar6 & uVar6 - 1) {
    iVar7 = 1 - iVar7;
  }
  if (iVar7 != 0) {
    local_b0 = local_b0 | 0x8000000;
  }
  return CONCAT44(local_b0,uVar5);
}


// ==== _RT3_LicenseCodeDeswizzle @ 0002ee97 ====

undefined4
_RT3_LicenseCodeDeswizzle
          (uint param_1,uint param_2,ushort *param_3,ushort *param_4,ushort *param_5,byte *param_6)

{
  uint uVar1;
  byte bVar2;
  uint uVar3;
  uint uVar4;
  uint uVar5;
  undefined4 uVar6;
  uint uVar7;
  uint uVar8;
  uint uVar9;
  undefined2 local_14;
  
  if (param_3 != (ushort *)0x0) {
    *param_3 = 0;
  }
  if (param_4 != (ushort *)0x0) {
    *param_4 = 0;
  }
  if (param_5 != (ushort *)0x0) {
    *param_5 = 0;
  }
  if (param_6 != (byte *)0x0) {
    *param_6 = 0;
  }
  uVar7 = param_2 & 0x7ffffff;
  uVar5 = 0;
  uVar1 = param_1 >> 3;
  uVar3 = uVar1 | param_2 << 0x1d;
  uVar9 = 0;
  uVar8 = uVar7 >> 3;
  do {
    bVar2 = (byte)uVar5 & 0x1f;
    uVar4 = uVar3 >> bVar2 | uVar8 << 0x20 - bVar2;
    if ((uVar5 & 0x20) != 0) {
      uVar4 = uVar8 >> ((byte)uVar5 & 0x1f);
    }
    uVar5 = uVar5 + 3;
    uVar9 = uVar9 + (uVar4 & 7);
  } while (uVar5 != 0x39);
  if ((param_1 & 7) == (uVar9 & 7)) {
    if (param_5 != (ushort *)0x0) {
      local_14 = (ushort)uVar1;
      *param_5 = *param_5 | local_14 & 0xf;
    }
    if (param_6 != (byte *)0x0) {
      *param_6 = *param_6 | (byte)((uVar3 >> 4) << 7);
    }
    if (param_4 != (ushort *)0x0) {
      *param_4 = *param_4 | (ushort)(((uVar1 & 0x1e0) >> 5) << 4);
    }
    if (param_6 != (byte *)0x0) {
      *param_6 = *param_6 | (byte)(((uVar1 & 0x200) >> 9) << 6);
    }
    if (param_3 != (ushort *)0x0) {
      *param_3 = *param_3 | (ushort)(((uVar1 & 0x3c00) >> 10) << 8);
    }
    if (param_5 != (ushort *)0x0) {
      *param_5 = *param_5 | (ushort)((uVar3 >> 0xe) << 0xc);
    }
    if (param_6 != (byte *)0x0) {
      *param_6 = *param_6 | (byte)(((uVar1 & 0x40000) >> 0x12) << 5);
    }
    if (param_4 != (ushort *)0x0) {
      *param_4 = *param_4 | (ushort)(uVar3 >> 0x13) & 0xf;
    }
    if (param_6 != (byte *)0x0) {
      *param_6 = *param_6 | (byte)(((uVar1 & 0x800000) >> 0x17) << 4);
    }
    if (param_3 != (ushort *)0x0) {
      *param_3 = *param_3 | (ushort)(((uVar1 & 0xf000000) >> 0x18) << 4);
    }
    if (param_5 != (ushort *)0x0) {
      *param_5 = *param_5 | (ushort)((uVar3 >> 0x1c) << 8);
    }
    if (param_6 != (byte *)0x0) {
      *param_6 = *param_6 | (byte)((uVar8 & 1) << 3);
    }
    if (param_4 != (ushort *)0x0) {
      *param_4 = *param_4 | (ushort)((uVar7 >> 4) << 0xc);
    }
    if (param_6 != (byte *)0x0) {
      *param_6 = *param_6 | (byte)((uVar7 >> 8 & 1) << 2);
    }
    if (param_3 != (ushort *)0x0) {
      *param_3 = *param_3 | (ushort)(uVar7 >> 9) & 0xf;
    }
    if (param_5 != (ushort *)0x0) {
      *param_5 = *param_5 | (ushort)((uVar7 >> 0xd & 0xf) << 4);
    }
    if (param_6 != (byte *)0x0) {
      *param_6 = *param_6 | ((byte)(uVar7 >> 0x11) & 1) * '\x02';
    }
    if (param_4 != (ushort *)0x0) {
      *param_4 = *param_4 | (ushort)((uVar7 >> 0x12 & 0xf) << 8);
    }
    if (param_6 != (byte *)0x0) {
      *param_6 = *param_6 | (byte)(uVar7 >> 0x16) & 1;
    }
    uVar6 = 1;
    if (param_3 != (ushort *)0x0) {
      *param_3 = *param_3 | (ushort)((uVar7 >> 0x17) << 0xc);
    }
  }
  else {
    if (param_3 != (ushort *)0x0) {
      *param_3 = 0x79b7;
    }
    if (param_4 != (ushort *)0x0) {
      *param_4 = 0x77b9;
    }
    if (param_5 != (ushort *)0x0) {
      *param_5 = 0x7033;
    }
    uVar6 = 0;
    if (param_6 != (byte *)0x0) {
      *param_6 = 0;
    }
  }
  return uVar6;
}


// ==== _RT3_CalcLicenseChecksum @ 0002f196 ====

ulonglong _RT3_CalcLicenseChecksum(uint param_1,uint param_2)

{
  byte bVar1;
  uint uVar2;
  uint uVar3;
  uint uVar4;
  uint uVar5;
  uint uVar6;
  undefined4 local_10;
  
  uVar3 = 0;
  local_10 = 0;
  uVar6 = (param_2 & 0x7ffffff) >> 3;
  do {
    bVar1 = (byte)uVar3 & 0x1f;
    uVar4 = uVar6 >> ((byte)uVar3 & 0x1f);
    uVar2 = (param_1 >> 3 | param_2 << 0x1d) >> bVar1 | uVar6 << 0x20 - bVar1;
    uVar5 = uVar4;
    if ((uVar3 & 0x20) != 0) {
      uVar5 = 0;
      uVar2 = uVar4;
    }
    uVar3 = uVar3 + 3;
    local_10 = local_10 + (uVar2 & 7);
  } while (uVar3 != 0x39);
  return CONCAT44(uVar5,local_10) & 0xffffffff00000007;
}


// ==== _RT3_ExtractLicenseChecksum @ 0002f1ec ====

uint _RT3_ExtractLicenseChecksum(uint param_1)

{
  return param_1 & 7;
}


// ==== _RT3_ExtractLicenseTimestamp @ 0002f1f7 ====

uint _RT3_ExtractLicenseTimestamp(uint param_1,uint param_2)

{
  uint uVar1;
  
  uVar1 = param_1 >> 0xc;
  return (param_1 >> 7 & 1) << 7 | (uVar1 & 1) << 6 | ((uVar1 & 0x200) >> 9) << 5 |
         ((uVar1 & 0x4000) >> 0xe) << 4 | ((param_2 << 0x14 & 0x800000) >> 0x17) << 3 |
         ((param_2 << 0x14 & 0x10000000) >> 0x1c) << 2 | ((param_2 >> 0xc & 0x20) >> 5) * 2 |
         (param_2 >> 0x15 & 2) >> 1;
}


// ==== _RT3_ExtractLicenseBlock1 @ 0002f289 ====

uint _RT3_ExtractLicenseBlock1(uint param_1,uint param_2)

{
  return (param_1 >> 0xd & 0xf) << 8 | (param_1 >> 0x1b & 0xf) << 4 | (param_2 & 0x1e00) >> 9 |
         ((param_2 & 0x7ffffff) >> 0x17) << 0xc;
}


// ==== _RT3_ExtractLicenseBlock2 @ 0002f2e5 ====

uint _RT3_ExtractLicenseBlock2(uint param_1,uint param_2)

{
  return (param_1 >> 8 & 0xf) << 4 | param_1 >> 0x16 & 0xf | ((param_2 & 0xf0) >> 4) << 0xc |
         ((param_2 & 0x3fffff) >> 0x12) << 8;
}


// ==== _RT3_ExtractLicenseBlock3 @ 0002f341 ====

uint _RT3_ExtractLicenseBlock3(uint param_1,uint param_2)

{
  return param_1 >> 3 & 0xf | (param_1 >> 0x11 & 0xf) << 0xc |
         ((param_1 >> 0x11 | param_2 << 0xf) >> 0xe & 0xf) << 8 | ((param_2 & 0x1ffff) >> 0xd) << 4;
}


// ==== _RT3_GetTimePeriod @ 0002f396 ====

uint _RT3_GetTimePeriod(void)

{
  uint uVar1;
  uint uVar2;
  
  uVar1 = _TimerGetUTCSeconds();
  uVar2 = 0;
  if (0x3a500ecf < uVar1) {
    uVar2 = (uVar1 + 0xc5b92bb0) / 0x127500;
  }
  return uVar2 & 0xff;
}


// ==== _RT3_LicenseTextToCode @ 0002f3bf ====

void _RT3_LicenseTextToCode(byte *param_1,uint *param_2)

{
  int iVar1;
  char *pcVar2;
  undefined *puVar3;
  int iVar4;
  undefined *puVar5;
  uint local_24;
  uint local_20;
  uint local_18;
  
  puVar3 = PTR__gRT3_EightBitToFiveBitChars_00038044;
  if (_gInited_70503 == '\0') {
    iVar4 = 0;
    puVar5 = PTR__gRT3_EightBitToFiveBitChars_00038044;
    do {
      *puVar5 = 0xff;
      iVar1 = 0;
      pcVar2 = _gRT3_FiveBitToEightBitChars;
      do {
        if (*pcVar2 == iVar4) {
          *puVar5 = (char)iVar1;
        }
        iVar1 = iVar1 + 1;
        pcVar2 = pcVar2 + 1;
      } while (iVar1 != 0x20);
      iVar4 = iVar4 + 1;
      puVar5 = puVar5 + 1;
    } while (iVar4 != 0x100);
    puVar5 = PTR__gRT3_EightBitToFiveBitChars_00038044 + 0x1a;
    do {
      puVar3[0x61] = puVar3[0x41];
      puVar3 = puVar3 + 1;
    } while (puVar5 != puVar3);
    _gInited_70503 = '\x01';
  }
  local_24 = 0;
  local_20 = 0;
  if (param_2 != (uint *)0x0 && param_1 != (byte *)0x0) {
    local_18 = 0;
    do {
      if (*param_1 == 0) break;
      if (PTR__gRT3_EightBitToFiveBitChars_00038044[*param_1] != 0xff) {
        local_18 = local_18 + 1;
        local_20 = local_20 << 5 | local_24 >> 0x1b;
        local_24 = local_24 << 5 | (uint)(byte)PTR__gRT3_EightBitToFiveBitChars_00038044[*param_1];
      }
      param_1 = param_1 + 1;
    } while (local_18 < 0xc);
  }
  *param_2 = local_24;
  param_2[1] = local_20;
  return;
}


// ==== _EncodeParameterSafe @ 0002f4b8 ====

void __regparm3 _EncodeParameterSafe(byte *param_1,byte *param_2,uint param_3)

{
  byte bVar1;
  byte bVar2;
  byte bVar3;
  uint local_14;
  byte *local_10;
  
  local_14 = param_3;
  local_10 = param_2;
  while (3 < local_14) {
    bVar3 = *local_10;
    local_10 = local_10 + 1;
    if (bVar3 == 0) break;
    if (((byte)(bVar3 - 0x21) < 0x5f && bVar3 != 0x26) && (bVar3 != 0x25 && bVar3 != 0x2f)) {
      local_14 = local_14 - 1;
      *param_1 = bVar3;
      param_1 = param_1 + 1;
    }
    else {
      bVar1 = bVar3 >> 4;
      bVar3 = bVar3 & 0xf;
      bVar2 = bVar1 + 0x30;
      if (9 < bVar1) {
        bVar2 = bVar1 + 0x37;
      }
      param_1[1] = bVar2;
      bVar2 = bVar3 + 0x30;
      if (9 < bVar3) {
        bVar2 = bVar3 + 0x37;
      }
      local_14 = local_14 - 3;
      *param_1 = 0x25;
      param_1[2] = bVar2;
      param_1 = param_1 + 3;
    }
  }
  *param_1 = 0;
  return;
}


// ==== _RenewLicenseTCP @ 0002f549 ====

int _RenewLicenseTCP(char *param_1,char *param_2,char *param_3,char *param_4,char *param_5,
                    char *param_6,undefined1 *param_7,undefined1 *param_8)

{
  char cVar1;
  uint uVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  undefined4 uVar6;
  char *pcVar7;
  undefined1 *puVar8;
  undefined1 *local_888;
  undefined1 *local_884;
  char *local_870;
  undefined1 local_864 [1024];
  undefined1 local_464 [260];
  undefined1 local_360 [256];
  undefined1 local_260 [256];
  undefined1 local_160 [256];
  undefined1 local_60 [32];
  undefined1 local_40 [16];
  undefined1 local_30 [16];
  undefined1 *local_20 [4];
  
  local_20[0] = (undefined1 *)0x0;
  *param_7 = 0;
  *param_8 = 0;
  if ((((*param_3 != '\0') && (*param_4 != '\0')) && (*param_5 != '\0')) && (*param_6 != '\0')) {
    uVar2 = _StringGetLength(param_6);
    local_870 = param_5;
    if (0xb < uVar2) {
      for (; (cVar1 = *local_870, cVar1 < '0' && cVar1 != '\0' && ('9' < cVar1));
          local_870 = local_870 + 1) {
      }
      if (cVar1 != '\0') {
        _MemoryClear(local_40,0x10);
        _MemoryClear(local_30,0x10);
        if ((param_2 == (char *)0x0) || (*param_2 == '\0')) {
          param_2 = param_1;
        }
        iVar3 = _SimpleResolve(0,param_2,local_464);
        if ((((iVar3 != 0) || (iVar3 = _QueueCreate(local_40), iVar3 != 0)) ||
            (iVar3 = _QueueCreate(local_30), iVar3 != 0)) ||
           (iVar3 = _NetworkQueueFill(local_40,3,4,0x400), iVar3 != 0)) goto LAB_0002fa5f;
        iVar3 = -0x1b5c;
        iVar4 = _StreamCreate(0,0,0,local_40,local_40,local_30,local_30);
        if (iVar4 == 0) goto LAB_0002fa5f;
        iVar3 = _StreamOpenClient(iVar4,0,local_464,&DAT_00002710);
        if (iVar3 == 0) {
          _EncodeParameterSafe();
          _EncodeParameterSafe();
          _EncodeParameterSafe();
          _EncodeParameterSafe();
          iVar3 = -0x1b5c;
          puVar8 = local_864;
          _StringFormatSafe(puVar8,0x400,
                            "GET http://%s/p=%s&n=%s&c=%s&l=%s HTTP/1.1\r\nConnection: Close\r\nPragma: no-cache\r\n\r\n"
                            ,param_1,local_260,local_360,local_60,local_160,puVar8);
          iVar5 = _QueueRemove(local_40);
          if (iVar5 != 0) {
            _StringCopy(iVar5 + 0x1c,puVar8);
            uVar6 = _StringGetLength(puVar8);
            *(undefined4 *)(iVar5 + 0x18) = uVar6;
            iVar3 = _StreamSend(iVar4,iVar5);
            if (iVar3 == 0) {
              local_864[0] = 0;
              local_20[0] = (undefined1 *)0x0;
              do {
                do {
                  iVar3 = _StringGetLength(puVar8);
                  if (0x3ff < iVar3 + 1U) goto LAB_0002f91c;
                  iVar3 = _NetworkQueueWait(local_30,10);
                  if (iVar3 == 0) {
                    iVar3 = -0x1b60;
                    goto LAB_0002fa51;
                  }
                  if (*(uint *)(iVar3 + 0x14) <= *(uint *)(iVar3 + 0x18)) {
                    *(uint *)(iVar3 + 0x18) = *(uint *)(iVar3 + 0x14) - 1;
                  }
                  *(undefined1 *)(*(int *)(iVar3 + 0x18) + 0x1c + iVar3) = 0;
                  _StringAppendSafe(puVar8,iVar3 + 0x1c,0x400);
                  _QueueInsert(local_40,iVar3);
                  local_870 = (char *)_StringFindString(puVar8,"\r\n\r\n");
                } while (local_870 == (char *)0x0);
                local_870 = local_870 + 4;
                local_20[0] = (undefined1 *)_StringFindString(local_870,"\r\n");
              } while (local_20[0] == (undefined1 *)0x0);
LAB_0002f91c:
              _StreamClose(iVar4,1);
              if (local_20[0] == (undefined1 *)0x0) {
                pcVar7 = "Server response invalid or incomplete";
LAB_0002f966:
                _StringCopy(param_8,pcVar7);
              }
              else {
                if (*local_870 == '<') {
                  pcVar7 = "Renewal blocked by web proxy or firewall";
                  goto LAB_0002f966;
                }
                *local_20[0] = 0;
                _MemoryCopy(puVar8,local_870,local_20[0] + (1 - (int)local_870));
                local_20[0] = (undefined1 *)0x0;
                iVar3 = _StringTokenize(puVar8,9,local_20);
                if (iVar3 != 0) {
                  _StringCopySafe(param_7,iVar3,0x100);
                }
                iVar3 = 0;
                pcVar7 = (char *)_StringTokenize(puVar8,9,local_20);
                if (pcVar7 == (char *)0x0) goto LAB_0002fa51;
                iVar3 = _StringGetLength(pcVar7);
                if ((*pcVar7 == '<') && (pcVar7[iVar3 + -1] == '>')) {
                  pcVar7[iVar3 + -1] = '\0';
                  pcVar7 = pcVar7 + 1;
                }
                _StringCopySafe(param_8,pcVar7,0x100);
              }
              iVar3 = 0;
            }
          }
        }
LAB_0002fa51:
        _StreamDispose(iVar4);
        goto LAB_0002fa5f;
      }
    }
  }
  iVar3 = -0x1b59;
LAB_0002fa5f:
  local_884 = local_40;
  local_888 = local_30;
  _QueueEmpty(local_888);
  _QueueDispose(local_888);
  _QueueEmpty(local_884);
  _QueueDispose(local_884);
  return iVar3;
}


// ==== _RenewLicenseUDP @ 0002faa4 ====

int _RenewLicenseUDP(undefined4 param_1,char *param_2,char *param_3,char *param_4,char *param_5,
                    undefined1 *param_6,undefined1 *param_7)

{
  char cVar1;
  uint uVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  undefined4 uVar6;
  char *pcVar7;
  undefined1 *local_568;
  undefined1 local_544 [1024];
  undefined1 local_144 [260];
  undefined1 local_40 [16];
  undefined1 local_30 [16];
  undefined4 local_20 [4];
  
  *param_6 = 0;
  *param_7 = 0;
  if ((((*param_2 != '\0') && (*param_3 != '\0')) && (*param_4 != '\0')) &&
     ((*param_5 != '\0' && (uVar2 = _StringGetLength(param_5), pcVar7 = param_4, 0xb < uVar2)))) {
    for (; (cVar1 = *pcVar7, cVar1 < '0' && cVar1 != '\0' && ('9' < cVar1)); pcVar7 = pcVar7 + 1) {
    }
    if (cVar1 != '\0') {
      _MemoryClear(local_30,0x10);
      _MemoryClear(local_40,0x10);
      iVar3 = _SimpleResolve(0,param_1,local_144);
      if (((iVar3 == 0) && (iVar3 = _QueueCreate(local_30), iVar3 == 0)) &&
         ((iVar3 = _QueueCreate(local_40), iVar3 == 0 &&
          (iVar3 = _NetworkQueueFill(local_30,2,4,0x400), iVar3 == 0)))) {
        iVar3 = -0x1b5c;
        iVar4 = _DatagramCreate(0,0,0,local_30,local_30,local_40,local_40);
        if (iVar4 != 0) {
          iVar3 = _DatagramOpen(iVar4,0);
          if (iVar3 == 0) {
            iVar3 = -0x1b5c;
            _StringFormatSafe(local_544,0x400,"%s\t%s\t%s\t%s",param_2,param_3,param_4,param_5);
            iVar5 = _QueueRemove(local_30);
            if (iVar5 != 0) {
              _AddressDuplicate(iVar5 + 0x14,local_144);
              _StringCopy(iVar5 + 0x120,local_544);
              uVar6 = _StringGetLength(local_544);
              *(undefined4 *)(iVar5 + 0x11c) = uVar6;
              iVar3 = _DatagramSend(iVar4,iVar5);
              if (iVar3 == 0) {
                iVar3 = -0x1b60;
                iVar5 = _NetworkQueueWait(local_40,5);
                if (iVar5 != 0) {
                  if (*(uint *)(iVar5 + 0x118) <= *(uint *)(iVar5 + 0x11c)) {
                    *(uint *)(iVar5 + 0x11c) = *(uint *)(iVar5 + 0x118) - 1;
                  }
                  *(undefined1 *)(*(int *)(iVar5 + 0x11c) + 0x120 + iVar5) = 0;
                  local_20[0] = 0;
                  iVar3 = _StringTokenize(iVar5 + 0x120,9,local_20);
                  if (iVar3 != 0) {
                    _StringCopySafe(param_6,iVar3,0x100);
                  }
                  iVar3 = _StringTokenize(iVar5 + 0x120,9,local_20);
                  if (iVar3 != 0) {
                    _StringCopySafe(param_7,iVar3,0x100);
                  }
                  iVar3 = 0;
                  _QueueInsert(local_30,iVar5);
                }
              }
            }
          }
          _DatagramDispose(iVar4);
        }
      }
      goto LAB_0002fe18;
    }
  }
  iVar3 = -0x1b59;
LAB_0002fe18:
  local_568 = local_30;
  _QueueEmpty(local_40);
  _QueueDispose(local_40);
  _QueueEmpty(local_568);
  _QueueDispose(local_568);
  return iVar3;
}


// ==== _GetPathToSystemPreferences @ 0002fe51 ====

int _GetPathToSystemPreferences(undefined4 param_1)

{
  char cVar1;
  short sVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  uint uVar6;
  int local_74;
  int local_6c;
  int local_68;
  undefined1 local_5c [80];
  
  sVar2 = _FSFindFolder(0xffff8003,0x70726566,1,local_5c);
  if ((sVar2 == 0) && (iVar3 = _CFURLCreateFromFSRef(0,local_5c), iVar3 != 0)) {
    iVar4 = _CFStringCreateWithCString(0,param_1,0x600);
    if (iVar4 == 0) {
      local_74 = 0;
      local_6c = 0;
      local_68 = 0;
    }
    else {
      local_74 = _CFURLCreateCopyAppendingPathComponent(0,iVar3,iVar4,0);
      local_6c = 0;
      local_68 = 0;
      if (local_74 != 0) {
        local_6c = _CFURLCopyFileSystemPath(local_74,0);
        local_68 = 0;
        if (local_6c != 0) {
          uVar6 = 1;
          iVar5 = _CFStringGetLength(local_6c);
          local_68 = 0;
          do {
            uVar6 = uVar6 + iVar5;
            if (local_68 != 0) {
              _MemoryDeallocate(local_68);
              local_68 = 0;
            }
          } while (((uVar6 <= iVar5 + 5U) && (local_68 = _MemoryAllocate(uVar6), local_68 != 0)) &&
                  (cVar1 = _CFStringGetCString(local_6c,local_68,uVar6,0x8000100), cVar1 == '\0'));
        }
      }
    }
    _CFRelease(iVar3);
    if (local_74 != 0) {
      _CFRelease(local_74);
    }
    if (iVar4 != 0) {
      _CFRelease(iVar4);
    }
    if (local_6c != 0) {
      _CFRelease(local_6c);
    }
  }
  else {
    local_68 = 0;
  }
  return local_68;
}


// ==== _WriteToFileAsSuperUser @ 00030000 ====

int _WriteToFileAsSuperUser(undefined4 param_1,void *param_2,size_t param_3)

{
  int iVar1;
  size_t sVar2;
  char *local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  undefined4 local_1c;
  undefined4 *local_18;
  FILE *local_14;
  int local_10;
  
  local_10 = 0;
  local_30 = 0;
  local_2c = 0;
  local_28 = 0;
  local_34 = "system.privilege.admin";
  local_18 = &local_34;
  local_20 = 0;
  local_14 = (FILE *)0x0;
  local_1c = 1;
  local_24 = param_1;
  iVar1 = _AuthorizationCreate(0,0,0,&local_10);
  if (iVar1 == 0) {
    iVar1 = _AuthorizationCopyRights(local_10,&local_1c,0,0x13,0);
    if (iVar1 == 0) {
      iVar1 = _AuthorizationExecuteWithPrivileges(local_10,"/usr/bin/tee",0,&local_24,&local_14);
      if (iVar1 == 0) {
        sVar2 = _fwrite(param_2,1,param_3,local_14);
        iVar1 = ((int)param_3 <= (int)sVar2) - 1;
      }
    }
  }
  if (local_14 != (FILE *)0x0) {
    _fclose(local_14);
  }
  if (local_10 != 0) {
    _AuthorizationFree(local_10,0);
  }
  if (iVar1 == -0xea66) {
    iVar1 = -0x1b5f;
  }
  return iVar1;
}


// ==== __ClockInitialize @ 0003014a ====

void __ClockInitialize(void)

{
  int iVar1;
  int iVar2;
  undefined8 uVar3;
  
  uVar3 = CONCAT44(DAT_00035a1c,_gMicrosecondsAdjust);
  if (_gClockInitialized == '\0') {
    _MemoryClear(&_gClockResolverFreeQ,0x10);
    _MemoryClear(&_gClockResolverRecvQ,0x10);
    _MemoryClear(&_gClockDatagramFreeQ,0x10);
    _MemoryClear(&_gClockDatagramRecvQ,0x10);
    _TimerGetMicroseconds();
    _TimerGetMicroseconds();
    iVar1 = _TimerGetUTCSeconds();
    do {
      iVar2 = _TimerGetUTCSeconds();
    } while (iVar1 == iVar2);
    uVar3 = _TimerGetMicroseconds();
    uVar3 = ___umoddi3(uVar3,1000000,0);
    _gClockInitialized = '\x01';
  }
  DAT_00035a1c = (undefined4)((ulonglong)uVar3 >> 0x20);
  _gMicrosecondsAdjust = (undefined4)uVar3;
  return;
}


// ==== _ClockMakeWideSeconds @ 00030212 ====

undefined8 _ClockMakeWideSeconds(undefined4 param_1,uint param_2,int param_3)

{
  int iVar1;
  double dVar2;
  double dVar3;
  
  if (_gClockInitialized == '\0') {
    __ClockInitialize();
  }
  iVar1 = ___umoddi3(param_2 - _gMicrosecondsAdjust,
                     (param_3 - DAT_00035a1c) - (uint)(param_2 < _gMicrosecondsAdjust),1000000,0);
  dVar2 = (((double)(iVar1 + -0x80000000) + DAT_00033f10) * DOUBLE_00033ff0) / DOUBLE_00033ff8;
  dVar3 = dVar2;
  if (DAT_00033f20 <= dVar2) {
    dVar3 = DAT_00033f20;
  }
  if (dVar3 <= 0.0) {
    dVar3 = 0.0;
  }
  return CONCAT44(param_1,(int)(dVar3 - (double)((ulonglong)DAT_00033f10 &
                                                -(ulonglong)(DAT_00033f10 <= dVar2))) ^
                          (uint)(DAT_00033f10 <= dVar2) * -0x80000000);
}


// ==== _ClockGetWideSeconds @ 000302f5 ====

void _ClockGetWideSeconds(void)

{
  undefined4 uVar1;
  undefined8 uVar2;
  
  if (_gClockInitialized == '\0') {
    __ClockInitialize();
  }
  uVar1 = _TimerGetUTCSeconds();
  uVar2 = _TimerGetMicroseconds();
  _ClockMakeWideSeconds(uVar1,uVar2);
  return;
}


// ==== __ClockSendPacket @ 00030339 ====

void __regparm3 __ClockSendPacket(int param_1)

{
  int iVar1;
  uint uVar2;
  uint uVar3;
  undefined8 uVar4;
  ulonglong uVar5;
  int local_24;
  
  if (1 < *(int *)(param_1 + 0x234) - 2U) {
    return;
  }
  *(undefined4 *)(param_1 + 0x234) = 3;
  if (2 < *(uint *)(param_1 + 0x230)) {
    iVar1 = -0x1b60;
    goto LAB_00030380;
  }
  local_24 = _QueueRemove(&_gClockDatagramFreeQ);
  if (local_24 == 0) {
    iVar1 = _NetworkQueueFill(&_gClockDatagramFreeQ,2,4,0x30);
    if (iVar1 != 0) goto LAB_00030380;
    local_24 = _QueueRemove(&_gClockDatagramFreeQ);
    if (local_24 == 0) {
      iVar1 = -0x1b5c;
      goto LAB_00030380;
    }
  }
  _AddressDuplicate(local_24 + 0x14,param_1 + 4);
  *(undefined4 *)(local_24 + 0x11c) = 0x30;
  _MemoryClear(local_24 + 0x120,0x30);
  uVar4 = _TimerGetMilliseconds();
  *(int *)(param_1 + 0x230) = *(int *)(param_1 + 0x230) + 1;
  *(undefined8 *)(param_1 + 0x224) = uVar4;
  *(undefined1 *)(local_24 + 0x121) = 4;
  *(undefined1 *)(local_24 + 0x122) = 10;
  *(undefined1 *)(local_24 + 0x123) = 0xfa;
  *(undefined1 *)(local_24 + 0x120) = 0x23;
  uVar5 = _ClockGetWideSeconds();
  uVar2 = (uint)(uVar5 >> 0x20);
  uVar3 = (uint)uVar5;
  *(ulonglong *)(param_1 + 0x21c) = uVar5;
  uVar2 = uVar2 >> 0x18 | uVar2 >> 8 & 0xff00 | (int)((uVar5 & 0xff0000ff0000) >> 0x20) << 8 |
          uVar2 << 0x18;
  uVar3 = uVar3 >> 0x18 | (uint)(uVar5 & 0xff0000ff0000) >> 8 | (uVar3 & 0xff00) << 8 |
          uVar3 << 0x18;
  *(uint *)(local_24 + 0x138) = uVar2;
  *(uint *)(local_24 + 0x148) = uVar2;
  *(uint *)(local_24 + 0x140) = uVar2;
  *(uint *)(local_24 + 0x13c) = uVar3;
  *(uint *)(local_24 + 0x14c) = uVar3;
  *(uint *)(local_24 + 0x144) = uVar3;
  iVar1 = _DatagramSend(_gClockDatagram,local_24);
  if (iVar1 == 0) {
    return;
  }
  _QueueInsert(&_gClockDatagramFreeQ,local_24);
LAB_00030380:
  if (*(int **)(param_1 + 0x208) != (int *)0x0) {
    **(int **)(param_1 + 0x208) = iVar1;
  }
  *(int *)(param_1 + 0x20c) = iVar1;
  *(undefined4 *)(param_1 + 0x234) = 5;
  return;
}


// ==== __ClockNetworkCallback @ 00030665 ====

void __ClockNetworkCallback(undefined4 param_1,undefined4 param_2,ushort param_3)

{
  undefined4 *puVar1;
  uint uVar2;
  uint uVar3;
  undefined4 uVar4;
  int *piVar5;
  char cVar6;
  uint uVar7;
  int iVar8;
  short sVar9;
  uint uVar10;
  int iVar11;
  undefined4 *puVar12;
  undefined8 uVar13;
  int local_40;
  undefined4 *local_30;
  undefined4 local_24;
  short local_1e [7];
  
  if (param_3 == 9) {
    while (iVar8 = _QueueRemove(&_gClockResolverRecvQ), iVar8 != 0) {
      iVar11 = *(int *)(iVar8 + 0x10);
      local_40 = 0;
      if (*(int *)(iVar11 + 0x234) == 1) {
        *(undefined4 *)(iVar11 + 0x234) = 2;
        cVar6 = _AddressIsEmpty(iVar8 + 0x14);
        local_40 = -0x1bc4;
        if (cVar6 == '\0') {
          _AddressDecomposeTCPIP(iVar8 + 0x14,local_1e,&local_24);
          sVar9 = 0x7b00;
          if (local_1e[0] != 0) {
            sVar9 = local_1e[0];
          }
          _AddressComposeTCPIP(iVar11 + 4,sVar9,local_24);
          __ClockSendPacket();
          local_40 = 0;
        }
      }
      _QueueInsert(&_gClockResolverFreeQ,iVar8);
      if (local_40 != 0) {
        if (*(int **)(iVar11 + 0x208) != (int *)0x0) {
          **(int **)(iVar11 + 0x208) = local_40;
        }
        *(undefined4 *)(iVar11 + 0x234) = 5;
        *(int *)(iVar11 + 0x20c) = local_40;
      }
    }
  }
  else if (param_3 < 10) {
    if (param_3 == 2) {
      puVar1 = &_gClockQueryList;
      while (puVar12 = puVar1, puVar1 = (undefined4 *)*puVar12, puVar1 != (undefined4 *)0x0) {
        if (puVar1[0x8d] == 3) {
          uVar13 = _TimerGetMilliseconds();
          if (((int)((ulonglong)uVar13 >> 0x20) - puVar1[0x8a] !=
               (uint)((uint)uVar13 < (uint)puVar1[0x89])) || (3999 < (uint)uVar13 - puVar1[0x89])) {
            __ClockSendPacket();
          }
          puVar1 = (undefined4 *)*puVar12;
        }
        else if ((puVar1[0x8d] == 5) && (*(char *)(puVar1 + 0x8b) == '\0')) {
          *puVar12 = *puVar1;
          _MemoryDeallocate(puVar1);
          puVar1 = &_gClockQueryList;
        }
      }
    }
  }
  else if ((ushort)(param_3 - 0xc) < 2) {
    while (iVar8 = _QueueRemove(&_gClockDatagramRecvQ), iVar8 != 0) {
      uVar13 = _ClockGetWideSeconds();
      if (((*(uint *)(iVar8 + 0x11c) < 0x30) || ((*(byte *)(iVar8 + 0x120) & 0x3f) != 0x24)) ||
         (*(int *)(iVar8 + 0x13c) == 0 && *(int *)(iVar8 + 0x138) == 0)) {
        iVar11 = -0x1b59;
        local_30 = (undefined4 *)0x0;
      }
      else {
        uVar2 = *(uint *)(iVar8 + 0x124);
        uVar3 = *(uint *)(iVar8 + 0x128);
        *(uint *)(iVar8 + 0x124) =
             uVar2 >> 0x18 | uVar2 >> 8 & 0xff00 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
        uVar2 = *(uint *)(iVar8 + 300);
        *(uint *)(iVar8 + 0x128) =
             uVar3 >> 0x18 | uVar3 >> 8 & 0xff00 | (uVar3 & 0xff00) << 8 | uVar3 << 0x18;
        *(uint *)(iVar8 + 300) =
             uVar2 >> 0x18 | uVar2 >> 8 & 0xff00 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
        uVar2 = *(uint *)(iVar8 + 0x130);
        uVar3 = *(uint *)(iVar8 + 0x134);
        *(uint *)(iVar8 + 0x130) =
             uVar3 >> 0x18 | uVar3 >> 8 & 0xff00 | (uVar3 & 0xff00) << 8 | uVar3 << 0x18;
        *(uint *)(iVar8 + 0x134) =
             uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
        uVar2 = *(uint *)(iVar8 + 0x138);
        uVar3 = *(uint *)(iVar8 + 0x13c);
        *(uint *)(iVar8 + 0x138) =
             uVar3 >> 0x18 | uVar3 >> 8 & 0xff00 | (uVar3 & 0xff00) << 8 | uVar3 << 0x18;
        *(uint *)(iVar8 + 0x13c) =
             uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
        uVar2 = *(uint *)(iVar8 + 0x140);
        uVar3 = *(uint *)(iVar8 + 0x144);
        *(uint *)(iVar8 + 0x140) =
             uVar3 >> 0x18 | uVar3 >> 8 & 0xff00 | (uVar3 & 0xff00) << 8 | uVar3 << 0x18;
        *(uint *)(iVar8 + 0x144) =
             uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
        uVar2 = *(uint *)(iVar8 + 0x148);
        uVar3 = *(uint *)(iVar8 + 0x14c);
        *(uint *)(iVar8 + 0x148) =
             uVar3 >> 0x18 | uVar3 >> 8 & 0xff00 | (uVar3 & 0xff00) << 8 | uVar3 << 0x18;
        *(uint *)(iVar8 + 0x14c) =
             uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
        for (local_30 = _gClockQueryList; local_30 != (undefined4 *)0x0;
            local_30 = (undefined4 *)*local_30) {
          if (*(int *)(iVar8 + 0x13c) == local_30[0x88] && local_30[0x87] == *(int *)(iVar8 + 0x138)
             ) {
            if (local_30[0x8d] == 3) {
              local_30[0x8d] = 4;
              if ((undefined8 *)local_30[0x86] != (undefined8 *)0x0) {
                *(undefined8 *)local_30[0x86] = uVar13;
              }
              puVar1 = (undefined4 *)local_30[0x85];
              if (puVar1 != (undefined4 *)0x0) {
                uVar4 = local_30[0x88];
                *puVar1 = local_30[0x87];
                puVar1[1] = uVar4;
              }
              piVar5 = (int *)local_30[0x84];
              uVar2 = *(uint *)(iVar8 + 0x144);
              uVar3 = *(uint *)(iVar8 + 0x14c);
              uVar10 = *(uint *)(iVar8 + 0x140) >> 1 | uVar2 << 0x1f;
              uVar7 = *(uint *)(iVar8 + 0x148) >> 1 | uVar3 << 0x1f;
              *piVar5 = uVar10 + uVar7;
              piVar5[1] = (uVar2 >> 1) + (uVar3 >> 1) + (uint)CARRY4(uVar10,uVar7);
              local_30[0x8d] = 5;
            }
            break;
          }
        }
        iVar11 = 0;
      }
      _QueueInsert(&_gClockDatagramFreeQ,iVar8);
      if (iVar11 != 0) {
        if ((int *)local_30[0x82] != (int *)0x0) {
          *(int *)local_30[0x82] = iVar11;
        }
        local_30[0x83] = iVar11;
        local_30[0x8d] = 5;
      }
    }
  }
  return;
}


// ==== _ClockQueryDispose @ 00030d09 ====

void _ClockQueryDispose(void)

{
  undefined4 *puVar1;
  undefined4 *puVar2;
  undefined4 *puVar3;
  
  _SystemCheckCallback();
  if (_gClockResolver != 0) {
    _ResolverClose(_gClockResolver);
    _ResolverDispose(_gClockResolver);
    _gClockResolver = 0;
    _NetworkQueueEmpty(&_gClockResolverFreeQ);
    _NetworkQueueEmpty(&_gClockResolverRecvQ);
    _QueueDispose(&_gClockResolverFreeQ);
    _QueueDispose(&_gClockResolverRecvQ);
  }
  if (_gClockDatagram != 0) {
    _DatagramClose(_gClockDatagram,0);
    _DatagramDispose(_gClockDatagram);
    _gClockDatagram = 0;
    _NetworkQueueEmpty(&_gClockDatagramFreeQ);
    _NetworkQueueEmpty(&_gClockDatagramRecvQ);
    _QueueDispose(&_gClockDatagramFreeQ);
    _QueueDispose(&_gClockDatagramRecvQ);
  }
  while (puVar3 = _gClockQueryList, _gClockQueryList != (undefined4 *)0x0) {
    puVar2 = (undefined4 *)*_gClockQueryList;
    if ((_gClockQueryList[0x8d] != 5) &&
       (puVar1 = _gClockQueryList + 0x82, (undefined4 *)*puVar1 != (undefined4 *)0x0)) {
      _gClockQueryList = puVar2;
      *(undefined4 *)*puVar1 = 0xffffe4a1;
      puVar2 = _gClockQueryList;
    }
    _gClockQueryList = puVar2;
    _MemoryDeallocate(puVar3);
  }
  _gClockInitialized = 0;
  return;
}


// ==== _ClockQueryServer @ 00030e16 ====

int _ClockQueryServer(char *param_1,int param_2,undefined4 *param_3,undefined4 *param_4,
                     undefined4 *param_5,int *param_6)

{
  char cVar1;
  int iVar2;
  int iVar3;
  uint uVar4;
  undefined4 *local_20;
  
  _SystemCheckCallback();
  if ((param_1 == (char *)0x0) || (*param_1 == '\0')) {
    param_1 = "time.apple.com:123";
  }
  if (param_3 != (undefined4 *)0x0) {
    *param_3 = 0;
    param_3[1] = 0;
  }
  if (param_4 != (undefined4 *)0x0) {
    *param_4 = 0;
    param_4[1] = 0;
  }
  if (param_6 != (int *)0x0) {
    *param_6 = 0;
  }
  *param_5 = 0;
  param_5[1] = 0;
  if (_gClockInitialized == '\0') {
    __ClockInitialize();
  }
  cVar1 = _NetworkStackGetLoaded(0);
  if (cVar1 == '\0') {
    iVar2 = _NetworkStackLoad(1);
    local_20 = (undefined4 *)0x0;
    if (iVar2 != 0) goto LAB_00031289;
  }
  _SystemSetQuitProc(_ClockQueryDispose);
  if (_gClockResolver == 0) {
    iVar2 = _QueueCreate(&_gClockResolverFreeQ);
    local_20 = (undefined4 *)0x0;
    if (iVar2 != 0) goto LAB_00031289;
    iVar2 = _QueueCreate(&_gClockResolverRecvQ);
    local_20 = (undefined4 *)0x0;
    if (iVar2 != 0) goto LAB_00031289;
    iVar2 = _NetworkQueueFill(&_gClockResolverFreeQ,1,4,0x218);
    local_20 = (undefined4 *)0x0;
    if (iVar2 != 0) goto LAB_00031289;
    _gClockResolver =
         _ResolverCreate(0,0,__ClockNetworkCallback,&_gClockResolverRecvQ,&_gClockResolverFreeQ);
    if (_gClockResolver != 0) {
      iVar2 = _ResolverOpen(_gClockResolver);
      local_20 = (undefined4 *)0x0;
      if (iVar2 != 0) goto LAB_00031289;
      goto LAB_00030fac;
    }
LAB_0003127d:
    iVar2 = -0x1b5c;
    local_20 = (undefined4 *)0x0;
    goto LAB_00031289;
  }
LAB_00030fac:
  if (_gClockDatagram == 0) {
    iVar2 = _QueueCreate(&_gClockDatagramFreeQ);
    local_20 = (undefined4 *)0x0;
    if (iVar2 != 0) goto LAB_00031289;
    iVar2 = _QueueCreate(&_gClockDatagramRecvQ);
    local_20 = (undefined4 *)0x0;
    if (iVar2 != 0) goto LAB_00031289;
    iVar2 = _NetworkQueueFill(&_gClockDatagramFreeQ,2,4,0x30);
    local_20 = (undefined4 *)0x0;
    if (iVar2 != 0) goto LAB_00031289;
    _gClockDatagram =
         _DatagramCreate(0,0,__ClockNetworkCallback,&_gClockDatagramFreeQ,&_gClockDatagramFreeQ,
                         &_gClockDatagramRecvQ,&_gClockDatagramRecvQ);
    if (_gClockDatagram == 0) goto LAB_0003127d;
    _DatagramControl(_gClockDatagram,0,0x6000,1);
    iVar2 = _DatagramOpen(_gClockDatagram,0);
    local_20 = (undefined4 *)0x0;
    if (iVar2 != 0) goto LAB_00031289;
  }
  iVar2 = -0x1b5c;
  local_20 = (undefined4 *)_MemoryAllocate(0x238);
  if (local_20 == (undefined4 *)0x0) goto LAB_00031289;
  _MemoryClear(local_20,0x238);
  _StringCopySafe(local_20 + 0x42,param_1,0x100);
  local_20[0x82] = param_6;
  local_20[0x84] = param_5;
  local_20[0x85] = param_3;
  local_20[0x86] = param_4;
  *(bool *)(local_20 + 0x8b) = param_2 != 0;
  *local_20 = _gClockQueryList;
  _gClockQueryList = local_20;
  if (local_20[0x8d] == 0) {
    local_20[0x8d] = 1;
    iVar2 = _QueueRemove(&_gClockResolverFreeQ);
    if (iVar2 == 0) {
      iVar3 = _NetworkQueueFill(&_gClockResolverFreeQ,2,4,0x30);
      if (iVar3 == 0) {
        iVar2 = _QueueRemove(&_gClockResolverFreeQ);
        if (iVar2 != 0) goto LAB_000311b4;
        iVar3 = -0x1b5c;
      }
    }
    else {
LAB_000311b4:
      _AddressComposeEmpty(iVar2 + 0x14);
      _StringCopySafe(iVar2 + 0x118,local_20 + 0x42,0x100);
      *(undefined4 **)(iVar2 + 0x10) = local_20;
      iVar3 = _ResolveName(_gClockResolver,iVar2);
      if (iVar3 == 0) goto LAB_00031221;
      _QueueInsert(&_gClockResolverFreeQ,iVar2);
    }
    if ((int *)local_20[0x82] != (int *)0x0) {
      *(int *)local_20[0x82] = iVar3;
    }
    local_20[0x83] = iVar3;
    local_20[0x8d] = 5;
  }
LAB_00031221:
  iVar2 = 0;
  if (param_2 != 0) {
    iVar2 = _TimerGetUTCSeconds();
    while( true ) {
      uVar4 = _TimerGetUTCSeconds();
      if (((uint)(param_2 + iVar2) <= uVar4) || (local_20[0x8d] == 5)) break;
      _SystemIdle();
    }
    if ((((int *)local_20[0x84])[1] != 0 || *(int *)local_20[0x84] != 0) ||
       (iVar2 = -0x1b60, local_20[0x83] != 0)) {
      iVar2 = local_20[0x83];
    }
  }
LAB_00031289:
  if ((param_2 != 0 || iVar2 != 0) && (local_20 != (undefined4 *)0x0)) {
    if (local_20 == _gClockQueryList) {
      _gClockQueryList = (undefined4 *)*local_20;
    }
    _MemoryDeallocate(local_20);
  }
  if ((param_2 != 0) && (_gClockQueryList == (undefined4 *)0x0)) {
    _ClockQueryDispose();
  }
  if (param_6 != (int *)0x0) {
    *param_6 = iVar2;
  }
  return iVar2;
}


// ==== _GetHTTPSProxy @ 0003130c ====

/* WARNING: Type propagation algorithm not settling */

int _GetHTTPSProxy(char *param_1,undefined1 *param_2,undefined1 *param_3)

{
  char cVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  uint uVar6;
  char *pcVar7;
  char *local_174;
  char local_158;
  undefined1 local_157 [255];
  undefined4 local_58;
  uint local_54;
  char *local_50;
  undefined4 local_4c;
  undefined4 local_48;
  int *local_44;
  undefined4 local_40;
  undefined4 *local_3c;
  int local_38;
  int local_34;
  int local_30;
  int local_2c [6];
  undefined4 uStack_14;
  
  uStack_14 = 0x31317;
  local_30 = 0;
  local_2c[2] = 0;
  local_158 = s__00032084[0];
  _memset(local_157,0,0xff);
  *param_1 = '\0';
  if (param_2 != (undefined1 *)0x0) {
    *param_2 = 0;
  }
  if (param_3 != (undefined1 *)0x0) {
    *param_3 = 0;
  }
  iVar2 = _SCDynamicStoreCopyProxies(0);
  if (iVar2 != 0) {
    iVar3 = _CFDictionaryGetValue(iVar2,&cf_HTTPSEnable);
    if (iVar3 != 0) {
      iVar4 = _CFGetTypeID(iVar3);
      iVar5 = _CFNumberGetTypeID();
      if (iVar4 == iVar5) {
        _CFNumberGetValue(iVar3,9,&local_30);
      }
    }
    if (local_30 != 0) {
      iVar3 = _CFDictionaryGetValue(iVar2,&cf_HTTPSProxy);
      if (iVar3 != 0) {
        iVar4 = _CFGetTypeID(iVar3);
        iVar5 = _CFStringGetTypeID();
        if (iVar4 == iVar5) {
          _CFStringGetCString(iVar3,&local_158,0x100,0x600);
        }
      }
      local_174 = &local_158;
      iVar3 = _CFDictionaryGetValue(iVar2,&cf_HTTPSPort);
      if (iVar3 != 0) {
        iVar4 = _CFGetTypeID(iVar3);
        iVar5 = _CFNumberGetTypeID();
        if (iVar4 == iVar5) {
          _CFNumberGetValue(iVar3,9,local_2c + 2);
        }
      }
      pcVar7 = "%s:%i";
      if (local_2c[2] == 0) {
        pcVar7 = "%s";
      }
      _StringFormatSafe(param_1,0x100,pcVar7,local_174,local_2c[2]);
    }
    _CFRelease(iVar2);
  }
  cVar1 = _SystemMacOSXOrLater();
  if (((cVar1 != '\0') && (param_2 != (undefined1 *)0x0 && *param_1 != '\0')) &&
     (param_3 != (undefined1 *)0x0)) {
    local_50 = param_1;
    iVar3 = 0;
    local_34 = 0;
    local_38 = 0;
    local_2c[0] = 0;
    local_2c[3] = 0;
    local_2c[1] = 0x68747378;
    local_58 = 0x73727672;
    local_54 = _StringGetLength(param_1);
    local_4c = 0x7074636c;
    local_48 = 4;
    local_40 = 2;
    local_44 = local_2c + 1;
    local_3c = &local_58;
    iVar2 = _SecKeychainSearchCreateFromAttributes(0,0x696e6574,&local_40,&local_34);
    if (iVar2 == 0) {
      while (iVar2 = _SecKeychainSearchCopyNext(local_34,&local_38), iVar2 == 0) {
        local_58 = 0x61636374;
        local_40 = 1;
        local_3c = &local_58;
        iVar3 = _SecKeychainItemCopyContent(local_38,0,&local_40,local_2c + 3,local_2c);
        if (iVar3 == -0x62cd) {
          return -0x1b5f;
        }
        if ((iVar3 == 0) && (local_2c[0] != 0)) {
          uVar6 = 0xff;
          if (local_54 < 0x100) {
            uVar6 = local_54;
          }
          local_54 = uVar6;
          _StringCopySafe(param_2,local_50,uVar6 + 1);
          uVar6 = 0xff;
          if ((uint)local_2c[3] < 0x100) {
            uVar6 = local_2c[3];
          }
          local_2c[3] = uVar6;
          _StringCopySafe(param_3,local_2c[0],uVar6 + 1);
          _SecKeychainItemFreeContent(&local_40,local_2c[0]);
        }
        if (local_38 != 0) {
          _CFRelease(local_38);
          local_38 = 0;
        }
      }
      if (local_34 == 0) {
        return iVar3;
      }
      _CFRelease(local_34);
      return iVar3;
    }
  }
  return 0;
}


// ==== _GetNoProxyList @ 000316cc ====

int _GetNoProxyList(undefined1 *param_1)

{
  short sVar1;
  int iVar2;
  int iVar3;
  undefined4 uVar4;
  undefined4 *puVar5;
  int local_3cc;
  byte *local_3c4;
  int local_3c0;
  undefined1 local_3ae [256];
  undefined1 local_2ae [256];
  undefined1 local_1ae [256];
  undefined1 local_ae [70];
  undefined4 local_68;
  undefined1 *local_64;
  int local_54;
  undefined1 *local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined1 local_24 [4];
  int local_20 [4];
  
  local_20[0] = 0;
  if (param_1 != (undefined1 *)0x0) {
    *param_1 = 0;
  }
  puVar5 = (undefined4 *)0x0;
  iVar2 = _HashCreate(0x2000001);
  local_3cc = -0x1b5c;
  if (iVar2 != 0) {
    local_2c = 0;
    local_28 = 2;
    if (_creatorCode_77890 == -1) {
      local_30 = local_ae;
      local_64 = local_2ae;
      local_68 = 0x3c;
      sVar1 = _GetProcessInformation(&local_2c,&local_68);
      if (sVar1 == 0) {
        _creatorCode_77890 = local_54;
      }
      else {
        _creatorCode_77890 = 0x3f3f3f3f;
      }
    }
    iVar3 = _ICStart(local_20,_creatorCode_77890);
    if ((iVar3 == 0) && (iVar3 = _ICBegin(local_20[0],1), iVar3 == 0)) {
      puVar5 = (undefined4 *)_NewHandle(0);
      local_3cc = -0x1b5c;
      if (puVar5 != (undefined4 *)0x0) {
        uVar4 = _C2PStringCopy(local_3ae,"NoProxyDomains");
        iVar3 = _ICFindPrefHandle(local_20[0],uVar4,local_24,puVar5);
        if (iVar3 == 0) {
          _HLockHi(puVar5);
          sVar1 = *(short *)*puVar5;
          local_3c4 = (byte *)((short *)*puVar5 + 1);
          for (local_3c0 = 0; sVar1 != local_3c0; local_3c0 = local_3c0 + 1) {
            if (*local_3c4 != 0) {
              _P2CStringCopy(local_1ae,local_3c4);
              iVar3 = _HashLookup(iVar2,local_1ae,0);
              if ((iVar3 == 0) && (local_3cc = _HashAppend(iVar2,local_1ae,""), local_3cc != 0))
              goto LAB_000318e2;
            }
            local_3c4 = local_3c4 + *local_3c4 + 1;
          }
        }
        local_3cc = 0;
      }
    }
    else {
      puVar5 = (undefined4 *)0x0;
      local_3cc = 0;
    }
  }
LAB_000318e2:
  if (param_1 != (undefined1 *)0x0) {
    *param_1 = 0;
  }
  if (puVar5 != (undefined4 *)0x0) {
    _DisposeHandle(puVar5);
  }
  if (local_20[0] != 0) {
    _ICStop(local_20[0]);
  }
  iVar3 = iVar2;
  if (iVar2 != 0 && local_3cc == -0x1b5c) {
    iVar3 = 0;
    _HashDispose(iVar2);
  }
  return iVar3;
}


// ==== _GetSOCKSServer @ 00031947 ====

/* WARNING: Type propagation algorithm not settling */

int _GetSOCKSServer(char *param_1,undefined1 *param_2,undefined1 *param_3)

{
  char cVar1;
  short sVar2;
  int iVar3;
  undefined4 uVar4;
  undefined1 *puVar5;
  uint uVar6;
  int iVar7;
  char local_3ca [256];
  undefined1 local_2ca [256];
  undefined1 local_1ca [256];
  undefined1 local_ca [70];
  undefined4 local_84;
  undefined1 *local_80;
  char *local_7c;
  undefined4 local_78;
  undefined4 local_74;
  int *local_70;
  undefined1 *local_4c;
  undefined4 local_48;
  undefined4 *local_44;
  uint local_40;
  int local_3c [6];
  undefined1 local_24 [7];
  char local_1d [13];
  
  local_3c[4] = 0;
  *param_1 = '\0';
  if (param_2 != (undefined1 *)0x0) {
    *param_2 = 0;
  }
  if (param_3 != (undefined1 *)0x0) {
    *param_3 = 0;
  }
  local_48 = 0;
  local_44 = (undefined4 *)0x2;
  if (_creatorCode_77890 == (int *)0xffffffff) {
    local_4c = local_ca;
    local_80 = local_2ca;
    local_84 = 0x3c;
    sVar2 = _GetProcessInformation(&local_48,&local_84);
    if (sVar2 == 0) {
      _creatorCode_77890 = local_70;
    }
    else {
      _creatorCode_77890 = (int *)0x3f3f3f3f;
    }
  }
  iVar3 = _ICStart(local_3c + 4,_creatorCode_77890);
  if ((iVar3 == 0) && (iVar3 = _ICBegin(local_3c[4],1), iVar3 == 0)) {
    local_3c[5] = 1;
    uVar4 = _C2PStringCopy(local_1ca,"UseSocks");
    iVar3 = _ICGetPref(local_3c[4],uVar4,local_24,local_1d,local_3c + 5);
    if ((iVar3 == 0) && (local_1d[0] != '\0')) {
      local_3c[5] = 0x100;
      uVar4 = _C2PStringCopy(local_1ca,"SocksHost");
      iVar3 = _ICGetPref(local_3c[4],uVar4,local_24,local_3ca,local_3c + 5);
      if ((iVar3 == 0) && (local_3ca[0] != '\0')) {
        _P2CStringCopy(param_1,local_3ca);
      }
    }
  }
  cVar1 = _SystemMacOSXOrLater();
  if (((cVar1 != '\0') && (*param_1 != '\0' && param_2 != (undefined1 *)0x0)) &&
     (param_3 != (undefined1 *)0x0)) {
    iVar7 = 0;
    local_3c[3] = 0;
    local_3c[2] = 0;
    local_3c[0] = 0;
    local_40 = 0;
    local_3c[1] = 0x736f7820;
    local_84 = 0x73727672;
    local_7c = param_1;
    local_80 = (undefined1 *)_StringGetLength(param_1);
    local_78 = 0x7074636c;
    local_74 = 4;
    local_48 = 2;
    local_70 = local_3c + 1;
    local_44 = &local_84;
    iVar3 = _SecKeychainSearchCreateFromAttributes(0,0x696e6574,&local_48,local_3c + 3);
    if (iVar3 == 0) {
      while (iVar3 = _SecKeychainSearchCopyNext(local_3c[3],local_3c + 2), iVar3 == 0) {
        local_84 = 0x61636374;
        local_48 = 1;
        local_44 = &local_84;
        iVar7 = _SecKeychainItemCopyContent(local_3c[2],0,&local_48,&local_40,local_3c);
        if (iVar7 == -0x62cd) {
          iVar7 = -0x1b5f;
          goto LAB_00031cc9;
        }
        if ((iVar7 == 0) && (local_3c[0] != 0)) {
          puVar5 = (undefined1 *)0xff;
          if (local_80 < (undefined1 *)0x100) {
            puVar5 = local_80;
          }
          local_80 = puVar5;
          _StringCopySafe(param_2,local_7c,puVar5 + 1);
          uVar6 = 0xff;
          if (local_40 < 0x100) {
            uVar6 = local_40;
          }
          local_40 = uVar6;
          _StringCopySafe(param_3,local_3c[0],uVar6 + 1);
          _SecKeychainItemFreeContent(&local_48,local_3c[0]);
        }
        if (local_3c[2] != 0) {
          _CFRelease(local_3c[2]);
          local_3c[2] = 0;
        }
      }
      if (local_3c[3] != 0) {
        _CFRelease(local_3c[3]);
        local_3c[3] = 0;
      }
      goto LAB_00031cc9;
    }
  }
  iVar7 = 0;
LAB_00031cc9:
  if (local_3c[4] != 0) {
    _ICStop(local_3c[4]);
  }
  return iVar7;
}


// ==== _GetHTTPProxy @ 00031ce5 ====

/* WARNING: Type propagation algorithm not settling */

int _GetHTTPProxy(char *param_1,undefined1 *param_2,undefined1 *param_3)

{
  char cVar1;
  short sVar2;
  int iVar3;
  undefined4 uVar4;
  undefined1 *puVar5;
  uint uVar6;
  int iVar7;
  char local_3ca [256];
  undefined1 local_2ca [256];
  undefined1 local_1ca [256];
  undefined1 local_ca [70];
  undefined4 local_84;
  undefined1 *local_80;
  char *local_7c;
  undefined4 local_78;
  undefined4 local_74;
  int *local_70;
  undefined1 *local_4c;
  undefined4 local_48;
  undefined4 *local_44;
  uint local_40;
  int local_3c [6];
  undefined1 local_24 [7];
  char local_1d [13];
  
  local_3c[4] = 0;
  *param_1 = '\0';
  if (param_2 != (undefined1 *)0x0) {
    *param_2 = 0;
  }
  if (param_3 != (undefined1 *)0x0) {
    *param_3 = 0;
  }
  local_48 = 0;
  local_44 = (undefined4 *)0x2;
  if (_creatorCode_77890 == (int *)0xffffffff) {
    local_4c = local_ca;
    local_80 = local_2ca;
    local_84 = 0x3c;
    sVar2 = _GetProcessInformation(&local_48,&local_84);
    if (sVar2 == 0) {
      _creatorCode_77890 = local_70;
    }
    else {
      _creatorCode_77890 = (int *)0x3f3f3f3f;
    }
  }
  iVar3 = _ICStart(local_3c + 4,_creatorCode_77890);
  if ((iVar3 == 0) && (iVar3 = _ICBegin(local_3c[4],1), iVar3 == 0)) {
    local_3c[5] = 1;
    uVar4 = _C2PStringCopy(local_1ca,"UseHTTPProxy");
    iVar3 = _ICGetPref(local_3c[4],uVar4,local_24,local_1d,local_3c + 5);
    if ((iVar3 == 0) && (local_1d[0] != '\0')) {
      local_3c[5] = 0x100;
      uVar4 = _C2PStringCopy(local_1ca,"HTTPProxyHost");
      iVar3 = _ICGetPref(local_3c[4],uVar4,local_24,local_3ca,local_3c + 5);
      if ((iVar3 == 0) && (local_3ca[0] != '\0')) {
        _P2CStringCopy(param_1,local_3ca);
      }
    }
  }
  cVar1 = _SystemMacOSXOrLater();
  if (((cVar1 != '\0') && (*param_1 != '\0' && param_2 != (undefined1 *)0x0)) &&
     (param_3 != (undefined1 *)0x0)) {
    iVar7 = 0;
    local_3c[3] = 0;
    local_3c[2] = 0;
    local_3c[0] = 0;
    local_40 = 0;
    local_3c[1] = 0x68747078;
    local_84 = 0x73727672;
    local_7c = param_1;
    local_80 = (undefined1 *)_StringGetLength(param_1);
    local_78 = 0x7074636c;
    local_74 = 4;
    local_48 = 2;
    local_70 = local_3c + 1;
    local_44 = &local_84;
    iVar3 = _SecKeychainSearchCreateFromAttributes(0,0x696e6574,&local_48,local_3c + 3);
    if (iVar3 == 0) {
      while (iVar3 = _SecKeychainSearchCopyNext(local_3c[3],local_3c + 2), iVar3 == 0) {
        local_84 = 0x61636374;
        local_48 = 1;
        local_44 = &local_84;
        iVar7 = _SecKeychainItemCopyContent(local_3c[2],0,&local_48,&local_40,local_3c);
        if (iVar7 == -0x62cd) {
          iVar7 = -0x1b5f;
          goto LAB_00032067;
        }
        if ((iVar7 == 0) && (local_3c[0] != 0)) {
          puVar5 = (undefined1 *)0xff;
          if (local_80 < (undefined1 *)0x100) {
            puVar5 = local_80;
          }
          local_80 = puVar5;
          _StringCopySafe(param_2,local_7c,puVar5 + 1);
          uVar6 = 0xff;
          if (local_40 < 0x100) {
            uVar6 = local_40;
          }
          local_40 = uVar6;
          _StringCopySafe(param_3,local_3c[0],uVar6 + 1);
          _SecKeychainItemFreeContent(&local_48,local_3c[0]);
        }
        if (local_3c[2] != 0) {
          _CFRelease(local_3c[2]);
          local_3c[2] = 0;
        }
      }
      if (local_3c[3] != 0) {
        _CFRelease(local_3c[3]);
        local_3c[3] = 0;
      }
      goto LAB_00032067;
    }
  }
  iVar7 = 0;
LAB_00032067:
  if (local_3c[4] != 0) {
    _ICStop(local_3c[4]);
  }
  return iVar7;
}


// ==== _AddResource @ 000380c0 ====

void _AddResource(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AddressComposeEmpty @ 000380c5 ====

void _AddressComposeEmpty(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AddressComposeTCPIP @ 000380ca ====

void _AddressComposeTCPIP(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AddressDecomposeTCPIP @ 000380cf ====

void _AddressDecomposeTCPIP(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AddressDuplicate @ 000380d4 ====

void _AddressDuplicate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AddressIsEmpty @ 000380d9 ====

void _AddressIsEmpty(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AuthorizationCopyRights @ 000380de ====

void _AuthorizationCopyRights(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AuthorizationCreate @ 000380e3 ====

void _AuthorizationCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AuthorizationExecuteWithPrivileges @ 000380e8 ====

void _AuthorizationExecuteWithPrivileges(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AuthorizationFree @ 000380ed ====

void _AuthorizationFree(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _C2PStringCopy @ 000380f2 ====

void _C2PStringCopy(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFAllocatorGetDefault @ 000380f7 ====

void _CFAllocatorGetDefault(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_000380fc @ 000380fc ====

void FUN_000380fc(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFArrayCreate @ 00038101 ====

void _CFArrayCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFBundleCopyResourceURL @ 00038106 ====

void _CFBundleCopyResourceURL(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFBundleGetMainBundle @ 0003810b ====

void _CFBundleGetMainBundle(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFDataCreate @ 00038110 ====

void _CFDataCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFDataGetBytePtr @ 00038115 ====

void _CFDataGetBytePtr(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFDataGetLength @ 0003811a ====

void _CFDataGetLength(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFDictionaryCreateMutable @ 0003811f ====

void _CFDictionaryCreateMutable(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFDictionaryGetValue @ 00038124 ====

void _CFDictionaryGetValue(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFDictionaryGetValueIfPresent @ 00038129 ====

void _CFDictionaryGetValueIfPresent(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFDictionarySetValue @ 0003812e ====

void _CFDictionarySetValue(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFGetTypeID @ 00038133 ====

void _CFGetTypeID(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFNumberGetTypeID @ 00038138 ====

void _CFNumberGetTypeID(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_0003813d @ 0003813d ====

void FUN_0003813d(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFNumberGetValue @ 00038142 ====

void _CFNumberGetValue(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFPreferencesCopyValue @ 00038147 ====

void _CFPreferencesCopyValue(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFPreferencesSetValue @ 0003814c ====

void _CFPreferencesSetValue(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFPreferencesSynchronize @ 00038151 ====

void _CFPreferencesSynchronize(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFRelease @ 00038156 ====

void _CFRelease(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFRunLoopGetCurrent @ 0003815b ====

void _CFRunLoopGetCurrent(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringAppendCString @ 00038160 ====

void _CFStringAppendCString(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringCreateMutable @ 00038165 ====

void _CFStringCreateMutable(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringCreateWithCString @ 0003816a ====

void _CFStringCreateWithCString(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringCreateWithFormat @ 0003816f ====

void _CFStringCreateWithFormat(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringCreateWithPascalString @ 00038174 ====

void _CFStringCreateWithPascalString(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringGetCString @ 00038179 ====

void _CFStringGetCString(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_0003817e @ 0003817e ====

void FUN_0003817e(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringGetLength @ 00038183 ====

void _CFStringGetLength(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringGetPascalString @ 00038188 ====

void _CFStringGetPascalString(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringGetSystemEncoding @ 0003818d ====

void _CFStringGetSystemEncoding(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringGetTypeID @ 00038192 ====

void _CFStringGetTypeID(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFURLCopyFileSystemPath @ 00038197 ====

void _CFURLCopyFileSystemPath(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFURLCopyLastPathComponent @ 0003819c ====

void _CFURLCopyLastPathComponent(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFURLCreateCopyAppendingPathComponent @ 000381a1 ====

void _CFURLCreateCopyAppendingPathComponent(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFURLCreateCopyDeletingLastPathComponent @ 000381a6 ====

void _CFURLCreateCopyDeletingLastPathComponent(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFURLCreateFromFSRef @ 000381ab ====

void _CFURLCreateFromFSRef(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFURLCreateWithFileSystemPath @ 000381b0 ====

void _CFURLCreateWithFileSystemPath(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFURLGetFSRef @ 000381b5 ====

void _CFURLGetFSRef(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGAcquireDisplayFadeReservation @ 000381ba ====

void _CGAcquireDisplayFadeReservation(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_000381bf @ 000381bf ====

void FUN_000381bf(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGCaptureAllDisplays @ 000381c4 ====

void _CGCaptureAllDisplays(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGColorSpaceCreateDeviceRGB @ 000381c9 ====

void _CGColorSpaceCreateDeviceRGB(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGColorSpaceRelease @ 000381ce ====

void _CGColorSpaceRelease(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGContextDrawImage @ 000381d3 ====

void _CGContextDrawImage(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGDataProviderCreateWithData @ 000381d8 ====

void _CGDataProviderCreateWithData(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGDataProviderCreateWithURL @ 000381dd ====

void _CGDataProviderCreateWithURL(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGDataProviderRelease @ 000381e2 ====

void _CGDataProviderRelease(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGDisplayBestModeForParameters @ 000381e7 ====

void _CGDisplayBestModeForParameters(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGDisplayCurrentMode @ 000381ec ====

void _CGDisplayCurrentMode(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGDisplayFade @ 000381f1 ====

void _CGDisplayFade(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGDisplayPixelsWide @ 000381f6 ====

void _CGDisplayPixelsWide(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGDisplaySwitchToMode @ 000381fb ====

void _CGDisplaySwitchToMode(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGImageCreate @ 00038200 ====

void _CGImageCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGImageCreateWithPNGDataProvider @ 00038205 ====

void _CGImageCreateWithPNGDataProvider(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGImageGetHeight @ 0003820a ====

void _CGImageGetHeight(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGImageGetWidth @ 0003820f ====

void _CGImageGetWidth(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGImageRelease @ 00038214 ====

void _CGImageRelease(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGMainDisplayID @ 00038219 ====

void _CGMainDisplayID(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGReleaseAllDisplays @ 0003821e ====

void _CGReleaseAllDisplays(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGReleaseDisplayFadeReservation @ 00038223 ====

void _CGReleaseDisplayFadeReservation(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGShieldingWindowLevel @ 00038228 ====

void _CGShieldingWindowLevel(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CloseMovieFile @ 0003822d ====

void _CloseMovieFile(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CloseResFile @ 00038232 ====

void _CloseResFile(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CopyBits @ 00038237 ====

void _CopyBits(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_0003823c @ 0003823c ====

void FUN_0003823c(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CopyDeepMask @ 00038241 ====

void _CopyDeepMask(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CreateNibReference @ 00038246 ====

void _CreateNibReference(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CreateWindowFromNib @ 0003824b ====

void _CreateWindowFromNib(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DT_Open @ 00038250 ====

void _DT_Open(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DatagramClose @ 00038255 ====

void _DatagramClose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DatagramControl @ 0003825a ====

void _DatagramControl(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DatagramCreate @ 0003825f ====

void _DatagramCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DatagramDispose @ 00038264 ====

void _DatagramDispose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DatagramOpen @ 00038269 ====

void _DatagramOpen(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DatagramSend @ 0003826e ====

void _DatagramSend(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DisableMenuCommand @ 00038273 ====

void _DisableMenuCommand(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DisposeEventHandlerUPP @ 00038278 ====

void _DisposeEventHandlerUPP(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_0003827d @ 0003827d ====

void FUN_0003827d(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DisposeGWorld @ 00038282 ====

void _DisposeGWorld(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DisposeHandle @ 00038287 ====

void _DisposeHandle(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DisposeNibReference @ 0003828c ====

void _DisposeNibReference(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DisposeWindow @ 00038291 ====

void _DisposeWindow(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _Draw1Control @ 00038296 ====

void _Draw1Control(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _EnableMenuCommand @ 0003829b ====

void _EnableMenuCommand(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _EnterMovies @ 000382a0 ====

void _EnterMovies(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ExitMovies @ 000382a5 ====

void _ExitMovies(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ExitToShell @ 000382aa ====

void _ExitToShell(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSClose @ 000382af ====

void _FSClose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSFindFolder @ 000382b4 ====

void _FSFindFolder(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSGetCatalogInfo @ 000382b9 ====

void _FSGetCatalogInfo(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_000382be @ 000382be ====

void FUN_000382be(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSMakeFSSpec @ 000382c3 ====

void _FSMakeFSSpec(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSPathMakeRef @ 000382c8 ====

void _FSPathMakeRef(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSRead @ 000382cd ====

void _FSRead(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSRefMakePath @ 000382d2 ====

void _FSRefMakePath(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSpCreateResFile @ 000382d7 ====

void _FSpCreateResFile(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSpDelete @ 000382dc ====

void _FSpDelete(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSpGetFInfo @ 000382e1 ====

void _FSpGetFInfo(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSpMakeFSRef @ 000382e6 ====

void _FSpMakeFSRef(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSpOpenDF @ 000382eb ====

void _FSpOpenDF(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSpOpenResFile @ 000382f0 ====

void _FSpOpenResFile(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSpSetFInfo @ 000382f5 ====

void _FSpSetFInfo(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FT_Close @ 000382fa ====

void _FT_Close(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_000382ff @ 000382ff ====

void FUN_000382ff(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FT_FileClose @ 00038304 ====

void _FT_FileClose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FT_FileGetFlags @ 00038309 ====

void _FT_FileGetFlags(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FT_FileLoad @ 0003830e ====

void _FT_FileLoad(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FT_FileOpen @ 00038313 ====

void _FT_FileOpen(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FT_FileRead @ 00038318 ====

void _FT_FileRead(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FT_FileSave @ 0003831d ====

void _FT_FileSave(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FT_FileSetFlags @ 00038322 ====

void _FT_FileSetFlags(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FT_FileWrite @ 00038327 ====

void _FT_FileWrite(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FT_Open @ 0003832c ====

void _FT_Open(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FT_PathCreateFromMacFSSpec @ 00038331 ====

void _FT_PathCreateFromMacFSSpec(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FindFolder @ 00038336 ====

void _FindFolder(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetControlByID @ 0003833b ====

void _GetControlByID(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetDblTime @ 00038340 ====

void _GetDblTime(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetEventParameter @ 00038345 ====

void _GetEventParameter(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetGWorld @ 0003834a ====

void _GetGWorld(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetGWorldPixMap @ 0003834f ====

void _GetGWorldPixMap(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetKeys @ 00038354 ====

void _GetKeys(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetMainDevice @ 00038359 ====

void _GetMainDevice(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetMenuHandle @ 0003835e ====

void _GetMenuHandle(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetPixBaseAddr @ 00038363 ====

void _GetPixBaseAddr(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetPixRowBytes @ 00038368 ====

void _GetPixRowBytes(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetPortBitMapForCopyBits @ 0003836d ====

void _GetPortBitMapForCopyBits(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetProcessInformation @ 00038372 ====

void _GetProcessInformation(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetWindowEventTarget @ 00038377 ====

void _GetWindowEventTarget(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_0003837c @ 0003837c ====

void FUN_0003837c(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetWindowPort @ 00038381 ====

void _GetWindowPort(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GoToBeginningOfMovie @ 00038386 ====

void _GoToBeginningOfMovie(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HIImageViewSetImage @ 0003838b ====

void _HIImageViewSetImage(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HIViewFindByID @ 00038390 ====

void _HIViewFindByID(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HIViewGetRoot @ 00038395 ====

void _HIViewGetRoot(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HIViewSetNeedsDisplay @ 0003839a ====

void _HIViewSetNeedsDisplay(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HLockHi @ 0003839f ====

void _HLockHi(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HashAppend @ 000383a4 ====

void _HashAppend(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HashCreate @ 000383a9 ====

void _HashCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HashDispose @ 000383ae ====

void _HashDispose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HashLookup @ 000383b3 ====

void _HashLookup(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HideWindow @ 000383b8 ====

void _HideWindow(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_000383bd @ 000383bd ====

void FUN_000383bd(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ICBegin @ 000383c2 ====

void _ICBegin(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ICFindPrefHandle @ 000383c7 ====

void _ICFindPrefHandle(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ICGetPref @ 000383cc ====

void _ICGetPref(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ICStart @ 000383d1 ====

void _ICStart(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ICStop @ 000383d6 ====

void _ICStop(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IT_Open @ 000383db ====

void _IT_Open(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectAllocate @ 000383e0 ====

void _IndirectAllocate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectAppendData @ 000383e5 ====

void _IndirectAppendData(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectCompress @ 000383ea ====

void _IndirectCompress(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectDeallocate @ 000383ef ====

void _IndirectDeallocate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectDecompress @ 000383f4 ====

void _IndirectDecompress(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectDuplicate @ 000383f9 ====

void _IndirectDuplicate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_000383fe @ 000383fe ====

void FUN_000383fe(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectGetSize @ 00038403 ====

void _IndirectGetSize(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectInitialize @ 00038408 ====

void _IndirectInitialize(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectSetLock @ 0003840d ====

void _IndirectSetLock(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectSetSize @ 00038412 ====

void _IndirectSetSize(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _InitCursor @ 00038417 ====

void _InitCursor(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _InstallEventHandler @ 0003841c ====

void _InstallEventHandler(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IsMovieDone @ 00038421 ====

void _IsMovieDone(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IsPlatformOpen @ 00038426 ====

void _IsPlatformOpen(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _LockPixels @ 0003842b ====

void _LockPixels(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _LockPortBits @ 00038430 ====

void _LockPortBits(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _MemoryAllocate @ 00038435 ====

void _MemoryAllocate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _MemoryChecksum @ 0003843a ====

void _MemoryChecksum(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_0003843f @ 0003843f ====

void FUN_0003843f(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _MemoryClear @ 00038444 ====

void _MemoryClear(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _MemoryCopy @ 00038449 ====

void _MemoryCopy(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _MemoryDeallocate @ 0003844e ====

void _MemoryDeallocate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _MoviesTask @ 00038453 ====

void _MoviesTask(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NSApplicationMain @ 00038458 ====

void _NSApplicationMain(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NSFileTypeForHFSTypeCode @ 0003845d ====

void _NSFileTypeForHFSTypeCode(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NetworkQueueEmpty @ 00038462 ====

void _NetworkQueueEmpty(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NetworkQueueFill @ 00038467 ====

void _NetworkQueueFill(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NetworkQueueWait @ 0003846c ====

void _NetworkQueueWait(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NetworkStackGetActive @ 00038471 ====

void _NetworkStackGetActive(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NetworkStackGetLoaded @ 00038476 ====

void _NetworkStackGetLoaded(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NetworkStackLoad @ 0003847b ====

void _NetworkStackLoad(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NewAlias @ 00038480 ====

void _NewAlias(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NewEventHandlerUPP @ 00038485 ====

void _NewEventHandlerUPP(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NewGWorld @ 0003848a ====

void _NewGWorld(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NewHandle @ 0003848f ====

void _NewHandle(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NewMovieFromFile @ 00038494 ====

void _NewMovieFromFile(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _OpenMovieFile @ 00038499 ====

void _OpenMovieFile(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _P2CStringCopy @ 0003849e ====

void _P2CStringCopy(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _PlatformOpen @ 000384a3 ====

void _PlatformOpen(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _QDBeginCGContext @ 000384a8 ====

void _QDBeginCGContext(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _QDEndCGContext @ 000384ad ====

void _QDEndCGContext(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _QDFlushPortBuffer @ 000384b2 ====

void _QDFlushPortBuffer(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _QueueCreate @ 000384b7 ====

void _QueueCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_000384bc @ 000384bc ====

void FUN_000384bc(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _QueueDispose @ 000384c1 ====

void _QueueDispose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _QueueEmpty @ 000384c6 ====

void _QueueEmpty(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _QueueInsert @ 000384cb ====

void _QueueInsert(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _QueueRemove @ 000384d0 ====

void _QueueRemove(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _QuitAppModalLoopForWindow @ 000384d5 ====

void _QuitAppModalLoopForWindow(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ResError @ 000384da ====

void _ResError(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ResolveName @ 000384df ====

void _ResolveName(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ResolverClose @ 000384e4 ====

void _ResolverClose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ResolverCreate @ 000384e9 ====

void _ResolverCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ResolverDispose @ 000384ee ====

void _ResolverDispose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ResolverOpen @ 000384f3 ====

void _ResolverOpen(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _RunAppModalLoopForWindow @ 000384f8 ====

void _RunAppModalLoopForWindow(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_000384fd @ 000384fd ====

void FUN_000384fd(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SCDynamicStoreCopyProxies @ 00038502 ====

void _SCDynamicStoreCopyProxies(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SUInfoValueForKey @ 00038507 ====

void _SUInfoValueForKey(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SecKeychainItemCopyContent @ 0003850c ====

void _SecKeychainItemCopyContent(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SecKeychainItemFreeContent @ 00038511 ====

void _SecKeychainItemFreeContent(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SecKeychainSearchCopyNext @ 00038516 ====

void _SecKeychainSearchCopyNext(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SecKeychainSearchCreateFromAttributes @ 0003851b ====

void _SecKeychainSearchCreateFromAttributes(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetControlData @ 00038520 ====

void _SetControlData(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetGWorld @ 00038525 ====

void _SetGWorld(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetMenuItemTextWithCFString @ 0003852a ====

void _SetMenuItemTextWithCFString(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetMovieBox @ 0003852f ====

void _SetMovieBox(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetMovieVolume @ 00038534 ====

void _SetMovieVolume(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetQDGlobalsRandomSeed @ 00038539 ====

void _SetQDGlobalsRandomSeed(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_0003853e @ 0003853e ====

void FUN_0003853e(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetRect @ 00038543 ====

void _SetRect(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SimpleResolve @ 00038548 ====

void _SimpleResolve(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StartMovie @ 0003854d ====

void _StartMovie(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StopMovie @ 00038552 ====

void _StopMovie(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StreamClose @ 00038557 ====

void _StreamClose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StreamCreate @ 0003855c ====

void _StreamCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StreamDispose @ 00038561 ====

void _StreamDispose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StreamOpenClient @ 00038566 ====

void _StreamOpenClient(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StreamSend @ 0003856b ====

void _StreamSend(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringAppendSafe @ 00038570 ====

void _StringAppendSafe(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringCompare @ 00038575 ====

void _StringCompare(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringCopy @ 0003857a ====

void _StringCopy(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_0003857f @ 0003857f ====

void FUN_0003857f(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringCopySafe @ 00038584 ====

void _StringCopySafe(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringFindString @ 00038589 ====

void _StringFindString(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringFormatSafe @ 0003858e ====

void _StringFormatSafe(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringFromNumber @ 00038593 ====

void _StringFromNumber(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringGetLength @ 00038598 ====

void _StringGetLength(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringToNumber @ 0003859d ====

void _StringToNumber(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringTokenize @ 000385a2 ====

void _StringTokenize(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SystemCheckCallback @ 000385a7 ====

void _SystemCheckCallback(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SystemCreateMachOWrapper @ 000385ac ====

void _SystemCreateMachOWrapper(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SystemIdle @ 000385b1 ====

void _SystemIdle(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SystemLoadMachOSymbol @ 000385b6 ====

void _SystemLoadMachOSymbol(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SystemMacOSXOrLater @ 000385bb ====

void _SystemMacOSXOrLater(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SystemRunningAsAdmin @ 000385c0 ====

void _SystemRunningAsAdmin(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SystemSetIdleProc @ 000385c5 ====

void _SystemSetIdleProc(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SystemSetQuitProc @ 000385ca ====

void _SystemSetQuitProc(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TickCount @ 000385cf ====

void _TickCount(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetElapsedSeconds @ 000385d4 ====

void _TimerGetElapsedSeconds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetLocalSeconds @ 000385d9 ====

void _TimerGetLocalSeconds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetMicroseconds @ 000385de ====

void _TimerGetMicroseconds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetMilliseconds @ 000385e3 ====

void _TimerGetMilliseconds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetSeconds @ 000385e8 ====

void _TimerGetSeconds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetTickRate @ 000385ed ====

void _TimerGetTickRate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetTicks @ 000385f2 ====

void _TimerGetTicks(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetUTCOffset @ 000385f7 ====

void _TimerGetUTCOffset(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_000385fc @ 000385fc ====

void FUN_000385fc(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetUTCSeconds @ 00038601 ====

void _TimerGetUTCSeconds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _UnlockPixels @ 00038606 ====

void _UnlockPixels(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _UnlockPortBits @ 0003860b ====

void _UnlockPortBits(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _UseResFile @ 00038610 ====

void _UseResFile(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== ___keymgr_dwarf2_register_sections @ 00038615 ====

void ___keymgr_dwarf2_register_sections(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== ___umoddi3 @ 0003861a ====

void ___umoddi3(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _atexit @ 0003861f ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

int _atexit(void *param_1)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _exit @ 00038624 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

void _exit(int param_1)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _fclose @ 00038629 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

int _fclose(FILE *param_1)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _free @ 0003862e ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

void _free(void *param_1)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _fwrite @ 00038633 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

size_t _fwrite(void *param_1,size_t param_2,size_t param_3,FILE *param_4)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _getpwuid @ 00038638 ====

void _getpwuid(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== FUN_0003863d @ 0003863d ====

void FUN_0003863d(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _getuid @ 00038642 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

uid_t _getuid(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _malloc @ 00038647 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

void * _malloc(size_t param_1)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _memcpy @ 0003864c ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

void * _memcpy(void *param_1,void *param_2,size_t param_3)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _memset @ 00038651 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

void * _memset(void *param_1,int param_2,size_t param_3)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _objc_msgSend @ 00038656 ====

void _objc_msgSend(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _objc_msgSendSuper @ 0003865b ====

void _objc_msgSendSuper(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _objc_msgSend_stret @ 00038660 ====

void _objc_msgSend_stret(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _rand @ 00038665 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

int _rand(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _random @ 0003866a ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

long _random(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _srand @ 0003866f ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

void _srand(uint param_1)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _srandom @ 00038674 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

void _srandom(uint param_1)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _time @ 00038679 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

time_t _time(time_t *param_1)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}

