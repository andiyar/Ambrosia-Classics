// Decompilation of BTX_i386 (1559 functions)

// ==== entry @ 00001c50 ====

void entry(void)

{
  __start();
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== __start @ 00001c7a ====

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
  if (*(code **)PTR_0003f000 != (code *)0x0) {
    (**(code **)PTR_0003f000)();
  }
  if (*(code **)PTR_0003f008 != (code *)0x0) {
    (**(code **)PTR_0003f008)();
  }
  ___keymgr_dwarf2_register_sections();
  __dyld_func_lookup("__dyld_make_delayed_module_initializer_calls",&local_24);
  (*local_24)();
  __dyld_func_lookup("__dyld_mod_term_funcs",local_20);
  if (local_20[0] != (void *)0x0) {
    _atexit(local_20[0]);
  }
  *(undefined4 *)PTR_0003f004 = 0;
  iVar2 = _main(param_1,param_2,param_3,piVar1 + 1);
                    /* WARNING: Subroutine does not return */
  _exit(iVar2);
}


// ==== __dyld_func_lookup @ 00001d68 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __dyld_func_lookup(void)

{
                    /* WARNING: Could not recover jumptable at 0x00001d68. Too many branches */
                    /* WARNING: Treating indirect jump as call */
  (*_DAT_000343ac)();
  return;
}


// ==== _cxa_atexit_check_2 @ 00001d6e ====

void _cxa_atexit_check_2(undefined4 *param_1)

{
  *param_1 = 1;
  return;
}


// ==== _cxa_atexit_check_1 @ 00001d7f ====

void _cxa_atexit_check_1(undefined4 *param_1)

{
  int iVar1;
  int unaff_EBX;
  
  ___i686_get_pc_thunk_bx();
  iVar1 = (*(code *)param_1[1])(unaff_EBX + -0x1d,param_1,param_1);
  if (iVar1 != 0) {
    *param_1 = 0xffffffff;
  }
  return;
}


// ==== _check_cxa_atexit @ 00001dc3 ====

int _check_cxa_atexit(code *param_1,code *param_2)

{
  int iVar1;
  int unaff_EBX;
  int local_20;
  int local_14;
  code *local_10;
  
  ___i686_get_pc_thunk_bx();
  local_14 = 0;
  local_10 = param_1;
  iVar1 = (*param_1)(unaff_EBX + -0x50,&local_14,&local_14);
  if (iVar1 == 0) {
    (*param_2)(&local_14);
    if (local_14 == 0) {
      (*param_2)(&local_14);
      local_14 = 0;
    }
    local_20 = local_14;
  }
  else {
    local_20 = -1;
  }
  return local_20;
}


// ==== _get_globals @ 00001e38 ====

void * _get_globals(void)

{
  int iVar1;
  undefined4 uVar2;
  int unaff_EBX;
  void *local_1c;
  void *local_18;
  int local_14;
  int local_10;
  
  ___i686_get_pc_thunk_bx();
  iVar1 = __keymgr_get_and_lock_processwide_ptr_2(0xe,&local_1c);
  if (iVar1 != 0) {
    return (void *)0x0;
  }
  local_18 = local_1c;
  if ((local_1c == (void *)0x0) && (local_18 = _calloc(0x14,1), local_18 == (void *)0x0)) {
    return (void *)0x0;
  }
  if (*(char *)((int)local_18 + 3) != '\0') {
    return local_18;
  }
  local_14 = _dlopen(unaff_EBX + 0x2d8ac,0x10);
  if (local_14 != 0) {
    uVar2 = _dlsym(local_14,unaff_EBX + 0x2d8c8);
    *(undefined4 *)((int)local_18 + 8) = uVar2;
    uVar2 = _dlsym(local_14,unaff_EBX + 0x2d8d8);
    *(undefined4 *)((int)local_18 + 0xc) = uVar2;
    if (((*(int *)((int)local_18 + 8) != 0) && (*(int *)((int)local_18 + 0xc) != 0)) &&
       (local_10 = _check_cxa_atexit(*(undefined4 *)((int)local_18 + 8),
                                     *(undefined4 *)((int)local_18 + 0xc)), local_10 != -1)) {
      if (local_10 == 0) {
        *(undefined1 *)((int)local_18 + 3) = 2;
      }
      else {
        uVar2 = _dlsym(local_14,unaff_EBX + 0x2d8e8);
        *(undefined4 *)((int)local_18 + 0x10) = uVar2;
        if (*(int *)((int)local_18 + 0x10) == 0) goto LAB_00001f82;
        *(undefined1 *)((int)local_18 + 3) = 0x10;
      }
      return local_18;
    }
  }
LAB_00001f82:
  __keymgr_set_and_unlock_processwide_ptr(0xe,local_18);
  return (void *)0x0;
}


// ==== _add_routine @ 00001fa5 ====

undefined4 _add_routine(int param_1,undefined4 *param_2)

{
  undefined4 *puVar1;
  int iVar2;
  undefined4 local_24;
  undefined4 local_20;
  
  puVar1 = _malloc(0x10);
  if (puVar1 == (undefined4 *)0x0) {
    __keymgr_set_and_unlock_processwide_ptr(0xe,param_1);
    local_24 = 0xffffffff;
  }
  else {
    puVar1[1] = *param_2;
    puVar1[2] = param_2[1];
    puVar1[3] = param_2[2];
    *puVar1 = *(undefined4 *)(param_1 + 4);
    *(undefined4 **)(param_1 + 4) = puVar1;
    iVar2 = __keymgr_set_and_unlock_processwide_ptr(0xe,param_1);
    if (iVar2 == 0) {
      local_20 = 0;
    }
    else {
      local_20 = 0xffffffff;
    }
    local_24 = local_20;
  }
  return local_24;
}


// ==== _run_routines @ 0000203e ====

int _run_routines(int param_1,undefined4 *param_2)

{
  undefined4 *puVar1;
  uint uVar2;
  byte local_20;
  
  while( true ) {
    puVar1 = *(undefined4 **)(param_1 + 4);
    if (puVar1 == (undefined4 *)0x0) {
      return param_1;
    }
    if (puVar1 == param_2) break;
    *(undefined4 *)(param_1 + 4) = *puVar1;
    __keymgr_set_and_unlock_processwide_ptr(0xe,param_1);
    if ((uint)puVar1[2] < 6) {
      local_20 = (byte)puVar1[2];
      uVar2 = 1 << (local_20 & 0x1f);
      if ((uVar2 & 0x15) == 0) {
        if ((uVar2 & 0x2a) != 0) {
          (*(code *)puVar1[1])(puVar1[3]);
        }
      }
      else {
        (*(code *)puVar1[1])();
      }
    }
    _free(puVar1);
    param_1 = __keymgr_get_and_lock_processwide_ptr(0xe);
    if (param_1 == 0) {
      return 0;
    }
  }
  return param_1;
}


// ==== _cxa_atexit_wrapper @ 000020fa ====

void _cxa_atexit_wrapper(undefined4 *param_1)

{
  int local_18;
  undefined4 local_14;
  undefined1 local_d;
  
  local_14 = 0;
  local_d = 0;
  local_18 = __keymgr_get_and_lock_processwide_ptr(0xe);
  if (local_18 != 0) {
    local_d = *(undefined1 *)(local_18 + 2);
    *(undefined1 *)(local_18 + 2) = 1;
    local_14 = *(undefined4 *)(local_18 + 4);
    __keymgr_set_and_unlock_processwide_ptr(0xe,local_18);
  }
  if (param_1[1] == 0) {
    (*(code *)*param_1)();
  }
  else {
    (*(code *)*param_1)(param_1[2]);
  }
  if (local_18 != 0) {
    local_18 = __keymgr_get_and_lock_processwide_ptr(0xe);
  }
  if (local_18 != 0) {
    local_18 = _run_routines(local_18,local_14);
  }
  if (local_18 != 0) {
    *(undefined1 *)(local_18 + 2) = local_d;
    __keymgr_set_and_unlock_processwide_ptr(0xe,local_18);
  }
  return;
}


// ==== _atexit_common @ 000021cb ====

undefined4 _atexit_common(undefined4 *param_1,undefined4 param_2)

{
  code *pcVar1;
  int iVar2;
  undefined4 *puVar3;
  int unaff_EBX;
  undefined4 local_30;
  
  ___i686_get_pc_thunk_bx();
  iVar2 = _get_globals();
  if (iVar2 == 0) {
    local_30 = 0xffffffff;
  }
  else if ((*(char *)(iVar2 + 2) == '\0') && (*(char *)(iVar2 + 3) != '\x01')) {
    if (*(byte *)(iVar2 + 3) < 0x10) {
      pcVar1 = *(code **)(iVar2 + 8);
      iVar2 = __keymgr_set_and_unlock_processwide_ptr(0xe,iVar2);
      if (iVar2 == 0) {
        puVar3 = _malloc(0xc);
        if (puVar3 == (undefined4 *)0x0) {
          local_30 = 0xffffffff;
        }
        else {
          *puVar3 = *param_1;
          puVar3[1] = param_1[1];
          puVar3[2] = param_1[2];
          local_30 = (*pcVar1)(unaff_EBX + -0xdd,puVar3,param_2);
        }
      }
      else {
        local_30 = 0xffffffff;
      }
    }
    else if (param_1[1] == 0) {
      pcVar1 = *(code **)(iVar2 + 0x10);
      iVar2 = __keymgr_set_and_unlock_processwide_ptr(0xe,iVar2);
      if (iVar2 == 0) {
        local_30 = (*pcVar1)(*param_1);
      }
      else {
        local_30 = 0xffffffff;
      }
    }
    else {
      pcVar1 = *(code **)(iVar2 + 8);
      iVar2 = __keymgr_set_and_unlock_processwide_ptr(0xe,iVar2);
      if (iVar2 == 0) {
        local_30 = (*pcVar1)(*param_1,param_1[2],param_2);
      }
      else {
        local_30 = 0xffffffff;
      }
    }
  }
  else {
    local_30 = _add_routine(iVar2,param_1);
  }
  return local_30;
}


// ==== ___cxa_atexit @ 00002361 ====

void ___cxa_atexit(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  undefined4 local_18;
  undefined4 local_14;
  undefined4 local_10;
  
  local_18 = param_1;
  local_14 = 1;
  local_10 = param_2;
  _atexit_common(&local_18,param_3);
  return;
}


// ==== _atexit @ 0000238e ====

int _atexit(void *param_1)

{
  int iVar1;
  int unaff_EBX;
  void *local_18;
  undefined4 local_14;
  
  ___i686_get_pc_thunk_bx();
  local_18 = param_1;
  local_14 = 0;
  iVar1 = _atexit_common(&local_18,*(undefined4 *)(&DAT_0003cc72 + unaff_EBX));
  return iVar1;
}


// ==== _ResetPoint @ 000023c4 ====

void _ResetPoint(char param_1)

{
  int iVar1;
  char *pcVar2;
  char *pcVar3;
  char *pcVar4;
  char *pcVar5;
  undefined1 uVar6;
  
  iVar1 = param_1 * 0x18;
  uVar6 = iVar1 == 0;
  (&_points)[iVar1] = 0;
  (&DAT_00034636)[iVar1] = 0;
  pcVar2 = (char *)_RT3_GetDisplayCopies();
  iVar1 = 4;
  pcVar4 = "N/A";
  do {
    pcVar3 = pcVar2;
    pcVar5 = pcVar4;
    if (iVar1 == 0) break;
    iVar1 = iVar1 + -1;
    pcVar5 = pcVar4 + 1;
    pcVar3 = pcVar2 + 1;
    uVar6 = *pcVar2 == *pcVar4;
    pcVar2 = pcVar3;
    pcVar4 = pcVar5;
  } while ((bool)uVar6);
  iVar1 = 0;
  if (!(bool)uVar6) {
    iVar1 = (uint)(byte)pcVar3[-1] - (uint)(byte)pcVar5[-1];
  }
  _gPointsNotReg = iVar1 == 0;
  _gNumActivePoints = _gNumActivePoints + -1;
  return;
}


// ==== _InitPoints @ 0000241b ====

void _InitPoints(void)

{
  short sVar1;
  int iVar2;
  undefined1 *puVar3;
  
  iVar2 = 0;
  puVar3 = &_points;
  do {
    _ResetPoint(iVar2);
    sVar1 = _GetRandomFast(2,6);
    *(short *)(puVar3 + 0x12) = sVar1 + 0x12;
    iVar2 = iVar2 + 1;
    puVar3 = puVar3 + 0x18;
  } while (iVar2 != 8);
  _gNumActivePoints = 0;
  return;
}


// ==== _NewPoint @ 00002468 ====

void _NewPoint(short param_1,short param_2,char param_3,short param_4)

{
  short sVar1;
  char *pcVar2;
  int iVar3;
  int iVar4;
  
  if (_gNumActivePoints != 8) {
    param_1 = param_1 + -4;
    if (param_1 < 0) {
      param_1 = 0;
    }
    else if (0x280 < param_1 + 0x30) {
      param_1 = 0x250;
    }
    iVar3 = 0;
    pcVar2 = &_points;
    iVar4 = 0;
    do {
      if (*pcVar2 == '\0') {
        (&_points)[iVar4] = 1;
        *(undefined2 *)((int)&DAT_0003462a + iVar4) = 0x34;
        *(short *)((int)&DAT_0003462c + iVar4) = (short)param_3;
        *(undefined2 *)((int)&DAT_0003462e + iVar4) = 0;
        (&DAT_00034637)[iVar4] = 0;
        *(short *)((int)&DAT_00034624 + iVar4) = param_1;
        *(short *)((int)&DAT_00034622 + iVar4) = param_2 + 8;
        *(short *)((int)&DAT_00034628 + iVar4) = param_1 + 0x30;
        *(short *)((int)&DAT_00034626 + iVar4) = param_2 + 0x24;
        sVar1 = _GetPtrLevel();
        if ((*(short *)((int)&DAT_00034632 + iVar4) <= sVar1) && (_gPointsNotReg != '\0')) {
          (&DAT_00034636)[iVar4] = 1;
        }
        *(short *)((int)&DAT_00034630 + iVar4) = param_4;
        if (param_4 < 1) {
          (&DAT_00034634)[iVar4] = 0;
          (&DAT_00034635)[iVar4] = 1;
        }
        else {
          (&DAT_00034634)[iVar4] = 1;
          (&DAT_00034635)[iVar4] = 0;
        }
        _gNumActivePoints = _gNumActivePoints + 1;
        return;
      }
      iVar3 = iVar3 + 1;
      iVar4 = iVar4 + 0x18;
      pcVar2 = pcVar2 + 0x18;
    } while (iVar3 != 8);
  }
  return;
}


// ==== _ProcessPoints @ 00002585 ====

void _ProcessPoints(void)

{
  short sVar1;
  char *pcVar2;
  int iVar3;
  undefined2 *puVar4;
  undefined2 *local_20;
  
  if (_gNumActivePoints != 0) {
    iVar3 = 0;
    pcVar2 = &_points;
    puVar4 = &DAT_00034622;
    local_20 = &DAT_00034622;
    do {
      if (*pcVar2 != '\0') {
        if (pcVar2[0x14] == '\0') {
          if (0 < *(short *)(pcVar2 + 2)) {
            _OffsetRect(local_20,0,0xffffffff);
          }
          sVar1 = *(short *)(pcVar2 + 0xe);
          *(ushort *)(pcVar2 + 0xe) = sVar1 + 1U;
          if (0x1e < (ushort)(sVar1 + 1U)) {
            pcVar2[0x17] = '\x01';
            pcVar2[0x15] = '\0';
          }
          _AddRectToBgnd(puVar4);
        }
        else {
          sVar1 = *(short *)(pcVar2 + 0xe);
          *(ushort *)(pcVar2 + 0xe) = sVar1 + 1U;
          if ((int)*(short *)(pcVar2 + 0x10) < (int)(uint)(ushort)(sVar1 + 1U)) {
            pcVar2[0xe] = '\0';
            pcVar2[0xf] = '\0';
            pcVar2[0x14] = '\0';
            pcVar2[0x15] = '\x01';
          }
        }
      }
      iVar3 = iVar3 + 1;
      local_20 = local_20 + 0xc;
      puVar4 = puVar4 + 0xc;
      pcVar2 = pcVar2 + 0x18;
    } while (iVar3 != 8);
  }
  return;
}


// ==== _DrawPointsToComp @ 00002641 ====

void _DrawPointsToComp(void)

{
  short sVar1;
  char *pcVar2;
  int iVar3;
  undefined2 *puVar4;
  
  if (_gNumActivePoints != 0) {
    iVar3 = 0;
    pcVar2 = &_points;
    puVar4 = &DAT_00034622;
    do {
      if (*pcVar2 != '\0') {
        if (pcVar2[0x15] != '\0') {
          _SpriteToComp(0,(int)*(short *)(pcVar2 + 4),(int)*(short *)(pcVar2 + 2),
                        (int)*(short *)(pcVar2 + 10),(int)*(short *)(pcVar2 + 0xc),1);
        }
        _AddRectToScreen(puVar4);
        if (pcVar2[0x16] != '\0') {
          sVar1 = _GetRandomFast(0,0x14);
          if (sVar1 == 1) {
            _StdError("Unable to contact Ambrosia web server to report a hacked copy of Bubble Trouble. Please check your Internet connection and try again."
                      ,0xffffffd9);
          }
        }
        if (pcVar2[0x17] != '\0') {
          _ResetPoint(iVar3);
        }
      }
      iVar3 = iVar3 + 1;
      puVar4 = puVar4 + 0xc;
      pcVar2 = pcVar2 + 0x18;
    } while (iVar3 != 8);
  }
  return;
}


// ==== _LoadIcon @ 0000270b ====

bool _LoadIcon(short param_1,short *param_2,short *param_3,int *param_4)

{
  undefined4 uVar1;
  undefined4 uVar2;
  int iVar3;
  
  iVar3 = _GetCIcon((int)param_1);
  *param_4 = iVar3;
  if (iVar3 != 0) {
    _MoveHHi(iVar3);
    _HLock(*param_4);
    uVar1 = *(undefined4 *)(*(int *)*param_4 + 10);
    uVar2 = *(undefined4 *)(*(int *)*param_4 + 6);
    *param_2 = (short)((uint)uVar1 >> 0x10) - (short)((uint)uVar2 >> 0x10);
    *param_3 = (short)uVar1 - (short)uVar2;
  }
  return iVar3 != 0;
}


// ==== _InitROCS @ 0000276e ====

void _InitROCS(void)

{
  undefined4 uVar1;
  
  uVar1 = _GetWorldBgndBase();
  *(undefined4 *)PTR__gBgndBase_0003402c = uVar1;
  uVar1 = _GetWorldBgndRB();
  *(undefined4 *)PTR__gBgndRB_00034018 = uVar1;
  uVar1 = _GetWorldCompBase();
  *(undefined4 *)PTR__gCompBase_00034028 = uVar1;
  uVar1 = _GetWorldCompRB();
  *(undefined4 *)PTR__gCompRB_00034020 = uVar1;
  return;
}


// ==== _BlastItTransparent @ 000027aa ====

/* WARNING: Removing unreachable block (ram,0x000028be) */

void _BlastItTransparent(void)

{
  uint uVar1;
  bool bVar2;
  uint uVar3;
  int iVar4;
  uint uVar5;
  uint *puVar6;
  uint uVar7;
  uint *local_24;
  
  puVar6 = *(uint **)PTR__gSrcMem_0003401c;
  local_24 = *(uint **)PTR__gDestMem_00034014;
  bVar2 = false;
  do {
    while( true ) {
      while( true ) {
        uVar1 = *puVar6;
        uVar3 = uVar1 >> 0x18;
        uVar7 = uVar1 & 0xffffff;
        puVar6 = puVar6 + 1;
        if (uVar3 != 2) break;
        if ((uVar1 & 1) == 1) {
          bVar2 = (bool)(bVar2 ^ 1);
        }
        local_24 = (uint *)((int)local_24 + uVar7);
      }
      if (2 < uVar3) break;
      if (uVar3 == 1) {
        for (; 3 < uVar7; uVar7 = uVar7 - 4) {
          if (bVar2) {
            uVar3 = *puVar6 & 0xff00ff;
            uVar5 = *local_24 & 0xff00ff00;
          }
          else {
            uVar3 = *puVar6 & 0xff00ff00;
            uVar5 = *local_24 & 0xff00ff;
          }
          *local_24 = uVar3 | uVar5;
          puVar6 = puVar6 + 1;
          local_24 = local_24 + 1;
        }
        if (1 < uVar7) {
          if (bVar2) {
            *(char *)local_24 = (char)*puVar6;
          }
          else {
            *(undefined1 *)((int)local_24 + 1) = *(undefined1 *)((int)puVar6 + 1);
          }
          local_24 = (uint *)((int)local_24 + 2);
          puVar6 = (uint *)((int)puVar6 + 2);
          uVar7 = uVar7 - 2;
        }
        if (uVar7 != 0) {
          if (bVar2) {
            *(char *)local_24 = (char)*puVar6;
          }
          local_24 = (uint *)((int)local_24 + 1);
          puVar6 = (uint *)((int)puVar6 + 1);
          bVar2 = (bool)(bVar2 ^ 1);
        }
        if ((uVar1 & 3) == 0) {
          iVar4 = 0;
        }
        else {
          iVar4 = 4 - (uVar1 & 3);
        }
        puVar6 = (uint *)((int)puVar6 + iVar4);
      }
      else {
LAB_000027ea:
        _ResultErrorInt(0x7d1,5,uVar3);
      }
    }
    if (uVar3 != 3) {
      if (uVar3 == 4) {
        return;
      }
      goto LAB_000027ea;
    }
    bVar2 = (bool)(bVar2 ^ 1);
    local_24 = (uint *)((int)local_24 + *(int *)PTR__gDestWorldIncr_00034024);
  } while( true );
}


// ==== _PlotCompiledTransToComp @ 000028fd ====

void _PlotCompiledTransToComp(short *param_1,short param_2,short param_3)

{
  int iVar1;
  
  iVar1 = *(int *)PTR__gCompRB_00034020;
  *(int *)PTR__gDestMem_00034014 = param_3 * iVar1 + *(int *)PTR__gCompBase_00034028 + (int)param_2;
  *(short **)PTR__gSrcMem_0003401c = param_1 + 2;
  *(int *)PTR__gDestWorldIncr_00034024 = iVar1 - *param_1;
  _BlastItTransparent();
  return;
}


// ==== _PlotCompiledTransToBgnd @ 00002945 ====

void _PlotCompiledTransToBgnd(short *param_1,short param_2,short param_3)

{
  int iVar1;
  
  iVar1 = *(int *)PTR__gBgndRB_00034018;
  *(int *)PTR__gDestMem_00034014 = param_3 * iVar1 + *(int *)PTR__gBgndBase_0003402c + (int)param_2;
  *(short **)PTR__gSrcMem_0003401c = param_1 + 2;
  *(int *)PTR__gDestWorldIncr_00034024 = iVar1 - *param_1;
  _BlastItTransparent();
  return;
}


// ==== _BlastIt @ 0000298d ====

void _BlastIt(void)

{
  uint uVar1;
  uint uVar2;
  int iVar3;
  uint uVar4;
  uint *puVar5;
  uint *puVar6;
  
  puVar5 = *(uint **)PTR__gSrcMem_0003401c;
  puVar6 = *(uint **)PTR__gDestMem_00034014;
  do {
    while( true ) {
      while( true ) {
        uVar1 = *puVar5;
        uVar2 = uVar1 >> 0x18;
        uVar4 = uVar1 & 0xffffff;
        puVar5 = puVar5 + 1;
        if (uVar2 != 2) break;
        puVar6 = (uint *)((int)puVar6 + uVar4);
      }
      if (2 < uVar2) break;
      if (uVar2 == 1) {
        for (; 7 < uVar4; uVar4 = uVar4 - 8) {
          *(undefined8 *)puVar6 = *(undefined8 *)puVar5;
          puVar6 = puVar6 + 2;
          puVar5 = puVar5 + 2;
        }
        if (3 < uVar4) {
          *puVar6 = *puVar5;
          puVar6 = puVar6 + 1;
          puVar5 = puVar5 + 1;
          uVar4 = uVar4 - 4;
        }
        if (1 < uVar4) {
          *(short *)puVar6 = (short)*puVar5;
          puVar6 = (uint *)((int)puVar6 + 2);
          puVar5 = (uint *)((int)puVar5 + 2);
          uVar4 = uVar4 - 2;
        }
        if (uVar4 != 0) {
          *(char *)puVar6 = (char)*puVar5;
          puVar6 = (uint *)((int)puVar6 + 1);
          puVar5 = (uint *)((int)puVar5 + 1);
        }
        if ((uVar1 & 3) == 0) {
          iVar3 = 0;
        }
        else {
          iVar3 = 4 - (uVar1 & 3);
        }
        puVar5 = (uint *)((int)puVar5 + iVar3);
      }
      else {
LAB_000029c5:
        _ResultErrorInt(0x7d1,5,uVar2);
      }
    }
    if (uVar2 != 3) {
      if (uVar2 == 4) {
        return;
      }
      goto LAB_000029c5;
    }
    puVar6 = (uint *)((int)puVar6 + *(int *)PTR__gDestWorldIncr_00034024);
  } while( true );
}


// ==== _PlotCompiledGraphicToComp @ 00002a69 ====

void _PlotCompiledGraphicToComp(short *param_1,short param_2,short param_3)

{
  int iVar1;
  
  iVar1 = *(int *)PTR__gCompRB_00034020;
  *(int *)PTR__gDestMem_00034014 = param_3 * iVar1 + *(int *)PTR__gCompBase_00034028 + (int)param_2;
  *(short **)PTR__gSrcMem_0003401c = param_1 + 2;
  *(int *)PTR__gDestWorldIncr_00034024 = iVar1 - *param_1;
  _BlastIt();
  return;
}


// ==== _PlotCompiledGraphicToBgnd @ 00002ab1 ====

void _PlotCompiledGraphicToBgnd(short *param_1,short param_2,short param_3)

{
  int iVar1;
  
  iVar1 = *(int *)PTR__gBgndRB_00034018;
  *(int *)PTR__gDestMem_00034014 = param_3 * iVar1 + *(int *)PTR__gBgndBase_0003402c + (int)param_2;
  *(short **)PTR__gSrcMem_0003401c = param_1 + 2;
  *(int *)PTR__gDestWorldIncr_00034024 = iVar1 - *param_1;
  _BlastIt();
  return;
}


// ==== _Splats_ResetSplat @ 00002af9 ====

void _Splats_ResetSplat(short param_1)

{
  (&_splat)[param_1 * 0x1e] = 0;
  return;
}


// ==== _Splats_NewSplat @ 00002b11 ====

void _Splats_NewSplat(short param_1,short param_2,char param_3)

{
  undefined2 uVar1;
  char *pcVar2;
  int iVar3;
  int iVar4;
  
  iVar3 = 0;
  pcVar2 = &_splat;
  iVar4 = 0;
  do {
    if (*pcVar2 == '\0') {
      uVar1 = _GetFrameCounter();
      (&_splat)[iVar4] = 1;
      *(undefined2 *)((int)&DAT_00034702 + iVar4) = uVar1;
      (&DAT_00034704)[iVar4] = param_3;
      (&DAT_0003471d)[iVar4] = 0;
      if (param_3 == '\0') {
        *(undefined2 *)((int)&DAT_00034716 + iVar4) = 0x26;
      }
      else if (param_3 == '\x01') {
        *(undefined2 *)((int)&DAT_00034716 + iVar4) = 0x27;
      }
      *(short *)((int)&DAT_00034706 + iVar4 + 2) = param_1;
      *(short *)((int)&DAT_00034706 + iVar4) = param_2;
      *(short *)((int)&DAT_0003470a + iVar4 + 2) = param_1 + 0x28;
      *(short *)((int)&DAT_0003470a + iVar4) = param_2 + 0x28;
      *(undefined4 *)((int)&DAT_0003470e + iVar4) = *(undefined4 *)((int)&DAT_00034706 + iVar4);
      *(undefined4 *)((int)&DAT_00034712 + iVar4) = *(undefined4 *)((int)&DAT_0003470a + iVar4);
      *(undefined2 *)((int)&DAT_00034718 + iVar4) = 1;
      *(undefined2 *)((int)&DAT_0003471a + iVar4) = uVar1;
      (&DAT_0003471c)[iVar4] = 1;
      return;
    }
    iVar3 = iVar3 + 1;
    iVar4 = iVar4 + 0x1e;
    pcVar2 = pcVar2 + 0x1e;
  } while (iVar3 != 0xc);
  _DebugValues();
  return;
}


// ==== _Splats_Process @ 00002c0b ====

void _Splats_Process(void)

{
  uint uVar1;
  char *pcVar2;
  int iVar3;
  undefined4 *puVar4;
  
  uVar1 = _GetFrameCounter();
  iVar3 = 0;
  pcVar2 = &_splat;
  puVar4 = &DAT_0003470e;
  do {
    if (*pcVar2 != '\0') {
      if (*(ushort *)(pcVar2 + 0x1a) + 7 < (uVar1 & 0xffff)) {
        pcVar2[0x1d] = '\x01';
        pcVar2[0x1c] = '\0';
      }
      _AddRectToBgnd(puVar4);
    }
    iVar3 = iVar3 + 1;
    puVar4 = (undefined4 *)((int)puVar4 + 0x1e);
    pcVar2 = pcVar2 + 0x1e;
  } while (iVar3 != 0xc);
  return;
}


// ==== _Splats_Init @ 00002c62 ====

void _Splats_Init(void)

{
  undefined1 *puVar1;
  
  puVar1 = &_splat;
  do {
    *puVar1 = 0;
    puVar1 = puVar1 + 0x1e;
  } while (puVar1 != &_gLevelSymbol_Sprite);
  return;
}


// ==== _Splats_DrawToComp @ 00002c79 ====

void _Splats_DrawToComp(void)

{
  undefined4 *puVar1;
  undefined4 *puVar2;
  int iVar3;
  undefined1 *puVar4;
  undefined4 *local_30;
  undefined4 local_24 [5];
  
  iVar3 = 0;
  puVar2 = &DAT_0003470e;
  local_30 = &DAT_0003470e;
  puVar4 = &_splat;
  do {
    if (*(char *)((int)puVar2 + -0xe) != '\0') {
      puVar1 = local_30;
      if (*(char *)((int)puVar2 + 0xe) != '\0') {
        _SpriteToComp(0,(int)*(short *)((int)puVar2 + -6),(int)*(short *)(puVar2 + -2),
                      (int)*(short *)(puVar2 + 2),(int)*(short *)((int)puVar2 + 10),1);
        _UnionRect(puVar4 + 0xe,puVar4 + 6,local_24);
        puVar1 = local_24;
      }
      _AddRectToScreen(puVar1);
      if (*(char *)((int)puVar2 + 0xf) == '\0') {
        *puVar2 = puVar2[-2];
        puVar2[1] = puVar2[-1];
      }
      else {
        *(undefined1 *)((int)puVar2 + -0xe) = 0;
      }
    }
    iVar3 = iVar3 + 1;
    puVar4 = puVar4 + 0x1e;
    local_30 = (undefined4 *)((int)local_30 + 0x1e);
    puVar2 = (undefined4 *)((int)puVar2 + 0x1e);
  } while (iVar3 != 0xc);
  return;
}


// ==== _InitLevelSymbol @ 00002d33 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _InitLevelSymbol(void)

{
  _DAT_00034870 = 600;
  __gLevelSymbol_Rect = 0x1be;
  _DAT_00034874 = 0x274;
  _DAT_00034872 = 0x1da;
  _gLevelSymbol_NeedsDrawing = 0;
  return;
}


// ==== _LoadLevelSymbol @ 00002d63 ====

void _LoadLevelSymbol(void)

{
  return;
}


// ==== _CheckLevel @ 00002d68 ====

void _CheckLevel(int *param_1,short param_2)

{
  int iVar1;
  undefined1 uVar2;
  int *piVar3;
  int iVar4;
  short sVar5;
  int iVar6;
  
  piVar3 = (int *)_GetResource(0x4441524b,0x81);
  if (piVar3 == (int *)0x0) {
    _ResourceError(0x7de,3,"DARK",0x81);
  }
  _MoveHHi(piVar3);
  _HLock(piVar3);
  iVar1 = *(int *)(*piVar3 + -4 + param_2 * 4);
  _ReleaseResource(piVar3);
  iVar4 = _GetHandleSize(param_1);
  iVar6 = 0;
  sVar5 = 0;
  while( true ) {
    if (iVar4 / 2 <= (int)sVar5) break;
    iVar6 = iVar6 + (uint)*(ushort *)(*param_1 + sVar5 * 2);
    sVar5 = sVar5 + 1;
  }
  uVar2 = 0;
  if (iVar1 == iVar6) {
    uVar2 = _gLevelsOkay;
  }
  _gLevelsOkay = uVar2;
  return;
}


// ==== _LevelsOkay @ 00002e22 ====

undefined1 _LevelsOkay(void)

{
  return _gLevelsOkay;
}


// ==== _ResetLevelHackCheck @ 00002e2e ====

void _ResetLevelHackCheck(void)

{
  _gLevelsOkay = 1;
  return;
}


// ==== _CheckMaze @ 00002e3a ====

void _CheckMaze(int *param_1,short param_2)

{
  int iVar1;
  undefined1 uVar2;
  int *piVar3;
  int iVar4;
  short sVar5;
  int iVar6;
  
  piVar3 = (int *)_GetResource(0x4441524b,0x81);
  if (piVar3 == (int *)0x0) {
    _ResourceError(0x7de,3,"DARK",0x81);
  }
  _MoveHHi(piVar3);
  _HLock(piVar3);
  iVar1 = *(int *)(*piVar3 + 0xc4 + param_2 * 4);
  _ReleaseResource(piVar3);
  iVar4 = _GetHandleSize(param_1);
  iVar6 = 0;
  sVar5 = 0;
  while( true ) {
    if (iVar4 / 2 <= (int)sVar5) break;
    iVar6 = iVar6 + (uint)*(ushort *)(*param_1 + sVar5 * 2);
    sVar5 = sVar5 + 1;
  }
  uVar2 = 0;
  if (iVar1 == iVar6) {
    uVar2 = _gLevelsOkay;
  }
  _gLevelsOkay = uVar2;
  return;
}


// ==== _LoadLevel @ 00002ef7 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _LoadLevel(short param_1)

{
  short sVar1;
  short sVar2;
  short sVar3;
  short sVar4;
  short sVar5;
  undefined2 *puVar6;
  undefined *puVar7;
  short sVar8;
  undefined4 *puVar9;
  int local_20;
  
  if (param_1 < 100) {
    if (param_1 < 0x33) goto LAB_00002f34;
  }
  else {
    _SetCurrLevelNum(99);
  }
  param_1 = _GetRandomFast(0x15,0x32);
LAB_00002f34:
  sVar8 = _GetShortPref(0x3a);
  if ((sVar8 < param_1) && (param_1 < 0x1f)) {
    _SetShortPref(0x3a,(int)param_1);
  }
  local_20 = (int)param_1;
  _SaveGamePrefs();
  puVar9 = (undefined4 *)_GetResource(0x4c45564c,local_20);
  if (puVar9 == (undefined4 *)0x0) {
    _ResourceError(0x7de,2,"LEVL",local_20);
  }
  else {
    _MoveHHi(puVar9);
    _HLock(puVar9);
    _OtherLevCheck(puVar9,local_20);
    puVar7 = PTR__level_0003f010;
    puVar6 = (undefined2 *)*puVar9;
    *(undefined2 *)PTR__level_0003f010 = *puVar6;
    *(undefined2 *)(puVar7 + 2) = puVar6[1];
    *(undefined2 *)(puVar7 + 4) = puVar6[2];
    *(undefined2 *)(puVar7 + 6) = puVar6[3];
    *(undefined2 *)(puVar7 + 8) = puVar6[4];
    *(undefined2 *)(puVar7 + 10) = puVar6[5];
    sVar8 = 0x1e;
    if ((short)puVar6[6] < 0x1f) {
      sVar8 = puVar6[6];
    }
    *(short *)(puVar7 + 0xc) = sVar8;
    *(undefined2 *)(puVar7 + 0xe) = puVar6[7];
    *(undefined2 *)(puVar7 + 0x10) = puVar6[8];
    *(undefined2 *)(puVar7 + 0x12) = puVar6[9];
    *(undefined2 *)(puVar7 + 0x14) = puVar6[10];
    *(undefined2 *)(puVar7 + 0x16) = puVar6[0xb];
    puVar7 = PTR__level_0003f010;
    sVar8 = 3;
    if (2 < (short)puVar6[0xc]) {
      sVar8 = puVar6[0xc];
    }
    *(short *)(PTR__level_0003f010 + 0x18) = sVar8;
    if (4 < sVar8) {
      *(undefined2 *)(puVar7 + 0x18) = 4;
    }
    puVar7 = PTR__level_0003f010;
    *(undefined2 *)(PTR__level_0003f010 + 0x1a) = puVar6[0xd];
    *(undefined2 *)(puVar7 + 0x1c) = puVar6[0xe];
    *(undefined2 *)(puVar7 + 0x1e) = puVar6[0xf];
    *(undefined2 *)(puVar7 + 0x20) = puVar6[0x10];
    *(undefined2 *)(puVar7 + 0x22) = puVar6[0x11];
    sVar8 = puVar6[0x12];
    *(short *)(puVar7 + 0x24) = sVar8;
    sVar1 = puVar6[0x13];
    *(short *)(puVar7 + 0x26) = sVar1;
    sVar2 = puVar6[0x14];
    *(short *)(puVar7 + 0x28) = sVar2;
    sVar3 = puVar6[0x15];
    *(short *)(puVar7 + 0x2a) = sVar3;
    sVar4 = puVar6[0x16];
    *(short *)(puVar7 + 0x2c) = sVar4;
    sVar5 = puVar6[0x17];
    *(short *)(PTR__level_0003f010 + 0x2e) = sVar5;
    *(undefined4 *)(PTR__level_0003f010 + 0x30) = *(undefined4 *)(puVar6 + 0x18);
    *(undefined4 *)(PTR__level_0003f010 + 0x34) = *(undefined4 *)(puVar6 + 0x1a);
    *(undefined4 *)(PTR__level_0003f010 + 0x38) = *(undefined4 *)(puVar6 + 0x1c);
    *(undefined4 *)(PTR__level_0003f010 + 0x3c) = *(undefined4 *)(puVar6 + 0x1e);
    if ((int)sVar8 + (int)sVar1 + (int)sVar2 + (int)sVar3 + (int)sVar4 + (int)sVar5 !=
        (int)*(short *)(PTR__level_0003f010 + 0xc)) {
      _LocationError(0x7de,1);
    }
    _CheckLevelReroute(puVar9,local_20);
    _ReleaseResource(puVar9);
  }
  _DAT_00034870 = 600;
  __gLevelSymbol_Rect = 0x1be;
  _DAT_00034874 = 0x274;
  _DAT_00034872 = 0x1da;
  _gLevelSymbol_NeedsDrawing = 0;
  return;
}


// ==== _LoadOrbitData @ 000031a6 ====

void _LoadOrbitData(void)

{
  undefined4 *puVar1;
  size_t sVar2;
  
  puVar1 = (undefined4 *)_GetResource(0x5350494e,1);
  if (puVar1 == (undefined4 *)0x0) {
    _DeathAlert(6);
  }
  else {
    _HLock(puVar1);
    _HNoPurge(puVar1);
    sVar2 = _GetHandleSize(puVar1);
    if (0 < (int)sVar2) {
      _memmove(PTR__gOrbit_Table_00034034,(void *)*puVar1,sVar2);
    }
    _ReleaseResource(puVar1);
  }
  return;
}


// ==== _ResetStar @ 00003216 ====

void _ResetStar(short param_1)

{
  PTR__star_0003403c[param_1 * 0x38] = 0;
  *(short *)PTR__gNumActiveStars_00034040 = *(short *)PTR__gNumActiveStars_00034040 + -1;
  return;
}


// ==== _CreateStarRandomLocLookupTable @ 0000323e ====

void _CreateStarRandomLocLookupTable(void)

{
  short *psVar1;
  short sVar2;
  short *psVar3;
  
  *(undefined2 *)PTR__gStarsLocationIndex_00034038 = 0;
  psVar1 = (short *)(PTR__gStarsLocationLookup_00034030 + 0x2a);
  psVar3 = (short *)PTR__gStarsLocationLookup_00034030;
  do {
    sVar2 = _GetRandomFast(0,8);
    *psVar3 = sVar2;
    sVar2 = _GetRandomFast(0,1);
    if (sVar2 != 0) {
      *psVar3 = -*psVar3;
    }
    psVar3 = psVar3 + 1;
  } while (psVar1 != psVar3);
  return;
}


// ==== _NewStar @ 0000329a ====

void _NewStar(short param_1,short param_2,undefined2 param_3,short param_4,short param_5,
             undefined2 param_6)

{
  int iVar1;
  undefined *puVar2;
  undefined2 uVar3;
  short sVar4;
  char *pcVar5;
  int iVar6;
  undefined *local_2c;
  short local_20;
  short local_1e;
  
  puVar2 = PTR__star_0003403c;
  local_1e = param_1;
  local_20 = param_2;
  if (*(short *)PTR__gNumActiveStars_00034040 == 0x3c) {
    return;
  }
  iVar6 = 0;
  pcVar5 = PTR__star_0003403c;
  while (*pcVar5 != '\0') {
    iVar6 = iVar6 + 1;
    pcVar5 = pcVar5 + 0x38;
    if (iVar6 == 0x3c) {
      return;
    }
  }
  iVar1 = iVar6 * 0x38;
  PTR__star_0003403c[iVar1] = 1;
  uVar3 = _GetFrameCounter();
  *(undefined2 *)(puVar2 + iVar1 + 2) = uVar3;
  *(undefined2 *)(puVar2 + iVar1 + 0x1e) = 1;
  *(undefined2 *)(puVar2 + iVar1 + 0x20) = 0;
  *(undefined2 *)(puVar2 + iVar1 + 4) = param_3;
  local_2c = PTR__star_0003403c;
  switch(param_3) {
  default:
    return;
  case 1:
    goto LAB_000033ea;
  case 2:
    goto LAB_000033ea;
  case 3:
LAB_000033ea:
    *(undefined2 *)(PTR__star_0003403c + iVar6 * 0x38 + 0x18) = 0x1a;
    *(undefined2 *)(local_2c + iVar6 * 0x38 + 0x1a) = 0x1a;
    *(undefined2 *)(local_2c + iVar6 * 0x38 + 0x1c) = 0x28;
    break;
  case 4:
    *(undefined2 *)(PTR__star_0003403c + iVar6 * 0x38 + 0x18) = 0x1a;
    *(undefined2 *)(local_2c + iVar6 * 0x38 + 0x1a) = 0x1a;
    *(undefined2 *)(local_2c + iVar6 * 0x38 + 0x1c) = 0x29;
    break;
  case 5:
    *(undefined2 *)(PTR__star_0003403c + iVar6 * 0x38 + 0x18) = 0x1a;
    *(undefined2 *)(local_2c + iVar6 * 0x38 + 0x1a) = 0x1a;
    *(undefined2 *)(local_2c + iVar6 * 0x38 + 0x1c) = 0x2a;
    break;
  case 6:
    *(undefined2 *)(PTR__star_0003403c + iVar6 * 0x38 + 0x18) = 0x1a;
    *(undefined2 *)(local_2c + iVar6 * 0x38 + 0x1a) = 0x1a;
    *(undefined2 *)(local_2c + iVar6 * 0x38 + 0x1c) = 0x2b;
    break;
  case 7:
    local_1e = param_1 + 1;
    local_20 = param_2 + 1;
    *(undefined2 *)(PTR__star_0003403c + iVar6 * 0x38 + 0x18) = 0x26;
    *(undefined2 *)(local_2c + iVar6 * 0x38 + 0x1a) = 0x26;
    *(undefined2 *)(local_2c + iVar6 * 0x38 + 0x1c) = 0x2c;
  }
  iVar1 = iVar6 * 0x38;
  *(short *)(local_2c + iVar1 + 10) = local_1e;
  *(short *)(local_2c + iVar1 + 8) = local_20;
  *(short *)(local_2c + iVar1 + 0xe) = local_1e + *(short *)(local_2c + iVar1 + 0x18);
  *(short *)(local_2c + iVar1 + 0xc) = local_20 + *(short *)(local_2c + iVar1 + 0x1a);
  *(undefined4 *)(local_2c + iVar1 + 0x10) = *(undefined4 *)(local_2c + iVar1 + 8);
  *(undefined4 *)(local_2c + iVar1 + 0x14) = *(undefined4 *)(local_2c + iVar1 + 0xc);
  if ((((*(short *)(local_2c + iVar1 + 10) < 0) || (0x280 < *(short *)(local_2c + iVar1 + 0xe))) ||
      (*(short *)(local_2c + iVar1 + 8) < 0)) || (0x1b8 < *(short *)(local_2c + iVar1 + 0xc))) {
    local_2c[iVar6 * 0x38] = 0;
    return;
  }
  *(short *)(local_2c + iVar1 + 6) = param_5;
  if (param_5 == 2) {
    *(undefined4 *)(local_2c + iVar1 + 0x30) = *(undefined4 *)(local_2c + iVar1 + 8);
    *(undefined4 *)(local_2c + iVar1 + 0x34) = *(undefined4 *)(local_2c + iVar1 + 0xc);
    *(undefined2 *)(local_2c + iVar1 + 0x2e) = param_6;
    *(undefined2 *)(local_2c + iVar1 + 0x2a) = 0;
    *(undefined2 *)(local_2c + iVar1 + 0x2c) = 4;
  }
  else {
    if (param_5 == 0xb) {
      *(undefined2 *)(local_2c + iVar1 + 0x2a) = 0xfff6;
      *(undefined2 *)(local_2c + iVar1 + 0x2c) = 7;
      sVar4 = _GetRandomFast(0,1);
      if (sVar4 == 0) {
        *(undefined2 *)(local_2c + iVar1 + 0x28) = 0xfffb;
        local_2c = PTR__star_0003403c;
      }
      else {
        *(undefined2 *)(local_2c + iVar1 + 0x28) = 5;
        local_2c = PTR__star_0003403c;
      }
      goto LAB_0000355b;
    }
    *(undefined2 *)(local_2c + iVar1 + 0x2a) = 0;
    *(undefined2 *)(local_2c + iVar1 + 0x2c) = 2;
  }
  *(undefined2 *)(local_2c + iVar1 + 0x28) = 0;
LAB_0000355b:
  local_2c[iVar6 * 0x38 + 0x26] = 0;
  *(short *)(local_2c + iVar6 * 0x38 + 0x22) = param_4;
  if (param_4 < 1) {
    local_2c[iVar6 * 0x38 + 0x24] = 0;
    local_2c[iVar6 * 0x38 + 0x25] = 1;
  }
  else {
    local_2c[iVar6 * 0x38 + 0x24] = 1;
    local_2c[iVar6 * 0x38 + 0x25] = 0;
  }
  *(short *)PTR__gNumActiveStars_00034040 = *(short *)PTR__gNumActiveStars_00034040 + 1;
  return;
}


// ==== _NewStarGroup @ 000035b5 ====

void _NewStarGroup(short param_1,short param_2,short param_3)

{
  short sVar1;
  char cVar2;
  short sVar3;
  int iVar4;
  int iVar5;
  short sVar6;
  short sVar7;
  int iVar8;
  int iVar9;
  short sVar10;
  int iVar11;
  int iVar12;
  undefined4 uVar13;
  undefined4 uVar14;
  undefined4 uVar15;
  undefined4 uVar16;
  
  if (((param_3 != 0xf) && (param_3 != 0x10)) && (cVar2 = _GetBooleanPref(0x35), cVar2 == '\0')) {
    return;
  }
  switch(param_3) {
  case 0:
    _NewStar((int)(short)(param_1 + -8),(int)(short)(param_2 + -8),2,0,0,0xffffffff);
    _NewStar((int)(short)(param_1 + -0x14),(int)(short)(param_2 + -3),2,2,0,0xffffffff);
    _NewStar((int)(short)(param_1 + 6),(int)(short)(param_2 + 6),2,6,0,0xffffffff);
    _NewStar((int)(short)(param_1 + 2),(int)(short)(param_2 + 0x16),2,0xc,0,0xffffffff);
    _NewStar((int)(short)(param_1 + 0x1c),(int)(short)(param_2 + 0x10),2,2,0,0xffffffff);
    _NewStar((int)(short)(param_1 + 0x20),(int)(short)(param_2 + -8),2,9,0,0xffffffff);
    _NewStar((int)(short)(param_1 + 0x1a),(int)(short)(param_2 + 0x1c),2,6,0,0xffffffff);
    uVar15 = 0;
    uVar14 = 0x12;
    uVar13 = 2;
    iVar8 = (int)(short)(param_2 + 9);
    param_1 = param_1 + 9;
    goto LAB_00003e8c;
  case 1:
    _NewStar((int)(short)(param_1 + -8),(int)(short)(param_2 + -8),2,0,0,0xffffffff);
    uVar15 = 0;
    uVar14 = 3;
    uVar13 = 2;
    iVar8 = (int)(short)(param_2 + 6);
    param_1 = param_1 + 6;
    goto LAB_00003e8c;
  case 2:
    iVar8 = (int)(short)(param_2 + 6);
    iVar12 = (int)(short)(param_1 + 6);
    _NewStar(iVar12,iVar8,2,0,3,0xffffffff);
    _NewStar(iVar12,iVar8,2,0,4,0xffffffff);
    _NewStar(iVar12,iVar8,2,0,5,0xffffffff);
    _NewStar(iVar12,iVar8,2,0,6,0xffffffff);
    _NewStar(iVar12,iVar8,2,0,7,0xffffffff);
    _NewStar(iVar12,iVar8,2,0,8,0xffffffff);
    _NewStar(iVar12,iVar8,2,0,9,0xffffffff);
    uVar16 = 0xffffffff;
    uVar15 = 10;
    goto LAB_0000450b;
  case 3:
    _NewStar((int)(short)(param_1 + -8),(int)(short)(param_2 + -8),4,0,0xb,0xffffffff);
    iVar12 = (int)(short)(param_1 + 6);
    _NewStar(iVar12,(int)(short)(param_2 + 6),4,3,0xb,0xffffffff);
    iVar8 = (int)(short)(param_2 + 0x14);
    _NewStar((int)(short)(param_1 + -0x10),iVar8,4,0,0xb,0xffffffff);
    uVar15 = 0xb;
    uVar14 = 3;
    uVar13 = 4;
    break;
  case 4:
    _NewStar((int)(short)(param_1 + -8),(int)(short)(param_2 + -8),5,0,0xb,0xffffffff);
    iVar12 = (int)(short)(param_1 + 6);
    _NewStar(iVar12,(int)(short)(param_2 + 6),5,3,0xb,0xffffffff);
    iVar8 = (int)(short)(param_2 + 0x14);
    _NewStar((int)(short)(param_1 + -0x10),iVar8,5,0,0xb,0xffffffff);
    uVar15 = 0xb;
    uVar14 = 3;
    uVar13 = 5;
    break;
  case 5:
    _NewStar((int)(short)(param_1 + -8),(int)(short)(param_2 + -8),6,0,0xb,0xffffffff);
    iVar12 = (int)(short)(param_1 + 6);
    _NewStar(iVar12,(int)(short)(param_2 + 6),6,3,0xb,0xffffffff);
    iVar8 = (int)(short)(param_2 + 0x14);
    _NewStar((int)(short)(param_1 + -0x10),iVar8,6,0,0xb,0xffffffff);
    uVar15 = 0xb;
    uVar14 = 3;
    uVar13 = 6;
    break;
  case 6:
    sVar1 = *(short *)(PTR__hero_0003f014 + 0x16);
    sVar7 = *(short *)(PTR__hero_0003f014 + 0x14);
    sVar10 = *(short *)(PTR__gStarsLocationLookup_00034030 +
                       *(short *)PTR__gStarsLocationIndex_00034038 * 2);
    sVar6 = *(short *)PTR__gStarsLocationIndex_00034038 + 1;
    sVar3 = 0;
    if (sVar6 != 0x15) {
      sVar3 = sVar6;
    }
    *(short *)PTR__gStarsLocationIndex_00034038 = sVar3;
    sVar7 = sVar7 + 0x1a;
    goto LAB_00004333;
  case 7:
    sVar1 = *(short *)(PTR__hero_0003f014 + 0x16);
    sVar7 = *(short *)(PTR__hero_0003f014 + 0x14);
    sVar10 = *(short *)(PTR__gStarsLocationLookup_00034030 +
                       *(short *)PTR__gStarsLocationIndex_00034038 * 2);
    sVar6 = *(short *)PTR__gStarsLocationIndex_00034038 + 1;
    sVar3 = 0;
    if (sVar6 != 0x15) {
      sVar3 = sVar6;
    }
    *(short *)PTR__gStarsLocationIndex_00034038 = sVar3;
    sVar7 = sVar7 + -0xd;
LAB_00004333:
    iVar8 = (int)sVar7;
    sVar10 = sVar1 + 6 + sVar10;
    goto LAB_00004403;
  case 8:
    sVar10 = *(short *)(PTR__hero_0003f014 + 0x16);
    sVar7 = *(short *)(PTR__hero_0003f014 + 0x14);
    sVar1 = *(short *)(PTR__gStarsLocationLookup_00034030 +
                      *(short *)PTR__gStarsLocationIndex_00034038 * 2);
    sVar6 = *(short *)PTR__gStarsLocationIndex_00034038 + 1;
    sVar3 = 0;
    if (sVar6 != 0x15) {
      sVar3 = sVar6;
    }
    *(short *)PTR__gStarsLocationIndex_00034038 = sVar3;
    iVar8 = (int)(short)(sVar7 + 6 + sVar1);
    sVar10 = sVar10 + 0x1e;
    goto LAB_00004403;
  case 9:
    sVar10 = *(short *)(PTR__hero_0003f014 + 0x16);
    sVar7 = *(short *)(PTR__hero_0003f014 + 0x14);
    sVar1 = *(short *)(PTR__gStarsLocationLookup_00034030 +
                      *(short *)PTR__gStarsLocationIndex_00034038 * 2);
    sVar6 = *(short *)PTR__gStarsLocationIndex_00034038 + 1;
    sVar3 = 0;
    if (sVar6 != 0x15) {
      sVar3 = sVar6;
    }
    *(short *)PTR__gStarsLocationIndex_00034038 = sVar3;
    iVar8 = (int)(short)(sVar7 + 6 + sVar1);
    sVar10 = sVar10 + -0x11;
LAB_00004403:
    uVar15 = 0;
    uVar14 = 0;
    uVar13 = 2;
    iVar12 = (int)sVar10;
    break;
  case 10:
    iVar8 = (int)(short)(param_2 + 6);
    iVar12 = (int)(short)(param_1 + 6);
    _NewStar(iVar12,iVar8,2,0,2,0);
    _NewStar(iVar12,iVar8,2,0,2,10);
    _NewStar(iVar12,iVar8,2,0,2,0x14);
    _NewStar(iVar12,iVar8,2,0,2,0x1e);
    _NewStar(iVar12,iVar8,2,0,2,0x28);
    uVar16 = 0x32;
    uVar15 = 2;
LAB_0000450b:
    uVar14 = 0;
    uVar13 = 2;
    goto LAB_00004af8;
  case 0xb:
    _NewStar((int)(short)(param_1 + -8),(int)(short)(param_2 + -8),4,0,0xb,0xffffffff);
    _NewStar((int)(short)(param_1 + 6),(int)(short)(param_2 + 6),4,3,0xb,0xffffffff);
    _NewStar((int)(short)(param_1 + -0x10),(int)(short)(param_2 + 0x14),4,0,0xb,0xffffffff);
    _NewStar((int)(short)(param_1 + 6),(int)(short)(param_2 + 0x14),4,3,0xb,0xffffffff);
    uVar13 = 4;
    goto LAB_00003812;
  case 0xc:
    _NewStar((int)(short)(param_1 + -8),(int)(short)(param_2 + -8),5,0,0xb,0xffffffff);
    _NewStar((int)(short)(param_1 + 6),(int)(short)(param_2 + 6),5,3,0xb,0xffffffff);
    _NewStar((int)(short)(param_1 + -0x10),(int)(short)(param_2 + 0x14),5,0,0xb,0xffffffff);
    _NewStar((int)(short)(param_1 + 6),(int)(short)(param_2 + 0x14),5,3,0xb,0xffffffff);
    uVar13 = 5;
    goto LAB_00003812;
  case 0xd:
    _NewStar((int)(short)(param_1 + -8),(int)(short)(param_2 + -8),6,0,0xb,0xffffffff);
    _NewStar((int)(short)(param_1 + 6),(int)(short)(param_2 + 6),6,3,0xb,0xffffffff);
    _NewStar((int)(short)(param_1 + -0x10),(int)(short)(param_2 + 0x14),6,0,0xb,0xffffffff);
    _NewStar((int)(short)(param_1 + 6),(int)(short)(param_2 + 0x14),6,3,0xb,0xffffffff);
    uVar13 = 6;
LAB_00003812:
    uVar15 = 0xb;
    uVar14 = 4;
    iVar8 = (int)(short)(param_2 + 0xe);
    param_1 = param_1 + 2;
LAB_00003e8c:
    uVar16 = 0xffffffff;
    iVar12 = (int)param_1;
    goto LAB_00004af8;
  case 0xe:
    _NewStar((int)(short)(param_1 + -8),(int)(short)(param_2 + -8),2,0,0xb,0xffffffff);
    iVar4 = (int)(short)(param_1 + 6);
    _NewStar(iVar4,(int)(short)(param_2 + 6),2,3,0xb,0xffffffff);
    iVar5 = (int)(short)(param_2 + 0x14);
    _NewStar((int)(short)(param_1 + -0x10),iVar5,2,0,0xb,0xffffffff);
    _NewStar(iVar4,iVar5,2,3,0xb,0xffffffff);
    _NewStar((int)(short)(param_1 + 2),(int)(short)(param_2 + 0xe),2,4,0xb,0xffffffff);
    _NewStar((int)param_1,(int)param_2,2,4,0xb,0xffffffff);
    iVar8 = (int)(short)(param_2 + -2);
    iVar12 = (int)(short)(param_1 + 10);
    _NewStar(iVar12,iVar8,2,4,0xb,0xffffffff);
    _NewStar((int)(short)(param_1 + -8),(int)(short)(param_2 + -8),2,2,0xb,0xffffffff);
    _NewStar(iVar4,(int)(short)(param_2 + 6),2,5,0xb,0xffffffff);
    _NewStar((int)(short)(param_1 + -0x10),iVar5,2,6,0xb,0xffffffff);
    _NewStar(iVar4,iVar5,2,4,0xb,0xffffffff);
    _NewStar((int)(short)(param_1 + 2),(int)(short)(param_2 + 0xe),2,7,0xb,0xffffffff);
    _NewStar((int)param_1,(int)param_2,2,8,0xb,0xffffffff);
    uVar15 = 0xb;
    uVar14 = 8;
    uVar13 = 2;
    break;
  case 0xf:
    iVar8 = (int)(short)(param_2 + -0x28);
    iVar5 = (int)(short)(param_1 + -0x28);
    _NewStar(iVar5,iVar8,7,2,0,0xffffffff);
    iVar4 = (int)param_1;
    _NewStar(iVar4,iVar8,7,2,0,0xffffffff);
    iVar12 = (int)(short)(param_1 + 0x28);
    _NewStar(iVar12,iVar8,7,2,0,0xffffffff);
    iVar8 = (int)param_2;
    _NewStar(iVar5,iVar8,7,2,0,0xffffffff);
    _NewStar(iVar4,iVar8,7,0,0,0xffffffff);
    _NewStar(iVar12,iVar8,7,2,0,0xffffffff);
    iVar8 = (int)(short)(param_2 + 0x28);
    _NewStar(iVar5,iVar8,7,2,0,0xffffffff);
    _NewStar(iVar4,iVar8,7,2,0,0xffffffff);
    uVar15 = 0;
    uVar14 = 2;
    uVar13 = 7;
    break;
  case 0x10:
    iVar8 = (int)(short)(param_2 + -0x50);
    iVar11 = (int)(short)(param_1 + -0x28);
    _NewStar(iVar11,iVar8,7,7,0,0xffffffff);
    iVar4 = (int)param_1;
    _NewStar(iVar4,iVar8,7,7,0,0xffffffff);
    iVar12 = (int)(short)(param_1 + 0x28);
    _NewStar(iVar12,iVar8,7,7,0,0xffffffff);
    iVar9 = (int)(short)(param_2 + -0x28);
    iVar8 = (int)(short)(param_1 + -0x50);
    _NewStar(iVar8,iVar9,7,7,0,0xffffffff);
    _NewStar(iVar11,iVar9,7,3,0,0xffffffff);
    _NewStar(iVar4,iVar9,7,3,0,0xffffffff);
    _NewStar(iVar12,iVar9,7,3,0,0xffffffff);
    iVar5 = (int)(short)(param_1 + 0x50);
    _NewStar(iVar5,iVar9,7,7,0,0xffffffff);
    iVar9 = (int)param_2;
    _NewStar(iVar8,iVar9,7,7,0,0xffffffff);
    _NewStar(iVar11,iVar9,7,3,0,0xffffffff);
    _NewStar(iVar4,iVar9,7,0,0,0xffffffff);
    _NewStar(iVar12,iVar9,7,3,0,0xffffffff);
    _NewStar(iVar5,iVar9,7,7,0,0xffffffff);
    iVar9 = (int)(short)(param_2 + 0x28);
    _NewStar(iVar8,iVar9,7,7,0,0xffffffff);
    _NewStar(iVar11,iVar9,7,3,0,0xffffffff);
    _NewStar(iVar4,iVar9,7,3,0,0xffffffff);
    _NewStar(iVar12,iVar9,7,3,0,0xffffffff);
    _NewStar(iVar5,iVar9,7,7,0,0xffffffff);
    iVar8 = (int)(short)(param_2 + 0x50);
    _NewStar(iVar11,iVar8,7,7,0,0xffffffff);
    _NewStar(iVar4,iVar8,7,7,0,0xffffffff);
    uVar16 = 0xffffffff;
    uVar15 = 0;
    uVar14 = 7;
    uVar13 = 7;
    goto LAB_00004af8;
  default:
    goto switchD_000035fe_default;
  }
  uVar16 = 0xffffffff;
LAB_00004af8:
  _NewStar(iVar12,iVar8,uVar13,uVar14,uVar15,uVar16);
switchD_000035fe_default:
  return;
}


// ==== _ProcessStars @ 00004b05 ====

void _ProcessStars(void)

{
  short *psVar1;
  short sVar2;
  short sVar3;
  uint uVar4;
  char *pcVar5;
  int iVar6;
  undefined4 uVar7;
  undefined4 uVar8;
  
  if (*(short *)PTR__gNumActiveStars_00034040 != 0) {
    iVar6 = 0;
    pcVar5 = PTR__star_0003403c;
    do {
      if (*pcVar5 == '\0') goto LAB_00004da1;
      if (pcVar5[0x24] != '\0') {
        uVar4 = _GetFrameCounter();
        if ((int)((int)*(short *)(pcVar5 + 0x22) + (uint)*(ushort *)(pcVar5 + 2)) <
            (int)(uVar4 & 0xffff)) {
          pcVar5[0x24] = '\0';
          pcVar5[0x25] = '\x01';
        }
        goto LAB_00004da1;
      }
      switch(*(undefined2 *)(pcVar5 + 6)) {
      default:
        goto switchD_00004b68_caseD_0;
      case 2:
        sVar3 = *(short *)(PTR__gOrbit_Table_00034034 + *(short *)(pcVar5 + 0x2e) * 4);
        sVar2 = *(short *)(PTR__gOrbit_Table_00034034 + *(short *)(pcVar5 + 0x2e) * 4 + 2);
        *(short *)(pcVar5 + 10) = sVar2 + *(short *)(pcVar5 + 0x32);
        *(short *)(pcVar5 + 8) = sVar3 + *(short *)(pcVar5 + 0x30);
        *(short *)(pcVar5 + 0xe) = sVar2 + *(short *)(pcVar5 + 0x32) + 0x1a;
        *(short *)(pcVar5 + 0xc) = sVar3 + *(short *)(pcVar5 + 0x30) + 0x1a;
        sVar3 = *(short *)(pcVar5 + 0x2e);
        *(short *)(pcVar5 + 0x2e) = sVar3 + 2;
        if (0x3b < (short)(sVar3 + 2)) {
          pcVar5[0x2e] = '\x02';
          pcVar5[0x2f] = '\0';
        }
        goto switchD_00004b68_caseD_0;
      case 3:
        uVar8 = 0xfffffffc;
        goto LAB_00004bd1;
      case 4:
        uVar8 = 0xfffffffd;
        goto LAB_00004b81;
      case 5:
        uVar8 = 0;
        uVar7 = 4;
        break;
      case 6:
        uVar8 = 3;
LAB_00004b81:
        uVar7 = 3;
        break;
      case 7:
        uVar8 = 4;
LAB_00004bd1:
        uVar7 = 0;
        break;
      case 8:
        uVar8 = 3;
        goto LAB_00004bff;
      case 9:
        uVar8 = 0;
        uVar7 = 0xfffffffc;
        break;
      case 10:
        uVar8 = 0xfffffffd;
LAB_00004bff:
        uVar7 = 0xfffffffd;
        break;
      case 0xb:
        psVar1 = (short *)(pcVar5 + 0x2a);
        sVar3 = *(short *)(pcVar5 + 0x2a) + 1;
        *(short *)(pcVar5 + 0x2a) = sVar3;
        if (sVar3 < -0x12) {
          pcVar5[0x2a] = -0x12;
          pcVar5[0x2b] = -1;
        }
        else if (0x12 < sVar3) {
          pcVar5[0x2a] = '\x12';
          pcVar5[0x2b] = '\0';
        }
        _MyOffsetRect(PTR__star_0003403c + iVar6 * 0x38 + 8,(int)*(short *)(pcVar5 + 0x28),
                      (int)*psVar1);
        if (*(short *)(pcVar5 + 10) < 0) {
          if (-(int)*(short *)(pcVar5 + 0x18) < (int)*(short *)(pcVar5 + 10)) {
            *(short *)(pcVar5 + 0x28) = -*(short *)(pcVar5 + 0x28);
          }
          else {
            pcVar5[0x25] = '\0';
            pcVar5[0x26] = '\x01';
          }
        }
        if (*(short *)(pcVar5 + 8) < 0) {
          if (-(int)*(short *)(pcVar5 + 0x1a) < (int)*(short *)(pcVar5 + 8)) {
            *psVar1 = -*psVar1;
          }
          else {
            pcVar5[0x25] = '\0';
            pcVar5[0x26] = '\x01';
          }
        }
        if (0x27f < *(short *)(pcVar5 + 0xe)) {
          if (*(short *)(pcVar5 + 0x18) + 0x280 < (int)*(short *)(pcVar5 + 0xe)) {
            pcVar5[0x25] = '\0';
            pcVar5[0x26] = '\x01';
          }
          else {
            *(short *)(pcVar5 + 0x28) = -*(short *)(pcVar5 + 0x28);
          }
        }
        if (0x1b7 < *(short *)(pcVar5 + 0xc)) {
          if (*(short *)(pcVar5 + 0x1a) + 0x1b8 < (int)*(short *)(pcVar5 + 0xc)) {
            pcVar5[0x25] = '\0';
            pcVar5[0x26] = '\x01';
          }
          else {
            *psVar1 = -*psVar1;
          }
        }
        goto switchD_00004b68_caseD_0;
      }
      _MyOffsetRect(PTR__star_0003403c + iVar6 * 0x38 + 8,uVar7,uVar8);
switchD_00004b68_caseD_0:
      sVar3 = *(short *)(pcVar5 + 0x20);
      *(ushort *)(pcVar5 + 0x20) = sVar3 + 1U;
      if ((int)*(short *)(pcVar5 + 0x2c) < (int)(uint)(ushort)(sVar3 + 1U)) {
        pcVar5[0x20] = '\0';
        pcVar5[0x21] = '\0';
        sVar3 = *(short *)(pcVar5 + 0x1e);
        *(short *)(pcVar5 + 0x1e) = sVar3 + 1;
        if (5 < (short)(sVar3 + 1)) {
          pcVar5[0x26] = '\x01';
          pcVar5[0x25] = '\0';
        }
      }
      _AddRectToBgnd(PTR__star_0003403c + iVar6 * 0x38 + 0x10);
LAB_00004da1:
      iVar6 = iVar6 + 1;
      pcVar5 = pcVar5 + 0x38;
    } while (iVar6 != 0x3c);
  }
  return;
}


// ==== _InitStars @ 00004db8 ====

void _InitStars(void)

{
  undefined1 *puVar1;
  undefined *puVar2;
  
  puVar1 = PTR__star_0003403c + 0xd20;
  puVar2 = PTR__star_0003403c;
  do {
    *puVar2 = 0;
    puVar2 = puVar2 + 0x38;
  } while (puVar2 != puVar1);
  *(undefined2 *)PTR__gNumActiveStars_00034040 = 0;
  _CreateStarRandomLocLookupTable();
  return;
}


// ==== _DrawStarsToComp @ 00004de0 ====

void _DrawStarsToComp(void)

{
  short sVar1;
  bool bVar2;
  undefined *puVar3;
  undefined4 *puVar4;
  undefined4 *puVar5;
  int iVar6;
  undefined *puVar7;
  undefined4 *local_38;
  undefined4 *local_34;
  undefined4 local_24 [5];
  
  puVar3 = PTR__gNumActiveStars_00034040;
  if (*(short *)PTR__gNumActiveStars_00034040 != 0) {
    iVar6 = 0;
    puVar4 = (undefined4 *)(PTR__star_0003403c + 0x10);
    puVar7 = PTR__star_0003403c + 8;
    local_38 = puVar4;
    local_34 = puVar4;
    do {
      if (*(char *)(puVar4 + -4) != '\0') {
        sVar1 = *(short *)((int)puVar4 + -6);
        if ((((sVar1 < 0) || (0x280 < *(short *)((int)puVar4 + -2))) ||
            (*(short *)(puVar4 + -2) < 0)) || (0x1b8 < *(short *)(puVar4 + -1))) {
          bVar2 = false;
        }
        else {
          bVar2 = true;
        }
        puVar5 = local_34;
        if (*(char *)((int)puVar4 + 0x15) != '\0') {
          if (bVar2) {
            if (*(short *)(puVar4 + -3) == 7) {
              _TransSpriteToComp(0,(int)sVar1,(int)*(short *)(puVar4 + -2),
                                 (int)*(short *)(puVar4 + 3),(int)*(short *)((int)puVar4 + 0xe),1);
            }
            else {
              _SpriteToComp(0,(int)sVar1,(int)*(short *)(puVar4 + -2),(int)*(short *)(puVar4 + 3),
                            (int)*(short *)((int)puVar4 + 0xe),1);
            }
          }
          _UnionRect(local_38,puVar7,local_24);
          puVar5 = local_24;
        }
        _AddRectToScreen(puVar5);
        if (*(char *)((int)puVar4 + 0x16) == '\0') {
          *puVar4 = puVar4[-2];
          puVar4[1] = puVar4[-1];
        }
        else {
          *(undefined1 *)(puVar4 + -4) = 0;
          *(short *)puVar3 = *(short *)puVar3 + -1;
        }
      }
      iVar6 = iVar6 + 1;
      puVar7 = puVar7 + 0x38;
      local_38 = local_38 + 0xe;
      local_34 = local_34 + 0xe;
      puVar4 = puVar4 + 0xe;
    } while (iVar6 != 0x3c);
  }
  return;
}


// ==== _Utils_ConstructPath @ 00004f2e ====

void _Utils_ConstructPath(char *param_1,char *param_2,char *param_3,char param_4)

{
  char *pcVar1;
  char *pcVar2;
  char *pcVar3;
  
  if (param_4 == '\0') {
    if (param_2 == (char *)0x0) {
      _sprintf(param_3,"%s%s",param_1,":");
      return;
    }
    pcVar3 = ":";
    pcVar2 = param_1;
  }
  else {
    if (param_2 != (char *)0x0) {
      param_2 = ":";
      pcVar2 = ":";
      pcVar1 = "%s%s%s%s";
      goto LAB_00004fb9;
    }
    param_2 = ":";
    pcVar2 = ":";
    pcVar3 = param_1;
  }
  pcVar1 = "%s%s%s";
  param_1 = pcVar3;
LAB_00004fb9:
  _sprintf(param_3,pcVar1,pcVar2,param_1,param_2);
  return;
}


// ==== _Utils_Log @ 00004fc4 ====

void _Utils_Log(void)

{
  return;
}


// ==== _Mac_IsRunningOSXOrLater @ 00004fca ====

undefined4 _Mac_IsRunningOSXOrLater(void)

{
  short sVar1;
  undefined4 uVar2;
  int local_10 [3];
  
  sVar1 = _Gestalt(0x73797376,local_10);
  if ((sVar1 == 0) && (0x9ff < local_10[0])) {
    uVar2 = 1;
  }
  else {
    uVar2 = 0;
  }
  return uVar2;
}


// ==== _Mac_IsQuickTimeInstalled @ 00004ffc ====

bool _Mac_IsQuickTimeInstalled(void)

{
  short sVar1;
  undefined1 local_10 [12];
  
  sVar1 = _Gestalt(0x7174696d,local_10);
  return sVar1 == 0;
}


// ==== _Utils_String_Safe_strncpy @ 00005020 ====

char * _Utils_String_Safe_strncpy(char *param_1,char *param_2,size_t param_3)

{
  if (((param_1 == (char *)0x0) || (param_2 == (char *)0x0)) || ((int)param_3 < 1)) {
    param_1 = (char *)0x0;
  }
  else {
    _strncpy(param_1,param_2,param_3);
    param_1[param_3] = '\0';
  }
  return param_1;
}


// ==== _Mac_CToPascalString @ 00005066 ====

void _Mac_CToPascalString(char *param_1)

{
  char cVar1;
  uint uVar2;
  int iVar3;
  char *pcVar4;
  int iVar5;
  
  if (param_1 != (char *)0x0) {
    uVar2 = 0xffffffff;
    pcVar4 = param_1;
    do {
      if (uVar2 == 0) break;
      uVar2 = uVar2 - 1;
      cVar1 = *pcVar4;
      pcVar4 = pcVar4 + 1;
    } while (cVar1 != '\0');
    iVar3 = ~uVar2 - 1;
    pcVar4 = param_1 + iVar3;
    for (iVar5 = 0; iVar5 < iVar3; iVar5 = iVar5 + 1) {
      *pcVar4 = pcVar4[-1];
      pcVar4 = pcVar4 + -1;
    }
    *param_1 = (char)iVar3;
  }
  return;
}


// ==== _Mac_PascalToCString @ 000050a0 ====

void _Mac_PascalToCString(byte *param_1)

{
  byte bVar1;
  int iVar2;
  
  if (param_1 != (byte *)0x0) {
    bVar1 = *param_1;
    for (iVar2 = 0; iVar2 < (int)(uint)bVar1; iVar2 = iVar2 + 1) {
      param_1[iVar2] = param_1[iVar2 + 1];
    }
    param_1[bVar1] = 0;
  }
  return;
}


// ==== _Mac_PascalStringCopy @ 000050c8 ====

void * _Mac_PascalStringCopy(void *param_1,byte *param_2)

{
  if (*param_2 + 1 != 0) {
    _memmove(param_1,param_2,*param_2 + 1);
  }
  return param_1;
}


// ==== _Mac_PascalStringCopyNum @ 000050f8 ====

void _Mac_PascalStringCopyNum(byte *param_1,undefined1 *param_2,ushort param_3)

{
  int iVar1;
  
  if ((short)(ushort)*param_1 < (short)param_3) {
    param_3 = (ushort)*param_1;
  }
  *param_2 = (char)param_3;
  for (iVar1 = 0; (short)iVar1 < (short)param_3; iVar1 = iVar1 + 1) {
    param_2[iVar1 + 1] = param_1[iVar1 + 1];
  }
  return;
}


// ==== _Mac_PascalStringConvertCR @ 0000513a ====

void _Mac_PascalStringConvertCR(byte *param_1)

{
  byte bVar1;
  int iVar2;
  
  bVar1 = *param_1;
  for (iVar2 = 1; iVar2 < (int)(uint)bVar1; iVar2 = iVar2 + 1) {
    if (param_1[iVar2] == 10) {
      param_1[iVar2] = 0xd;
    }
  }
  return;
}


// ==== _Mac_PascalStringCat @ 00005160 ====

byte * _Mac_PascalStringCat(byte *param_1,byte *param_2)

{
  byte bVar1;
  uint uVar2;
  size_t sVar3;
  
  sVar3 = (size_t)*param_2;
  bVar1 = *param_1;
  if (bVar1 != 0xff) {
    uVar2 = (uint)bVar1;
    if (0xff < sVar3 + uVar2) {
      sVar3 = 0xff - uVar2;
    }
    if (0 < (int)sVar3) {
      _memmove(param_1 + uVar2 + 1,param_2 + 1,sVar3);
      bVar1 = *param_1;
    }
    *param_1 = bVar1 + (char)sVar3;
  }
  return param_1;
}


// ==== _Mac_GetAppName @ 000051bc ====

void _Mac_GetAppName(char *param_1)

{
  int iVar1;
  undefined1 local_c6 [6];
  byte local_c0 [64];
  undefined4 local_80;
  undefined1 *local_7c;
  undefined1 *local_48;
  undefined1 local_44 [32];
  undefined1 local_24 [20];
  
  _GetCurrentProcess(local_24);
  local_80 = 0x3c;
  local_7c = local_44;
  local_48 = local_c6;
  _GetProcessInformation(local_24,&local_80);
  for (iVar1 = 0; iVar1 < (int)(uint)local_c0[0]; iVar1 = iVar1 + 1) {
    local_c0[iVar1] = local_c0[iVar1 + 1];
  }
  local_c0[local_c0[0]] = 0;
  if (param_1 != (char *)0x0) {
    _strncpy(param_1,(char *)local_c0,0x3f);
    param_1[0x3f] = '\0';
  }
  return;
}


// ==== _Utils_Log_Start @ 00005248 ====

void _Utils_Log_Start(void)

{
  return;
}


// ==== _DrawCompGWorld @ 0000524d ====

void _DrawCompGWorld(void)

{
  undefined *puVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined1 local_2c [8];
  undefined1 local_24 [20];
  
  puVar1 = PTR__gCompGWorld_0003f020;
  _GetPortBounds(*(undefined4 *)PTR__gCompGWorld_0003f020,local_24);
  _GetPortBounds(*(undefined4 *)puVar1,local_2c);
  uVar2 = _GetWindowPort(*(undefined4 *)PTR__environment_0003f028);
  uVar2 = _GetPortBitMapForCopyBits(uVar2);
  uVar3 = _GetPortBitMapForCopyBits(*(undefined4 *)puVar1);
  _CopyBits(uVar3,uVar2,local_24,local_2c,0,0);
  return;
}


// ==== _DrawBgndGWorld @ 000052d0 ====

void _DrawBgndGWorld(void)

{
  undefined *puVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined1 local_2c [8];
  undefined1 local_24 [20];
  
  puVar1 = PTR__gBgndGWorld_0003f01c;
  _GetPortBounds(*(undefined4 *)PTR__gBgndGWorld_0003f01c,local_24);
  _GetPortBounds(*(undefined4 *)puVar1,local_2c);
  uVar2 = _GetWindowPort(*(undefined4 *)PTR__environment_0003f028);
  uVar2 = _GetPortBitMapForCopyBits(uVar2);
  uVar3 = _GetPortBitMapForCopyBits(*(undefined4 *)puVar1);
  _CopyBits(uVar3,uVar2,local_24,local_2c,0,0);
  return;
}


// ==== _DrawSpriteGWorld @ 00005353 ====

void _DrawSpriteGWorld(void)

{
  undefined *puVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined1 local_2c [8];
  undefined1 local_24 [20];
  
  puVar1 = PTR__gSpriteGWorld_0003f024;
  _GetPortBounds(*(undefined4 *)PTR__gSpriteGWorld_0003f024,local_24);
  _GetPortBounds(*(undefined4 *)puVar1,local_2c);
  uVar2 = _GetWindowPort(*(undefined4 *)PTR__environment_0003f028);
  uVar2 = _GetPortBitMapForCopyBits(uVar2);
  uVar3 = _GetPortBitMapForCopyBits(*(undefined4 *)puVar1);
  _CopyBits(uVar3,uVar2,local_24,local_2c,0,0);
  return;
}


// ==== _Useless5 @ 000053d6 ====

int _Useless5(void)

{
  int iVar1;
  int iVar2;
  
  iVar1 = _RT3_GetHoursUsed();
  iVar2 = _RT3_GetDaysHad();
  return iVar1 + iVar2;
}


// ==== _Useless8 @ 000053f3 ====

int __regparm3 _Useless8(char param_1)

{
  int iVar1;
  
  if (param_1 == '\0') {
    iVar1 = 7;
  }
  else {
    iVar1 = _Useless8();
    iVar1 = iVar1 * 3;
  }
  return iVar1;
}


// ==== _CleanUp @ 00005413 ====

void _CleanUp(void)

{
  undefined *puVar1;
  
  _Utils_Log("\n\n\n*** Entered clean-up routines for game shut down. ***");
  puVar1 = PTR__environment_00034054;
  if (PTR__environment_00034054[0x26] == '\0') {
    _ExitFullScreenMode();
  }
  _Utils_Log("Menu bar shown.");
  if (*(int *)puVar1 != 0) {
    _DisposeWindow(*(int *)puVar1);
  }
  _Utils_Log("Main window disposed.");
  _RemoveCarbonTimer();
  _Utils_Log("Carbon timer removed if required.");
  _CloseKeys();
  _Utils_Log("ISp closed if required.");
  _RT3_Close();
  _ResetScreenSize();
  _Utils_Log("Screen size/depth restored if necessary.");
  _ST_Close();
  _Utils_Log("Sound tool closed.");
  _DisposeGWorlds();
  _Utils_Log("All graphics worlds disposed.");
  _CloseMusic();
  _Utils_Log("Music code closed.");
  _FlushEvents(0xffff,0);
  _Utils_Log("Outstanding events flushed. Exiting... Dr Chandra, will I dream?...\n");
  _ExitToShell();
  return;
}


// ==== _CheckValidity @ 000054f2 ====

void _CheckValidity(char param_1,char param_2,char param_3)

{
  undefined1 local_2a [8];
  short sStack_22;
  undefined4 local_20;
  short sStack_1e;
  
  _GetQDGlobalsScreenBits(local_2a);
  if ((((sStack_22 <= sStack_1e) && (param_1 != '\0')) && (param_2 == '\0')) && (param_3 == '\0')) {
    _ParamText("\x04-108",&DAT_00033160,&DAT_00033160,&DAT_00033160);
    _Utils_Log("Error checking screen boundaries (QuickDraw/CopyBits), exiting...");
    _StopAlert(0xd9,0);
    _CleanUp();
  }
  return;
}


// ==== _main @ 00005586 ====

undefined4 _main(void)

{
  short sVar1;
  undefined4 uVar2;
  int local_10 [2];
  
  _PlatformOpen();
  _FT_Open();
  _BTInstallEndianFlippers();
  _Gestalt(0x73797376,local_10);
  *PTR__gRunningTiger_0003404c = local_10[0] - 0x1040U < 0x10;
  _LoadMenuBar();
  _SetOrigMenuBarHeight();
  _Utils_Log("Loaded menu bar.");
  uVar2 = _NewAEEventHandlerUPP(_openApplicationAEHandler);
  sVar1 = _AEInstallEventHandler(0x61657674,0x6f617070,uVar2,0,0);
  if (sVar1 == 0) {
    _RunApplicationEventLoop();
    _SaveGamePrefs();
    _CleanUp();
  }
  _PlatformClose();
  _FT_Close();
  _DisposeAEEventHandlerUPP(uVar2);
  return 0;
}


// ==== _InitMac @ 0000563c ====

void _InitMac(void)

{
  undefined1 uVar1;
  undefined1 uVar2;
  char cVar3;
  undefined1 uVar4;
  undefined2 uVar5;
  short sVar6;
  ushort uVar7;
  undefined4 uVar8;
  undefined4 uVar9;
  undefined4 uVar10;
  undefined4 uVar11;
  undefined4 uVar12;
  int iVar13;
  uint uVar14;
  byte bVar15;
  byte bVar16;
  int iVar17;
  int iVar18;
  undefined8 uVar19;
  char *pcVar20;
  int local_4d4;
  int local_4d0;
  undefined2 local_4c4;
  undefined1 local_4c2 [510];
  undefined1 local_2c4 [256];
  undefined4 local_1c4;
  undefined4 local_1c0;
  undefined4 local_1bc;
  undefined4 local_1b8;
  undefined1 local_1b4;
  uint auStack_cc [2];
  undefined4 local_c4;
  uint local_c0 [40];
  short local_1e [7];
  
  _Utils_Log_Start("BT Data",0);
  _Utils_Log("Version:  1.0.2,  %s,  %s\n\n","Aug 25 2008","13:13:13");
  _MoreMasterPointers(0x140);
  _Utils_Log("Master pointers allocated.");
  uVar5 = _CurResFile();
  *(undefined2 *)PTR__gTopRef_00034050 = uVar5;
  *(undefined4 *)PTR__environment_00034054 = 0;
  _WatchCursor();
  _Utils_Log("Done watch cursor.");
  _LoadHandCursor();
  _Utils_Log("Loaded hand cursor.");
  _AppleEventsInit();
  _Utils_Log("Initialised Apple Events.");
  _InitPrefs();
  _Utils_Log("Inited main prefs.");
  _AlexPrefsInit();
  _LoadDefaultHiScores();
  _Utils_Log("Inited specific prefs and high scores.");
  _LoadGamePrefs();
  _Utils_Log("Loaded game prefs.");
  _InitPrefsDialog();
  _Utils_Log("Inited prefs dialog.");
  _Utils_Log("Displayed copyright message for pre-release if necessary.");
  _DoBirthdaysCheck();
  _Utils_Log("Done Alex birthday check.");
  _InitEncryption();
  _Utils_Log("Done David birthday check.");
  uVar19 = _RT3_GetLicenseCode();
  local_4d0 = _RT3_GetLicenseCopies();
  uVar8 = _RT3_GetLicenseName();
  sVar6 = 0;
  iVar18 = 1;
  do {
    _GetIndString(local_2c4,0x81,iVar18);
    uVar9 = _CFStringCreateWithPascalString(*(undefined4 *)PTR_0003f02c,local_2c4,0x600);
    uVar10 = _CFBundleGetMainBundle();
    uVar10 = _CFBundleCopyResourceURL(uVar10,uVar9,&cf_rsrc,0);
    _CFURLGetFSRef(uVar10,&local_c4);
    if (sVar6 != 0) {
      _Utils_Log("* FSMakeFSSpec error for opening resource file, exiting...");
      _NumToString((int)sVar6,&local_1c4);
      _ParamText(&local_1c4,&DAT_00033160,&DAT_00033160,&DAT_00033160);
      _StopAlert(0xd7,0);
      _CleanUp();
    }
    sVar6 = _FSOpenResourceFile(&local_c4,0,0,1,local_1e);
    if ((sVar6 != 0) || (local_1e[0] < 1)) {
      _FSGetResourceForkName(&local_4c4);
      _FSOpenFork(&local_c4,local_4c4,local_4c2,1,local_1e);
      if ((sVar6 != 0) || (local_1e[0] < 1)) {
        _Utils_Log("* FSOpenResourceFile error for opening resource file, exiting...");
        _DeathAlert(0xf);
      }
    }
    if ((short)iVar18 == 3) {
      *(short *)PTR__gSavedRef_00034048 = local_1e[0];
    }
    *(short *)PTR__gTopRef_00034050 = local_1e[0];
    _Utils_Log("Opened resource file.");
    _CFRelease(uVar9);
    _CFRelease(uVar10);
    iVar18 = iVar18 + 1;
  } while (iVar18 != 5);
  _Utils_Log("All required resource files opened.");
  iVar18 = _RT3_IsRegistered();
  if (iVar18 != 0) {
    sVar6 = _FSFindFolder(0xffff8005,0x61737570,0,&local_1c4);
    if (sVar6 == 0) {
      uVar9 = *(undefined4 *)PTR_0003f02c;
      uVar10 = _CFURLCreateFromFSRef(uVar9,&local_1c4);
      uVar9 = _CFURLCreateCopyAppendingPathComponent(uVar9,uVar10,&cf_BubbleTroubleX,1);
      iVar18 = 1;
      do {
        _GetIndString(local_2c4,0x88,iVar18);
        uVar12 = *(undefined4 *)PTR_0003f02c;
        uVar11 = _CFStringCreateWithPascalString(uVar12,local_2c4,0x600);
        uVar12 = _CFURLCreateCopyAppendingPathComponent(uVar12,uVar9,uVar11,0);
        cVar3 = _CFURLGetFSRef(uVar12,&local_c4);
        if (cVar3 == '\0') {
LAB_00005b40:
          _CFRelease(uVar11);
          _CFRelease(uVar12);
          pcVar20 = "Opened custom resource file.";
        }
        else {
          sVar6 = _FSOpenResourceFile(&local_c4,0,0,1,local_1e);
          if ((sVar6 == 0) && (0 < local_1e[0])) {
LAB_00005af5:
            if ((short)iVar18 == 1) {
              iVar17 = 1;
              do {
                iVar13 = _Get1Resource(0x4c45564c,iVar17);
                if ((iVar13 != 0) || (iVar13 = _Get1Resource(0x4d415a45,1), iVar13 != 0)) {
                  _ReleaseResource(iVar13);
                  _gUsingCustomLevels = 1;
                  break;
                }
                iVar17 = iVar17 + 1;
              } while (iVar17 != 0x33);
            }
            *(short *)PTR__gTopRef_00034050 = local_1e[0];
            goto LAB_00005b40;
          }
          _FSGetResourceForkName(&local_4c4);
          _FSOpenResourceFile(&local_c4,local_4c4,local_4c2,1,local_1e);
          if (0 < local_1e[0]) goto LAB_00005af5;
          pcVar20 = "* FSOpenFork error for opening custom resource file; not using file.";
        }
        _Utils_Log(pcVar20);
        iVar18 = iVar18 + 1;
      } while (iVar18 != 4);
      _CFRelease(uVar10);
      _CFRelease(uVar9);
      pcVar20 = "All optional resource files opened.";
    }
    else {
      pcVar20 = "No Application Support folder found.";
    }
    _Utils_Log(pcVar20);
  }
  _ResetOptionsMenu();
  _PreloadBackgrounds();
  _Utils_Log("Preloaded JPEG backgrounds.");
  local_c4._0_1_ = 0x49;
  local_c4._1_1_ = 0x71;
  local_c4._2_1_ = 0xad;
  local_1c4 = DAT_00033220;
  local_1c0 = DAT_00033224;
  local_1bc = DAT_00033228;
  local_1b8 = DAT_0003322c;
  local_1b4 = DAT_00033230;
  local_4d4 = _RT3_GetLicenseCopies();
  uVar9 = _RT3_GetLicenseName();
  pcVar20 = (char *)_RT3_CheckLicenseName(uVar9);
  if (pcVar20 != (char *)0x0) {
    if (('/' < *pcVar20) && (*pcVar20 < ':')) {
      local_4d4 = 1;
    }
    while ((iVar18 = _StringGetLength(&local_1c4), iVar18 + 1U < 0x11 && (*pcVar20 != '\0'))) {
      _StringAppendSafe(&local_1c4,pcVar20,0x11);
    }
  }
  bVar15 = ((byte)local_4d4 ^ 0x4b ^ local_1c0._3_1_) + 0xa6 ^ 0x72;
  bVar15 = bVar15 << 1 | (char)bVar15 < '\0';
  if (bVar15 < 0x42) {
    bVar15 = bVar15 ^ (byte)local_4d4;
  }
  bVar15 = bVar15 - 0x2e ^ local_1c4._2_1_;
  bVar15 = (bVar15 << 5 | bVar15 >> 3) + 0x92;
  bVar15 = (bVar15 * ' ' | bVar15 >> 3) ^ (byte)local_1c4;
  uVar7 = _RT3_ExtractLicenseBlock1(0x12345678,0x12345678);
  bVar15 = (bVar15 ^ 0x6c) + 0x7e;
  bVar15 = ((bVar15 * '@' | bVar15 >> 2) ^ 0x62 ^ local_1c0._1_1_ ^ (byte)local_4d4) + 0x98;
  bVar15 = ((bVar15 * '\x10' | bVar15 >> 4) ^ 0x54 ^ (byte)local_4d4 ^ local_1b8._1_1_) + 0x77;
  _Useless5();
  bVar16 = bVar15 * -0x80 | bVar15 >> 1;
  bVar15 = bVar16 - 0x33;
  if ((int)local_1bc._2_1_ < (int)(uint)bVar15) {
    bVar15 = bVar16 + 0x2d;
  }
  bVar15 = (bVar15 << 7 | (byte)(bVar15 + 0x66) >> 1) ^ local_1b8._3_1_ ^ (byte)local_4d4;
  bVar15 = ((bVar15 << 7 | bVar15 >> 1) ^ (byte)local_4d4) + 0xaa;
  bVar15 = (bVar15 * '\b' | bVar15 >> 5) ^ (byte)local_1bc;
  if ((int)local_1b8._2_1_ < (int)(uint)bVar15) {
    bVar15 = bVar15 + 0x76;
  }
  bVar15 = bVar15 + 0x20;
  if (0x20 < bVar15) {
    bVar15 = bVar15 ^ local_1c0._1_1_;
  }
  bVar15 = bVar15 + 0xa7 ^ local_1bc._3_1_;
  bVar15 = (bVar15 << 7 | bVar15 >> 1) + 0xbe;
  bVar15 = (bVar15 * '\b' | bVar15 >> 5) ^ 0x62 ^ (byte)local_4d4;
  cVar3 = ((bVar15 << 4 | bVar15 >> 4) ^ (byte)local_4d4) - 0x30;
  bVar15 = ((cVar3 * '\x02' | cVar3 < '\0') ^ 0x58U) + 0x55 ^ (byte)local_4d4 ^ (byte)local_1b8;
  bVar15 = (bVar15 << 7 | (bVar15 ^ 0x20) >> 1) + 0x9a;
  _TimerGetSeconds();
  _TimerGetSeconds();
  _TimerGetSeconds();
  _Useless8();
  bVar16 = ((bVar15 * '\b' | bVar15 >> 5) + 0x31 ^ (byte)local_4d4 ^ 0x6c) + 0x95 ^ 0x2d;
  bVar15 = bVar16 + 0x5e;
  if (0x4f < bVar16) {
    bVar15 = bVar16;
  }
  bVar16 = bVar15 << 6 | bVar15 >> 2;
  if (bVar16 < 0x6c) {
    _TimerGetSeconds();
  }
  bVar16 = ((bVar15 >> 2) << 6 | bVar16 >> 2) + 0x1d ^ local_1c0._1_1_;
  bVar15 = bVar16 >> 2;
  cVar3 = _IsPlatformOpen();
  bVar15 = cVar3 * (bVar15 << 6 | (byte)(bVar16 << 6 | bVar15) >> 2);
  bVar15 = ((bVar15 * '\x10' | bVar15 >> 4) - 0x3f ^ 0x75 ^ (byte)local_4d4) + 0x31;
  bVar15 = (bVar15 * '\b' | bVar15 >> 5) - 0x29;
  bVar15 = (bVar15 * '\x10' | bVar15 >> 4) + 0x13;
  bVar15 = ((bVar15 * '\x10' | bVar15 >> 4) ^ (byte)local_4d4) + 0x30;
  bVar15 = (bVar15 * '\x04' | bVar15 >> 6) - 0x2f;
  if (bVar15 < 3) {
    bVar15 = *(byte *)((int)local_c0 + (bVar15 - 4));
  }
  for (; bVar15 <= uVar7; uVar7 = uVar7 - bVar15) {
  }
  if ((local_4d4 == 0) || (uVar7 != 0)) {
    _valid1 = 0;
  }
  else {
    _valid1 = 1;
  }
  bVar15 = bVar15 ^ 0x75 ^ local_1c4._3_1_ ^ (byte)local_4d4;
  local_4d4._0_1_ = (byte)local_4d4 ^ (bVar15 << 6 | bVar15 >> 2) + 0x1a;
  bVar15 = ((byte)local_4d4 << 2 | (byte)local_4d4 >> 6) + 0x13;
  if ((int)(uint)bVar15 < (int)local_1c0._2_1_) {
    bVar15 = bVar15 >> 1 | bVar15 * -0x80;
  }
  if (bVar15 != local_1b8._1_1_) {
    _IsPlatformOpen();
  }
  local_c4._0_1_ = 0x49;
  local_c4._1_1_ = 0x71;
  local_c4._2_1_ = 0xad;
  local_1c4 = DAT_00033220;
  local_1c0 = DAT_00033224;
  local_1bc = DAT_00033228;
  local_1b8 = DAT_0003322c;
  local_1b4 = DAT_00033230;
  pcVar20 = (char *)_RT3_CheckLicenseName(uVar8);
  if (pcVar20 != (char *)0x0) {
    if (('/' < *pcVar20) && (*pcVar20 < ':')) {
      local_4d0 = 1;
    }
    while ((iVar18 = _StringGetLength(&local_1c4), iVar18 + 1U < 0x11 && (*pcVar20 != '\0'))) {
      _StringAppendSafe(&local_1c4,pcVar20,0x11);
    }
  }
  bVar15 = ((byte)local_4d0 ^ 0x4b ^ local_1c0._3_1_) + 0xa6 ^ 0x72;
  bVar15 = bVar15 << 1 | (char)bVar15 < '\0';
  if (bVar15 < 0x42) {
    bVar15 = bVar15 ^ (byte)local_4d0;
  }
  bVar15 = bVar15 - 0x2e ^ local_1c4._2_1_;
  bVar15 = (bVar15 << 5 | bVar15 >> 3) + 0x92;
  bVar15 = (bVar15 * ' ' | bVar15 >> 3) ^ (byte)local_1c4;
  uVar7 = _RT3_ExtractLicenseBlock1(uVar19);
  bVar15 = (bVar15 ^ 0x6c) + 0x7e;
  bVar15 = ((bVar15 * '@' | bVar15 >> 2) ^ 0x62 ^ local_1c0._1_1_ ^ (byte)local_4d0) + 0x98;
  bVar15 = ((bVar15 * '\x10' | bVar15 >> 4) ^ 0x54 ^ (byte)local_4d0 ^ local_1b8._1_1_) + 0x77;
  _Useless5();
  bVar16 = bVar15 * -0x80 | bVar15 >> 1;
  bVar15 = bVar16 - 0x33;
  if ((int)local_1bc._2_1_ < (int)(uint)bVar15) {
    bVar15 = bVar16 + 0x2d;
  }
  bVar15 = (bVar15 << 7 | (byte)(bVar15 + 0x66) >> 1) ^ local_1b8._3_1_ ^ (byte)local_4d0;
  bVar15 = ((bVar15 << 7 | bVar15 >> 1) ^ (byte)local_4d0) + 0xaa;
  bVar15 = (bVar15 * '\b' | bVar15 >> 5) ^ (byte)local_1bc;
  if ((int)local_1b8._2_1_ < (int)(uint)bVar15) {
    bVar15 = bVar15 + 0x76;
  }
  bVar15 = bVar15 + 0x20;
  if (0x20 < bVar15) {
    bVar15 = bVar15 ^ local_1c0._1_1_;
  }
  bVar15 = bVar15 + 0xa7 ^ local_1bc._3_1_;
  bVar15 = (bVar15 << 7 | bVar15 >> 1) + 0xbe;
  bVar15 = (bVar15 * '\b' | bVar15 >> 5) ^ 0x62 ^ (byte)local_4d0;
  cVar3 = ((bVar15 << 4 | bVar15 >> 4) ^ (byte)local_4d0) - 0x30;
  bVar15 = ((cVar3 * '\x02' | cVar3 < '\0') ^ 0x58U) + 0x55 ^ (byte)local_4d0 ^ (byte)local_1b8;
  bVar15 = (bVar15 << 7 | (bVar15 ^ 0x20) >> 1) + 0x9a;
  _TimerGetSeconds();
  _TimerGetSeconds();
  _TimerGetSeconds();
  _Useless8();
  bVar16 = ((bVar15 * '\b' | bVar15 >> 5) + 0x31 ^ (byte)local_4d0 ^ 0x6c) + 0x95 ^ 0x2d;
  bVar15 = bVar16 + 0x5e;
  if (0x4f < bVar16) {
    bVar15 = bVar16;
  }
  bVar16 = bVar15 << 6 | bVar15 >> 2;
  if (bVar16 < 0x6c) {
    _TimerGetSeconds();
  }
  bVar16 = ((bVar15 >> 2) << 6 | bVar16 >> 2) + 0x1d ^ local_1c0._1_1_;
  bVar15 = bVar16 >> 2;
  cVar3 = _IsPlatformOpen();
  bVar15 = cVar3 * (bVar15 << 6 | (byte)(bVar16 << 6 | bVar15) >> 2);
  bVar15 = ((bVar15 * '\x10' | bVar15 >> 4) - 0x3f ^ 0x75 ^ (byte)local_4d0) + 0x31;
  bVar15 = (bVar15 * '\b' | bVar15 >> 5) - 0x29;
  bVar15 = (bVar15 * '\x10' | bVar15 >> 4) + 0x13;
  bVar15 = ((bVar15 * '\x10' | bVar15 >> 4) ^ (byte)local_4d0) + 0x30;
  bVar15 = (bVar15 * '\x04' | bVar15 >> 6) - 0x2f;
  if (bVar15 < 3) {
    bVar15 = *(byte *)((int)local_c0 + (bVar15 - 4));
  }
  for (; bVar15 <= uVar7; uVar7 = uVar7 - bVar15) {
  }
  if ((local_4d0 == 0) || (uVar7 != 0)) {
    _valid2 = 0;
  }
  else {
    _valid2 = 1;
  }
  bVar15 = bVar15 ^ 0x75 ^ local_1c4._3_1_ ^ (byte)local_4d0;
  local_4d0._0_1_ = (byte)local_4d0 ^ (bVar15 << 6 | bVar15 >> 2) + 0x1a;
  bVar15 = ((byte)local_4d0 << 2 | (byte)local_4d0 >> 6) + 0x13;
  if ((int)(uint)bVar15 < (int)local_1c0._2_1_) {
    bVar15 = bVar15 >> 1 | bVar15 * -0x80;
  }
  if (bVar15 != local_1b8._1_1_) {
    _IsPlatformOpen();
  }
  _OpenMusic();
  _Utils_Log("Initialised music code.");
  _Utils_Log("About to check screen boundaries for CopyBits window limits.");
  uVar2 = _valid1;
  uVar1 = _valid2;
  uVar4 = _RT3_IsRegistered();
  _CheckValidity(uVar4,uVar2,uVar1);
  _SetRect(PTR__environment_00034054 + 0x12,0,0,0x280,0x1e0);
  _Utils_Log("Confirming graphics buffering memory.");
  _memcpy(&local_c4,&_C_90_75287,0xa0);
  uVar19 = _RT3_GetLicenseCode();
  iVar18 = 1;
  do {
    if ((((uint)((ulonglong)uVar19 >> 0x20) ^ auStack_cc[iVar18 * 2 + 1]) & 0xfffffff) == 0 &&
        auStack_cc[iVar18 * 2] == (uint)uVar19) {
      _Utils_Log("Double buffering memory error, exiting...");
      _StdError("Double buffering memory error (video card not compatible?).",0xffffff94);
    }
    iVar18 = iVar18 + 1;
  } while (iVar18 != 0x15);
  _CreateGameWindow();
  _Utils_Log("Game window created.");
  _Utils_Log("\nAbout to do screen resolution/depth altering if required.");
  _PrepareMonitor();
  _Utils_Log("All monitor changing code completed.\n");
  _SetToScreen();
  _FillScreenBlack();
  _InitSpritePlottingTechnique();
  _Utils_Log("Chosen sprite plotting technique.");
  _Utils_Log("\nAbout to create all graphics worlds.");
  _CreateGWorlds();
  _Utils_Log("All graphics worlds created successfully.\n");
  _UpdateScreenInfo();
  _Utils_Log("Confirmed screen information.");
  _InitAmbrosiaSoundTool();
  _Utils_Log("Opened sound tool.");
  uVar5 = _ST_GetSysVolume();
  _ST_SetVolume(uVar5);
  _Utils_Log("Set sound tool volume.");
  if (PTR__environment_00034054[0x26] == '\0') {
    _HideMyCursor();
  }
  else {
    _WatchCursor();
  }
  _Utils_Log("Hidden cursor.");
  if ((PTR__environment_00034054[0x26] == '\0') && (cVar3 = _CanUseFades(), cVar3 != '\0')) {
    _CGAcquireDisplayFadeReservation(0x40400000,local_c0 + 0x27);
    _CGDisplayFade(local_c0[0x27],0x3dcccccd,0,0x3f800000,0,0,0,1);
    _Utils_Log("Screen faded out: full screen mode.");
  }
  _SetToScreen();
  _FillScreenBlack();
  _Utils_Log("Set to screen before comp world logo display.");
  if ((PTR__environment_00034054[0x26] != '\0') || (cVar3 = _CanUseFades(), cVar3 == '\0')) {
    _SetToCompGWorld();
  }
  _FillScreenBlack();
  _Utils_Log("Blacked comp world/screen (depending on wipes/fades).");
  _DrawAndCentrePict(200);
  if ((PTR__environment_00034054[0x26] == '\0') && (cVar3 = _CanUseFades(), cVar3 != '\0')) {
    _FlushIfNecessary();
  }
  _SetToScreen();
  iVar18 = _TickCount();
  _Utils_Log("Drawn logo.");
  _Utils_Log("Hydro-spanner brought and tool box successfully dropped.");
  if ((PTR__environment_00034054[0x26] == '\0') && (cVar3 = _CanUseFades(), cVar3 != '\0')) {
    _CGDisplayFade(local_c0[0x27],0x3f19999a,0x3f800000,0,0,0,0,1);
    pcVar20 = "Displayed logo via fade (full screen mode).";
  }
  else {
    _WipeScreenOut(4);
    pcVar20 = "Displayed logo via wipe (window mode).";
  }
  _Utils_Log(pcVar20);
  _InitCompiledSprites();
  _Utils_Log("Initialised compiled sprite code.");
  _InitKeys();
  _InitControls();
  _Utils_Log("Initialised keys and controls.");
  _LoadLetters();
  _Utils_Log("Loaded letter graphics.");
  while (uVar14 = _TickCount(), uVar14 < iVar18 + 0x82U) {
    _FlushEvents(0xffff,0);
  }
  if ((PTR__environment_00034054[0x26] == '\0') && (cVar3 = _CanUseFades(), cVar3 != '\0')) {
    _CGDisplayFade(local_c0[0x27],0x3f19999a,0,0x3f800000,0,0,0,1);
  }
  else {
    _SetToCompGWorld();
  }
  _FillScreenBlack();
  _SetToScreen();
  if ((PTR__environment_00034054[0x26] != '\0') || (cVar3 = _CanUseFades(), cVar3 == '\0')) {
    _WipeScreen(4);
  }
  _Utils_Log("Wiped off logo.");
  _Utils_Log("I can\'t believe you\'re reading all this.");
  if ((PTR__environment_00034054[0x26] != '\0') || (cVar3 = _CanUseFades(), cVar3 == '\0')) {
    _SetToCompGWorld();
  }
  _FillScreenBlack();
  _DrawAndCentrePict(0x2333);
  if ((PTR__environment_00034054[0x26] == '\0') && (cVar3 = _CanUseFades(), cVar3 != '\0')) {
    _FlushIfNecessary();
  }
  _SetToScreen();
  if ((PTR__environment_00034054[0x26] == '\0') && (cVar3 = _CanUseFades(), cVar3 != '\0')) {
    _CGDisplayFade(local_c0[0x27],0x3f19999a,0x3f800000,0,0,0,0,1);
    _CGReleaseDisplayFadeReservation(local_c0[0x27]);
  }
  else {
    _WipeScreenOut(4);
  }
  _Utils_Log("Displayed BT logo.");
  _InitProgressBar();
  _Utils_Log("Initialised progress bar.");
  iVar18 = _TickCount();
  _PlayIntroSound();
  _Utils_Log("Played intro sound.");
  _UpdateProgress();
  _Utils_Log("First progress update completed.");
  _LoadSprites(0);
  _Utils_Log("Loaded permanent sprite set completely.");
  _UpdateProgress();
  _LoadOrbitData();
  _Utils_Log("Loaded orbit data.");
  _UpdateProgress();
  _LoadSounds();
  _Utils_Log("Loaded sound effects.");
  _UpdateProgress();
  while (uVar14 = _TickCount(), uVar14 < iVar18 + 0x3cU) {
    _FlushEvents(0xffff,0);
  }
  _DisposeIntroSound();
  _UpdateSoundVol();
  _Utils_Log("Disposed intro sound and updated volume.");
  return;
}


// ==== _openApplicationAEHandler @ 000066db ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

int _openApplicationAEHandler(undefined4 param_1)

{
  undefined4 uVar1;
  char cVar2;
  short sVar3;
  int iVar4;
  int iVar5;
  int iVar6;
  code *pcVar7;
  int local_30;
  undefined1 local_24 [4];
  undefined1 local_20 [16];
  
  sVar3 = _AEGetAttributePtr(param_1,0x6d697373,0x2a2a2a2a,local_20,0,0,local_24);
  if (sVar3 == 0) {
    return -0x6b3;
  }
  if (sVar3 != -0x6a5) {
    return (int)sVar3;
  }
  if (__aswSparkle == 0) {
    __aswSparkle = 0;
    iVar4 = _CFBundleGetMainBundle();
    if ((iVar4 != 0) && (iVar4 = _CFBundleCopyPrivateFrameworksURL(iVar4), iVar4 != 0)) {
      uVar1 = *(undefined4 *)PTR_0003f030;
      iVar5 = _CFURLCreateCopyAppendingPathComponent
                        (uVar1,iVar4,&cf_ASWCarbonSparkleBridge_bundle,0);
      if (iVar5 != 0) {
        __aswSparkle = _CFBundleCreate(uVar1,iVar5);
        if ((__aswSparkle != 0) && (cVar2 = _CFBundleLoadExecutable(__aswSparkle), cVar2 == '\0')) {
          _CFRelease(__aswSparkle);
          __aswSparkle = 0;
        }
        _CFRelease(iVar5);
      }
      _CFRelease(iVar4);
    }
    if (__aswSparkle == 0) goto LAB_00006834;
  }
  __ASWSparkleInit = (code *)_CFBundleGetFunctionPointerForName(__aswSparkle,&cf__frameworkInit);
  ___ASWSparkleCheckForUpdates =
       _CFBundleGetFunctionPointerForName(__aswSparkle,&cf_checkForUpdatesAndNotify);
  ___ASWSparkleScheduleCheck =
       _CFBundleGetFunctionPointerForName(__aswSparkle,&cf_scheduleCheckWithInterval);
  if (__ASWSparkleInit != (code *)0x0) {
    (*__ASWSparkleInit)();
  }
LAB_00006834:
  sVar3 = _RT3_Open(1,0x8003,"Bubble Trouble X","Bubble Trouble X");
  if (sVar3 == 0) {
    local_30 = 0;
  }
  else {
    local_30 = (int)sVar3;
    _DebugValues("Game parsing error for graphics routines.",local_30);
    _ExitToShell();
  }
  iVar4 = _CFBundleGetMainBundle();
  if ((iVar4 != 0) && (iVar4 = _CFBundleCopyPrivateFrameworksURL(iVar4), iVar4 != 0)) {
    uVar1 = *(undefined4 *)PTR_0003f030;
    iVar5 = _CFURLCreateCopyAppendingPathComponent
                      (uVar1,iVar4,&cf_ASWRegistrationCarbonBridge_bundle,0);
    if (iVar5 == 0) {
      iVar6 = 0;
    }
    else {
      iVar6 = _CFBundleCreate(uVar1,iVar5);
      if ((iVar6 != 0) && (cVar2 = _CFBundleLoadExecutable(iVar6), cVar2 == '\0')) {
        _CFRelease(iVar6);
        iVar6 = 0;
      }
      _CFRelease(iVar5);
    }
    _CFRelease(iVar4);
    if ((iVar6 != 0) &&
       (pcVar7 = (code *)_CFBundleGetFunctionPointerForName(iVar6,&cf_InitializeRegistration),
       pcVar7 != (code *)0x0)) {
      (*pcVar7)();
    }
  }
  _InitMac();
  _Interface();
  _QuitApplicationEventLoop();
  return local_30;
}


// ==== _TimeBonus_Reset @ 00006930 ====

void _TimeBonus_Reset(void)

{
  short sVar1;
  
  sVar1 = _GetCurrLevelNum();
  if (sVar1 < 5) {
    _gTimeBonus = 0x9c4;
  }
  else if (sVar1 < 10) {
    _gTimeBonus = 3000;
  }
  else {
    _gTimeBonus = 0xdac;
    if (0xe < sVar1) {
      _gTimeBonus = 4000;
    }
  }
  _gTimeBonusHasChanged = 0;
  _gTimeBonusTimer = _GetFrameCounter();
  _gTimeBonus_FlashBonus = 0;
  _gTimeBonus_FlashTimer = _GetFrameCounter();
  _gTimeBonusRect._2_2_ = 0x1e0;
  _gTimeBonusRect._0_2_ = 0x1be;
  DAT_000349a0._2_2_ = 0x1e0;
  DAT_000349a0._0_2_ = 0x1dc;
  return;
}


// ==== _TimeBonus_RequestDraw @ 000069c1 ====

void _TimeBonus_RequestDraw(void)

{
  _gTimeBonusHasChanged = 1;
  return;
}


// ==== _TimeBonus_Increase @ 000069cd ====

void _TimeBonus_Increase(int param_1,undefined1 param_2)

{
  param_1 = _gTimeBonus + param_1;
  _gTimeBonus = 0x1866e;
  if (param_1 < 0x1866f) {
    _gTimeBonus = param_1;
  }
  _gTimeBonusHasChanged = 1;
  _gTimeBonus_FlashBonus = param_2;
  _gTimeBonus_FlashTimer = _GetFrameCounter();
  return;
}


// ==== _TimeBonus_GetBonus @ 00006a0b ====

undefined4 _TimeBonus_GetBonus(void)

{
  return _gTimeBonus;
}


// ==== _TimeBonus_Process @ 00006a15 ====

void _TimeBonus_Process(void)

{
  ushort uVar1;
  ushort uVar2;
  short sVar3;
  uint uVar4;
  
  uVar1 = _gTimeBonusTimer;
  if (*PTR__gIsEndOfLevel_0003f034 == '\0') {
    if (_gTimeBonus < 1) {
      sVar3 = _GetCurrentNotice();
      uVar1 = _gTimeBonusTimer;
      if ((sVar3 == 5) &&
         (uVar4 = _GetFrameCounter(), uVar1 = _gTimeBonusTimer,
         _gTimeBonusTimer + 0x3c < (uVar4 & 0xffff))) {
        _PrepareNotice(0);
        uVar1 = _gTimeBonusTimer;
      }
    }
    else {
      uVar2 = _GetFrameCounter();
      uVar1 = uVar2;
      if ((*(short *)(PTR__hero_0003f014 + 2) == 2) &&
         (uVar1 = _gTimeBonusTimer, _gTimeBonusTimer + 0x1e < (uint)uVar2)) {
        _gTimeBonus = _gTimeBonus + -0x32;
        _gTimeBonusHasChanged = 1;
        _gTimeBonusTimer = uVar2;
        if (_gTimeBonus == 0) {
          _PlayMySnd(0x1e,0x14,0);
          _PlayMySnd(0x17,0x14,0);
          _PrepareNotice(5);
          _Jewels_TurnToBlocks();
          uVar1 = uVar2;
        }
        else {
          uVar1 = uVar2;
          if (_gTimeBonus < 500) {
            _PlayMySnd(0x15,0x14,0);
            _gTimeBonus_FlashBonus = 1;
            _gTimeBonus_FlashTimer = _GetFrameCounter();
            uVar1 = _gTimeBonusTimer;
          }
        }
      }
    }
  }
  _gTimeBonusTimer = uVar1;
  return;
}


// ==== _TimeBonus_Draw @ 00006b3a ====

void _TimeBonus_Draw(char param_1)

{
  int iVar1;
  char cVar2;
  char cVar3;
  int iVar4;
  uint uVar5;
  short sVar6;
  undefined4 uVar7;
  undefined4 local_32;
  undefined4 local_2e;
  undefined4 local_2a;
  undefined4 local_26;
  char acStack_21 [17];
  
  if ((param_1 != '\0') || (_gTimeBonusHasChanged != '\0')) {
    _SetRect(&local_2a,0x1e0,6,(int)DAT_000349a0._2_2_,0x24);
    _SetRect(&local_32,0x1e0,0x1be,(int)DAT_000349a0._2_2_,0x1dc);
    _SetToCompGWorld();
    _ScoreToComp(local_2a,local_26,local_32,local_2e);
    iVar4 = 0;
    do {
      acStack_21[iVar4] = '\0';
      iVar4 = iVar4 + 1;
    } while (iVar4 != 5);
    cVar3 = '\0';
    iVar4 = _gTimeBonus;
    do {
      iVar1 = iVar4 / 10;
      acStack_21[cVar3] = (char)iVar4 + (char)iVar1 * -10;
      cVar2 = cVar3 + '\x01';
      if ('\x05' < (char)(cVar3 + '\x01')) {
        cVar2 = cVar3;
      }
      cVar3 = cVar2;
      iVar4 = iVar1;
    } while (0 < iVar1);
    _gTimeBonusRect = 0x1e001be;
    DAT_000349a0 = 0x1e001dc;
    iVar4 = 0;
    do {
      cVar3 = acStack_21[iVar4 + 4];
      if ((((char)iVar4 != '\0') || (cVar3 != '\0')) && (cVar3 != -1)) {
        sVar6 = (short)((uint)DAT_000349a0 >> 0x10);
        if (_gTimeBonus < 10000) {
          sVar6 = sVar6 + 0x16;
        }
        if (_gTimeBonus_FlashBonus == '\0') {
          uVar7 = 0x21;
        }
        else {
          uVar7 = 0x22;
        }
        _SpriteToComp(0,(int)sVar6,0x1be,uVar7,(int)(short)(cVar3 + 1),0);
        DAT_000349a0._2_2_ = DAT_000349a0._2_2_ + 0x17;
      }
      iVar4 = iVar4 + -1;
    } while (iVar4 != -5);
    if (_gTimeBonus < 10000) {
      DAT_000349a0._2_2_ = DAT_000349a0._2_2_ + 0x16;
    }
    local_32 = _gTimeBonusRect;
    local_2e = DAT_000349a0;
    if (PTR__environment_0003f028[8] != '\0') {
      _OffsetRect(&local_32,(int)*(short *)(PTR__environment_0003f028 + 0x1a),
                  (int)*(short *)(PTR__environment_0003f028 + 0x1c));
    }
    cVar3 = _UsingQDPlotting();
    if (cVar3 == '\0') {
      _CustomCompToScreen(_gTimeBonusRect,DAT_000349a0,local_32,local_2e);
    }
    else {
      _CompToScreen(_gTimeBonusRect,DAT_000349a0,local_32,local_2e);
    }
    _SetToScreen();
    _gTimeBonusHasChanged = '\0';
    if (_gTimeBonus_FlashBonus != '\0') {
      uVar5 = _GetFrameCounter();
      cVar3 = '\0';
      if ((uVar5 & 0xffff) <= _gTimeBonus_FlashTimer + 4) {
        cVar3 = _gTimeBonus_FlashBonus;
      }
      _gTimeBonusHasChanged = '\x01';
      _gTimeBonus_FlashBonus = cVar3;
    }
  }
  return;
}


// ==== _TimeBonus_CountDown @ 00006dcb ====

void _TimeBonus_CountDown(void)

{
  int iVar1;
  short sVar2;
  undefined4 uVar3;
  
  iVar1 = _Multiplier_Get();
  if (1 < iVar1) {
    _Multiplier_Flash();
    iVar1 = iVar1 * _gTimeBonus;
    _gTimeBonus = 0x1866e;
    if (iVar1 < 0x1866f) {
      _gTimeBonus = iVar1;
    }
    _PlayMySnd(9,0x1e,0);
    _gTimeBonus_FlashBonus = 1;
    _gTimeBonus_FlashTimer = _GetFrameCounter();
    _TimeBonus_Draw(1);
    _FlushIfNecessary();
    _WaitFor(0x3c);
  }
  if (_gTimeBonus == 0) {
    uVar3 = 0x2a;
  }
  else {
    if (_gTimeBonus < 0x2711) goto LAB_00006e97;
    uVar3 = 0x29;
  }
  _PlayMySnd(uVar3,0x1e,0);
LAB_00006e97:
  sVar2 = 0;
  while (0 < _gTimeBonus) {
    if (_gTimeBonus < 50000) {
      if (_gTimeBonus < 10000) {
        iVar1 = 100;
        if (_gTimeBonus < 5000) {
          iVar1 = 0x32;
        }
      }
      else {
        iVar1 = 200;
      }
    }
    else {
      iVar1 = 500;
    }
    _gTimeBonus = _gTimeBonus - iVar1;
    _AddToScore(iVar1,0);
    sVar2 = sVar2 + 1;
    if (2 < sVar2) {
      _PlayMySnd(0x11,0x1e,0);
      sVar2 = 0;
    }
    _TimeBonus_Draw(1);
    _DrawScore(1);
    _FlushIfNecessary();
    _WaitFor(1);
    _AdvanceFrameCounter();
    _DrawReserveInfo();
    _WaitFor(1);
    _DrawReserveInfo();
    _WaitFor(1);
    _DrawReserveInfo();
  }
  _WaitFor(0xf);
  return;
}


// ==== _InitProgressBar @ 00006f83 ====

void _InitProgressBar(void)

{
  short sVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined4 uVar4;
  undefined2 local_22;
  undefined2 local_20;
  undefined2 local_1e;
  
  local_22 = 0;
  local_20 = 0;
  local_1e = 0;
  *(undefined2 *)PTR__gPCurSteps_00034070 = 0;
  _SetToScreen();
  puVar3 = PTR__environment_0003f028;
  puVar2 = PTR__gPRect_00034074;
  sVar1 = *(short *)(PTR__environment_0003f028 + 0xc);
  *(short *)(PTR__gPRect_00034074 + 2) = sVar1 + 0xfa;
  *(short *)(puVar2 + 6) = sVar1 + 0x186;
  sVar1 = *(short *)(puVar3 + 10);
  *(short *)puVar2 = sVar1 + 0x1bd;
  *(short *)(puVar2 + 4) = sVar1 + 0x1c3;
  _RGBForeColor(&_gPBorderCol1);
  _MoveTo((int)(short)(*(short *)(puVar2 + 2) + -2),(int)(short)(*(short *)puVar2 + -2));
  _LineTo((int)(short)(*(short *)(puVar2 + 6) + 1),(int)(short)(*(short *)puVar2 + -2));
  _LineTo((int)(short)(*(short *)(puVar2 + 6) + 1),(int)(short)(*(short *)(puVar2 + 4) + 1));
  _LineTo((int)(short)(*(short *)(puVar2 + 2) + -2),(int)(short)(*(short *)(puVar2 + 4) + 1));
  _LineTo((int)(short)(*(short *)(puVar2 + 2) + -2),(int)(short)(*(short *)puVar2 + -2));
  _SetCPixel((int)(short)(*(short *)(puVar2 + 6) + 1),(int)(short)(*(short *)puVar2 + -2),&local_22)
  ;
  _SetCPixel((int)(short)(*(short *)(puVar2 + 6) + 1),(int)(short)(*(short *)(puVar2 + 4) + 1),
             &local_22);
  _SetCPixel((int)(short)(*(short *)(puVar2 + 2) + -2),(int)(short)(*(short *)(puVar2 + 4) + 1),
             &local_22);
  _SetCPixel((int)(short)(*(short *)(puVar2 + 2) + -2),(int)(short)(*(short *)puVar2 + -2),&local_22
            );
  _RGBForeColor(&_gPBorderCol2);
  _MoveTo((int)(short)(*(short *)(puVar2 + 2) + -1),(int)(short)(*(short *)puVar2 + -1));
  _LineTo((int)*(short *)(puVar2 + 6),(int)(short)(*(short *)puVar2 + -1));
  _LineTo((int)*(short *)(puVar2 + 6),(int)*(short *)(puVar2 + 4));
  _LineTo((int)(short)(*(short *)(puVar2 + 2) + -1),(int)*(short *)(puVar2 + 4));
  _LineTo((int)(short)(*(short *)(puVar2 + 2) + -1),(int)(short)(*(short *)puVar2 + -1));
  _RGBForeColor(&_gPInside1);
  uVar4 = _NewPtr(8);
  uVar4 = _GetQDGlobalsBlack(uVar4);
  _FillRect(puVar2,uVar4);
  _DisposePtr(uVar4);
  _RGBForeColor(&local_22);
  return;
}


// ==== _UpdateProgress @ 000071c5 ====

void _UpdateProgress(void)

{
  short sVar1;
  undefined4 uVar2;
  undefined4 local_1a;
  undefined2 local_16;
  short sStack_14;
  undefined2 local_12;
  undefined2 local_10;
  undefined2 local_e;
  
  local_12 = 0;
  local_10 = 0;
  local_e = 0;
  sVar1 = *(short *)PTR__gPCurSteps_00034070;
  *(short *)PTR__gPCurSteps_00034070 = sVar1 + 1;
  local_1a._2_2_ = (short)((uint)*(undefined4 *)PTR__gPRect_00034074 >> 0x10);
  sStack_14 = (short)((uint)*(undefined4 *)(PTR__gPRect_00034074 + 4) >> 0x10);
  local_1a._2_2_ =
       local_1a._2_2_ +
       (short)(int)((float)((int)sStack_14 - (int)local_1a._2_2_) *
                   ((float)(int)(short)(sVar1 + 1) / FLOAT_00033fb0));
  sVar1 = *(short *)(PTR__gPRect_00034074 + 6);
  if (local_1a._2_2_ <= *(short *)(PTR__gPRect_00034074 + 6)) {
    sVar1 = local_1a._2_2_;
  }
  _local_16 = CONCAT22(sVar1,(short)*(undefined4 *)(PTR__gPRect_00034074 + 4));
  local_1a = *(undefined4 *)PTR__gPRect_00034074;
  uVar2 = _NewPtr(8);
  uVar2 = _GetQDGlobalsBlack(uVar2);
  _RGBForeColor(&_gPInside2);
  _FillRect(&local_1a,uVar2);
  _DisposePtr(uVar2);
  _RGBForeColor(&local_12);
  _FlushIfNecessary();
  return;
}


// ==== _ASWReg_ShowDialogWithOptions @ 0000728c ====

uint __regparm3 _ASWReg_ShowDialogWithOptions(char param_1,char param_2)

{
  undefined4 uVar1;
  char cVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  code *pcVar6;
  uint uVar7;
  cfstringStruct *pcVar8;
  
  iVar3 = _CFBundleGetMainBundle();
  if ((iVar3 != 0) && (iVar3 = _CFBundleCopyPrivateFrameworksURL(iVar3), iVar3 != 0)) {
    uVar1 = *(undefined4 *)PTR_0003f030;
    iVar4 = _CFURLCreateCopyAppendingPathComponent
                      (uVar1,iVar3,&cf_ASWRegistrationCarbonBridge_bundle,0);
    if (iVar4 == 0) {
      iVar5 = 0;
    }
    else {
      iVar5 = _CFBundleCreate(uVar1,iVar4);
      if ((iVar5 != 0) && (cVar2 = _CFBundleLoadExecutable(iVar5), cVar2 == '\0')) {
        _CFRelease(iVar5);
        iVar5 = 0;
      }
      _CFRelease(iVar4);
    }
    _CFRelease(iVar3);
    if (iVar5 != 0) {
      if (param_1 == '\0') {
        if (param_2 == '\0') {
          pcVar8 = &cf_runWithoutCountDown;
        }
        else {
          pcVar8 = &cf_run;
        }
        pcVar6 = (code *)_CFBundleGetFunctionPointerForName(iVar5,pcVar8);
        if (pcVar6 != (code *)0x0) {
          (*pcVar6)();
        }
      }
      else {
        if (param_2 == '\0') {
          pcVar8 = &cf_runModalWithoutCountDown;
        }
        else {
          pcVar8 = &cf_runModal;
        }
        pcVar6 = (code *)_CFBundleGetFunctionPointerForName(iVar5,pcVar8);
        if (pcVar6 != (code *)0x0) {
          uVar7 = (*pcVar6)();
          return uVar7 & 0xff;
        }
      }
      return 0;
    }
  }
  return 0xffffffd5;
}


// ==== _ASWAboutBoxLoadPrivateFrameworkBundle @ 0000738b ====

void __regparm3 _ASWAboutBoxLoadPrivateFrameworkBundle(undefined4 param_1,int *param_2)

{
  undefined4 uVar1;
  char cVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  
  if (param_2 != (int *)0x0) {
    *param_2 = 0;
    iVar3 = _CFBundleGetMainBundle();
    if (iVar3 != 0) {
      iVar3 = _CFBundleCopyPrivateFrameworksURL(iVar3);
      if (iVar3 != 0) {
        uVar1 = *(undefined4 *)PTR_0003f030;
        iVar4 = _CFURLCreateCopyAppendingPathComponent(uVar1,iVar3,param_1,0);
        if (iVar4 != 0) {
          iVar5 = _CFBundleCreate(uVar1,iVar4);
          *param_2 = iVar5;
          if (iVar5 != 0) {
            cVar2 = _CFBundleLoadExecutable(iVar5);
            if (cVar2 == '\0') {
              _CFRelease(*param_2);
              *param_2 = 0;
            }
          }
          _CFRelease(iVar4);
        }
        _CFRelease(iVar3);
      }
    }
  }
  return;
}


// ==== _DrawCompPattern @ 0000742c ====

void _DrawCompPattern(void)

{
  _PatternFillCompGWorld(0x390);
  _SetToScreen();
  return;
}


// ==== _UpdateInterfaceText @ 00007444 ====

void _UpdateInterfaceText(void)

{
  _CompToScreen(*(undefined4 *)PTR__gTextRect_00034080,*(undefined4 *)(PTR__gTextRect_00034080 + 4),
                CONCAT22(*(short *)(PTR__environment_0003f028 + 0xc) +
                         *(short *)(PTR__gTextRect_00034080 + 2),
                         *(short *)(PTR__environment_0003f028 + 10) +
                         *(short *)PTR__gTextRect_00034080),
                CONCAT22(*(short *)(PTR__environment_0003f028 + 0xc) +
                         *(short *)(PTR__gTextRect_00034080 + 6),
                         *(short *)(PTR__environment_0003f028 + 10) +
                         *(short *)(PTR__gTextRect_00034080 + 4)));
  return;
}


// ==== _UpdateScreen @ 000074c0 ====

void _UpdateScreen(void)

{
  _IsMenuBarHidden();
  _SetToScreen();
  _CompToScreen(*(undefined4 *)(PTR__environment_0003f028 + 0x12),
                *(undefined4 *)(PTR__environment_0003f028 + 0x16),
                *(undefined4 *)(PTR__environment_0003f028 + 10),
                *(undefined4 *)(PTR__environment_0003f028 + 0xe));
  return;
}


// ==== _WipeScreenOut @ 000074fc ====

void _WipeScreenOut(short param_1)

{
  uint uVar1;
  int iVar2;
  int iVar3;
  uint local_44;
  short local_3e;
  undefined4 local_3c;
  undefined4 local_38;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  local_44 = _TickCount();
  _SetRect(&local_24,0,0xf0,0x280,(int)(short)(param_1 + 0xf0));
  local_2c = local_24;
  local_28 = local_20;
  _SetRect(&local_34,0,(int)(short)(0xf0 - param_1),0x280,0xf0);
  local_3c = local_34;
  local_38 = local_30;
  _SetToScreen();
  _CompToScreen(local_24,local_20,local_2c,local_28);
  _CompToScreen(local_34,local_30,local_3c,local_38);
  _FlushIfNecessary();
  iVar3 = (int)param_1;
  local_3e = 0;
  iVar2 = 0;
  while (iVar2 <= iVar3 * 2 + 0xf0) {
    uVar1 = _TickCount();
    if (local_44 < uVar1) {
      local_44 = _TickCount();
      _OffsetRect(&local_24,0,iVar3);
      _OffsetRect(&local_2c,0,iVar3);
      _OffsetRect(&local_34,0,(int)-param_1);
      _OffsetRect(&local_3c,0,(int)-param_1);
      local_3e = local_3e + param_1;
      _CompToScreen(local_24,local_20,local_2c,local_28);
      _CompToScreen(local_34,local_30,local_3c,local_38);
      _FlushIfNecessary();
      iVar2 = (int)local_3e;
    }
  }
  return;
}


// ==== _WipeScreen @ 000076d3 ====

void _WipeScreen(short param_1)

{
  undefined *puVar1;
  int iVar2;
  uint uVar3;
  int iVar4;
  short sVar5;
  uint local_40;
  undefined4 local_3c;
  undefined4 local_38;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  local_40 = _TickCount();
  iVar2 = (int)param_1;
  _SetRect(&local_24,0,0,0x280,iVar2);
  puVar1 = PTR__environment_0003f028;
  local_2c = local_24;
  local_28 = local_20;
  _OffsetRect(&local_2c,(int)*(short *)(PTR__environment_0003f028 + 0x1a),
              (int)*(short *)(PTR__environment_0003f028 + 0x1c));
  _SetRect(&local_34,0,(int)(short)(0x1e0 - param_1),0x280,0x1e0);
  local_3c = local_34;
  local_38 = local_30;
  _OffsetRect(&local_3c,(int)*(short *)(puVar1 + 0x1a),(int)*(short *)(puVar1 + 0x1c));
  _SetToScreen();
  _CompToScreen(local_24,local_20,local_2c,local_28);
  _CompToScreen(local_34,local_30,local_3c,local_38);
  _FlushIfNecessary();
  sVar5 = 0;
  iVar4 = 0;
  while (iVar4 < iVar2 * 2 + 0xf0) {
    uVar3 = _TickCount();
    if (local_40 < uVar3) {
      local_40 = _TickCount();
      _OffsetRect(&local_24,0,iVar2);
      _OffsetRect(&local_2c,0,iVar2);
      _OffsetRect(&local_34,0,(int)-param_1);
      _OffsetRect(&local_3c,0,(int)-param_1);
      sVar5 = sVar5 + param_1;
      _CompToScreen(local_24,local_20,local_2c,local_28);
      _CompToScreen(local_34,local_30,local_3c,local_38);
      _FlushIfNecessary();
      iVar4 = (int)sVar5;
    }
  }
  return;
}


// ==== _FlashButton @ 000078e0 ====

void __regparm3 _FlashButton(undefined1 param_1)

{
  undefined4 uVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  undefined4 local_14;
  undefined4 local_10;
  
  _ResetNumScrnRects();
  _SetToBgndGWorld();
  _SetRect(&local_14,0,0,300,300);
  _DrawPicture(_gMenuButtonsPict,&local_14);
  _SetToScreen();
  switch(param_1) {
  default:
    goto switchD_00007941_caseD_0;
  case 1:
    local_14 = _gBtn_New_SrcR;
    local_10 = DAT_000349dc;
    _OffsetRect(&local_14,0x96,0);
    _BgndToCompTransparent(local_14,local_10,_gBtn_New_DstR,DAT_00034a14);
    _AddRectToScreen(&_gBtn_New_DstR);
    _DrawRectsToScreen();
    _FlushIfNecessary();
    _ProcessMenuStars();
    _WaitFor(10);
    _SetToBgndGWorld();
    _SetRect(&local_14,0,0,300,300);
    _DrawPicture(_gMenuButtonsPict,&local_14);
    _SetToScreen();
    uVar1 = _gBtn_New_SrcR;
    uVar2 = DAT_000349dc;
    uVar3 = _gBtn_New_DstR;
    uVar4 = DAT_00034a14;
    break;
  case 2:
    local_14 = _gBtn_Demo_SrcR;
    local_10 = DAT_000349e4;
    _OffsetRect(&local_14,0x96,0);
    _BgndToCompTransparent(local_14,local_10,_gBtn_Demo_DstR,DAT_00034a1c);
    _AddRectToScreen(&_gBtn_Demo_DstR);
    _DrawRectsToScreen();
    _FlushIfNecessary();
    _ProcessMenuStars();
    _WaitFor(10);
    _SetToBgndGWorld();
    _SetRect(&local_14,0,0,300,300);
    _DrawPicture(_gMenuButtonsPict,&local_14);
    _SetToScreen();
    uVar1 = _gBtn_Demo_SrcR;
    uVar2 = DAT_000349e4;
    uVar3 = _gBtn_Demo_DstR;
    uVar4 = DAT_00034a1c;
    break;
  case 3:
    local_14 = _gBtn_Scores_SrcR;
    local_10 = DAT_000349ec;
    _OffsetRect(&local_14,0x96,0);
    _BgndToCompTransparent(local_14,local_10,_gBtn_Scores_DstR,DAT_00034a24);
    _AddRectToScreen(&_gBtn_Scores_DstR);
    _DrawRectsToScreen();
    _FlushIfNecessary();
    _ProcessMenuStars();
    _WaitFor(10);
    _SetToBgndGWorld();
    _SetRect(&local_14,0,0,300,300);
    _DrawPicture(_gMenuButtonsPict,&local_14);
    _SetToScreen();
    uVar1 = _gBtn_Scores_SrcR;
    uVar2 = DAT_000349ec;
    uVar3 = _gBtn_Scores_DstR;
    uVar4 = DAT_00034a24;
    break;
  case 4:
    local_14 = _gBtn_Prefs_SrcR;
    local_10 = DAT_000349f4;
    _OffsetRect(&local_14,0x96,0);
    _BgndToCompTransparent(local_14,local_10,_gBtn_Prefs_DstR,DAT_00034a2c);
    _AddRectToScreen(&_gBtn_Prefs_DstR);
    _DrawRectsToScreen();
    _FlushIfNecessary();
    _ProcessMenuStars();
    _WaitFor(10);
    _SetToBgndGWorld();
    _SetRect(&local_14,0,0,300,300);
    _DrawPicture(_gMenuButtonsPict,&local_14);
    _SetToScreen();
    uVar1 = _gBtn_Prefs_SrcR;
    uVar2 = DAT_000349f4;
    uVar3 = _gBtn_Prefs_DstR;
    uVar4 = DAT_00034a2c;
    break;
  case 5:
    local_14 = _gBtn_Credits_SrcR;
    local_10 = DAT_000349fc;
    _OffsetRect(&local_14,0x96,0);
    _BgndToCompTransparent(local_14,local_10,_gBtn_Credits_DstR,DAT_00034a34);
    _AddRectToScreen(&_gBtn_Credits_DstR);
    _DrawRectsToScreen();
    _FlushIfNecessary();
    _ProcessMenuStars();
    _WaitFor(10);
    _SetToBgndGWorld();
    _SetRect(&local_14,0,0,300,300);
    _DrawPicture(_gMenuButtonsPict,&local_14);
    _SetToScreen();
    uVar1 = _gBtn_Credits_SrcR;
    uVar2 = DAT_000349fc;
    uVar3 = _gBtn_Credits_DstR;
    uVar4 = DAT_00034a34;
    break;
  case 6:
    local_14 = _gBtn_Quit_SrcR;
    local_10 = DAT_00034a04;
    _OffsetRect(&local_14,0x96,0);
    _BgndToCompTransparent(local_14,local_10,_gBtn_Quit_DstR,DAT_00034a3c);
    _AddRectToScreen(&_gBtn_Quit_DstR);
    _DrawRectsToScreen();
    _FlushIfNecessary();
    _ProcessMenuStars();
    _WaitFor(10);
    _SetToBgndGWorld();
    _SetRect(&local_14,0,0,300,300);
    _DrawPicture(_gMenuButtonsPict,&local_14);
    _SetToScreen();
    uVar1 = _gBtn_Quit_SrcR;
    uVar2 = DAT_00034a04;
    uVar3 = _gBtn_Quit_DstR;
    uVar4 = DAT_00034a3c;
    break;
  case 7:
    local_14 = _gBtn_Register_SrcR;
    local_10 = DAT_00034a0c;
    _OffsetRect(&local_14,0x96,0);
    _BgndToCompTransparent(local_14,local_10,_gBtn_Register_DstR,DAT_00034a44);
    _AddRectToScreen(&_gBtn_Register_DstR);
    _DrawRectsToScreen();
    _FlushIfNecessary();
    _ProcessMenuStars();
    _WaitFor(10);
    _SetToBgndGWorld();
    _SetRect(&local_14,0,0,300,300);
    _DrawPicture(_gMenuButtonsPict,&local_14);
    _SetToScreen();
    uVar1 = _gBtn_Register_SrcR;
    uVar2 = DAT_00034a0c;
    uVar3 = _gBtn_Register_DstR;
    uVar4 = DAT_00034a44;
  }
  _BgndToCompTransparent(uVar1,uVar2,uVar3,uVar4);
  _DrawRectsToScreen();
  _ProcessMenuStars();
  _FlushIfNecessary();
switchD_00007941_caseD_0:
  return;
}


// ==== _DrawButton @ 00007f62 ====

void __regparm3 _DrawButton(char param_1)

{
  uint uVar1;
  undefined4 local_14;
  undefined4 local_10;
  
  _ResetNumScrnRects();
  _SetToBgndGWorld();
  _SetRect(&local_14,0,0,300,300);
  _DrawPicture(_gMenuButtonsPict,&local_14);
  _SetToScreen();
  if ((_gBtn_Hit_New != 0) && ((uint)_gBtn_Hit_New != (int)param_1)) {
    _BgndToCompTransparent(_gBtn_New_SrcR,DAT_000349dc,_gBtn_New_DstR,DAT_00034a14);
    _AddRectToScreen(&_gBtn_New_DstR);
    _gBtn_Hit_New = 0;
  }
  uVar1 = (uint)param_1;
  if ((_gBtn_Hit_Demo != 0) && (_gBtn_Hit_Demo != uVar1)) {
    _BgndToCompTransparent(_gBtn_Demo_SrcR,DAT_000349e4,_gBtn_Demo_DstR,DAT_00034a1c);
    _AddRectToScreen(&_gBtn_Demo_DstR);
    _gBtn_Hit_Demo = 0;
  }
  if ((_gBtn_Hit_Scores != 0) && (_gBtn_Hit_Scores != uVar1)) {
    _BgndToCompTransparent(_gBtn_Scores_SrcR,DAT_000349ec,_gBtn_Scores_DstR,DAT_00034a24);
    _AddRectToScreen(&_gBtn_Scores_DstR);
    _gBtn_Hit_Scores = 0;
  }
  if ((_gBtn_Hit_Prefs != 0) && (_gBtn_Hit_Prefs != uVar1)) {
    _BgndToCompTransparent(_gBtn_Prefs_SrcR,DAT_000349f4,_gBtn_Prefs_DstR,DAT_00034a2c);
    _AddRectToScreen(&_gBtn_Prefs_DstR);
    _gBtn_Hit_Prefs = 0;
  }
  if ((_gBtn_Hit_Credits != 0) && (_gBtn_Hit_Credits != uVar1)) {
    _BgndToCompTransparent(_gBtn_Credits_SrcR,DAT_000349fc,_gBtn_Credits_DstR,DAT_00034a34);
    _AddRectToScreen(&_gBtn_Credits_DstR);
    _gBtn_Hit_Credits = 0;
  }
  if ((_gBtn_Hit_Quit != 0) && (_gBtn_Hit_Quit != uVar1)) {
    _BgndToCompTransparent(_gBtn_Quit_SrcR,DAT_00034a04,_gBtn_Quit_DstR,DAT_00034a3c);
    _AddRectToScreen(&_gBtn_Quit_DstR);
    _gBtn_Hit_Quit = 0;
  }
  if ((_gBtn_Hit_Register != 0) && (_gBtn_Hit_Register != uVar1)) {
    _BgndToCompTransparent(_gBtn_Register_SrcR,DAT_00034a0c,_gBtn_Register_DstR,DAT_00034a44);
    _AddRectToScreen(&_gBtn_Register_DstR);
    _gBtn_Hit_Register = 0;
  }
  switch(uVar1) {
  case 0:
    break;
  case 1:
    local_14 = _gBtn_New_SrcR;
    local_10 = DAT_000349dc;
    _OffsetRect(&local_14,0x96,0);
    _BgndToCompTransparent(local_14,local_10,_gBtn_New_DstR,DAT_00034a14);
    _AddRectToScreen(&_gBtn_New_DstR);
    _gBtn_Hit_New = 1;
    break;
  case 2:
    local_14 = _gBtn_Demo_SrcR;
    local_10 = DAT_000349e4;
    _OffsetRect(&local_14,0x96,0);
    _BgndToCompTransparent(local_14,local_10,_gBtn_Demo_DstR,DAT_00034a1c);
    _AddRectToScreen(&_gBtn_Demo_DstR);
    _gBtn_Hit_Demo = 1;
    break;
  case 3:
    local_14 = _gBtn_Scores_SrcR;
    local_10 = DAT_000349ec;
    _OffsetRect(&local_14,0x96,0);
    _BgndToCompTransparent(local_14,local_10,_gBtn_Scores_DstR,DAT_00034a24);
    _AddRectToScreen(&_gBtn_Scores_DstR);
    _gBtn_Hit_Scores = 1;
    break;
  case 4:
    local_14 = _gBtn_Prefs_SrcR;
    local_10 = DAT_000349f4;
    _OffsetRect(&local_14,0x96,0);
    _BgndToCompTransparent(local_14,local_10,_gBtn_Prefs_DstR,DAT_00034a2c);
    _AddRectToScreen(&_gBtn_Prefs_DstR);
    _gBtn_Hit_Prefs = 1;
    break;
  case 5:
    local_14 = _gBtn_Credits_SrcR;
    local_10 = DAT_000349fc;
    _OffsetRect(&local_14,0x96,0);
    _BgndToCompTransparent(local_14,local_10,_gBtn_Credits_DstR,DAT_00034a34);
    _AddRectToScreen(&_gBtn_Credits_DstR);
    _gBtn_Hit_Credits = 1;
    break;
  case 6:
    local_14 = _gBtn_Quit_SrcR;
    local_10 = DAT_00034a04;
    _OffsetRect(&local_14,0x96,0);
    _BgndToCompTransparent(local_14,local_10,_gBtn_Quit_DstR,DAT_00034a3c);
    _AddRectToScreen(&_gBtn_Quit_DstR);
    _gBtn_Hit_Quit = 1;
    break;
  case 7:
    local_14 = _gBtn_Register_SrcR;
    local_10 = DAT_00034a0c;
    _OffsetRect(&local_14,0x96,0);
    _BgndToCompTransparent(local_14,local_10,_gBtn_Register_DstR,DAT_00034a44);
    _AddRectToScreen(&_gBtn_Register_DstR);
    _gBtn_Hit_Register = 1;
    break;
  default:
    goto switchD_000081f1_default;
  }
  _DrawRectsToScreen();
switchD_000081f1_default:
  return;
}


// ==== _PrefsButton @ 000084c6 ====

void _PrefsButton(void)

{
  _PrefsDialog();
  _UpdateMusicVolume();
  return;
}


// ==== _LoadMenuBar @ 000084d7 ====

void _LoadMenuBar(void)

{
  undefined4 uVar1;
  
  _CreateNibReference(&cf_main,&_gNibRef);
  _SetMenuBarFromNib(_gNibRef,&cf_MenuBar);
  _gOptionsMenu = _GetMenuHandle(0x83);
  _CreateNewMenu(0x8c,0,&_gKeySetsSubMenu);
  _InsertMenuItemTextWithCFString(_gKeySetsSubMenu,&cf_Default,0,0,0);
  _SetMenuItemHierarchicalMenu(_gOptionsMenu,6,_gKeySetsSubMenu);
  if (_gKeySetsSubMenu == 0) {
    _StdError("Can\'t load sub menu for key sets.",0x8c);
  }
  uVar1 = _GetMenuHandle(0x80);
  uVar1 = _GetMenuEventTarget(uVar1);
  _InstallEventHandler(uVar1,_MenuHandler,1,&_menuEvents_74915,0,0);
  uVar1 = _GetMenuHandle(0x83);
  uVar1 = _GetMenuEventTarget(uVar1);
  _InstallEventHandler(uVar1,_MenuHandler,1,&_menuEvents_74915,0,0);
  return;
}


// ==== _ResetOptionsMenu @ 00008625 ====

void _ResetOptionsMenu(void)

{
  char cVar1;
  undefined2 uVar2;
  ushort uVar3;
  short sVar4;
  short sVar5;
  undefined4 uVar6;
  undefined1 local_12a [256];
  undefined1 local_2a [12];
  undefined1 local_1e [14];
  
  while (uVar3 = _CountMenuItems(_gKeySetsSubMenu), 1 < uVar3) {
    uVar2 = _CountMenuItems(_gKeySetsSubMenu);
    _DeleteMenuItem(_gKeySetsSubMenu,uVar2);
  }
  _SetItemMark(_gKeySetsSubMenu,1,0);
  sVar4 = _GetShortPref(0x37);
  if (1 < sVar4) {
    _InsertMenuItem(_gKeySetsSubMenu,"\x02(-",0xff);
  }
  for (sVar4 = 2; sVar5 = _GetShortPref(0x37), sVar4 <= sVar5; sVar4 = sVar4 + 1) {
    _GetKeySetPref((int)sVar4,local_2a,local_1e,local_1e,local_1e,local_1e,local_1e);
    _CopyCStringToPascal(local_2a,local_12a);
    _InsertMenuItem(_gKeySetsSubMenu,local_12a,0xff);
  }
  sVar4 = _GetShortPref(0x38);
  if (1 < sVar4) {
    sVar4 = sVar4 + 1;
  }
  _SetItemMark(_gKeySetsSubMenu,sVar4,0x12);
  cVar1 = _GetBooleanPref(0x37);
  if (cVar1 == '\0') {
    uVar6 = 0;
  }
  else {
    uVar6 = 0x12;
  }
  _SetItemMark(_gOptionsMenu,1,uVar6);
  sVar4 = _GetShortPref(0x33);
  if (sVar4 == 1) {
    uVar6 = 0;
  }
  else {
    uVar6 = 0x12;
  }
  _SetItemMark(_gOptionsMenu,3,uVar6);
  sVar4 = _GetShortPref(0x35);
  if (sVar4 == 1) {
    uVar6 = 0;
  }
  else {
    uVar6 = 0x12;
  }
  _SetItemMark(_gOptionsMenu,4,uVar6);
  cVar1 = _GetBooleanPref(0x41);
  if ((cVar1 != '\0') && (cVar1 = _CanUseISp(), cVar1 != '\0')) {
    _DisableMenuItem(_gOptionsMenu,6);
    return;
  }
  _EnableMenuItem(_gOptionsMenu,6);
  return;
}


// ==== _EnableAboutMenu @ 00008850 ====

void _EnableAboutMenu(void)

{
  _EnableMenuCommand(0,0x61626f75);
  return;
}


// ==== _DisableAboutMenu @ 0000886c ====

void _DisableAboutMenu(void)

{
  _DisableMenuCommand(0,0x61626f75);
  return;
}


// ==== _SuspendGame @ 00008888 ====

void _SuspendGame(void)

{
  _gSuspended = 1;
  _PauseMusic();
  _SuspendKeys();
  _ScreenSuspend();
  return;
}


// ==== _Fade @ 000088a5 ====

void _Fade(void)

{
  return;
}


// ==== _UnFade @ 000088aa ====

void _UnFade(void)

{
  return;
}


// ==== _AppleEventsInit @ 000088af ====

void _AppleEventsInit(void)

{
  short sVar1;
  undefined4 uVar2;
  byte local_10 [12];
  
  uVar2 = _NewAEEventHandlerUPP(_QuitAppleEventHandler);
  sVar1 = _AEInstallEventHandler(0x61657674,0x71756974,uVar2,0,0);
  if (sVar1 != 0) {
    _StdError("Cannot install Apple Event handler for quit.",(int)sVar1);
  }
  sVar1 = _Gestalt(0x6d656e75,local_10);
  if ((sVar1 == 0) && ((local_10[0] & 2) != 0)) {
    uVar2 = _NewAEEventHandlerUPP(_PrefsAppleEventHandler);
    sVar1 = _AEInstallEventHandler(0x61657674,0x70726566,uVar2,0,0);
    if (sVar1 != 0) {
      _StdError("Cannot install Apple Event handler for prefs.",(int)sVar1);
    }
  }
  return;
}


// ==== _QuitAppleEventHandler @ 00008969 ====

undefined4 _QuitAppleEventHandler(void)

{
  _gFinished = 1;
  _QuitApplicationEventLoop();
  return 0;
}


// ==== _PrefsAppleEventHandler @ 0000897f ====

undefined4 _PrefsAppleEventHandler(void)

{
  _gDoPrefsNow = 1;
  return 0;
}


// ==== _DrawInterfaceText @ 0000898d ====

void _DrawInterfaceText(void)

{
  char cVar1;
  bool bVar2;
  undefined *puVar3;
  short sVar4;
  uint uVar5;
  undefined4 uVar6;
  int iVar7;
  undefined4 *puVar8;
  char *pcVar9;
  size_t sVar10;
  undefined4 local_230;
  undefined1 local_228 [255];
  undefined1 uStack_129;
  undefined1 local_128 [3];
  undefined1 auStack_125 [2];
  undefined1 auStack_123 [3];
  undefined4 local_120;
  undefined4 local_11c;
  uint local_118;
  undefined4 local_114;
  undefined4 local_110;
  int local_10c;
  uint local_108;
  uint local_104;
  undefined4 local_100;
  uint local_fc;
  undefined4 local_f8;
  undefined4 local_f4;
  uint local_f0;
  undefined4 local_ec;
  undefined2 local_28;
  undefined2 local_26;
  undefined2 local_24;
  undefined2 local_22;
  undefined2 local_20;
  undefined2 local_1e;
  
  local_22 = 0xffff;
  local_20 = 0x9999;
  local_1e = 0;
  sVar4 = _Interface_GetOccasions();
  uVar5 = _RT3_GetDaysHad();
  if ((uVar5 < 0x1f) || (uVar5 = _RT3_GetHoursUsed(), uVar5 < 7)) {
    bVar2 = false;
  }
  else {
    bVar2 = true;
  }
  switch(_gMsgCounter) {
  case 0:
    _local_128 = 0x79706f43;
    stack0xfffffedc = 0x68676972;
    local_120 = 0x39312074;
    local_11c = 0x322d3539;
    local_118 = 0x20383030;
    local_114 = 0x78656c41;
    local_110 = 0x74654d20;
    local_10c = 0x666c6163;
    local_108 = 0x7661442f;
    local_104 = 0x57206469;
    local_100 = 0x69657261;
    local_fc = 0x2620676e;
    local_f8 = 0x626d4120;
    local_f4 = 0x69736f72;
    local_f0 = CONCAT22(local_f0._2_2_,0x61);
    break;
  case 1:
    uVar6 = _CFBundleGetMainBundle();
    uVar6 = _CFBundleGetValueForInfoDictionaryKey(uVar6,&cf_CFBundleVersion);
    uVar6 = _CFStringCreateWithFormat(*(undefined4 *)PTR_0003f02c,0,&cf_Version__,uVar6);
    _CFStringGetCString(uVar6,local_128,0x100,0x600);
    _CFRelease(uVar6);
    break;
  case 2:
    if (_gIsGameRegistered == '\0') {
      if (bVar2) {
        _local_128 = 0x53494854;
        stack0xfffffedc = 0x504f4320;
        local_120 = 0x53492059;
        local_11c = 0x544f4e20;
        local_118 = 0x47455220;
        local_114 = 0x45545349;
        local_110 = 0x2e444552;
        local_10c = (uint)local_10c._1_3_ << 8;
LAB_00008de3:
        local_230 = 0x45;
        goto LAB_00009cf1;
      }
      _local_128 = 0x73696854;
      stack0xfffffedc = 0x706f6320;
      local_120 = 0x73692079;
      local_11c = 0x544f4e20;
      local_118 = 0x47455220;
      local_114 = 0x45545349;
      local_110 = 0x2e444552;
      goto LAB_00009a05;
    }
    _local_128 = 0x69676552;
    stack0xfffffedc = 0x72657473;
    local_120 = 0x54206465;
    local_11c = 0x20203a6f;
    local_118 = local_118 & 0xffffff00;
    pcVar9 = (char *)_RT3_GetDisplayName();
    _strcat(local_128,pcVar9);
    uVar5 = 0xffffffff;
    pcVar9 = local_128;
    do {
      if (uVar5 == 0) break;
      uVar5 = uVar5 - 1;
      cVar1 = *pcVar9;
      pcVar9 = pcVar9 + 1;
    } while (cVar1 != '\0');
    *(undefined4 *)(&uStack_129 + ~uVar5) = 0x5b2020;
    pcVar9 = (char *)_RT3_GetDisplayCopies();
    _strcat(local_128,pcVar9);
    iVar7 = _RT3_GetLicenseCopies();
    if (iVar7 == 1) {
      uVar5 = 0xffffffff;
      pcVar9 = local_128;
      do {
        if (uVar5 == 0) break;
        uVar5 = uVar5 - 1;
        cVar1 = *pcVar9;
        pcVar9 = pcVar9 + 1;
      } while (cVar1 != '\0');
      uVar5 = ~uVar5;
      *(undefined4 *)(&uStack_129 + uVar5) = 0x706f6320;
      *(undefined2 *)(local_128 + uVar5 + 3) = 0x5d79;
      auStack_123[uVar5] = 0;
    }
    else {
      uVar5 = 0xffffffff;
      pcVar9 = local_128;
      do {
        if (uVar5 == 0) break;
        uVar5 = uVar5 - 1;
        cVar1 = *pcVar9;
        pcVar9 = pcVar9 + 1;
      } while (cVar1 != '\0');
      uVar5 = ~uVar5;
      *(undefined4 *)(&uStack_129 + uVar5) = 0x706f6320;
      *(undefined4 *)(local_128 + uVar5 + 3) = 0x5d736569;
      auStack_123[uVar5 + 2] = 0;
    }
    break;
  case 3:
    if (sVar4 == 0) {
      if (_gInfoFlag == '\0') {
        _gInfoFlag = '\x01';
        if (_gIsGameRegistered != '\0') {
          _local_128 = 0x6e616854;
          stack0xfffffedc = 0x6620736b;
          local_120 = 0x7320726f;
          local_11c = 0x6f707075;
          local_118 = 0x6e697472;
          local_114 = 0x68532067;
          local_110 = 0x77657261;
          local_10c = 0x21657261;
          goto LAB_000092a3;
        }
        if (bVar2) {
          _local_128 = 0x41454c50;
          stack0xfffffedc = 0x52204553;
          local_120 = 0x53494745;
          local_11c = 0x20524554;
          local_118 = 0x20444e41;
          local_114 = 0x50505553;
          local_110 = 0x2054524f;
          local_10c = 0x52414853;
          local_108 = 0x52415745;
          local_104 = CONCAT13(local_104._3_1_,0x2145);
          goto LAB_00008de3;
        }
        _local_128 = 0x61656c50;
        stack0xfffffedc = 0x72206573;
        local_120 = 0x73696765;
        local_11c = 0x20726574;
        local_118 = 0x20646e61;
        local_114 = 0x70707573;
        local_110 = 0x2074726f;
        local_10c = 0x72616853;
        local_108 = 0x72617765;
        local_104 = CONCAT22(local_104._2_2_,0x2165);
LAB_00009071:
        local_104._0_3_ = (uint3)(ushort)local_104;
      }
      else {
        _local_128 = 0x69736956;
        stack0xfffffedc = 0x73752074;
        local_120 = 0x20746120;
        local_11c = 0x70747468;
        local_118 = 0x772f2f3a;
        local_114 = 0x412e7777;
        local_110 = 0x6f72626d;
        local_10c = 0x53616973;
        local_108 = 0x6f632e57;
        local_104 = 0x61672f6d;
        local_100 = 0x2f73656d;
        local_fc = 0x2f7462;
        _gInfoFlag = '\0';
      }
    }
    else {
      switch(sVar4) {
      case 1:
        _local_128 = 0x656d6552;
        stack0xfffffedc = 0x7265626d;
        local_120 = 0x206f7420;
        local_11c = 0x676e6168;
        local_118 = 0x20707520;
        local_114 = 0x72756f79;
        local_110 = 0x6f747320;
        local_10c = 0x6e696b63;
        local_108 = CONCAT13(local_108._3_1_,0x2167);
        break;
      case 2:
        _local_128 = 0x7272654d;
        stack0xfffffedc = 0x68432079;
        local_120 = 0x74736972;
        local_11c = 0x2073616d;
        local_118 = 0x79206f74;
        local_114 = 0x2072756f;
        local_110 = 0x696d6166;
        local_10c = 0x21796c;
        break;
      case 3:
        _local_128 = 0x70706148;
        stack0xfffffedc = 0x69422079;
        local_120 = 0x64687472;
        local_11c = 0x44207961;
        local_118 = 0x64697661;
        local_114 = 0x6f572021;
        local_110 = 0x21746f;
        break;
      case 4:
        _local_128 = 0x70706148;
        stack0xfffffedc = 0x69422079;
        local_120 = 0x64687472;
        local_11c = 0x41207961;
        local_118 = 0x2178656c;
        local_114 = 0x6f6f5720;
        local_110 = CONCAT13(local_110._3_1_,0x2174);
        break;
      case 5:
        _local_128 = 0x76697244;
        stack0xfffffedc = 0x61732065;
        local_120 = 0x796c6566;
        local_11c = 0x6e6f7420;
        local_118 = 0x74686769;
        local_114 = 0x6c6f6620;
        local_110 = 0x21736b;
        break;
      case 6:
        _local_128 = 0x70706148;
        stack0xfffffedc = 0x654e2079;
        local_120 = 0x65592077;
        local_11c = 0x74207261;
        local_118 = 0x6f79206f;
        local_114 = 0x6e612075;
        local_110 = 0x6f792064;
        local_10c = 0x66207275;
        local_108 = 0x6c696d61;
        local_104 = CONCAT22(local_104._2_2_,0x2179);
        goto LAB_00009071;
      case 7:
        _local_128 = 0x63697254;
        stack0xfffffedc = 0x726f206b;
        local_120 = 0x65725420;
        local_11c = 0x3f7461;
        break;
      default:
        _local_128 = 0x6e616854;
        stack0xfffffedc = 0x6f79206b;
        local_120 = 0x6f662075;
        local_11c = 0x75732072;
        local_118 = 0x726f7070;
        local_114 = 0x676e6974;
        local_110 = 0x61685320;
        local_10c = 0x61776572;
        local_108 = 0x216572;
      }
    }
    break;
  case 4:
    pcVar9 = "A man he hears what he wants to hear, and disregards the rest.";
    goto LAB_00009911;
  case 5:
    _local_128 = 0x20726157;
    stack0xfffffedc = 0x70207369;
    local_120 = 0x65636165;
    local_11c = 0x7246202e;
    local_118 = 0x6f646565;
    local_114 = 0x7369206d;
    local_110 = 0x616c7320;
    local_10c = 0x79726576;
    local_108 = 0x6749202e;
    local_104 = 0x61726f6e;
    local_100 = 0x2065636e;
    local_fc = 0x73207369;
    local_f8 = 0x6e657274;
    local_f4 = 0x2e687467;
    goto LAB_000099b3;
  case 6:
    pcVar9 = "Never send to know for whom the bell tolls; It tolls for thee.";
    goto LAB_00009911;
  case 7:
    _local_128 = 0x6c676145;
    stack0xfffffedc = 0x6d207365;
    local_120 = 0x73207961;
    local_11c = 0x2c72616f;
    local_118 = 0x74756220;
    local_114 = 0x61657720;
    local_110 = 0x736c6573;
    local_10c = 0x6e6f6420;
    local_108 = 0x67207427;
    local_104 = 0x73207465;
    local_100 = 0x656b6375;
    local_fc = 0x6e692064;
    local_f8 = 0x6a206f74;
    local_f4 = 0x65207465;
    local_f0 = 0x6e69676e;
    local_ec = 0x2e7365;
    break;
  case 8:
    _local_128 = 0x20656854;
    stack0xfffffedc = 0x736c776f;
    local_120 = 0x65726120;
    local_11c = 0x746f6e20;
    local_118 = 0x61687720;
    local_114 = 0x68742074;
    local_110 = 0x73207965;
    local_10c = 0x2e6d6565;
LAB_000092a3:
    local_108 = local_108 & 0xffffff00;
    break;
  case 9:
    _local_128 = 0x2774654c;
    stack0xfffffedc = 0x6c702073;
    local_120 = 0x47207961;
    local_11c = 0x61626f6c;
    local_118 = 0x6854206c;
    local_114 = 0x6f6d7265;
    local_110 = 0x6c63756e;
    local_10c = 0x20726165;
    local_108 = 0x2e726157;
    local_104 = local_104 & 0xffffff00;
    break;
  case 10:
    _local_128 = 0x696d6f43;
    stack0xfffffedc = 0x6e20676e;
    local_120 = 0x20747865;
    local_11c = 0x73726576;
    local_118 = 0x2e6e6f69;
    local_114 = 0x48202e2e;
    local_110 = 0x79727261;
    local_10c = 0x746f5020;
    local_108 = 0x20726574;
    local_104 = 0x79616c70;
    local_100 = 0x20676e69;
    local_fc = 0x69757173;
    local_f8 = 0x74696464;
    local_f4 = 0x2e6863;
    break;
  case 0xb:
    _local_128 = 0x65696353;
    stack0xfffffedc = 0x6c6f746e;
    local_120 = 0x2c79676f;
    local_11c = 0x202e6e20;
    local_118 = 0x696c6552;
    local_114 = 0x756f6967;
    local_110 = 0x79732073;
    local_10c = 0x6d657473;
    local_108 = 0x7328202e;
    local_104 = 0x203a6565;
    local_100 = 0x6d616353;
    local_fc = 0x694d202c;
    local_f8 = 0x4320646e;
    local_f4 = 0x72746e6f;
    local_f0 = 0x296c6f;
    break;
  case 0xc:
    _local_128 = 0x72746150;
    stack0xfffffedc = 0x2c746f69;
    local_120 = 0x202e6e20;
    local_11c = 0x20656854;
    local_118 = 0x65707564;
    local_114 = 0x20666f20;
    local_110 = 0x74617473;
    local_10c = 0x656d7365;
    local_108 = 0x6e61206e;
    local_104 = 0x68742064;
    local_100 = 0x6f742065;
    local_fc = 0x6f206c6f;
    local_f8 = 0x6f632066;
    local_f4 = 0x6575716e;
    local_f0 = 0x73726f72;
    local_ec = CONCAT22(local_ec._2_2_,0x2e);
    break;
  case 0xd:
    sVar10 = 0x44;
    pcVar9 = "Philosophy, n. Route of many roads leading from nowhere to nothing.";
    goto LAB_00009cd9;
  case 0xe:
    _local_128 = 0x69736f50;
    stack0xfffffedc = 0x65766974;
    local_120 = 0x6461202c;
    local_11c = 0x4d202e6a;
    local_118 = 0x61747369;
    local_114 = 0x206e656b;
    local_110 = 0x74207461;
    local_10c = 0x74206568;
    local_108 = 0x6f20706f;
    local_104 = 0x6e6f2066;
    local_100 = 0x20732765;
    local_fc = 0x63696f76;
    local_f8 = CONCAT13(local_f8._3_1_,0x2e65);
    break;
  case 0xf:
    sVar10 = 0x43;
    pcVar9 = "Reverence, n. Spiritual attitude of a man to god and a dog to man.";
    goto LAB_00009cd9;
  case 0x10:
    _local_128 = 0x6e696153;
    stack0xfffffedc = 0x6e202c74;
    local_120 = 0x2041202e;
    local_11c = 0x64616564;
    local_118 = 0x6e697320;
    local_114 = 0x2072656e;
    local_110 = 0x69766572;
    local_10c = 0x20646573;
    local_108 = 0x20646e61;
    local_104 = 0x74696465;
    local_100 = 0x2e6465;
    break;
  case 0x11:
    _local_128 = 0x27756f59;
    stack0xfffffedc = 0x68206572;
    local_120 = 0x20686769;
    local_11c = 0x6e69616d;
    local_118 = 0x616e6574;
    local_114 = 0x2065636e;
    local_110 = 0x7173616d;
    local_10c = 0x61726575;
    local_108 = 0x676e6964;
    local_104 = 0x20736120;
    local_100 = 0x20776f6c;
    local_fc = 0x6e69616d;
    local_f8 = 0x616e6574;
    local_f4 = 0x2e65636e;
    goto LAB_000099b3;
  case 0x12:
    _local_128 = 0x79206f44;
    stack0xfffffedc = 0x6520756f;
    local_120 = 0x20726576;
    local_11c = 0x65766168;
    local_118 = 0x6a656420;
    local_114 = 0x75762061;
    local_110 = 0x73724d20;
    local_10c = 0x6e614c20;
    local_108 = 0x74736163;
    local_104 = 0x3f7265;
    break;
  case 0x13:
    pcVar9 = "Two pieces of string: \'Feeling okay?\' \'No, I\'m a frayed knot.\'";
    goto LAB_00009911;
  case 0x14:
    _local_128 = 0x6f642049;
    stack0xfffffedc = 0x2074276e;
    local_120 = 0x65726163;
    local_11c = 0x61687720;
    local_118 = 0x6f792074;
    local_114 = 0x6d732075;
    local_110 = 0x2c6c6c65;
    local_10c = 0x74656720;
    local_108 = 0x206e6920;
    local_104 = 0x72656874;
    local_100 = CONCAT13(local_100._3_1_,0x2165);
    break;
  case 0x15:
    _local_128 = 0x2064654e;
    stack0xfffffedc = 0x20656874;
    local_120 = 0x64616568;
    local_11c = 0x6964202c;
    local_118 = 0x68742064;
    local_114 = 0x68772065;
    local_110 = 0x6c747369;
    local_10c = 0x20676e69;
    local_108 = 0x6c6c6562;
    local_104 = 0x74756279;
    local_100 = 0x206e6f74;
    local_fc = 0x63697274;
    local_f8 = 0x42203f6b;
    local_f4 = 0x21676e69;
    goto LAB_000099b3;
  case 0x16:
    _local_128 = 0x2e656e4f;
    stack0xfffffedc = 0x776f4820;
    local_120 = 0x6e616d20;
    local_11c = 0x73702079;
    local_118 = 0x69686379;
    local_114 = 0x64207363;
    local_110 = 0x2073656f;
    local_10c = 0x74207469;
    local_108 = 0x20656b61;
    local_104 = 0x63206f74;
    local_100 = 0x676e6168;
    local_fc = 0x20612065;
    local_f8 = 0x6867696c;
    local_f4 = 0x75622074;
    local_f0 = 0x3f626c;
    break;
  case 0x17:
    _local_128 = 0x65726548;
    stack0xfffffedc = 0x6c207327;
    local_120 = 0x696b6f6f;
    local_11c = 0x6120676e;
    local_118 = 0x6f792074;
    local_114 = 0x73202c75;
    local_110 = 0x64697571;
    local_10c = CONCAT22(local_10c._2_2_,0x2e);
    break;
  case 0x18:
    pcVar9 = "How long have you been looking at these messages? Have a game!";
LAB_00009911:
    puVar8 = (undefined4 *)local_128;
    for (iVar7 = 0xf; iVar7 != 0; iVar7 = iVar7 + -1) {
      *puVar8 = *(undefined4 *)pcVar9;
      pcVar9 = pcVar9 + 4;
      puVar8 = puVar8 + 1;
    }
    *(undefined2 *)puVar8 = *(undefined2 *)pcVar9;
    *(char *)((int)puVar8 + 2) = pcVar9[2];
    break;
  case 0x19:
    _local_128 = 0x72656854;
    stack0xfffffedc = 0x616d2065;
    local_120 = 0x65622079;
    local_11c = 0x62756220;
    local_118 = 0x73656c62;
    local_114 = 0x65686120;
    local_110 = 0x2e2e6461;
    local_10c = 0x7562202e;
    local_108 = 0x68772074;
    local_104 = 0x20656c69;
    local_100 = 0x72656874;
    local_fc = 0x20732765;
    local_f8 = 0x6973756d;
    local_f4 = 0x2e2e2e63;
LAB_000099b3:
    local_f0 = local_f0 & 0xffffff00;
    break;
  case 0x1a:
    _local_128 = 0x6e656857;
    stack0xfffffedc = 0x756f7920;
    local_120 = 0x73696620;
    local_11c = 0x70752068;
    local_118 = 0x61206e6f;
    local_114 = 0x61747320;
    local_110 = 0x2e2e2e72;
LAB_00009a05:
    local_10c = (uint)local_10c._1_3_ << 8;
    break;
  case 0x1b:
    _local_128 = 0x206c6c41;
    stack0xfffffedc = 0x72756f79;
    local_120 = 0x73696620;
    local_11c = 0x72612068;
    local_118 = 0x65622065;
    local_114 = 0x676e6f6c;
    local_110 = 0x206f7420;
    local_10c = 0x2e7375;
    break;
  case 0x1c:
    _local_128 = 0x79616c50;
    stack0xfffffedc = 0x20746920;
    local_120 = 0x69616761;
    local_11c = 0x53202c6e;
    local_118 = 0x6f6d6c61;
    local_114 = CONCAT13(local_114._3_1_,0x2e6e);
    break;
  case 0x1d:
    _local_128 = 0x27756f59;
    stack0xfffffedc = 0x62206c6c;
    local_120 = 0x6c702065;
    local_11c = 0x6e697961;
    local_118 = 0x6e612067;
    local_114 = 0x6568746f;
    local_110 = 0x61672072;
    local_10c = 0x6920656d;
    local_108 = 0x6874206e;
    local_104 = 0x6c422065;
    local_100 = 0x796b6e69;
    local_fc = 0x20666f20;
    local_f8 = 0x65206e61;
    local_f4 = CONCAT13(local_f4._3_1_,0x6579);
    break;
  case 0x1e:
    sVar10 = 0x42;
    pcVar9 = "Have you option clicked the title above? command? control? shift?";
    goto LAB_00009cd9;
  case 0x1f:
    _local_128 = 0x27756f59;
    stack0xfffffedc = 0x6c206576;
    local_120 = 0x2074736f;
    local_11c = 0x74616874;
    local_118 = 0x766f6c20;
    local_114 = 0x20676e69;
    local_110 = 0x696c6565;
    local_10c = 0x2e2e676e;
    local_108 = CONCAT22(local_108._2_2_,0x2e);
    break;
  case 0x20:
    _local_128 = 0x72656854;
    stack0xfffffedc = 0x20732765;
    local_120 = 0x70206f6e;
    local_11c = 0x6369616c;
    local_118 = 0x696c2065;
    local_114 = 0x6820656b;
    local_110 = 0x2c656d6f;
    local_10c = 0x65687420;
    local_108 = 0x73276572;
    local_104 = 0x206f6e20;
    local_100 = 0x69616c70;
    local_fc = 0x6c206563;
    local_f8 = 0x20656b69;
    local_f4 = 0x656d6f68;
    local_f0 = 0x2e2e2e;
    break;
  case 0x21:
    _local_128 = 0x61656c50;
    stack0xfffffedc = 0x20646573;
    local_120 = 0x6d206f74;
    local_11c = 0x20746565;
    local_118 = 0x2c756f79;
    local_114 = 0x706f6820;
    local_110 = 0x6f792065;
    local_10c = 0x75672075;
    local_108 = 0x20737365;
    local_104 = 0x6e20796d;
    local_100 = 0x2e656d61;
    local_fc = local_fc & 0xffffff00;
    break;
  default:
    sVar10 = 0x41;
    pcVar9 = "What\'s the fun in programming unless you get the occasional bug?";
LAB_00009cd9:
    _memcpy(local_128,pcVar9,sVar10);
  }
  local_230 = 0x111;
LAB_00009cf1:
  _CopyCStringToPascal(local_128,local_228);
  _SetToCompGWorld();
  _ForeColor(0x21);
  _BackColor(0x1e);
  puVar3 = PTR__gTextRect_00034080;
  _WorldSpriteToComp(*(undefined4 *)PTR__gSrcTextRect_0003407c,
                     *(undefined4 *)(PTR__gSrcTextRect_0003407c + 4),
                     *(undefined4 *)PTR__gTextRect_00034080,
                     *(undefined4 *)(PTR__gTextRect_00034080 + 4));
  local_24 = 0x8fff;
  local_26 = 0x8fff;
  local_28 = 0x8fff;
  _OpColor(&local_28);
  _PenMode(0x20);
  _ForeColor(0x21);
  _PaintRect(puVar3);
  _PenMode(0);
  _ForeColor(0x21);
  _RGBForeColor(&local_22);
  _MoveTo((int)*(short *)(puVar3 + 2),(int)*(short *)puVar3);
  _LineTo((int)*(short *)(puVar3 + 6),(int)*(short *)puVar3);
  _LineTo((int)*(short *)(puVar3 + 6),(int)*(short *)(puVar3 + 4));
  _LineTo((int)*(short *)(puVar3 + 2),(int)*(short *)(puVar3 + 4));
  _LineTo((int)*(short *)(puVar3 + 2),(int)*(short *)puVar3);
  _ForeColor(0x21);
  _SetGenevaNine();
  sVar4 = _StringWidth(local_228);
  _MoveTo((int)(short)(*(short *)(puVar3 + 2) +
                      (short)((((int)*(short *)(puVar3 + 6) - (int)*(short *)(puVar3 + 2)) -
                              (int)sVar4) / 2)),(int)(short)(*(short *)(puVar3 + 4) + -7));
  local_28 = 0;
  local_26 = 0;
  local_24 = 0;
  _RGBForeColor(&local_28);
  _ForeColor(local_230);
  _BackColor(0x1e);
  _DrawString(local_228);
  _ForeColor(0x21);
  return;
}


// ==== _DrawMainMenu @ 00009eb3 ====

void _DrawMainMenu(void)

{
  undefined4 local_14;
  undefined4 local_10;
  
  _PatternFillCompGWorld(0x391);
  _CompToSpriteGWorld(*(undefined4 *)PTR__gTextRect_00034080,
                      *(undefined4 *)(PTR__gTextRect_00034080 + 4),
                      *(undefined4 *)PTR__gSrcTextRect_0003407c,
                      *(undefined4 *)(PTR__gSrcTextRect_0003407c + 4));
  _gLogoR._2_2_ = 0xab;
  _gLogoR._0_2_ = 0x19;
  DAT_000349d4._2_2_ = 0x1d5;
  DAT_000349d4._0_2_ = 0xad;
  _SetToBgndGWorld();
  _SetRect(&local_14,0,0,300,300);
  _DrawPicture(_gMenuButtonsPict,&local_14);
  _SetToCompGWorld();
  local_14 = 0xe500bb;
  local_10 = 0x19b00c9;
  _DrawPictInRect(0x2334,0xe500bb,0x19b00c9);
  _SetToScreen();
  _SetRect(&_gBtn_New_SrcR,0,0,0x96,0x22);
  _SetRect(&_gBtn_Demo_SrcR,0,0x22,0x47,0x44);
  _SetRect(&_gBtn_Scores_SrcR,0,0x44,0x65,0x66);
  _SetRect(&_gBtn_Prefs_SrcR,0,0x66,0x50,0x88);
  _SetRect(&_gBtn_Credits_SrcR,0,0x88,0x68,0xaa);
  _SetRect(&_gBtn_Quit_SrcR,0,0xaa,0x43,0xcc);
  _SetRect(&_gBtn_Register_SrcR,0,0xcc,0x7b,0xee);
  _GetRectRsrc(1,&_gBtn_New_DstR);
  _GetRectRsrc(2,&_gBtn_Demo_DstR);
  _GetRectRsrc(3,&_gBtn_Scores_DstR);
  _GetRectRsrc(4,&_gBtn_Prefs_DstR);
  _GetRectRsrc(5,&_gBtn_Credits_DstR);
  _GetRectRsrc(6,&_gBtn_Quit_DstR);
  _GetRectRsrc(7,&_gBtn_Register_DstR);
  _BgndToCompTransparent(_gBtn_New_SrcR,DAT_000349dc,_gBtn_New_DstR,DAT_00034a14);
  _BgndToCompTransparent(_gBtn_Demo_SrcR,DAT_000349e4,_gBtn_Demo_DstR,DAT_00034a1c);
  _BgndToCompTransparent(_gBtn_Scores_SrcR,DAT_000349ec,_gBtn_Scores_DstR,DAT_00034a24);
  _BgndToCompTransparent(_gBtn_Prefs_SrcR,DAT_000349f4,_gBtn_Prefs_DstR,DAT_00034a2c);
  _BgndToCompTransparent(_gBtn_Credits_SrcR,DAT_000349fc,_gBtn_Credits_DstR,DAT_00034a34);
  _BgndToCompTransparent(_gBtn_Quit_SrcR,DAT_00034a04,_gBtn_Quit_DstR,DAT_00034a3c);
  if (_gIsGameRegistered == '\0') {
    _BgndToCompTransparent(_gBtn_Register_SrcR,DAT_00034a0c,_gBtn_Register_DstR,DAT_00034a44);
  }
  _DrawInterfaceText();
  _SetToScreen();
  return;
}


// ==== _ResumeGame @ 0000a28e ====

void _ResumeGame(void)

{
  undefined *puVar1;
  char cVar2;
  
  _gSuspended = 0;
  _gInfoTimer = _TickCount();
  _ScreenResume();
  _CheckEnvironment();
  puVar1 = PTR__environment_0003f028;
  if (PTR__environment_0003f028[0x26] == '\0') {
    _ShowWindow(*(undefined4 *)PTR__environment_0003f028);
  }
  _SetMyCCursor(200);
  if (puVar1[0x26] == '\0') {
    cVar2 = _IsOSX();
    if (cVar2 == '\0') {
      _HideGameMenuBar();
    }
  }
  _ResumeKeys();
  _ShowMyCursor();
  _RT3_Idle();
  if (_gIsGameRegistered == '\0') {
    _gIsGameRegistered = _RT3_IsRegistered();
    if (_gIsGameRegistered != '\0') {
      _DrawMainMenu();
      _UpdateScreen();
      _PlayMySnd(0xd,0x14,0);
    }
  }
  _SetToScreen();
  _UpdateScreen();
  return;
}


// ==== _RegisterButton @ 0000a341 ====

void _RegisterButton(void)

{
  char cVar1;
  char cVar2;
  
  cVar1 = PTR__environment_0003f028[0x26];
  if (cVar1 == '\0') {
    _GoWindowMode();
  }
  _PlayMySnd(0x13,10,0);
  cVar2 = _MusicPlaying();
  if (cVar2 != '\0') {
    _StopMusic();
  }
  _ASWReg_ShowDialogWithOptions();
  if (cVar1 == '\0') {
    _GoFullScreenMode();
  }
  _ResumeGame();
  _SetMyCCursor(200);
  _gInfoTimer = _TickCount();
  return;
}


// ==== _DoRegReminder @ 0000a3c1 ====

void _DoRegReminder(void)

{
  char cVar1;
  short local_1c;
  uint local_1a;
  
  if ((_gIsGameRegistered == '\0') && (cVar1 = _GameInForeground(), cVar1 != '\0')) {
    _ShowMyCursor();
    _SetToCompGWorld();
    _DrawAndCentrePict(0x238b);
    _SetToScreen();
    _WipeScreenOut(4);
    _FlushEvents(0xffff,0);
    do {
      while( true ) {
        do {
          cVar1 = _WaitNextEvent(0x800a,&local_1c,10,0);
        } while (cVar1 == '\0');
        if (local_1c == 3) {
          return;
        }
        if (local_1c != 0xf) break;
        if (local_1a >> 0x18 == 1) {
          if ((local_1a & 1) != 0) {
            _ResumeGame();
            return;
          }
          _SuspendGame();
        }
      }
    } while (local_1c != 1);
  }
  return;
}


// ==== _HandleMenuChoice @ 0000a482 ====

void _HandleMenuChoice(short param_1,short param_2)

{
  undefined *puVar1;
  char cVar2;
  short sVar3;
  code *pcVar4;
  int iVar5;
  int iVar6;
  undefined4 uVar7;
  undefined1 local_28 [8];
  int local_20;
  
  if (param_1 == 0x81) {
    if (param_2 == 1) {
      _gFinished = 1;
      _SaveGamePrefs();
      _DoRegReminder();
      _StopMusic();
      _CleanUp();
    }
  }
  else if (param_1 < 0x82) {
    if (param_1 == 0x80) {
      if (param_2 == 2) {
        _ASWReg_ShowDialogWithOptions();
      }
      else if (param_2 < 3) {
        if (param_2 == 1) {
          _SetMyCCursor(200);
          local_20 = 0;
          _ASWAboutBoxLoadPrivateFrameworkBundle();
          _ASWAboutBoxLoadPrivateFrameworkBundle();
          if ((local_20 != 0) &&
             (pcVar4 = (code *)_CFBundleGetFunctionPointerForName(local_20,&cf_show),
             pcVar4 != (code *)0x0)) {
            (*pcVar4)();
          }
        }
      }
      else if (param_2 == 4) {
        if (__aswSparkle == 0) {
          __aswSparkle = 0;
          iVar5 = _CFBundleGetMainBundle();
          if ((iVar5 != 0) && (iVar5 = _CFBundleCopyPrivateFrameworksURL(iVar5), iVar5 != 0)) {
            uVar7 = *(undefined4 *)PTR_0003f030;
            iVar6 = _CFURLCreateCopyAppendingPathComponent
                              (uVar7,iVar5,&cf_ASWCarbonSparkleBridge_bundle,0);
            if (iVar6 != 0) {
              __aswSparkle = _CFBundleCreate(uVar7,iVar6);
              if ((__aswSparkle != 0) &&
                 (cVar2 = _CFBundleLoadExecutable(__aswSparkle), cVar2 == '\0')) {
                _CFRelease(__aswSparkle);
                __aswSparkle = 0;
              }
              _CFRelease(iVar6);
            }
            _CFRelease(iVar5);
          }
          if (__aswSparkle == 0) {
            return;
          }
        }
        if ((__ASWSparkleCheckForUpdates == (code *)0x0) &&
           (__ASWSparkleCheckForUpdates =
                 (code *)_CFBundleGetFunctionPointerForName
                                   (__aswSparkle,&cf_checkForUpdatesAndNotify),
           __ASWSparkleCheckForUpdates == (code *)0x0)) {
          return;
        }
        (*__ASWSparkleCheckForUpdates)(1);
      }
      else if (param_2 == 6) {
        _PrefsButton();
      }
    }
  }
  else {
    if (param_1 == 0x83) {
      if (param_2 == 3) {
        sVar3 = _GetShortPref(0x33);
        if (sVar3 == 1) {
          sVar3 = _GetShortPref(0x34);
          _SetShortPref(0x33,(int)sVar3);
          uVar7 = 0x12;
        }
        else {
          _SetShortPref(0x33,1);
          uVar7 = 0;
        }
        _SetItemMark(_gOptionsMenu,3,uVar7);
        _UpdateSoundVol();
      }
      else if (param_2 == 4) {
        sVar3 = _GetShortPref(0x35);
        if (sVar3 == 1) {
          sVar3 = _GetShortPref(0x36);
          _SetShortPref(0x35,(int)sVar3);
          uVar7 = 0x12;
        }
        else {
          _SetShortPref(0x35,1);
          uVar7 = 0;
        }
        _SetItemMark(_gOptionsMenu,4,uVar7);
        _UpdateMusicStatus();
        _UpdateMusicVolume();
      }
      else {
        if (param_2 != 1) {
          return;
        }
        cVar2 = _GetBooleanPref(0x37);
        if (cVar2 == '\0') {
          _SetBooleanPref(0x37,1);
          uVar7 = 0x12;
        }
        else {
          _SetBooleanPref(0x37,0);
          uVar7 = 0;
        }
        _SetItemMark(_gOptionsMenu,1,uVar7);
        cVar2 = _GetBooleanPref(0x37);
        if (cVar2 == '\0') {
          cVar2 = _GoWindowMode();
        }
        else {
          cVar2 = _GoFullScreenMode();
        }
        if (cVar2 == '\0') {
          cVar2 = _GetBooleanPref(0x37);
          _SetBooleanPref(0x37,(uint)(cVar2 == '\0'));
          _SetItemMark(_gOptionsMenu,1,(int)((uint)(cVar2 == '\0') << 0x1f) >> 0x1f & 0x12);
        }
        puVar1 = PTR__environment_0003f028;
        uVar7 = _GetWindowPort(*(undefined4 *)PTR__environment_0003f028);
        _GetPortBounds(uVar7,local_28);
        _InvalWindowRect(*(undefined4 *)puVar1,local_28);
        if ((puVar1[0x26] == '\0') && (*PTR__gPlayGame_0003f03c == '\0')) {
          _HideGameMenuBar();
        }
        else {
          _ShowGameMenuBar();
        }
      }
    }
    else {
      if (param_1 != 0x8c) {
        return;
      }
      sVar3 = _GetShortPref(0x38);
      if (1 < sVar3) {
        sVar3 = sVar3 + 1;
      }
      _SetItemMark(_gKeySetsSubMenu,sVar3,0);
      if (2 < param_2) {
        param_2 = param_2 + -1;
      }
      _SetShortPref(0x38,(int)param_2);
      if (1 < param_2) {
        param_2 = param_2 + 1;
      }
      _InitControls();
      _SetItemMark(_gKeySetsSubMenu,param_2,0x12);
    }
    _SaveGamePrefs();
  }
  return;
}


// ==== _MenuHandler @ 0000a911 ====

int _MenuHandler(undefined4 param_1,undefined4 param_2)

{
  short sVar1;
  int iVar2;
  undefined1 local_1a [8];
  undefined4 local_12;
  short local_e;
  
  iVar2 = _GetEventClass(param_2);
  if ((iVar2 == 0x636d6473) && (iVar2 = _GetEventKind(param_2), iVar2 == 1)) {
    iVar2 = _GetEventParameter(param_2,0x2d2d2d2d,0x68636d64,0,0xe,0,local_1a);
    if (iVar2 != 0) {
      return iVar2;
    }
    sVar1 = _GetMenuID(local_12);
    _HandleMenuChoice((int)sVar1,(int)local_e);
    return 0;
  }
  return -0x2692;
}


// ==== _RequestGame @ 0000a9a1 ====

void _RequestGame(short param_1,char param_2)

{
  bool bVar1;
  char cVar2;
  
  bVar1 = 1 < param_1;
  _gPlayerIsCheating = bVar1;
  if (_doneOnce_74886 == '\0') {
    _Utils_Log("  Entering game request.");
  }
  _DisableMenuCommand(0,0x61626f75);
  if (_doneOnce_74886 == '\0') {
    _Utils_Log("  About menu item disabled.");
  }
  if (PTR__environment_0003f028[0x26] == '\0') {
    _HideGameMenuBar();
  }
  if (_doneOnce_74886 == '\0') {
    _Utils_Log("  Menu bar hidden if necessary.");
  }
  _UpdateScreen();
  if (_doneOnce_74886 == '\0') {
    _Utils_Log("  Screen updated.");
  }
  if (param_2 != '\x01') {
    _HideMyCursor();
  }
  if ((_doneOnce_74886 == '\0') &&
     (_Utils_Log("  Cursor hidden if not a demo."), _doneOnce_74886 == '\0')) {
    _Utils_Log("  About to send a play game request.");
  }
  _PlayGame((int)param_1,(int)param_2);
  if (_doneOnce_74886 == '\0') {
    _Utils_Log("  Play game request successful.");
  }
  _gHighScoresRequired = '\0';
  _ShowMyCursor();
  if (_doneOnce_74886 == '\0') {
    _Utils_Log("  Cursor shown.");
  }
  if ((((!bVar1) && (_gPlayerIsCheating == '\0')) && (param_2 == '\0')) &&
     (cVar2 = _CheckHiScore(), cVar2 != '\0')) {
    if (_doneOnce_74886 == '\0') {
      _Utils_Log("  Button graphics reloaded.");
    }
    _gHighScoresRequired = '\x01';
  }
  if (_doneOnce_74886 == '\0') {
    _Utils_Log("  Interface screen reloaded.");
  }
  if (_gFinished == '\0') {
    _gPlayerIsCheating = '\0';
    if (_gHighScoresRequired == '\0') {
      if (_doneOnce_74886 == '\0') {
        _Utils_Log("  Interface redraw flag cleared.");
      }
      if (PTR__environment_0003f028[0x26] == '\0') {
        _HideGameMenuBar();
      }
      _DrawMainMenu();
      _EnableMenuCommand(0,0x61626f75);
      _SetMyCCursor(200);
      _ShowMyCursor();
      _WipeScreen(0xc);
    }
    else {
      if (_doneOnce_74886 == '\0') {
        _Utils_Log("  Interface redraw flag set.");
      }
      _FlushEvents(0x3e,0);
      if (PTR__environment_0003f028[0x26] == '\0') {
        _HideGameMenuBar();
      }
      _DrawCompPattern();
      _EnableMenuCommand(0,0x61626f75);
      _UpdateScreen();
      _SetMyCCursor(200);
      _ShowMyCursor();
      _PlayMySnd(0x13,0x14,0);
      cVar2 = _DisplayHiScores();
      if (cVar2 != '\0') {
        _NewGameButton();
      }
      _DrawMainMenu();
      _WipeScreen(0xc);
      _FlushEvents(0x3e,0);
    }
  }
  *PTR__gGameMode_0003f038 = 0;
  if (_doneOnce_74886 == '\0') {
    _Utils_Log("  Game mode returned to normal.");
  }
  _doneOnce_74886 = 1;
  return;
}


// ==== _NewGameButton @ 0000ac76 ====

void _NewGameButton(void)

{
  char cVar1;
  
  if (_doneOnce_74822 == '\0') {
    _Utils_Log("*** About to start a new game. ***");
  }
  _PlayMySnd(0x24,0x14,0);
  if (_doneOnce_74822 == '\0') {
    _Utils_Log("New game sound played.");
  }
  _StopMusic();
  if (_doneOnce_74822 == '\0') {
    _Utils_Log("Music stopped.");
  }
  _UnloadMusic();
  if (_doneOnce_74822 == '\0') {
    _Utils_Log("Music unloaded.");
    if (_doneOnce_74822 == '\0') {
      _Utils_Log("\nAbout to request a new game.");
    }
  }
  _RequestGame(1,0);
  if (_doneOnce_74822 == '\0') {
    _Utils_Log("Game request completed.\n");
  }
  _ResetMenuStars();
  if (_doneOnce_74822 == '\0') {
    _Utils_Log("Menu stars reset.");
  }
  _LoadMusic(0);
  if (_doneOnce_74822 == '\0') {
    _Utils_Log("Title music re-loaded.");
  }
  cVar1 = _MusicPlaying();
  if ((cVar1 == '\0') && (_gSuspended == '\0')) {
    _StartMusic();
  }
  if (_doneOnce_74822 == '\0') {
    _Utils_Log("Title music restarted.");
    if (_doneOnce_74822 == '\0') {
      _Utils_Log("*** Game code successful. ***\n\n\n");
      _doneOnce_74822 = '\x01';
    }
  }
  return;
}


// ==== _ScoresButton @ 0000adb9 ====

void _ScoresButton(void)

{
  char cVar1;
  
  cVar1 = _IsMenuBarHidden();
  if ((cVar1 == '\0') && (PTR__environment_0003f028[0x26] == '\0')) {
    _HideGameMenuBar();
  }
  _UpdateScreen();
  cVar1 = _DisplayHiScores();
  if (cVar1 != '\0') {
    _NewGameButton();
  }
  _FlushEvents(0x3e,0);
  _DrawMainMenu();
  _WipeScreen(0xc);
  _ResetMenuStars();
  return;
}


// ==== _CreditsButton @ 0000ae16 ====

void _CreditsButton(void)

{
  char cVar1;
  ushort uVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  
  cVar1 = _IsControlKeyDown();
  if (cVar1 == '\0') {
    cVar1 = _IsOptionKeyDown();
    if (cVar1 == '\0') {
      cVar1 = _IsCommandKeyDown();
      if (cVar1 == '\0') {
        cVar1 = _IsShiftKeyDown();
        if (cVar1 == '\0') {
          uVar2 = 0;
          uVar3 = 0;
        }
        else {
          uVar2 = 4;
          uVar3 = 4;
        }
      }
      else {
        uVar2 = 3;
        uVar3 = 3;
      }
    }
    else {
      uVar2 = 2;
      uVar3 = 2;
    }
  }
  else {
    uVar2 = 1;
    uVar3 = 1;
  }
  cVar1 = _IsMenuBarHidden();
  if ((cVar1 == '\0') && (PTR__environment_0003f028[0x26] == '\0')) {
    _HideGameMenuBar();
  }
  _UpdateScreen();
  if (uVar2 == 2) {
    uVar4 = 0x28;
    goto LAB_0000af2b;
  }
  if (uVar2 < 3) {
    if (uVar2 == 1) {
      uVar4 = 0x26;
      goto LAB_0000af2b;
    }
  }
  else {
    if (uVar2 == 3) {
      uVar4 = 0x2c;
      goto LAB_0000af2b;
    }
    if (uVar2 == 4) {
      uVar4 = 0x27;
      goto LAB_0000af2b;
    }
  }
  uVar4 = 0x13;
LAB_0000af2b:
  _PlayMySnd(uVar4,0x14,0);
  cVar1 = _DisplayCredits(uVar3);
  if (cVar1 != '\0') {
    _NewGameButton();
  }
  _FlushEvents(0x3e,0);
  _DrawMainMenu();
  _WipeScreen(0xc);
  _ResetMenuStars();
  return;
}


// ==== _DemoButton @ 0000af71 ====

void _DemoButton(void)

{
  short sVar1;
  
  sVar1 = _GetFilmCounter();
  if (_doneOnce_74877 == '\0') {
    _Utils_Log("*** About to start a new game via demo mode. ***");
  }
  *PTR__gGameMode_0003f038 = 1;
  if (_doneOnce_74877 == '\0') {
    _Utils_Log("Game request about to be made for demo mode.");
  }
  _RequestGame((int)(short)(sVar1 + 1),1);
  if (_doneOnce_74877 == '\0') {
    _Utils_Log("Game request done, about to reset menu stars.");
  }
  _ResetMenuStars();
  if (_doneOnce_74877 == '\0') {
    _Utils_Log("*** End of new game code via demo mode. ***\n\n\n");
  }
  _doneOnce_74877 = 1;
  return;
}


// ==== _HandleMSMouse @ 0000b001 ====

void _HandleMSMouse(char param_1)

{
  bool bVar1;
  bool bVar2;
  undefined *puVar3;
  char cVar4;
  short sVar5;
  undefined1 uVar6;
  undefined4 local_34;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined1 local_20 [16];
  
  puVar3 = PTR__gEvent_00034084;
  sVar5 = _FindWindow(*(undefined4 *)(PTR__gEvent_00034084 + 10),local_20);
  if (sVar5 != 2) {
    if (sVar5 == 3) {
      if (param_1 == '\0') {
        return;
      }
      cVar4 = _IsOptionKeyDown();
      if (cVar4 != '\0') {
        local_24 = *(undefined4 *)(puVar3 + 10);
        _GlobalToLocal(&local_24);
        cVar4 = _PtInRect(local_24,PTR__gTextRect_00034080);
        if (cVar4 != '\0') {
          _PlayMySnd(0,10,0);
          _gMsgCounter = _GetRandomFast(3,0x21);
          return;
        }
      }
      cVar4 = _IsOptionKeyDown();
      if ((((cVar4 != '\0') || (cVar4 = _IsShiftKeyDown(), cVar4 != '\0')) ||
          (cVar4 = _IsCommandKeyDown(), cVar4 != '\0')) ||
         (cVar4 = _IsControlKeyDown(), cVar4 != '\0')) {
        local_24 = *(undefined4 *)(PTR__gEvent_00034084 + 10);
        _GlobalToLocal(&local_24);
        local_2c = _gLogoR;
        local_28 = DAT_000349d4;
        _InsetRect(&local_2c,5,5);
        cVar4 = _PtInRect(local_24,&local_2c);
        if (cVar4 != '\0') {
          _PlayMySnd(0x11,10,0);
          _CreditsButton();
          goto LAB_0000b165;
        }
      }
      local_24 = *(undefined4 *)(PTR__gEvent_00034084 + 10);
      _GlobalToLocal(&local_24);
      cVar4 = _PtInRect(local_24,&_gBtn_New_DstR);
      if (cVar4 == '\0') {
        cVar4 = _PtInRect(local_24,&_gBtn_Demo_DstR);
        if (cVar4 == '\0') {
          cVar4 = _PtInRect(local_24,&_gBtn_Scores_DstR);
          if (cVar4 == '\0') {
            cVar4 = _PtInRect(local_24,&_gBtn_Prefs_DstR);
            if (cVar4 == '\0') {
              cVar4 = _PtInRect(local_24,&_gBtn_Credits_DstR);
              if (cVar4 == '\0') {
                cVar4 = _PtInRect(local_24,&_gBtn_Quit_DstR);
                if (cVar4 == '\0') {
                  if (_gIsGameRegistered != '\0') {
                    return;
                  }
                  cVar4 = _PtInRect(local_24,&_gBtn_Register_DstR);
                  if (cVar4 == '\0') {
                    return;
                  }
                  uVar6 = 7;
                }
                else {
                  uVar6 = 6;
                }
              }
              else {
                uVar6 = 5;
              }
            }
            else {
              uVar6 = 4;
            }
          }
          else {
            uVar6 = 3;
          }
        }
        else {
          uVar6 = 2;
        }
      }
      else {
        uVar6 = 1;
      }
      _gInfoTimer = _TickCount();
      _PlayMySnd(0x11,10,0);
      switch(uVar6) {
      default:
        return;
      case 1:
        local_34 = _gBtn_New_DstR;
        local_30 = DAT_00034a14;
        break;
      case 2:
        local_34 = _gBtn_Demo_DstR;
        local_30 = DAT_00034a1c;
        break;
      case 3:
        local_34 = _gBtn_Scores_DstR;
        local_30 = DAT_00034a24;
        break;
      case 4:
        local_34 = _gBtn_Prefs_DstR;
        local_30 = DAT_00034a2c;
        break;
      case 5:
        local_34 = _gBtn_Credits_DstR;
        local_30 = DAT_00034a34;
        break;
      case 6:
        local_34 = _gBtn_Quit_DstR;
        local_30 = DAT_00034a3c;
        break;
      case 7:
        local_34 = _gBtn_Register_DstR;
        local_30 = DAT_00034a44;
      }
      _SetToBgndGWorld();
      _SetRect(&local_2c,0,0,300,300);
      _DrawPicture(_gMenuButtonsPict,&local_2c);
      _SetToScreen();
      puVar3 = PTR__environment_0003f028;
      bVar1 = false;
      bVar2 = true;
      do {
        _ProcessMenuStars();
        _GetMouse(&local_24);
        if (puVar3[0x26] == '\0') {
          local_24 = CONCAT22(local_24._2_2_ - *(short *)(puVar3 + 0x1a),
                              (short)local_24 - *(short *)(puVar3 + 0x1c));
        }
        cVar4 = _PtInRect(local_24,&local_34);
        if (cVar4 == '\0') {
          cVar4 = _PtInRect(local_24,&local_34);
          if (cVar4 == '\0') {
            if ((bVar1) || (bVar2)) {
              _DrawButton();
              bVar1 = false;
              goto LAB_0000b3f4;
            }
            bVar1 = false;
          }
        }
        else if ((!bVar1) || (bVar2)) {
          _DrawButton();
          bVar1 = true;
LAB_0000b3f4:
          bVar2 = false;
        }
        cVar4 = _StillDown();
        if (cVar4 == '\0') {
          _DrawButton();
          _ProcessMenuStars();
          _GetMouse(&local_24);
          if (PTR__environment_0003f028[0x26] == '\0') {
            local_24 = CONCAT22(local_24._2_2_ - *(short *)(PTR__environment_0003f028 + 0x1a),
                                (short)local_24 - *(short *)(PTR__environment_0003f028 + 0x1c));
          }
          cVar4 = _PtInRect(local_24,&local_34);
          if (cVar4 == '\0') {
            return;
          }
          switch(uVar6) {
          default:
            return;
          case 1:
            _NewGameButton();
            return;
          case 2:
            _DemoButton();
            return;
          case 3:
            goto switchD_0000b465_caseD_3;
          case 4:
            _PrefsButton();
            return;
          case 5:
            _CreditsButton();
            return;
          case 6:
            _gFinished = 1;
            return;
          case 7:
            if (_gIsGameRegistered != '\0') {
              return;
            }
            _RegisterButton();
            return;
          }
        }
      } while( true );
    }
    if (sVar5 != 1) {
      return;
    }
    _MenuSelect(*(undefined4 *)(puVar3 + 10));
  }
LAB_0000b165:
  _gInfoTimer = _TickCount();
  return;
switchD_0000b465_caseD_3:
  cVar4 = _IsOptionKeyDown();
  if (cVar4 != '\0') {
    cVar4 = _HiScoreEraseDialog();
    if (cVar4 == '\0') {
      return;
    }
    _PlayMySnd(0x27,10,0);
    _PlayMySnd(0x12,10,0);
    _LoadDefaultHiScores();
  }
  _ScoresButton();
  return;
}


// ==== _Interface @ 0000b500 ====

void _Interface(void)

{
  ushort uVar1;
  bool bVar2;
  undefined *puVar3;
  char cVar4;
  undefined4 uVar5;
  int iVar6;
  uint uVar7;
  short sVar8;
  undefined4 uVar9;
  int local_3c;
  uint local_30;
  undefined4 local_24;
  undefined1 local_20 [16];
  
  local_3c = _TickCount();
  _gBtn_Hit_Quit = 0;
  _gBtn_Hit_Credits = 0;
  _gBtn_Hit_Prefs = 0;
  _gBtn_Hit_Scores = 0;
  _gBtn_Hit_Demo = 0;
  _gBtn_Hit_New = 0;
  _Utils_Log("About to load credits information.");
  _RT3_Idle();
  _gIsGameRegistered = _RT3_IsRegistered();
  _Utils_Log("Credits information loaded.");
  _gMsgCounter = 0;
  _gInfoTimer = _TickCount();
  _FlushEvents(0x3e,0);
  _SetToScreen();
  _Utils_Log("Events flushed.");
  _ResetMenuStars();
  _Get0To6();
  _Get13To22();
  _Utils_Log("Menu stars reset.");
  if (PTR__environment_0003f028[0x26] == '\0') {
    _HideGameMenuBar();
  }
  _Utils_Log("Menu bar hidden if required.");
  _gMenuButtonsPict = _GetPicture(0x238c);
  if (_gMenuButtonsPict == 0) {
    _ResourceError(0x7d4,1,"PICT",0x238c);
  }
  _HNoPurge(_gMenuButtonsPict);
  _MoveHHi(_gMenuButtonsPict);
  _HLock(_gMenuButtonsPict);
  _gTitlePict = _GetPicture(0x2332);
  if (_gTitlePict == 0) {
    _ResourceError(0x7d4,1,"PICT",0x2332);
  }
  _HNoPurge(_gTitlePict);
  _MoveHHi(_gTitlePict);
  _HLock(_gTitlePict);
  _Utils_Log("Main menu graphics loaded.");
  _LoadMusic(0);
  _Utils_Log("Title music loaded.");
  _DrawMainMenu();
  _Utils_Log("Main menu drawn.");
  _CheckNumRecordings();
  _ShowMyCursor();
  _SetMyCCursor(200);
  _Utils_Log("About to reveal main screen with wipe.");
  _WipeScreen(6);
  _Utils_Log("Interface screen displayed.");
  _Utils_Log("Menu star rects zeroed.");
  cVar4 = _GameInForeground();
  if (cVar4 == '\0') {
    _Utils_Log("Application in background, suspending the game.");
    _SuspendGame();
  }
  else {
    _Utils_Log("Starting interface music, app still in foreground.");
    if (_gIsGameRegistered != '\0') {
      _StartMusic();
    }
  }
  _Utils_Log("*** Game loading completed successfully. ***\n\n\n");
  _SetToScreen();
  _CheckEnvironment();
  _UpdateScreen();
  uVar5 = _GetEventDispatcherTarget();
  bVar2 = false;
  local_30 = 0;
  do {
    while( true ) {
      while( true ) {
        if (_gFinished != '\0') {
          _DoRegReminder();
          _StopMusic();
          return;
        }
        if (_gSuspended == '\0') {
          _GetMouse(local_20);
        }
        if (*PTR__gDidToggleFullscreen_0003f040 != '\0') {
          *PTR__gDidToggleFullscreen_0003f040 = 0;
          iVar6 = _TickCount();
          local_30 = iVar6 + 10;
        }
        if ((local_30 != 0) && (uVar7 = _TickCount(), local_30 < uVar7)) {
          _SetToScreen();
          _DrawMainMenu();
          _UpdateScreen();
          _FlushIfNecessary();
          local_30 = 0;
        }
        if (_gSuspended == '\0') {
          if (_gMsgCounter < 4) {
            uVar7 = _TickCount();
            if (_gInfoTimer + 0xb4U < uVar7) {
              _gInfoTimer = _TickCount();
              puVar3 = PTR__gTextRect_00034080;
              _SpriteGWorldToCompGWorld
                        (*(undefined4 *)PTR__gSrcTextRect_0003407c,
                         *(undefined4 *)(PTR__gSrcTextRect_0003407c + 4),
                         *(undefined4 *)PTR__gTextRect_00034080,
                         *(undefined4 *)(PTR__gTextRect_00034080 + 4));
              _DrawInterfaceText();
              _SetToScreen();
              _CompToScreen(*(undefined4 *)puVar3,*(undefined4 *)(puVar3 + 4),
                            CONCAT22(*(short *)(PTR__environment_0003f028 + 0xc) +
                                     *(short *)(puVar3 + 2),
                                     *(short *)(PTR__environment_0003f028 + 10) + *(short *)puVar3),
                            CONCAT22(*(short *)(PTR__environment_0003f028 + 0xc) +
                                     *(short *)(puVar3 + 6),
                                     *(short *)(PTR__environment_0003f028 + 10) +
                                     *(short *)(puVar3 + 4)));
              sVar8 = _gMsgCounter + 1;
              _gMsgCounter = 0;
              if (sVar8 < 4) {
                _gMsgCounter = sVar8;
              }
            }
          }
          else {
            iVar6 = _TickCount();
            _gInfoTimer = iVar6 + 0x78;
            _DrawMainMenu();
            _UpdateScreen();
            _gMsgCounter = 0;
          }
        }
        if (_gDoPrefsNow != '\0') {
          _PrefsDialog();
          _gDoPrefsNow = '\0';
        }
        uVar7 = _TickCount();
        if ((local_3c + 0x4b0U < uVar7) && (_gSuspended == '\0')) {
          if (bVar2) {
            _FlashButton();
            _ScoresButton();
          }
          else {
            _FlashButton();
            _DemoButton();
          }
          bVar2 = (bool)(bVar2 ^ 1);
          local_3c = _TickCount();
        }
        cVar4 = _MusicPlaying();
        if ((cVar4 == '\0') && (_gSuspended == '\0')) {
          _StartMusic();
        }
        cVar4 = _MusicPaused();
        if ((cVar4 != '\0') && (cVar4 = _GameInForeground(), cVar4 != '\0')) {
          _ResumeMusic();
        }
        if (_gSuspended == '\0') {
          _ProcessMenuStars();
        }
        _SetMyCCursor(200);
        iVar6 = _ReceiveNextEvent(0,0,0x11111111,0x3fa11111,1,&local_24);
        if (iVar6 != 0) {
          *(undefined2 *)PTR__gEvent_00034084 = 0;
        }
        _SendEventToEventTarget(local_24,uVar5);
        puVar3 = PTR__gEvent_00034084;
        _ConvertEventRefToEventRecord(local_24,PTR__gEvent_00034084);
        _ReleaseEvent(local_24);
        iVar6 = _GetEventClass(local_24);
        if (iVar6 != 0x6170706c) break;
        iVar6 = _GetEventKind(local_24);
        if (iVar6 == 1) {
          local_3c = _TickCount();
          _ResumeGame();
        }
        else if (iVar6 == 2) {
          _SuspendGame();
        }
      }
      uVar1 = *(ushort *)puVar3;
      if (uVar1 == 3) break;
      if (uVar1 < 4) {
        if (uVar1 == 1) {
          _HandleMSMouse(1);
          local_3c = _TickCount();
        }
      }
      else {
        if (uVar1 == 5) break;
        if (uVar1 == 0x17) {
          _AEProcessAppleEvent(puVar3);
        }
      }
    }
    if ((PTR__gEvent_00034084[0xf] & 1) != 0) goto switchD_0000bab2_caseD_4;
    switch(PTR__gEvent_00034084[2]) {
    case 3:
    case 0xd:
    case 0x4e:
    case 0x6e:
      *PTR__gGameMode_0003f038 = 0;
      _PlayMySnd(0x11,10,0);
      _FlashButton();
      _NewGameButton();
      break;
    case 0x42:
    case 0x62:
      uVar9 = 0x2f;
      goto LAB_0000bcc6;
    case 0x43:
    case 99:
      *PTR__gGameMode_0003f038 = 0;
      _PlayMySnd(0x11,10,0);
      _FlashButton();
      _CreditsButton();
      break;
    case 0x44:
    case 100:
      _FlashButton();
      _DemoButton();
      break;
    case 0x4c:
    case 0x6c:
      *PTR__gGameMode_0003f038 = 0;
      _PlayMySnd(0x16,10,0);
      sVar8 = _DoLevelSelect();
      if (sVar8 != 0) {
        _PlayMySnd(0x24,0x14,0);
        _StopMusic();
        _UnloadMusic();
        _RequestGame((int)sVar8,0);
        _ResetMenuStars();
        _LoadMusic(0);
        cVar4 = _MusicPlaying();
        if (cVar4 == '\0') {
          _StartMusic();
        }
      }
      break;
    case 0x50:
    case 0x70:
      *PTR__gGameMode_0003f038 = 0;
      _PlayMySnd(0x11,10,0);
      _FlashButton();
      _PrefsButton();
      break;
    case 0x51:
    case 0x71:
      *PTR__gGameMode_0003f038 = 0;
      _PlayMySnd(0x11,10,0);
      _FlashButton();
      _gFinished = '\x01';
      break;
    case 0x52:
    case 0x72:
      if (_gIsGameRegistered == '\0') {
        *PTR__gGameMode_0003f038 = 0;
        _PlayMySnd(0x11,10,0);
        _FlashButton();
        _RegisterButton();
      }
      break;
    case 0x53:
    case 0x73:
      _FlashButton();
      _ScoresButton();
      break;
    case 0x57:
    case 0x77:
      uVar9 = 0x2e;
LAB_0000bcc6:
      _PlayMySnd(uVar9,0x1e,0);
      break;
    case 0x58:
    case 0x78:
      _DisplayPoem();
      break;
    case 0x5a:
    case 0x7a:
      _DisplayQuote();
    }
switchD_0000bab2_caseD_4:
    local_3c = _TickCount();
    _gInfoTimer = _TickCount();
  } while( true );
}


// ==== _DrawAndCentrePict @ 0000bd14 ====

void _DrawAndCentrePict(short param_1)

{
  int iVar1;
  short local_2c;
  short local_2a;
  short local_28;
  short local_26;
  short local_24;
  short local_22;
  short local_20;
  short local_1e;
  
  iVar1 = _GetPicture((int)param_1);
  if (iVar1 == 0) {
    _ResourceError(0x7d4,1,"PICT",(int)param_1);
  }
  _MoveHHi(iVar1);
  _HNoPurge(iVar1);
  _QDGetPictureBounds(iVar1,&local_2c);
  local_22 = (short)(((int)*(short *)(PTR__environment_0003f028 + 0x18) -
                     ((int)local_26 - (int)local_2a)) / 2);
  local_24 = (short)(((int)*(short *)(PTR__environment_0003f028 + 0x16) -
                     ((int)local_28 - (int)local_2c)) / 2);
  local_1e = local_22 + (short)((int)local_26 - (int)local_2a);
  local_20 = local_24 + (short)((int)local_28 - (int)local_2c);
  _DrawPicture(iVar1,&local_24);
  return;
}


// ==== _DrawAndCentrePictOnScreen @ 0000bdd1 ====

void _DrawAndCentrePictOnScreen(short param_1)

{
  int iVar1;
  undefined4 uVar2;
  short local_34;
  short local_32;
  short local_30;
  short local_2e;
  undefined1 local_2c [4];
  short local_28;
  short local_26;
  short local_24;
  short local_22;
  short local_20;
  short local_1e;
  
  iVar1 = _GetPicture((int)param_1);
  if (iVar1 == 0) {
    _ResourceError(0x7d4,1,"PICT",(int)param_1);
  }
  _MoveHHi(iVar1);
  _HNoPurge(iVar1);
  _QDGetPictureBounds(iVar1,&local_34);
  uVar2 = _GetWindowPort(*(undefined4 *)PTR__environment_0003f028);
  _GetPortBounds(uVar2,local_2c);
  local_22 = (short)(((int)local_26 - (int)(short)(local_2e - local_32)) / 2);
  local_24 = (short)(((int)local_28 - (int)(short)(local_30 - local_34)) / 2);
  local_1e = (local_2e - local_32) + local_22;
  local_20 = (local_30 - local_34) + local_24;
  _SetToScreen();
  _DrawPicture(iVar1,&local_24);
  _ReleaseResource(iVar1);
  _FlushIfNecessary();
  return;
}


// ==== _DrawPICTBasic @ 0000beba ====

void _DrawPICTBasic(short param_1)

{
  int iVar1;
  short local_1c;
  short local_1a;
  short local_18;
  short local_16;
  undefined2 local_14;
  undefined2 local_12;
  short local_10;
  short local_e;
  
  iVar1 = _GetPicture((int)param_1);
  if (iVar1 == 0) {
    _DeathAlert(6);
  }
  _HNoPurge(iVar1);
  _QDGetPictureBounds(iVar1,&local_1c);
  local_10 = local_18 - local_1c;
  local_e = local_16 - local_1a;
  local_12 = 0;
  local_14 = 0;
  _DrawPicture(iVar1,&local_14);
  _HPurge(iVar1);
  return;
}


// ==== _DrawPICTResource @ 0000bf3b ====

void _DrawPICTResource(short param_1)

{
  int iVar1;
  short local_1c;
  short local_1a;
  short local_18;
  short local_16;
  undefined2 local_14;
  undefined2 local_12;
  short local_10;
  short local_e;
  
  iVar1 = _GetPicture((int)param_1);
  if (iVar1 == 0) {
    _DeathAlert(6);
  }
  _HNoPurge(iVar1);
  _QDGetPictureBounds(iVar1,&local_1c);
  local_10 = local_18 - local_1c;
  local_e = local_16 - local_1a;
  local_12 = 0;
  local_14 = 0;
  _DrawPicture(iVar1,&local_14);
  _HPurge(iVar1);
  return;
}


// ==== _DrawPictInRect @ 0000bfbc ====

void _DrawPictInRect(short param_1)

{
  int iVar1;
  
  iVar1 = _GetResource(0x50494354,(int)param_1);
  if (iVar1 == 0) {
    _DeathAlert(6);
  }
  _MoveHHi(iVar1);
  _HLock(iVar1);
  _HNoPurge(iVar1);
  _DrawPicture(iVar1,&stack0x00000008);
  return;
}


// ==== _LoadPictInRect @ 0000c016 ====

bool _LoadPictInRect(undefined4 param_1,short param_2)

{
  int iVar1;
  
  _SetGWorld(param_1,0);
  iVar1 = _GetResource(0x50494354,(int)param_2);
  if (iVar1 != 0) {
    _HNoPurge(iVar1);
    _DrawPicture(iVar1,&stack0x0000000c);
    _HPurge(iVar1);
  }
  return iVar1 != 0;
}


// ==== _LoadPict @ 0000c078 ====

int _LoadPict(short param_1,undefined4 param_2)

{
  int iVar1;
  
  iVar1 = _GetPicture((int)param_1);
  if (iVar1 == 0) {
    _ResourceError(0x7d4,1,"PICT",(int)param_1);
  }
  _MoveHHi(iVar1);
  _HLock(iVar1);
  _QDGetPictureBounds(iVar1,param_2);
  return iVar1;
}


// ==== _DrawSecretPictInRect @ 0000c0da ====

void _DrawSecretPictInRect(short param_1)

{
  int iVar1;
  
  iVar1 = _GetResource(0x494d4147,(int)param_1);
  if (iVar1 == 0) {
    _ResourceError(0x7d4,1,"IMAG",(int)param_1);
  }
  _HNoPurge(iVar1);
  _HLock(iVar1);
  _DrawPicture(iVar1,&stack0x00000008);
  _HUnlock(iVar1);
  _HPurge(iVar1);
  return;
}


// ==== _ZoomAndShowWindow @ 0000c152 ====

void _ZoomAndShowWindow(void)

{
  _ShowWindow();
  return;
}


// ==== _IsScreenSaverOn @ 0000c15b ====

uint _IsScreenSaverOn(void)

{
  short sVar1;
  uint uVar2;
  uint local_10 [3];
  
  sVar1 = _Gestalt(0x53415652,local_10);
  if (sVar1 == 0) {
    uVar2 = local_10[0] >> 1 & 1;
  }
  else {
    uVar2 = 0;
  }
  return uVar2;
}


// ==== _IsExpiryDateOk @ 0000c187 ====

bool _IsExpiryDateOk(void)

{
  undefined1 local_30 [14];
  undefined2 local_22;
  undefined2 local_20;
  undefined2 local_1e;
  undefined2 local_1c;
  undefined2 local_1a;
  undefined2 local_18;
  undefined2 local_16;
  uint local_14;
  uint local_10 [2];
  
  local_22 = 0x7cc;
  local_20 = 0xb;
  local_1e = 2;
  local_1c = 0;
  local_1a = 0;
  local_18 = 0;
  local_16 = 0;
  _DateToSeconds(&local_22,local_10);
  _GetTime(local_30);
  _DateToSeconds(local_30,&local_14);
  return local_14 <= local_10[0];
}


// ==== _Interface_GetOccasions @ 0000c1f6 ====

undefined4 _Interface_GetOccasions(void)

{
  undefined1 local_1a [2];
  short local_18;
  short local_16;
  
  _GetTime(local_1a);
  if (local_18 == 0xc) {
    if (local_16 == 0x18) {
      return 1;
    }
    if (local_16 == 0x19) {
      return 2;
    }
    if (local_16 == 0x1f) {
      return 5;
    }
  }
  else if (local_18 == 1) {
    if (local_16 == 0x14) {
      return 3;
    }
    if (local_16 == 1) {
      return 6;
    }
  }
  else if (local_18 == 9) {
    if (local_16 == 0x11) {
      return 4;
    }
  }
  else if ((local_18 == 10) && (local_16 == 0x1f)) {
    return 7;
  }
  return 0;
}


// ==== _NewDynamicArray_UnsignedChar @ 0000c28c ====

int * _NewDynamicArray_UnsignedChar(int param_1,int param_2)

{
  int *piVar1;
  int *piVar2;
  int iVar3;
  
  piVar2 = (int *)_NewPtrClear(param_1 * 4);
  iVar3 = _NewPtrClear(param_1 * param_2);
  *piVar2 = iVar3;
  piVar1 = piVar2;
  for (iVar3 = 1; iVar3 < param_1; iVar3 = iVar3 + 1) {
    piVar1[1] = param_2 + *piVar1;
    piVar1 = piVar1 + 1;
  }
  return piVar2;
}


// ==== _KillDynamicArray_UnsignedChar @ 0000c2e0 ====

void _KillDynamicArray_UnsignedChar(int *param_1)

{
  if (param_1 != (int *)0x0) {
    if (*param_1 != 0) {
      _DisposePtr(*param_1);
    }
    _DisposePtr();
    return;
  }
  return;
}


// ==== _SaveScreen @ 0000c30f ====

void _SaveScreen(void)

{
  return;
}


// ==== _IsMachineAPowerMac @ 0000c314 ====

undefined4 _IsMachineAPowerMac(void)

{
  short sVar1;
  undefined4 uVar2;
  uint local_10 [3];
  
  sVar1 = _Gestalt(0x63707574,local_10);
  if ((sVar1 == 0) && ((4 < local_10[0] || ((1 << ((byte)local_10[0] & 0x1f) & 0x1dU) == 0)))) {
    uVar2 = 1;
  }
  else {
    uVar2 = 0;
  }
  return uVar2;
}


// ==== _IsCorrectSndManagerAvail @ 0000c351 ====

bool _IsCorrectSndManagerAvail(void)

{
  uint uVar1;
  
  uVar1 = _SndSoundManagerVersion();
  return 0x32fffff < uVar1;
}


// ==== _IsVMActive @ 0000c369 ====

undefined4 _IsVMActive(void)

{
  short sVar1;
  undefined4 uVar2;
  byte local_10 [12];
  
  sVar1 = _Gestalt(0x766d2020,local_10);
  if ((sVar1 == 0) && ((local_10[0] & 1) != 0)) {
    uVar2 = 1;
  }
  else {
    uVar2 = 0;
  }
  return uVar2;
}


// ==== _RectsCollide @ 0000c398 ====

undefined4 _RectsCollide(short *param_1,short *param_2)

{
  undefined4 uVar1;
  
  if ((((param_1[1] < param_2[3]) && (param_2[1] < param_1[3])) && (*param_1 < param_2[2])) &&
     (*param_2 < param_1[2])) {
    uVar1 = 1;
  }
  else {
    uVar1 = 0;
  }
  return uVar1;
}


// ==== _MyOffsetRect @ 0000c3d2 ====

void _MyOffsetRect(short *param_1,short param_2,short param_3)

{
  param_1[1] = param_1[1] + param_2;
  param_1[3] = param_1[3] + param_2;
  *param_1 = *param_1 + param_3;
  param_1[2] = param_1[2] + param_3;
  return;
}


// ==== _MyInsetRect @ 0000c3f1 ====

void _MyInsetRect(short *param_1,short param_2,short param_3)

{
  param_1[1] = param_1[1] + param_2;
  param_1[3] = param_1[3] - param_2;
  *param_1 = *param_1 + param_3;
  param_1[2] = param_1[2] - param_3;
  return;
}


// ==== _MyUnionRect @ 0000c410 ====

void _MyUnionRect(short *param_1,short *param_2,short *param_3)

{
  short sVar1;
  
  if (param_1[1] < param_2[1]) {
    param_3[1] = param_1[1];
    sVar1 = param_2[3];
  }
  else {
    param_3[1] = param_2[1];
    sVar1 = param_1[3];
  }
  param_3[3] = sVar1;
  if (*param_1 < *param_2) {
    *param_3 = *param_1;
    sVar1 = param_2[2];
  }
  else {
    *param_3 = *param_2;
    sVar1 = param_1[2];
  }
  param_3[2] = sVar1;
  return;
}


// ==== _ScramblePassword @ 0000c464 ====

void _ScramblePassword(byte *param_1,short param_2)

{
  byte *pbVar1;
  
  pbVar1 = param_1 + param_2;
  for (; param_1 < pbVar1; param_1 = param_1 + 1) {
    *param_1 = ~(*param_1 << 4 | *param_1 >> 4);
  }
  return;
}


// ==== _SetMouse @ 0000c486 ====

void _SetMouse(undefined4 param_1)

{
  _LocalToGlobal(&param_1);
  _CGWarpMouseCursorPosition((float)(int)param_1._2_2_,(float)(int)(short)param_1);
  return;
}


// ==== _GetRandomFast @ 0000c4cc ====

uint _GetRandomFast(ushort param_1,ushort param_2)

{
  uint uVar1;
  
  uVar1 = _Random();
  uVar1 = (((uint)param_2 - (uint)param_1) + 1) * (uVar1 & 0xffff);
  if (0x7fffffff < uVar1) {
    uVar1 = uVar1 + 0xffff;
  }
  return (uint)param_1 + ((int)uVar1 >> 0x10) & 0xffff;
}


// ==== _WasMouseClicked @ 0000c505 ====

undefined4 _WasMouseClicked(void)

{
  char cVar1;
  undefined4 uVar2;
  short local_1c [12];
  
  cVar1 = _WaitNextEvent(0xffff,local_1c,10,0);
  if ((cVar1 == '\0') || (local_1c[0] != 1)) {
    uVar2 = 0;
  }
  else {
    uVar2 = 1;
  }
  return uVar2;
}


// ==== _WaitUntilKeyOrMousePress @ 0000c544 ====

void _WaitUntilKeyOrMousePress(void)

{
  char cVar1;
  short local_1c;
  uint local_1a;
  
  _FlushEvents(0x3e,0);
  while( true ) {
    do {
      cVar1 = _WaitNextEvent(0x800a,&local_1c,10,0);
    } while (cVar1 == '\0');
    if (local_1c == 3) break;
    if (local_1c == 0xf) {
      if (local_1a >> 0x18 == 1) {
        if ((local_1a & 1) == 0) {
          _SuspendGame();
        }
        else {
          _ResumeGame();
        }
      }
    }
    else if (local_1c == 1) {
      return;
    }
  }
  return;
}


// ==== _GameInForeground @ 0000c5c4 ====

undefined1 _GameInForeground(void)

{
  undefined1 local_1e [8];
  undefined1 local_16 [9];
  undefined1 local_d;
  
  local_d = 1;
  _GetFrontProcess(local_1e);
  _GetCurrentProcess(local_16);
  _SameProcess(local_1e,local_16,&local_d);
  return local_d;
}


// ==== _WaitFor @ 0000c604 ====

void _WaitFor(short param_1)

{
  int iVar1;
  uint uVar2;
  
  iVar1 = _TickCount();
  do {
    uVar2 = _TickCount();
  } while (uVar2 < (uint)(iVar1 + param_1));
  return;
}


// ==== _WaitAndProcessEvents @ 0000c626 ====

void _WaitAndProcessEvents(short param_1)

{
  int iVar1;
  uint uVar2;
  undefined1 local_1c [16];
  
  iVar1 = _TickCount();
  while( true ) {
    uVar2 = _TickCount();
    if ((uint)(iVar1 + param_1) <= uVar2) break;
    _WaitNextEvent(0xffff,local_1c,10,0);
  }
  return;
}


// ==== _SetOrigMenuBarHeight @ 0000c66f ====

void _SetOrigMenuBarHeight(void)

{
  undefined2 uVar1;
  
  uVar1 = _GetMBarHeight();
  *(undefined2 *)PTR__gOrigMenuBarHeight_00034098 = uVar1;
  return;
}


// ==== _GetOrigMenuBarHeight @ 0000c685 ====

int _GetOrigMenuBarHeight(void)

{
  return (int)*(short *)PTR__gOrigMenuBarHeight_00034098;
}


// ==== _HideGameMenuBar @ 0000c692 ====

void _HideGameMenuBar(void)

{
  return;
}


// ==== _ShowGameMenuBar @ 0000c697 ====

void _ShowGameMenuBar(void)

{
  return;
}


// ==== _IsMenuBarHidden @ 0000c69c ====

undefined1 _IsMenuBarHidden(void)

{
  return _gMenuBarHidden;
}


// ==== _HideMyCursor @ 0000c6a8 ====

void _HideMyCursor(void)

{
  undefined4 uVar1;
  
  if (_gCursorVisible != '\0') {
    uVar1 = _CGMainDisplayID();
    _CGDisplayHideCursor(uVar1);
    _gCursorVisible = '\0';
  }
  return;
}


// ==== _ShowMyCursor @ 0000c6cd ====

void _ShowMyCursor(void)

{
  undefined4 uVar1;
  
  if (_gCursorVisible == '\0') {
    uVar1 = _CGMainDisplayID();
    _CGDisplayShowCursor(uVar1);
    _gCursorVisible = '\x01';
  }
  return;
}


// ==== _DeathAlert @ 0000c6f2 ====

void _DeathAlert(short param_1)

{
  undefined1 local_10c [260];
  
  _InitCursor();
  _ShowMyCursor();
  _UnFade();
  _GetIndString(local_10c,0x80,(int)param_1);
  _ParamText(local_10c,0,0,0);
  _StopAlert(0x81,0);
  _CleanUp();
  _ExitToShell();
  return;
}


// ==== _WatchCursor @ 0000c770 ====

void _WatchCursor(void)

{
  undefined4 *puVar1;
  
  puVar1 = (undefined4 *)_GetCursor(4);
  _SetCursor(*puVar1);
  return;
}


// ==== _DoBirthdaysCheck @ 0000c78e ====

void _DoBirthdaysCheck(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  undefined1 local_22 [2];
  short local_20;
  short local_1e;
  undefined4 local_14;
  short local_e;
  
  _GetTime(local_22);
  if (local_20 == 1) {
    if (local_1e != 0x14) {
      return;
    }
    uVar1 = 3000;
  }
  else {
    if (local_20 != 9) {
      return;
    }
    if (local_1e != 0x11) {
      return;
    }
    uVar1 = 0xbb9;
  }
  uVar1 = _GetNewDialog(uVar1,0,0xffffffff);
  _GetPort(&local_14);
  uVar2 = _GetDialogWindow(uVar1);
  uVar2 = _GetWindowPort(uVar2);
  _SetPort(uVar2);
  _SetDialogDefaultItem(uVar1,1);
  uVar2 = _GetDialogWindow(uVar1);
  _ShowWindow(uVar2);
  _InitCursor();
  do {
    _ModalDialog(0,&local_e);
  } while (local_e != 1);
  _WatchCursor();
  _SetPort(local_14);
  _DisposeDialog(uVar1);
  return;
}


// ==== _Bit_test @ 0000c872 ====

uint _Bit_test(int param_1,uint param_2)

{
  uint uVar1;
  
  uVar1 = param_2;
  if ((int)param_2 < 0) {
    uVar1 = param_2 + 7;
  }
  param_2 = param_2 & 0x80000007;
  if ((int)param_2 < 0) {
    param_2 = (param_2 - 1 | 0xfffffff8) + 1;
  }
  return (int)*(char *)(((int)uVar1 >> 3) + param_1) >> ((byte)param_2 & 0x1f) & 1;
}


// ==== _IsEscapeKeyDown @ 0000c8a3 ====

bool _IsEscapeKeyDown(void)

{
  char cVar1;
  
  cVar1 = _GameKeyDown(0x35);
  return cVar1 != '\0';
}


// ==== _IsOptionKeyDown @ 0000c8bf ====

uint _IsOptionKeyDown(void)

{
  uint uVar1;
  
  uVar1 = _GetCurrentKeyModifiers();
  return uVar1 >> 0xb & 1;
}


// ==== _IsCommandKeyDown @ 0000c8d2 ====

uint _IsCommandKeyDown(void)

{
  uint uVar1;
  
  uVar1 = _GetCurrentKeyModifiers();
  return uVar1 >> 8 & 1;
}


// ==== _IsShiftKeyDown @ 0000c8e5 ====

uint _IsShiftKeyDown(void)

{
  uint uVar1;
  
  uVar1 = _GetCurrentKeyModifiers();
  return uVar1 >> 9 & 1;
}


// ==== _IsControlKeyDown @ 0000c8f8 ====

uint _IsControlKeyDown(void)

{
  uint uVar1;
  
  uVar1 = _GetCurrentKeyModifiers();
  return uVar1 >> 0xc & 1;
}


// ==== _FlushIfNecessarySpecificPort @ 0000c90b ====

void _FlushIfNecessarySpecificPort(undefined4 param_1)

{
  short sVar1;
  char *pcVar2;
  byte local_10 [12];
  
  pcVar2 = PTR__gDoubleBuffered_0003409c;
  if (_gCheckedDoubleBuffered == '\0') {
    sVar1 = _Gestalt(0x77696e64,local_10);
    pcVar2 = PTR__gDoubleBuffered_0003409c;
    if (sVar1 == 0) {
      *PTR__gDoubleBuffered_0003409c = local_10[0] & 8;
    }
    else {
      *PTR__gDoubleBuffered_0003409c = 0;
    }
    _gCheckedDoubleBuffered = '\x01';
  }
  if (*pcVar2 != '\0') {
    _QDFlushPortBuffer(param_1,0);
  }
  return;
}


// ==== _FlushIfNecessary @ 0000c974 ====

void _FlushIfNecessary(void)

{
  short sVar1;
  undefined4 uVar2;
  char *pcVar3;
  byte local_10 [12];
  
  pcVar3 = PTR__gDoubleBuffered_0003409c;
  if (_gCheckedDoubleBuffered == '\0') {
    sVar1 = _Gestalt(0x77696e64,local_10);
    pcVar3 = PTR__gDoubleBuffered_0003409c;
    if (sVar1 == 0) {
      *PTR__gDoubleBuffered_0003409c = local_10[0] & 8;
    }
    else {
      *PTR__gDoubleBuffered_0003409c = 0;
    }
    _gCheckedDoubleBuffered = '\x01';
  }
  if (*pcVar3 != '\0') {
    uVar2 = _GetWindowPort(*(undefined4 *)PTR__environment_0003f028);
    _QDFlushPortBuffer(uVar2,0);
  }
  return;
}


// ==== _GetRectRsrc @ 0000c9e9 ====

void _GetRectRsrc(short param_1,undefined2 *param_2)

{
  int *piVar1;
  
  piVar1 = (int *)_GetResource(0x52656374,(int)param_1);
  param_2[1] = *(undefined2 *)*piVar1;
  *param_2 = *(undefined2 *)(*piVar1 + 2);
  param_2[3] = *(undefined2 *)(*piVar1 + 4);
  param_2[2] = *(undefined2 *)(*piVar1 + 6);
  _ReleaseResource();
  return;
}


// ==== _RunningInAqua @ 0000ca3a ====

byte _RunningInAqua(void)

{
  short sVar1;
  byte local_10 [12];
  
  sVar1 = _Gestalt(0x6d656e75,local_10);
  if (sVar1 == 0) {
    local_10[0] = local_10[0] & 2;
  }
  else {
    local_10[0] = 0;
  }
  return local_10[0];
}


// ==== _IsOSX @ 0000ca65 ====

undefined1 _IsOSX(void)

{
  short sVar1;
  undefined *puVar2;
  ushort local_10 [6];
  
  puVar2 = PTR__gIsOSX_00034094;
  if (_gCheckedIsOSX == '\0') {
    sVar1 = _Gestalt(0x73797376,local_10);
    if (sVar1 != 0) {
      _StdError("Cannot check system version with Gestalt.",(int)sVar1);
    }
    puVar2 = PTR__gIsOSX_00034094;
    *PTR__gIsOSX_00034094 = 0xa00 < local_10[0];
    _gCheckedIsOSX = '\x01';
  }
  return *puVar2;
}


// ==== _SetChicagoTwelve @ 0000cac3 ====

void _SetChicagoTwelve(void)

{
  char cVar1;
  short local_e [5];
  
  cVar1 = _IsOSX();
  if (cVar1 == '\0') {
    _GetFNum("\aChicago",local_e);
  }
  else {
    local_e[0] = _FMGetFontFamilyFromName("\aChicago");
  }
  _TextFont((int)local_e[0]);
  _TextSize(0xc);
  return;
}


// ==== _SetGenevaNine @ 0000cb11 ====

void _SetGenevaNine(void)

{
  char cVar1;
  short local_e [5];
  
  cVar1 = _IsOSX();
  if (cVar1 == '\0') {
    _GetFNum("\x06Geneva",local_e);
  }
  else {
    local_e[0] = _FMGetFontFamilyFromName("\x06Geneva");
  }
  _TextFont((int)local_e[0]);
  _TextSize(9);
  return;
}


// ==== _IsDoubleBuffered @ 0000cb5f ====

undefined1 _IsDoubleBuffered(void)

{
  undefined1 uVar1;
  
  uVar1 = _IsOSX();
  return uVar1;
}


// ==== _RunningUnderClassic @ 0000cb6f ====

undefined4 _RunningUnderClassic(void)

{
  short sVar1;
  undefined4 uVar2;
  byte local_10 [12];
  
  sVar1 = _Gestalt(0x62626f78,local_10);
  if ((sVar1 == 0) && ((local_10[0] & 1) != 0)) {
    uVar2 = 1;
  }
  else {
    uVar2 = 0;
  }
  return uVar2;
}


// ==== _CarbonVersionOkay @ 0000cba1 ====

bool _CarbonVersionOkay(void)

{
  short sVar1;
  int local_10 [3];
  
  sVar1 = _Gestalt(0x63626f6e,local_10);
  return sVar1 == 0 && 0x103 < local_10[0];
}


// ==== _FillScreenBlack @ 0000cbd1 ====

void _FillScreenBlack(void)

{
  undefined4 uVar1;
  
  uVar1 = _NewPtr(8);
  uVar1 = _GetQDGlobalsBlack(uVar1);
  _FillRect(PTR__environment_0003f028 + 0x12,uVar1);
  _DisposePtr(uVar1);
  return;
}


// ==== _PreloadBackgrounds @ 0000cc10 ====

void _PreloadBackgrounds(void)

{
  int iVar1;
  int iVar2;
  
  iVar1 = _GetPicture(0x390);
  if (iVar1 == 0) {
    _StdError("Cannot load title screen background picture. May need QuickTime update (for JPEGs)?",
              0x390);
  }
  _MoveHHi(iVar1);
  _HLock(iVar1);
  iVar1 = _GetPicture(0x238b);
  if (iVar1 == 0) {
    _StdError("Cannot load reg screen background picture. May need QuickTime update (for JPEGs)?",
              0x390);
  }
  _MoveHHi(iVar1);
  _HLock(iVar1);
  iVar1 = 0;
  do {
    iVar2 = _GetPicture(iVar1 + 13000);
    if (iVar2 == 0) {
      _StdError("Cannot load level background picture. May need QuickTime update (for JPEGs)?",iVar1
               );
    }
    _MoveHHi(iVar2);
    _HLock(iVar2);
    iVar1 = iVar1 + 1;
  } while (iVar1 != 6);
  return;
}


// ==== _Get0To6 @ 0000ccc9 ====

uint _Get0To6(void)

{
  uint uVar1;
  
  if (_val_74130 == 99) {
    uVar1 = _GetRandomFast(0,6);
    _val_74130 = uVar1 & 0xffff;
  }
  return _val_74130;
}


// ==== _Get13To22 @ 0000ccfb ====

uint _Get13To22(void)

{
  uint uVar1;
  
  if (_val_74138 == 99) {
    uVar1 = _GetRandomFast(0xd,0x16);
    _val_74138 = uVar1 & 0xffff;
  }
  return _val_74138;
}


// ==== _EditorRunning @ 0000cd2d ====

undefined4 _EditorRunning(void)

{
  short sVar1;
  undefined4 local_50;
  undefined4 local_4c;
  int local_3c;
  undefined4 local_18;
  undefined4 local_14;
  undefined4 local_10;
  
  local_14 = 0;
  local_10 = 0;
  sVar1 = _GetNextProcess(&local_14);
  if (sVar1 == 0) {
    do {
      local_4c = 0;
      local_18 = 0;
      local_50 = 0x3c;
      sVar1 = _GetProcessInformation(&local_14,&local_50);
      if (sVar1 != 0) {
        return 0;
      }
      if (local_3c == 0x42746544) {
        return 1;
      }
      sVar1 = _GetNextProcess(&local_14);
    } while (sVar1 == 0);
  }
  return 0;
}


// ==== _DrawTestLetter @ 0000cda2 ====

void _DrawTestLetter(void)

{
  undefined1 local_20 [16];
  
  _PatternFillCompGWorld(0x390);
  _DrawLetter(0x58,100,100,local_20,0);
  _CompToScreen(0,0x28001e0,0,0x28001e0);
  _Delay(10,local_20);
  return;
}


// ==== _DisplayPoem @ 0000ce2b ====

void _DisplayPoem(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  uVar1 = _GetNewDialog(0x122,0,0xffffffff);
  _SetToScreen();
  uVar2 = _GetDialogWindow(uVar1);
  uVar2 = _GetWindowPort(uVar2);
  _SetPort(uVar2);
  uVar2 = _GetDialogWindow(uVar1);
  _ShowWindow(uVar2);
  _DrawDialog(uVar1);
  uVar2 = _GetDialogWindow(uVar1);
  uVar2 = _GetWindowPort(uVar2);
  _FlushIfNecessarySpecificPort(uVar2);
  _WaitUntilKeyOrMousePress();
  _DisposeDialog(uVar1);
  _SetToScreen();
  return;
}


// ==== _DisplayQuote @ 0000ceb4 ====

void _DisplayQuote(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  _StopMusic();
  uVar1 = _GetNewDialog(0x123,0,0xffffffff);
  _SetToScreen();
  uVar2 = _GetDialogWindow(uVar1);
  uVar2 = _GetWindowPort(uVar2);
  _SetPort(uVar2);
  uVar2 = _GetDialogWindow(uVar1);
  _ShowWindow(uVar2);
  _DrawDialog(uVar1);
  uVar2 = _GetDialogWindow(uVar1);
  uVar2 = _GetWindowPort(uVar2);
  _FlushIfNecessarySpecificPort(uVar2);
  _WaitUntilKeyOrMousePress();
  _DisposeDialog(uVar1);
  _SetToScreen();
  _ResumeMusic();
  return;
}


// ==== _IsSaveScreenKeyDown @ 0000cf47 ====

byte _IsSaveScreenKeyDown(void)

{
  undefined1 local_1c [6];
  char local_16;
  
  _GetKeys(local_1c);
  return local_16 >> 2 & 1;
}


// ==== _InitPrefsDialog @ 0000cf64 ====

void _InitPrefsDialog(void)

{
  undefined *puVar1;
  int iVar2;
  int iVar3;
  int *piVar4;
  
  iVar2 = _NewPtr(0x800);
  *(int *)PTR__gSavedPrefsData_000340a8 = iVar2;
  if (iVar2 == 0) {
    _OutOfMemory("InitPrefsDialog, Dialogs.c");
  }
  puVar1 = PTR__gWhichPrefs_000340ac;
  iVar2 = 1000;
  piVar4 = (int *)PTR__gPrefsIcons_000340a4;
  do {
    iVar3 = _GetCIcon(iVar2);
    *piVar4 = iVar3;
    if (iVar3 == 0) {
      _StdError("Can\'t load cicn for display in prefs dialog.",*(short *)puVar1 + 999);
    }
    _MoveHHi(*piVar4);
    _HLock(*piVar4);
    iVar2 = iVar2 + 1;
    piVar4 = piVar4 + 1;
  } while (iVar2 != 0x3eb);
  return;
}


// ==== _CheckQDOverride @ 0000cff2 ====

void _CheckQDOverride(void)

{
  char cVar1;
  
  cVar1 = _GameKeyDown(0x38);
  if (cVar1 != '\0') {
    _SetShortPref(0x39,1);
    _SetBooleanPref(0x37,0);
    _SetBooleanPref(0x3f,0);
    _SaveGamePrefs();
    _NoteAlert(0x780,0);
  }
  return;
}


// ==== _RememberPrefsData @ 0000d05f ====

void _RememberPrefsData(void)

{
  _memmove(*(void **)PTR__gSavedPrefsData_000340a8,*(void **)PTR__gPrefsData_0003f044,0x800);
  return;
}


// ==== _upperChar @ 0000d089 ====

int _upperChar(char param_1)

{
  if ((byte)(param_1 + 0x9fU) < 0x1a) {
    param_1 = param_1 + -0x20;
  }
  return (int)param_1;
}


// ==== _MouseInWhichPrefsItem @ 0000d0a1 ====

int _MouseInWhichPrefsItem(undefined4 param_1)

{
  char cVar1;
  short sVar2;
  int iVar3;
  short sVar4;
  undefined1 local_30 [8];
  undefined1 local_28 [6];
  undefined4 local_22;
  undefined1 local_1e [14];
  
  if (_firstTime_73946 == '\0') {
    _GetMouse(&local_22);
    sVar2 = _CountDITL(param_1);
    for (sVar4 = 1; sVar4 <= sVar2; sVar4 = sVar4 + 1) {
      _GetDialogItem(param_1,(int)sVar4,local_1e,local_28,local_30);
      cVar1 = _PtInRect(local_22,local_30);
      if (cVar1 != '\0') {
        return (int)sVar4;
      }
    }
    iVar3 = 0;
  }
  else {
    _firstTime_73946 = '\0';
    iVar3 = 0x18;
  }
  return iVar3;
}


// ==== _GetItemRect @ 0000d131 ====

void _GetItemRect(undefined4 param_1,short param_2,undefined4 param_3)

{
  undefined1 local_14 [6];
  undefined1 local_e [10];
  
  _GetDialogItem(param_1,(int)param_2,local_e,local_14,param_3);
  return;
}


// ==== _UnhiliteCurrentPrefsArea @ 0000d161 ====

void _UnhiliteCurrentPrefsArea(void)

{
  return;
}


// ==== _SetEditableTextItem @ 0000d166 ====

void _SetEditableTextItem(undefined4 param_1,short param_2,undefined4 param_3)

{
  undefined1 local_11c [256];
  undefined1 local_1c [8];
  undefined4 local_14;
  undefined1 local_e [2];
  
  _CopyCStringToPascal(param_3,local_11c);
  _GetDialogItem(param_1,(int)param_2,local_e,&local_14,local_1c);
  _SetDialogItemText(local_14,local_11c);
  return;
}


// ==== _CheckPrefsHelp @ 0000d1c7 ====

void _CheckPrefsHelp(undefined4 param_1)

{
  undefined *puVar1;
  short sVar2;
  short sVar3;
  undefined1 local_21c [256];
  undefined1 local_11c [268];
  
  sVar2 = _MouseInWhichPrefsItem(param_1);
  if (sVar2 != 0) {
    if (sVar2 < 0x1a) {
      _GetIndString(local_11c,0x87,(int)sVar2);
      sVar3 = 0x87;
    }
    else {
      sVar3 = *(short *)PTR__gWhichPrefs_000340ac + 0x83;
      sVar2 = sVar2 + -0x19;
      _GetIndString(local_11c,(int)sVar3,(int)sVar2);
    }
    puVar1 = PTR__gLastHelpInfo_000340b4;
    if ((sVar3 != *(short *)PTR__gLastHelpInfo_000340b4) ||
       (sVar2 != *(short *)(PTR__gLastHelpInfo_000340b4 + 2))) {
      *(short *)PTR__gLastHelpInfo_000340b4 = sVar3;
      *(short *)(puVar1 + 2) = sVar2;
      _CopyPascalStringToC(local_11c,local_21c);
      puVar1 = PTR__gDoingPrefsHelp_000340b8;
      *PTR__gDoingPrefsHelp_000340b8 = 1;
      _SetEditableTextItem(param_1,0x17,local_21c);
      *puVar1 = 0;
    }
  }
  return;
}


// ==== _SelectBox @ 0000d294 ====

void _SelectBox(undefined4 param_1,short param_2)

{
  _SelectDialogItemText(param_1,(int)param_2,0,0xff);
  return;
}


// ==== _GetEditableTextItem @ 0000d2bf ====

void _GetEditableTextItem(undefined4 param_1,short param_2,undefined4 param_3)

{
  undefined1 local_11c [256];
  undefined1 local_1c [8];
  undefined4 local_14;
  undefined1 local_e [6];
  
  _GetDialogItem(param_1,(int)param_2,local_e,&local_14,local_1c);
  _GetDialogItemText(local_14,local_11c);
  _CopyPascalStringToC(local_11c,param_3);
  return;
}


// ==== _DoLevelSelect @ 0000d31e ====

int _DoLevelSelect(void)

{
  bool bVar1;
  short sVar2;
  int iVar3;
  undefined4 uVar4;
  undefined4 uVar5;
  short local_13e;
  undefined1 local_134 [256];
  undefined1 local_34 [8];
  int local_2c;
  undefined4 local_28;
  undefined4 local_24;
  short local_20;
  short local_1e [7];
  
  iVar3 = _RT3_IsRegistered();
  if (iVar3 == 0) {
    local_13e = _GetShortPref(0x3a);
    _SetShortPref(0x3a,8);
  }
  _GetPort(&local_28);
  sVar2 = _GetShortPref(0x3a);
  _NumToString((int)sVar2,local_134);
  _ParamText(local_134,&DAT_00033544,&DAT_00033544,&DAT_00033544);
  uVar4 = _GetNewDialog(0xa0,0,0xffffffff);
  _SetDialogDefaultItem(uVar4,1);
  _SetPortDialogPort(uVar4);
  _NumToString(2,local_134);
  _GetDialogItem(uVar4,4,local_1e,&local_24,local_34);
  _SetDialogItemText(local_24,local_134);
  _SetDialogItem(uVar4,4,(int)local_1e[0],local_24,local_34);
  _SelectDialogItemText(uVar4,4,0,0x7fff);
  _PlayMySnd(0x16,10,0);
  uVar5 = _GetDialogWindow(uVar4);
  _ZoomAndShowWindow(uVar5);
  uVar5 = _NewModalFilterUPP(_LevelSelectFilter);
  do {
    _ModalDialog(uVar5,&local_20);
  } while (1 < (ushort)(local_20 - 1U));
  _GetDialogItem(uVar4,4,local_1e,&local_24,local_34);
  _GetDialogItemText(local_24,local_134);
  _StringToNum(local_134,&local_2c);
  if (local_20 != 1) {
    bVar1 = false;
    goto LAB_0000d5b9;
  }
  if (local_2c < 2) {
LAB_0000d548:
    local_2c = 0;
    _SysBeep(1);
    bVar1 = false;
  }
  else {
    sVar2 = _GetShortPref(0x3a);
    if (sVar2 < local_2c) goto LAB_0000d548;
    bVar1 = true;
  }
  _NumToString(local_2c,local_134);
  _SetDialogItemText(local_24,local_134);
  _SetDialogItem(uVar4,4,(int)local_1e[0],local_24,local_34);
  _WaitFor(0x1e);
LAB_0000d5b9:
  _DisposeDialog(uVar4);
  _DisposeModalFilterUPP(uVar5);
  _SetPort(local_28);
  iVar3 = _RT3_IsRegistered();
  if (iVar3 == 0) {
    _SetShortPref(0x3a,(int)local_13e);
  }
  if (bVar1) {
    iVar3 = (int)(short)local_2c;
  }
  else {
    iVar3 = 0;
  }
  return iVar3;
}


// ==== _GetItemControl @ 0000d60b ====

void _GetItemControl(undefined4 param_1,short param_2,undefined4 param_3)

{
  _GetDialogItemAsControl(param_1,(int)param_2,param_3);
  return;
}


// ==== _FlashMyDialogItem @ 0000d62d ====

void _FlashMyDialogItem(undefined4 param_1,short param_2)

{
  undefined1 local_14 [4];
  undefined4 local_10 [3];
  
  _GetDialogItemAsControl(param_1,(int)param_2,local_10);
  _HiliteControl(local_10[0],1);
  _Delay(8,local_14);
  _HiliteControl(local_10[0],0);
  return;
}


// ==== _numberFilter @ 0000d688 ====

undefined4 _numberFilter(undefined4 param_1,short *param_2,undefined2 *param_3)

{
  char cVar1;
  undefined4 uVar2;
  undefined4 local_14;
  undefined1 local_10 [8];
  
  if (*param_2 == 3) {
    cVar1 = _BitAnd(*(undefined4 *)(param_2 + 1),0xff);
    if ((cVar1 == '\r') || (cVar1 == '\x03')) {
      *param_3 = 1;
      uVar2 = 1;
    }
    else {
      if (cVar1 != '\x1b') {
        if ((9 < (byte)(cVar1 - 0x30U)) && (cVar1 != '\b')) {
          _SysBeep(1);
          *param_2 = 0;
        }
        goto LAB_0000d755;
      }
      *param_3 = 2;
      uVar2 = 2;
    }
    _GetDialogItemAsControl(param_1,uVar2,&local_14);
    _HiliteControl(local_14,1);
    _Delay(8,local_10);
    _HiliteControl(local_14,0);
    uVar2 = 1;
  }
  else {
LAB_0000d755:
    uVar2 = 0;
  }
  return uVar2;
}


// ==== _GetMyDialogItemState @ 0000d75d ====

int _GetMyDialogItemState(undefined4 param_1,short param_2)

{
  short sVar1;
  undefined4 local_10 [3];
  
  _GetDialogItemAsControl(param_1,(int)param_2,local_10);
  sVar1 = _GetControlValue(local_10[0]);
  return (int)sVar1;
}


// ==== _SetMyDialogItemTitle @ 0000d78b ====

void _SetMyDialogItemTitle(undefined4 param_1,short param_2,undefined4 param_3)

{
  undefined1 local_20 [8];
  undefined1 local_18 [4];
  undefined4 local_14;
  ushort local_e;
  
  _GetDialogItem(param_1,(int)param_2,&local_e,&local_14,local_20);
  local_e = local_e & 0xff7f;
  if ((local_e == 8) || (local_e == 0x10)) {
    _SetDialogItemText(local_14,param_3);
  }
  else {
    _GetDialogItemAsControl(param_1,(int)param_2,local_18);
    _SetControlTitle(local_14,param_3);
    _SetPortDialogPort(param_1);
  }
  return;
}


// ==== _cstrlen @ 0000d819 ====

void _cstrlen(int param_1)

{
  int iVar1;
  
  iVar1 = -1;
  do {
    iVar1 = iVar1 + 1;
  } while (*(char *)(param_1 + iVar1) != '\0');
  return;
}


// ==== _SetDialogFontAndSize @ 0000d82f ====

void _SetDialogFontAndSize(undefined4 param_1,short param_2,short param_3)

{
  int *piVar1;
  short local_24;
  short local_22;
  short local_1e;
  
  _SetPortDialogPort(param_1);
  _TextFont((int)param_2);
  _TextSize((int)param_3);
  _GetFontInfo(&local_24);
  piVar1 = (int *)_GetDialogTextEditHandle(param_1);
  *(undefined2 *)(*piVar1 + 0x4a) = 1;
  *(undefined2 *)(*piVar1 + 0x50) = 9;
  *(short *)(*piVar1 + 0x18) = local_24 + local_22 + local_1e;
  *(short *)(*piVar1 + 0x1a) = local_24;
  return;
}


// ==== _SetMyDialogItemState @ 0000d8a2 ====

void _SetMyDialogItemState(undefined4 param_1,short param_2,short param_3)

{
  undefined4 local_10 [2];
  
  _GetDialogItemAsControl(param_1,(int)param_2,local_10);
  _SetControlValue(local_10[0],(int)param_3);
  return;
}


// ==== _ResetPrefsGameValues @ 0000d8dc ====

void _ResetPrefsGameValues(undefined4 param_1)

{
  undefined1 uVar1;
  
  uVar1 = _GetBooleanPref(0x37);
  _SetMyDialogItemState(param_1,0x1a,uVar1);
  uVar1 = _GetBooleanPref(0x36);
  _SetMyDialogItemState(param_1,0x1b,uVar1);
  uVar1 = _GetBooleanPref(0x35);
  _SetMyDialogItemState(param_1,0x1c,uVar1);
  uVar1 = _GetBooleanPref(0x3d);
  _SetMyDialogItemState(param_1,0x1d,uVar1);
  return;
}


// ==== _ResetPrefsSoundValues @ 0000d978 ====

void _ResetPrefsSoundValues(undefined4 param_1)

{
  undefined1 uVar1;
  short sVar2;
  
  sVar2 = _GetShortPref(0x33);
  _SetMyDialogItemState(param_1,0x1a,(int)sVar2);
  sVar2 = _GetShortPref(0x35);
  _SetMyDialogItemState(param_1,0x1b,(int)sVar2);
  uVar1 = _GetBooleanPref(0x40);
  _SetMyDialogItemState(param_1,0x1c,uVar1);
  return;
}


// ==== _OutlineItem @ 0000d9ed ====

void _OutlineItem(undefined4 param_1,short param_2)

{
  undefined4 uVar1;
  int iVar2;
  undefined1 local_42 [18];
  short local_30 [2];
  short local_2c;
  undefined4 local_28;
  undefined1 local_24 [6];
  undefined1 local_1e [14];
  
  _GetPort(&local_28);
  _SetPortDialogPort(param_1);
  _GetDialogItem(param_1,(int)param_2,local_1e,local_24,local_30);
  _GetPenState(local_42);
  _PenNormal();
  _InsetRect(local_30,0xfffffffc,0xfffffffc);
  uVar1 = _NewPtr(8);
  uVar1 = _GetQDGlobalsBlack(uVar1);
  _PenPat(uVar1);
  _DisposePtr(uVar1);
  _PenSize(3,3);
  iVar2 = (int)(short)((short)(((int)local_2c - (int)local_30[0]) / 2) + 2);
  _FrameRoundRect(local_30,iVar2,iVar2);
  _SetPenState(local_42);
  _SetPort(local_28);
  return;
}


// ==== _ActivateItem @ 0000dada ====

void _ActivateItem(undefined4 param_1,short param_2)

{
  undefined4 local_10 [3];
  
  _GetDialogItemAsControl(param_1,(int)param_2,local_10);
  _ActivateControl(local_10[0]);
  return;
}


// ==== _ItemOn @ 0000db07 ====

void _ItemOn(undefined4 param_1,short param_2)

{
  undefined4 local_10 [3];
  
  _GetDialogItemAsControl(param_1,(int)param_2,local_10);
  _ActivateControl(local_10[0]);
  return;
}


// ==== _DeactivateItem @ 0000db34 ====

void _DeactivateItem(undefined4 param_1,short param_2)

{
  undefined4 local_10 [3];
  
  _GetDialogItemAsControl(param_1,(int)param_2,local_10);
  _DeactivateControl(local_10[0]);
  return;
}


// ==== _ItemOff @ 0000db61 ====

void _ItemOff(undefined4 param_1,short param_2)

{
  undefined4 local_10 [3];
  
  _GetDialogItemAsControl(param_1,(int)param_2,local_10);
  _DeactivateControl(local_10[0]);
  return;
}


// ==== _AddItems @ 0000db8e ====

void _AddItems(undefined4 param_1,short param_2)

{
  int iVar1;
  
  iVar1 = _GetResource(0x4449544c,(int)param_2);
  if (iVar1 == 0) {
    _ResourceError(0x7d9,1,"DITL",(int)param_2);
  }
  _MoveHHi(iVar1);
  _HLock(iVar1);
  _AppendDITL(param_1,iVar1,0);
  _ReleaseResource();
  return;
}


// ==== _RemoveItems @ 0000dc07 ====

void _RemoveItems(undefined4 param_1)

{
  short sVar1;
  
  sVar1 = _CountDITL(param_1);
  _ShortenDITL(param_1,(int)(short)(sVar1 + -0x19));
  return;
}


// ==== _GetPopUpMenuHandle @ 0000dc2f ====

void _GetPopUpMenuHandle(void)

{
  _GetControlPopupMenuHandle();
  return;
}


// ==== _NewSetDlgFilter @ 0000dc38 ====

undefined4 _NewSetDlgFilter(undefined4 param_1,short *param_2,undefined2 *param_3)

{
  short sVar1;
  char cVar2;
  undefined4 uVar3;
  
  sVar1 = *param_2;
  if (sVar1 != 5) {
    if (sVar1 == 6) {
      _OutlineItem(param_1,1);
      return 0;
    }
    if (sVar1 != 3) {
      return 0;
    }
  }
  cVar2 = _BitAnd(*(undefined4 *)(param_2 + 1),0xff);
  if ((*(byte *)((int)param_2 + 0xf) & 1) == 0) {
    if ((cVar2 == '\r') || (cVar2 == '\x03')) {
      *param_3 = 1;
      uVar3 = 1;
      goto LAB_0000dc96;
    }
    if (cVar2 != '\x1b') {
      return 0;
    }
  }
  else {
    if ((byte)(cVar2 + 0x9fU) < 0x1a) {
      cVar2 = cVar2 + -0x20;
    }
    if (cVar2 != '.') {
      return 1;
    }
  }
  *param_3 = 2;
  uVar3 = 2;
LAB_0000dc96:
  _FlashMyDialogItem(param_1,uVar3);
  return 1;
}


// ==== _LevelSelectFilter @ 0000dce3 ====

undefined4 _LevelSelectFilter(undefined4 param_1,short *param_2,undefined2 *param_3)

{
  char cVar1;
  undefined4 uVar2;
  
  if ((*param_2 != 3) && (*param_2 != 5)) {
    return 0;
  }
  cVar1 = _BitAnd(*(undefined4 *)(param_2 + 1),0xff);
  if ((*(byte *)((int)param_2 + 0xf) & 1) == 0) {
    if ((cVar1 == '\r') || (cVar1 == '\x03')) {
      *param_3 = 1;
      uVar2 = 1;
      goto LAB_0000dd3b;
    }
    if (cVar1 != '\x1b') {
      if ((byte)(cVar1 - 0x30U) < 10) {
        return 0;
      }
      if (cVar1 != '\b') {
        _SysBeep(1);
        return 1;
      }
      return 0;
    }
  }
  else {
    if ((byte)(cVar1 + 0x9fU) < 0x1a) {
      cVar1 = cVar1 + -0x20;
    }
    if (cVar1 != '.') {
      return 1;
    }
  }
  *param_3 = 2;
  uVar2 = 2;
LAB_0000dd3b:
  _FlashMyDialogItem(param_1,uVar2);
  return 1;
}


// ==== _HiScoreEraseFilter @ 0000dd8d ====

undefined4 _HiScoreEraseFilter(undefined4 param_1,short *param_2,undefined2 *param_3)

{
  short sVar1;
  char cVar2;
  
  sVar1 = *param_2;
  if (sVar1 != 5) {
    if (sVar1 == 6) {
      _OutlineItem(param_1,1);
      return 0;
    }
    if (sVar1 != 3) {
      return 0;
    }
  }
  cVar2 = _BitAnd(*(undefined4 *)(param_2 + 1),0xff);
  if ((*(byte *)((int)param_2 + 0xf) & 1) == 0) {
    if (((cVar2 != '\r') && (cVar2 != '\x03')) && (cVar2 != '\x1b')) {
      return 0;
    }
  }
  else {
    if ((byte)(cVar2 + 0x9fU) < 0x1a) {
      cVar2 = cVar2 + -0x20;
    }
    if (cVar2 != '.') {
      return 1;
    }
  }
  *param_3 = 2;
  _FlashMyDialogItem(param_1,2);
  return 1;
}


// ==== _RestorePrefsData @ 0000de22 ====

void _RestorePrefsData(void)

{
  _memmove(*(void **)PTR__gPrefsData_0003f044,*(void **)PTR__gSavedPrefsData_000340a8,0x800);
  return;
}


// ==== _SetPrefsKey @ 0000de4c ====

void _SetPrefsKey(short param_1,undefined4 param_2)

{
  undefined *puVar1;
  short sVar2;
  int iVar3;
  short *psVar4;
  undefined4 uVar5;
  undefined1 local_3c [44];
  
  sVar2 = _GetLeftKey();
  if ((((sVar2 == param_1) && (*(short *)PTR__gKeyTarget_000340b0 != 0x1a)) ||
      ((sVar2 = _GetRightKey(), param_1 == sVar2 && (*(short *)PTR__gKeyTarget_000340b0 != 0x1b))))
     || ((((sVar2 = _GetUpKey(), param_1 == sVar2 && (*(short *)PTR__gKeyTarget_000340b0 != 0x1c))
          || ((sVar2 = _GetDownKey(), param_1 == sVar2 &&
              (*(short *)PTR__gKeyTarget_000340b0 != 0x1d)))) ||
         ((sVar2 = _GetPushKey(), puVar1 = PTR__gKeyTarget_000340b0, param_1 == sVar2 &&
          (*(short *)PTR__gKeyTarget_000340b0 != 0x1e)))))) {
    _SysBeep(1);
  }
  else {
    if ((ushort)(*(short *)PTR__gKeyTarget_000340b0 - 0x1aU) < 5) {
      iVar3 = (int)param_1;
      _CodeToName(iVar3,local_3c);
      _SetEditableTextItem(param_2,(int)*(short *)puVar1,local_3c);
      psVar4 = (short *)PTR__gKeyTarget_000340b0;
      switch(*(undefined2 *)puVar1) {
      case 0x1a:
        _SetLeftKey(iVar3);
        psVar4 = (short *)PTR__gKeyTarget_000340b0;
        *(undefined2 *)PTR__gKeyTarget_000340b0 = 0x1b;
        break;
      case 0x1b:
        _SetRightKey(iVar3);
        psVar4 = (short *)PTR__gKeyTarget_000340b0;
        *(undefined2 *)PTR__gKeyTarget_000340b0 = 0x1c;
        break;
      case 0x1c:
        _SetUpKey(iVar3);
        psVar4 = (short *)PTR__gKeyTarget_000340b0;
        *(undefined2 *)PTR__gKeyTarget_000340b0 = 0x1d;
        break;
      case 0x1d:
        _SetDownKey(iVar3);
        psVar4 = (short *)PTR__gKeyTarget_000340b0;
        *(undefined2 *)PTR__gKeyTarget_000340b0 = 0x1e;
        break;
      case 0x1e:
        _SetPushKey(iVar3);
        psVar4 = (short *)PTR__gKeyTarget_000340b0;
        *(undefined2 *)PTR__gKeyTarget_000340b0 = 0x1a;
      }
      _SelectDialogItemText(param_2,(int)*psVar4,0,0xff);
      _SaveKeys();
    }
    sVar2 = _GetLeftKey();
    if ((((sVar2 == 0) && (sVar2 = _GetRightKey(), sVar2 == 0x25)) &&
        (sVar2 = _GetUpKey(), sVar2 == 0xe)) &&
       (((sVar2 = _GetDownKey(), sVar2 == 7 && (sVar2 = _GetPushKey(), sVar2 == 0x2f)) &&
        (_played_74034 == '\0')))) {
      _played_74034 = '\x01';
      uVar5 = 0xd;
    }
    else {
      sVar2 = _GetLeftKey();
      if (sVar2 != 2) {
        return;
      }
      sVar2 = _GetRightKey();
      if (sVar2 != 0xd) {
        return;
      }
      sVar2 = _GetUpKey();
      if (sVar2 != 0) {
        return;
      }
      sVar2 = _GetDownKey();
      if (sVar2 != 0xf) {
        return;
      }
      sVar2 = _GetPushKey();
      if (sVar2 != 0xe) {
        return;
      }
      if (_playedTwo_74035 != '\0') {
        return;
      }
      _playedTwo_74035 = '\x01';
      uVar5 = 9;
    }
    _PlayMySnd(uVar5,10,0);
  }
  return;
}


// ==== _TouchUpPrefsDialog @ 0000e083 ====

void _TouchUpPrefsDialog(undefined4 param_1)

{
  int iVar1;
  undefined1 local_38 [8];
  undefined2 local_30;
  undefined2 local_2e;
  undefined2 local_2c;
  undefined2 local_2a;
  undefined2 local_28;
  undefined2 local_26;
  undefined1 local_24 [6];
  undefined1 local_1e [14];
  
  local_30 = 0x7fff;
  local_2e = 0x7fff;
  local_2c = 0x7fff;
  local_2a = 0;
  local_28 = 0;
  local_26 = 0;
  _SetPortDialogPort(param_1);
  _PenSize(1,1);
  _RGBForeColor(&local_30);
  iVar1 = 0xe;
  do {
    _GetDialogItem(param_1,iVar1,local_1e,local_24,local_38);
    _FrameRect(local_38);
    iVar1 = iVar1 + 1;
  } while (iVar1 != 0x16);
  _GetDialogItem(param_1,0x16,local_1e,local_24,local_38);
  _FrameRect(local_38);
  _RGBForeColor(&local_2a);
  return;
}


// ==== _HiliteCurrentPrefsArea @ 0000e150 ====

void _HiliteCurrentPrefsArea(undefined4 param_1)

{
  undefined *puVar1;
  short sVar2;
  int iVar3;
  undefined4 *puVar4;
  undefined4 uVar5;
  undefined4 uVar6;
  undefined1 local_2c [8];
  undefined1 local_24 [6];
  undefined1 local_1e [14];
  
  _SetPortDialogPort(param_1);
  puVar1 = PTR__gPrefsIcons_000340a4;
  iVar3 = 8;
  puVar4 = (undefined4 *)PTR__gPrefsIcons_000340a4;
  do {
    _GetDialogItem(param_1,iVar3,local_1e,local_24,local_2c);
    if (*(short *)PTR__gWhichPrefs_000340ac == (short)((short)iVar3 + -7)) {
      uVar6 = *(undefined4 *)(puVar1 + *(short *)PTR__gWhichPrefs_000340ac * 4 + -4);
      uVar5 = 0x4000;
    }
    else {
      uVar6 = *puVar4;
      uVar5 = 0;
    }
    sVar2 = _PlotCIconHandle(local_2c,0,uVar5,uVar6);
    if (sVar2 != 0) {
      _StdError("Can\'t plot cicn for prefs dialog.",(int)sVar2);
    }
    iVar3 = iVar3 + 1;
    puVar4 = puVar4 + 1;
  } while (iVar3 != 0xb);
  return;
}


// ==== _PrefsDlgFilter @ 0000e209 ====

undefined4 _PrefsDlgFilter(undefined4 param_1,ushort *param_2,undefined2 *param_3)

{
  ushort uVar1;
  char cVar2;
  char cVar3;
  short sVar4;
  undefined4 uVar5;
  
  uVar1 = *param_2;
  if (uVar1 == 3) {
LAB_0000e3c5:
    cVar2 = _BitAnd(*(undefined4 *)(param_2 + 1),0xff);
    if ((*(byte *)((int)param_2 + 0xf) & 1) == 0) {
      if ((cVar2 != '\r') && (cVar2 != '\x03')) {
        if (cVar2 == '\x1b') goto LAB_0000e414;
        if (cVar2 != '\t') {
          if ((*(short *)PTR__gWhichPrefs_000340ac == 2) &&
             (sVar4 = _GetShortPref(0x38), sVar4 != 1)) {
            _SetPrefsKey(*(undefined1 *)((int)param_2 + 3),param_1);
          }
          goto LAB_0000e486;
        }
        goto LAB_0000e299;
      }
      *param_3 = 1;
      uVar5 = 1;
LAB_0000e424:
      _FlashMyDialogItem(param_1,uVar5);
    }
    else {
      if ((byte)(cVar2 + 0x9fU) < 0x1a) {
        cVar2 = cVar2 + -0x20;
      }
      if (cVar2 == '.') {
LAB_0000e414:
        *param_3 = 2;
        uVar5 = 2;
        goto LAB_0000e424;
      }
    }
LAB_0000e486:
    uVar5 = 1;
  }
  else {
    if (uVar1 < 4) {
      if (((uVar1 == 0) && (_CheckPrefsHelp(param_1), *(short *)PTR__gWhichPrefs_000340ac == 2)) &&
         (sVar4 = _GetShortPref(0x38), sVar4 != 1)) {
        cVar2 = _GameKeyDown(0x3b);
        if ((cVar2 == '\0') || (_keyDown4_73980 != '\0')) {
          cVar3 = _GameKeyDown(0x3b);
          cVar2 = '\0';
          if (cVar3 != '\0') {
            cVar2 = _keyDown4_73980;
          }
          _keyDown4_73980 = cVar2;
          cVar2 = _GameKeyDown(0x38);
          if ((cVar2 == '\0') || (_keyDown1_73977 != '\0')) {
            cVar3 = _GameKeyDown(0x38);
            cVar2 = '\0';
            if (cVar3 != '\0') {
              cVar2 = _keyDown1_73977;
            }
            _keyDown1_73977 = cVar2;
            cVar2 = _GameKeyDown(0x3a);
            if ((cVar2 == '\0') || (_keyDown2_73978 != '\0')) {
              cVar3 = _GameKeyDown(0x3a);
              cVar2 = '\0';
              if (cVar3 != '\0') {
                cVar2 = _keyDown2_73978;
              }
              _keyDown2_73978 = cVar2;
              cVar2 = _GameKeyDown(0x37);
              if ((cVar2 == '\0') || (_keyDown3_73979 != '\0')) {
                cVar2 = _GameKeyDown(0x37);
                if (cVar2 == '\0') {
                  _keyDown3_73979 = '\0';
                }
              }
              else {
                _SetPrefsKey(0x37,param_1);
                _keyDown3_73979 = '\x01';
              }
            }
            else {
              _SetPrefsKey(0x3a,param_1);
              _keyDown2_73978 = '\x01';
            }
          }
          else {
            _SetPrefsKey(0x38,param_1);
            _keyDown1_73977 = '\x01';
          }
        }
        else {
          _SetPrefsKey(0x3b,param_1);
          _keyDown4_73980 = '\x01';
        }
      }
    }
    else {
      if (uVar1 == 5) goto LAB_0000e3c5;
      if (uVar1 == 6) {
        _TouchUpPrefsDialog(param_1);
        _HiliteCurrentPrefsArea(param_1);
      }
    }
LAB_0000e299:
    uVar5 = 0;
  }
  return uVar5;
}


// ==== _ResetPrefsKeysValues @ 0000e491 ====

void _ResetPrefsKeysValues(undefined4 param_1)

{
  undefined1 uVar1;
  char cVar2;
  short sVar3;
  undefined2 uVar4;
  ushort uVar5;
  short sVar6;
  undefined4 uVar7;
  int iVar8;
  undefined2 uVar9;
  undefined2 uVar10;
  undefined2 local_150;
  undefined2 local_14e;
  undefined1 local_144 [256];
  undefined1 local_44 [32];
  undefined4 local_24;
  undefined1 local_1e [14];
  
  sVar3 = _GetShortPref(0x38);
  if (sVar3 == 1) {
    _ShowDialogItem(param_1,0x22);
    _ShowDialogItem(param_1,0x23);
    _ShowDialogItem(param_1,0x24);
    _ShowDialogItem(param_1,0x25);
    _ShowDialogItem(param_1,0x26);
    _HideDialogItem(param_1,0x1a);
    _HideDialogItem(param_1,0x1b);
    _HideDialogItem(param_1,0x1c);
    _HideDialogItem(param_1,0x1d);
    _HideDialogItem(param_1,0x1e);
    _DeactivateItem(param_1,0x20);
    uVar4 = 0x22;
    uVar9 = 0x23;
    uVar10 = 0x24;
    local_150 = 0x25;
    local_14e = 0x26;
  }
  else {
    _HideDialogItem(param_1,0x22);
    _HideDialogItem(param_1,0x23);
    _HideDialogItem(param_1,0x24);
    _HideDialogItem(param_1,0x25);
    _HideDialogItem(param_1,0x26);
    _ShowDialogItem(param_1,0x1a);
    _ShowDialogItem(param_1,0x1b);
    _ShowDialogItem(param_1,0x1c);
    _ShowDialogItem(param_1,0x1d);
    _ShowDialogItem(param_1,0x1e);
    _ActivateItem(param_1,0x20);
    uVar4 = 0x1a;
    uVar9 = 0x1b;
    uVar10 = 0x1c;
    local_150 = 0x1d;
    local_14e = 0x1e;
  }
  _InitControls();
  _GetLeftName(local_44);
  _SetEditableTextItem(param_1,uVar4,local_44);
  _GetRightName(local_44);
  _SetEditableTextItem(param_1,uVar9,local_44);
  _GetUpName(local_44);
  _SetEditableTextItem(param_1,uVar10,local_44);
  _GetDownName(local_44);
  _SetEditableTextItem(param_1,local_150,local_44);
  _GetPushName(local_44);
  _SetEditableTextItem(param_1,local_14e,local_44);
  sVar3 = _GetShortPref(0x38);
  if (sVar3 != 1) {
    _SelectDialogItemText(param_1,(int)*(short *)PTR__gKeyTarget_000340b0,0,0xff);
  }
  _GetDialogItemAsControl(param_1,0x21,&local_24);
  uVar7 = _GetControlPopupMenuHandle(local_24);
  while( true ) {
    uVar5 = _CountMenuItems(uVar7);
    if (uVar5 < 2) break;
    uVar4 = _CountMenuItems(uVar7);
    _DeleteMenuItem(uVar7,uVar4);
  }
  sVar3 = _GetShortPref(0x37);
  if (1 < sVar3) {
    _InsertMenuItem(uVar7,"\x02(-",0xff);
  }
  sVar3 = 2;
  while( true ) {
    sVar6 = _GetShortPref(0x37);
    if (sVar6 < sVar3) break;
    _GetKeySetPref((int)sVar3,local_44,local_1e,local_1e,local_1e,local_1e,local_1e);
    _CopyCStringToPascal(local_44,local_144);
    _InsertMenuItem(uVar7,local_144,0xff);
    sVar3 = sVar3 + 1;
  }
  sVar3 = _GetShortPref(0x37);
  _SetControlMaximum(local_24,(int)(short)(sVar3 + 1));
  sVar3 = _GetShortPref(0x38);
  if (sVar3 < 2) {
    iVar8 = 1;
  }
  else {
    sVar3 = _GetShortPref(0x38);
    iVar8 = (int)(short)(sVar3 + 1);
  }
  _SetMyDialogItemState(param_1,0x21,iVar8);
  uVar1 = _GetBooleanPref(0x41);
  _SetMyDialogItemState(param_1,0x2c,uVar1);
  cVar2 = _CanUseISp();
  if (cVar2 == '\0') {
    _DeactivateItem(param_1,0x2c);
  }
  cVar2 = _GetBooleanPref(0x41);
  if (cVar2 != '\0') {
    cVar2 = _CanUseISp();
    if (cVar2 != '\0') {
      _DeactivateItem(param_1,0x1f);
      _DeactivateItem(param_1,0x20);
      _DeactivateItem(param_1,0x21);
      uVar7 = 0x2d;
      goto LAB_0000e9c2;
    }
  }
  _DeactivateItem(param_1,0x2d);
  _ActivateItem(param_1,0x1f);
  _ActivateItem(param_1,0x20);
  uVar7 = 0x21;
LAB_0000e9c2:
  _ActivateItem(param_1,uVar7);
  return;
}


// ==== _ChangeArea @ 0000e9d8 ====

void _ChangeArea(undefined4 param_1,short param_2)

{
  short sVar1;
  
  _SetPortDialogPort(param_1);
  _PlayMySnd(0x11,10,0);
  *(short *)PTR__gWhichPrefs_000340ac = param_2;
  _HiliteCurrentPrefsArea(param_1);
  _RemoveItems(param_1);
  _AddItems(param_1,(int)(short)(param_2 + 0xbe));
  sVar1 = *(short *)PTR__gWhichPrefs_000340ac;
  if (sVar1 == 2) {
    *(undefined2 *)PTR__gKeyTarget_000340b0 = 0x1a;
    _ResetPrefsKeysValues();
    return;
  }
  if (sVar1 != 3) {
    if (sVar1 == 1) {
      _ResetPrefsSoundValues();
      return;
    }
    return;
  }
  _ResetPrefsGameValues();
  return;
}


// ==== _PrefsDialog @ 0000ea93 ====

void _PrefsDialog(void)

{
  char cVar1;
  undefined *puVar2;
  char cVar3;
  short sVar4;
  short sVar5;
  int iVar6;
  undefined4 uVar7;
  undefined4 uVar8;
  int iVar9;
  undefined4 uVar10;
  undefined4 uVar11;
  uint uVar12;
  short *psVar13;
  char *pcVar14;
  bool bVar15;
  int iVar16;
  char local_132 [10];
  undefined1 local_128;
  short local_32;
  short local_30;
  short local_2e;
  short local_2c;
  short local_2a;
  undefined4 local_28;
  int local_24;
  short local_20;
  short local_1e [7];
  
  puVar2 = PTR__environment_0003f028;
  cVar1 = PTR__environment_0003f028[0x26];
  _Gestalt(0x73797376,&local_24);
  if ((puVar2[0x26] == '\0') && (local_24 < 0x1051)) {
    _GoWindowMode();
  }
  _memmove(*(void **)PTR__gSavedPrefsData_000340a8,*(void **)PTR__gPrefsData_0003f044,0x800);
  *(undefined2 *)PTR__gWhichPrefs_000340ac = 1;
  iVar6 = _GetNewDialog(0xbe,0,0xffffffff);
  if (iVar6 == 0) {
    _ResourceError(0x7d9,2,"DLOG",0xbe);
  }
  _SetToScreen();
  _SetPortDialogPort(iVar6);
  _SetDialogDefaultItem(iVar6,1);
  _SetDialogCancelItem(iVar6,2);
  _CreateWindowGroup(0,&local_28);
  uVar8 = local_28;
  uVar7 = _GetDialogWindow(iVar6);
  _SetWindowGroup(uVar7,uVar8);
  if (PTR__environment_0003f028[0x26] == '\0') {
    uVar8 = _CGShieldingWindowLevel();
  }
  else {
    uVar8 = _CGWindowLevelForKey(4);
  }
  _SetWindowGroupLevel(local_28,uVar8);
  puVar2 = PTR__gLastHelpInfo_000340b4;
  *(undefined2 *)(PTR__gLastHelpInfo_000340b4 + 2) = 0;
  *(undefined2 *)puVar2 = 0;
  _PlayMySnd(0x16,10,0);
  uVar8 = _GetDialogWindow(iVar6);
  _ZoomAndShowWindow(uVar8);
  _AddItems(iVar6,(int)(short)(*(short *)PTR__gWhichPrefs_000340ac + 0xbe));
  _ResetPrefsSoundValues(iVar6);
  iVar9 = _NewModalFilterUPP(_PrefsDlgFilter);
  if (iVar9 == 0) {
    _StdError("Can\'t make myFilterProcPtr for prefs dialog.",0);
  }
  uVar8 = _NewModalFilterUPP(_NewSetDlgFilter);
  do {
    _ModalDialog(iVar9,&local_20);
    psVar13 = (short *)PTR__gWhichPrefs_000340ac;
    switch(local_20) {
    case 3:
      _AlexPrefsSoundInit();
      _AlexPrefsKeysInit();
      _AlexPrefsGameInit();
      sVar4 = *(short *)PTR__gWhichPrefs_000340ac;
      if (sVar4 == 2) {
        _ResetPrefsKeysValues(iVar6);
      }
      else if (sVar4 == 3) {
        _ResetPrefsGameValues(iVar6);
      }
      else if (sVar4 == 1) {
        _ResetPrefsSoundValues(iVar6);
      }
      uVar7 = _GetDialogPort(iVar6);
      _GetPortBounds(uVar7,&local_32);
      uVar7 = _GetDialogWindow(iVar6);
      _InvalWindowRect(uVar7,&local_32);
      goto LAB_0000edba;
    case 4:
      _memmove(*(void **)PTR__gPrefsData_0003f044,*(void **)PTR__gSavedPrefsData_000340a8,0x800);
      sVar4 = *(short *)PTR__gWhichPrefs_000340ac;
      if (sVar4 == 2) {
        _ResetPrefsKeysValues(iVar6);
      }
      else if (sVar4 == 3) {
        _ResetPrefsGameValues(iVar6);
      }
      else if (sVar4 == 1) {
        _ResetPrefsSoundValues(iVar6);
      }
LAB_0000edba:
      _UpdateSoundVol();
      _UpdateMusicVolume();
      psVar13 = (short *)PTR__gWhichPrefs_000340ac;
      break;
    case 5:
      if (*(short *)PTR__gWhichPrefs_000340ac != 1) {
        uVar7 = 1;
LAB_0000ee06:
        _ChangeArea(iVar6,uVar7);
      }
      break;
    case 6:
      if (*(short *)PTR__gWhichPrefs_000340ac != 2) {
        uVar7 = 2;
        goto LAB_0000ee06;
      }
      break;
    case 7:
      if (*(short *)PTR__gWhichPrefs_000340ac != 3) {
        uVar7 = 3;
        goto LAB_0000ee06;
      }
    }
    sVar4 = *psVar13;
    if (sVar4 == 2) {
      switch(local_20) {
      case 0x1a:
      case 0x1b:
      case 0x1c:
      case 0x1d:
      case 0x1e:
        *(short *)PTR__gKeyTarget_000340b0 = local_20;
        sVar4 = _GetShortPref(0x38);
        if (sVar4 != 1) {
          _SelectDialogItemText(iVar6,(int)local_20,0,0xff);
        }
        break;
      case 0x1f:
        sVar4 = _GetShortPref(0x37);
        if (sVar4 < 0x14) {
          uVar10 = _GetNewDialog(200,0,0xffffffff);
          uVar7 = _GetDialogWindow(uVar10);
          _ShowWindow(uVar7);
          uVar7 = local_28;
          uVar11 = _GetDialogWindow(uVar10);
          _SetWindowGroup(uVar11,uVar7);
          _SetPortDialogPort(uVar10);
          _SelectDialogItemText(uVar10,3,0,0xff);
          uVar7 = _GetDialogWindow(uVar10);
          _SelectWindow(uVar7);
          while( true ) {
            do {
              _ModalDialog(uVar8,local_1e);
            } while (1 < (ushort)(local_1e[0] - 1U));
            if (local_1e[0] == 2) break;
            _GetEditableTextItem(uVar10,3,local_132);
            uVar12 = 0xffffffff;
            pcVar14 = local_132;
            do {
              if (uVar12 == 0) break;
              uVar12 = uVar12 - 1;
              cVar3 = *pcVar14;
              pcVar14 = pcVar14 + 1;
            } while (cVar3 != '\0');
            if (~uVar12 - 1 < 0xb) break;
            _NoteAlert(0xc9,0);
            local_128 = 0;
            _SetEditableTextItem(uVar10,3,local_132);
            _SelectDialogItemText(uVar10,3,0,0xff);
          }
          _SetPortDialogPort(iVar6);
          _DisposeDialog(uVar10);
          if (local_1e[0] == 1) {
            sVar4 = _GetShortPref(0x37);
            _SetShortPref(0x37,(int)(short)(sVar4 + 1));
            sVar4 = _GetShortPref(0x37);
            _SetShortPref(0x38,(int)sVar4);
            sVar4 = _GetShortPref(0x37);
            _SetKeySetPref((int)sVar4,local_132,0x7b,0x7c,0x7e,0x7d,0x31);
            goto LAB_0000f229;
          }
        }
        else {
          _NoteAlert(0xca,0);
        }
        break;
      case 0x20:
        sVar4 = _GetShortPref(0x38);
        if (1 < sVar4) {
          sVar4 = _GetShortPref(0x38);
          while (sVar5 = _GetShortPref(0x37), sVar4 < sVar5) {
            _GetKeySetPref((int)(short)(sVar4 + 1),local_132,&local_32,&local_30,&local_2e,&local_2c
                           ,&local_2a);
            _SetKeySetPref((int)sVar4,local_132,(int)local_32,(int)local_30,(int)local_2e,
                           (int)local_2c,(int)local_2a);
            sVar4 = sVar4 + 1;
          }
          sVar4 = _GetShortPref(0x38);
          _SetShortPref(0x38,(int)(short)(sVar4 + -1));
          sVar4 = _GetShortPref(0x37);
          _SetShortPref(0x37,(int)(short)(sVar4 + -1));
          goto LAB_0000f229;
        }
        break;
      case 0x21:
        sVar4 = _GetMyDialogItemState(iVar6,0x21);
        if (1 < sVar4) {
          sVar4 = sVar4 + -1;
        }
        iVar16 = (int)sVar4;
LAB_0000f218:
        _SetShortPref(0x38,iVar16);
        _InitControls();
LAB_0000f229:
        _ResetPrefsKeysValues(iVar6);
        break;
      default:
        goto switchD_0000ee51_caseD_22;
      case 0x2c:
        cVar3 = _GetBooleanPref(0x41);
        _SetBooleanPref(0x41,cVar3 == '\0');
        _SetMyDialogItemState(iVar6,(int)local_20,cVar3 == '\0');
        cVar3 = _GetBooleanPref(0x41);
        if ((cVar3 != '\0') && (cVar3 = _CanUseISp(), cVar3 != '\0')) {
          iVar16 = 1;
          goto LAB_0000f218;
        }
        _ActivateItem(iVar6,0x1f);
        _ActivateItem(iVar6,0x20);
        _ActivateItem(iVar6,0x21);
        _DeactivateItem(iVar6,0x2d);
        break;
      case 0x2d:
        _KeysConfigure();
      }
      goto switchD_0000f2b3_caseD_1e;
    }
    if (sVar4 != 3) {
      if (sVar4 == 1) {
        if (local_20 == 0x1b) {
          sVar4 = _GetMyDialogItemState(iVar6,0x1b);
          _SetShortPref(0x35,(int)sVar4);
          sVar4 = _GetShortPref(0x35);
          if (sVar4 != 1) {
            sVar4 = _GetShortPref(0x35);
            _SetShortPref(0x36,(int)sVar4);
          }
          sVar4 = _GetShortPref(0x33);
          sVar5 = _GetShortPref(0x35);
          _SetShortPref(0x33,(int)sVar5);
          _PlayMySnd(0xd,10,0);
          _SetShortPref(0x33,(int)sVar4);
        }
        else {
          if (local_20 != 0x1c) {
            if (local_20 != 0x1a) goto switchD_0000ee51_caseD_22;
            sVar4 = _GetMyDialogItemState(iVar6,0x1a);
            _SetShortPref(0x33,(int)sVar4);
            sVar4 = _GetShortPref(0x33);
            if (sVar4 != 1) {
              sVar4 = _GetShortPref(0x33);
              _SetShortPref(0x34,(int)sVar4);
            }
            _PlayMySnd(0x12,10,0);
            goto switchD_0000f2b3_caseD_1e;
          }
          cVar3 = _GetBooleanPref(0x40);
          _SetBooleanPref(0x40,cVar3 == '\0');
          _SetMyDialogItemState(iVar6,(int)local_20,cVar3 == '\0');
        }
        _UpdateMusicVolume();
      }
      goto switchD_0000f2b3_caseD_1e;
    }
    switch(local_20) {
    case 0x19:
      sVar4 = _GetMyDialogItemState(iVar6,0x19);
      _SetShortPref(0x39,(int)sVar4);
      if (_shownSwitchQDModeDialog_73627 == '\0') {
        _NoteAlert(0xcb,0);
        _shownSwitchQDModeDialog_73627 = '\x01';
      }
      goto switchD_0000f2b3_caseD_1e;
    case 0x1a:
      cVar3 = _GetBooleanPref(0x37);
      bVar15 = cVar3 == '\0';
      uVar7 = 0x37;
      break;
    case 0x1b:
      cVar3 = _GetBooleanPref(0x36);
      bVar15 = cVar3 == '\0';
      uVar7 = 0x36;
      break;
    case 0x1c:
      cVar3 = _GetBooleanPref(0x35);
      bVar15 = cVar3 == '\0';
      uVar7 = 0x35;
      break;
    case 0x1d:
      cVar3 = _GetBooleanPref(0x3d);
      bVar15 = cVar3 == '\0';
      uVar7 = 0x3d;
      break;
    default:
      goto switchD_0000f2b3_caseD_1e;
    case 0x1f:
      cVar3 = _GetBooleanPref(0x3f);
      _SetBooleanPref(0x3f,cVar3 == '\0');
      _SetMyDialogItemState(iVar6,(int)local_20,cVar3 == '\0');
      if (_shownSwitchDepthDialog_73626 == '\0') {
        _NoteAlert(0xcb,0);
        _shownSwitchDepthDialog_73626 = '\x01';
      }
      goto switchD_0000f2b3_caseD_1e;
    }
    _SetBooleanPref(uVar7,bVar15);
    _SetMyDialogItemState(iVar6,(int)local_20,bVar15);
switchD_0000f2b3_caseD_1e:
switchD_0000ee51_caseD_22:
  } while (1 < (ushort)(local_20 - 1U));
  if (local_20 == 1) {
    cVar3 = _GetBooleanPref(0x37);
    if ((cVar3 == '\0') || (PTR__environment_0003f028[0x26] == '\0')) {
      cVar3 = _GetBooleanPref(0x37);
      if ((cVar3 == '\0') && ((PTR__environment_0003f028[0x26] == '\0' && (cVar1 == '\0')))) {
        _GoWindowMode();
      }
      goto LAB_0000f64e;
    }
  }
  else if (((local_20 != 2) ||
           (_memmove(*(void **)PTR__gPrefsData_0003f044,*(void **)PTR__gSavedPrefsData_000340a8,
                     0x800), cVar1 != '\0')) || (PTR__environment_0003f028[0x26] == '\0'))
  goto LAB_0000f64e;
  _GoFullScreenMode();
LAB_0000f64e:
  _SaveGamePrefs();
  _InitControls();
  _UpdateSoundVol();
  _UpdateMusicStatus();
  _SetToScreen();
  _ReleaseWindowGroup(local_28);
  _DisposeDialog(iVar6);
  _DisposeModalFilterUPP(uVar8);
  _DisposeModalFilterUPP(iVar9);
  _ResetOptionsMenu();
  _SetMyCCursor(200);
  return;
}


// ==== _AlexPrefsSoundInit @ 0000f6b8 ====

void _AlexPrefsSoundInit(void)

{
  _SetShortPref(0x33,3);
  _SetShortPref(0x34,3);
  _SetBooleanPref(0x39,0);
  _SetBooleanPref(0x3b,0);
  _SetBooleanPref(0x3c,0);
  _SetShortPref(0x35,4);
  _SetShortPref(0x36,4);
  _SetBooleanPref(0x40,1);
  return;
}


// ==== _AlexPrefsKeysInit @ 0000f790 ====

void _AlexPrefsKeysInit(void)

{
  undefined4 local_16;
  undefined4 local_12;
  undefined1 local_e;
  
  _SetBooleanPref(0x41,0);
  _SetShortPref(0x37,8);
  _SetShortPref(0x38,1);
  local_16 = 0x61666544;
  local_12 = 0x746c75;
  _SetKeySetPref(1,&local_16,0x7b,0x7c,0x7e,0x7d,0x31);
  local_16 = 0x7079654b;
  local_12 = 0x31206461;
  local_e = 0;
  _SetKeySetPref(2,&local_16,0x56,0x58,0x5b,0x54,0x31);
  local_16 = 0x7079654b;
  local_12 = 0x32206461;
  local_e = 0;
  _SetKeySetPref(3,&local_16,0x56,0x58,0x5b,0x57,0x31);
  local_16 = 0x7079654b;
  local_12 = 0x33206461;
  local_e = 0;
  _SetKeySetPref(4,&local_16,0x56,0x58,0x5b,0x54,0x52);
  local_16 = 0x7079654b;
  local_12 = 0x34206461;
  local_e = 0;
  _SetKeySetPref(5,&local_16,0x56,0x58,0x5b,0x57,0x52);
  local_16 = 0x6279654b;
  local_12 = 0x6472616f;
  local_e = 0;
  _SetKeySetPref(6,&local_16,0x26,0x25,0x22,0x28,0x31);
  local_16 = 0x73616c43;
  local_12 = 0x636973;
  _SetKeySetPref(7,&local_16,6,7,0x27,0x2c,0x31);
  local_16 = 0x63657053;
  local_12 = 0x6d757274;
  local_e = 0;
  _SetKeySetPref(8,&local_16,0xc,0xd,0xe,0xf,0x11);
  return;
}


// ==== _AlexPrefsGameInit @ 0000fa24 ====

void _AlexPrefsGameInit(void)

{
  char cVar1;
  
  _SetShortPref(0x39,2);
  _SetBooleanPref(0x37,0);
  cVar1 = _IsOSX();
  _SetBooleanPref(0x3f,cVar1 == '\0');
  _SetBooleanPref(0x3d,0);
  _SetBooleanPref(0x35,1);
  _SetBooleanPref(0x36,1);
  return;
}


// ==== _AlexPrefsInit @ 0000fa93 ====

void _AlexPrefsInit(void)

{
  _SetBooleanPref(0x33,0);
  _SetBooleanPref(0x38,0);
  _SetBooleanPref(0x34,0);
  _SetBooleanPref(0x3a,0);
  _SetShortPref(0x3a,10);
  _SetBooleanPref(0x3e,0);
  _AlexPrefsSoundInit();
  _AlexPrefsKeysInit();
  _AlexPrefsGameInit();
  return;
}


// ==== _GoFullScreenMode @ 0000fb21 ====

undefined4 _GoFullScreenMode(void)

{
  undefined *puVar1;
  undefined4 uVar2;
  int iVar3;
  undefined4 uVar4;
  undefined1 local_34 [8];
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined2 local_1e [7];
  
  uVar2 = _CGMainDisplayID();
  uVar2 = _CGDisplayCurrentMode(uVar2);
  *(undefined4 *)PTR__gSavedDisplayMode_000340c8 = uVar2;
  uVar2 = _CFDictionaryGetValue(uVar2,&cf_BitsPerPixel);
  _CFNumberGetValue(uVar2,9,&local_24);
  uVar2 = _CGMainDisplayID();
  uVar2 = _CGDisplayBestModeForParameters(uVar2,local_24,0x280,0x1e0,0);
  _CGAcquireDisplayFadeReservation(0x3f4ccccd,&local_28);
  _CGDisplayFade(local_28,0x3ecccccd,0,0x3f800000,0,0,0,1);
  _SetRect(local_34,0,0,0x280,0x1e0);
  puVar1 = PTR__environment_0003f028;
  _GetWindowBounds(*(undefined4 *)PTR__environment_0003f028,0x21,PTR__gSavedWindowBounds_000340c4);
  iVar3 = _CGCaptureAllDisplays();
  if (iVar3 == 0) {
    uVar4 = _CGMainDisplayID();
    iVar3 = _CGDisplaySwitchToMode(uVar4,uVar2);
    if (iVar3 == 0) {
      _SetWindowBounds(*(undefined4 *)puVar1,0x21,local_34);
      uVar2 = _GetWindowGroupOfClass(6);
      uVar4 = _CGShieldingWindowLevel();
      _SetWindowGroupLevel(uVar2,uVar4);
      _ShowWindow(*(undefined4 *)puVar1);
      _gIsFullscreen = 1;
      puVar1[0x26] = 0;
      *PTR__gDidToggleFullscreen_000340d0 = 1;
      _UpdateScreen();
      _FlushIfNecessary();
      _CGDisplayFade(local_28,0x3ecccccd,0x3f800000,0,0,0,0,1);
      _CGReleaseDisplayFadeReservation(local_28);
      iVar3 = _GetIndMenuItemWithCommandID(0,0x68696465,1,&local_2c,local_1e);
      if (iVar3 == 0) {
        _GetMenuItemCommandKey(local_2c,local_1e[0],0,PTR__gSavedHideKey_000340d4);
        _SetMenuItemCommandKey(local_2c,local_1e[0],0,0);
        iVar3 = _GetIndMenuItemWithCommandID(0,0x6869646f,1,&local_2c,local_1e);
        if (iVar3 == 0) {
          _GetMenuItemCommandKey(local_2c,local_1e[0],0,PTR__gSavedHideOthersKey_000340cc);
          _SetMenuItemCommandKey(local_2c,local_1e[0],0,0);
        }
      }
    }
  }
  return 1;
}


// ==== _GoWindowMode @ 0000fde1 ====

undefined4 _GoWindowMode(void)

{
  undefined *puVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  int iVar4;
  undefined4 local_28;
  undefined4 local_24;
  undefined2 local_1e [7];
  
  if (_gIsFullscreen == '\0') {
    _ShowWindow(*(undefined4 *)PTR__environment_0003f028);
  }
  else {
    _CGAcquireDisplayFadeReservation(0x3f4ccccd,&local_24);
    _CGDisplayFade(local_24,0x3ecccccd,0,0x3f800000,0,0,0,1);
    puVar1 = PTR__environment_0003f028;
    _HideWindow(*(undefined4 *)PTR__environment_0003f028);
    uVar3 = *(undefined4 *)PTR__gSavedDisplayMode_000340c8;
    uVar2 = _CGMainDisplayID();
    _CGDisplaySwitchToMode(uVar2,uVar3);
    _CGReleaseAllDisplays();
    _SetWindowBounds(*(undefined4 *)puVar1,0x21,PTR__gSavedWindowBounds_000340c4);
    _ShowWindow(*(undefined4 *)puVar1);
    uVar3 = _GetWindowGroupOfClass(6);
    uVar2 = _CGWindowLevelForKey(4);
    _SetWindowGroupLevel(uVar3,uVar2);
    _CGDisplayFade(local_24,0x3ecccccd,0x3f800000,0,0,0,0,1);
    _CGReleaseDisplayFadeReservation(local_24);
    puVar1[0x26] = 1;
    _gIsFullscreen = '\0';
    *PTR__gDidToggleFullscreen_000340d0 = 1;
    _UpdateScreen();
    _FlushIfNecessary();
    iVar4 = _GetIndMenuItemWithCommandID(0,0x68696465,1,&local_28,local_1e);
    if (iVar4 == 0) {
      _SetMenuItemCommandKey(local_28,local_1e[0],0,*(undefined2 *)PTR__gSavedHideKey_000340d4);
      iVar4 = _GetIndMenuItemWithCommandID(0,0x6869646f,1,&local_28,local_1e);
      if (iVar4 == 0) {
        _SetMenuItemCommandKey
                  (local_28,local_1e[0],0,*(undefined2 *)PTR__gSavedHideOthersKey_000340cc);
      }
    }
  }
  return 1;
}


// ==== _PrepareMonitor @ 0000ffd8 ====

void _PrepareMonitor(void)

{
  undefined *puVar1;
  char cVar2;
  
  cVar2 = _GetBooleanPref(0x37);
  puVar1 = PTR__environment_0003f028;
  PTR__environment_0003f028[0x26] = cVar2 == '\0';
  cVar2 = _GetBooleanPref(0x37);
  if ((cVar2 == '\0') || (puVar1[0x26] != '\0')) {
    _Utils_Log(
              "  Resolution switching option (full screen) deemed to be turned off, or in-a-window mode."
              );
    _GoWindowMode();
  }
  else {
    _Utils_Log("  Resolution switching option on, and not in in-a-window mode.");
    _GoFullScreenMode();
  }
  return;
}


// ==== _ExitFullScreenMode @ 00010037 ====

void _ExitFullScreenMode(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  undefined4 local_20 [4];
  
  if (_gIsFullscreen != '\0') {
    _CGAcquireDisplayFadeReservation(0x3f4ccccd,local_20);
    _CGDisplayFade(local_20[0],0x3ecccccd,0,0x3f800000,0,0,0,1);
    _HideWindow(*(undefined4 *)PTR__environment_0003f028);
    uVar1 = *(undefined4 *)PTR__gSavedDisplayMode_000340c8;
    uVar2 = _CGMainDisplayID();
    _CGDisplaySwitchToMode(uVar2,uVar1);
    _CGReleaseAllDisplays();
    _CGDisplayFade(local_20[0],0x3ecccccd,0x3f800000,0,0,0,0,1);
    _CGReleaseDisplayFadeReservation(local_20[0]);
    _gIsFullscreen = '\0';
  }
  return;
}


// ==== _RestoreSavedResolution @ 0001010b ====

void _RestoreSavedResolution(void)

{
  return;
}


// ==== _ScreenSuspend @ 00010110 ====

void _ScreenSuspend(void)

{
  return;
}


// ==== _ScreenResume @ 00010115 ====

void _ScreenResume(void)

{
  return;
}


// ==== _GetScreenDepth @ 0001011a ====

int _GetScreenDepth(void)

{
  short sVar1;
  undefined4 uVar2;
  
  uVar2 = _CGMainDisplayID();
  sVar1 = _CGDisplayBitsPerPixel(uVar2);
  return (int)sVar1;
}


// ==== _GameFadeOut @ 00010130 ====

void _GameFadeOut(void)

{
  return;
}


// ==== _GameFadeIn @ 00010135 ====

void _GameFadeIn(void)

{
  return;
}


// ==== _ResetScreenSize @ 0001013a ====

void _ResetScreenSize(void)

{
  return;
}


// ==== _UpdateScreenInfo @ 0001013f ====

void _UpdateScreenInfo(void)

{
  return;
}


// ==== _CreateGameWindow @ 00010144 ====

void _CreateGameWindow(void)

{
  undefined *puVar1;
  undefined1 local_14 [8];
  
  _SetRect(local_14,0,0,0x280,0x1e0);
  puVar1 = PTR__environment_0003f028;
  _CreateNewWindow(6,0x2800000,local_14,PTR__environment_0003f028);
  _SetWindowTitleWithCFString(*(undefined4 *)puVar1,&cf_BubbleTroubleX);
  if (*(int *)puVar1 == 0) {
    _StdError("Cannot create the game window (perhaps low on memory?).",0);
    _CleanUp();
  }
  _SetToScreen();
  _SetRect(puVar1 + 10,0,0,0x280,0x1e0);
  *(undefined2 *)(puVar1 + 0x1a) = 0;
  *(undefined2 *)(puVar1 + 0x1c) = 0;
  _RepositionWindow(*(undefined4 *)puVar1,0,1);
  return;
}


// ==== _GetMonRect @ 00010227 ====

void _GetMonRect(undefined4 param_1)

{
  _SetRect(param_1,0,0,0,0);
  return;
}


// ==== _CheckEnvironment @ 0001025a ====

void _CheckEnvironment(void)

{
  return;
}


// ==== _RezlibFadeOut @ 0001025f ====

void _RezlibFadeOut(void)

{
  int iVar1;
  undefined4 local_10 [2];
  
  if ((_gFadedOut == '\0') && (PTR__environment_0003f028[0x26] == '\0')) {
    _CGAcquireDisplayFadeReservation(0x3f19999a,local_10);
    iVar1 = _CGDisplayFade(local_10[0],0x3f19999a,0,0x3f800000,0,0,0,1);
    if (iVar1 != 0) {
      _StdError("Cannot fade main screen to black with gamma fade.",iVar1);
    }
    _CGReleaseDisplayFadeReservation(local_10[0]);
    _gFadedOut = '\x01';
  }
  return;
}


// ==== _RezlibFadeIn @ 000102eb ====

void _RezlibFadeIn(void)

{
  int iVar1;
  undefined4 local_10 [2];
  
  if (_gFadedOut != '\0') {
    _CGAcquireDisplayFadeReservation(0x3f19999a,local_10);
    iVar1 = _CGDisplayFade(local_10[0],0x3f19999a,0x3f800000,0,0,0,0,1);
    if (iVar1 != 0) {
      _StdError("Cannot from black to normal.",iVar1);
    }
    _CGReleaseDisplayFadeReservation(local_10[0]);
    _gFadedOut = '\0';
  }
  return;
}


// ==== _CanUseFades @ 0001036c ====

undefined4 _CanUseFades(void)

{
  return 1;
}


// ==== _InitWeapon @ 00010376 ====

void _InitWeapon(void)

{
  undefined *puVar1;
  
  *PTR__gWeapon_000340e8 = 0;
  *PTR__gWeaponAmmo_000340ec = 0;
  *PTR__gWeaponInfoHasChanged_000340e4 = 1;
  *(undefined2 *)PTR__gTimeOfLastWepLaunch_000340d8 = 0;
  puVar1 = PTR__gWeaponImageR_000340dc;
  *(undefined2 *)(PTR__gWeaponImageR_000340dc + 2) = 0x140;
  *(undefined2 *)puVar1 = 0x1be;
  *(undefined2 *)(puVar1 + 6) = 0x168;
  *(undefined2 *)(puVar1 + 4) = 0x1e6;
  puVar1 = PTR__gWeaponNumR_000340e0;
  *(undefined2 *)(PTR__gWeaponNumR_000340e0 + 2) = 0x167;
  *(undefined2 *)puVar1 = 0x1c2;
  *(undefined2 *)(puVar1 + 6) = 399;
  *(undefined2 *)(puVar1 + 4) = 0x1ea;
  return;
}


// ==== _RequestWeaponDraw @ 000103d5 ====

void _RequestWeaponDraw(void)

{
  if (*PTR__gWeapon_000340e8 != '\0') {
    *PTR__gWeaponInfoHasChanged_000340e4 = 1;
  }
  return;
}


// ==== _DecreaseAmmo @ 000103ec ====

void _DecreaseAmmo(void)

{
  char cVar1;
  
  cVar1 = *PTR__gWeaponAmmo_000340ec;
  *PTR__gWeaponAmmo_000340ec = cVar1 + -1;
  if ((char)(cVar1 + -1) == '\0') {
    *PTR__gWeapon_000340e8 = 0;
  }
  *PTR__gWeaponInfoHasChanged_000340e4 = 1;
  return;
}


// ==== _IncreaseAmmo @ 00010412 ====

void _IncreaseAmmo(char param_1)

{
  if ((char)*PTR__gWeaponAmmo_000340ec < '\t') {
    *PTR__gWeaponAmmo_000340ec = *PTR__gWeaponAmmo_000340ec + param_1;
    *PTR__gWeaponInfoHasChanged_000340e4 = 1;
  }
  return;
}


// ==== _NewWeapon @ 00010434 ====

void _NewWeapon(char param_1)

{
  *PTR__gWeapon_000340e8 = param_1;
  *PTR__gWeaponInfoHasChanged_000340e4 = 1;
  if (param_1 == '\x01') {
    *PTR__gWeaponAmmo_000340ec = 0x1e;
  }
  return;
}


// ==== _DrawWeaponInfo @ 00010459 ====

void _DrawWeaponInfo(void)

{
  return;
}


// ==== _LaunchWeapon @ 0001045e ====

void _LaunchWeapon(void)

{
  char cVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined2 uVar4;
  uint uVar5;
  
  puVar3 = PTR__gWeapon_000340e8;
  if (*PTR__gWeapon_000340e8 != '\0') {
    uVar5 = _GetFrameCounter();
    puVar2 = PTR__gTimeOfLastWepLaunch_000340d8;
    if ((*(ushort *)PTR__gTimeOfLastWepLaunch_000340d8 + 0xf <= (uVar5 & 0xffff)) &&
       (*puVar3 == '\x01')) {
      uVar4 = _GetFrameCounter();
      *(undefined2 *)puVar2 = uVar4;
      cVar1 = *PTR__gWeaponAmmo_000340ec;
      *PTR__gWeaponAmmo_000340ec = cVar1 + -1;
      if ((char)(cVar1 + -1) == '\0') {
        *puVar3 = 0;
      }
      *PTR__gWeaponInfoHasChanged_000340e4 = 1;
    }
  }
  return;
}


// ==== _SetScore @ 000104b3 ====

void _SetScore(int param_1)

{
  **(int **)PTR__gEScore_000340f0 = param_1 + 0x129;
  *(int *)PTR__gStackScore_000340fc = param_1;
  return;
}


// ==== _SetLives @ 000104d1 ====

void _SetLives(short param_1)

{
  **(short **)PTR__gELives_00034100 = param_1 + 0x10d;
  *(short *)PTR__gStackLives_00034108 = param_1;
  return;
}


// ==== _SetLevel @ 000104f1 ====

void _SetLevel(short param_1)

{
  **(short **)PTR__gELevel_000340f8 = param_1 + 0xc0;
  *(short *)PTR__gStackLevel_00034104 = param_1;
  return;
}


// ==== _AddScore @ 00010511 ====

void _AddScore(int param_1)

{
  **(int **)PTR__gEScore_000340f0 = **(int **)PTR__gEScore_000340f0 + param_1;
  *(int *)PTR__gStackScore_000340fc = *(int *)PTR__gStackScore_000340fc + param_1;
  return;
}


// ==== _GetScore @ 00010529 ====

undefined4 _GetScore(void)

{
  return *(undefined4 *)PTR__gStackScore_000340fc;
}


// ==== _NextLevel @ 00010535 ====

void _NextLevel(void)

{
  **(short **)PTR__gELevel_000340f8 = **(short **)PTR__gELevel_000340f8 + 1;
  *(short *)PTR__gStackLevel_00034104 = *(short *)PTR__gStackLevel_00034104 + 1;
  return;
}


// ==== _GetLevel @ 0001054e ====

int _GetLevel(void)

{
  return (int)*(short *)PTR__gStackLevel_00034104;
}


// ==== _GetPtrLevel @ 0001055b ====

int _GetPtrLevel(void)

{
  return (int)(short)(**(short **)PTR__gELevel_000340f8 + -0xc0);
}


// ==== _AddLives @ 0001056f ====

void _AddLives(short param_1)

{
  **(short **)PTR__gELives_00034100 = **(short **)PTR__gELives_00034100 + param_1;
  *(short *)PTR__gStackLives_00034108 = *(short *)PTR__gStackLives_00034108 + param_1;
  return;
}


// ==== _SubtractLife @ 0001058a ====

void _SubtractLife(void)

{
  **(short **)PTR__gELives_00034100 = **(short **)PTR__gELives_00034100 + -1;
  *(short *)PTR__gStackLives_00034108 = *(short *)PTR__gStackLives_00034108 + -1;
  return;
}


// ==== _GetLives @ 000105a3 ====

int _GetLives(void)

{
  return (int)*(short *)PTR__gStackLives_00034108;
}


// ==== _IsHacked @ 000105b0 ====

undefined1 _IsHacked(void)

{
  return *PTR__gHacked_000340f4;
}


// ==== _SetHacked @ 000105bd ====

void _SetHacked(undefined1 param_1)

{
  *PTR__gHacked_000340f4 = param_1;
  return;
}


// ==== _GetBogusContestScore @ 000105cc ====

int _GetBogusContestScore(void)

{
  return *(int *)PTR__gStackScore_000340fc + 4000000;
}


// ==== _CheckForHacking @ 000105dd ====

void _CheckForHacking(void)

{
  if (*(int *)PTR__gStackScore_000340fc + 0x129 != **(int **)PTR__gEScore_000340f0) {
    **(int **)PTR__gEScore_000340f0 = *(int *)PTR__gStackScore_000340fc + 0x129;
    *PTR__gHacked_000340f4 = 1;
  }
  if (*(short *)PTR__gStackLives_00034108 + 0x10d != (int)**(short **)PTR__gELives_00034100) {
    **(short **)PTR__gELives_00034100 = *(short *)PTR__gStackLives_00034108 + 0x10d;
    *PTR__gHacked_000340f4 = 1;
  }
  if (*(short *)PTR__gStackLevel_00034104 + 0xc0 != (int)**(short **)PTR__gELevel_000340f8) {
    **(short **)PTR__gELevel_000340f8 = *(short *)PTR__gStackLevel_00034104 + 0xc0;
    *PTR__gHacked_000340f4 = 1;
  }
  return;
}


// ==== _InitEncryption @ 00010664 ====

void _InitEncryption(void)

{
  undefined4 *puVar1;
  undefined2 *puVar2;
  
  puVar1 = (undefined4 *)_NewPtr(4);
  *(undefined4 **)PTR__gEScore_000340f0 = puVar1;
  *puVar1 = 0x129;
  *(undefined4 *)PTR__gStackScore_000340fc = 0;
  puVar2 = (undefined2 *)_NewPtr(2);
  *(undefined2 **)PTR__gELives_00034100 = puVar2;
  *puVar2 = 0x10d;
  *(undefined2 *)PTR__gStackLives_00034108 = 0;
  puVar2 = (undefined2 *)_NewPtr(2);
  *(undefined2 **)PTR__gELevel_000340f8 = puVar2;
  *puVar2 = 0xc1;
  *(undefined2 *)PTR__gStackLevel_00034104 = 1;
  *PTR__gHacked_000340f4 = 0;
  return;
}


// ==== _ResetMenuStars @ 000106df ====

void _ResetMenuStars(void)

{
  undefined2 *puVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined2 *puVar4;
  undefined4 uVar5;
  
  puVar1 = (undefined2 *)(PTR__gMenuStars_00034118 + 0x168);
  puVar4 = (undefined2 *)PTR__gMenuStars_00034118;
  do {
    *puVar4 = 0;
    puVar4[1] = 0;
    puVar4[2] = 0;
    *(undefined4 *)(puVar4 + 4) = 0;
    puVar4 = puVar4 + 6;
  } while (puVar4 != puVar1);
  *(undefined2 *)PTR__gNextMenuStar_00034110 = 0;
  uVar5 = _TickCount();
  *(undefined4 *)PTR__gLastMenuStarTime_00034114 = uVar5;
  puVar2 = PTR__gLastMenuStarPoint_0003410c;
  _GetMouse(PTR__gLastMenuStarPoint_0003410c);
  puVar3 = PTR__environment_0003f028;
  *(short *)(puVar2 + 2) =
       (*(short *)(puVar2 + 2) - *(short *)(PTR__environment_0003f028 + 0xc)) + -0xd;
  *(short *)puVar2 = (*(short *)puVar2 - *(short *)(puVar3 + 10)) + -0xd;
  return;
}


// ==== _ProcessMenuStars @ 0001075d ====

void _ProcessMenuStars(void)

{
  short *psVar1;
  undefined *puVar2;
  short sVar3;
  short sVar4;
  short sVar5;
  short sVar6;
  short sVar7;
  int iVar8;
  undefined4 uVar9;
  short sVar10;
  undefined *puVar11;
  short *psVar12;
  short *psVar13;
  int *piVar14;
  short *local_34;
  undefined4 local_28;
  undefined4 local_24;
  short local_20;
  short local_1e;
  
  _UsingQDPlotting();
  iVar8 = _TickCount();
  if (1 < (uint)(iVar8 - *(int *)PTR__gLastMenuStarTime_00034114)) {
    _GetMouse(&local_20);
    local_1e = (local_1e - *(short *)(PTR__environment_0003f028 + 0xc)) + -0xd;
    local_20 = (local_20 - *(short *)(PTR__environment_0003f028 + 10)) + -0xd;
    if ((local_1e != *(short *)(PTR__gLastMenuStarPoint_0003410c + 2)) ||
       (local_20 != *(short *)PTR__gLastMenuStarPoint_0003410c)) {
      sVar6 = _GetRandomFast(0,0x14);
      sVar7 = _GetRandomFast(0,0x14);
      puVar2 = PTR__gMenuStars_00034118;
      puVar11 = PTR__gNextMenuStar_00034110;
      sVar10 = sVar6 + -10 + local_1e;
      sVar6 = sVar7 + -10 + local_20;
      if (sVar10 < 0x267) {
        local_1e = 0;
        if (-1 < sVar10) {
          local_1e = sVar10;
        }
      }
      else {
        local_1e = 0x266;
      }
      if (sVar6 < 0x1c7) {
        local_20 = 0;
        if (-1 < sVar6) {
          local_20 = sVar6;
        }
      }
      else {
        local_20 = 0x1c6;
      }
      iVar8 = *(short *)PTR__gNextMenuStar_00034110 * 0xc;
      *(undefined2 *)(PTR__gMenuStars_00034118 + iVar8) = 1;
      *(short *)(puVar2 + iVar8 + 2) = local_1e;
      *(short *)(puVar2 + iVar8 + 4) = local_20;
      uVar9 = _TickCount();
      *(undefined4 *)(puVar2 + iVar8 + 8) = uVar9;
      sVar7 = *(short *)puVar11 + 1;
      sVar6 = 0;
      if (sVar7 < 0x1e) {
        sVar6 = sVar7;
      }
      *(short *)puVar11 = sVar6;
      uVar9 = _TickCount();
      *(undefined4 *)PTR__gLastMenuStarTime_00034114 = uVar9;
      puVar11 = PTR__gLastMenuStarPoint_0003410c;
      _GetMouse(PTR__gLastMenuStarPoint_0003410c);
      puVar2 = PTR__environment_0003f028;
      *(short *)(puVar11 + 2) =
           (*(short *)(puVar11 + 2) - *(short *)(PTR__environment_0003f028 + 0xc)) + -0xd;
      *(short *)puVar11 = (*(short *)puVar11 - *(short *)(puVar2 + 10)) + -0xd;
    }
  }
  psVar13 = (short *)PTR__gMenuStars_00034118;
  psVar12 = (short *)PTR__gMenuStars_00034118;
  do {
    if (*psVar12 != 0) {
      _SetRect(&local_28,(int)psVar12[1],(int)psVar12[2],(int)(short)(psVar12[1] + 0x1a),
               (int)(short)(psVar12[2] + 0x1a));
      _SetToBgndGWorld();
      _CopyCompToBgnd(local_28,local_24,local_28,local_24,0);
      _SetToScreen();
    }
    psVar12 = psVar12 + 6;
    psVar1 = (short *)((int)psVar13 + 0x168);
  } while (psVar1 != psVar12);
  do {
    sVar6 = *psVar13;
    if ((sVar6 != 0) && (sVar6 != 6)) {
      _SpriteToBgnd(0,(int)psVar13[1],(int)psVar13[2],0x28,(int)sVar6);
    }
    psVar13 = psVar13 + 6;
  } while (psVar1 != psVar13);
  local_34 = (short *)PTR__gMenuStars_00034118;
  do {
    if (*local_34 != 0) {
      _SetRect(&local_28,(int)local_34[1],(int)local_34[2],(int)(short)(local_34[1] + 0x1a),
               (int)(short)(local_34[2] + 0x1a));
      sVar4 = (short)local_24;
      sVar5 = local_24._2_2_;
      sVar10 = (short)local_28;
      sVar3 = local_28._2_2_;
      sVar6 = *(short *)(PTR__environment_0003f028 + 0xc);
      sVar7 = *(short *)(PTR__environment_0003f028 + 10);
      _SetToScreen();
      _BgndToScreen(local_28,local_24,CONCAT22(sVar3 + sVar6,sVar10 + sVar7),
                    CONCAT22(sVar5 + sVar6,sVar4 + sVar7),0);
    }
    local_34 = local_34 + 6;
  } while (psVar1 != local_34);
  piVar14 = (int *)(PTR__gMenuStars_00034118 + 8);
  puVar11 = PTR__gMenuStars_00034118;
  do {
    if (((short)piVar14[-2] != 0) &&
       (iVar8 = _TickCount(), puVar11 = PTR__gMenuStars_00034118, 3 < (uint)(iVar8 - *piVar14))) {
      *(short *)(piVar14 + -2) = (short)piVar14[-2] + 1;
      iVar8 = _TickCount();
      *piVar14 = iVar8;
      puVar11 = PTR__gMenuStars_00034118;
      if (6 < (short)piVar14[-2]) {
        *(undefined2 *)(piVar14 + -2) = 0;
        puVar11 = PTR__gMenuStars_00034118;
      }
    }
    piVar14 = piVar14 + 3;
  } while ((int *)(puVar11 + 0x170) != piVar14);
  return;
}


// ==== _CustomCompToBgnd @ 00010ac4 ====

void _CustomCompToBgnd(void)

{
  return;
}


// ==== _Useless5 @ 00010ac9 ====

int _Useless5(void)

{
  int iVar1;
  int iVar2;
  
  iVar1 = _RT3_GetHoursUsed();
  iVar2 = _RT3_GetDaysHad();
  return iVar1 + iVar2;
}


// ==== _Useless8 @ 00010ae6 ====

int __regparm3 _Useless8(char param_1)

{
  int iVar1;
  
  if (param_1 == '\0') {
    iVar1 = 7;
  }
  else {
    iVar1 = _Useless8();
    iVar1 = iVar1 * 3;
  }
  return iVar1;
}


// ==== _DrawNumEnemies @ 00010b06 ====

void _DrawNumEnemies(void)

{
  undefined *puVar1;
  undefined1 local_324 [256];
  char local_224 [4];
  char local_220 [4];
  char local_21c [4];
  char local_218 [4];
  char local_214 [2];
  char local_212;
  undefined1 local_211 [237];
  char local_124 [4];
  char local_120 [4];
  char local_11c [4];
  char local_118 [4];
  char local_114 [2];
  char local_112;
  undefined1 local_111 [237];
  short local_24;
  short local_22;
  short local_20;
  undefined2 local_1e;
  
  local_124 = (char  [4])s_Enemies_Active___00030e1c._0_4_;
  local_120 = (char  [4])s_Enemies_Active___00030e1c._4_4_;
  local_11c = (char  [4])s_Enemies_Active___00030e1c._8_4_;
  local_118 = (char  [4])s_Enemies_Active___00030e1c._12_4_;
  local_114 = (char  [2])s_Enemies_Active___00030e1c._16_2_;
  local_112 = s_Enemies_Active___00030e1c[0x12];
  _memset(local_111,0,0xed);
  local_224[0] = s_Enemies_Killed___00030e30[0];
  local_224[1] = s_Enemies_Killed___00030e30[1];
  local_224[2] = s_Enemies_Killed___00030e30[2];
  local_224[3] = s_Enemies_Killed___00030e30[3];
  local_220[0] = s_Enemies_Killed___00030e30[4];
  local_220[1] = s_Enemies_Killed___00030e30[5];
  local_220[2] = s_Enemies_Killed___00030e30[6];
  local_220[3] = s_Enemies_Killed___00030e30[7];
  local_21c[0] = s_Enemies_Killed___00030e30[8];
  local_21c[1] = s_Enemies_Killed___00030e30[9];
  local_21c[2] = s_Enemies_Killed___00030e30[10];
  local_21c[3] = s_Enemies_Killed___00030e30[0xb];
  local_218[0] = s_Enemies_Killed___00030e30[0xc];
  local_218[1] = s_Enemies_Killed___00030e30[0xd];
  local_218[2] = s_Enemies_Killed___00030e30[0xe];
  local_218[3] = s_Enemies_Killed___00030e30[0xf];
  local_214[0] = s_Enemies_Killed___00030e30[0x10];
  local_214[1] = s_Enemies_Killed___00030e30[0x11];
  local_212 = s_Enemies_Killed___00030e30[0x12];
  _memset(local_211,0,0xed);
  _SetToScreen();
  puVar1 = PTR__environment_0003f028;
  local_22 = 10;
  local_24 = *(short *)(PTR__environment_0003f028 + 10) + -0x28;
  local_1e = 0x6e;
  local_20 = *(short *)(PTR__environment_0003f028 + 10) + -0x18;
  _PaintRect(&local_24);
  _ForeColor(0x1e);
  _MoveTo((int)(short)(local_22 + 4),(int)(short)(local_20 + -4));
  _DrawString(local_124);
  _NumToString((int)(char)*PTR__gNumEnemiesActive_00034120,local_324);
  _ForeColor(0x1e);
  _DrawString(local_324);
  _ForeColor(0x21);
  local_22 = 10;
  local_24 = *(short *)(puVar1 + 10) + 10;
  local_1e = 0x6e;
  local_20 = *(short *)(puVar1 + 10) + 0x1a;
  _PaintRect(&local_24);
  _ForeColor(0x1e);
  _MoveTo((int)(short)(local_22 + 4),(int)(short)(local_20 + -4));
  _DrawString(local_224);
  _NumToString((int)_gNumEnemiesSquished,local_324);
  _ForeColor(0x1e);
  _DrawString(local_324);
  _ForeColor(0x21);
  return;
}


// ==== _DrawEnemyCheckIndicator @ 00010d1a ====

void _DrawEnemyCheckIndicator(char param_1)

{
  char *pcVar1;
  char local_214 [4];
  char local_210 [4];
  char local_20c [4];
  char local_208 [2];
  char local_206;
  undefined1 local_205 [241];
  char local_114 [4];
  char local_110 [4];
  char local_10c [2];
  char local_10a;
  undefined1 local_109 [245];
  undefined2 local_14;
  short local_12;
  short local_10;
  undefined2 local_e;
  
  local_114 = (char  [4])s_Checking_00030e44._0_4_;
  local_110 = (char  [4])s_Checking_00030e44._4_4_;
  local_10c = (char  [2])s_Checking_00030e44._8_2_;
  local_10a = s_Checking_00030e44[10];
  _memset(local_109,0,0xf5);
  local_214[0] = s_Not_Checking_00030e50[0];
  local_214[1] = s_Not_Checking_00030e50[1];
  local_214[2] = s_Not_Checking_00030e50[2];
  local_214[3] = s_Not_Checking_00030e50[3];
  local_210[0] = s_Not_Checking_00030e50[4];
  local_210[1] = s_Not_Checking_00030e50[5];
  local_210[2] = s_Not_Checking_00030e50[6];
  local_210[3] = s_Not_Checking_00030e50[7];
  local_20c[0] = s_Not_Checking_00030e50[8];
  local_20c[1] = s_Not_Checking_00030e50[9];
  local_20c[2] = s_Not_Checking_00030e50[10];
  local_20c[3] = s_Not_Checking_00030e50[0xb];
  local_208[0] = s_Not_Checking_00030e50[0xc];
  local_208[1] = s_Not_Checking_00030e50[0xd];
  local_206 = s_Not_Checking_00030e50[0xe];
  _memset(local_205,0,0xf1);
  _SetToScreen();
  local_12 = 10;
  local_14 = 200;
  local_e = 0x46;
  local_10 = 0xd8;
  _PaintRect(&local_14);
  if (param_1 == '\0') {
    _ForeColor(0xcd);
    _MoveTo((int)(short)(local_12 + 4),(int)(short)(local_10 + -4));
    pcVar1 = local_214;
  }
  else {
    _ForeColor(0x1e);
    _MoveTo((int)(short)(local_12 + 4),(int)(short)(local_10 + -4));
    pcVar1 = local_114;
  }
  _DrawString(pcVar1);
  _ForeColor(0x21);
  return;
}


// ==== _ResetEnemy @ 00010e78 ====

void _ResetEnemy(char param_1)

{
  PTR__enemy_0003f04c[param_1 * 0x5c] = 0;
  *PTR__gNumEnemiesActive_00034120 = *PTR__gNumEnemiesActive_00034120 + -1;
  return;
}


// ==== _AreAllEnemiesSquished @ 00010e9b ====

bool _AreAllEnemiesSquished(void)

{
  return *(short *)(PTR__level_0003f010 + 0xc) <= (short)_gNumEnemiesSquished;
}


// ==== _FinishLevel @ 00010eb7 ====

void _FinishLevel(void)

{
  _gNumEnemiesSquished = (char)*(undefined2 *)(PTR__level_0003f010 + 0xc);
  return;
}


// ==== _WasEnemySquished @ 00010eca ====

int _WasEnemySquished(undefined4 param_1)

{
  undefined *puVar1;
  char cVar2;
  int iVar3;
  char *pcVar4;
  int iVar5;
  char *local_28;
  
  puVar1 = PTR__enemy_0003f04c;
  iVar3 = 0;
  local_28 = PTR__enemy_0003f04c + 0x43;
  iVar5 = 0;
  pcVar4 = PTR__enemy_0003f04c;
  while (((((cVar2 = *pcVar4, cVar2 != '\x01' && (cVar2 != '\x04')) && (cVar2 != '\x05')) &&
          ((cVar2 != '\x06' && (cVar2 != '\x03')))) ||
         (cVar2 = _RectsCollide(param_1,puVar1 + iVar5 + 0x12), cVar2 == '\0'))) {
    iVar3 = iVar3 + 1;
    iVar5 = iVar5 + 0x5c;
    local_28 = local_28 + 0x5c;
    pcVar4 = pcVar4 + 0x5c;
    if (iVar3 == 0x1e) {
      return -1;
    }
  }
  if (puVar1[iVar5] != '\x06') {
    return iVar3;
  }
  _Balloons_PopBalloon((int)*local_28);
  return iVar3;
}


// ==== _KillEnemy @ 00010f57 ====

void _KillEnemy(char param_1,char param_2)

{
  undefined *puVar1;
  
  puVar1 = PTR__enemy_0003f04c;
  PTR__enemy_0003f04c[param_1 * 0x5c + 0x47] = 1;
  puVar1[param_1 * 0x5c + 0x46] = 0;
  _gNumEnemiesSquished = _gNumEnemiesSquished + '\x01';
  if (param_2 != '\0') {
    PTR__gMaze_0003f054
    [(int)(char)puVar1[param_1 * 0x5c + 0x24] + (char)puVar1[param_1 * 0x5c + 0x30] * 0x10] = 0;
  }
  return;
}


// ==== _CaptureEnemy @ 00010fa6 ====

void _CaptureEnemy(char param_1,undefined1 param_2)

{
  undefined *puVar1;
  undefined2 uVar2;
  int iVar3;
  
  puVar1 = PTR__enemy_0003f04c;
  iVar3 = param_1 * 0x5c;
  PTR__enemy_0003f04c[iVar3] = 6;
  uVar2 = _GetFrameCounter();
  *(undefined2 *)(puVar1 + iVar3 + 2) = uVar2;
  *(undefined2 *)(puVar1 + iVar3 + 0x3a) = 0x20;
  *(short *)(puVar1 + iVar3 + 0x40) = (short)(char)puVar1[iVar3 + 0x10];
  puVar1[iVar3 + 0x43] = param_2;
  return;
}


// ==== _ReleaseEnemyFromBalloon @ 00010ff3 ====

void _ReleaseEnemyFromBalloon(char param_1)

{
  int iVar1;
  char cVar2;
  undefined *puVar3;
  undefined2 uVar4;
  int iVar5;
  
  puVar3 = PTR__enemy_0003f04c;
  iVar5 = (int)param_1;
  iVar1 = iVar5 * 0x5c;
  if (PTR__enemy_0003f04c[iVar1] == '\x05') {
    return;
  }
  PTR__enemy_0003f04c[iVar1] = 1;
  uVar4 = _GetFrameCounter();
  *(undefined2 *)(puVar3 + iVar1 + 2) = uVar4;
  cVar2 = puVar3[iVar1 + 0x10];
  if (cVar2 == '\x02') {
    *(undefined2 *)(puVar3 + iVar1 + 0x3a) = 0x1c;
  }
  else if (cVar2 < '\x03') {
    if (cVar2 == '\x01') {
      *(undefined2 *)(puVar3 + iVar1 + 0x3a) = 0x1b;
    }
  }
  else if (cVar2 == '\x03') {
    *(undefined2 *)(puVar3 + iVar1 + 0x3a) = 0x1d;
  }
  else if (cVar2 == '\x04') {
    *(undefined2 *)(puVar3 + iVar1 + 0x3a) = 0x1e;
  }
  if (*(short *)(PTR__enemy_0003f04c + iVar5 * 0x5c + 0x3a) != 0x1e) {
    cVar2 = PTR__enemy_0003f04c[iVar5 * 0x5c + 0x23];
    if (cVar2 == '\x02') {
      *(undefined2 *)(PTR__enemy_0003f04c + iVar5 * 0x5c + 0x40) = 4;
      return;
    }
    if ('\x02' < cVar2) {
      if (cVar2 == '\x03') {
        *(undefined2 *)(PTR__enemy_0003f04c + iVar5 * 0x5c + 0x40) = 7;
        return;
      }
      if (cVar2 != '\x04') {
        return;
      }
      *(undefined2 *)(PTR__enemy_0003f04c + iVar5 * 0x5c + 0x40) = 10;
      return;
    }
    if (cVar2 != '\x01') {
      return;
    }
  }
  *(undefined2 *)(PTR__enemy_0003f04c + iVar5 * 0x5c + 0x40) = 1;
  return;
}


// ==== _StopAllEnemies @ 000110c8 ====

void _StopAllEnemies(void)

{
  undefined *puVar1;
  undefined2 uVar2;
  undefined2 *puVar3;
  
  puVar1 = PTR__enemy_0003f04c;
  puVar3 = (undefined2 *)(PTR__enemy_0003f04c + 2);
  do {
    if ((*(byte *)(puVar3 + -1) < 7) && ((1 << (*(byte *)(puVar3 + -1) & 0x1f) & 0x5eU) != 0)) {
      *(undefined1 *)(puVar3 + -1) = 5;
      uVar2 = _GetFrameCounter();
      *puVar3 = uVar2;
    }
    puVar3 = puVar3 + 0x2e;
  } while (puVar3 != (undefined2 *)(puVar1 + 0xaca));
  return;
}


// ==== _InitEnemies @ 0001111b ====

void _InitEnemies(void)

{
  undefined1 *puVar1;
  undefined *puVar2;
  undefined1 uVar3;
  undefined *puVar4;
  undefined *puVar5;
  
  puVar2 = PTR__gNumEnemiesActive_00034120;
  puVar1 = PTR__enemy_0003f04c + 0xac8;
  puVar4 = PTR__enemy_0003f04c;
  puVar5 = PTR__gREGCHECK1registered_0003411c;
  do {
    *puVar4 = 0;
    *puVar2 = *puVar2 + -1;
    uVar3 = _RT3_IsRegistered();
    *puVar5 = uVar3;
    puVar4 = puVar4 + 0x5c;
    puVar5 = puVar5 + 1;
  } while (puVar1 != puVar4);
  _gNumEnemiesSquished = 0;
  *puVar2 = 0;
  _gEnemy_LastColour = 1;
  return;
}


// ==== _DrawEnemiesToComp @ 00011170 ====

void _DrawEnemiesToComp(void)

{
  char cVar1;
  undefined4 *puVar2;
  int iVar3;
  undefined *puVar4;
  undefined4 *local_30;
  undefined1 local_24 [20];
  
  iVar3 = 0;
  puVar2 = (undefined4 *)(PTR__enemy_0003f04c + 0x1a);
  puVar4 = PTR__enemy_0003f04c + 0x10;
  local_30 = puVar2;
LAB_0001120e:
  do {
    if (*(char *)((int)puVar2 + -0x1a) != '\0') {
      if (*(char *)(puVar2 + 0xb) == '\0') {
        _AddRectToScreen(local_30);
        cVar1 = *(char *)((int)puVar2 + 0x2d);
      }
      else {
        _SpriteToComp(0,(int)*(short *)((int)puVar2 + -6),(int)*(short *)(puVar2 + -2),
                      (int)*(short *)(puVar2 + 8),(int)*(short *)((int)puVar2 + 0x26),1);
        _UnionRect(puVar4 + 10,puVar4 + 2,local_24);
        _AddRectToScreen(local_24);
        cVar1 = *(char *)((int)puVar2 + 0x2d);
      }
      if (cVar1 == '\0') {
        *puVar2 = puVar2[-2];
        puVar2[1] = puVar2[-1];
        iVar3 = iVar3 + 1;
        puVar4 = puVar4 + 0x5c;
        local_30 = local_30 + 0x17;
        puVar2 = puVar2 + 0x17;
        if (iVar3 == 0x1e) {
          return;
        }
        goto LAB_0001120e;
      }
      *(undefined1 *)((int)puVar2 + -0x1a) = 0;
      *PTR__gNumEnemiesActive_00034120 = *PTR__gNumEnemiesActive_00034120 + -1;
    }
    iVar3 = iVar3 + 1;
    puVar4 = puVar4 + 0x5c;
    local_30 = local_30 + 0x17;
    puVar2 = puVar2 + 0x17;
    if (iVar3 == 0x1e) {
      return;
    }
  } while( true );
}


// ==== _PopEnemy @ 00011254 ====

void _PopEnemy(char param_1)

{
  char *pcVar1;
  undefined *puVar2;
  
  puVar2 = PTR__enemy_0003f04c;
  pcVar1 = PTR__enemy_0003f04c + param_1 * 0x5c;
  if ((pcVar1[0x47] == '\0') && (*pcVar1 != '\0')) {
    _PlayMySnd(0,10,0);
    _AddToScore(100,1);
    _NewPoint((int)*(short *)(pcVar1 + 0x14),(int)*(short *)(pcVar1 + 0x12),1,0xc);
    puVar2[param_1 * 0x5c + 0x47] = 1;
    puVar2[param_1 * 0x5c + 0x46] = 0;
    _gNumEnemiesSquished = _gNumEnemiesSquished + '\x01';
    PTR__gMaze_0003f054
    [(int)(char)puVar2[param_1 * 0x5c + 0x24] + (char)puVar2[param_1 * 0x5c + 0x30] * 0x10] = 0;
  }
  return;
}


// ==== _SquishEnemy @ 0001131b ====

void _SquishEnemy(char param_1,char param_2)

{
  char cVar1;
  char cVar2;
  short sVar3;
  undefined *puVar4;
  char *pcVar5;
  int iVar6;
  int iVar7;
  undefined4 uVar8;
  
  iVar6 = (int)param_1;
  pcVar5 = PTR__enemy_0003f04c + iVar6 * 0x5c;
  if (pcVar5[0x47] != '\0') {
    return;
  }
  if (*pcVar5 == '\0') {
    return;
  }
  if (0x13 < *(short *)(pcVar5 + 0x3e)) {
    *(short *)(pcVar5 + 0x3e) = *(short *)(pcVar5 + 0x3e) + 2;
  }
  if (*(short *)(pcVar5 + 0x3e) == 0x13) {
    *(undefined2 *)PTR__gTopRef_0003f058 = *(undefined2 *)PTR__gSavedRef_0003f048;
  }
  else {
    *(short *)PTR__gTopRef_0003f058 = *(short *)PTR__gTopRef_0003f058 + 1;
  }
  _PlayMySnd(0,10,0);
  iVar7 = (int)param_2;
  if (param_2 == '\x02') {
    _AddToScore(400,1);
    uVar8 = 4;
LAB_000114e9:
    _NewPoint((int)*(short *)(PTR__enemy_0003f04c + iVar6 * 0x5c + 0x14),
              (int)*(short *)(PTR__enemy_0003f04c + iVar6 * 0x5c + 0x12),uVar8,0xc);
  }
  else {
    if (param_2 < '\x03') {
      if (param_2 == '\x01') {
        _AddToScore(200,1);
        uVar8 = 2;
        goto LAB_000114e9;
      }
LAB_000113bd:
      _AddToScore(0xc80,1);
      _NewPoint((int)*(short *)(PTR__enemy_0003f04c + iVar6 * 0x5c + 0x14),
                (int)*(short *)(PTR__enemy_0003f04c + iVar6 * 0x5c + 0x12),0x18,0xc);
    }
    else if (param_2 == '\x03') {
      _AddToScore(800,1);
      _PlayMySnd(0x26,10,0xf);
      _NewPoint((int)*(short *)(PTR__enemy_0003f04c + iVar6 * 0x5c + 0x14),
                (int)*(short *)(PTR__enemy_0003f04c + iVar6 * 0x5c + 0x12),8,0xc);
      iVar7 = 3;
    }
    else {
      if (param_2 != '\x04') goto LAB_000113bd;
      _AddToScore(0x640,1);
      _NewPoint((int)*(short *)(PTR__enemy_0003f04c + iVar6 * 0x5c + 0x14),
                (int)*(short *)(PTR__enemy_0003f04c + iVar6 * 0x5c + 0x12),0xb,0xc);
      iVar7 = 4;
    }
    _Bonus_SetNumEnemySquishes(iVar7);
  }
  puVar4 = PTR__enemy_0003f04c;
  PTR__enemy_0003f04c[param_1 * 0x5c + 0x47] = 1;
  puVar4[param_1 * 0x5c + 0x46] = 0;
  _gNumEnemiesSquished = _gNumEnemiesSquished + '\x01';
  PTR__gMaze_0003f054
  [(int)(char)puVar4[param_1 * 0x5c + 0x24] + (char)puVar4[param_1 * 0x5c + 0x30] * 0x10] = 0;
  _Splats_NewSplat((int)*(short *)(puVar4 + iVar6 * 0x5c + 0x14),
                   (int)*(short *)(puVar4 + iVar6 * 0x5c + 0x12),0);
  if (*(short *)(puVar4 + iVar6 * 0x5c + 0x3e) != 0x13) {
    *(short *)PTR__gTopRef_0003f058 = *(short *)PTR__gTopRef_0003f058 + -1;
  }
  iVar7 = iVar6 * 0x5c;
  if (PTR__enemy_0003f04c[iVar7] == '\x06') {
    cVar1 = PTR__enemy_0003f04c[iVar7 + 0x10];
    if (cVar1 != '\x02') {
      if (cVar1 == '\x03') goto LAB_00011661;
      if (cVar1 == '\x01') goto LAB_00011657;
    }
    uVar8 = 4;
  }
  else {
    sVar3 = *(short *)(PTR__enemy_0003f04c + iVar7 + 0x3a);
    if ((sVar3 == 0x1c) || (sVar3 == 0x1e)) {
      uVar8 = 4;
      cVar1 = PTR__enemy_0003f04c[iVar6 * 0x5c + 0x30];
      cVar2 = PTR__enemy_0003f04c[iVar6 * 0x5c + 0x24];
      goto LAB_00011685;
    }
    if (sVar3 == 0x1b) {
LAB_00011657:
      uVar8 = 3;
    }
    else {
LAB_00011661:
      uVar8 = 5;
    }
  }
  cVar1 = PTR__enemy_0003f04c[iVar7 + 0x30];
  cVar2 = PTR__enemy_0003f04c[iVar7 + 0x24];
LAB_00011685:
  _NewStarGroup(cVar2 * 0x28,cVar1 * 0x28,uVar8);
  return;
}


// ==== _SquishAllEnemies @ 0001169b ====

void _SquishAllEnemies(void)

{
  byte *pbVar1;
  int iVar2;
  char cVar3;
  
  cVar3 = '\0';
  iVar2 = 0;
  pbVar1 = PTR__enemy_0003f04c;
  do {
    if ((*pbVar1 < 7) && ((1 << (*pbVar1 & 0x1f) & 0x5eU) != 0)) {
      _SquishEnemy(iVar2,(int)cVar3);
      cVar3 = cVar3 + '\x01';
    }
    iVar2 = iVar2 + 1;
    pbVar1 = pbVar1 + 0x5c;
  } while (iVar2 != 0x1e);
  return;
}


// ==== _CheckForBombKills @ 000116eb ====

int _CheckForBombKills(undefined4 *param_1,char param_2)

{
  char cVar1;
  char *pcVar2;
  int iVar3;
  undefined *puVar4;
  short local_1e;
  
  local_1e = 0;
  iVar3 = 0;
  pcVar2 = PTR__enemy_0003f04c + 0x43;
  puVar4 = PTR__enemy_0003f04c + 0x12;
  do {
    cVar1 = pcVar2[-0x43];
    if ((((cVar1 == '\x01') || (cVar1 == '\x04')) || (cVar1 == '\x05')) ||
       ((cVar1 == '\x06' || (cVar1 == '\x03')))) {
      cVar1 = _RectsCollide(param_1,puVar4);
      if (cVar1 != '\0') {
        if (pcVar2[-0x43] == '\x06') {
          _Balloons_PopBalloon((int)*pcVar2);
        }
        local_1e = local_1e + 1;
        _SquishEnemy(iVar3,(int)(char)(param_2 + (char)local_1e));
      }
    }
    iVar3 = iVar3 + 1;
    puVar4 = puVar4 + 0x5c;
    pcVar2 = pcVar2 + 0x5c;
  } while (iVar3 != 0x1e);
  cVar1 = _IsHeroCaught(*param_1,param_1[1],1,1);
  if (cVar1 != '\0') {
    _PlayMySnd(0x2b,10,5);
    _HeroCaught(2);
  }
  return (int)local_1e;
}


// ==== _MakeAllEnemiesDisappear @ 000117d7 ====

void _MakeAllEnemiesDisappear(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  undefined *puVar3;
  ushort uVar4;
  char *pcVar5;
  int iVar6;
  undefined1 uVar7;
  byte bVar8;
  byte bVar9;
  char cVar10;
  int local_50;
  undefined *local_40;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined1 local_20;
  byte local_1f [15];
  
  _Balloons_PopAll();
  puVar3 = PTR__enemy_0003f04c;
  local_40 = PTR__enemy_0003f04c + 0x42;
  do {
    if (local_40[-0x42] == '\x05') {
      local_1f[0] = 0x49;
      local_1f[1] = 0x71;
      local_1f[2] = 0xad;
      local_30 = DAT_000335dc;
      local_2c = DAT_000335e0;
      local_28 = DAT_000335e4;
      local_24 = DAT_000335e8;
      local_20 = DAT_000335ec;
      local_50 = *(int *)(local_40 + 0x12);
      pcVar5 = (char *)_RT3_CheckLicenseName(*(undefined4 *)(local_40 + -0xe));
      uVar1 = *(undefined4 *)(local_40 + -0x1a);
      uVar2 = *(undefined4 *)(local_40 + -0x16);
      if (pcVar5 != (char *)0x0) {
        if (('/' < *pcVar5) && (*pcVar5 < ':')) {
          local_50 = 1;
        }
        while ((iVar6 = _StringGetLength(&local_30), iVar6 + 1U < 0x11 && (*pcVar5 != '\0'))) {
          _StringAppendSafe(&local_30,pcVar5,0x11);
        }
      }
      bVar8 = ((byte)local_50 ^ 0x4b ^ local_2c._3_1_) + 0xa6 ^ 0x72;
      bVar8 = bVar8 << 1 | (char)bVar8 < '\0';
      if (bVar8 < 0x42) {
        bVar8 = bVar8 ^ (byte)local_50;
      }
      bVar8 = bVar8 - 0x2e ^ local_30._2_1_;
      bVar8 = (bVar8 << 5 | bVar8 >> 3) + 0x92;
      bVar8 = (bVar8 * ' ' | bVar8 >> 3) ^ (byte)local_30;
      uVar4 = _RT3_ExtractLicenseBlock1(uVar1,uVar2);
      bVar8 = (bVar8 ^ 0x6c) + 0x7e;
      bVar8 = ((bVar8 * '@' | bVar8 >> 2) ^ 0x62 ^ local_2c._1_1_ ^ (byte)local_50) + 0x98;
      bVar8 = ((bVar8 * '\x10' | bVar8 >> 4) ^ 0x54 ^ (byte)local_50 ^ local_24._1_1_) + 0x77;
      _Useless5();
      bVar9 = bVar8 * -0x80 | bVar8 >> 1;
      bVar8 = bVar9 - 0x33;
      if ((int)local_28._2_1_ < (int)(uint)bVar8) {
        bVar8 = bVar9 + 0x2d;
      }
      bVar8 = (bVar8 << 7 | (byte)(bVar8 + 0x66) >> 1) ^ local_24._3_1_ ^ (byte)local_50;
      bVar8 = ((bVar8 << 7 | bVar8 >> 1) ^ (byte)local_50) + 0xaa;
      bVar8 = (bVar8 * '\b' | bVar8 >> 5) ^ (byte)local_28;
      if ((int)local_24._2_1_ < (int)(uint)bVar8) {
        bVar8 = bVar8 + 0x76;
      }
      bVar8 = bVar8 + 0x20;
      if (0x20 < bVar8) {
        bVar8 = bVar8 ^ local_2c._1_1_;
      }
      bVar8 = bVar8 + 0xa7 ^ local_28._3_1_;
      bVar8 = (bVar8 << 7 | bVar8 >> 1) + 0xbe;
      bVar8 = (bVar8 * '\b' | bVar8 >> 5) ^ 0x62 ^ (byte)local_50;
      cVar10 = ((bVar8 << 4 | bVar8 >> 4) ^ (byte)local_50) - 0x30;
      bVar8 = ((cVar10 * '\x02' | cVar10 < '\0') ^ 0x58U) + 0x55 ^ (byte)local_50 ^ (byte)local_24;
      bVar8 = (bVar8 << 7 | (bVar8 ^ 0x20) >> 1) + 0x9a;
      _TimerGetSeconds();
      _TimerGetSeconds();
      _TimerGetSeconds();
      _Useless8();
      bVar9 = ((bVar8 * '\b' | bVar8 >> 5) + 0x31 ^ (byte)local_50 ^ 0x6c) + 0x95 ^ 0x2d;
      bVar8 = bVar9 + 0x5e;
      if (0x4f < bVar9) {
        bVar8 = bVar9;
      }
      bVar9 = bVar8 << 6 | bVar8 >> 2;
      if (bVar9 < 0x6c) {
        _TimerGetSeconds();
      }
      bVar9 = ((bVar8 >> 2) << 6 | bVar9 >> 2) + 0x1d ^ local_2c._1_1_;
      bVar8 = bVar9 >> 2;
      cVar10 = _IsPlatformOpen();
      bVar8 = cVar10 * (bVar8 << 6 | (byte)(bVar9 << 6 | bVar8) >> 2);
      bVar8 = ((bVar8 * '\x10' | bVar8 >> 4) - 0x3f ^ 0x75 ^ (byte)local_50) + 0x31;
      bVar8 = (bVar8 * '\b' | bVar8 >> 5) - 0x29;
      bVar8 = (bVar8 * '\x10' | bVar8 >> 4) + 0x13;
      bVar8 = ((bVar8 * '\x10' | bVar8 >> 4) ^ (byte)local_50) + 0x30;
      bVar8 = (bVar8 * '\x04' | bVar8 >> 6) - 0x2f;
      if (bVar8 < 3) {
        bVar8 = local_1f[bVar8];
      }
      for (; bVar8 <= uVar4; uVar4 = uVar4 - bVar8) {
      }
      if ((local_50 == 0) || (uVar4 != 0)) {
        uVar7 = 0;
      }
      else {
        uVar7 = 1;
      }
      *local_40 = uVar7;
      bVar8 = bVar8 ^ 0x75 ^ local_30._3_1_ ^ (byte)local_50;
      local_50._0_1_ = (byte)local_50 ^ (bVar8 << 6 | bVar8 >> 2) + 0x1a;
      bVar8 = ((byte)local_50 << 2 | (byte)local_50 >> 6) + 0x13;
      if ((int)(uint)bVar8 < (int)local_2c._2_1_) {
        bVar8 = bVar8 >> 1 | bVar8 * -0x80;
      }
      if (bVar8 != local_24._1_1_) {
        _IsPlatformOpen();
      }
      local_40[5] = 1;
      *(short *)(PTR__level_0003f010 + (char)local_40[-0x32] * 2 + 0x22) =
           *(short *)(PTR__level_0003f010 + (char)local_40[-0x32] * 2 + 0x22) + 1;
      local_40[4] = 0;
    }
    else if (local_40[-0x42] != '\0') {
      local_40[-0x42] = 5;
      local_40[5] = 1;
      *(short *)(PTR__level_0003f010 + (char)local_40[-0x32] * 2 + 0x22) =
           *(short *)(PTR__level_0003f010 + (char)local_40[-0x32] * 2 + 0x22) + 1;
      local_40[4] = 0;
    }
    local_40 = local_40 + 0x5c;
  } while (local_40 != puVar3 + 0xb0a);
  return;
}


// ==== _ProcessEnemies @ 00011ad3 ====

void _ProcessEnemies(void)

{
  char *pcVar1;
  char cVar2;
  short sVar3;
  undefined4 uVar4;
  char cVar5;
  ushort uVar6;
  ushort uVar7;
  char *pcVar8;
  int iVar9;
  byte bVar10;
  byte bVar11;
  char *pcVar12;
  int iVar13;
  bool bVar14;
  bool bVar15;
  undefined4 uVar16;
  int local_58;
  ushort local_4a;
  char *local_48;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined1 local_20;
  byte local_1f [15];
  
  uVar6 = _GetFrameCounter();
  iVar13 = 0;
  pcVar12 = PTR__enemy_0003f04c + 0x31;
  local_48 = PTR__gREGCHECK1registered_0003411c;
  do {
    pcVar1 = pcVar12 + -0x31;
    if (pcVar12[-0x31] != '\0') {
      switch(pcVar12[-0x31]) {
      case '\x01':
        if (pcVar12[0x1a] == '\0') {
          _EnemyAI(iVar13);
        }
        else {
          sVar3 = *(short *)(pcVar12 + 0x13);
          *(ushort *)(pcVar12 + 0x13) = sVar3 + 1U;
          if (0xf < (ushort)(sVar3 + 1U)) {
            pcVar12[0x1a] = '\0';
            pcVar12[0x13] = '\0';
            pcVar12[0x14] = '\0';
          }
        }
        sVar3 = *(short *)(pcVar12 + 9);
        if (sVar3 == 0x1c) {
          cVar5 = pcVar12[0x1b];
          pcVar12[0x1b] = cVar5 + '\x01';
          if ('\x03' < (char)(cVar5 + '\x01')) {
            pcVar12[0x1b] = '\0';
            *(short *)(pcVar12 + 0xf) = *(short *)(pcVar12 + 0xf) + 1;
          }
          cVar5 = pcVar12[-0xe];
          if (cVar5 == '\x02') {
            if (4 < (ushort)(*(short *)(pcVar12 + 0xf) - 6U)) {
              pcVar12[0xf] = '\x06';
              pcVar12[0x10] = '\0';
            }
          }
          else if (cVar5 < '\x03') {
            if (cVar5 == '\x01') {
              bVar14 = (ushort)(*(short *)(pcVar12 + 0xf) - 1U) < 4;
              bVar15 = (ushort)(*(short *)(pcVar12 + 0xf) - 1U) == 4;
LAB_00011d25:
              if (!bVar14 && !bVar15) {
                pcVar12[0xf] = '\x01';
                pcVar12[0x10] = '\0';
              }
            }
          }
          else if (cVar5 == '\x03') {
            if (4 < (ushort)(*(short *)(pcVar12 + 0xf) - 0xbU)) {
              pcVar12[0xf] = '\v';
              pcVar12[0x10] = '\0';
            }
          }
          else if ((cVar5 == '\x04') && (4 < (ushort)(*(short *)(pcVar12 + 0xf) - 0x10U))) {
            pcVar12[0xf] = '\x10';
            pcVar12[0x10] = '\0';
          }
        }
        else {
          if (sVar3 < 0x1d) {
            if (sVar3 == 0x1b) {
LAB_00011c6e:
              cVar5 = pcVar12[0x1b];
              pcVar12[0x1b] = cVar5 + '\x01';
              if ('\x02' < (char)(cVar5 + '\x01')) {
                pcVar12[0x1b] = '\0';
                *(short *)(pcVar12 + 0xf) = *(short *)(pcVar12 + 0xf) + 1;
              }
              cVar5 = pcVar12[-0xe];
              if (cVar5 == '\x02') {
                if (2 < (ushort)(*(short *)(pcVar12 + 0xf) - 4U)) {
                  pcVar12[0xf] = '\x04';
                  pcVar12[0x10] = '\0';
                }
              }
              else if (cVar5 < '\x03') {
                if (cVar5 == '\x01') {
                  bVar14 = (ushort)(*(short *)(pcVar12 + 0xf) - 1U) < 2;
                  bVar15 = (ushort)(*(short *)(pcVar12 + 0xf) - 1U) == 2;
                  goto LAB_00011d25;
                }
              }
              else if (cVar5 == '\x03') {
                if (2 < (ushort)(*(short *)(pcVar12 + 0xf) - 7U)) {
                  pcVar12[0xf] = '\a';
                  pcVar12[0x10] = '\0';
                }
              }
              else if ((cVar5 == '\x04') && (2 < (ushort)(*(short *)(pcVar12 + 0xf) - 10U))) {
                pcVar12[0xf] = '\n';
                pcVar12[0x10] = '\0';
              }
              goto LAB_00011ba5;
            }
          }
          else {
            if (sVar3 == 0x1d) goto LAB_00011c6e;
            if (sVar3 == 0x1e) {
              cVar5 = pcVar12[0x1b];
              pcVar12[0x1b] = cVar5 + '\x01';
              if ('\x03' < (char)(cVar5 + '\x01')) {
                pcVar12[0x1b] = '\0';
                uVar7 = *(ushort *)(pcVar12 + 0xf);
                *(ushort *)(pcVar12 + 0xf) = uVar7 + 1;
                bVar14 = uVar7 < 6;
                bVar15 = uVar7 == 6;
                goto LAB_00011d25;
              }
              goto LAB_00011ba5;
            }
          }
          _DebugValues("ProcessEnemies() - unknown enemy type.",(int)sVar3);
          _CleanUp();
        }
LAB_00011ba5:
        bVar14 = true;
        goto LAB_00011baa;
      case '\x02':
        if ((int)((uint)*(ushort *)(pcVar12 + -0x2f) + (int)*(short *)(PTR__level_0003f010 + 0x14))
            < (int)(uint)uVar6) {
          *pcVar1 = '\x03';
          *(ushort *)(pcVar12 + -0x2f) = uVar6;
        }
        break;
      case '\x03':
        if ((int)(*(ushort *)(pcVar12 + -0x2f) + 10 + (int)*(short *)(PTR__level_0003f010 + 0x10)) <
            (int)(uint)uVar6) {
          local_1f[0] = 0x49;
          local_1f[1] = 0x71;
          local_1f[2] = 0xad;
          local_30 = DAT_000335dc;
          local_2c = DAT_000335e0;
          local_28 = DAT_000335e4;
          local_24 = DAT_000335e8;
          local_20 = DAT_000335ec;
          local_58 = *(int *)(pcVar12 + 0x23);
          pcVar8 = (char *)_RT3_CheckLicenseName(*(undefined4 *)(pcVar12 + 3));
          uVar16 = *(undefined4 *)(pcVar12 + -0x29);
          uVar4 = *(undefined4 *)(pcVar12 + -0x25);
          if (pcVar8 != (char *)0x0) {
            if (('/' < *pcVar8) && (*pcVar8 < ':')) {
              local_58 = 1;
            }
            while ((iVar9 = _StringGetLength(&local_30), iVar9 + 1U < 0x11 && (*pcVar8 != '\0'))) {
              _StringAppendSafe(&local_30,pcVar8,0x11);
            }
          }
          bVar10 = ((byte)local_58 ^ 0x4b ^ local_2c._3_1_) + 0xa6 ^ 0x72;
          bVar10 = bVar10 << 1 | (char)bVar10 < '\0';
          if (bVar10 < 0x42) {
            bVar10 = (byte)local_58 ^ bVar10;
          }
          bVar10 = bVar10 - 0x2e ^ local_30._2_1_;
          bVar10 = (bVar10 << 5 | bVar10 >> 3) + 0x92;
          bVar10 = (bVar10 * ' ' | bVar10 >> 3) ^ (byte)local_30;
          local_4a = _RT3_ExtractLicenseBlock1(uVar16,uVar4);
          bVar10 = (bVar10 ^ 0x6c) + 0x7e;
          bVar10 = ((bVar10 * '@' | bVar10 >> 2) ^ 0x62 ^ local_2c._1_1_ ^ (byte)local_58) + 0x98;
          bVar10 = ((bVar10 * '\x10' | bVar10 >> 4) ^ 0x54 ^ (byte)local_58 ^ local_24._1_1_) + 0x77
          ;
          _Useless5();
          bVar11 = bVar10 * -0x80 | bVar10 >> 1;
          bVar10 = bVar11 - 0x33;
          if ((int)local_28._2_1_ < (int)(uint)bVar10) {
            bVar10 = bVar11 + 0x2d;
          }
          bVar10 = (bVar10 << 7 | (byte)(bVar10 + 0x66) >> 1) ^ local_24._3_1_ ^ (byte)local_58;
          bVar10 = ((bVar10 << 7 | bVar10 >> 1) ^ (byte)local_58) + 0xaa;
          bVar10 = (bVar10 * '\b' | bVar10 >> 5) ^ (byte)local_28;
          if ((int)local_24._2_1_ < (int)(uint)bVar10) {
            bVar10 = bVar10 + 0x76;
          }
          bVar10 = bVar10 + 0x20;
          if (0x20 < bVar10) {
            bVar10 = bVar10 ^ local_2c._1_1_;
          }
          bVar10 = bVar10 + 0xa7 ^ local_28._3_1_;
          bVar10 = (bVar10 << 7 | bVar10 >> 1) + 0xbe;
          bVar10 = (bVar10 * '\b' | bVar10 >> 5) ^ 0x62 ^ (byte)local_58;
          cVar5 = ((bVar10 << 4 | bVar10 >> 4) ^ (byte)local_58) - 0x30;
          bVar10 = ((cVar5 * '\x02' | cVar5 < '\0') ^ 0x58U) + 0x55 ^ (byte)local_58 ^
                   (byte)local_24;
          bVar10 = (bVar10 << 7 | (bVar10 ^ 0x20) >> 1) + 0x9a;
          _TimerGetSeconds();
          _TimerGetSeconds();
          _TimerGetSeconds();
          _Useless8();
          bVar11 = ((bVar10 * '\b' | bVar10 >> 5) + 0x31 ^ (byte)local_58 ^ 0x6c) + 0x95 ^ 0x2d;
          bVar10 = bVar11 + 0x5e;
          if (0x4f < bVar11) {
            bVar10 = bVar11;
          }
          bVar11 = bVar10 << 6 | bVar10 >> 2;
          if (bVar11 < 0x6c) {
            _TimerGetSeconds();
          }
          bVar11 = ((bVar10 >> 2) << 6 | bVar11 >> 2) + 0x1d ^ local_2c._1_1_;
          bVar10 = bVar11 >> 2;
          cVar5 = _IsPlatformOpen();
          bVar10 = cVar5 * (bVar10 << 6 | (byte)(bVar11 << 6 | bVar10) >> 2);
          bVar10 = ((bVar10 * '\x10' | bVar10 >> 4) - 0x3f ^ 0x75 ^ (byte)local_58) + 0x31;
          bVar10 = (bVar10 * '\b' | bVar10 >> 5) - 0x29;
          bVar10 = (bVar10 * '\x10' | bVar10 >> 4) + 0x13;
          bVar10 = ((bVar10 * '\x10' | bVar10 >> 4) ^ (byte)local_58) + 0x30;
          bVar10 = (bVar10 * '\x04' | bVar10 >> 6) - 0x2f;
          if (bVar10 < 3) {
            bVar10 = local_1f[bVar10];
          }
          for (; bVar10 <= local_4a; local_4a = local_4a - bVar10) {
          }
          if ((local_58 == 0) || (local_4a != 0)) {
            cVar5 = '\0';
          }
          else {
            cVar5 = '\x01';
          }
          pcVar12[-0xf] = cVar5;
          bVar10 = bVar10 ^ 0x75 ^ local_30._3_1_ ^ (byte)local_58;
          local_58._0_1_ = (byte)local_58 ^ (bVar10 << 6 | bVar10 >> 2) + 0x1a;
          bVar10 = ((byte)local_58 << 2 | (byte)local_58 >> 6) + 0x13;
          if ((int)(uint)bVar10 < (int)local_2c._2_1_) {
            bVar10 = bVar10 >> 1 | bVar10 * -0x80;
          }
          if (bVar10 != local_24._1_1_) {
            _IsPlatformOpen();
          }
          *pcVar1 = '\x01';
          *(ushort *)(pcVar12 + -0x2f) = uVar6;
          pcVar12[0x15] = '\x01';
          pcVar12[0x1a] = '\x01';
          pcVar12[0x13] = '\0';
          pcVar12[0x14] = '\0';
          if ((pcVar12[-0xf] == '\0') && (*local_48 != '\0')) {
            uVar7 = _GetRandomFast(1,0x1e);
            *(ushort *)(pcVar12 + 0xd) = 0x13 - (ushort)(uVar7 < 2);
          }
          else {
            pcVar12[0xd] = '\x17';
            pcVar12[0xe] = '\0';
          }
          if ((pcVar12[-0xf] == '\0') && (*local_48 != '\0')) {
            *(short *)(pcVar12 + 0xd) = *(short *)(pcVar12 + 0xd) + 1;
          }
        }
        break;
      case '\x04':
      case '\x05':
      case '\x06':
        break;
      default:
        goto switchD_00011b16_default;
      }
      bVar14 = false;
LAB_00011baa:
      _AddRectToBgnd(PTR__enemy_0003f04c + iVar13 * 0x5c + 0x1a);
      _CorrectEnemyAligned(iVar13);
      if (*pcVar12 != '\0') goto LAB_000120fc;
      cVar5 = pcVar12[-0xe];
      if (cVar5 == '\x02') {
        cVar5 = pcVar12[-1];
        cVar2 = pcVar12[-0xd];
        uVar16 = 2;
LAB_000120d3:
        cVar5 = _GetNextObject(uVar16,(int)cVar2,(int)cVar5);
LAB_000120d8:
        if ((((cVar5 == '\n') || (cVar5 == '\x0f')) || (cVar5 == '\x10')) ||
           ((cVar5 == '\x14' || (cVar5 == '\x1e')))) {
          _SquishEnemy(iVar13,1);
        }
      }
      else if (cVar5 < '\x03') {
        if (cVar5 == '\x01') {
LAB_000120a5:
          cVar5 = PTR__gMaze_0003f054[(int)pcVar12[-0xd] + pcVar12[-1] * 0x10];
          goto LAB_000120d8;
        }
      }
      else {
        if (cVar5 == '\x03') goto LAB_000120a5;
        if (cVar5 == '\x04') {
          cVar5 = pcVar12[-1];
          cVar2 = pcVar12[-0xd];
          uVar16 = 4;
          goto LAB_000120d3;
        }
      }
LAB_000120fc:
      if (((bVar14) && (*(short *)(PTR__hero_0003f014 + 2) == 2)) &&
         ((cVar5 = _IsHeroCaught(*(undefined4 *)(PTR__enemy_0003f04c + iVar13 * 0x5c + 0x12),
                                 *(undefined4 *)(PTR__enemy_0003f04c + iVar13 * 0x5c + 0x16),1,1),
          cVar5 != '\0' && (*pcVar1 != '\x04')))) {
        _HeroCaught(1);
      }
    }
    iVar13 = iVar13 + 1;
    pcVar12 = pcVar12 + 0x5c;
    local_48 = local_48 + 1;
  } while (iVar13 != 0x1e);
switchD_00011b16_default:
  return;
}


// ==== _CheckNewEnemies @ 000124fa ====

void _CheckNewEnemies(void)

{
  undefined *puVar1;
  undefined *puVar2;
  char cVar3;
  undefined1 uVar4;
  undefined2 uVar5;
  short sVar6;
  undefined4 uVar7;
  char *pcVar8;
  int iVar9;
  undefined1 *puVar10;
  undefined8 uVar11;
  int local_34;
  char local_2b;
  int local_28;
  int local_24;
  int local_20;
  
  if (*(short *)(PTR__hero_0003f014 + 2) != 2) {
    return;
  }
  if (*(short *)PTR__gNumNormalBlocks_0003f050 < 1) {
    if ('\0' < (char)*PTR__gNumEnemiesActive_00034120) {
      return;
    }
    _gNumEnemiesSquished = (char)*(undefined2 *)(PTR__level_0003f010 + 0xc);
    return;
  }
  iVar9 = _TimeBonus_GetBonus();
  if (iVar9 < 1) {
    _gNumEnemiesSquished =
         (char)*(undefined2 *)(PTR__level_0003f010 + 0xc) - *PTR__gNumEnemiesActive_00034120;
  }
  if ((int)*(short *)(PTR__level_0003f010 + 0xc) <=
      (int)_gNumEnemiesSquished + (int)(char)*PTR__gNumEnemiesActive_00034120) {
    return;
  }
  if (*(short *)(PTR__level_0003f010 + 0xe) <= (short)(char)*PTR__gNumEnemiesActive_00034120) {
    return;
  }
  uVar5 = _GetFrameCounter();
  puVar2 = PTR__gMaze_0003f054;
  local_20 = 0;
  local_34 = 0;
  pcVar8 = PTR__enemy_0003f04c;
  while (*pcVar8 != '\0') {
    local_20 = local_20 + 1;
    local_34 = local_34 + 0x5c;
    pcVar8 = pcVar8 + 0x5c;
    if (local_20 == 0x1e) {
      return;
    }
  }
  if (*(short *)PTR__gNumNormalBlocks_0003f050 < 1) {
    if ((char)*PTR__gNumEnemiesActive_00034120 < '\x01') {
      _gNumEnemiesSquished = (char)*(undefined2 *)(PTR__level_0003f010 + 0xc);
      return;
    }
    return;
  }
  cVar3 = _GetRandomFast(0,0xf);
  local_2b = _GetRandomFast(0,10);
  puVar1 = PTR__enemy_0003f04c;
  *(undefined4 *)(PTR__enemy_0003f04c + local_34 + 0x28) = 0xc6f140ed;
  *(undefined4 *)(puVar1 + local_34 + 0x2c) = 0xa07705e;
  do {
    cVar3 = cVar3 + '\x01';
    if (cVar3 < '\x10') {
      local_28 = (int)local_2b;
      local_24 = (int)cVar3;
    }
    else {
      local_2b = local_2b + '\x01';
      if (local_2b < '\v') {
        local_28 = (int)local_2b;
      }
      else {
        local_2b = '\0';
        local_28 = 0;
      }
      cVar3 = '\0';
      local_24 = 0;
    }
  } while (puVar2[local_24 + local_28 * 0x10] != '\n');
  puVar10 = PTR__enemy_0003f04c + local_34;
  *(short *)(puVar10 + 0x14) = (short)local_24 * 0x28;
  *(short *)(puVar10 + 0x12) = (short)local_28 * 0x28;
  uVar7 = _RT3_GetLicenseName();
  *(undefined4 *)(puVar10 + 0x34) = uVar7;
  *(short *)(puVar10 + 0x18) = *(short *)(puVar10 + 0x14) + 0x28;
  *(short *)(puVar10 + 0x16) = *(short *)(puVar10 + 0x12) + 0x28;
  *(undefined4 *)(puVar10 + 0x1a) = *(undefined4 *)(puVar10 + 0x12);
  *(undefined4 *)(puVar10 + 0x1e) = *(undefined4 *)(puVar10 + 0x16);
  *(undefined2 *)(puVar10 + 0x3c) = 4;
  *puVar10 = 2;
  *(undefined2 *)(PTR__enemy_0003f04c + local_34 + 2) = uVar5;
  *(undefined2 *)(puVar10 + 0x3e) = 0x14;
  uVar4 = _GetRandomFast(1,4);
  puVar10[0x23] = uVar4;
  puVar10[0x31] = 1;
  puVar10[0x42] = 1;
  puVar10[0x24] = cVar3;
  puVar10[0x30] = local_2b;
  puVar10[0x32] = 0;
  uVar7 = _RT3_GetLicenseCopies();
  *(undefined4 *)(puVar10 + 0x54) = uVar7;
  puVar10[0x38] = 0;
  *(undefined2 *)(puVar10 + 0x5a) = uVar5;
  if (((*(int *)(PTR__level_0003f010 + 0x24) == 0) && (*(int *)(PTR__level_0003f010 + 0x28) == 0))
     && (*(int *)(PTR__level_0003f010 + 0x2c) == 0)) {
    *(undefined2 *)(PTR__level_0003f010 + 0x24) = 1;
  }
  do {
    do {
      sVar6 = _GetRandomFast(0,5);
    } while (sVar6 == 99);
  } while (*(short *)(PTR__level_0003f010 + sVar6 * 2 + 0x24) == 0);
  *(short *)(PTR__level_0003f010 + sVar6 * 2 + 0x24) =
       *(short *)(PTR__level_0003f010 + sVar6 * 2 + 0x24) + -1;
  puVar2 = PTR__enemy_0003f04c;
  sVar6 = sVar6 + 1;
  PTR__enemy_0003f04c[local_34 + 0x10] = (char)sVar6;
  if (sVar6 == 2) {
    *(undefined2 *)(puVar2 + local_34 + 0x3a) = 0x1c;
  }
  else if (sVar6 < 3) {
    if (sVar6 == 1) {
      *(undefined2 *)(puVar2 + local_34 + 0x3a) = 0x1b;
    }
  }
  else if (sVar6 == 3) {
    *(undefined2 *)(puVar2 + local_34 + 0x3a) = 0x1d;
  }
  else if (sVar6 == 4) {
    *(undefined2 *)(puVar2 + local_34 + 0x3a) = 0x1e;
  }
  if (*(short *)(PTR__enemy_0003f04c + local_34 + 0x3a) != 0x1e) {
    cVar3 = PTR__enemy_0003f04c[local_34 + 0x23];
    if (cVar3 == '\x02') {
      *(undefined2 *)(PTR__enemy_0003f04c + local_34 + 0x40) = 4;
      goto LAB_00012412;
    }
    if ('\x02' < cVar3) {
      if (cVar3 == '\x03') {
        *(undefined2 *)(PTR__enemy_0003f04c + local_34 + 0x40) = 7;
      }
      else if (cVar3 == '\x04') {
        *(undefined2 *)(PTR__enemy_0003f04c + local_34 + 0x40) = 10;
      }
      goto LAB_00012412;
    }
    if (cVar3 != '\x01') goto LAB_00012412;
  }
  *(undefined2 *)(PTR__enemy_0003f04c + local_34 + 0x40) = 1;
LAB_00012412:
  puVar2 = PTR__enemy_0003f04c;
  PTR__enemy_0003f04c[local_34 + 0x4c] = 0;
  puVar2[local_34 + 0x43] = 0xff;
  *(undefined2 *)(puVar2 + local_34 + 0x44) = 0;
  puVar2[local_34 + 0x46] = 0;
  puVar2[local_34 + 0x47] = 0;
  uVar11 = _RT3_GetLicenseCode();
  puVar1 = PTR__enemy_0003f04c;
  *(int *)(PTR__enemy_0003f04c + local_34 + 8) = (int)uVar11;
  *(int *)(puVar1 + local_34 + 0xc) = (int)((ulonglong)uVar11 >> 0x20);
  *(undefined2 *)(puVar2 + local_34 + 0x48) = 0;
  puVar2[local_34 + 0x4a] = 0;
  *(undefined2 *)(puVar2 + local_34 + 0x4e) = 0;
  *(undefined2 *)(puVar2 + local_34 + 0x50) = 0;
  *(undefined2 *)(puVar2 + local_34 + 0x52) = 0;
  *(undefined2 *)(puVar2 + local_34 + 0x58) = 0;
  PTR__gMaze_0003f054[local_24 + local_28 * 0x10] = 0x3c;
  *(short *)PTR__gNumNormalBlocks_0003f050 = *(short *)PTR__gNumNormalBlocks_0003f050 + -1;
  cVar3 = _NewBlock(local_24,local_28,0,0x3c,local_20,0);
  if (cVar3 == '\0') {
    _StdError("Internal error: NewBlock() - none free. Increase max count.",0);
  }
  *PTR__gNumEnemiesActive_00034120 = *PTR__gNumEnemiesActive_00034120 + '\x01';
  return;
}


// ==== _InitEnemyAI @ 00012591 ====

void _InitEnemyAI(void)

{
  return;
}


// ==== _CorrectEnemyAligned @ 00012596 ====

void _CorrectEnemyAligned(short param_1)

{
  int iVar1;
  undefined1 uVar2;
  
  iVar1 = param_1 * 0x5c;
  if ((*(short *)(PTR__enemy_0003f04c + iVar1 + 0x14) ==
       (short)((*(short *)(PTR__enemy_0003f04c + iVar1 + 0x14) / 0x28) * 0x28)) &&
     (*(short *)(PTR__enemy_0003f04c + iVar1 + 0x12) ==
      (short)((*(short *)(PTR__enemy_0003f04c + iVar1 + 0x12) / 0x28) * 0x28))) {
    uVar2 = 1;
  }
  else {
    uVar2 = 0;
  }
  PTR__enemy_0003f04c[param_1 * 0x5c + 0x31] = uVar2;
  return;
}


// ==== _DoEnemyFeatureDelay @ 0001263e ====

bool _DoEnemyFeatureDelay(char param_1)

{
  short sVar1;
  undefined *puVar2;
  
  puVar2 = PTR__enemy_0003f04c;
  sVar1 = *(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x52);
  if (sVar1 < 10) {
    *(undefined2 *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x58) = 4;
    *(short *)(puVar2 + param_1 * 0x5c + 0x52) = *(short *)(puVar2 + param_1 * 0x5c + 0x52) + 1;
    puVar2[param_1 * 0x5c + 0x4a] = 1;
  }
  else {
    *(undefined2 *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x52) = 0;
    *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x58) = 0;
  }
  return sVar1 < 10;
}


// ==== _CanDoNormalOtherPop @ 00012c83 ====

bool _CanDoNormalOtherPop(short param_1)

{
  bool bVar1;
  ushort uVar2;
  
  uVar2 = _GetFrameCounter();
  if (*(ushort *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x5a) + 0x78 < (uint)uVar2) {
    bVar1 = (short)(4 - uVar2) <
            (short)((int)((uint)uVar2 - (uint)*(ushort *)(PTR__enemy_0003f04c + param_1 * 0x5c + 2))
                   / 0x1e);
  }
  else {
    bVar1 = false;
  }
  return bVar1;
}


// ==== _CanDoNormalPop @ 00012cf4 ====

bool _CanDoNormalPop(short param_1)

{
  bool bVar1;
  ushort uVar2;
  
  uVar2 = _GetFrameCounter();
  if (*(ushort *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x5a) + 0x78 < (uint)uVar2) {
    bVar1 = (short)(10 - uVar2) <
            (short)((int)((uint)uVar2 - (uint)*(ushort *)(PTR__enemy_0003f04c + param_1 * 0x5c + 2))
                   / 0x1e);
  }
  else {
    bVar1 = false;
  }
  return bVar1;
}


// ==== _FigureEnemyRandomness @ 00012d65 ====

uint _FigureEnemyRandomness(short param_1)

{
  undefined *puVar1;
  short sVar2;
  uint uVar3;
  uint uVar4;
  int iVar5;
  
  puVar1 = PTR__enemy_0003f04c;
  sVar2 = *(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x3a);
  if (sVar2 == 0x1e) {
    sVar2 = _GetCurrLevelNum();
    iVar5 = (int)(short)(sVar2 * -0xf + 0x2ee);
    goto LAB_00012dd9;
  }
  if (sVar2 < 0x1f) {
    if (sVar2 == 0x1c) {
      iVar5 = 0x78;
      goto LAB_00012dd9;
    }
    if (sVar2 == 0x1d) {
      iVar5 = 0xb4;
      goto LAB_00012dd9;
    }
  }
  else {
    if (sVar2 == 0x3039) {
      iVar5 = 0x4b0;
      goto LAB_00012dd9;
    }
    if (sVar2 == 0x303a) {
      iVar5 = 0x1e;
      goto LAB_00012dd9;
    }
  }
  iVar5 = 600;
LAB_00012dd9:
  uVar3 = _GetFrameCounter();
  uVar3 = iVar5 / (int)((uVar3 & 0xffff) - (uint)*(ushort *)(puVar1 + param_1 * 0x5c + 2)) + 1;
  uVar4 = 1;
  if (0 < (short)uVar3) {
    uVar4 = uVar3;
  }
  return uVar4 & 0xffff;
}


// ==== _EnemyCheckBurstingBubble @ 00012e01 ====

bool _EnemyCheckBurstingBubble(short param_1,short param_2)

{
  char cVar1;
  int iVar2;
  int iVar3;
  short unaff_BX;
  undefined4 uVar4;
  
  if (param_2 == 2) {
    iVar2 = (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x30];
    iVar3 = (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x24];
    uVar4 = 2;
  }
  else if (param_2 < 3) {
    if (param_2 != 1) {
LAB_00012e2e:
      _LocationErrorInt(0x7d8,4);
      goto LAB_00012ebd;
    }
    iVar2 = (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x30];
    iVar3 = (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x24];
    uVar4 = 1;
  }
  else if (param_2 == 3) {
    iVar2 = (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x30];
    iVar3 = (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x24];
    uVar4 = 3;
  }
  else {
    if (param_2 != 4) goto LAB_00012e2e;
    iVar2 = (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x30];
    iVar3 = (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x24];
    uVar4 = 4;
  }
  cVar1 = _GetNextObject(uVar4,iVar3,iVar2);
  unaff_BX = (short)cVar1;
LAB_00012ebd:
  return unaff_BX == 0x28;
}


// ==== _UsableEnemyBlock @ 00012ecc ====

undefined1 _UsableEnemyBlock(short param_1)

{
  undefined1 uVar1;
  
  if (((param_1 == 0) || (param_1 == 0x46)) || (param_1 == 0x50)) {
    uVar1 = 1;
  }
  else {
    uVar1 = 0;
  }
  return uVar1;
}


// ==== _ToastBubble @ 00012ef2 ====

void _ToastBubble(short param_1)

{
  undefined *puVar1;
  byte bVar2;
  int iVar3;
  int iVar4;
  short sVar5;
  undefined4 uVar6;
  
  puVar1 = PTR__enemy_0003f04c;
LAB_00012f0e:
  if ('\0' < (char)puVar1[param_1 * 0x5c + 0x30]) {
    bVar2 = _GetNextObject(1,(int)(char)puVar1[param_1 * 0x5c + 0x24],
                           (int)(char)puVar1[param_1 * 0x5c + 0x30]);
    sVar5 = 1;
    goto LAB_00012f83;
  }
  sVar5 = 1;
LAB_00012f3e:
  sVar5 = sVar5 + 1;
  if ((3 < sVar5) || (sVar5 == 1)) {
    puVar1[param_1 * 0x5c + 0x23] = 1;
    goto LAB_00013053;
  }
  if (sVar5 == 2) goto LAB_00012fdb;
  if (sVar5 < 3) {
    if (sVar5 != 1) {
LAB_00012f2a:
      _LocationErrorInt(0x7d8,5);
      goto LAB_00012f3e;
    }
    goto LAB_00012f0e;
  }
  if (sVar5 == 3) {
    if ('\0' < (char)puVar1[param_1 * 0x5c + 0x24]) {
      iVar3 = (int)(char)puVar1[param_1 * 0x5c + 0x30];
      iVar4 = (int)(char)puVar1[param_1 * 0x5c + 0x24];
      uVar6 = 3;
      goto LAB_00012f7c;
    }
    goto LAB_00012f3e;
  }
  if (sVar5 != 4) goto LAB_00012f2a;
  if ('\x0e' < (char)puVar1[param_1 * 0x5c + 0x24]) goto LAB_00012f3e;
  iVar3 = (int)(char)puVar1[param_1 * 0x5c + 0x30];
  iVar4 = (int)(char)puVar1[param_1 * 0x5c + 0x24];
  uVar6 = 4;
  goto LAB_00012f7c;
LAB_00012fdb:
  if ('\t' < (char)puVar1[param_1 * 0x5c + 0x30]) goto LAB_00012f3e;
  iVar3 = (int)(char)puVar1[param_1 * 0x5c + 0x30];
  iVar4 = (int)(char)puVar1[param_1 * 0x5c + 0x24];
  uVar6 = 2;
LAB_00012f7c:
  bVar2 = _GetNextObject(uVar6,iVar4,iVar3);
LAB_00012f83:
  if ((bVar2 < 0x11) && ((1 << (bVar2 & 0x1f) & 0x18400U) != 0)) {
    _CrushBlock((int)(char)puVar1[param_1 * 0x5c + 0x24],(int)(char)puVar1[param_1 * 0x5c + 0x30],
                (int)(char)sVar5,0);
    *(undefined2 *)(puVar1 + param_1 * 0x5c + 0x48) = 0;
    puVar1[param_1 * 0x5c + 0x23] = (char)sVar5;
LAB_00013053:
    puVar1[param_1 * 0x5c + 0x4a] = 1;
    return;
  }
  goto LAB_00012f3e;
}


// ==== _TryRemoveGo @ 0001305e ====

undefined4 _TryRemoveGo(short param_1,short param_2)

{
  undefined *puVar1;
  char cVar2;
  short sVar3;
  undefined2 uVar4;
  int iVar5;
  int iVar6;
  undefined4 uVar7;
  ushort unaff_SI;
  
  puVar1 = PTR__enemy_0003f04c;
  if (param_2 == 2) {
    iVar5 = (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x30];
    iVar6 = (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x24];
    uVar7 = 2;
  }
  else if (param_2 < 3) {
    if (param_2 != 1) {
LAB_00013091:
      _LocationErrorInt(0x7d8,3);
      goto LAB_000130a5;
    }
    iVar5 = (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x30];
    iVar6 = (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x24];
    uVar7 = 1;
  }
  else if (param_2 == 3) {
    iVar5 = (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x30];
    iVar6 = (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x24];
    uVar7 = 3;
  }
  else {
    if (param_2 != 4) goto LAB_00013091;
    iVar5 = (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x30];
    iVar6 = (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x24];
    uVar7 = 4;
  }
  cVar2 = _GetNextObject(uVar7,iVar6,iVar5);
  unaff_SI = (ushort)cVar2;
LAB_000130a5:
  if ((unaff_SI < 0x11) && ((1 << ((byte)unaff_SI & 0x1f) & 0x18400U) != 0)) {
    if (*(short *)(puVar1 + param_1 * 0x5c + 0x3a) == 0x1e) {
      sVar3 = 10;
    }
    else {
      sVar3 = _GetCurrLevelNum();
      sVar3 = 0x28 - sVar3;
      if (sVar3 < 5) {
        sVar3 = 5;
      }
    }
    cVar2 = (char)param_2;
    if (*(short *)(puVar1 + param_1 * 0x5c + 0x52) < sVar3) {
      *(undefined2 *)(puVar1 + param_1 * 0x5c + 0x58) = 2;
      *(short *)(puVar1 + param_1 * 0x5c + 0x52) = *(short *)(puVar1 + param_1 * 0x5c + 0x52) + 1;
      puVar1[param_1 * 0x5c + 0x23] = cVar2;
      puVar1[param_1 * 0x5c + 0x4a] = 1;
    }
    else {
      *(undefined2 *)(puVar1 + param_1 * 0x5c + 0x52) = 0;
      *(undefined2 *)(puVar1 + param_1 * 0x5c + 0x58) = 0;
      _CrushBlock((int)(char)puVar1[param_1 * 0x5c + 0x24],(int)(char)puVar1[param_1 * 0x5c + 0x30],
                  (int)cVar2,0);
      puVar1[param_1 * 0x5c + 0x23] = cVar2;
      puVar1[param_1 * 0x5c + 0x4a] = 1;
      uVar4 = _GetFrameCounter();
      *(undefined2 *)(puVar1 + param_1 * 0x5c + 0x5a) = uVar4;
    }
    uVar7 = 1;
  }
  else {
    uVar7 = 0;
  }
  return uVar7;
}


// ==== _TooMuchEnemyTurning @ 000131da ====

bool _TooMuchEnemyTurning(short param_1)

{
  return 0 < *(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x48);
}


// ==== _TryEnemyPushBlock @ 000131fd ====

undefined4 _TryEnemyPushBlock(short param_1,short param_2)

{
  undefined *puVar1;
  char cVar2;
  undefined2 uVar3;
  int iVar4;
  int iVar5;
  short sVar6;
  undefined4 uVar7;
  
  puVar1 = PTR__enemy_0003f04c;
  if (param_2 == 2) {
    if ('\b' < (char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x30]) {
      return 0;
    }
    cVar2 = _GetNextObject(2,(int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x24],
                           (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x30]);
    sVar6 = (short)cVar2;
    iVar4 = (int)(char)puVar1[param_1 * 0x5c + 0x30];
    iVar5 = (int)(char)puVar1[param_1 * 0x5c + 0x24];
    uVar7 = 2;
  }
  else if (param_2 < 3) {
    if (param_2 != 1) {
LAB_00013234:
      _LocationErrorInt(0x7d8,5);
      return 0;
    }
    if ((char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x30] < '\x02') {
      return 0;
    }
    cVar2 = _GetNextObject(1,(int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x24],
                           (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x30]);
    sVar6 = (short)cVar2;
    iVar4 = (int)(char)puVar1[param_1 * 0x5c + 0x30];
    iVar5 = (int)(char)puVar1[param_1 * 0x5c + 0x24];
    uVar7 = 1;
  }
  else if (param_2 == 3) {
    if ((char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x24] < '\x02') {
      return 0;
    }
    cVar2 = _GetNextObject(3,(int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x24],
                           (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x30]);
    sVar6 = (short)cVar2;
    iVar4 = (int)(char)puVar1[param_1 * 0x5c + 0x30];
    iVar5 = (int)(char)puVar1[param_1 * 0x5c + 0x24];
    uVar7 = 3;
  }
  else {
    if (param_2 != 4) goto LAB_00013234;
    if ('\r' < (char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x24]) {
      return 0;
    }
    cVar2 = _GetNextObject(4,(int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x24],
                           (int)(char)PTR__enemy_0003f04c[param_1 * 0x5c + 0x30]);
    sVar6 = (short)cVar2;
    iVar4 = (int)(char)puVar1[param_1 * 0x5c + 0x30];
    iVar5 = (int)(char)puVar1[param_1 * 0x5c + 0x24];
    uVar7 = 4;
  }
  cVar2 = _GetDistantObject(uVar7,iVar5,iVar4);
  if (((sVar6 != 0x4d2) && (sVar6 == 10)) && ((cVar2 == '\0' || (cVar2 == 'F')))) {
    if (*(short *)(puVar1 + param_1 * 0x5c + 0x3a) == 0x1e) {
      sVar6 = 10;
    }
    else {
      sVar6 = _GetCurrLevelNum();
      sVar6 = sVar6 * -2 + 0x46;
      if (sVar6 < 5) {
        sVar6 = 5;
      }
    }
    cVar2 = (char)param_2;
    if (*(short *)(puVar1 + param_1 * 0x5c + 0x52) < sVar6) {
      *(undefined2 *)(puVar1 + param_1 * 0x5c + 0x58) = 1;
      *(short *)(puVar1 + param_1 * 0x5c + 0x52) = *(short *)(puVar1 + param_1 * 0x5c + 0x52) + 1;
      puVar1[param_1 * 0x5c + 0x23] = cVar2;
      puVar1[param_1 * 0x5c + 0x4a] = 1;
    }
    else {
      *(undefined2 *)(puVar1 + param_1 * 0x5c + 0x52) = 0;
      *(undefined2 *)(puVar1 + param_1 * 0x5c + 0x58) = 0;
      puVar1[param_1 * 0x5c + 0x4a] = 0;
      _PushBlock((int)(char)puVar1[param_1 * 0x5c + 0x24],(int)(char)puVar1[param_1 * 0x5c + 0x30],
                 (int)cVar2,10);
      puVar1[param_1 * 0x5c + 0x23] = cVar2;
      puVar1[param_1 * 0x5c + 0x4a] = 1;
      uVar3 = _GetFrameCounter();
      *(undefined2 *)(puVar1 + param_1 * 0x5c + 0x5a) = uVar3;
    }
    return 1;
  }
  return 0;
}


// ==== _TryEnemyCreateBalloon @ 00013441 ====

undefined4 _TryEnemyCreateBalloon(short param_1,short param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  char cVar3;
  short sVar4;
  undefined2 uVar5;
  int iVar6;
  short sVar7;
  short local_4e;
  undefined1 local_1e;
  
  puVar2 = PTR__enemy_0003f04c;
  puVar1 = PTR__hero_0003f014;
  iVar6 = (int)param_1;
  if (PTR__hero_0003f014[0x4c] != '\0') {
    return 0;
  }
  if (param_2 == 2) {
    local_4e = 0x4d2;
    sVar7 = (short)(char)PTR__enemy_0003f04c[iVar6 * 0x5c + 0x30];
    sVar4 = sVar7;
    for (; sVar7 < 10; sVar7 = sVar7 + 1) {
      cVar3 = _GetNextObject(2,(int)(char)puVar2[iVar6 * 0x5c + 0x24],(int)(char)sVar4);
      local_4e = (short)cVar3;
      if ((puVar2[iVar6 * 0x5c + 0x24] == puVar1[0x28]) && (sVar7 == (char)puVar1[0x34]))
      goto LAB_00013666;
      sVar4 = sVar4 + 1;
      if (cVar3 != '\0') break;
    }
  }
  else if (param_2 < 3) {
    if (param_2 != 1) {
LAB_00013491:
      _LocationErrorInt(0x7d8,5);
      return 0;
    }
    local_4e = 0x4d2;
    sVar7 = (short)(char)PTR__enemy_0003f04c[iVar6 * 0x5c + 0x30];
    sVar4 = sVar7;
    for (; 0 < sVar7; sVar7 = sVar7 + -1) {
      cVar3 = _GetNextObject(1,(int)(char)puVar2[iVar6 * 0x5c + 0x24],(int)(char)sVar4);
      local_4e = (short)cVar3;
      if ((puVar2[iVar6 * 0x5c + 0x24] == puVar1[0x28]) && (sVar7 == (char)puVar1[0x34]))
      goto LAB_00013666;
      sVar4 = sVar4 + -1;
      if (cVar3 != '\0') break;
    }
  }
  else if (param_2 == 3) {
    local_4e = 0x4d2;
    sVar7 = (short)(char)PTR__enemy_0003f04c[iVar6 * 0x5c + 0x24];
    sVar4 = sVar7;
    for (; 0 < sVar7; sVar7 = sVar7 + -1) {
      cVar3 = _GetNextObject(3,(int)(char)sVar4,(int)(char)puVar2[iVar6 * 0x5c + 0x30]);
      local_4e = (short)cVar3;
      if ((sVar7 == (char)puVar1[0x28]) && (puVar2[iVar6 * 0x5c + 0x30] == puVar1[0x34]))
      goto LAB_00013666;
      sVar4 = sVar4 + -1;
      if (cVar3 != '\0') break;
    }
  }
  else {
    if (param_2 != 4) goto LAB_00013491;
    local_4e = 0x4d2;
    sVar7 = (short)(char)PTR__enemy_0003f04c[iVar6 * 0x5c + 0x24];
    sVar4 = sVar7;
    for (; sVar7 < 0xf; sVar7 = sVar7 + 1) {
      cVar3 = _GetNextObject(4,(int)(char)sVar4,(int)(char)puVar2[iVar6 * 0x5c + 0x30]);
      local_4e = (short)cVar3;
      if ((sVar7 == (char)PTR__hero_0003f014[0x28]) &&
         (puVar2[iVar6 * 0x5c + 0x30] == PTR__hero_0003f014[0x34])) goto LAB_00013666;
      sVar4 = sVar4 + 1;
      if (cVar3 != '\0') break;
    }
  }
  if (local_4e != 0x46) {
    return 0;
  }
LAB_00013666:
  sVar4 = _GetCurrLevelNum();
  sVar4 = sVar4 * -3 + 0x46;
  if (sVar4 < 5) {
    sVar4 = 5;
  }
  local_1e = (undefined1)param_2;
  if (*(short *)(puVar2 + iVar6 * 0x5c + 0x52) < sVar4) {
    *(undefined2 *)(puVar2 + iVar6 * 0x5c + 0x58) = 3;
    *(short *)(puVar2 + iVar6 * 0x5c + 0x52) = *(short *)(puVar2 + iVar6 * 0x5c + 0x52) + 1;
    puVar2[iVar6 * 0x5c + 0x23] = local_1e;
    puVar2[iVar6 * 0x5c + 0x4a] = 1;
    uVar5 = _GetFrameCounter();
    *(undefined2 *)(puVar2 + iVar6 * 0x5c + 0x5a) = uVar5;
  }
  else {
    *(undefined2 *)(puVar2 + iVar6 * 0x5c + 0x52) = 0;
    *(undefined2 *)(puVar2 + iVar6 * 0x5c + 0x58) = 0;
    puVar2[iVar6 * 0x5c + 0x23] = local_1e;
    puVar2[iVar6 * 0x5c + 0x4a] = 1;
    uVar5 = _GetFrameCounter();
    *(undefined2 *)(puVar2 + iVar6 * 0x5c + 0x5a) = uVar5;
    _Balloons_New(iVar6);
  }
  return 1;
}


// ==== _CheckUp @ 000136e6 ====

undefined4 _CheckUp(short param_1)

{
  bool bVar1;
  char cVar2;
  int iVar3;
  
  iVar3 = (int)param_1;
  if (PTR__enemy_0003f04c[iVar3 * 0x5c + 0x23] == '\0') {
    cVar2 = _GetNextObject(1,(int)(char)PTR__enemy_0003f04c[iVar3 * 0x5c + 0x24],
                           (int)(char)PTR__enemy_0003f04c[iVar3 * 0x5c + 0x30]);
    if (((cVar2 == '\0') || (cVar2 == 'F')) || (cVar2 == 'P')) {
      bVar1 = true;
    }
    else {
      bVar1 = false;
    }
    if (bVar1) {
      PTR__enemy_0003f04c[iVar3 * 0x5c + 0x23] = 1;
      return 1;
    }
  }
  return 0;
}


// ==== _CheckLeft @ 0001376c ====

undefined4 _CheckLeft(short param_1)

{
  bool bVar1;
  char cVar2;
  int iVar3;
  
  iVar3 = (int)param_1;
  if (PTR__enemy_0003f04c[iVar3 * 0x5c + 0x23] == '\0') {
    cVar2 = _GetNextObject(3,(int)(char)PTR__enemy_0003f04c[iVar3 * 0x5c + 0x24],
                           (int)(char)PTR__enemy_0003f04c[iVar3 * 0x5c + 0x30]);
    if (((cVar2 == '\0') || (cVar2 == 'F')) || (cVar2 == 'P')) {
      bVar1 = true;
    }
    else {
      bVar1 = false;
    }
    if (bVar1) {
      PTR__enemy_0003f04c[iVar3 * 0x5c + 0x23] = 3;
      return 1;
    }
  }
  return 0;
}


// ==== _CheckDown @ 000137f2 ====

undefined4 _CheckDown(short param_1)

{
  bool bVar1;
  char cVar2;
  int iVar3;
  
  iVar3 = (int)param_1;
  if (PTR__enemy_0003f04c[iVar3 * 0x5c + 0x23] == '\0') {
    cVar2 = _GetNextObject(2,(int)(char)PTR__enemy_0003f04c[iVar3 * 0x5c + 0x24],
                           (int)(char)PTR__enemy_0003f04c[iVar3 * 0x5c + 0x30]);
    if (((cVar2 == '\0') || (cVar2 == 'F')) || (cVar2 == 'P')) {
      bVar1 = true;
    }
    else {
      bVar1 = false;
    }
    if (bVar1) {
      PTR__enemy_0003f04c[iVar3 * 0x5c + 0x23] = 2;
      return 1;
    }
  }
  return 0;
}


// ==== _CheckRight @ 00013878 ====

undefined4 _CheckRight(short param_1)

{
  bool bVar1;
  char cVar2;
  int iVar3;
  
  iVar3 = (int)param_1;
  if (PTR__enemy_0003f04c[iVar3 * 0x5c + 0x23] == '\0') {
    cVar2 = _GetNextObject(4,(int)(char)PTR__enemy_0003f04c[iVar3 * 0x5c + 0x24],
                           (int)(char)PTR__enemy_0003f04c[iVar3 * 0x5c + 0x30]);
    if (((cVar2 == '\0') || (cVar2 == 'F')) || (cVar2 == 'P')) {
      bVar1 = true;
    }
    else {
      bVar1 = false;
    }
    if (bVar1) {
      PTR__enemy_0003f04c[iVar3 * 0x5c + 0x23] = 4;
      return 1;
    }
  }
  return 0;
}


// ==== _TryAndTurnEnemy @ 000138fe ====

undefined1 _TryAndTurnEnemy(short param_1,short param_2)

{
  undefined1 uVar1;
  
  if (param_2 == 2) {
    uVar1 = _CheckDown((int)param_1);
  }
  else if (param_2 < 3) {
    if (param_2 != 1) {
LAB_0001391a:
      _LocationErrorInt(0x7d8,1);
      return 0;
    }
    uVar1 = _CheckUp((int)param_1);
  }
  else if (param_2 == 3) {
    uVar1 = _CheckLeft((int)param_1);
  }
  else {
    if (param_2 != 4) goto LAB_0001391a;
    uVar1 = _CheckRight((int)param_1);
  }
  return uVar1;
}


// ==== _FigureEnemyMove @ 00013bd4 ====

void _FigureEnemyMove(char param_1)

{
  undefined *puVar1;
  char cVar2;
  char cVar3;
  short sVar4;
  short sVar5;
  undefined2 uVar6;
  short sVar7;
  uint uVar8;
  int iVar9;
  int iVar10;
  undefined4 uVar11;
  short local_3e;
  short local_3c;
  short local_3a;
  short sStack_32;
  char cStack_25;
  undefined2 local_24;
  undefined2 local_22;
  short local_20 [8];
  
  uVar8 = _Get0To6();
  puVar1 = PTR__enemy_0003f04c;
  iVar9 = 0;
  do {
    *(undefined1 *)((int)&local_24 + iVar9) = 0;
    iVar9 = iVar9 + 1;
  } while (iVar9 != 4);
  iVar9 = (int)param_1;
  sVar7 = *(short *)(PTR__enemy_0003f04c + iVar9 * 0x5c + 0x58);
  if ((sVar7 == 0) || (7 < uVar8)) goto LAB_00013cca;
  if (sVar7 == 2) {
    cVar2 = _TryRemoveGo(iVar9,(int)(char)PTR__enemy_0003f04c[iVar9 * 0x5c + 0x23]);
joined_r0x00013c7a:
    if (cVar2 != '\0') {
      puVar1[iVar9 * 0x5c + 0x4a] = 1;
      return;
    }
  }
  else if (sVar7 < 3) {
    if (sVar7 == 1) {
      cVar2 = _TryEnemyPushBlock(iVar9,(int)(char)PTR__enemy_0003f04c[iVar9 * 0x5c + 0x23]);
      goto joined_r0x00013c7a;
    }
  }
  else {
    if (sVar7 == 3) {
      cVar2 = _TryEnemyCreateBalloon(iVar9,(int)(char)PTR__enemy_0003f04c[iVar9 * 0x5c + 0x23]);
      goto joined_r0x00013c7a;
    }
    if (sVar7 == 4) {
      if (*(short *)(PTR__enemy_0003f04c + iVar9 * 0x5c + 0x52) < 10) {
        *(undefined2 *)(PTR__enemy_0003f04c + iVar9 * 0x5c + 0x58) = 4;
        *(short *)(puVar1 + iVar9 * 0x5c + 0x52) = *(short *)(puVar1 + iVar9 * 0x5c + 0x52) + 1;
        puVar1[iVar9 * 0x5c + 0x4a] = 1;
        return;
      }
      *(undefined2 *)(PTR__enemy_0003f04c + iVar9 * 0x5c + 0x52) = 0;
      *(undefined2 *)(puVar1 + iVar9 * 0x5c + 0x58) = 0;
    }
  }
LAB_00013cca:
  cVar2 = puVar1[iVar9 * 0x5c + 0x23];
  puVar1[iVar9 * 0x5c + 0x23] = 0;
  if (cVar2 != '\0') {
    iVar10 = (int)(short)cVar2;
    cVar3 = _EnemyCheckBurstingBubble(iVar9,iVar10);
    if ((cVar3 != '\0') && (puVar1[iVar9 * 0x5c + 0x4a] != '\0')) {
      puVar1[iVar9 * 0x5c + 0x23] = cVar2;
      return;
    }
    cVar3 = _EnemyCheckBurstingBubble(iVar9,iVar10);
    if (((cVar3 == '\0') && (puVar1[iVar9 * 0x5c + 0x4a] != '\0')) &&
       (cVar3 = _TryAndTurnEnemy(iVar9,iVar10), cVar3 != '\0')) {
      puVar1[iVar9 * 0x5c + 0x4a] = 0;
      return;
    }
  }
  if (puVar1[iVar9 * 0x5c + 0x4a] != '\0') {
    puVar1[iVar9 * 0x5c + 0x4a] = 0;
  }
  uVar6 = _FigureEnemyRandomness(iVar9);
  sVar7 = _GetRandomFast(1,uVar6);
  if ((sVar7 == 1) || (iVar10 = _TimeBonus_GetBonus(), iVar10 < 1)) {
    sVar7 = (short)(char)puVar1[iVar9 * 0x5c + 0x24] - (short)(char)PTR__hero_0003f014[0x28];
    sVar4 = (short)(char)puVar1[iVar9 * 0x5c + 0x30] - (short)(char)PTR__hero_0003f014[0x34];
    local_3c = sVar4;
    if ((sVar4 < 0) && (uVar8 == 0xffffffff)) {
      local_3c = -sVar4;
    }
    local_3a = sVar7;
    if ((sVar7 < 0) && (uVar8 == 0xffffffff)) {
      local_3a = -sVar7;
    }
    sVar5 = _GetLevel();
    if ((uVar8 + 9 <= (uint)(int)sVar5) && (*PTR__gAIRegistered_0003f05c == '\0')) {
      _GetRandomFast(0,7);
    }
    if (cVar2 == '\x02') {
      local_3e = 1;
    }
    else if (cVar2 < '\x03') {
      if (cVar2 == '\x01') {
        local_3e = 2;
      }
      else {
LAB_00013e2b:
        _LocationErrorInt(0x7d8,1);
      }
    }
    else if (cVar2 == '\x03') {
      local_3e = 4;
    }
    else {
      if (cVar2 != '\x04') goto LAB_00013e2b;
      local_3e = 3;
    }
    if (sVar4 < 0) {
      if (sVar7 < 0) {
        if (local_3a < local_3c) {
          local_20[0] = 2;
LAB_00013f3d:
          local_20[1] = 4;
        }
        else {
          local_20[0] = 4;
LAB_00013eb6:
          local_20[1] = 2;
        }
      }
      else {
        if (sVar7 == 0) {
          local_20[0] = 2;
LAB_00013f0a:
          sVar7 = _GetRandomFast(1,2);
          local_20[1] = (sVar7 != 1) + 3;
          goto LAB_00013f6e;
        }
        if (local_3c <= local_3a) {
          local_20[0] = 3;
          goto LAB_00013eb6;
        }
        local_20[0] = 2;
LAB_00013efa:
        local_20[1] = 3;
      }
    }
    else if (sVar4 == 0) {
      if (sVar7 < 1) {
        if (sVar7 == 0) goto LAB_00013f74;
        local_20[0] = 4;
      }
      else {
        local_20[0] = 3;
      }
      sVar7 = _GetRandomFast(1,2);
      local_20[1] = (sVar7 != 1) + 1;
LAB_00013f6e:
    }
    else {
      if (sVar7 < 1) {
        if (sVar7 == 0) {
          local_20[0] = 1;
          goto LAB_00013f0a;
        }
        if (local_3a < local_3c) {
          local_20[0] = 1;
          goto LAB_00013f3d;
        }
LAB_00013f74:
        local_20[0] = 4;
      }
      else {
        if (local_3a < local_3c) {
          local_20[0] = 1;
          goto LAB_00013efa;
        }
        local_20[0] = 3;
      }
      local_20[1] = 1;
    }
    sVar7 = local_20[0];
    if ((local_3e != local_20[0]) && (*(short *)(puVar1 + iVar9 * 0x5c + 0x3c) < 6)) {
      if (*(short *)(puVar1 + iVar9 * 0x5c + 0x3a) == 0x1d) {
        cVar3 = _CanDoNormalPop(iVar9);
        if (cVar3 == '\0') {
          iVar10 = (int)sVar7;
        }
        else {
          iVar10 = (int)sVar7;
          cVar3 = _TryEnemyCreateBalloon(iVar9,iVar10);
          if (cVar3 != '\0') {
            return;
          }
        }
      }
      else {
        iVar10 = (int)local_20[0];
      }
      cVar3 = _TryAndTurnEnemy(iVar9,iVar10);
      if (cVar3 != '\0') {
        return;
      }
      if ((*(short *)(puVar1 + iVar9 * 0x5c + 0x3a) == 0x1e) &&
         (cVar3 = _TryEnemyPushBlock(iVar9,iVar10), cVar3 != '\0')) {
        return;
      }
      cVar3 = _CanDoNormalPop(iVar9);
      if (cVar3 != '\0') {
        if (((ushort)(*(short *)(puVar1 + iVar9 * 0x5c + 0x3a) - 0x1cU) < 2) &&
           (cVar3 = _TryEnemyPushBlock(iVar9,iVar10), cVar3 != '\0')) {
          return;
        }
        cVar3 = _TryRemoveGo(iVar9,iVar10);
        if (cVar3 != '\0') {
          return;
        }
      }
      (&cStack_25)[iVar10] = '\x01';
    }
    sVar4 = local_20[1];
    if (local_3e != local_20[1]) {
      iVar10 = (int)local_20[1];
      cVar3 = _TryAndTurnEnemy(iVar9,iVar10);
      if (cVar3 != '\0') {
        return;
      }
      cVar3 = _CanDoNormalPop(iVar9);
      if (cVar3 != '\0') {
        sVar5 = *(short *)(puVar1 + iVar9 * 0x5c + 0x3a);
        if ((((sVar5 == 0x1e) || (sVar5 == 0x1c)) || (sVar5 == 0x1d)) &&
           (cVar3 = _TryEnemyPushBlock(iVar9,(int)sVar7), cVar3 != '\0')) {
          return;
        }
        cVar3 = _TryRemoveGo(iVar9,iVar10);
        if (cVar3 != '\0') {
          return;
        }
      }
      (&cStack_25)[iVar10] = '\x01';
    }
    if (local_3e == sVar7) {
      iVar10 = 1;
    }
    else {
      if (local_3e != sVar4) goto LAB_00014180;
      iVar10 = 0;
    }
    sVar5 = local_20[iVar10];
    if (sVar5 == 3) {
      cVar3 = _TryAndTurnEnemy(iVar9,4);
      if (cVar3 != '\0') {
        return;
      }
      local_22 = CONCAT11(1,(undefined1)local_22);
    }
    else if (sVar5 == 4) {
      cVar3 = _TryAndTurnEnemy(iVar9,3);
      if (cVar3 != '\0') {
        return;
      }
      local_22 = CONCAT11(local_22._1_1_,1);
    }
    else if (sVar5 == 1) {
      cVar3 = _TryAndTurnEnemy(iVar9,2);
      if (cVar3 != '\0') {
        return;
      }
      local_24 = CONCAT11(1,(undefined1)local_24);
    }
    else if (sVar5 == 2) {
      cVar3 = _TryAndTurnEnemy(iVar9,1);
      if (cVar3 != '\0') {
        return;
      }
      local_24 = CONCAT11(local_24._1_1_,1);
    }
LAB_00014180:
    iVar10 = 1;
    do {
      if (((&cStack_25)[iVar10] == '\0') && (local_3e != (short)iVar10)) {
        cVar3 = _TryAndTurnEnemy(iVar9,iVar10);
        if (cVar3 != '\0') {
          return;
        }
        cVar3 = _CanDoNormalOtherPop(iVar9);
        if ((cVar3 != '\0') && (cVar3 = _TryRemoveGo(iVar9,iVar10), cVar3 != '\0')) {
          return;
        }
        (&cStack_25)[iVar10] = '\x01';
      }
      iVar10 = iVar10 + 1;
      if (iVar10 == 5) {
        iVar10 = 1;
        do {
          if ((&cStack_25)[iVar10] == '\0') {
            cVar3 = _TryAndTurnEnemy(iVar9,iVar10);
            if (cVar3 != '\0') {
              return;
            }
            (&cStack_25)[iVar10] = '\x01';
          }
          iVar10 = iVar10 + 1;
        } while (iVar10 != 5);
        iVar10 = 0;
        do {
          *(undefined1 *)((int)&local_24 + iVar10) = 0;
          iVar10 = iVar10 + 1;
        } while (iVar10 != 4);
        cVar3 = _TryRemoveGo(iVar9,(int)sVar7);
        if (cVar3 == '\0') {
          (&cStack_25)[sVar7] = '\x01';
          cVar3 = _TryRemoveGo(iVar9,(int)sVar4);
          if (cVar3 == '\0') {
            (&cStack_25)[sVar4] = '\x01';
            sStack_32 = 2;
            do {
              iVar10 = 1;
              do {
                if ((&cStack_25)[iVar10] == '\0') {
                  cVar3 = _TryRemoveGo(iVar9,iVar10);
                  if (cVar3 != '\0') {
                    return;
                  }
                  (&cStack_25)[iVar10] = '\x01';
                }
                iVar10 = iVar10 + 1;
              } while (iVar10 != 5);
              sStack_32 = sStack_32 + -1;
            } while (sStack_32 != 0);
            puVar1[iVar9 * 0x5c + 0x23] = cVar2;
            puVar1[iVar9 * 0x5c + 0x4a] = 1;
          }
        }
        return;
      }
    } while( true );
  }
  puVar1[iVar9 * 0x5c + 0x23] = cVar2;
  puVar1 = PTR__enemy_0003f04c;
  iVar9 = (int)param_1;
  sVar7 = *(short *)(PTR__enemy_0003f04c + iVar9 * 0x5c + 0x58);
  if (sVar7 == 0) goto LAB_000139b4;
  if (sVar7 == 2) {
    cVar2 = _TryRemoveGo(iVar9,(int)(char)PTR__enemy_0003f04c[iVar9 * 0x5c + 0x23]);
LAB_00013a81:
    if (cVar2 != '\0') goto LAB_00013bc8;
  }
  else if (sVar7 < 3) {
    if (sVar7 == 1) {
      cVar2 = _TryEnemyPushBlock(iVar9,(int)(char)PTR__enemy_0003f04c[iVar9 * 0x5c + 0x23]);
      goto LAB_00013a81;
    }
  }
  else {
    if (sVar7 == 3) {
      cVar2 = _TryEnemyCreateBalloon(iVar9,(int)(char)PTR__enemy_0003f04c[iVar9 * 0x5c + 0x23]);
      goto LAB_00013a81;
    }
    if (sVar7 == 4) {
      if (*(short *)(PTR__enemy_0003f04c + iVar9 * 0x5c + 0x52) < 10) {
        *(undefined2 *)(PTR__enemy_0003f04c + iVar9 * 0x5c + 0x58) = 4;
        *(short *)(puVar1 + iVar9 * 0x5c + 0x52) = *(short *)(puVar1 + iVar9 * 0x5c + 0x52) + 1;
        puVar1[iVar9 * 0x5c + 0x4a] = 1;
        return;
      }
      *(undefined2 *)(PTR__enemy_0003f04c + iVar9 * 0x5c + 0x52) = 0;
      *(undefined2 *)(puVar1 + iVar9 * 0x5c + 0x58) = 0;
    }
  }
LAB_000139b4:
  cVar2 = puVar1[iVar9 * 0x5c + 0x23];
  puVar1[iVar9 * 0x5c + 0x23] = 0;
  local_24 = 3;
  local_22 = 4;
  local_20[0] = 1;
  local_20[1] = 2;
  sVar7 = 8;
  do {
    sVar4 = _GetRandomFast(0,3);
    sVar5 = _GetRandomFast(0,3);
    uVar6 = (&local_24)[sVar5];
    (&local_24)[sVar5] = (&local_24)[sVar4];
    (&local_24)[sVar4] = uVar6;
    sVar7 = sVar7 + -1;
  } while (sVar7 != 0);
  iVar10 = 0;
  do {
    sVar7 = (&local_24)[iVar10];
    if (sVar7 == 2) {
      if (cVar2 != '\x01') {
        uVar11 = 2;
        goto LAB_00013b26;
      }
    }
    else if (sVar7 < 3) {
      if ((sVar7 == 1) && (cVar2 != '\x02')) {
        uVar11 = 1;
        goto LAB_00013b26;
      }
    }
    else if (sVar7 == 3) {
      if (cVar2 != '\x04') {
        uVar11 = 3;
        goto LAB_00013b26;
      }
    }
    else if ((sVar7 == 4) && (cVar2 != '\x03')) {
      uVar11 = 4;
LAB_00013b26:
      cVar3 = _TryAndTurnEnemy(iVar9,uVar11);
      if (cVar3 != '\0') {
        return;
      }
    }
    iVar10 = iVar10 + 1;
  } while (iVar10 != 4);
  if (cVar2 == '\x02') {
    uVar11 = 1;
LAB_00013b8f:
    cVar2 = _TryAndTurnEnemy(iVar9,uVar11);
    if (cVar2 != '\0') {
      return;
    }
  }
  else {
    if ('\x02' < cVar2) {
      if (cVar2 == '\x03') {
        uVar11 = 4;
      }
      else {
        if (cVar2 != '\x04') goto LAB_00013b98;
        uVar11 = 3;
      }
      goto LAB_00013b8f;
    }
    if (cVar2 == '\x01') {
      uVar11 = 2;
      goto LAB_00013b8f;
    }
  }
LAB_00013b98:
  if (0 < *(short *)(puVar1 + iVar9 * 0x5c + 0x48)) {
    _ToastBubble(iVar9);
    *(undefined2 *)(puVar1 + iVar9 * 0x5c + 0x48) = 0;
    return;
  }
  *(short *)(puVar1 + iVar9 * 0x5c + 0x48) = *(short *)(puVar1 + iVar9 * 0x5c + 0x48) + 1;
  puVar1[iVar9 * 0x5c + 0x23] = 3;
LAB_00013bc8:
  puVar1[iVar9 * 0x5c + 0x4a] = 1;
  return;
}


// ==== _EnemyAI @ 00014296 ====

void _EnemyAI(char param_1)

{
  char cVar1;
  undefined *puVar2;
  int iVar3;
  undefined1 uVar4;
  short sVar5;
  short sVar6;
  short unaff_SI;
  bool bVar7;
  bool bVar8;
  
  puVar2 = PTR__enemy_0003f04c;
  iVar3 = (short)param_1 * 0x5c;
  if ((*(short *)(PTR__enemy_0003f04c + iVar3 + 0x14) ==
       (short)((*(short *)(PTR__enemy_0003f04c + iVar3 + 0x14) / 0x28) * 0x28)) &&
     (*(short *)(PTR__enemy_0003f04c + iVar3 + 0x12) ==
      (short)((*(short *)(PTR__enemy_0003f04c + iVar3 + 0x12) / 0x28) * 0x28))) {
    uVar4 = 1;
  }
  else {
    uVar4 = 0;
  }
  PTR__enemy_0003f04c[(short)param_1 * 0x5c + 0x31] = uVar4;
  if (puVar2[param_1 * 0x5c + 0x31] != '\0') {
    _FigureEnemyMove((int)param_1);
  }
  puVar2 = PTR__enemy_0003f04c;
  if (PTR__enemy_0003f04c[param_1 * 0x5c + 0x4a] != '\0') {
    return;
  }
  sVar6 = *(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x3a);
  if (sVar6 == 0x1d) {
    if (*(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x3c) < 4) {
      *(undefined2 *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x50) = 8;
    }
    else if (*(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x50) == 0) {
      *(undefined2 *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x50) = 2;
    }
    unaff_SI = *(short *)(puVar2 + param_1 * 0x5c + 0x50);
    if ((unaff_SI < 2) || (3 < *(short *)(puVar2 + param_1 * 0x5c + 0x3c))) {
      if (puVar2[param_1 * 0x5c + 0x31] != '\0') {
        sVar6 = *(short *)(puVar2 + param_1 * 0x5c + 0x4e);
        sVar5 = sVar6 + 1;
        *(short *)(puVar2 + param_1 * 0x5c + 0x4e) = sVar5;
        if (sVar5 < 0xd) {
          if (sVar5 != 0xc) {
            if (10 < sVar5) {
LAB_00012a30:
              *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x50) = 8;
              unaff_SI = 8;
              goto LAB_00012a4e;
            }
            if (sVar5 != 10) {
              if (7 < sVar5) {
LAB_00012a27:
                iVar3 = _TimeBonus_GetBonus();
                if (0 < iVar3) {
                  *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x50) = 2;
                  goto LAB_00012a14;
                }
                goto LAB_00012a30;
              }
              if (sVar5 < 6) {
                if (3 < sVar5) goto LAB_00012a27;
                if (sVar6 == 0 || sVar5 < 1) goto LAB_00012a4e;
              }
            }
          }
          *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x50) = 4;
          unaff_SI = 4;
        }
        else {
          *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x50) = 2;
          *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x4e) = 0;
LAB_00012a14:
          unaff_SI = 2;
        }
      }
    }
    else {
      unaff_SI = unaff_SI + 6;
      *(short *)(puVar2 + param_1 * 0x5c + 0x50) = unaff_SI;
    }
LAB_00012a4e:
    if ((*(short *)(puVar2 + param_1 * 0x5c + 0x3c) < 4) && (-1 < unaff_SI)) {
      unaff_SI = unaff_SI + 6;
      *(short *)(puVar2 + param_1 * 0x5c + 0x50) = unaff_SI;
    }
    goto LAB_000127e2;
  }
  if (sVar6 < 0x1e) {
    if (sVar6 == 0x1b) {
      if (*(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x3c) < 4) {
        *(undefined2 *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x4e) = 8;
LAB_0001282e:
        if (3 < *(short *)(puVar2 + param_1 * 0x5c + 0x3c)) goto LAB_0001283c;
        *(short *)(puVar2 + param_1 * 0x5c + 0x4e) = *(short *)(puVar2 + param_1 * 0x5c + 0x4e) + 6;
LAB_000128a3:
        if (*(short *)(puVar2 + param_1 * 0x5c + 0x3c) < 4) {
          *(short *)(puVar2 + param_1 * 0x5c + 0x4e) =
               *(short *)(puVar2 + param_1 * 0x5c + 0x4e) + 6;
        }
      }
      else {
        if (*(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x4e) == 0) {
          *(undefined2 *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x4e) = 2;
          goto LAB_0001282e;
        }
LAB_0001283c:
        if (puVar2[param_1 * 0x5c + 0x31] != '\0') {
          iVar3 = _TimeBonus_GetBonus();
          if (iVar3 < 1) {
            sVar6 = (short)(char)puVar2[param_1 * 0x5c + 0x24] -
                    (short)(char)PTR__hero_0003f014[0x28];
            if ((sVar6 < 0) && (0 < *(short *)(puVar2 + param_1 * 0x5c + 0x3c))) {
              sVar6 = -sVar6;
            }
            sVar5 = (short)(char)puVar2[param_1 * 0x5c + 0x30] -
                    (short)(char)PTR__hero_0003f014[0x34];
            if ((sVar5 < 0) && (0 < *(short *)(puVar2 + param_1 * 0x5c + 0x3c))) {
              sVar5 = -sVar5;
            }
            if ((1 < sVar6) || (1 < sVar5)) {
              *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x4e) = 4;
              goto LAB_000128a3;
            }
          }
          *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x4e) = 2;
          goto LAB_000128a3;
        }
      }
      unaff_SI = *(short *)(puVar2 + param_1 * 0x5c + 0x4e);
      goto LAB_000127e2;
    }
    if (sVar6 != 0x1c) {
LAB_000127ce:
      _LocationError(0x7d8,6);
      goto LAB_000127e2;
    }
    if (*(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x3c) < 4) {
      *(undefined2 *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x50) = 6;
    }
    else if (*(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x50) == 0) {
      *(undefined2 *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x50) = 2;
    }
    if (puVar2[param_1 * 0x5c + 0x31] == '\0') goto LAB_00012954;
    sVar6 = *(short *)(puVar2 + param_1 * 0x5c + 0x3c);
    if (3 < sVar6) {
      sVar6 = (short)(char)puVar2[param_1 * 0x5c + 0x24] - (short)(char)PTR__hero_0003f014[0x28];
      if (sVar6 < 0) {
        sVar6 = -sVar6;
      }
      sVar5 = (short)(char)puVar2[param_1 * 0x5c + 0x30] - (short)(char)PTR__hero_0003f014[0x34];
      if (sVar5 < 0) {
        sVar5 = -sVar5;
      }
      iVar3 = _TimeBonus_GetBonus();
      if ((iVar3 < 1) || (*(short *)(puVar2 + param_1 * 0x5c + 0x3c) < 4)) {
        if ((sVar6 < 2) && (sVar5 < 2)) goto LAB_00012946;
        *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x50) = 8;
      }
      else if ((sVar6 < 3) && (sVar5 < 3)) {
LAB_00012946:
        *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x50) = 2;
      }
      else {
        *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x50) = 4;
      }
LAB_00012954:
      sVar6 = *(short *)(puVar2 + param_1 * 0x5c + 0x3c);
      if (3 < sVar6) goto LAB_00012c1e;
    }
    if (((char)puVar2[param_1 * 0x5c + 0x30] < '\x04') ||
       ('\x06' < (char)puVar2[param_1 * 0x5c + 0x24])) {
      *(short *)(puVar2 + param_1 * 0x5c + 0x50) =
           *(short *)(puVar2 + param_1 * 0x5c + 0x50) + sVar6 * 2;
    }
    else {
      *(short *)(puVar2 + param_1 * 0x5c + 0x50) = *(short *)(puVar2 + param_1 * 0x5c + 0x50) + 6;
    }
    sVar6 = *(short *)(puVar2 + param_1 * 0x5c + 0x3c) * 3 +
            *(short *)(puVar2 + param_1 * 0x5c + 0x50);
    *(short *)(puVar2 + param_1 * 0x5c + 0x50) = sVar6;
    if (*(short *)(puVar2 + param_1 * 0x5c + 0x3c) == 3) {
      *(short *)(puVar2 + param_1 * 0x5c + 0x50) = sVar6 + -1;
    }
  }
  else {
    if (sVar6 == 0x3039) {
      if (*(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x3c) < 4) {
        *(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x4e) =
             *(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x3c) * 10;
      }
      else if (*(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x50) == 0) {
        *(undefined2 *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x50) = 2;
      }
      if (puVar2[param_1 * 0x5c + 0x31] == '\0') {
LAB_00012b89:
        if (3 < *(short *)(puVar2 + param_1 * 0x5c + 0x3c)) goto LAB_00012c1e;
      }
      else if (3 < *(short *)(puVar2 + param_1 * 0x5c + 0x3c)) {
        sVar6 = (short)(char)puVar2[param_1 * 0x5c + 0x24] - (short)(char)PTR__hero_0003f014[0x28];
        if (sVar6 < 0) {
          sVar6 = -sVar6;
        }
        sVar5 = (short)(char)puVar2[param_1 * 0x5c + 0x30] - (short)(char)PTR__hero_0003f014[0x34];
        if (sVar5 < 0) {
          sVar5 = -sVar5;
        }
        if ((sVar6 < 5) && (sVar5 < 2)) {
          *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x50) = 8;
        }
        else {
          *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x50) = 2;
        }
        goto LAB_00012b89;
      }
      *(short *)(puVar2 + param_1 * 0x5c + 0x50) = *(short *)(puVar2 + param_1 * 0x5c + 0x50) + -10;
      goto LAB_00012c1e;
    }
    if (sVar6 == 0x303a) {
      if (*(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x3c) == 3) {
        *(undefined2 *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x50) = 9;
      }
      else if (*(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x50) == 0) {
        *(undefined2 *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x50) = 4;
      }
      if (puVar2[param_1 * 0x5c + 0x31] == '\0') {
        sVar6 = *(short *)(puVar2 + param_1 * 0x5c + 0x3c);
        if (sVar6 < 4) goto LAB_00012c0b;
      }
      else {
        sVar6 = *(short *)(puVar2 + param_1 * 0x5c + 0x3c);
        if (sVar6 < 4) {
LAB_00012c0b:
          *(short *)(puVar2 + param_1 * 0x5c + 0x3c) = sVar6 + 0xd;
        }
        else {
          sVar6 = *(short *)(puVar2 + param_1 * 0x5c + 0x4e) + 1;
          *(short *)(puVar2 + param_1 * 0x5c + 0x4e) = sVar6;
          if (sVar6 < 0xd) {
            if (sVar6 < 9) {
              if (sVar6 == 8) {
                *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x50) = 1;
              }
            }
            else {
              *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x50) = 0x10;
            }
          }
          else {
            *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x50) = 4;
            *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x4e) = 0;
          }
        }
      }
      if (*(short *)(puVar2 + param_1 * 0x5c + 0x3c) == 3) {
        *(short *)(puVar2 + param_1 * 0x5c + 0x50) = *(short *)(puVar2 + param_1 * 0x5c + 0x50) + -2
        ;
      }
      goto LAB_00012c1e;
    }
    if (sVar6 != 0x1e) goto LAB_000127ce;
    if (*(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x3c) < 4) {
      *(undefined2 *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x50) = 7;
LAB_00012a84:
      if (*(short *)(puVar2 + param_1 * 0x5c + 0x3c) < 4) {
        *(short *)(puVar2 + param_1 * 0x5c + 0x50) = *(short *)(puVar2 + param_1 * 0x5c + 0x50) + 7;
      }
    }
    else if (*(short *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x50) == 0) {
      *(undefined2 *)(PTR__enemy_0003f04c + param_1 * 0x5c + 0x50) = 2;
      goto LAB_00012a84;
    }
    if (puVar2[param_1 * 0x5c + 0x31] == '\0') {
      if (3 < *(short *)(puVar2 + param_1 * 0x5c + 0x3c)) goto LAB_00012afe;
LAB_00012af9:
      *(short *)(puVar2 + param_1 * 0x5c + 0x50) = *(short *)(puVar2 + param_1 * 0x5c + 0x50) + 7;
    }
    else {
      if (*(short *)(puVar2 + param_1 * 0x5c + 0x3c) < 4) goto LAB_00012af9;
      *(short *)(puVar2 + param_1 * 0x5c + 0x4e) = *(short *)(puVar2 + param_1 * 0x5c + 0x4e) + 1;
      iVar3 = _TimeBonus_GetBonus();
      if (iVar3 < 1) {
        sVar6 = *(short *)(puVar2 + param_1 * 0x5c + 0x4e);
        if (sVar6 < 8) {
          if (sVar6 != 7) {
            bVar8 = SBORROW2(sVar6,2);
            sVar5 = sVar6 + -2;
            bVar7 = sVar6 == 2;
            goto LAB_00012adb;
          }
          goto LAB_00012aea;
        }
LAB_00012ac7:
        *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x50) = 2;
        *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x4e) = 0;
      }
      else {
        sVar6 = *(short *)(puVar2 + param_1 * 0x5c + 0x4e);
        if (7 < sVar6) goto LAB_00012ac7;
        if (sVar6 == 7) {
LAB_00012aea:
          *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x50) = 4;
        }
        else {
          bVar8 = SBORROW2(sVar6,3);
          sVar5 = sVar6 + -3;
          bVar7 = sVar6 == 3;
LAB_00012adb:
          if (bVar7 || bVar8 != sVar5 < 0) {
            if (0 < sVar6) goto LAB_00012aea;
          }
          else {
            *(undefined2 *)(puVar2 + param_1 * 0x5c + 0x50) = 8;
          }
        }
      }
    }
LAB_00012afe:
    if (*(short *)(puVar2 + param_1 * 0x5c + 0x3c) == 3) {
      *(short *)(puVar2 + param_1 * 0x5c + 0x50) = *(short *)(puVar2 + param_1 * 0x5c + 0x50) + -1;
    }
  }
LAB_00012c1e:
  unaff_SI = *(short *)(puVar2 + param_1 * 0x5c + 0x50);
LAB_000127e2:
  cVar1 = puVar2[param_1 * 0x5c + 0x23];
  if (cVar1 == '\x02') {
    *(short *)(puVar2 + param_1 * 0x5c + 0x12) =
         *(short *)(puVar2 + param_1 * 0x5c + 0x12) + unaff_SI;
    *(short *)(puVar2 + param_1 * 0x5c + 0x16) =
         *(short *)(puVar2 + param_1 * 0x5c + 0x16) + unaff_SI;
  }
  else {
    if ('\x02' < cVar1) {
      if (cVar1 == '\x03') {
        *(short *)(puVar2 + param_1 * 0x5c + 0x14) =
             *(short *)(puVar2 + param_1 * 0x5c + 0x14) - unaff_SI;
        *(short *)(puVar2 + param_1 * 0x5c + 0x18) =
             *(short *)(puVar2 + param_1 * 0x5c + 0x18) - unaff_SI;
      }
      else {
        if (cVar1 != '\x04') {
          return;
        }
        *(short *)(puVar2 + param_1 * 0x5c + 0x14) =
             *(short *)(puVar2 + param_1 * 0x5c + 0x14) + unaff_SI;
        *(short *)(puVar2 + param_1 * 0x5c + 0x18) =
             *(short *)(puVar2 + param_1 * 0x5c + 0x18) + unaff_SI;
      }
      puVar2 = PTR__enemy_0003f04c;
      sVar6 = *(short *)(PTR__enemy_0003f04c + (short)param_1 * 0x5c + 0x14);
      sVar5 = sVar6 % 0x28;
      PTR__enemy_0003f04c[(short)param_1 * 0x5c + 0x32] = (char)sVar5;
      puVar2[(short)param_1 * 0x5c + 0x24] = (char)((short)(sVar6 - sVar5) / 0x28);
      return;
    }
    if (cVar1 != '\x01') {
      return;
    }
    *(short *)(puVar2 + param_1 * 0x5c + 0x12) =
         *(short *)(puVar2 + param_1 * 0x5c + 0x12) - unaff_SI;
    *(short *)(puVar2 + param_1 * 0x5c + 0x16) =
         *(short *)(puVar2 + param_1 * 0x5c + 0x16) - unaff_SI;
  }
  puVar2 = PTR__enemy_0003f04c;
  sVar6 = *(short *)(PTR__enemy_0003f04c + (short)param_1 * 0x5c + 0x12);
  sVar5 = sVar6 % 0x28;
  PTR__enemy_0003f04c[(short)param_1 * 0x5c + 0x38] = (char)sVar5;
  puVar2[(short)param_1 * 0x5c + 0x30] = (char)((short)(sVar6 - sVar5) / 0x28);
  return;
}


// ==== _DebugValues @ 00014373 ====

void _DebugValues(undefined4 param_1,undefined4 param_2)

{
  undefined1 local_20c [256];
  undefined1 local_10c [256];
  
  _RezlibFadeIn();
  _ShowCursor();
  _TurnISpOff();
  _CopyCStringToPascal(param_1,local_20c);
  _NumToString(param_2,local_10c);
  _ParamText(local_20c,local_10c,&DAT_0003360c,&DAT_0003360c);
  _StopAlert(8000,0);
  return;
}


// ==== _DoResultError @ 000143f1 ====

void _DoResultError(short param_1,short param_2,short param_3,short param_4)

{
  char local_21c [256];
  undefined1 local_11c [268];
  
  _RezlibFadeIn();
  _ShowCursor();
  _TurnISpOff();
  _GetIndString(local_21c,(int)param_1,(int)param_2);
  if (local_21c[0] == '\0') {
    _DebugValues("Sorry, but I can\'t load an error message I wanted to display!",0);
    _CleanUp();
  }
  _NumToString((int)param_3,local_11c);
  _ParamText(local_21c,local_11c,&DAT_0003360c,&DAT_0003360c);
  _StopAlert((int)param_4,0);
  _CleanUp();
  return;
}


// ==== _ResultErrorInt @ 000144b9 ====

void _ResultErrorInt(short param_1,short param_2,short param_3)

{
  _DoResultError((int)param_1,(int)param_2,(int)param_3,0x232d);
  return;
}


// ==== _ResultError @ 000144e5 ====

void _ResultError(short param_1,short param_2,short param_3)

{
  _DoResultError((int)param_1,(int)param_2,(int)param_3,0x2329);
  return;
}


// ==== _DoLocationError @ 00014511 ====

void _DoLocationError(short param_1,short param_2,short param_3)

{
  char local_11c [268];
  
  _RezlibFadeIn();
  _ShowCursor();
  _TurnISpOff();
  _GetIndString(local_11c,(int)param_1,(int)param_2);
  if (local_11c[0] == '\0') {
    _DebugValues("Sorry, but I can\'t load an error message I wanted to display!",0);
    _CleanUp();
  }
  _ParamText(local_11c,&DAT_0003360c,&DAT_0003360c,&DAT_0003360c);
  _StopAlert((int)param_3,0);
  _CleanUp();
  return;
}


// ==== _LocationErrorInt @ 000145be ====

void _LocationErrorInt(short param_1,short param_2)

{
  _DoLocationError((int)param_1,(int)param_2,0x232c);
  return;
}


// ==== _LocationError @ 000145e2 ====

void _LocationError(short param_1,short param_2)

{
  _DoLocationError((int)param_1,(int)param_2,9000);
  return;
}


// ==== _ResourceError @ 00014606 ====

void _ResourceError(short param_1,short param_2,undefined4 param_3,short param_4)

{
  undefined1 local_31c [256];
  char local_21c [256];
  undefined1 local_11c [268];
  
  _RezlibFadeIn();
  _ShowCursor();
  _TurnISpOff();
  _GetIndString(local_21c,(int)param_1,(int)param_2);
  if (local_21c[0] == '\0') {
    _DebugValues("Sorry, but I can\'t load an error message I wanted to display!",0);
    _CleanUp();
  }
  _NumToString((int)param_4,local_11c);
  _CopyCStringToPascal(param_3,local_31c);
  _ParamText(local_21c,local_31c,local_11c,&DAT_0003360c);
  _StopAlert(0x232a,0);
  _CleanUp();
  return;
}


// ==== _OutOfMemory @ 000146d1 ====

void _OutOfMemory(undefined4 param_1)

{
  undefined1 local_10c [260];
  
  _RezlibFadeIn();
  _ShowCursor();
  _TurnISpOff();
  _CopyCStringToPascal(param_1,local_10c);
  _ParamText(local_10c,&DAT_0003360c,&DAT_0003360c,&DAT_0003360c);
  _StopAlert(0x232b,0);
  _CleanUp();
  return;
}


// ==== _StdError @ 00014741 ====

void _StdError(undefined4 param_1,undefined4 param_2)

{
  undefined1 local_20c [256];
  undefined1 local_10c [256];
  
  _RezlibFadeIn();
  _ShowCursor();
  _TurnISpOff();
  _CopyCStringToPascal(param_1,local_20c);
  _NumToString(param_2,local_10c);
  _ParamText(local_20c,local_10c,&DAT_0003360c,&DAT_0003360c);
  _StopAlert(0x1f41,0);
  _CleanUp();
  return;
}


// ==== _ASWPlotCIcon @ 000147c4 ====

void _ASWPlotCIcon(undefined4 param_1,int *param_2)

{
  int iVar1;
  undefined *puVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  undefined4 local_20 [4];
  
  if (*PTR__gRunningTiger_0003f06c == '\0') {
    _PlotCIcon(param_1,param_2);
  }
  else {
    _GetGWorld(local_20,0);
    puVar2 = PTR__gTransGWorld_0003f064;
    _SetGWorld(*(undefined4 *)PTR__gTransGWorld_0003f064,0);
    _EraseRect(*param_2 + 0x46);
    _PlotCIcon(*param_2 + 0x46,param_2);
    _SetGWorld(local_20[0],0);
    iVar1 = *param_2;
    uVar3 = _GetPortBitMapForCopyBits(*(undefined4 *)puVar2);
    _CopyBits(*param_2,uVar3,iVar1 + 0x46,iVar1 + 0x46,0x24,0);
    iVar1 = *param_2;
    uVar3 = _GetPortBitMapForCopyBits(local_20[0]);
    uVar4 = _GetPortBitMapForCopyBits(*(undefined4 *)puVar2);
    _CopyBits(uVar4,uVar3,iVar1 + 0x46,param_1,0x24,0);
  }
  return;
}


// ==== _ASWPlotCIconHandle @ 000148cb ====

void _ASWPlotCIconHandle(undefined4 param_1,short param_2,short param_3,int *param_4)

{
  double dVar1;
  double dVar2;
  undefined *puVar3;
  short sVar4;
  undefined4 uVar5;
  int iVar6;
  undefined4 uVar7;
  byte *pbVar8;
  int iVar9;
  int local_40;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20 [4];
  
  if (*PTR__gRunningTiger_0003f06c == '\0') {
    _PlotCIconHandle(param_1,(int)param_2,(int)param_3,param_4);
  }
  else {
    local_24 = *(undefined4 *)(*param_4 + 0x4a);
    local_28 = *(undefined4 *)(*param_4 + 0x46);
    _GetGWorld(local_20,0);
    puVar3 = PTR__gTransGWorld_0003f064;
    uVar5 = _GetGWorldPixMap(*(undefined4 *)PTR__gTransGWorld_0003f064);
    _LockPixels(uVar5);
    _SetGWorld(*(undefined4 *)puVar3,0);
    _EraseRect(&local_28);
    _ASWPlotCIcon(&local_28,param_4);
    uVar5 = _GetGWorldPixMap(*(undefined4 *)puVar3);
    iVar6 = _GetPixBaseAddr(uVar5);
    sVar4 = _GetPixRowBytes(uVar5);
    if (iVar6 != 0) {
      for (local_40 = 0; local_40 < (short)((short)local_24 - (short)local_28);
          local_40 = local_40 + 1) {
        pbVar8 = (byte *)(iVar6 + local_40 * sVar4);
        for (iVar9 = 0; dVar2 = DOUBLE_00033fc0, dVar1 = DOUBLE_00033fb8, iVar9 < sVar4;
            iVar9 = iVar9 + 4) {
          *pbVar8 = (byte)(int)((double)(int)(0xff - (uint)*pbVar8) * DOUBLE_00033fb8 +
                               DOUBLE_00033fc0);
          pbVar8[1] = (byte)(int)((double)(int)(0xff - (uint)pbVar8[1]) * dVar1 + dVar2);
          pbVar8[2] = (byte)(int)((double)(int)(0xff - (uint)pbVar8[2]) * dVar1 + dVar2);
          pbVar8 = pbVar8 + 4;
        }
      }
    }
    puVar3 = PTR__gTransGWorld_0003f064;
    uVar5 = _GetGWorldPixMap(*(undefined4 *)PTR__gTransGWorld_0003f064);
    _UnlockPixels(uVar5);
    _SetGWorld(local_20[0],0);
    uVar5 = _GetPortBitMapForCopyBits(local_20[0]);
    uVar7 = _GetPortBitMapForCopyBits(*(undefined4 *)puVar3);
    _CopyBits(uVar7,uVar5,&local_28,param_1,0x24,0);
  }
  return;
}


// ==== _InitSpritePlottingTechnique @ 00014ab5 ====

void _InitSpritePlottingTechnique(void)

{
  undefined *puVar1;
  char cVar2;
  short sVar3;
  
  sVar3 = _GetShortPref(0x39);
  puVar1 = PTR__gUsePlotIcon_0003413c;
  *PTR__gUsePlotIcon_0003413c = sVar3 == 1;
  cVar2 = _IsDoubleBuffered();
  if ((cVar2 != '\0') && (*puVar1 == '\0')) {
    *puVar1 = 1;
  }
  return;
}


// ==== _UsingQDPlotting @ 00014aec ====

undefined1 _UsingQDPlotting(void)

{
  return *PTR__gUsePlotIcon_0003413c;
}


// ==== _ReadSpriteCount @ 00014af9 ====

int _ReadSpriteCount(short param_1)

{
  return (int)(short)(**(short **)(PTR__gSpriteDataRes_00034140 + param_1 * 4) + 1);
}


// ==== _ReadSpriteFrameData @ 00014b11 ====

void _ReadSpriteFrameData(short param_1,short param_2,undefined2 *param_3,undefined2 *param_4)

{
  undefined2 *puVar1;
  
  puVar1 = (undefined2 *)(*(int *)(PTR__gSpriteDataRes_00034140 + param_1 * 4) + param_2 * 4);
  *param_3 = puVar1[-1];
  *param_4 = *puVar1;
  return;
}


// ==== _FindFrameLoc @ 00014b3c ====

int _FindFrameLoc(short param_1,short param_2,short param_3)

{
  return *(int *)(PTR__gCSData_00034128 + param_1 * 4) + 200 +
         *(short *)(*(int *)(PTR__gCSData_00034128 + param_1 * 4) + param_2 * 2) * 4 + param_3 * 4;
}


// ==== _LoadSpriteDataRes @ 00014b63 ====

void * _LoadSpriteDataRes(short param_1)

{
  undefined4 *puVar1;
  undefined4 uVar2;
  void *pvVar3;
  size_t sVar4;
  
  puVar1 = (undefined4 *)_GetResource(0x62745350,(int)param_1);
  if (puVar1 == (undefined4 *)0x0) {
    _ResourceError(0x7d2,0xc,"btSP",(int)param_1);
  }
  _HLock(puVar1);
  uVar2 = _GetHandleSize(puVar1);
  pvVar3 = (void *)_NewPtr(uVar2);
  if (pvVar3 == (void *)0x0) {
    _OutOfMemory("LoadSpriteDataRes, blit.c");
  }
  sVar4 = _GetHandleSize(puVar1);
  if (0 < (int)sVar4) {
    _memmove(pvVar3,(void *)*puVar1,sVar4);
  }
  _ReleaseResource(puVar1);
  return pvVar3;
}


// ==== _CompToScreen @ 00014bfe ====

void _CompToScreen(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  _SetToScreen();
  uVar1 = _GetWindowPort(*(undefined4 *)PTR__environment_0003f028);
  uVar1 = _GetPortBitMapForCopyBits(uVar1);
  uVar2 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gCompGWorld_0003f020);
  _CopyBits(uVar2,uVar1,&stack0x00000004,&stack0x0000000c,0,0);
  return;
}


// ==== _TransToScreen @ 00014c62 ====

void _TransToScreen(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  _SetToScreen();
  uVar1 = _GetWindowPort(*(undefined4 *)PTR__environment_0003f028);
  uVar1 = _GetPortBitMapForCopyBits(uVar1);
  uVar2 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gTransGWorld_0003f064);
  _CopyBits(uVar2,uVar1,&stack0x00000004,&stack0x0000000c,9,0);
  return;
}


// ==== _TransToComp @ 00014cc6 ====

void _TransToComp(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  uVar1 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gCompGWorld_0003f020);
  uVar2 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gTransGWorld_0003f064);
  _CopyBits(uVar2,uVar1,&stack0x00000004,&stack0x0000000c,9,0);
  return;
}


// ==== _TransToBgnd @ 00014d1d ====

void _TransToBgnd(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  uVar1 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gBgndGWorld_0003f01c);
  uVar2 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gTransGWorld_0003f064);
  _CopyBits(uVar2,uVar1,&stack0x00000004,&stack0x0000000c,0x27,0);
  return;
}


// ==== _CompToScreenMode @ 00014d74 ====

void _CompToScreenMode(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  int iVar3;
  short in_stack_00000014;
  
  iVar3 = (int)in_stack_00000014;
  _SetToScreen();
  uVar1 = _GetWindowPort(*(undefined4 *)PTR__environment_0003f028);
  uVar1 = _GetPortBitMapForCopyBits(uVar1);
  uVar2 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gCompGWorld_0003f020);
  _CopyBits(uVar2,uVar1,&stack0x00000004,&stack0x0000000c,iVar3,0);
  return;
}


// ==== _ScreenToComp @ 00014dda ====

void _ScreenToComp(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  uVar1 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gCompGWorld_0003f020);
  uVar2 = _GetWindowPort(*(undefined4 *)PTR__environment_0003f028);
  uVar2 = _GetPortBitMapForCopyBits(uVar2);
  _CopyBits(uVar2,uVar1,&stack0x00000004,&stack0x0000000c,0,0);
  return;
}


// ==== _CustomCompToScreen @ 00014e39 ====

void _CustomCompToScreen(void)

{
  _CompToScreen();
  return;
}


// ==== _BgndToComp @ 00014e42 ====

void _BgndToComp(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  uVar1 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gCompGWorld_0003f020);
  uVar2 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gBgndGWorld_0003f01c);
  _CopyBits(uVar2,uVar1,&stack0x00000004,&stack0x0000000c,0,0);
  return;
}


// ==== _CompToSpriteGWorld @ 00014e99 ====

void _CompToSpriteGWorld(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  uVar1 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gSpriteGWorld_0003f024);
  uVar2 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gCompGWorld_0003f020);
  _CopyBits(uVar2,uVar1,&stack0x00000004,&stack0x0000000c,0,0);
  return;
}


// ==== _SpriteGWorldToCompGWorld @ 00014ef0 ====

void _SpriteGWorldToCompGWorld(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  uVar1 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gCompGWorld_0003f020);
  uVar2 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gSpriteGWorld_0003f024);
  _CopyBits(uVar2,uVar1,&stack0x00000004,&stack0x0000000c,0,0);
  return;
}


// ==== _CustomBgndToComp @ 00014f47 ====

void _CustomBgndToComp(int param_1,int param_2,int param_3)

{
  int iVar1;
  int iVar2;
  int iVar3;
  uint uVar4;
  undefined8 *puVar5;
  uint uVar6;
  int iVar7;
  undefined8 *puVar8;
  
  iVar1 = *(int *)PTR__gBlitBgndRB_0003412c;
  puVar8 = (undefined8 *)
           (iVar1 * (short)param_1 + *(int *)PTR__gBlitBgndBase_00034124 + (param_1 >> 0x10));
  iVar2 = *(int *)PTR__gBlitCompRB_00034130;
  puVar5 = (undefined8 *)
           ((short)param_3 * iVar2 + *(int *)PTR__gBlitCompBase_00034144 + (param_3 >> 0x10));
  uVar6 = (param_2 >> 0x10) - (param_1 >> 0x10);
  iVar3 = (int)(short)param_2 - (int)(short)param_1;
  if (-1 < iVar3) {
    for (iVar7 = 0; uVar4 = uVar6, iVar3 != iVar7; iVar7 = iVar7 + 1) {
      for (; 7 < uVar4; uVar4 = uVar4 - 8) {
        *puVar5 = *puVar8;
        puVar5 = puVar5 + 1;
        puVar8 = puVar8 + 1;
      }
      if (3 < uVar4) {
        *(undefined4 *)puVar5 = *(undefined4 *)puVar8;
        puVar5 = (undefined8 *)((int)puVar5 + 4);
        puVar8 = (undefined8 *)((int)puVar8 + 4);
        uVar4 = uVar4 - 4;
      }
      if (1 < uVar4) {
        *(undefined2 *)puVar5 = *(undefined2 *)puVar8;
        puVar5 = (undefined8 *)((int)puVar5 + 2);
        puVar8 = (undefined8 *)((int)puVar8 + 2);
        uVar4 = uVar4 - 2;
      }
      if (uVar4 != 0) {
        *(undefined1 *)puVar5 = *(undefined1 *)puVar8;
        puVar5 = (undefined8 *)((int)puVar5 + 1);
        puVar8 = (undefined8 *)((int)puVar8 + 1);
      }
      puVar8 = (undefined8 *)((int)puVar8 + (iVar1 - uVar6));
      puVar5 = (undefined8 *)((int)puVar5 + (iVar2 - uVar6));
    }
  }
  return;
}


// ==== _BgndToCompTransparent @ 00015028 ====

void _BgndToCompTransparent(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  uVar1 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gCompGWorld_0003f020);
  uVar2 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gBgndGWorld_0003f01c);
  _CopyBits(uVar2,uVar1,&stack0x00000004,&stack0x0000000c,0x24,0);
  return;
}


// ==== _ScoreToComp @ 0001507f ====

void _ScoreToComp(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  uVar1 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gCompGWorld_0003f020);
  uVar2 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gScoreGWorld_0003f060);
  _CopyBits(uVar2,uVar1,&stack0x00000004,&stack0x0000000c,0,0);
  return;
}


// ==== _CustomScoreToComp @ 000150d6 ====

void _CustomScoreToComp(void)

{
  _ScoreToComp();
  return;
}


// ==== _CompToScore @ 000150df ====

void _CompToScore(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  uVar1 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gScoreGWorld_0003f060);
  uVar2 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gCompGWorld_0003f020);
  _CopyBits(uVar2,uVar1,&stack0x00000004,&stack0x0000000c,0,0);
  return;
}


// ==== _ScoreToCompTransparent @ 00015136 ====

void _ScoreToCompTransparent(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  uVar1 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gCompGWorld_0003f020);
  uVar2 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gScoreGWorld_0003f060);
  _CopyBits(uVar2,uVar1,&stack0x00000004,&stack0x0000000c,0x24,0);
  return;
}


// ==== _SpriteToCompTransparent @ 0001518d ====

void _SpriteToCompTransparent(void)

{
  char cVar1;
  char cVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  char in_stack_00000014;
  
  cVar1 = in_stack_00000014;
  cVar2 = _IsDoubleBuffered();
  if ((cVar2 == '\0') || (cVar1 == '\0')) {
    uVar3 = *(undefined4 *)PTR__gCompGWorld_0003f020;
  }
  else {
    uVar3 = _GetWindowPort(*(undefined4 *)PTR__environment_0003f028);
  }
  uVar3 = _GetPortBitMapForCopyBits(uVar3);
  uVar4 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gSpriteGWorld_0003f024);
  _CopyBits(uVar4,uVar3,&stack0x00000004,&stack0x0000000c,0x24,0);
  return;
}


// ==== _WorldSpriteToComp @ 00015206 ====

void _WorldSpriteToComp(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  uVar1 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gCompGWorld_0003f020);
  uVar2 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gSpriteGWorld_0003f024);
  _CopyBits(uVar2,uVar1,&stack0x00000004,&stack0x0000000c,0,0);
  return;
}


// ==== _BgndToScreen @ 0001525d ====

void _BgndToScreen(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  int iVar3;
  short in_stack_00000014;
  
  iVar3 = (int)in_stack_00000014;
  uVar1 = _GetWindowPort(*(undefined4 *)PTR__environment_0003f028);
  uVar1 = _GetPortBitMapForCopyBits(uVar1);
  uVar2 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gBgndGWorld_0003f01c);
  _CopyBits(uVar2,uVar1,&stack0x00000004,&stack0x0000000c,iVar3,0);
  return;
}


// ==== _CustomBgndToScreen @ 000152be ====

void _CustomBgndToScreen(undefined4 param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4
                        )

{
  _BgndToScreen(param_1,param_2,param_3,param_4,0);
  return;
}


// ==== _CopyBetweenGWorlds @ 000152ee ====

void _CopyBetweenGWorlds(undefined4 param_1,undefined4 param_2)

{
  undefined4 uVar1;
  undefined4 uVar2;
  int iVar3;
  short in_stack_0000001c;
  
  iVar3 = (int)in_stack_0000001c;
  uVar1 = _GetPortBitMapForCopyBits(param_2);
  uVar2 = _GetPortBitMapForCopyBits(param_1);
  _CopyBits(uVar2,uVar1,&stack0x0000000c,&stack0x00000014,iVar3,0);
  return;
}


// ==== _CopyCompToBgnd @ 0001533f ====

void _CopyCompToBgnd(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  int iVar3;
  short in_stack_00000014;
  
  iVar3 = (int)in_stack_00000014;
  uVar1 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gBgndGWorld_0003f01c);
  uVar2 = _GetPortBitMapForCopyBits(*(undefined4 *)PTR__gCompGWorld_0003f020);
  _CopyBits(uVar2,uVar1,&stack0x00000004,&stack0x0000000c,iVar3,0);
  return;
}


// ==== _SpriteToComp @ 00015398 ====

void _SpriteToComp(short param_1,short param_2,short param_3,short param_4,short param_5)

{
  int *piVar1;
  int iVar2;
  short local_24;
  short local_22;
  short local_20;
  short local_1e;
  
  iVar2 = (int)param_1;
  if (PTR__gSetLoaded_00034134[iVar2] == '\0') {
    _LocationErrorInt(0x7d2,9);
  }
  if (0 < param_5) {
    param_5 = param_5 + -1;
  }
  if (*PTR__gUsePlotIcon_0003413c == '\0') {
    _PlotCompiledGraphicToComp
              (*(undefined4 *)
                (*(int *)(PTR__gCSData_00034128 + iVar2 * 4) + 200 +
                param_5 * 4 +
                *(short *)(*(int *)(PTR__gCSData_00034128 + iVar2 * 4) + (short)(param_4 + -1) * 2)
                * 4),(int)param_2,(int)param_3);
  }
  else {
    piVar1 = *(int **)(*(int *)(PTR__gCSData_00034128 + iVar2 * 4) + 200 +
                       *(short *)(*(int *)(PTR__gCSData_00034128 + iVar2 * 4) +
                                 (short)(param_4 + -1) * 2) * 4 + param_5 * 4);
    if (piVar1 == (int *)0x0) {
      _LocationErrorInt(0x7d2,10);
    }
    local_22 = param_2;
    local_24 = param_3;
    local_1e = (*(short *)(*piVar1 + 0x4c) - *(short *)(*piVar1 + 0x48)) + param_2;
    local_20 = (*(short *)(*piVar1 + 0x4a) - *(short *)(*piVar1 + 0x46)) + param_3;
    if (*PTR__gGhostIcons_0003f068 == '\0') {
      _ASWPlotCIcon(&local_24,piVar1);
    }
    else {
      _PlotCIconHandle(&local_24,0,3,piVar1);
    }
  }
  return;
}


// ==== _GetSpriteRect @ 000154c9 ====

void _GetSpriteRect(short param_1,short param_2,short param_3,undefined2 *param_4)

{
  int *piVar1;
  
  if (*PTR__gUsePlotIcon_0003413c == '\0') {
    _StdError("Internal error: trying to get sprite rect for non-cicn sprite.",0);
  }
  piVar1 = *(int **)(*(int *)(PTR__gCSData_00034128 + param_1 * 4) + 200 +
                     *(short *)(*(int *)(PTR__gCSData_00034128 + param_1 * 4) +
                               (short)(param_2 + -1) * 2) * 4 + param_3 * 4);
  if (piVar1 == (int *)0x0) {
    _DebugValues("Cannot get rect for plotting transparent cicn sprite.",(int)param_3);
  }
  param_4[1] = 0;
  *param_4 = 0;
  param_4[3] = *(short *)(*piVar1 + 0x4c) - *(short *)(*piVar1 + 0x48);
  param_4[2] = *(short *)(*piVar1 + 0x4a) - *(short *)(*piVar1 + 0x46);
  return;
}


// ==== _SpriteToBgnd @ 00015567 ====

void _SpriteToBgnd(short param_1,short param_2,short param_3,short param_4,short param_5)

{
  int *piVar1;
  int iVar2;
  short local_24;
  short local_22;
  short local_20;
  short local_1e;
  
  iVar2 = (int)param_1;
  if (PTR__gSetLoaded_00034134[iVar2] == '\0') {
    _LocationErrorInt(0x7d2,9);
  }
  if (0 < param_5) {
    param_5 = param_5 + -1;
  }
  if (*PTR__gUsePlotIcon_0003413c == '\0') {
    _PlotCompiledGraphicToBgnd
              (*(undefined4 *)
                (*(int *)(PTR__gCSData_00034128 + iVar2 * 4) + 200 +
                param_5 * 4 +
                *(short *)(*(int *)(PTR__gCSData_00034128 + iVar2 * 4) + (short)(param_4 + -1) * 2)
                * 4),(int)param_2,(int)param_3);
  }
  else {
    piVar1 = *(int **)(*(int *)(PTR__gCSData_00034128 + iVar2 * 4) + 200 +
                       *(short *)(*(int *)(PTR__gCSData_00034128 + iVar2 * 4) +
                                 (short)(param_4 + -1) * 2) * 4 + param_5 * 4);
    if (piVar1 == (int *)0x0) {
      _LocationErrorInt(0x7d2,10);
    }
    local_22 = param_2;
    local_24 = param_3;
    local_1e = (*(short *)(*piVar1 + 0x4c) - *(short *)(*piVar1 + 0x48)) + param_2;
    local_20 = (*(short *)(*piVar1 + 0x4a) - *(short *)(*piVar1 + 0x46)) + param_3;
    _SetToBgndGWorld();
    _ASWPlotCIcon(&local_24,piVar1);
  }
  return;
}


// ==== _TransSpriteToComp @ 0001566e ====

void _TransSpriteToComp(short param_1,short param_2,short param_3,short param_4,short param_5)

{
  int *piVar1;
  int iVar2;
  short local_24;
  short local_22;
  short local_20;
  short local_1e;
  
  iVar2 = (int)param_1;
  if (PTR__gSetLoaded_00034134[iVar2] == '\0') {
    _LocationErrorInt(0x7d2,9);
  }
  if (0 < param_5) {
    param_5 = param_5 + -1;
  }
  if (*PTR__gUsePlotIcon_0003413c == '\0') {
    _PlotCompiledTransToComp
              (*(undefined4 *)
                (*(int *)(PTR__gCSData_00034128 + iVar2 * 4) + 200 +
                param_5 * 4 +
                *(short *)(*(int *)(PTR__gCSData_00034128 + iVar2 * 4) + (short)(param_4 + -1) * 2)
                * 4),(int)param_2,(int)param_3);
  }
  else {
    piVar1 = *(int **)(*(int *)(PTR__gCSData_00034128 + iVar2 * 4) + 200 +
                       *(short *)(*(int *)(PTR__gCSData_00034128 + iVar2 * 4) +
                                 (short)(param_4 + -1) * 2) * 4 + param_5 * 4);
    if (piVar1 == (int *)0x0) {
      _LocationErrorInt(0x7d2,10);
    }
    local_22 = param_2;
    local_24 = param_3;
    local_1e = (*(short *)(*piVar1 + 0x4c) - *(short *)(*piVar1 + 0x48)) + param_2;
    local_20 = (*(short *)(*piVar1 + 0x4a) - *(short *)(*piVar1 + 0x46)) + param_3;
    _ASWPlotCIconHandle(&local_24,0,1,piVar1);
  }
  return;
}


// ==== _InitCompiledSprites @ 00015784 ====

void _InitCompiledSprites(void)

{
  undefined1 *puVar1;
  short sVar2;
  short sVar3;
  short *psVar4;
  short sVar5;
  undefined4 uVar6;
  undefined *puVar7;
  undefined4 *puVar8;
  int iVar9;
  short sVar10;
  short sVar11;
  undefined2 *puVar12;
  int iVar13;
  int iVar14;
  undefined2 auStackY_100e4 [32724];
  undefined2 auStack_e4 [106];
  
  uVar6 = _GetWorldBgndBase();
  *(undefined4 *)PTR__gBlitBgndBase_00034124 = uVar6;
  uVar6 = _GetWorldBgndRB();
  *(undefined4 *)PTR__gBlitBgndRB_0003412c = uVar6;
  uVar6 = _GetWorldCompBase();
  *(undefined4 *)PTR__gBlitCompBase_00034144 = uVar6;
  uVar6 = _GetWorldCompRB();
  *(undefined4 *)PTR__gBlitCompRB_00034130 = uVar6;
  puVar1 = PTR__gSetLoaded_00034134 + 0x14;
  puVar7 = PTR__gSetLoaded_00034134;
  do {
    *puVar7 = 0;
    puVar7 = puVar7 + 1;
  } while (puVar7 != puVar1);
  puVar8 = (undefined4 *)_GetResource(0x5370494c,0x80);
  if (puVar8 == (undefined4 *)0x0) {
    _ResourceError(0x7d2,1,"SpIL",0x80);
  }
  _MoveHHi(puVar8);
  _HLock(puVar8);
  psVar4 = (short *)*puVar8;
  sVar2 = *psVar4;
  if (0x13 < sVar2) {
    _LocationErrorInt(0x7d2,2);
  }
  for (iVar13 = 0; (short)iVar13 <= sVar2; iVar13 = iVar13 + 1) {
    iVar9 = (int)(short)iVar13;
    iVar14 = (int)psVar4[iVar13 + 1];
    *(int *)(PTR__gSpriteDataIDs_00034138 + iVar9 * 4) = iVar14;
    puVar8 = (undefined4 *)_GetResource(0x53704963,iVar14);
    if (puVar8 == (undefined4 *)0x0) {
      _ResourceError(0x7d2,3,"SpIc",(int)*(short *)(PTR__gSpriteDataIDs_00034138 + iVar9 * 4));
    }
    _MoveHHi(puVar8);
    _HLock(puVar8);
    *(undefined4 *)(PTR__gSpriteDataRes_00034140 + iVar9 * 4) = *puVar8;
  }
  for (sVar5 = 0; sVar5 <= sVar2; sVar5 = sVar5 + 1) {
    iVar13 = (int)sVar5;
    sVar11 = **(short **)(PTR__gSpriteDataRes_00034140 + sVar5 * 4) + 1;
    if (100 < sVar11) {
      _LocationErrorInt(0x7d2,4);
    }
    iVar14 = 0;
    for (sVar10 = 0; sVar10 < sVar11; sVar10 = sVar10 + 1) {
      sVar3 = *(short *)(*(int *)(PTR__gSpriteDataRes_00034140 + sVar5 * 4) +
                        (short)(sVar10 + 1) * 4);
      auStack_e4[sVar10] = (short)iVar14;
      iVar14 = iVar14 + sVar3;
    }
    iVar9 = _NewPtr(iVar14 * 4 + 200);
    *(int *)(PTR__gCSData_00034128 + iVar13 * 4) = iVar9;
    if (iVar9 == 0) {
      _OutOfMemory("InitCompiledSprites, Blit.c");
    }
    puVar12 = *(undefined2 **)(PTR__gCSData_00034128 + iVar13 * 4);
    for (sVar10 = 0; sVar10 < sVar11; sVar10 = sVar10 + 1) {
      *puVar12 = auStack_e4[sVar10];
      puVar12 = puVar12 + 1;
    }
    for (; sVar11 < 100; sVar11 = sVar11 + 1) {
      *puVar12 = 0;
      puVar12 = puVar12 + 1;
    }
    iVar13 = *(int *)(PTR__gCSData_00034128 + iVar13 * 4);
    iVar9 = 0;
    while (sVar11 = (short)iVar9, iVar9 = iVar9 + 1, sVar11 < iVar14) {
      *(undefined4 *)(iVar13 + 0xc4 + iVar9 * 4) = 0;
    }
  }
  return;
}


// ==== _LoadSprites @ 00015a32 ====

void _LoadSprites(short param_1)

{
  short *psVar1;
  short sVar2;
  short sVar3;
  short sVar4;
  short sVar5;
  undefined *puVar6;
  char cVar7;
  undefined4 uVar8;
  int iVar9;
  short sVar10;
  short sVar11;
  undefined4 local_3c;
  undefined4 local_24;
  undefined1 local_20 [2];
  undefined1 local_1e [14];
  
  if (PTR__gSetLoaded_00034134[param_1] != '\0') {
    _LocationErrorInt(0x7d2,5);
  }
  puVar6 = PTR__gSpriteDataRes_00034140;
  iVar9 = (int)param_1;
  sVar2 = **(short **)(PTR__gSpriteDataRes_00034140 + iVar9 * 4);
  for (sVar5 = 0; (short)(sVar5 + 1) <= (short)(sVar2 + 1); sVar5 = sVar5 + 1) {
    psVar1 = (short *)(*(int *)(puVar6 + iVar9 * 4) + (short)(sVar5 + 1) * 4);
    sVar3 = psVar1[-1];
    sVar4 = *psVar1;
    sVar10 = sVar3;
    for (sVar11 = 0; sVar11 < sVar4; sVar11 = sVar11 + 1) {
      if (*PTR__gUsePlotIcon_0003413c == '\0') {
        local_3c = _LoadSpriteDataRes((int)sVar10);
      }
      else {
        cVar7 = _LoadIcon((int)sVar10,local_1e,local_20,&local_24);
        if (cVar7 == '\0') {
          _StdError("Cannot load sprite (cicn).",(int)sVar3 + (int)sVar11);
          _CleanUp();
        }
      }
      uVar8 = local_3c;
      if (*PTR__gUsePlotIcon_0003413c != '\0') {
        uVar8 = local_24;
      }
      *(undefined4 *)
       (*(int *)(PTR__gCSData_00034128 + iVar9 * 4) + 200 +
        *(short *)(*(int *)(PTR__gCSData_00034128 + iVar9 * 4) + sVar5 * 2) * 4 + sVar11 * 4) =
           uVar8;
      sVar10 = sVar10 + 1;
    }
    _UpdateProgress();
  }
  PTR__gSetLoaded_00034134[param_1] = 1;
  return;
}


// ==== _GetBgndRectCount @ 00015b8b ====

int _GetBgndRectCount(void)

{
  return (int)_sBgndRectCount;
}


// ==== _GetBgndRect @ 00015b97 ====

void _GetBgndRect(short param_1,undefined4 *param_2)

{
  undefined4 uVar1;
  
  uVar1 = *(undefined4 *)(&DAT_00034a84 + param_1 * 8);
  *param_2 = *(undefined4 *)(&_sBgndRectList + param_1 * 8);
  param_2[1] = uVar1;
  return;
}


// ==== _RestoreBgndRect @ 00015bb6 ====

void _RestoreBgndRect(uint *param_1,char param_2)

{
  char cVar1;
  uint uVar2;
  short sVar3;
  uint uVar4;
  int iVar5;
  uint uVar6;
  uint uVar7;
  uint local_4c;
  uint local_48;
  ushort local_3e;
  ushort local_3c;
  int local_20;
  
  uVar2 = *param_1;
  uVar7 = param_1[1];
  local_3e = (ushort)uVar2;
  uVar4 = uVar2 >> 0x10;
  local_3c = (ushort)(uVar7 >> 0x10);
  if ((((-1 < (int)uVar7) && (sVar3 = (short)(uVar2 >> 0x10), sVar3 < 0x281)) &&
      ((short)local_3e < 0x1b9)) && (-1 < (short)uVar7)) {
    if ((int)uVar2 < 0) {
      iVar5 = (int)(short)local_3c;
      uVar4 = 0;
      local_20 = 0;
    }
    else if ((short)local_3c < 0x281) {
      iVar5 = (int)(short)local_3c;
      local_20 = (int)sVar3;
    }
    else {
      local_20 = (int)sVar3;
      local_3c = 0x280;
      iVar5 = 0x280;
    }
    if ((short)local_3e < 0) {
      local_3e = 0;
    }
    else if (0x1b8 < (short)uVar7) {
      uVar7 = 0x1b8;
    }
    if ((iVar5 != local_20 && -1 < iVar5 - local_20) &&
       ((int)(short)uVar7 != (int)(short)local_3e && -1 < (int)(short)uVar7 - (int)(short)local_3e))
    {
      local_48 = uVar7 & 0xffff;
      local_4c = (uint)local_3e;
      uVar6 = uVar4 << 0x10;
      local_4c = local_4c | uVar6;
      uVar2 = (uint)local_3c << 0x10;
      local_48 = local_48 | uVar2;
      cVar1 = _UsingQDPlotting();
      if (cVar1 == '\0') {
        _CustomBgndToComp(local_3e | uVar6,uVar7 & 0xffff | uVar2,local_4c,local_48);
      }
      else {
        cVar1 = _IsDoubleBuffered();
        if ((cVar1 == '\0') || (param_2 != '\0')) {
          _BgndToComp((uint)local_3e | uVar4 << 0x10,uVar7 & 0xffff | (uint)local_3c << 0x10,
                      local_4c,local_48);
        }
        else {
          _BgndToScreen(local_3e | uVar6,uVar7 & 0xffff | uVar2,local_4c,local_48,0);
        }
      }
    }
  }
  return;
}


// ==== _ResetNumBgndRects @ 00015d95 ====

void _ResetNumBgndRects(void)

{
  _sBgndRectCount = 0;
  return;
}


// ==== _AdjustRect32Bit @ 00015da3 ====

void _AdjustRect32Bit(int param_1)

{
  *(ushort *)(param_1 + 2) = *(ushort *)(param_1 + 2) & 0xfffc;
  *(ushort *)(param_1 + 6) = *(short *)(param_1 + 6) + 3U & 0xfffc;
  return;
}


// ==== _RestoreBgnd @ 00015dbe ====

void _RestoreBgnd(undefined1 param_1)

{
  short sVar1;
  undefined4 local_24;
  undefined4 local_20;
  
  sVar1 = 0;
  while( true ) {
    if (_sBgndRectCount <= sVar1) break;
    local_20 = *(undefined4 *)(&DAT_00034a84 + sVar1 * 8);
    local_24 = *(undefined4 *)(&_sBgndRectList + sVar1 * 8);
    _RestoreBgndRect(&local_24,param_1);
    sVar1 = sVar1 + 1;
  }
  return;
}


// ==== _AddRectToBgnd @ 00015e09 ====

void _AddRectToBgnd(undefined4 *param_1)

{
  ushort uVar1;
  ushort uVar2;
  char cVar3;
  short sVar4;
  uint uVar5;
  short sVar6;
  ushort uVar7;
  char cVar8;
  short sVar9;
  ushort uVar10;
  int iVar11;
  short sVar12;
  int local_c8;
  uint local_c4;
  short local_bc;
  short local_ac;
  ushort local_9c;
  ushort local_8c;
  undefined4 local_34;
  undefined4 local_30;
  int local_28;
  int local_20;
  
  local_bc = (short)param_1[1];
  local_ac = (short)*param_1;
  local_9c = (ushort)((uint)param_1[1] >> 0x10);
  local_8c = (ushort)((uint)*param_1 >> 0x10);
  cVar3 = _UsingQDPlotting();
  if (cVar3 != '\0') {
    local_8c = local_8c & 0xfffc;
    local_9c = local_9c + 3 & 0xfffc;
  }
  if ((short)local_8c < 0) {
    local_8c = 0;
    cVar3 = '\0';
  }
  else {
    cVar3 = (char)((short)local_8c / 0x28);
  }
  if ((short)local_9c < 0x281) {
    local_28 = (int)(short)local_9c;
  }
  else {
    local_9c = 0x280;
    local_28 = 0x280;
  }
  if (local_ac < 0) {
    local_ac = 0;
    cVar8 = '\0';
  }
  else {
    cVar8 = (char)(local_ac / 0x28);
  }
  if (local_bc < 0x1b9) {
    iVar11 = (int)local_bc;
  }
  else {
    local_bc = 0x1b8;
    iVar11 = 0x1b8;
  }
  sVar6 = (short)((local_28 + -1) / 0x28);
  sVar12 = (short)((iVar11 + -1) / 0x28);
  sVar4 = 0xf;
  if (sVar6 < 0x10) {
    sVar4 = sVar6;
  }
  sVar6 = 10;
  if (sVar12 < 0xb) {
    sVar6 = sVar12;
  }
  for (sVar12 = 0; sVar12 < (char)(((char)sVar4 - cVar3) + '\x01'); sVar12 = sVar12 + 1) {
    for (sVar9 = 0; sVar9 < (char)(((char)sVar6 - cVar8) + '\x01'); sVar9 = sVar9 + 1) {
      _CheckBlock((int)(char)(cVar3 + (char)sVar12),(int)(char)(cVar8 + (char)sVar9));
    }
  }
  iVar11 = (int)_sBgndRectCount;
  if (iVar11 < _sNumBgndRects + -1) {
    *(short *)(&DAT_00034a84 + iVar11 * 8) = local_bc;
    *(short *)(&_sBgndRectList + iVar11 * 8) = local_ac;
    *(ushort *)(&DAT_00034a86 + iVar11 * 8) = local_9c;
    *(ushort *)(&DAT_00034a82 + iVar11 * 8) = local_8c;
    _sBgndRectCount = _sBgndRectCount + 1;
  }
  else {
    local_c8 = 0;
    local_c4 = 0xffffffff;
    for (local_20 = 0; (short)local_20 < _sBgndRectCount; local_20 = local_20 + 1) {
      iVar11 = (int)(short)local_20;
      uVar1 = *(ushort *)(&DAT_00034a82 + iVar11 * 8);
      uVar7 = local_8c;
      if ((short)uVar1 < (short)local_8c) {
        uVar7 = uVar1;
      }
      sVar6 = *(short *)(&_sBgndRectList + iVar11 * 8);
      sVar12 = local_ac;
      if (sVar6 <= local_ac) {
        sVar12 = sVar6;
      }
      uVar2 = *(ushort *)(&DAT_00034a86 + iVar11 * 8);
      uVar10 = local_9c;
      if ((short)local_9c <= (short)uVar2) {
        uVar10 = uVar2;
      }
      sVar4 = *(short *)(&DAT_00034a84 + iVar11 * 8);
      sVar9 = local_bc;
      if (local_bc <= sVar4) {
        sVar9 = sVar4;
      }
      uVar5 = ((int)sVar9 - (int)sVar12) * ((int)(short)uVar10 - (int)(short)uVar7) -
              ((int)(short)uVar2 - (int)(short)uVar1) * ((int)sVar4 - (int)sVar6);
      if (uVar5 < local_c4) {
        local_30 = CONCAT22(uVar10,sVar9);
        local_34 = CONCAT22(uVar7,sVar12);
        local_c8 = local_20;
        local_c4 = uVar5;
      }
    }
    *(undefined4 *)(&_sBgndRectList + local_c8 * 8) = local_34;
    *(undefined4 *)(&DAT_00034a84 + local_c8 * 8) = local_30;
  }
  return;
}


// ==== _Bubbles_CreateRandomLUT @ 000161f6 ====

void _Bubbles_CreateRandomLUT(void)

{
  undefined1 uVar1;
  undefined2 uVar2;
  undefined2 *puVar3;
  undefined1 *puVar4;
  
  puVar3 = &_gBubbles_RandXLocTable;
  do {
    uVar2 = _GetRandomFast(0x28,0x1e0);
    *puVar3 = uVar2;
    puVar3 = puVar3 + 1;
  } while (puVar3 != (undefined2 *)&_gBubbles_RandDriftTable);
  _gBubbles_RandXLocIndex = 0;
  puVar4 = &_gBubbles_RandDriftTable;
  do {
    uVar1 = _GetRandomFast(0,4);
    *puVar4 = uVar1;
    puVar4 = puVar4 + 1;
  } while (puVar4 != &_gBubbles_RandVerticalTable);
  _gBubbles_RandDriftIndex = 0;
  puVar3 = (undefined2 *)&_gBubbles_RandVerticalTable;
  do {
    uVar1 = _GetRandomFast(2,5);
    *(undefined1 *)puVar3 = uVar1;
    puVar3 = (undefined2 *)((int)puVar3 + 1);
  } while (puVar3 != &_gBubbles_RandDelayTable);
  _gBubbles_RandVerticalIndex = 0;
  puVar3 = &_gBubbles_RandDelayTable;
  do {
    uVar2 = _GetRandomFast(0x19,0x5a);
    *puVar3 = uVar2;
    puVar3 = puVar3 + 1;
  } while (puVar3 != (undefined2 *)&_gBubbles_RandGroupsTable);
  _gBubbles_RandDelayIndex = 0;
  puVar4 = &_gBubbles_RandGroupsTable;
  do {
    uVar2 = _GetRandomFast(0,0xe);
    switch(uVar2) {
    case 0:
    case 1:
      *puVar4 = 0;
      break;
    case 2:
    case 3:
      *puVar4 = 1;
      break;
    case 4:
    case 5:
      *puVar4 = 2;
      break;
    case 6:
      *puVar4 = 3;
      break;
    case 7:
    case 8:
      *puVar4 = 4;
      break;
    default:
      *puVar4 = 5;
      break;
    case 0xb:
      *puVar4 = 6;
      break;
    case 0xc:
    case 0xd:
      *puVar4 = 7;
      break;
    case 0xe:
      *puVar4 = 8;
    }
    puVar4 = puVar4 + 1;
  } while (puVar4 != &DAT_00034f1b);
  _gBubbles_RandGroupsIndex = 0;
  return;
}


// ==== _Bubbles_ResetBubble @ 0001632a ====

void _Bubbles_ResetBubble(char param_1)

{
  (&_gBubbles)[param_1 * 0x26] = 0;
  _gBubbles_NumActive = _gBubbles_NumActive + -1;
  return;
}


// ==== _Bubbles_New @ 00016349 ====

void _Bubbles_New(short param_1,short param_2,char param_3,short param_4)

{
  char cVar1;
  char cVar2;
  undefined2 uVar3;
  int iVar4;
  short sVar5;
  short sVar6;
  char *pcVar7;
  int iVar8;
  
  if (_gBubbles_NumActive == 8) {
    return;
  }
  uVar3 = _GetFrameCounter();
  iVar4 = 0;
  pcVar7 = &_gBubbles;
  iVar8 = 0;
  while (*pcVar7 != '\0') {
    iVar4 = iVar4 + 1;
    iVar8 = iVar8 + 0x26;
    pcVar7 = pcVar7 + 0x26;
    if (iVar4 == 8) {
      _DebugValues("NewBubble() - Shouldn\'t have got this far.",0xffffffff);
      _CleanUp();
      return;
    }
  }
  (&_gBubbles)[iVar8] = 1;
  *(undefined2 *)((int)&DAT_00034d42 + iVar8) = uVar3;
  *(undefined2 *)((int)&DAT_00034d44 + iVar8) = uVar3;
  uVar3 = _GetRandomFast(5,9);
  *(undefined2 *)((int)&DAT_00034d46 + iVar8) = uVar3;
  (&DAT_00034d48)[iVar8] = param_3;
  (&DAT_00034d61)[iVar8] = 0;
  (&DAT_00034d60)[iVar8] = 1;
  if (param_3 == '\x01') {
    *(undefined2 *)((int)&DAT_00034d5c + iVar8) = 0x2e;
    *(undefined2 *)((int)&DAT_00034d5e + iVar8) = 1;
    sVar6 = 0x17;
    sVar5 = 0x17;
  }
  else if (param_3 < '\x02') {
    if (param_3 != '\0') {
      return;
    }
    *(undefined2 *)((int)&DAT_00034d5c + iVar8) = 0x2d;
    *(undefined2 *)((int)&DAT_00034d5e + iVar8) = 1;
    sVar6 = 0x12;
    sVar5 = 0x12;
  }
  else if (param_3 == '\x02') {
    *(undefined2 *)((int)&DAT_00034d5c + iVar8) = 0x2f;
    *(undefined2 *)((int)&DAT_00034d5e + iVar8) = 1;
    sVar6 = 0x1d;
    sVar5 = 0x1d;
  }
  else {
    if (param_3 != '\x03') {
      return;
    }
    *(undefined2 *)((int)&DAT_00034d5c + iVar8) = 0x30;
    *(undefined2 *)((int)&DAT_00034d5e + iVar8) = 1;
    sVar6 = 0x2b;
    sVar5 = 0x2b;
  }
  *(short *)((int)&DAT_00034d4a + iVar8 + 2) = param_1;
  *(short *)((int)&DAT_00034d4a + iVar8) = param_2;
  *(short *)((int)&DAT_00034d4e + iVar8 + 2) = param_1 + sVar6;
  *(short *)((int)&DAT_00034d4e + iVar8) = param_2 + sVar5;
  *(undefined4 *)((int)&DAT_00034d52 + iVar8) = *(undefined4 *)((int)&DAT_00034d4a + iVar8);
  *(undefined4 *)((int)&DAT_00034d56 + iVar8) = *(undefined4 *)((int)&DAT_00034d4e + iVar8);
  (&DAT_00034d5a)[iVar8] = 0;
  cVar1 = (&_gBubbles_RandVerticalTable)[_gBubbles_RandVerticalIndex];
  (&DAT_00034d5b)[iVar8] = cVar1;
  cVar2 = (&DAT_00034d48)[iVar8];
  if (cVar2 == '\0') {
    if (cVar1 < '\x04') goto LAB_000164fa;
  }
  else {
    if (cVar2 == '\x01') {
      if ('\x04' < cVar1) {
        (&DAT_00034d5b)[iVar8] = 4;
      }
      goto LAB_000164fa;
    }
    if (((cVar2 != '\x02') && (cVar2 != '\x03')) || ('\x02' < cVar1)) goto LAB_000164fa;
  }
  (&DAT_00034d5b)[iVar8] = 3;
LAB_000164fa:
  sVar6 = _gBubbles_RandVerticalIndex + 1;
  _gBubbles_RandVerticalIndex = 0;
  if (sVar6 < 0x15) {
    _gBubbles_RandVerticalIndex = sVar6;
  }
  *(short *)((int)&DAT_00034d64 + iVar8) = param_4;
  if (param_4 < 1) {
    (&DAT_00034d62)[iVar8] = 0;
    (&DAT_00034d60)[iVar8] = 1;
  }
  else {
    (&DAT_00034d62)[iVar8] = 1;
    (&DAT_00034d60)[iVar8] = 0;
  }
  _gBubbles_NumActive = _gBubbles_NumActive + 1;
  return;
}


// ==== _Bubbles_NewGroup @ 0001657e ====

void _Bubbles_NewGroup(short param_1,short param_2,undefined1 param_3)

{
  char cVar1;
  int iVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  
  cVar1 = _GetBooleanPref(0x36);
  if (cVar1 == '\0') {
    return;
  }
  switch(param_3) {
  case 0:
    uVar3 = 0;
    break;
  case 1:
    uVar3 = 1;
    break;
  case 2:
    uVar3 = 2;
    break;
  case 3:
    uVar3 = 3;
    break;
  case 4:
    _Bubbles_New((int)(short)(param_1 + 8),(int)param_2,0,0);
    uVar3 = 0;
    goto LAB_00016688;
  case 5:
    _Bubbles_New((int)param_1,(int)param_2,0,0);
    uVar3 = 2;
LAB_00016688:
    param_2 = param_2 + 8;
LAB_0001668b:
    uVar4 = 0;
    param_1 = param_1 + 0x14;
LAB_00016697:
    iVar2 = (int)param_1;
LAB_0001669b:
    _Bubbles_New(iVar2,(int)param_2,uVar3,uVar4);
    goto LAB_000166b5;
  case 6:
    _Bubbles_New((int)param_1,(int)param_2,3,0);
    uVar3 = 2;
    param_2 = param_2 + 0x10;
    goto LAB_0001668b;
  case 7:
    _Bubbles_New((int)(short)(param_1 + 8),(int)param_2,0,0);
    _Bubbles_New((int)(short)(param_1 + 0x14),(int)(short)(param_2 + 8),1,0);
    _Bubbles_New((int)(short)(param_1 + 0x14),(int)(short)(param_2 + 0x29),0,0);
    goto LAB_000166b5;
  case 8:
    _Bubbles_New((int)(short)(param_1 + 8),(int)param_2,1,0);
    _Bubbles_New((int)(short)(param_1 + 8),(int)(short)(param_2 + 0x10),3,0);
    _Bubbles_New((int)(short)(param_1 + 0x14),(int)(short)(param_2 + 0x29),1,0);
    _Bubbles_New((int)(short)(param_1 + 1),(int)(short)(param_2 + 4),0,0);
    goto LAB_000166b5;
  case 9:
    _Bubbles_New((int)(short)(param_1 + -8),(int)(short)(param_2 + 0xc),0,0);
    _Bubbles_New((int)(short)(param_1 + -0xc),(int)(short)(param_2 + 10),1,2);
    uVar4 = 4;
    uVar3 = 2;
    param_2 = param_2 + 8;
    param_1 = param_1 + -0x10;
    goto LAB_00016697;
  case 10:
    iVar2 = (int)param_1;
    _Bubbles_New(iVar2,(int)(short)(param_2 + 0xc),0,0);
    _Bubbles_New(iVar2,(int)(short)(param_2 + 10),1,2);
    uVar4 = 4;
    uVar3 = 2;
    param_2 = param_2 + 8;
    goto LAB_0001669b;
  case 0xb:
    _Bubbles_New((int)(short)(param_1 + 8),(int)(short)(param_2 + 8),2,0);
    _Bubbles_New((int)(short)(param_1 + 10),(int)(short)(param_2 + 10),1,2);
    _Bubbles_New((int)(short)(param_1 + 10),(int)(short)(param_2 + 10),1,3);
    _Bubbles_New((int)(short)(param_1 + 0xc),(int)(short)(param_2 + 0xc),0,4);
    _Bubbles_New((int)(short)(param_1 + 0xc),(int)(short)(param_2 + 0xc),0,6);
LAB_000166b5:
    _PlayMySnd();
    return;
  default:
    goto switchD_000165b7_default;
  }
  _Bubbles_New((int)param_1,(int)param_2,uVar3,0);
switchD_000165b7_default:
  return;
}


// ==== _Bubbles @ 000169e2 ====

void _Bubbles(void)

{
  short sVar1;
  undefined *puVar2;
  char cVar3;
  ushort uVar4;
  int iVar5;
  short sVar6;
  int iVar7;
  undefined4 uVar8;
  
  cVar3 = _GetBooleanPref(0x36);
  if (cVar3 == '\0') {
    return;
  }
  uVar4 = _GetFrameCounter();
  puVar2 = PTR__hero_0003f014;
  if ((uint)uVar4 <= (uint)_gBubbles_TimeLastGroupLaunched + (uint)_gBubbles_DelayTilNextGroup) {
    return;
  }
  if (((*(short *)(PTR__hero_0003f014 + 2) == 2) && (PTR__hero_0003f014[0x35] != '\0')) &&
     (*(ushort *)(PTR__hero_0003f014 + 0xc) + 0x8c < (uint)uVar4)) {
    if (*(short *)(PTR__hero_0003f014 + 0x26) == 3) {
      uVar8 = 9;
      sVar6 = *(short *)(PTR__hero_0003f014 + 0x14);
      sVar1 = *(short *)(PTR__hero_0003f014 + 0x16);
    }
    else {
      if (*(short *)(PTR__hero_0003f014 + 0x26) != 4) goto LAB_00016a88;
      uVar8 = 10;
      sVar6 = *(short *)(PTR__hero_0003f014 + 0x14);
      sVar1 = *(short *)(PTR__hero_0003f014 + 0x1a);
    }
    _Bubbles_NewGroup((int)sVar1,(int)sVar6,uVar8);
    *(ushort *)(puVar2 + 0xc) = uVar4;
  }
  else {
LAB_00016a88:
    iVar5 = (int)_gBubbles_RandXLocIndex;
    _gBubbles_RandXLocIndex = _gBubbles_RandXLocIndex + 1;
    if (0x20 < _gBubbles_RandXLocIndex) {
      _gBubbles_RandXLocIndex = 0;
    }
    iVar7 = (int)_gBubbles_RandGroupsIndex;
    sVar6 = _gBubbles_RandGroupsIndex + 1;
    _gBubbles_RandGroupsIndex = 0;
    if (sVar6 < 0x15) {
      _gBubbles_RandGroupsIndex = sVar6;
    }
    _Bubbles_NewGroup((int)(short)(&_gBubbles_RandXLocTable)[iVar5],0x181,
                      (int)(char)(&_gBubbles_RandGroupsTable)[iVar7]);
  }
  iVar5 = (int)_gBubbles_RandDelayIndex;
  sVar6 = _gBubbles_RandDelayIndex + 1;
  _gBubbles_RandDelayIndex = 0;
  if (sVar6 < 0xd) {
    _gBubbles_RandDelayIndex = sVar6;
  }
  _gBubbles_TimeLastGroupLaunched = uVar4;
  _gBubbles_DelayTilNextGroup = (&_gBubbles_RandDelayTable)[iVar5];
  return;
}


// ==== _Bubbles_Process @ 00016b1a ====

void _Bubbles_Process(void)

{
  short *psVar1;
  short *psVar2;
  char cVar3;
  char cVar4;
  ushort uVar5;
  uint uVar6;
  int iVar7;
  char cVar8;
  short sVar9;
  short sVar10;
  char *pcVar11;
  int local_24;
  
  if (_gBubbles_NumActive != 0) {
    local_24 = 0;
    pcVar11 = &_gBubbles;
    do {
      uVar5 = _GetFrameCounter();
      if (*pcVar11 != '\0') {
        if (pcVar11[0x22] != '\0') {
          uVar6 = _GetFrameCounter();
          if ((int)((int)*(short *)(pcVar11 + 0x24) + (uint)*(ushort *)(pcVar11 + 2)) <
              (int)(uVar6 & 0xffff)) {
            pcVar11[0x22] = '\0';
            pcVar11[0x20] = '\x01';
          }
          goto LAB_00016cc1;
        }
        if ((int)((uint)*(ushort *)(pcVar11 + 4) + (int)*(short *)(pcVar11 + 6)) < (int)(uint)uVar5)
        {
          *(ushort *)(pcVar11 + 4) = uVar5;
          sVar9 = 1;
          if ((short)(*(short *)(pcVar11 + 0x1e) + 1) < 4) {
            sVar9 = *(short *)(pcVar11 + 0x1e) + 1;
          }
          *(short *)(pcVar11 + 0x1e) = sVar9;
        }
        *(short *)(pcVar11 + 10) = *(short *)(pcVar11 + 10) - (short)pcVar11[0x1b];
        *(short *)(pcVar11 + 0xe) = *(short *)(pcVar11 + 0xe) - (short)pcVar11[0x1b];
        cVar3 = (&_gBubbles_SnakingTable)[pcVar11[0x1a]];
        cVar8 = pcVar11[0x1a] + '\x01';
        cVar4 = '\0';
        if (cVar8 < '\x13') {
          cVar4 = cVar8;
        }
        pcVar11[0x1a] = cVar4;
        psVar1 = (short *)(pcVar11 + 0xc);
        *(short *)(pcVar11 + 0xc) = *(short *)(pcVar11 + 0xc) + (short)cVar3;
        psVar2 = (short *)(pcVar11 + 0x10);
        *(short *)(pcVar11 + 0x10) = *(short *)(pcVar11 + 0x10) + (short)cVar3;
        iVar7 = (int)_gBubbles_RandDriftIndex;
        sVar9 = _gBubbles_RandDriftIndex + 1;
        _gBubbles_RandDriftIndex = 0;
        if (sVar9 < 0x15) {
          _gBubbles_RandDriftIndex = sVar9;
        }
        switch((&_gBubbles_RandDriftTable)[iVar7]) {
        case 0:
          sVar9 = *psVar1;
          sVar10 = *psVar2;
          goto LAB_00016c64;
        case 1:
          sVar9 = *psVar1 + -1;
          *psVar1 = sVar9;
          sVar10 = *psVar2 + -1;
          break;
        case 2:
          sVar9 = *psVar1 + -2;
          *psVar1 = sVar9;
          sVar10 = *psVar2 + -2;
          break;
        case 3:
          sVar9 = *psVar1 + 1;
          *psVar1 = sVar9;
          sVar10 = *psVar2 + 1;
          break;
        case 4:
          sVar9 = *psVar1 + 2;
          *psVar1 = sVar9;
          sVar10 = *psVar2 + 2;
          break;
        default:
          goto switchD_00016c10_default;
        }
        *psVar2 = sVar10;
LAB_00016c64:
        if (*(short *)(pcVar11 + 0xe) < 0) {
          pcVar11[0x21] = '\x01';
        }
        if (sVar9 < 5) {
          *psVar1 = 5;
          *psVar2 = (char)((char)sVar10 - (char)sVar9) + 5;
        }
        else if (0x27b < sVar10) {
          *psVar2 = 0x27b;
          *psVar1 = 0x27b - (char)((char)sVar10 - (char)sVar9);
        }
        _AddRectToBgnd((int)&DAT_00034d52 + local_24 * 0x26);
      }
LAB_00016cc1:
      local_24 = local_24 + 1;
      pcVar11 = pcVar11 + 0x26;
    } while (local_24 != 8);
  }
switchD_00016c10_default:
  return;
}


// ==== _Bubbles_Init @ 00016cda ====

void _Bubbles_Init(void)

{
  undefined2 *puVar1;
  
  puVar1 = (undefined2 *)&_gBubbles;
  do {
    *(undefined1 *)puVar1 = 0;
    _gBubbles_NumActive = _gBubbles_NumActive + -1;
    puVar1 = puVar1 + 0x13;
  } while (puVar1 != &_gBubbles_NumActive);
  _Bubbles_CreateRandomLUT();
  _gBubbles_NumActive = 0;
  _gBubbles_TimeLastGroupLaunched = 0;
  _gBubbles_DelayTilNextGroup = 0x1e;
  return;
}


// ==== _Bubbles_DrawToComp @ 00016d25 ====

void _Bubbles_DrawToComp(void)

{
  undefined4 *puVar1;
  undefined4 *puVar2;
  int iVar3;
  undefined4 *puVar4;
  undefined4 *local_34;
  undefined4 *local_30;
  undefined4 local_24 [5];
  
  if (_gBubbles_NumActive != 0) {
    iVar3 = 0;
    puVar2 = &DAT_00034d52;
    local_30 = &DAT_00034d52;
    local_34 = &DAT_00034d52;
    puVar4 = &DAT_00034d4a;
    do {
      if (*(char *)((int)puVar2 + -0x12) != '\0') {
        puVar1 = local_30;
        if (*(char *)((int)puVar2 + 0xe) != '\0') {
          if ((((-1 < *(short *)((int)puVar2 + -6)) && (*(short *)((int)puVar2 + -2) < 0x281)) &&
              (-1 < *(short *)(puVar2 + -2))) && (*(short *)(puVar2 + -1) < 0x1b9)) {
            _SpriteToComp(0,(int)*(short *)((int)puVar2 + -6),(int)*(short *)(puVar2 + -2),
                          (int)*(short *)((int)puVar2 + 10),(int)*(short *)(puVar2 + 3),1);
          }
          _UnionRect(local_34,puVar4,local_24);
          puVar1 = local_24;
        }
        _AddRectToScreen(puVar1);
        if (*(char *)((int)puVar2 + 0xf) == '\0') {
          *puVar2 = puVar2[-2];
          puVar2[1] = puVar2[-1];
        }
        else {
          *(undefined1 *)((int)puVar2 + -0x12) = 0;
          _gBubbles_NumActive = _gBubbles_NumActive + -1;
        }
      }
      iVar3 = iVar3 + 1;
      puVar4 = (undefined4 *)((int)puVar4 + 0x26);
      local_34 = (undefined4 *)((int)local_34 + 0x26);
      local_30 = (undefined4 *)((int)local_30 + 0x26);
      puVar2 = (undefined4 *)((int)puVar2 + 0x26);
    } while (iVar3 != 8);
  }
  return;
}


// ==== _AdvanceFrameCounter @ 00016e21 ====

void _AdvanceFrameCounter(void)

{
  _gFrameCounter = _gFrameCounter + 1;
  return;
}


// ==== _EscapeFromGame @ 00016e2e ====

void _EscapeFromGame(void)

{
  *PTR__gPlayGame_0003416c = 0;
  return;
}


// ==== _TimerAction @ 00016e3b ====

void _TimerAction(void)

{
  _gTimerFired = 1;
  return;
}


// ==== _RemoveCarbonTimer @ 00016e47 ====

void _RemoveCarbonTimer(void)

{
  if (_gCarbonTimerInstalled != '\0') {
    _gCarbonTimerInstalled = '\0';
    _RemoveEventLoopTimer(*(undefined4 *)PTR__gCarbonTimer_00034174);
    _DisposeEventLoopTimerUPP(*(undefined4 *)PTR__gTimerUPP_00034168);
  }
  return;
}


// ==== _ResetFrameCounter @ 00016e7d ====

void _ResetFrameCounter(void)

{
  _gFrameCounter = 0;
  return;
}


// ==== _GetCurrLevelNum @ 00016e8b ====

int _GetCurrLevelNum(void)

{
  short sVar1;
  
  sVar1 = _GetLevel();
  return (int)sVar1;
}


// ==== _InGameResume @ 00016e99 ====

void _InGameResume(void)

{
  int iVar1;
  
  _ScreenResume();
  _CheckEnvironment();
  _ResumeKeys();
  _SetMyCCursor(200);
  if (PTR__environment_0003f028[0x26] == '\0') {
    _ShowWindow(*(undefined4 *)PTR__environment_0003f028);
  }
  iVar1 = _RT3_IsRegistered();
  if ((iVar1 != 0) && (_gRegWhenSuspended == '\0')) {
    _DebugValues("Thank you for registering! Please re-open Bubble Trouble to complete the process."
                 ,0);
    _CleanUp();
    return;
  }
  return;
}


// ==== _InGameSuspend @ 00016efd ====

void _InGameSuspend(void)

{
  _SuspendKeys();
  _gRegWhenSuspended = _RT3_IsRegistered();
  _ScreenSuspend();
  return;
}


// ==== _SaveScreenBeforePause @ 00016f18 ====

void _SaveScreenBeforePause(void)

{
  _ScreenToComp(*(undefined4 *)(PTR__environment_0003f028 + 0x12),
                *(undefined4 *)(PTR__environment_0003f028 + 0x16),
                *(undefined4 *)(PTR__environment_0003f028 + 0x12),
                *(undefined4 *)(PTR__environment_0003f028 + 0x16));
  return;
}


// ==== _RestoreScreenAfterPause @ 00016f45 ====

void _RestoreScreenAfterPause(void)

{
  _CompToScreen(*(undefined4 *)(PTR__environment_0003f028 + 0x12),
                *(undefined4 *)(PTR__environment_0003f028 + 0x16),
                *(undefined4 *)(PTR__environment_0003f028 + 0x12),
                *(undefined4 *)(PTR__environment_0003f028 + 0x16));
  return;
}


// ==== _DrawFPS @ 00016f72 ====

void _DrawFPS(short param_1)

{
  undefined4 uVar1;
  undefined1 local_214 [256];
  char local_114 [4];
  char local_110 [4];
  undefined1 local_10c [248];
  short local_14;
  short local_12;
  short local_10;
  short local_e;
  
  local_114 = (char  [4])s_FPS___00031068._0_4_;
  local_110 = (char  [4])s_FPS___00031068._4_4_;
  _memset(local_10c,0,0xf8);
  _SetToScreen();
  local_12 = *(short *)(PTR__environment_0003f028 + 0xc) + 0x1b8;
  local_14 = *(short *)(PTR__environment_0003f028 + 0xe) + -0x19;
  local_e = *(short *)(PTR__environment_0003f028 + 0xc) + 0x1ea;
  local_10 = *(short *)(PTR__environment_0003f028 + 0xe) + -9;
  _PaintRect(&local_14);
  _ForeColor(0x1e);
  _MoveTo((int)(short)(local_12 + 4),(int)(short)(local_10 + -4));
  _DrawString(local_114);
  _NumToString((int)param_1,local_214);
  if (param_1 < 0x1e) {
    uVar1 = 0xcd;
  }
  else {
    uVar1 = 0x1e;
  }
  _ForeColor(uVar1);
  _DrawString(local_214);
  _ForeColor(0x21);
  return;
}


// ==== _GetFrameCounter @ 00017078 ====

undefined2 _GetFrameCounter(void)

{
  return _gFrameCounter;
}


// ==== _SetPlayRecordCount @ 00017084 ====

void _SetPlayRecordCount(undefined4 param_1)

{
  _gRecording = param_1;
  return;
}


// ==== _RecordingCountOK @ 00017091 ====

bool _RecordingCountOK(void)

{
  return *(int *)PTR__gRecordingCounter_00034198 < 2000;
}


// ==== _GetUpRecording @ 000170a7 ====

undefined1 _GetUpRecording(void)

{
  return (&DAT_00034f4c)[*(int *)PTR__gRecordingCounter_00034198];
}


// ==== _GetDownRecording @ 000170ba ====

undefined1 _GetDownRecording(void)

{
  return (&DAT_0003571c)[*(int *)PTR__gRecordingCounter_00034198];
}


// ==== _GetLeftRecording @ 000170cd ====

undefined1 _GetLeftRecording(void)

{
  return (&DAT_00035eec)[*(int *)PTR__gRecordingCounter_00034198];
}


// ==== _GetRightRecording @ 000170e0 ====

undefined1 _GetRightRecording(void)

{
  return (&DAT_000366bc)[*(int *)PTR__gRecordingCounter_00034198];
}


// ==== _GetPushRecording @ 000170f3 ====

undefined1 _GetPushRecording(void)

{
  return (&DAT_00036e8c)[*(int *)PTR__gRecordingCounter_00034198];
}


// ==== _SetUpRecording @ 00017106 ====

void _SetUpRecording(undefined1 param_1)

{
  (&DAT_00034f4c)[*(int *)PTR__gRecordingCounter_00034198] = param_1;
  return;
}


// ==== _SetDownRecording @ 0001711b ====

void _SetDownRecording(undefined1 param_1)

{
  (&DAT_0003571c)[*(int *)PTR__gRecordingCounter_00034198] = param_1;
  return;
}


// ==== _SetLeftRecording @ 00017130 ====

void _SetLeftRecording(undefined1 param_1)

{
  (&DAT_00035eec)[*(int *)PTR__gRecordingCounter_00034198] = param_1;
  return;
}


// ==== _SetRightRecording @ 00017145 ====

void _SetRightRecording(undefined1 param_1)

{
  (&DAT_000366bc)[*(int *)PTR__gRecordingCounter_00034198] = param_1;
  return;
}


// ==== _SetPushRecording @ 0001715a ====

void _SetPushRecording(undefined1 param_1)

{
  (&DAT_00036e8c)[*(int *)PTR__gRecordingCounter_00034198] = param_1;
  return;
}


// ==== _CheckNumRecordings @ 0001716f ====

void _CheckNumRecordings(void)

{
  int iVar1;
  short sVar2;
  
  sVar2 = 0;
  while( true ) {
    iVar1 = _GetResource(0x46494c4d,(int)(short)(sVar2 + 1));
    if (iVar1 == 0) break;
    _ReleaseResource(iVar1);
    sVar2 = sVar2 + 1;
  }
  _gNumFilmsAvailable = sVar2;
  return;
}


// ==== _IsGameDemoPlaying @ 000171ab ====

bool _IsGameDemoPlaying(void)

{
  return *PTR__gGameMode_00034180 == '\x01';
}


// ==== _GetFilmCounter @ 000171be ====

int _GetFilmCounter(void)

{
  return (int)_gFilmCounter;
}


// ==== _SetCurrLevelNum @ 000171ca ====

void _SetCurrLevelNum(void)

{
  _SetLevel();
  return;
}


// ==== _StartTimeCheck @ 000171da ====

void _StartTimeCheck(void)

{
  *(undefined2 *)PTR__gNumTimeChecks_00034190 = 0xffff;
  _Microseconds(PTR__gStartMicroTickCount_00034184);
  return;
}


// ==== _UpdateTimeCheck @ 000171f9 ====

void _UpdateTimeCheck(undefined4 param_1)

{
  short sVar1;
  undefined *puVar2;
  
  puVar2 = PTR__gNumTimeChecks_00034190;
  sVar1 = *(short *)PTR__gNumTimeChecks_00034190;
  *(ushort *)PTR__gNumTimeChecks_00034190 = sVar1 + 1U;
  _Microseconds(PTR__gMicroTickCounts_00034170 + (uint)(ushort)(sVar1 + 1U) * 8);
  _CopyCStringToPascal(param_1,PTR__gTimingMessages_0003418c + (uint)*(ushort *)puVar2 * 0x100);
  return;
}


// ==== _DisplayOneTime @ 00017244 ====

void _DisplayOneTime(undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  undefined1 local_20c [256];
  undefined1 local_10c [256];
  
  _NumToString(param_2,local_10c);
  _NumToString(param_3,local_20c);
  _ParamText(param_1,local_10c,local_20c,&DAT_000336a0);
  _NoteAlert(0xd0,0);
  return;
}


// ==== _FinishTimeCheck @ 000172b2 ====

void _FinishTimeCheck(void)

{
  int iVar1;
  int iVar2;
  undefined *puVar3;
  char cVar4;
  int iVar5;
  uint uVar6;
  ushort uVar7;
  undefined *puVar8;
  
  puVar8 = PTR__gEndMicroTickCount_00034194;
  _Microseconds(PTR__gEndMicroTickCount_00034194);
  puVar3 = PTR__gTimingMessages_0003418c;
  iVar1 = *(int *)puVar8;
  iVar2 = *(int *)PTR__gStartMicroTickCount_00034184;
  uVar7 = 0;
  do {
    if (*(ushort *)PTR__gNumTimeChecks_00034190 < uVar7) {
      return;
    }
    if (uVar7 == 0) {
      iVar5 = *(int *)PTR__gMicroTickCounts_00034170 - *(int *)PTR__gStartMicroTickCount_00034184;
      cVar4 = _IsOptionKeyDown();
      puVar8 = puVar3;
      if (cVar4 == '\0') {
LAB_00017343:
        _DisplayOneTime(puVar8,iVar5,iVar1 - iVar2);
      }
    }
    else {
      uVar6 = (uint)uVar7;
      iVar5 = *(int *)(PTR__gMicroTickCounts_00034170 + uVar6 * 8) -
              *(int *)(PTR__gMicroTickCounts_00034170 + uVar6 * 8 + -8);
      cVar4 = _IsOptionKeyDown();
      if (cVar4 == '\0') {
        puVar8 = PTR__gTimingMessages_0003418c + uVar6 * 0x100;
        goto LAB_00017343;
      }
    }
    uVar7 = uVar7 + 1;
  } while( true );
}


// ==== _NewLevel @ 0001735f ====

void _NewLevel(void)

{
  undefined1 uVar1;
  char cVar2;
  short sVar3;
  undefined4 uVar4;
  
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #1");
  }
  _gIsEndOfLevel = 0;
  _gFrameCounter = 0;
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #2");
  }
  _NextLevel();
  sVar3 = _GetLevel();
  _LoadLevel((int)sVar3);
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #3");
  }
  uVar1 = _RT3_IsRegistered();
  PTR__gBogusRegCheck1_0003419c[3] = uVar1;
  uVar4 = _RT3_GetLicenseCopies();
  *(undefined4 *)PTR__gBogusRegCopies_00034178 = uVar4;
  _ResetBlocks();
  _ResetHurtBlockList();
  _TimeBonus_Reset();
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #4");
  }
  cVar2 = _LoadMaze((int)*(short *)PTR__level_0003f010);
  if (cVar2 == '\0') {
    _CleanUp();
  }
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #5.1");
  }
  _InitHero();
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #5.2");
  }
  _PositionJewels();
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #5.3");
  }
  _Splats_Init();
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #5.4");
  }
  _Bubbles_Init();
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #5.5");
  }
  _Balloons_Init();
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #6");
  }
  _InitStars();
  _InitPoints();
  _InitEnemies();
  _InitEnemyAI();
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #7");
  }
  _Bonus_Init();
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #7.1");
  }
  _DrawMaze();
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #7.2");
  }
  _RequestDrawReserveHero(0);
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #8");
  }
  _SetToScreen();
  _WipeScreen(0xc);
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #9");
  }
  _DrawReserveInfo();
  _DrawScore(1);
  _TimeBonus_Draw(1);
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #10");
  }
  _Multiplier_Draw(1);
  _EXTRA_Draw(1);
  _Sounds_InitDelayedSounds();
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #11");
  }
  _ResetNotices();
  if (*PTR__gGameMode_00034180 == '\x01') {
    uVar4 = 4;
  }
  else {
    uVar4 = 6;
  }
  _PrepareNotice(uVar4);
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #12");
  }
  if (*PTR__gGameMode_00034180 != '\x01') {
    if (_doneOnce_74900 == '\0') {
      _Utils_Log("    New game flag #12.1");
    }
    _LoadMusic(1);
  }
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #13");
  }
  if (*PTR__gGameMode_00034180 != '\x01') {
    _PlayMySnd(2,0x14,0);
  }
  if (_doneOnce_74900 == '\0') {
    _Utils_Log("    New game flag #14");
  }
  _doneOnce_74900 = 1;
  return;
}


// ==== _PauseGame @ 0001767b ====

void _PauseGame(char param_1,char param_2)

{
  bool bVar1;
  undefined *puVar2;
  undefined *puVar3;
  char cVar4;
  short sVar5;
  undefined4 uVar6;
  int iVar7;
  uint uVar8;
  char *pcVar9;
  int iVar10;
  uint unaff_ESI;
  undefined4 uVar11;
  bool local_61;
  float local_5c;
  float local_58;
  float local_54;
  float local_50;
  float local_4c;
  float local_48;
  float local_44;
  float local_40;
  undefined1 local_3c [8];
  undefined1 local_34 [9];
  char local_2b [7];
  char local_24 [4];
  undefined4 local_20 [4];
  
  bVar1 = param_2 != '\0';
  if (bVar1) {
    _InGameSuspend();
  }
  local_61 = !bVar1 && param_2 == '\0';
  _DisableAboutMenu();
  builtin_strncpy(local_2b,"OOGLE",6);
  _FlushEvents(0x3e,0);
  _SetToScreen();
  _ST_HaltSound(0);
  _TurnISpOff();
  cVar4 = _MusicPlaying();
  if (cVar4 != '\0') {
    _PauseMusic();
  }
  _PlayMySnd(0x16,0x1e,0);
  _SetMyCCursor(200);
  _CGAssociateMouseAndMouseCursorPosition(1);
  _SetMouse(*(undefined4 *)PTR__gSavedMousePosition_0003417c);
  _ShowMyCursor();
  if (PTR__environment_0003f028[0x26] == '\0') {
    _ShowGameMenuBar();
  }
  _EnableMenuCommand(0,0x70726566);
  _EnableMenuCommand(0,0x46756c6c);
  uVar6 = _GetEventDispatcherTarget();
  bVar1 = true;
  do {
    if (*PTR__gDidToggleFullscreen_0003f040 != '\0') {
      *PTR__gDidToggleFullscreen_0003f040 = 0;
      iVar7 = _TickCount();
      unaff_ESI = iVar7 + 10;
    }
    if ((unaff_ESI != 0) && (uVar8 = _TickCount(), unaff_ESI < uVar8)) {
      _UpdateScreen();
      _FlushIfNecessary();
      unaff_ESI = 0;
    }
    puVar2 = PTR__gDoPrefsNow_0003f078;
    if (*PTR__gDoPrefsNow_0003f078 != '\0') {
      _PrefsDialog();
      *puVar2 = 0;
    }
    if (*PTR__gFinished_0003f074 != '\0') {
      _DoRegReminder();
      _StopMusic();
      _CleanUp();
    }
    iVar7 = _ReceiveNextEvent(0,0,0x11111111,0x3fa11111,1,local_20);
    puVar2 = PTR__gEvent_0003f080;
    if (iVar7 != 0) {
      *(undefined2 *)PTR__gEvent_0003f080 = 0;
    }
    _ConvertEventRefToEventRecord(local_20[0],puVar2);
    iVar7 = _GetEventClass(local_20[0]);
    puVar3 = PTR__gEvent_0003f080;
    if (iVar7 == 0x6170706c) {
      iVar7 = _GetEventKind(local_20[0]);
      if (iVar7 == 1) {
        cVar4 = _PauseKey();
        if (cVar4 == '\0') {
          _InGameResume();
          bVar1 = false;
        }
        local_61 = true;
      }
      else if (iVar7 == 2) {
        _InGameSuspend();
        local_61 = false;
      }
      else {
        _SetMyCCursor(200);
      }
    }
    else {
      switch(*(undefined2 *)puVar2) {
      case 0:
        cVar4 = _PauseKey();
        if ((cVar4 == '\0') && (local_61)) {
          bVar1 = false;
        }
        break;
      case 1:
        _HandleMSMouse(0);
        break;
      case 3:
        cVar4 = PTR__gEvent_0003f080[2];
        if ((PTR__gEvent_0003f080[0xf] & 1) == 0) {
          pcVar9 = local_2b + 1;
          do {
            pcVar9[-1] = *pcVar9;
            pcVar9 = pcVar9 + 1;
          } while (local_2b + 6 != pcVar9);
          local_2b[4] = cVar4;
          iVar7 = (local_2b[0] + 0x19a) * (local_2b[1] + 0x6a) * (local_2b[2] + 0x14d) + 3 +
                  (local_2b[3] + 0x118) * (cVar4 + 0x230);
          if (iVar7 == 0x227742c) {
            _PlayMySnd(0,0x1e,0);
            _gShowFPS = _gShowFPS == '\0';
LAB_00017ec8:
            _SetHacked(1);
          }
          else {
            if (iVar7 == 0x20ec7c5) {
              _PlayMySnd(3,0x1e,0);
              _ResetScore(0);
              goto LAB_00017ec8;
            }
            if (iVar7 != 0x242795e) {
              if (iVar7 == 0x22a51cf) {
                _PlayMySnd(0x2f,0x1e,0);
                _gDaddyMode = 1;
                goto LAB_00017def;
              }
              if (iVar7 == 0x211e290) {
                _PlayMySnd(0,0x1e,0);
                _NewStarGroup((char)PTR__hero_0003f014[0x28] * 0x28,
                              (char)PTR__hero_0003f014[0x34] * 0x28,10);
              }
              else {
                if (iVar7 == 0x239b951) {
                  uVar11 = 0x2e;
                  goto LAB_00017cfb;
                }
                if (iVar7 != 0x249007e) {
                  if (iVar7 == 0x20df815) {
                    sVar5 = 3;
                    do {
                      _PlayMySnd(0,0x1e,0);
                      _Delay(0x14,local_24);
                      sVar5 = sVar5 + -1;
                    } while (sVar5 != 0);
                    goto LAB_00017bdb;
                  }
                  if (iVar7 != 0x224fc15) goto LAB_00017a4c;
                  _PlayMySnd(0x1f,0x14,0);
                  _PlayMySnd(4,0x14,0);
                  _PlayMySnd(0xf,10,0);
                  _RegenerateBlocks();
                  goto LAB_00017def;
                }
                _PlayMySnd(0x29,0x1e,0);
                _gLimitFrames = _gLimitFrames == '\0';
              }
              goto LAB_00017ec8;
            }
            iVar10 = 0;
            do {
              _PlayMySnd(iVar10,0x1e,0);
              _Delay(10,local_24);
              iVar10 = iVar10 + 1;
            } while (iVar10 != 0x30);
LAB_00017a4c:
            if (iVar7 == 0x21d95f1) {
              _PlayMySnd(0,0x1e,0);
              _gEndOfLevelTime = _gFrameCounter;
              _gIsEndOfLevel = 1;
              _PlayMySnd(0x23,0x1e,0);
              goto LAB_00017def;
            }
            if (iVar7 == 0x21dd0a7) {
              _PlayMySnd(0x29,0x14,0);
              _gGhostIcons = _gGhostIcons == '\0';
              goto LAB_00017ec8;
            }
            if (iVar7 == 0x22badb8) {
              _PlayMySnd(0x2f,0x1e,0);
              _Delay(0x19,local_24);
              _PlayMySnd(0x2f,0x1e,0);
              _Delay(0x19,local_24);
              uVar11 = 0x2f;
LAB_00017cfb:
              _PlayMySnd(uVar11,0x1e,0);
              goto LAB_00017ec8;
            }
            if (iVar7 == 0x252bb8b) {
              _PlayMySnd(0,0x1e,0);
              _AddHero(1,1);
LAB_00017def:
              *PTR__gPlayerIsCheating_0003f070 = 1;
              goto LAB_00017ec8;
            }
            if (iVar7 == 0x21ba771) {
              _PlayMySnd(0,0x1e,0);
              _AddToScore(9000,0);
              goto LAB_00017def;
            }
LAB_00017bdb:
            if (iVar7 == 0x23ba91e) {
              _PlayMySnd(0,0x1e,0);
              _SetHeroInvisibility(1);
              goto LAB_00017def;
            }
            if (iVar7 == 0x20a59aa) {
              _PlayMySnd(0,0x1e,0);
              _Balloons_CaptureAllEnemies();
              goto LAB_00017def;
            }
            if (iVar7 == 0x26e29e4) {
              _PlayMySnd(0,0x1e,0);
              *PTR__gPlayerIsCheating_0003f070 = 1;
              uVar11 = 1;
LAB_00017ec3:
              _EXTRA_Change(uVar11,0);
              goto LAB_00017ec8;
            }
            if (iVar7 == 0x26e4547) {
              _PlayMySnd(0,0x1e,0);
              *PTR__gPlayerIsCheating_0003f070 = 1;
              uVar11 = 2;
              goto LAB_00017ec3;
            }
            if (iVar7 == 0x26e3f83) {
              _PlayMySnd(0,0x1e,0);
              *PTR__gPlayerIsCheating_0003f070 = 1;
              uVar11 = 3;
              goto LAB_00017ec3;
            }
            if (iVar7 == 0x26e3ca1) {
              _PlayMySnd(0,0x1e,0);
              *PTR__gPlayerIsCheating_0003f070 = 1;
              uVar11 = 4;
              goto LAB_00017ec3;
            }
            if (iVar7 == 0x26e2420) {
              _PlayMySnd(0,0x1e,0);
              *PTR__gPlayerIsCheating_0003f070 = 1;
              uVar11 = 5;
              goto LAB_00017ec3;
            }
            if (iVar7 == 0x232858f) {
              _PlayMySnd(0,0x1e,0);
              *PTR__gPlayerIsCheating_0003f070 = 1;
              uVar11 = 2;
LAB_00017fab:
              _Multiplier_Change(uVar11);
              goto LAB_00017ec8;
            }
            if (iVar7 == 0x23286f2) {
              _PlayMySnd(0,0x1e,0);
              *PTR__gPlayerIsCheating_0003f070 = 1;
              uVar11 = 3;
              goto LAB_00017fab;
            }
            if (iVar7 != 0x5792ca4) goto LAB_00017ec8;
          }
          if (iVar7 == 0x2328855) {
            _PlayMySnd(0,0x1e,0);
            *PTR__gPlayerIsCheating_0003f070 = 1;
            uVar11 = 4;
          }
          else {
            if (iVar7 != 0x23289b8) break;
            _PlayMySnd(0,0x1e,0);
            *PTR__gPlayerIsCheating_0003f070 = 1;
            uVar11 = 5;
          }
          _Multiplier_Change(uVar11);
        }
        break;
      case 6:
        _BeginUpdate(*(undefined4 *)(PTR__gEvent_0003f080 + 2));
        if ((local_61) && (*(int *)(puVar3 + 2) == *(int *)PTR__environment_0003f028)) {
          _CheckEnvironment();
          _UpdateScreen();
        }
        _EndUpdate(*(undefined4 *)(PTR__gEvent_0003f080 + 2));
        break;
      case 0x17:
        _AEProcessAppleEvent(PTR__gEvent_0003f080);
        if (*PTR__gFinished_0003f074 != '\0') {
          _SaveGamePrefs();
          _DoRegReminder();
          _StopMusic();
          _CleanUp();
        }
      }
    }
    _SendEventToEventTarget(local_20[0],uVar6);
    _ReleaseEvent(local_20[0]);
    if (!bVar1) {
      _ResumeMusic();
      _TurnISpOn();
      _EnableAboutMenu();
      cVar4 = _IsOSX();
      if (cVar4 != '\0') {
        local_24[0] = '\0';
        sVar5 = _GetCurrentProcess(local_34);
        if (sVar5 != 0) {
          _StdError("Cannot get current process during game resume.",(int)sVar5);
        }
        while (local_24[0] == '\0') {
          sVar5 = _GetFrontProcess(local_3c);
          if (sVar5 != 0) {
            _StdError("Cannot get front process during game resume.",(int)sVar5);
          }
          _SameProcess(local_3c,local_34,local_24);
        }
      }
      _DisableMenuCommand(0,0x70726566);
      _DisableMenuCommand(0,0x46756c6c);
      uVar6 = _CGMainDisplayID();
      _CGDisplayBounds(&local_5c,uVar6);
      local_4c = local_5c;
      local_48 = local_58;
      local_44 = local_54;
      local_40 = local_50;
      _GetMouse(PTR__gSavedMousePosition_0003417c);
      cVar4 = _Button();
      if (cVar4 == '\0') {
        _CGWarpMouseCursorPosition
                  (local_44 * FLOAT_00033fb4 + local_4c,FLOAT_00033fb4 * local_40 + local_48);
      }
      _CGAssociateMouseAndMouseCursorPosition(0);
      _HideMyCursor();
      puVar2 = PTR__environment_0003f028;
      if (PTR__environment_0003f028[0x26] == '\0') {
        _HideGameMenuBar();
        _ShowGameMenuBar();
        _HideGameMenuBar();
      }
      _CheckEnvironment();
      cVar4 = _IsDoubleBuffered();
      if (cVar4 != '\0') {
        _CompToScreen(*(undefined4 *)(puVar2 + 0x12),*(undefined4 *)(puVar2 + 0x16),
                      *(undefined4 *)(puVar2 + 0x12),*(undefined4 *)(puVar2 + 0x16));
      }
      _PrepareNotice((int)param_1);
      _UpdateScreen();
      return;
    }
  } while( true );
}


// ==== _PlayGame @ 00018247 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _PlayGame(undefined4 param_1,char param_2)

{
  bool bVar1;
  bool bVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  ushort uVar6;
  undefined *puVar7;
  char cVar8;
  undefined1 uVar9;
  undefined4 uVar10;
  int iVar11;
  undefined4 *puVar12;
  int iVar13;
  short sVar14;
  uint uVar15;
  char *pcVar16;
  undefined **ppuVar17;
  undefined8 uVar18;
  undefined *local_140;
  int local_f0;
  byte local_ea;
  char local_e9;
  int local_e8;
  short local_e2;
  float local_dc;
  undefined4 local_d8;
  float local_d4;
  undefined4 local_d0;
  uint auStack_cc [2];
  float local_c4;
  uint local_c0;
  float local_bc;
  undefined4 local_b8;
  undefined4 local_b4;
  undefined4 local_b0;
  undefined4 local_ac;
  undefined4 local_a8;
  undefined4 local_20 [4];
  
  ppuVar17 = (undefined **)&stack0xfffffec4;
  local_140 = (undefined *)0x18274;
  local_e8 = _TickCount();
  if (_doneOnce_74711 == '\0') {
    local_140 = (undefined *)0x1828f;
    _Utils_Log();
  }
  _gLimitFrames = '\x01';
  _gDaddyMode = '\0';
  _gGhostIcons = 0;
  local_140 = (undefined *)0x182b8;
  _FlushEvents();
  local_140 = (undefined *)0x182c4;
  _SetHacked();
  if (_doneOnce_74711 == '\0') {
    local_140 = (undefined *)0x182d9;
    _Utils_Log();
  }
  local_140 = (undefined *)0x182de;
  _ResetLevelHackCheck();
  local_140 = (undefined *)0x182e3;
  _CopyResetLevelHC();
  if (_doneOnce_74711 == '\0') {
    local_140 = (undefined *)0x182f8;
    _Utils_Log();
  }
  local_140 = (undefined *)0x182fd;
  cVar8 = _IsOSX();
  if (cVar8 != '\0') {
    local_140 = (undefined *)0x18306;
    _GetMainEventLoop();
    local_140 = (undefined *)0x18314;
    uVar10 = _NewEventLoopTimerUPP();
    *(undefined4 *)PTR__gTimerUPP_00034168 = uVar10;
    local_140 = (undefined *)0x1835a;
    _InstallEventLoopTimer();
    _gCarbonTimerInstalled = '\x01';
    if (_doneOnce_74711 == '\0') {
      local_140 = (undefined *)0x18376;
      _Utils_Log();
    }
  }
  *PTR__gGameMode_00034180 = param_2;
  if (param_2 == '\x01') {
    if (_doneOnce_74711 == '\0') {
      local_140 = (undefined *)0x1839d;
      _Utils_Log();
    }
    local_140 = (undefined *)0x183b8;
    _gRecordHandle = (undefined4 *)_GetResource();
    if (_gRecordHandle != (undefined4 *)0x0) {
      local_140 = (undefined *)0x183c9;
      iVar11 = _GetHandleSize();
      if (iVar11 != 0x271c) {
        local_140 = (undefined *)0x183e5;
        _SetHandleSize();
      }
      local_140 = (undefined *)0x183f2;
      _HLock();
      local_140 = (undefined *)0x18411;
      _memmove(&_gRecording,(void *)*_gRecordHandle,0x271c);
      local_140 = (undefined *)0x1841e;
      _HUnlock();
      local_140 = (undefined *)0x1842b;
      _HPurge();
    }
    sVar14 = _gFilmCounter + 1;
    _gFilmCounter = 0;
    if (sVar14 != _gNumFilmsAvailable) {
      _gFilmCounter = sVar14;
    }
    *(undefined4 *)PTR__gRecordingCounter_00034198 = 0;
  }
  else {
    if (_doneOnce_74711 == '\0') {
      local_140 = (undefined *)0x1846e;
      _Utils_Log();
    }
    local_140 = (undefined *)0x18473;
    _TickCount();
  }
  local_140 = (undefined *)0x1847b;
  _SetQDGlobalsRandomSeed();
  if (*PTR__gGameMode_00034180 == '\x02') {
    if (_doneOnce_74711 == '\0') {
      local_140 = (undefined *)0x1849a;
      _Utils_Log();
    }
    *(undefined4 *)PTR__gRecordingCounter_00034198 = 0;
    local_140 = (undefined *)0x184aa;
    _TickCount();
    local_140 = (undefined *)0x184b2;
    _SetQDGlobalsRandomSeed();
    local_140 = (undefined *)0x184b7;
    DAT_00034f44 = _GetQDGlobalsRandomSeed();
    _gRecording = 0;
    local_140 = (undefined *)0x184cb;
    sVar14 = _GetLevel();
    _DAT_00034f48 = (int)sVar14;
  }
  else if (_doneOnce_74711 == '\0') {
    local_140 = (undefined *)0x1850d;
    _Utils_Log();
  }
  *PTR__gPlayGame_0003416c = 1;
  local_140 = (undefined *)0x18522;
  _SetLevel();
  local_140 = (undefined *)0x18527;
  uVar9 = _RT3_IsRegistered();
  puVar4 = PTR__gBogusRegCheck1_0003419c;
  PTR__gBogusRegCheck1_0003419c[2] = uVar9;
  local_140 = (undefined *)0x18535;
  uVar9 = _RT3_IsRegistered();
  puVar4[4] = uVar9;
  local_140 = (undefined *)0x1853d;
  _SetToScreen();
  if (_doneOnce_74711 == '\0') {
    local_140 = (undefined *)0x18552;
    _Utils_Log();
  }
  local_140 = (undefined *)0x18557;
  _ResetHeroLives();
  if (_doneOnce_74711 == '\0') {
    local_140 = (undefined *)0x1856c;
    _Utils_Log();
  }
  local_140 = (undefined *)0x18578;
  _ResetScore();
  if (_doneOnce_74711 == '\0') {
    local_140 = (undefined *)0x1858d;
    _Utils_Log();
  }
  local_140 = (undefined *)0x18599;
  _Multiplier_Reset();
  if (_doneOnce_74711 == '\0') {
    local_140 = (undefined *)0x185ae;
    _Utils_Log();
  }
  local_140 = (undefined *)0x185ba;
  _EXTRA_Reset();
  if (_doneOnce_74711 == '\0') {
    local_140 = (undefined *)0x185cf;
    _Utils_Log();
  }
  local_140 = (undefined *)0x185d4;
  _NewLevel();
  if (_doneOnce_74711 == '\0') {
    local_140 = (undefined *)0x185e9;
    _Utils_Log();
  }
  puVar4 = PTR__gGameMode_00034180;
  if (*PTR__gGameMode_00034180 != '\x01') {
    local_140 = (undefined *)0x185f9;
    _TurnISpOn();
  }
  if (_doneOnce_74711 == '\0') {
    local_140 = (undefined *)0x1860e;
    _Utils_Log();
  }
  puVar3 = PTR__gSavedMousePosition_0003417c;
  _doneOnce_74711 = 1;
  local_140 = (undefined *)0x18623;
  _GetMouse();
  if (*puVar4 != '\x01') {
    local_140 = (undefined *)0x18631;
    _CGMainDisplayID();
    local_140 = (undefined *)0x18643;
    _CGDisplayBounds();
    ppuVar17 = &local_140;
    local_c4 = local_dc;
    local_c0 = local_d8;
    local_bc = local_d4;
    local_b8 = local_d0;
    local_140 = puVar3;
    _GetMouse();
    local_140 = (undefined *)(local_bc * FLOAT_00033fb4 + local_c4);
    _CGWarpMouseCursorPosition();
    local_140 = (undefined *)0x0;
    _CGAssociateMouseAndMouseCursorPosition();
    _HideMyCursor();
  }
  ppuVar17[-1] = (undefined *)0x186e8;
  iVar11 = _GetEventDispatcherTarget();
  ppuVar17[1] = (undefined *)0x70726566;
  *ppuVar17 = (undefined *)0x0;
  ppuVar17[-1] = (undefined *)0x18702;
  _DisableMenuCommand();
  ppuVar17[1] = (undefined *)0x46756c6c;
  *ppuVar17 = (undefined *)0x0;
  ppuVar17[-1] = (undefined *)0x18716;
  _DisableMenuCommand();
  puVar7 = PTR__hero_0003f014;
  puVar3 = PTR__gPlayGame_0003416c;
  local_f0 = 0;
  bVar1 = true;
  bVar2 = false;
  local_ea = 0;
  local_e2 = 0x1e;
  do {
    if (*puVar3 == '\0') {
      ppuVar17[1] = (undefined *)0x70726566;
      *ppuVar17 = (undefined *)0x0;
      ppuVar17[-1] = (undefined *)0x1919b;
      _EnableMenuCommand();
      ppuVar17[1] = (undefined *)0x46756c6c;
      *ppuVar17 = (undefined *)0x0;
      ppuVar17[-1] = (undefined *)0x191af;
      _EnableMenuCommand();
      puVar4 = PTR__gGameMode_00034180;
      if (*PTR__gGameMode_00034180 != '\x01') {
        *ppuVar17 = (undefined *)*(undefined4 *)PTR__gSavedMousePosition_0003417c;
        ppuVar17[-1] = (undefined *)0x191c9;
        _SetMouse();
        ppuVar17[-1] = (undefined *)0x191ce;
        _ShowMyCursor();
        *ppuVar17 = (undefined *)0x1;
        ppuVar17[-1] = (undefined *)0x191da;
        _CGAssociateMouseAndMouseCursorPosition();
      }
      if (*puVar4 == '\x02') {
        ppuVar17[-1] = (undefined *)0x191e8;
        sVar14 = _GetLevel();
        ppuVar17[1] = (undefined *)(int)sVar14;
        *ppuVar17 = (undefined *)0x46494c4d;
        ppuVar17[-1] = (undefined *)0x191fb;
        iVar11 = _Get1Resource();
        if (iVar11 != 0) {
          *ppuVar17 = (undefined *)iVar11;
          ppuVar17[-1] = (undefined *)0x19209;
          _RemoveResource();
          *ppuVar17 = (undefined *)iVar11;
          ppuVar17[-1] = (undefined *)0x19211;
          _DisposeHandle();
        }
        *ppuVar17 = (undefined *)0x271c;
        ppuVar17[-1] = (undefined *)0x1921d;
        puVar12 = (undefined4 *)_NewHandle();
        ppuVar17[2] = (undefined *)0x271c;
        ppuVar17[1] = (undefined *)&_gRecording;
        *ppuVar17 = (undefined *)*puVar12;
        ppuVar17[-1] = (undefined *)0x19239;
        _memmove(*ppuVar17,ppuVar17[1],(size_t)ppuVar17[2]);
        ppuVar17[3] = "\x0eFILM RECORDING";
        ppuVar17[2] = (undefined *)(int)sVar14;
        ppuVar17[1] = (undefined *)0x46494c4d;
        *ppuVar17 = (undefined *)puVar12;
        ppuVar17[-1] = (undefined *)0x19255;
        _AddResource();
        *ppuVar17 = (undefined *)puVar12;
        ppuVar17[-1] = (undefined *)0x1925d;
        _WriteResource();
        *ppuVar17 = (undefined *)puVar12;
        ppuVar17[-1] = (undefined *)0x19265;
        _ReleaseResource();
        *ppuVar17 = (undefined *)0x1;
        ppuVar17[-1] = (undefined *)0x19271;
        _SysBeep();
      }
      if (*PTR__gGameMode_00034180 != '\x01') {
        ppuVar17[-1] = (undefined *)0x19280;
        _UnloadMusic();
        *ppuVar17 = (undefined *)0x0;
        ppuVar17[-1] = (undefined *)0x1928c;
        _ST_HaltSound();
        ppuVar17[-1] = (undefined *)0x19291;
        _StopMusicWithoutFade();
      }
      _gGhostIcons = 0;
      if (_gCarbonTimerInstalled != '\0') {
        ppuVar17[-1] = (undefined *)0x192a6;
        _RemoveCarbonTimer();
      }
      ppuVar17[1] = (undefined *)0x0;
      *ppuVar17 = (undefined *)0x3e;
      ppuVar17[-1] = (undefined *)0x192ba;
      _FlushEvents();
      ppuVar17[-1] = (undefined *)0x192bf;
      _TurnISpOff();
      ppuVar17[-1] = (undefined *)0x192c4;
      cVar8 = _IsOSX();
      if (cVar8 != '\0') {
        iVar11 = *(int *)(PTR__environment_0003f028 + 0x16);
        ppuVar17[2] = (undefined *)*(int *)(PTR__environment_0003f028 + 0x12);
        ppuVar17[3] = (undefined *)iVar11;
        iVar11 = *(int *)(PTR__environment_0003f028 + 0x16);
        *ppuVar17 = (undefined *)*(undefined4 *)(PTR__environment_0003f028 + 0x12);
        ppuVar17[1] = (undefined *)iVar11;
        ppuVar17[-1] = (undefined *)0x192ed;
        _ScreenToComp();
      }
      ppuVar17[2] = (undefined *)0x0;
      ppuVar17[1] = (undefined *)0x1e;
      *ppuVar17 = (undefined *)0x1b;
      ppuVar17[-1] = (undefined *)0x19309;
      _PlayMySnd();
      return;
    }
    _gTimerFired = '\0';
    _gFrameCounter = _gFrameCounter + 1;
    ppuVar17[-1] = (undefined *)0x18787;
    _ResetNumBgndRects();
    ppuVar17[-1] = (undefined *)0x1878c;
    _ResetNumScrnRects();
    puVar5 = PTR__hero_0003f014;
    uVar6 = _gFrameCounter;
    sVar14 = *(short *)(PTR__hero_0003f014 + 2);
    if (sVar14 == 2) {
      if (*(ushort *)(PTR__hero_0003f014 + 4) + 10 < (uint)_gFrameCounter) {
        ppuVar17[-1] = (undefined *)0x187e4;
        _CheckNewEnemies();
      }
    }
    else if (sVar14 < 3) {
      if (sVar14 == 1) {
        ppuVar17[-1] = (undefined *)0x187fd;
        sVar14 = _GetLives();
        if (sVar14 < 1) {
          iVar13 = 0x5f;
        }
        else {
          iVar13 = (int)(short)((-(ushort)!bVar1 & 0xfff6) + 0x46);
        }
        if ((int)((uint)*(ushort *)(puVar7 + 4) + iVar13) < (int)(uint)_gFrameCounter) {
          ppuVar17[-1] = (undefined *)0x1882c;
          sVar14 = _GetLives();
          if (sVar14 < 1) {
            *puVar3 = 0;
          }
          else {
            PTR__gMaze_0003f054[(int)(char)puVar7[0x28] + (char)puVar7[0x34] * 0x10] = 0;
            *(undefined2 *)(puVar7 + 2) = 2;
            *(ushort *)(puVar7 + 4) = _gFrameCounter;
            puVar7[0x4a] = 1;
            *ppuVar17 = (undefined *)0x0;
            ppuVar17[-1] = (undefined *)0x1886b;
            _SetHeroInvisibility();
            *ppuVar17 = (undefined *)0x5;
            ppuVar17[-1] = (undefined *)0x18877;
            _SetHeroSpeed();
            if (*puVar4 != '\x01') {
              *ppuVar17 = (undefined *)0x0;
              ppuVar17[-1] = (undefined *)0x1888e;
              _PrepareNotice();
            }
            *ppuVar17 = (undefined *)0x0;
            ppuVar17[-1] = (undefined *)0x1889a;
            _RequestDrawReserveHero();
            ppuVar17[-1] = (undefined *)0x1889f;
            _StartMusic();
            ppuVar17[2] = (undefined *)0x0;
            ppuVar17[1] = (undefined *)((char)puVar7[0x34] * 0x28);
            *ppuVar17 = (undefined *)((char)puVar7[0x28] * 0x28);
            ppuVar17[-1] = (undefined *)0x188cd;
            _NewStarGroup();
            if (*puVar4 != '\x01') {
              ppuVar17[2] = (undefined *)0x0;
              ppuVar17[1] = (undefined *)0x14;
              *ppuVar17 = (undefined *)0x8;
              ppuVar17[-1] = (undefined *)0x188f4;
              _PlayMySnd();
            }
            ppuVar17[2] = (undefined *)0x0;
            ppuVar17[1] = (undefined *)0xa;
            *ppuVar17 = (undefined *)0x1b;
            ppuVar17[-1] = (undefined *)0x18910;
            _PlayMySnd();
            ppuVar17[-1] = (undefined *)0x18915;
            _Blocks_DeactivateRubberBlocks();
          }
          bVar1 = false;
        }
      }
    }
    else if (sVar14 == 3) {
      if (*(ushort *)(PTR__hero_0003f014 + 4) + 0x1e < (uint)_gFrameCounter) {
        *(undefined2 *)(PTR__hero_0003f014 + 2) = 4;
        *(ushort *)(puVar5 + 4) = uVar6;
        ppuVar17[-1] = (undefined *)0x1895a;
        _SubtractLife();
        *(undefined2 *)(puVar5 + 0x3e) = 1;
        *(undefined2 *)(puVar5 + 0x42) = 0;
        *(undefined2 *)(puVar5 + 0x48) = 0;
        ppuVar17[-1] = (undefined *)0x18971;
        _MakeAllEnemiesDisappear();
        ppuVar17[-1] = (undefined *)0x18976;
        _StopMusicWithoutFade();
        ppuVar17[2] = (undefined *)0x0;
        ppuVar17[1] = (undefined *)0x14;
        *ppuVar17 = (undefined *)0x22;
        ppuVar17[-1] = (undefined *)0x18992;
        _PlayMySnd();
        *ppuVar17 = (undefined *)0x1;
        ppuVar17[-1] = (undefined *)0x1899e;
        _RequestDrawReserveHero();
        ppuVar17[-1] = (undefined *)0x189a3;
        _EraseOuch();
      }
    }
    else if ((sVar14 == 4) && (*(ushort *)(PTR__hero_0003f014 + 4) + 0x41 < (uint)_gFrameCounter)) {
      if (*puVar4 == '\x02') {
        *puVar3 = 0;
      }
      else if (*puVar4 == '\x01') {
        *puVar3 = 0;
      }
      else {
        *(undefined2 *)(PTR__hero_0003f014 + 2) = 1;
        *(ushort *)(puVar5 + 4) = uVar6;
        ppuVar17[-1] = (undefined *)0x18a08;
        _ResetHeroPosition();
        *ppuVar17 = (undefined *)0x1;
        ppuVar17[-1] = (undefined *)0x18a14;
        _Multiplier_Reset();
        ppuVar17[-1] = (undefined *)0x18a19;
        sVar14 = _GetLives();
        if (sVar14 < 1) {
          *ppuVar17 = (undefined *)0x2;
          ppuVar17[-1] = (undefined *)0x18a5d;
          _PrepareNotice();
          ppuVar17[2] = (undefined *)0x0;
          ppuVar17[1] = (undefined *)0x1e;
          *ppuVar17 = (undefined *)0x3;
          ppuVar17[-1] = (undefined *)0x18a79;
          _PlayMySnd();
        }
        else if (_gIsEndOfLevel == '\0') {
          ppuVar17[2] = (undefined *)0x0;
          ppuVar17[1] = (undefined *)0x14;
          *ppuVar17 = (undefined *)0x2;
          ppuVar17[-1] = (undefined *)0x18a43;
          _PlayMySnd();
          *ppuVar17 = (undefined *)0x1;
          ppuVar17[-1] = (undefined *)0x18a4f;
          _PrepareNotice();
        }
      }
    }
    ppuVar17[-1] = (undefined *)0x18a7e;
    cVar8 = _PauseKey();
    if ((cVar8 == '\0') && (local_ea == 0)) {
      bVar2 = false;
    }
    else if (*puVar4 != '\x01') {
      ppuVar17[-1] = (undefined *)0x18aa4;
      local_e9 = _GetCurrentNotice();
      *ppuVar17 = (undefined *)0x3;
      ppuVar17[-1] = (undefined *)0x18ab6;
      _PrepareNotice();
      bVar2 = true;
    }
    puVar5 = PTR__gNumNormalBlocks_00034188;
    if (0 < *(short *)PTR__gNumNormalBlocks_00034188) {
      ppuVar17[-1] = (undefined *)0x18ad2;
      sVar14 = _NormalBlockCount();
      *(short *)puVar5 = sVar14;
      if (sVar14 == 0) {
        ppuVar17[2] = (undefined *)0x0;
        ppuVar17[1] = (undefined *)0x14;
        *ppuVar17 = (undefined *)0x21;
        ppuVar17[-1] = (undefined *)0x18afa;
        _PlayMySnd();
        ppuVar17[1] = (undefined *)0x1;
        *ppuVar17 = (undefined *)0x7d0;
        ppuVar17[-1] = (undefined *)0x18b0e;
        _AddToScore();
        ppuVar17[2] = (undefined *)0x2;
        ppuVar17[1] = (undefined *)((char)puVar7[0x34] * 0x28);
        *ppuVar17 = (undefined *)((char)puVar7[0x28] * 0x28);
        ppuVar17[-1] = (undefined *)0x18b3c;
        _NewStarGroup();
        ppuVar17[3] = (undefined *)0xc;
        ppuVar17[2] = (undefined *)0xc;
        ppuVar17[1] = (undefined *)(int)*(short *)(puVar7 + 0x14);
        *ppuVar17 = (undefined *)(int)*(short *)(puVar7 + 0x16);
        ppuVar17[-1] = (undefined *)0x18b66;
        _NewPoint();
        ppuVar17[-1] = (undefined *)0x18b6b;
        _FinishLevel();
      }
    }
    ppuVar17[-1] = (undefined *)0x18b70;
    _Bubbles();
    ppuVar17[-1] = (undefined *)0x18b75;
    _ProcessEnemies();
    ppuVar17[-1] = (undefined *)0x18b7a;
    _ProcessHero();
    ppuVar17[-1] = (undefined *)0x18b7f;
    _Splats_Process();
    ppuVar17[-1] = (undefined *)0x18b84;
    _Bubbles_Process();
    ppuVar17[-1] = (undefined *)0x18b89;
    _Balloons_Process();
    ppuVar17[-1] = (undefined *)0x18b8e;
    _Bonus_Process();
    ppuVar17[-1] = (undefined *)0x18b93;
    _ProcessBlocks();
    ppuVar17[-1] = (undefined *)0x18b98;
    _ProcessStars();
    ppuVar17[-1] = (undefined *)0x18b9d;
    _ProcessPoints();
    ppuVar17[-1] = (undefined *)0x18ba2;
    _TimeBonus_Process();
    ppuVar17[-1] = (undefined *)0x18ba7;
    _Sounds_CheckDelayedSounds();
    ppuVar17[-1] = (undefined *)0x18bac;
    _EraseNotice();
    ppuVar17[-1] = (undefined *)0x18bb1;
    cVar8 = _IsDoubleBuffered();
    if (cVar8 == '\0') {
      ppuVar17[-1] = (undefined *)0x18bc1;
      _SetToCompGWorld();
    }
    else {
      ppuVar17[-1] = (undefined *)0x18bba;
      _SetToScreen();
    }
    *ppuVar17 = (undefined *)0x0;
    ppuVar17[-1] = (undefined *)0x18bcd;
    _RestoreBgnd();
    ppuVar17[-1] = (undefined *)0x18bd2;
    _DrawHurtBlocksToComp();
    ppuVar17[-1] = (undefined *)0x18bd7;
    _DrawHeroToComp();
    ppuVar17[-1] = (undefined *)0x18bdc;
    _DrawEnemiesToComp();
    ppuVar17[-1] = (undefined *)0x18be1;
    _Balloons_DrawToComp();
    ppuVar17[-1] = (undefined *)0x18be6;
    _DrawBlocksToComp();
    ppuVar17[-1] = (undefined *)0x18beb;
    _Splats_DrawToComp();
    ppuVar17[-1] = (undefined *)0x18bf0;
    _Bonus_Draw();
    ppuVar17[-1] = (undefined *)0x18bf5;
    _DrawStarsToComp();
    ppuVar17[-1] = (undefined *)0x18bfa;
    _DrawOuchToComp();
    ppuVar17[-1] = (undefined *)0x18bff;
    _DrawPointsToComp();
    ppuVar17[-1] = (undefined *)0x18c04;
    _Bubbles_DrawToComp();
    ppuVar17[-1] = (undefined *)0x18c09;
    _CheckForHacking();
    *ppuVar17 = (undefined *)0x0;
    ppuVar17[-1] = (undefined *)0x18c15;
    _DrawScore();
    *ppuVar17 = (undefined *)0x0;
    ppuVar17[-1] = (undefined *)0x18c21;
    _TimeBonus_Draw();
    ppuVar17[-1] = (undefined *)0x18c26;
    _DrawReserveInfo();
    ppuVar17[-1] = (undefined *)0x18c2b;
    _DrawNotice();
    ppuVar17[-1] = (undefined *)0x18c30;
    cVar8 = _IsDoubleBuffered();
    if (cVar8 == '\0') {
      ppuVar17[-1] = (undefined *)0x18c39;
      _DrawRectsToScreen();
    }
    ppuVar17[-1] = (undefined *)0x18c3e;
    _FlushIfNecessary();
    if (bVar2) {
      iVar13 = *(int *)(PTR__environment_0003f028 + 0x16);
      ppuVar17[2] = (undefined *)*(int *)(PTR__environment_0003f028 + 0x12);
      ppuVar17[3] = (undefined *)iVar13;
      iVar13 = *(int *)(PTR__environment_0003f028 + 0x16);
      *ppuVar17 = (undefined *)*(undefined4 *)(PTR__environment_0003f028 + 0x12);
      ppuVar17[1] = (undefined *)iVar13;
      ppuVar17[-1] = (undefined *)0x18c6c;
      _ScreenToComp();
    }
    ppuVar17[-1] = (undefined *)0x18c71;
    cVar8 = _IsEscapeKeyDown();
    if (cVar8 == '\0') {
      _gEscapeKeyFrames = 0;
    }
    else {
      *ppuVar17 = (undefined *)0x3d;
      ppuVar17[-1] = (undefined *)0x18c81;
      cVar8 = _GetBooleanPref();
      if (cVar8 == '\0') {
        *puVar3 = 0;
      }
      else {
        _gEscapeKeyFrames = _gEscapeKeyFrames + 1;
        if (0x1e < _gEscapeKeyFrames) {
          *puVar3 = 0;
        }
      }
    }
    if (_gIsEndOfLevel == '\0') {
      if ((ushort)(*(short *)(puVar7 + 2) - 1U) < 2) {
        ppuVar17[-1] = (undefined *)0x18cdf;
        cVar8 = _AreAllEnemiesSquished();
        if (cVar8 != '\0') {
          _gEndOfLevelTime = _gFrameCounter;
          _gIsEndOfLevel = '\x01';
          if (*puVar4 != '\x01') {
            ppuVar17[2] = (undefined *)0x0;
            ppuVar17[1] = (undefined *)0x1e;
            *ppuVar17 = (undefined *)0x23;
            ppuVar17[-1] = (undefined *)0x18d1e;
            _PlayMySnd();
          }
        }
        goto LAB_00018d1e;
      }
    }
    else {
LAB_00018d1e:
      if ((ushort)(*(short *)(puVar7 + 2) - 1U) < 2) {
        ppuVar17[-1] = (undefined *)0x18d3a;
        sVar14 = _GetLives();
        if (((0 < sVar14) && (_gIsEndOfLevel != '\0')) &&
           (_gEndOfLevelTime + 0x46 < (uint)_gFrameCounter)) {
          if (*puVar4 == '\x01') {
            *puVar3 = 0;
          }
          else {
            _gEndOfLevelTime = 0;
            _gIsEndOfLevel = '\0';
            if (*PTR__gEXTRA_Animate_0003f07c != '\0') {
              *ppuVar17 = (undefined *)0x1;
              ppuVar17[-1] = (undefined *)0x18da8;
              _EXTRA_Reset();
            }
            ppuVar17[-1] = (undefined *)0x18dad;
            _StopMusic();
            ppuVar17[-1] = (undefined *)0x18db2;
            _TimeBonus_CountDown();
            ppuVar17[2] = (undefined *)0x0;
            ppuVar17[1] = (undefined *)0x1e;
            *ppuVar17 = (undefined *)0x1b;
            ppuVar17[-1] = (undefined *)0x18dce;
            _PlayMySnd();
            if (*puVar4 != '\x01') {
              ppuVar17[-1] = (undefined *)0x18dde;
              _UnloadMusic();
            }
            ppuVar17[2] = (undefined *)0xa0;
            ppuVar17[1] = &_C_74_74842;
            *ppuVar17 = (undefined *)&local_c4;
            ppuVar17[-1] = (undefined *)0x18dfc;
            _memcpy(*ppuVar17,ppuVar17[1],(size_t)ppuVar17[2]);
            ppuVar17[-1] = (undefined *)0x18e01;
            uVar18 = _RT3_GetLicenseCode();
            iVar13 = 1;
            do {
              if (((auStack_cc[iVar13 * 2 + 1] ^ (uint)((ulonglong)uVar18 >> 0x20)) & 0xfffffff) ==
                  0 && auStack_cc[iVar13 * 2] == (uint)uVar18) {
                ppuVar17[1] = (undefined *)0x14;
                *ppuVar17 = (undefined *)0x0;
                ppuVar17[-1] = (undefined *)0x18e52;
                sVar14 = _GetRandomFast();
                if (sVar14 == 1) {
                  ppuVar17[1] = (undefined *)0xffffffce;
                  *ppuVar17 = "Too many commands in music channel buffer (channel corrupt).";
                  ppuVar17[-1] = (undefined *)0x18e6c;
                  _StdError();
                }
                break;
              }
              iVar13 = iVar13 + 1;
            } while (iVar13 != 0x15);
            ppuVar17[-1] = (undefined *)0x18e7b;
            sVar14 = _GetLevel();
            if (7 < sVar14) {
              ppuVar17[-1] = (undefined *)0x18e86;
              iVar13 = _RT3_IsRegistered();
              if (iVar13 == 0) {
                ppuVar17[-1] = (undefined *)0x18e8f;
                _TurnISpOff();
                ppuVar17[-1] = (undefined *)0x18e94;
                _DoRegReminder();
                *puVar3 = 0;
                goto LAB_00018ea4;
              }
            }
            ppuVar17[-1] = (undefined *)0x18ea4;
            _NewLevel();
          }
        }
      }
    }
LAB_00018ea4:
    *ppuVar17 = (undefined *)0xc;
    ppuVar17[-1] = (undefined *)0x18eb0;
    cVar8 = _GameKeyDown();
    if (cVar8 != '\0') {
      ppuVar17[-1] = (undefined *)0x18eb9;
      cVar8 = _IsCommandKeyDown();
      if (cVar8 != '\0') {
        ppuVar17[-1] = (undefined *)0x18ec2;
        _DoRegReminder();
        ppuVar17[-1] = (undefined *)0x18ec7;
        _StopMusic();
        ppuVar17[-1] = (undefined *)0x18ecc;
        _CleanUp();
      }
    }
    ppuVar17[-1] = (undefined *)0x18ed1;
    uVar18 = _RT3_GetLicenseCode();
    cVar8 = '\0';
    for (uVar15 = (uint)uVar18 ^ (uint)((ulonglong)uVar18 >> 0x20); uVar15 != 0;
        uVar15 = uVar15 & uVar15 - 1) {
      cVar8 = '\x01' - cVar8;
    }
    if (cVar8 == '\0') {
      ppuVar17[-1] = (undefined *)0x18ef8;
      iVar13 = _RT3_IsRegistered();
      if (iVar13 != 0) {
        ppuVar17[-1] = (undefined *)0x18f01;
        _CleanUp();
      }
    }
    if (bVar2) {
      ppuVar17[1] = (undefined *)(uint)local_ea;
      *ppuVar17 = (undefined *)(int)local_e9;
      ppuVar17[-1] = (undefined *)0x18f24;
      _PauseGame();
      bVar2 = false;
      local_ea = 0;
    }
    pcVar16 = PTR__gGameMode_00034180;
    if ((*PTR__gGameMode_00034180 == '\x01') &&
       (_gRecording <= *(uint *)PTR__gRecordingCounter_00034198)) {
      *puVar3 = 0;
    }
    if (_gCarbonTimerInstalled == '\0') {
      if (_gLimitFrames != '\0') {
        if (_gDaddyMode == '\0') {
          do {
            ppuVar17[-1] = (undefined *)0x18f7e;
            uVar15 = _TickCount();
          } while (uVar15 < local_f0 + 2U);
        }
        else {
          do {
            ppuVar17[-1] = (undefined *)0x18f92;
            uVar15 = _TickCount();
          } while (uVar15 < local_f0 + 4U);
        }
      }
      ppuVar17[-1] = (undefined *)0x18f9b;
      local_f0 = _TickCount();
    }
    else {
      do {
        local_c4 = 2.7720746e+20;
        local_c0 = 2;
        local_bc = 2.7720746e+20;
        local_b8 = 1;
        local_b4 = 0x6d6f7573;
        local_b0 = 1;
        local_ac = 0x6b657962;
        local_a8 = 1;
        if ((*pcVar16 == '\x01') || (_gTimerFired == '\0')) {
          ppuVar17[5] = (undefined *)local_20;
          ppuVar17[4] = (undefined *)0x1;
          ppuVar17[2] = (undefined *)0xd2f1a9fc;
          ppuVar17[3] = (undefined *)0x3f50624d;
          ppuVar17[1] = (undefined *)&local_c4;
        }
        else {
          ppuVar17[5] = (undefined *)local_20;
          ppuVar17[4] = (undefined *)0x1;
          ppuVar17[2] = (undefined *)0x0;
          ppuVar17[3] = (undefined *)0x0;
          ppuVar17[1] = (undefined *)&local_c4;
        }
        *ppuVar17 = (undefined *)0x4;
        ppuVar17[-1] = (undefined *)0x1906a;
        iVar13 = _ReceiveNextEvent();
        if (iVar13 == -0x2694) {
          ppuVar17[-1] = (undefined *)0x184d8;
          _ShowMyCursor();
          *ppuVar17 = (undefined *)0x1;
          ppuVar17[-1] = (undefined *)0x184e4;
          _CGAssociateMouseAndMouseCursorPosition();
          *ppuVar17 = (undefined *)*(undefined4 *)PTR__gSavedMousePosition_0003417c;
          ppuVar17[-1] = (undefined *)0x184f3;
          _SetMouse();
          return;
        }
        if (iVar13 == 0) {
          *ppuVar17 = (undefined *)local_20[0];
          ppuVar17[-1] = (undefined *)0x190a1;
          iVar13 = _GetEventKind();
          if (iVar13 == 2) {
            if (local_ea == 0) {
              if (*puVar4 == '\x01') {
                ppuVar17[-1] = (undefined *)0x190c8;
                _SuspendGame();
                *puVar3 = 0;
              }
              else {
                local_ea = 1;
              }
            }
          }
          else if ((iVar13 == 1) && (*puVar4 == '\x01')) {
            *puVar3 = 0;
          }
          ppuVar17[1] = (undefined *)iVar11;
          *ppuVar17 = (undefined *)local_20[0];
          ppuVar17[-1] = (undefined *)0x19101;
          _SendEventToEventTarget();
          *ppuVar17 = (undefined *)local_20[0];
          ppuVar17[-1] = (undefined *)0x1910c;
          _ReleaseEvent();
        }
        else if (iVar13 != -0x2693) {
          ppuVar17[1] = (undefined *)iVar13;
          *ppuVar17 = "Cannot use ReceiveNextEvent to get OS X events.";
          ppuVar17[-1] = (undefined *)0x19094;
          _StdError();
        }
      } while ((_gTimerFired == '\0') && (pcVar16 = PTR__gGameMode_00034180, _gLimitFrames != '\0'))
      ;
      _gTimerFired = '\0';
    }
    sVar14 = local_e2;
    if (_gShowFPS != '\0') {
      ppuVar17[-1] = (undefined *)0x1913f;
      uVar15 = _TickCount();
      sVar14 = local_e2 + 1;
      if (local_e8 + 0x3cU < uVar15) {
        *ppuVar17 = (undefined *)(int)local_e2;
        ppuVar17[-1] = (undefined *)0x1915f;
        _DrawFPS();
        ppuVar17[-1] = (undefined *)0x19164;
        local_e8 = _TickCount();
        local_e2 = 0;
        sVar14 = local_e2;
      }
    }
    local_e2 = sVar14;
    ppuVar17[-1] = (undefined *)0x19178;
    _HideMyCursor();
  } while( true );
}


// ==== _GameKeyDown @ 00019311 ====

undefined1 _GameKeyDown(ushort param_1)

{
  undefined1 uVar1;
  ushort uVar2;
  undefined1 local_2c [28];
  
  _GetKeys(local_2c);
  uVar2 = param_1;
  if ((short)param_1 < 0) {
    uVar2 = param_1 + 7;
  }
  param_1 = param_1 & 0x8007;
  if ((short)param_1 < 0) {
    param_1 = (param_1 - 1 | 0xfff8) + 1;
  }
  uVar1 = _BitTst(local_2c,(int)(short)(((uVar2 & 0xfff8) - param_1) + 7));
  return uVar1;
}


// ==== _InitKeys @ 0001936b ====

void _InitKeys(void)

{
  return;
}


// ==== _CloseKeys @ 00019370 ====

void _CloseKeys(void)

{
  return;
}


// ==== _SuspendKeys @ 00019375 ====

void _SuspendKeys(void)

{
  return;
}


// ==== _ResumeKeys @ 0001937a ====

void _ResumeKeys(void)

{
  return;
}


// ==== _TurnISpOn @ 0001937f ====

void _TurnISpOn(void)

{
  return;
}


// ==== _TurnISpOff @ 00019384 ====

void _TurnISpOff(void)

{
  return;
}


// ==== _KeysConfigure @ 00019389 ====

void _KeysConfigure(void)

{
  return;
}


// ==== _ISpConfigureEventProc @ 0001938e ====

undefined4 _ISpConfigureEventProc(void)

{
  return 0;
}


// ==== _InitControls @ 00019395 ====

void _InitControls(void)

{
  short sVar1;
  
  sVar1 = _GetShortPref(0x38);
  _GetKeySetPref((int)sVar1,PTR__gKeySetName_000341ac,PTR__gLeftCode_000341a8,
                 PTR__gRightCode_000341a4,PTR__gUpCode_000341b8,PTR__gDownCode_000341b0,
                 PTR__gPushCode_000341b4);
  return;
}


// ==== _UpKey @ 000193ee ====

undefined1 _UpKey(void)

{
  undefined1 uVar1;
  
  uVar1 = _GameKeyDown((int)*(short *)PTR__gUpCode_000341b8);
  return uVar1;
}


// ==== _RightKey @ 00019409 ====

undefined1 _RightKey(void)

{
  undefined1 uVar1;
  
  uVar1 = _GameKeyDown((int)*(short *)PTR__gRightCode_000341a4);
  return uVar1;
}


// ==== _DownKey @ 00019424 ====

undefined1 _DownKey(void)

{
  undefined1 uVar1;
  
  uVar1 = _GameKeyDown((int)*(short *)PTR__gDownCode_000341b0);
  return uVar1;
}


// ==== _LeftKey @ 0001943f ====

undefined1 _LeftKey(void)

{
  undefined1 uVar1;
  
  uVar1 = _GameKeyDown((int)*(short *)PTR__gLeftCode_000341a8);
  return uVar1;
}


// ==== _PushKey @ 0001945a ====

undefined1 _PushKey(void)

{
  undefined1 uVar1;
  
  uVar1 = _GameKeyDown((int)*(short *)PTR__gPushCode_000341b4);
  return uVar1;
}


// ==== _PauseKey @ 00019475 ====

undefined1 _PauseKey(void)

{
  undefined1 uVar1;
  
  uVar1 = _GameKeyDown(0x39);
  return uVar1;
}


// ==== _CodeToName @ 0001948c ====

void _CodeToName(ushort param_1,undefined2 *param_2)

{
  char local_10c [256];
  
  if (param_1 < 0x80) {
    _GetIndString(local_10c,0x82,(int)(short)(param_1 + 1));
    if (local_10c[0] != '\0') {
      _CopyPascalStringToC(local_10c,param_2);
      return;
    }
  }
  *param_2 = 0x3f3f;
  *(undefined1 *)(param_2 + 1) = 0;
  return;
}


// ==== _GetPushName @ 000194ec ====

void _GetPushName(undefined4 param_1)

{
  _CodeToName((int)*(short *)PTR__gPushCode_000341b4,param_1);
  return;
}


// ==== _GetLeftName @ 0001950b ====

void _GetLeftName(undefined4 param_1)

{
  _CodeToName((int)*(short *)PTR__gLeftCode_000341a8,param_1);
  return;
}


// ==== _GetDownName @ 0001952a ====

void _GetDownName(undefined4 param_1)

{
  _CodeToName((int)*(short *)PTR__gDownCode_000341b0,param_1);
  return;
}


// ==== _GetRightName @ 00019549 ====

void _GetRightName(undefined4 param_1)

{
  _CodeToName((int)*(short *)PTR__gRightCode_000341a4,param_1);
  return;
}


// ==== _GetUpName @ 00019568 ====

void _GetUpName(undefined4 param_1)

{
  _CodeToName((int)*(short *)PTR__gUpCode_000341b8,param_1);
  return;
}


// ==== _GetUpKey @ 00019587 ====

int _GetUpKey(void)

{
  return (int)*(short *)PTR__gUpCode_000341b8;
}


// ==== _GetRightKey @ 00019594 ====

int _GetRightKey(void)

{
  return (int)*(short *)PTR__gRightCode_000341a4;
}


// ==== _GetDownKey @ 000195a1 ====

int _GetDownKey(void)

{
  return (int)*(short *)PTR__gDownCode_000341b0;
}


// ==== _GetLeftKey @ 000195ae ====

int _GetLeftKey(void)

{
  return (int)*(short *)PTR__gLeftCode_000341a8;
}


// ==== _GetPushKey @ 000195bb ====

int _GetPushKey(void)

{
  return (int)*(short *)PTR__gPushCode_000341b4;
}


// ==== _SetUpKey @ 000195c8 ====

void _SetUpKey(undefined2 param_1)

{
  *(undefined2 *)PTR__gUpCode_000341b8 = param_1;
  return;
}


// ==== _SetRightKey @ 000195d8 ====

void _SetRightKey(undefined2 param_1)

{
  *(undefined2 *)PTR__gRightCode_000341a4 = param_1;
  return;
}


// ==== _SetDownKey @ 000195e8 ====

void _SetDownKey(undefined2 param_1)

{
  *(undefined2 *)PTR__gDownCode_000341b0 = param_1;
  return;
}


// ==== _SetLeftKey @ 000195f8 ====

void _SetLeftKey(undefined2 param_1)

{
  *(undefined2 *)PTR__gLeftCode_000341a8 = param_1;
  return;
}


// ==== _SetPushKey @ 00019608 ====

void _SetPushKey(undefined2 param_1)

{
  *(undefined2 *)PTR__gPushCode_000341b4 = param_1;
  return;
}


// ==== _WaitForKey @ 00019618 ====

void _WaitForKey(short *param_1)

{
  char cVar1;
  ushort uVar2;
  ushort uVar3;
  short sVar4;
  int iVar5;
  undefined1 local_2c [28];
  
  do {
    _GetKeys(local_2c);
    *param_1 = -1;
    iVar5 = 0;
    do {
      cVar1 = _BitTst(local_2c,iVar5);
      if (cVar1 != '\0') {
        uVar3 = (ushort)iVar5;
        uVar2 = uVar3;
        if ((short)uVar3 < 0) {
          uVar2 = uVar3 + 7;
        }
        uVar3 = uVar3 & 0x8007;
        if ((short)uVar3 < 0) {
          uVar3 = (uVar3 - 1 | 0xfff8) + 1;
        }
        sVar4 = ((uVar2 & 0xfff8) - uVar3) + 7;
        *param_1 = sVar4;
        if ((sVar4 != 0x39) && (sVar4 != 0x7f)) break;
      }
      iVar5 = iVar5 + 1;
    } while (iVar5 != 0x80);
    sVar4 = *param_1;
    if (((sVar4 != 0x39) && (sVar4 != 0x7f)) && (sVar4 != -1)) {
      return;
    }
  } while( true );
}


// ==== _SaveKeys @ 000196ab ====

void _SaveKeys(void)

{
  short sVar1;
  short sVar2;
  short sVar3;
  short sVar4;
  short sVar5;
  short sVar6;
  
  sVar1 = *(short *)PTR__gPushCode_000341b4;
  sVar2 = *(short *)PTR__gDownCode_000341b0;
  sVar3 = *(short *)PTR__gUpCode_000341b8;
  sVar4 = *(short *)PTR__gRightCode_000341a4;
  sVar5 = *(short *)PTR__gLeftCode_000341a8;
  sVar6 = _GetShortPref(0x38);
  _SetKeySetPref((int)sVar6,PTR__gKeySetName_000341ac,(int)sVar5,(int)sVar4,(int)sVar3,(int)sVar2,
                 (int)sVar1);
  return;
}


// ==== _CanUseISp @ 00019723 ====

undefined4 _CanUseISp(void)

{
  return 0;
}


// ==== _Multiplier_Get @ 0001972a ====

undefined4 _Multiplier_Get(void)

{
  return _gBonusMultiplier;
}


// ==== _Bonus_Init @ 00019734 ====

void _Bonus_Init(void)

{
  char *pcVar1;
  short sVar2;
  ushort uVar3;
  undefined2 uVar4;
  short sVar5;
  char *pcVar6;
  undefined2 *puVar7;
  undefined4 uVar8;
  undefined4 uVar9;
  
  sVar2 = _GetCurrLevelNum();
  _bonus = 1;
  uVar3 = _GetRandomFast(0,100);
  DAT_000376c8 = uVar3 < 0x32;
  uVar4 = 0;
  if (sVar2 != 1) {
    uVar4 = _gBonus_NumEnemiesSquishedAtOnce;
  }
  _gBonus_NumEnemiesSquishedAtOnce = uVar4;
  DAT_000376c4 = _GetRandomFast(0xdc,600);
  DAT_000376ec = _GetRandomFast(0x1c2,0x3b6);
  pcVar6 = &_bonus;
  do {
    if (*pcVar6 != '\0') {
      pcVar6[1] = '\0';
      pcVar6[2] = '\0';
      uVar4 = _GetFrameCounter();
      *(undefined2 *)(pcVar6 + 0x26) = uVar4;
      pcVar6[3] = '\x01';
      pcVar6[0x18] = '\x02';
      pcVar6[0x19] = '\0';
      pcVar6[0x16] = '\0';
      pcVar6[0x17] = '\0';
      pcVar1 = pcVar6 + 0x22;
      pcVar6[0x22] = -1;
      pcVar6[0x23] = -1;
      uVar4 = _GetFrameCounter();
      *(undefined2 *)(pcVar6 + 0x1e) = uVar4;
      pcVar6[0x20] = '\x01';
      pcVar6[0x21] = '\0';
      sVar5 = _GetRandomFast(0x46,0x212);
      *(short *)(pcVar6 + 8) = sVar5;
      *(short *)(pcVar6 + 0xc) = sVar5 + 0x28;
      pcVar6[6] = -0x48;
      pcVar6[7] = '\x01';
      pcVar6[10] = -0x20;
      pcVar6[0xb] = '\x01';
      *(undefined4 *)(pcVar6 + 0xe) = *(undefined4 *)(pcVar6 + 6);
      *(undefined4 *)(pcVar6 + 0x12) = *(undefined4 *)(pcVar6 + 10);
      sVar5 = _GetRandomFast(1,0xe);
      *(short *)(pcVar6 + 4) = sVar5;
      if (sVar5 < 9) {
        if (sVar5 < 5) {
          if (sVar5 == 3) {
            *(short *)(pcVar6 + 4) = 0xe;
            goto LAB_0001989d;
          }
        }
        else {
          uVar4 = _GetRandomFast(9,0xd);
          *(undefined2 *)(pcVar6 + 4) = uVar4;
        }
      }
      else if (sVar5 == 0xe) {
LAB_0001989d:
        if (sVar2 < 3) {
          uVar9 = 1;
LAB_000198bb:
          uVar8 = 0;
        }
        else {
          if (sVar2 < 6) {
            uVar9 = 2;
            goto LAB_000198bb;
          }
          if (sVar2 < 0xb) {
            uVar9 = 3;
            uVar8 = 1;
          }
          else {
            uVar9 = 6;
            uVar8 = 2;
          }
        }
        uVar4 = _GetRandomFast(uVar8,uVar9);
        switch(uVar4) {
        case 0:
          pcVar1[0] = -0xc;
          pcVar1[1] = '\x01';
          pcVar6[0x1c] = '\x0e';
          pcVar6[0x1d] = '\0';
          break;
        case 1:
          pcVar1[0] = ' ';
          pcVar1[1] = '\x03';
          pcVar6[0x1c] = '\x0f';
          pcVar6[0x1d] = '\0';
          break;
        case 2:
          pcVar1[0] = -0x18;
          pcVar1[1] = '\x03';
          pcVar6[0x1c] = '\x10';
          pcVar6[0x1d] = '\0';
          break;
        case 3:
          pcVar1[0] = -0x30;
          pcVar1[1] = '\a';
          pcVar6[0x1c] = '\x11';
          pcVar6[0x1d] = '\0';
          break;
        case 4:
          pcVar1[0] = -0x48;
          pcVar1[1] = '\v';
          pcVar6[0x1c] = '\x12';
          pcVar6[0x1d] = '\0';
          break;
        case 5:
          pcVar1[0] = -0x60;
          pcVar1[1] = '\x0f';
          pcVar6[0x1c] = '\x13';
          pcVar6[0x1d] = '\0';
          break;
        case 6:
          pcVar1[0] = -0x78;
          pcVar1[1] = '\x13';
          pcVar6[0x1c] = '\x14';
          pcVar6[0x1d] = '\0';
          break;
        default:
          goto switchD_000198f9_default;
        }
      }
      pcVar6[0x1a] = '\x1a';
      pcVar6[0x1b] = '\0';
      sVar5 = *(short *)(pcVar6 + 4);
      if (sVar5 != 0xe) {
        *(short *)(pcVar6 + 0x1c) = sVar5;
      }
    }
    pcVar6 = pcVar6 + 0x28;
  } while (pcVar6 != (char *)&_gBonus_NumEnemiesSquishedAtOnce);
  puVar7 = &_gBonus_RandDriftTable;
  do {
    uVar4 = _GetRandomFast(0,4);
    *puVar7 = uVar4;
    puVar7 = puVar7 + 1;
  } while (puVar7 != (undefined2 *)&DAT_0003772a);
  _gBonus_RandDriftIndex = 0;
  _gMultiplier_Rect._2_2_ = 0x259;
  _gMultiplier_Rect._0_2_ = 0x1c0;
  DAT_00037686._2_2_ = 0x275;
  DAT_00037686._0_2_ = 0x1dc;
  *PTR__gMultiplier_Animate_000341ec = 0;
  _gMultiplier_Timer = _GetFrameCounter();
  _gMultiplier_AnimCounter = 0;
  *PTR__gEXTRA_Animate_000341e8 = 0;
  _gEXTRA_Timer = _GetFrameCounter();
  _gEXTRA_AnimCounter = 0;
switchD_000198f9_default:
  return;
}


// ==== _Bonus_DoesHeroTouch @ 00019a13 ====

undefined4 _Bonus_DoesHeroTouch(short param_1)

{
  undefined *puVar1;
  char cVar2;
  int iVar3;
  undefined4 local_14;
  undefined4 local_10;
  
  puVar1 = PTR__hero_0003f014;
  iVar3 = (int)param_1;
  if ((((&_bonus)[iVar3 * 0x28] != '\0') && (*(short *)(PTR__hero_0003f014 + 2) == 2)) &&
     ((&DAT_000376a2)[iVar3 * 0x28] == '\0')) {
    local_10 = (&DAT_000376aa)[iVar3 * 10];
    local_14 = (&DAT_000376a6)[iVar3 * 10];
    _InsetRect(&local_14,8,8);
    cVar2 = _RectsCollide(&local_14,puVar1 + 0x14);
    if (cVar2 != '\0') {
      return 1;
    }
  }
  return 0;
}


// ==== _Bonus_Draw @ 00019a94 ====

void _Bonus_Draw(void)

{
  undefined4 *puVar1;
  undefined4 *puVar2;
  int iVar3;
  undefined1 *puVar4;
  undefined4 *local_30;
  undefined4 local_24 [5];
  
  iVar3 = 0;
  puVar2 = &DAT_000376ae;
  local_30 = &DAT_000376ae;
  puVar4 = &_bonus;
  do {
    if (*(char *)((int)puVar2 + -0xe) != '\0') {
      puVar1 = local_30;
      if (*(char *)((int)puVar2 + -0xb) != '\0') {
        if ((((-1 < *(short *)((int)puVar2 + -6)) && (*(short *)((int)puVar2 + -2) < 0x281)) &&
            (-1 < *(short *)(puVar2 + -2))) &&
           ((*(short *)(puVar2 + -1) < 0x1b9 &&
            (_SpriteToComp(0,(int)*(short *)((int)puVar2 + -6),(int)*(short *)(puVar2 + -2),
                           (int)*(short *)(puVar2 + 3),(int)*(short *)((int)puVar2 + 0xe),1),
            *(char *)(puVar2 + -3) == '\0')))) {
          _SpriteToComp(0,(int)*(short *)((int)puVar2 + -6),(int)*(short *)(puVar2 + -2),0x19,
                        (int)*(short *)((int)puVar2 + 0x12),1);
        }
        _UnionRect(puVar4 + 0xe,puVar4 + 6,local_24);
        puVar1 = local_24;
      }
      _AddRectToScreen(puVar1);
      if (*(char *)((int)puVar2 + -0xd) == '\0') {
        *puVar2 = puVar2[-2];
        puVar2[1] = puVar2[-1];
      }
      else {
        *(undefined1 *)((int)puVar2 + -0xe) = 0;
      }
    }
    iVar3 = iVar3 + 1;
    puVar4 = puVar4 + 0x28;
    local_30 = local_30 + 10;
    puVar2 = puVar2 + 10;
  } while (iVar3 != 2);
  return;
}


// ==== _Multiplier_Draw @ 00019bb4 ====

void _Multiplier_Draw(char param_1)

{
  undefined4 local_1c;
  undefined4 local_18;
  undefined4 local_14;
  undefined4 local_10;
  
  _SetRect(&local_14,0x259,6,(int)DAT_00037686._2_2_,0x24);
  _SetRect(&local_1c,0x259,0x1be,(int)DAT_00037686._2_2_,0x1dc);
  _SetToCompGWorld();
  _ScoreToComp(local_14,local_10,local_1c,local_18);
  if ((param_1 != '\0') && (_gBonusMultiplier != 1)) {
    _SpriteToComp(0,0x259,0x1c0,0x23,(int)(short)((short)_gBonusMultiplier + -1),0);
  }
  local_1c = _gMultiplier_Rect;
  local_18 = DAT_00037686;
  if (PTR__environment_0003f028[8] != '\0') {
    _OffsetRect(&local_1c,(int)*(short *)(PTR__environment_0003f028 + 0x1a),
                (int)*(short *)(PTR__environment_0003f028 + 0x1c));
  }
  _CompToScreen(_gMultiplier_Rect,DAT_00037686,local_1c,local_18);
  _FlushIfNecessary();
  return;
}


// ==== _Multiplier_Change @ 00019ceb ====

void _Multiplier_Change(undefined4 param_1)

{
  _gBonusMultiplier = param_1;
  _Multiplier_Draw(1);
  *PTR__gMultiplier_Animate_000341ec = 1;
  _gMultiplier_Timer = _GetFrameCounter();
  _gMultiplier_AnimCounter = 0;
  return;
}


// ==== _Multiplier_Flash @ 00019d23 ====

void _Multiplier_Flash(void)

{
  int iVar1;
  short sVar2;
  
  iVar1 = _gBonusMultiplier;
  if (_gBonusMultiplier != 1) {
    sVar2 = 3;
    do {
      _gBonusMultiplier = 1;
      _Multiplier_Draw(1);
      _FlushIfNecessary();
      _WaitFor(8);
      _gBonusMultiplier = iVar1;
      _Multiplier_Draw(1);
      _FlushIfNecessary();
      _PlayMySnd(0x20,0x1e,0);
      _WaitFor(8);
      sVar2 = sVar2 + -1;
    } while (sVar2 != 0);
  }
  return;
}


// ==== _Multiplier_Process @ 00019dae ====

void _Multiplier_Process(void)

{
  undefined *puVar1;
  ushort uVar2;
  uint uVar3;
  
  puVar1 = PTR__gMultiplier_Animate_000341ec;
  if (*PTR__gMultiplier_Animate_000341ec != '\0') {
    uVar2 = _GetFrameCounter();
    if (_gMultiplier_Timer + 5 < (uint)uVar2) {
      _gMultiplier_AnimCounter = _gMultiplier_AnimCounter + 1;
      if (9 < (short)_gMultiplier_AnimCounter) {
        _gMultiplier_AnimCounter = 9;
        *puVar1 = 0;
      }
      _gMultiplier_Timer = uVar2;
      if (_gMultiplier_AnimCounter < 9) {
        uVar3 = 1 << ((byte)_gMultiplier_AnimCounter & 0x1f);
        if ((uVar3 & 0x155) == 0) {
          if ((uVar3 & 0xaa) != 0) {
            _Multiplier_Draw(0);
          }
        }
        else {
          _Multiplier_Draw(1);
          _PlayMySnd(0x20,0x1e,0);
        }
      }
    }
  }
  return;
}


// ==== _Multiplier_Reset @ 00019e68 ====

void _Multiplier_Reset(char param_1)

{
  _gBonusMultiplier = 1;
  if (param_1 != '\0') {
    _Multiplier_Draw();
    return;
  }
  return;
}


// ==== _EXTRA_Draw @ 00019e8a ====

void _EXTRA_Draw(char param_1)

{
  undefined4 uVar1;
  undefined4 local_1c;
  undefined4 local_18;
  undefined4 local_14;
  undefined4 local_10;
  
  _SetRect(&local_14,0x142,6,0x1a7,0x26);
  _SetRect(&local_1c,0x142,0x1be,0x1a7,0x1de);
  _SetToCompGWorld();
  _ScoreToComp(local_14,local_10,local_1c,local_18);
  if (param_1 != '\0') {
    if (_gExtra_E == '\0') {
      uVar1 = 0x25;
    }
    else {
      uVar1 = 0x24;
    }
    _SpriteToComp(0,0x142,0x1be,uVar1,1,0);
    if (_gExtra_X == '\0') {
      uVar1 = 0x25;
    }
    else {
      uVar1 = 0x24;
    }
    _SpriteToComp(0,0x152,0x1be,uVar1,2,0);
    if (_gExtra_T == '\0') {
      uVar1 = 0x25;
    }
    else {
      uVar1 = 0x24;
    }
    _SpriteToComp(0,0x167,0x1be,uVar1,3,0);
    if (_gExtra_R == '\0') {
      uVar1 = 0x25;
    }
    else {
      uVar1 = 0x24;
    }
    _SpriteToComp(0,0x17d,0x1be,uVar1,4,0);
    if (_gExtra_A == '\0') {
      uVar1 = 0x25;
    }
    else {
      uVar1 = 0x24;
    }
    _SpriteToComp(0,0x193,0x1be,uVar1,5,0);
  }
  local_14 = local_1c;
  local_10 = local_18;
  if (PTR__environment_0003f028[8] != '\0') {
    _OffsetRect(&local_1c,(int)*(short *)(PTR__environment_0003f028 + 0x1a),
                (int)*(short *)(PTR__environment_0003f028 + 0x1c));
  }
  _CompToScreen(local_14,local_10,local_1c,local_18);
  _FlushIfNecessary();
  return;
}


// ==== _EXTRA_Reset @ 0001a128 ====

void _EXTRA_Reset(char param_1)

{
  _gExtra_A = 0;
  _gExtra_R = 0;
  _gExtra_T = 0;
  _gExtra_X = 0;
  _gExtra_E = 0;
  if (param_1 != '\0') {
    _EXTRA_Draw();
    return;
  }
  return;
}


// ==== _EXTRA_Change @ 0001a163 ====

void _EXTRA_Change(short param_1,short param_2)

{
  undefined *puVar1;
  int iVar2;
  
  switch((int)param_1) {
  default:
    _DebugValues("EXTRA_Change() - unknown letter.",(int)param_1);
    break;
  case 1:
    _gExtra_E = '\x01';
    break;
  case 2:
    _gExtra_X = '\x01';
    break;
  case 3:
    _gExtra_T = '\x01';
    break;
  case 4:
    _gExtra_R = '\x01';
    break;
  case 5:
    _gExtra_A = '\x01';
  }
  _EXTRA_Draw(1);
  puVar1 = PTR__gEXTRA_Animate_000341e8;
  if ((((*PTR__gEXTRA_Animate_000341e8 == '\0') && (_gExtra_E != '\0')) && (_gExtra_X != '\0')) &&
     (((_gExtra_T != '\0' && (_gExtra_R != '\0')) && (_gExtra_A != '\0')))) {
    _EXTRA_Draw(1);
    *puVar1 = 1;
    _gEXTRA_Timer = _GetFrameCounter();
    _gEXTRA_AnimCounter = 0;
    _gExtra_A = 0;
    _gExtra_R = 0;
    _gExtra_T = 0;
    _gExtra_X = 0;
    _gExtra_E = 0;
    _AddHero(1,1);
    iVar2 = (int)param_2;
    if ((&_bonus)[iVar2 * 0x28] != '\0') {
      (&DAT_000376a4)[iVar2 * 0x14] = 0xe;
      (&DAT_000376ba)[iVar2 * 0x14] = 0x1a;
      (&DAT_000376bc)[iVar2 * 0x14] = 0x15;
    }
    _AddToScore(10000,1);
    _Balloons_CaptureAllEnemies();
    return;
  }
  return;
}


// ==== _Bonus_Reward @ 0001a2c5 ====

void _Bonus_Reward(short param_1)

{
  short sVar1;
  undefined1 uVar2;
  int iVar3;
  undefined4 uVar4;
  
  iVar3 = (int)param_1;
  switch((&DAT_000376a4)[iVar3 * 0x14]) {
  default:
    goto switchD_0001a2e4_caseD_0;
  case 1:
    _PlayMySnd(0xf,10,0);
    _Balloons_CaptureAllEnemies();
    return;
  case 2:
    _PlayMySnd(0x1f,0x14,0);
    _PlayMySnd(4,0x14,0);
    _PlayMySnd(0xf,10,0);
    _RegenerateBlocks();
    return;
  case 4:
    _PlayMySnd(0x1f,0x14,0);
    _PlayMySnd(4,0x14,0);
    _SetHeroInvisibility();
    return;
  case 5:
    _PlayMySnd(0x2c,0x14,0);
    goto LAB_0001a400;
  case 6:
    _PlayMySnd(0x2c,0x14,0);
    goto LAB_0001a400;
  case 7:
    _PlayMySnd(0x2c,0x14,0);
    goto LAB_0001a400;
  case 8:
    _PlayMySnd(0x2c,0x14,0);
LAB_0001a400:
    _Multiplier_Change();
    return;
  case 9:
    _PlayMySnd(0x1f,0x14,0);
    uVar4 = 1;
    break;
  case 10:
    _PlayMySnd(0x1f,0x14,0);
    uVar4 = 2;
    break;
  case 0xb:
    _PlayMySnd(0x1f,0x14,0);
    uVar4 = 3;
    break;
  case 0xc:
    _PlayMySnd(0x1f,0x14,0);
    uVar4 = 4;
    break;
  case 0xd:
    _PlayMySnd(0x1f,0x14,0);
    uVar4 = 5;
    break;
  case 0xe:
    _PlayMySnd(0x1a,0x14,0);
    sVar1 = (&DAT_000376c2)[iVar3 * 0x14];
    if (sVar1 == 2000) {
      _TimeBonus_Increase(2000,1);
      uVar2 = 0xc;
    }
    else if (sVar1 < 0x7d1) {
      if (sVar1 == 800) {
        _TimeBonus_Increase(800,1);
        uVar2 = 8;
      }
      else if (sVar1 == 1000) {
        _TimeBonus_Increase(1000,1);
        uVar2 = 10;
      }
      else {
        if (sVar1 != 500) {
          return;
        }
        _TimeBonus_Increase(500,1);
        uVar2 = 5;
      }
    }
    else if (sVar1 == 4000) {
      _TimeBonus_Increase(4000,1);
      uVar2 = 0xe;
    }
    else if (sVar1 < 0xfa1) {
      if (sVar1 != 3000) {
        return;
      }
      _TimeBonus_Increase(3000,1);
      uVar2 = 0xd;
    }
    else if (sVar1 == 5000) {
      _PlayMySnd(0x28,0x14,5);
      _TimeBonus_Increase(5000,1);
      uVar2 = 0xf;
    }
    else {
      if (sVar1 != 10000) {
        return;
      }
      _PlayMySnd(0x28,0x14,5);
      _TimeBonus_Increase(10000,1);
      uVar2 = 0x14;
    }
    _NewPoint((int)*(short *)((int)&DAT_000376a6 + iVar3 * 0x28 + 2),
              (int)*(short *)(&DAT_000376a6 + iVar3 * 10),uVar2,3);
    goto switchD_0001a2e4_caseD_0;
  }
  _EXTRA_Change(uVar4,iVar3);
switchD_0001a2e4_caseD_0:
  return;
}


// ==== _Bonus_Pop @ 0001a6fd ====

void __regparm3 _Bonus_Pop(short param_1)

{
  undefined2 uVar1;
  int iVar2;
  
  _PlayMySnd(6,10,0);
  _PlayMySnd(0x1a,0x14,0);
  iVar2 = (int)param_1;
  (&DAT_000376a2)[iVar2 * 0x28] = 1;
  uVar1 = _GetFrameCounter();
  (&DAT_000376c6)[iVar2 * 0x14] = uVar1;
  _AddRectToBgnd(&DAT_000376a6 + iVar2 * 10);
  _NewStarGroup((int)*(short *)((int)&DAT_000376a6 + iVar2 * 0x28 + 2),
                (int)*(short *)(&DAT_000376a6 + iVar2 * 10),2);
  _Bonus_Reward(iVar2);
  return;
}


// ==== _Bonus_WasHit @ 0001a79a ====

undefined4 _Bonus_WasHit(undefined4 param_1)

{
  char cVar1;
  char *pcVar2;
  int iVar3;
  undefined4 uVar4;
  undefined4 local_24;
  undefined4 local_20;
  
  uVar4 = 0;
  iVar3 = 0;
  pcVar2 = &_bonus;
  do {
    if ((*pcVar2 != '\0') && (pcVar2[2] == '\0')) {
      local_24 = *(undefined4 *)(pcVar2 + 6);
      local_20 = *(undefined4 *)(pcVar2 + 10);
      _InsetRect(&local_24,8,8);
      cVar1 = _RectsCollide(param_1,&local_24);
      if (cVar1 != '\0') {
        _Bonus_Pop();
        uVar4 = 1;
      }
    }
    iVar3 = iVar3 + 1;
    pcVar2 = pcVar2 + 0x28;
  } while (iVar3 != 2);
  return uVar4;
}


// ==== _Bonus_SetNumEnemySquishes @ 0001a818 ====

void _Bonus_SetNumEnemySquishes(short param_1)

{
  short sVar1;
  undefined4 uVar2;
  
  _gBonus_NumEnemiesSquishedAtOnce = param_1;
  if (param_1 < 3) {
    _gBonus_NumEnemiesSquishedAtOnce = 0;
    return;
  }
  if (param_1 == 4) {
    switch(_gBonusMultiplier) {
    default:
      goto switchD_0001a853_caseD_0;
    case 1:
    case 2:
switchD_0001a853_caseD_2:
      uVar2 = 3;
      break;
    case 3:
switchD_0001a853_caseD_3:
      uVar2 = 4;
      break;
    case 4:
      goto switchD_0001a853_caseD_4;
    case 5:
      goto switchD_0001a853_caseD_5;
    }
  }
  else {
    if (param_1 == 5) {
      switch(_gBonusMultiplier) {
      default:
        goto switchD_0001a853_caseD_0;
      case 1:
      case 2:
      case 3:
        goto switchD_0001a853_caseD_3;
      case 4:
        goto switchD_0001a853_caseD_4;
      case 5:
        goto switchD_0001a853_caseD_5;
      }
    }
    if (param_1 != 3) {
      switch(_gBonusMultiplier) {
      default:
        goto switchD_0001a853_caseD_0;
      case 1:
      case 2:
      case 3:
      case 4:
        goto switchD_0001a853_caseD_4;
      case 5:
        goto switchD_0001a853_caseD_5;
      }
    }
    switch(_gBonusMultiplier) {
    default:
      goto switchD_0001a853_caseD_0;
    case 1:
      uVar2 = 2;
      break;
    case 2:
      goto switchD_0001a853_caseD_2;
    case 3:
      goto switchD_0001a853_caseD_3;
    case 4:
switchD_0001a853_caseD_4:
      uVar2 = 5;
      break;
    case 5:
switchD_0001a853_caseD_5:
      sVar1 = _GetLevel();
      if (sVar1 < 9) {
        _AddToScore(2000,1);
        uVar2 = 0xc;
      }
      else {
        _AddToScore(4000,1);
        uVar2 = 0xe;
      }
      _NewPoint((int)*(short *)(PTR__hero_0003f014 + 0x16),
                (int)*(short *)(PTR__hero_0003f014 + 0x14),uVar2,0);
      goto switchD_0001a853_caseD_0;
    }
  }
  _Multiplier_Change(uVar2);
switchD_0001a853_caseD_0:
  _gBonus_NumEnemiesSquishedAtOnce = 0;
  return;
}


// ==== _Bonus_Process @ 0001a92b ====

void _Bonus_Process(void)

{
  undefined *puVar1;
  char cVar2;
  ushort uVar3;
  short sVar4;
  short sVar5;
  uint uVar6;
  int iVar7;
  char *pcVar8;
  undefined4 uVar9;
  int local_24;
  
  puVar1 = PTR__gEXTRA_Animate_000341e8;
  if ((*PTR__gEXTRA_Animate_000341e8 == '\0') ||
     (uVar3 = _GetFrameCounter(), (uint)uVar3 <= _gEXTRA_Timer + 5)) goto LAB_0001aa39;
  _gEXTRA_AnimCounter = _gEXTRA_AnimCounter + 1;
  if (9 < (short)_gEXTRA_AnimCounter) {
    _gEXTRA_AnimCounter = 9;
    *puVar1 = 0;
  }
  _gEXTRA_Timer = uVar3;
  if (9 < _gEXTRA_AnimCounter) goto LAB_0001aa39;
  uVar6 = 1 << ((byte)_gEXTRA_AnimCounter & 0x1f);
  if ((uVar6 & 0x155) == 0) {
    if ((uVar6 & 0xaa) == 0) {
      if ((uVar6 & 0x200) == 0) goto LAB_0001aa39;
      _gExtra_A = 0;
      _gExtra_R = 0;
      _gExtra_T = 0;
      _gExtra_X = 0;
      _gExtra_E = 0;
      goto LAB_0001aa2d;
    }
    _gExtra_A = 0;
    _gExtra_R = 0;
    _gExtra_T = 0;
    _gExtra_X = 0;
    _gExtra_E = 0;
    uVar9 = 0;
  }
  else {
    _gExtra_A = 1;
    _gExtra_R = 1;
    _gExtra_T = 1;
    _gExtra_X = 1;
    _gExtra_E = 1;
LAB_0001aa2d:
    uVar9 = 1;
  }
  _EXTRA_Draw(uVar9);
LAB_0001aa39:
  _Multiplier_Process();
  local_24 = 0;
  pcVar8 = &_bonus;
  do {
    uVar3 = _GetFrameCounter();
    if (*pcVar8 != '\0') {
      if (uVar3 == *(ushort *)(pcVar8 + 0x24)) {
        _PlayMySnd(0x13,10,5);
      }
      if (uVar3 <= *(ushort *)(pcVar8 + 0x24)) goto LAB_0001ac9f;
      if (pcVar8[2] == '\0') {
        *(short *)(pcVar8 + 6) = *(short *)(pcVar8 + 6) - *(short *)(pcVar8 + 0x18);
        *(short *)(pcVar8 + 10) = *(short *)(pcVar8 + 10) - *(short *)(pcVar8 + 0x18);
        sVar5 = *(short *)(&_gBonus_SnakingLUT + *(short *)(pcVar8 + 0x16) * 2);
        sVar4 = *(short *)(pcVar8 + 0x16) + 1;
        if (0x12 < sVar4) {
          sVar4 = 0;
        }
        *(short *)(pcVar8 + 0x16) = sVar4;
        _OffsetRect(&DAT_000376a6 + local_24 * 10,(int)sVar5,0);
        iVar7 = (int)_gBonus_RandDriftIndex;
        sVar5 = _gBonus_RandDriftIndex + 1;
        _gBonus_RandDriftIndex = 0;
        if (sVar5 < 0x15) {
          _gBonus_RandDriftIndex = sVar5;
        }
        switch((&_gBonus_RandDriftTable)[iVar7]) {
        case 0:
          goto switchD_0001ab94_caseD_0;
        case 1:
          uVar9 = 0xffffffff;
          break;
        case 2:
          uVar9 = 0xfffffffe;
          break;
        case 3:
          uVar9 = 1;
          break;
        case 4:
          uVar9 = 2;
          break;
        default:
          goto switchD_0001ab94_default;
        }
        _OffsetRect(&DAT_000376a6 + local_24 * 10,uVar9,0);
switchD_0001ab94_caseD_0:
        if (*(short *)(pcVar8 + 6) < 0) {
          pcVar8[1] = '\x01';
          _PlayMySnd(6,10,0);
        }
        if (*(short *)(pcVar8 + 8) < 5) {
          pcVar8[8] = '\x05';
          pcVar8[9] = '\0';
          pcVar8[0xc] = '-';
          pcVar8[0xd] = '\0';
        }
        else if (0x27b < *(short *)(pcVar8 + 0xc)) {
          pcVar8[0xc] = '{';
          pcVar8[0xd] = '\x02';
          pcVar8[8] = 'S';
          pcVar8[9] = '\x02';
        }
        if (*(ushort *)(pcVar8 + 0x1e) + 2 < (uint)uVar3) {
          *(ushort *)(pcVar8 + 0x1e) = uVar3;
          sVar5 = 1;
          if ((short)(*(short *)(pcVar8 + 0x20) + 1) < 4) {
            sVar5 = *(short *)(pcVar8 + 0x20) + 1;
          }
          *(short *)(pcVar8 + 0x20) = sVar5;
        }
        cVar2 = _Bonus_DoesHeroTouch(local_24);
        if (cVar2 != '\0') {
          _Bonus_Pop();
        }
      }
      else if (*(ushort *)(pcVar8 + 0x26) + 0x1e < (uint)uVar3) {
        pcVar8[1] = '\x01';
        pcVar8[3] = '\0';
      }
      else {
        *(short *)(pcVar8 + 6) = *(short *)(pcVar8 + 6) - *(short *)(pcVar8 + 0x18);
        *(short *)(pcVar8 + 10) = *(short *)(pcVar8 + 10) - *(short *)(pcVar8 + 0x18);
        if (*(short *)(pcVar8 + 6) < 0) {
          pcVar8[1] = '\x01';
          _PlayMySnd(6,10,0);
        }
        if (*(short *)(pcVar8 + 8) < 5) {
          pcVar8[8] = '\x05';
          pcVar8[9] = '\0';
          pcVar8[0xc] = '-';
          pcVar8[0xd] = '\0';
        }
        else if (0x27b < *(short *)(pcVar8 + 0xc)) {
          pcVar8[0xc] = '{';
          pcVar8[0xd] = '\x02';
          pcVar8[8] = 'S';
          pcVar8[9] = '\x02';
        }
      }
      _AddRectToBgnd(&DAT_000376ae + local_24 * 10);
    }
LAB_0001ac9f:
    local_24 = local_24 + 1;
    pcVar8 = pcVar8 + 0x28;
  } while (local_24 != 2);
switchD_0001ab94_default:
  return;
}


// ==== _OpenMusic @ 0001acb8 ====

void _OpenMusic(void)

{
  undefined *puVar1;
  short sVar2;
  int iVar3;
  
  iVar3 = _NewPtr(0x424);
  puVar1 = PTR__gMusicChannel_000341fc;
  *(int *)PTR__gMusicChannel_000341fc = iVar3;
  if (iVar3 == 0) {
    _StdError("Out of memory, OpenMusic",0);
  }
  *(undefined2 *)(*(int *)puVar1 + 0x1e) = 0x100;
  sVar2 = _SndNewChannel(puVar1,5,0xc0,0);
  if (sVar2 != 0) {
    _StdError("Can\'t create sound channel for music.",(int)sVar2);
  }
  _gMusicOpen = 1;
  return;
}


// ==== _MusicPlaying @ 0001ad36 ====

undefined1 _MusicPlaying(void)

{
  short sVar1;
  undefined1 local_24 [12];
  undefined1 local_18;
  
  if ((_gMusicOpen == '\0') || (_gMusicLoaded == '\0')) {
    local_18 = 0;
  }
  else {
    sVar1 = _SndChannelStatus(*(undefined4 *)PTR__gMusicChannel_000341fc,0x18,local_24);
    if (sVar1 != 0) {
      _StdError("Can\'t get sound status.",(int)sVar1);
    }
  }
  return local_18;
}


// ==== _StartMusic @ 0001ad8c ====

void _StartMusic(void)

{
  undefined *puVar1;
  undefined *puVar2;
  char cVar3;
  short sVar4;
  short sVar5;
  short local_2e;
  undefined2 local_24;
  undefined2 local_22;
  undefined4 local_20;
  
  cVar3 = _IsGameDemoPlaying();
  if (cVar3 != '\0') {
    return;
  }
  if (_gMusicOpen == '\0') {
    return;
  }
  if (_gMusicLoaded == '\0') {
    return;
  }
  local_24 = 0x2e;
  local_22 = 0;
  if ((*PTR__gPlayGame_0003f03c == '\0') && (cVar3 = _GetBooleanPref(0x40), cVar3 == '\0')) {
LAB_0001ae44:
    local_20 = 0;
  }
  else {
    sVar4 = _GetShortPref(0x35);
    if (sVar4 == 2) {
      local_20 = 0x400040;
      goto LAB_0001ae19;
    }
    if (sVar4 < 3) {
      if (sVar4 == 1) goto LAB_0001ae44;
    }
    else {
      if (sVar4 == 3) {
        local_20 = 0x800080;
        goto LAB_0001ae19;
      }
      if (sVar4 == 4) {
        local_20 = 0x1000100;
        goto LAB_0001ae19;
      }
    }
    sVar4 = _GetShortPref(0x35);
    _StdError("Bad sound volume level in music.",(int)sVar4);
  }
LAB_0001ae19:
  sVar4 = _SndDoImmediate(*(undefined4 *)PTR__gMusicChannel_000341fc,&local_24);
  if (sVar4 != 0) {
    _StdError("Can\'t adjust sound volume on music channel.",(int)sVar4);
  }
  puVar2 = PTR__gMusicChannel_000341fc;
  puVar1 = PTR__gNumMusicLoopItems_000341f8;
  local_2e = 1;
  do {
    for (sVar4 = 1; sVar4 <= *(short *)puVar1; sVar4 = sVar4 + 1) {
      sVar5 = _SndPlay(*(undefined4 *)puVar2,
                       *(undefined4 *)
                        (PTR__gMusicSegmentsArray_00034204 +
                        *(short *)(PTR__gMusicLoopItems_000341f4 + sVar4 * 2) * 4),1);
      if (sVar5 != 0) {
        _DebugValues("Can\'t play music sound.",(int)sVar5);
        _ExitToShell();
      }
    }
    local_2e = local_2e + 1;
  } while (local_2e != 0x33);
  return;
}


// ==== _PlayMusicIfNecessary @ 0001aef8 ====

void _PlayMusicIfNecessary(void)

{
  char cVar1;
  
  if ((_gMusicOpen != '\0') && (_gMusicLoaded != '\0')) {
    cVar1 = _MusicPlaying();
    if (cVar1 == '\0') {
      _StartMusic();
      return;
    }
  }
  return;
}


// ==== _StopMusicWithoutFade @ 0001af21 ====

void _StopMusicWithoutFade(void)

{
  undefined *puVar1;
  short sVar2;
  undefined2 local_14;
  undefined2 local_12;
  undefined4 local_10;
  
  puVar1 = PTR__gMusicChannel_000341fc;
  if ((_gMusicOpen != '\0') && (_gMusicLoaded != '\0')) {
    local_14 = 4;
    local_12 = 0;
    local_10 = 0;
    sVar2 = _SndDoImmediate(*(undefined4 *)PTR__gMusicChannel_000341fc,&local_14);
    if (sVar2 != 0) {
      _DebugValues("Can\'t stop sound on music channel (#1).",(int)sVar2);
    }
    local_14 = 3;
    sVar2 = _SndDoImmediate(*(undefined4 *)puVar1,&local_14);
    if (sVar2 != 0) {
      _DebugValues("Can\'t stop sound on music channel (#2).",(int)sVar2);
    }
  }
  return;
}


// ==== _StopMusic @ 0001afac ====

void _StopMusic(void)

{
  char cVar1;
  undefined1 uVar2;
  short sVar3;
  int iVar4;
  int iVar5;
  uint unaff_EBX;
  undefined2 local_14;
  undefined2 local_12;
  uint local_10;
  
  if ((_gMusicOpen != '\0') && (_gMusicLoaded != '\0')) {
    sVar3 = _GetShortPref(0x35);
    if ((sVar3 != 1) &&
       ((*PTR__gPlayGame_0003f03c != '\0' || (cVar1 = _GetBooleanPref(0x40), cVar1 != '\0')))) {
      uVar2 = _RT3_IsRegistered();
      *PTR__gMusicRegCheck_00034208 = uVar2;
      cVar1 = _MusicPlaying();
      if (cVar1 != '\0') {
        local_14 = 0x2e;
        local_12 = 0;
        sVar3 = _GetShortPref(0x35);
        if (sVar3 == 3) {
          unaff_EBX = 0x80;
        }
        else if (sVar3 == 4) {
          unaff_EBX = 0x100;
        }
        else if (sVar3 == 2) {
          unaff_EBX = 0x40;
        }
        else {
          sVar3 = _GetShortPref(0x35);
          _StdError("Bad music volume in StopMusic.",(int)sVar3);
        }
        for (; -1 < (int)unaff_EBX; unaff_EBX = unaff_EBX - 5) {
          iVar4 = _TickCount();
          local_10 = unaff_EBX << 0x10 | unaff_EBX;
          sVar3 = _SndDoImmediate(*(undefined4 *)PTR__gMusicChannel_000341fc,&local_14);
          if (sVar3 != 0) {
            _StdError("Can\'t set sound volume for fade.",(int)sVar3);
          }
          do {
            iVar5 = _TickCount();
          } while (iVar4 == iVar5);
        }
      }
    }
    _StopMusicWithoutFade();
  }
  return;
}


// ==== _UpdateMusicVolume @ 0001b0d5 ====

void _UpdateMusicVolume(void)

{
  char cVar1;
  short sVar2;
  undefined2 local_14;
  undefined2 local_12;
  undefined4 local_10;
  
  if (_gMusicOpen == '\0') {
    return;
  }
  if (_gMusicLoaded == '\0') {
    return;
  }
  cVar1 = _MusicPlaying();
  if ((cVar1 == '\0') && (*PTR__gPlayGame_0003f03c == '\0')) {
    _StartMusic();
    return;
  }
  local_14 = 0x2e;
  local_12 = 0;
  if ((*PTR__gPlayGame_0003f03c == '\0') && (cVar1 = _GetBooleanPref(0x40), cVar1 == '\0')) {
LAB_0001b19a:
    local_10 = 0;
  }
  else {
    sVar2 = _GetShortPref(0x35);
    if (sVar2 == 2) {
      local_10 = 0x400040;
      goto LAB_0001b16f;
    }
    if (sVar2 < 3) {
      if (sVar2 == 1) goto LAB_0001b19a;
    }
    else {
      if (sVar2 == 3) {
        local_10 = 0x800080;
        goto LAB_0001b16f;
      }
      if (sVar2 == 4) {
        local_10 = 0x1000100;
        goto LAB_0001b16f;
      }
    }
    sVar2 = _GetShortPref(0x35);
    _StdError("Bad music volume in UpdateMusicVolume.",(int)sVar2);
  }
LAB_0001b16f:
  sVar2 = _SndDoImmediate(*(undefined4 *)PTR__gMusicChannel_000341fc,&local_14);
  if (sVar2 != 0) {
    _StdError("Can\'t set sound volume for UpdateMusicVolume.",(int)sVar2);
  }
  return;
}


// ==== _GetMusicString @ 0001b1d1 ====

void _GetMusicString(short param_1,char *param_2)

{
  undefined1 local_10c [256];
  
  _GetIndString(local_10c,0x83,(int)param_1);
  _CopyPascalStringToC(local_10c,param_2);
  if (*param_2 == '\0') {
    _ResourceError(0x7d6,0xb,"STR#",0x83);
  }
  return;
}


// ==== _LoadMusic @ 0001b23c ====

void _LoadMusic(short param_1)

{
  undefined *puVar1;
  char cVar2;
  int iVar3;
  uint uVar4;
  uint *puVar5;
  uint *puVar6;
  char *pcVar7;
  undefined1 uVar8;
  char *pcVar9;
  char local_634 [256];
  char local_534 [256];
  undefined1 local_434 [256];
  uint local_334 [4];
  undefined2 local_324;
  undefined1 local_234 [255];
  undefined2 uStack_135;
  undefined1 local_34 [8];
  char local_2c [8];
  char local_24 [20];
  
  if (_gMusicOpen == '\0') {
    return;
  }
  if (_gMusicLoaded != '\0') {
    return;
  }
  local_334[0] = local_334[0] & 0xffffff00;
  uVar8 = param_1 == 0;
  if ((bool)uVar8) {
    _GetMusicString(2,local_534);
  }
  else {
    uVar8 = param_1 == 1;
    if ((bool)uVar8) {
      _GetMusicString(3,local_534);
      _GetMusicString(4,local_634);
      _NumToString((int)*(short *)(PTR__level_0003f010 + 4),local_234);
      _CopyPascalStringToC(local_234,local_2c);
      _strcat(local_534,local_2c);
      _strcat(local_534,local_634);
    }
  }
  _strcat((char *)local_334,local_534);
  iVar3 = 0x12;
  puVar5 = local_334;
  pcVar9 = "Level set 1 music";
  do {
    puVar6 = puVar5;
    pcVar7 = pcVar9;
    if (iVar3 == 0) break;
    iVar3 = iVar3 + -1;
    pcVar7 = pcVar9 + 1;
    puVar6 = (uint *)((int)puVar5 + 1);
    uVar8 = (char)*puVar5 == *pcVar9;
    puVar5 = puVar6;
    pcVar9 = pcVar7;
  } while ((bool)uVar8);
  iVar3 = 0;
  if (!(bool)uVar8) {
    iVar3 = (uint)*(byte *)((int)puVar6 + -1) - (uint)(byte)pcVar7[-1];
  }
  uVar8 = iVar3 == 0;
  if ((bool)uVar8) {
    *(undefined2 *)PTR__gNumMusicLoopItems_000341f8 = 1;
    *(undefined2 *)(PTR__gMusicLoopItems_000341f4 + 2) = 1;
  }
  else {
    iVar3 = 0x12;
    puVar5 = local_334;
    pcVar9 = "Level set 2 music";
    do {
      puVar6 = puVar5;
      pcVar7 = pcVar9;
      if (iVar3 == 0) break;
      iVar3 = iVar3 + -1;
      pcVar7 = pcVar9 + 1;
      puVar6 = (uint *)((int)puVar5 + 1);
      uVar8 = (char)*puVar5 == *pcVar9;
      puVar5 = puVar6;
      pcVar9 = pcVar7;
    } while ((bool)uVar8);
    iVar3 = 0;
    if (!(bool)uVar8) {
      iVar3 = (uint)*(byte *)((int)puVar6 + -1) - (uint)(byte)pcVar7[-1];
    }
    uVar8 = iVar3 == 0;
    if (!(bool)uVar8) {
      iVar3 = 0x12;
      puVar5 = local_334;
      pcVar9 = "Level set 3 music";
      do {
        puVar6 = puVar5;
        pcVar7 = pcVar9;
        if (iVar3 == 0) break;
        iVar3 = iVar3 + -1;
        pcVar7 = pcVar9 + 1;
        puVar6 = (uint *)((int)puVar5 + 1);
        uVar8 = (char)*puVar5 == *pcVar9;
        puVar5 = puVar6;
        pcVar9 = pcVar7;
      } while ((bool)uVar8);
      iVar3 = 0;
      if (!(bool)uVar8) {
        iVar3 = (uint)*(byte *)((int)puVar6 + -1) - (uint)(byte)pcVar7[-1];
      }
      uVar8 = iVar3 == 0;
      if (!(bool)uVar8) {
        iVar3 = 0x12;
        puVar5 = local_334;
        pcVar9 = "Level set 4 music";
        do {
          puVar6 = puVar5;
          pcVar7 = pcVar9;
          if (iVar3 == 0) break;
          iVar3 = iVar3 + -1;
          pcVar7 = pcVar9 + 1;
          puVar6 = (uint *)((int)puVar5 + 1);
          uVar8 = (char)*puVar5 == *pcVar9;
          puVar5 = puVar6;
          pcVar9 = pcVar7;
        } while ((bool)uVar8);
        iVar3 = 0;
        if (!(bool)uVar8) {
          iVar3 = (uint)*(byte *)((int)puVar6 + -1) - (uint)(byte)pcVar7[-1];
        }
        uVar8 = iVar3 == 0;
        if (!(bool)uVar8) {
          iVar3 = 0xc;
          puVar5 = local_334;
          pcVar9 = "Title music";
          do {
            puVar6 = puVar5;
            pcVar7 = pcVar9;
            if (iVar3 == 0) break;
            iVar3 = iVar3 + -1;
            pcVar7 = pcVar9 + 1;
            puVar6 = (uint *)((int)puVar5 + 1);
            uVar8 = (char)*puVar5 == *pcVar9;
            puVar5 = puVar6;
            pcVar9 = pcVar7;
          } while ((bool)uVar8);
          iVar3 = 0;
          if (!(bool)uVar8) {
            iVar3 = (uint)*(byte *)((int)puVar6 + -1) - (uint)(byte)pcVar7[-1];
          }
          uVar8 = iVar3 == 0;
          if (!(bool)uVar8) {
            _StdError("Unknown music name for setting loop items.",0);
            goto LAB_0001b421;
          }
        }
      }
    }
    *(undefined2 *)(PTR__gMusicLoopItems_000341f4 + 2) = 1;
    *(undefined2 *)PTR__gNumMusicLoopItems_000341f8 = 1;
  }
LAB_0001b421:
  iVar3 = 0xc;
  puVar5 = local_334;
  pcVar9 = "Title music";
  do {
    puVar6 = puVar5;
    pcVar7 = pcVar9;
    if (iVar3 == 0) break;
    iVar3 = iVar3 + -1;
    pcVar7 = pcVar9 + 1;
    puVar6 = (uint *)((int)puVar5 + 1);
    uVar8 = (char)*puVar5 == *pcVar9;
    puVar5 = puVar6;
    pcVar9 = pcVar7;
  } while ((bool)uVar8);
  iVar3 = 0;
  if (!(bool)uVar8) {
    iVar3 = (uint)*(byte *)((int)puVar6 + -1) - (uint)(byte)pcVar7[-1];
  }
  if (iVar3 == 0) {
    local_334[0] = 0x6576654c;
    local_334[1] = 0x6573206c;
    local_334[2] = 0x20332074;
    local_334[3] = 0x6973756d;
    local_324 = 99;
  }
  *(undefined2 *)PTR__gMusicSegments_00034200 = 1;
  _strcpy((char *)((int)&uStack_135 + 1),(char *)local_334);
  uVar4 = 0xffffffff;
  pcVar9 = (char *)((int)&uStack_135 + 1);
  do {
    if (uVar4 == 0) break;
    uVar4 = uVar4 - 1;
    cVar2 = *pcVar9;
    pcVar9 = pcVar9 + 1;
  } while (cVar2 != '\0');
  *(undefined2 *)((int)&uStack_135 + ~uVar4) = 0x2e;
  _NumToString(1,local_34);
  _CopyPascalStringToC(local_34,local_24);
  _strcat((char *)((int)&uStack_135 + 1),local_24);
  _CopyCStringToPascal((int)&uStack_135 + 1,local_434);
  iVar3 = _GetNamedResource(0x736e6420,local_434);
  puVar1 = PTR__gMusicSegmentsArray_00034204;
  *(int *)(PTR__gMusicSegmentsArray_00034204 + 4) = iVar3;
  if (iVar3 == 0) {
    cVar2 = _IsOSX();
    if (cVar2 == '\0') {
      pcVar9 = 
      "Sorry, cannot load a music \'snd \' resource. Try giving Bubble Trouble more memory.";
    }
    else {
      pcVar9 = "Sorry, cannot load music \'snd \' resource.";
    }
    _StdError(pcVar9,1);
  }
  _HLock(*(undefined4 *)(puVar1 + 4));
  _gMusicLoaded = 1;
  return;
}


// ==== _UnloadMusic @ 0001b55c ====

void _UnloadMusic(void)

{
  undefined *puVar1;
  undefined *puVar2;
  short sVar3;
  
  if ((_gMusicOpen != '\0') && (_gMusicLoaded != '\0')) {
    _StopMusicWithoutFade();
    puVar2 = PTR__gMusicSegmentsArray_00034204;
    puVar1 = PTR__gMusicSegments_00034200;
    for (sVar3 = 1; sVar3 <= *(short *)puVar1; sVar3 = sVar3 + 1) {
      _ReleaseResource(*(undefined4 *)(puVar2 + sVar3 * 4));
    }
    _gMusicLoaded = '\0';
  }
  return;
}


// ==== _CloseMusic @ 0001b5b4 ====

void _CloseMusic(void)

{
  if (_gMusicOpen != '\0') {
    if (_gMusicLoaded != '\0') {
      _UnloadMusic();
    }
    _gMusicOpen = '\0';
  }
  return;
}


// ==== _PauseMusic @ 0001b5da ====

void _PauseMusic(void)

{
  short sVar1;
  undefined2 local_14;
  undefined2 local_12;
  undefined4 local_10;
  
  if ((_gMusicOpen != '\0') && (_gMusicLoaded != '\0')) {
    local_14 = 0x56;
    local_12 = 0;
    local_10 = 0;
    sVar1 = _SndDoImmediate(*(undefined4 *)PTR__gMusicChannel_000341fc,&local_14);
    if (sVar1 != 0) {
      _StdError("Can\'t pause sound on music channel.",(int)sVar1);
    }
    _gMusicPaused = 1;
  }
  return;
}


// ==== _ResumeMusic @ 0001b63a ====

void _ResumeMusic(void)

{
  char cVar1;
  short sVar2;
  undefined2 local_14;
  undefined2 local_12;
  undefined4 local_10;
  
  if ((_gMusicOpen != '\0') && (_gMusicLoaded != '\0')) {
    local_14 = 0x56;
    local_12 = 0;
    local_10 = 0x10000;
    sVar2 = _SndDoImmediate(*(undefined4 *)PTR__gMusicChannel_000341fc,&local_14);
    if (sVar2 != 0) {
      _StdError("Can\'t resume sound on music channel.",(int)sVar2);
    }
    cVar1 = _MusicPlaying();
    if (cVar1 == '\0') {
      _StartMusic();
    }
    _gMusicPaused = 0;
  }
  return;
}


// ==== _MusicPaused @ 0001b6a8 ====

undefined1 _MusicPaused(void)

{
  return _gMusicPaused;
}


// ==== _UpdateMusicStatus @ 0001b6b4 ====

void _UpdateMusicStatus(void)

{
  return;
}


// ==== _ResetHurtBlockList @ 0001b6b9 ====

void _ResetHurtBlockList(void)

{
  undefined1 *puVar1;
  
  puVar1 = &_gHurtBlock;
  do {
    *puVar1 = 0;
    puVar1 = puVar1 + 0xc;
  } while (puVar1 != &_gReserveHero_NeedsDrawing);
  return;
}


// ==== _NewHurtBlock @ 0001b6d0 ====

void _NewHurtBlock(char param_1,char param_2,undefined1 param_3)

{
  short sVar1;
  int iVar2;
  int iVar3;
  undefined2 uVar4;
  char *pcVar5;
  
  iVar2 = -1;
  iVar3 = 0;
  pcVar5 = &_gHurtBlock;
  do {
    if (*pcVar5 == '\0') {
      if ((char)iVar2 == -1) {
        iVar2 = iVar3;
      }
    }
    else if ((param_1 == pcVar5[6]) && (param_2 == pcVar5[7])) {
      return;
    }
    iVar3 = iVar3 + 1;
    pcVar5 = pcVar5 + 0xc;
  } while (iVar3 != 0x32);
  if ((char)iVar2 == -1) {
    return;
  }
  iVar3 = (int)(char)iVar2;
  iVar2 = iVar3 * 0xc;
  (&_gHurtBlock)[iVar2] = 1;
  (&DAT_00037766)[iVar2] = param_1;
  (&DAT_00037767)[iVar2] = param_2;
  (&DAT_00037764)[iVar3 * 6] = param_1 * 0x28;
  (&DAT_00037762)[iVar3 * 6] = param_2 * 0x28;
  switch(param_3) {
  case 10:
    (&DAT_00037768)[iVar3 * 6] = 0x11;
    break;
  default:
    goto switchD_0001b77b_caseD_b;
  case 0xf:
    (&DAT_00037768)[iVar3 * 6] = 0x14;
    break;
  case 0x10:
    (&DAT_00037768)[iVar3 * 6] = 0x15;
    break;
  case 0x14:
    (&DAT_00037768)[iVar3 * 6] = 0x16;
    goto LAB_0001b7e9;
  case 0x1e:
    (&DAT_00037768)[iVar3 * 6] = 0x17;
LAB_0001b7e9:
    uVar4 = *(undefined2 *)(PTR__level_0003f010 + 8);
    goto LAB_0001b7ac;
  case 0x34:
    sVar1 = _GetCurrLevelNum();
    if (sVar1 < 0xc) {
      (&DAT_00037768)[iVar3 * 6] = 0x12;
    }
    else {
      (&DAT_00037768)[iVar3 * 6] = 0x13;
    }
    (&DAT_0003776a)[iVar3 * 6] = 1;
    return;
  case 0x3c:
    (&DAT_00037768)[iVar3 * 6] = 0x1f;
  }
  uVar4 = *(undefined2 *)(PTR__level_0003f010 + 6);
LAB_0001b7ac:
  (&DAT_0003776a)[iVar3 * 6] = uVar4;
switchD_0001b77b_caseD_b:
  return;
}


// ==== _CheckBlock @ 0001b842 ====

void _CheckBlock(char param_1,char param_2)

{
  char *pcVar1;
  
  if ((byte)(PTR__gMaze_0003f054[(int)param_1 + param_2 * 0x10] - 10) < 0x33) {
    pcVar1 = PTR__block_00034224;
    do {
      if (((*pcVar1 != '\0') && (param_1 == pcVar1[0x17])) && (param_2 == pcVar1[0x18])) {
        return;
      }
      pcVar1 = pcVar1 + 0x34;
    } while (pcVar1 != PTR__block_00034224 + 0x71c);
    _NewHurtBlock((int)param_1,(int)param_2,
                  (int)(char)PTR__gMaze_0003f054[(int)param_1 + param_2 * 0x10]);
  }
  return;
}


// ==== _DrawHurtBlocksToComp @ 0001b8b1 ====

void _DrawHurtBlocksToComp(void)

{
  short *psVar1;
  
  psVar1 = &DAT_0003776a;
  do {
    if ((char)psVar1[-5] != '\0') {
      _SpriteToComp(0,(int)psVar1[-3],(int)psVar1[-4],(int)psVar1[-1],(int)*psVar1,1);
      *(undefined1 *)(psVar1 + -5) = 0;
    }
    psVar1 = psVar1 + 6;
  } while (psVar1 != (short *)&_gReserveHero_NumR);
  return;
}


// ==== _ResetBlocks @ 0001b90e ====

void _ResetBlocks(void)

{
  undefined1 *puVar1;
  undefined *puVar2;
  
  puVar1 = PTR__block_00034224 + 0x71c;
  puVar2 = PTR__block_00034224;
  do {
    *puVar2 = 0;
    puVar2 = puVar2 + 0x34;
  } while (puVar2 != puVar1);
  _gNumActiveBlocks = 0;
  *PTR__gJewelsDone_0003420c = 0;
  *PTR__gJewelAnimDir_00034228 = 1;
  *(undefined2 *)PTR__gNumNormalBlocks_0003f050 = 100;
  return;
}


// ==== _NewBlock @ 0001b94b ====

undefined4
_NewBlock(char param_1,char param_2,undefined1 param_3,char param_4,char param_5,char param_6)

{
  short sVar1;
  undefined2 uVar2;
  undefined *puVar3;
  char *pcVar4;
  int iVar5;
  int iVar6;
  
  puVar3 = PTR__block_00034224;
  iVar6 = 0;
  pcVar4 = PTR__block_00034224;
  while (*pcVar4 != '\0') {
    iVar6 = iVar6 + 1;
    pcVar4 = pcVar4 + 0x34;
    if (iVar6 == 0x23) {
      return 0;
    }
  }
  iVar5 = iVar6 * 0x34;
  *(short *)(PTR__block_00034224 + iVar5 + 8) = param_1 * 0x28;
  *(short *)(puVar3 + iVar5 + 6) = param_2 * 0x28;
  *(short *)(puVar3 + iVar5 + 0xc) = param_1 * 0x28 + 0x28;
  *(short *)(puVar3 + iVar5 + 10) = param_2 * 0x28 + 0x28;
  *(undefined4 *)(puVar3 + iVar5 + 0xe) = *(undefined4 *)(puVar3 + iVar5 + 6);
  *(undefined4 *)(puVar3 + iVar5 + 0x12) = *(undefined4 *)(puVar3 + iVar5 + 10);
  puVar3[iVar5 + 4] = param_4;
  puVar3[iVar5 + 0x16] = param_3;
  puVar3[iVar5 + 0x19] = 1;
  puVar3[iVar5 + 0x1d] = 0;
  puVar3[iVar5 + 0x17] = param_1;
  puVar3[iVar5 + 0x18] = param_2;
  puVar3[iVar5 + 0x1b] = 0;
  puVar3[iVar5 + 0x1c] = 0;
  puVar3[iVar5 + 0x24] = 0;
  *(undefined2 *)(puVar3 + iVar5 + 0x26) = 0;
  puVar3[iVar5 + 0x28] = 0;
  puVar3[iVar5 + 0x29] = param_5;
  puVar3[iVar5 + 0x2c] = 0;
  *(undefined2 *)(puVar3 + iVar5 + 0x2e) = 0;
  *(undefined2 *)(puVar3 + iVar5 + 0x30) = 0;
  switch((int)param_4) {
  case 10:
    puVar3[iVar6 * 0x34] = 1;
    puVar3 = puVar3 + iVar6 * 0x34;
    puVar3[0x1a] = 1;
    *(undefined2 *)(puVar3 + 0x1e) = 0x11;
    goto LAB_0001ba79;
  default:
    _DebugValues("NewBlock() - Unknown block type: ",(int)param_4);
    _CleanUp();
    break;
  case 0xf:
    puVar3[iVar6 * 0x34] = 1;
    puVar3 = puVar3 + iVar6 * 0x34;
    puVar3[0x1a] = 1;
    *(undefined2 *)(puVar3 + 0x1e) = 0x14;
    goto LAB_0001ba79;
  case 0x10:
    puVar3[iVar6 * 0x34] = 1;
    puVar3 = puVar3 + iVar6 * 0x34;
    puVar3[0x1a] = 1;
    *(undefined2 *)(puVar3 + 0x1e) = 0x15;
    goto LAB_0001ba79;
  case 0x14:
    puVar3[iVar6 * 0x34] = 1;
    puVar3 = puVar3 + iVar6 * 0x34;
    puVar3[0x1a] = 1;
    *(undefined2 *)(puVar3 + 0x1e) = 0x16;
    goto LAB_0001bb30;
  case 0x1e:
    puVar3[iVar6 * 0x34] = 1;
    puVar3 = puVar3 + iVar6 * 0x34;
    puVar3[0x1a] = 0;
    *(undefined2 *)(puVar3 + 0x1e) = 0x17;
LAB_0001bb30:
    *(undefined2 *)(puVar3 + 0x20) = 1;
    puVar3[0x22] = param_1;
    puVar3[0x23] = param_2;
    break;
  case 0x28:
    puVar3[iVar6 * 0x34] = 2;
    puVar3 = puVar3 + iVar6 * 0x34;
    puVar3[0x1a] = 0;
    *(undefined2 *)(puVar3 + 0x1e) = 0x18;
LAB_0001ba79:
    *(undefined2 *)(puVar3 + 0x20) = 1;
    break;
  case 0x33:
    break;
  case 0x34:
    if (param_6 == '\0') {
      iVar5 = iVar6 * 0x34;
      puVar3[iVar5] = 3;
      puVar3[iVar5 + 0x1a] = 0;
      *(undefined2 *)(puVar3 + iVar5 + 0x20) = 2;
    }
    else {
      iVar5 = iVar6 * 0x34;
      puVar3[iVar5] = 1;
      puVar3[iVar5 + 0x1a] = 1;
      *(undefined2 *)(puVar3 + iVar5 + 0x20) = 1;
    }
    sVar1 = _GetCurrLevelNum();
    if (sVar1 < 0xc) {
      *(undefined2 *)(PTR__block_00034224 + iVar6 * 0x34 + 0x1e) = 0x12;
    }
    else {
      *(undefined2 *)(PTR__block_00034224 + iVar6 * 0x34 + 0x1e) = 0x13;
    }
    break;
  case 0x3c:
    iVar5 = iVar6 * 0x34;
    puVar3[iVar5] = 3;
    puVar3[iVar5 + 0x1a] = 0;
    *(undefined2 *)(puVar3 + iVar5 + 0x1e) = 0x1f;
    *(short *)(puVar3 + iVar5 + 0x20) = (short)(char)PTR__enemy_0003f04c[param_5 * 0x5c + 0x10];
    *(undefined2 *)(puVar3 + iVar5 + 0x2a) = 0xf;
  }
  uVar2 = _GetFrameCounter();
  *(undefined2 *)(PTR__block_00034224 + iVar6 * 0x34 + 2) = uVar2;
  _gNumActiveBlocks = _gNumActiveBlocks + 1;
  return 1;
}


// ==== _CrushBlock @ 0001bc14 ====

void _CrushBlock(char param_1,char param_2,char param_3,char param_4)

{
  char cVar1;
  int iVar2;
  int iVar3;
  longlong lVar4;
  
  if (param_3 == '\x02') {
    param_2 = param_2 + '\x01';
  }
  else if (param_3 < '\x03') {
    if (param_3 != '\x01') {
      return;
    }
    param_2 = param_2 + -1;
  }
  else if (param_3 == '\x03') {
    param_1 = param_1 + -1;
  }
  else {
    if (param_3 != '\x04') {
      return;
    }
    param_1 = param_1 + '\x01';
  }
  iVar3 = (int)param_2;
  iVar2 = (int)param_1;
  cVar1 = _NewBlock(iVar2,iVar3,(int)param_3,0x28,0xffffffff,0);
  if (cVar1 == '\0') {
    _DebugValues("CrushBlock() - no free block. Increase kMaxNumBlocks.",0xffffffff);
    _CleanUp();
  }
  if (PTR__gMaze_0003f054[iVar2 + iVar3 * 0x10] != '4') {
    PTR__gMaze_0003f054[iVar2 + iVar3 * 0x10] = 0x28;
  }
  _PlayMySnd(6,10,0);
  if (param_4 == '\0') {
    return;
  }
  lVar4 = _RT3_GetLicenseCode();
  iVar2 = _RT3_CalcLicenseChecksum(lVar4);
  iVar3 = _RT3_ExtractLicenseChecksum(lVar4);
  if (((iVar2 != iVar3) && (lVar4 != 0)) && (iVar2 = _GetScore(), 0x7472 < iVar2)) {
    _GetRandomFast(0,0x28);
  }
  _AddToScore();
  return;
}


// ==== _PushBlock @ 0001bd62 ====

void _PushBlock(char param_1,char param_2,char param_3,char param_4)

{
  char cVar1;
  
  if (param_3 == '\x02') {
    param_2 = param_2 + '\x01';
    goto LAB_0001bda0;
  }
  if (param_3 < '\x03') {
    if (param_3 == '\x01') {
      param_2 = param_2 + -1;
      goto LAB_0001bda0;
    }
  }
  else {
    if (param_3 == '\x03') {
      param_1 = param_1 + -1;
      goto LAB_0001bda0;
    }
    if (param_3 == '\x04') {
      param_1 = param_1 + '\x01';
      goto LAB_0001bda0;
    }
  }
  _DebugValues("PushBlock() - unknown block direction.",(int)param_3);
  _CleanUp();
LAB_0001bda0:
  cVar1 = _NewBlock((int)param_1,(int)param_2,(int)param_3,(int)param_4,0xffffffff,1);
  if (cVar1 == '\0') {
    _DebugValues("PushBlock() - no free block. Increase kMaxNumBlocks.",0xffffffff);
    _CleanUp();
  }
  PTR__gMaze_0003f054[(int)param_1 + param_2 * 0x10] = 0;
  _PlayMySnd();
  return;
}


// ==== _KillEggBlock @ 0001be3b ====

void _KillEggBlock(char param_1,char param_2,char param_3)

{
  undefined *puVar1;
  undefined2 uVar2;
  undefined *puVar3;
  int iVar4;
  
  puVar1 = PTR__block_00034224;
  if (param_3 == '\x02') {
    param_2 = param_2 + '\x01';
  }
  else if (param_3 < '\x03') {
    if (param_3 != '\x01') {
      return;
    }
    param_2 = param_2 + -1;
  }
  else if (param_3 == '\x03') {
    param_1 = param_1 + -1;
  }
  else {
    if (param_3 != '\x04') {
      return;
    }
    param_1 = param_1 + '\x01';
  }
  iVar4 = 0;
  puVar3 = PTR__block_00034224;
  while (((puVar3[4] != '<' || (param_1 != puVar3[0x17])) || (param_2 != puVar3[0x18]))) {
    iVar4 = iVar4 + 1;
    puVar3 = puVar3 + 0x34;
    if (iVar4 == 0x23) {
      return;
    }
  }
  iVar4 = iVar4 * 0x34;
  PTR__block_00034224[iVar4 + 4] = 0x28;
  puVar1[iVar4] = 2;
  uVar2 = _GetFrameCounter();
  *(undefined2 *)(puVar1 + iVar4 + 2) = uVar2;
  puVar1[iVar4 + 0x1a] = 0;
  *(undefined2 *)(puVar1 + iVar4 + 0x1e) = 0x18;
  *(undefined2 *)(puVar1 + iVar4 + 0x20) = 1;
  puVar1[iVar4 + 0x24] = 0;
  *(undefined2 *)(puVar1 + iVar4 + 0x26) = 0;
  PTR__gMaze_0003f054[(int)(char)puVar1[iVar4 + 0x17] + (char)puVar1[iVar4 + 0x18] * 0x10] = 0x28;
  _PlayMySnd(6,0x14,0);
  _PlayMySnd(0,0x14,0);
  _AddToScore(0x32,1);
  _NewPoint((int)*(short *)(puVar1 + iVar4 + 8),(int)*(short *)(puVar1 + iVar4 + 6),0x15,0xc);
  _KillEnemy((int)(char)puVar1[iVar4 + 0x29],0);
  _NewStarGroup();
  return;
}


// ==== _ExplodeBombBlock @ 0001c032 ====

void _ExplodeBombBlock(char param_1)

{
  undefined *puVar1;
  short sVar2;
  short sVar3;
  int iVar4;
  int iVar5;
  int iVar6;
  undefined4 local_24;
  undefined4 local_20;
  
  puVar1 = PTR__block_00034224;
  iVar4 = param_1 * 0x34;
  local_24 = *(undefined4 *)(PTR__block_00034224 + iVar4 + 6);
  local_20 = *(undefined4 *)(PTR__block_00034224 + iVar4 + 10);
  *(undefined2 *)(PTR__block_00034224 + iVar4 + 0x1e) = 0xffff;
  *(undefined2 *)(puVar1 + iVar4 + 0x20) = 1;
  puVar1[iVar4 + 0x28] = 1;
  iVar5 = (int)(char)puVar1[iVar4 + 0x18];
  iVar6 = (int)(char)puVar1[iVar4 + 0x17];
  PTR__gMaze_0003f054[iVar6 + iVar5 * 0x10] = 0;
  _PlayMySnd(0x19,0x14,0);
  sVar2 = _GetCurrLevelNum();
  if (sVar2 < 0xc) {
    _NewStarGroup(iVar6 * 0x28,iVar5 * 0x28,0xf);
    _InsetRect(&local_24,0xffffffd8,0xffffffd8);
    iVar4 = 0;
  }
  else {
    _NewStarGroup(iVar6 * 0x28,iVar5 * 0x28,0x10);
    local_24 = CONCAT22(local_24._2_2_ + -0x28,(short)local_24 + -0x50);
    local_20 = CONCAT22(local_20._2_2_ + 0x28,(short)local_20 + -0x28);
    sVar2 = _CheckForBombKills(&local_24,0);
    local_24._2_2_ = (short)((uint)*(undefined4 *)(PTR__block_00034224 + iVar4 + 6) >> 0x10);
    local_24._0_2_ = (short)*(undefined4 *)(PTR__block_00034224 + iVar4 + 6);
    local_20._2_2_ = (short)((uint)*(undefined4 *)(PTR__block_00034224 + iVar4 + 10) >> 0x10);
    local_20._0_2_ = (short)*(undefined4 *)(PTR__block_00034224 + iVar4 + 10);
    local_24 = CONCAT22(local_24._2_2_ + -0x28,(short)local_24 + 0x50);
    local_20 = CONCAT22(local_20._2_2_ + 0x28,(short)local_20 + 0x50);
    sVar3 = _CheckForBombKills(&local_24,(int)sVar2);
    local_24._2_2_ = (short)((uint)*(undefined4 *)(PTR__block_00034224 + iVar4 + 6) >> 0x10);
    local_24._0_2_ = (short)*(undefined4 *)(PTR__block_00034224 + iVar4 + 6);
    local_20._2_2_ = (short)((uint)*(undefined4 *)(PTR__block_00034224 + iVar4 + 10) >> 0x10);
    local_20._0_2_ = (short)*(undefined4 *)(PTR__block_00034224 + iVar4 + 10);
    local_24 = CONCAT22(local_24._2_2_ + -0x50,(short)local_24 + -0x28);
    local_20 = CONCAT22(local_20._2_2_ + 0x50,(short)local_20 + 0x28);
    iVar4 = (int)(short)(sVar2 + sVar3);
  }
  _CheckForBombKills(&local_24,iVar4);
  return;
}


// ==== _ActivateBombBlock @ 0001c1c4 ====

void _ActivateBombBlock(char param_1,char param_2,char param_3)

{
  uint uVar1;
  char *pcVar2;
  int iVar3;
  ushort *puVar4;
  char local_21;
  
  local_21 = param_2;
  if (param_3 == '\x02') {
    local_21 = param_2 + '\x01';
  }
  else if (param_3 < '\x03') {
    if (param_3 != '\x01') {
      return;
    }
    local_21 = param_2 + -1;
  }
  else if (param_3 == '\x03') {
    param_1 = param_1 + -1;
  }
  else {
    if (param_3 != '\x04') {
      return;
    }
    param_1 = param_1 + '\x01';
  }
  iVar3 = 0;
  puVar4 = (ushort *)(PTR__block_00034224 + 2);
  pcVar2 = PTR__block_00034224;
  while ((((*pcVar2 == '\0' || (pcVar2[4] != '4')) || (param_1 != pcVar2[0x17])) ||
         (local_21 != pcVar2[0x18]))) {
    iVar3 = iVar3 + 1;
    puVar4 = puVar4 + 0x1a;
    pcVar2 = pcVar2 + 0x34;
    if (iVar3 == 0x23) {
      _PlayMySnd(0x18,10,0);
      _NewBlock((int)param_1,(int)local_21,(int)param_3,0x34,0xffffffff,0);
      return;
    }
  }
  uVar1 = _GetFrameCounter();
  if ((uVar1 & 0xffff) <= *puVar4 + 0x1e) {
    return;
  }
  _ExplodeBombBlock();
  return;
}


// ==== _Blocks_DeactivateRubberBlocks @ 0001c2c7 ====

void _Blocks_DeactivateRubberBlocks(void)

{
  char *pcVar1;
  undefined *puVar2;
  char *pcVar3;
  
  puVar2 = PTR__gMaze_0003f054;
  pcVar1 = PTR__block_00034224 + 0x71c;
  pcVar3 = PTR__block_00034224;
  do {
    if ((*pcVar3 != '\0') && ((byte)(pcVar3[4] - 0xfU) < 2)) {
      pcVar3[0x28] = '\x01';
      puVar2[(int)(short)pcVar3[0x17] + (short)pcVar3[0x18] * 0x10] = pcVar3[4];
    }
    pcVar3 = pcVar3 + 0x34;
  } while (pcVar3 != pcVar1);
  return;
}


// ==== _DrawBlocksToComp @ 0001c315 ====

void _DrawBlocksToComp(void)

{
  undefined4 *puVar1;
  undefined *puVar2;
  int iVar3;
  undefined1 local_24 [20];
  
  if (_gNumActiveBlocks != 0) {
    iVar3 = 0;
    puVar1 = (undefined4 *)(PTR__block_00034224 + 0xe);
    puVar2 = PTR__block_00034224;
    do {
      if (*(char *)((int)puVar1 + -0xe) != '\0') {
        if (*(short *)(puVar1 + 4) != -1) {
          _SpriteToComp(0,(int)*(short *)((int)puVar1 + -6),(int)*(short *)(puVar1 + -2),
                        (int)*(short *)(puVar1 + 4),(int)*(short *)((int)puVar1 + 0x12),1);
        }
        _UnionRect(puVar2 + 0xe,puVar2 + 6,local_24);
        _AddRectToScreen(local_24);
        *puVar1 = puVar1[-2];
        puVar1[1] = puVar1[-1];
        if (*(char *)((int)puVar1 + 0x1a) != '\0') {
          *(undefined1 *)((int)puVar1 + -0xe) = 0;
          _gNumActiveBlocks = _gNumActiveBlocks + -1;
        }
      }
      iVar3 = iVar3 + 1;
      puVar2 = puVar2 + 0x34;
      puVar1 = puVar1 + 0xd;
    } while (iVar3 != 0x23);
  }
  return;
}


// ==== _RegenerateBlocks @ 0001c3db ====

void _RegenerateBlocks(void)

{
  bool bVar1;
  undefined *puVar2;
  char cVar3;
  char cVar4;
  short sVar5;
  short sVar6;
  int iVar7;
  char local_2d;
  short local_24;
  short local_22;
  short local_20;
  short local_1e;
  
  sVar5 = _GetCurrLevelNum();
  local_2d = '\x06';
  do {
    cVar3 = _GetRandomFast(1,0xe);
    cVar4 = _GetRandomFast(1,9);
    puVar2 = PTR__gMaze_0003f054;
    bVar1 = false;
    do {
      do {
        cVar3 = cVar3 + '\x01';
        if ('\x0e' < cVar3) {
          cVar4 = cVar4 + '\x01';
          if (cVar4 < '\n') {
            cVar3 = '\x01';
          }
          else {
            if (bVar1) goto LAB_0001c532;
            cVar3 = '\x01';
            cVar4 = '\x01';
            bVar1 = true;
          }
        }
      } while ((cVar3 == PTR__hero_0003f014[0x28]) || (cVar4 == PTR__hero_0003f014[0x34]));
      iVar7 = cVar4 * 0x10;
    } while ((PTR__gMaze_0003f054[cVar3 + iVar7] != '\0') ||
            (PTR__gMazeCopy_0003f084[cVar3 + iVar7] != '\n'));
    if (sVar5 < 0xb) {
      PTR__gMaze_0003f054[cVar3 + iVar7] = 0xf;
    }
    else {
      sVar6 = _GetRandomFast(0,1);
      puVar2[cVar3 + iVar7] = ~-(sVar6 == 0) + 0x10;
    }
    local_22 = cVar3 * 0x28;
    local_24 = cVar4 * 0x28;
    local_1e = local_22 + 0x28;
    local_20 = local_24 + 0x28;
    _AddRectToBgnd(&local_24);
    _AddRectToScreen(&local_24);
    _MyInsetRect(&local_24,3,3);
    cVar3 = _WasEnemySquished(&local_24);
    if (cVar3 != -1) {
      _SquishEnemy((int)cVar3,1);
    }
LAB_0001c532:
    local_2d = local_2d + -1;
    if (local_2d == '\0') {
      return;
    }
  } while( true );
}


// ==== _PositionSingleJewel @ 0001c544 ====

void _PositionSingleJewel(char param_1)

{
  bool bVar1;
  undefined *puVar2;
  char cVar3;
  char cVar4;
  char *pcVar5;
  short sVar6;
  int iVar7;
  short local_20;
  
  cVar3 = _GetRandomFast(1,0xe);
  cVar4 = _GetRandomFast(1,9);
  local_20 = 0;
  iVar7 = (int)cVar4;
  do {
    local_20 = local_20 + 1;
    if (PTR__gMaze_0003f054[(int)cVar3 + iVar7 * 0x10] == '\n') {
      if ((cVar3 == '\a') && (cVar4 == '\x06')) {
        bVar1 = true;
      }
      else {
        bVar1 = false;
      }
      pcVar5 = PTR__gMaze_0003f054 + iVar7 * 0x10;
      sVar6 = 0x10;
      do {
        if (*pcVar5 == '\x14') {
          if (local_20 < 0x97) {
            bVar1 = true;
          }
          break;
        }
        pcVar5 = pcVar5 + 1;
        sVar6 = sVar6 + -1;
      } while (sVar6 != 0);
      pcVar5 = PTR__gMaze_0003f054 + cVar3;
      sVar6 = 0xb;
      do {
        if (*pcVar5 == '\x14') {
          if (local_20 < 0x97) goto LAB_0001c621;
          break;
        }
        pcVar5 = pcVar5 + 0x10;
        sVar6 = sVar6 + -1;
      } while (sVar6 != 0);
      if (!bVar1) {
        PTR__gMaze_0003f054[(int)cVar3 + iVar7 * 0x10] = 0x14;
        puVar2 = PTR__jewel_00034214;
        PTR__jewel_00034214[param_1 * 2] = cVar3;
        puVar2[param_1 * 2 + 1] = cVar4;
        return;
      }
    }
LAB_0001c621:
    if (local_20 < 0x1f5) {
      cVar3 = cVar3 + '\x01';
      if ('\x0e' < cVar3) {
        cVar4 = cVar4 + '\x01';
        if (cVar4 < '\n') {
          cVar3 = '\x01';
          iVar7 = (int)cVar4;
        }
        else {
          cVar3 = '\x01';
          cVar4 = '\x01';
          iVar7 = 1;
        }
      }
    }
    else {
      cVar3 = cVar3 + '\x01';
      if ('\x0f' < cVar3) {
        cVar4 = cVar4 + '\x01';
        if (cVar4 < '\v') {
          cVar3 = '\0';
          iVar7 = (int)cVar4;
        }
        else {
          cVar3 = '\0';
          cVar4 = '\0';
          iVar7 = 0;
        }
      }
    }
  } while( true );
}


// ==== _PositionJewels @ 0001c6a6 ====

void _PositionJewels(void)

{
  undefined *puVar1;
  short sVar2;
  
  *PTR__gJewelFound_00034218 = 0;
  *PTR__gTargetJewelXLoc_00034220 = 0xff;
  *PTR__gTargetJewelYLoc_00034210 = 0xff;
  *PTR__gJewelCount_0003422c = 0;
  puVar1 = PTR__gNumJewels_0003421c;
  *PTR__gNumJewels_0003421c = (char)*(undefined2 *)(PTR__level_0003f010 + 0x18);
  for (sVar2 = 0; sVar2 < (char)*puVar1; sVar2 = sVar2 + 1) {
    _PositionSingleJewel((int)(char)sVar2);
  }
  return;
}


// ==== _Jewels_TurnToBlocks @ 0001c705 ====

void _Jewels_TurnToBlocks(void)

{
  char *pcVar1;
  short sVar2;
  int local_34;
  short local_2e;
  short local_24;
  short local_22;
  short local_20;
  short local_1e;
  
  if (*PTR__gJewelsDone_0003420c == '\0') {
    local_34 = 0;
    local_2e = 0;
    do {
      pcVar1 = PTR__gMaze_0003f054 + local_34 * 0x10;
      sVar2 = 0;
      do {
        if ((*pcVar1 == '\x14') || (*pcVar1 == '\x1e')) {
          *pcVar1 = '\n';
          local_24 = local_2e;
          local_1e = sVar2 + 0x28;
          local_22 = sVar2;
          local_20 = local_2e + 0x28;
          _AddRectToBgnd(&local_24);
          _AddRectToScreen(&local_24);
          _NewStarGroup((int)local_22,(int)local_24,0);
        }
        pcVar1 = pcVar1 + 1;
        sVar2 = sVar2 + 0x28;
      } while (sVar2 != 0x280);
      local_34 = local_34 + 1;
      local_2e = local_2e + 0x28;
    } while (local_34 != 0xb);
    *PTR__gJewelsDone_0003420c = 1;
  }
  return;
}


// ==== _Jewels_GiveBonus @ 0001c7c5 ====

void _Jewels_GiveBonus(void)

{
  bool bVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined2 uVar4;
  char *pcVar5;
  undefined4 uVar6;
  
  if ((*PTR__gTargetJewelXLoc_00034220 == '\0') || (*PTR__gTargetJewelXLoc_00034220 == '\x0f')) {
    bVar1 = true;
  }
  else {
    bVar1 = false;
  }
  if (((*PTR__gTargetJewelYLoc_00034210 == '\0') || (*PTR__gTargetJewelYLoc_00034210 == '\n')) ||
     (bVar1)) {
    pcVar5 = (char *)0x3e8;
    uVar6 = 10;
  }
  else {
    uVar4 = _GetLevel();
    switch(uVar4) {
    default:
      pcVar5 = (char *)0x2710;
      uVar6 = 0x14;
      break;
    case 1:
      pcVar5 = "";
      uVar6 = 0xf;
      break;
    case 2:
      pcVar5 = "ersions/A/ASWAppKit";
      uVar6 = 0x10;
      break;
    case 3:
      pcVar5 = "";
      uVar6 = 0x11;
      break;
    case 4:
      pcVar5 = "";
      uVar6 = 0x12;
      break;
    case 5:
      pcVar5 = (char *)0x2328;
      uVar6 = 0x13;
    }
  }
  _PlayMySnd(0x21,0x14,0);
  _AddToScore(pcVar5,1);
  puVar3 = PTR__gTargetJewelXLoc_00034220;
  puVar2 = PTR__gTargetJewelYLoc_00034210;
  _NewStarGroup((char)*PTR__gTargetJewelXLoc_00034220 * 0x28,
                (char)*PTR__gTargetJewelYLoc_00034210 * 0x28,2);
  _NewPoint((char)*puVar3 * 0x28,(char)*puVar2 * 0x28,uVar6,10);
  *PTR__gJewelsDone_0003420c = 1;
  _Balloons_CaptureAllEnemies();
  return;
}


// ==== _IsJewelTheTarget @ 0001c8fb ====

undefined4 _IsJewelTheTarget(char param_1,char param_2,char param_3)

{
  if (*PTR__gJewelFound_00034218 != '\0') {
    if (param_1 == '\x03') {
      param_2 = param_2 + -1;
    }
    else if (param_1 == '\x04') {
      param_2 = param_2 + '\x01';
    }
    else if (param_1 == '\x01') {
      param_3 = param_3 + -1;
    }
    else if (param_1 == '\x02') {
      param_3 = param_3 + '\x01';
    }
    if ((param_2 == *PTR__gTargetJewelXLoc_00034220) && (param_3 == *PTR__gTargetJewelYLoc_00034210)
       ) {
      return 1;
    }
  }
  return 0;
}


// ==== _IsJewelTheDistantTarget @ 0001c95a ====

undefined4 _IsJewelTheDistantTarget(char param_1,char param_2,char param_3)

{
  if (*PTR__gJewelFound_00034218 != '\0') {
    if (param_1 == '\x03') {
      param_2 = param_2 + -2;
    }
    else if (param_1 == '\x04') {
      param_2 = param_2 + '\x02';
    }
    else if (param_1 == '\x01') {
      param_3 = param_3 + -2;
    }
    else if (param_1 == '\x02') {
      param_3 = param_3 + '\x02';
    }
    if ((param_2 == *PTR__gTargetJewelXLoc_00034220) && (param_3 == *PTR__gTargetJewelYLoc_00034210)
       ) {
      return 1;
    }
  }
  return 0;
}


// ==== _IsTargetJewelFound @ 0001c9b9 ====

undefined1 _IsTargetJewelFound(void)

{
  return *PTR__gJewelFound_00034218;
}


// ==== _IsActiveBombBlock @ 0001c9c6 ====

undefined4 _IsActiveBombBlock(char param_1,char param_2)

{
  char *pcVar1;
  
  pcVar1 = PTR__block_00034224;
  while ((((*pcVar1 == '\0' || (pcVar1[4] != '4')) || (pcVar1[0x17] != param_1)) ||
         (pcVar1[0x18] != param_2))) {
    pcVar1 = pcVar1 + 0x34;
    if (PTR__block_00034224 + 0x71c == pcVar1) {
      return 0;
    }
  }
  return 1;
}


// ==== _CheckJewelMovement @ 0001ca05 ====

void _CheckJewelMovement(char param_1,char param_2,char param_3)

{
  char cVar1;
  undefined *puVar2;
  char cVar3;
  int iVar4;
  int iVar5;
  int iVar6;
  
  iVar5 = (int)param_1;
  cVar1 = PTR__block_00034224[iVar5 * 0x34 + 0x16];
  iVar6 = (int)param_3;
  iVar4 = (int)param_2;
  if (PTR__gMaze_0003f054[iVar4 + iVar6 * 0x10] == '\x1e') {
    cVar1 = *PTR__gJewelCount_0003422c;
    *PTR__gJewelCount_0003422c = cVar1 + '\x01';
    puVar2 = PTR__level_0003f010;
    if ((int)(char)(cVar1 + '\x01') < (char)*PTR__gNumJewels_0003421c + -1) {
      if ((short)(char)*PTR__gNumEnemiesActive_0003f088 < *(short *)(PTR__level_0003f010 + 0xe)) {
        *(short *)(PTR__level_0003f010 + 0xc) = *(short *)(PTR__level_0003f010 + 0xc) + 1;
        *(short *)(puVar2 + 0x2a) = *(short *)(puVar2 + 0x2a) + 1;
      }
      _NewStarGroup((char)*PTR__gTargetJewelXLoc_00034220 * 0x28,
                    (char)*PTR__gTargetJewelYLoc_00034210 * 0x28,0);
      _PlayMySnd(9,0x14,0);
    }
    else {
      _Jewels_GiveBonus();
    }
    PTR__block_00034224[iVar5 * 0x34 + 0x28] = 1;
    return;
  }
  if (PTR__gMaze_0003f054[iVar4 + iVar6 * 0x10] == '\x14') {
    if (*PTR__gJewelFound_00034218 == '\0') {
      *PTR__gJewelFound_00034218 = 1;
      *PTR__gTargetJewelXLoc_00034220 = param_2;
      *PTR__gTargetJewelYLoc_00034210 = param_3;
      PTR__block_00034224[iVar5 * 0x34 + 4] = 0x1e;
      _NewBlock(iVar4,iVar6,1,0x1e,0,1);
    }
    cVar1 = *PTR__gJewelCount_0003422c;
    *PTR__gJewelCount_0003422c = cVar1 + '\x01';
    puVar2 = PTR__level_0003f010;
    if ((int)(char)(cVar1 + '\x01') < (char)*PTR__gNumJewels_0003421c + -1) {
      if ((short)(char)*PTR__gNumEnemiesActive_0003f088 < *(short *)(PTR__level_0003f010 + 0xe)) {
        *(short *)(PTR__level_0003f010 + 0xc) = *(short *)(PTR__level_0003f010 + 0xc) + 1;
        *(short *)(puVar2 + 0x2a) = *(short *)(puVar2 + 0x2a) + 1;
      }
      _NewStarGroup((char)*PTR__gTargetJewelXLoc_00034220 * 0x28,
                    (char)*PTR__gTargetJewelYLoc_00034210 * 0x28,0);
      _PlayMySnd(9,0x14,0);
    }
    else {
      _Jewels_GiveBonus();
    }
  }
  else {
    cVar3 = _GetNextObject((int)cVar1,iVar4,iVar6);
    if (cVar3 == '\0') {
      return;
    }
    if (cVar3 == 'P') {
      return;
    }
    if (((((cVar3 != '\n') && (cVar3 != '2')) && (cVar3 != '(')) &&
        ((cVar3 != '<' && (cVar3 != '\x0f')))) &&
       ((cVar3 != '\x10' && ((cVar3 != '3' && (cVar3 != '4')))))) {
      if ((cVar3 != '\x14') && (cVar3 != '\x1e')) {
        return;
      }
      if (*PTR__gJewelFound_00034218 == '\0') {
        return;
      }
      if (cVar1 == '\x03') {
        param_2 = param_2 + -1;
      }
      else if (cVar1 == '\x04') {
        param_2 = param_2 + '\x01';
      }
      else if (cVar1 == '\x01') {
        param_3 = param_3 + -1;
      }
      else if (cVar1 == '\x02') {
        param_3 = param_3 + '\x01';
      }
      if ((param_2 == *PTR__gTargetJewelXLoc_00034220) &&
         (param_3 == *PTR__gTargetJewelYLoc_00034210)) {
        return;
      }
    }
  }
  puVar2 = PTR__block_00034224;
  PTR__block_00034224[iVar5 * 0x34 + 0x28] = 1;
  PTR__gMaze_0003f054[iVar4 + iVar6 * 0x10] = puVar2[iVar5 * 0x34 + 4];
  return;
}


// ==== _MoveBlock @ 0001cccb ====

void _MoveBlock(char param_1)

{
  int iVar1;
  char cVar2;
  short sVar3;
  undefined *puVar4;
  undefined *puVar5;
  char cVar6;
  int iVar7;
  short sVar8;
  int iVar9;
  int iVar10;
  bool bVar11;
  bool bVar12;
  undefined4 local_24;
  undefined4 local_20;
  
  iVar10 = (int)param_1;
  iVar1 = iVar10 * 0x34;
  if (((PTR__block_00034224[iVar1 + 4] == '\x14') || (PTR__block_00034224[iVar1 + 4] == '\x1e')) &&
     (iVar7 = _TimeBonus_GetBonus(), puVar4 = PTR__block_00034224, iVar7 < 1)) {
    PTR__block_00034224[iVar1 + 4] = 10;
    puVar4[iVar1] = 1;
    puVar4[iVar1 + 0x1a] = 1;
    *(undefined2 *)(puVar4 + iVar1 + 0x1e) = 0x11;
    *(undefined2 *)(puVar4 + iVar1 + 0x20) = 1;
  }
  puVar4 = PTR__block_00034224;
  if (PTR__block_00034224[iVar10 * 0x34 + 0x2c] == '\0') {
    cVar6 = PTR__block_00034224[iVar10 * 0x34 + 0x16];
    if (cVar6 == '\x02') {
      _MyOffsetRect(PTR__block_00034224 + iVar10 * 0x34 + 6,0,10);
      cVar6 = puVar4[iVar10 * 0x34 + 0x1c];
      puVar4[iVar10 * 0x34 + 0x1c] = cVar6 + '\n';
      if ((char)(cVar6 + '\n') == '(') {
        puVar4[iVar10 * 0x34 + 0x18] = puVar4[iVar10 * 0x34 + 0x18] + '\x01';
LAB_0001ce27:
        puVar4[iVar10 * 0x34 + 0x1c] = 0;
      }
    }
    else if (cVar6 < '\x03') {
      if (cVar6 == '\x01') {
        _MyOffsetRect(PTR__block_00034224 + iVar10 * 0x34 + 6,0,0xfffffff6);
        cVar6 = puVar4[iVar10 * 0x34 + 0x1c];
        puVar4[iVar10 * 0x34 + 0x1c] = cVar6 + -10;
        if ((char)(cVar6 + -10) == -0x28) {
          puVar4[iVar10 * 0x34 + 0x18] = puVar4[iVar10 * 0x34 + 0x18] + -1;
          goto LAB_0001ce27;
        }
      }
    }
    else if (cVar6 == '\x03') {
      _MyOffsetRect(PTR__block_00034224 + iVar10 * 0x34 + 6,0xfffffff6,0);
      cVar6 = puVar4[iVar10 * 0x34 + 0x1b];
      puVar4[iVar10 * 0x34 + 0x1b] = cVar6 + -10;
      if ((char)(cVar6 + -10) == -0x28) {
        puVar4[iVar10 * 0x34 + 0x17] = puVar4[iVar10 * 0x34 + 0x17] + -1;
LAB_0001cdc7:
        puVar4[iVar10 * 0x34 + 0x1b] = 0;
      }
    }
    else if (cVar6 == '\x04') {
      _MyOffsetRect(PTR__block_00034224 + iVar10 * 0x34 + 6,10,0);
      cVar6 = puVar4[iVar10 * 0x34 + 0x1b];
      puVar4[iVar10 * 0x34 + 0x1b] = cVar6 + '\n';
      if ((char)(cVar6 + '\n') == '(') {
        puVar4[iVar10 * 0x34 + 0x17] = puVar4[iVar10 * 0x34 + 0x17] + '\x01';
        goto LAB_0001cdc7;
      }
    }
  }
  puVar4 = PTR__block_00034224;
  iVar1 = iVar10 * 0x34;
  PTR__block_00034224[iVar1 + 0x19] = 0;
  if ((puVar4[iVar1 + 0x1b] == '\0') && (puVar4[iVar1 + 0x1c] == '\0')) {
    puVar4[iVar1 + 0x19] = 1;
  }
  iVar1 = iVar10 * 0x34;
  local_24 = *(undefined4 *)(PTR__block_00034224 + iVar1 + 6);
  local_20 = *(undefined4 *)(PTR__block_00034224 + iVar1 + 10);
  _MyInsetRect(&local_24,3,3);
  cVar6 = _WasEnemySquished(&local_24);
  puVar4 = PTR__block_00034224;
  if (cVar6 != -1) {
    cVar2 = PTR__block_00034224[iVar1 + 0x1d];
    PTR__block_00034224[iVar1 + 0x1d] = cVar2 + '\x01';
    _SquishEnemy((int)cVar6,(int)(char)(cVar2 + '\x01'));
  }
  cVar6 = _IsHeroCaught(*(undefined4 *)(PTR__block_00034224 + iVar1 + 6),
                        *(undefined4 *)(PTR__block_00034224 + iVar1 + 10),1,0);
  if (cVar6 != '\0') {
    _HeroCaught(2);
  }
  _Balloons_CheckSquishes(&local_24);
  _Bonus_WasHit(&local_24);
  if (puVar4[iVar1 + 0x19] == '\0') {
    return;
  }
  if (PTR__block_00034224[iVar1 + 4] == '\x14') {
    _CheckJewelMovement(iVar10,(int)(char)puVar4[iVar1 + 0x17],(int)(char)puVar4[iVar1 + 0x18]);
    return;
  }
  iVar9 = (int)(char)puVar4[iVar1 + 0x18];
  iVar7 = (int)(char)puVar4[iVar1 + 0x17];
  cVar6 = _GetNextObject((int)(char)puVar4[iVar1 + 0x16],iVar7,iVar9);
  puVar5 = PTR__block_00034224;
  if (((cVar6 == '\0') || (cVar6 == 'P')) && (puVar4[iVar1 + 0x2c] == '\0')) {
    return;
  }
  iVar1 = iVar10 * 0x34;
  cVar6 = PTR__block_00034224[iVar1 + 4];
  if (1 < (byte)(cVar6 - 0xfU)) {
    PTR__block_00034224[iVar1 + 0x28] = 1;
    PTR__gMaze_0003f054[iVar7 + iVar9 * 0x10] = cVar6;
    if (cVar6 != '4') {
      return;
    }
    _ExplodeBombBlock(iVar10);
    return;
  }
  PTR__block_00034224[iVar1 + 0x2c] = 1;
  sVar3 = *(short *)(puVar5 + iVar1 + 0x30);
  sVar8 = sVar3 + 1;
  *(short *)(puVar5 + iVar1 + 0x30) = sVar8;
  puVar4 = PTR__block_00034224;
  cVar6 = puVar5[iVar1 + 0x16];
  if (cVar6 == '\x02') {
    if (sVar8 == 2) {
      *(undefined2 *)(puVar5 + iVar1 + 0x20) = 5;
      return;
    }
    if (sVar8 < 3) {
      if (sVar3 != 0) {
code_r0x0001d049:
        *(undefined2 *)(PTR__block_00034224 + iVar10 * 0x34 + 0x20) = 1;
        puVar4[iVar10 * 0x34 + 0x2c] = 0;
        puVar4[iVar10 * 0x34 + 0x28] = 1;
        return;
      }
LAB_0001d108:
      *(undefined2 *)(puVar5 + iVar1 + 0x20) = 4;
      return;
    }
    if (sVar8 == 3) {
      _PlayMySnd(0x14,10,0);
      goto LAB_0001d108;
    }
    if (sVar8 != 4) goto code_r0x0001d049;
    *(undefined2 *)(puVar5 + iVar1 + 0x20) = 1;
    puVar5[iVar1 + 0x16] = 1;
  }
  else if (cVar6 < '\x03') {
    if (cVar6 != '\x01') {
      return;
    }
    if (sVar8 == 2) {
      *(undefined2 *)(puVar5 + iVar1 + 0x20) = 3;
      return;
    }
    if (sVar8 < 3) {
      if (sVar3 != 0) goto code_r0x0001d049;
LAB_0001d083:
      *(undefined2 *)(puVar5 + iVar1 + 0x20) = 2;
      return;
    }
    if (sVar8 == 3) {
      _PlayMySnd(0x14,10,0);
      goto LAB_0001d083;
    }
    if (sVar8 != 4) goto code_r0x0001d049;
    *(undefined2 *)(puVar5 + iVar1 + 0x20) = 1;
    puVar5[iVar1 + 0x16] = 2;
  }
  else {
    if (cVar6 != '\x03') {
      if (cVar6 != '\x04') {
        return;
      }
      if (sVar8 == 2) {
        *(undefined2 *)(puVar5 + iVar1 + 0x20) = 9;
        return;
      }
      if (sVar8 < 3) {
        if (sVar3 != 0) goto code_r0x0001d049;
LAB_0001d216:
        *(undefined2 *)(puVar5 + iVar1 + 0x20) = 8;
        return;
      }
      if (sVar8 == 3) {
        _PlayMySnd(0x14,10,0);
        goto LAB_0001d216;
      }
      if (sVar8 != 4) goto code_r0x0001d049;
      *(undefined2 *)(puVar5 + iVar1 + 0x20) = 1;
      puVar5[iVar1 + 0x16] = 3;
      puVar5[iVar1 + 0x2c] = 0;
      *(undefined2 *)(puVar5 + iVar1 + 0x30) = 0;
      sVar3 = *(short *)(puVar5 + iVar1 + 0x2e);
      sVar8 = sVar3 + 1;
      *(short *)(puVar5 + iVar1 + 0x2e) = sVar8;
      if (PTR__block_00034224[iVar1 + 4] == '\x0f') {
        bVar12 = SBORROW2(sVar8,1);
        bVar11 = sVar3 == 0;
      }
      else {
        bVar12 = SBORROW2(sVar8,2);
        sVar3 = sVar3 + -1;
        bVar11 = sVar8 == 2;
      }
      if (bVar11 || bVar12 != sVar3 < 0) {
        return;
      }
      goto LAB_0001d25f;
    }
    if (sVar8 == 2) {
      *(undefined2 *)(puVar5 + iVar1 + 0x20) = 7;
      return;
    }
    if (sVar8 < 3) {
      if (sVar3 != 0) goto code_r0x0001d049;
LAB_0001d16f:
      *(undefined2 *)(puVar5 + iVar1 + 0x20) = 6;
      return;
    }
    if (sVar8 == 3) {
      _PlayMySnd(0x14,10,0);
      goto LAB_0001d16f;
    }
    if (sVar8 != 4) goto code_r0x0001d049;
    *(undefined2 *)(puVar5 + iVar1 + 0x20) = 1;
    puVar5[iVar1 + 0x16] = 4;
  }
  puVar5[iVar1 + 0x2c] = 0;
  *(undefined2 *)(puVar5 + iVar1 + 0x30) = 0;
  sVar3 = *(short *)(puVar5 + iVar1 + 0x2e);
  sVar8 = sVar3 + 1;
  *(short *)(puVar5 + iVar1 + 0x2e) = sVar8;
  if (PTR__block_00034224[iVar1 + 4] == '\x0f') {
    bVar12 = SBORROW2(sVar8,1);
    bVar11 = sVar8 == 1;
  }
  else {
    bVar12 = SBORROW2(sVar8,2);
    sVar3 = sVar3 + -1;
    bVar11 = sVar3 == 0;
  }
  _PlayMySnd(0x14,10,0);
  if (bVar11 || bVar12 != sVar3 < 0) {
    return;
  }
LAB_0001d25f:
  puVar4 = PTR__block_00034224;
  PTR__block_00034224[iVar10 * 0x34 + 0x28] = 1;
  PTR__gMaze_0003f054[iVar7 + iVar9 * 0x10] = puVar4[iVar10 * 0x34 + 4];
  return;
}


// ==== _ProcessBlocks @ 0001d2b8 ====

void _ProcessBlocks(void)

{
  char cVar1;
  short sVar2;
  int iVar3;
  uint uVar4;
  char cVar5;
  short *psVar6;
  int iVar7;
  char *pcVar8;
  int local_5c;
  int local_58;
  int local_54;
  char acStack_3f [47];
  
  iVar3 = 0;
  do {
    acStack_3f[iVar3] = '\0';
    iVar3 = iVar3 + 1;
  } while (iVar3 != 0x23);
  if (_gNumActiveBlocks != 0) {
    iVar3 = 0;
    psVar6 = (short *)(PTR__block_00034224 + 0x2a);
    local_5c = 0;
    pcVar8 = PTR__block_00034224;
    do {
      if ((char)psVar6[-0x15] != '\0') {
        _AddRectToBgnd(pcVar8 + local_5c + 0xe);
        if ((char)psVar6[-8] != '\0') {
          _MoveBlock(iVar3);
        }
        cVar5 = (char)psVar6[-0x13];
        if (cVar5 == '(') {
          sVar2 = psVar6[-5];
          psVar6[-5] = sVar2 + 1;
          pcVar8 = PTR__block_00034224;
          if (8 < (short)(sVar2 + 1)) {
            *(undefined1 *)(psVar6 + -1) = 1;
            PTR__gMaze_0003f054[(int)*(char *)((int)psVar6 + -0x13) + (char)psVar6[-9] * 0x10] = 0;
            pcVar8 = PTR__block_00034224;
          }
        }
        else {
          pcVar8 = PTR__block_00034224;
          if (cVar5 < ')') {
            if ((cVar5 == '\x1e') &&
               (sVar2 = psVar6[-2], psVar6[-2] = sVar2 + 1, pcVar8 = PTR__block_00034224,
               4 < (short)(sVar2 + 1))) {
              psVar6[-2] = 0;
              if (*PTR__gJewelAnimDir_00034228 == '\0') {
                sVar2 = psVar6[-5];
                psVar6[-5] = sVar2 + -1;
                pcVar8 = PTR__block_00034224;
                if ((short)(sVar2 + -1) < 2) {
                  *PTR__gJewelAnimDir_00034228 = 1;
                  goto LAB_0001d3af;
                }
              }
              else {
                sVar2 = psVar6[-5];
                psVar6[-5] = sVar2 + 1;
                pcVar8 = PTR__block_00034224;
                if (3 < (short)(sVar2 + 1)) {
                  *PTR__gJewelAnimDir_00034228 = 0;
LAB_0001d3af:
                  pcVar8 = PTR__block_00034224;
                  if (*PTR__gJewelsDone_0003420c != '\0') {
                    *(undefined1 *)(psVar6 + -1) = 1;
                    psVar6[-5] = 1;
                    pcVar8 = PTR__block_00034224;
                  }
                }
              }
            }
          }
          else if (cVar5 == '4') {
            if ((char)psVar6[-8] == '\0') {
              PTR__gMaze_0003f054[(int)*(char *)((int)psVar6 + -0x13) + (char)psVar6[-9] * 0x10] =
                   0x34;
              uVar4 = _GetFrameCounter();
              if ((ushort)psVar6[-0x14] + 0x3c < (uVar4 & 0xffff)) {
                _ExplodeBombBlock(iVar3);
                pcVar8 = PTR__block_00034224;
              }
              else {
                sVar2 = psVar6[-2];
                psVar6[-2] = sVar2 + 1;
                pcVar8 = PTR__block_00034224;
                if (3 < (short)(sVar2 + 1)) {
                  psVar6[-2] = 0;
                  sVar2 = psVar6[-5];
                  psVar6[-5] = sVar2 + 1;
                  pcVar8 = PTR__block_00034224;
                  if (3 < (short)(sVar2 + 1)) {
                    psVar6[-5] = 2;
                    pcVar8 = PTR__block_00034224;
                  }
                }
              }
            }
          }
          else if (cVar5 == '<') {
            if ((char)psVar6[-0x15] == '\x03') {
              uVar4 = _GetFrameCounter();
              if ((int)(uVar4 & 0xffff) <
                  (int)((uint)(ushort)psVar6[-0x14] + (int)*(short *)(PTR__level_0003f010 + 0x10)))
              {
                sVar2 = psVar6[-2];
                psVar6[-2] = sVar2 + 1;
                if (8 < (short)(sVar2 + 1)) {
                  psVar6[-2] = 0;
                  *(bool *)(psVar6 + -3) = (char)psVar6[-3] == '\0';
                }
                if ((char)psVar6[-3] == '\0') {
                  psVar6[-6] = 0x11;
                  psVar6[-5] = 1;
                }
                else {
                  psVar6[-6] = 0x1f;
                  psVar6[-5] = (short)(char)PTR__enemy_0003f04c
                                            [*(char *)((int)psVar6 + -1) * 0x5c + 0x10];
                }
              }
              else {
                *(undefined1 *)(psVar6 + -0x15) = 4;
                sVar2 = _GetFrameCounter();
                psVar6[-0x14] = sVar2;
              }
            }
            pcVar8 = PTR__block_00034224;
            if (((char)psVar6[-0x15] == '\x04') &&
               (uVar4 = _GetFrameCounter(), pcVar8 = PTR__block_00034224,
               (int)((uint)(ushort)psVar6[-0x14] + (int)*psVar6) < (int)(uVar4 & 0xffff))) {
              *(undefined1 *)(psVar6 + -0x13) = 0x28;
              *(char *)(psVar6 + -0x15) = '\x02';
              sVar2 = _GetFrameCounter();
              psVar6[-0x14] = sVar2;
              psVar6[-6] = 0x18;
              psVar6[-5] = 1;
              PTR__gMaze_0003f054[(int)*(char *)((int)psVar6 + -0x13) + (char)psVar6[-9] * 0x10] =
                   0x28;
              _PlayMySnd(0x10,10,0);
              pcVar8 = PTR__block_00034224;
            }
          }
        }
      }
      iVar3 = iVar3 + 1;
      local_5c = local_5c + 0x34;
      psVar6 = psVar6 + 0x1a;
    } while (iVar3 != 0x23);
    local_54 = 0;
    local_58 = 0;
    do {
      if (((*pcVar8 != '\0') && (pcVar8[0x1a] != '\0')) && (pcVar8[0x28] == '\0')) {
        cVar5 = (char)local_54;
        do {
          cVar5 = cVar5 + '\x01';
          if ('\"' < cVar5) goto LAB_0001d6cc;
          iVar7 = (int)cVar5;
          iVar3 = iVar7 * 0x34;
        } while (((PTR__block_00034224[iVar3] == '\0') ||
                 (PTR__block_00034224[iVar3 + 0x1a] == '\0')) ||
                ((PTR__block_00034224[iVar3 + 0x28] != '\0' ||
                 (cVar1 = _RectsCollide(PTR__block_00034224 + local_58 + 6,
                                        PTR__block_00034224 + iVar3 + 6), cVar1 == '\0'))));
        if ((pcVar8[0x2c] == '\0') && (acStack_3f[local_54] == '\0')) {
          cVar5 = pcVar8[0x16];
          if (cVar5 == '\x02') {
            pcVar8[0x16] = '\x01';
          }
          else if (cVar5 < '\x03') {
            if (cVar5 == '\x01') {
              pcVar8[0x16] = '\x02';
            }
          }
          else if (cVar5 == '\x03') {
            pcVar8[0x16] = '\x04';
          }
          else if (cVar5 == '\x04') {
            pcVar8[0x16] = '\x03';
          }
        }
        if ((PTR__block_00034224[iVar7 * 0x34 + 0x2c] == '\0') && (acStack_3f[iVar7] == '\0')) {
          cVar5 = PTR__block_00034224[iVar7 * 0x34 + 0x16];
          if (cVar5 == '\x02') {
            PTR__block_00034224[iVar7 * 0x34 + 0x16] = 1;
          }
          else if (cVar5 < '\x03') {
            if (cVar5 == '\x01') {
              PTR__block_00034224[iVar7 * 0x34 + 0x16] = 2;
            }
          }
          else if (cVar5 == '\x03') {
            PTR__block_00034224[iVar7 * 0x34 + 0x16] = 4;
          }
          else if (cVar5 == '\x04') {
            PTR__block_00034224[iVar7 * 0x34 + 0x16] = 3;
          }
        }
        acStack_3f[iVar7] = '\x01';
        acStack_3f[local_54] = '\x01';
        _PlayMySnd(0x14,10,0);
      }
LAB_0001d6cc:
      local_54 = local_54 + 1;
      local_58 = local_58 + 0x34;
      pcVar8 = pcVar8 + 0x34;
    } while (local_54 != 0x23);
  }
  return;
}


// ==== _InitLetterRects @ 0001d6e9 ====

void _InitLetterRects(void)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined *puVar3;
  
  puVar2 = PTR__gLetters_00034230;
  puVar1 = PTR__gLetters_00034230 + 0x400;
  puVar3 = PTR__gLetters_00034230;
  do {
    _SetRect(puVar3,0,0,0,0);
    puVar3 = puVar3 + 8;
  } while (puVar1 != puVar3);
  _SetRect(puVar2 + 0x208,0,0,0xe,0x17);
  _SetRect(puVar2 + 0x210,0x15,0,0x22,0x17);
  _SetRect(puVar2 + 0x218,0x2a,0,0x38,0x17);
  _SetRect(puVar2 + 0x220,0x3f,0,0x4c,0x17);
  _SetRect(puVar2 + 0x228,0x54,0,0x60,0x17);
  _SetRect(puVar2 + 0x230,0x69,0,0x76,0x17);
  _SetRect(puVar2 + 0x238,0x7e,0,0x8f,0x17);
  _SetRect(puVar2 + 0x240,0x93,0,0xa0,0x17);
  _SetRect(puVar2 + 0x248,0xa8,0,0xb0,0x17);
  _SetRect(puVar2 + 0x250,0xbd,0,0xc9,0x17);
  _SetRect(puVar2 + 600,0xd2,0,0xe2,0x17);
  _SetRect(puVar2 + 0x260,0xe7,0,0xf2,0x17);
  _SetRect(puVar2 + 0x268,0xfc,0,0x111,0x17);
  _SetRect(puVar2 + 0x270,0x111,0,0x120,0x17);
  _SetRect(puVar2 + 0x278,0x126,0,0x135,0x17);
  _SetRect(puVar2 + 0x280,0x13b,0,0x14a,0x17);
  _SetRect(puVar2 + 0x288,0x150,0,0x160,0x17);
  _SetRect(puVar2 + 0x290,0x165,0,0x174,0x17);
  _SetRect(puVar2 + 0x298,0x17a,0,0x189,0x17);
  _SetRect(puVar2 + 0x2a0,399,0,0x19e,0x17);
  _SetRect(puVar2 + 0x2a8,0x1a4,0,0x1b4,0x17);
  _SetRect(puVar2 + 0x2b0,0x1b9,0,0x1c7,0x17);
  _SetRect(puVar2 + 0x2b8,0x1ce,0,0x1e3,0x17);
  _SetRect(puVar2 + 0x2c0,0x1e3,0,499,0x17);
  _SetRect(puVar2 + 0x2c8,0x1f8,0,0x208,0x17);
  _SetRect(puVar2 + 0x2d0,0x20d,0,0x21f,0x17);
  *(undefined4 *)(puVar2 + 0x308) = *(undefined4 *)(puVar2 + 0x208);
  *(undefined4 *)(puVar2 + 0x30c) = *(undefined4 *)(puVar2 + 0x20c);
  *(undefined4 *)(puVar2 + 0x310) = *(undefined4 *)(puVar2 + 0x210);
  *(undefined4 *)(puVar2 + 0x314) = *(undefined4 *)(puVar2 + 0x214);
  *(undefined4 *)(puVar2 + 0x318) = *(undefined4 *)(puVar2 + 0x218);
  *(undefined4 *)(puVar2 + 0x31c) = *(undefined4 *)(puVar2 + 0x21c);
  *(undefined4 *)(puVar2 + 800) = *(undefined4 *)(puVar2 + 0x220);
  *(undefined4 *)(puVar2 + 0x324) = *(undefined4 *)(puVar2 + 0x224);
  *(undefined4 *)(puVar2 + 0x328) = *(undefined4 *)(puVar2 + 0x228);
  *(undefined4 *)(puVar2 + 0x32c) = *(undefined4 *)(puVar2 + 0x22c);
  *(undefined4 *)(puVar2 + 0x330) = *(undefined4 *)(puVar2 + 0x230);
  *(undefined4 *)(puVar2 + 0x334) = *(undefined4 *)(puVar2 + 0x234);
  *(undefined4 *)(puVar2 + 0x338) = *(undefined4 *)(puVar2 + 0x238);
  *(undefined4 *)(puVar2 + 0x33c) = *(undefined4 *)(puVar2 + 0x23c);
  *(undefined4 *)(puVar2 + 0x340) = *(undefined4 *)(puVar2 + 0x240);
  *(undefined4 *)(puVar2 + 0x344) = *(undefined4 *)(puVar2 + 0x244);
  *(undefined4 *)(puVar2 + 0x348) = *(undefined4 *)(puVar2 + 0x248);
  *(undefined4 *)(puVar2 + 0x34c) = *(undefined4 *)(puVar2 + 0x24c);
  *(undefined4 *)(puVar2 + 0x350) = *(undefined4 *)(puVar2 + 0x250);
  *(undefined4 *)(puVar2 + 0x354) = *(undefined4 *)(puVar2 + 0x254);
  *(undefined4 *)(puVar2 + 0x358) = *(undefined4 *)(puVar2 + 600);
  *(undefined4 *)(puVar2 + 0x35c) = *(undefined4 *)(puVar2 + 0x25c);
  *(undefined4 *)(puVar2 + 0x360) = *(undefined4 *)(puVar2 + 0x260);
  *(undefined4 *)(puVar2 + 0x364) = *(undefined4 *)(puVar2 + 0x264);
  *(undefined4 *)(puVar2 + 0x368) = *(undefined4 *)(puVar2 + 0x268);
  *(undefined4 *)(puVar2 + 0x36c) = *(undefined4 *)(puVar2 + 0x26c);
  *(undefined4 *)(puVar2 + 0x370) = *(undefined4 *)(puVar2 + 0x270);
  *(undefined4 *)(puVar2 + 0x374) = *(undefined4 *)(puVar2 + 0x274);
  *(undefined4 *)(puVar2 + 0x378) = *(undefined4 *)(puVar2 + 0x278);
  *(undefined4 *)(puVar2 + 0x37c) = *(undefined4 *)(puVar2 + 0x27c);
  *(undefined4 *)(puVar2 + 0x380) = *(undefined4 *)(puVar2 + 0x280);
  *(undefined4 *)(puVar2 + 900) = *(undefined4 *)(puVar2 + 0x284);
  *(undefined4 *)(puVar2 + 0x388) = *(undefined4 *)(puVar2 + 0x288);
  *(undefined4 *)(puVar2 + 0x38c) = *(undefined4 *)(puVar2 + 0x28c);
  *(undefined4 *)(puVar2 + 0x390) = *(undefined4 *)(puVar2 + 0x290);
  *(undefined4 *)(puVar2 + 0x394) = *(undefined4 *)(puVar2 + 0x294);
  *(undefined4 *)(puVar2 + 0x398) = *(undefined4 *)(puVar2 + 0x298);
  *(undefined4 *)(puVar2 + 0x39c) = *(undefined4 *)(puVar2 + 0x29c);
  *(undefined4 *)(puVar2 + 0x3a0) = *(undefined4 *)(puVar2 + 0x2a0);
  *(undefined4 *)(puVar2 + 0x3a4) = *(undefined4 *)(puVar2 + 0x2a4);
  *(undefined4 *)(puVar2 + 0x3a8) = *(undefined4 *)(puVar2 + 0x2a8);
  *(undefined4 *)(puVar2 + 0x3ac) = *(undefined4 *)(puVar2 + 0x2ac);
  *(undefined4 *)(puVar2 + 0x3b0) = *(undefined4 *)(puVar2 + 0x2b0);
  *(undefined4 *)(puVar2 + 0x3b4) = *(undefined4 *)(puVar2 + 0x2b4);
  *(undefined4 *)(puVar2 + 0x3b8) = *(undefined4 *)(puVar2 + 0x2b8);
  *(undefined4 *)(puVar2 + 0x3bc) = *(undefined4 *)(puVar2 + 700);
  *(undefined4 *)(puVar2 + 0x3c0) = *(undefined4 *)(puVar2 + 0x2c0);
  *(undefined4 *)(puVar2 + 0x3c4) = *(undefined4 *)(puVar2 + 0x2c4);
  *(undefined4 *)(puVar2 + 0x3c8) = *(undefined4 *)(puVar2 + 0x2c8);
  *(undefined4 *)(puVar2 + 0x3cc) = *(undefined4 *)(puVar2 + 0x2cc);
  *(undefined4 *)(puVar2 + 0x3d0) = *(undefined4 *)(puVar2 + 0x2d0);
  *(undefined4 *)(puVar2 + 0x3d4) = *(undefined4 *)(puVar2 + 0x2d4);
  _SetRect(puVar2 + 0x188,5,0x17,0xc,0x2e);
  _SetRect(puVar2 + 400,0x15,0x17,0x23,0x2e);
  _SetRect(puVar2 + 0x198,0x2a,0x17,0x38,0x2e);
  _SetRect(puVar2 + 0x1a0,0x3f,0x17,0x51,0x2e);
  _SetRect(puVar2 + 0x1a8,0x54,0x17,0x62,0x2e);
  _SetRect(puVar2 + 0x1b0,0x69,0x17,0x77,0x2e);
  _SetRect(puVar2 + 0x1b8,0x7e,0x17,0x8d,0x2e);
  _SetRect(puVar2 + 0x1c0,0x93,0x17,0xa1,0x2e);
  _SetRect(puVar2 + 0x1c8,0xa8,0x17,0xb6,0x2e);
  _SetRect(puVar2 + 0x180,0xbd,0x17,0xca,0x2e);
  _SetRect(puVar2 + 0x160,0xd2,0x17,0xda,0x2e);
  _SetRect(puVar2 + 0x170,0xe7,0x17,0xee,0x2e);
  _SetRect(puVar2 + 0x178,0xfc,0x17,0x10b,0x2e);
  _SetRect(puVar2 + 0x1f8,0x111,0x17,0x11e,0x2e);
  _SetRect(puVar2 + 0x1d8,0x126,0x17,0x12e,0x2e);
  _SetRect(puVar2 + 0x1d0,0x13b,0x17,0x142,0x2e);
  _SetRect(puVar2 + 0x138,0x150,0x17,0x157,0x2e);
  _SetRect(puVar2 + 0x110,0x165,0x17,0x16f,0x2e);
  _SetRect(puVar2 + 0x108,0x17a,0x17,0x184,0x2e);
  _SetRect(puVar2 + 0x150,399,0x17,0x19e,0x2e);
  _SetRect(puVar2 + 0x140,0x1a4,0x17,0x1ae,0x2e);
  _SetRect(puVar2 + 0x148,0x1b9,0x17,0x1c3,0x2e);
  _SetRect(puVar2 + 0x168,0x1ce,0x17,0x1da,0x2e);
  _SetRect(puVar2 + 0x1e8,0x1e3,0x17,0x1ee,0x2e);
  _SetRect(puVar2 + 0x158,0x1f8,0x17,0x204,0x2e);
  _SetRect(puVar2 + 0x100,0x20d,0x17,0x214,0x2e);
  return;
}


// ==== _LoadLetters @ 0001e2ff ====

void _LoadLetters(void)

{
  undefined4 uVar1;
  undefined1 local_1c [8];
  undefined1 local_14 [8];
  
  _SetToSpriteGWorld();
  _ForeColor(0x21);
  _GetPortBounds(*(undefined4 *)PTR__gSpriteGWorld_0003f024,local_1c);
  _ClipRect(local_1c);
  _EraseRect(local_1c);
  uVar1 = _LoadPict(0x2329,local_14);
  _DrawPicture(uVar1,local_14);
  uVar1 = _LoadPict(0x232a,local_14);
  _OffsetRect(local_14,0,0x2e);
  _DrawPicture(uVar1,local_14);
  _SetToScreen();
  _InitLetterRects();
  return;
}


// ==== _GetLetterWidth @ 0001e3a4 ====

int _GetLetterWidth(char param_1)

{
  return (int)(short)(*(short *)(PTR__gLetters_00034230 + param_1 * 8 + 6) -
                     *(short *)(PTR__gLetters_00034230 + param_1 * 8 + 2));
}


// ==== _DrawLetter @ 0001e3be ====

void _DrawLetter(char param_1,ushort param_2,short param_3,undefined2 *param_4,char param_5)

{
  short sVar1;
  short sVar2;
  undefined *puVar3;
  int iVar4;
  int iVar5;
  undefined4 local_24;
  undefined4 local_20;
  
  puVar3 = PTR__gLetters_00034230;
  iVar4 = (int)param_1;
  iVar5 = (uint)param_2 +
          (uint)(ushort)(*(short *)(PTR__gLetters_00034230 + iVar4 * 8 + 6) -
                        *(short *)(PTR__gLetters_00034230 + iVar4 * 8 + 2));
  sVar1 = *(short *)(PTR__gLetters_00034230 + iVar4 * 8 + 4);
  sVar2 = *(short *)(PTR__gLetters_00034230 + iVar4 * 8);
  *param_4 = (short)iVar5;
  local_24 = *(undefined4 *)(puVar3 + iVar4 * 8);
  local_20 = *(undefined4 *)(puVar3 + iVar4 * 8 + 4);
  if (param_5 != '\0') {
    _OffsetRect(&local_24,0,0x2e);
  }
  _SetToSpriteGWorld();
  _ForeColor(0x21);
  _BackColor(0x1e);
  _SetToCompGWorld();
  _ForeColor(0x21);
  _BackColor(0x1e);
  _SpriteToCompTransparent
            (local_24,local_20,CONCAT22(param_2,param_3),
             (uint)(ushort)((sVar1 - sVar2) + param_3) | iVar5 * 0x10000,0);
  return;
}


// ==== _DrawCustomString @ 0001e4c0 ====

void _DrawCustomString(char *param_1,uint param_2,short param_3,undefined1 param_4,char param_5)

{
  char cVar1;
  char *pcVar2;
  short sVar3;
  ushort local_1e [7];
  
  if ((short)param_2 == -1) {
    sVar3 = 0;
    pcVar2 = param_1;
    while( true ) {
      cVar1 = *pcVar2;
      if (cVar1 == '\0') break;
      if (-1 < cVar1) {
        sVar3 = sVar3 + (*(short *)(PTR__gLetters_00034230 + cVar1 * 8 + 6) -
                        *(short *)(PTR__gLetters_00034230 + cVar1 * 8 + 2));
      }
      pcVar2 = pcVar2 + 1;
    }
    param_2 = (uint)((0x280 - sVar3) - (0x280 - sVar3 >> 0x1f)) >> 1;
  }
  while( true ) {
    cVar1 = *param_1;
    if (cVar1 == '\0') break;
    if (-1 < cVar1) {
      _DrawLetter((int)cVar1,(int)(short)param_2,(int)param_3,local_1e,param_4);
      if (param_5 == '\0') {
        param_2 = (uint)local_1e[0];
      }
      else {
        param_2 = param_2 + 0xf;
      }
    }
    param_1 = param_1 + 1;
  }
  return;
}


// ==== _GetWorldBgndBase @ 0001e57a ====

void _GetWorldBgndBase(void)

{
  undefined4 uVar1;
  
  if (_gBWCreated == '\0') {
    _StdError("Internal error: trying to get base before BG world created.",0);
    _CleanUp();
  }
  uVar1 = _GetGWorldPixMap(*(undefined4 *)PTR__gBgndGWorld_0003423c);
  _GetPixBaseAddr(uVar1);
  return;
}


// ==== _GetWorldBgndRB @ 0001e5bb ====

void _GetWorldBgndRB(void)

{
  undefined4 uVar1;
  
  if (_gBWCreated == '\0') {
    _StdError("Internal error: trying to get RB before BG world created.",0);
    _CleanUp();
  }
  uVar1 = _GetGWorldPixMap(*(undefined4 *)PTR__gBgndGWorld_0003423c);
  _GetPixRowBytes(uVar1);
  return;
}


// ==== _GetWorldCompBase @ 0001e5fc ====

void _GetWorldCompBase(void)

{
  undefined4 uVar1;
  
  if (_gBWCreated == '\0') {
    _StdError("Internal error: trying to get base before comp world created.",0);
    _CleanUp();
  }
  uVar1 = _GetGWorldPixMap(*(undefined4 *)PTR__gCompGWorld_00034244);
  _GetPixBaseAddr(uVar1);
  return;
}


// ==== _GetWorldCompRB @ 0001e63d ====

void _GetWorldCompRB(void)

{
  undefined4 uVar1;
  
  if (_gBWCreated == '\0') {
    _StdError("Internal error: trying to get RB before comp world created.",0);
    _CleanUp();
  }
  uVar1 = _GetGWorldPixMap(*(undefined4 *)PTR__gCompGWorld_00034244);
  _GetPixRowBytes(uVar1);
  return;
}


// ==== _DisposeGWorlds @ 0001e67e ====

void _DisposeGWorlds(void)

{
  undefined *puVar1;
  
  _Utils_Log("  About to dispose graphics worlds.");
  puVar1 = PTR__gCompGWorld_00034244;
  if (_gCWCreated != '\0') {
    _DisposeGWorld(*(undefined4 *)PTR__gCompGWorld_00034244);
    _Utils_Log("  Disposed comp world.");
    *(undefined4 *)puVar1 = 0;
  }
  puVar1 = PTR__gSpriteGWorld_00034248;
  if (_gSWCreated != '\0') {
    _DisposeGWorld(*(undefined4 *)PTR__gSpriteGWorld_00034248);
    _Utils_Log("  Disposed sprite world.");
    *(undefined4 *)puVar1 = 0;
  }
  puVar1 = PTR__gBgndGWorld_0003423c;
  if (_gBWCreated != '\0') {
    _DisposeGWorld(*(undefined4 *)PTR__gBgndGWorld_0003423c);
    _Utils_Log("  Disposed bgnd world.");
    *(undefined4 *)puVar1 = 0;
  }
  puVar1 = PTR__gScoreGWorld_00034240;
  if (_gScoreGWorldCreated != '\0') {
    _DisposeGWorld(*(undefined4 *)PTR__gScoreGWorld_00034240);
    _Utils_Log("  Disposed score world.");
    *(undefined4 *)puVar1 = 0;
  }
  puVar1 = PTR__gTransGWorld_0003424c;
  if (_gTWCreated != '\0') {
    _DisposeGWorld(*(undefined4 *)PTR__gTransGWorld_0003424c);
    _Utils_Log("  Disposed trans world.");
    *(undefined4 *)puVar1 = 0;
  }
  _Utils_Log("  Graphics worlds disposed.");
  return;
}


// ==== _CreateCompGWorld @ 0001e77a ====

void _CreateCompGWorld(void)

{
  undefined *puVar1;
  short sVar2;
  undefined4 uVar3;
  undefined1 local_14 [8];
  
  puVar1 = PTR__gCompGWorld_00034244;
  sVar2 = _NewGWorld(PTR__gCompGWorld_00034244,0,PTR__environment_0003f028 + 0x12,0,0,2);
  if (sVar2 != 0) {
    _ResultError(0x7d3,1,(int)sVar2);
  }
  _Utils_Log("  NewGWorld (comp) successful.");
  uVar3 = _GetGWorldPixMap(*(undefined4 *)puVar1);
  _LockPixels(uVar3);
  _SetGWorld(*(undefined4 *)puVar1,0);
  _ForeColor(0x21);
  _GetPortBounds(*(undefined4 *)puVar1,local_14);
  _ClipRect(local_14);
  _EraseRect(local_14);
  _Utils_Log("  \'comp\' world erased in black.");
  _gCWCreated = 1;
  return;
}


// ==== _CreateTransGWorld @ 0001e851 ====

void _CreateTransGWorld(void)

{
  undefined *puVar1;
  short sVar2;
  undefined4 uVar3;
  undefined1 local_1c [8];
  undefined1 local_14 [8];
  
  _SetRect(local_14,0,0,0x60,0x60);
  puVar1 = PTR__gTransGWorld_0003424c;
  sVar2 = _NewGWorld(PTR__gTransGWorld_0003424c,0x20,local_14,0,0,0x100);
  if (sVar2 != 0) {
    _StdError("Cannot create \'trans\' GWorld. Perhaps out of memory?",(int)sVar2);
  }
  _Utils_Log("  NewGWorld (trans) created.");
  uVar3 = _GetGWorldPixMap(*(undefined4 *)puVar1);
  _LockPixels(uVar3);
  _SetGWorld(*(undefined4 *)puVar1,0);
  _ForeColor(0x21);
  _GetPortBounds(*(undefined4 *)puVar1,local_1c);
  _ClipRect(local_1c);
  _EraseRect(local_1c);
  _Utils_Log("  \'trans\' world erased in black.");
  _gTWCreated = 1;
  return;
}


// ==== _CreateScoreGWorld @ 0001e943 ====

void _CreateScoreGWorld(void)

{
  undefined *puVar1;
  short sVar2;
  undefined4 uVar3;
  undefined1 local_1c [8];
  undefined1 local_14 [8];
  
  _SetRect(local_14,0,0,0x280,0x28);
  puVar1 = PTR__gScoreGWorld_00034240;
  sVar2 = _NewGWorld(PTR__gScoreGWorld_00034240,0,local_14,0,0,2);
  if (sVar2 != 0) {
    _ResultError(0x7d3,1,(int)sVar2);
  }
  _Utils_Log("  NewGWorld (score) successful.");
  uVar3 = _GetGWorldPixMap(*(undefined4 *)puVar1);
  _LockPixels(uVar3);
  _SetGWorld(*(undefined4 *)puVar1,0);
  _ForeColor(0x21);
  _GetPortBounds(*(undefined4 *)puVar1,local_1c);
  _ClipRect(local_1c);
  _EraseRect(local_1c);
  _Utils_Log("  \'score\' world erased in black.");
  _gScoreGWorldCreated = 1;
  return;
}


// ==== _CreateBgndGWorld @ 0001ea3d ====

void _CreateBgndGWorld(void)

{
  undefined *puVar1;
  short sVar2;
  undefined4 uVar3;
  undefined1 local_1c [8];
  undefined1 local_14 [8];
  
  _SetRect(local_14,0,0,0x280,0x1e0);
  puVar1 = PTR__gBgndGWorld_0003423c;
  sVar2 = _NewGWorld(PTR__gBgndGWorld_0003423c,0,local_14,0,0,2);
  if (sVar2 != 0) {
    _ResultError(0x7d3,3,(int)sVar2);
  }
  _Utils_Log("  NewGWorld (bgnd) successful.");
  uVar3 = _GetGWorldPixMap(*(undefined4 *)puVar1);
  _LockPixels(uVar3);
  _SetGWorld(*(undefined4 *)puVar1,0);
  _ForeColor(0x21);
  _GetPortBounds(*(undefined4 *)puVar1,local_1c);
  _ClipRect(local_1c);
  _EraseRect(local_1c);
  _Utils_Log("  \'bgnd\' world erased in black.");
  _gBWCreated = 1;
  return;
}


// ==== _CreateSpriteGWorld @ 0001eb37 ====

void _CreateSpriteGWorld(void)

{
  undefined *puVar1;
  undefined *puVar2;
  short sVar3;
  undefined4 uVar4;
  undefined1 local_1c [8];
  undefined4 local_14;
  undefined4 local_10;
  
  puVar1 = PTR__gTextRect_0003f08c;
  _SetRect(PTR__gTextRect_0003f08c,0x9d,0x1a9,0x1e2,0x1bd);
  puVar2 = PTR__gSrcTextRect_0003f090;
  *(undefined2 *)(PTR__gSrcTextRect_0003f090 + 2) = 0;
  *(undefined2 *)puVar2 = 0x5c;
  *(short *)(puVar2 + 6) = *(short *)(puVar1 + 6) - *(short *)(puVar1 + 2);
  sVar3 = (*(short *)(puVar1 + 4) - *(short *)puVar1) + 0x5c;
  *(short *)(puVar2 + 4) = sVar3;
  _SetRect(&local_14,0,0,0x222,(int)sVar3);
  puVar1 = PTR__gSpriteWorldRect_00034250;
  *(undefined4 *)PTR__gSpriteWorldRect_00034250 = local_14;
  *(undefined4 *)(puVar1 + 4) = local_10;
  puVar1 = PTR__gSpriteGWorld_00034248;
  sVar3 = _NewGWorld(PTR__gSpriteGWorld_00034248,0,&local_14,0,0,2);
  if (sVar3 != 0) {
    _ResultError(0x7d3,2,(int)sVar3);
  }
  _Utils_Log("  NewGWorld (sprite) successful.");
  uVar4 = _GetGWorldPixMap(*(undefined4 *)puVar1);
  _LockPixels(uVar4);
  _SetGWorld(*(undefined4 *)puVar1,0);
  _ForeColor(0x21);
  _GetPortBounds(*(undefined4 *)puVar1,local_1c);
  _ClipRect(local_1c);
  _EraseRect(local_1c);
  _Utils_Log("  \'sprite\' world erased in black.");
  _gSWCreated = 1;
  return;
}


// ==== _CreateGWorlds @ 0001ec98 ====

void _CreateGWorlds(void)

{
  _CreateCompGWorld();
  _Utils_Log("  \'comp\' world created successfully.");
  _CreateSpriteGWorld();
  _Utils_Log("  \'sprite\' world created successfully.");
  _CreateBgndGWorld();
  _Utils_Log("  \'bgnd\' world created successfully.");
  _CreateScoreGWorld();
  _Utils_Log("  \'score\' world created successfully.");
  _CreateTransGWorld();
  _Utils_Log("  \'trans\' world created successfully.");
  _InitScreenCopy();
  _Utils_Log("  Screen copy code completed.");
  _InitROCS();
  _Utils_Log("  ROCS initialisation completed.");
  return;
}


// ==== _SetToScreen @ 0001ed17 ====

void _SetToScreen(void)

{
  undefined4 uVar1;
  
  uVar1 = _GetWindowPort(*(undefined4 *)PTR__environment_0003f028);
  _SetGWorld(uVar1,0);
  return;
}


// ==== _SetToSpriteGWorld @ 0001ed3e ====

void _SetToSpriteGWorld(void)

{
  _SetGWorld(*(undefined4 *)PTR__gSpriteGWorld_00034248,0);
  return;
}


// ==== _SetToCompGWorld @ 0001ed5d ====

void _SetToCompGWorld(void)

{
  _SetGWorld(*(undefined4 *)PTR__gCompGWorld_00034244,0);
  return;
}


// ==== _SetToTransGWorld @ 0001ed7c ====

void _SetToTransGWorld(void)

{
  _SetGWorld(*(undefined4 *)PTR__gTransGWorld_0003424c,0);
  return;
}


// ==== _PaintCompGWorld @ 0001ed9b ====

void _PaintCompGWorld(void)

{
  undefined1 local_14 [12];
  
  _GetPortBounds(*(undefined4 *)PTR__gCompGWorld_00034244,local_14);
  _ForeColor(0x21);
  _PaintRect(local_14);
  return;
}


// ==== _SetToBgndGWorld @ 0001edd2 ====

void _SetToBgndGWorld(void)

{
  _SetGWorld(*(undefined4 *)PTR__gBgndGWorld_0003423c,0);
  return;
}


// ==== _PaintBgndGWorld @ 0001edf1 ====

void _PaintBgndGWorld(void)

{
  undefined1 local_14 [12];
  
  _GetPortBounds(*(undefined4 *)PTR__gBgndGWorld_0003423c,local_14);
  _ForeColor(0x21);
  _PaintRect(local_14);
  return;
}


// ==== _SetToScoreGWorld @ 0001ee28 ====

void _SetToScoreGWorld(void)

{
  _SetGWorld(*(undefined4 *)PTR__gScoreGWorld_00034240,0);
  return;
}


// ==== _PaintScoreGWorld @ 0001ee47 ====

void _PaintScoreGWorld(void)

{
  undefined1 local_14 [12];
  
  _GetPortBounds(*(undefined4 *)PTR__gScoreGWorld_00034240,local_14);
  _ForeColor(0x21);
  _PaintRect(local_14);
  return;
}


// ==== _EraseTransGWorld @ 0001ee7e ====

void _EraseTransGWorld(void)

{
  undefined2 local_14;
  undefined2 local_12;
  undefined2 local_10;
  undefined2 local_e;
  
  local_14 = 0;
  local_12 = 0;
  local_10 = 0x60;
  local_e = 0x60;
  _ForeColor(0x1e);
  _PaintRect(&local_14);
  return;
}


// ==== _PatternFillCompGWorld @ 0001eeb5 ====

void _PatternFillCompGWorld(void)

{
  _SetGWorld(*(undefined4 *)PTR__gCompGWorld_00034244,0);
  _DrawAndCentrePict();
  return;
}


// ==== _DrawCredit @ 0001eee4 ====

void _DrawCredit(short param_1)

{
  char *pcVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  
  _PatternFillCompGWorld(0x390);
  switch((int)param_1) {
  case 0:
    _DrawCustomString("Coding + Design Maestros",0xffffffff,200,1,0);
    _DrawCustomString("Alex Metcalf",0xffffffff,0xe6,0,0);
    uVar4 = 0;
    uVar3 = 0x104;
    uVar2 = 0xffffffff;
    pcVar1 = "David Wareing";
    break;
  case 1:
    _DrawCustomString("Title + Background Artwork",0xffffffff,0xd7,1,0);
    uVar4 = 0;
    uVar3 = 0xf5;
    uVar2 = 0xffffffff;
    pcVar1 = "Marcus Conge";
    break;
  case 2:
    _DrawCustomString("Sprite Artwork",0xffffffff,0x9b,1,0);
    _DrawCustomString("Marcus Conge",0xffffffff,0xb9,0,0);
    _DrawCustomString("Additional Sprite Artwork",0xffffffff,0xf5,1,0);
    _DrawCustomString("David Wareing",0xffffffff,0x113,0,0);
    uVar4 = 0;
    uVar3 = 0x131;
    uVar2 = 0xffffffff;
    pcVar1 = "Alex Metcalf";
    break;
  case 3:
    _DrawCustomString("OS X Transmogrifying",0xffffffff,0x7d,1,0);
    _DrawCustomString("Alex Metcalf",0xffffffff,0x9b,0,0);
    _DrawCustomString("David Wareing",0xffffffff,0xb9,0,0);
    _DrawCustomString("Special Thanks",0xffffffff,0xf5,1,0);
    _DrawCustomString("Sheryn Wareing",0xffffffff,0x113,0,0);
    _DrawCustomString("Thomas Metcalf",0xffffffff,0x131,0,0);
    uVar4 = 0;
    uVar3 = 0x14f;
    uVar2 = 0xffffffff;
    pcVar1 = "Luke Slot";
    break;
  case 4:
    _DrawCustomString("Ambrosia Software Crew",0xffffffff,0x8c,1,0);
    _DrawCustomString("Andrew Welch - El Presidente",0xffffffff,0xaa,0,0);
    _DrawCustomString("David Dunham - Technical Support",0xffffffff,200,0,0);
    _DrawCustomString("Matt Slot - Bitwise Operator",0xffffffff,0xe6,0,0);
    _DrawCustomString("David Cockhern - Money Man",0xffffffff,0x104,0,0);
    _DrawCustomString("Aaron Hunt - Operations",0xffffffff,0x122,0,0);
    uVar4 = 0;
    uVar3 = 0x140;
    uVar2 = 0xffffffff;
    pcVar1 = "Ed Ota - Operations";
    break;
  case 5:
    _DrawCustomString("Musicians",0xffffffff,200,1,0);
    _DrawCustomString("Matt Swoboda",0xffffffff,0xe6,0,0);
    uVar4 = 0;
    uVar3 = 0x104;
    uVar2 = 0xffffffff;
    pcVar1 = "Yannis Brown";
    break;
  case 6:
    _DrawCustomString("Sound FX",0xffffffff,0xaa,1,0);
    _DrawCustomString("Alex Metcalf",0xffffffff,200,0,0);
    _DrawCustomString("Ambrosia Labs",0xffffffff,0xe6,0,0);
    _DrawCustomString("David Wareing",0xffffffff,0x104,0,0);
    uVar4 = 0;
    uVar3 = 0x122;
    uVar2 = 0xffffffff;
    pcVar1 = "Matt Lee";
    break;
  case 7:
    _DrawCustomString("Ambrosia Software Tools",0xffffffff,0x5f,1,0);
    _DrawCustomString("Ambrosia Sound Tool",0xffffffff,0x7d,0,0);
    _DrawCustomString("Ambrosia Registration Tool",0xffffffff,0x9b,0,0);
    _DrawCustomString("Universal Binary",0xffffffff,0xd7,1,0);
    _DrawCustomString("Kent Sutherland",0xffffffff,0xf5,0,0);
    _DrawCustomString("OS X Icon Artistry",0xffffffff,0x131,1,0);
    _DrawCustomString("Marcus Conge",0xffffffff,0x14f,0,0);
    uVar4 = 0;
    uVar3 = 0x16d;
    uVar2 = 0xffffffff;
    pcVar1 = "Markus Magnuson";
    break;
  case 8:
    _DrawCustomString("OS X Testing Team",0xffffffff,0x32,1,0);
    _DrawCustomString("Fiyin \'Khaotic\' Adewale",0xffffffff,0x50,0,0);
    _DrawCustomString("Matthew \'Anklebiter\' Beedle",0xffffffff,0x6e,0,0);
    _DrawCustomString("Patrick Bernardi",0xffffffff,0x8c,0,0);
    _DrawCustomString("Light Blashpemy",0xffffffff,0xaa,0,0);
    _DrawCustomString("Dominic \'Eytee\' Dagradi",0xffffffff,200,0,0);
    _DrawCustomString("Roseann Devlin",0xffffffff,0xe6,0,0);
    _DrawCustomString("Liam Doughty",0xffffffff,0x104,0,0);
    _DrawCustomString("Alex \'ARGH\' Eiser",0xffffffff,0x122,0,0);
    _DrawCustomString("Jon Forst",0xffffffff,0x140,0,0);
    _DrawCustomString("Tim \'Musapi\' Frede",0xffffffff,0x15e,0,0);
    _DrawCustomString("David Evan Isom",0xffffffff,0x17c,0,0);
    uVar4 = 0;
    uVar3 = 0x19a;
    uVar2 = 0xffffffff;
    pcVar1 = "Jan \'janski\' Van Tol";
    break;
  case 9:
    _DrawCustomString("OS X Testing Team",0xffffffff,0x32,1,0);
    _DrawCustomString("Ryan Junk",0xffffffff,0x50,0,0);
    _DrawCustomString("Matt \'Zebe\' Lee",0xffffffff,0x6e,0,0);
    _DrawCustomString("Markus \'superqult\' Magnuson",0xffffffff,0x8c,0,0);
    _DrawCustomString("Patrik Montgomery",0xffffffff,0xaa,0,0);
    _DrawCustomString("Adam \'Juneappal\' Price",0xffffffff,200,0,0);
    _DrawCustomString("Nick Robbins",0xffffffff,0xe6,0,0);
    _DrawCustomString("Kyle \'niles\' Rove",0xffffffff,0x104,0,0);
    _DrawCustomString("Luke Slot",0xffffffff,0x122,0,0);
    _DrawCustomString("Jeremy Sobczak",0xffffffff,0x140,0,0);
    _DrawCustomString("Adam \'Cyrus\' Smith",0xffffffff,0x15e,0,0);
    _DrawCustomString("Neal Staley",0xffffffff,0x17c,0,0);
    uVar4 = 0;
    uVar3 = 0x19a;
    uVar2 = 0xffffffff;
    pcVar1 = "Benjamin \'Andiyar\' Thomas";
    break;
  case 10:
    _DrawCustomString("Original Testing Team",0xffffffff,0x41,1,0);
    _DrawCustomString("David Sie",0xffffffff,0x5f,0,0);
    _DrawCustomString("Scott Lemon",0xffffffff,0x7d,0,0);
    _DrawCustomString("Joshua Bruce",0xffffffff,0x9b,0,0);
    _DrawCustomString("Justin Anderson",0xffffffff,0xb9,0,0);
    _DrawCustomString("Michael Artz",0xffffffff,0xd7,0,0);
    _DrawCustomString("David Bahr",0xffffffff,0xf5,0,0);
    _DrawCustomString("Josh Barnes",0xffffffff,0x113,0,0);
    _DrawCustomString("Kenneth M. Berger",0xffffffff,0x131,0,0);
    _DrawCustomString("Mike Betzel",0xffffffff,0x14f,0,0);
    _DrawCustomString("Erin Brown",0xffffffff,0x16d,0,0);
    uVar4 = 0;
    uVar3 = 0x18b;
    uVar2 = 0xffffffff;
    pcVar1 = "Bryan Chan";
    break;
  case 0xb:
    _DrawCustomString("Original Testing Team",0xffffffff,0x41,1,0);
    _DrawCustomString("James A. Collins",0xffffffff,0x5f,0,0);
    _DrawCustomString("Jeremy Condit",0xffffffff,0x7d,0,0);
    _DrawCustomString("Rose \'BamBam\' Cooper",0xffffffff,0x9b,0,0);
    _DrawCustomString("Jabob Cusack",0xffffffff,0xb9,0,0);
    _DrawCustomString("Steffan Davies",0xffffffff,0xd7,0,0);
    _DrawCustomString("Liam Doughty",0xffffffff,0xf5,0,0);
    _DrawCustomString("Ken Dye",0xffffffff,0x113,0,0);
    _DrawCustomString("Andrew Feigenson",0xffffffff,0x131,0,0);
    _DrawCustomString("Pat Gardella",0xffffffff,0x14f,0,0);
    _DrawCustomString("Ken Gerrard",0xffffffff,0x16d,0,0);
    uVar4 = 0;
    uVar3 = 0x18b;
    uVar2 = 0xffffffff;
    pcVar1 = "Robert Goree";
    break;
  case 0xc:
    _DrawCustomString("Original Testing Team",0xffffffff,0x41,1,0);
    _DrawCustomString("Kevin Griffiths",0xffffffff,0x5f,0,0);
    _DrawCustomString("Sion Harris",0xffffffff,0x7d,0,0);
    _DrawCustomString("Steffan Harris",0xffffffff,0x9b,0,0);
    _DrawCustomString("Mark Headley",0xffffffff,0xb9,0,0);
    _DrawCustomString("John Heitmann",0xffffffff,0xd7,0,0);
    _DrawCustomString("Ryan Junk",0xffffffff,0xf5,0,0);
    _DrawCustomString("Tony Kiefer",0xffffffff,0x113,0,0);
    _DrawCustomString("Matt Lee",0xffffffff,0x131,0,0);
    _DrawCustomString("Chris Littman",0xffffffff,0x14f,0,0);
    _DrawCustomString("Barry Maggert",0xffffffff,0x16d,0,0);
    uVar4 = 0;
    uVar3 = 0x18b;
    uVar2 = 0xffffffff;
    pcVar1 = "Steven Marcotte";
    break;
  case 0xd:
    _DrawCustomString("Original Testing Team",0xffffffff,0x41,1,0);
    _DrawCustomString("Duncan McQueen",0xffffffff,0x5f,0,0);
    _DrawCustomString("Ryan Moser",0xffffffff,0x7d,0,0);
    _DrawCustomString("Etienne Pelaprat",0xffffffff,0x9b,0,0);
    _DrawCustomString("Dan Pride",0xffffffff,0xb9,0,0);
    _DrawCustomString("Jake Rodkin",0xffffffff,0xd7,0,0);
    _DrawCustomString("David Rugge",0xffffffff,0xf5,0,0);
    _DrawCustomString("Steve Sabol",0xffffffff,0x113,0,0);
    _DrawCustomString("Bruce E. Strange",0xffffffff,0x131,0,0);
    _DrawCustomString("Ken Taylor",0xffffffff,0x14f,0,0);
    _DrawCustomString("Michael Thyen",0xffffffff,0x16d,0,0);
    uVar4 = 0;
    uVar3 = 0x18b;
    uVar2 = 0xffffffff;
    pcVar1 = "The Students of Mr. Morley\'s Computer Lab";
    break;
  case 0xe:
    uVar4 = 1;
    uVar3 = 0xd7;
    uVar2 = 0xffffffff;
    pcVar1 = "Recommended Reading Follows...";
    break;
  case 0xf:
    _DrawCustomString("The Selfish Gene",0xffffffff,0xd7,1,0);
    uVar4 = 0;
    uVar3 = 0xf5;
    uVar2 = 0xffffffff;
    pcVar1 = "Richard Dawkins";
    break;
  case 0x10:
    _DrawCustomString("Hannibal",0xffffffff,0xd7,1,0);
    uVar4 = 0;
    uVar3 = 0xf5;
    uVar2 = 0xffffffff;
    pcVar1 = "Thomas Harris";
    break;
  case 0x11:
    _DrawCustomString("The Forge of God",0xffffffff,0xd7,1,0);
    uVar4 = 0;
    uVar3 = 0xf5;
    uVar2 = 0xffffffff;
    pcVar1 = "Greg Bear";
    break;
  case 0x12:
    _DrawCustomString("Fear and Loathing in Las Vegas",0xffffffff,0xd7,1,0);
    uVar4 = 0;
    uVar3 = 0xf5;
    uVar2 = 0xffffffff;
    pcVar1 = "Hunter S. Thompson";
    break;
  case 0x13:
    _DrawCustomString("Brave New World",0xffffffff,0xd7,1,0);
    uVar4 = 0;
    uVar3 = 0xf5;
    uVar2 = 0xffffffff;
    pcVar1 = "Aldous Huxley";
    break;
  case 0x14:
    _DrawCustomString("The Kraken Wakes",0xffffffff,0xd7,1,0);
    uVar4 = 0;
    uVar3 = 0xf5;
    uVar2 = 0xffffffff;
    pcVar1 = "John Wyndham";
    break;
  case 0x15:
    _DrawCustomString("All The Trouble in the World",0xffffffff,0xd7,1,0);
    uVar4 = 0;
    uVar3 = 0xf5;
    uVar2 = 0xffffffff;
    pcVar1 = "P.J. O\'Rourke";
    break;
  case 0x16:
    _DrawCustomString("The Tao Of Pooh",0xffffffff,0xd7,1,0);
    uVar4 = 0;
    uVar3 = 0xf5;
    uVar2 = 0xffffffff;
    pcVar1 = "Benjamin Hoff";
    break;
  case 0x17:
    _DrawCustomString("David\'s Recommended Viewing",0xffffffff,0x7d,1,0);
    _DrawCustomString("12 Monkeys",0xffffffff,0x9b,0,0);
    _DrawCustomString("The Usual Suspects",0xffffffff,0xb9,0,0);
    _DrawCustomString("Lost Highway",0xffffffff,0xd7,0,0);
    _DrawCustomString("The Big Lebowski",0xffffffff,0xf5,0,0);
    _DrawCustomString("Mars Attacks!",0xffffffff,0x113,0,0);
    _DrawCustomString("The Life of Brian",0xffffffff,0x131,0,0);
    uVar4 = 0;
    uVar3 = 0x14f;
    uVar2 = 0xffffffff;
    pcVar1 = "Forbidden Planet";
    break;
  case 0x18:
    _DrawCustomString("Alex\'s Recommended Viewing",0xffffffff,0x7d,1,0);
    _DrawCustomString("Some Like It Hot",0xffffffff,0x9b,0,0);
    _DrawCustomString("When Harry Met Sally",0xffffffff,0xb9,0,0);
    _DrawCustomString("2001",0xffffffff,0xd7,0,0);
    _DrawCustomString("The Empire Strikes Back",0xffffffff,0xf5,0,0);
    _DrawCustomString("The Naked Gun",0xffffffff,0x113,0,0);
    _DrawCustomString("Groundhog Day",0xffffffff,0x131,0,0);
    uVar4 = 0;
    uVar3 = 0x14f;
    uVar2 = 0xffffffff;
    pcVar1 = "Ocean\'s Eleven";
    break;
  case 0x19:
    _DrawCustomString("David\'s Recommended Listening",0xffffffff,0x7d,1,0);
    _DrawCustomString("Roxy Music",0xffffffff,0x9b,0,0);
    _DrawCustomString("Neil Young",0xffffffff,0xb9,0,0);
    _DrawCustomString("Bob Dylan",0xffffffff,0xd7,0,0);
    _DrawCustomString("Pulp",0xffffffff,0xf5,0,0);
    _DrawCustomString("Leonard Cohen",0xffffffff,0x113,0,0);
    _DrawCustomString("Lloyd Cole",0xffffffff,0x131,0,0);
    uVar4 = 0;
    uVar3 = 0x14f;
    uVar2 = 0xffffffff;
    pcVar1 = "Blondie";
    break;
  case 0x1a:
    _DrawCustomString("Alex\'s Recommended Listening",0xffffffff,0x7d,1,0);
    _DrawCustomString("Muse",0xffffffff,0x9b,0,0);
    _DrawCustomString("Red Hot Chili Peppers",0xffffffff,0xb9,0,0);
    _DrawCustomString("Radiohead",0xffffffff,0xd7,0,0);
    _DrawCustomString("Nina Simone",0xffffffff,0xf5,0,0);
    _DrawCustomString("Barenaked Ladies",0xffffffff,0x113,0,0);
    _DrawCustomString("Propellerheads",0xffffffff,0x131,0,0);
    uVar4 = 0;
    uVar3 = 0x14f;
    uVar2 = 0xffffffff;
    pcVar1 = "The Police";
    break;
  case 0x1b:
    _DrawCustomString("Some Human Rights Abusers",0xffffffff,0x7d,1,0);
    _DrawCustomString("China",0xffffffff,0x9b,0,0);
    _DrawCustomString("Indonesia",0xffffffff,0xb9,0,0);
    _DrawCustomString("Saudi Arabia",0xffffffff,0xd7,0,0);
    _DrawCustomString("Iraq",0xffffffff,0xf5,0,0);
    _DrawCustomString("Syria",0xffffffff,0x113,0,0);
    _DrawCustomString("North Korea",0xffffffff,0x131,0,0);
    uVar4 = 0;
    uVar3 = 0x14f;
    uVar2 = 0xffffffff;
    pcVar1 = "Burma";
    break;
  case 0x1c:
    _DrawCustomString("Some Things To Do On A Rainy Day or Night",0xffffffff,0x7d,1,0);
    _DrawCustomString("Visit your local library.",0xffffffff,0x9b,0,0);
    _DrawCustomString("Do some drawing.",0xffffffff,0xb9,0,0);
    _DrawCustomString("Avoid joining Scientology.",0xffffffff,0xd7,0,0);
    _DrawCustomString("Spend some quality time with your cat.",0xffffffff,0xf5,0,0);
    _DrawCustomString("Read \'Cosmos\' by Carl Sagan.",0xffffffff,0x113,0,0);
    _DrawCustomString("Play chess with a friend.",0xffffffff,0x131,0,0);
    uVar4 = 0;
    uVar3 = 0x14f;
    uVar2 = 0xffffffff;
    pcVar1 = "Gaze at the stars and ponder...";
    break;
  case 0x1d:
    _DrawCustomString("In memorium",0xffffffff,0x70,1,0);
    _DrawCustomString("Carl Sagan,  1934 - 1996",0xffffffff,0x157,1,0);
    _DrawSecretPictInRect(0x80,0xe300a6,0x19c0139);
    goto LAB_00021442;
  case 0x1e:
    _DrawCustomString("Alex\'s favourite things in life",0xffffffff,0x7d,1,0);
    _DrawCustomString("Alto saxophone",0xffffffff,0x9b,0,0);
    _DrawCustomString("Evenings out with friends",0xffffffff,0xb9,0,0);
    _DrawCustomString("Skiing",0xffffffff,0xd7,0,0);
    _DrawCustomString("Cheers (US TV)",0xffffffff,0xf5,0,0);
    _DrawCustomString("Juggling",0xffffffff,0x113,0,0);
    _DrawCustomString("An alcoholic beverage",0xffffffff,0x131,0,0);
    uVar4 = 0;
    uVar3 = 0x14f;
    uVar2 = 0xffffffff;
    pcVar1 = "Marmite";
    break;
  case 0x1f:
    _DrawCustomString("Alex\'s reasons for you to pay shareware fee",0x28,0x7d,1,0);
    _DrawCustomString("1. You\'ll sleep better.",0x28,0x9b,0,0);
    _DrawCustomString("2. The development tools cost 400 pounds.",0x28,0xb9,0,0);
    _DrawCustomString("3. I can start saving up to ski this winter.",0x28,0xd7,0,0);
    _DrawCustomString("4. I\'m still paying off student loans.",0x28,0xf5,0,0);
    _DrawCustomString("5. I\'d like to fly and meet David again.",0x28,0x113,0,0);
    _DrawCustomString("6. Bubble Trouble 2 needs funding?",0x28,0x131,0,0);
    uVar4 = 0;
    uVar3 = 0x14f;
    uVar2 = 0x28;
    pcVar1 = "7. Beer is expensive.";
    break;
  case 0x20:
    _DrawCustomString("Some truly great people",0xffffffff,0x6e,1,0);
    _DrawCustomString("Gary Larson (great cartoonist)",0xffffffff,0x8c,0,0);
    _DrawCustomString("Orson Welles (great director)",0xffffffff,0xaa,0,0);
    _DrawCustomString("Kevin Kline (great actor)",0xffffffff,200,0,0);
    _DrawCustomString("George Orwell (great writer)",0xffffffff,0xe6,0,0);
    _DrawCustomString("Paul Davison (great teacher)",0xffffffff,0x104,0,0);
    _DrawCustomString("Tony Stott (great friend)",0xffffffff,0x122,0,0);
    _DrawCustomString("Mum, Dad, Harriet, Thomas (great family)",0xffffffff,0x140,0,0);
    uVar4 = 0;
    uVar3 = 0x15e;
    uVar2 = 0xffffffff;
    pcVar1 = "Registered Users (grate-ful)";
    break;
  case 0x21:
    _DrawCustomString("Have you seen these (young looking) men?",0xffffffff,0x5a,1,0);
    _DrawCustomString("Alex Metcalf",0x5f,0x13e,1,0);
    _DrawCustomString("David Wareing",0x186,0x13e,1,0);
    _DrawCustomString("Responsible for crimes",0xffffffff,0x172,0,0);
    _DrawCustomString("against productivity",0xffffffff,400,0,0);
    _DrawPictInRect(0x72da,0x640081,0xf8012d);
    _DrawPictInRect(0x72d9,0x1900081,0x224012d);
    goto LAB_00021442;
  default:
    _DebugValues("DrawCredit() - Unknown credit value.",(int)param_1);
    goto LAB_00021442;
  }
  _DrawCustomString(pcVar1,uVar2,uVar3,uVar4,0);
LAB_00021442:
  _SetToScreen();
  _WipeScreen();
  return;
}


// ==== _DisplayCredits @ 0002145a ====

undefined4 _DisplayCredits(short param_1)

{
  char cVar1;
  int iVar2;
  uint uVar3;
  short sVar4;
  undefined4 uVar5;
  short local_2e;
  short local_2c;
  uint local_2a;
  
  iVar2 = _TickCount();
  switch((int)param_1) {
  case 0:
    local_2e = 0xd;
    goto LAB_000214e9;
  case 1:
    sVar4 = 0xe;
    local_2e = 0x16;
    uVar5 = 0xe;
    break;
  case 2:
    sVar4 = 0x17;
    local_2e = 0x1a;
    uVar5 = 0x17;
    break;
  case 3:
    sVar4 = 0x1b;
    local_2e = 0x1d;
    uVar5 = 0x1b;
    break;
  case 4:
    sVar4 = 0x1e;
    local_2e = 0x21;
    uVar5 = 0x1e;
    break;
  default:
    _DebugValues("DisplayCredits() - unknown credit.",(int)param_1);
    _CleanUp();
    local_2e = 0;
LAB_000214e9:
    sVar4 = 0;
    uVar5 = 0;
  }
  _SetToScreen();
  _DrawCredit(uVar5);
  _FlushEvents(0x3e,0);
  while( true ) {
    do {
      uVar3 = _TickCount();
      if (iVar2 + 0xf0U < uVar3) {
        sVar4 = sVar4 + 1;
        if (local_2e < sVar4) {
          return 0;
        }
        _DrawCredit((int)sVar4);
        iVar2 = _TickCount();
      }
      cVar1 = _WaitNextEvent(0x800a,&local_2c,10,0);
    } while (cVar1 == '\0');
    if (local_2c == 3) break;
    if (local_2c == 0xf) {
      if (local_2a >> 0x18 == 1) {
        if ((local_2a & 1) == 0) {
          _SuspendGame();
        }
        else {
          _ResumeGame();
          iVar2 = _TickCount();
          iVar2 = iVar2 + -0xf0;
        }
      }
    }
    else if (local_2c == 1) {
LAB_000215a7:
      _PlayMySnd(0x11,10,0);
      return 0;
    }
  }
  if (((char)local_2a == 'N') || ((char)local_2a == 'n')) {
    _PlayMySnd(0x11,10,0);
    return 1;
  }
  goto LAB_000215a7;
}


// ==== _Useless7 @ 00021604 ====

void __regparm3 _Useless7(byte param_1)

{
  byte bVar1;
  uint uVar2;
  char cVar3;
  
  bVar1 = _RT3_GetTimePeriod();
  uVar2 = (uint)(bVar1 ^ param_1);
  for (cVar3 = '\0'; cVar3 != -(param_1 & 6); cVar3 = cVar3 + -1) {
    uVar2 = _RandomSeed(uVar2);
  }
  return;
}


// ==== _Useless8 @ 0002163f ====

int __regparm3 _Useless8(char param_1)

{
  int iVar1;
  
  if (param_1 == '\0') {
    iVar1 = 7;
  }
  else {
    iVar1 = _Useless8();
    iVar1 = iVar1 * 3;
  }
  return iVar1;
}


// ==== _ResetHeroPosition @ 0002165f ====

void _ResetHeroPosition(void)

{
  undefined1 uVar1;
  int iVar2;
  undefined *puVar3;
  int iVar4;
  undefined *puVar5;
  int iVar6;
  char local_1e;
  
  puVar5 = PTR__hero_0003f014;
  if (PTR__gMaze_0003f054[0x67] == '\0') {
    PTR__hero_0003f014[0x28] = 7;
    puVar5[0x34] = 6;
  }
  else {
    iVar4 = 0;
    iVar6 = 0x50;
    do {
      puVar3 = PTR__gMaze_0003f054 + iVar6;
      iVar2 = 0;
      do {
        if (puVar3[6] == '\0') {
          PTR__hero_0003f014[0x28] = (char)iVar2 + '\x06';
          local_1e = (char)iVar4;
          goto LAB_0002171b;
        }
        iVar2 = iVar2 + 1;
        puVar3 = puVar3 + 1;
      } while (iVar2 != 3);
      iVar4 = iVar4 + 1;
      iVar6 = iVar6 + 0x10;
    } while (iVar4 != 3);
    iVar4 = 0;
    iVar6 = 0x50;
    do {
      puVar3 = PTR__gMaze_0003f054 + iVar6;
      iVar2 = 0;
      do {
        if ((puVar3[6] != '\x14') && (puVar3[6] != '\x1e')) {
          PTR__hero_0003f014[0x28] = (char)iVar2 + '\x06';
          local_1e = (char)iVar4;
LAB_0002171b:
          puVar5[0x34] = local_1e + '\x05';
          goto LAB_00021685;
        }
        iVar2 = iVar2 + 1;
        puVar3 = puVar3 + 1;
      } while (iVar2 != 3);
      iVar4 = iVar4 + 1;
      iVar6 = iVar6 + 0x10;
    } while (iVar4 != 3);
    _DebugValues("Internal error: can\'t find good starting loc.",0);
    _CleanUp();
    puVar5 = PTR__hero_0003f014;
  }
LAB_00021685:
  puVar5[0x35] = 1;
  *(undefined2 *)(puVar5 + 0x36) = 0;
  uVar1 = _RT3_IsRegistered();
  puVar5[0x3a] = uVar1;
  *(undefined2 *)(puVar5 + 0x38) = 0;
  *(short *)(puVar5 + 0x16) = (char)puVar5[0x28] * 0x28;
  *(short *)(puVar5 + 0x14) = (char)puVar5[0x34] * 0x28;
  *(short *)(puVar5 + 0x1a) = (char)puVar5[0x28] * 0x28 + 0x28;
  *(short *)(puVar5 + 0x18) = (char)puVar5[0x34] * 0x28 + 0x28;
  *(undefined4 *)(puVar5 + 0x1c) = *(undefined4 *)(puVar5 + 0x14);
  *(undefined4 *)(puVar5 + 0x20) = *(undefined4 *)(puVar5 + 0x18);
  *(undefined2 *)(puVar5 + 0x26) = 3;
  *(undefined2 *)(puVar5 + 0x3c) = 1;
  *(undefined2 *)(puVar5 + 0x3e) = 3;
  puVar5[0x40] = 0;
  puVar5[0x4b] = 0;
  puVar5[0x4c] = 0;
  return;
}


// ==== _InitHero @ 000217b3 ====

void _InitHero(void)

{
  undefined *puVar1;
  undefined2 uVar2;
  undefined4 uVar3;
  undefined8 uVar4;
  
  puVar1 = PTR__hero_0003f014;
  *(undefined4 *)(PTR__hero_0003f014 + 0x2c) = 0x21cf4642;
  *(undefined4 *)(puVar1 + 0x30) = 0xfb58e4;
  *(undefined2 *)(puVar1 + 2) = 1;
  uVar2 = _GetFrameCounter();
  *(undefined2 *)(puVar1 + 4) = uVar2;
  puVar1[0x50] = 0;
  uVar2 = _GetFrameCounter();
  *(undefined2 *)(puVar1 + 0x52) = uVar2;
  uVar3 = _RT3_GetLicenseCopies();
  *(undefined4 *)(puVar1 + 8) = uVar3;
  puVar1[0x5f] = 0;
  puVar1[0x4c] = 0;
  uVar2 = _GetFrameCounter();
  *(undefined2 *)(puVar1 + 0x4e) = uVar2;
  uVar4 = _RT3_GetLicenseCode();
  *(undefined8 *)(puVar1 + 0x54) = uVar4;
  uVar2 = _GetFrameCounter();
  *(undefined2 *)(puVar1 + 0xc) = uVar2;
  uVar3 = _RT3_GetLicenseName();
  *(undefined4 *)(puVar1 + 0x10) = uVar3;
  *(undefined2 *)(puVar1 + 0x66) = 5;
  puVar1[0x40] = 0;
  _ResetHeroPosition();
  _gReserveHero_NeedsDrawing = 0;
  _gReserveHero_AnimFrame = 4;
  _gReserveHero_Animate = 0;
  _gReserveHero_NumAnimCycles = 0;
  _gReserveHero_AnimTimer = _GetFrameCounter();
  _gReserveHero_ImageR._2_2_ = 0x10;
  _gReserveHero_ImageR._0_2_ = 0x1bd;
  DAT_000379ce._2_2_ = 0x30;
  DAT_000379ce._0_2_ = 0x1dd;
  _gReserveHero_NumR._2_2_ = 0x37;
  _gReserveHero_NumR._0_2_ = 0x1be;
  DAT_000379c6._2_2_ = 0x4d;
  DAT_000379c6._0_2_ = 0x1dc;
  return;
}


// ==== _ResetHeroLives @ 000218a7 ====

void _ResetHeroLives(void)

{
  _SetLives(3);
  PTR__hero_0003f014[0x24] = 1;
  return;
}


// ==== _RequestDrawReserveHero @ 000218c4 ====

void _RequestDrawReserveHero(char param_1)

{
  undefined1 uVar1;
  
  _gReserveHero_NeedsDrawing = 1;
  uVar1 = 1;
  if (param_1 == '\0') {
    uVar1 = _gReserveHero_Animate;
  }
  _gReserveHero_Animate = uVar1;
  return;
}


// ==== _DrawReserveHeroNumber @ 000218e8 ====

void _DrawReserveHeroNumber(void)

{
  short sVar1;
  int iVar2;
  undefined4 local_1c;
  undefined4 local_18;
  undefined4 local_14;
  undefined4 local_10;
  
  _SetRect(&local_14,0x37,5,0x4d,0x24);
  _SetRect(&local_1c,0x37,0x1bd,0x4d,0x1dc);
  _ScoreToComp(local_14,local_10,local_1c,local_18);
  sVar1 = _GetLives();
  if (9 < sVar1) {
    _SetLives(9);
  }
  _SetToCompGWorld();
  sVar1 = _GetLives();
  if (sVar1 < 1) {
    iVar2 = 1;
  }
  else {
    sVar1 = _GetLives();
    iVar2 = (int)sVar1;
  }
  _SpriteToComp(0,0x37,0x1be,0x21,iVar2,0);
  _SetToScreen();
  local_1c = _gReserveHero_NumR;
  local_18 = DAT_000379c6;
  if (PTR__environment_0003f028[8] != '\0') {
    _OffsetRect(&local_1c,(int)*(short *)(PTR__environment_0003f028 + 0x1a),
                (int)*(short *)(PTR__environment_0003f028 + 0x1c));
  }
  _CompToScreen(_gReserveHero_NumR,DAT_000379c6,local_1c,local_18);
  return;
}


// ==== _DrawReserveHeroImage @ 00021a3c ====

void _DrawReserveHeroImage(void)

{
  ushort uVar1;
  short sVar2;
  undefined4 local_1c;
  undefined4 local_18;
  undefined4 local_14;
  undefined4 local_10;
  
  _SetToCompGWorld();
  _SetRect(&local_14,0x10,4,0x30,0x25);
  _SetRect(&local_1c,0x10,0x1bc,0x30,0x1dd);
  _ScoreToComp(local_14,local_10,local_1c,local_18);
  if (_gReserveHero_Animate == '\0') {
    _gReserveHero_NeedsDrawing = 0;
  }
  else {
    uVar1 = _GetFrameCounter();
    if (_gReserveHero_AnimTimer < uVar1) {
      sVar2 = _gReserveHero_AnimFrame + -1;
      _gReserveHero_AnimFrame = 0xc;
      if (0 < sVar2) {
        _gReserveHero_AnimFrame = sVar2;
      }
      _gReserveHero_AnimTimer = uVar1;
      if ((_gReserveHero_AnimFrame == 4) &&
         (_gReserveHero_NumAnimCycles = _gReserveHero_NumAnimCycles + 1,
         _gReserveHero_NumAnimCycles == 2)) {
        _gReserveHero_NeedsDrawing = 0;
        _gReserveHero_Animate = '\0';
        _gReserveHero_NumAnimCycles = 0;
      }
    }
  }
  _SpriteToComp(0,0x10,0x1bd,8,(int)_gReserveHero_AnimFrame,0);
  _SetToScreen();
  local_1c = _gReserveHero_ImageR;
  local_18 = DAT_000379ce;
  if (PTR__environment_0003f028[8] != '\0') {
    _OffsetRect(&local_1c,(int)*(short *)(PTR__environment_0003f028 + 0x1a),
                (int)*(short *)(PTR__environment_0003f028 + 0x1c));
  }
  _CompToScreen(_gReserveHero_ImageR,DAT_000379ce,local_1c,local_18);
  return;
}


// ==== _DrawReserveInfo @ 00021bd2 ====

void _DrawReserveInfo(void)

{
  if (_gReserveHero_NeedsDrawing != '\0') {
    _DrawReserveHeroNumber();
    _DrawReserveHeroImage();
    return;
  }
  return;
}


// ==== _SetHeroInvisibility @ 00021bee ====

void _SetHeroInvisibility(char param_1)

{
  undefined *puVar1;
  undefined2 uVar2;
  
  puVar1 = PTR__hero_0003f014;
  if (param_1 == '\0') {
    PTR__hero_0003f014[0x50] = 0;
    puVar1[0x51] = 0;
  }
  else {
    PTR__hero_0003f014[0x50] = 1;
    uVar2 = _GetFrameCounter();
    *(undefined2 *)(puVar1 + 0x52) = uVar2;
    puVar1[0x51] = 1;
    *(undefined2 *)(puVar1 + 0x5c) = 0;
    puVar1[0x5e] = 0;
  }
  return;
}


// ==== _SetHeroSpeed @ 00021c31 ====

void _SetHeroSpeed(short param_1)

{
  undefined *puVar1;
  undefined2 uVar2;
  
  puVar1 = PTR__hero_0003f014;
  if (param_1 == 5) {
    PTR__hero_0003f014[0x5f] = 0;
    *(undefined2 *)(puVar1 + 0x66) = 5;
  }
  else {
    PTR__hero_0003f014[0x5f] = 1;
    uVar2 = _GetFrameCounter();
    *(undefined2 *)(puVar1 + 0x60) = uVar2;
    *(undefined2 *)(puVar1 + 0x66) = 10;
    *(undefined2 *)(puVar1 + 0x62) = 0;
    puVar1[100] = 1;
  }
  return;
}


// ==== _IsHeroCaught @ 00021c79 ====

undefined4 _IsHeroCaught(undefined4 param_1,undefined4 param_2,char param_3,char param_4)

{
  char cVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined4 local_14;
  undefined4 local_10;
  
  cVar1 = param_4;
  if ((*(short *)(PTR__hero_0003f014 + 2) == 2) &&
     ((param_3 == '\0' || (PTR__hero_0003f014[0x50] == '\0')))) {
    if (param_4 == '\0') {
      uVar3 = 4;
      uVar2 = 4;
    }
    else {
      uVar3 = 0xb;
      uVar2 = 0xb;
    }
    _MyInsetRect(&param_1,uVar2,uVar3);
    local_10 = *(undefined4 *)(PTR__hero_0003f014 + 0x18);
    local_14 = *(undefined4 *)(PTR__hero_0003f014 + 0x14);
    if (cVar1 != '\0') {
      _MyInsetRect(&local_14,8,8);
    }
    cVar1 = _RectsCollide(&local_14,&param_1);
    if (cVar1 != '\0') {
      return 1;
    }
  }
  return 0;
}


// ==== _NewOuch @ 00021d2f ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _NewOuch(void)

{
  short sVar1;
  
  if (*(short *)(PTR__hero_0003f014 + 0x26) != 4) {
    sVar1 = *(short *)(PTR__hero_0003f014 + 0x16) + -0x25;
    _gOuchSpriteFace = 1;
    if (sVar1 < 0) {
      sVar1 = 0;
    }
    DAT_000379da = 0x253;
    if (sVar1 < 0x254) {
      DAT_000379da = sVar1;
    }
    sVar1 = 0;
    if (-1 < (short)(*(short *)(PTR__hero_0003f014 + 0x14) + -0x1e)) {
      sVar1 = *(short *)(PTR__hero_0003f014 + 0x14) + -0x1e;
    }
    _gOuchR = 0x187;
    if (sVar1 < 0x188) {
      _gOuchR = sVar1;
    }
    _DAT_000379de = DAT_000379da + 0x2d;
    _DAT_000379dc = _gOuchR + 0x31;
    return;
  }
  sVar1 = *(short *)(PTR__hero_0003f014 + 0x1a) + -8;
  _gOuchSpriteFace = 2;
  if (sVar1 < 0) {
    sVar1 = 0;
  }
  DAT_000379da = 0x253;
  if (sVar1 < 0x254) {
    DAT_000379da = sVar1;
  }
  sVar1 = 0;
  if (-1 < (short)(*(short *)(PTR__hero_0003f014 + 0x14) + -0x1e)) {
    sVar1 = *(short *)(PTR__hero_0003f014 + 0x14) + -0x1e;
  }
  _gOuchR = 0x187;
  if (sVar1 < 0x188) {
    _gOuchR = sVar1;
  }
  _DAT_000379de = DAT_000379da + 0x2d;
  _DAT_000379dc = _gOuchR + 0x31;
  return;
}


// ==== _HeroCaught @ 00021dfa ====

void _HeroCaught(short param_1)

{
  undefined *puVar1;
  undefined2 uVar2;
  short sVar3;
  undefined4 uVar4;
  
  puVar1 = PTR__hero_0003f014;
  *(undefined2 *)(PTR__hero_0003f014 + 2) = 3;
  uVar2 = _GetFrameCounter();
  *(undefined2 *)(puVar1 + 4) = uVar2;
  _StopAllEnemies();
  _NewOuch();
  if (param_1 == 1) {
    sVar3 = _GetRandomFast(0,1);
    if (sVar3 == 0) {
      uVar4 = 0x25;
    }
    else {
      uVar4 = 10;
    }
    _PlayMySnd(uVar4,0x14,0);
  }
  else if (param_1 == 2) {
    _PlayMySnd(0,0x14,0);
    sVar3 = _GetRandomFast(0,1);
    if (sVar3 == 0) {
      uVar4 = 0x2d;
    }
    else {
      uVar4 = 0xb;
    }
    _PlayMySnd(uVar4,0x14,5);
    puVar1 = PTR__hero_0003f014;
    _Splats_NewSplat((int)*(short *)(PTR__hero_0003f014 + 0x16),
                     (int)*(short *)(PTR__hero_0003f014 + 0x14),1);
    _NewStarGroup((char)puVar1[0x28] * 0x28,(char)puVar1[0x34] * 0x28,0xe);
    puVar1[0x4a] = 0;
  }
  return;
}


// ==== _CheckHeroMovement @ 00021f49 ====

void _CheckHeroMovement(void)

{
  int iVar1;
  char cVar2;
  char cVar3;
  char cVar4;
  char cVar5;
  undefined1 uVar6;
  undefined1 local_1d;
  
  _gHero_MoveKeyDown = 0;
  _gHero_PushKeyPressed = 0;
  _gHero_RightKeyPressed = 0;
  _gHero_LeftKeyPressed = 0;
  _gHero_DownKeyPressed = 0;
  _gHero_UpKeyPressed = 0;
  if (*PTR__gGameMode_0003f038 == '\x01') {
    local_1d = _GetUpRecording();
    cVar2 = _GetDownRecording();
    cVar3 = _GetLeftRecording();
    cVar4 = _GetRightRecording();
    cVar5 = _GetPushRecording();
    *(int *)PTR__gRecordingCounter_0003f098 = *(int *)PTR__gRecordingCounter_0003f098 + 1;
  }
  else {
    cVar2 = _UpKey();
    local_1d = cVar2 != '\0';
    cVar2 = _DownKey();
    cVar2 = cVar2 != '\0';
    cVar3 = _LeftKey();
    cVar3 = cVar3 != '\0';
    cVar4 = _RightKey();
    cVar4 = cVar4 != '\0';
    cVar5 = _PushKey();
    cVar5 = cVar5 != '\0';
  }
  if (local_1d != '\0') {
    _gHero_UpKeyPressed = 1;
    _gHero_MoveKeyDown = 1;
  }
  if (cVar2 != '\0') {
    _gHero_DownKeyPressed = 1;
    _gHero_MoveKeyDown = 1;
  }
  if (cVar3 != '\0') {
    _gHero_LeftKeyPressed = 1;
    _gHero_MoveKeyDown = 1;
  }
  if (cVar4 != '\0') {
    _gHero_RightKeyPressed = 1;
    _gHero_MoveKeyDown = 1;
  }
  uVar6 = 1;
  if (cVar5 == '\0') {
    uVar6 = _gHero_PushKeyPressed;
  }
  _gHero_PushKeyPressed = uVar6;
  if (*PTR__gGameMode_0003f038 == '\x02') {
    cVar2 = _RecordingCountOK();
    if (cVar2 != '\0') {
      _SetUpRecording(_gHero_UpKeyPressed);
      _SetDownRecording(_gHero_DownKeyPressed);
      _SetLeftRecording(_gHero_LeftKeyPressed);
      _SetRightRecording(_gHero_RightKeyPressed);
      _SetPushRecording(_gHero_PushKeyPressed);
      iVar1 = *(int *)PTR__gRecordingCounter_0003f098;
      *(int *)PTR__gRecordingCounter_0003f098 = iVar1 + 1;
      _SetPlayRecordCount(iVar1 + 1);
      return;
    }
  }
  return;
}


// ==== _HeroPushCrushCheck @ 000220d8 ====

undefined4 _HeroPushCrushCheck(void)

{
  short sVar1;
  bool bVar2;
  bool bVar3;
  char cVar4;
  char cVar5;
  char cVar6;
  char cVar7;
  int iVar8;
  int iVar9;
  int iVar10;
  
  cVar6 = PTR__hero_0003f014[0x28];
  cVar7 = PTR__hero_0003f014[0x34];
  sVar1 = *(short *)(PTR__hero_0003f014 + 0x26);
  iVar8 = (int)cVar6;
  iVar9 = (int)cVar7;
  iVar10 = (int)(char)sVar1;
  cVar4 = _GetNextObject(iVar10,iVar8,iVar9);
  if ((((cVar4 == '\n') || (cVar4 == '\x0f')) || (cVar4 == '\x10')) || (cVar4 == '4')) {
    cVar5 = _GetDistantObject(iVar10,iVar8,iVar9);
    if ((cVar5 == '\0') || (cVar5 == 'P')) {
      if (sVar1 == 2) {
        cVar7 = cVar7 + '\x01';
      }
      else if (sVar1 < 3) {
        if (sVar1 == 1) {
          cVar7 = cVar7 + -1;
        }
      }
      else if (sVar1 == 3) {
        cVar6 = cVar6 + -1;
      }
      else if (sVar1 == 4) {
        cVar6 = cVar6 + '\x01';
      }
      if ((cVar4 == '4') && (cVar6 = _IsActiveBombBlock((int)cVar6,(int)cVar7), cVar6 != '\0')) {
        return 0;
      }
      bVar2 = true;
      _PushBlock(iVar8,iVar9,iVar10,(int)cVar4);
      goto joined_r0x000221f0;
    }
    if (cVar4 == '\x14') goto LAB_000221f6;
    if (0x32 < (ushort)((short)cVar5 - 10U)) {
      bVar2 = false;
      goto LAB_00022138;
    }
    _CrushBlock(iVar8,iVar9,iVar10,1);
    if (cVar4 == '4') {
      _ActivateBombBlock(iVar8,iVar9,iVar10);
      return 2;
    }
    bVar2 = false;
    bVar3 = true;
  }
  else {
    bVar2 = false;
joined_r0x000221f0:
    if (cVar4 == '\x14') {
LAB_000221f6:
      cVar6 = _IsTargetJewelFound();
      if (cVar6 == '\0') {
        cVar6 = _GetDistantObject(iVar10,iVar8,iVar9);
        if ((cVar6 == '\0') || (cVar6 == 'P')) {
          _PushBlock(iVar8,iVar9,iVar10,(int)cVar4);
          bVar2 = true;
        }
        else {
          bVar2 = false;
        }
        if (cVar6 == '\x14') {
          _PushBlock(iVar8,iVar9,iVar10,(int)cVar4);
LAB_0002246c:
          bVar2 = true;
        }
        else {
LAB_0002223b:
          if (!bVar2) goto LAB_0002234b;
          bVar2 = true;
        }
      }
      else {
        cVar6 = _IsJewelTheTarget(iVar10,iVar8,iVar9);
        if (cVar6 == '\0') {
          cVar6 = _GetDistantObject(iVar10,iVar8,iVar9);
          if ((cVar6 == '\0') || (cVar6 == 'P')) {
            bVar2 = true;
            _PushBlock(iVar8,iVar9,iVar10,(int)cVar4);
          }
          else {
            bVar2 = false;
          }
          if (((cVar6 == '\x14') || (cVar6 == '\x1e')) &&
             (cVar6 = _IsJewelTheDistantTarget(iVar10,iVar8,iVar9), cVar6 != '\0')) {
            _PushBlock(iVar8,iVar9,iVar10,(int)cVar4);
            goto LAB_0002246c;
          }
          goto LAB_0002223b;
        }
LAB_0002234b:
        bVar2 = true;
        _PlayMySnd(7,10,0);
      }
    }
LAB_00022138:
    bVar3 = false;
  }
  if (cVar4 != '2') {
    if (cVar4 < '3') {
      if (cVar4 == '\x1e') goto LAB_0002226e;
    }
    else {
      if (cVar4 != '3') {
        if (cVar4 != '<') goto LAB_00022154;
        _KillEggBlock(iVar8,iVar9,iVar10);
      }
      bVar3 = true;
    }
LAB_00022154:
    if (bVar2) {
      return 1;
    }
    if (!bVar3) {
      return 0;
    }
    return 2;
  }
LAB_0002226e:
  _PlayMySnd(7,10,0);
  return 1;
}


// ==== _MoveHeroNotAligned @ 000224c8 ====

void _MoveHeroNotAligned(void)

{
  short sVar1;
  bool bVar2;
  undefined *puVar3;
  undefined *puVar4;
  short sVar5;
  
  puVar4 = PTR__gStackLevel_0003f094;
  puVar3 = PTR__hero_0003f014;
  sVar5 = *(short *)(PTR__hero_0003f014 + 0x26);
  if (sVar5 == 2) {
    if (_gHero_UpKeyPressed != '\0') {
      *(undefined2 *)(PTR__hero_0003f014 + 0x26) = 1;
      sVar5 = *(short *)puVar4;
      *(undefined2 *)(puVar3 + 0x3c) = 2;
      if (((_gLevelForEffect <= (uint)(int)sVar5) && (sVar5 = _GetRandomFast(0,1), sVar5 == 1)) &&
         (puVar3[0x3a] == '\0')) {
        *(undefined2 *)(puVar3 + 0x3c) = 3;
      }
      goto LAB_000225df;
    }
LAB_0002250b:
    bVar2 = false;
    sVar5 = *(short *)(PTR__hero_0003f014 + 0x26);
    sVar1 = sVar5 + -2;
    if (sVar5 != 2) goto LAB_0002251b;
LAB_000225ed:
    _MyOffsetRect(puVar3 + 0x14,0,(int)*(short *)(puVar3 + 0x66));
    sVar5 = *(short *)(puVar3 + 0x38);
    *(short *)(puVar3 + 0x38) = sVar5 + *(short *)(puVar3 + 0x66);
    if ((short)(sVar5 + *(short *)(puVar3 + 0x66)) != 0x28) goto LAB_0002255b;
    puVar3[0x34] = puVar3[0x34] + '\x01';
  }
  else {
    if (sVar5 < 3) {
      if (sVar5 != 1) {
        return;
      }
      if (_gHero_DownKeyPressed != '\0') {
        *(undefined2 *)(PTR__hero_0003f014 + 0x26) = 2;
        sVar5 = *(short *)puVar4;
        *(undefined2 *)(puVar3 + 0x3c) = 3;
        if (((_gLevelForEffect <= (uint)(int)sVar5) && (sVar5 = _GetRandomFast(0,1), sVar5 == 1)) &&
           (puVar3[0x3a] == '\0')) {
          *(undefined2 *)(puVar3 + 0x3c) = 2;
        }
        goto LAB_000225df;
      }
      goto LAB_0002250b;
    }
    if (sVar5 != 3) {
      if (sVar5 != 4) {
        return;
      }
      if (_gHero_LeftKeyPressed != '\0') {
        *(undefined2 *)(PTR__hero_0003f014 + 0x26) = 3;
        sVar5 = *(short *)puVar4;
        *(undefined2 *)(puVar3 + 0x3c) = 4;
        if (((_gLevelForEffect <= (uint)(int)sVar5) && (sVar5 = _GetRandomFast(0,1), sVar5 == 1)) &&
           (puVar3[0x3a] == '\0')) {
          *(undefined2 *)(puVar3 + 0x3c) = 4;
        }
        goto LAB_000225df;
      }
      goto LAB_0002250b;
    }
    if (_gHero_RightKeyPressed == '\0') goto LAB_0002250b;
    *(undefined2 *)(PTR__hero_0003f014 + 0x26) = 4;
    sVar5 = *(short *)puVar4;
    *(undefined2 *)(puVar3 + 0x3c) = 5;
    if (((_gLevelForEffect <= (uint)(int)sVar5) && (sVar5 = _GetRandomFast(0,1), sVar5 == 1)) &&
       (puVar3[0x3a] == '\0')) {
      *(undefined2 *)(puVar3 + 0x3c) = 5;
    }
LAB_000225df:
    bVar2 = true;
    sVar5 = *(short *)(puVar3 + 0x26);
    sVar1 = sVar5 + -2;
    if (sVar1 == 0) goto LAB_000225ed;
LAB_0002251b:
    if (SBORROW2(sVar5,2) == sVar1 < 0) {
      if (sVar5 == 3) {
        _MyOffsetRect(puVar3 + 0x14,(int)-*(short *)(puVar3 + 0x66),0);
        sVar5 = *(short *)(puVar3 + 0x36);
        *(short *)(puVar3 + 0x36) = sVar5 - *(short *)(puVar3 + 0x66);
        if ((short)(sVar5 - *(short *)(puVar3 + 0x66)) != -0x28) goto LAB_0002255b;
        puVar3[0x28] = puVar3[0x28] + -1;
      }
      else {
        if (sVar5 != 4) {
          return;
        }
        _MyOffsetRect(puVar3 + 0x14,(int)*(short *)(puVar3 + 0x66),0);
        sVar5 = *(short *)(puVar3 + 0x36);
        *(short *)(puVar3 + 0x36) = sVar5 + *(short *)(puVar3 + 0x66);
        if ((short)(sVar5 + *(short *)(puVar3 + 0x66)) != 0x28) goto LAB_0002255b;
        puVar3[0x28] = puVar3[0x28] + '\x01';
      }
      *(undefined2 *)(puVar3 + 0x36) = 0;
      goto LAB_0002255b;
    }
    if (sVar5 != 1) {
      return;
    }
    _MyOffsetRect(puVar3 + 0x14,0,(int)-*(short *)(puVar3 + 0x66));
    sVar5 = *(short *)(puVar3 + 0x38);
    *(short *)(puVar3 + 0x38) = sVar5 - *(short *)(puVar3 + 0x66);
    if ((short)(sVar5 - *(short *)(puVar3 + 0x66)) != -0x28) goto LAB_0002255b;
    puVar3[0x34] = puVar3[0x34] + -1;
  }
  *(undefined2 *)(puVar3 + 0x38) = 0;
LAB_0002255b:
  puVar3 = PTR__hero_0003f014;
  if (bVar2) {
    sVar5 = *(short *)(PTR__hero_0003f014 + 0x3e);
    *(short *)(PTR__hero_0003f014 + 0x3e) = sVar5 + -1;
    if ((short)(sVar5 + -1) < 1) {
      *(undefined2 *)(puVar3 + 0x3e) = 8;
    }
  }
  else {
    sVar5 = 1;
    if ((short)(*(short *)(PTR__hero_0003f014 + 0x3e) + 1) < 9) {
      sVar5 = *(short *)(PTR__hero_0003f014 + 0x3e) + 1;
    }
    *(short *)(PTR__hero_0003f014 + 0x3e) = sVar5;
  }
  puVar3[0x35] = 0;
  if ((*(short *)(puVar3 + 0x36) == 0) && (*(short *)(puVar3 + 0x38) == 0)) {
    puVar3[0x35] = 1;
    return;
  }
  return;
}


// ==== _MoveHeroAligned @ 00022847 ====

void _MoveHeroAligned(void)

{
  char cVar1;
  undefined *puVar2;
  undefined *puVar3;
  char cVar4;
  short sVar5;
  undefined1 uVar6;
  ushort uVar7;
  
  puVar3 = PTR__gStackLevel_0003f094;
  puVar2 = PTR__hero_0003f014;
  cVar4 = PTR__hero_0003f014[0x28];
  cVar1 = PTR__hero_0003f014[0x34];
  if (_gHero_UpKeyPressed == '\0') {
    if (_gHero_DownKeyPressed == '\0') {
      if (_gHero_LeftKeyPressed == '\0') {
        if (_gHero_RightKeyPressed == '\0') {
          uVar7 = 0;
          _DebugValues("MoveHeroAligned() - No movement key was down!",0xffffffff);
          uVar6 = 0;
        }
        else {
          *(undefined2 *)(PTR__hero_0003f014 + 0x3c) = 5;
          if (((_gLevelForEffect <= (uint)(int)*(short *)puVar3) &&
              (sVar5 = _GetRandomFast(0,1), sVar5 == 1)) && (puVar2[0x3a] == '\0')) {
            *(undefined2 *)(puVar2 + 0x3c) = 4;
          }
          uVar7 = 4;
          uVar6 = 4;
        }
      }
      else {
        *(undefined2 *)(PTR__hero_0003f014 + 0x3c) = 4;
        if (((_gLevelForEffect <= (uint)(int)*(short *)puVar3) &&
            (sVar5 = _GetRandomFast(0,1), sVar5 == 1)) && (puVar2[0x3a] == '\0')) {
          *(undefined2 *)(puVar2 + 0x3c) = 5;
        }
        uVar7 = 3;
        uVar6 = 3;
      }
    }
    else {
      *(undefined2 *)(PTR__hero_0003f014 + 0x3c) = 3;
      if (((_gLevelForEffect <= (uint)(int)*(short *)puVar3) &&
          (sVar5 = _GetRandomFast(0,1), sVar5 == 1)) && (puVar2[0x3a] == '\0')) {
        *(undefined2 *)(puVar2 + 0x3c) = 2;
      }
      uVar7 = 2;
      uVar6 = 2;
    }
  }
  else {
    *(undefined2 *)(PTR__hero_0003f014 + 0x3c) = 2;
    if (((_gLevelForEffect <= (uint)(int)*(short *)puVar3) &&
        (sVar5 = _GetRandomFast(0,1), sVar5 == 1)) && (puVar2[0x3a] == '\0')) {
      *(undefined2 *)(puVar2 + 0x3c) = 3;
    }
    uVar7 = 1;
    uVar6 = 1;
  }
  *(ushort *)(puVar2 + 0x26) = uVar7;
  *(undefined2 *)(puVar2 + 0x3e) = 1;
  cVar4 = _GetNextObject(uVar6,(int)cVar4,(int)cVar1);
  if ((cVar4 != '\0') && (cVar4 != 'P')) {
    return;
  }
  if (uVar7 == 2) {
    _MyOffsetRect(puVar2 + 0x14,0,(int)*(short *)(puVar2 + 0x66));
    sVar5 = *(short *)(puVar2 + 0x38);
    *(short *)(puVar2 + 0x38) = sVar5 + *(short *)(puVar2 + 0x66);
    if ((short)(sVar5 + *(short *)(puVar2 + 0x66)) != 0x28) goto LAB_00022948;
    puVar2[0x34] = puVar2[0x34] + '\x01';
  }
  else {
    if (2 < uVar7) {
      if (uVar7 == 3) {
        _MyOffsetRect(puVar2 + 0x14,(int)-*(short *)(puVar2 + 0x66),0);
        sVar5 = *(short *)(puVar2 + 0x36);
        *(short *)(puVar2 + 0x36) = sVar5 - *(short *)(puVar2 + 0x66);
        if ((short)(sVar5 - *(short *)(puVar2 + 0x66)) != -0x28) goto LAB_00022948;
        puVar2[0x28] = puVar2[0x28] + -1;
      }
      else {
        if (uVar7 != 4) goto LAB_00022948;
        _MyOffsetRect(puVar2 + 0x14,(int)*(short *)(puVar2 + 0x66),0);
        sVar5 = *(short *)(puVar2 + 0x36);
        *(short *)(puVar2 + 0x36) = sVar5 + *(short *)(puVar2 + 0x66);
        if ((short)(sVar5 + *(short *)(puVar2 + 0x66)) != 0x28) goto LAB_00022948;
        puVar2[0x28] = puVar2[0x28] + '\x01';
      }
      *(undefined2 *)(puVar2 + 0x36) = 0;
      goto LAB_00022948;
    }
    if (uVar7 != 1) goto LAB_00022948;
    _MyOffsetRect(puVar2 + 0x14,0,(int)-*(short *)(puVar2 + 0x66));
    sVar5 = *(short *)(puVar2 + 0x38);
    *(short *)(puVar2 + 0x38) = sVar5 - *(short *)(puVar2 + 0x66);
    if ((short)(sVar5 - *(short *)(puVar2 + 0x66)) != -0x28) goto LAB_00022948;
    puVar2[0x34] = puVar2[0x34] + -1;
  }
  *(undefined2 *)(puVar2 + 0x38) = 0;
LAB_00022948:
  puVar2 = PTR__hero_0003f014;
  PTR__hero_0003f014[0x35] = 0;
  if ((*(short *)(puVar2 + 0x36) == 0) && (*(short *)(puVar2 + 0x38) == 0)) {
    puVar2[0x35] = 1;
    return;
  }
  return;
}


// ==== _DrawHeroToComp @ 00022b8b ====

void _DrawHeroToComp(void)

{
  short sVar1;
  undefined *puVar2;
  undefined1 local_14 [8];
  
  puVar2 = PTR__hero_0003f014;
  sVar1 = *(short *)(PTR__hero_0003f014 + 2);
  if (1 < sVar1) {
    if (sVar1 < 4) {
      if (PTR__hero_0003f014[0x4a] != '\0') {
        if (PTR__hero_0003f014[0x51] == '\0') {
          _SpriteToComp(0,(int)*(short *)(PTR__hero_0003f014 + 0x16),
                        (int)*(short *)(PTR__hero_0003f014 + 0x14),
                        (int)*(short *)(PTR__hero_0003f014 + 0x3c),
                        (int)*(short *)(PTR__hero_0003f014 + 0x3e),1);
        }
        else {
          _TransSpriteToComp(0,(int)*(short *)(PTR__hero_0003f014 + 0x16),
                             (int)*(short *)(PTR__hero_0003f014 + 0x14),
                             (int)*(short *)(PTR__hero_0003f014 + 0x3c),
                             (int)*(short *)(PTR__hero_0003f014 + 0x3e),1);
        }
      }
      _UnionRect(puVar2 + 0x1c,puVar2 + 0x14,local_14);
      _AddRectToScreen(local_14);
      puVar2 = PTR__hero_0003f014;
    }
    else if (sVar1 == 4) {
      if (*(short *)(PTR__hero_0003f014 + 0x48) < 0x10) {
        if (PTR__hero_0003f014[0x4a] != '\0') {
          _SpriteToComp(0,(int)*(short *)(PTR__hero_0003f014 + 0x16),
                        (int)*(short *)(PTR__hero_0003f014 + 0x14),
                        (int)*(short *)(PTR__hero_0003f014 + 0x3c),
                        (int)*(short *)(PTR__hero_0003f014 + 0x3e),1);
        }
        _UnionRect(puVar2 + 0x1c,puVar2 + 0x14,local_14);
        _AddRectToScreen(local_14);
      }
      else {
        _AddRectToScreen(PTR__hero_0003f014 + 0x1c);
      }
    }
  }
  *(undefined4 *)(puVar2 + 0x1c) = *(undefined4 *)(puVar2 + 0x14);
  *(undefined4 *)(puVar2 + 0x20) = *(undefined4 *)(puVar2 + 0x18);
  return;
}


// ==== _EraseOuch @ 00022ce3 ====

void _EraseOuch(void)

{
  _AddRectToBgnd(&_gOuchR);
  _AddRectToScreen(&_gOuchR);
  return;
}


// ==== _DrawOuchToComp @ 00022d03 ====

void _DrawOuchToComp(void)

{
  if (*(short *)(PTR__hero_0003f014 + 2) != 3) {
    return;
  }
  _SpriteToComp(0,(int)DAT_000379da,(int)_gOuchR,0x10,(int)_gOuchSpriteFace,1);
  _AddRectToScreen(&_gOuchR);
  return;
}


// ==== _AddHero @ 00022d62 ====

void _AddHero(short param_1,char param_2)

{
  short sVar1;
  
  _AddLives((int)param_1);
  sVar1 = _GetLives();
  if (9 < sVar1) {
    _SetLives(9);
  }
  if (param_2 != '\0') {
    _PlayMySnd(0xd,0x14,0);
    _PlayMySnd(0xd,0x14,0);
  }
  _gReserveHero_NeedsDrawing = 1;
  _gReserveHero_Animate = 1;
  return;
}


// ==== _ProcessHero @ 00022de0 ====

void _ProcessHero(void)

{
  undefined4 uVar1;
  bool bVar2;
  undefined1 uVar3;
  byte bVar4;
  char cVar5;
  byte bVar6;
  short sVar7;
  ushort uVar8;
  uint uVar9;
  char *pcVar10;
  int iVar11;
  undefined *puVar12;
  undefined *puVar13;
  undefined4 uVar14;
  int local_58;
  int local_48;
  undefined4 local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined1 local_20;
  byte local_1f [15];
  
  puVar13 = PTR__hero_0003f014;
  _AddRectToBgnd(PTR__hero_0003f014 + 0x1c);
  sVar7 = *(short *)(puVar13 + 2);
  if (sVar7 == 3) {
    return;
  }
  if (sVar7 != 4) {
    if (sVar7 == 1) {
      return;
    }
    if (_gLevelForEffect == 0x32) {
      _gLevelForEffect = _Get13To22();
    }
    puVar13 = PTR__hero_0003f014;
    if (PTR__hero_0003f014[0x50] != '\0') {
      uVar9 = _GetFrameCounter();
      if (*(ushort *)(puVar13 + 0x52) + 300 < (uVar9 & 0xffff)) {
        puVar13[0x50] = 0;
        puVar13[0x51] = 0;
      }
      else {
        uVar9 = _GetFrameCounter();
        if (*(ushort *)(puVar13 + 0x52) + 0xd2 < (uVar9 & 0xffff)) {
          sVar7 = *(short *)(puVar13 + 0x5c);
          *(short *)(puVar13 + 0x5c) = sVar7 + 1;
          if (2 < (short)(sVar7 + 1)) {
            *(undefined2 *)(puVar13 + 0x5c) = 0;
            puVar13[0x5e] = puVar13[0x5e] == '\0';
          }
          puVar13[0x51] = puVar13[0x5e];
        }
      }
    }
    puVar12 = puVar13;
    if (puVar13[0x5f] != '\0') {
      uVar9 = _GetFrameCounter();
      if (*(ushort *)(puVar13 + 0x60) + 0x1c2 < (uVar9 & 0xffff)) {
        puVar13[0x5f] = 0;
        *(undefined2 *)(puVar13 + 0x66) = 5;
        puVar12 = PTR__hero_0003f014;
      }
      else {
        uVar9 = _GetFrameCounter();
        puVar12 = PTR__hero_0003f014;
        if ((*(ushort *)(puVar13 + 0x60) + 0x168 < (uVar9 & 0xffff)) &&
           (sVar7 = *(short *)(puVar13 + 0x62), *(short *)(puVar13 + 0x62) = sVar7 + 1,
           puVar12 = PTR__hero_0003f014, 6 < (short)(sVar7 + 1))) {
          *(undefined2 *)(puVar13 + 0x62) = 0;
          puVar13[100] = puVar13[100] == '\0';
          puVar12 = PTR__hero_0003f014;
        }
      }
    }
    if (puVar12[0x4c] != '\0') {
      uVar9 = _GetFrameCounter();
      if ((uVar9 & 0xffff) <= *(ushort *)(puVar12 + 0x4e) + 0x5a) {
        return;
      }
      puVar12[0x4c] = 0;
      return;
    }
    if (puVar12[0x40] != '\0') {
      sVar7 = *(short *)(puVar12 + 0x42);
      *(short *)(puVar12 + 0x42) = sVar7 + 1;
      if ((short)(sVar7 + 1) <= *(short *)(puVar12 + 0x46)) {
        return;
      }
      puVar12[0x40] = 0;
      sVar7 = *(short *)(puVar12 + 0x26);
      puVar13 = puVar12;
      if (sVar7 == 1) {
        *(undefined2 *)(puVar12 + 0x3c) = 2;
        if (((_gLevelForEffect <= (uint)(int)*(short *)PTR__gStackLevel_0003f094) &&
            (sVar7 = _GetRandomFast(0,1), puVar13 = PTR__hero_0003f014, sVar7 == 1)) &&
           (puVar12[0x3a] == '\0')) {
          *(undefined2 *)(puVar12 + 0x3c) = 3;
          puVar13 = PTR__hero_0003f014;
        }
      }
      else if (sVar7 == 2) {
        *(undefined2 *)(puVar12 + 0x3c) = 3;
        if (((_gLevelForEffect <= (uint)(int)*(short *)PTR__gStackLevel_0003f094) &&
            (sVar7 = _GetRandomFast(0,1), puVar13 = PTR__hero_0003f014, sVar7 == 1)) &&
           (puVar12[0x3a] == '\0')) {
          *(undefined2 *)(puVar12 + 0x3c) = 2;
          puVar13 = PTR__hero_0003f014;
        }
      }
      else if (sVar7 == 3) {
        *(undefined2 *)(puVar12 + 0x3c) = 4;
        if (((_gLevelForEffect <= (uint)(int)*(short *)PTR__gStackLevel_0003f094) &&
            (sVar7 = _GetRandomFast(0,1), puVar13 = PTR__hero_0003f014, sVar7 == 1)) &&
           (puVar12[0x3a] == '\0')) {
          *(undefined2 *)(puVar12 + 0x3c) = 5;
          puVar13 = PTR__hero_0003f014;
        }
      }
      else if ((((sVar7 == 4) &&
                (*(undefined2 *)(puVar12 + 0x3c) = 5,
                _gLevelForEffect <= (uint)(int)*(short *)PTR__gStackLevel_0003f094)) &&
               (sVar7 = _GetRandomFast(0,1), puVar13 = PTR__hero_0003f014, sVar7 == 1)) &&
              (puVar12[0x3a] == '\0')) {
        *(undefined2 *)(puVar12 + 0x3c) = 4;
        puVar13 = PTR__hero_0003f014;
      }
      *(undefined2 *)(puVar13 + 0x3e) = 1;
      return;
    }
    if (*(short *)(puVar12 + 2) == 2) {
      _CheckHeroMovement();
    }
    if (puVar12[0x35] == '\0') {
      _MoveHeroNotAligned();
      if (puVar12[0x5f] == '\0') {
        return;
      }
      if (puVar12[100] == '\0') {
        return;
      }
      sVar7 = *(short *)(puVar12 + 0x26);
      if (sVar7 == 2) {
        uVar14 = 7;
      }
      else if (sVar7 < 3) {
        if (sVar7 != 1) {
          return;
        }
        uVar14 = 6;
      }
      else if (sVar7 == 3) {
        uVar14 = 8;
      }
      else {
        if (sVar7 != 4) {
          return;
        }
        uVar14 = 9;
      }
      _NewStarGroup((char)puVar12[0x28] * 0x28,(char)puVar12[0x34] * 0x28,uVar14);
      return;
    }
    if (_gHero_PushKeyPressed != '\0') {
      sVar7 = _HeroPushCrushCheck();
      if (sVar7 == 1) {
        *(undefined2 *)(puVar12 + 0x3c) = 6;
        uVar3 = _RT3_IsRegistered();
        puVar12[0x3a] = uVar3;
        *(undefined2 *)(puVar12 + 0x3e) = *(undefined2 *)(puVar12 + 0x26);
        puVar12[0x40] = 1;
        local_1f[0] = 0x49;
        local_1f[1] = 0x71;
        local_1f[2] = 0xad;
        local_30 = DAT_00033af0;
        local_2c = DAT_00033af4;
        local_28 = DAT_00033af8;
        local_24 = DAT_00033afc;
        local_20 = DAT_00033b00;
        local_48 = *(int *)(puVar12 + 8);
        pcVar10 = (char *)_RT3_CheckLicenseName(*(undefined4 *)(puVar12 + 0x10));
        uVar14 = *(undefined4 *)(puVar12 + 0x2c);
        uVar1 = *(undefined4 *)(puVar12 + 0x30);
        if (pcVar10 != (char *)0x0) {
          cVar5 = *pcVar10;
          if (cVar5 < '0') {
            if (cVar5 == '\0') goto LAB_0002348a;
          }
          else if (cVar5 < ':') {
            local_48 = 1;
          }
          while (iVar11 = _StringGetLength(pcVar10), iVar11 != 0) {
            iVar11 = _StringGetLength(&local_30);
            if (0x10 < iVar11 + 1U) break;
            _StringAppendSafe(&local_30,pcVar10,0x11);
          }
        }
LAB_0002348a:
        bVar4 = (local_24._2_1_ ^ 0x58 ^ (byte)local_48) + 0x78;
        bVar4 = (((bVar4 * '\x04' | bVar4 >> 6) ^ local_30._1_1_) + 0x3f ^ local_30._3_1_) + 0xb4;
        bVar4 = (bVar4 * '\x04' | bVar4 >> 6) ^ (byte)local_48;
        if (bVar4 < 0x54) {
          bVar4 = bVar4 ^ local_28._2_1_;
        }
        bVar4 = ((bVar4 >> 1 | bVar4 << 7) ^ (byte)local_48) + 0xba ^ 0x75;
        bVar4 = bVar4 << 6 | bVar4 >> 2;
        if ((int)(uint)bVar4 < (int)(char)local_2c) {
          bVar4 = bVar4 ^ 0x62;
        }
        bVar4 = (bVar4 ^ local_24._1_1_) + 0x29 ^ local_24._3_1_;
        cVar5 = _IsPlatformOpen();
        bVar6 = bVar4 * cVar5 + 3;
        bVar4 = bVar6 >> 3;
        uVar8 = _RT3_ExtractLicenseBlock2(uVar14,uVar1);
        bVar4 = (bVar4 << 7 | (byte)(bVar6 * ' ' | bVar4) >> 1) + 0x7e;
        bVar4 = (bVar4 * '\x10' | bVar4 >> 4) ^ (byte)local_48;
        bVar4 = (bVar4 << 7 | bVar4 >> 1) ^ local_24._1_1_;
        bVar4 = (bVar4 << 2 | bVar4 >> 6) ^ local_2c._3_1_;
        bVar4 = (bVar4 << 5 | bVar4 >> 3) + 0x47;
        if (bVar4 < 0x44) {
          bVar4 = bVar4 * '\x04' | bVar4 >> 6;
        }
        bVar6 = bVar4 + 0x11;
        if (0x79 < bVar4) {
          bVar6 = bVar4;
        }
        bVar4 = (bVar6 << 4 | bVar6 >> 4) ^ 0x62 ^ (byte)local_24;
        _Useless8();
        bVar4 = ((bVar4 >> 4 | bVar4 << 4) + 0x6c ^ 0x65 ^ (byte)local_28 ^ (byte)local_30) - 0x39;
        bVar4 = (bVar4 * '\x10' | bVar4 >> 4) + 0x21 ^ (byte)local_30;
        bVar4 = (bVar4 << 6 | bVar4 >> 2) ^ (byte)local_48;
        _Useless7();
        puVar13 = PTR__hero_0003f014;
        bVar4 = (bVar4 >> 1 | bVar4 << 7) - 0x1d ^ local_30._2_1_ ^ local_28._3_1_;
        bVar4 = (bVar4 << 4 | bVar4 >> 4) - 0x2f ^ 0x65 ^ local_28._2_1_;
        if ((bVar4 < 0x54) && (bVar4 < 0x42)) {
          bVar4 = bVar4 - 0x19;
        }
        bVar4 = (local_28._2_1_ ^ (bVar4 << 3 | bVar4 >> 5)) + 0x10;
        if (bVar4 < 0x75) {
          bVar4 = bVar4 ^ (byte)local_28;
        }
        bVar4 = bVar4 << 6 | (bVar4 ^ 0x20) >> 2;
        if (0x20 < bVar4) {
          bVar4 = (byte)local_48 ^ bVar4;
        }
        bVar4 = bVar4 + 0x52 ^ (byte)local_48;
        bVar4 = ((bVar4 << 4 | bVar4 >> 4) ^ 0xb5) + 0x48;
        bVar4 = (bVar4 * '\b' | bVar4 >> 5) ^ (byte)local_48;
        bVar6 = ((bVar4 << 1 | (char)bVar4 < '\0') + 0x51 ^ (byte)local_48) - 5 ^ 0x6c;
        bVar4 = bVar6 + 0x32;
        if (0x58 < bVar4) {
          bVar4 = bVar6 + 0x4d;
        }
        bVar4 = ((byte)local_48 ^
                ((bVar4 - 0x3f) * '\b' | (byte)(bVar4 - 0x3f) >> 5) + 0xa1 ^ local_2c._2_1_ ^ 0x6c)
                + 0x51;
        bVar4 = bVar4 * ' ' | bVar4 >> 3;
        if (bVar4 < 3) {
          bVar4 = local_1f[bVar4];
        }
        for (; bVar4 <= uVar8; uVar8 = uVar8 - bVar4) {
        }
        if ((local_48 == 0) || (uVar8 != 0)) {
          uVar3 = 0;
        }
        else {
          uVar3 = 1;
        }
        PTR__hero_0003f014[0x44] = uVar3;
        *(undefined2 *)(puVar13 + 0x42) = 0;
        *(undefined2 *)(puVar13 + 0x46) = 2;
        return;
      }
      if (sVar7 == 2) {
        *(undefined2 *)(puVar12 + 0x3c) = 6;
        *(undefined2 *)(puVar12 + 0x3e) = *(undefined2 *)(puVar12 + 0x26);
        puVar12[0x40] = 1;
        *(undefined2 *)(puVar12 + 0x42) = 0;
        if ((puVar12[0x24] == '\0') &&
           (*(int *)(puVar12 + 0x58) != 0 || *(int *)(puVar12 + 0x54) != 0)) {
          iVar11 = _GetScore();
          if ((0x4603 < iVar11) && (sVar7 = _GetRandomFast(0,0x1e), sVar7 == 1)) {
            if (*(short *)(puVar12 + 0x66) == 5) {
              *(undefined2 *)(puVar12 + 0x66) = 1;
            }
            else {
              *(undefined2 *)(puVar12 + 0x66) = 5;
            }
          }
          bVar2 = false;
        }
        else {
          bVar2 = true;
        }
        *(undefined2 *)(PTR__hero_0003f014 + 0x46) = 5;
        if (bVar2) {
          return;
        }
      }
    }
    if (_gHero_MoveKeyDown == '\0') {
      return;
    }
    _MoveHeroAligned();
    return;
  }
  *(undefined2 *)(puVar13 + 0x3c) = 7;
  *(short *)(puVar13 + 0x42) = *(short *)(puVar13 + 0x42) + 1;
  local_1f[0] = 0x49;
  local_1f[1] = 0x71;
  local_1f[2] = 0xad;
  local_30 = DAT_00033af0;
  local_2c = DAT_00033af4;
  local_28 = DAT_00033af8;
  local_24 = DAT_00033afc;
  local_20 = DAT_00033b00;
  local_58 = *(int *)(puVar13 + 8);
  pcVar10 = (char *)_RT3_CheckLicenseName(*(undefined4 *)(puVar13 + 0x10));
  uVar14 = *(undefined4 *)(puVar13 + 0x54);
  uVar1 = *(undefined4 *)(puVar13 + 0x58);
  if (pcVar10 != (char *)0x0) {
    cVar5 = *pcVar10;
    if (cVar5 < '0') {
      if (cVar5 == '\0') goto LAB_00022ed9;
    }
    else if (cVar5 < ':') {
      local_58 = 1;
    }
    while (iVar11 = _StringGetLength(pcVar10), iVar11 != 0) {
      iVar11 = _StringGetLength(&local_30);
      if (0x10 < iVar11 + 1U) break;
      _StringAppendSafe(&local_30,pcVar10,0x11);
    }
  }
LAB_00022ed9:
  bVar4 = (local_24._2_1_ ^ 0x58 ^ (byte)local_58) + 0x78;
  bVar4 = (((bVar4 * '\x04' | bVar4 >> 6) ^ local_30._1_1_) + 0x3f ^ local_30._3_1_) + 0xb4;
  bVar4 = (bVar4 * '\x04' | bVar4 >> 6) ^ (byte)local_58;
  if (bVar4 < 0x54) {
    bVar4 = bVar4 ^ local_28._2_1_;
  }
  bVar4 = ((bVar4 >> 1 | bVar4 << 7) ^ (byte)local_58) + 0xba ^ 0x75;
  bVar4 = bVar4 << 6 | bVar4 >> 2;
  if ((int)(uint)bVar4 < (int)(char)local_2c) {
    bVar4 = bVar4 ^ 0x62;
  }
  bVar4 = (bVar4 ^ local_24._1_1_) + 0x29 ^ local_24._3_1_;
  cVar5 = _IsPlatformOpen();
  bVar6 = bVar4 * cVar5 + 3;
  bVar4 = bVar6 >> 3;
  uVar8 = _RT3_ExtractLicenseBlock2(uVar14,uVar1);
  bVar4 = (bVar4 << 7 | (byte)(bVar6 * ' ' | bVar4) >> 1) + 0x7e;
  bVar4 = (bVar4 * '\x10' | bVar4 >> 4) ^ (byte)local_58;
  bVar4 = (bVar4 << 7 | bVar4 >> 1) ^ local_24._1_1_;
  bVar4 = (bVar4 << 2 | bVar4 >> 6) ^ local_2c._3_1_;
  bVar4 = (bVar4 << 5 | bVar4 >> 3) + 0x47;
  if (bVar4 < 0x44) {
    bVar4 = bVar4 * '\x04' | bVar4 >> 6;
  }
  bVar6 = bVar4 + 0x11;
  if (0x79 < bVar4) {
    bVar6 = bVar4;
  }
  bVar4 = (bVar6 << 4 | bVar6 >> 4) ^ 0x62 ^ (byte)local_24;
  _Useless8();
  bVar4 = ((bVar4 >> 4 | bVar4 << 4) + 0x6c ^ 0x65 ^ (byte)local_28 ^ (byte)local_30) - 0x39;
  bVar4 = (bVar4 * '\x10' | bVar4 >> 4) + 0x21 ^ (byte)local_30;
  bVar4 = (bVar4 << 6 | bVar4 >> 2) ^ (byte)local_58;
  _Useless7();
  puVar13 = PTR__hero_0003f014;
  bVar4 = (bVar4 >> 1 | bVar4 << 7) - 0x1d ^ local_30._2_1_ ^ local_28._3_1_;
  bVar4 = (bVar4 << 4 | bVar4 >> 4) - 0x2f ^ 0x65 ^ local_28._2_1_;
  if ((bVar4 < 0x54) && (bVar4 < 0x42)) {
    bVar4 = bVar4 - 0x19;
  }
  bVar4 = (local_28._2_1_ ^ (bVar4 << 3 | bVar4 >> 5)) + 0x10;
  if (bVar4 < 0x75) {
    bVar4 = bVar4 ^ (byte)local_28;
  }
  bVar4 = bVar4 << 6 | (bVar4 ^ 0x20) >> 2;
  if (0x20 < bVar4) {
    bVar4 = (byte)local_58 ^ bVar4;
  }
  bVar4 = bVar4 + 0x52 ^ (byte)local_58;
  bVar4 = ((bVar4 << 4 | bVar4 >> 4) ^ 0xb5) + 0x48;
  bVar4 = (bVar4 * '\b' | bVar4 >> 5) ^ (byte)local_58;
  bVar6 = ((bVar4 << 1 | (char)bVar4 < '\0') + 0x51 ^ (byte)local_58) - 5 ^ 0x6c;
  bVar4 = bVar6 + 0x32;
  if (0x58 < bVar4) {
    bVar4 = bVar6 + 0x4d;
  }
  bVar4 = ((byte)local_58 ^
          ((bVar4 - 0x3f) * '\b' | (byte)(bVar4 - 0x3f) >> 5) + 0xa1 ^ local_2c._2_1_ ^ 0x6c) + 0x51
  ;
  bVar4 = bVar4 * ' ' | bVar4 >> 3;
  if (bVar4 < 3) {
    bVar4 = local_1f[bVar4];
  }
  for (; bVar4 <= uVar8; uVar8 = uVar8 - bVar4) {
  }
  if ((local_58 == 0) || (uVar8 != 0)) {
    uVar3 = 0;
  }
  else {
    uVar3 = 1;
  }
  PTR__hero_0003f014[0x24] = uVar3;
  if (1 < *(short *)(puVar13 + 0x42)) {
    *(undefined2 *)(puVar13 + 0x42) = 0;
    sVar7 = *(short *)(puVar13 + 0x3e);
    *(short *)(puVar13 + 0x3e) = sVar7 + 1;
    if (0x10 < (short)(sVar7 + 1)) {
      if ((puVar13[0x4a] != '\0') && (puVar13[0x4b] == '\0')) {
        _Bubbles_NewGroup((int)*(short *)(puVar13 + 0x16),(int)*(short *)(puVar13 + 0x14),0xb);
        puVar13[0x4b] = 1;
      }
      *(undefined2 *)(puVar13 + 0x3e) = 0x10;
      *(short *)(puVar13 + 0x48) = *(short *)(puVar13 + 0x48) + 1;
    }
  }
  return;
}


// ==== _Balloons_ResetBalloon @ 000237da ====

void _Balloons_ResetBalloon(short param_1)

{
  (&_gBalloons)[param_1 * 0x2c] = 0;
  _gBalloons_NumActive = _gBalloons_NumActive + -1;
  return;
}


// ==== _Balloons_New @ 000237f9 ====

void _Balloons_New(short param_1)

{
  char cVar1;
  undefined *puVar2;
  undefined2 uVar3;
  char *pcVar4;
  short sVar5;
  short sVar6;
  int iVar7;
  int iVar8;
  int iVar9;
  undefined4 uVar10;
  undefined4 uVar11;
  
  if (_gBalloons_NumActive != 0x1e) {
    uVar3 = _GetFrameCounter();
    puVar2 = PTR__enemy_0003f04c;
    iVar7 = 0;
    pcVar4 = &_gBalloons;
    iVar9 = (int)param_1;
    iVar8 = 0;
    do {
      if (*pcVar4 == '\0') {
        cVar1 = PTR__enemy_0003f04c[iVar9 * 0x5c + 0x23];
        if (cVar1 == '\x02') {
          sVar5 = *(short *)(PTR__enemy_0003f04c + iVar9 * 0x5c + 0x14);
          *(short *)((int)&DAT_00037a06 + iVar8) = sVar5 + 0xb;
          sVar6 = *(short *)(puVar2 + iVar9 * 0x5c + 0x16);
          *(short *)((int)&DAT_00037a04 + iVar8) = sVar6 + 0x14;
          *(short *)((int)&DAT_00037a0a + iVar8) = sVar5 + 0x1c;
          sVar6 = sVar6 + 0x25;
        }
        else if (cVar1 < '\x03') {
          if (cVar1 != '\x01') {
            return;
          }
          sVar5 = *(short *)(PTR__enemy_0003f04c + iVar9 * 0x5c + 0x14);
          *(short *)((int)&DAT_00037a06 + iVar8) = sVar5 + 0xb;
          sVar6 = *(short *)(puVar2 + iVar9 * 0x5c + 0x12);
          *(short *)((int)&DAT_00037a04 + iVar8) = sVar6 + -0x25;
          *(short *)((int)&DAT_00037a0a + iVar8) = sVar5 + 0x1c;
          sVar6 = sVar6 + -0x14;
        }
        else {
          if (cVar1 == '\x03') {
            sVar5 = *(short *)(PTR__enemy_0003f04c + iVar9 * 0x5c + 0x14);
            *(short *)((int)&DAT_00037a06 + iVar8) = sVar5 + -0x25;
            sVar6 = *(short *)(puVar2 + iVar9 * 0x5c + 0x12);
            *(short *)((int)&DAT_00037a04 + iVar8) = sVar6 + 0xb;
            sVar5 = sVar5 + -0x14;
          }
          else {
            if (cVar1 != '\x04') {
              return;
            }
            sVar5 = *(short *)(PTR__enemy_0003f04c + iVar9 * 0x5c + 0x18);
            *(short *)((int)&DAT_00037a06 + iVar8) = sVar5 + 0x14;
            sVar6 = *(short *)(puVar2 + iVar9 * 0x5c + 0x12);
            *(short *)((int)&DAT_00037a04 + iVar8) = sVar6 + 0xb;
            sVar5 = sVar5 + 0x25;
          }
          *(short *)((int)&DAT_00037a0a + iVar8) = sVar5;
          sVar6 = sVar6 + 0x1c;
        }
        *(short *)((int)&DAT_00037a08 + iVar8) = sVar6;
        (&_gBalloons)[iVar8] = 1;
        *(undefined2 *)((int)&DAT_000379e2 + iVar8) = uVar3;
        (&DAT_00037a01)[iVar8] = 0;
        *(undefined2 *)((int)&DAT_000379fa + iVar8) = 0x31;
        *(undefined2 *)((int)&DAT_000379fc + iVar8) = 1;
        (&DAT_000379f8)[iVar8] = cVar1;
        *(undefined2 *)((int)&DAT_000379fe + iVar8) = 0;
        (&DAT_00037a00)[iVar8] = 1;
        *(undefined2 *)((int)&DAT_000379e4 + iVar8) = uVar3;
        uVar3 = _GetRandomFast(4,7);
        *(undefined2 *)((int)&DAT_000379e6 + iVar8) = uVar3;
        puVar2 = PTR__enemy_0003f04c;
        sVar6 = *(short *)(PTR__enemy_0003f04c + iVar9 * 0x5c + 0x14);
        *(short *)((int)&DAT_000379e8 + iVar8 + 2) = sVar6;
        sVar5 = *(short *)(puVar2 + iVar9 * 0x5c + 0x12);
        *(short *)((int)&DAT_000379e8 + iVar8) = sVar5;
        *(short *)((int)&DAT_000379ec + iVar8 + 2) = sVar6 + 0x28;
        *(short *)((int)&DAT_000379ec + iVar8) = sVar5 + 0x28;
        cVar1 = puVar2[iVar9 * 0x5c + 0x23];
        if (cVar1 == '\x02') {
          uVar11 = 0x14;
LAB_000239f2:
          uVar10 = 0;
        }
        else {
          if (cVar1 < '\x03') {
            if (cVar1 != '\x01') goto LAB_00023a2c;
            uVar11 = 0xffffffec;
            goto LAB_000239f2;
          }
          if (cVar1 == '\x03') {
            uVar11 = 0;
            uVar10 = 0xffffffec;
          }
          else {
            if (cVar1 != '\x04') goto LAB_00023a2c;
            uVar11 = 0;
            uVar10 = 0x14;
          }
        }
        _OffsetRect((int)&DAT_000379e8 + iVar8,uVar10,uVar11);
LAB_00023a2c:
        *(undefined4 *)((int)&DAT_000379f0 + iVar8) = *(undefined4 *)((int)&DAT_000379e8 + iVar8);
        *(undefined4 *)((int)&DAT_000379f4 + iVar8) = *(undefined4 *)((int)&DAT_000379ec + iVar8);
        _gBalloons_NumActive = _gBalloons_NumActive + 1;
        _PlayMySnd(0xe,10,0);
        return;
      }
      iVar7 = iVar7 + 1;
      iVar8 = iVar8 + 0x2c;
      pcVar4 = pcVar4 + 0x2c;
    } while (iVar7 != 0x1e);
  }
  return;
}


// ==== _Balloons_PopBalloon @ 00023a84 ====

void _Balloons_PopBalloon(short param_1)

{
  undefined2 uVar1;
  int iVar2;
  
  iVar2 = (int)param_1;
  (&_gBalloons)[iVar2 * 0x2c] = 3;
  uVar1 = _GetFrameCounter();
  (&DAT_000379e2)[iVar2 * 0x16] = uVar1;
  (&DAT_000379fa)[iVar2 * 0x16] = 0x33;
  (&DAT_000379fc)[iVar2 * 0x16] = 1;
  (&DAT_000379fe)[iVar2 * 0x16] = 0;
  _PlayMySnd(0x10,10,0);
  return;
}


// ==== _Balloons_CheckSquishes @ 00023ae8 ====

void _Balloons_CheckSquishes(undefined4 param_1)

{
  char cVar1;
  char *pcVar2;
  int iVar3;
  undefined4 *puVar4;
  
  if (_gBalloons_NumActive != 0) {
    iVar3 = 0;
    pcVar2 = &_gBalloons;
    puVar4 = &DAT_000379e8;
    do {
      if (*pcVar2 == '\x01') {
        cVar1 = _RectsCollide(param_1,puVar4);
        if (cVar1 != '\0') {
          _Balloons_PopBalloon(iVar3);
        }
      }
      iVar3 = iVar3 + 1;
      puVar4 = puVar4 + 0xb;
      pcVar2 = pcVar2 + 0x2c;
    } while (iVar3 != 0x1e);
  }
  return;
}


// ==== _Balloons_MoveBalloon @ 00023b3d ====

void _Balloons_MoveBalloon(short param_1)

{
  short *psVar1;
  char cVar2;
  int iVar3;
  int iVar4;
  
  iVar4 = (int)param_1;
  iVar3 = iVar4 * 0x2c;
  cVar2 = (&DAT_000379f8)[iVar3];
  if (cVar2 == '\x02') {
    *(short *)(&DAT_000379e8 + iVar4 * 0xb) = *(short *)(&DAT_000379e8 + iVar4 * 0xb) + 8;
    *(short *)(&DAT_000379ec + iVar4 * 0xb) = *(short *)(&DAT_000379ec + iVar4 * 0xb) + 8;
    (&DAT_00037a04)[iVar4 * 0x16] = (&DAT_00037a04)[iVar4 * 0x16] + 8;
    (&DAT_00037a08)[iVar4 * 0x16] = (&DAT_00037a08)[iVar4 * 0x16] + 8;
  }
  else if (cVar2 < '\x03') {
    if (cVar2 != '\x01') {
      return;
    }
    *(short *)(&DAT_000379e8 + iVar4 * 0xb) = *(short *)(&DAT_000379e8 + iVar4 * 0xb) + -8;
    *(short *)(&DAT_000379ec + iVar4 * 0xb) = *(short *)(&DAT_000379ec + iVar4 * 0xb) + -8;
    (&DAT_00037a04)[iVar4 * 0x16] = (&DAT_00037a04)[iVar4 * 0x16] + -8;
    (&DAT_00037a08)[iVar4 * 0x16] = (&DAT_00037a08)[iVar4 * 0x16] + -8;
  }
  else if (cVar2 == '\x03') {
    psVar1 = (short *)((int)&DAT_000379e8 + iVar3 + 2);
    *psVar1 = *psVar1 + -8;
    psVar1 = (short *)((int)&DAT_000379ec + iVar3 + 2);
    *psVar1 = *psVar1 + -8;
    (&DAT_00037a06)[iVar4 * 0x16] = (&DAT_00037a06)[iVar4 * 0x16] + -8;
    (&DAT_00037a0a)[iVar4 * 0x16] = (&DAT_00037a0a)[iVar4 * 0x16] + -8;
  }
  else {
    if (cVar2 != '\x04') {
      return;
    }
    psVar1 = (short *)((int)&DAT_000379e8 + iVar3 + 2);
    *psVar1 = *psVar1 + 8;
    psVar1 = (short *)((int)&DAT_000379ec + iVar3 + 2);
    *psVar1 = *psVar1 + 8;
    (&DAT_00037a06)[iVar4 * 0x16] = (&DAT_00037a06)[iVar4 * 0x16] + 8;
    (&DAT_00037a0a)[iVar4 * 0x16] = (&DAT_00037a0a)[iVar4 * 0x16] + 8;
  }
  iVar3 = iVar4 * 0x2c;
  if (*(short *)((int)&DAT_000379e8 + iVar3 + 2) < 0) {
    *(undefined2 *)((int)&DAT_000379e8 + iVar3 + 2) = 0;
    *(undefined2 *)((int)&DAT_000379ec + iVar3 + 2) = 0x28;
  }
  else if (0x280 < *(short *)((int)&DAT_000379ec + iVar3 + 2)) {
    *(undefined2 *)((int)&DAT_000379ec + iVar3 + 2) = 0x280;
    *(undefined2 *)((int)&DAT_000379e8 + iVar3 + 2) = 600;
  }
  if (*(short *)(&DAT_000379e8 + iVar4 * 0xb) < 0) {
    *(undefined2 *)(&DAT_000379e8 + iVar4 * 0xb) = 0;
    *(undefined2 *)(&DAT_000379ec + iVar4 * 0xb) = 0x28;
  }
  else if (0x1b8 < *(short *)(&DAT_000379ec + iVar4 * 0xb)) {
    *(undefined2 *)(&DAT_000379ec + iVar4 * 0xb) = 0x1b8;
    *(undefined2 *)(&DAT_000379e8 + iVar4 * 0xb) = 400;
  }
  return;
}


// ==== _Balloons_CheckHeroHit @ 00023c86 ====

bool _Balloons_CheckHeroHit(short param_1)

{
  char cVar1;
  
  cVar1 = _RectsCollide(&DAT_00037a04 + param_1 * 0x16,PTR__hero_0003f014 + 0x14);
  return cVar1 != '\0';
}


// ==== _Balloons_CaptureHero @ 00023cbb ====

void _Balloons_CaptureHero(short param_1)

{
  short sVar1;
  short sVar2;
  undefined4 uVar3;
  undefined *puVar4;
  undefined2 uVar5;
  int iVar6;
  int iVar7;
  
  puVar4 = PTR__hero_0003f014;
  if (PTR__hero_0003f014[0x4c] == '\0') {
    uVar5 = _GetFrameCounter();
    _PlayMySnd(0xf,10,0);
    _PlayMySnd(0x27,10,5);
    iVar6 = (int)param_1;
    iVar7 = iVar6 * 0x2c;
    (&_gBalloons)[iVar7] = 2;
    (&DAT_000379e2)[iVar6 * 0x16] = uVar5;
    (&DAT_000379fa)[iVar6 * 0x16] = 0x32;
    (&DAT_000379fc)[iVar6 * 0x16] = 1;
    (&DAT_00037a02)[iVar7] = 0x46;
    (&DAT_00037a03)[iVar7] = 0xff;
    (&DAT_000379e4)[iVar6 * 0x16] = uVar5;
    sVar1 = *(short *)(puVar4 + 0x16);
    *(short *)((int)&DAT_000379e8 + iVar7 + 2) = sVar1;
    sVar2 = *(short *)(puVar4 + 0x14);
    *(short *)(&DAT_000379e8 + iVar6 * 0xb) = sVar2;
    *(short *)((int)&DAT_000379ec + iVar7 + 2) = sVar1 + 0x28;
    *(short *)(&DAT_000379ec + iVar6 * 0xb) = sVar2 + 0x28;
    uVar3 = (&DAT_000379ec)[iVar6 * 0xb];
    *(undefined4 *)(&DAT_00037a04 + iVar6 * 0x16) = (&DAT_000379e8)[iVar6 * 0xb];
    *(undefined4 *)(&DAT_00037a08 + iVar6 * 0x16) = uVar3;
    puVar4[0x4c] = 1;
    *(undefined2 *)(puVar4 + 0x4e) = uVar5;
  }
  return;
}


// ==== _Balloons_CheckHardObjectHit @ 00023da7 ====

undefined4 _Balloons_CheckHardObjectHit(short param_1)

{
  short sVar1;
  int iVar2;
  undefined4 uVar3;
  char cVar4;
  char cVar5;
  
  iVar2 = (int)param_1;
  if (((((short)(&DAT_00037a06)[iVar2 * 0x16] < 1) ||
       (sVar1 = (&DAT_00037a0a)[iVar2 * 0x16], 0x27f < sVar1)) ||
      ((short)(&DAT_00037a04)[iVar2 * 0x16] < 1)) || (0x1b7 < (short)(&DAT_00037a08)[iVar2 * 0x16]))
  {
LAB_00023f47:
    uVar3 = 1;
  }
  else {
    cVar5 = (&DAT_000379f8)[iVar2 * 0x2c];
    if (cVar5 == '\x02') {
      cVar5 = (char)(sVar1 / 0x28);
      cVar4 = (char)((short)(&DAT_00037a08)[iVar2 * 0x16] / 0x28);
LAB_00023f2a:
      if ((byte)(PTR__gMaze_0003f054[(int)cVar5 + cVar4 * 0x10] - 10) < 0x33) goto LAB_00023f47;
    }
    else {
      if ('\x02' < cVar5) {
        if (cVar5 == '\x03') {
          cVar5 = (char)((short)(&DAT_00037a06)[iVar2 * 0x16] / 0x28);
        }
        else {
          if (cVar5 != '\x04') goto LAB_00023e1a;
          cVar5 = (char)(sVar1 / 0x28);
        }
LAB_00023f01:
        cVar4 = (char)((short)(&DAT_00037a04)[iVar2 * 0x16] / 0x28);
        goto LAB_00023f2a;
      }
      if (cVar5 == '\x01') {
        cVar5 = (char)(sVar1 / 0x28);
        goto LAB_00023f01;
      }
    }
LAB_00023e1a:
    uVar3 = 0;
  }
  return uVar3;
}


// ==== _Balloons_PopAll @ 00023f54 ====

void _Balloons_PopAll(void)

{
  undefined2 uVar1;
  undefined2 *puVar2;
  
  uVar1 = _GetFrameCounter();
  puVar2 = &DAT_000379e2;
  do {
    if (*(char *)(puVar2 + -1) == '\x02') {
      *(undefined1 *)(puVar2 + -1) = 3;
      *puVar2 = uVar1;
      puVar2[0xc] = 0x33;
      puVar2[0xd] = 1;
      puVar2[0xe] = 0;
    }
    puVar2 = puVar2 + 0x16;
  } while (puVar2 != (undefined2 *)&DAT_00037f0a);
  return;
}


// ==== _Balloons_CheckBalloonEnemyHit @ 00023f90 ====

undefined4 _Balloons_CheckBalloonEnemyHit(short param_1)

{
  short sVar1;
  short sVar2;
  undefined4 uVar3;
  undefined *puVar4;
  char cVar5;
  int iVar6;
  int iVar7;
  int iVar8;
  int iVar9;
  char *pcVar10;
  undefined *local_3c;
  char local_30;
  undefined4 local_24;
  undefined4 local_20;
  
  iVar6 = (int)param_1;
  iVar7 = iVar6 * 0x2c;
  local_24 = (&DAT_000379e8)[iVar6 * 0xb];
  local_20 = (&DAT_000379ec)[iVar6 * 0xb];
  _MyInsetRect(&local_24,6,6);
  puVar4 = PTR__enemy_0003f04c;
  iVar9 = 0;
  local_3c = PTR__enemy_0003f04c + 0x10;
  iVar8 = 0;
  pcVar10 = PTR__enemy_0003f04c;
  while( true ) {
    cVar5 = *pcVar10;
    if ((((cVar5 == '\x01') || (cVar5 == '\x04')) || (cVar5 == '\x05')) &&
       (cVar5 = _RectsCollide(&DAT_00037a04 + iVar6 * 0x16,puVar4 + iVar8 + 0x12), cVar5 != '\0'))
    break;
    iVar9 = iVar9 + 1;
    iVar8 = iVar8 + 0x5c;
    local_3c = local_3c + 0x5c;
    pcVar10 = pcVar10 + 0x5c;
    if (iVar9 == 0x1e) {
      return 0;
    }
  }
  (&DAT_00037a02)[iVar7] = 0x50;
  (&DAT_00037a03)[iVar7] = (char)iVar9;
  local_30 = (char)param_1;
  _CaptureEnemy(iVar9,(int)local_30);
  _PlayMySnd(0xf,10,0);
  sVar1 = *(short *)(local_3c + 4);
  *(short *)((int)&DAT_000379e8 + iVar7 + 2) = sVar1;
  sVar2 = *(short *)(local_3c + 2);
  *(short *)(&DAT_000379e8 + iVar6 * 0xb) = sVar2;
  *(short *)((int)&DAT_000379ec + iVar7 + 2) = sVar1 + 0x28;
  *(short *)(&DAT_000379ec + iVar6 * 0xb) = sVar2 + 0x28;
  uVar3 = (&DAT_000379ec)[iVar6 * 0xb];
  *(undefined4 *)(&DAT_00037a04 + iVar6 * 0x16) = (&DAT_000379e8)[iVar6 * 0xb];
  *(undefined4 *)(&DAT_00037a08 + iVar6 * 0x16) = uVar3;
  return 1;
}


// ==== _Balloons_CaptureAllEnemies @ 000240dd ====

void _Balloons_CaptureAllEnemies(void)

{
  char cVar1;
  short sVar2;
  short sVar3;
  undefined2 uVar4;
  undefined2 uVar5;
  char *pcVar6;
  int iVar7;
  int iVar8;
  char *pcVar9;
  int local_20;
  
  uVar4 = _GetFrameCounter();
  local_20 = 0;
  pcVar9 = PTR__enemy_0003f04c;
  do {
    cVar1 = *pcVar9;
    if (((cVar1 == '\x01') || (cVar1 == '\x04')) || (cVar1 == '\x05')) {
      if (0x1d < _gBalloons_NumActive) {
        return;
      }
      iVar7 = 0;
      pcVar6 = &_gBalloons;
      iVar8 = 0;
      do {
        if (*pcVar6 == '\0') {
          _gBalloons_NumActive = _gBalloons_NumActive + 1;
          (&_gBalloons)[iVar8] = 2;
          *(undefined2 *)((int)&DAT_000379e2 + iVar8) = uVar4;
          (&DAT_00037a01)[iVar8] = 0;
          *(undefined2 *)((int)&DAT_000379fa + iVar8) = 0x32;
          *(undefined2 *)((int)&DAT_000379fc + iVar8) = 1;
          (&DAT_000379f8)[iVar8] = (char)*(undefined2 *)(PTR__hero_0003f014 + 0x26);
          *(undefined2 *)((int)&DAT_000379fe + iVar8) = 0;
          (&DAT_00037a00)[iVar8] = 1;
          (&DAT_00037a02)[iVar8] = pcVar9[4];
          (&DAT_00037a03)[iVar8] = (undefined1)local_20;
          *(undefined2 *)((int)&DAT_000379e4 + iVar8) = uVar4;
          uVar5 = _GetRandomFast(4,7);
          *(undefined2 *)((int)&DAT_000379e6 + iVar8) = uVar5;
          _CaptureEnemy(local_20,(int)(char)iVar7);
          sVar2 = *(short *)(pcVar9 + 0x14);
          *(short *)((int)&DAT_000379e8 + iVar8 + 2) = sVar2;
          sVar3 = *(short *)(pcVar9 + 0x12);
          *(short *)((int)&DAT_000379e8 + iVar8) = sVar3;
          *(short *)((int)&DAT_000379ec + iVar8 + 2) = sVar2 + 0x28;
          *(short *)((int)&DAT_000379ec + iVar8) = sVar3 + 0x28;
          *(undefined4 *)((int)&DAT_00037a04 + iVar8) = *(undefined4 *)((int)&DAT_000379e8 + iVar8);
          *(undefined4 *)((int)&DAT_00037a08 + iVar8) = *(undefined4 *)((int)&DAT_000379ec + iVar8);
          break;
        }
        iVar7 = iVar7 + 1;
        iVar8 = iVar8 + 0x2c;
        pcVar6 = pcVar6 + 0x2c;
      } while (iVar7 != 0x1e);
    }
    local_20 = local_20 + 1;
    pcVar9 = pcVar9 + 0x5c;
    if (local_20 == 0x1e) {
      _PlayMySnd(0xf,10,0);
      return;
    }
  } while( true );
}


// ==== _Balloons_Init @ 00024260 ====

void _Balloons_Init(void)

{
  undefined2 *puVar1;
  
  puVar1 = (undefined2 *)&_gBalloons;
  do {
    *(undefined1 *)puVar1 = 0;
    puVar1 = puVar1 + 0x16;
  } while (puVar1 != &_gBalloons_NumActive);
  _gBalloons_NumActive = 0;
  return;
}


// ==== _Balloons_DrawToComp @ 00024280 ====

void _Balloons_DrawToComp(void)

{
  undefined4 *puVar1;
  undefined4 *puVar2;
  int iVar3;
  undefined4 *puVar4;
  undefined4 *local_34;
  undefined4 *local_30;
  undefined4 local_24 [5];
  
  if (_gBalloons_NumActive != 0) {
    iVar3 = 0;
    puVar2 = &DAT_000379f0;
    local_30 = &DAT_000379f0;
    local_34 = &DAT_000379f0;
    puVar4 = &DAT_000379e8;
    do {
      if (*(char *)(puVar2 + -4) != '\0') {
        puVar1 = local_30;
        if (*(char *)(puVar2 + 4) != '\0') {
          if (*(short *)((int)puVar2 + 0x16) < 0) {
            *(undefined1 *)(puVar2 + 4) = 0;
          }
          if (0x280 < *(short *)((int)puVar2 + 0x1a)) {
            *(undefined1 *)(puVar2 + 4) = 0;
          }
          if (*(short *)(puVar2 + 5) < 0) {
            *(undefined1 *)(puVar2 + 4) = 0;
          }
          if (0x1b8 < *(short *)(puVar2 + 6)) {
            *(undefined1 *)(puVar2 + 4) = 0;
          }
          if (*(char *)(puVar2 + 4) != '\0') {
            _SpriteToComp(0,(int)*(short *)((int)puVar2 + -6),(int)*(short *)(puVar2 + -2),
                          (int)*(short *)((int)puVar2 + 10),(int)*(short *)(puVar2 + 3),1);
            _UnionRect(local_34,puVar4,local_24);
            puVar1 = local_24;
          }
        }
        _AddRectToScreen(puVar1);
        if (*(char *)((int)puVar2 + 0x11) == '\0') {
          *puVar2 = puVar2[-2];
          puVar2[1] = puVar2[-1];
        }
        else {
          *(undefined1 *)(puVar2 + -4) = 0;
          _gBalloons_NumActive = _gBalloons_NumActive + -1;
        }
      }
      iVar3 = iVar3 + 1;
      puVar4 = puVar4 + 0xb;
      local_34 = local_34 + 0xb;
      local_30 = local_30 + 0xb;
      puVar2 = puVar2 + 0xb;
    } while (iVar3 != 0x1e);
  }
  return;
}


// ==== _Balloons_Process @ 00024394 ====

void _Balloons_Process(void)

{
  undefined *puVar1;
  char cVar2;
  ushort uVar3;
  short sVar4;
  uint uVar5;
  short sVar6;
  undefined1 *puVar7;
  int iVar8;
  int local_30;
  undefined2 *local_2c;
  
  if (_gBalloons_NumActive != 0) {
    uVar3 = _GetFrameCounter();
    puVar1 = PTR__hero_0003f014;
    iVar8 = 0;
    puVar7 = &DAT_00037a01;
    uVar5 = (uint)uVar3;
    local_2c = &DAT_00037a04;
    local_30 = 0;
    do {
      if (puVar7[-0x21] != '\0') {
        _AddRectToBgnd((int)&DAT_000379f0 + local_30);
        cVar2 = puVar7[-0x21];
        if (cVar2 == '\x02') {
          if ((int)((uint)*(ushort *)(puVar7 + -0x1d) + (int)*(short *)(puVar7 + -0x1b)) <
              (int)uVar5) {
            sVar6 = 1;
            if ((short)(*(short *)(puVar7 + -5) + 1) < 4) {
              sVar6 = *(short *)(puVar7 + -5) + 1;
            }
            *(short *)(puVar7 + -5) = sVar6;
            *(ushort *)(puVar7 + -0x1d) = uVar3;
          }
          if ((puVar1[0x4c] == '\0') &&
             (cVar2 = _RectsCollide(local_2c,puVar1 + 0x14), cVar2 != '\0')) {
            _Balloons_PopBalloon(iVar8);
            _PopEnemy((int)(char)puVar7[2]);
          }
          if (puVar7[-0x21] == '\x02') {
            if ((int)((uint)*(ushort *)(puVar7 + -0x1f) +
                     (int)*(short *)(PTR__level_0003f010 + 0x1e)) < (int)uVar5) {
              puVar7[-1] = puVar7[-1] == '\0';
            }
            if ((int)((uint)*(ushort *)(puVar7 + -0x1f) +
                     (int)*(short *)(PTR__level_0003f010 + 0x20)) < (int)uVar5) {
              puVar7[-1] = 1;
              _Balloons_PopBalloon(iVar8);
              _ReleaseEnemyFromBalloon((int)(char)puVar7[2]);
            }
          }
        }
        else if (cVar2 == '\x03') {
          sVar6 = *(short *)(puVar7 + -3);
          *(ushort *)(puVar7 + -3) = sVar6 + 1U;
          if (3 < (ushort)(sVar6 + 1U)) {
            *puVar7 = 1;
            puVar7[-1] = 0;
          }
        }
        else {
          if (cVar2 != '\x01') {
            return;
          }
          _Balloons_MoveBalloon(iVar8);
          cVar2 = _Balloons_CheckBalloonEnemyHit(iVar8);
          if (cVar2 == '\0') {
            if (((PTR__hero_0003f014[0x4c] == '\0') && (PTR__hero_0003f014[0x50] == '\0')) &&
               (cVar2 = _RectsCollide((int)&DAT_00037a04 + local_30,PTR__hero_0003f014 + 0x14),
               cVar2 != '\0')) {
              _Balloons_CaptureHero(iVar8);
            }
            if (puVar7[-0x21] == '\x01') {
              cVar2 = _Balloons_CheckHardObjectHit(iVar8);
              if (cVar2 == '\0') {
                if ((*(short *)(puVar7 + -5) < 2) &&
                   (sVar6 = *(short *)(puVar7 + -3), *(ushort *)(puVar7 + -3) = sVar6 + 1U,
                   2 < (ushort)(sVar6 + 1U))) {
                  *(undefined2 *)(puVar7 + -3) = 0;
                  sVar6 = *(short *)(puVar7 + -5);
                  sVar4 = sVar6 + 1;
                  *(short *)(puVar7 + -5) = sVar4;
                  if (sVar4 == 2) {
                    *(short *)(puVar7 + 5) = *(short *)(puVar7 + -0x17) + 8;
                    *(short *)(puVar7 + 3) = *(short *)(puVar7 + -0x19) + 8;
                    *(short *)(puVar7 + 9) = *(short *)(puVar7 + -0x17) + 0x1a;
                    sVar6 = *(short *)(puVar7 + -0x19) + 0x1f;
LAB_0002453b:
                    *(short *)(puVar7 + 7) = sVar6;
                  }
                  else if (sVar4 < 3) {
                    if (sVar6 != 0) {
                      return;
                    }
                  }
                  else {
                    if (sVar4 == 3) {
                      *(short *)(puVar7 + 5) = *(short *)(puVar7 + -0x17) + 3;
                      *(short *)(puVar7 + 3) = *(short *)(puVar7 + -0x19) + 3;
                      *(short *)(puVar7 + 9) = *(short *)(puVar7 + -0x17) + 0x1a;
                      sVar6 = *(short *)(puVar7 + -0x19) + 0x20;
                      goto LAB_0002453b;
                    }
                    if (sVar4 != 4) {
                      return;
                    }
                    *(undefined4 *)(puVar7 + 3) = *(undefined4 *)(puVar7 + -0x19);
                    *(undefined4 *)(puVar7 + 7) = *(undefined4 *)(puVar7 + -0x15);
                  }
                }
              }
              else {
                _Balloons_PopBalloon(iVar8);
              }
            }
          }
          else {
            puVar7[-0x21] = 2;
            *(ushort *)(puVar7 + -0x1f) = uVar3;
            *(undefined2 *)(puVar7 + -7) = 0x32;
            *(undefined2 *)(puVar7 + -5) = 1;
            *(ushort *)(puVar7 + -0x1d) = uVar3;
          }
        }
      }
      iVar8 = iVar8 + 1;
      local_30 = local_30 + 0x2c;
      local_2c = local_2c + 0x16;
      puVar7 = puVar7 + 0x2c;
    } while (iVar8 != 0x1e);
  }
  return;
}


// ==== _PasStringCopy @ 00024640 ====

void _PasStringCopy(byte *param_1,byte *param_2)

{
  byte bVar1;
  ushort uVar2;
  
  bVar1 = *param_1;
  *param_2 = bVar1;
  uVar2 = (ushort)bVar1;
  while( true ) {
    param_1 = param_1 + 1;
    param_2 = param_2 + 1;
    uVar2 = uVar2 - 1;
    if ((short)uVar2 < 0) break;
    *param_2 = *param_1;
  }
  return;
}


// ==== _HiScoreEraseDialog @ 00024670 ====

bool _HiScoreEraseDialog(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  short local_1e [7];
  
  uVar1 = _GetNewDialog(0x3e9,0,0xffffffff);
  _PlayMySnd(0x16,10,0);
  _SetDialogDefaultItem(uVar1,2);
  _SetDialogCancelItem(uVar1,2);
  uVar2 = _GetDialogWindow(uVar1);
  _ZoomAndShowWindow(uVar2);
  uVar2 = _GetDialogWindow(uVar1);
  uVar2 = _GetWindowPort(uVar2);
  _SetPort(uVar2);
  uVar2 = _NewModalFilterUPP(PTR_LAB_0003f09c);
  do {
    _ModalDialog(uVar2,local_1e);
  } while (1 < (ushort)(local_1e[0] - 1U));
  _DisposeDialog(uVar1);
  _DisposeModalFilterUPP(uVar2);
  _SetToScreen();
  return local_1e[0] == 1;
}


// ==== _DrawDefaultButton @ 0002474d ====

void _DrawDefaultButton(undefined4 param_1)

{
  undefined1 local_1c [8];
  undefined1 local_14 [6];
  undefined1 local_e [6];
  
  _GetDialogItem(param_1,1,local_e,local_14,local_1c);
  _InsetRect(local_1c,0xfffffffc,0xfffffffc);
  _PenSize(3,3);
  _FrameRoundRect(local_1c,0x10,0x10);
  _PenNormal();
  return;
}


// ==== _PasStringCopyNum @ 000247cb ====

void _PasStringCopyNum(byte *param_1,undefined1 *param_2,ushort param_3)

{
  int iVar1;
  
  if ((short)(ushort)*param_1 < (short)param_3) {
    param_3 = (ushort)*param_1;
  }
  *param_2 = (char)param_3;
  for (iVar1 = 0; (short)iVar1 < (short)param_3; iVar1 = iVar1 + 1) {
    param_2[iVar1 + 1] = param_1[iVar1 + 1];
  }
  return;
}


// ==== _GetDialogString @ 0002480c ====

void _GetDialogString(undefined4 param_1,short param_2,undefined4 param_3)

{
  undefined1 local_1c [8];
  undefined4 local_14;
  undefined1 local_e [10];
  
  _GetDialogItem(param_1,(int)param_2,local_e,&local_14,local_1c);
  _GetDialogItemText(local_14,param_3);
  return;
}


// ==== _SetDialogString @ 0002484e ====

void _SetDialogString(undefined4 param_1,short param_2,undefined4 param_3)

{
  undefined1 local_1c [8];
  undefined4 local_14;
  undefined1 local_e [10];
  
  _GetDialogItem(param_1,(int)param_2,local_e,&local_14,local_1c);
  _SetDialogItemText(local_14,param_3);
  return;
}


// ==== _HiScoreNameFilter @ 00024890 ====

undefined4 _HiScoreNameFilter(undefined4 param_1,short *param_2,undefined2 *param_3)

{
  char cVar1;
  int *piVar2;
  int iVar3;
  int iVar4;
  undefined4 uVar5;
  byte local_10c [264];
  
  if ((*param_2 == 3) || (*param_2 == 5)) {
    cVar1 = _BitAnd(*(undefined4 *)(param_2 + 1),0xff);
    if ((cVar1 == '\r') || (cVar1 == '\x03')) {
      *param_3 = 1;
      _FlashMyDialogItem(param_1,1);
      return 1;
    }
    if (((byte)(cVar1 - 0x1cU) < 4) || (cVar1 == '\b')) {
      uVar5 = 6;
    }
    else {
      _GetDialogString(param_1,2,local_10c);
      if ((9 < local_10c[0]) &&
         (piVar2 = (int *)_GetDialogTextEditHandle(param_1), iVar3 = (int)*(short *)(*piVar2 + 0x22)
         , iVar4 = (int)*(short *)(*piVar2 + 0x20), iVar3 == iVar4 || iVar3 - iVar4 < 0)) {
        _SysBeep(1);
        return 1;
      }
      uVar5 = 1;
    }
    _PlayMySnd(uVar5,0x14,0);
  }
  return 0;
}


// ==== _SwapHighScoresFromBigEndian @ 00024982 ====

void _SwapHighScoresFromBigEndian(void)

{
  undefined *puVar1;
  ushort *puVar2;
  uint uVar3;
  undefined *puVar4;
  undefined *puVar5;
  
  puVar1 = PTR__highScores_00034264 + 0x1c;
  puVar4 = PTR__highScores_00034264;
  puVar5 = PTR__highScores_00034264;
  do {
    uVar3 = *(uint *)(puVar5 + 0x60);
    *(uint *)(puVar5 + 0x60) =
         uVar3 >> 0x18 | (uVar3 & 0xff0000) >> 8 | (uVar3 & 0xff00) << 8 | uVar3 << 0x18;
    puVar2 = (ushort *)(puVar4 + 0x7c);
    *puVar2 = *puVar2 << 8 | *puVar2 >> 8;
    puVar5 = puVar5 + 4;
    puVar4 = puVar4 + 2;
  } while (puVar5 != puVar1);
  return;
}


// ==== _SwapHighScoresToBigEndian @ 000249ab ====

void _SwapHighScoresToBigEndian(void)

{
  undefined *puVar1;
  ushort *puVar2;
  uint uVar3;
  undefined *puVar4;
  undefined *puVar5;
  
  puVar1 = PTR__highScores_00034264 + 0x1c;
  puVar4 = PTR__highScores_00034264;
  puVar5 = PTR__highScores_00034264;
  do {
    uVar3 = *(uint *)(puVar5 + 0x60);
    *(uint *)(puVar5 + 0x60) =
         uVar3 >> 0x18 | (uVar3 & 0xff0000) >> 8 | (uVar3 & 0xff00) << 8 | uVar3 << 0x18;
    puVar2 = (ushort *)(puVar4 + 0x7c);
    *puVar2 = *puVar2 << 8 | *puVar2 >> 8;
    puVar5 = puVar5 + 4;
    puVar4 = puVar4 + 2;
  } while (puVar5 != puVar1);
  return;
}


// ==== _LoadDefaultHiScores @ 000249d4 ====

void _LoadDefaultHiScores(void)

{
  undefined4 *puVar1;
  uint uVar2;
  
  puVar1 = (undefined4 *)_GetResource(0x53434f52,0x80);
  if (puVar1 == (undefined4 *)0x0) {
    _ResourceError(3000,1,"SCOR",0x80);
  }
  _HNoPurge(puVar1);
  _HLock(puVar1);
  uVar2 = _GetHandleSize(puVar1);
  if (0x8a < uVar2) {
    _LocationErrorInt(3000,2);
  }
  if (0 < (int)uVar2) {
    _memmove(PTR__highScores_00034264,(void *)*puVar1,uVar2);
  }
  _ReleaseResource(puVar1);
  _SwapHighScoresFromBigEndian();
  return;
}


// ==== _SaveDefaultHiScores @ 00024a7d ====

void _SaveDefaultHiScores(void)

{
  int iVar1;
  undefined4 *puVar2;
  
  iVar1 = _GetResource(0x53434f52,0x80);
  if (iVar1 == 0) {
    _DebugValues("Couldn\'t find the default hi scores!",0xffffffff);
  }
  else {
    _HNoPurge(iVar1);
    _RemoveResource(iVar1);
    _HPurge(iVar1);
  }
  puVar2 = (undefined4 *)_NewHandle(0x8a);
  _SwapHighScoresToBigEndian();
  _memmove((void *)*puVar2,PTR__highScores_00034264,0x8a);
  _AddResource(puVar2,0x53434f52,0x80,"\x0eFactory Scores");
  _WriteResource(puVar2);
  _ReleaseResource(puVar2);
  _SwapHighScoresFromBigEndian();
  return;
}


// ==== _CheckHiScore @ 00024b34 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 _CheckHiScore(void)

{
  char cVar1;
  undefined2 uVar2;
  short sVar3;
  int iVar4;
  uint uVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  undefined4 uVar8;
  int iVar9;
  undefined *puVar10;
  char *pcVar11;
  char *pcVar12;
  undefined *puVar13;
  undefined *puVar14;
  char *pcVar15;
  char *pcVar16;
  undefined1 uVar17;
  bool bVar18;
  short local_35e;
  char local_350 [256];
  char local_250 [256];
  char local_150 [4];
  uint local_14c;
  undefined2 local_148;
  char acStack_51 [21];
  undefined4 local_3c;
  undefined4 local_38;
  undefined1 local_34 [8];
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  short local_1e [7];
  
  __gLatestHighScoreIndex = 0xffff;
  iVar4 = _GetScore();
  if (iVar4 <= *(int *)(PTR__highScores_00034264 + 0x78)) {
    return 0;
  }
  _SetToCompGWorld();
  puVar13 = PTR__environment_0003f028;
  local_3c = *(undefined4 *)(PTR__environment_0003f028 + 0x12);
  local_38 = *(undefined4 *)(PTR__environment_0003f028 + 0x16);
  _GetIndPattern(local_34,0,4);
  _PenPat(local_34);
  _PenMode(1);
  _PaintRect(&local_3c);
  _PenNormal();
  _SetToScreen();
  _UpdateScreen();
  iVar4 = _RT3_IsRegistered();
  if (((iVar4 == 0) && (uVar5 = _RT3_GetDaysHad(), 6 < uVar5)) &&
     (uVar5 = _RT3_GetNumLaunches(), 9 < uVar5)) {
    uVar6 = _GetScore();
    _NumToString(uVar6,local_350);
    uVar7 = _GetNewDialog(0x3ea,0,0xffffffff);
    _GetPort(&local_24);
    uVar6 = _GetDialogWindow(uVar7);
    uVar6 = _GetWindowPort(uVar6);
    _SetPort(uVar6);
    _ParamText(local_350,&DAT_00033b01,&DAT_00033b01,&DAT_00033b01);
    _PlayMySnd(0xd,10,0);
    uVar6 = _GetDialogWindow(uVar7);
    _ZoomAndShowWindow(uVar6);
    _CreateWindowGroup(0,&local_28);
    uVar6 = local_28;
    uVar8 = _GetDialogWindow(uVar7);
    _SetWindowGroup(uVar8,uVar6);
    if (puVar13[0x26] == '\0') {
      uVar6 = _CGShieldingWindowLevel();
    }
    else {
      uVar6 = _CGWindowLevelForKey(4);
    }
    _SetWindowGroupLevel(local_28,uVar6);
    _InitCursor();
    _SetDialogDefaultItem(uVar7,1);
    do {
      _ModalDialog(0,local_1e);
    } while (local_1e[0] != 1);
    _PlayMySnd(0x11,10,0);
    _SetPort(local_24);
    _DisposeDialog(uVar7);
    _ReleaseWindowGroup(local_28);
    return 0;
  }
  _FlushEvents(0x3e,0);
  puVar13 = PTR__highScores_00034264;
  local_35e = 5;
  puVar10 = PTR__highScores_00034264;
  iVar4 = 0;
  puVar14 = PTR__highScores_00034264;
  while( true ) {
    iVar9 = _GetScore();
    if (iVar9 <= *(int *)(puVar14 + 0x74)) break;
    if (local_35e == -1) break;
    *(int *)(puVar14 + 0x78) = *(int *)(puVar14 + 0x74);
    *(undefined2 *)(puVar10 + 0x88) = *(undefined2 *)(puVar10 + 0x86);
    _memmove(puVar13 + iVar4 + 0x54,puVar13 + iVar4 + 0x48,0xc);
    local_35e = local_35e + -1;
    puVar10 = puVar10 + -2;
    iVar4 = iVar4 + -0xc;
    puVar14 = puVar14 + -4;
  }
  iVar4 = (int)(short)(local_35e + 1);
  uVar6 = _GetScore();
  puVar13 = PTR__highScores_00034264;
  *(undefined4 *)(PTR__highScores_00034264 + iVar4 * 4 + 0x60) = uVar6;
  uVar2 = _GetLevel();
  *(undefined2 *)(puVar13 + iVar4 * 2 + 0x7c) = uVar2;
  __gLatestHighScoreIndex = local_35e + 1;
  uVar7 = _GetNewDialog(1000,0,0xffffffff);
  uVar6 = _GetDialogWindow(uVar7);
  uVar6 = _GetWindowPort(uVar6);
  _SetPort(uVar6);
  _PlayMySnd(0xd,10,0);
  _SetDialogDefaultItem(uVar7,1);
  _CreateWindowGroup(0,&local_2c);
  uVar6 = local_2c;
  uVar8 = _GetDialogWindow(uVar7);
  _SetWindowGroup(uVar8,uVar6);
  if (PTR__environment_0003f028[0x26] == '\0') {
    uVar6 = _CGShieldingWindowLevel();
  }
  else {
    uVar6 = _CGWindowLevelForKey(4);
  }
  _SetWindowGroupLevel(local_2c,uVar6);
  uVar6 = _GetDialogWindow(uVar7);
  _ZoomAndShowWindow(uVar6);
  _InitCursor();
  _SetDialogString(uVar7,2,PTR__highScores_00034264);
  _SelectDialogItemText(uVar7,2,0,0x400);
  uVar6 = _NewModalFilterUPP(_HiScoreNameFilter);
  do {
    _ModalDialog(uVar6,local_1e);
  } while (local_1e[0] != 1);
  _PlayMySnd(0xf,10,0);
  _GetDialogString(uVar7,2,local_250);
  uVar17 = local_250[0] == '\0';
  if ((bool)uVar17) {
    sVar3 = _GetRandomFast(0,1);
    if (sVar3 == 0) {
      builtin_strncpy(local_350,"Maniac",7);
    }
    else {
      builtin_strncpy(local_350,"Swoop",6);
    }
    puVar13 = PTR__highScores_00034264 + iVar4 * 0xc + 0xc;
    _CopyCStringToPascal(local_350,puVar13);
    goto LAB_00025494;
  }
  _CopyPascalStringToC(local_250,local_150);
  iVar9 = 8;
  pcVar11 = local_150;
  pcVar15 = "Wareing";
  do {
    pcVar12 = pcVar11;
    pcVar16 = pcVar15;
    if (iVar9 == 0) break;
    iVar9 = iVar9 + -1;
    pcVar16 = pcVar15 + 1;
    pcVar12 = pcVar11 + 1;
    uVar17 = *pcVar11 == *pcVar15;
    pcVar11 = pcVar12;
    pcVar15 = pcVar16;
  } while ((bool)uVar17);
  iVar9 = 0;
  if (!(bool)uVar17) {
    iVar9 = (uint)(byte)pcVar12[-1] - (uint)(byte)pcVar16[-1];
  }
  uVar17 = iVar9 == 0;
  if ((bool)uVar17) {
    builtin_strncpy(local_150,"Swoo",4);
    local_14c = CONCAT13(local_14c._3_1_,0x2170);
    _PlayMySnd(0xd,10,0);
  }
  iVar9 = 8;
  pcVar11 = local_150;
  pcVar15 = "Metcalf";
  do {
    pcVar12 = pcVar11;
    pcVar16 = pcVar15;
    if (iVar9 == 0) break;
    iVar9 = iVar9 + -1;
    pcVar16 = pcVar15 + 1;
    pcVar12 = pcVar11 + 1;
    uVar17 = *pcVar11 == *pcVar15;
    pcVar11 = pcVar12;
    pcVar15 = pcVar16;
  } while ((bool)uVar17);
  iVar9 = 0;
  if (!(bool)uVar17) {
    iVar9 = (uint)(byte)pcVar12[-1] - (uint)(byte)pcVar16[-1];
  }
  uVar17 = iVar9 == 0;
  if ((bool)uVar17) {
    builtin_strncpy(local_150,"Mani",4);
    local_14c = 0x216361;
    _PlayMySnd(0xd,10,0);
  }
  iVar9 = 5;
  pcVar11 = local_150;
  pcVar15 = "Luke";
  do {
    pcVar12 = pcVar11;
    pcVar16 = pcVar15;
    if (iVar9 == 0) break;
    iVar9 = iVar9 + -1;
    pcVar16 = pcVar15 + 1;
    pcVar12 = pcVar11 + 1;
    uVar17 = *pcVar11 == *pcVar15;
    pcVar11 = pcVar12;
    pcVar15 = pcVar16;
  } while ((bool)uVar17);
  iVar9 = 0;
  if (!(bool)uVar17) {
    iVar9 = (uint)(byte)pcVar12[-1] - (uint)(byte)pcVar16[-1];
  }
  uVar17 = iVar9 == 0;
  if ((bool)uVar17) {
    builtin_strncpy(local_150,"Skyw",4);
    local_14c = 0x656b6c61;
    local_148 = 0x72;
    _PlayMySnd(0xd,10,0);
  }
  iVar9 = 4;
  pcVar11 = local_150;
  pcVar15 = "Dog";
  do {
    pcVar12 = pcVar11;
    pcVar16 = pcVar15;
    if (iVar9 == 0) break;
    iVar9 = iVar9 + -1;
    pcVar16 = pcVar15 + 1;
    pcVar12 = pcVar11 + 1;
    uVar17 = *pcVar11 == *pcVar15;
    pcVar11 = pcVar12;
    pcVar15 = pcVar16;
  } while ((bool)uVar17);
  iVar9 = 0;
  if (!(bool)uVar17) {
    iVar9 = (uint)(byte)pcVar12[-1] - (uint)(byte)pcVar16[-1];
  }
  uVar17 = true;
  if (iVar9 == 0) {
LAB_0002519a:
    builtin_strncpy(local_150,"Nonn",4);
    local_14c = CONCAT22(local_14c._2_2_,0x79);
    _PlayMySnd(0x2e,10,0);
  }
  else {
    iVar9 = 5;
    bVar18 = false;
    pcVar11 = local_150;
    pcVar15 = "Woof";
    do {
      pcVar12 = pcVar11;
      pcVar16 = pcVar15;
      if (iVar9 == 0) break;
      iVar9 = iVar9 + -1;
      pcVar16 = pcVar15 + 1;
      pcVar12 = pcVar11 + 1;
      bVar18 = *pcVar11 == *pcVar15;
      pcVar11 = pcVar12;
      pcVar15 = pcVar16;
    } while (bVar18);
    iVar9 = 0;
    if (!bVar18) {
      iVar9 = (uint)(byte)pcVar12[-1] - (uint)(byte)pcVar16[-1];
    }
    uVar17 = iVar9 == 0;
    if ((bool)uVar17) goto LAB_0002519a;
  }
  iVar9 = 4;
  pcVar11 = local_150;
  pcVar15 = "Han";
  do {
    pcVar12 = pcVar11;
    pcVar16 = pcVar15;
    if (iVar9 == 0) break;
    iVar9 = iVar9 + -1;
    pcVar16 = pcVar15 + 1;
    pcVar12 = pcVar11 + 1;
    uVar17 = *pcVar11 == *pcVar15;
    pcVar11 = pcVar12;
    pcVar15 = pcVar16;
  } while ((bool)uVar17);
  iVar9 = 0;
  if (!(bool)uVar17) {
    iVar9 = (uint)(byte)pcVar12[-1] - (uint)(byte)pcVar16[-1];
  }
  uVar17 = iVar9 == 0;
  if ((bool)uVar17) {
    builtin_strncpy(local_150,"Solo",4);
    local_14c = local_14c & 0xffffff00;
    _PlayMySnd(0xd,10,0);
  }
  iVar9 = 6;
  pcVar11 = local_150;
  pcVar15 = "Darth";
  do {
    pcVar12 = pcVar11;
    pcVar16 = pcVar15;
    if (iVar9 == 0) break;
    iVar9 = iVar9 + -1;
    pcVar16 = pcVar15 + 1;
    pcVar12 = pcVar11 + 1;
    uVar17 = *pcVar11 == *pcVar15;
    pcVar11 = pcVar12;
    pcVar15 = pcVar16;
  } while ((bool)uVar17);
  iVar9 = 0;
  if (!(bool)uVar17) {
    iVar9 = (uint)(byte)pcVar12[-1] - (uint)(byte)pcVar16[-1];
  }
  uVar17 = iVar9 == 0;
  if ((bool)uVar17) {
    builtin_strncpy(local_150,"Vade",4);
    local_14c = CONCAT22(local_14c._2_2_,0x72);
    _PlayMySnd(0xd,10,0);
  }
  iVar9 = 4;
  pcVar11 = local_150;
  pcVar15 = "Ben";
  do {
    pcVar12 = pcVar11;
    pcVar16 = pcVar15;
    if (iVar9 == 0) break;
    iVar9 = iVar9 + -1;
    pcVar16 = pcVar15 + 1;
    pcVar12 = pcVar11 + 1;
    uVar17 = *pcVar11 == *pcVar15;
    pcVar11 = pcVar12;
    pcVar15 = pcVar16;
  } while ((bool)uVar17);
  iVar9 = 0;
  if (!(bool)uVar17) {
    iVar9 = (uint)(byte)pcVar12[-1] - (uint)(byte)pcVar16[-1];
  }
  uVar17 = iVar9 == 0;
  if ((bool)uVar17) {
    builtin_strncpy(local_150,"Obi ",4);
    local_14c = 0x6e6157;
    _PlayMySnd(0xd,10,0);
  }
  iVar9 = 6;
  pcVar11 = local_150;
  pcVar15 = "Apple";
  do {
    pcVar12 = pcVar11;
    pcVar16 = pcVar15;
    if (iVar9 == 0) break;
    iVar9 = iVar9 + -1;
    pcVar16 = pcVar15 + 1;
    pcVar12 = pcVar11 + 1;
    uVar17 = *pcVar11 == *pcVar15;
    pcVar11 = pcVar12;
    pcVar15 = pcVar16;
  } while ((bool)uVar17);
  iVar9 = 0;
  if (!(bool)uVar17) {
    iVar9 = (uint)(byte)pcVar12[-1] - (uint)(byte)pcVar16[-1];
  }
  uVar17 = iVar9 == 0;
  if ((bool)uVar17) {
    builtin_strncpy(local_150,"Moof",4);
    local_14c = local_14c & 0xffffff00;
    _PlayMySnd(0xd,10,0);
  }
  iVar9 = 5;
  pcVar11 = local_150;
  pcVar15 = "Bart";
  do {
    pcVar12 = pcVar11;
    pcVar16 = pcVar15;
    if (iVar9 == 0) break;
    iVar9 = iVar9 + -1;
    pcVar16 = pcVar15 + 1;
    pcVar12 = pcVar11 + 1;
    uVar17 = *pcVar11 == *pcVar15;
    pcVar11 = pcVar12;
    pcVar15 = pcVar16;
  } while ((bool)uVar17);
  iVar9 = 0;
  if (!(bool)uVar17) {
    iVar9 = (uint)(byte)pcVar12[-1] - (uint)(byte)pcVar16[-1];
  }
  uVar17 = iVar9 == 0;
  if ((bool)uVar17) {
    builtin_strncpy(local_150,"Simp",4);
    local_14c = 0x6e6f73;
    _PlayMySnd(0xd,10,0);
  }
  iVar9 = 6;
  pcVar11 = local_150;
  pcVar15 = "Homer";
  do {
    pcVar12 = pcVar11;
    pcVar16 = pcVar15;
    if (iVar9 == 0) break;
    iVar9 = iVar9 + -1;
    pcVar16 = pcVar15 + 1;
    pcVar12 = pcVar11 + 1;
    uVar17 = *pcVar11 == *pcVar15;
    pcVar11 = pcVar12;
    pcVar15 = pcVar16;
  } while ((bool)uVar17);
  iVar9 = 0;
  if (!(bool)uVar17) {
    iVar9 = (uint)(byte)pcVar12[-1] - (uint)(byte)pcVar16[-1];
  }
  uVar17 = iVar9 == 0;
  if ((bool)uVar17) {
    builtin_strncpy(local_150,"Doh",4);
    _PlayMySnd(0xd,10,0);
  }
  iVar9 = 6;
  pcVar11 = local_150;
  pcVar15 = "Steve";
  do {
    pcVar12 = pcVar11;
    pcVar16 = pcVar15;
    if (iVar9 == 0) break;
    iVar9 = iVar9 + -1;
    pcVar16 = pcVar15 + 1;
    pcVar12 = pcVar11 + 1;
    uVar17 = *pcVar11 == *pcVar15;
    pcVar11 = pcVar12;
    pcVar15 = pcVar16;
  } while ((bool)uVar17);
  iVar9 = 0;
  if (!(bool)uVar17) {
    iVar9 = (uint)(byte)pcVar12[-1] - (uint)(byte)pcVar16[-1];
  }
  uVar17 = iVar9 == 0;
  if ((bool)uVar17) {
    builtin_strncpy(local_150,"Woz",4);
    _PlayMySnd(0xd,10,0);
  }
  iVar9 = 6;
  pcVar11 = local_150;
  pcVar15 = "Oogle";
  do {
    pcVar12 = pcVar11;
    pcVar16 = pcVar15;
    if (iVar9 == 0) break;
    iVar9 = iVar9 + -1;
    pcVar16 = pcVar15 + 1;
    pcVar12 = pcVar11 + 1;
    uVar17 = *pcVar11 == *pcVar15;
    pcVar11 = pcVar12;
    pcVar15 = pcVar16;
  } while ((bool)uVar17);
  iVar9 = 0;
  if (!(bool)uVar17) {
    iVar9 = (uint)(byte)pcVar12[-1] - (uint)(byte)pcVar16[-1];
  }
  if (iVar9 == 0) {
    builtin_strncpy(local_150,"Boog",4);
    local_14c = CONCAT13(local_14c._3_1_,0x656c);
    _PlayMySnd(0xd,10,0);
  }
  _CopyCStringToPascal(local_150,local_250);
  puVar13 = PTR__highScores_00034264 + iVar4 * 0xc + 0xc;
  _memmove(puVar13,local_250,0xc);
LAB_00025494:
  _memmove(PTR__highScores_00034264,puVar13,0xc);
  if (*PTR__gUsingCustomLevels_0003f0a0 != '\0') {
    _CopyPascalStringToC(puVar13,local_350);
    pcVar11 = acStack_51 + 1;
    _strcpy(pcVar11,local_350);
    uVar5 = 0xffffffff;
    pcVar15 = pcVar11;
    do {
      if (uVar5 == 0) break;
      uVar5 = uVar5 - 1;
      cVar1 = *pcVar15;
      pcVar15 = pcVar15 + 1;
    } while (cVar1 != '\0');
    (pcVar11 + (~uVar5 - 1))[0] = '^';
    (pcVar11 + (~uVar5 - 1))[1] = '\0';
    _CopyCStringToPascal(pcVar11,puVar13);
  }
  _ReleaseWindowGroup(local_2c);
  _DisposeDialog(uVar7);
  _DisposeModalFilterUPP(uVar6);
  _SetToScreen();
  _UpdateScreen();
  return 1;
}


// ==== _DrawSingleHiScore @ 0002553a ====

void _DrawSingleHiScore(char param_1,short param_2,undefined1 param_3,char param_4)

{
  undefined *puVar1;
  int iVar2;
  byte *pbVar3;
  ushort uVar4;
  byte *pbVar5;
  int iVar6;
  undefined2 local_22e;
  undefined1 local_22c [256];
  byte local_12c;
  byte local_12b [255];
  short local_2c [3];
  undefined2 local_26;
  short local_24 [3];
  undefined2 local_1e;
  
  local_22e = param_2;
  iVar2 = (int)param_1;
  pbVar3 = PTR__highScores_00034264 + iVar2 * 0xc + 0xc;
  local_12c = *pbVar3;
  uVar4 = (ushort)local_12c;
  pbVar5 = local_12b;
  while( true ) {
    pbVar3 = pbVar3 + 1;
    uVar4 = uVar4 - 1;
    if ((short)uVar4 < 0) break;
    *pbVar5 = *pbVar3;
    pbVar5 = pbVar5 + 1;
  }
  _CopyPascalStringToC(&local_12c,local_22c);
  iVar6 = (int)local_22e;
  _DrawCustomString(local_22c,0x74,iVar6,param_3,0);
  if (local_22c[local_12c - 1] == '^') {
    local_2c[1] = 0x31;
    local_2c[0] = local_22e;
    local_26 = 0x60;
    local_2c[2] = local_22e + 0x17;
    _DrawPicture(*(undefined4 *)PTR__gCustomLevelsPict_00034260,local_2c);
  }
  puVar1 = PTR__highScores_00034264;
  _NumToString(*(undefined4 *)(PTR__highScores_00034264 + iVar2 * 4 + 0x60),&local_12c);
  _CopyPascalStringToC(&local_12c,local_22c);
  _DrawCustomString(local_22c,0x154,iVar6,param_3,1);
  _NumToString((int)*(short *)(puVar1 + iVar2 * 2 + 0x7c),&local_12c);
  _CopyPascalStringToC(&local_12c,local_22c);
  _DrawCustomString(local_22c,0x1d8,iVar6,param_3,1);
  if (param_4 != '\0') {
    local_24[1] = 0x6a;
    local_24[0] = local_22e + -5;
    local_1e = 0x209;
    local_24[2] = local_22e + 0x1b;
    _AddRectToScreen(local_24);
  }
  return;
}


// ==== _DisplayHiScores @ 00025733 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 _DisplayHiScores(void)

{
  short sVar1;
  undefined *puVar2;
  char cVar3;
  int iVar4;
  int iVar5;
  uint uVar6;
  short sVar7;
  int iVar8;
  ushort local_3c;
  uint local_3a;
  undefined1 local_2c [8];
  undefined2 local_24;
  undefined2 local_22;
  undefined2 local_20;
  undefined2 local_1e;
  
  iVar4 = _TickCount();
  _SetToBgndGWorld();
  _DrawAndCentrePict(0x390);
  _PatternFillCompGWorld(0x390);
  local_22 = 0xd1;
  local_24 = 0x50;
  local_1e = 0x1af;
  local_20 = 0x75;
  _SetToCompGWorld();
  iVar5 = _GetPicture(0x233c);
  if (iVar5 == 0) {
    _ResourceError(0x7d4,1,"PICT",0x233c);
  }
  _HNoPurge(iVar5);
  _DrawPicture(iVar5,&local_24);
  _HPurge(iVar5);
  iVar5 = _GetPicture(0x2375);
  puVar2 = PTR__gCustomLevelsPict_00034260;
  *(int *)PTR__gCustomLevelsPict_00034260 = iVar5;
  if (iVar5 == 0) {
    _ResourceError(0x7d4,1,"PICT",0x2375);
  }
  _MoveHHi(*(undefined4 *)puVar2);
  _HLock(*(undefined4 *)puVar2);
  _DrawCustomString("Name",0x74,0x91,1,0);
  _DrawCustomString("Score",0x151,0x91,1,0);
  _DrawCustomString("Level",0x1c3,0x91,1,0);
  iVar5 = 0;
  iVar8 = 0xbc;
  do {
    _DrawSingleHiScore(iVar5,iVar8,0,0);
    iVar5 = iVar5 + 1;
    iVar8 = iVar8 + 0x23;
  } while (iVar5 != 7);
  _SetToScreen();
  _WipeScreen(0xc);
  if (-1 < __gLatestHighScoreIndex) {
    _WaitFor(0x14);
    sVar1 = __gLatestHighScoreIndex * 0x23;
    _SetRect(local_2c,0x74,(int)(short)(sVar1 + 0xb7),0x209,(int)(short)(sVar1 + 0xd8));
    sVar7 = 6;
    do {
      _ResetNumScrnRects();
      _ResetNumBgndRects();
      _AddRectToBgnd(local_2c);
      _AddRectToScreen(local_2c);
      _RestoreBgnd(1);
      _DrawRectsToScreen();
      _FlushIfNecessary();
      _WaitFor(5);
      _DrawSingleHiScore((int)_gLatestHighScoreIndex,(int)(short)(sVar1 + 0xbc),0,1);
      _DrawRectsToScreen();
      _FlushIfNecessary();
      _WaitFor(5);
      sVar7 = sVar7 + -1;
    } while (sVar7 != 0);
  }
  __gLatestHighScoreIndex = 0xffff;
  _FlushEvents(0x3e,0);
  while( true ) {
    while( true ) {
      uVar6 = _TickCount();
      if (iVar4 + 600U < uVar6) {
        return 0;
      }
      cVar3 = _WaitNextEvent(0x800a,&local_3c,10,0);
      if (cVar3 != '\0') break;
      cVar3 = _IsCommandKeyDown();
      if ((cVar3 != '\0') && (cVar3 = _GameKeyDown(0xc), cVar3 != '\0')) {
        *PTR__gFinished_0003f074 = 1;
        return 0;
      }
    }
    if (local_3c == 3) break;
    if (local_3c < 4) {
      if (local_3c == 1) {
LAB_00025a7d:
        _PlayMySnd(0x11,10,0);
        return 0;
      }
    }
    else {
      if (local_3c == 5) break;
      if ((local_3c == 0xf) && (local_3a >> 0x18 == 1)) {
        if ((local_3a & 1) == 0) {
          _SuspendGame();
        }
        else {
          _ResumeGame();
        }
      }
    }
  }
  if (((char)local_3a == 'N') || ((char)local_3a == 'n')) {
    _PlayMySnd(0x11,10,0);
    return 1;
  }
  goto LAB_00025a7d;
}


// ==== _LoadHandCursor @ 00025af8 ====

void _LoadHandCursor(void)

{
  _gCursor_Hand = _GetCCursor(200);
  if (_gCursor_Hand != 0) {
    _HLock(_gCursor_Hand);
  }
  return;
}


// ==== _SetMyCCursor @ 00025b1d ====

void _SetMyCCursor(short param_1)

{
  if (param_1 == 200) {
    _SetCCursor();
    return;
  }
  _DebugValues("SetMyCursor() - Unknown cursor type.",(int)param_1);
  return;
}


// ==== _MyInitCursor @ 00025b4e ====

void _MyInitCursor(void)

{
  if (_gCursID != 0) {
    _InitCursor();
  }
  _gCursID = 0;
  return;
}


// ==== _MySetCursor @ 00025b6e ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _MySetCursor(short param_1)

{
  short sVar1;
  int iVar2;
  undefined4 *puVar3;
  
  if (_gCursID == param_1) {
    return;
  }
  if (param_1 == -1) {
    if (_gCursID != -1) {
      _gCursID = -1;
      _HideCursor();
    }
  }
  else if (_gCursID == -1) {
    _InitCursor();
    _gCursID = 0;
  }
  iVar2 = _GetCCursor((int)param_1);
  if ((iVar2 == 0) || (sVar1 = _ResError(), sVar1 != 0)) {
    puVar3 = (undefined4 *)_GetCursor((int)param_1);
    if (puVar3 == (undefined4 *)0x0) {
      return;
    }
    sVar1 = _ResError();
    if (sVar1 != 0) {
      return;
    }
    _SetCursor(*puVar3);
  }
  else {
    _SetCCursor(iVar2);
  }
  _gCursID = param_1;
  __gCursChange = _TickCount();
  return;
}


// ==== _SpinMyCursor @ 00025c1b ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SpinMyCursor(void)

{
  int iVar1;
  
  iVar1 = _TickCount();
  if (9 < (uint)(iVar1 - __gCursChange)) {
    if (6 < (ushort)(_gCursID - 0x100U)) {
      _gCursID = 0x100;
    }
    _MySetCursor((int)(short)(_gCursID + 1));
  }
  return;
}


// ==== _DrawPlayerInfo @ 00025c60 ====

void _DrawPlayerInfo(void)

{
  return;
}


// ==== _PrepareScoreBar @ 00025c65 ====

void _PrepareScoreBar(void)

{
  undefined4 local_22;
  undefined4 local_1e;
  undefined4 local_1a;
  undefined4 local_16;
  undefined2 local_12;
  undefined2 local_10;
  undefined2 local_e;
  
  _SetToCompGWorld();
  _SetRect(&local_1a,0,0x1b8,0x280,0x1e0);
  local_e = 0x7fff;
  local_10 = 0x7fff;
  local_12 = 0x7fff;
  _OpColor(&local_12);
  _PenMode(0x20);
  _ForeColor(0x21);
  _PaintRect(&local_1a);
  _PenMode(0);
  _ForeColor(0x21);
  _ForeColor(0x155);
  _PenSize(1,2);
  _MoveTo(0,0x1b8);
  _LineTo(0x280,0x1b8);
  _PenSize(1,1);
  _ForeColor(0x21);
  _SetRect(&local_22,0,0,0x280,0x28);
  _CompToScore(local_1a,local_16,local_22,local_1e);
  return;
}


// ==== _DrawMaze @ 00025daa ====

void _DrawMaze(void)

{
  undefined *puVar1;
  short sVar2;
  undefined1 *puVar3;
  int iVar4;
  int iVar5;
  longlong lVar6;
  undefined4 uVar7;
  int local_20;
  
  _SetToBgndGWorld();
  _PaintBgndGWorld();
  _SetToCompGWorld();
  _PaintCompGWorld();
  _SetToBgndGWorld();
  puVar1 = PTR__level_0003f010;
  _DrawAndCentrePict((int)*(short *)(PTR__level_0003f010 + 2));
  lVar6 = _RT3_GetLicenseCode();
  *PTR__gAIRegistered_00034270 = lVar6 != 0;
  _SetToCompGWorld();
  _DrawAndCentrePict((int)*(short *)(puVar1 + 2));
  _PrepareScoreBar();
  local_20 = 0;
  iVar5 = 0;
  do {
    puVar3 = PTR__gMaze_00034268 + local_20 * 0x10;
    iVar4 = 0;
    do {
      switch(*puVar3) {
      case 10:
        uVar7 = 0x11;
        break;
      default:
        goto switchD_00025e29_caseD_b;
      case 0xf:
        uVar7 = 0x14;
        break;
      case 0x10:
        uVar7 = 0x15;
        break;
      case 0x14:
        uVar7 = 0x16;
        break;
      case 0x1e:
        uVar7 = 0x17;
        break;
      case 0x34:
        sVar2 = _GetCurrLevelNum();
        if (sVar2 < 0xc) {
          uVar7 = 0x12;
        }
        else {
          uVar7 = 0x13;
        }
      }
      _SpriteToComp(0,iVar4,iVar5,uVar7,1,0);
switchD_00025e29_caseD_b:
      puVar3 = puVar3 + 1;
      iVar4 = iVar4 + 0x28;
    } while (iVar4 != 0x280);
    local_20 = local_20 + 1;
    iVar5 = iVar5 + 0x28;
    if (local_20 == 0xb) {
      return;
    }
  } while( true );
}


// ==== _GetNextObject @ 00025f34 ====

int _GetNextObject(char param_1,char param_2,char param_3)

{
  char unaff_BL;
  
  if (param_1 == '\x02') {
    if (param_3 == '\n') {
      return 0x32;
    }
    unaff_BL = PTR__gMaze_00034268[(int)param_2 + param_3 * 0x10 + 0x10];
    goto LAB_00025f69;
  }
  if (param_1 < '\x03') {
    if (param_1 == '\x01') {
      if (param_3 == '\0') {
        return 0x32;
      }
      unaff_BL = PTR__gMaze_00034268[(int)param_2 + param_3 * 0x10 + -0x10];
      goto LAB_00025f69;
    }
  }
  else {
    if (param_1 == '\x03') {
      if (param_2 == '\0') {
        return 0x32;
      }
      unaff_BL = PTR__gMaze_00034268[(int)param_2 + param_3 * 0x10 + -1];
      goto LAB_00025f69;
    }
    if (param_1 == '\x04') {
      if (param_2 == '\x0f') {
        return 0x32;
      }
      unaff_BL = PTR__gMaze_00034268[(int)param_2 + param_3 * 0x10 + 1];
      goto LAB_00025f69;
    }
  }
  _DebugValues("GetNextObject() - Unknown direction.",(int)param_1);
  _CleanUp();
LAB_00025f69:
  return (int)unaff_BL;
}


// ==== _GetDistantObject @ 00025fed ====

int _GetDistantObject(char param_1,char param_2,char param_3)

{
  char unaff_BL;
  
  if (param_1 == '\x02') {
    if (param_3 == '\t') {
      return 0x32;
    }
    unaff_BL = PTR__gMaze_00034268[(int)param_2 + param_3 * 0x10 + 0x20];
    goto LAB_00026022;
  }
  if (param_1 < '\x03') {
    if (param_1 == '\x01') {
      if (param_3 == '\x01') {
        return 0x32;
      }
      unaff_BL = PTR__gMaze_00034268[(int)param_2 + param_3 * 0x10 + -0x20];
      goto LAB_00026022;
    }
  }
  else {
    if (param_1 == '\x03') {
      if (param_2 == '\x01') {
        return 0x32;
      }
      unaff_BL = PTR__gMaze_00034268[(int)param_2 + param_3 * 0x10 + -2];
      goto LAB_00026022;
    }
    if (param_1 == '\x04') {
      if (param_2 == '\x0e') {
        return 0x32;
      }
      unaff_BL = PTR__gMaze_00034268[(int)param_2 + param_3 * 0x10 + 2];
      goto LAB_00026022;
    }
  }
  _DebugValues("GetDistantObject() - Unknown direction.",(int)param_1);
  _CleanUp();
LAB_00026022:
  return (int)unaff_BL;
}


// ==== _NormalBlockCount @ 000260a8 ====

int _NormalBlockCount(void)

{
  char cVar1;
  char *pcVar2;
  short sVar3;
  int iVar4;
  
  sVar3 = 0;
  iVar4 = 0;
  do {
    pcVar2 = PTR__gMaze_00034268 + iVar4 * 0x10;
    cVar1 = '\x10';
    do {
      if (*pcVar2 == '\n') {
        sVar3 = sVar3 + 1;
      }
      pcVar2 = pcVar2 + 1;
      cVar1 = cVar1 + -1;
    } while (cVar1 != '\0');
    iVar4 = iVar4 + 1;
  } while (iVar4 != 0xb);
  return (int)sVar3;
}


// ==== _SaveMaze @ 000260e6 ====

void _SaveMaze(short param_1)

{
  int iVar1;
  undefined4 *puVar2;
  
  iVar1 = _GetResource(0x4d415a45,(int)param_1);
  if (iVar1 != 0) {
    _RemoveResource(iVar1);
    _DisposeHandle(iVar1);
  }
  puVar2 = (undefined4 *)_NewHandle(0xb0);
  _memmove((void *)*puVar2,PTR__gMaze_00034268,0xb0);
  _AddResource(puVar2,0x4d415a45,(int)param_1,"\tMaze Data");
  _WriteResource(puVar2);
  _ReleaseResource();
  return;
}


// ==== _DrawMiniMaze @ 00026173 ====

void _DrawMiniMaze(void)

{
  undefined1 *puVar1;
  int iVar2;
  int iVar3;
  undefined4 uVar4;
  int local_20;
  
  _SetToScreen();
  _PenSize(6,6);
  local_20 = 0;
  iVar3 = 0;
  do {
    puVar1 = PTR__gMaze_00034268 + local_20 * 0x10;
    iVar2 = 0;
    do {
      switch(*puVar1) {
      case 0:
        uVar4 = 0x21;
        break;
      default:
        goto switchD_000261b4_caseD_1;
      case 10:
        uVar4 = 0x1e;
        break;
      case 0xf:
      case 0x28:
        uVar4 = 0x155;
        break;
      case 0x10:
        uVar4 = 0x45;
        break;
      case 0x14:
        uVar4 = 0x199;
        break;
      case 0x1e:
        uVar4 = 0xcd;
        break;
      case 0x34:
        uVar4 = 0x111;
        break;
      case 0x3c:
        uVar4 = 0x89;
      }
      _ForeColor(uVar4);
switchD_000261b4_caseD_1:
      _MoveTo(iVar2,iVar3);
      _Line(0,0);
      puVar1 = puVar1 + 1;
      iVar2 = iVar2 + 6;
    } while (iVar2 != 0x60);
    local_20 = local_20 + 1;
    iVar3 = iVar3 + 6;
    if (local_20 == 0xb) {
      _ForeColor(0x21);
      _PenSize(1,1);
      return;
    }
  } while( true );
}


// ==== _LoadMaze @ 0002626e ====

bool _LoadMaze(short param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined1 *puVar3;
  undefined4 *puVar4;
  short sVar5;
  undefined1 *puVar6;
  int iVar7;
  
  puVar2 = PTR__gMazeCopy_0003426c;
  puVar1 = PTR__gMaze_00034268;
  iVar7 = 0;
  do {
    puVar6 = puVar1 + iVar7 * 0x10;
    puVar3 = puVar2 + iVar7 * 0x10;
    sVar5 = 0x10;
    do {
      *puVar6 = 0;
      *puVar3 = 0;
      puVar6 = puVar6 + 1;
      puVar3 = puVar3 + 1;
      sVar5 = sVar5 + -1;
    } while (sVar5 != 0);
    iVar7 = iVar7 + 1;
  } while (iVar7 != 0xb);
  iVar7 = (int)param_1;
  puVar4 = (undefined4 *)_GetResource(0x4d415a45,iVar7);
  if (puVar4 != (undefined4 *)0x0) {
    _MoveHHi(puVar4);
    _HLock(puVar4);
    _OtherMazeCheck(puVar4,iVar7);
    _memmove(PTR__gMaze_00034268,(void *)*puVar4,0xb0);
    _memmove(PTR__gMazeCopy_0003426c,(void *)*puVar4,0xb0);
    _CheckMaze(puVar4,iVar7);
    _ReleaseResource(puVar4);
  }
  return puVar4 != (undefined4 *)0x0;
}


// ==== _InitScreenCopy @ 00026347 ====

void _InitScreenCopy(void)

{
  return;
}


// ==== _ResetNumScrnRects @ 0002634c ====

void _ResetNumScrnRects(void)

{
  _sScrnRectCount = 0;
  return;
}


// ==== _AddRectToScreen @ 0002635a ====

void _AddRectToScreen(uint *param_1)

{
  short sVar1;
  short sVar2;
  short sVar3;
  uint uVar4;
  short sVar5;
  short sVar6;
  int iVar7;
  uint uVar8;
  short sVar9;
  short sVar10;
  short sVar11;
  short sVar12;
  short sVar13;
  bool bVar14;
  bool bVar15;
  short local_ec;
  short local_cc;
  int local_a8;
  uint local_a4;
  undefined4 local_5c;
  undefined4 local_58;
  int local_50;
  undefined4 local_24;
  undefined4 local_20;
  
  uVar8 = param_1[1];
  uVar4 = *param_1;
  local_24._2_2_ = (short)(uVar4 >> 0x10);
  local_cc = local_24._2_2_;
  local_24._0_2_ = (short)uVar4;
  local_20._0_2_ = (short)uVar8;
  local_20._2_2_ = (short)(uVar8 >> 0x10);
  local_ec = local_20._2_2_;
  sVar13 = 0;
  while( true ) {
    if (_sScrnRectCount <= sVar13) {
      if ((((-1 < (int)uVar8) && (local_24._2_2_ < 0x281)) && ((short)local_24 < 0x1b9)) &&
         (-1 < (short)local_20)) {
        local_24 = uVar4;
        if ((int)uVar4 < 0) {
          local_cc = 0;
          local_24 = uVar4 & 0xffff;
        }
        if (0x280 < local_20._2_2_) {
          local_20 = CONCAT22(0x280,(short)local_20);
          local_ec = 0x280;
          uVar8 = local_20;
        }
        local_20 = uVar8;
        sVar13 = 0;
        if (-1 < (short)local_24) {
          sVar13 = (short)local_24;
        }
        local_24 = CONCAT22(local_24._2_2_,sVar13);
        sVar12 = 0x1b8;
        if ((short)local_20 < 0x1b9) {
          sVar12 = (short)local_20;
        }
        local_20 = CONCAT22(local_20._2_2_,sVar12);
        if (((int)local_ec != (int)local_cc && -1 < (int)local_ec - (int)local_cc) &&
           ((int)sVar12 != (int)sVar13 && -1 < (int)sVar12 - (int)sVar13)) {
          if (_sScrnRectCount < _sNumScrnRects) {
            *(uint *)(&_sScrnRectList + _sScrnRectCount * 8) = local_24;
            *(uint *)(&DAT_00037f24 + _sScrnRectCount * 8) = local_20;
            _sScrnRectCount = _sScrnRectCount + 1;
          }
          else {
            local_a8 = 0;
            local_a4 = 0xffffffff;
            for (local_50 = 0; (short)local_50 < _sScrnRectCount; local_50 = local_50 + 1) {
              iVar7 = (int)(short)local_50;
              sVar5 = *(short *)(&DAT_00037f22 + iVar7 * 8);
              sVar10 = local_cc;
              if (sVar5 < local_cc) {
                sVar10 = sVar5;
              }
              sVar1 = *(short *)(&_sScrnRectList + iVar7 * 8);
              sVar9 = sVar13;
              if (sVar1 < sVar13) {
                sVar9 = sVar1;
              }
              sVar2 = *(short *)(&DAT_00037f26 + iVar7 * 8);
              sVar11 = local_ec;
              if (local_ec < sVar2) {
                sVar11 = sVar2;
              }
              sVar3 = *(short *)(&DAT_00037f24 + iVar7 * 8);
              sVar6 = sVar12;
              if (sVar12 < sVar3) {
                sVar6 = sVar3;
              }
              uVar8 = ((int)sVar6 - (int)sVar9) * ((int)sVar11 - (int)sVar10) -
                      ((int)sVar2 - (int)sVar5) * ((int)sVar3 - (int)sVar1);
              if (uVar8 < local_a4) {
                local_58 = CONCAT22(sVar11,sVar6);
                local_5c = CONCAT22(sVar10,sVar9);
                local_a8 = local_50;
                local_a4 = uVar8;
              }
            }
            *(undefined4 *)(&_sScrnRectList + local_a8 * 8) = local_5c;
            *(undefined4 *)(&DAT_00037f24 + local_a8 * 8) = local_58;
          }
        }
      }
      return;
    }
    iVar7 = (int)sVar13;
    sVar12 = *(short *)(&DAT_00037f22 + iVar7 * 8);
    if (local_24._2_2_ < sVar12) {
      bVar14 = SBORROW2(sVar12,local_20._2_2_);
      sVar5 = sVar12 - local_20._2_2_;
    }
    else {
      bVar14 = SBORROW2(local_24._2_2_,*(short *)(&DAT_00037f26 + iVar7 * 8));
      sVar5 = local_24._2_2_ - *(short *)(&DAT_00037f26 + iVar7 * 8);
    }
    sVar10 = *(short *)(&_sScrnRectList + iVar7 * 8);
    if ((short)local_24 < sVar10) {
      bVar15 = SBORROW2(sVar10,(short)local_20);
      sVar1 = sVar10 - (short)local_20;
    }
    else {
      bVar15 = SBORROW2((short)local_24,*(short *)(&DAT_00037f24 + iVar7 * 8));
      sVar1 = (short)local_24 - *(short *)(&DAT_00037f24 + iVar7 * 8);
    }
    if ((bVar15 != sVar1 < 0) && (bVar14 != sVar5 < 0)) break;
    sVar13 = sVar13 + 1;
  }
  if (sVar12 < local_24._2_2_) {
    local_24._2_2_ = sVar12;
  }
  if (sVar10 <= (short)local_24) {
    local_24._0_2_ = sVar10;
  }
  sVar12 = *(short *)(&DAT_00037f26 + iVar7 * 8);
  if (*(short *)(&DAT_00037f26 + iVar7 * 8) < local_20._2_2_) {
    sVar12 = local_20._2_2_;
  }
  sVar5 = *(short *)(&DAT_00037f24 + iVar7 * 8);
  if (*(short *)(&DAT_00037f24 + iVar7 * 8) < (short)local_20) {
    sVar5 = (short)local_20;
  }
  local_20 = CONCAT22(sVar12,sVar5);
  sVar12 = _sScrnRectCount + -1;
  _sScrnRectCount = sVar12;
  for (; sVar13 < sVar12; sVar13 = sVar13 + 1) {
    iVar7 = (int)sVar13;
    *(undefined4 *)(&_sScrnRectList + iVar7 * 8) = *(undefined4 *)(&DAT_00037f28 + iVar7 * 8);
    *(undefined4 *)(&DAT_00037f24 + iVar7 * 8) = *(undefined4 *)(&DAT_00037f2c + iVar7 * 8);
  }
  _AddRectToScreen(&local_24);
  return;
}


// ==== _DrawRectsToScreen @ 0002675a ====

void _DrawRectsToScreen(void)

{
  undefined4 uVar1;
  int iVar2;
  short sVar3;
  uint uVar4;
  ushort local_40;
  undefined4 local_3e;
  
  for (sVar3 = 0; sVar3 < _sScrnRectCount; sVar3 = sVar3 + 1) {
    uVar1 = *(undefined4 *)(&_sScrnRectList + sVar3 * 8);
    iVar2 = *(int *)(&DAT_00037f24 + sVar3 * 8);
    uVar4 = iVar2 >> 0x10;
    local_40 = (ushort)iVar2;
    local_3e = uVar1;
    if (PTR__environment_0003f028[8] != '\0') {
      local_3e = CONCAT22((short)((uint)uVar1 >> 0x10) +
                          *(short *)(PTR__environment_0003f028 + 0x1a),
                          (short)uVar1 + *(short *)(PTR__environment_0003f028 + 0x1c));
      uVar4 = (uint)(ushort)(*(short *)(PTR__environment_0003f028 + 0x1a) +
                            (short)((uint)iVar2 >> 0x10));
      local_40 = *(short *)(PTR__environment_0003f028 + 0x1c) + local_40;
    }
    _CompToScreen(uVar1,iVar2,local_3e,(uint)local_40 | uVar4 << 0x10);
  }
  return;
}


// ==== _Sounds_InitDelayedSounds @ 00026888 ====

void _Sounds_InitDelayedSounds(void)

{
  undefined2 *puVar1;
  
  puVar1 = &_delayedSound;
  do {
    *puVar1 = 0xffff;
    puVar1 = puVar1 + 3;
  } while (puVar1 != &_gShowWhichNotice);
  return;
}


// ==== _Sounds_CheckDelayedSounds @ 000268a1 ====

void _Sounds_CheckDelayedSounds(void)

{
  ushort uVar1;
  undefined2 uVar2;
  ushort uVar3;
  short sVar4;
  undefined2 *puVar5;
  undefined4 uVar6;
  
  uVar3 = _GetFrameCounter();
  puVar5 = &DAT_000381a6;
  do {
    uVar1 = puVar5[-2];
    if (((uVar1 != 0xffff) && ((ushort)puVar5[-1] <= uVar3)) && (puVar5[-2] = 0xffff, uVar1 < 0x30))
    {
      uVar2 = *puVar5;
      sVar4 = _GetShortPref(0x33);
      if (sVar4 == 3) {
        uVar6 = 0x40;
      }
      else if (sVar4 == 4) {
        uVar6 = 0x100;
      }
      else {
        if (sVar4 != 2) goto LAB_00026930;
        uVar6 = 0x10;
      }
      _ST_PlaySound(*(undefined4 *)(PTR__gSound_0003427c + (short)uVar1 * 4),uVar2,uVar6);
    }
LAB_00026930:
    puVar5 = puVar5 + 3;
    if (puVar5 == (undefined2 *)&_gEraseNotice) {
      return;
    }
  } while( true );
}


// ==== _InitAmbrosiaSoundTool @ 00026947 ====

void _InitAmbrosiaSoundTool(void)

{
  short sVar1;
  
  sVar1 = _ST_Open(4,0);
  if (sVar1 != 0) {
    _ResultError(2000,3,(int)sVar1);
  }
  return;
}


// ==== _UpdateSoundVol @ 00026981 ====

void _UpdateSoundVol(void)

{
  return;
}


// ==== _PlayIntroSound @ 00026986 ====

void _PlayIntroSound(void)

{
  undefined *puVar1;
  short sVar2;
  int iVar3;
  undefined4 uVar4;
  
  iVar3 = _ST_LoadSndResource(0x2343);
  puVar1 = PTR__gIntroSnd_00034278;
  *(int *)PTR__gIntroSnd_00034278 = iVar3;
  if (iVar3 == 0) {
    _ResourceError(2000,1,"snd ",0x2343);
  }
  sVar2 = _GetShortPref(0x33);
  if (sVar2 == 3) {
    uVar4 = 0x40;
  }
  else if (sVar2 == 4) {
    uVar4 = 0x100;
  }
  else {
    if (sVar2 != 2) {
      return;
    }
    uVar4 = 0x10;
  }
  _ST_PlaySound(*(undefined4 *)puVar1,0x14,uVar4);
  return;
}


// ==== _DisposeIntroSound @ 00026a1b ====

void _DisposeIntroSound(void)

{
  return;
}


// ==== _LoadSounds @ 00026a20 ====

void _LoadSounds(void)

{
  int iVar1;
  int iVar2;
  int *piVar3;
  
  iVar2 = 9000;
  piVar3 = (int *)PTR__gSound_0003427c;
  do {
    iVar1 = _ST_LoadSndResource(iVar2);
    *piVar3 = iVar1;
    if (iVar1 == 0) {
      _ResourceError(2000,2,"snd ",iVar2);
    }
    _UpdateProgress();
    iVar2 = iVar2 + 1;
    piVar3 = piVar3 + 1;
  } while (iVar2 != 0x2358);
  return;
}


// ==== _PlayMySnd @ 00026a7b ====

void _PlayMySnd(short param_1,undefined2 param_2,short param_3)

{
  short sVar1;
  short *psVar2;
  int iVar3;
  undefined4 uVar4;
  
  if (param_3 != 0) {
    iVar3 = 0;
    psVar2 = &_delayedSound;
    do {
      if (*psVar2 == -1) {
        (&_delayedSound)[iVar3 * 3] = param_1;
        sVar1 = _GetFrameCounter();
        (&DAT_000381a4)[iVar3 * 3] = param_3 + sVar1;
        (&DAT_000381a6)[iVar3 * 3] = param_2;
        return;
      }
      iVar3 = iVar3 + 1;
      psVar2 = psVar2 + 3;
    } while (iVar3 != 5);
  }
  sVar1 = _GetShortPref(0x33);
  if (sVar1 == 3) {
    uVar4 = 0x40;
  }
  else if (sVar1 == 4) {
    uVar4 = 0x100;
  }
  else {
    if (sVar1 != 2) {
      return;
    }
    uVar4 = 0x10;
  }
  _ST_PlaySound(*(undefined4 *)(PTR__gSound_0003427c + param_1 * 4),param_2,uVar4);
  return;
}


// ==== _SaveGamePrefs @ 00026b36 ====

void _SaveGamePrefs(void)

{
  short sVar1;
  char local_118 [256];
  undefined4 local_18;
  undefined4 local_14;
  short local_10;
  short local_e;
  
  _GetIndString(local_118,0x81,5);
  if (local_118[0] == '\0') {
    _ResourceError(0x7d7,1,"STR#",0x81);
  }
  sVar1 = _FindFolder(0xffff8000,0x70726566,1,&local_e,&local_14);
  if (sVar1 != 0) {
    _ResultError(0x7d7,2,(int)sVar1);
  }
  sVar1 = _HOpen((int)local_e,local_14,local_118,0,&local_10);
  if (sVar1 != 0) {
    if (sVar1 == -0x2b) {
      sVar1 = _HCreate((int)local_e,local_14,local_118,0x42756262,0x70726566);
      if (sVar1 != 0) {
        _ResultError(0x7d7,3,(int)sVar1);
      }
      sVar1 = _HOpen((int)local_e,local_14,local_118,0,&local_10);
      if (sVar1 != 0) {
        _ResultError(0x7d7,4,(int)sVar1);
      }
      _LoadDefaultHiScores();
    }
    else {
      _ResultError(0x7d7,5,(int)sVar1);
    }
  }
  sVar1 = _SetFPos((int)local_10,1,0);
  if (sVar1 != 0) {
    _FSClose((int)local_10);
    _ResultError(0x7d7,6,(int)sVar1);
  }
  local_18 = 0x800;
  sVar1 = _FSWrite((int)local_10,&local_18,*(undefined4 *)PTR__gPrefsData_00034280);
  if (sVar1 == 0) {
    local_18 = 0x8a;
    _SwapHighScoresToBigEndian();
    sVar1 = _FSWrite((int)local_10,&local_18,PTR__highScores_0003f0a4);
    _SwapHighScoresFromBigEndian();
    if (sVar1 == 0) goto LAB_00026d81;
  }
  _FSClose((int)local_10);
  _ResultError(0x7d7,7,(int)sVar1);
LAB_00026d81:
  sVar1 = _FSClose((int)local_10);
  if (sVar1 != 0) {
    _ResultError(0x7d7,8,(int)sVar1);
  }
  return;
}


// ==== _SetBooleanPref @ 00026db5 ====

void _SetBooleanPref(short param_1,undefined1 param_2)

{
  if (99 < (ushort)(param_1 - 1U)) {
    _LocationErrorInt(0x7d7,0xc);
  }
  *(undefined1 *)((int)(short)(param_1 + 1) + *(int *)PTR__gPrefsData_00034280) = param_2;
  return;
}


// ==== _SetHighScore @ 00026df9 ====

void _SetHighScore(short param_1,char *param_2,undefined4 param_3)

{
  char cVar1;
  uint uVar2;
  char *pcVar3;
  char local_21c [256];
  undefined1 local_11c [268];
  
  if (9 < (ushort)(param_1 - 1U)) {
    _LocationErrorInt(0x7d7,0x10);
  }
  uVar2 = 0xffffffff;
  pcVar3 = param_2;
  do {
    if (uVar2 == 0) break;
    uVar2 = uVar2 - 1;
    cVar1 = *pcVar3;
    pcVar3 = pcVar3 + 1;
  } while (cVar1 != '\0');
  if (0x1d < ~uVar2 - 1) {
    _ResultErrorInt(0x7d7,0x11,(int)(short)(~uVar2 - 1));
  }
  pcVar3 = (char *)((int)(short)((param_1 - 1U) * 0x28 + 0x476) + *(int *)PTR__gPrefsData_00034280);
  _strcpy(pcVar3,param_2);
  _NumToString(param_3,local_11c);
  _CopyPascalStringToC(local_11c,local_21c);
  _strcpy(pcVar3 + 0x1e,local_21c);
  return;
}


// ==== _GetBooleanPref @ 00026ebc ====

undefined1 _GetBooleanPref(short param_1)

{
  if (99 < (ushort)(param_1 - 1U)) {
    _LocationError(0x7d7,0xc);
  }
  return *(undefined1 *)((int)(short)(param_1 + 1) + *(int *)PTR__gPrefsData_00034280);
}


// ==== _GetLongPref @ 00026efa ====

uint _GetLongPref(short param_1)

{
  uint uVar1;
  
  if (99 < (ushort)(param_1 - 1U)) {
    _LocationError(0x7d7,0xe);
  }
  uVar1 = *(uint *)((int)(short)((param_1 - 1U) * 4 + 0x12e) + *(int *)PTR__gPrefsData_00034280);
  return uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
}


// ==== _GetHighScore @ 00026f3d ====

void _GetHighScore(short param_1,char *param_2,undefined4 param_3)

{
  char *pcVar1;
  undefined1 local_20c [256];
  char local_10c [256];
  
  if (9 < (ushort)(param_1 - 1U)) {
    _LocationError(0x7d7,0x10);
  }
  pcVar1 = (char *)((int)(short)((param_1 - 1U) * 0x28 + 0x476) + *(int *)PTR__gPrefsData_00034280);
  _strcpy(param_2,pcVar1);
  _strcpy(local_10c,pcVar1 + 0x1e);
  _CopyCStringToPascal(local_10c,local_20c);
  _StringToNum(local_20c,param_3);
  return;
}


// ==== _SetPrefsVersion @ 00026fcf ====

void _SetPrefsVersion(ushort param_1)

{
  **(ushort **)PTR__gPrefsData_00034280 = param_1 << 8 | param_1 >> 8;
  return;
}


// ==== _SetShortPref @ 00026fe7 ====

void _SetShortPref(short param_1,ushort param_2)

{
  if (99 < (ushort)(param_1 - 1U)) {
    _LocationErrorInt(0x7d7,0xd);
  }
  *(ushort *)((int)(short)(param_1 + 0x65 + (param_1 - 1U)) + *(int *)PTR__gPrefsData_00034280) =
       param_2 << 8 | param_2 >> 8;
  return;
}


// ==== _SetKeySetPref @ 00027030 ====

void _SetKeySetPref(short param_1,int param_2,ushort param_3,ushort param_4,ushort param_5,
                   ushort param_6,ushort param_7)

{
  ushort *puVar1;
  int iVar2;
  ushort *puVar3;
  
  if (0x13 < (ushort)(param_1 - 1U)) {
    _LocationErrorInt(0x7d7,0xf);
  }
  iVar2 = 0;
  puVar1 = (ushort *)
           ((int)(short)((param_1 - 1U) * 0x16 + 0x2be) + *(int *)PTR__gPrefsData_00034280);
  do {
    puVar3 = puVar1;
    *(undefined1 *)puVar3 = *(undefined1 *)(iVar2 + param_2);
    iVar2 = iVar2 + 1;
    puVar1 = (ushort *)((int)puVar3 + 1);
  } while (iVar2 != 0xc);
  *(ushort *)((int)puVar3 + 1) = param_3 << 8 | param_3 >> 8;
  *(ushort *)((int)puVar3 + 3) = param_4 << 8 | param_4 >> 8;
  *(ushort *)((int)puVar3 + 5) = param_5 << 8 | param_5 >> 8;
  *(ushort *)((int)puVar3 + 7) = param_6 << 8 | param_6 >> 8;
  *(ushort *)((int)puVar3 + 9) = param_7 << 8 | param_7 >> 8;
  return;
}


// ==== _GetPrefsVersion @ 000270e8 ====

int _GetPrefsVersion(void)

{
  return (int)(short)(**(ushort **)PTR__gPrefsData_00034280 << 8 |
                     **(ushort **)PTR__gPrefsData_00034280 >> 8);
}


// ==== _GetShortPref @ 000270fc ====

int _GetShortPref(short param_1)

{
  ushort uVar1;
  
  if (99 < (ushort)(param_1 - 1U)) {
    _LocationError(0x7d7,0xd);
  }
  uVar1 = *(ushort *)
           ((int)(short)(param_1 + 0x65 + (param_1 - 1U)) + *(int *)PTR__gPrefsData_00034280);
  return (int)(short)(uVar1 << 8 | uVar1 >> 8);
}


// ==== _GetKeySetPref @ 00027140 ====

void _GetKeySetPref(short param_1,int param_2,ushort *param_3,ushort *param_4,ushort *param_5,
                   ushort *param_6,ushort *param_7)

{
  ushort uVar1;
  ushort *puVar2;
  ushort *puVar3;
  int iVar4;
  
  if (0x13 < (ushort)(param_1 - 1U)) {
    _LocationError(0x7d7,0xf);
  }
  iVar4 = 0;
  puVar2 = (ushort *)
           ((int)(short)((param_1 - 1U) * 0x16 + 0x2be) + *(int *)PTR__gPrefsData_00034280);
  do {
    puVar3 = puVar2;
    *(char *)(iVar4 + param_2) = (char)*puVar3;
    iVar4 = iVar4 + 1;
    puVar2 = (ushort *)((int)puVar3 + 1);
  } while (iVar4 != 0xc);
  uVar1 = *(ushort *)((int)puVar3 + 1);
  *param_3 = uVar1 << 8 | uVar1 >> 8;
  *param_4 = *(ushort *)((int)puVar3 + 3) << 8 | *(ushort *)((int)puVar3 + 3) >> 8;
  *param_5 = *(ushort *)((int)puVar3 + 5) << 8 | *(ushort *)((int)puVar3 + 5) >> 8;
  *param_6 = *(ushort *)((int)puVar3 + 7) << 8 | *(ushort *)((int)puVar3 + 7) >> 8;
  *param_7 = *(ushort *)((int)puVar3 + 9) << 8 | *(ushort *)((int)puVar3 + 9) >> 8;
  return;
}


// ==== _SetLongPref @ 000271e5 ====

void _SetLongPref(short param_1,uint param_2)

{
  if (99 < (ushort)(param_1 - 1U)) {
    _LocationErrorInt(0x7d7,0xe);
  }
  *(uint *)((int)(short)((param_1 - 1U) * 4 + 0x12e) + *(int *)PTR__gPrefsData_00034280) =
       param_2 >> 0x18 | (param_2 & 0xff0000) >> 8 | (param_2 & 0xff00) << 8 | param_2 << 0x18;
  return;
}


// ==== _ZeroPrefs @ 0002722d ====

void _ZeroPrefs(void)

{
  undefined *puVar1;
  int iVar2;
  int iVar3;
  
  _SetPrefsVersion(0x17);
  puVar1 = PTR__gPrefsData_00034280;
  iVar2 = 0;
  do {
    if (99 < (ushort)iVar2) {
      _LocationErrorInt(0x7d7,0xc);
    }
    *(undefined1 *)(iVar2 + 2 + *(int *)puVar1) = 0;
    iVar2 = iVar2 + 1;
  } while (iVar2 != 100);
  iVar2 = 1;
  do {
    _SetShortPref(iVar2,0);
    iVar2 = iVar2 + 1;
  } while (iVar2 != 0x65);
  iVar2 = 1;
  do {
    _SetLongPref(iVar2,0);
    iVar2 = iVar2 + 1;
  } while (iVar2 != 0x65);
  iVar2 = 1;
  iVar3 = 10000;
  do {
    _SetHighScore(iVar2,"Bubble Trouble X",iVar3);
    iVar2 = iVar2 + 1;
    iVar3 = iVar3 + -1000;
  } while (iVar2 != 0xb);
  return;
}


// ==== _InitPrefs @ 000272d6 ====

void _InitPrefs(void)

{
  int iVar1;
  
  iVar1 = _NewPtr(0x800);
  *(int *)PTR__gPrefsData_00034280 = iVar1;
  if (iVar1 == 0) {
    _OutOfMemory("InitPrefs, Prefs.c");
  }
  _ZeroPrefs();
  return;
}


// ==== _LoadGamePrefs @ 00027306 ====

void _LoadGamePrefs(void)

{
  undefined *puVar1;
  short sVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  undefined4 uVar5;
  undefined4 uVar6;
  undefined2 local_36e;
  undefined1 local_36c [510];
  char local_16e [256];
  undefined1 local_6e [80];
  short local_1e [7];
  
  _GetIndString(local_16e,0x81,5);
  if (local_16e[0] == '\0') {
    _ResourceError(0x7d7,2,"STR#",0x81);
  }
  sVar2 = _FSFindFolder(0xffff8005,0x70726566,0,local_6e);
  if (sVar2 != 0) {
    _ResultError(0x7d7,2,(int)sVar2);
  }
  uVar6 = *(undefined4 *)PTR_0003f02c;
  uVar3 = _CFURLCreateFromFSRef(uVar6,local_6e);
  uVar4 = _CFURLCopyFileSystemPath(uVar3,0);
  uVar5 = _CFStringCreateMutableCopy(uVar6,0,uVar4);
  _CFStringAppend(uVar5,&cf__);
  _CFStringAppendPascalString(uVar5,local_16e,0x600);
  _CFRelease(uVar3);
  uVar6 = _CFURLCreateWithFileSystemPath(uVar6,uVar5,0,0);
  _CFURLGetFSRef(uVar6,local_6e);
  _CFRelease(uVar6);
  if (sVar2 != 0) {
    _ResultError(0x7d7,9,(int)sVar2);
  }
  _CFRelease(uVar4);
  _CFRelease(uVar5);
  _FSGetDataForkName(&local_36e);
  sVar2 = _FSOpenFork(local_6e,local_36e,local_36c,0,local_1e);
  if (sVar2 != 0) {
    if (sVar2 == -0x2b) {
      return;
    }
    if (sVar2 == -0x581) {
      return;
    }
    _ResultError(0x7d7,9,(int)sVar2);
  }
  sVar2 = _FSSetForkPosition((int)local_1e[0],1,0,0);
  if (sVar2 != 0) {
    _FSClose((int)local_1e[0]);
    _ResultError(0x7d7,6,(int)sVar2);
  }
  _LoadDefaultHiScores();
  puVar1 = PTR__gPrefsData_00034280;
  sVar2 = _FSReadFork((int)local_1e[0],3,0,0,0x800,*(undefined4 *)PTR__gPrefsData_00034280,0);
  if (sVar2 != 0) {
    _FSClose((int)local_1e[0]);
    _ResultError(0x7d7,10,(int)sVar2);
  }
  sVar2 = _GetPrefsVersion();
  if (sVar2 == 0x17) {
    sVar2 = _FSReadFork((int)local_1e[0],3,0,0,0x8a,PTR__highScores_0003f0a4,0);
    _SwapHighScoresFromBigEndian();
    if (sVar2 != 0) {
      _FSCloseFork((int)local_1e[0]);
      _ResultError(0x7d7,10,(int)sVar2);
    }
    sVar2 = _FSCloseFork((int)local_1e[0]);
    if (sVar2 != 0) {
      _ResultError(0x7d7,8,(int)sVar2);
    }
    if (*(char *)(*(int *)puVar1 + 0x3f) == '\0') {
      *(undefined1 *)(*(int *)puVar1 + 0x3f) = 1;
      _LoadDefaultHiScores();
      _SaveGamePrefs();
    }
  }
  else {
    _FSCloseFork((int)local_1e[0]);
    sVar2 = _FSDeleteObject(local_6e);
    if (sVar2 != 0) {
      _ResultError(0x7d7,0xb,(int)sVar2);
    }
    _ZeroPrefs();
    _AlexPrefsInit();
    _LoadDefaultHiScores();
  }
  return;
}


// ==== _ResetNotices @ 000276d8 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _ResetNotices(void)

{
  _gShowWhichNotice = 0;
  _gLastNoticeShown = 0;
  _gEraseNotice = 0;
  DAT_000381c8 = 0xec;
  _gGetReadyNoticeRect = (short)((*(short *)(PTR__environment_0003f028 + 0x16) + -0x26) / 2);
  _DAT_000381cc = 0x193;
  _DAT_000381ca = _gGetReadyNoticeRect + 0x26;
  DAT_000381d8 = 0x109;
  _gPausedNoticeRect = _gGetReadyNoticeRect;
  _DAT_000381dc = 0x176;
  _DAT_000381da = _DAT_000381ca;
  _gResumeNoticeRect._2_2_ = 0x9b;
  _gResumeNoticeRect._0_2_ = _gGetReadyNoticeRect + 0x3a;
  DAT_000381e2._2_2_ = 0x1e5;
  DAT_000381e2._0_2_ = _gGetReadyNoticeRect + 0x4a;
  _gResumeNotice2Rect._2_2_ = 0xbe;
  _gResumeNotice2Rect._0_2_ = _gGetReadyNoticeRect + 0x4e;
  DAT_000381ea._2_2_ = 0x1c2;
  DAT_000381ea._0_2_ = _gGetReadyNoticeRect + 0x5e;
  DAT_000381d0 = 0x100;
  _gBellyUpNoticeRect = _gGetReadyNoticeRect;
  _DAT_000381d4 = 0x180;
  _DAT_000381d2 = _gGetReadyNoticeRect + 0x40;
  DAT_000381f0 = 0xea;
  _gGameOverNoticeRect = _gGetReadyNoticeRect;
  _DAT_000381f4 = 0x195;
  _DAT_000381f2 = _DAT_000381ca;
  DAT_000381f8 = 0xea;
  _gHurryUpNoticeRect = _gGetReadyNoticeRect;
  _DAT_000381fc = 0x196;
  _DAT_000381fa = _DAT_000381ca;
  _DAT_00038200 = 0xe6;
  _gNotice_Rect_Level = _gGetReadyNoticeRect;
  _DAT_00038204 = 0x19a;
  _DAT_00038202 = _DAT_000381ca;
  return;
}


// ==== _GetCurrentNotice @ 0002781d ====

int _GetCurrentNotice(void)

{
  return (int)_gShowWhichNotice;
}


// ==== _PrepareNotice @ 00027829 ====

void _PrepareNotice(undefined2 param_1)

{
  _gEraseNotice = _gShowWhichNotice != 0;
  _gLastNoticeShown = _gShowWhichNotice;
  _gShowWhichNotice = param_1;
  return;
}


// ==== _EraseNotice @ 0002784e ====

void _EraseNotice(void)

{
  undefined8 uVar1;
  undefined4 *puVar2;
  
  uVar1 = _RT3_GetLicenseCode();
  *(undefined8 *)PTR__gNoticesCode_00034284 = uVar1;
  if (_gEraseNotice != '\0') {
    switch(_gLastNoticeShown) {
    default:
      goto switchD_00027881_caseD_0;
    case 1:
      _AddRectToBgnd(&_gGetReadyNoticeRect);
      puVar2 = (undefined4 *)&_gGetReadyNoticeRect;
      break;
    case 2:
      _AddRectToBgnd(&_gBellyUpNoticeRect);
      puVar2 = (undefined4 *)&_gBellyUpNoticeRect;
      break;
    case 3:
      _AddRectToBgnd(&_gPausedNoticeRect);
      _AddRectToScreen(&_gPausedNoticeRect);
      _AddRectToBgnd(&_gResumeNoticeRect);
      _AddRectToScreen(&_gResumeNoticeRect);
      _AddRectToBgnd(&_gResumeNotice2Rect);
      puVar2 = &_gResumeNotice2Rect;
      break;
    case 4:
      _AddRectToBgnd(&_gGameOverNoticeRect);
      puVar2 = (undefined4 *)&_gGameOverNoticeRect;
      break;
    case 5:
      _AddRectToBgnd(&_gHurryUpNoticeRect);
      puVar2 = (undefined4 *)&_gHurryUpNoticeRect;
      break;
    case 6:
      _AddRectToBgnd(&_gNotice_Rect_Level);
      puVar2 = (undefined4 *)&_gNotice_Rect_Level;
    }
    _AddRectToScreen(puVar2);
    _gEraseNotice = '\0';
  }
switchD_00027881_caseD_0:
  return;
}


// ==== _DrawNotice @ 00027948 ====

void _DrawNotice(void)

{
  short sVar1;
  char cVar2;
  short sVar3;
  undefined4 *puVar4;
  undefined4 uVar5;
  
  switch(_gShowWhichNotice) {
  default:
    goto switchD_00027960_caseD_0;
  case 1:
    _SpriteToComp(0,(int)DAT_000381c8,(int)_gGetReadyNoticeRect,9,1,1);
    _SpriteToComp(0,DAT_000381c8 + 0x40,(int)_gGetReadyNoticeRect,9,2,1);
    _SpriteToComp(0,DAT_000381c8 + 0x80,(int)_gGetReadyNoticeRect,9,3,1);
    puVar4 = (undefined4 *)&_gGetReadyNoticeRect;
    break;
  case 2:
    _SpriteToComp(0,(int)DAT_000381d0,(int)_gBellyUpNoticeRect,0xb,1,1);
    _SpriteToComp(0,DAT_000381d0 + 0x40,(int)_gBellyUpNoticeRect,0xb,2,1);
    puVar4 = (undefined4 *)&_gBellyUpNoticeRect;
    break;
  case 3:
    _SpriteToComp(0,(int)DAT_000381d8,(int)_gPausedNoticeRect,10,1,1);
    _SpriteToComp(0,DAT_000381d8 + 0x40,(int)_gPausedNoticeRect,10,2,1);
    _AddRectToScreen(&_gPausedNoticeRect);
    cVar2 = _IsDoubleBuffered();
    if (cVar2 == '\0') {
      _SetToCompGWorld();
    }
    else {
      _SetToScreen();
    }
    _DrawPictInRect(0x2346,_gResumeNoticeRect,DAT_000381e2);
    _DrawPictInRect(0x2347,_gResumeNotice2Rect,DAT_000381ea);
    _AddRectToScreen(&_gResumeNoticeRect);
    puVar4 = &_gResumeNotice2Rect;
    break;
  case 4:
    _SpriteToComp(0,(int)DAT_000381f0,(int)_gGameOverNoticeRect,0xc,1,1);
    _SpriteToComp(0,DAT_000381f0 + 0x40,(int)_gGameOverNoticeRect,0xc,2,1);
    _SpriteToComp(0,DAT_000381f0 + 0x80,(int)_gGameOverNoticeRect,0xc,3,1);
    puVar4 = (undefined4 *)&_gGameOverNoticeRect;
    break;
  case 5:
    _SpriteToComp(0,(int)DAT_000381f8,(int)_gHurryUpNoticeRect,0xd,1,1);
    _SpriteToComp(0,DAT_000381f8 + 0x40,(int)_gHurryUpNoticeRect,0xd,2,1);
    _SpriteToComp(0,DAT_000381f8 + 0x80,(int)_gHurryUpNoticeRect,0xd,3,1);
    puVar4 = (undefined4 *)&_gHurryUpNoticeRect;
    break;
  case 6:
    sVar3 = _GetCurrLevelNum();
    if (sVar3 < 10) {
      _SpriteToComp(0,0xfe,(int)_gNotice_Rect_Level,0xe,1,1);
      _SpriteToComp(0,0x13e,(int)_gNotice_Rect_Level,0xe,2,1);
      uVar5 = 0x166;
      sVar1 = sVar3;
    }
    else {
      _SpriteToComp(0,0xf1,(int)_gNotice_Rect_Level,0xe,1,1);
      _SpriteToComp(0,0x131,(int)_gNotice_Rect_Level,0xe,2,1);
      sVar1 = sVar3 / 10;
      _SpriteToComp(0,0x174,_gNotice_Rect_Level + 2,0xf,(int)(short)(sVar3 % 10 + 1),1);
      uVar5 = 0x159;
    }
    _SpriteToComp(0,uVar5,_gNotice_Rect_Level + 2,0xf,(int)(short)(sVar1 + 1),1);
    puVar4 = (undefined4 *)&_gNotice_Rect_Level;
  }
  _AddRectToScreen(puVar4);
switchD_00027960_caseD_0:
  return;
}


// ==== _CheckLevelReroute @ 00027ef0 ====

void _CheckLevelReroute(void)

{
  _CheckLevel();
  return;
}


// ==== _OtherLevCheck @ 00027f00 ====

void _OtherLevCheck(int *param_1,short param_2)

{
  int iVar1;
  int *piVar2;
  int iVar3;
  int iVar4;
  short sVar5;
  int iVar6;
  
  piVar2 = (int *)_GetResource(0x5350494e,2);
  if (piVar2 == (int *)0x0) {
    _ResourceError(0x7dc,2,"SPIN",2);
  }
  _MoveHHi(piVar2);
  _HLock(piVar2);
  iVar1 = *(int *)(*piVar2 + -4 + param_2 * 4);
  _ReleaseResource(piVar2);
  iVar3 = _GetHandleSize(param_1);
  iVar6 = 0;
  sVar5 = 0;
  while( true ) {
    iVar4 = (int)sVar5;
    sVar5 = sVar5 + 1;
    if (iVar3 / 2 <= iVar4) break;
    iVar6 = iVar6 + iVar4 * (uint)*(ushort *)(*param_1 + iVar4 * 2);
  }
  if (iVar1 != iVar6) {
    *PTR__gCopyLevelsOkay_00034288 = 0;
  }
  return;
}


// ==== _CopyLevelsOkay @ 00027fb4 ====

undefined1 _CopyLevelsOkay(void)

{
  return *PTR__gCopyLevelsOkay_00034288;
}


// ==== _CopyResetLevelHC @ 00027fc1 ====

void _CopyResetLevelHC(void)

{
  *PTR__gCopyLevelsOkay_00034288 = 1;
  return;
}


// ==== _OtherMazeCheck @ 00027fce ====

void _OtherMazeCheck(int *param_1,short param_2)

{
  int iVar1;
  int *piVar2;
  int iVar3;
  int iVar4;
  short sVar5;
  int iVar6;
  
  piVar2 = (int *)_GetResource(0x5350494e,2);
  if (piVar2 == (int *)0x0) {
    _ResourceError(0x7dc,2,"SPIN",2);
  }
  _MoveHHi(piVar2);
  _HLock(piVar2);
  iVar1 = *(int *)(*piVar2 + 0xc4 + param_2 * 4);
  _ReleaseResource(piVar2);
  iVar3 = _GetHandleSize(param_1);
  iVar6 = 0;
  sVar5 = 0;
  while( true ) {
    iVar4 = (int)sVar5;
    sVar5 = sVar5 + 1;
    if (iVar3 / 2 <= iVar4) break;
    iVar6 = iVar6 + iVar4 * (uint)*(ushort *)(*param_1 + iVar4 * 2);
  }
  if (iVar1 != iVar6) {
    *PTR__gCopyLevelsOkay_00034288 = 0;
  }
  return;
}


// ==== _ResetScore @ 00028085 ====

void _ResetScore(undefined4 param_1)

{
  undefined *puVar1;
  
  _SetScore(param_1);
  *PTR__gScoreHasChanged_00034290 = 1;
  *(undefined4 *)PTR__gNextExtraLifeScore_0003428c = 10000;
  puVar1 = PTR__gScoreRect_00034294;
  *(undefined2 *)(PTR__gScoreRect_00034294 + 2) = 0x84;
  *(undefined2 *)puVar1 = 0x1be;
  *(undefined2 *)(puVar1 + 6) = 0x84;
  *(undefined2 *)(puVar1 + 4) = 0x1dc;
  return;
}


// ==== _Score_Get @ 000280c7 ====

void _Score_Get(void)

{
  _GetScore();
  return;
}


// ==== _RequestDrawScore @ 000280d0 ====

void _RequestDrawScore(void)

{
  *PTR__gScoreHasChanged_00034290 = 1;
  return;
}


// ==== _AddToScore @ 000280dd ====

void _AddToScore(int param_1,char param_2)

{
  undefined *puVar1;
  int iVar2;
  longlong lVar3;
  
  lVar3 = _RT3_GetLicenseCode();
  if ((param_2 != '\0') && (lVar3 != 0x29348de929a84af)) {
    iVar2 = _Multiplier_Get();
    param_1 = iVar2 * param_1;
  }
  _AddScore(param_1);
  *PTR__gScoreHasChanged_00034290 = 1;
  iVar2 = _GetScore();
  puVar1 = PTR__gNextExtraLifeScore_0003428c;
  if (*(int *)PTR__gNextExtraLifeScore_0003428c <= iVar2) {
    _AddHero(1,1);
    if (*(int *)puVar1 < 40000) {
      *(undefined4 *)puVar1 = 40000;
    }
    else {
      *(int *)puVar1 = *(int *)puVar1 + 40000;
    }
  }
  return;
}


// ==== _DrawScore @ 00028168 ====

void _DrawScore(char param_1)

{
  int iVar1;
  undefined *puVar2;
  char cVar3;
  char cVar4;
  int iVar5;
  char local_34 [8];
  undefined4 local_2c;
  undefined4 local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  puVar2 = PTR__gScoreRect_00034294;
  if ((param_1 != '\0') || (*PTR__gScoreHasChanged_00034290 != '\0')) {
    _SetRect(&local_24,0x84,6,(int)*(short *)(PTR__gScoreRect_00034294 + 6),0x24);
    _SetRect(&local_2c,0x84,0x1be,(int)*(short *)(puVar2 + 6),0x1dc);
    _SetToCompGWorld();
    _ScoreToComp(local_24,local_20,local_2c,local_28);
    iVar5 = _GetScore();
    puVar2 = PTR__gScoreRect_00034294;
    local_34[0] = '\0';
    local_34[1] = 0;
    local_34[2] = 0;
    local_34[3] = 0;
    local_34[4] = 0;
    local_34[7] = 0xff;
    local_34[6] = 0xff;
    local_34[5] = 0xff;
    cVar4 = '\0';
    do {
      iVar1 = iVar5 / 10;
      local_34[cVar4] = (char)iVar5 + (char)iVar1 * -10;
      cVar3 = cVar4 + '\x01';
      if ('\b' < (char)(cVar4 + '\x01')) {
        cVar3 = cVar4;
      }
      cVar4 = cVar3;
      iVar5 = iVar1;
    } while (iVar1 != 0);
    *(undefined2 *)(PTR__gScoreRect_00034294 + 2) = 0x84;
    *(undefined2 *)puVar2 = 0x1be;
    *(undefined2 *)(puVar2 + 6) = 0x84;
    *(undefined2 *)(puVar2 + 4) = 0x1dc;
    iVar5 = 0;
    do {
      if (local_34[iVar5 + 7] != -1) {
        _SpriteToComp(0,(int)*(short *)(puVar2 + 6),0x1be,0x21,(int)(short)(local_34[iVar5 + 7] + 1)
                      ,0);
        *(short *)(puVar2 + 6) = *(short *)(puVar2 + 6) + 0x18;
      }
      iVar5 = iVar5 + -1;
    } while (iVar5 != -8);
    local_2c = *(undefined4 *)puVar2;
    local_28 = *(undefined4 *)(puVar2 + 4);
    if (PTR__environment_0003f028[8] != '\0') {
      _OffsetRect(&local_2c,(int)*(short *)(PTR__environment_0003f028 + 0x1a),
                  (int)*(short *)(PTR__environment_0003f028 + 0x1c));
    }
    cVar4 = _UsingQDPlotting();
    if (cVar4 == '\0') {
      _CustomCompToScreen(*(undefined4 *)puVar2,*(undefined4 *)(puVar2 + 4),local_2c,local_28);
    }
    else {
      _CompToScreen(*(undefined4 *)puVar2,*(undefined4 *)(puVar2 + 4),local_2c,local_28);
    }
    _SetToScreen();
    *PTR__gScoreHasChanged_00034290 = 0;
  }
  return;
}


// ==== _BTInstallEndianFlippers @ 00028366 ====

void _BTInstallEndianFlippers(void)

{
  int iVar1;
  
  iVar1 = _CoreEndianInstallFlipper(0x72737263,0x5370494c,_FlipSpIL,0);
  if (iVar1 == 0) {
    iVar1 = _CoreEndianInstallFlipper(0x72737263,0x53704963,_FlipSpIc,0);
    if (iVar1 == 0) {
      iVar1 = _CoreEndianInstallFlipper(0x72737263,0x4c45564c,_FlipLEVL,0);
      if (iVar1 == 0) {
        iVar1 = _CoreEndianInstallFlipper(0x72737263,0x52656374,_FlipRect,0);
        if (iVar1 == 0) {
          _CoreEndianInstallFlipper(0x72737263,0x46494c4d,_FlipFILM,0);
        }
      }
    }
  }
  return;
}


// ==== _FlipRect @ 00028436 ====

bool _FlipRect(void)

{
  uint uVar1;
  bool bVar2;
  ushort *in_stack_00000010;
  int in_stack_00000014;
  
  bVar2 = in_stack_00000014 != 8;
  if (!bVar2) {
    for (uVar1 = 0; uVar1 < 4; uVar1 = uVar1 + 1) {
      *in_stack_00000010 = *in_stack_00000010 << 8 | *in_stack_00000010 >> 8;
      in_stack_00000010 = in_stack_00000010 + 1;
    }
    bVar2 = false;
  }
  return bVar2;
}


// ==== _FlipSpIL @ 00028465 ====

uint _FlipSpIL(void)

{
  uint uVar1;
  ushort *in_stack_00000010;
  uint in_stack_00000014;
  
  uVar1 = in_stack_00000014 & 1;
  if (uVar1 == 0) {
    for (uVar1 = 0; uVar1 < in_stack_00000014 >> 1; uVar1 = uVar1 + 1) {
      *in_stack_00000010 = *in_stack_00000010 << 8 | *in_stack_00000010 >> 8;
      in_stack_00000010 = in_stack_00000010 + 1;
    }
    uVar1 = 0;
  }
  return uVar1;
}


// ==== _FlipSpIc @ 0002848f ====

uint _FlipSpIc(void)

{
  uint uVar1;
  ushort *in_stack_00000010;
  uint in_stack_00000014;
  
  uVar1 = in_stack_00000014 & 1;
  if (uVar1 == 0) {
    for (uVar1 = 0; uVar1 < in_stack_00000014 >> 1; uVar1 = uVar1 + 1) {
      *in_stack_00000010 = *in_stack_00000010 << 8 | *in_stack_00000010 >> 8;
      in_stack_00000010 = in_stack_00000010 + 1;
    }
    uVar1 = 0;
  }
  return uVar1;
}


// ==== _FlipLEVL @ 000284b9 ====

uint _FlipLEVL(void)

{
  uint uVar1;
  ushort *in_stack_00000010;
  uint in_stack_00000014;
  
  uVar1 = in_stack_00000014 & 1;
  if (uVar1 == 0) {
    for (uVar1 = 0; uVar1 < in_stack_00000014 >> 1; uVar1 = uVar1 + 1) {
      *in_stack_00000010 = *in_stack_00000010 << 8 | *in_stack_00000010 >> 8;
      in_stack_00000010 = in_stack_00000010 + 1;
    }
    uVar1 = 0;
  }
  return uVar1;
}


// ==== _FlipFILM @ 000284e3 ====

bool _FlipFILM(void)

{
  uint uVar1;
  uint *in_stack_00000010;
  int in_stack_00000014;
  
  if (in_stack_00000014 == 0x271c) {
    uVar1 = *in_stack_00000010;
    *in_stack_00000010 =
         uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
    uVar1 = in_stack_00000010[1];
    in_stack_00000010[1] =
         uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
    uVar1 = in_stack_00000010[2];
    in_stack_00000010[2] =
         uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
  }
  return in_stack_00000014 != 0x271c;
}


// ==== __RT3_LicenseSwap @ 00028513 ====

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


// ==== __RT3_LogInfoSwap @ 0002863f ====

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


// ==== __RT3_CalcLoginHash @ 00028963 ====

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


// ==== __RT3_RemoveFSEventCallback @ 000289a8 ====

void __RT3_RemoveFSEventCallback(void)

{
  int unaff_EBX;
  
  ___i686_get_pc_thunk_bx();
  if (*(int *)(unaff_EBX + 0xf878) != 0) {
    (**(code **)(unaff_EBX + 0xf874))(*(int *)(unaff_EBX + 0xf878));
    (**(code **)(unaff_EBX + 0xf870))(*(undefined4 *)(unaff_EBX + 0xf878));
    (**(code **)(unaff_EBX + 0xf86c))(*(undefined4 *)(unaff_EBX + 0xf878));
    *(undefined4 *)(unaff_EBX + 0xf878) = 0;
  }
  return;
}


// ==== __RT3_InstallFSEventCallback @ 000289f5 ====

/* WARNING: Type propagation algorithm not settling */

int __RT3_InstallFSEventCallback(void)

{
  code *pcVar1;
  undefined4 uVar2;
  short sVar3;
  int iVar4;
  undefined4 uVar5;
  int unaff_EBX;
  int iVar6;
  int local_480;
  undefined1 local_474 [1024];
  undefined1 local_74 [76];
  int aiStack_28 [6];
  
  ___i686_get_pc_thunk_bx();
  aiStack_28[1] = unaff_EBX + 0xbb4a;
  aiStack_28[2] = aiStack_28[1];
  if (*(int *)(unaff_EBX + 0xf836) == 0) {
    iVar4 = _SystemLoadMachOSymbol(unaff_EBX + 0xbb6a,unaff_EBX + 0xbb5a);
    *(int *)(unaff_EBX + 0xf836) = iVar4;
    if (iVar4 != 0) goto LAB_00028a42;
LAB_00028cfa:
    iVar4 = -0x1b5b;
LAB_00028cff:
    local_480 = 0;
    goto LAB_00028d33;
  }
LAB_00028a42:
  if (*(int *)(unaff_EBX + 0xf832) == 0) {
    iVar4 = _SystemLoadMachOSymbol(unaff_EBX + 0xbb6a,unaff_EBX + 0xbb7a);
    *(int *)(unaff_EBX + 0xf832) = iVar4;
    if (iVar4 == 0) goto LAB_00028cfa;
  }
  if (*(int *)(unaff_EBX + 0xf82e) == 0) {
    iVar4 = _SystemLoadMachOSymbol(unaff_EBX + 0xbb6a,unaff_EBX + 0xbb8a);
    *(int *)(unaff_EBX + 0xf82e) = iVar4;
    if (iVar4 == 0) goto LAB_00028cfa;
  }
  if (*(int *)(unaff_EBX + 0xf822) == 0) {
    iVar4 = _SystemLoadMachOSymbol(unaff_EBX + 0xbb6a,unaff_EBX + 0xbb9a);
    *(int *)(unaff_EBX + 0xf822) = iVar4;
    if (iVar4 == 0) goto LAB_00028cfa;
  }
  if (*(int *)(unaff_EBX + 0xf81e) == 0) {
    iVar4 = _SystemLoadMachOSymbol(unaff_EBX + 0xbb6a,unaff_EBX + 0xbbaa);
    *(int *)(unaff_EBX + 0xf81e) = iVar4;
    if (iVar4 == 0) goto LAB_00028cfa;
  }
  if (*(int *)(unaff_EBX + 0xf81a) == 0) {
    iVar4 = _SystemLoadMachOSymbol(unaff_EBX + 0xbb6a,unaff_EBX + 0xbbba);
    *(int *)(unaff_EBX + 0xf81a) = iVar4;
    if (iVar4 == 0) goto LAB_00028cfa;
  }
  if (*(int *)(unaff_EBX + 0xf82a) == 0) {
    iVar4 = _SystemCreateMachOWrapper(unaff_EBX + 0x2fa1);
    *(int *)(unaff_EBX + 0xf82a) = iVar4;
    if (iVar4 != 0) goto LAB_00028b58;
LAB_00028d14:
    iVar4 = -0x1b5c;
  }
  else {
LAB_00028b58:
    sVar3 = _FSFindFolder(0xffff8005,0x70726566,0,local_74);
    if (sVar3 == 0) {
      iVar4 = _FSRefMakePath(local_74,local_474,0x400);
      if (iVar4 != 0) goto LAB_00028cff;
      aiStack_28[1] = _CFStringCreateWithCString(0,local_474,0x8000100);
      if (aiStack_28[1] != 0) {
        sVar3 = _FSFindFolder(0xffff8003,0x70726566,0,local_74);
        if (sVar3 != 0) goto LAB_00028bec;
        iVar4 = _FSRefMakePath(local_74,local_474,0x400);
        if (iVar4 != 0) goto LAB_00028cff;
        aiStack_28[2] = _CFStringCreateWithCString(0,local_474,0x8000100);
        if (aiStack_28[2] != 0) {
          local_480 = _CFArrayCreate(0,aiStack_28 + 1,2,0);
          if (local_480 != 0) {
            iVar4 = (**(code **)(unaff_EBX + 0xf836))
                              (0,*(undefined4 *)(unaff_EBX + 0xf82a),0,local_480,0xffffffff,
                               0xffffffff,0,0x40000000,0);
            *(int *)(unaff_EBX + 0xf826) = iVar4;
            if (iVar4 != 0) {
              pcVar1 = *(code **)(unaff_EBX + 0xf832);
              uVar2 = **(undefined4 **)(unaff_EBX + 0x166ee);
              uVar5 = _CFRunLoopGetCurrent();
              (*pcVar1)(*(undefined4 *)(unaff_EBX + 0xf826),uVar5,uVar2);
              (**(code **)(unaff_EBX + 0xf82e))(*(undefined4 *)(unaff_EBX + 0xf826));
              iVar4 = 0;
              goto LAB_00028d33;
            }
          }
          iVar4 = -0x1b5c;
          goto LAB_00028d33;
        }
      }
      goto LAB_00028d14;
    }
LAB_00028bec:
    iVar4 = (int)sVar3;
  }
  local_480 = 0;
LAB_00028d33:
  iVar6 = 1;
  do {
    if (aiStack_28[iVar6] != 0) {
      _CFRelease(aiStack_28[iVar6]);
    }
    iVar6 = iVar6 + 1;
  } while (iVar6 != 3);
  if (local_480 != 0) {
    _CFRelease(local_480);
  }
  if (iVar4 != 0) {
    __RT3_RemoveFSEventCallback();
  }
  return iVar4;
}


// ==== _RT3_GetLicenseCopies @ 00028d84 ====

int _RT3_GetLicenseCopies(void)

{
  int iVar1;
  int iVar2;
  int extraout_ECX;
  
  ___i686_get_pc_thunk_cx();
  iVar1 = *(int *)(*(int *)(extraout_ECX + 0x16354) + 0x200);
  iVar2 = 0;
  if (0 < iVar1) {
    iVar2 = iVar1;
  }
  return iVar2;
}


// ==== _RT3_IsOpen @ 00028da1 ====

undefined1 _RT3_IsOpen(void)

{
  int extraout_ECX;
  
  ___i686_get_pc_thunk_cx();
  return *(undefined1 *)(extraout_ECX + 0xb587);
}


// ==== _RT3_GetDisplayName @ 00028db2 ====

char * _RT3_GetDisplayName(void)

{
  char *pcVar1;
  int extraout_ECX;
  
  ___i686_get_pc_thunk_cx();
  pcVar1 = *(char **)(extraout_ECX + 0x16326);
  if (*pcVar1 == '\0') {
    pcVar1 = *(char **)(extraout_ECX + 0x16346);
  }
  return pcVar1;
}


// ==== _RT3_GetDisplayCode @ 00028dcd ====

int _RT3_GetDisplayCode(void)

{
  int iVar1;
  int extraout_ECX;
  
  ___i686_get_pc_thunk_cx();
  if (*(char *)(*(int *)(extraout_ECX + 0x1630b) + 0x100) == '\0') {
    iVar1 = *(int *)(extraout_ECX + 0x162ef);
  }
  else {
    iVar1 = *(int *)(extraout_ECX + 0x1630b) + 0x100;
  }
  return iVar1;
}


// ==== _RT3_GetDisplayCopies @ 00028df3 ====

void _RT3_GetDisplayCopies(void)

{
  int iVar1;
  int unaff_EBX;
  
  ___i686_get_pc_thunk_bx();
  iVar1 = *(int *)(*(int *)(unaff_EBX + 0x162e1) + 0x200);
  if (iVar1 < 1) {
    _StringCopy(*(undefined4 *)(unaff_EBX + 0x162e9),*(undefined4 *)(unaff_EBX + 0x162ad));
  }
  else {
    _StringFromNumber(*(undefined4 *)(unaff_EBX + 0x162e9),iVar1);
  }
  return;
}


// ==== _RT3_GetLicenseCode @ 00028e41 ====

undefined8 _RT3_GetLicenseCode(void)

{
  uint uVar1;
  int unaff_EBX;
  uint local_24;
  uint local_20;
  
  ___i686_get_pc_thunk_bx();
  local_24 = 0;
  local_20 = 0;
  if (*(char *)(*(int *)(unaff_EBX + 0x16291) + 0x100) == '\0') {
    local_24 = 0;
    local_20 = 0;
  }
  else {
    _RT3_LicenseTextToCode(*(int *)(unaff_EBX + 0x16291) + 0x100,&local_24);
    uVar1 = _TimerGetMicroseconds();
    local_24 = local_24 ^ **(uint **)(unaff_EBX + 0x16281);
    local_20 = local_20 ^ (*(uint **)(unaff_EBX + 0x16281))[1] |
               *(int *)(unaff_EBX + 0xb4f1 + (uVar1 & 7) * 8) << 0x1c;
  }
  return CONCAT44(local_20,local_24);
}


// ==== _RT3_GetLicenseName @ 00028ee7 ====

undefined4 _RT3_GetLicenseName(void)

{
  int extraout_ECX;
  
  ___i686_get_pc_thunk_cx();
  return *(undefined4 *)(extraout_ECX + 0x161d1);
}


// ==== _RT3_IsRegistered @ 00028ef7 ====

int _RT3_IsRegistered(void)

{
  int iVar1;
  int extraout_EDX;
  
  ___i686_get_pc_thunk_dx();
  if (*(int *)(*(int *)(extraout_EDX + 0x161e1) + 0x200) < 1) {
    iVar1 = 0;
  }
  else {
    iVar1 = 1 << ((byte)*(undefined4 *)(*(int *)(extraout_EDX + 0x161e1) + 0x208) & 0x1f);
  }
  return iVar1;
}


// ==== _RT3_IsRetailLicense @ 00028f22 ====

bool _RT3_IsRetailLicense(void)

{
  int unaff_EBX;
  char local_10c [260];
  
  ___i686_get_pc_thunk_bx();
  _RT3_FixLicenseName(local_10c,*(undefined4 *)(unaff_EBX + 0x161af));
  return (byte)(local_10c[0] - 0x30U) < 10;
}


// ==== _RT3_IsSystemLicense @ 00028f63 ====

undefined1 _RT3_IsSystemLicense(void)

{
  int extraout_ECX;
  
  ___i686_get_pc_thunk_cx();
  return **(undefined1 **)(extraout_ECX + 0x1615d);
}


// ==== _RT3_CanSetSystemLicense @ 00028f76 ====

bool _RT3_CanSetSystemLicense(void)

{
  char cVar1;
  
  cVar1 = _SystemMacOSXOrLater();
  return cVar1 != '\0';
}


// ==== _RT3_GetDaysHad @ 00028f8b ====

int _RT3_GetDaysHad(void)

{
  uint uVar1;
  uint uVar2;
  undefined4 uVar3;
  int iVar4;
  int unaff_EBX;
  
  ___i686_get_pc_thunk_bx();
  uVar2 = _TimerGetUTCSeconds();
  uVar3 = 0;
  if (1000 < *(uint *)(unaff_EBX + 0xb371)) {
    uVar3 = *(undefined4 *)(unaff_EBX + 0xb371);
  }
  *(undefined4 *)(unaff_EBX + 0xb371) = uVar3;
  uVar1 = *(uint *)(*(int *)(unaff_EBX + 0x16145) + 0x100);
  if (uVar2 < uVar1) {
    iVar4 = 0x5a;
  }
  else {
    iVar4 = (uVar2 - uVar1) / 0x15180 + 1;
  }
  return iVar4;
}


// ==== _RT3_GetHoursUsed @ 00028fe5 ====

uint _RT3_GetHoursUsed(void)

{
  int iVar1;
  uint uVar2;
  int unaff_EBX;
  
  ___i686_get_pc_thunk_bx();
  iVar1 = _TimerGetElapsedSeconds();
  if (*(int *)(unaff_EBX + 0xb327) == 0) {
    uVar2 = (uint)((ulonglong)*(uint *)(*(int *)(unaff_EBX + 0x160eb) + 0x104) * 0x91a2b3c5 >> 0x20)
    ;
  }
  else {
    uVar2 = (uint)((ulonglong)
                   (uint)((iVar1 + *(int *)(*(int *)(unaff_EBX + 0x160eb) + 0x104)) -
                         *(int *)(unaff_EBX + 0xb327)) * 0x91a2b3c5 >> 0x20);
  }
  return uVar2 >> 0xb;
}


// ==== _RT3_GetNumLaunches @ 00029035 ====

undefined4 _RT3_GetNumLaunches(void)

{
  int extraout_ECX;
  
  ___i686_get_pc_thunk_cx();
  return *(undefined4 *)(*(int *)(extraout_ECX + 0x1609f) + 0x108);
}


// ==== __RT3_IdleNetworkClock @ 0002904b ====

void __RT3_IdleNetworkClock(void)

{
  int *piVar1;
  byte *pbVar2;
  byte bVar3;
  int iVar4;
  bool bVar5;
  int iVar6;
  uint uVar7;
  undefined4 uVar8;
  int *piVar9;
  int unaff_EBX;
  bool bVar10;
  byte local_11c [268];
  
  ___i686_get_pc_thunk_bx();
  if (*(int *)(unaff_EBX + 0xb29c) != 0) {
    return;
  }
  piVar9 = *(int **)(unaff_EBX + 0x1609c);
  piVar1 = piVar9 + 8;
  do {
    if (piVar9[1] != 0 || *piVar9 != 0) {
      bVar5 = true;
      goto LAB_00029091;
    }
    piVar9 = piVar9 + 2;
  } while (piVar9 != piVar1);
  bVar5 = false;
LAB_00029091:
  bVar10 = *(int *)(unaff_EBX + 0xb2a4) == 0;
  iVar6 = _TimerGetTicks();
  iVar4 = *(int *)(unaff_EBX + 0xb2a4);
  uVar7 = _TimerGetTickRate();
  if ((uint)(iVar6 - iVar4) < uVar7) {
    if (bVar10) goto LAB_000290c1;
  }
  else {
    bVar10 = true;
LAB_000290c1:
    if (*(int *)(unaff_EBX + 0xb2a0) == 4) goto LAB_000290d3;
  }
  if (!bVar5) {
    if (!bVar10) {
      return;
    }
    iVar4 = *(int *)(unaff_EBX + 0xb2a0);
    iVar6 = *(int *)(unaff_EBX + 0xb244 + iVar4 * 4);
    uVar7 = 0;
    do {
      bVar3 = *(byte *)(iVar6 + uVar7);
      pbVar2 = local_11c + uVar7;
      *pbVar2 = bVar3;
      if (bVar3 == 0) break;
      *pbVar2 = (-((uVar7 & 1) == 0) & 0x1cU) + 0xa9 ^ bVar3;
      uVar7 = uVar7 + 1;
    } while (uVar7 != 0x100);
    _ClockQueryServer(local_11c,0,0,0,*(int *)(unaff_EBX + 0x1609c) + iVar4 * 8,0);
    uVar8 = _TimerGetTicks();
    *(undefined4 *)(unaff_EBX + 0xb2a4) = uVar8;
    *(int *)(unaff_EBX + 0xb2a0) = *(int *)(unaff_EBX + 0xb2a0) + 1;
    return;
  }
LAB_000290d3:
  _ClockQueryDispose();
  uVar8 = _TimerGetElapsedSeconds();
  *(undefined4 *)(unaff_EBX + 0xb29c) = uVar8;
  return;
}


// ==== _RT3_BeginNetworkClock @ 000291a3 ====

undefined4 _RT3_BeginNetworkClock(void)

{
  char cVar1;
  undefined4 uVar2;
  int unaff_EBX;
  
  ___i686_get_pc_thunk_bx();
  if (*(char *)(unaff_EBX + 0xb181) == '\0') {
    uVar2 = 0xffffe4a6;
  }
  else {
    cVar1 = _NetworkStackGetActive(0);
    if (cVar1 != '\0') {
      _SystemSetIdleProc(unaff_EBX + -0x164);
      __RT3_IdleNetworkClock();
    }
    uVar2 = 0;
  }
  return uVar2;
}


// ==== _RT3_GetNetworkClock @ 000291ea ====

int _RT3_GetNetworkClock(void)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int *piVar4;
  int unaff_EBX;
  int iVar5;
  
  ___i686_get_pc_thunk_bx();
  if (*(char *)(unaff_EBX + 0xb138) != '\0') {
    iVar5 = 0;
    piVar4 = *(int **)(unaff_EBX + 0x15f00);
    do {
      if (piVar4[1] != 0 || *piVar4 != 0) {
        iVar2 = _TimerGetElapsedSeconds();
        iVar1 = *(int *)(unaff_EBX + 0xb100);
        iVar3 = _TimerGetUTCOffset(0);
        return ((iVar2 - iVar1) - iVar3) +
               *(int *)(*(int *)(unaff_EBX + 0x15f00) + 4 + iVar5 * 8) + 0x7c558180;
      }
      iVar5 = iVar5 + 1;
      piVar4 = piVar4 + 2;
    } while (iVar5 != 4);
    if (*(int *)(unaff_EBX + 0xb100) != 0) {
      iVar5 = _TimerGetLocalSeconds();
      return iVar5;
    }
  }
  return 0;
}


// ==== _RT3_CheckLicenseName @ 0002926c ====

char * _RT3_CheckLicenseName(int param_1)

{
  char *pcVar1;
  int unaff_EBX;
  
  ___i686_get_pc_thunk_bx();
  if (param_1 != 0) {
    _RT3_FixLicenseName(unaff_EBX + 0xefc7,param_1);
  }
  pcVar1 = (char *)0x0;
  if (*(char *)(unaff_EBX + 0xefc7) != '\0') {
    pcVar1 = (char *)(unaff_EBX + 0xefc7);
  }
  return pcVar1;
}


// ==== _RT3_CheckLicenseCode @ 000292ad ====

undefined8 _RT3_CheckLicenseCode(byte *param_1)

{
  byte *pbVar1;
  int unaff_EBX;
  int iVar2;
  undefined4 local_24;
  undefined4 local_20;
  
  ___i686_get_pc_thunk_bx();
  local_24 = 0;
  local_20 = 0;
  iVar2 = 0;
  for (pbVar1 = param_1; *pbVar1 != 0; pbVar1 = pbVar1 + 1) {
    if (*(char *)(*(int *)(unaff_EBX + 0x15df5) + (uint)*pbVar1) != -1) {
      iVar2 = iVar2 + 1;
    }
  }
  if (iVar2 == 0xc) {
    _RT3_LicenseTextToCode(param_1,&local_24);
  }
  return CONCAT44(local_20,local_24);
}


// ==== __RT3_LoadCFPrefs @ 00029312 ====

uint __RT3_LoadCFPrefs(void)

{
  char cVar1;
  int *piVar2;
  int iVar3;
  undefined4 uVar4;
  undefined4 uVar5;
  uint uVar6;
  int extraout_ECX;
  int unaff_EBX;
  undefined8 uVar7;
  undefined4 local_20 [4];
  
  uVar7 = ___i686_get_pc_thunk_bx();
  iVar3 = (int)((ulonglong)uVar7 >> 0x20);
  piVar2 = (int *)uVar7;
  local_20[0] = 0;
  if (((piVar2 == (int *)0x0) || (iVar3 == 0)) || (extraout_ECX == 0)) {
    uVar6 = 0xffffe4a7;
  }
  else {
    *piVar2 = 0;
    iVar3 = _CFPreferencesCopyValue
                      (iVar3,**(undefined4 **)(unaff_EBX + 0x15db8),
                       **(undefined4 **)(unaff_EBX + 0x15ddc),
                       **(undefined4 **)(_RestoreBgnd + unaff_EBX + 6));
    if (((iVar3 != 0) &&
        (cVar1 = _CFDictionaryGetValueIfPresent(iVar3,extraout_ECX,local_20), cVar1 != '\0')) &&
       ((iVar3 = _CFDataGetBytePtr(local_20[0]), iVar3 != 0 &&
        (iVar3 = _CFDataGetLength(local_20[0]), iVar3 != 0)))) {
      uVar4 = _CFDataGetLength(local_20[0]);
      uVar5 = _CFDataGetBytePtr(local_20[0]);
      iVar3 = _IndirectInitialize(uVar5,uVar4);
      *piVar2 = iVar3;
      return -(uint)(iVar3 == 0) & 0xffffe4a4;
    }
    uVar6 = 0xffffe3dd;
  }
  return uVar6;
}


// ==== __RT3_CalcHashedStamp @ 000293f6 ====

uint __RT3_CalcHashedStamp(void)

{
  uint uVar1;
  uint uVar2;
  int unaff_EBX;
  byte *pbVar3;
  
  ___i686_get_pc_thunk_bx();
  uVar1 = _TimerGetUTCSeconds();
  uVar2 = 0;
  for (pbVar3 = *(byte **)(unaff_EBX + 0x15cd0); *pbVar3 != 0; pbVar3 = pbVar3 + 1) {
    uVar2 = uVar2 >> 0x1d ^ uVar2 * 4 ^ (uint)*pbVar3;
  }
  uVar1 = uVar1 ^ uVar2;
  if (uVar1 == 0) {
    uVar1 = 1;
  }
  return uVar1;
}


// ==== __RT3_CalcIdentifier @ 00029444 ====

uint __RT3_CalcIdentifier(void)

{
  int iVar1;
  byte *pbVar2;
  int unaff_EBX;
  uint uVar3;
  undefined1 local_138 [268];
  uint local_2c;
  
  iVar1 = ___i686_get_pc_thunk_bx();
  uVar3 = 0;
  for (pbVar2 = *(byte **)(unaff_EBX + 0x15c7f); *pbVar2 != 0; pbVar2 = pbVar2 + 1) {
    uVar3 = uVar3 >> 0x1d ^ uVar3 * 4 ^ (uint)*pbVar2;
  }
  if (iVar1 != 0) {
    iVar1 = _FT_FileGetFlags(iVar1,0,local_138,0);
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


// ==== _RT3_RenewLicenseCode @ 000294c0 ====

int _RT3_RenewLicenseCode(int param_1,byte *param_2,int param_3,char *param_4,undefined1 *param_5)

{
  int iVar1;
  int iVar2;
  int unaff_EBX;
  byte *pbVar3;
  undefined1 local_42c;
  undefined1 local_42b [255];
  undefined1 local_32c;
  undefined1 local_32b [255];
  undefined1 local_22c;
  undefined1 local_22b [255];
  char local_12c;
  undefined1 local_12b [255];
  int local_2c;
  int local_28;
  undefined4 local_24;
  undefined4 local_20;
  
  ___i686_get_pc_thunk_bx();
  local_12c = *(char *)(unaff_EBX + 0x61d3);
  _memset(local_12b,0,0xff);
  local_22c = *(undefined1 *)(unaff_EBX + 0x61d3);
  _memset(local_22b,0,0xff);
  local_32c = *(undefined1 *)(unaff_EBX + 0x61d3);
  _memset(local_32b,0,0xff);
  local_42c = *(undefined1 *)(unaff_EBX + 0x61d3);
  _memset(local_42b,0,0xff);
  if (*(char *)(unaff_EBX + 0xae5f) == '\0') {
    iVar1 = -0x1b5a;
  }
  else {
    *param_4 = '\0';
    *param_5 = 0;
    if (param_1 != 0) {
      _RT3_FixLicenseName(unaff_EBX + 0xed6f,param_1);
    }
    if (*(char *)(unaff_EBX + 0xed6f) != '\0') {
      local_2c = 0;
      local_28 = 0;
      iVar1 = 0;
      for (pbVar3 = param_2; *pbVar3 != 0; pbVar3 = pbVar3 + 1) {
        if (*(char *)(*(int *)(unaff_EBX + 0x15bdf) + (uint)*pbVar3) != -1) {
          iVar1 = iVar1 + 1;
        }
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
          iVar2 = _RenewLicenseTCP(unaff_EBX + 0x9a1f,&local_42c,
                                   *(undefined4 *)(unaff_EBX + 0x15c03),param_1,&local_32c,param_2,
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


// ==== __RT3_WriteLogEntry @ 0002971a ====

int __RT3_WriteLogEntry(void)

{
  undefined4 uVar1;
  undefined4 uVar2;
  int *piVar3;
  char cVar4;
  void *pvVar5;
  int iVar6;
  uint uVar7;
  undefined4 uVar8;
  int iVar9;
  byte bVar10;
  byte *pbVar11;
  int unaff_EBX;
  uint uVar12;
  int local_344;
  int local_340;
  undefined1 local_33c [256];
  undefined1 local_23c;
  undefined1 local_23b;
  char local_239;
  undefined1 local_220 [256];
  byte local_120 [256];
  int *local_20 [4];
  
  pvVar5 = (void *)___i686_get_pc_thunk_bx();
  _memcpy(local_120,(void *)(unaff_EBX + 0xa5b5),0x100);
  local_20[0] = (int *)0x0;
  uVar7 = *(uint *)((int)pvVar5 + 0xf0);
  uVar12 = *(uint *)((int)pvVar5 + 0xf4);
  *(uint *)((int)pvVar5 + 0xf0) =
       uVar12 >> 0x18 | uVar12 >> 8 & 0xff00 | (uVar12 & 0xff00) << 8 | uVar12 << 0x18;
  *(uint *)((int)pvVar5 + 0xf4) =
       uVar7 >> 0x18 | (uVar7 & 0xff0000) >> 8 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)pvVar5 + 0xf8);
  uVar12 = *(uint *)((int)pvVar5 + 0xfc);
  *(uint *)((int)pvVar5 + 0xf8) =
       uVar12 >> 0x18 | uVar12 >> 8 & 0xff00 | (uVar12 & 0xff00) << 8 | uVar12 << 0x18;
  *(uint *)((int)pvVar5 + 0xfc) =
       uVar7 >> 0x18 | (uVar7 & 0xff0000) >> 8 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)pvVar5 + 0x100);
  *(uint *)((int)pvVar5 + 0x100) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)pvVar5 + 0x104);
  *(uint *)((int)pvVar5 + 0x104) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)pvVar5 + 0x108);
  *(uint *)((int)pvVar5 + 0x108) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)pvVar5 + 0x10c);
  *(uint *)((int)pvVar5 + 0x10c) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)pvVar5 + 0x110);
  *(uint *)((int)pvVar5 + 0x110) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)pvVar5 + 0x114);
  *(uint *)((int)pvVar5 + 0x114) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)pvVar5 + 0x118);
  *(uint *)((int)pvVar5 + 0x118) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  bVar10 = 0x7a;
  pbVar11 = local_120;
  while( true ) {
    if (*pbVar11 == 0) break;
    *pbVar11 = *pbVar11 ^ bVar10;
    bVar10 = bVar10 - 3;
    pbVar11 = pbVar11 + 1;
  }
  iVar6 = _FT_FileLoad(0xfffffffd,local_120,"t Blashpemy",0,local_20);
  if (((iVar6 != 0) && (iVar6 == -0x1c23)) || (uVar7 = _IndirectGetSize(local_20[0]), uVar7 < 8)) {
    if (local_20[0] != (int *)0x0) {
      _IndirectDeallocate(local_20[0]);
      local_20[0] = (int *)0x0;
    }
    iVar6 = __RT3_LoadCFPrefs();
  }
  if (iVar6 == 0) {
    local_340 = _IndirectDecompress(local_20[0],0x7a6c6962,0);
    if (local_340 != 0) {
      if (local_340 != -0x1b5a) goto LAB_00029e85;
      goto LAB_00029baa;
    }
    uVar7 = _IndirectGetSize(local_20[0]);
    local_344 = 0;
    for (uVar12 = 0; uVar12 < uVar7 / 0x11c; uVar12 = uVar12 + 1) {
      _StringCopySafe(local_220,*local_20[0] + local_344,0x100);
      iVar6 = _StringCompare(*(undefined4 *)(unaff_EBX + 0x159a9),local_220);
      local_344 = local_344 + 0x11c;
      if (iVar6 == 0) break;
    }
    if (uVar12 == uVar7 / 0x11c) {
      local_340 = _IndirectAppendData(local_20[0],pvVar5,0x11c);
      if (local_340 != 0) goto LAB_00029e85;
    }
    else {
      _memcpy((void *)(uVar12 * 0x11c + *local_20[0]),pvVar5,0x11c);
    }
  }
  else {
LAB_00029baa:
    local_20[0] = (int *)_IndirectInitialize(pvVar5,0x11c);
    if (local_20[0] == (int *)0x0) {
      local_340 = -0x1b5c;
      goto LAB_00029e85;
    }
  }
  local_340 = _IndirectCompress(local_20[0],0x7a6c6962,0);
  piVar3 = local_20[0];
  if (local_340 == 0) {
    if (local_20[0] != (int *)0x0) {
      cVar4 = _IndirectSetLock(local_20[0],1);
      uVar8 = _IndirectGetSize(piVar3);
      iVar6 = _CFDataCreate(0,*piVar3,uVar8);
      if (cVar4 == '\0') {
        _IndirectSetLock(piVar3,0);
      }
      if (iVar6 != 0) {
        iVar9 = _CFDictionaryCreateMutable
                          (0,0,*(undefined4 *)(unaff_EBX + 0x159c5),
                           *(undefined4 *)(unaff_EBX + 0x15989));
        if (iVar9 != 0) {
          _CFDictionarySetValue(iVar9,unaff_EBX + 0xaea5,iVar6);
          uVar8 = **(undefined4 **)(unaff_EBX + 0x159b9);
          uVar1 = **(undefined4 **)(unaff_EBX + 0x159d1);
          uVar2 = **(undefined4 **)(unaff_EBX + 0x159ad);
          _CFPreferencesSetValue(unaff_EBX + 0xaeb5,iVar9,uVar2,uVar1,uVar8);
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
LAB_00029e85:
  if (local_20[0] != (int *)0x0) {
    _IndirectDeallocate(local_20[0]);
  }
  uVar7 = *(uint *)((int)pvVar5 + 0xf0);
  uVar12 = *(uint *)((int)pvVar5 + 0xf4);
  *(uint *)((int)pvVar5 + 0xf0) =
       uVar12 >> 0x18 | uVar12 >> 8 & 0xff00 | (uVar12 & 0xff00) << 8 | uVar12 << 0x18;
  *(uint *)((int)pvVar5 + 0xf4) =
       uVar7 >> 0x18 | (uVar7 & 0xff0000) >> 8 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)pvVar5 + 0xf8);
  uVar12 = *(uint *)((int)pvVar5 + 0xfc);
  *(uint *)((int)pvVar5 + 0xf8) =
       uVar12 >> 0x18 | uVar12 >> 8 & 0xff00 | (uVar12 & 0xff00) << 8 | uVar12 << 0x18;
  *(uint *)((int)pvVar5 + 0xfc) =
       uVar7 >> 0x18 | (uVar7 & 0xff0000) >> 8 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)pvVar5 + 0x100);
  *(uint *)((int)pvVar5 + 0x100) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)pvVar5 + 0x104);
  *(uint *)((int)pvVar5 + 0x104) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)pvVar5 + 0x108);
  *(uint *)((int)pvVar5 + 0x108) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)pvVar5 + 0x10c);
  *(uint *)((int)pvVar5 + 0x10c) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)pvVar5 + 0x110);
  *(uint *)((int)pvVar5 + 0x110) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)pvVar5 + 0x114);
  *(uint *)((int)pvVar5 + 0x114) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  uVar7 = *(uint *)((int)pvVar5 + 0x118);
  *(uint *)((int)pvVar5 + 0x118) =
       uVar7 >> 0x18 | uVar7 >> 8 & 0xff00 | (uVar7 & 0xff00) << 8 | uVar7 << 0x18;
  return local_340;
}


// ==== __RT3_ReadLogEntry @ 0002a24d ====

int __RT3_ReadLogEntry(void)

{
  uint uVar1;
  uint uVar2;
  bool bVar3;
  bool bVar4;
  bool bVar5;
  void *pvVar6;
  int iVar7;
  uint uVar8;
  undefined4 uVar9;
  byte bVar10;
  byte *pbVar11;
  int unaff_EBX;
  uint uVar12;
  int local_340;
  undefined1 local_33c [256];
  undefined1 local_23c;
  undefined1 local_23b;
  char local_239;
  undefined1 local_220 [256];
  byte local_120 [256];
  int *local_20 [4];
  
  pvVar6 = (void *)___i686_get_pc_thunk_bx();
  _memcpy(local_120,(void *)(unaff_EBX + 0x9b82),0x100);
  local_20[0] = (int *)0x0;
  bVar10 = 0x7a;
  pbVar11 = local_120;
  while( true ) {
    if (*pbVar11 == 0) break;
    *pbVar11 = *pbVar11 ^ bVar10;
    bVar10 = bVar10 - 3;
    pbVar11 = pbVar11 + 1;
  }
  iVar7 = _FT_FileLoad(0xfffffffd,local_120,"t Blashpemy",0,local_20);
  if (((iVar7 == 0) || (iVar7 != -0x1c23)) && (uVar8 = _IndirectGetSize(local_20[0]), 7 < uVar8)) {
LAB_0002a33b:
    bVar4 = false;
  }
  else {
    if (local_20[0] != (int *)0x0) {
      _IndirectDeallocate(local_20[0]);
      local_20[0] = (int *)0x0;
    }
    iVar7 = __RT3_LoadCFPrefs();
    if (local_20[0] == (int *)0x0) goto LAB_0002a33b;
    bVar4 = true;
  }
  if (iVar7 == 0) {
    iVar7 = _IndirectDecompress(local_20[0],0x7a6c6962,0);
    if (iVar7 != 0) {
      if (iVar7 != -0x1b5a) goto LAB_0002a9f1;
      goto LAB_0002a376;
    }
    uVar8 = _IndirectGetSize(local_20[0]);
    uVar8 = uVar8 / 0x11c;
    local_340 = 0;
    for (uVar12 = 0; uVar12 < uVar8; uVar12 = uVar12 + 1) {
      _StringCopySafe(local_220,*local_20[0] + local_340,0x100);
      iVar7 = _StringCompare(*(undefined4 *)(unaff_EBX + 0x14e76),local_220);
      local_340 = local_340 + 0x11c;
      if (iVar7 == 0) break;
    }
    if (uVar8 != uVar12) {
      _memcpy(pvVar6,(void *)(uVar12 * 0x11c + *local_20[0]),0x11c);
      uVar1 = *(uint *)((int)pvVar6 + 0xf0);
      uVar2 = *(uint *)((int)pvVar6 + 0xf4);
      *(uint *)((int)pvVar6 + 0xf0) =
           uVar2 >> 0x18 | uVar2 >> 8 & 0xff00 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
      *(uint *)((int)pvVar6 + 0xf4) =
           uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
      uVar1 = *(uint *)((int)pvVar6 + 0xf8);
      uVar2 = *(uint *)((int)pvVar6 + 0xfc);
      *(uint *)((int)pvVar6 + 0xf8) =
           uVar2 >> 0x18 | uVar2 >> 8 & 0xff00 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
      *(uint *)((int)pvVar6 + 0xfc) =
           uVar1 >> 0x18 | (uVar1 & 0xff0000) >> 8 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
      uVar1 = *(uint *)((int)pvVar6 + 0x100);
      *(uint *)((int)pvVar6 + 0x100) =
           uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
      uVar1 = *(uint *)((int)pvVar6 + 0x104);
      *(uint *)((int)pvVar6 + 0x104) =
           uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
      uVar1 = *(uint *)((int)pvVar6 + 0x108);
      *(uint *)((int)pvVar6 + 0x108) =
           uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
      uVar1 = *(uint *)((int)pvVar6 + 0x10c);
      *(uint *)((int)pvVar6 + 0x10c) =
           uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
      uVar1 = *(uint *)((int)pvVar6 + 0x110);
      *(uint *)((int)pvVar6 + 0x110) =
           uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
      uVar1 = *(uint *)((int)pvVar6 + 0x114);
      *(uint *)((int)pvVar6 + 0x114) =
           uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
      uVar1 = *(uint *)((int)pvVar6 + 0x118);
      *(uint *)((int)pvVar6 + 0x118) =
           uVar1 >> 0x18 | uVar1 >> 8 & 0xff00 | (uVar1 & 0xff00) << 8 | uVar1 << 0x18;
    }
    bVar3 = uVar8 == uVar12;
    _IndirectDeallocate(local_20[0]);
    local_20[0] = (int *)0x0;
    iVar7 = _FT_FileGetFlags(0xfffffffd,local_120,local_33c,0);
    if ((iVar7 == 0) && (!bVar3)) {
      if (local_239 != '\0') {
        bVar5 = false;
        bVar3 = false;
        goto LAB_0002a824;
      }
      local_23c = 1;
      local_23b = 1;
      local_239 = '\x01';
      _FT_FileSetFlags(0xfffffffd,local_120,local_33c);
      bVar5 = false;
      goto LAB_0002a81e;
    }
    bVar5 = false;
  }
  else {
LAB_0002a376:
    if (iVar7 == -0x1c29) {
      bVar5 = true;
LAB_0002a81e:
      bVar3 = false;
    }
    else {
      bVar5 = false;
      bVar3 = true;
    }
  }
LAB_0002a824:
  if (bVar4) {
LAB_0002a8ff:
    iVar7 = __RT3_WriteLogEntry();
    if (iVar7 != 0) {
      if (((undefined *)0x4 < &DAT_00001c29 + iVar7) ||
         ((1 << ((byte)(&DAT_00001c29 + iVar7) & 0x1f) & 0x13U) == 0)) goto LAB_0002a9f1;
LAB_0002a92f:
      _StringCopySafe(pvVar6,*(undefined4 *)(unaff_EBX + 0x14e76),0xf0);
      iVar7 = _TimerGetUTCSeconds();
      *(int *)((int)pvVar6 + 0x100) = iVar7 + -0x755580;
      *(char **)((int)pvVar6 + 0x104) =
           "/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework/Headers/MacMemory.h";
      *(undefined4 *)((int)pvVar6 + 0x108) = 100;
      *(undefined4 *)((int)pvVar6 + 0x10c) = 0;
      *(undefined4 *)((int)pvVar6 + 0x110) = 0;
      *(undefined4 *)((int)pvVar6 + 0x114) = 0;
      *(undefined4 *)((int)pvVar6 + 0x118) = 0;
    }
  }
  else {
    if (bVar3) {
      _StringCopySafe(pvVar6,*(undefined4 *)(unaff_EBX + 0x14e76),0xf0);
      uVar9 = _TimerGetUTCSeconds();
      *(undefined4 *)((int)pvVar6 + 0x100) = uVar9;
      *(undefined4 *)((int)pvVar6 + 0x104) = 0;
      *(undefined4 *)((int)pvVar6 + 0x108) = 0;
      if (*(uint *)(unaff_EBX + 0xa0b6) < *(uint *)((int)pvVar6 + 0x100)) {
        *(uint *)((int)pvVar6 + 0x100) = *(uint *)(unaff_EBX + 0xa0b6);
      }
      if (*(uint *)((int)pvVar6 + 0x108) < *(uint *)(unaff_EBX + 0xa0b2)) {
        *(uint *)((int)pvVar6 + 0x108) = *(uint *)(unaff_EBX + 0xa0b2);
      }
      if (*(uint *)((int)pvVar6 + 0x104) < *(uint *)(unaff_EBX + 0xa0ae)) {
        *(uint *)((int)pvVar6 + 0x104) = *(uint *)(unaff_EBX + 0xa0ae);
      }
      *(undefined4 *)((int)pvVar6 + 0x10c) = 0;
      *(undefined4 *)((int)pvVar6 + 0x110) = 0;
      *(undefined4 *)((int)pvVar6 + 0x114) = 0;
      *(undefined4 *)((int)pvVar6 + 0x118) = 0;
      goto LAB_0002a8ff;
    }
    if (bVar5) goto LAB_0002a92f;
    uVar8 = *(uint *)((int)pvVar6 + 0x100);
    if (*(uint *)(unaff_EBX + 0xa0b6) <= *(uint *)((int)pvVar6 + 0x100)) {
      uVar8 = *(uint *)(unaff_EBX + 0xa0b6);
    }
    *(uint *)(unaff_EBX + 0xa0b6) = uVar8;
    uVar8 = *(uint *)((int)pvVar6 + 0x108);
    if (*(uint *)((int)pvVar6 + 0x108) <= *(uint *)(unaff_EBX + 0xa0b2)) {
      uVar8 = *(uint *)(unaff_EBX + 0xa0b2);
    }
    *(uint *)(unaff_EBX + 0xa0b2) = uVar8;
    if (*(uint *)(unaff_EBX + 0xa0ae) < *(uint *)((int)pvVar6 + 0x104)) {
      *(uint *)(unaff_EBX + 0xa0ae) = *(uint *)((int)pvVar6 + 0x104);
    }
  }
  iVar7 = 0;
LAB_0002a9f1:
  if (local_20[0] != (int *)0x0) {
    _IndirectDeallocate(local_20[0]);
  }
  return iVar7;
}


// ==== __RT3_LicenseSave @ 0002aa3b ====

int __RT3_LicenseSave(char param_1)

{
  int iVar1;
  char cVar2;
  int *piVar3;
  int iVar4;
  undefined4 uVar5;
  int extraout_ECX;
  uint uVar6;
  uint uVar7;
  int unaff_EBX;
  byte *pbVar8;
  undefined8 uVar9;
  undefined1 local_11c [268];
  
  uVar9 = ___i686_get_pc_thunk_bx();
  uVar6 = (uint)((ulonglong)uVar9 >> 0x20);
  _StringCopySafe(local_11c,*(undefined4 *)(unaff_EBX + 0x14688),0x100);
  _StringAppendSafe(local_11c,unaff_EBX + 0x84d4,0x100);
  iVar1 = *(int *)(*(int *)uVar9 + 0x200);
  piVar3 = (int *)_IndirectDuplicate((int *)uVar9);
  if (piVar3 == (int *)0x0) {
    return -0x1b5c;
  }
  if (uVar6 == 0) {
    iVar4 = *piVar3;
    uVar5 = __RT3_CalcIdentifier();
    *(undefined4 *)(iVar4 + 0x204) = uVar5;
    if (param_1 != '\0') goto LAB_0002ab46;
    iVar4 = *piVar3;
    uVar5 = __RT3_CalcLoginHash();
    *(undefined4 *)(iVar4 + 0x20c) = uVar5;
  }
  else {
    uVar7 = 0;
    for (pbVar8 = *(byte **)(unaff_EBX + 0x14688); *pbVar8 != 0; pbVar8 = pbVar8 + 1) {
      uVar7 = uVar7 >> 0x1d ^ uVar7 * 4 ^ (uint)*pbVar8;
    }
    *(uint *)(*piVar3 + 0x204) = uVar7 ^ uVar6;
LAB_0002ab46:
    *(undefined4 *)(*piVar3 + 0x20c) = 0;
  }
  uVar6 = *(uint *)(*piVar3 + 0x200);
  *(uint *)(*piVar3 + 0x200) =
       uVar6 >> 0x18 | (int)uVar6 >> 8 & 0xff00U | (uVar6 & 0xff00) << 8 | uVar6 << 0x18;
  uVar6 = *(uint *)(*piVar3 + 0x204);
  *(uint *)(*piVar3 + 0x204) =
       uVar6 >> 0x18 | uVar6 >> 8 & 0xff00 | (uVar6 & 0xff00) << 8 | uVar6 << 0x18;
  uVar6 = *(uint *)(*piVar3 + 0x208);
  *(uint *)(*piVar3 + 0x208) =
       uVar6 >> 0x18 | uVar6 >> 8 & 0xff00 | (uVar6 & 0xff00) << 8 | uVar6 << 0x18;
  uVar6 = *(uint *)(*piVar3 + 0x20c);
  *(uint *)(*piVar3 + 0x20c) =
       uVar6 >> 0x18 | uVar6 >> 8 & 0xff00 | (uVar6 & 0xff00) << 8 | uVar6 << 0x18;
  uVar6 = *(uint *)(*piVar3 + 0x210);
  *(uint *)(*piVar3 + 0x210) =
       uVar6 >> 0x18 | uVar6 >> 8 & 0xff00 | (uVar6 & 0xff00) << 8 | uVar6 << 0x18;
  uVar6 = *(uint *)(*piVar3 + 0x214);
  *(uint *)(*piVar3 + 0x214) =
       uVar6 >> 0x18 | uVar6 >> 8 & 0xff00 | (uVar6 & 0xff00) << 8 | uVar6 << 0x18;
  iVar4 = _IndirectCompress(piVar3,0x7a6c6962,0);
  if (iVar4 == 0) {
    if ((param_1 == '\0') || (cVar2 = _SystemRunningAsAdmin(), cVar2 != '\0')) {
      iVar4 = _FT_FileSave((-(uint)(param_1 == '\0') & 4) - 7,local_11c,1,0x416c6963,0x41726567,
                           piVar3);
    }
    else {
      _IndirectSetLock(piVar3,1);
      iVar4 = _GetPathToSystemPreferences(local_11c);
      if (iVar4 == 0) {
        iVar4 = -0x1b5c;
        goto LAB_0002adce;
      }
      uVar5 = _IndirectGetSize(piVar3);
      iVar4 = _WriteToFileAsSuperUser(iVar4,*piVar3,uVar5);
    }
    if (iVar4 == 0) {
      *(int *)(unaff_EBX + 0x98bc) = *(int *)(unaff_EBX + 0x98bc) + 1;
      *(undefined4 *)(unaff_EBX + 0x98d0) = 0;
      __RT3_ReadLogEntry();
      iVar4 = _TimerGetUTCSeconds();
      if ((param_1 == '\0') && (0x2a2ff < (extraout_ECX - iVar4) + 0x15180U)) {
        if (iVar1 == 0) {
          uVar5 = 0;
        }
        else {
          uVar5 = __RT3_CalcHashedStamp();
        }
        *(undefined4 *)(*(int *)(unaff_EBX + 0x14690) + 0x110) = uVar5;
      }
      else {
        iVar1 = *(int *)(unaff_EBX + 0x14690);
        *(undefined4 *)(iVar1 + 0x110) = 0;
        *(undefined4 *)(iVar1 + 0x10c) = 0;
      }
      __RT3_WriteLogEntry();
      iVar4 = 0;
    }
  }
LAB_0002adce:
  _IndirectDeallocate(piVar3);
  return iVar4;
}


// ==== __RT3_LicenseLoad @ 0002ade3 ====

int __RT3_LicenseLoad(void)

{
  int iVar1;
  uint uVar2;
  uint uVar3;
  uint uVar4;
  undefined1 *extraout_ECX;
  byte *pbVar5;
  undefined1 *puVar6;
  int unaff_EBX;
  int *piVar7;
  uint uVar8;
  uint uVar9;
  bool bVar10;
  bool bVar11;
  undefined8 uVar12;
  int local_150;
  int *local_14c;
  int local_148;
  int *local_13c;
  int local_130;
  undefined1 local_12c [256];
  uint local_2c;
  uint local_28;
  int *local_20 [4];
  
  uVar12 = ___i686_get_pc_thunk_bx();
  puVar6 = (undefined1 *)((ulonglong)uVar12 >> 0x20);
  local_20[0] = (int *)0x0;
  *(undefined4 *)uVar12 = 0;
  *puVar6 = 0;
  if (extraout_ECX != (undefined1 *)0x0) {
    *extraout_ECX = 0;
  }
  uVar9 = 0;
  for (pbVar5 = *(byte **)(unaff_EBX + 0x142e0); *pbVar5 != 0; pbVar5 = pbVar5 + 1) {
    uVar9 = uVar9 >> 0x1d ^ uVar9 * 4 ^ (uint)*pbVar5;
  }
  _StringCopySafe(local_12c,*(byte **)(unaff_EBX + 0x142e0),0x100);
  _StringAppendSafe(local_12c,unaff_EBX + 0x812c,0x100);
  local_14c = (int *)0x0;
  local_148 = 0;
  local_13c = (int *)(unaff_EBX + 0x9530);
  do {
    iVar1 = _FT_FileGetFlags(*local_13c,local_12c,0,0);
    if (iVar1 == 0) {
      iVar1 = _FT_FileLoad(*local_13c,local_12c,0x5000,0,local_20);
    }
    if (iVar1 == -0x1b5c) {
      local_130 = -0x1b5c;
      iVar1 = local_130;
      goto LAB_0002b537;
    }
    if (iVar1 == 0) {
      iVar1 = _IndirectDecompress(local_20[0],0x7a6c6962,0);
      if (iVar1 == 0) {
        if (((local_20[0] != (int *)0x0) && (uVar2 = _IndirectGetSize(local_20[0]), 0x217 < uVar2))
           && (iVar1 = *local_20[0], *(int *)(iVar1 + 0x204) != 0)) {
          uVar2 = *(uint *)(iVar1 + 0x200);
          *(uint *)(iVar1 + 0x200) =
               uVar2 >> 0x18 | (int)uVar2 >> 8 & 0xff00U | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
          uVar2 = *(uint *)(*local_20[0] + 0x204);
          *(uint *)(*local_20[0] + 0x204) =
               uVar2 >> 0x18 | uVar2 >> 8 & 0xff00 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
          uVar2 = *(uint *)(*local_20[0] + 0x208);
          *(uint *)(*local_20[0] + 0x208) =
               uVar2 >> 0x18 | uVar2 >> 8 & 0xff00 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
          uVar2 = *(uint *)(*local_20[0] + 0x20c);
          *(uint *)(*local_20[0] + 0x20c) =
               uVar2 >> 0x18 | uVar2 >> 8 & 0xff00 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
          uVar2 = *(uint *)(*local_20[0] + 0x210);
          *(uint *)(*local_20[0] + 0x210) =
               uVar2 >> 0x18 | uVar2 >> 8 & 0xff00 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
          uVar2 = *(uint *)(*local_20[0] + 0x214);
          *(uint *)(*local_20[0] + 0x214) =
               uVar2 >> 0x18 | uVar2 >> 8 & 0xff00 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
          uVar2 = *(uint *)(*local_20[0] + 0x204);
          uVar3 = __RT3_CalcIdentifier();
          if ((uVar2 != (uVar9 ^ 0xa5a5a5a5)) && (uVar2 != uVar3)) {
            iVar1 = (uVar2 ^ uVar9) - (uVar3 ^ uVar9);
            if (iVar1 < 0) {
              iVar1 = -iVar1;
            }
            if ((0x15180 < iVar1) || ((iVar1 % 0xf) * 0x40 != (iVar1 % 0xf) * 4)) goto LAB_0002b1d0;
          }
          if ((*local_13c == -7) ||
             (((*(int *)(*local_20[0] + 0x20c) == 0 || (iVar1 = __RT3_CalcLoginHash(), iVar1 == 0))
              || (iVar1 == *(int *)(*local_20[0] + 0x20c))))) {
            piVar7 = local_20[0];
            if (local_14c != (int *)0x0) {
              if (((*(int *)(*local_14c + 0x200) != 0) || (*(int *)(*local_20[0] + 0x200) == 0)) &&
                 (*(uint *)(*local_20[0] + 0x208) <= *(uint *)(*local_14c + 0x208)))
              goto LAB_0002b1d0;
              _IndirectDeallocate(local_14c);
              piVar7 = local_20[0];
            }
            local_148 = *local_13c;
            local_20[0] = (int *)0x0;
            local_14c = piVar7;
          }
        }
      }
      else if (iVar1 != -0x1b5a) goto LAB_0002b537;
    }
LAB_0002b1d0:
    local_13c = local_13c + 1;
  } while ((int *)(unaff_EBX + 0x9538) != local_13c);
  bVar10 = local_14c != (int *)0x0;
  if (bVar10) {
    local_20[0] = local_14c;
    local_150 = local_148;
  }
  else {
    local_150 = 0;
  }
  if (**(char **)(unaff_EBX + 0x142b4) == '\0') {
    local_130 = 0;
LAB_0002b47c:
    bVar10 = !bVar10;
LAB_0002b483:
    if (!bVar10) goto LAB_0002b52d;
LAB_0002b489:
    if (local_20[0] == (int *)0x0) {
      local_20[0] = (int *)_IndirectAllocate(0x218);
      if (local_20[0] == (int *)0x0) {
        return -0x1b5c;
      }
    }
    else {
      iVar1 = _IndirectSetSize(local_20[0],0x218);
      if (iVar1 != 0) goto LAB_0002b537;
    }
    _MemoryClear(*local_20[0],0x218);
    *(undefined4 *)(*local_20[0] + 0x200) = 0;
    *(undefined4 *)(*local_20[0] + 0x208) = 0;
    *(undefined4 *)(*local_20[0] + 0x20c) = 0;
    *puVar6 = 1;
  }
  else {
    if (!bVar10) {
      local_130 = 0;
      goto LAB_0002b489;
    }
    if (*(int *)(*local_20[0] + 0x200) == 0) {
      local_130 = 0;
LAB_0002b3d9:
      if (((*(int *)(*local_20[0] + 0x200) != 0) &&
          (uVar9 = *(uint *)(*(int *)(unaff_EBX + 0x142e8) + 0x108), uVar9 != 0)) &&
         (uVar9 == (uVar9 / 3) * 3)) {
        _RT3_LicenseTextToCode(*local_20[0] + 0x100,&local_2c);
        if (((*(uint *)(*(int *)(unaff_EBX + 0x142e8) + 0xf4) ^ local_28) & 0x7bdfef7) != 0 ||
            ((*(uint *)(*(int *)(unaff_EBX + 0x142e8) + 0xf0) ^ local_2c) & 0xfbdfef78) != 0) {
          bVar10 = ((*(uint *)(*(int *)(unaff_EBX + 0x142e8) + 0xfc) ^ local_28) & 0x7bdfef7) == 0
                   && ((*(uint *)(*(int *)(unaff_EBX + 0x142e8) + 0xf8) ^ local_2c) & 0xfbdfef78) ==
                      0;
          goto LAB_0002b483;
        }
        goto LAB_0002b489;
      }
    }
    else {
      local_130 = __RT3_ReadLogEntry();
      if (**(char **)(unaff_EBX + 0x142b4) != '\0') {
        if (*(int *)(*local_20[0] + 0x200) != 0) {
          uVar2 = *(uint *)(*(int *)(unaff_EBX + 0x142e8) + 0x10c);
          uVar3 = *(uint *)(*(int *)(unaff_EBX + 0x142e8) + 0x110);
          uVar4 = _TimerGetUTCSeconds();
          uVar8 = 0;
          if (uVar2 != 0) {
            uVar8 = uVar2 ^ uVar9;
          }
          uVar9 = uVar9 ^ uVar3;
          if (uVar3 == 0) {
            uVar9 = 0;
          }
          if (local_150 == -7) {
            if (uVar8 == 0) {
              bVar11 = uVar9 == 0;
LAB_0002b30b:
              if (bVar11) goto LAB_0002b319;
            }
            iVar1 = *(int *)(unaff_EBX + 0x142e8);
            *(undefined4 *)(iVar1 + 0x10c) = 0;
            *(undefined4 *)(iVar1 + 0x110) = 0;
            iVar1 = __RT3_WriteLogEntry();
            if (iVar1 != 0) {
              local_130 = iVar1;
            }
          }
          else if (uVar8 == 0) {
            if (uVar9 != 0) {
              if ((int)(uVar4 - uVar9) < 0x24ea00) {
                bVar11 = 0 < (int)(uVar4 - uVar9);
                goto LAB_0002b363;
              }
              goto LAB_0002b3b1;
            }
          }
          else if (uVar9 != 0) {
            if ((0x93a80 < uVar4 - uVar8) || ((uVar8 <= uVar9 + 0x15180 && (uVar9 <= uVar4)))) {
              bVar11 = 0x93a80 < (int)(uVar4 - uVar8);
LAB_0002b363:
              bVar11 = !bVar11;
              goto LAB_0002b30b;
            }
LAB_0002b3b1:
            bVar10 = false;
          }
LAB_0002b319:
          if (**(char **)(unaff_EBX + 0x142b4) == '\0') goto LAB_0002b47c;
          if (!bVar10) goto LAB_0002b489;
        }
        goto LAB_0002b3d9;
      }
    }
  }
LAB_0002b52d:
  iVar1 = local_130;
  if (local_130 == 0) {
    if (local_20[0] == (int *)0x0) {
      return 0;
    }
    *(undefined4 *)uVar12 = local_20[0];
    if ((extraout_ECX != (undefined1 *)0x0) && (local_150 == -7)) {
      *extraout_ECX = 1;
    }
    _IndirectSetLock(local_20[0],1);
    **(int **)(unaff_EBX + 0x142f8) = *local_20[0];
    return 0;
  }
LAB_0002b537:
  local_130 = iVar1;
  if (local_20[0] != (int *)0x0) {
    _IndirectDeallocate(local_20[0]);
  }
  return local_130;
}


// ==== __RT3_LicenseRefresh @ 0002b5b3 ====

int __RT3_LicenseRefresh(void)

{
  char *pcVar1;
  bool bVar2;
  int iVar3;
  int unaff_EBX;
  int *piVar4;
  undefined4 *puVar5;
  undefined8 uVar6;
  int local_254;
  int *local_250;
  undefined1 local_244 [272];
  int local_134;
  undefined1 local_128 [256];
  int local_28 [2];
  char local_1d;
  
  ___i686_get_pc_thunk_bx();
  local_28[0] = 1;
  local_28[1] = 1;
  local_1d = '\0';
  _StringCopySafe(local_128,*(undefined4 *)(unaff_EBX + 0x13b10),0x100);
  _StringAppendSafe(local_128,unaff_EBX + 0x795c,0x100);
  bVar2 = false;
  local_254 = 1;
  puVar5 = (undefined4 *)(unaff_EBX + 0x8d60);
  piVar4 = local_28;
  local_250 = (int *)(unaff_EBX + 0x8d58);
  do {
    iVar3 = _FT_FileGetFlags(*puVar5,local_128,0,0);
    if ((iVar3 == 0) && (iVar3 = _FT_FileGetFlags(*puVar5,local_128,local_244,0), iVar3 == 0)) {
      *piVar4 = local_134;
    }
    if (*piVar4 != *local_250) {
      bVar2 = true;
    }
    local_254 = local_254 + 1;
    piVar4 = piVar4 + 1;
    puVar5 = puVar5 + 1;
    local_250 = local_250 + 1;
  } while (local_254 != 3);
  if (*(int *)(unaff_EBX + 0x8d68) != 0) {
    if (!bVar2) {
      return 0;
    }
    _IndirectDeallocate(*(int *)(unaff_EBX + 0x8d68));
    *(undefined4 *)(unaff_EBX + 0x8d68) = 0;
  }
  iVar3 = __RT3_LicenseLoad();
  if (iVar3 == 0) {
    pcVar1 = *(char **)(unaff_EBX + 0x13b1c);
    _MemoryCopy(pcVar1,**(undefined4 **)(unaff_EBX + 0x8d68),0x218);
    _MemoryCopy((int *)(unaff_EBX + 0x8d58),local_28,8);
    if (*pcVar1 == '\0') {
      _StringCopy(*(undefined4 *)(unaff_EBX + 0x13afc),pcVar1);
    }
    else {
      _RT3_FixLicenseName(*(undefined4 *)(unaff_EBX + 0x13afc),pcVar1);
    }
    iVar3 = *(int *)(*(int *)(unaff_EBX + 0x13b1c) + 0x200);
    if (iVar3 < 1) {
      _StringCopy(*(undefined4 *)(unaff_EBX + 0x13b24),*(undefined4 *)(unaff_EBX + 0x13ae8));
    }
    else {
      _StringFromNumber(*(undefined4 *)(unaff_EBX + 0x13b24),iVar3);
    }
    iVar3 = *(int *)(unaff_EBX + 0x13b1c);
    *(bool *)**(undefined4 **)(unaff_EBX + 0x13af4) = 0 < *(int *)(iVar3 + 0x200);
    uVar6 = _RT3_CalcMainHash(*(undefined4 *)(unaff_EBX + 0x13b10),
                              *(undefined4 *)(unaff_EBX + 0x13afc),*(undefined4 *)(iVar3 + 0x200));
    **(undefined8 **)(unaff_EBX + 0x13b0c) = uVar6;
    if (local_1d != '\0') {
      __RT3_LicenseSave(0);
    }
    return 0;
  }
  return iVar3;
}


// ==== _RT3_ResetLicenseInfo @ 0002b84e ====

int _RT3_ResetLicenseInfo(void)

{
  undefined4 *puVar1;
  int iVar2;
  int unaff_EBX;
  int iVar3;
  
  ___i686_get_pc_thunk_bx();
  if (*(char *)(unaff_EBX + 0x8ad4) == '\0') {
    iVar3 = -0x1b5a;
  }
  else {
    puVar1 = (undefined4 *)_IndirectAllocate(0x218);
    if (puVar1 == (undefined4 *)0x0) {
      iVar3 = -0x1b5c;
    }
    else {
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


// ==== _RT3_EnableCrackDetection @ 0002b8c7 ====

void _RT3_EnableCrackDetection(char param_1)

{
  int unaff_EBX;
  
  ___i686_get_pc_thunk_bx();
  if (param_1 == '\0') {
    __RT3_LicenseRefresh();
  }
  else {
    **(int **)(unaff_EBX + 0x13819) = unaff_EBX + 0x3dd1;
    _MemoryClear(*(undefined4 *)(unaff_EBX + 0x1380d),0x218);
    _MemoryClear(unaff_EBX + 0x8a49,8);
    _MemoryClear(**(undefined4 **)(unaff_EBX + 0x137e5),1);
    _MemoryClear(*(undefined4 *)(unaff_EBX + 0x137ed),0x100);
  }
  return;
}


// ==== _RT3_Idle @ 0002b94e ====

void _RT3_Idle(void)

{
  uint *puVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  undefined4 uVar5;
  int unaff_EBX;
  
  ___i686_get_pc_thunk_bx();
  if (*(char *)(unaff_EBX + 0x89d8) != '\0') {
    iVar3 = _TimerGetTicks();
    iVar2 = *(int *)(unaff_EBX + 0xc9e8);
    if ((iVar2 == 0) || (iVar4 = _TimerGetTickRate(), (uint)(iVar4 * 2) < (uint)(iVar3 - iVar2))) {
      __RT3_LicenseRefresh();
      uVar5 = _TimerGetTicks();
      *(undefined4 *)(unaff_EBX + 0xc9e8) = uVar5;
    }
    puVar1 = (uint *)(**(int **)(unaff_EBX + 0x13760) + -3);
    *puVar1 = *puVar1 ^ *(uint *)(unaff_EBX + 0xc9e8) >> 8;
    return;
  }
  return;
}


// ==== __RT3_FSEventCallback @ 0002b9a7 ====

void __RT3_FSEventCallback(void)

{
  __RT3_LicenseRefresh();
  return;
}


// ==== _RT3_SetLicenseInfo @ 0002b9b5 ====

int _RT3_SetLicenseInfo(undefined4 param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,
                       undefined4 param_5,undefined4 param_6,undefined1 param_7)

{
  int iVar1;
  undefined4 uVar2;
  int iVar3;
  int unaff_EBX;
  undefined1 local_12c [256];
  undefined4 local_2c;
  undefined4 local_28;
  int *local_24;
  undefined1 local_1d;
  
  ___i686_get_pc_thunk_bx();
  local_24 = (int *)0x0;
  local_1d = 0;
  local_2c = 0;
  local_28 = 0;
  if (_QuitAppleEventHandler[unaff_EBX + 1] == (code)0x0) {
    iVar1 = -0x1b5a;
  }
  else {
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


// ==== _RT3_CreateLicenseFile @ 0002bb01 ====

undefined4
_RT3_CreateLicenseFile
          (int param_1,byte *param_2,undefined4 param_3,undefined4 param_4,undefined1 param_5)

{
  undefined4 uVar1;
  undefined4 uVar2;
  int unaff_EBX;
  byte *pbVar3;
  int iVar4;
  char local_124 [256];
  int local_24;
  int local_20;
  
  ___i686_get_pc_thunk_bx();
  if (*(char *)(unaff_EBX + 0x881e) == '\0') {
    uVar1 = 0xffffe4a6;
  }
  else {
    if (param_1 != 0) {
      _RT3_FixLicenseName(unaff_EBX + 0xc72e,param_1);
    }
    if (*(char *)(unaff_EBX + 0xc72e) != '\0') {
      local_24 = 0;
      local_20 = 0;
      iVar4 = 0;
      for (pbVar3 = param_2; *pbVar3 != 0; pbVar3 = pbVar3 + 1) {
        if (*(char *)(*(int *)(unaff_EBX + 0x1359e) + (uint)*pbVar3) != -1) {
          iVar4 = iVar4 + 1;
        }
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


// ==== _RT3_IncNumLaunches @ 0002bc25 ====

void _RT3_IncNumLaunches(void)

{
  int *piVar1;
  int unaff_EBX;
  
  ___i686_get_pc_thunk_bx();
  __RT3_ReadLogEntry();
  piVar1 = (int *)(*(int *)(unaff_EBX + 0x134ab) + 0x108);
  *piVar1 = *piVar1 + 1;
  *(int *)(unaff_EBX + 0x86df) = *(int *)(unaff_EBX + 0x86df) + 1;
  __RT3_WriteLogEntry();
  return;
}


// ==== _RT3_Close @ 0002bc5c ====

void _RT3_Close(void)

{
  int iVar1;
  uint uVar2;
  int iVar3;
  int iVar4;
  undefined4 uVar5;
  int unaff_EBX;
  
  ___i686_get_pc_thunk_bx();
  if (*(char *)(unaff_EBX + 0x86c6) != '\0') {
    if (**(char **)(unaff_EBX + 0x1343e) != '\0') {
      __RT3_ReadLogEntry();
      iVar4 = *(int *)(unaff_EBX + 0x13472);
      *(int *)(iVar4 + 0x108) = *(int *)(iVar4 + 0x108) + 1;
      *(int *)(unaff_EBX + 0x86a6) = *(int *)(unaff_EBX + 0x86a6) + 1;
      if (*(int *)(unaff_EBX + 0x86ae) != 0) {
        uVar2 = _TimerGetElapsedSeconds();
        if (*(uint *)(unaff_EBX + 0x86ae) < uVar2) {
          iVar1 = *(int *)(iVar4 + 0x104);
          iVar3 = _TimerGetElapsedSeconds();
          *(int *)(iVar4 + 0x104) = iVar1 + (iVar3 - *(int *)(unaff_EBX + 0x86ae));
          iVar4 = _TimerGetElapsedSeconds();
          *(int *)(unaff_EBX + 0x86a2) =
               *(int *)(unaff_EBX + 0x86a2) + (iVar4 - *(int *)(unaff_EBX + 0x86ae));
        }
      }
      if (*(int *)(*(int *)(unaff_EBX + 0x13476) + 0x200) < 1) {
        uVar5 = __RT3_CalcHashedStamp();
        *(undefined4 *)(*(int *)(unaff_EBX + 0x13472) + 0x10c) = uVar5;
      }
      __RT3_WriteLogEntry();
    }
    __RT3_RemoveFSEventCallback();
    **(int **)(unaff_EBX + 0x13482) = unaff_EBX + 0x3a3a;
    if (*(int *)(unaff_EBX + 0x86c2) != 0) {
      _IndirectDeallocate(*(int *)(unaff_EBX + 0x86c2));
      *(undefined4 *)(unaff_EBX + 0x86c2) = 0;
    }
    _MemoryClear(**(undefined4 **)(unaff_EBX + 0x1344e),1);
    _MemoryClear(unaff_EBX + 0x86b2,8);
    *(undefined1 *)(unaff_EBX + 0x86c6) = 0;
  }
  return;
}


// ==== _RT3_Open @ 0002bd7e ====

int _RT3_Open(char param_1,short param_2,undefined4 param_3,undefined4 param_4)

{
  int iVar1;
  undefined4 uVar2;
  int unaff_EBX;
  
  ___i686_get_pc_thunk_bx();
  if (*(char *)(unaff_EBX + 0x85a4) == '\0') {
    iVar1 = _PlatformOpen();
    if (iVar1 != 0) {
      return iVar1;
    }
    iVar1 = _FT_Open();
    if (iVar1 != 0) {
      return iVar1;
    }
    if ((param_2 != 3) && (param_2 != -0x7ffd)) {
      return -0x1b5a;
    }
    _RT3_InitTables();
    if (param_1 != '\0') {
      _StringCopySafe(*(undefined4 *)(unaff_EBX + 0x13374),unaff_EBX + 0x71a0,0x100);
      _StringCopySafe(*(undefined4 *)(unaff_EBX + 0x13320),unaff_EBX + 0x39a8,0x100);
      _StringCopySafe(*(undefined4 *)(unaff_EBX + 0x13338),unaff_EBX + 0x39a8,0x100);
    }
    **(short **)(unaff_EBX + 0x13330) = param_2;
    _StringCopy(*(undefined4 *)(unaff_EBX + 0x13340),param_4);
    _StringCopy(*(undefined4 *)(unaff_EBX + 0x1335c),*(undefined4 *)(unaff_EBX + 0x13320));
    _StringCopy(*(undefined4 *)(unaff_EBX + 0x13348),param_3);
    _MemoryClear(*(undefined4 *)(unaff_EBX + 0x13334),0x100);
    *(undefined4 *)(unaff_EBX + 0x857c) = 0;
    **(char **)(unaff_EBX + 0x1331c) = param_1;
    if (param_1 != '\0') {
      uVar2 = _TimerGetElapsedSeconds();
      *(undefined4 *)(unaff_EBX + 0x858c) = uVar2;
    }
    iVar1 = __RT3_ReadLogEntry();
    if (iVar1 != 0) {
      return iVar1;
    }
    iVar1 = __RT3_LicenseRefresh();
    if (iVar1 != 0) {
      return iVar1;
    }
    iVar1 = __RT3_InstallFSEventCallback();
    if (iVar1 != 0) {
      _SystemSetIdleProc(unaff_EBX + -0x43e);
    }
    *(undefined1 *)(unaff_EBX + 0x85a4) = 1;
  }
  return 0;
}


// ==== _RT3_InitTables @ 0002bf01 ====

void _RT3_InitTables(void)

{
  int iVar1;
  char *pcVar2;
  undefined1 *puVar3;
  int unaff_EBX;
  int iVar4;
  undefined1 *puVar5;
  
  ___i686_get_pc_thunk_bx();
  if (*(char *)(unaff_EBX + 0xc435) == '\0') {
    iVar4 = 0;
    puVar3 = *(undefined1 **)(unaff_EBX + 0x131a1);
    puVar5 = puVar3;
    do {
      *puVar5 = 0xff;
      iVar1 = 0;
      pcVar2 = (char *)(unaff_EBX + 0x8471);
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
    iVar4 = *(int *)(unaff_EBX + 0x131a1);
    do {
      puVar3[0x61] = puVar3[0x41];
      puVar3 = puVar3 + 1;
    } while ((undefined1 *)(iVar4 + 0x1a) != puVar3);
    *(undefined1 *)(unaff_EBX + 0xc435) = 1;
  }
  return;
}


// ==== _RT3_CalcTimePeriod @ 0002bf81 ====

uint _RT3_CalcTimePeriod(uint param_1)

{
  uint uVar1;
  
  if (param_1 < 0x3a500ed0) {
    uVar1 = 0;
  }
  else {
    uVar1 = (param_1 + 0xc5b92bb0) / 0x127500 & 0xff;
  }
  return uVar1;
}


// ==== _RT3_FixProductName @ 0002bfa7 ====

void _RT3_FixProductName(char *param_1,char *param_2)

{
  char cVar1;
  char *pcVar2;
  
  for (pcVar2 = param_1; (uint)((int)pcVar2 - (int)param_1) < 0xff; pcVar2 = pcVar2 + 1) {
    cVar1 = *param_2;
    *pcVar2 = cVar1;
    param_2 = param_2 + 1;
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


// ==== _RT3_FixLicenseName @ 0002bffd ====

void _RT3_FixLicenseName(char *param_1,char *param_2)

{
  char cVar1;
  char *pcVar2;
  char *pcVar3;
  int unaff_EBX;
  uint uVar4;
  
  ___i686_get_pc_thunk_bx();
  uVar4 = 0;
  for (pcVar2 = param_2;
      (((cVar1 = *pcVar2, cVar1 != '\0' && (uVar4 < 0xff)) && (0x19 < (byte)(cVar1 + 0x9fU))) &&
      (0x19 < (byte)(cVar1 + 0xbfU))); pcVar2 = pcVar2 + 1) {
    if ((byte)(cVar1 - 0x30U) < 10) {
      param_1[uVar4] = cVar1;
      uVar4 = uVar4 + 1;
    }
  }
  pcVar3 = param_1;
  if (((*(short *)(unaff_EBX + 0x8398) == -0x7ffd) && (*pcVar2 == '\0')) && (uVar4 == 6)) {
    pcVar3 = param_1 + 6;
    uVar4 = (int)pcVar3 - (int)param_1;
  }
  else {
    while (uVar4 = (int)pcVar3 - (int)param_1, uVar4 < 0xff) {
      cVar1 = *param_2;
      *pcVar3 = cVar1;
      param_2 = param_2 + 1;
      if (cVar1 == '\0') goto LAB_0002c0a0;
      if ((byte)(cVar1 + 0x9fU) < 0x1a) {
        *pcVar3 = cVar1 + -0x20;
        pcVar3 = pcVar3 + 1;
      }
      else {
        pcVar3 = pcVar3 + ((byte)(cVar1 + 0xbfU) < 0x1a);
      }
    }
  }
  if (uVar4 < 0x100) {
LAB_0002c0a0:
    *pcVar3 = '\0';
  }
  return;
}


// ==== _RT3_CalcMainHash @ 0002c0a8 ====

undefined8 _RT3_CalcMainHash(char *param_1,char *param_2,int param_3)

{
  char cVar1;
  uint uVar2;
  uint uVar3;
  uint local_34;
  uint local_2c;
  uint local_14;
  uint local_10;
  
  local_14 = 0;
  local_10 = 0;
  local_34 = param_3 * 7;
  for (; cVar1 = *param_1, cVar1 != '\0'; param_1 = param_1 + 1) {
    uVar2 = (local_10 >> 0x1c | local_14 << 4) ^ (int)cVar1;
    uVar3 = (local_14 >> 0x1c | local_10 << 4) ^ (int)cVar1 >> 0x1f;
    local_10 = uVar2 >> 0x1f | uVar3 * 2;
    local_14 = (uVar3 >> 0x1f | uVar2 * 2) ^ local_34;
    local_34 = local_34 + param_3;
  }
  local_2c = param_3 * 0x27;
  for (; cVar1 = *param_2, cVar1 != '\0'; param_2 = param_2 + 1) {
    uVar2 = (local_10 >> 0x1d | local_14 << 3) ^ (int)cVar1;
    uVar3 = (local_14 >> 0x1d | local_10 << 3) ^ (int)cVar1 >> 0x1f;
    local_10 = uVar2 >> 0x1f | uVar3 * 2;
    local_14 = (uVar3 >> 0x1f | uVar2 * 2) ^ local_2c;
    local_2c = local_2c + param_3 * 3;
  }
  if (local_10 == 0 && local_14 == 0) {
    local_14 = 1;
    local_10 = 0;
  }
  else {
    local_10 = local_10 & 0xfffffff;
  }
  return CONCAT44(local_10,local_14);
}


// ==== _RT3_LicenseCodeToText @ 0002c1e9 ====

void _RT3_LicenseCodeToText(uint param_1,uint param_2,undefined1 *param_3)

{
  byte bVar1;
  uint uVar2;
  undefined1 *puVar3;
  int unaff_EBX;
  uint local_1c;
  int local_18;
  
  ___i686_get_pc_thunk_bx();
  if (param_3 != (undefined1 *)0x0) {
    local_18 = 4;
    local_1c = 0;
    bVar1 = 0x37;
    do {
      uVar2 = param_1 >> (bVar1 & 0x1f) | (param_2 & 0xfffffff) << 0x20 - (bVar1 & 0x1f);
      if ((bVar1 & 0x20) != 0) {
        uVar2 = (param_2 & 0xfffffff) >> (bVar1 & 0x1f);
      }
      *param_3 = *(undefined1 *)(unaff_EBX + 0x8189 + (uVar2 & 0x1f));
      puVar3 = param_3 + 1;
      local_18 = local_18 + -1;
      if (local_18 == 0) {
        param_3[1] = -(local_1c < 0xb) & 0x2d;
        puVar3 = param_3 + 2;
        local_18 = 4;
      }
      local_1c = local_1c + 1;
      bVar1 = bVar1 - 5;
      param_3 = puVar3;
    } while (local_1c != 0xc);
  }
  return;
}


// ==== _RT3_LicenseCodeEnswizzle @ 0002c286 ====

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
  uVar2 = ((uVar4 | param_4 >> 6 & 1) << 4 | param_2 >> 4 & 0xf) * 2;
  uVar8 = (((((((uVar5 & 0xfffffff0 | (uVar6 & 0x7fffff) >> 0x13) << 1 | (uVar3 & 0xfffffff) >> 0x1b
               ) << 4 | (uVar3 & 0x7ffffff) >> 0x17) << 4 | (uVar8 & 0xfffffff) >> 0x18) << 1 |
            (uVar8 & 0xffffff) >> 0x17) << 4 | (uVar8 & 0x7fffff) >> 0x13) << 1 |
          (uVar4 & 0xfffffff) >> 0x1b) << 4 | (uVar4 & 0x7ffffff) >> 0x17;
  uVar5 = (uVar2 | param_4 >> 7) << 4 | param_3 & 0xf;
  local_a8 = 0;
  uVar6 = 0;
  do {
    bVar1 = (byte)uVar6 & 0x1f;
    uVar4 = uVar5 >> bVar1 | uVar8 << 0x20 - bVar1;
    if ((uVar6 & 0x20) != 0) {
      uVar4 = uVar8 >> ((byte)uVar6 & 0x1f);
    }
    local_a8 = local_a8 + (uVar4 & 7);
    uVar6 = uVar6 + 3;
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


// ==== _RT3_LicenseCodeDeswizzle @ 0002c698 ====

undefined4
_RT3_LicenseCodeDeswizzle
          (uint param_1,uint param_2,ushort *param_3,ushort *param_4,ushort *param_5,byte *param_6)

{
  uint uVar1;
  byte bVar2;
  uint uVar3;
  uint uVar4;
  undefined4 uVar5;
  uint uVar6;
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
  uVar1 = param_1 >> 3;
  uVar3 = uVar1 | param_2 << 0x1d;
  uVar8 = uVar7 >> 3;
  uVar9 = 0;
  uVar6 = 0;
  do {
    bVar2 = (byte)uVar6 & 0x1f;
    uVar4 = uVar3 >> bVar2 | uVar8 << 0x20 - bVar2;
    if ((uVar6 & 0x20) != 0) {
      uVar4 = uVar8 >> ((byte)uVar6 & 0x1f);
    }
    uVar9 = uVar9 + (uVar4 & 7);
    uVar6 = uVar6 + 3;
  } while (uVar6 != 0x39);
  if ((param_1 & 7) == (uVar9 & 7)) {
    if (param_5 != (ushort *)0x0) {
      local_14 = (ushort)uVar1;
      *param_5 = *param_5 | local_14 & 0xf;
    }
    if (param_6 != (byte *)0x0) {
      *param_6 = *param_6 | (char)(uVar3 >> 4) << 7;
    }
    if (param_4 != (ushort *)0x0) {
      *param_4 = *param_4 | (ushort)(((uVar1 & 0x1e0) >> 5) << 4);
    }
    if (param_6 != (byte *)0x0) {
      *param_6 = *param_6 | ((byte)(uVar3 >> 9) & 1) << 6;
    }
    if (param_3 != (ushort *)0x0) {
      *param_3 = *param_3 | (ushort)(((uVar1 & 0x3c00) >> 10) << 8);
    }
    if (param_5 != (ushort *)0x0) {
      *param_5 = *param_5 | (ushort)((uVar3 >> 0xe) << 0xc);
    }
    if (param_6 != (byte *)0x0) {
      *param_6 = *param_6 | ((byte)(uVar3 >> 0x12) & 1) << 5;
    }
    if (param_4 != (ushort *)0x0) {
      *param_4 = *param_4 | (ushort)(uVar3 >> 0x13) & 0xf;
    }
    if (param_6 != (byte *)0x0) {
      *param_6 = *param_6 | ((byte)(uVar3 >> 0x17) & 1) << 4;
    }
    if (param_3 != (ushort *)0x0) {
      *param_3 = *param_3 | (ushort)(((uVar1 & 0xf000000) >> 0x18) << 4);
    }
    if (param_5 != (ushort *)0x0) {
      *param_5 = *param_5 | (ushort)((uVar3 >> 0x1c) << 8);
    }
    if (param_6 != (byte *)0x0) {
      *param_6 = *param_6 | ((byte)uVar8 & 1) << 3;
    }
    if (param_4 != (ushort *)0x0) {
      *param_4 = *param_4 | (ushort)((uVar7 >> 4) << 0xc);
    }
    if (param_6 != (byte *)0x0) {
      *param_6 = *param_6 | ((byte)(uVar7 >> 8) & 1) << 2;
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
    if (param_3 != (ushort *)0x0) {
      *param_3 = *param_3 | (ushort)((uVar7 >> 0x17) << 0xc);
    }
    uVar5 = 1;
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
    if (param_6 != (byte *)0x0) {
      *param_6 = 0;
    }
    uVar5 = 0;
  }
  return uVar5;
}


// ==== _RT3_CalcLicenseChecksum @ 0002c98e ====

ulonglong _RT3_CalcLicenseChecksum(uint param_1,uint param_2)

{
  byte bVar1;
  uint uVar2;
  uint uVar3;
  uint uVar4;
  uint uVar5;
  uint uVar6;
  undefined4 local_10;
  
  uVar6 = (param_2 & 0x7ffffff) >> 3;
  local_10 = 0;
  uVar3 = 0;
  do {
    bVar1 = (byte)uVar3 & 0x1f;
    uVar4 = uVar6 >> ((byte)uVar3 & 0x1f);
    uVar2 = (param_1 >> 3 | param_2 << 0x1d) >> bVar1 | uVar6 << 0x20 - bVar1;
    uVar5 = uVar4;
    if ((uVar3 & 0x20) != 0) {
      uVar5 = 0;
      uVar2 = uVar4;
    }
    local_10 = local_10 + (uVar2 & 7);
    uVar3 = uVar3 + 3;
  } while (uVar3 != 0x39);
  return CONCAT44(uVar5,local_10) & 0xffffffff00000007;
}


// ==== _RT3_ExtractLicenseChecksum @ 0002c9e4 ====

uint _RT3_ExtractLicenseChecksum(uint param_1)

{
  return param_1 & 7;
}


// ==== _RT3_ExtractLicenseTimestamp @ 0002c9ef ====

uint _RT3_ExtractLicenseTimestamp(uint param_1,uint param_2)

{
  uint uVar1;
  
  uVar1 = param_1 >> 0xc;
  return (param_1 >> 7 & 1) << 7 | (uVar1 & 1) << 6 | ((uVar1 & 0x200) >> 9) << 5 |
         ((uVar1 & 0x4000) >> 0xe) << 4 | ((param_2 << 0x14 & 0x800000) >> 0x17) << 3 |
         ((param_2 << 0x14 & 0x10000000) >> 0x1c) << 2 | ((param_2 >> 0xc & 0x20) >> 5) * 2 |
         (param_2 >> 0x15 & 2) >> 1;
}


// ==== _RT3_ExtractLicenseBlock1 @ 0002ca81 ====

uint _RT3_ExtractLicenseBlock1(uint param_1,uint param_2)

{
  return (param_1 >> 0xd & 0xf) << 8 | (param_1 >> 0x1b & 0xf) << 4 | (param_2 & 0x1e00) >> 9 |
         ((param_2 & 0x7ffffff) >> 0x17) << 0xc;
}


// ==== _RT3_ExtractLicenseBlock2 @ 0002cad0 ====

uint _RT3_ExtractLicenseBlock2(uint param_1,uint param_2)

{
  return (param_1 >> 8 & 0xf) << 4 | param_1 >> 0x16 & 0xf | ((param_2 & 0xf0) >> 4) << 0xc |
         ((param_2 & 0x3fffff) >> 0x12) << 8;
}


// ==== _RT3_ExtractLicenseBlock3 @ 0002cb1f ====

uint _RT3_ExtractLicenseBlock3(uint param_1,uint param_2)

{
  return param_1 >> 3 & 0xf | (param_1 >> 0x11 & 0xf) << 0xc |
         ((param_1 >> 0x11 | param_2 << 0xf) >> 0xe & 0xf) << 8 | ((param_2 & 0x1ffff) >> 0xd) << 4;
}


// ==== _RT3_GetTimePeriod @ 0002cb67 ====

uint _RT3_GetTimePeriod(void)

{
  uint uVar1;
  
  uVar1 = _TimerGetUTCSeconds();
  if (uVar1 < 0x3a500ed0) {
    uVar1 = 0;
  }
  else {
    uVar1 = (uVar1 + 0xc5b92bb0) / 0x127500;
  }
  return uVar1 & 0xff;
}


// ==== _RT3_LicenseTextToCode @ 0002cb94 ====

void _RT3_LicenseTextToCode(byte *param_1,uint *param_2)

{
  byte bVar1;
  int iVar2;
  char *pcVar3;
  undefined1 *puVar4;
  int unaff_EBX;
  int iVar5;
  undefined1 *puVar6;
  uint local_24;
  uint local_20;
  uint local_18;
  
  ___i686_get_pc_thunk_bx();
  if (*(char *)(unaff_EBX + 0xb7a2) == '\0') {
    iVar5 = 0;
    puVar4 = *(undefined1 **)(unaff_EBX + 0x1250e);
    puVar6 = puVar4;
    do {
      *puVar6 = 0xff;
      iVar2 = 0;
      pcVar3 = (char *)(unaff_EBX + 0x77de);
      do {
        if (*pcVar3 == iVar5) {
          *puVar6 = (char)iVar2;
        }
        iVar2 = iVar2 + 1;
        pcVar3 = pcVar3 + 1;
      } while (iVar2 != 0x20);
      iVar5 = iVar5 + 1;
      puVar6 = puVar6 + 1;
    } while (iVar5 != 0x100);
    iVar5 = *(int *)(unaff_EBX + 0x1250e);
    do {
      puVar4[0x61] = puVar4[0x41];
      puVar4 = puVar4 + 1;
    } while ((undefined1 *)(iVar5 + 0x1a) != puVar4);
    *(undefined1 *)(unaff_EBX + 0xb7a2) = 1;
  }
  if ((param_1 == (byte *)0x0) || (param_2 == (uint *)0x0)) {
    local_24 = 0;
    local_20 = 0;
  }
  else {
    local_24 = 0;
    local_20 = 0;
    local_18 = 0;
    do {
      if (*param_1 == 0) break;
      bVar1 = *(byte *)(*(int *)(unaff_EBX + 0x1250e) + (uint)*param_1);
      if (bVar1 != 0xff) {
        local_20 = local_20 << 5 | local_24 >> 0x1b;
        local_24 = local_24 << 5 | (uint)bVar1;
        local_18 = local_18 + 1;
      }
      param_1 = param_1 + 1;
    } while (local_18 < 0xc);
  }
  *param_2 = local_24;
  param_2[1] = local_20;
  return;
}


// ==== _EncodeParameterSafe @ 0002cca2 ====

void __regparm3 _EncodeParameterSafe(byte *param_1,byte *param_2,uint param_3)

{
  byte bVar1;
  byte bVar2;
  uint local_10;
  
  local_10 = param_3;
  while (3 < local_10) {
    bVar2 = *param_2;
    param_2 = param_2 + 1;
    if (bVar2 == 0) break;
    if (((((byte)(bVar2 - 0x21) < 0x5f) && (bVar2 != 0x26)) && (bVar2 != 0x25)) && (bVar2 != 0x2f))
    {
      *param_1 = bVar2;
      param_1 = param_1 + 1;
      local_10 = local_10 - 1;
    }
    else {
      bVar1 = bVar2 >> 4;
      bVar2 = bVar2 & 0xf;
      *param_1 = 0x25;
      if (bVar1 < 10) {
        bVar1 = bVar1 + 0x30;
      }
      else {
        bVar1 = bVar1 + 0x37;
      }
      param_1[1] = bVar1;
      if (bVar2 < 10) {
        bVar2 = bVar2 + 0x30;
      }
      else {
        bVar2 = bVar2 + 0x37;
      }
      param_1[2] = bVar2;
      param_1 = param_1 + 3;
      local_10 = local_10 - 3;
    }
  }
  *param_1 = 0;
  return;
}


// ==== _RenewLicenseTCP @ 0002cd25 ====

int _RenewLicenseTCP(char *param_1,char *param_2,char *param_3,char *param_4,char *param_5,
                    char *param_6,undefined1 *param_7,undefined1 *param_8)

{
  uint uVar1;
  int iVar2;
  int iVar3;
  undefined4 uVar4;
  char *pcVar5;
  int unaff_EBX;
  undefined1 *local_888;
  undefined1 local_864 [1024];
  undefined1 local_464 [260];
  undefined1 local_360 [256];
  undefined1 local_260 [256];
  undefined1 local_160 [256];
  undefined1 local_60 [32];
  undefined1 local_40 [16];
  undefined1 local_30 [16];
  undefined1 *local_20 [4];
  
  ___i686_get_pc_thunk_bx();
  local_20[0] = (undefined1 *)0x0;
  *param_7 = 0;
  *param_8 = 0;
  if ((((*param_3 == '\0') || (*param_4 == '\0')) || (*param_5 == '\0')) ||
     (((*param_6 == '\0' || (uVar1 = _StringGetLength(param_6), uVar1 < 0xc)) || (*param_5 == '\0'))
     )) {
    iVar2 = -0x1b59;
    goto LAB_0002d1be;
  }
  _MemoryClear(local_40,0x10);
  _MemoryClear(local_30,0x10);
  if ((param_2 == (char *)0x0) || (*param_2 == '\0')) {
    param_2 = param_1;
  }
  iVar2 = _SimpleResolve(0,param_2,local_464);
  if ((((iVar2 != 0) || (iVar2 = _QueueCreate(local_40), iVar2 != 0)) ||
      (iVar2 = _QueueCreate(local_30), iVar2 != 0)) ||
     (iVar2 = _NetworkQueueFill(local_40,3,4,0x400), iVar2 != 0)) goto LAB_0002d1be;
  iVar3 = _StreamCreate(0,0,0,local_40,local_40,local_30,local_30);
  if (iVar3 == 0) {
    iVar2 = -0x1b5c;
    goto LAB_0002d1be;
  }
  iVar2 = _StreamOpenClient(iVar3,0,local_464,10000);
  if (iVar2 == 0) {
    _EncodeParameterSafe();
    _EncodeParameterSafe();
    _EncodeParameterSafe();
    _EncodeParameterSafe();
    _StringFormatSafe(local_864,0x400,unaff_EBX + 0x6206,param_1,local_260,local_360,local_60,
                      local_160);
    iVar2 = _QueueRemove(local_40);
    if (iVar2 == 0) {
      iVar2 = -0x1b5c;
    }
    else {
      _StringCopy(iVar2 + 0x1c,local_864);
      uVar4 = _StringGetLength(local_864);
      *(undefined4 *)(iVar2 + 0x18) = uVar4;
      iVar2 = _StreamSend(iVar3,iVar2);
      if (iVar2 == 0) {
        local_864[0] = 0;
        local_20[0] = (undefined1 *)0x0;
        do {
          do {
            iVar2 = _StringGetLength(local_864);
            if (0x3ff < iVar2 + 1U) goto LAB_0002d09a;
            iVar2 = _NetworkQueueWait(local_30,10);
            if (iVar2 == 0) {
              iVar2 = -0x1b60;
              goto LAB_0002d1b0;
            }
            if (*(uint *)(iVar2 + 0x14) <= *(uint *)(iVar2 + 0x18)) {
              *(uint *)(iVar2 + 0x18) = *(uint *)(iVar2 + 0x14) - 1;
            }
            *(undefined1 *)(*(int *)(iVar2 + 0x18) + 0x1c + iVar2) = 0;
            _StringAppendSafe(local_864,iVar2 + 0x1c,0x400);
            _QueueInsert(local_40,iVar2);
            param_5 = (char *)_StringFindString(local_864,unaff_EBX + 0x625a);
          } while (param_5 == (char *)0x0);
          param_5 = param_5 + 4;
          local_20[0] = (undefined1 *)_StringFindString(param_5,unaff_EBX + 0x6262);
        } while (local_20[0] == (undefined1 *)0x0);
LAB_0002d09a:
        _StreamClose(iVar3,1);
        if (local_20[0] == (undefined1 *)0x0) {
          iVar2 = unaff_EBX + 0x6266;
LAB_0002d0ca:
          _StringCopy(param_8,iVar2);
        }
        else {
          if (*param_5 == '<') {
            iVar2 = unaff_EBX + 0x628e;
            goto LAB_0002d0ca;
          }
          *local_20[0] = 0;
          _MemoryCopy(local_864,param_5,local_20[0] + (1 - (int)param_5));
          local_20[0] = (undefined1 *)0x0;
          iVar2 = _StringTokenize(local_864,9,local_20);
          if (iVar2 != 0) {
            _StringCopySafe(param_7,iVar2,0x100);
          }
          pcVar5 = (char *)_StringTokenize(local_864,9,local_20);
          if (pcVar5 != (char *)0x0) {
            iVar2 = _StringGetLength(pcVar5);
            if ((*pcVar5 == '<') && (pcVar5[iVar2 + -1] == '>')) {
              pcVar5[iVar2 + -1] = '\0';
              pcVar5 = pcVar5 + 1;
            }
            _StringCopySafe(param_8,pcVar5,0x100);
          }
        }
        iVar2 = 0;
      }
    }
  }
LAB_0002d1b0:
  _StreamDispose(iVar3);
LAB_0002d1be:
  local_888 = local_40;
  _QueueEmpty(local_30);
  _QueueDispose(local_30);
  _QueueEmpty(local_888);
  _QueueDispose(local_888);
  return iVar2;
}


// ==== _RenewLicenseUDP @ 0002d1f7 ====

int _RenewLicenseUDP(undefined4 param_1,char *param_2,char *param_3,char *param_4,char *param_5,
                    undefined1 *param_6,undefined1 *param_7)

{
  uint uVar1;
  int iVar2;
  int iVar3;
  undefined4 uVar4;
  int iVar5;
  int unaff_EBX;
  undefined1 *local_564;
  undefined1 local_544 [1024];
  undefined1 local_144 [260];
  undefined1 local_40 [16];
  undefined1 local_30 [16];
  undefined4 local_20 [4];
  
  ___i686_get_pc_thunk_bx();
  *param_6 = 0;
  *param_7 = 0;
  if (((((*param_2 == '\0') || (*param_3 == '\0')) || (*param_4 == '\0')) ||
      ((*param_5 == '\0' || (uVar1 = _StringGetLength(param_5), uVar1 < 0xc)))) ||
     (*param_4 == '\0')) {
    iVar2 = -0x1b59;
  }
  else {
    _MemoryClear(local_30,0x10);
    _MemoryClear(local_40,0x10);
    iVar2 = _SimpleResolve(0,param_1,local_144);
    if (((iVar2 == 0) && (iVar2 = _QueueCreate(local_30), iVar2 == 0)) &&
       ((iVar2 = _QueueCreate(local_40), iVar2 == 0 &&
        (iVar2 = _NetworkQueueFill(local_30,2,4,0x400), iVar2 == 0)))) {
      iVar3 = _DatagramCreate(0,0,0,local_30,local_30,local_40,local_40);
      if (iVar3 == 0) {
        iVar2 = -0x1b5c;
      }
      else {
        iVar2 = _DatagramOpen(iVar3,0);
        if (iVar2 == 0) {
          _StringFormatSafe(local_544,0x400,unaff_EBX + 0x5de8,param_2,param_3,param_4,param_5);
          iVar2 = _QueueRemove(local_30);
          if (iVar2 == 0) {
            iVar2 = -0x1b5c;
          }
          else {
            _AddressDuplicate(iVar2 + 0x14,local_144);
            _StringCopy(iVar2 + 0x120,local_544);
            uVar4 = _StringGetLength(local_544);
            *(undefined4 *)(iVar2 + 0x11c) = uVar4;
            iVar2 = _DatagramSend(iVar3,iVar2);
            if (iVar2 == 0) {
              iVar2 = _NetworkQueueWait(local_40,5);
              if (iVar2 == 0) {
                iVar2 = -0x1b60;
              }
              else {
                if (*(uint *)(iVar2 + 0x118) <= *(uint *)(iVar2 + 0x11c)) {
                  *(uint *)(iVar2 + 0x11c) = *(uint *)(iVar2 + 0x118) - 1;
                }
                *(undefined1 *)(*(int *)(iVar2 + 0x11c) + 0x120 + iVar2) = 0;
                local_20[0] = 0;
                iVar5 = _StringTokenize(iVar2 + 0x120,9,local_20);
                if (iVar5 != 0) {
                  _StringCopySafe(param_6,iVar5,0x100);
                }
                iVar5 = _StringTokenize(iVar2 + 0x120,9,local_20);
                if (iVar5 != 0) {
                  _StringCopySafe(param_7,iVar5,0x100);
                }
                _QueueInsert(local_30,iVar2);
                iVar2 = 0;
              }
            }
          }
        }
        _DatagramDispose(iVar3);
      }
    }
  }
  local_564 = local_30;
  _QueueEmpty(local_40);
  _QueueDispose(local_40);
  _QueueEmpty(local_564);
  _QueueDispose(local_564);
  return iVar2;
}


// ==== _GetPathToSystemPreferences @ 0002d562 ====

int _GetPathToSystemPreferences(undefined4 param_1)

{
  char cVar1;
  short sVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  uint uVar6;
  int iVar7;
  int local_70;
  int local_68;
  undefined1 local_5c [80];
  
  sVar2 = _FSFindFolder(0xffff8003,0x70726566,1,local_5c);
  if ((sVar2 != 0) || (iVar3 = _CFURLCreateFromFSRef(0,local_5c), iVar3 == 0)) {
    return 0;
  }
  iVar4 = _CFStringCreateWithCString(0,param_1,0x600);
  if (iVar4 == 0) {
    local_70 = 0;
LAB_0002d605:
    local_68 = 0;
  }
  else {
    local_70 = _CFURLCreateCopyAppendingPathComponent(0,iVar3,iVar4,0);
    if (local_70 == 0) goto LAB_0002d605;
    local_68 = _CFURLCopyFileSystemPath(local_70,0);
    if (local_68 != 0) {
      iVar5 = _CFStringGetLength(local_68);
      iVar7 = 0;
      uVar6 = 1;
      do {
        uVar6 = uVar6 + iVar5;
        if (iVar7 != 0) {
          _MemoryDeallocate(iVar7);
        }
        iVar7 = 0;
      } while (((uVar6 <= iVar5 + 5U) && (iVar7 = _MemoryAllocate(uVar6), iVar7 != 0)) &&
              (cVar1 = _CFStringGetCString(local_68,iVar7,uVar6,0x8000100), cVar1 == '\0'));
      goto LAB_0002d6c3;
    }
  }
  iVar7 = 0;
LAB_0002d6c3:
  _CFRelease(iVar3);
  if (local_70 != 0) {
    _CFRelease(local_70);
  }
  if (iVar4 != 0) {
    _CFRelease(iVar4);
  }
  if (local_68 != 0) {
    _CFRelease(local_68);
  }
  return iVar7;
}


// ==== _WriteToFileAsSuperUser @ 0002d6e0 ====

int _WriteToFileAsSuperUser(undefined4 param_1,void *param_2,size_t param_3)

{
  int iVar1;
  size_t sVar2;
  int unaff_EBX;
  int local_34 [5];
  undefined4 local_20;
  undefined4 local_1c;
  int *local_18;
  FILE *local_14;
  int local_10;
  
  ___i686_get_pc_thunk_bx();
  local_10 = 0;
  local_34[0] = unaff_EBX + 0x590f;
  local_34[1] = 0;
  local_34[2] = 0;
  local_34[3] = 0;
  local_20 = 0;
  local_14 = (FILE *)0x0;
  local_1c = 1;
  local_18 = local_34;
  local_34[4] = param_1;
  iVar1 = _AuthorizationCreate(0,0,0,&local_10);
  if (((iVar1 == 0) && (iVar1 = _AuthorizationCopyRights(local_10,&local_1c,0,0x13,0), iVar1 == 0))
     && (iVar1 = _AuthorizationExecuteWithPrivileges
                           (local_10,unaff_EBX + 0x5927,0,local_34 + 4,&local_14), iVar1 == 0)) {
    sVar2 = _fwrite(param_2,1,param_3,local_14);
    iVar1 = ((int)param_3 <= (int)sVar2) - 1;
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


// ==== __ClockInitialize @ 0002d825 ====

void __ClockInitialize(void)

{
  int iVar1;
  int iVar2;
  int unaff_EBX;
  undefined8 uVar3;
  
  ___i686_get_pc_thunk_bx();
  if (*(char *)(unaff_EBX + 0xab16) == '\0') {
    _MemoryClear(unaff_EBX + 0xab2e,0x10);
    _MemoryClear(unaff_EBX + 0xab3e,0x10);
    _MemoryClear(unaff_EBX + 0xab4e,0x10);
    _MemoryClear(unaff_EBX + 0xab5e,0x10);
    _TimerGetMicroseconds();
    _TimerGetMicroseconds();
    iVar1 = _TimerGetUTCSeconds();
    do {
      iVar2 = _TimerGetUTCSeconds();
    } while (iVar1 == iVar2);
    uVar3 = _TimerGetMicroseconds();
    uVar3 = ___umoddi3(uVar3,1000000,0);
    *(undefined8 *)(unaff_EBX + 0xab26) = uVar3;
    *(undefined1 *)(unaff_EBX + 0xab16) = 1;
  }
  return;
}


// ==== _ClockMakeWideSeconds @ 0002d8ec ====

undefined8 _ClockMakeWideSeconds(undefined4 param_1,uint param_2,int param_3)

{
  double dVar1;
  undefined1 auVar2 [12];
  undefined4 uVar3;
  int unaff_EBX;
  double dVar4;
  double dVar5;
  undefined4 local_5c;
  
  ___i686_get_pc_thunk_bx();
  if (*(char *)(unaff_EBX + 0xaa4e) == '\0') {
    __ClockInitialize();
  }
  uVar3 = ___umoddi3(param_2 - *(uint *)(unaff_EBX + 0xaa5e),
                     (param_3 - *(int *)(unaff_EBX + 0xaa62)) -
                     (uint)(param_2 < *(uint *)(unaff_EBX + 0xaa5e)),1000000,0);
  auVar2._4_4_ = uVar3;
  auVar2._0_4_ = uVar3;
  auVar2._8_4_ = *(undefined4 *)(unaff_EBX + 0x65ea);
  dVar4 = ((((double)((ulonglong)*(uint *)(unaff_EBX + 0x65e6) << 0x20) -
            *(double *)(unaff_EBX + 0x65f6)) + (auVar2._4_8_ - *(double *)(unaff_EBX + 0x65fe))) *
          *(double *)(unaff_EBX + 0x66ce)) / *(double *)(unaff_EBX + 0x66d6);
  dVar1 = *(double *)(unaff_EBX + 0x6606);
  dVar5 = dVar4;
  if (*(double *)(unaff_EBX + 0x6616) <= dVar4) {
    dVar5 = *(double *)(unaff_EBX + 0x6616);
  }
  if (dVar5 <= 0.0) {
    dVar5 = 0.0;
  }
  local_5c = (uint)(dVar1 <= dVar4) * -0x80000000 ^
             (int)(dVar5 - (double)((ulonglong)dVar1 & -(ulonglong)(dVar1 <= dVar4)));
  return CONCAT44(param_1,local_5c);
}


// ==== _ClockGetWideSeconds @ 0002d9e9 ====

void _ClockGetWideSeconds(void)

{
  undefined4 uVar1;
  int unaff_EBX;
  undefined8 uVar2;
  
  ___i686_get_pc_thunk_bx();
  if (*(char *)(unaff_EBX + 0xa952) == '\0') {
    __ClockInitialize();
  }
  uVar1 = _TimerGetUTCSeconds();
  uVar2 = _TimerGetMicroseconds();
  _ClockMakeWideSeconds(uVar1,uVar2);
  return;
}


// ==== __ClockSendPacket @ 0002da27 ====

void __ClockSendPacket(void)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int unaff_EBX;
  uint uVar4;
  uint uVar5;
  undefined8 uVar6;
  ulonglong uVar7;
  int local_24;
  
  iVar2 = ___i686_get_pc_thunk_bx();
  if (1 < *(int *)(iVar2 + 0x234) - 2U) {
    return;
  }
  *(undefined4 *)(iVar2 + 0x234) = 3;
  if (2 < *(uint *)(iVar2 + 0x230)) {
    iVar3 = -0x1b60;
    goto LAB_0002da67;
  }
  iVar1 = unaff_EBX + 0xa948;
  local_24 = _QueueRemove(iVar1);
  if (local_24 == 0) {
    iVar3 = _NetworkQueueFill(iVar1,2,4,0x30);
    if (iVar3 != 0) goto LAB_0002da67;
    local_24 = _QueueRemove(iVar1);
    if (local_24 == 0) {
      iVar3 = -0x1b5c;
      goto LAB_0002da67;
    }
  }
  _AddressDuplicate(local_24 + 0x14,iVar2 + 4);
  *(undefined4 *)(local_24 + 0x11c) = 0x30;
  _MemoryClear(local_24 + 0x120,0x30);
  uVar6 = _TimerGetMilliseconds();
  *(undefined8 *)(iVar2 + 0x224) = uVar6;
  *(int *)(iVar2 + 0x230) = *(int *)(iVar2 + 0x230) + 1;
  *(undefined1 *)(local_24 + 0x120) = 0x23;
  *(undefined1 *)(local_24 + 0x121) = 4;
  *(undefined1 *)(local_24 + 0x122) = 10;
  *(undefined1 *)(local_24 + 0x123) = 0xfa;
  uVar7 = _ClockGetWideSeconds();
  uVar4 = (uint)(uVar7 >> 0x20);
  uVar5 = (uint)uVar7;
  *(ulonglong *)(iVar2 + 0x21c) = uVar7;
  uVar4 = uVar4 >> 0x18 | uVar4 >> 8 & 0xff00 | (int)((uVar7 & 0xff0000ff0000) >> 0x20) << 8 |
          uVar4 << 0x18;
  uVar5 = uVar5 >> 0x18 | (uint)(uVar7 & 0xff0000ff0000) >> 8 | (uVar5 & 0xff00) << 8 |
          uVar5 << 0x18;
  *(uint *)(local_24 + 0x138) = uVar4;
  *(uint *)(local_24 + 0x13c) = uVar5;
  *(uint *)(local_24 + 0x148) = uVar4;
  *(uint *)(local_24 + 0x14c) = uVar5;
  *(uint *)(local_24 + 0x140) = uVar4;
  *(uint *)(local_24 + 0x144) = uVar5;
  iVar3 = _DatagramSend(*(undefined4 *)(_MenuHandler + unaff_EBX + 7),local_24);
  if (iVar3 == 0) {
    return;
  }
  _QueueInsert(iVar1,local_24);
LAB_0002da67:
  if (*(int **)(iVar2 + 0x208) != (int *)0x0) {
    **(int **)(iVar2 + 0x208) = iVar3;
  }
  *(int *)(iVar2 + 0x20c) = iVar3;
  *(undefined4 *)(iVar2 + 0x234) = 5;
  return;
}


// ==== __ClockNetworkCallback @ 0002dd55 ====

void __ClockNetworkCallback(undefined4 param_1,undefined4 param_2,ushort param_3)

{
  int *piVar1;
  uint uVar2;
  uint uVar3;
  undefined4 *puVar4;
  undefined4 uVar5;
  char cVar6;
  short sVar7;
  uint uVar8;
  int iVar9;
  int unaff_EBX;
  uint uVar10;
  int iVar11;
  int *piVar12;
  undefined8 uVar13;
  int local_40;
  undefined4 *local_30;
  undefined4 local_24;
  short local_1e [7];
  
  ___i686_get_pc_thunk_bx();
  if (param_3 == 9) {
    while (iVar9 = _QueueRemove(unaff_EBX + 0xa60a), iVar9 != 0) {
      iVar11 = *(int *)(iVar9 + 0x10);
      if (*(int *)(iVar11 + 0x234) == 1) {
        *(undefined4 *)(iVar11 + 0x234) = 2;
        cVar6 = _AddressIsEmpty(iVar9 + 0x14);
        if (cVar6 == '\0') {
          _AddressDecomposeTCPIP(iVar9 + 0x14,local_1e,&local_24);
          sVar7 = local_1e[0];
          if (local_1e[0] == 0) {
            sVar7 = 0x7b00;
          }
          _AddressComposeTCPIP(iVar11 + 4,sVar7,local_24);
          __ClockSendPacket();
          goto LAB_0002de85;
        }
        local_40 = -0x1bc4;
      }
      else {
LAB_0002de85:
        local_40 = 0;
      }
      _QueueInsert(unaff_EBX + 0xa5fa,iVar9);
      if (local_40 != 0) {
        if (*(int **)(iVar11 + 0x208) != (int *)0x0) {
          **(int **)(iVar11 + 0x208) = local_40;
        }
        *(int *)(iVar11 + 0x20c) = local_40;
        *(undefined4 *)(iVar11 + 0x234) = 5;
      }
    }
  }
  else if (param_3 < 10) {
    if (param_3 == 2) {
      piVar1 = (int *)(unaff_EBX + 0xa5e6);
      while (piVar12 = piVar1, piVar1 = (int *)*piVar12, piVar1 != (int *)0x0) {
        if (piVar1[0x8d] == 3) {
          uVar13 = _TimerGetMilliseconds();
          if (((int)((ulonglong)uVar13 >> 0x20) - piVar1[0x8a] !=
               (uint)((uint)uVar13 < (uint)piVar1[0x89])) || (3999 < (uint)uVar13 - piVar1[0x89])) {
            __ClockSendPacket();
          }
          piVar1 = (int *)*piVar12;
        }
        else if ((piVar1[0x8d] == 5) && ((char)piVar1[0x8b] == '\0')) {
          *piVar12 = *piVar1;
          _MemoryDeallocate(piVar1);
          piVar1 = (int *)(unaff_EBX + 0xa5e6);
        }
      }
    }
  }
  else if ((ushort)(param_3 - 0xc) < 2) {
    while (iVar9 = _QueueRemove(unaff_EBX + 0xa62a), iVar9 != 0) {
      uVar13 = _ClockGetWideSeconds();
      if (((*(uint *)(iVar9 + 0x11c) < 0x30) || ((*(byte *)(iVar9 + 0x120) & 0x3f) != 0x24)) ||
         (*(int *)(iVar9 + 0x13c) == 0 && *(int *)(iVar9 + 0x138) == 0)) {
        iVar11 = -0x1b59;
        local_30 = (undefined4 *)0x0;
      }
      else {
        uVar2 = *(uint *)(iVar9 + 0x124);
        *(uint *)(iVar9 + 0x124) =
             uVar2 >> 0x18 | uVar2 >> 8 & 0xff00 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
        uVar2 = *(uint *)(iVar9 + 0x128);
        *(uint *)(iVar9 + 0x128) =
             uVar2 >> 0x18 | uVar2 >> 8 & 0xff00 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
        uVar2 = *(uint *)(iVar9 + 300);
        *(uint *)(iVar9 + 300) =
             uVar2 >> 0x18 | uVar2 >> 8 & 0xff00 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
        uVar2 = *(uint *)(iVar9 + 0x130);
        uVar3 = *(uint *)(iVar9 + 0x134);
        *(uint *)(iVar9 + 0x130) =
             uVar3 >> 0x18 | uVar3 >> 8 & 0xff00 | (uVar3 & 0xff00) << 8 | uVar3 << 0x18;
        *(uint *)(iVar9 + 0x134) =
             uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
        uVar2 = *(uint *)(iVar9 + 0x138);
        uVar3 = *(uint *)(iVar9 + 0x13c);
        *(uint *)(iVar9 + 0x138) =
             uVar3 >> 0x18 | uVar3 >> 8 & 0xff00 | (uVar3 & 0xff00) << 8 | uVar3 << 0x18;
        *(uint *)(iVar9 + 0x13c) =
             uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
        uVar2 = *(uint *)(iVar9 + 0x140);
        uVar3 = *(uint *)(iVar9 + 0x144);
        *(uint *)(iVar9 + 0x140) =
             uVar3 >> 0x18 | uVar3 >> 8 & 0xff00 | (uVar3 & 0xff00) << 8 | uVar3 << 0x18;
        *(uint *)(iVar9 + 0x144) =
             uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
        uVar2 = *(uint *)(iVar9 + 0x148);
        uVar3 = *(uint *)(iVar9 + 0x14c);
        *(uint *)(iVar9 + 0x148) =
             uVar3 >> 0x18 | uVar3 >> 8 & 0xff00 | (uVar3 & 0xff00) << 8 | uVar3 << 0x18;
        *(uint *)(iVar9 + 0x14c) =
             uVar2 >> 0x18 | (uVar2 & 0xff0000) >> 8 | (uVar2 & 0xff00) << 8 | uVar2 << 0x18;
        for (local_30 = *(undefined4 **)(unaff_EBX + 0xa5e6); local_30 != (undefined4 *)0x0;
            local_30 = (undefined4 *)*local_30) {
          if (*(int *)(iVar9 + 0x13c) == local_30[0x88] && local_30[0x87] == *(int *)(iVar9 + 0x138)
             ) {
            if (local_30[0x8d] == 3) {
              local_30[0x8d] = 4;
              if ((undefined8 *)local_30[0x86] != (undefined8 *)0x0) {
                *(undefined8 *)local_30[0x86] = uVar13;
              }
              puVar4 = (undefined4 *)local_30[0x85];
              if (puVar4 != (undefined4 *)0x0) {
                uVar5 = local_30[0x88];
                *puVar4 = local_30[0x87];
                puVar4[1] = uVar5;
              }
              piVar1 = (int *)local_30[0x84];
              uVar2 = *(uint *)(iVar9 + 0x144);
              uVar10 = *(uint *)(iVar9 + 0x140) >> 1 | uVar2 << 0x1f;
              uVar3 = *(uint *)(iVar9 + 0x14c);
              uVar8 = *(uint *)(iVar9 + 0x148) >> 1 | uVar3 << 0x1f;
              *piVar1 = uVar10 + uVar8;
              piVar1[1] = (uVar2 >> 1) + (uVar3 >> 1) + (uint)CARRY4(uVar10,uVar8);
              local_30[0x8d] = 5;
            }
            break;
          }
        }
        iVar11 = 0;
      }
      _QueueInsert(unaff_EBX + 0xa61a,iVar9);
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


// ==== _ClockQueryDispose @ 0002e3f5 ====

void _ClockQueryDispose(void)

{
  undefined4 *puVar1;
  int unaff_EBX;
  
  ___i686_get_pc_thunk_bx();
  _SystemCheckCallback();
  if (*(int *)(unaff_EBX + 0x9f51) != 0) {
    _ResolverClose(*(int *)(unaff_EBX + 0x9f51));
    _ResolverDispose(*(undefined4 *)(unaff_EBX + 0x9f51));
    *(undefined4 *)(unaff_EBX + 0x9f51) = 0;
    _NetworkQueueEmpty(unaff_EBX + 0x9f5d);
    _NetworkQueueEmpty(unaff_EBX + 0x9f6d);
    _QueueDispose(unaff_EBX + 0x9f5d);
    _QueueDispose(unaff_EBX + 0x9f6d);
  }
  if (*(int *)(unaff_EBX + 0x9f4d) != 0) {
    _DatagramClose(*(int *)(unaff_EBX + 0x9f4d),0);
    _DatagramDispose(*(undefined4 *)(unaff_EBX + 0x9f4d));
    *(undefined4 *)(unaff_EBX + 0x9f4d) = 0;
    _NetworkQueueEmpty(unaff_EBX + 0x9f7d);
    _NetworkQueueEmpty(unaff_EBX + 0x9f8d);
    _QueueDispose(unaff_EBX + 0x9f7d);
    _QueueDispose(unaff_EBX + 0x9f8d);
  }
  while (puVar1 = *(undefined4 **)(unaff_EBX + 0x9f49), puVar1 != (undefined4 *)0x0) {
    *(undefined4 *)(unaff_EBX + 0x9f49) = *puVar1;
    if ((puVar1[0x8d] != 5) && ((undefined4 *)puVar1[0x82] != (undefined4 *)0x0)) {
      *(undefined4 *)puVar1[0x82] = 0xffffe4a1;
    }
    _MemoryDeallocate(puVar1);
  }
  *(undefined1 *)(unaff_EBX + 0x9f45) = 0;
  return;
}


// ==== _ClockQueryServer @ 0002e501 ====

int _ClockQueryServer(char *param_1,int param_2,undefined4 *param_3,undefined4 *param_4,
                     undefined4 *param_5,int *param_6)

{
  int iVar1;
  char cVar2;
  int iVar3;
  undefined4 *puVar4;
  int iVar5;
  uint uVar6;
  int unaff_EBX;
  int local_20;
  
  ___i686_get_pc_thunk_bx();
  _SystemCheckCallback();
  if ((param_1 == (char *)0x0) || (*param_1 == '\0')) {
    param_1 = (char *)(unaff_EBX + 0x4b15);
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
  if (*(char *)(unaff_EBX + 0x9e39) == '\0') {
    __ClockInitialize();
  }
  cVar2 = _NetworkStackGetLoaded(0);
  if ((cVar2 == '\0') && (iVar3 = _NetworkStackLoad(1), iVar3 != 0)) {
LAB_0002e8f7:
    if (param_2 == 0) goto LAB_0002e91f;
  }
  else {
    _SystemSetQuitProc(unaff_EBX + -0x11a);
    if (*(int *)(unaff_EBX + 0x9e45) == 0) {
      iVar5 = unaff_EBX + 0x9e51;
      iVar3 = _QueueCreate(iVar5);
      if (iVar3 == 0) {
        iVar3 = _QueueCreate(unaff_EBX + 0x9e61);
        if ((iVar3 == 0) && (iVar3 = _NetworkQueueFill(iVar5,1,4,0x218), iVar3 == 0)) {
          iVar3 = _ResolverCreate(0,0,unaff_EBX + -0x7ba,unaff_EBX + 0x9e61,iVar5);
          *(int *)(unaff_EBX + 0x9e45) = iVar3;
          if (iVar3 == 0) goto LAB_0002e8f2;
          iVar3 = _ResolverOpen(iVar3);
          if (iVar3 == 0) goto LAB_0002e660;
        }
      }
      goto LAB_0002e8f7;
    }
LAB_0002e660:
    if (*(int *)(unaff_EBX + 0x9e41) == 0) {
      iVar5 = unaff_EBX + 0x9e71;
      iVar3 = _QueueCreate(iVar5);
      if (iVar3 == 0) {
        iVar1 = unaff_EBX + 0x9e81;
        iVar3 = _QueueCreate(iVar1);
        if ((iVar3 == 0) && (iVar3 = _NetworkQueueFill(iVar5,2,4,0x30), iVar3 == 0)) {
          iVar3 = _DatagramCreate(0,0,unaff_EBX + -0x7ba,iVar5,iVar5,iVar1,iVar1);
          *(int *)(unaff_EBX + 0x9e41) = iVar3;
          if (iVar3 == 0) goto LAB_0002e8f2;
          _DatagramControl(iVar3,0,0x6000,1);
          iVar3 = _DatagramOpen(*(undefined4 *)(unaff_EBX + 0x9e41),0);
          if (iVar3 == 0) goto LAB_0002e741;
        }
      }
      goto LAB_0002e8f7;
    }
LAB_0002e741:
    puVar4 = (undefined4 *)_MemoryAllocate(0x238);
    if (puVar4 == (undefined4 *)0x0) {
LAB_0002e8f2:
      iVar3 = -0x1b5c;
      goto LAB_0002e8f7;
    }
    _MemoryClear(puVar4,0x238);
    _StringCopySafe(puVar4 + 0x42,param_1,0x100);
    puVar4[0x82] = param_6;
    puVar4[0x84] = param_5;
    puVar4[0x85] = param_3;
    puVar4[0x86] = param_4;
    *(bool *)(puVar4 + 0x8b) = param_2 != 0;
    *puVar4 = *(undefined4 *)(unaff_EBX + 0x9e3d);
    *(undefined4 **)(unaff_EBX + 0x9e3d) = puVar4;
    if (puVar4[0x8d] == 0) {
      puVar4[0x8d] = 1;
      iVar3 = unaff_EBX + 0x9e51;
      iVar5 = _QueueRemove(iVar3);
      if (iVar5 == 0) {
        local_20 = _NetworkQueueFill(iVar3,2,4,0x30);
        if (local_20 == 0) {
          iVar5 = _QueueRemove(iVar3);
          if (iVar5 != 0) goto LAB_0002e830;
          local_20 = -0x1b5c;
        }
      }
      else {
LAB_0002e830:
        _AddressComposeEmpty(iVar5 + 0x14);
        _StringCopySafe(iVar5 + 0x118,puVar4 + 0x42,0x100);
        *(undefined4 **)(iVar5 + 0x10) = puVar4;
        local_20 = _ResolveName(*(undefined4 *)(unaff_EBX + 0x9e45),iVar5);
        if (local_20 == 0) goto LAB_0002e89b;
        _QueueInsert(iVar3,iVar5);
      }
      if ((int *)puVar4[0x82] != (int *)0x0) {
        *(int *)puVar4[0x82] = local_20;
      }
      puVar4[0x83] = local_20;
      puVar4[0x8d] = 5;
    }
LAB_0002e89b:
    if (param_2 == 0) {
      iVar3 = 0;
      goto LAB_0002e91f;
    }
    iVar3 = _TimerGetUTCSeconds();
    while ((uVar6 = _TimerGetUTCSeconds(), uVar6 < (uint)(param_2 + iVar3) && (puVar4[0x8d] != 5)))
    {
      _SystemIdle();
    }
    if ((((int *)puVar4[0x84])[1] == 0 && *(int *)puVar4[0x84] == 0) && (puVar4[0x83] == 0)) {
      iVar3 = -0x1b60;
    }
    else {
      iVar3 = puVar4[0x83];
    }
    if (*(undefined4 **)(unaff_EBX + 0x9e3d) == puVar4) {
      *(undefined4 *)(unaff_EBX + 0x9e3d) = **(undefined4 **)(unaff_EBX + 0x9e3d);
    }
    _MemoryDeallocate(puVar4);
  }
  if (*(int *)(unaff_EBX + 0x9e3d) == 0) {
    _ClockQueryDispose();
  }
LAB_0002e91f:
  if (param_6 != (int *)0x0) {
    *param_6 = iVar3;
  }
  return iVar3;
}


// ==== _GetHTTPSProxy @ 0002e95e ====

/* WARNING: Type propagation algorithm not settling */

int _GetHTTPSProxy(char *param_1,undefined1 *param_2,undefined1 *param_3)

{
  char cVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  uint uVar6;
  int unaff_EBX;
  undefined1 *local_170;
  undefined1 local_158;
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
  int local_2c [7];
  
  ___i686_get_pc_thunk_bx();
  local_30 = 0;
  local_2c[2] = 0;
  local_158 = *(undefined1 *)(unaff_EBX + 0xd35);
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
    iVar3 = _CFDictionaryGetValue(iVar2,unaff_EBX + 0x5c81);
    if (iVar3 != 0) {
      iVar4 = _CFGetTypeID(iVar3);
      iVar5 = _CFNumberGetTypeID();
      if (iVar4 == iVar5) {
        _CFNumberGetValue(iVar3,9,&local_30);
      }
    }
    if (local_30 != 0) {
      iVar3 = _CFDictionaryGetValue(iVar2,unaff_EBX + 0x5c91);
      if (iVar3 != 0) {
        iVar4 = _CFGetTypeID(iVar3);
        iVar5 = _CFStringGetTypeID();
        if (iVar4 == iVar5) {
          _CFStringGetCString(iVar3,&local_158,0x100,0x600);
        }
      }
      local_170 = &local_158;
      iVar3 = _CFDictionaryGetValue(iVar2,unaff_EBX + 0x5ca1);
      if (iVar3 != 0) {
        iVar4 = _CFGetTypeID(iVar3);
        iVar5 = _CFNumberGetTypeID();
        if (iVar4 == iVar5) {
          _CFNumberGetValue(iVar3,9,local_2c + 2);
        }
      }
      if (local_2c[2] == 0) {
        iVar3 = unaff_EBX + 0x46f5;
      }
      else {
        iVar3 = unaff_EBX + 0x46ed;
      }
      _StringFormatSafe(param_1,0x100,iVar3,local_170,local_2c[2]);
    }
    _CFRelease(iVar2);
  }
  cVar1 = _SystemMacOSXOrLater();
  if ((((cVar1 != '\0') && (*param_1 != '\0')) && (param_2 != (undefined1 *)0x0)) &&
     (param_3 != (undefined1 *)0x0)) {
    local_34 = 0;
    local_38 = 0;
    local_2c[0] = 0;
    local_2c[3] = 0;
    local_2c[1] = 0x68747378;
    local_58 = 0x73727672;
    local_50 = param_1;
    local_54 = _StringGetLength(param_1);
    local_4c = 0x7074636c;
    local_44 = local_2c + 1;
    local_48 = 4;
    local_40 = 2;
    local_3c = &local_58;
    iVar2 = _SecKeychainSearchCreateFromAttributes(0,0x696e6574,&local_40,&local_34);
    if (iVar2 == 0) {
      iVar2 = 0;
      while (iVar3 = _SecKeychainSearchCopyNext(local_34,&local_38), iVar3 == 0) {
        local_58 = 0x61636374;
        local_40 = 1;
        local_3c = &local_58;
        iVar2 = _SecKeychainItemCopyContent(local_38,0,&local_40,local_2c + 3,local_2c);
        if (iVar2 == -0x62cd) {
          return -0x1b5f;
        }
        if ((iVar2 == 0) && (local_2c[0] != 0)) {
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
        return iVar2;
      }
      _CFRelease(local_34);
      return iVar2;
    }
  }
  return 0;
}


// ==== _GetNoProxyList @ 0002ed18 ====

int _GetNoProxyList(undefined1 *param_1)

{
  short sVar1;
  int iVar2;
  undefined4 uVar3;
  int unaff_EBX;
  int iVar4;
  byte *pbVar5;
  undefined4 *local_3c4;
  int local_3c0;
  undefined1 local_3ae [256];
  undefined1 local_2ae [256];
  undefined1 local_1ae [256];
  undefined1 local_ae [70];
  undefined4 local_68;
  undefined1 *local_64;
  undefined4 local_54;
  undefined1 *local_30;
  undefined4 local_2c;
  undefined4 local_28;
  undefined1 local_24 [4];
  int local_20 [4];
  
  ___i686_get_pc_thunk_bx();
  local_20[0] = 0;
  if (param_1 != (undefined1 *)0x0) {
    *param_1 = 0;
  }
  iVar2 = _HashCreate(0x2000001);
  if (iVar2 == 0) {
    iVar4 = -0x1b5c;
  }
  else {
    local_2c = 0;
    local_28 = 2;
    if (*(int *)(unaff_EBX + 0x567b) == -1) {
      local_68 = 0x3c;
      local_30 = local_ae;
      local_64 = local_2ae;
      sVar1 = _GetProcessInformation(&local_2c,&local_68);
      if (sVar1 == 0) {
        *(undefined4 *)(unaff_EBX + 0x567b) = local_54;
      }
      else {
        *(undefined4 *)(unaff_EBX + 0x567b) = 0x3f3f3f3f;
      }
    }
    iVar4 = _ICStart(local_20,*(undefined4 *)(unaff_EBX + 0x567b));
    if ((iVar4 == 0) && (iVar4 = _ICBegin(local_20[0],1), iVar4 == 0)) {
      local_3c4 = (undefined4 *)_NewHandle(0);
      if (local_3c4 == (undefined4 *)0x0) {
        iVar4 = -0x1b5c;
      }
      else {
        uVar3 = _C2PStringCopy(local_3ae,unaff_EBX + 0x433f);
        iVar4 = _ICFindPrefHandle(local_20[0],uVar3,local_24,local_3c4);
        if (iVar4 == 0) {
          _HLockHi(local_3c4);
          sVar1 = *(short *)*local_3c4;
          pbVar5 = (byte *)((short *)*local_3c4 + 1);
          for (local_3c0 = 0; sVar1 != local_3c0; local_3c0 = local_3c0 + 1) {
            if (*pbVar5 != 0) {
              _P2CStringCopy(local_1ae,pbVar5);
              iVar4 = _HashLookup(iVar2,local_1ae,0);
              if ((iVar4 == 0) &&
                 (iVar4 = _HashAppend(iVar2,local_1ae,unaff_EBX + 0x97b), iVar4 != 0))
              goto LAB_0002ef11;
            }
            pbVar5 = pbVar5 + *pbVar5 + 1;
          }
        }
        iVar4 = 0;
      }
      goto LAB_0002ef11;
    }
    iVar4 = 0;
  }
  local_3c4 = (undefined4 *)0x0;
LAB_0002ef11:
  if (param_1 != (undefined1 *)0x0) {
    *param_1 = 0;
  }
  if (local_3c4 != (undefined4 *)0x0) {
    _DisposeHandle(local_3c4);
  }
  if (local_20[0] != 0) {
    _ICStop(local_20[0]);
  }
  if ((iVar4 == -0x1b5c) && (iVar2 != 0)) {
    _HashDispose(iVar2);
    iVar2 = 0;
  }
  return iVar2;
}


// ==== _GetSOCKSServer @ 0002ef78 ====

/* WARNING: Type propagation algorithm not settling */

int _GetSOCKSServer(char *param_1,undefined1 *param_2,undefined1 *param_3)

{
  char cVar1;
  short sVar2;
  int iVar3;
  undefined4 uVar4;
  undefined1 *puVar5;
  int iVar6;
  int unaff_EBX;
  uint uVar7;
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
  
  ___i686_get_pc_thunk_bx();
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
  if (*(int *)(unaff_EBX + 0x541b) == -1) {
    local_84 = 0x3c;
    local_4c = local_ca;
    local_80 = local_2ca;
    sVar2 = _GetProcessInformation(&local_48,&local_84);
    if (sVar2 == 0) {
      *(int **)(unaff_EBX + 0x541b) = local_70;
    }
    else {
      *(undefined4 *)(unaff_EBX + 0x541b) = 0x3f3f3f3f;
    }
  }
  iVar3 = _ICStart(local_3c + 4,*(undefined4 *)(unaff_EBX + 0x541b));
  if (iVar3 == 0) {
    iVar3 = _ICBegin(local_3c[4],1);
    if (iVar3 == 0) {
      local_3c[5] = 1;
      uVar4 = _C2PStringCopy(local_1ca,unaff_EBX + 0x40ef);
      iVar3 = _ICGetPref(local_3c[4],uVar4,local_24,local_1d,local_3c + 5);
      if ((iVar3 == 0) && (local_1d[0] != '\0')) {
        local_3c[5] = 0x100;
        uVar4 = _C2PStringCopy(local_1ca,unaff_EBX + 0x40fb);
        iVar3 = _ICGetPref(local_3c[4],uVar4,local_24,local_3ca,local_3c + 5);
        if ((iVar3 == 0) && (local_3ca[0] != '\0')) {
          _P2CStringCopy(param_1,local_3ca);
        }
      }
    }
  }
  cVar1 = _SystemMacOSXOrLater();
  if ((((cVar1 != '\0') && (*param_1 != '\0')) && (param_2 != (undefined1 *)0x0)) &&
     (param_3 != (undefined1 *)0x0)) {
    local_3c[3] = 0;
    local_3c[2] = 0;
    local_3c[0] = 0;
    local_40 = 0;
    local_3c[1] = 0x736f7820;
    local_84 = 0x73727672;
    local_7c = param_1;
    local_80 = (undefined1 *)_StringGetLength(param_1);
    local_78 = 0x7074636c;
    local_70 = local_3c + 1;
    local_74 = 4;
    local_48 = 2;
    local_44 = &local_84;
    iVar3 = _SecKeychainSearchCreateFromAttributes(0,0x696e6574,&local_48,local_3c + 3);
    if (iVar3 == 0) {
      iVar3 = 0;
      while( true ) {
        iVar6 = _SecKeychainSearchCopyNext(local_3c[3],local_3c + 2);
        if (iVar6 != 0) break;
        local_84 = 0x61636374;
        local_48 = 1;
        local_44 = &local_84;
        iVar3 = _SecKeychainItemCopyContent(local_3c[2],0,&local_48,&local_40,local_3c);
        if (iVar3 == -0x62cd) {
          iVar3 = -0x1b5f;
          goto LAB_0002f2f1;
        }
        if ((iVar3 == 0) && (local_3c[0] != 0)) {
          puVar5 = (undefined1 *)0xff;
          if (local_80 < (undefined1 *)0x100) {
            puVar5 = local_80;
          }
          local_80 = puVar5;
          _StringCopySafe(param_2,local_7c,puVar5 + 1);
          uVar7 = 0xff;
          if (local_40 < 0x100) {
            uVar7 = local_40;
          }
          local_40 = uVar7;
          _StringCopySafe(param_3,local_3c[0],uVar7 + 1);
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
      goto LAB_0002f2f1;
    }
  }
  iVar3 = 0;
LAB_0002f2f1:
  if (local_3c[4] != 0) {
    _ICStop(local_3c[4]);
  }
  return iVar3;
}


// ==== _GetHTTPProxy @ 0002f30d ====

/* WARNING: Type propagation algorithm not settling */

int _GetHTTPProxy(char *param_1,undefined1 *param_2,undefined1 *param_3)

{
  char cVar1;
  short sVar2;
  int iVar3;
  undefined4 uVar4;
  undefined1 *puVar5;
  int iVar6;
  int unaff_EBX;
  uint uVar7;
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
  
  ___i686_get_pc_thunk_bx();
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
  if (*(int *)(unaff_EBX + 0x5086) == -1) {
    local_84 = 0x3c;
    local_4c = local_ca;
    local_80 = local_2ca;
    sVar2 = _GetProcessInformation(&local_48,&local_84);
    if (sVar2 == 0) {
      *(int **)(unaff_EBX + 0x5086) = local_70;
    }
    else {
      *(undefined4 *)(unaff_EBX + 0x5086) = 0x3f3f3f3f;
    }
  }
  iVar3 = _ICStart(local_3c + 4,*(undefined4 *)(unaff_EBX + 0x5086));
  if (iVar3 == 0) {
    iVar3 = _ICBegin(local_3c[4],1);
    if (iVar3 == 0) {
      local_3c[5] = 1;
      uVar4 = _C2PStringCopy(local_1ca,unaff_EBX + 0x3d72);
      iVar3 = _ICGetPref(local_3c[4],uVar4,local_24,local_1d,local_3c + 5);
      if ((iVar3 == 0) && (local_1d[0] != '\0')) {
        local_3c[5] = 0x100;
        uVar4 = _C2PStringCopy(local_1ca,unaff_EBX + 0x3d82);
        iVar3 = _ICGetPref(local_3c[4],uVar4,local_24,local_3ca,local_3c + 5);
        if ((iVar3 == 0) && (local_3ca[0] != '\0')) {
          _P2CStringCopy(param_1,local_3ca);
        }
      }
    }
  }
  cVar1 = _SystemMacOSXOrLater();
  if ((((cVar1 != '\0') && (*param_1 != '\0')) && (param_2 != (undefined1 *)0x0)) &&
     (param_3 != (undefined1 *)0x0)) {
    local_3c[3] = 0;
    local_3c[2] = 0;
    local_3c[0] = 0;
    local_40 = 0;
    local_3c[1] = 0x68747078;
    local_84 = 0x73727672;
    local_7c = param_1;
    local_80 = (undefined1 *)_StringGetLength(param_1);
    local_78 = 0x7074636c;
    local_70 = local_3c + 1;
    local_74 = 4;
    local_48 = 2;
    local_44 = &local_84;
    iVar3 = _SecKeychainSearchCreateFromAttributes(0,0x696e6574,&local_48,local_3c + 3);
    if (iVar3 == 0) {
      iVar3 = 0;
      while( true ) {
        iVar6 = _SecKeychainSearchCopyNext(local_3c[3],local_3c + 2);
        if (iVar6 != 0) break;
        local_84 = 0x61636374;
        local_48 = 1;
        local_44 = &local_84;
        iVar3 = _SecKeychainItemCopyContent(local_3c[2],0,&local_48,&local_40,local_3c);
        if (iVar3 == -0x62cd) {
          iVar3 = -0x1b5f;
          goto LAB_0002f686;
        }
        if ((iVar3 == 0) && (local_3c[0] != 0)) {
          puVar5 = (undefined1 *)0xff;
          if (local_80 < (undefined1 *)0x100) {
            puVar5 = local_80;
          }
          local_80 = puVar5;
          _StringCopySafe(param_2,local_7c,puVar5 + 1);
          uVar7 = 0xff;
          if (local_40 < 0x100) {
            uVar7 = local_40;
          }
          local_40 = uVar7;
          _StringCopySafe(param_3,local_3c[0],uVar7 + 1);
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
      goto LAB_0002f686;
    }
  }
  iVar3 = 0;
LAB_0002f686:
  if (local_3c[4] != 0) {
    _ICStop(local_3c[4]);
  }
  return iVar3;
}


// ==== ___i686.get_pc_thunk.bx @ 000330b0 ====

void ___i686_get_pc_thunk_bx(void)

{
  return;
}


// ==== ___i686.get_pc_thunk.dx @ 000330b4 ====

void ___i686_get_pc_thunk_dx(void)

{
  return;
}


// ==== ___i686.get_pc_thunk.cx @ 000330b8 ====

void ___i686_get_pc_thunk_cx(void)

{
  return;
}


// ==== _exit @ 0003f104 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

void _exit(int param_1)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== ___keymgr_dwarf2_register_sections @ 0003f109 ====

void ___keymgr_dwarf2_register_sections(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _dlopen @ 0003f10e ====

void _dlopen(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== __keymgr_get_and_lock_processwide_ptr @ 0003f113 ====

void __keymgr_get_and_lock_processwide_ptr(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _free @ 0003f118 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

void _free(void *param_1)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _malloc @ 0003f11d ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

void * _malloc(size_t param_1)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== __keymgr_set_and_unlock_processwide_ptr @ 0003f122 ====

void __keymgr_set_and_unlock_processwide_ptr(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _dlsym @ 0003f127 ====

void _dlsym(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== __keymgr_get_and_lock_processwide_ptr_2 @ 0003f12c ====

void __keymgr_get_and_lock_processwide_ptr_2(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _calloc @ 0003f131 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

void * _calloc(size_t param_1,size_t param_2)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _OffsetRect @ 0003f136 ====

void _OffsetRect(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _MoveHHi @ 0003f13b ====

void _MoveHHi(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HLock @ 0003f140 ====

void _HLock(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetCIcon @ 0003f145 ====

void _GetCIcon(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _UnionRect @ 0003f14a ====

void _UnionRect(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ReleaseResource @ 0003f14f ====

void _ReleaseResource(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetResource @ 0003f154 ====

void _GetResource(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetHandleSize @ 0003f159 ====

void _GetHandleSize(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _memmove @ 0003f15e ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

void * _memmove(void *param_1,void *param_2,size_t param_3)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HNoPurge @ 0003f163 ====

void _HNoPurge(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _sprintf @ 0003f168 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

int _sprintf(char *param_1,char *param_2,...)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _Gestalt @ 0003f16d ====

void _Gestalt(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetCurrentProcess @ 0003f172 ====

void _GetCurrentProcess(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _strncpy @ 0003f177 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

char * _strncpy(char *param_1,char *param_2,size_t param_3)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetProcessInformation @ 0003f17c ====

void _GetProcessInformation(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CopyBits @ 0003f181 ====

void _CopyBits(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetPortBitMapForCopyBits @ 0003f186 ====

void _GetPortBitMapForCopyBits(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetWindowPort @ 0003f18b ====

void _GetWindowPort(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetPortBounds @ 0003f190 ====

void _GetPortBounds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFBundleCopyPrivateFrameworksURL @ 0003f195 ====

void _CFBundleCopyPrivateFrameworksURL(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringAppendSafe @ 0003f19a ====

void _StringAppendSafe(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFBundleGetFunctionPointerForName @ 0003f19f ====

void _CFBundleGetFunctionPointerForName(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFBundleCreate @ 0003f1a4 ====

void _CFBundleCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ParamText @ 0003f1a9 ====

void _ParamText(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _Get1Resource @ 0003f1ae ====

void _Get1Resource(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGDisplayFade @ 0003f1b3 ====

void _CGDisplayFade(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _memcpy @ 0003f1b8 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

void * _memcpy(void *param_1,void *param_2,size_t param_3)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSOpenResourceFile @ 0003f1bd ====

void _FSOpenResourceFile(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFURLCreateCopyAppendingPathComponent @ 0003f1c2 ====

void _CFURLCreateCopyAppendingPathComponent(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSFindFolder @ 0003f1c7 ====

void _FSFindFolder(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FT_Close @ 0003f1cc ====

void _FT_Close(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ST_Close @ 0003f1d1 ====

void _ST_Close(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetSeconds @ 0003f1d6 ====

void _TimerGetSeconds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NewAEEventHandlerUPP @ 0003f1db ====

void _NewAEEventHandlerUPP(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ExitToShell @ 0003f1e0 ====

void _ExitToShell(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFURLGetFSRef @ 0003f1e5 ====

void _CFURLGetFSRef(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AEInstallEventHandler @ 0003f1ea ====

void _AEInstallEventHandler(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TickCount @ 0003f1ef ====

void _TickCount(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _RunApplicationEventLoop @ 0003f1f4 ====

void _RunApplicationEventLoop(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetIndString @ 0003f1f9 ====

void _GetIndString(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSGetResourceForkName @ 0003f1fe ====

void _FSGetResourceForkName(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NumToString @ 0003f203 ====

void _NumToString(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IsPlatformOpen @ 0003f208 ====

void _IsPlatformOpen(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _PlatformOpen @ 0003f20d ====

void _PlatformOpen(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringCreateWithPascalString @ 0003f212 ====

void _CFStringCreateWithPascalString(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _MoreMasterPointers @ 0003f217 ====

void _MoreMasterPointers(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFRelease @ 0003f21c ====

void _CFRelease(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DisposeWindow @ 0003f221 ====

void _DisposeWindow(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFBundleCopyResourceURL @ 0003f226 ====

void _CFBundleCopyResourceURL(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetRect @ 0003f22b ====

void _SetRect(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DisposeAEEventHandlerUPP @ 0003f230 ====

void _DisposeAEEventHandlerUPP(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _QuitApplicationEventLoop @ 0003f235 ====

void _QuitApplicationEventLoop(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CurResFile @ 0003f23a ====

void _CurResFile(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetQDGlobalsScreenBits @ 0003f23f ====

void _GetQDGlobalsScreenBits(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FT_Open @ 0003f244 ====

void _FT_Open(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGReleaseDisplayFadeReservation @ 0003f249 ====

void _CGReleaseDisplayFadeReservation(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ST_GetSysVolume @ 0003f24e ====

void _ST_GetSysVolume(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringGetLength @ 0003f253 ====

void _StringGetLength(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFBundleGetMainBundle @ 0003f258 ====

void _CFBundleGetMainBundle(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ST_SetVolume @ 0003f25d ====

void _ST_SetVolume(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _PlatformClose @ 0003f262 ====

void _PlatformClose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGAcquireDisplayFadeReservation @ 0003f267 ====

void _CGAcquireDisplayFadeReservation(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSOpenFork @ 0003f26c ====

void _FSOpenFork(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FlushEvents @ 0003f271 ====

void _FlushEvents(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AEGetAttributePtr @ 0003f276 ====

void _AEGetAttributePtr(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFURLCreateFromFSRef @ 0003f27b ====

void _CFURLCreateFromFSRef(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StopAlert @ 0003f280 ====

void _StopAlert(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFBundleLoadExecutable @ 0003f285 ====

void _CFBundleLoadExecutable(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NewPtr @ 0003f28a ====

void _NewPtr(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DisposePtr @ 0003f28f ====

void _DisposePtr(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _MoveTo @ 0003f294 ====

void _MoveTo(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _RGBForeColor @ 0003f299 ====

void _RGBForeColor(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetQDGlobalsBlack @ 0003f29e ====

void _GetQDGlobalsBlack(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FillRect @ 0003f2a3 ====

void _FillRect(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetCPixel @ 0003f2a8 ====

void _SetCPixel(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _LineTo @ 0003f2ad ====

void _LineTo(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ForeColor @ 0003f2b2 ====

void _ForeColor(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _BackColor @ 0003f2b7 ====

void _BackColor(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DeleteMenuItem @ 0003f2bc ====

void _DeleteMenuItem(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetItemMark @ 0003f2c1 ====

void _SetItemMark(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SendEventToEventTarget @ 0003f2c6 ====

void _SendEventToEventTarget(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetMenuEventTarget @ 0003f2cb ====

void _GetMenuEventTarget(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _InsetRect @ 0003f2d0 ====

void _InsetRect(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _InvalWindowRect @ 0003f2d5 ====

void _InvalWindowRect(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetEventKind @ 0003f2da ====

void _GetEventKind(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringCreateWithFormat @ 0003f2df ====

void _CFStringCreateWithFormat(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AEProcessAppleEvent @ 0003f2e4 ====

void _AEProcessAppleEvent(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _InsertMenuItemTextWithCFString @ 0003f2e9 ====

void _InsertMenuItemTextWithCFString(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetMouse @ 0003f2ee ====

void _GetMouse(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _InsertMenuItem @ 0003f2f3 ====

void _InsertMenuItem(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FindWindow @ 0003f2f8 ====

void _FindWindow(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DrawString @ 0003f2fd ====

void _DrawString(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetMenuHandle @ 0003f302 ====

void _GetMenuHandle(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _EnableMenuCommand @ 0003f307 ====

void _EnableMenuCommand(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CopyCStringToPascal @ 0003f30c ====

void _CopyCStringToPascal(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _EnableMenuItem @ 0003f311 ====

void _EnableMenuItem(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetEventDispatcherTarget @ 0003f316 ====

void _GetEventDispatcherTarget(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _PenMode @ 0003f31b ====

void _PenMode(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ReceiveNextEvent @ 0003f320 ====

void _ReceiveNextEvent(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DisableMenuCommand @ 0003f325 ====

void _DisableMenuCommand(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringWidth @ 0003f32a ====

void _StringWidth(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CreateNewMenu @ 0003f32f ====

void _CreateNewMenu(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ShowWindow @ 0003f334 ====

void _ShowWindow(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CountMenuItems @ 0003f339 ====

void _CountMenuItems(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _strcat @ 0003f33e ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

char * _strcat(char *param_1,char *param_2)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _WaitNextEvent @ 0003f343 ====

void _WaitNextEvent(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringGetCString @ 0003f348 ====

void _CFStringGetCString(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _InstallEventHandler @ 0003f34d ====

void _InstallEventHandler(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetPicture @ 0003f352 ====

void _GetPicture(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _PtInRect @ 0003f357 ====

void _PtInRect(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DrawPicture @ 0003f35c ====

void _DrawPicture(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _MenuSelect @ 0003f361 ====

void _MenuSelect(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _OpColor @ 0003f366 ====

void _OpColor(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StillDown @ 0003f36b ====

void _StillDown(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ReleaseEvent @ 0003f370 ====

void _ReleaseEvent(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CreateNibReference @ 0003f375 ====

void _CreateNibReference(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DisableMenuItem @ 0003f37a ====

void _DisableMenuItem(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFBundleGetValueForInfoDictionaryKey @ 0003f37f ====

void _CFBundleGetValueForInfoDictionaryKey(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetEventClass @ 0003f384 ====

void _GetEventClass(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _PaintRect @ 0003f389 ====

void _PaintRect(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetMenuItemHierarchicalMenu @ 0003f38e ====

void _SetMenuItemHierarchicalMenu(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetMenuBarFromNib @ 0003f393 ====

void _SetMenuBarFromNib(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ConvertEventRefToEventRecord @ 0003f398 ====

void _ConvertEventRefToEventRecord(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GlobalToLocal @ 0003f39d ====

void _GlobalToLocal(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetMenuID @ 0003f3a2 ====

void _GetMenuID(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetEventParameter @ 0003f3a7 ====

void _GetEventParameter(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetGWorld @ 0003f3ac ====

void _SetGWorld(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HUnlock @ 0003f3b1 ====

void _HUnlock(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _QDGetPictureBounds @ 0003f3b6 ====

void _QDGetPictureBounds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HPurge @ 0003f3bb ====

void _HPurge(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _InitCursor @ 0003f3c0 ====

void _InitCursor(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DisposeDialog @ 0003f3c5 ====

void _DisposeDialog(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetNewDialog @ 0003f3ca ====

void _GetNewDialog(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetFNum @ 0003f3cf ====

void _GetFNum(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SndSoundManagerVersion @ 0003f3d4 ====

void _SndSoundManagerVersion(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _LocalToGlobal @ 0003f3d9 ====

void _LocalToGlobal(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NewPtrClear @ 0003f3de ====

void _NewPtrClear(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetCursor @ 0003f3e3 ====

void _SetCursor(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGWarpMouseCursorPosition @ 0003f3e8 ====

void _CGWarpMouseCursorPosition(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetTime @ 0003f3ed ====

void _GetTime(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetDialogDefaultItem @ 0003f3f2 ====

void _SetDialogDefaultItem(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGDisplayShowCursor @ 0003f3f7 ====

void _CGDisplayShowCursor(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetPort @ 0003f3fc ====

void _SetPort(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetKeys @ 0003f401 ====

void _GetKeys(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGDisplayHideCursor @ 0003f406 ====

void _CGDisplayHideCursor(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DateToSeconds @ 0003f40b ====

void _DateToSeconds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGMainDisplayID @ 0003f410 ====

void _CGMainDisplayID(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetNextProcess @ 0003f415 ====

void _GetNextProcess(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TextFont @ 0003f41a ====

void _TextFont(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _QDFlushPortBuffer @ 0003f41f ====

void _QDFlushPortBuffer(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetCurrentKeyModifiers @ 0003f424 ====

void _GetCurrentKeyModifiers(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetDialogWindow @ 0003f429 ====

void _GetDialogWindow(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _Delay @ 0003f42e ====

void _Delay(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DrawDialog @ 0003f433 ====

void _DrawDialog(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetCursor @ 0003f438 ====

void _GetCursor(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetPort @ 0003f43d ====

void _GetPort(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetMBarHeight @ 0003f442 ====

void _GetMBarHeight(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FMGetFontFamilyFromName @ 0003f447 ====

void _FMGetFontFamilyFromName(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ModalDialog @ 0003f44c ====

void _ModalDialog(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TextSize @ 0003f451 ====

void _TextSize(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _Random @ 0003f456 ====

void _Random(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetFrontProcess @ 0003f45b ====

void _GetFrontProcess(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SameProcess @ 0003f460 ====

void _SameProcess(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetControlTitle @ 0003f465 ====

void _SetControlTitle(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _BitAnd @ 0003f46a ====

void _BitAnd(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetPenState @ 0003f46f ====

void _GetPenState(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringToNum @ 0003f474 ====

void _StringToNum(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DeactivateControl @ 0003f479 ====

void _DeactivateControl(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetControlValue @ 0003f47e ====

void _GetControlValue(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FrameRoundRect @ 0003f483 ====

void _FrameRoundRect(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetPenState @ 0003f488 ====

void _SetPenState(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HiliteControl @ 0003f48d ====

void _HiliteControl(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetDialogPort @ 0003f492 ====

void _GetDialogPort(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetDialogItem @ 0003f497 ====

void _SetDialogItem(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AppendDITL @ 0003f49c ====

void _AppendDITL(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetWindowGroup @ 0003f4a1 ====

void _SetWindowGroup(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NoteAlert @ 0003f4a6 ====

void _NoteAlert(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetFontInfo @ 0003f4ab ====

void _GetFontInfo(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CopyPascalStringToC @ 0003f4b0 ====

void _CopyPascalStringToC(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetDialogItemText @ 0003f4b5 ====

void _GetDialogItemText(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetDialogTextEditHandle @ 0003f4ba ====

void _GetDialogTextEditHandle(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ShowDialogItem @ 0003f4bf ====

void _ShowDialogItem(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _PenPat @ 0003f4c4 ====

void _PenPat(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ReleaseWindowGroup @ 0003f4c9 ====

void _ReleaseWindowGroup(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HideDialogItem @ 0003f4ce ====

void _HideDialogItem(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGWindowLevelForKey @ 0003f4d3 ====

void _CGWindowLevelForKey(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SelectWindow @ 0003f4d8 ====

void _SelectWindow(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _PenSize @ 0003f4dd ====

void _PenSize(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _PlotCIconHandle @ 0003f4e2 ====

void _PlotCIconHandle(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetDialogItemText @ 0003f4e7 ====

void _SetDialogItemText(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetPortDialogPort @ 0003f4ec ====

void _SetPortDialogPort(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _PenNormal @ 0003f4f1 ====

void _PenNormal(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetWindowGroupLevel @ 0003f4f6 ====

void _SetWindowGroupLevel(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SelectDialogItemText @ 0003f4fb ====

void _SelectDialogItemText(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ShortenDITL @ 0003f500 ====

void _ShortenDITL(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ActivateControl @ 0003f505 ====

void _ActivateControl(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetDialogItem @ 0003f50a ====

void _GetDialogItem(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FrameRect @ 0003f50f ====

void _FrameRect(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetControlValue @ 0003f514 ====

void _SetControlValue(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGShieldingWindowLevel @ 0003f519 ====

void _CGShieldingWindowLevel(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetDialogCancelItem @ 0003f51e ====

void _SetDialogCancelItem(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CreateWindowGroup @ 0003f523 ====

void _CreateWindowGroup(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetControlMaximum @ 0003f528 ====

void _SetControlMaximum(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetDialogItemAsControl @ 0003f52d ====

void _GetDialogItemAsControl(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetControlPopupMenuHandle @ 0003f532 ====

void _GetControlPopupMenuHandle(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SysBeep @ 0003f537 ====

void _SysBeep(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NewModalFilterUPP @ 0003f53c ====

void _NewModalFilterUPP(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CountDITL @ 0003f541 ====

void _CountDITL(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DisposeModalFilterUPP @ 0003f546 ====

void _DisposeModalFilterUPP(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetMenuItemCommandKey @ 0003f54b ====

void _SetMenuItemCommandKey(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _RepositionWindow @ 0003f550 ====

void _RepositionWindow(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGDisplaySwitchToMode @ 0003f555 ====

void _CGDisplaySwitchToMode(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CreateNewWindow @ 0003f55a ====

void _CreateNewWindow(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetWindowBounds @ 0003f55f ====

void _SetWindowBounds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGDisplayBitsPerPixel @ 0003f564 ====

void _CGDisplayBitsPerPixel(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetMenuItemCommandKey @ 0003f569 ====

void _GetMenuItemCommandKey(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFNumberGetValue @ 0003f56e ====

void _CFNumberGetValue(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetIndMenuItemWithCommandID @ 0003f573 ====

void _GetIndMenuItemWithCommandID(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGCaptureAllDisplays @ 0003f578 ====

void _CGCaptureAllDisplays(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGDisplayCurrentMode @ 0003f57d ====

void _CGDisplayCurrentMode(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HideWindow @ 0003f582 ====

void _HideWindow(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetWindowBounds @ 0003f587 ====

void _GetWindowBounds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetWindowGroupOfClass @ 0003f58c ====

void _GetWindowGroupOfClass(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetWindowTitleWithCFString @ 0003f591 ====

void _SetWindowTitleWithCFString(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGDisplayBestModeForParameters @ 0003f596 ====

void _CGDisplayBestModeForParameters(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFDictionaryGetValue @ 0003f59b ====

void _CFDictionaryGetValue(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGReleaseAllDisplays @ 0003f5a0 ====

void _CGReleaseAllDisplays(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _memset @ 0003f5a5 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

void * _memset(void *param_1,int param_2,size_t param_3)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ShowCursor @ 0003f5aa ====

void _ShowCursor(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetGWorld @ 0003f5af ====

void _GetGWorld(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _LockPixels @ 0003f5b4 ====

void _LockPixels(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetGWorldPixMap @ 0003f5b9 ====

void _GetGWorldPixMap(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _UnlockPixels @ 0003f5be ====

void _UnlockPixels(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _EraseRect @ 0003f5c3 ====

void _EraseRect(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _PlotCIcon @ 0003f5c8 ====

void _PlotCIcon(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetPixRowBytes @ 0003f5cd ====

void _GetPixRowBytes(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetPixBaseAddr @ 0003f5d2 ====

void _GetPixBaseAddr(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGAssociateMouseAndMouseCursorPosition @ 0003f5d7 ====

void _CGAssociateMouseAndMouseCursorPosition(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _RemoveEventLoopTimer @ 0003f5dc ====

void _RemoveEventLoopTimer(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NewHandle @ 0003f5e1 ====

void _NewHandle(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ST_HaltSound @ 0003f5e6 ====

void _ST_HaltSound(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _RemoveResource @ 0003f5eb ====

void _RemoveResource(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DisposeEventLoopTimerUPP @ 0003f5f0 ====

void _DisposeEventLoopTimerUPP(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _BeginUpdate @ 0003f5f5 ====

void _BeginUpdate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetHandleSize @ 0003f5fa ====

void _SetHandleSize(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _InstallEventLoopTimer @ 0003f5ff ====

void _InstallEventLoopTimer(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NewEventLoopTimerUPP @ 0003f604 ====

void _NewEventLoopTimerUPP(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetQDGlobalsRandomSeed @ 0003f609 ====

void _GetQDGlobalsRandomSeed(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetQDGlobalsRandomSeed @ 0003f60e ====

void _SetQDGlobalsRandomSeed(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DisposeHandle @ 0003f613 ====

void _DisposeHandle(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CGDisplayBounds @ 0003f618 ====

void _CGDisplayBounds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _Microseconds @ 0003f61d ====

void _Microseconds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetMainEventLoop @ 0003f622 ====

void _GetMainEventLoop(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _EndUpdate @ 0003f627 ====

void _EndUpdate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _WriteResource @ 0003f62c ====

void _WriteResource(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AddResource @ 0003f631 ====

void _AddResource(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _Button @ 0003f636 ====

void _Button(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _BitTst @ 0003f63b ====

void _BitTst(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SndNewChannel @ 0003f640 ====

void _SndNewChannel(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetNamedResource @ 0003f645 ====

void _GetNamedResource(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SndPlay @ 0003f64a ====

void _SndPlay(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SndDoImmediate @ 0003f64f ====

void _SndDoImmediate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _strcpy @ 0003f654 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

char * _strcpy(char *param_1,char *param_2)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SndChannelStatus @ 0003f659 ====

void _SndChannelStatus(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ClipRect @ 0003f65e ====

void _ClipRect(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NewGWorld @ 0003f663 ====

void _NewGWorld(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DisposeGWorld @ 0003f668 ====

void _DisposeGWorld(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _RandomSeed @ 0003f66d ====

void _RandomSeed(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetIndPattern @ 0003f672 ====

void _GetIndPattern(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetCCursor @ 0003f677 ====

void _SetCCursor(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _GetCCursor @ 0003f67c ====

void _GetCCursor(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HideCursor @ 0003f681 ====

void _HideCursor(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ResError @ 0003f686 ====

void _ResError(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _Line @ 0003f68b ====

void _Line(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ST_Open @ 0003f690 ====

void _ST_Open(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ST_PlaySound @ 0003f695 ====

void _ST_PlaySound(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ST_LoadSndResource @ 0003f69a ====

void _ST_LoadSndResource(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSWrite @ 0003f69f ====

void _FSWrite(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SetFPos @ 0003f6a4 ====

void _SetFPos(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSCloseFork @ 0003f6a9 ====

void _FSCloseFork(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FindFolder @ 0003f6ae ====

void _FindFolder(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFURLCopyFileSystemPath @ 0003f6b3 ====

void _CFURLCopyFileSystemPath(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSDeleteObject @ 0003f6b8 ====

void _FSDeleteObject(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFURLCreateWithFileSystemPath @ 0003f6bd ====

void _CFURLCreateWithFileSystemPath(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSReadFork @ 0003f6c2 ====

void _FSReadFork(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSClose @ 0003f6c7 ====

void _FSClose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringCreateMutableCopy @ 0003f6cc ====

void _CFStringCreateMutableCopy(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringAppendPascalString @ 0003f6d1 ====

void _CFStringAppendPascalString(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HCreate @ 0003f6d6 ====

void _HCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringAppend @ 0003f6db ====

void _CFStringAppend(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSGetDataForkName @ 0003f6e0 ====

void _FSGetDataForkName(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSSetForkPosition @ 0003f6e5 ====

void _FSSetForkPosition(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HOpen @ 0003f6ea ====

void _HOpen(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CoreEndianInstallFlipper @ 0003f6ef ====

void _CoreEndianInstallFlipper(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFDataGetLength @ 0003f6f4 ====

void _CFDataGetLength(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectAppendData @ 0003f6f9 ====

void _IndirectAppendData(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectInitialize @ 0003f6fe ====

void _IndirectInitialize(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectDuplicate @ 0003f703 ====

void _IndirectDuplicate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SystemMacOSXOrLater @ 0003f708 ====

void _SystemMacOSXOrLater(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FT_FileGetFlags @ 0003f70d ====

void _FT_FileGetFlags(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringCopy @ 0003f712 ====

void _StringCopy(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _MemoryChecksum @ 0003f717 ====

void _MemoryChecksum(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FT_FileLoad @ 0003f71c ====

void _FT_FileLoad(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFDictionaryGetValueIfPresent @ 0003f721 ====

void _CFDictionaryGetValueIfPresent(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SystemLoadMachOSymbol @ 0003f726 ====

void _SystemLoadMachOSymbol(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringFromNumber @ 0003f72b ====

void _StringFromNumber(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SystemRunningAsAdmin @ 0003f730 ====

void _SystemRunningAsAdmin(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _getpwuid @ 0003f735 ====

void _getpwuid(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SystemSetIdleProc @ 0003f73a ====

void _SystemSetIdleProc(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectDeallocate @ 0003f73f ====

void _IndirectDeallocate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectSetSize @ 0003f744 ====

void _IndirectSetSize(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFPreferencesCopyValue @ 0003f749 ====

void _CFPreferencesCopyValue(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetTicks @ 0003f74e ====

void _TimerGetTicks(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringCompare @ 0003f753 ====

void _StringCompare(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectSetLock @ 0003f758 ====

void _IndirectSetLock(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FT_FileSetFlags @ 0003f75d ====

void _FT_FileSetFlags(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFArrayCreate @ 0003f762 ====

void _CFArrayCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetTickRate @ 0003f767 ====

void _TimerGetTickRate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFPreferencesSetValue @ 0003f76c ====

void _CFPreferencesSetValue(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetMicroseconds @ 0003f771 ====

void _TimerGetMicroseconds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFDictionaryCreateMutable @ 0003f776 ====

void _CFDictionaryCreateMutable(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringCreateWithCString @ 0003f77b ====

void _CFStringCreateWithCString(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _MemoryCopy @ 0003f780 ====

void _MemoryCopy(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FT_FileSave @ 0003f785 ====

void _FT_FileSave(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFDataGetBytePtr @ 0003f78a ====

void _CFDataGetBytePtr(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _getuid @ 0003f78f ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

uid_t _getuid(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetUTCSeconds @ 0003f794 ====

void _TimerGetUTCSeconds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFDataCreate @ 0003f799 ====

void _CFDataCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetElapsedSeconds @ 0003f79e ====

void _TimerGetElapsedSeconds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectAllocate @ 0003f7a3 ====

void _IndirectAllocate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NetworkStackGetActive @ 0003f7a8 ====

void _NetworkStackGetActive(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringCopySafe @ 0003f7ad ====

void _StringCopySafe(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SystemCreateMachOWrapper @ 0003f7b2 ====

void _SystemCreateMachOWrapper(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectGetSize @ 0003f7b7 ====

void _IndirectGetSize(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectDecompress @ 0003f7bc ====

void _IndirectDecompress(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _MemoryClear @ 0003f7c1 ====

void _MemoryClear(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _IndirectCompress @ 0003f7c6 ====

void _IndirectCompress(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetUTCOffset @ 0003f7cb ====

void _TimerGetUTCOffset(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _FSRefMakePath @ 0003f7d0 ====

void _FSRefMakePath(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFDictionarySetValue @ 0003f7d5 ====

void _CFDictionarySetValue(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetLocalSeconds @ 0003f7da ====

void _TimerGetLocalSeconds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFRunLoopGetCurrent @ 0003f7df ====

void _CFRunLoopGetCurrent(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFPreferencesSynchronize @ 0003f7e4 ====

void _CFPreferencesSynchronize(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SimpleResolve @ 0003f7e9 ====

void _SimpleResolve(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NetworkQueueFill @ 0003f7ee ====

void _NetworkQueueFill(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _QueueCreate @ 0003f7f3 ====

void _QueueCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AddressDuplicate @ 0003f7f8 ====

void _AddressDuplicate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _QueueDispose @ 0003f7fd ====

void _QueueDispose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NetworkQueueWait @ 0003f802 ====

void _NetworkQueueWait(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StreamOpenClient @ 0003f807 ====

void _StreamOpenClient(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringFindString @ 0003f80c ====

void _StringFindString(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _QueueEmpty @ 0003f811 ====

void _QueueEmpty(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DatagramSend @ 0003f816 ====

void _DatagramSend(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringTokenize @ 0003f81b ====

void _StringTokenize(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StreamDispose @ 0003f820 ====

void _StreamDispose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StreamClose @ 0003f825 ====

void _StreamClose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DatagramDispose @ 0003f82a ====

void _DatagramDispose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _QueueRemove @ 0003f82f ====

void _QueueRemove(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _QueueInsert @ 0003f834 ====

void _QueueInsert(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StreamCreate @ 0003f839 ====

void _StreamCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DatagramCreate @ 0003f83e ====

void _DatagramCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DatagramOpen @ 0003f843 ====

void _DatagramOpen(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StringFormatSafe @ 0003f848 ====

void _StringFormatSafe(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _StreamSend @ 0003f84d ====

void _StreamSend(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AuthorizationCopyRights @ 0003f852 ====

void _AuthorizationCopyRights(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _MemoryDeallocate @ 0003f857 ====

void _MemoryDeallocate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AuthorizationFree @ 0003f85c ====

void _AuthorizationFree(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AuthorizationCreate @ 0003f861 ====

void _AuthorizationCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _fwrite @ 0003f866 ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

size_t _fwrite(void *param_1,size_t param_2,size_t param_3,FILE *param_4)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AuthorizationExecuteWithPrivileges @ 0003f86b ====

void _AuthorizationExecuteWithPrivileges(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringGetLength @ 0003f870 ====

void _CFStringGetLength(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _MemoryAllocate @ 0003f875 ====

void _MemoryAllocate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _fclose @ 0003f87a ====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

int _fclose(FILE *param_1)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ResolverOpen @ 0003f87f ====

void _ResolverOpen(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ResolveName @ 0003f884 ====

void _ResolveName(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NetworkQueueEmpty @ 0003f889 ====

void _NetworkQueueEmpty(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AddressDecomposeTCPIP @ 0003f88e ====

void _AddressDecomposeTCPIP(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DatagramClose @ 0003f893 ====

void _DatagramClose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AddressIsEmpty @ 0003f898 ====

void _AddressIsEmpty(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ResolverCreate @ 0003f89d ====

void _ResolverCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _TimerGetMilliseconds @ 0003f8a2 ====

void _TimerGetMilliseconds(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AddressComposeTCPIP @ 0003f8a7 ====

void _AddressComposeTCPIP(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SystemSetQuitProc @ 0003f8ac ====

void _SystemSetQuitProc(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _DatagramControl @ 0003f8b1 ====

void _DatagramControl(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ResolverDispose @ 0003f8b6 ====

void _ResolverDispose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NetworkStackLoad @ 0003f8bb ====

void _NetworkStackLoad(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== ___umoddi3 @ 0003f8c0 ====

void ___umoddi3(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ResolverClose @ 0003f8c5 ====

void _ResolverClose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _NetworkStackGetLoaded @ 0003f8ca ====

void _NetworkStackGetLoaded(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SystemCheckCallback @ 0003f8cf ====

void _SystemCheckCallback(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SystemIdle @ 0003f8d4 ====

void _SystemIdle(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _AddressComposeEmpty @ 0003f8d9 ====

void _AddressComposeEmpty(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _P2CStringCopy @ 0003f8de ====

void _P2CStringCopy(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _C2PStringCopy @ 0003f8e3 ====

void _C2PStringCopy(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFGetTypeID @ 0003f8e8 ====

void _CFGetTypeID(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HashDispose @ 0003f8ed ====

void _HashDispose(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SecKeychainSearchCopyNext @ 0003f8f2 ====

void _SecKeychainSearchCopyNext(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ICFindPrefHandle @ 0003f8f7 ====

void _ICFindPrefHandle(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SecKeychainItemCopyContent @ 0003f8fc ====

void _SecKeychainItemCopyContent(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFNumberGetTypeID @ 0003f901 ====

void _CFNumberGetTypeID(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _CFStringGetTypeID @ 0003f906 ====

void _CFStringGetTypeID(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HashAppend @ 0003f90b ====

void _HashAppend(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SCDynamicStoreCopyProxies @ 0003f910 ====

void _SCDynamicStoreCopyProxies(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ICGetPref @ 0003f915 ====

void _ICGetPref(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SecKeychainItemFreeContent @ 0003f91a ====

void _SecKeychainItemFreeContent(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ICBegin @ 0003f91f ====

void _ICBegin(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HLockHi @ 0003f924 ====

void _HLockHi(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HashLookup @ 0003f929 ====

void _HashLookup(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ICStart @ 0003f92e ====

void _ICStart(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _SecKeychainSearchCreateFromAttributes @ 0003f933 ====

void _SecKeychainSearchCreateFromAttributes(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _HashCreate @ 0003f938 ====

void _HashCreate(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}


// ==== _ICStop @ 0003f93d ====

void _ICStop(void)

{
  do {
                    /* WARNING: Do nothing block with infinite loop */
  } while( true );
}

