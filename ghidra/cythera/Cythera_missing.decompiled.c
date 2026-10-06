// CyDecompAt of Cythera_pef (840 addresses)

// ==== .SetData__9TApWidgetFsUllPc @ 10000114 ====
// CyDecompAt: created, body 10000114-10000173

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetData__9TApWidgetFsUllPc
               (int param_1,short param_2,undefined4 param_3,undefined4 param_4,undefined4 param_5)

{
  FUN_100c50e8(_DAT_100d940c,*(undefined4 *)(param_1 + 4),(int)param_2,param_3,param_4,param_5);
  return;
}


// ==== .GetData__9TApWidgetFsUllPcPl @ 100001a4 ====
// CyDecompAt: created, body 100001a4-1000020b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _GetData__9TApWidgetFsUllPcPl
               (int param_1,short param_2,undefined4 param_3,undefined4 param_4,undefined4 param_5,
               undefined4 param_6)

{
  FUN_100c50e8(_DAT_100d940c,*(undefined4 *)(param_1 + 4),(int)param_2,param_3,param_4,param_5,
               param_6);
  return;
}


// ==== .SetData__18TAppearanceAdapterFlsUllPc @ 10000308 ====
// CyDecompAt: created, body 10000308-10000353

void _SetData__18TAppearanceAdapterFlsUllPc
               (undefined4 param_1,undefined4 param_2,short param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6)

{
  .glue::SetControlData(param_2,(int)param_3,param_4,param_5,param_6);
  return;
}


// ==== .GetData__18TAppearanceAdapterFlsUllPcPl @ 1000038c ====
// CyDecompAt: created, body 1000038c-100003df

void _GetData__18TAppearanceAdapterFlsUllPcPl
               (undefined4 param_1,undefined4 param_2,short param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6,undefined4 param_7)

{
  .glue::GetControlData(param_2,(int)param_3,param_4,param_5,param_6,param_7);
  return;
}


// ==== .SetValue__18TAppearanceAdapterFls @ 1000041c ====
// CyDecompAt: created, body 1000041c-1000044f

void _SetValue__18TAppearanceAdapterFls(undefined4 param_1,undefined4 param_2,short param_3)

{
  .glue::SetControlValue(param_2,(int)param_3);
  return;
}


// ==== .GetValue__18TAppearanceAdapterFl @ 10000484 ====
// CyDecompAt: created, body 10000484-100004af

void _GetValue__18TAppearanceAdapterFl(undefined4 param_1,undefined4 param_2)

{
  .glue::GetControlValue(param_2);
  return;
}


// ==== .GetReference__18TAppearanceAdapterFl @ 100004e4 ====
// CyDecompAt: created, body 100004e4-1000050f

void _GetReference__18TAppearanceAdapterFl(undefined4 param_1,undefined4 param_2)

{
  .glue::GetControlReference(param_2);
  return;
}


// ==== .Activate__18TAppearanceAdapterFl @ 10000548 ====
// CyDecompAt: created, body 10000548-10000573

void _Activate__18TAppearanceAdapterFl(undefined4 param_1,undefined4 param_2)

{
  .glue::ActivateControl(param_2);
  return;
}


// ==== .Deactivate__18TAppearanceAdapterFl @ 100005a8 ====
// CyDecompAt: created, body 100005a8-100005d3

void _Deactivate__18TAppearanceAdapterFl(undefined4 param_1,undefined4 param_2)

{
  .glue::DeactivateControl(param_2);
  return;
}


// ==== .Enable__18TAppearanceAdapterFl @ 1000060c ====
// CyDecompAt: created, body 1000060c-1000063b

void _Enable__18TAppearanceAdapterFl(undefined4 param_1,undefined4 param_2)

{
  .glue::HiliteControl(param_2,0);
  return;
}


// ==== .Disable__18TAppearanceAdapterFl @ 10000670 ====
// CyDecompAt: created, body 10000670-1000069f

void _Disable__18TAppearanceAdapterFl(undefined4 param_1,undefined4 param_2)

{
  .glue::HiliteControl(param_2,0xff);
  return;
}


// ==== .Embed__18TAppearanceAdapterFl9TApWidget @ 100006d4 ====
// CyDecompAt: created, body 100006d4-1000070b

void _Embed__18TAppearanceAdapterFl9TApWidget
               (undefined4 param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4)

{
  .glue::EmbedControl(param_2,param_4);
  return;
}


// ==== .HandleWidgetClick__18TAppearanceAdapterFl5PointsP17RoutineDescriptor @ 10000748 ====
// CyDecompAt: created, body 10000748-100007ab

undefined4
_HandleWidgetClick__18TAppearanceAdapterFl5PointsP17RoutineDescriptor
          (undefined4 param_1,int *param_2,undefined4 param_3,short param_4,undefined4 param_5)

{
  undefined4 uVar1;
  
  if (*(char *)(*param_2 + 0x11) == -1) {
    uVar1 = 0;
  }
  else {
    uVar1 = .glue::HandleControlClick(param_2,param_3,(int)param_4,param_5);
  }
  return uVar1;
}


// ==== .CreateRoot__18TAppearanceAdapterFP9TApWindow @ 10000804 ====
// CyDecompAt: created, body 10000804-1000085b

void _CreateRoot__18TAppearanceAdapterFP9TApWindow
               (undefined4 *param_1,undefined4 param_2,int param_3)

{
  undefined4 auStack_18 [4];
  
  .glue::CreateRootControl(*(undefined4 *)(param_3 + 4),auStack_18);
  *param_1 = &PTR_PTR_100d3d2c;
  param_1[1] = auStack_18[0];
  return;
}


// ==== .DisposeRoot__18TAppearanceAdapterF9TApWidget @ 1000089c ====
// CyDecompAt: created, body 1000089c-1000089f

void _DisposeRoot__18TAppearanceAdapterF9TApWidget(void)

{
  return;
}


// ==== .NewGroupBox__18TAppearanceAdapterFP9TApWindow9TApWidgetlR4RectPCUc @ 100009c4 ====
// CyDecompAt: created, body 100009c4-10000a4b

void _NewGroupBox__18TAppearanceAdapterFP9TApWindow9TApWidgetlR4RectPCUc
               (undefined4 param_1,undefined4 param_2,int param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6,undefined4 param_7,undefined4 param_8)

{
  undefined4 uVar1;
  
  uVar1 = .glue::NewControl(*(undefined4 *)(param_3 + 4),param_7,param_8,1,0,0,0,0xa0,param_6);
  .debug::_NewTApControl__18TAppearanceAdapterF9TApWidgetPP13ControlRecord
            (param_1,param_2,param_4,param_5,uVar1);
  return;
}


// ==== .NewSlider__18TAppearanceAdapterFP9TApWindow9TApWidgetlR4RectPCUcssss @ 10000aa4 ====
// CyDecompAt: created, body 10000aa4-10000b2f

void _NewSlider__18TAppearanceAdapterFP9TApWindow9TApWidgetlR4RectPCUcssss
               (undefined4 param_1,undefined4 param_2,int param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6,undefined4 param_7,undefined4 param_8,
               short param_9,short param_10,short param_11,short param_12)

{
  undefined4 uVar1;
  
  uVar1 = .glue::NewControl(*(undefined4 *)(param_3 + 4),param_7,param_8,1,(int)param_9,
                            (int)param_10,(int)param_11,param_12 + 0x30,param_6);
  .debug::_NewTApControl__18TAppearanceAdapterF9TApWidgetPP13ControlRecord
            (param_1,param_2,param_4,param_5,uVar1);
  return;
}


// ==== .NewCheckBox__18TAppearanceAdapterFP9TApWindow9TApWidgetlR4RectPCUcUc @ 10000b88 ====
// CyDecompAt: created, body 10000b88-10000c0f

void _NewCheckBox__18TAppearanceAdapterFP9TApWindow9TApWidgetlR4RectPCUcUc
               (undefined4 param_1,undefined4 param_2,int param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6,undefined4 param_7,undefined4 param_8,
               undefined1 param_9)

{
  undefined4 uVar1;
  
  uVar1 = .glue::NewControl(*(undefined4 *)(param_3 + 4),param_7,param_8,1,param_9,0,1,1,param_6);
  .debug::_NewTApControl__18TAppearanceAdapterF9TApWidgetPP13ControlRecord
            (param_1,param_2,param_4,param_5,uVar1);
  return;
}


// ==== .NewPushButton__18TAppearanceAdapterFP9TApWindow9TApWidgetlR4RectPCUc @ 10000c68 ====
// CyDecompAt: created, body 10000c68-10000cef

void _NewPushButton__18TAppearanceAdapterFP9TApWindow9TApWidgetlR4RectPCUc
               (undefined4 param_1,undefined4 param_2,int param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6,undefined4 param_7,undefined4 param_8)

{
  undefined4 uVar1;
  
  uVar1 = .glue::NewControl(*(undefined4 *)(param_3 + 4),param_7,param_8,1,0,0,1,0,param_6);
  .debug::_NewTApControl__18TAppearanceAdapterF9TApWidgetPP13ControlRecord
            (param_1,param_2,param_4,param_5,uVar1);
  return;
}


// ==== .NewStaticIcon__18TAppearanceAdapterFP9TApWindow9TApWidgetlR4Rects @ 10000d48 ====
// CyDecompAt: created, body 10000d48-10000dcf

void _NewStaticIcon__18TAppearanceAdapterFP9TApWindow9TApWidgetlR4Rects
               (undefined4 param_1,undefined4 param_2,int param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6,undefined4 param_7,short param_8)

{
  undefined4 uVar1;
  
  uVar1 = .glue::NewControl(*(undefined4 *)(param_3 + 4),param_7,PTR_DAT_100ce1a0,1,(int)param_8,0,1
                            ,0x141,param_6);
  .debug::_NewTApControl__18TAppearanceAdapterF9TApWidgetPP13ControlRecord
            (param_1,param_2,param_4,param_5,uVar1);
  return;
}


// ==== .NewStaticText__18TAppearanceAdapterFP9TApWindow9TApWidgetlR4RectPCUcs @ 10000e24 ====
// CyDecompAt: created, body 10000e24-10000f2b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _NewStaticText__18TAppearanceAdapterFP9TApWindow9TApWidgetlR4RectPCUcs
               (undefined4 *param_1,undefined4 param_2,int param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6,undefined4 param_7,undefined1 *param_8,
               short param_9)

{
  undefined4 uVar1;
  undefined1 auStack_20 [4];
  undefined4 uStack_1c;
  undefined **ppuStack_18;
  undefined4 uStack_14;
  
  uVar1 = .glue::NewControl(*(undefined4 *)(param_3 + 4),param_7,param_8,1,0,0,0,0x120,param_6);
  .debug::_NewTApControl__18TAppearanceAdapterF9TApWidgetPP13ControlRecord
            (auStack_20,param_2,param_4,param_5,uVar1);
  ppuStack_18 = &PTR_PTR_100d3d2c;
  uStack_14 = uStack_1c;
  .debug::_SetFont__9TApWidgetFss(&ppuStack_18,0,(int)param_9);
  FUN_100c50e8(_DAT_100d940c,uStack_14,0,0x74657874,*param_8,param_8 + 1);
  *param_1 = &PTR_PTR_100d3d2c;
  param_1[1] = uStack_14;
  return;
}


// ==== .FindWidgetUnderMouse__18TAppearanceAdapterFP9TApWindow5PointPs @ 10000f84 ====
// CyDecompAt: created, body 10000f84-10000fe7

void _FindWidgetUnderMouse__18TAppearanceAdapterFP9TApWindow5PointPs
               (undefined4 *param_1,undefined4 param_2,int param_3,undefined4 param_4,
               undefined4 param_5)

{
  undefined4 uVar1;
  
  uVar1 = .glue::FindControlUnderMouse(param_4,*(undefined4 *)(param_3 + 4),param_5);
  *param_1 = &PTR_PTR_100d3d2c;
  param_1[1] = uVar1;
  return;
}


// ==== .DrawRoutine__18TAppearanceAdapterFP9TApWindow @ 1000103c ====
// CyDecompAt: created, body 1000103c-1000106b

void _DrawRoutine__18TAppearanceAdapterFP9TApWindow(undefined4 param_1,int param_2)

{
  .glue::DrawControls(*(undefined4 *)(param_2 + 4));
  return;
}


// ==== .ActivateRoutine__18TAppearanceAdapterFP9TApWindow @ 100010ac ====
// CyDecompAt: created, body 100010ac-100010db

void _ActivateRoutine__18TAppearanceAdapterFP9TApWindow(undefined4 param_1,int param_2)

{
  .glue::ActivateControl(*(undefined4 *)(param_2 + 0x10));
  return;
}


// ==== .DeactivateRoutine__18TAppearanceAdapterFP9TApWindow @ 10001120 ====
// CyDecompAt: created, body 10001120-1000114f

void _DeactivateRoutine__18TAppearanceAdapterFP9TApWindow(undefined4 param_1,int param_2)

{
  .glue::DeactivateControl(*(undefined4 *)(param_2 + 0x10));
  return;
}


// ==== .KeyRoutine__18TAppearanceAdapterFP9TApWindows @ 10001198 ====
// CyDecompAt: created, body 10001198-1000120f

void _KeyRoutine__18TAppearanceAdapterFP9TApWindows(undefined4 param_1,int param_2)

{
  undefined *puVar1;
  short sVar2;
  undefined4 auStack_18 [5];
  
  puVar1 = PTR_DAT_100cdb84;
  sVar2 = .glue::GetKeyboardFocus(*(undefined4 *)(param_2 + 4),auStack_18);
  if (sVar2 == 0) {
    .glue::HandleControlKey
              (auStack_18[0],(ushort)((uint)*(undefined4 *)(*(int *)puVar1 + 6) >> 8) & 0xff,
               *(uint *)(*(int *)puVar1 + 6) & 0xff,(int)*(short *)(*(int *)puVar1 + 0x12));
  }
  return;
}


// ==== .IdleRoutine__18TAppearanceAdapterFP9TApWindow @ 10001250 ====
// CyDecompAt: created, body 10001250-1000127f

void _IdleRoutine__18TAppearanceAdapterFP9TApWindow(undefined4 param_1,int param_2)

{
  .glue::IdleControls(*(undefined4 *)(param_2 + 4));
  return;
}


// ==== .Embed__8T7WidgetF9TApWidget @ 100012c0 ====
// CyDecompAt: created, body 100012c0-100014ab

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Embed__8T7WidgetF9TApWidget(undefined4 param_1,undefined4 param_2,int param_3)

{
  int iVar1;
  int iVar2;
  int *piVar3;
  undefined4 *puVar4;
  undefined4 *puVar5;
  undefined4 *puVar6;
  undefined **ppuStack_5c;
  int iStack_58;
  int iStack_54;
  undefined **ppuStack_50;
  undefined1 auStack_4c [12];
  
  piVar3 = (int *)&DAT_100d38c4;
  if (param_3 != 0) {
    if (_DAT_100d38c4 < _DAT_100d38c8) {
      piVar3 = (int *)&DAT_100d38c8;
    }
    iStack_54 = *piVar3;
    if (iStack_54 - 1U < *(uint *)(param_3 + 0xc)) {
      ppuStack_50 = &PTR_PTR_100d3cb8;
      FUN_100c15b4(auStack_4c,PTR_s_vector_insert_length_error_100ce194);
      ppuStack_50 = &PTR_PTR_100d3ca8;
      FUN_100bdef4(PTR_s__std_exception__std_logic_erro_100ce190,&ppuStack_50,PTR_PTR_100cdb74);
    }
    if (*(uint *)(param_3 + 0xc) < *(uint *)(param_3 + 8)) {
      iVar2 = *(int *)(param_3 + 0xc);
      *(int *)(param_3 + 0xc) = iVar2 + 1;
      *(undefined4 *)(*(int *)(param_3 + 0x10) + iVar2 * 4) = param_1;
    }
    else {
      puVar4 = *(undefined4 **)(param_3 + 0x10);
      if (*(int *)(param_3 + 8) == 0) {
        iVar2 = 1;
      }
      else {
        iVar2 = *(int *)(param_3 + 8) << 1;
      }
      iStack_58 = FUN_100be7c8(iVar2 << 2);
      if (iStack_58 == 0) {
        ppuStack_5c = &PTR_PTR_100d3c68;
        FUN_100bdef4(PTR_s__std_exception__std_bad_alloc__100ce18c,&ppuStack_5c,_DAT_100cdb6c);
      }
      *(int *)(param_3 + 0x10) = iStack_58;
      if (*(int *)(param_3 + 0xc) != 0) {
        iVar1 = *(int *)(param_3 + 0xc);
        puVar5 = *(undefined4 **)(param_3 + 0x10);
        for (puVar6 = puVar4; puVar6 != puVar4 + iVar1; puVar6 = puVar6 + 1) {
          *puVar5 = *puVar6;
          puVar5 = puVar5 + 1;
        }
      }
      *(undefined4 *)(*(int *)(param_3 + 0x10) + *(int *)(param_3 + 0xc) * 4) = param_1;
      if (puVar4 != (undefined4 *)0x0) {
        FUN_100be848(puVar4);
      }
      *(int *)(param_3 + 0xc) = *(int *)(param_3 + 0xc) + 1;
      *(int *)(param_3 + 8) = iVar2;
    }
  }
  return;
}


// ==== .__dt__Q23std9bad_allocFv @ 100014dc ====
// CyDecompAt: created, body 100014dc-1000155f

undefined4 * ___dt__Q23std9bad_allocFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d3c68;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d3cc8;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__Q23std12length_errorFv @ 1000158c ====
// CyDecompAt: created, body 1000158c-1000162b

undefined4 * ___dt__Q23std12length_errorFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d3ca8;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d3cb8;
      if (param_1 != (undefined4 *)0xfffffffc) {
        .debug::___dt__28_RefCountedPtr<c,9_Array<c>>Fv(param_1 + 1,0xffffffff);
      }
      if (param_1 != (undefined4 *)0x0) {
        *param_1 = &PTR_PTR_100d3cc8;
      }
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__Q23std11logic_errorFv @ 1000165c ====
// CyDecompAt: created, body 1000165c-100016e3

undefined4 * ___dt__Q23std11logic_errorFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d3cb8;
    if (param_1 != (undefined4 *)0xfffffffc) {
      .debug::___dt__28_RefCountedPtr<c,9_Array<c>>Fv(param_1 + 1,0xffffffff);
    }
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d3cc8;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__Q23std9exceptionFv @ 10001714 ====
// CyDecompAt: created, body 10001714-10001787

undefined4 * ___dt__Q23std9exceptionFv(undefined4 *param_1,short param_2)

{
  if ((param_1 != (undefined4 *)0x0) && (*param_1 = &PTR_PTR_100d3cc8, 0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .FindWidgetUnderMouse__8T7WidgetF5PointPs @ 10001848 ====
// CyDecompAt: created, body 10001848-100018f7

void _FindWidgetUnderMouse__8T7WidgetF5PointPs
               (undefined4 *param_1,int param_2,undefined4 param_3,undefined4 param_4)

{
  undefined4 *puVar1;
  undefined1 auStack_28 [4];
  int iStack_24;
  undefined **ppuStack_20;
  int iStack_1c;
  
  puVar1 = *(undefined4 **)(param_2 + 0x10);
  while( true ) {
    if (puVar1 == (undefined4 *)(*(int *)(param_2 + 0x10) + *(int *)(param_2 + 0xc) * 4)) {
      *param_1 = &PTR_PTR_100d3d2c;
      param_1[1] = 0;
      return;
    }
    FUN_100c50e8(auStack_28,*puVar1,param_3,param_4);
    ppuStack_20 = &PTR_PTR_100d3d2c;
    iStack_1c = iStack_24;
    if (iStack_24 != 0) break;
    puVar1 = puVar1 + 1;
  }
  *param_1 = &PTR_PTR_100d3d2c;
  param_1[1] = iStack_24;
  return;
}


// ==== .HandleWidgetClick__8T7WidgetF5PointsP17RoutineDescriptor @ 10001934 ====
// CyDecompAt: created, body 10001934-1000193b

undefined4 _HandleWidgetClick__8T7WidgetF5PointsP17RoutineDescriptor(void)

{
  return 0;
}


// ==== .__dt__8T7WidgetFv @ 10001a4c ====
// CyDecompAt: created, body 10001a4c-10001ae7

undefined4 * ___dt__8T7WidgetFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d3cd8;
    if (((param_1 != (undefined4 *)0xfffffff8) && (param_1 != (undefined4 *)0xfffffff8)) &&
       (param_1[4] != 0)) {
      FUN_100be848(param_1[4]);
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .SetValue__15T7ControlWidgetFs @ 10001b10 ====
// CyDecompAt: created, body 10001b10-10001b47

void _SetValue__15T7ControlWidgetFs(int param_1,short param_2)

{
  .glue::SetControlValue(*(undefined4 *)(param_1 + 0x14),(int)param_2);
  return;
}


// ==== .GetValue__15T7ControlWidgetFv @ 10001b78 ====
// CyDecompAt: created, body 10001b78-10001ba7

void _GetValue__15T7ControlWidgetFv(int param_1)

{
  .glue::GetControlValue(*(undefined4 *)(param_1 + 0x14));
  return;
}


// ==== .Activate__15T7ControlWidgetFv @ 10001bd8 ====
// CyDecompAt: created, body 10001bd8-10001c0b

void _Activate__15T7ControlWidgetFv(int param_1)

{
  .glue::HiliteControl(*(undefined4 *)(param_1 + 0x14),0);
  return;
}


// ==== .Deactivate__15T7ControlWidgetFv @ 10001c3c ====
// CyDecompAt: created, body 10001c3c-10001c6f

void _Deactivate__15T7ControlWidgetFv(int param_1)

{
  .glue::HiliteControl(*(undefined4 *)(param_1 + 0x14),0xff);
  return;
}


// ==== .Enable__15T7ControlWidgetFv @ 10001ca4 ====
// CyDecompAt: created, body 10001ca4-10001cd7

void _Enable__15T7ControlWidgetFv(int param_1)

{
  .glue::HiliteControl(*(undefined4 *)(param_1 + 0x14),0);
  return;
}


// ==== .Disable__15T7ControlWidgetFv @ 10001d08 ====
// CyDecompAt: created, body 10001d08-10001d3b

void _Disable__15T7ControlWidgetFv(int param_1)

{
  .glue::HiliteControl(*(undefined4 *)(param_1 + 0x14),0xff);
  return;
}


// ==== .DrawRoutine__15T7ControlWidgetFv @ 10001d6c ====
// CyDecompAt: created, body 10001d6c-10001d9b

void _DrawRoutine__15T7ControlWidgetFv(int param_1)

{
  .glue::Draw1Control(*(undefined4 *)(param_1 + 0x14));
  return;
}


// ==== .FindWidgetUnderMouse__15T7ControlWidgetF5PointPs @ 10001dd0 ====
// CyDecompAt: created, body 10001dd0-10001e83

void _FindWidgetUnderMouse__15T7ControlWidgetF5PointPs
               (undefined4 *param_1,int param_2,undefined4 param_3,undefined2 *param_4)

{
  char cVar2;
  undefined2 uVar1;
  int aiStack_18 [3];
  
  cVar2 = .glue::PtInRect(param_3,**(int **)(param_2 + 0x14) + 8);
  if (cVar2 != '\0') {
    uVar1 = .glue::FindControl(param_3,*(undefined4 *)(**(int **)(param_2 + 0x14) + 4),aiStack_18);
    *param_4 = uVar1;
    if (aiStack_18[0] == *(int *)(param_2 + 0x14)) {
      *param_1 = &PTR_PTR_100d3d2c;
      param_1[1] = param_2;
      return;
    }
  }
  *param_1 = &PTR_PTR_100d3d2c;
  param_1[1] = 0;
  return;
}


// ==== .HandleWidgetClick__15T7ControlWidgetF5PointsP17RoutineDescriptor @ 10001ec8 ====
// CyDecompAt: created, body 10001ec8-10001f07

void _HandleWidgetClick__15T7ControlWidgetF5PointsP17RoutineDescriptor
               (int param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4)

{
  .glue::TrackControl(*(undefined4 *)(param_1 + 0x14),param_2,param_4);
  return;
}


// ==== .DrawRoutine__10T7GroupBoxFv @ 10002034 ====
// CyDecompAt: created, body 10002034-100020df

void _DrawRoutine__10T7GroupBoxFv(int param_1)

{
  short sStack_18;
  short sStack_16;
  undefined4 uStack_14;
  
  .glue::TextFont(0);
  .glue::TextSize(0);
  uStack_14 = *(undefined4 *)(param_1 + 0x18);
  sStack_18 = (short)((uint)*(undefined4 *)(param_1 + 0x14) >> 0x10);
  sStack_18 = sStack_18 + 0x10;
  sStack_16 = (short)*(undefined4 *)(param_1 + 0x14);
  .glue::FrameRect(&sStack_18);
  .glue::TextMode(0);
  .glue::MoveTo(sStack_16 + 4,(int)sStack_18);
  .glue::DrawString(param_1 + 0x1c);
  .glue::TextMode(1);
  .debug::_DrawRoutine__8T7WidgetFv(param_1);
  return;
}


// ==== .__dt__12T7IconWidgetFv @ 100021e8 ====
// CyDecompAt: created, body 100021e8-1000229f

undefined4 * ___dt__12T7IconWidgetFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d3b40;
    .glue::DisposeCIcon(param_1[7]);
    if ((((param_1 != (undefined4 *)0x0) &&
         (*param_1 = &PTR_PTR_100d3cd8, param_1 != (undefined4 *)0xfffffff8)) &&
        (param_1 != (undefined4 *)0xfffffff8)) && (param_1[4] != 0)) {
      FUN_100be848(param_1[4]);
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .DrawRoutine__12T7IconWidgetFv @ 100022cc ====
// CyDecompAt: created, body 100022cc-10002303

void _DrawRoutine__12T7IconWidgetFv(int param_1)

{
  .glue::PlotCIcon(param_1 + 0x14,*(undefined4 *)(param_1 + 0x1c));
  return;
}


// ==== .SetData__13T7LabelWidgetFsUllPc @ 10002420 ====
// CyDecompAt: created, body 10002420-1000246f

undefined4
_SetData__13T7LabelWidgetFsUllPc
          (int param_1,undefined4 param_2,int param_3,undefined4 param_4,ushort *param_5)

{
  undefined4 uVar1;
  
  if (param_3 == 0x666f6e74) {
    if ((*param_5 & 1) != 0) {
      *(ushort *)(param_1 + 0x11e) = param_5[1];
    }
    if ((*param_5 & 0x40) != 0) {
      *(ushort *)(param_1 + 0x11c) = param_5[5];
    }
    uVar1 = 0;
  }
  else {
    uVar1 = 0xffff888b;
  }
  return uVar1;
}


// ==== .DrawRoutine__13T7LabelWidgetFv @ 100024a4 ====
// CyDecompAt: created, body 100024a4-100025ab

void _DrawRoutine__13T7LabelWidgetFv(int param_1)

{
  .glue::TextFont(1);
  .glue::TextSize(0);
  .glue::TextFace(0);
  if (*(short *)(param_1 + 0x11e) == -1) {
    .glue::TextFont(0);
    .glue::TextSize(0);
  }
  else if (*(short *)(param_1 + 0x11e) == -2) {
    .glue::TextFont(3);
    .glue::TextSize(10);
  }
  else if (*(short *)(param_1 + 0x11e) == -3) {
    .glue::TextFont(3);
    .glue::TextSize(10);
    .glue::TextFace(1);
  }
  .glue::TETextBox(param_1 + 0x1d,*(undefined1 *)(param_1 + 0x1c),param_1 + 0x14,
                   (int)*(short *)(param_1 + 0x11c));
  .glue::TextFont(1);
  .glue::TextSize(0);
  .glue::TextFace(0);
  return;
}


// ==== .__dt__14T7SliderWidgetFv @ 100026fc ====
// CyDecompAt: created, body 100026fc-100027b3

undefined4 * ___dt__14T7SliderWidgetFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d3a80;
    .debug::_DisposeSlider(param_1[5]);
    if ((((param_1 != (undefined4 *)0x0) &&
         (*param_1 = &PTR_PTR_100d3cd8, param_1 != (undefined4 *)0xfffffff8)) &&
        (param_1 != (undefined4 *)0xfffffff8)) && (param_1[4] != 0)) {
      FUN_100be848(param_1[4]);
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .SetValue__14T7SliderWidgetFs @ 100027e0 ====
// CyDecompAt: created, body 100027e0-10002817

void _SetValue__14T7SliderWidgetFs(int param_1,short param_2)

{
  .debug::_SetSliderValue(*(undefined4 *)(param_1 + 0x14),(int)param_2);
  return;
}


// ==== .GetValue__14T7SliderWidgetFv @ 10002848 ====
// CyDecompAt: created, body 10002848-10002877

void _GetValue__14T7SliderWidgetFv(int param_1)

{
  .debug::_GetSliderValue(*(undefined4 *)(param_1 + 0x14));
  return;
}


// ==== .Activate__14T7SliderWidgetFv @ 100028a8 ====
// CyDecompAt: created, body 100028a8-100028db

void _Activate__14T7SliderWidgetFv(int param_1)

{
  .debug::_SetSliderEnabled(*(undefined4 *)(param_1 + 0x14),1);
  return;
}


// ==== .Deactivate__14T7SliderWidgetFv @ 1000290c ====
// CyDecompAt: created, body 1000290c-1000293f

void _Deactivate__14T7SliderWidgetFv(int param_1)

{
  .debug::_SetSliderEnabled(*(undefined4 *)(param_1 + 0x14),0);
  return;
}


// ==== .DrawRoutine__14T7SliderWidgetFv @ 10002974 ====
// CyDecompAt: created, body 10002974-100029a3

void _DrawRoutine__14T7SliderWidgetFv(int param_1)

{
  .debug::_DrawSlider(*(undefined4 *)(param_1 + 0x14));
  return;
}


// ==== .FindWidgetUnderMouse__14T7SliderWidgetF5PointPs @ 100029d8 ====
// CyDecompAt: created, body 100029d8-10002a5f

void _FindWidgetUnderMouse__14T7SliderWidgetF5PointPs
               (undefined4 *param_1,int param_2,undefined4 param_3,undefined2 *param_4)

{
  char cVar1;
  
  cVar1 = .glue::PtInRect(param_3,*(int *)(param_2 + 0x14) + 0x10);
  if (cVar1 == '\0') {
    *param_1 = &PTR_PTR_100d3d2c;
    param_1[1] = 0;
  }
  else {
    *param_4 = 0x81;
    *param_1 = &PTR_PTR_100d3d2c;
    param_1[1] = param_2;
  }
  return;
}


// ==== .HandleWidgetClick__14T7SliderWidgetF5PointsP17RoutineDescriptor @ 10002aa4 ====
// CyDecompAt: created, body 10002aa4-10002aef

undefined4
_HandleWidgetClick__14T7SliderWidgetF5PointsP17RoutineDescriptor(int param_1,undefined4 param_2)

{
  char cVar2;
  undefined4 uVar1;
  
  cVar2 = .debug::_TrackSlider(*(undefined4 *)(param_1 + 0x14),param_2);
  if (cVar2 == '\0') {
    uVar1 = 0;
  }
  else {
    uVar1 = 0x81;
  }
  return uVar1;
}


// ==== .SetData__9T7AdapterFlsUllPc @ 10002b44 ====
// CyDecompAt: created, body 10002b44-10002bab

undefined4
_SetData__9T7AdapterFlsUllPc
          (undefined4 param_1,int param_2,short param_3,undefined4 param_4,undefined4 param_5,
          undefined4 param_6)

{
  undefined4 uVar1;
  
  if (param_2 == 0) {
    uVar1 = 0xffff888b;
  }
  else {
    uVar1 = FUN_100c50e8(param_2,(int)param_3,param_4,param_5,param_6);
  }
  return uVar1;
}


// ==== .SetData__8T7WidgetFsUllPc @ 10002bdc ====
// CyDecompAt: created, body 10002bdc-10002be3

undefined4 _SetData__8T7WidgetFsUllPc(void)

{
  return 0xffff888b;
}


// ==== .GetData__9T7AdapterFlsUllPcPl @ 10002c10 ====
// CyDecompAt: created, body 10002c10-10002c7f

undefined4
_GetData__9T7AdapterFlsUllPcPl
          (undefined4 param_1,int param_2,short param_3,undefined4 param_4,undefined4 param_5,
          undefined4 param_6,undefined4 param_7)

{
  undefined4 uVar1;
  
  if (param_2 == 0) {
    uVar1 = 0xffff888b;
  }
  else {
    uVar1 = FUN_100c50e8(param_2,(int)param_3,param_4,param_5,param_6,param_7);
  }
  return uVar1;
}


// ==== .GetData__8T7WidgetFsUllPcPl @ 10002cb0 ====
// CyDecompAt: created, body 10002cb0-10002cb7

undefined4 _GetData__8T7WidgetFsUllPcPl(void)

{
  return 0xffff888b;
}


// ==== .SetValue__9T7AdapterFls @ 10002ce8 ====
// CyDecompAt: created, body 10002ce8-10002d2f

void _SetValue__9T7AdapterFls(undefined4 param_1,int param_2,short param_3)

{
  if (param_2 != 0) {
    FUN_100c50e8(param_2,(int)param_3);
  }
  return;
}


// ==== .SetValue__8T7WidgetFs @ 10002d5c ====
// CyDecompAt: created, body 10002d5c-10002d5f

void _SetValue__8T7WidgetFs(void)

{
  return;
}


// ==== .GetValue__9T7AdapterFl @ 10002d88 ====
// CyDecompAt: created, body 10002d88-10002dcf

undefined4 _GetValue__9T7AdapterFl(undefined4 param_1,int param_2)

{
  undefined4 uVar1;
  
  if (param_2 == 0) {
    uVar1 = 0;
  }
  else {
    uVar1 = FUN_100c50e8(param_2);
  }
  return uVar1;
}


// ==== .GetValue__8T7WidgetFv @ 10002dfc ====
// CyDecompAt: created, body 10002dfc-10002e03

undefined4 _GetValue__8T7WidgetFv(void)

{
  return 0;
}


// ==== .GetReference__9T7AdapterFl @ 10002e2c ====
// CyDecompAt: created, body 10002e2c-10002e43

undefined4 _GetReference__9T7AdapterFl(undefined4 param_1,int param_2)

{
  if (param_2 == 0) {
    return 0;
  }
  return *(undefined4 *)(param_2 + 4);
}


// ==== .Activate__9T7AdapterFl @ 10002e74 ====
// CyDecompAt: created, body 10002e74-10002eb3

void _Activate__9T7AdapterFl(undefined4 param_1,int param_2)

{
  if (param_2 != 0) {
    FUN_100c50e8(param_2);
  }
  return;
}


// ==== .Activate__8T7WidgetFv @ 10002ee0 ====
// CyDecompAt: created, body 10002ee0-10002ee3

void _Activate__8T7WidgetFv(void)

{
  return;
}


// ==== .Deactivate__9T7AdapterFl @ 10002f0c ====
// CyDecompAt: created, body 10002f0c-10002f4b

void _Deactivate__9T7AdapterFl(undefined4 param_1,int param_2)

{
  if (param_2 != 0) {
    FUN_100c50e8(param_2);
  }
  return;
}


// ==== .Deactivate__8T7WidgetFv @ 10002f78 ====
// CyDecompAt: created, body 10002f78-10002f7b

void _Deactivate__8T7WidgetFv(void)

{
  return;
}


// ==== .Enable__9T7AdapterFl @ 10002fa8 ====
// CyDecompAt: created, body 10002fa8-10002fe7

void _Enable__9T7AdapterFl(undefined4 param_1,int param_2)

{
  if (param_2 != 0) {
    FUN_100c50e8(param_2);
  }
  return;
}


// ==== .Enable__8T7WidgetFv @ 10003010 ====
// CyDecompAt: created, body 10003010-10003013

void _Enable__8T7WidgetFv(void)

{
  return;
}


// ==== .Disable__9T7AdapterFl @ 1000303c ====
// CyDecompAt: created, body 1000303c-1000307b

void _Disable__9T7AdapterFl(undefined4 param_1,int param_2)

{
  if (param_2 != 0) {
    FUN_100c50e8(param_2);
  }
  return;
}


// ==== .Disable__8T7WidgetFv @ 100030a4 ====
// CyDecompAt: created, body 100030a4-100030a7

void _Disable__8T7WidgetFv(void)

{
  return;
}


// ==== .Embed__9T7AdapterFl9TApWidget @ 100030d0 ====
// CyDecompAt: created, body 100030d0-1000311f

void _Embed__9T7AdapterFl9TApWidget
               (undefined4 param_1,int param_2,undefined4 param_3,undefined4 param_4)

{
  if (param_2 != 0) {
    FUN_100c50e8(param_2,param_3,param_4);
  }
  return;
}


// ==== .HandleWidgetClick__9T7AdapterFl5PointsP17RoutineDescriptor @ 10003150 ====
// CyDecompAt: created, body 10003150-100031af

undefined4
_HandleWidgetClick__9T7AdapterFl5PointsP17RoutineDescriptor
          (undefined4 param_1,int param_2,undefined4 param_3,short param_4,undefined4 param_5)

{
  undefined4 uVar1;
  
  if (param_2 == 0) {
    uVar1 = 0;
  }
  else {
    uVar1 = FUN_100c50e8(param_2,param_3,(int)param_4,param_5);
  }
  return uVar1;
}


// ==== .CreateRoot__9T7AdapterFP9TApWindow @ 10003200 ====
// CyDecompAt: created, body 10003200-1000327f

void _CreateRoot__9T7AdapterFP9TApWindow(undefined4 *param_1)

{
  undefined4 *puVar1;
  
  puVar1 = (undefined4 *)FUN_100be7c8(0x14);
  if (puVar1 != (undefined4 *)0x0) {
    *puVar1 = &PTR_PTR_100d3cd8;
    puVar1[1] = 0;
    puVar1[2] = 0;
    puVar1[3] = 0;
    puVar1[4] = 0;
  }
  *param_1 = &PTR_PTR_100d3d2c;
  param_1[1] = puVar1;
  return;
}


// ==== .DisposeRoot__9T7AdapterF9TApWidget @ 100032b8 ====
// CyDecompAt: created, body 100032b8-1000330b

void _DisposeRoot__9T7AdapterF9TApWidget(undefined4 param_1,undefined4 param_2,int param_3)

{
  if ((param_3 != 0) && (param_3 != 0)) {
    FUN_100c50e8(param_3,1);
  }
  return;
}


// ==== .NewGroupBox__9T7AdapterFP9TApWindow9TApWidgetlR4RectPCUc @ 10003444 ====
// CyDecompAt: created, body 10003444-1000350f

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _NewGroupBox__9T7AdapterFP9TApWindow9TApWidgetlR4RectPCUc
               (undefined4 *param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6,undefined4 param_7,undefined4 param_8)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x11c);
  if (iVar1 != 0) {
    .debug::___ct__10T7GroupBoxFlR4RectPCUc(iVar1,param_6,param_7,param_8);
  }
  FUN_100c50e8(_DAT_100d940c,iVar1,param_4,param_5);
  *param_1 = &PTR_PTR_100d3d2c;
  param_1[1] = iVar1;
  return;
}


// ==== .NewSlider__9T7AdapterFP9TApWindow9TApWidgetlR4RectPCUcssss @ 1000355c ====
// CyDecompAt: created, body 1000355c-1000364f

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _NewSlider__9T7AdapterFP9TApWindow9TApWidgetlR4RectPCUcssss
               (undefined4 *param_1,undefined4 param_2,int param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6,undefined4 param_7,undefined4 param_8,
               short param_9,short param_10,short param_11)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x18);
  if (iVar1 != 0) {
    .debug::___ct__14T7SliderWidgetFlP4RectPUcP4RectssssP8GrafPort
              (iVar1,param_6,param_7,param_8,0,(int)param_10,(int)param_11,(int)param_9,1,
               *(undefined4 *)(param_3 + 4));
  }
  FUN_100c50e8(_DAT_100d940c,iVar1,param_4,param_5);
  *param_1 = &PTR_PTR_100d3d2c;
  param_1[1] = iVar1;
  return;
}


// ==== .NewCheckBox__9T7AdapterFP9TApWindow9TApWidgetlR4RectPCUcUc @ 100036a0 ====
// CyDecompAt: created, body 100036a0-1000372f

void _NewCheckBox__9T7AdapterFP9TApWindow9TApWidgetlR4RectPCUcUc
               (undefined4 param_1,undefined4 param_2,int param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6,undefined4 param_7,undefined4 param_8,
               undefined1 param_9)

{
  undefined4 uVar1;
  
  uVar1 = .glue::NewControl(*(undefined4 *)(param_3 + 4),param_7,param_8,1,param_9,0,1,1,param_6);
  .debug::_NewT7Control__9T7AdapterF9TApWidgetlPP13ControlRecord
            (param_1,param_2,param_4,param_5,param_6,uVar1);
  return;
}


// ==== .NewPushButton__9T7AdapterFP9TApWindow9TApWidgetlR4RectPCUc @ 10003780 ====
// CyDecompAt: created, body 10003780-1000380f

void _NewPushButton__9T7AdapterFP9TApWindow9TApWidgetlR4RectPCUc
               (undefined4 param_1,undefined4 param_2,int param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6,undefined4 param_7,undefined4 param_8)

{
  undefined4 uVar1;
  
  uVar1 = .glue::NewControl(*(undefined4 *)(param_3 + 4),param_7,param_8,1,0,0,1,0,param_6);
  .debug::_NewT7Control__9T7AdapterF9TApWidgetlPP13ControlRecord
            (param_1,param_2,param_4,param_5,param_6,uVar1);
  return;
}


// ==== .NewStaticIcon__9T7AdapterFP9TApWindow9TApWidgetlR4Rects @ 10003860 ====
// CyDecompAt: created, body 10003860-1000392b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _NewStaticIcon__9T7AdapterFP9TApWindow9TApWidgetlR4Rects
               (undefined4 *param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6,undefined4 param_7,short param_8)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x20);
  if (iVar1 != 0) {
    .debug::___ct__12T7IconWidgetFlR4Rects(iVar1,param_6,param_7,(int)param_8);
  }
  FUN_100c50e8(_DAT_100d940c,iVar1,param_4,param_5);
  *param_1 = &PTR_PTR_100d3d2c;
  param_1[1] = iVar1;
  return;
}


// ==== .NewStaticText__9T7AdapterFP9TApWindow9TApWidgetlR4RectPCUcs @ 10003978 ====
// CyDecompAt: created, body 10003978-10003a53

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _NewStaticText__9T7AdapterFP9TApWindow9TApWidgetlR4RectPCUcs
               (undefined4 *param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6,undefined4 param_7,undefined4 param_8,
               short param_9)

{
  undefined **ppuStack_20;
  int iStack_1c;
  
  iStack_1c = FUN_100be7c8(0x120);
  if (iStack_1c != 0) {
    .debug::___ct__13T7LabelWidgetFlR4RectPCUc(iStack_1c,param_6,param_7,param_8);
  }
  ppuStack_20 = &PTR_PTR_100d3d2c;
  .debug::_SetFont__9TApWidgetFss(&ppuStack_20,0,(int)param_9);
  FUN_100c50e8(_DAT_100d940c,iStack_1c,param_4,param_5);
  *param_1 = &PTR_PTR_100d3d2c;
  param_1[1] = iStack_1c;
  return;
}


// ==== .FindWidgetUnderMouse__9T7AdapterFP9TApWindow5PointPs @ 10003aa4 ====
// CyDecompAt: created, body 10003aa4-10003b1f

void _FindWidgetUnderMouse__9T7AdapterFP9TApWindow5PointPs
               (undefined4 *param_1,undefined4 param_2,int param_3,undefined4 param_4,
               undefined4 param_5)

{
  if (*(int *)(param_3 + 0x10) == 0) {
    *param_1 = &PTR_PTR_100d3d2c;
    param_1[1] = 0;
  }
  else {
    FUN_100c50e8(param_1,*(undefined4 *)(param_3 + 0x10),param_4,param_5);
  }
  return;
}


// ==== .DrawRoutine__9T7AdapterFP9TApWindow @ 10003b68 ====
// CyDecompAt: created, body 10003b68-10003baf

void _DrawRoutine__9T7AdapterFP9TApWindow(undefined4 param_1,int param_2)

{
  if (*(int *)(param_2 + 0x10) != 0) {
    FUN_100c50e8();
  }
  return;
}


// ==== .ActivateRoutine__9T7AdapterFP9TApWindow @ 10003be8 ====
// CyDecompAt: created, body 10003be8-10003beb

void _ActivateRoutine__9T7AdapterFP9TApWindow(void)

{
  return;
}


// ==== .DeactivateRoutine__9T7AdapterFP9TApWindow @ 10003c28 ====
// CyDecompAt: created, body 10003c28-10003c2b

void _DeactivateRoutine__9T7AdapterFP9TApWindow(void)

{
  return;
}


// ==== .KeyRoutine__9T7AdapterFP9TApWindows @ 10003c68 ====
// CyDecompAt: created, body 10003c68-10003c6b

void _KeyRoutine__9T7AdapterFP9TApWindows(void)

{
  return;
}


// ==== .IdleRoutine__9T7AdapterFP9TApWindow @ 10003ca4 ====
// CyDecompAt: created, body 10003ca4-10003ca7

void _IdleRoutine__9T7AdapterFP9TApWindow(void)

{
  return;
}


// ==== .MouseRoutine__9TApWindowF5Points @ 10003f4c ====
// CyDecompAt: created, body 10003f4c-1000409b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _MouseRoutine__9TApWindowF5Points(undefined4 param_1,undefined4 param_2,short param_3)

{
  int iVar1;
  undefined4 uVar2;
  undefined1 auStack_28 [4];
  int iStack_24;
  undefined **ppuStack_20;
  int iStack_1c;
  short asStack_18 [6];
  
  FUN_100c50e8(auStack_28,_DAT_100d940c,param_1,param_2,asStack_18);
  ppuStack_20 = &PTR_PTR_100d3d2c;
  iStack_1c = iStack_24;
  if ((iStack_24 != 0) &&
     (asStack_18[0] = FUN_100c50e8(_DAT_100d940c,iStack_24,param_2,(int)param_3,0xffffffff),
     asStack_18[0] != 0)) {
    if (asStack_18[0] == 0xb) {
      iVar1 = FUN_100c50e8(_DAT_100d940c,iStack_1c);
      FUN_100c50e8(_DAT_100d940c,iStack_1c,1 - iVar1);
    }
    uVar2 = FUN_100c50e8(_DAT_100d940c,iStack_1c);
    FUN_100c50e8(param_1,ppuStack_20,iStack_1c,uVar2,(int)asStack_18[0]);
  }
  return;
}


// ==== .DrawRoutine__9TApWindowFv @ 100040d0 ====
// CyDecompAt: created, body 100040d0-1000410b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DrawRoutine__9TApWindowFv(undefined4 param_1)

{
  FUN_100c50e8(_DAT_100d940c,param_1);
  return;
}


// ==== .ActivateRoutine__9TApWindowFv @ 10004138 ====
// CyDecompAt: created, body 10004138-10004173

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _ActivateRoutine__9TApWindowFv(undefined4 param_1)

{
  FUN_100c50e8(_DAT_100d940c,param_1);
  return;
}


// ==== .DeactivateRoutine__9TApWindowFv @ 100041a4 ====
// CyDecompAt: created, body 100041a4-100041df

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DeactivateRoutine__9TApWindowFv(undefined4 param_1)

{
  FUN_100c50e8(_DAT_100d940c,param_1);
  return;
}


// ==== .KeyRoutine__9TApWindowFs @ 10004214 ====
// CyDecompAt: created, body 10004214-10004257

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _KeyRoutine__9TApWindowFs(undefined4 param_1,short param_2)

{
  FUN_100c50e8(_DAT_100d940c,param_1,(int)param_2);
  return;
}


// ==== .IdleRoutine__9TApWindowFv @ 10004284 ====
// CyDecompAt: created, body 10004284-100042bf

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _IdleRoutine__9TApWindowFv(undefined4 param_1)

{
  FUN_100c50e8(_DAT_100d940c,param_1);
  return;
}


// ==== .ActivateRoutine__8T7WidgetFv @ 100042ec ====
// CyDecompAt: created, body 100042ec-100042ef

void _ActivateRoutine__8T7WidgetFv(void)

{
  return;
}


// ==== .DeactivateRoutine__8T7WidgetFv @ 10004320 ====
// CyDecompAt: created, body 10004320-10004323

void _DeactivateRoutine__8T7WidgetFv(void)

{
  return;
}


// ==== .KeyRoutine__8T7WidgetFs @ 10004358 ====
// CyDecompAt: created, body 10004358-1000435b

void _KeyRoutine__8T7WidgetFs(void)

{
  return;
}


// ==== .IdleRoutine__8T7WidgetFv @ 10004388 ====
// CyDecompAt: created, body 10004388-1000438b

void _IdleRoutine__8T7WidgetFv(void)

{
  return;
}


// ==== .__dt__13T7LabelWidgetFv @ 100043b8 ====
// CyDecompAt: created, body 100043b8-10004463

undefined4 * ___dt__13T7LabelWidgetFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d3ae0;
    if ((((param_1 != (undefined4 *)0x0) &&
         (*param_1 = &PTR_PTR_100d3cd8, param_1 != (undefined4 *)0xfffffff8)) &&
        (param_1 != (undefined4 *)0xfffffff8)) && (param_1[4] != 0)) {
      FUN_100be848(param_1[4]);
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__10T7GroupBoxFv @ 10004490 ====
// CyDecompAt: created, body 10004490-1000453b

undefined4 * ___dt__10T7GroupBoxFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d3ba0;
    if ((((param_1 != (undefined4 *)0x0) &&
         (*param_1 = &PTR_PTR_100d3cd8, param_1 != (undefined4 *)0xfffffff8)) &&
        (param_1 != (undefined4 *)0xfffffff8)) && (param_1[4] != 0)) {
      FUN_100be848(param_1[4]);
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__15T7ControlWidgetFv @ 10004564 ====
// CyDecompAt: created, body 10004564-1000460f

undefined4 * ___dt__15T7ControlWidgetFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d3c00;
    if ((((param_1 != (undefined4 *)0x0) &&
         (*param_1 = &PTR_PTR_100d3cd8, param_1 != (undefined4 *)0xfffffff8)) &&
        (param_1 != (undefined4 *)0xfffffff8)) && (param_1[4] != 0)) {
      FUN_100be848(param_1[4]);
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .what__Q23std9bad_allocCFv @ 10004640 ====
// CyDecompAt: created, body 10004640-10004647

undefined * _what__Q23std9bad_allocCFv(void)

{
  return PTR_s_Allocation_Failure_100ce188;
}


// ==== .what__Q23std11logic_errorCFv @ 10004674 ====
// CyDecompAt: created, body 10004674-100046ab

undefined4 _what__Q23std11logic_errorCFv(int param_1)

{
  return *(undefined4 *)(param_1 + 4);
}


// ==== .what__Q23std9exceptionCFv @ 100046dc ====
// CyDecompAt: created, body 100046dc-100046e3

undefined * _what__Q23std9exceptionCFv(void)

{
  return PTR_s_exception_100ce184;
}


// ==== .DisposeRoot__9TApWidgetFv @ 10004710 ====
// CyDecompAt: created, body 10004710-10004753

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DisposeRoot__9TApWidgetFv(undefined4 *param_1)

{
  FUN_100c50e8(_DAT_100d940c,*param_1,param_1[1]);
  return;
}


// ==== .Activate__9TApWidgetFv @ 10004780 ====
// CyDecompAt: created, body 10004780-100047bf

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Activate__9TApWidgetFv(int param_1)

{
  FUN_100c50e8(_DAT_100d940c,*(undefined4 *)(param_1 + 4));
  return;
}


// ==== .Deactivate__9TApWidgetFv @ 100047ec ====
// CyDecompAt: created, body 100047ec-1000482b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Deactivate__9TApWidgetFv(int param_1)

{
  FUN_100c50e8(_DAT_100d940c,*(undefined4 *)(param_1 + 4));
  return;
}


// ==== .Enable__9TApWidgetFv @ 10004858 ====
// CyDecompAt: created, body 10004858-10004897

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Enable__9TApWidgetFv(int param_1)

{
  FUN_100c50e8(_DAT_100d940c,*(undefined4 *)(param_1 + 4));
  return;
}


// ==== .Disable__9TApWidgetFv @ 100048c0 ====
// CyDecompAt: created, body 100048c0-100048ff

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Disable__9TApWidgetFv(int param_1)

{
  FUN_100c50e8(_DAT_100d940c,*(undefined4 *)(param_1 + 4));
  return;
}


// ==== .SetValue__9TApWidgetFs @ 10004928 ====
// CyDecompAt: created, body 10004928-1000496f

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetValue__9TApWidgetFs(int param_1,short param_2)

{
  FUN_100c50e8(_DAT_100d940c,*(undefined4 *)(param_1 + 4),(int)param_2);
  return;
}


// ==== .GetValue__9TApWidgetFv @ 1000499c ====
// CyDecompAt: created, body 1000499c-100049db

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _GetValue__9TApWidgetFv(int param_1)

{
  FUN_100c50e8(_DAT_100d940c,*(undefined4 *)(param_1 + 4));
  return;
}


// ==== .GetReference__9TApWidgetFv @ 10004a08 ====
// CyDecompAt: created, body 10004a08-10004a47

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _GetReference__9TApWidgetFv(int param_1)

{
  FUN_100c50e8(_DAT_100d940c,*(undefined4 *)(param_1 + 4));
  return;
}


// ==== .Embed__9TApWidgetF9TApWidget @ 10004a78 ====
// CyDecompAt: created, body 10004a78-10004ac7

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Embed__9TApWidgetF9TApWidget(int param_1,undefined4 param_2,undefined4 param_3)

{
  FUN_100c50e8(_DAT_100d940c,*(undefined4 *)(param_1 + 4),param_2,param_3);
  return;
}


// ==== .HandleWidgetClick__9TApWidgetF5PointsP17RoutineDescriptor @ 10004af8 ====
// CyDecompAt: created, body 10004af8-10004b4f

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleWidgetClick__9TApWidgetF5PointsP17RoutineDescriptor
               (int param_1,undefined4 param_2,short param_3,undefined4 param_4)

{
  FUN_100c50e8(_DAT_100d940c,*(undefined4 *)(param_1 + 4),param_2,(int)param_3,param_4);
  return;
}


// ==== .MyDrawDialogItem @ 10009344 ====
// CyDecompAt: created, body 10009344-1000939b

void _MyDrawDialogItem(undefined4 param_1,short param_2)

{
  int iVar1;
  
  iVar1 = .debug::_GetTWindow__7TWindowFP8GrafPort(param_1);
  if (iVar1 != 0) {
    FUN_100c50e8(iVar1,(int)param_2);
  }
  return;
}


// ==== .DrawRoutine__7TWindowFv @ 10009518 ====
// CyDecompAt: created, body 10009518-1000951b

void _DrawRoutine__7TWindowFv(void)

{
  return;
}


// ==== .DialogDrawRoutine__7TDialogFs @ 100095a4 ====
// CyDecompAt: created, body 100095a4-100095a7

void _DialogDrawRoutine__7TDialogFs(void)

{
  return;
}


// ==== .ActivateRoutine__7TWindowFv @ 100095d8 ====
// CyDecompAt: created, body 100095d8-100095db

void _ActivateRoutine__7TWindowFv(void)

{
  return;
}


// ==== .ActivateRoutine__7TDialogFv @ 1000960c ====
// CyDecompAt: created, body 1000960c-1000969f

void _ActivateRoutine__7TDialogFv(int param_1)

{
  undefined *puVar1;
  char cVar2;
  undefined4 uStack_18;
  short asStack_14 [4];
  
  puVar1 = PTR_DAT_100cdb84;
  uStack_18 = *(undefined4 *)(param_1 + 4);
  *(undefined2 *)(*(int *)(param_1 + 4) + 0x6c) = 2;
  cVar2 = .glue::DialogSelect(*(int *)puVar1 + 4,&uStack_18,asStack_14);
  if (cVar2 != '\0') {
    FUN_100c50e8(param_1,(int)asStack_14[0]);
  }
  *(undefined2 *)(*(int *)(param_1 + 4) + 0x6c) = 0x7a84;
  return;
}


// ==== .DeactivateRoutine__7TWindowFv @ 100096d0 ====
// CyDecompAt: created, body 100096d0-100096d3

void _DeactivateRoutine__7TWindowFv(void)

{
  return;
}


// ==== .DeactivateRoutine__7TDialogFv @ 10009704 ====
// CyDecompAt: created, body 10009704-10009797

void _DeactivateRoutine__7TDialogFv(int param_1)

{
  undefined *puVar1;
  char cVar2;
  undefined4 uStack_18;
  short asStack_14 [4];
  
  puVar1 = PTR_DAT_100cdb84;
  uStack_18 = *(undefined4 *)(param_1 + 4);
  *(undefined2 *)(*(int *)(param_1 + 4) + 0x6c) = 2;
  cVar2 = .glue::DialogSelect(*(int *)puVar1 + 4,&uStack_18,asStack_14);
  if (cVar2 != '\0') {
    FUN_100c50e8(param_1,(int)asStack_14[0]);
  }
  *(undefined2 *)(*(int *)(param_1 + 4) + 0x6c) = 0x7a84;
  return;
}


// ==== .MenuRoutine__7TWindowFss @ 100097c8 ====
// CyDecompAt: created, body 100097c8-100097cf

undefined4 _MenuRoutine__7TWindowFss(void)

{
  return 0;
}


// ==== .CloseRoutine__7TWindowFv @ 1000987c ====
// CyDecompAt: created, body 1000987c-100098af

void _CloseRoutine__7TWindowFv(void)

{
  FUN_100c50e8();
  return;
}


// ==== .MouseRoutine__7TWindowF5Points @ 100098dc ====
// CyDecompAt: created, body 100098dc-100098df

void _MouseRoutine__7TWindowF5Points(void)

{
  return;
}


// ==== .DialogItemRoutine__7TDialogFs @ 100099dc ====
// CyDecompAt: created, body 100099dc-100099df

void _DialogItemRoutine__7TDialogFs(void)

{
  return;
}


// ==== .DialogKeyEquiv__7TDialogFs @ 10009a10 ====
// CyDecompAt: created, body 10009a10-10009ac3

void _DialogKeyEquiv__7TDialogFs(int param_1,undefined4 param_2)

{
  undefined1 auStack_28 [4];
  undefined1 auStack_24 [8];
  ushort auStack_1c [2];
  undefined4 auStack_18 [4];
  
  .glue::GetDialogItem(*(undefined4 *)(param_1 + 4),param_2,auStack_1c,auStack_18,auStack_24);
  if ((3 < (short)(auStack_1c[0] & 0xff7f)) && ((short)(auStack_1c[0] & 0xff7f) < 8)) {
    .glue::HiliteControl(auStack_18[0],10);
    .glue::Delay(8,auStack_28);
    .glue::HiliteControl(auStack_18[0],0);
  }
  FUN_100c50e8(param_1,param_2);
  return;
}


// ==== .KeyRoutine__7TWindowFs @ 10009af4 ====
// CyDecompAt: created, body 10009af4-10009bdf

void _KeyRoutine__7TWindowFs(undefined4 param_1,short param_2)

{
  if (param_2 == 0x101) {
    FUN_100c50e8(param_1,0xc);
  }
  else if (param_2 < 0x101) {
    if (param_2 == 8) {
      FUN_100c50e8(param_1,0xf);
    }
    else if ((7 < param_2) && (0xff < param_2)) {
      FUN_100c50e8(param_1,0xb);
    }
  }
  else if (param_2 == 0x103) {
    FUN_100c50e8(param_1,0xe);
  }
  else if (param_2 < 0x103) {
    FUN_100c50e8(param_1,0xd);
  }
  return;
}


// ==== .KeyRoutine__7TDialogFs @ 10009c0c ====
// CyDecompAt: created, body 10009c0c-10009cfb

void _KeyRoutine__7TDialogFs(int param_1,short param_2)

{
  undefined *puVar1;
  char cVar2;
  undefined4 uStack_18;
  short asStack_14 [4];
  
  puVar1 = PTR_DAT_100cdb84;
  if (param_2 == 0x102) {
    .glue::DialogCopy(*(undefined4 *)(param_1 + 4));
  }
  else {
    if (param_2 < 0x102) {
      if (0x100 < param_2) {
        .glue::DialogCut(*(undefined4 *)(param_1 + 4));
        return;
      }
    }
    else if (param_2 < 0x104) {
      .glue::DialogPaste(*(undefined4 *)(param_1 + 4));
      return;
    }
    uStack_18 = *(undefined4 *)(param_1 + 4);
    *(undefined2 *)(*(int *)(param_1 + 4) + 0x6c) = 2;
    cVar2 = .glue::DialogSelect(*(int *)puVar1 + 4,&uStack_18,asStack_14);
    if (cVar2 != '\0') {
      FUN_100c50e8(param_1,(int)asStack_14[0]);
    }
    *(undefined2 *)(*(int *)(param_1 + 4) + 0x6c) = 0x7a84;
  }
  return;
}


// ==== .CommandRoutine__7TDialogFl @ 10009d28 ====
// CyDecompAt: created, body 10009d28-10009ddb

undefined4 _CommandRoutine__7TDialogFl(int param_1,int param_2)

{
  undefined4 uVar1;
  
  if (param_2 == 0xe) {
    .glue::DialogPaste(*(undefined4 *)(param_1 + 4));
    return 1;
  }
  if (param_2 < 0xe) {
    if (param_2 == 0xc) {
      .glue::DialogCut(*(undefined4 *)(param_1 + 4));
      return 1;
    }
    if (0xb < param_2) {
      .glue::DialogCopy(*(undefined4 *)(param_1 + 4));
      return 1;
    }
  }
  else if (param_2 < 0x10) {
    .glue::DialogDelete(*(undefined4 *)(param_1 + 4));
    return 1;
  }
  uVar1 = .debug::_CommandRoutine__7TWindowFl(param_1,param_2);
  return uVar1;
}


// ==== .ResizeRoutine__7TWindowFv @ 10009e0c ====
// CyDecompAt: created, body 10009e0c-10009e0f

void _ResizeRoutine__7TWindowFv(void)

{
  return;
}


// ==== .ZoomRoutine__7TWindowFs @ 10009e3c ====
// CyDecompAt: created, body 10009e3c-10009f07

void _ZoomRoutine__7TWindowFs(int param_1)

{
  if ((*(ushort *)(param_1 + 8) & 0x40) == 0) {
    .glue::SetPort(*(undefined4 *)(param_1 + 4));
    .glue::EraseRect(*(int *)(param_1 + 4) + 0x10);
    .glue::ZoomWindow(*(undefined4 *)(param_1 + 4),7,0);
    FUN_100c50e8(param_1);
  }
  else if (*(short *)(*(int *)(param_1 + 4) + 0x14) == *(short *)(*(int *)(param_1 + 4) + 0x10)) {
    FUN_100c50e8(param_1);
  }
  else {
    FUN_100c50e8(param_1,0x50,0x10);
  }
  return;
}


// ==== .Dock__7TWindowFss @ 10009f34 ====
// CyDecompAt: created, body 10009f34-1000a0d7

void _Dock__7TWindowFss(int param_1,short param_2,short param_3)

{
  bool bVar1;
  short sVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined4 uVar5;
  int *piVar6;
  undefined4 uVar7;
  int iVar8;
  undefined4 *puVar9;
  short sStack_1c;
  undefined4 uStack_18;
  undefined4 uStack_14;
  
  puVar3 = PTR_DAT_100ce294;
  iVar8 = **(int **)(*(int *)(param_1 + 4) + 0x82);
  uVar7 = *(undefined4 *)(iVar8 + 8);
  uVar5 = *(undefined4 *)(iVar8 + 0xc);
  uStack_18._0_2_ = (short)((uint)uVar7 >> 0x10);
  uStack_14._0_2_ = (short)((uint)uVar5 >> 0x10);
  bVar1 = uStack_14._0_2_ != uStack_18._0_2_;
  uStack_18 = uVar7;
  uStack_14 = uVar5;
  if (bVar1) {
    piVar6 = (int *).glue::GetMainDevice();
    puVar4 = PTR_DAT_100ce298;
    uVar5 = *(undefined4 *)(*piVar6 + 0x26);
    sVar2 = (short)uVar5;
    if (*PTR_DAT_100ce298 == '\0') {
      *(undefined2 *)puVar3 = 0;
      *puVar4 = 1;
    }
    *(short *)puVar3 = *(short *)puVar3 + 1;
    uStack_18._0_2_ = *(short *)puVar3 * param_3 + 0x28;
    sStack_1c = (short)((uint)uVar5 >> 0x10);
    if (sStack_1c + -0x14 <= (int)uStack_18._0_2_) {
      *(undefined2 *)puVar3 = 1;
      uStack_18._0_2_ = *(short *)puVar3 * param_3 + 0x28;
    }
    uStack_14 = CONCAT22(uStack_18._0_2_,sVar2);
    uStack_18 = CONCAT22(uStack_18._0_2_,sVar2 - param_2);
    iVar8 = **(int **)(*(int *)(param_1 + 4) + 0x82);
    *(undefined4 *)(iVar8 + 8) = uStack_18;
    *(undefined4 *)(iVar8 + 0xc) = uStack_14;
  }
  puVar9 = (undefined4 *)**(undefined4 **)(*(int *)(param_1 + 4) + 0x82);
  uVar7 = *puVar9;
  uVar5 = puVar9[1];
  .glue::ZoomWindow(*(undefined4 *)(param_1 + 4),8,0);
  puVar9 = (undefined4 *)**(int **)(*(int *)(param_1 + 4) + 0x82);
  *puVar9 = uStack_18;
  puVar9[1] = uStack_14;
  iVar8 = **(int **)(*(int *)(param_1 + 4) + 0x82);
  *(undefined4 *)(iVar8 + 8) = uVar7;
  *(undefined4 *)(iVar8 + 0xc) = uVar5;
  return;
}


// ==== .UnDock__7TWindowFv @ 1000a0fc ====
// CyDecompAt: created, body 1000a0fc-1000a1a7

void _UnDock__7TWindowFv(int param_1)

{
  undefined4 uVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  undefined4 *puVar5;
  int iVar6;
  
  puVar5 = (undefined4 *)**(undefined4 **)(*(int *)(param_1 + 4) + 0x82);
  uVar3 = *puVar5;
  uVar1 = puVar5[1];
  iVar6 = **(int **)(*(int *)(param_1 + 4) + 0x82);
  uVar4 = *(undefined4 *)(iVar6 + 8);
  uVar2 = *(undefined4 *)(iVar6 + 0xc);
  .glue::ZoomWindow(*(undefined4 *)(param_1 + 4),8,0);
  puVar5 = (undefined4 *)**(undefined4 **)(*(int *)(param_1 + 4) + 0x82);
  *puVar5 = uVar4;
  puVar5[1] = uVar2;
  iVar6 = **(int **)(*(int *)(param_1 + 4) + 0x82);
  *(undefined4 *)(iVar6 + 8) = uVar3;
  *(undefined4 *)(iVar6 + 0xc) = uVar1;
  return;
}


// ==== .CursorRoutine__7TWindowF5Points @ 1000a1d0 ====
// CyDecompAt: created, body 1000a1d0-1000a203

void _CursorRoutine__7TWindowF5Points(void)

{
  FUN_100c50e8();
  return;
}


// ==== .IdleRoutine__7TWindowFv @ 1000a238 ====
// CyDecompAt: created, body 1000a238-1000a23b

void _IdleRoutine__7TWindowFv(void)

{
  return;
}


// ==== .IdleRoutine__7TDialogFv @ 1000a268 ====
// CyDecompAt: created, body 1000a268-1000a2fb

void _IdleRoutine__7TDialogFv(int param_1)

{
  undefined *puVar1;
  char cVar2;
  undefined4 uStack_18;
  short asStack_14 [4];
  
  puVar1 = PTR_DAT_100cdb84;
  uStack_18 = *(undefined4 *)(param_1 + 4);
  *(undefined2 *)(*(int *)(param_1 + 4) + 0x6c) = 2;
  cVar2 = .glue::DialogSelect(*(int *)puVar1 + 4,&uStack_18,asStack_14);
  if (cVar2 != '\0') {
    FUN_100c50e8(param_1,(int)asStack_14[0]);
  }
  *(undefined2 *)(*(int *)(param_1 + 4) + 0x6c) = 0x7a84;
  return;
}


// ==== .LoopTask__7TWindowFv @ 1000a328 ====
// CyDecompAt: created, body 1000a328-1000a32b

void _LoopTask__7TWindowFv(void)

{
  return;
}


// ==== .HandleDragWindow__7TWindowF5Point @ 1000a404 ====
// CyDecompAt: created, body 1000a404-1000a7e7

void _HandleDragWindow__7TWindowF5Point(int param_1,undefined4 param_2)

{
  undefined *puVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  short sVar4;
  char cVar8;
  int iVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  int iVar9;
  short sStack_58;
  short sStack_56;
  short sStack_44;
  short sStack_42;
  undefined4 uStack_40;
  undefined4 uStack_3c;
  undefined4 uStack_38;
  int iStack_34;
  undefined4 auStack_30 [3];
  
  puVar1 = PTR_DAT_100cdb84;
  if ((((*(ushort *)(param_1 + 8) & 0x40) == 0) ||
      (*(short *)(*(int *)(param_1 + 4) + 0x14) != *(short *)(*(int *)(param_1 + 4) + 0x10))) &&
     (cVar8 = .glue::WaitMouseUp(), cVar8 != '\0')) {
    .glue::GetPort(auStack_30);
    .glue::GetWMgrPort(&iStack_34);
    .glue::SetPort(iStack_34);
    if (*(char *)(*(int *)puVar1 + 0x67) == '\0') {
      iVar9 = *(int *)(param_1 + 4);
      uVar2 = .glue::NewRgn();
      .glue::CopyRgn(*(undefined4 *)(iVar9 + 0x72),uVar2);
      .glue::GetGrayRgn();
      .glue::SetClip();
      for (iVar5 = .glue::FrontWindow(); iVar5 != iVar9; iVar5 = *(int *)(iVar5 + 0x90)) {
        .glue::DiffRgn(*(undefined4 *)(iStack_34 + 0x1c),*(undefined4 *)(iVar5 + 0x72),
                       *(undefined4 *)(iStack_34 + 0x1c));
      }
      iVar9 = .glue::DragGrayRgn(uVar2,param_2,PTR_DAT_100cdb94 + 0x56,PTR_DAT_100cdb94 + 0x56,0,0);
      .glue::DisposeRgn(uVar2);
      .glue::SetPort(auStack_30[0]);
      sVar4 = (short)((uint)iVar9 >> 0x10);
      if ((iVar9 != -0x7fff8000) && (((short)iVar9 != 0 || (sVar4 != 0)))) {
        uVar2 = *(undefined4 *)(**(int **)(iVar5 + 0x76) + 2);
        sStack_56 = (short)uVar2;
        sStack_58 = (short)((uint)uVar2 >> 0x10);
        .glue::MoveWindow(iVar5,(int)(short)iVar9 + (int)sStack_56,(int)sVar4 + (int)sStack_58,0);
      }
    }
    else {
      .glue::GetGrayRgn();
      .glue::SetClip();
      for (iVar5 = .glue::FrontWindow(); iVar5 != *(int *)(param_1 + 4);
          iVar5 = *(int *)(iVar5 + 0x90)) {
        .glue::DiffRgn(*(undefined4 *)(iStack_34 + 0x1c),*(undefined4 *)(iVar5 + 0x72),
                       *(undefined4 *)(iStack_34 + 0x1c));
      }
      uStack_3c = *(undefined4 *)(*(int *)(param_1 + 4) + 0x10);
      uStack_38 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x14);
      while (cVar8 = .glue::StillDown(), cVar8 != '\0') {
        .glue::GetMouse(&uStack_40);
        sVar4 = (short)((uint)param_2 >> 0x10);
        if ((uStack_40._2_2_ != (short)param_2) || (uStack_40._0_2_ != sVar4)) {
          uVar2 = *(undefined4 *)(**(int **)(iVar5 + 0x76) + 2);
          if (*(char *)(*(int *)puVar1 + 0x68) != '\0') {
            .glue::LMSetPaintWhite(0);
          }
          sStack_44 = (short)((uint)uVar2 >> 0x10);
          sStack_42 = (short)uVar2;
          .glue::MoveWindow(iVar5,((int)sStack_42 + (int)uStack_40._2_2_) - (int)(short)param_2,
                            ((int)sStack_44 + (int)uStack_40._0_2_) - (int)sVar4,0);
          if (*(char *)(*(int *)puVar1 + 0x68) != '\0') {
            .glue::LMSetPaintWhite(0xffffffff);
          }
          param_2 = uStack_40;
          if (*(char *)(*(int *)puVar1 + 0x68) != '\0') {
            if ((*(int *)(iVar5 + 0x7a) != 0) &&
               (cVar8 = .glue::EmptyRgn(*(undefined4 *)(iVar5 + 0x7a)), cVar8 == '\0')) {
              .glue::SetPort(iVar5);
              .glue::BeginUpdate(iVar5);
              FUN_100c50e8(param_1);
              .glue::EndUpdate(iVar5);
              .glue::SetPort(iStack_34);
            }
            iVar9 = *(int *)puVar1;
            uVar6 = *(undefined4 *)(iVar9 + 4);
            uVar2 = *(undefined4 *)(iVar9 + 8);
            uVar7 = *(undefined4 *)(iVar9 + 0xc);
            uVar3 = *(undefined4 *)(iVar9 + 0x10);
            while (cVar8 = .glue::CheckUpdate(*(int *)puVar1 + 4), cVar8 != '\0') {
              FUN_100c50e8();
            }
            iVar9 = *(int *)puVar1;
            *(undefined4 *)(iVar9 + 4) = uVar6;
            *(undefined4 *)(iVar9 + 8) = uVar2;
            *(undefined4 *)(iVar9 + 0xc) = uVar7;
            *(undefined4 *)(iVar9 + 0x10) = uVar3;
            .glue::SetPort(iStack_34);
            param_2 = uStack_40;
          }
        }
      }
      .glue::SetPort(auStack_30[0]);
    }
  }
  return;
}


// ==== .HandleSelectWindow__7TWindowF5Point @ 1000a81c ====
// CyDecompAt: created, body 1000a81c-1000a863

void _HandleSelectWindow__7TWindowF5Point(int param_1)

{
  if ((*(ushort *)(param_1 + 8) & 0x20) == 0) {
    FUN_100c50e8(param_1);
  }
  return;
}


// ==== .GetResizeRect__7TWindowFR4Rect @ 1000a89c ====
// CyDecompAt: created, body 1000a89c-1000a8d7

void _GetResizeRect__7TWindowFR4Rect(undefined4 param_1,undefined4 param_2)

{
  .glue::SetRect(param_2,0x40,0x40,32000,32000);
  return;
}


// ==== .HandleResizeWindow__7TWindowF5Point @ 1000a90c ====
// CyDecompAt: created, body 1000a90c-1000a99f

void _HandleResizeWindow__7TWindowF5Point(int param_1,undefined4 param_2)

{
  uint uVar1;
  undefined1 auStack_18 [16];
  
  FUN_100c50e8(param_1,auStack_18);
  uVar1 = .glue::GrowWindow(*(undefined4 *)(param_1 + 4),param_2,auStack_18);
  if (uVar1 != 0) {
    .glue::SizeWindow(*(undefined4 *)(param_1 + 4),uVar1 & 0xffff,(int)(short)(uVar1 >> 0x10),1);
    FUN_100c50e8(param_1);
  }
  return;
}


// ==== .HandleZoomWindow__7TWindowF5Points @ 1000a9d8 ====
// CyDecompAt: created, body 1000a9d8-1000aa3f

void _HandleZoomWindow__7TWindowF5Points(int param_1,undefined4 param_2,undefined4 param_3)

{
  char cVar1;
  
  cVar1 = .glue::TrackBox(*(undefined4 *)(param_1 + 4),param_2);
  if (cVar1 != '\0') {
    FUN_100c50e8(param_1,param_3);
  }
  return;
}


// ==== .GetOwningGD__7TWindowFPP7GDeviceR4Rect @ 1000ae40 ====
// CyDecompAt: created, body 1000ae40-1000af8b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

int * _GetOwningGD__7TWindowFPP7GDeviceR4Rect(int param_1,int *param_2,undefined4 param_3)

{
  char cVar2;
  int *piVar1;
  int *piVar3;
  uint uVar4;
  uint uVar5;
  undefined4 uStack_38;
  undefined4 uStack_34;
  undefined4 uStack_30;
  undefined4 uStack_2c;
  undefined4 uStack_28;
  undefined4 uStack_24;
  
  uVar4 = 0;
  uStack_28 = _DAT_100d3e8c;
  uStack_24 = uRam100d3e90;
  cVar2 = .glue::SectRect(param_3,*(int *)(param_1 + 4) + 0x10,&uStack_28);
  piVar3 = (int *)0x0;
  if (cVar2 != '\0') {
    uVar4 = ((int)uStack_24._2_2_ - (int)uStack_28._2_2_) *
            ((int)uStack_24._0_2_ - (int)uStack_28._0_2_);
    piVar3 = param_2;
  }
  for (piVar1 = (int *).glue::GetDeviceList(); piVar1 != (int *)0x0;
      piVar1 = (int *).glue::GetNextDevice(piVar1)) {
    cVar2 = .glue::TestDeviceAttribute(piVar1,0xd);
    if (cVar2 != '\0') {
      uStack_30 = *(undefined4 *)(*piVar1 + 0x22);
      uStack_2c = *(undefined4 *)(*piVar1 + 0x26);
      uStack_38 = _DAT_100d3e94;
      uStack_34 = uRam100d3e98;
      cVar2 = .glue::SectRect(&uStack_30,*(int *)(param_1 + 4) + 0x10,&uStack_38);
      if ((cVar2 != '\0') &&
         (uVar5 = ((int)uStack_34._2_2_ - (int)uStack_38._2_2_) *
                  ((int)uStack_34._0_2_ - (int)uStack_38._0_2_), uVar4 <= uVar5)) {
        piVar3 = piVar1;
        uVar4 = uVar5;
      }
    }
  }
  return piVar3;
}


// ==== .ForceOnGDevice__7TWindowFPP7GDevice @ 1000afc8 ====
// CyDecompAt: created, body 1000afc8-1000b157

void _ForceOnGDevice__7TWindowFPP7GDevice(int param_1,undefined4 param_2)

{
  int iVar1;
  int iVar2;
  short sStack_28;
  short sStack_26;
  short sStack_24;
  short sStack_22;
  undefined4 uStack_20;
  undefined4 uStack_1c;
  undefined4 uStack_18;
  undefined4 uStack_14;
  
  uStack_18 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x10);
  uStack_14 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x14);
  .glue::LocalToGlobal(&uStack_18);
  .glue::LocalToGlobal(&uStack_14);
  uStack_20 = uStack_18;
  uStack_1c = uStack_14;
  FUN_100c50e8(*(undefined4 *)PTR_DAT_100cdb84,param_2,&sStack_28);
  .glue::InsetRect(&sStack_28,10,10);
  .glue::SectRect(&uStack_18,&sStack_28,&uStack_20);
  if (((int)uStack_1c._2_2_ - (int)uStack_20._2_2_ < 0x20) ||
     ((int)uStack_1c._0_2_ - (int)uStack_20._0_2_ < 0x20)) {
    iVar1 = (int)uStack_18._0_2_;
    iVar2 = (int)uStack_18._2_2_;
    if (sStack_22 < uStack_14._2_2_) {
      iVar2 = iVar2 - ((int)uStack_14._2_2_ - (int)sStack_22);
    }
    if (sStack_24 < uStack_14._0_2_) {
      iVar1 = iVar1 - ((int)uStack_14._0_2_ - (int)sStack_24);
    }
    if ((short)iVar2 < sStack_26) {
      iVar2 = (int)sStack_26;
    }
    if ((short)iVar1 < sStack_28) {
      iVar1 = (int)sStack_28;
    }
    .glue::MoveWindow(*(undefined4 *)(param_1 + 4),iVar2,iVar1,0);
  }
  return;
}


// ==== .Select__7TWindowFv @ 1000b384 ====
// CyDecompAt: created, body 1000b384-1000b573

/* WARNING: Removing unreachable block (ram,0x1000b3c0) */

void _Select__7TWindowFv(int param_1)

{
  ushort uVar1;
  int iVar2;
  
  uVar1 = *(ushort *)(param_1 + 8) & 7;
  if (uVar1 == 1) {
    iVar2 = .debug::_FindLayer__7TWindowFUcs(1,1);
    if (iVar2 != param_1) {
      iVar2 = .debug::_FindLayer__7TWindowFUcs(0,3);
      if (iVar2 == 0) {
        .glue::BringToFront(*(undefined4 *)(param_1 + 4));
      }
      else {
        .glue::SendBehind(*(undefined4 *)(param_1 + 4),*(undefined4 *)(iVar2 + 4));
      }
      .glue::ShowHide(*(undefined4 *)(param_1 + 4),1);
    }
  }
  else if (uVar1 == 0) {
    iVar2 = .debug::_FindLayer__7TWindowFUcs(1,0);
    if (iVar2 == param_1) {
      .glue::ShowHide(*(undefined4 *)(param_1 + 4),1);
      FUN_100c50e8(param_1,0);
    }
    else {
      iVar2 = .debug::_FindLayer__7TWindowFUcs(1,0);
      if (iVar2 != 0) {
        FUN_100c50e8(iVar2,0);
      }
      iVar2 = .debug::_FindLayer__7TWindowFUcs(0,1);
      if (iVar2 == 0) {
        iVar2 = .debug::_FindLayer__7TWindowFUcs(0,3);
      }
      if (iVar2 == 0) {
        .glue::BringToFront(*(undefined4 *)(param_1 + 4));
      }
      else {
        .glue::SendBehind(*(undefined4 *)(param_1 + 4),*(undefined4 *)(iVar2 + 4));
      }
      .glue::ShowHide(*(undefined4 *)(param_1 + 4),1);
      FUN_100c50e8(param_1,0);
    }
  }
  .glue::SetPort(*(undefined4 *)(param_1 + 4));
  .glue::BeginUpdate(*(undefined4 *)(param_1 + 4));
  FUN_100c50e8(param_1);
  .glue::EndUpdate(*(undefined4 *)(param_1 + 4));
  return;
}


// ==== .HandleActivate__7TWindowFs @ 1000b954 ====
// CyDecompAt: created, body 1000b954-1000ba47

/* WARNING: Removing unreachable block (ram,0x1000b9c8) */

void _HandleActivate__7TWindowFs(int param_1,ushort param_2)

{
  ushort uVar1;
  int iVar2;
  
  if (*(char *)(*(int *)(param_1 + 4) + 0x6f) == '\0') {
    if ((*(ushort *)(param_1 + 8) & param_2) != 0) {
      *(ushort *)(param_1 + 8) = *(ushort *)(param_1 + 8) & 0xbfff;
      .glue::ShowHide(*(undefined4 *)(param_1 + 4),0);
    }
    uVar1 = *(ushort *)(param_1 + 8) & 7;
    if (uVar1 == 1) {
      .glue::HiliteWindow(*(undefined4 *)(param_1 + 4),1);
      FUN_100c50e8(param_1);
    }
    else if ((uVar1 == 0) && (iVar2 = .debug::_FindLayer__7TWindowFUcs(1,0), param_1 == iVar2)) {
      .glue::HiliteWindow(*(undefined4 *)(param_1 + 4),1);
      FUN_100c50e8(param_1);
    }
  }
  return;
}


// ==== .HandleDeactivate__7TWindowFs @ 1000ba78 ====
// CyDecompAt: created, body 1000ba78-1000bb7f

/* WARNING: Removing unreachable block (ram,0x1000bac0) */

void _HandleDeactivate__7TWindowFs(int param_1,ushort param_2)

{
  ushort uVar1;
  int iVar2;
  
  if (*(char *)(*(int *)(param_1 + 4) + 0x6f) != '\0') {
    uVar1 = *(ushort *)(param_1 + 8) & 7;
    if (uVar1 == 1) {
      .glue::HiliteWindow(*(undefined4 *)(param_1 + 4),0);
      FUN_100c50e8(param_1);
    }
    else if (((uVar1 == 0) && (iVar2 = .debug::_FindLayer__7TWindowFUcs(1,0), param_1 == iVar2)) &&
            (*(char *)(*(int *)PTR_DAT_100cdb84 + 0x65) == '\0')) {
      .glue::HiliteWindow(*(undefined4 *)(param_1 + 4),0);
      FUN_100c50e8(param_1);
    }
    if ((*(ushort *)(param_1 + 8) & param_2) != 0) {
      *(ushort *)(param_1 + 8) = *(ushort *)(param_1 + 8) | 0x4000;
      .glue::ShowHide(*(undefined4 *)(param_1 + 4),0);
    }
  }
  return;
}


// ==== .ChangeMenuBar__4TAppFs @ 1000bfe4 ====
// CyDecompAt: created, body 1000bfe4-1000c13b

void _ChangeMenuBar__4TAppFs(int param_1,int param_2)

{
  short sVar1;
  int *piVar2;
  int iVar3;
  undefined2 uVar4;
  short sVar5;
  
  .glue::ClearMenuBar();
  piVar2 = (int *).glue::GetResource(0x4d424152,param_2);
  if (piVar2 != (int *)0x0) {
    sVar1 = *(short *)*piVar2;
    for (sVar5 = 0; sVar5 < sVar1; sVar5 = sVar5 + 1) {
      .debug::_CreateMenu__12TCommandMenuFss((int)*(short *)(*piVar2 + (sVar5 + 1) * 2),0);
    }
  }
  piVar2 = (int *).glue::GetResource(0x4d424152,param_2 + 1);
  if (piVar2 != (int *)0x0) {
    sVar1 = *(short *)*piVar2;
    for (sVar5 = 0; sVar5 < sVar1; sVar5 = sVar5 + 1) {
      .debug::_CreateMenu__12TCommandMenuFss((int)*(short *)(*piVar2 + (sVar5 + 1) * 2),0xffffffff);
    }
  }
  iVar3 = .glue::GetMenuHandle(1);
  if (iVar3 == 0) {
    iVar3 = .glue::GetMenuHandle(0x80);
  }
  if (iVar3 != 0) {
    uVar4 = .glue::CountMItems(iVar3);
    *(undefined2 *)(param_1 + 0x38) = uVar4;
    if (*(short *)(param_1 + 0x38) < 5) {
      .glue::AppendResMenu(iVar3,0x44525652);
    }
  }
  .glue::DrawMenuBar();
  return;
}


// ==== .HandleOpenDocuments @ 1000c228 ====
// CyDecompAt: created, body 1000c228-1000c38b

undefined4 _HandleOpenDocuments(undefined4 param_1)

{
  undefined *puVar1;
  undefined4 uVar2;
  int iVar3;
  undefined1 auStack_78 [4];
  undefined1 auStack_74 [72];
  undefined1 auStack_2c [4];
  undefined1 auStack_28 [4];
  int iStack_24;
  undefined1 auStack_20 [16];
  
  puVar1 = PTR_DAT_100cdb84;
  uVar2 = .glue::AEGetParamDesc(param_1,0x2d2d2d2d,0x6c697374,auStack_20);
  if ((((short)uVar2 == 0) &&
      (uVar2 = .debug::_CheckAppleEventForMissingParams__FP6AEDesc(param_1), (short)uVar2 == 0)) &&
     (uVar2 = .glue::AECountItems(auStack_20,&iStack_24), (short)uVar2 == 0)) {
    *PTR_DAT_100ce284 = 1;
    for (iVar3 = 1; iVar3 <= iStack_24; iVar3 = iVar3 + 1) {
      uVar2 = .glue::AESizeOfNthItem(auStack_20,iVar3,auStack_28,auStack_2c);
      if ((short)uVar2 != 0) {
        return uVar2;
      }
      uVar2 = .glue::AEGetNthPtr(auStack_20,iVar3,0x66737320,auStack_78,auStack_28,auStack_74,0x46,
                                 auStack_2c);
      if ((short)uVar2 == 0) {
        FUN_100c50e8(*(undefined4 *)puVar1,auStack_74);
      }
    }
    .glue::AEDisposeDesc(auStack_20);
  }
  return uVar2;
}


// ==== .HandleQuitApplication @ 1000c3b4 ====
// CyDecompAt: created, body 1000c3b4-1000c43b

undefined4 _HandleQuitApplication(undefined4 param_1)

{
  undefined *puVar1;
  undefined4 uVar2;
  undefined1 uVar3;
  
  puVar1 = PTR_DAT_100cdb84;
  uVar2 = .debug::_CheckAppleEventForMissingParams__FP6AEDesc(param_1);
  if ((short)uVar2 == 0) {
    uVar3 = FUN_100c50e8();
    *(undefined1 *)(*(int *)puVar1 + 0x1c) = uVar3;
    if (*(char *)(*(int *)puVar1 + 0x1c) == '\0') {
      uVar2 = 0xffffff80;
    }
    else {
      uVar2 = 0;
    }
  }
  return uVar2;
}


// ==== .HandleOpenApplication @ 1000c464 ====
// CyDecompAt: created, body 1000c464-1000c4cf

undefined4 _HandleOpenApplication(undefined4 param_1)

{
  undefined4 uVar1;
  
  uVar1 = .debug::_CheckAppleEventForMissingParams__FP6AEDesc(param_1);
  if ((short)uVar1 == 0) {
    *PTR_DAT_100ce284 = 1;
    FUN_100c50e8();
    uVar1 = 0;
  }
  return uVar1;
}


// ==== .HandleDisplayNotice @ 1000c4f8 ====
// CyDecompAt: created, body 1000c4f8-1000c693

undefined4 _HandleDisplayNotice(undefined4 param_1)

{
  undefined *puVar1;
  undefined4 uStack_58;
  undefined4 uStack_54;
  undefined1 auStack_50 [8];
  undefined1 auStack_48 [8];
  int aiStack_40 [2];
  undefined1 auStack_38 [4];
  undefined1 auStack_34 [4];
  undefined1 auStack_30 [8];
  undefined1 auStack_28 [8];
  undefined1 auStack_20 [8];
  undefined1 auStack_18 [16];
  
  puVar1 = PTR_DAT_100cdb84;
  .glue::AEGetParamDesc(param_1,0x6473706c,0x2a2a2a2a,auStack_18);
  .glue::AECountItems(auStack_18,aiStack_40);
  for (; 0 < aiStack_40[0]; aiStack_40[0] = aiStack_40[0] + -1) {
    uStack_54 = 8;
    .glue::AEGetNthDesc(auStack_18,aiStack_40[0],0x2a2a2a2a,auStack_34,auStack_20);
    .glue::AEGetNthDesc(auStack_20,1,0x2a2a2a2a,auStack_34,auStack_28);
    .glue::AEGetParamPtr(auStack_28,0x64646472,0x2a2a2a2a,auStack_38,auStack_48,8,&uStack_54);
    .glue::AEGetParamPtr(auStack_28,0x646d6464,0x2a2a2a2a,auStack_38,&uStack_58,4,&uStack_54);
    .glue::AEGetNthDesc(auStack_20,2,0x2a2a2a2a,auStack_34,auStack_30);
    .glue::AEGetParamPtr(auStack_30,0x64646472,0x2a2a2a2a,auStack_38,auStack_50,8,&uStack_54);
    FUN_100c50e8(*(undefined4 *)puVar1,uStack_58,auStack_48,auStack_50);
  }
  .glue::AEDisposeDesc(auStack_18);
  return 0;
}


// ==== .DoStartup__4TAppFv @ 1000c6e8 ====
// CyDecompAt: created, body 1000c6e8-1000c6eb

void _DoStartup__4TAppFv(void)

{
  return;
}


// ==== .OpenFromFS__4TAppFR6FSSpec @ 1000c714 ====
// CyDecompAt: created, body 1000c714-1000c717

void _OpenFromFS__4TAppFR6FSSpec(void)

{
  return;
}


// ==== .DoMonitorChanged__4TAppFPP7GDeviceR4RectR4Rect @ 1000c748 ====
// CyDecompAt: created, body 1000c748-1000c903

void _DoMonitorChanged__4TAppFPP7GDeviceR4RectR4Rect
               (undefined4 param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4)

{
  int iVar1;
  int iVar2;
  char cVar3;
  undefined1 auStack_38 [8];
  undefined1 auStack_30 [8];
  undefined4 uStack_28;
  undefined4 uStack_24;
  undefined4 auStack_20 [3];
  
  .glue::GetPort(auStack_20);
  iVar1 = .glue::LMGetWindowList();
  do {
    if (iVar1 == 0) {
      .glue::SetPort(auStack_20[0]);
      return;
    }
    iVar2 = .debug::_GetTWindow__7TWindowFP8GrafPort(iVar1);
    if (iVar2 != 0) {
      .glue::SetPort(iVar1);
      uStack_28 = *(undefined4 *)(iVar1 + 0x10);
      uStack_24 = *(undefined4 *)(iVar1 + 0x14);
      .glue::LocalToGlobal(&uStack_28);
      .glue::LocalToGlobal(&uStack_24);
      cVar3 = .glue::EmptyRect(&uStack_28);
      if (cVar3 == '\0') {
        .glue::SectRect(&uStack_28,param_3,auStack_30);
        .glue::SectRect(&uStack_28,param_4,auStack_38);
        cVar3 = .glue::EmptyRect(auStack_30);
        if (cVar3 != '\0') {
          cVar3 = .glue::EmptyRect(auStack_38);
          if (cVar3 != '\0') goto LAB_1000c8d8;
        }
        FUN_100c50e8(iVar2,param_2,param_3,param_4);
      }
      else {
        cVar3 = .glue::PtInRect(uStack_28,param_3);
        if (cVar3 == '\0') {
          cVar3 = .glue::PtInRect(uStack_24,param_3);
          if (cVar3 == '\0') {
            cVar3 = .glue::PtInRect(uStack_28,param_4);
            if (cVar3 == '\0') {
              cVar3 = .glue::PtInRect(uStack_24,param_4);
              if (cVar3 == '\0') goto LAB_1000c8d8;
            }
          }
        }
        FUN_100c50e8(iVar2,param_2,param_3,param_4);
      }
    }
LAB_1000c8d8:
    iVar1 = *(int *)(iVar1 + 0x90);
  } while( true );
}


// ==== .MyGrowZone @ 1000c948 ====
// CyDecompAt: created, body 1000c948-1000c9df

undefined4 _MyGrowZone(void)

{
  undefined *puVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  
  puVar1 = PTR_DAT_100cdb84;
  uVar2 = .glue::SetCurrentA5();
  uVar3 = 0;
  if (*(int *)(*(int *)puVar1 + 0x60) != 0) {
    uVar3 = .glue::GetPtrSize(*(undefined4 *)(*(int *)puVar1 + 0x60));
    .glue::DisposePtr(*(undefined4 *)(*(int *)puVar1 + 0x60));
    *(undefined4 *)(*(int *)puVar1 + 0x60) = 0;
  }
  .glue::SetA5(uVar2);
  return uVar3;
}


// ==== .SetupEmergencyMem__4TAppFUl @ 1000ca00 ====
// CyDecompAt: created, body 1000ca00-1000ca93

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupEmergencyMem__4TAppFUl(int param_1,undefined4 param_2)

{
  undefined4 uVar1;
  undefined **appuStack_20 [3];
  
  uVar1 = .glue::NewPtr(param_2);
  *(undefined4 *)(param_1 + 0x60) = uVar1;
  if (*(int *)(param_1 + 0x60) == 0) {
    appuStack_20[0] = &PTR_PTR_100d3c68;
    FUN_100bdef4(PTR_s__std_exception__std_bad_alloc__100c538c_4_100ce280,appuStack_20,_DAT_100cdb6c
                );
  }
  .glue::NewRoutineDescriptor(PTR_PTR_100ce27c,0xf0,1);
  .glue::SetGrowZone();
  return;
}


// ==== .LowOnMemory__4TAppFv @ 1000cac4 ====
// CyDecompAt: created, body 1000cac4-1000cac7

void _LowOnMemory__4TAppFv(void)

{
  return;
}


// ==== .InitMac__4TAppFv @ 1000caf0 ====
// CyDecompAt: created, body 1000caf0-1000cfdf

void _InitMac__4TAppFv(int param_1)

{
  short sVar3;
  undefined4 uVar1;
  int iVar2;
  char cVar4;
  undefined1 uVar5;
  undefined4 uStack_28;
  undefined4 uStack_24;
  uint auStack_20 [5];
  
  .glue::MaxApplZone();
  .glue::MoreMasters();
  .glue::MoreMasters();
  .glue::MoreMasters();
  .glue::MoreMasters();
  .glue::InitGraf(PTR_DAT_100cdb94 + 0xca);
  .glue::InitFonts();
  .glue::InitWindows();
  .glue::InitMenus();
  .glue::TEInit();
  .glue::InitDialogs(0);
  .glue::InitCursor();
  .glue::SetEventMask(0xffff);
  FUN_100c50e8(param_1,0x14000);
  auStack_20[0] = 0x100;
  sVar3 = .glue::Gestalt(0x71642020,auStack_20);
  auStack_20[0] = auStack_20[0] & 0xff00;
  if (sVar3 == 0) {
    if (auStack_20[0] < 0x100) goto LAB_1000cbf0;
    *(undefined1 *)(param_1 + 0x14) = 1;
  }
  else {
LAB_1000cbf0:
    *(undefined1 *)(param_1 + 0x14) = 0;
  }
  sVar3 = .glue::Gestalt(0x74686473,auStack_20);
  if (sVar3 == 0) {
    if (((auStack_20[0] & 4) != 0) && ((auStack_20[0] & 1) != 0)) {
      *(undefined1 *)(param_1 + 0x1b) = 1;
      goto LAB_1000cc40;
    }
  }
  *(undefined1 *)(param_1 + 0x1b) = 0;
LAB_1000cc40:
  *(undefined4 *)(param_1 + 0x34) = 0;
  *(undefined1 *)(param_1 + 0x1f) = 0;
  *(undefined2 *)(param_1 + 0x3a) = 3;
  *(undefined1 *)(param_1 + 0x1e) = 1;
  *(undefined4 *)(param_1 + 0x30) = 0;
  *(undefined2 *)(param_1 + 0x3c) = 0;
  sVar3 = .glue::Gestalt(0x65766e74,auStack_20);
  if ((sVar3 == 0) && ((auStack_20[0] & 1) != 0)) {
    *(undefined1 *)(param_1 + 0x15) = 1;
  }
  else {
    *(undefined1 *)(param_1 + 0x15) = 0;
  }
  if (*(char *)(param_1 + 0x15) != '\0') {
    uStack_28 = 0;
    uStack_24 = 2;
    .glue::AECreateDesc(0x70736e20,&uStack_28,8,param_1 + 0x26);
    uVar1 = .glue::NewRoutineDescriptor(PTR_PTR_100ce278,0xfe0,1);
    .glue::AEInstallEventHandler(0x61657674,0x6f617070,uVar1,0,0);
    uVar1 = .glue::NewRoutineDescriptor(PTR_PTR_100ce274,0xfe0,1);
    .glue::AEInstallEventHandler(0x61657674,0x6f646f63,uVar1,0,0);
    uVar1 = .glue::NewRoutineDescriptor(PTR_PTR_100ce274,0xfe0,1);
    .glue::AEInstallEventHandler(0x61657674,0x70646f63,uVar1,0,0);
    uVar1 = .glue::NewRoutineDescriptor(PTR_PTR_100ce270,0xfe0,1);
    .glue::AEInstallEventHandler(0x61657674,0x71756974,uVar1,0,0);
    uVar1 = .glue::NewRoutineDescriptor(PTR_PTR_100ce26c,0xfe0,1);
    .glue::AEInstallEventHandler(0x61657674,0x636e6667,uVar1,0,0);
  }
  *(undefined1 *)(param_1 + 100) = 0;
  *(undefined1 *)(param_1 + 0x74) = 0;
  *(undefined2 *)(param_1 + 0x76) = 0;
  *(undefined1 *)(param_1 + 0x65) = 0;
  *(undefined1 *)(param_1 + 0x67) = 0;
  *(undefined1 *)(param_1 + 0x69) = 0;
  *(undefined1 *)(param_1 + 0x68) = 0;
  *(undefined1 *)(param_1 + 0x66) = 0;
  *(undefined4 *)(param_1 + 0x6c) = 0;
  *(undefined4 *)(param_1 + 0x70) = 0;
  *(undefined4 *)(param_1 + 0x58) = 0;
  *(undefined2 *)(param_1 + 0x5c) = 0;
  *(undefined1 *)(param_1 + 0x20) = 0;
  *(undefined1 *)(param_1 + 0x21) = 0;
  *(undefined2 *)(param_1 + 0x24) = 0;
  *(undefined1 *)(param_1 + 0x22) = 0;
  sVar3 = .glue::Gestalt(0x61707072,auStack_20);
  if ((sVar3 == 0) && ((auStack_20[0] & 1) != 0)) {
    *(undefined1 *)(param_1 + 0x16) = 1;
    .glue::RegisterAppearanceClient();
  }
  else {
    *(undefined1 *)(param_1 + 0x16) = 0;
  }
  *(undefined1 *)(param_1 + 0x17) = 0;
  sVar3 = .glue::Gestalt(0x636d6e75,auStack_20);
  if ((sVar3 == 0) && ((auStack_20[0] & 2) != 0)) {
    iVar2 = .glue::InitContextualMenus();
    if (iVar2 == 0) {
      *(undefined1 *)(param_1 + 0x17) = 1;
    }
  }
  uVar5 = 0;
  if (PTR_NavLibraryVersion_100cdca4 != (undefined *)0x0) {
    cVar4 = .glue::NavServicesCanRun();
    if (cVar4 != '\0') {
      uVar5 = 1;
    }
  }
  *(undefined1 *)(param_1 + 0x18) = uVar5;
  *(undefined1 *)(param_1 + 0x19) = 0;
  sVar3 = .glue::Gestalt(0x7174696d,auStack_20);
  if (sVar3 == 0) {
    sVar3 = .glue::Gestalt(0x71747273,auStack_20);
    if ((sVar3 == 0) && ((auStack_20[0] & 1) != 0)) {
      *(char *)(param_1 + 0x19) = '\x01' - (PTR_EnterMovies_100cdca0 == (undefined *)0x0);
    }
  }
  FUN_100c50e8(param_1,0x80);
  FUN_100c50e8(param_1);
  return;
}


// ==== .PostInitMac__4TAppFv @ 1000d004 ====
// CyDecompAt: created, body 1000d004-1000d007

void _PostInitMac__4TAppFv(void)

{
  return;
}


// ==== .HideMenuBar__4TAppFUc @ 1000d234 ====
// CyDecompAt: created, body 1000d234-1000d3cb

void _HideMenuBar__4TAppFUc(int param_1,undefined1 param_2)

{
  undefined *puVar1;
  undefined2 uVar4;
  short sVar5;
  char cVar6;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined4 uStack_28;
  undefined4 uStack_24;
  undefined1 auStack_20 [16];
  
  puVar1 = PTR_DAT_100ce25c;
  *(undefined1 *)(param_1 + 0x74) = param_2;
  if (*(char *)(param_1 + 0x1e) != '\0') {
    if (*(short *)(param_1 + 0x76) == 0) {
      uVar4 = .glue::GetMBarHeight();
      *(undefined2 *)(param_1 + 0x76) = uVar4;
    }
    if (*(char *)(param_1 + 100) == '\0') {
      sVar5 = .glue::Gestalt(0x73646576,auStack_20);
      if (sVar5 == 0) {
        cVar6 = .glue::SBIsControlStripVisible();
        if (cVar6 == '\0') {
          if (*(short *)puVar1 == 0) {
            *(undefined2 *)puVar1 = 2;
          }
        }
        else {
          if (*(short *)puVar1 == 0) {
            *(undefined2 *)puVar1 = 1;
          }
          .glue::SBShowHideControlStrip(0);
        }
      }
      uVar2 = .glue::LMGetGrayRgn();
      .glue::LMSetMBarHeight(0);
      uVar3 = .glue::NewRgn();
      puVar1 = PTR_DAT_100cdb94;
      *(undefined4 *)(param_1 + 0x78) = uVar3;
      uStack_28 = *(undefined4 *)(puVar1 + 0x56);
      uStack_24 = *(undefined4 *)(puVar1 + 0x5a);
      .glue::RectRgn(*(undefined4 *)(param_1 + 0x78),&uStack_28);
      .glue::DiffRgn(*(undefined4 *)(param_1 + 0x78),uVar2,*(undefined4 *)(param_1 + 0x78));
      .glue::UnionRgn(uVar2,*(undefined4 *)(param_1 + 0x78),uVar2);
      uVar2 = .glue::LMGetWindowList();
      .glue::PaintBehind(uVar2,*(undefined4 *)(param_1 + 0x78));
      .glue::CalcVisBehind(uVar2,*(undefined4 *)(param_1 + 0x78));
      *(undefined1 *)(param_1 + 100) = 1;
      FUN_100c50e8(param_1);
    }
  }
  return;
}


// ==== .ResetCursor__4TAppFv @ 1000d570 ====
// CyDecompAt: created, body 1000d570-1000d59b

void _ResetCursor__4TAppFv(void)

{
  .glue::SetCursor(PTR_DAT_100cdb94 + 0x5e);
  return;
}


// ==== .MEL__4TAppFv @ 1000d6c4 ====
// CyDecompAt: created, body 1000d6c4-1000d87f

void _MEL__4TAppFv(int param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  uint uVar3;
  int iVar4;
  uint uVar5;
  
  puVar2 = PTR_DAT_100cdc9c;
  puVar1 = PTR_DAT_100cdb84;
  uVar5 = 0;
  *(undefined1 *)(param_1 + 0x1c) = 0;
  *(undefined1 *)(param_1 + 0x1d) = 0;
LAB_1000d834:
  if ((*(char *)(param_1 + 0x1c) != '\0') ||
     ((*(char *)(param_1 + 0x1d) != '\0' && (*(int *)(param_1 + 0x30) != 0)))) {
    *(undefined1 *)(param_1 + 0x1d) = 0;
    return;
  }
  if (*(int *)(*(int *)puVar1 + 0x60) == 0) {
    FUN_100c50e8(param_1);
  }
  if ((*(char *)(param_1 + 0x1b) != '\0') && (*(int *)(param_1 + 0x30) == 0)) {
    if (*(int *)(param_1 + 0x34) == 0) {
      .glue::YieldToAnyThread();
    }
    else {
      .glue::YieldToThread(*(undefined4 *)(param_1 + 0x34));
    }
  }
  if (*(char *)(param_1 + 0x1f) != '\0') {
    *(undefined1 *)(param_1 + 0x1f) = 0;
    .glue::DrawMenuBar();
  }
  if (*(char *)(param_1 + 0x22) != '\0') {
    .debug::_HeapCheck__FP4Zone(0);
  }
  FUN_100c50e8(param_1);
  if (*(short *)(param_1 + 0x3c) != 0) goto code_r0x1000d7b4;
  goto LAB_1000d7c4;
code_r0x1000d7b4:
  uVar3 = .glue::TickCount();
  if (uVar5 < uVar3) {
LAB_1000d7c4:
    if (*puVar2 != '\0') {
      FUN_100c50e8(param_1);
      .debug::_ResetCursor__11TSpinCursorFv();
    }
    iVar4 = .glue::TickCount();
    uVar5 = *(short *)(param_1 + 0x3c) + iVar4;
    FUN_100c50e8(param_1,0xffffffff,param_1 + 4,1);
    FUN_100c50e8(param_1);
  }
  goto LAB_1000d834;
}


// ==== .HandleEvent__4TAppFv @ 1000d934 ====
// CyDecompAt: created, body 1000d934-1000dafb

void _HandleEvent__4TAppFv(int param_1)

{
  char cVar1;
  
  if ((*(char *)(param_1 + 0x1e) != '\0') && (*(char *)(param_1 + 0x74) != '\0')) {
    if ((*(short *)(param_1 + 0xe) < 1) && (*(char *)(param_1 + 100) != '\0')) {
      if (*(short *)(param_1 + 4) == 0) {
        .glue::GetMouse(param_1 + 0xe);
        .glue::LocalToGlobal(param_1 + 0xe);
        if (*(short *)(param_1 + 0xe) == 0) {
          FUN_100c50e8(param_1);
        }
      }
      if (*(short *)(param_1 + 4) == 1) {
        FUN_100c50e8(param_1);
      }
    }
    else if ((*(short *)(param_1 + 0x76) < *(short *)(param_1 + 0xe)) &&
            (*(char *)(param_1 + 100) == '\0')) {
      FUN_100c50e8(param_1,1);
    }
  }
  switch(*(undefined2 *)(param_1 + 4)) {
  default:
    FUN_100c50e8(param_1);
    break;
  case 1:
    FUN_100c50e8(param_1);
    break;
  case 5:
    if (*(char *)(param_1 + 0x21) != '\0') {
      return;
    }
  case 3:
    cVar1 = .debug::_NoDA__Fv();
    if (cVar1 != '\0') {
      FUN_100c50e8(param_1);
    }
    break;
  case 6:
    FUN_100c50e8(param_1);
    break;
  case 8:
    FUN_100c50e8(param_1);
    break;
  case 0xf:
    FUN_100c50e8(param_1);
    break;
  case 0x17:
    .glue::AEProcessAppleEvent(param_1 + 4);
  }
  return;
}


// ==== .HandleCursor__4TAppFv @ 1000dca4 ====
// CyDecompAt: created, body 1000dca4-1000dedb

void _HandleCursor__4TAppFv(int param_1)

{
  undefined4 uVar1;
  int iVar2;
  char cVar4;
  short sVar3;
  int iVar5;
  short sStack_28;
  undefined4 uStack_24;
  undefined4 uStack_20;
  undefined4 auStack_1c [4];
  
  if (*(char *)(param_1 + 0x1e) != '\0') {
    iVar2 = .glue::FrontWindow();
    if (iVar2 == 0) {
      FUN_100c50e8(param_1);
    }
    else {
      iVar2 = .debug::_FindLayer__7TWindowFUcs(1,0);
      if (*(int *)(param_1 + 0x30) != 0) {
        iVar2 = *(int *)(param_1 + 0x30);
      }
      if (iVar2 != 0) {
        iVar5 = *(int *)(iVar2 + 4);
        .glue::SetPort(iVar5);
        if ((*(short *)PTR_DAT_100cdc94 == 0) && (cVar4 = .glue::StillDown(), cVar4 == '\0')) {
          if (*(char *)(param_1 + 0x65) == '\0') {
            .glue::SetPort(iVar5);
            uStack_24 = *(undefined4 *)(param_1 + 0xe);
            .glue::GlobalToLocal(&uStack_24);
            uVar1 = *(undefined4 *)(param_1 + 0xe);
            cVar4 = .glue::PtInRect(uStack_24,iVar5 + 0x10);
            if ((cVar4 != '\0') &&
               (((sStack_28 = (short)((uint)uVar1 >> 0x10), 0x14 < sStack_28 ||
                 (*(char *)(param_1 + 100) != '\0')) &&
                (cVar4 = .glue::EmptyRgn(*(undefined4 *)(iVar5 + 0x18)), cVar4 == '\0')))) {
              FUN_100c50e8(iVar2,uStack_24,(int)*(short *)(param_1 + 0x12));
              return;
            }
            FUN_100c50e8(param_1);
          }
          else {
            sVar3 = .glue::FindWindow(*(undefined4 *)(param_1 + 0xe),auStack_1c);
            if (sVar3 == 3) {
              iVar2 = .debug::_GetTWindow__7TWindowFP8GrafPort(auStack_1c[0]);
              if (((iVar2 != 0) &&
                  (cVar4 = .glue::EmptyRgn(*(undefined4 *)(iVar5 + 0x18)), cVar4 == '\0')) &&
                 ((0x14 < *(short *)(param_1 + 0xe) || (*(char *)(param_1 + 100) != '\0')))) {
                .glue::SetPort(auStack_1c[0]);
                uStack_20 = *(undefined4 *)(param_1 + 0xe);
                .glue::GlobalToLocal(&uStack_20);
                FUN_100c50e8(iVar2,uStack_20,(int)*(short *)(param_1 + 0x12));
                return;
              }
              FUN_100c50e8(param_1);
            }
            else {
              FUN_100c50e8(param_1);
            }
          }
        }
      }
    }
  }
  return;
}


// ==== .LoopTask__4TAppFv @ 1000e02c ====
// CyDecompAt: created, body 1000e02c-1000e0ab

void _LoopTask__4TAppFv(int param_1)

{
  int iVar1;
  int iVar2;
  
  .glue::GetKeys(param_1 + 0x40);
  iVar1 = .glue::FrontWindow();
  if (iVar1 != 0) {
    iVar2 = .debug::_GetTWindow__7TWindowFP8GrafPort(iVar1);
    if (iVar2 != 0) {
      .glue::SetPort(iVar1);
      FUN_100c50e8(iVar2);
    }
  }
  return;
}


// ==== .Modeless__4TAppFP8GrafPorts @ 1000e0d0 ====
// CyDecompAt: created, body 1000e0d0-1000e0d3

void _Modeless__4TAppFP8GrafPorts(void)

{
  return;
}


// ==== .CenterWindow__4TAppFP8GrafPort @ 1000e104 ====
// CyDecompAt: created, body 1000e104-1000e107

void _CenterWindow__4TAppFP8GrafPort(void)

{
  return;
}


// ==== .AlignWindowTo__4TAppFP8GrafPorts @ 1000e13c ====
// CyDecompAt: created, body 1000e13c-1000e13f

void _AlignWindowTo__4TAppFP8GrafPorts(void)

{
  return;
}


// ==== .RelativeMoveWindow__4TAppFP8GrafPortss @ 1000e174 ====
// CyDecompAt: created, body 1000e174-1000e29b

void _RelativeMoveWindow__4TAppFP8GrafPortss
               (undefined4 param_1,int param_2,short param_3,short param_4)

{
  uint uVar1;
  int *piVar2;
  short sStack_28;
  short sStack_26;
  undefined4 uStack_24;
  short sStack_20;
  short sStack_1e;
  undefined4 uStack_1c;
  undefined4 uStack_18;
  undefined1 auStack_14 [16];
  
  .glue::SetRect(auStack_14,0,0,(int)param_3,(int)param_4);
  piVar2 = (int *).glue::GetMainDevice();
  uStack_1c = *(undefined4 *)(*piVar2 + 0x22);
  uStack_18 = *(undefined4 *)(*piVar2 + 0x26);
  .glue::GetPort(&uStack_24);
  .glue::SetPort(param_2);
  uVar1 = (int)*(short *)(param_2 + 0x12) + (int)*(short *)(param_2 + 0x16);
  sStack_1e = (short)((int)uVar1 >> 1) + (ushort)((int)uVar1 < 0 && (uVar1 & 1) != 0);
  uVar1 = (int)*(short *)(param_2 + 0x14) + (int)*(short *)(param_2 + 0x10);
  sStack_20 = (short)((int)uVar1 >> 1) + (ushort)((int)uVar1 < 0 && (uVar1 & 1) != 0);
  sStack_26 = sStack_1e;
  sStack_28 = sStack_20;
  .glue::LocalToGlobal(&sStack_28);
  .glue::SetPort(uStack_24);
  .glue::ScalePt(&sStack_28,auStack_14,&uStack_1c);
  .glue::MoveWindow(param_2,(int)sStack_26 - ((int)sStack_1e - (int)*(short *)(param_2 + 0x12)),
                    (int)sStack_28 - ((int)sStack_20 - (int)*(short *)(param_2 + 0x10)),0);
  return;
}


// ==== .ShowErr__4TAppFv @ 1000e2d8 ====
// CyDecompAt: created, body 1000e2d8-1000e2db

void _ShowErr__4TAppFv(void)

{
  return;
}


// ==== .FatalErr__4TAppFPCUc @ 1000e300 ====
// CyDecompAt: created, body 1000e300-1000e303

void _FatalErr__4TAppFPCUc(void)

{
  return;
}


// ==== .WarnErr__4TAppFPCUc @ 1000e32c ====
// CyDecompAt: created, body 1000e32c-1000e32f

void _WarnErr__4TAppFPCUc(void)

{
  return;
}


// ==== .HandleContextMenu__4TAppFv @ 1000e358 ====
// CyDecompAt: created, body 1000e358-1000e3af

void _HandleContextMenu__4TAppFv(int param_1)

{
  undefined1 auStack_c [2];
  undefined1 auStack_a [2];
  undefined1 auStack_8 [8];
  
  .glue::ContextualMenuSelect
            (0,*(undefined4 *)(param_1 + 0xe),0,0,0,0,auStack_8,auStack_a,auStack_c);
  return;
}


// ==== .HandleCommand__4TAppFl @ 1000e894 ====
// CyDecompAt: created, body 1000e894-1000ea07

void _HandleCommand__4TAppFl(int param_1,uint param_2)

{
  uint uVar1;
  short sVar2;
  int iVar3;
  char cVar4;
  int iVar5;
  
  if ((*(char *)(param_1 + 0x15) == '\0') || (*PTR_DAT_100ce284 != '\0')) {
    sVar2 = (short)(param_2 >> 0x10);
    iVar5 = (int)sVar2;
    uVar1 = param_2 & 0xffff;
    if (sVar2 != 0) {
      param_2 = .debug::_GetCommand__12TCommandMenuFss(iVar5,uVar1);
    }
    iVar3 = .debug::_FindLayer__7TWindowFUcs(1,0);
    if (*(int *)(param_1 + 0x70) != 0) {
      iVar3 = *(int *)(param_1 + 0x70);
    }
    if (*(int *)(param_1 + 0x30) != 0) {
      iVar3 = *(int *)(param_1 + 0x30);
    }
    cVar4 = '\0';
    if (iVar3 != 0) {
      if (param_2 != 0) {
        cVar4 = FUN_100c50e8(iVar3,param_2);
      }
      if ((cVar4 == '\0') && (sVar2 != 0)) {
        cVar4 = FUN_100c50e8(iVar3,iVar5,uVar1);
      }
    }
    if ((cVar4 == '\0') && (param_2 != 0)) {
      cVar4 = FUN_100c50e8(param_1,param_2);
    }
    if ((cVar4 == '\0') && (sVar2 != 0)) {
      FUN_100c50e8(param_1,iVar5,uVar1);
    }
    .glue::HiliteMenu(0);
  }
  else {
    .glue::HiliteMenu(0);
  }
  return;
}


// ==== .HandleKeyDown__4TAppFv @ 1000ea34 ====
// CyDecompAt: created, body 1000ea34-1000eb83

void _HandleKeyDown__4TAppFv(int param_1)

{
  char cVar3;
  undefined4 uVar1;
  int iVar2;
  short sVar4;
  
  cVar3 = .debug::_NoDA__Fv();
  if (cVar3 != '\0') {
    uVar1 = FUN_100c50e8(param_1,*(undefined4 *)(param_1 + 6),*(undefined1 *)(param_1 + 0x20));
    if ((*(char *)(param_1 + 0x16) != '\0') && (iVar2 = .glue::MenuEvent(param_1 + 4), iVar2 != 0))
    {
      FUN_100c50e8(param_1,iVar2);
      return;
    }
    if (((*(ushort *)(param_1 + 0x12) & 0x100) == 0) ||
       (((sVar4 = (short)uVar1, 0x1b < sVar4 && (sVar4 < 0x20)) || (0xff < sVar4)))) {
      iVar2 = .debug::_FindLayer__7TWindowFUcs(1,0);
      if (*(int *)(param_1 + 0x70) != 0) {
        iVar2 = *(int *)(param_1 + 0x70);
      }
      if (*(int *)(param_1 + 0x30) != 0) {
        iVar2 = *(int *)(param_1 + 0x30);
      }
      if (iVar2 != 0) {
        FUN_100c50e8(iVar2,uVar1);
      }
    }
    else {
      uVar1 = .glue::MenuKey(uVar1);
      FUN_100c50e8(param_1,uVar1);
    }
  }
  return;
}


// ==== .HandleActivateEvt__4TAppFv @ 1000ebb0 ====
// CyDecompAt: created, body 1000ebb0-1000ec6b

void _HandleActivateEvt__4TAppFv(int param_1)

{
  int iVar1;
  
  if (*(char *)(param_1 + 0x65) == '\0') {
    if (7 < *(short *)(*(int *)(param_1 + 6) + 0x6c)) {
      iVar1 = .debug::_GetTWindow__7TWindowFP8GrafPort(*(undefined4 *)(param_1 + 6));
      if ((*(ushort *)(param_1 + 0x12) & 1) == 0) {
        if (iVar1 != 0) {
          FUN_100c50e8(iVar1,0);
        }
      }
      else if (iVar1 != 0) {
        FUN_100c50e8(iVar1,0);
      }
    }
  }
  return;
}


// ==== .HandleUpdateEvt__4TAppFv @ 1000ec9c ====
// CyDecompAt: created, body 1000ec9c-1000ed37

void _HandleUpdateEvt__4TAppFv(int param_1)

{
  int iVar1;
  undefined4 uVar2;
  
  uVar2 = *(undefined4 *)(param_1 + 6);
  if (7 < *(short *)(*(int *)(param_1 + 6) + 0x6c)) {
    .glue::SetPort(uVar2);
    .glue::BeginUpdate(uVar2);
    iVar1 = .debug::_GetTWindow__7TWindowFP8GrafPort(uVar2);
    if (iVar1 != 0) {
      FUN_100c50e8(iVar1);
    }
    .glue::EndUpdate(uVar2);
  }
  return;
}


// ==== .RedrawAllNow__4TAppFv @ 1000ee08 ====
// CyDecompAt: created, body 1000ee08-1000eeaf

void _RedrawAllNow__4TAppFv(void)

{
  int iVar1;
  int iVar2;
  undefined4 auStack_18 [4];
  
  .glue::GetPort(auStack_18);
  for (iVar1 = .glue::FrontWindow(); iVar1 != 0; iVar1 = *(int *)(iVar1 + 0x90)) {
    iVar2 = .debug::_GetTWindow__7TWindowFP8GrafPort(iVar1);
    if (iVar2 != 0) {
      .glue::SetPort(iVar1);
      .glue::BeginUpdate(iVar1);
      FUN_100c50e8(iVar2);
      .glue::EndUpdate(iVar1);
    }
  }
  .glue::SetPort(auStack_18[0]);
  return;
}


// ==== .MoveableModal__4TAppFP7TWindow @ 1000eed8 ====
// CyDecompAt: created, body 1000eed8-1000ef7f

void _MoveableModal__4TAppFP7TWindow(int param_1,undefined4 param_2)

{
  undefined4 uVar1;
  
  uVar1 = *(undefined4 *)(param_1 + 0x30);
  *(undefined4 *)(param_1 + 0x30) = param_2;
  .debug::_BeginModal__7TWindowFv();
  FUN_100c50e8(param_2);
  FUN_100c50e8(param_2);
  FUN_100c50e8(param_1);
  FUN_100c50e8(param_2);
  .debug::_EndModal__7TWindowFv();
  *(undefined1 *)(param_1 + 0x1c) = 0;
  *(undefined4 *)(param_1 + 0x30) = uVar1;
  return;
}


// ==== .MoveableDialogerRoutine @ 1000efb4 ====
// CyDecompAt: created, body 1000efb4-1000f0fb

undefined1 _MoveableDialogerRoutine(uint param_1,ushort *param_2,undefined2 *param_3)

{
  undefined4 uVar1;
  short sVar2;
  undefined1 uVar3;
  int iVar4;
  uint auStack_18 [2];
  
  if (*param_2 == 6) {
    if (*param_2 != param_1) {
      iVar4 = *(int *)PTR_DAT_100cdb84;
      uVar1 = *(undefined4 *)(param_2 + 2);
      *(undefined4 *)(iVar4 + 4) = *(undefined4 *)param_2;
      *(undefined4 *)(iVar4 + 8) = uVar1;
      uVar1 = *(undefined4 *)(param_2 + 6);
      *(undefined4 *)(iVar4 + 0xc) = *(undefined4 *)(param_2 + 4);
      *(undefined4 *)(iVar4 + 0x10) = uVar1;
      FUN_100c50e8();
    }
  }
  else if (((*param_2 == 1) &&
           (sVar2 = .glue::FindWindow(*(undefined4 *)(param_2 + 5),auStack_18), sVar2 == 4)) &&
          (auStack_18[0] == param_1)) {
    .glue::DragWindow(param_1,*(undefined4 *)(param_2 + 5),PTR_DAT_100cdb94 + 0x56);
    *param_3 = 0;
    *param_2 = 0;
    return 0;
  }
  if (*(int *)PTR_DAT_100ce250 == 0) {
    uVar3 = 0;
  }
  else {
    uVar3 = .glue::CallUniversalProc(*(undefined4 *)PTR_DAT_100ce250,0xfd0,param_1,param_2,param_3);
  }
  return uVar3;
}


// ==== .MoveableModalDialog__4TAppFP17RoutineDescriptorPs @ 1000f128 ====
// CyDecompAt: created, body 1000f128-1000f1bb

void _MoveableModalDialog__4TAppFP17RoutineDescriptorPs
               (undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined4 uVar3;
  
  puVar2 = PTR_DAT_100ce24c;
  puVar1 = PTR_DAT_100ce248;
  if (*PTR_DAT_100ce24c == '\0') {
    *(undefined4 *)PTR_DAT_100ce248 = 0;
    *puVar2 = 1;
  }
  if (*(int *)puVar1 == 0) {
    uVar3 = .glue::NewRoutineDescriptor(PTR_PTR_100ce244,0xfd0,1);
    *(undefined4 *)puVar1 = uVar3;
  }
  *(undefined4 *)PTR_DAT_100ce250 = param_2;
  .glue::ModalDialog(*(undefined4 *)puVar1,param_3);
  return;
}


// ==== .GetCommand__5TCMNUFs @ 1000f4b0 ====
// CyDecompAt: created, body 1000f4b0-1000f4df

undefined4 _GetCommand__5TCMNUFs(int param_1,short param_2)

{
  if (param_2 <= *(short *)(param_1 + 0xc)) {
    return *(undefined4 *)(*(int *)(param_1 + 0x10) + (param_2 + -1) * 4);
  }
  return 0;
}


// ==== .GetCommand__15TAppearanceMenuFs @ 1000f5ac ====
// CyDecompAt: created, body 1000f5ac-1000f5fb

undefined4 _GetCommand__15TAppearanceMenuFs(int param_1,short param_2)

{
  short sVar1;
  undefined4 auStack_8 [2];
  
  sVar1 = .glue::GetMenuItemCommandID(*(undefined4 *)(param_1 + 0xc),(int)param_2,auStack_8);
  if (sVar1 != 0) {
    auStack_8[0] = 0;
  }
  return auStack_8[0];
}


// ==== .MyNavEventProc @ 1000fde8 ====
// CyDecompAt: created, body 1000fde8-1000fe93

void _MyNavEventProc(int param_1,int param_2)

{
  undefined *puVar1;
  undefined4 uVar2;
  int iVar3;
  undefined4 *puVar4;
  
  puVar1 = PTR_DAT_100cdb84;
  if (param_1 == 0) {
    iVar3 = *(int *)PTR_DAT_100cdb84;
    puVar4 = *(undefined4 **)(param_2 + 0x1a);
    uVar2 = puVar4[1];
    *(undefined4 *)(iVar3 + 4) = *puVar4;
    *(undefined4 *)(iVar3 + 8) = uVar2;
    uVar2 = puVar4[3];
    *(undefined4 *)(iVar3 + 0xc) = puVar4[2];
    *(undefined4 *)(iVar3 + 0x10) = uVar2;
    if (*(short *)(*(int *)puVar1 + 4) == 6) {
      FUN_100c50e8();
    }
    else {
      FUN_100c50e8();
    }
  }
  return;
}


// ==== .MyNavFilterProc @ 1000feb8 ====
// CyDecompAt: created, body 1000feb8-1000ff67

undefined4 _MyNavFilterProc(int *param_1,int param_2)

{
  bool bVar1;
  undefined4 uVar2;
  short sVar3;
  
  if ((*(short *)PTR_DAT_100ce230 == 0) || (*(int *)PTR_DAT_100ce22c == 0)) {
    uVar2 = 1;
  }
  else {
    uVar2 = 1;
    if ((*param_1 == 0x66737320) && (*(char *)(param_2 + 2) == '\0')) {
      bVar1 = false;
      for (sVar3 = 0; sVar3 < *(short *)PTR_DAT_100ce230; sVar3 = sVar3 + 1) {
        if (*(int *)(param_2 + 0x18) == *(int *)(*(int *)PTR_DAT_100ce22c + sVar3 * 4)) {
          bVar1 = true;
        }
      }
      if (!bVar1) {
        uVar2 = 0;
      }
    }
  }
  return uVar2;
}


// ==== .GetOneFile__4TAppFR6FSSpecsPUlUcPCUc @ 1000ff8c ====
// CyDecompAt: created, body 1000ff8c-10010353

undefined4
_GetOneFile__4TAppFR6FSSpecsPUlUcPCUc
          (int param_1,int param_2,undefined4 param_3,int param_4,char param_5,byte *param_6)

{
  char cVar1;
  undefined2 uVar2;
  uint uVar3;
  undefined *puVar4;
  undefined *puVar5;
  undefined *puVar6;
  undefined *puVar7;
  undefined4 *puVar8;
  undefined4 *puVar9;
  short sVar13;
  int *piVar10;
  undefined4 uVar11;
  int iVar12;
  undefined4 *puVar14;
  undefined4 *puVar15;
  undefined4 uVar16;
  short sVar17;
  undefined4 uStack_9fa;
  undefined4 auStack_9f2 [3];
  undefined2 auStack_9e6 [43];
  undefined1 auStack_990 [4];
  undefined4 *puStack_98c;
  undefined1 auStack_940 [4];
  undefined1 auStack_93c [2];
  uint uStack_93a;
  undefined1 auStack_832 [1782];
  undefined1 auStack_13c [2];
  char cStack_13a;
  undefined1 auStack_136 [258];
  
  puVar6 = PTR_DAT_100ce224;
  puVar4 = PTR_DAT_100ce218;
  if (*(char *)(param_1 + 0x18) != '\0') {
    sVar13 = .glue::NavLoad();
    uVar16 = 0;
    if (sVar13 == 0) {
      sVar13 = (short)param_3;
      piVar10 = (int *).glue::NewHandleClear((sVar13 + -1) * 4 + 0xc);
      uVar11 = FUN_100c50e8(param_1);
      puVar7 = PTR_DAT_100ce230;
      *(undefined4 *)*piVar10 = uVar11;
      puVar5 = PTR_DAT_100ce22c;
      *(short *)(*piVar10 + 6) = sVar13;
      *(short *)puVar7 = sVar13;
      *(int *)puVar5 = param_4;
      for (sVar17 = 0; sVar17 < sVar13; sVar17 = sVar17 + 1) {
        *(undefined4 *)(*piVar10 + sVar17 * 4 + 8) = *(undefined4 *)(param_4 + sVar17 * 4);
      }
      .glue::NavGetDefaultDialogOptions(auStack_93c);
      .glue::BlockMove(param_6,auStack_832,*param_6 + 1);
      uVar3 = uStack_93a & 0xffffff7f;
      uStack_93a = uVar3 | 6;
      if (param_5 != '\0') {
        uStack_93a = uVar3 | 0x46;
      }
      if (sVar13 == 1) {
        uStack_93a = uStack_93a | 1;
      }
      iVar12 = .glue::GetResource(0x6f70656e,0x80);
      puVar5 = PTR_DAT_100ce228;
      if (*PTR_DAT_100ce228 == '\0') {
        *(undefined4 *)puVar6 = 0;
        *puVar5 = 1;
      }
      if (*(int *)puVar6 == 0) {
        uVar11 = .glue::NewRoutineDescriptor(PTR_PTR_100ce220,0xfc0,1);
        *(undefined4 *)puVar6 = uVar11;
      }
      puVar5 = PTR_DAT_100ce21c;
      if (*PTR_DAT_100ce21c == '\0') {
        *(undefined4 *)puVar4 = 0;
        *puVar5 = 1;
      }
      if (*(int *)puVar4 == 0) {
        uVar11 = .glue::NewRoutineDescriptor(PTR_PTR_100ce214,0xfc0,1);
        *(undefined4 *)puVar4 = uVar11;
      }
      cVar1 = *(char *)(param_1 + 100);
      if (cVar1 != '\0') {
        FUN_100c50e8(param_1);
      }
      sVar13 = .glue::NavGetFile(0,auStack_13c,auStack_93c,*(undefined4 *)puVar6,0,
                                 *(undefined4 *)puVar4,iVar12,0);
      if ((((cStack_13a != '\0') && (sVar13 == 0)) &&
          (sVar13 = .glue::AECountItems(auStack_136,auStack_940), sVar13 == 0)) &&
         (sVar13 = .glue::AEGetNthDesc(auStack_136,1,0x66737320,0,auStack_990), sVar13 == 0)) {
        .glue::BlockMoveData(*puStack_98c,param_2,0x46);
        uVar16 = 1;
        .glue::AEDisposeDesc(auStack_990);
      }
      FUN_100c2568(auStack_13c);
      if (iVar12 != 0) {
        .glue::DisposeHandle(iVar12);
      }
      if (cVar1 != '\0') {
        FUN_100c50e8(param_1,*(undefined1 *)(param_1 + 0x74));
      }
      .glue::NavUnload();
      return uVar16;
    }
  }
  if (param_5 == '\0') {
    .glue::StandardGetFile(0,param_3,param_4,(int)&uStack_9fa + 2);
  }
  else {
    .glue::StandardGetFilePreview(0,param_3,param_4,(int)&uStack_9fa + 2);
  }
  if (uStack_9fa._2_1_ == '\0') {
    uVar16 = 0;
  }
  else {
    iVar12 = 8;
    puVar8 = &uStack_9fa;
    puVar9 = (undefined4 *)(param_2 + -8);
    do {
      puVar15 = puVar9;
      puVar14 = puVar8;
      uVar16 = puVar14[3];
      puVar15[2] = puVar14[2];
      puVar15[3] = uVar16;
      iVar12 = iVar12 + -1;
      puVar8 = puVar14 + 2;
      puVar9 = puVar15 + 2;
    } while (iVar12 != 0);
    uVar16 = 1;
    uVar2 = *(undefined2 *)(puVar14 + 5);
    puVar15[4] = puVar14[4];
    *(undefined2 *)(puVar15 + 5) = uVar2;
  }
  return uVar16;
}


// ==== .GetAppSignature__4TAppFv @ 1001038c ====
// CyDecompAt: created, body 1001038c-10010397

undefined4 _GetAppSignature__4TAppFv(void)

{
  return 0x3f3f3f3f;
}


// ==== .PutOneFile__4TAppFR6FSSpecPCUcPCUcPUc @ 100103c4 ====
// CyDecompAt: created, body 100103c4-10010613

undefined4
_PutOneFile__4TAppFR6FSSpecPCUcPCUcPUc
          (int param_1,int param_2,byte *param_3,byte *param_4,undefined1 *param_5)

{
  undefined2 uVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined4 *puVar4;
  undefined4 *puVar5;
  short sVar7;
  undefined4 uVar6;
  undefined4 *puVar8;
  undefined4 *puVar9;
  undefined4 uVar10;
  int iVar11;
  undefined4 uStack_98a;
  undefined4 auStack_982 [3];
  undefined2 auStack_976 [35];
  undefined1 auStack_930 [4];
  undefined1 auStack_92c [4];
  undefined1 auStack_928 [4];
  undefined1 auStack_924 [2];
  uint uStack_922;
  undefined1 auStack_81a [768];
  undefined1 auStack_51a [1014];
  undefined1 auStack_124 [2];
  char cStack_122;
  undefined1 uStack_121;
  undefined1 uStack_11f;
  undefined1 auStack_11e [254];
  
  puVar2 = PTR_DAT_100ce20c;
  if (*(char *)(param_1 + 0x18) != '\0') {
    sVar7 = .glue::NavLoad();
    uVar10 = 0;
    if (sVar7 == 0) {
      .glue::NavGetDefaultDialogOptions(auStack_924);
      .glue::BlockMove(param_3,auStack_81a,*param_3 + 1);
      .glue::BlockMove(param_4,auStack_51a,*param_4 + 1);
      puVar3 = PTR_DAT_100ce210;
      uStack_922 = uStack_922 & 0xffffff7f | 7;
      uStack_11f = 0;
      if (*PTR_DAT_100ce210 == '\0') {
        *(undefined4 *)puVar2 = 0;
        *puVar3 = 1;
      }
      if (*(int *)puVar2 == 0) {
        uVar6 = .glue::NewRoutineDescriptor(PTR_PTR_100ce220,0xfc0,1);
        *(undefined4 *)puVar2 = uVar6;
      }
      uVar6 = FUN_100c50e8(param_1);
      sVar7 = .glue::NavPutFile(0,auStack_124,auStack_924,*(undefined4 *)puVar2,0x3f3f3f3f,uVar6,0);
      if ((sVar7 == 0) && (cStack_122 != '\0')) {
        .glue::AEGetNthPtr(auStack_11e,1,0x66737320,auStack_928,auStack_92c,param_2,0x46,auStack_930
                          );
        uVar10 = 1;
        if (param_5 != (undefined1 *)0x0) {
          *param_5 = uStack_121;
        }
        .glue::NavCompleteSave(auStack_124,0);
      }
      FUN_100c2568(auStack_124);
      .glue::NavUnload();
      return uVar10;
    }
  }
  .glue::StandardPutFile(param_3,param_4,(int)&uStack_98a + 2);
  if (uStack_98a._2_1_ == '\0') {
    uVar10 = 0;
  }
  else {
    iVar11 = 8;
    puVar4 = &uStack_98a;
    puVar5 = (undefined4 *)(param_2 + -8);
    do {
      puVar9 = puVar5;
      puVar8 = puVar4;
      uVar10 = puVar8[3];
      puVar9[2] = puVar8[2];
      puVar9[3] = uVar10;
      iVar11 = iVar11 + -1;
      puVar4 = puVar8 + 2;
      puVar5 = puVar9 + 2;
    } while (iVar11 != 0);
    uVar1 = *(undefined2 *)(puVar8 + 5);
    puVar9[4] = puVar8[4];
    *(undefined2 *)(puVar9 + 5) = uVar1;
    if (param_5 != (undefined1 *)0x0) {
      *param_5 = (undefined1)uStack_98a;
    }
    uVar10 = 1;
  }
  return uVar10;
}


// ==== .Log__4TAppFPCce @ 1001064c ====
// CyDecompAt: created, body 1001064c-10010667

void _Log__4TAppFPCce(void)

{
  return;
}


// ==== .__dt__7TDialogFv @ 1001068c ====
// CyDecompAt: created, body 1001068c-100106eb

undefined4 * ___dt__7TDialogFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d414c;
    .debug::___dt__7TWindowFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__10TDelverAppFv @ 10011e0c ====
// CyDecompAt: created, body 10011e0c-10011e97

undefined4 * ___dt__10TDelverAppFv(undefined4 *param_1,short param_2)

{
  int aiStack_18 [5];
  
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d4358;
    .glue::GetCWMgrPort(aiStack_18);
    *(undefined4 *)(aiStack_18[0] + 0x3e) = *(undefined4 *)PTR_DAT_100cdd28;
    .glue::PortChanged(aiStack_18[0]);
    .debug::___dt__4TAppFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .HandleIdle__10TDelverAppFv @ 10011ec0 ====
// CyDecompAt: created, body 10011ec0-10011fb3

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleIdle__10TDelverAppFv(int param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined4 *puVar3;
  undefined4 uVar4;
  
  puVar3 = _DAT_100cdd40;
  puVar2 = PTR_DAT_100cdc78;
  .debug::_Idle__6TAudioFv(_DAT_100cdd24);
  .debug::_HandleIdle__4TAppFv(param_1);
  .debug::_HandleISPseudoMouse__Fv();
  puVar1 = PTR_DAT_100cdc6c;
  if ((((*(char *)(param_1 + 0x1e) != '\0') &&
       (*(int *)(**(int **)(*(int *)*puVar3 + 0x16) + 0x2a) != 0)) && (*(int *)puVar2 != 0)) &&
     (*(short *)(**(int **)(**(int **)(*(int *)*puVar3 + 0x16) + 0x2a) + 6) ==
      *(short *)(**(int **)puVar2 + 6))) {
    uVar4 = *(undefined4 *)**(undefined4 **)(**(int **)(*(int *)*puVar3 + 0x16) + 0x2a);
    *(undefined4 *)**(undefined4 **)puVar2 = uVar4;
    *(undefined4 *)puVar1 = uVar4;
  }
  return;
}


// ==== .HandleOSEvt__10TDelverAppFv @ 10011fe4 ====
// CyDecompAt: created, body 10011fe4-1001212b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleOSEvt__10TDelverAppFv(int param_1)

{
  undefined *puVar1;
  int iVar2;
  int aiStack_18 [2];
  
  puVar1 = PTR_DAT_100ce3c4;
  if (*(char *)(param_1 + 0x1e) == '\0') {
    .debug::_SwitchedIn__Fv();
    for (iVar2 = .glue::LMGetWindowList(); iVar2 != 0; iVar2 = *(int *)(iVar2 + 0x90)) {
      .glue::ShowHide(iVar2,1);
      .glue::HiliteWindow(iVar2,1);
    }
    .debug::_Resume__6TAudioFv(_DAT_100cdd24);
    .debug::_HandleISResume__Fv();
    .glue::GetDateTime(puVar1);
  }
  else {
    .glue::GetDateTime(aiStack_18);
    *(int *)PTR_DAT_100ce3c8 = *(int *)PTR_DAT_100ce3c8 + (aiStack_18[0] - *(int *)puVar1);
    *(int *)puVar1 = aiStack_18[0];
    for (iVar2 = .glue::LMGetWindowList(); iVar2 != 0; iVar2 = *(int *)(iVar2 + 0x90)) {
      .glue::HiliteWindow(iVar2,0);
      .glue::ShowHide(iVar2,0);
    }
    .debug::_SwitchedOut__Fv();
    .debug::_Suspend__6TAudioFv(_DAT_100cdd24);
    .debug::_HandleISSuspend__Fv();
  }
  .debug::_HandleOSEvt__4TAppFv(param_1);
  return;
}


// ==== .PostInitMac__10TDelverAppFv @ 1001215c ====
// CyDecompAt: created, body 1001215c-1001299b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _PostInitMac__10TDelverAppFv(void)

{
  byte bVar1;
  bool bVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  undefined4 *puVar6;
  undefined *puVar7;
  short *psVar8;
  undefined *puVar9;
  undefined4 *puVar10;
  short sVar13;
  undefined2 uVar14;
  char cVar15;
  int iVar11;
  undefined4 uVar12;
  byte bVar16;
  uint uVar17;
  short sStack_10c;
  undefined1 auStack_10a [2];
  undefined1 auStack_108 [8];
  undefined4 uStack_100;
  undefined1 auStack_fc [14];
  ushort uStack_ee;
  int iStack_ec;
  int iStack_e8;
  undefined *puStack_e4;
  undefined **ppuStack_e0;
  undefined *puStack_dc;
  undefined4 *puStack_d8;
  int iStack_d4;
  uint uStack_d0;
  byte bStack_cc;
  int iStack_c8;
  undefined4 uStack_c4;
  uint uStack_c0;
  uint uStack_bc;
  uint uStack_b8;
  uint uStack_b4;
  short sStack_b0;
  uint uStack_ac;
  undefined4 uStack_a8;
  undefined *puStack_a4;
  undefined *puStack_a0;
  undefined *puStack_9c;
  int iStack_98;
  undefined4 uStack_94;
  undefined4 uStack_90;
  short *psStack_5c;
  undefined2 uStack_58;
  undefined1 auStack_54 [20];
  
  puVar9 = PTR_DAT_100ce3a4;
  psVar8 = _DAT_100ce39c;
  puVar7 = PTR_DAT_100ce388;
  puVar6 = _DAT_100cdd40;
  puVar4 = PTR_DAT_100cdd0c;
  puVar3 = PTR_DAT_100cdb84;
  uStack_58 = .glue::GetCurrentProcess(auStack_54);
  uStack_90 = 0;
  psStack_5c = psVar8;
  uStack_94 = 0x3c;
  uStack_58 = .glue::GetProcessInformation(auStack_54,&uStack_94);
  iStack_98 = FUN_100be7c8(8);
  if (iStack_98 != 0) {
    .debug::___ct__6TAuditFv(iStack_98);
  }
  *(int *)PTR_DAT_100cdd20 = iStack_98;
  FUN_100c50e8();
  .debug::_RegisterClass__9TRegistryFUlPFP7TStream_Pv(0x53637257,PTR_PTR_100cdd1c);
  .debug::_RegisterClass__9TRegistryFUlPFP7TStream_Pv(0x43687257,PTR_PTR_100cdd18);
  *(undefined1 *)(*(int *)puVar3 + 0x17) = 0;
  *(undefined1 *)(*(int *)puVar3 + 0x21) = 1;
  *(undefined1 *)(*(int *)puVar3 + 0x22) = 1;
  .debug::_InitISSupport__Fv();
  puVar10 = (undefined4 *).glue::GetString(0x81);
  if (puVar10 == (undefined4 *)0x0) {
    puStack_9c = PTR_s_Unknown_scenario_data_100ce398;
    FUN_100bdef4(puVar9,&puStack_9c,0);
  }
  sVar13 = .glue::FSMakeFSSpec((int)*psVar8,*(undefined4 *)(psVar8 + 1),*puVar10,PTR_DAT_100cdd14);
  if (sVar13 != 0) {
    puStack_a0 = PTR_s_Unable_to_refer_to_scenario_data_100ce394;
    FUN_100bdef4(puVar9,&puStack_a0,0);
  }
  .glue::ReleaseResource(puVar10);
  uVar14 = .glue::FSpOpenResFile(PTR_DAT_100cdd14,1);
  puVar5 = PTR_DAT_100cdd10;
  *(undefined2 *)PTR_DAT_100cdd10 = uVar14;
  if (*(short *)puVar5 == 0) {
    puStack_a4 = PTR_s_Unable_to_open_data_file_100ce390;
    FUN_100bdef4(puVar9,&puStack_a4,0);
  }
  puVar10 = (undefined4 *).glue::GetString(0x82);
  if (puVar10 != (undefined4 *)0x0) {
    sVar13 = .glue::FSMakeFSSpec((int)*psVar8,*(undefined4 *)(psVar8 + 1),*puVar10,PTR_DAT_100ce38c)
    ;
    if (sVar13 == 0) {
      .glue::FSpOpenResFile(PTR_DAT_100ce38c,1);
    }
    .glue::ReleaseResource(puVar10);
  }
  uVar14 = FUN_100bebec();
  *(undefined2 *)puVar4 = uVar14;
  if (*(short *)puVar4 == 0) {
    sVar13 = FUN_100bed54();
    if (sVar13 == 0) {
      *(undefined2 *)puVar4 = 0x7b;
    }
    else {
      uVar14 = FUN_100bee50(1,PTR_DAT_100cdd08);
      *(undefined2 *)puVar4 = uVar14;
    }
  }
  .debug::_SetupGammaTools();
  .debug::_Init__6TAudioFv(_DAT_100cdd24);
  uStack_a8 = .debug::_Instance__6TPrefsFv();
  cVar15 = .debug::_LoadPrefs__6TPrefsFPCUcPvl(uStack_a8,puVar7,&DAT_100d3e20,4);
  if (cVar15 == '\0') {
    sStack_b0 = .glue::Gestalt(0x63707574,&uStack_ac);
    if (sStack_b0 != 0) {
      sStack_b0 = .glue::Gestalt(0x70726f63,&uStack_ac);
      uStack_ac = uStack_ac - 1;
    }
    if (uStack_ac < 4) {
      uStack_b4 = _DAT_100d426c;
      .debug::_SetMusicVolume__6TAudioFsUc(_DAT_100cdd24,0,1);
      _DAT_100d3e20 = uStack_b4;
    }
    else if (uStack_ac == 4) {
      _DAT_100d3e20 = _DAT_100d4270;
      uStack_b8 = _DAT_100d3e20;
    }
    else if (uStack_ac < 0x106) {
      _DAT_100d3e20 = _DAT_100d4274;
      uStack_bc = _DAT_100d3e20;
    }
    else {
      _DAT_100d3e20 = _DAT_100d4278;
      uStack_c0 = _DAT_100d3e20;
    }
    .debug::_SavePrefs__6TPrefsFPCUcPvl(uStack_a8,puVar7,&DAT_100d3e20,4);
  }
  *(byte *)(*(int *)puVar3 + 0x67) = DAT_100d3e20 & 1;
  *(byte *)(*(int *)puVar3 + 0x68) = DAT_100d3e20 & 1;
  *(byte *)(*(int *)puVar3 + 0x69) = DAT_100d3e20 & 1;
  *(undefined1 *)(*(int *)puVar3 + 0x66) = 1;
  iVar11 = .glue::GetMenuHandle(0x88);
  if (iVar11 != 0) {
    if ((DAT_100d3e20 >> 6 & 1) == 0) {
      .glue::CheckItem(iVar11,2,1);
    }
    else {
      .glue::CheckItem(iVar11,1,1);
    }
    if ((_DAT_100d3e20 & 0x1000000) != 0) {
      .glue::CheckItem(iVar11,4,1);
    }
    if ((int)_DAT_100d3e20 < 0) {
      if ((DAT_100d3e20 >> 1 & 1) == 0) {
        .glue::CheckItem(iVar11,7,1);
      }
      else {
        .glue::CheckItem(iVar11,6,1);
      }
    }
    else {
      .glue::CheckItem(iVar11,8,1);
    }
    bVar1 = DAT_100d3e20 >> 2 & 0xf;
    if (bVar1 == 6) {
      .glue::CheckItem(iVar11,0xb,1);
    }
    else if (bVar1 < 6) {
      if (bVar1 == 4) {
        .glue::CheckItem(iVar11,10,1);
      }
    }
    else if (bVar1 == 8) {
      .glue::CheckItem(iVar11,0xc,1);
    }
  }
  uStack_c4 = 0;
  iStack_c8 = .glue::MaxMem(&uStack_c4);
  puStack_d8 = (undefined4 *).glue::GetResource(0x4d656d55,0x81);
  if (puStack_d8 == (undefined4 *)0x0) {
    puStack_dc = PTR_s_Unable_to_load_memory_usage_info_100c5532_8_100ce374;
    FUN_100bdef4(puVar9,&puStack_dc,0);
  }
  .glue::BlockMove(*puStack_d8,&iStack_d4,0xc);
  iVar11 = (iStack_c8 - iStack_d4) / 100 + (iStack_c8 - iStack_d4 >> 0x1f);
  uVar17 = (iVar11 - (iVar11 >> 0x1f)) * (uint)bStack_cc;
  if (uVar17 < uStack_d0) {
    ppuStack_e0 = &PTR_PTR_100d3c68;
    FUN_100bdef4(PTR_s__std_exception__std_bad_alloc__100ce370,&ppuStack_e0,_DAT_100cdb6c);
    puStack_e4 = PTR_s_Not_enough_memory_100ce36c;
    FUN_100bdef4(puVar9,&puStack_e4,0);
  }
  iStack_e8 = FUN_100be7c8(0x10);
  if (iStack_e8 != 0) {
    .debug::___ct__6TCacheFUl(iStack_e8,uVar17);
  }
  iStack_ec = FUN_100be7c8(0x444);
  if (iStack_ec != 0) {
    .debug::___ct__15TCachedSegFilesFP6TCache(iStack_ec,iStack_e8);
  }
  *_DAT_100cdbc4 = iStack_ec;
  .glue::EventAvail(0xffff,auStack_fc);
  if (((DAT_100d3e20_1._0_1_ >> 4 & 1) == 0) || ((uStack_ee & 0xa00) != 0)) {
    _DAT_100d3e20 = _DAT_100d3e20 & 0xffdfffff;
    uVar12 = .debug::_PickAMonitor__Fv();
    *puVar6 = uVar12;
    if (8 < *(short *)(**(int **)(*(int *)*puVar6 + 0x16) + 0x20)) {
      uVar12 = .glue::GetNewDialog(0x8c,0,0xffffffff);
      .glue::GetDialogItem(uVar12,3,auStack_10a,&uStack_100,auStack_108);
      if ((DAT_100d3e20_1._0_1_ >> 4 & 1) != 0) {
        .glue::SetControlValue(uStack_100,1);
      }
      .glue::ShowWindow(uVar12);
      bVar2 = false;
      while (!bVar2) {
        .glue::ModalDialog(0,&sStack_10c);
        if (sStack_10c == 2) {
          _DAT_100d3e20 = _DAT_100d3e20 & 0xffdfffff;
          bVar2 = true;
        }
        else if (sStack_10c < 2) {
          if (0 < sStack_10c) {
            _DAT_100d3e20 = _DAT_100d3e20 & 0xffdfffff | 0x200000;
            bVar2 = true;
          }
        }
        else if (sStack_10c < 4) {
          iVar11 = .glue::GetControlValue(uStack_100);
          .glue::SetControlValue(uStack_100,1 - iVar11);
        }
      }
      bVar16 = .glue::GetControlValue(uStack_100);
      bVar1 = DAT_100d3e20_1._0_1_ & 0xef;
      DAT_100d3e20_1 = CONCAT12((bVar16 & 1) << 4 | bVar1,DAT_100d3e20_1._1_2_);
      .glue::DisposeDialog(uVar12);
      if ((DAT_100d3e20_1._0_1_ >> 5 & 1) != 0) {
        uVar12 = .debug::_PickAMonitor__Fv();
        *puVar6 = uVar12;
      }
      uVar12 = .debug::_Instance__6TPrefsFv();
      .debug::_SavePrefs__6TPrefsFPCUcPvl(uVar12,puVar7,&DAT_100d3e20,4);
    }
  }
  else {
    uVar12 = .debug::_PickAMonitor__Fv();
    *puVar6 = uVar12;
  }
  for (iVar11 = .glue::GetDeviceList(); iVar11 != 0; iVar11 = .glue::GetNextDevice(iVar11)) {
  }
  return;
}


// ==== .CreateFromStream__30TRegistrar<16TCharacterWindow>FP7TStream @ 100129cc ====
// CyDecompAt: created, body 100129cc-10012a1b

int _CreateFromStream__30TRegistrar<16TCharacterWindow>FP7TStream(undefined4 param_1)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x88);
  if (iVar1 != 0) {
    .debug::___ct__16TCharacterWindowFP7TStream(iVar1,param_1);
  }
  return iVar1;
}


// ==== .CreateFromStream__29TRegistrar<15TScriptedWindow>FP7TStream @ 10012a6c ====
// CyDecompAt: created, body 10012a6c-10012abb

int _CreateFromStream__29TRegistrar<15TScriptedWindow>FP7TStream(undefined4 param_1)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x38);
  if (iVar1 != 0) {
    .debug::___ct__15TScriptedWindowFP7TStream(iVar1,param_1);
  }
  return iVar1;
}


// ==== .TranslateKey__10TDelverAppFlUc @ 10012b0c ====
// CyDecompAt: created, body 10012b0c-10012b97

int _TranslateKey__10TDelverAppFlUc(int param_1,undefined4 param_2,undefined1 param_3)

{
  int iVar1;
  short sVar2;
  
  iVar1 = .debug::_TranslateKey__4TAppFlUc(param_1,param_2,param_3);
  sVar2 = (short)iVar1;
  if (0x2f < sVar2) {
    if ((sVar2 < 0x3a) && ((*(ushort *)(param_1 + 0x12) & 0x100) != 0)) {
      if (sVar2 == 0x30) {
        iVar1 = 0x109;
      }
      else {
        iVar1 = iVar1 + 0xcf;
      }
    }
  }
  return iVar1;
}


// ==== .ResetCursor__10TDelverAppFv @ 10012bcc ====
// CyDecompAt: created, body 10012bcc-10012bf3

void _ResetCursor__10TDelverAppFv(void)

{
  .debug::_ChangeCursor__Fs(0x2a);
  return;
}


// ==== .MyGetEvent__10TDelverAppFsP11EventRecordUc @ 10012c24 ====
// CyDecompAt: created, body 10012c24-10012df7

undefined4
_MyGetEvent__10TDelverAppFsP11EventRecordUc(int param_1,uint param_2,short *param_3,uint param_4)

{
  undefined *puVar1;
  undefined *puVar2;
  char cVar6;
  undefined4 uVar3;
  short sVar5;
  uint uVar4;
  
  puVar2 = PTR_DAT_100ce368;
  puVar1 = PTR_DAT_100ce364;
  if (*PTR_DAT_100ce368 == '\0') {
    *(undefined4 *)PTR_DAT_100ce364 = 0;
    *puVar2 = 1;
  }
  if (((param_4 & 0xff) == 0) ||
     (cVar6 = .debug::_CheckForISEvent__FP11EventRecord(param_3), cVar6 == '\0')) {
    cVar6 = .debug::_MyGetEvent__4TAppFsP11EventRecordUc(param_1,param_2,param_3,param_4);
    if (cVar6 == '\0') {
      if ((((*PTR_DAT_100cdd04 == '\0') || (*(char *)(param_1 + 0x1e) == '\0')) ||
          ((param_2 & 8) == 0)) ||
         ((*PTR_DAT_100cdd00 != '\0' ||
          (uVar4 = .glue::TickCount(), uVar4 <= *(int *)puVar1 + 0x14U)))) {
        uVar3 = 0;
      }
      else {
        uVar3 = .glue::TickCount();
        *(undefined4 *)puVar1 = uVar3;
        *param_3 = 3;
        uVar3 = 1;
        param_3[1] = 0;
        param_3[2] = 0x20;
      }
    }
    else {
      if (*param_3 != 0) {
        uVar3 = .glue::TickCount();
        *(undefined4 *)puVar1 = uVar3;
      }
      if (((bRam100d3e21 >> 2 & 1) != 0) && (*param_3 == 1)) {
        sVar5 = .debug::_ButtonNumber__Fv();
        if (sVar5 == 4) {
          param_3[7] = param_3[7] | 0x800;
          return 1;
        }
        if (sVar5 < 4) {
          if (sVar5 == 2) {
            param_3[7] = param_3[7] | 0x100;
            return 1;
          }
          if (1 < sVar5) {
            param_3[7] = param_3[7] | 0x1000;
            return 1;
          }
        }
        else if (sVar5 < 6) {
          param_3[7] = param_3[7] | 0x200;
          return 1;
        }
      }
      uVar3 = 1;
    }
  }
  else {
    uVar3 = 1;
  }
  return uVar3;
}


// ==== .DoQuit__10TDelverAppFv @ 10013a58 ====
// CyDecompAt: created, body 10013a58-10013bd7

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 _DoQuit__10TDelverAppFv(undefined4 param_1)

{
  int *piVar1;
  short sVar4;
  char cVar5;
  undefined4 uVar2;
  int iVar3;
  undefined4 uStack_28;
  undefined4 auStack_24 [4];
  
  piVar1 = _DAT_100cdcdc;
  if (*(int *)PTR_DAT_100cdce0 != 0) {
    if (*PTR_DAT_100cdd00 != '\0') {
      return 0;
    }
    sVar4 = .debug::_MyAlert__Fs(0x81);
    if (sVar4 == 1) {
      .debug::_DoSave__10TDelverAppFUcUc(param_1,0,1);
    }
    else if (sVar4 == 2) {
      return 0;
    }
  }
  cVar5 = .debug::_DoQuit__4TAppFv(param_1);
  if (cVar5 == '\0') {
    uVar2 = 0;
  }
  else {
    if (*piVar1 != 0) {
      .glue::SetPort(*(undefined4 *)(*piVar1 + 4));
      uStack_28 = *(undefined4 *)(*(int *)(*piVar1 + 4) + 0x10);
      auStack_24[0] = *(undefined4 *)(*(int *)(*piVar1 + 4) + 0x14);
      .glue::LocalToGlobal(&uStack_28);
      .glue::LocalToGlobal(auStack_24);
      uVar2 = .debug::_Instance__6TPrefsFv();
      .debug::_SavePrefs__6TPrefsFPCUcPvl(uVar2,PTR_DAT_100ce328,&uStack_28,8);
    }
    .debug::_Halt__6TAudioFv(_DAT_100cdd24);
    .debug::_NukeScratchFile__Fv();
    iVar3 = .glue::FrontWindow();
    while (iVar3 != 0) {
      .glue::HideWindow(iVar3);
      iVar3 = .glue::FrontWindow();
    }
    .debug::_SwitchedAndGone__Fv();
    if (*(short *)PTR_DAT_100cdd0c == 0) {
      FUN_100becb0();
    }
    uVar2 = 1;
  }
  return uVar2;
}


// ==== .OpenFromFS__10TDelverAppFR6FSSpec @ 10014ef8 ====
// CyDecompAt: created, body 10014ef8-100150a3

void _OpenFromFS__10TDelverAppFR6FSSpec(undefined4 param_1,undefined4 param_2)

{
  short sVar2;
  char cVar3;
  undefined4 uVar1;
  undefined1 auStack_28 [4];
  char acStack_24 [4];
  int aiStack_20 [5];
  
  sVar2 = .glue::FSpGetFInfo(param_2,aiStack_20);
  if (sVar2 == 0) {
    if (aiStack_20[0] == 0x44656c50) {
      cVar3 = .debug::_CheckPlayerFile__10TDelverAppFR6FSSpec(param_2);
      if (cVar3 != '\0') {
        if (*(int *)PTR_DAT_100cdce0 == 0) {
          .debug::_InitWorld__10TDelverAppFv(param_1);
          sVar2 = FUN_100b8f80(acStack_24);
          if (((sVar2 == 0) && (acStack_24[0] == '\0')) &&
             (sVar2 = FUN_100b95e8(auStack_28), sVar2 == 0)) {
            .debug::_GammaFadeIn(0x32);
            FUN_100c50e8();
            FUN_100b9064(0);
            FUN_100c50e8(*(undefined4 *)PTR_DAT_100cdb84,1);
            .debug::_GammaFadeOut(0x32);
          }
          uVar1 = .debug::_Instance__6TPrefsFv();
          .debug::_SetFile__6TPrefsFPCUcR6FSSpec(uVar1,PTR_DAT_100ce32c,param_2);
          .debug::_CreateWindows__Fv();
          .debug::_OpenPlayerFile__10TDelverAppFR6FSSpecUc(param_1,param_2,1);
        }
        else {
          sVar2 = .debug::_MyAlert__Fs(0x86);
          if (sVar2 == 1) {
            .debug::_DoSave__10TDelverAppFUcUc(param_1,0,1);
          }
          else if (sVar2 == 2) {
            return;
          }
          .debug::_OpenAndSetPlayerFileFromFS__10TDelverAppFR6FSSpec(param_1,param_2);
        }
      }
    }
    else {
      FUN_100c50e8(param_1);
    }
  }
  return;
}


// ==== .ShowMenuBar__10TDelverAppFv @ 1001555c ====
// CyDecompAt: created, body 1001555c-10015597

void _ShowMenuBar__10TDelverAppFv(undefined4 param_1)

{
  if (*PTR_DAT_100cdd00 == '\0') {
    .debug::_ShowMenuBar__4TAppFv(param_1);
  }
  return;
}


// ==== .GetGDevContent__10TDelverAppFPP7GDeviceR4Rect @ 100155c8 ====
// CyDecompAt: created, body 100155c8-10015627

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _GetGDevContent__10TDelverAppFPP7GDeviceR4Rect(undefined4 param_1,int param_2,int param_3)

{
  .debug::_GetGDevContent__4TAppFPP7GDeviceR4Rect(param_1);
  if (param_2 == *_DAT_100cdd40) {
    *(short *)(param_3 + 4) = *(short *)(param_3 + 4) + -0x90;
  }
  return;
}


// ==== .HandleMouseDown__10TDelverAppFv @ 10015668 ====
// CyDecompAt: created, body 10015668-10015723

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleMouseDown__10TDelverAppFv(int param_1)

{
  int iVar1;
  int iVar2;
  undefined4 auStack_18 [4];
  
  if (*PTR_DAT_100cdd00 == '\0') {
    .debug::_HandleMouseDown__4TAppFv(param_1);
  }
  else {
    .glue::FindWindow(*(undefined4 *)(param_1 + 0xe),auStack_18);
    iVar1 = .debug::_GetTWindow__7TWindowFP8GrafPort(auStack_18[0]);
    if (iVar1 != 0) {
      if (((*(ushort *)(iVar1 + 8) & 7) != 1) &&
         (iVar2 = .debug::_FindLayer__7TWindowFUcs(1,0), iVar1 != iVar2)) {
        .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(_DAT_100cdd24,0);
        return;
      }
      .debug::_HandleMouseDown__4TAppFv(param_1);
    }
  }
  return;
}


// ==== .DefaultCommand__10TDelverAppFl @ 10015888 ====
// CyDecompAt: created, body 10015888-10015adb

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 _DefaultCommand__10TDelverAppFl(int param_1,int param_2)

{
  undefined *puVar1;
  int iVar2;
  short sVar4;
  char cVar5;
  undefined4 uVar3;
  undefined1 auStack_68 [80];
  
  puVar1 = PTR_DAT_100cdb98;
  if (param_2 == 0x6a) {
    .debug::_DoSaveAs__10TDelverAppFUc(param_1,0);
    return 1;
  }
  if (param_2 < 0x6a) {
    if (param_2 == 5) {
      .debug::_DoSave__10TDelverAppFUcUc(param_1,1,0);
      .debug::_myprintf__13TStatusWindowFPce
                (*(undefined4 *)puVar1,PTR_s__Game_Saved__100c5841_0x2c_100ce2e0);
      return 1;
    }
    if (param_2 < 5) {
      if (param_2 == 3) {
        sVar4 = .debug::_MyAlert__Fs(0x86);
        if (sVar4 == 1) {
          .debug::_DoSave__10TDelverAppFUcUc(param_1,0,1);
          .debug::_myprintf__13TStatusWindowFPce
                    (*(undefined4 *)puVar1,PTR_s__Game_Saved__100c5841_0x2c_100ce2e0);
        }
        else if (sVar4 == 2) {
          return 1;
        }
        cVar5 = .debug::_DoOpen__10TDelverAppFP6FSSpecP6FSSpec(auStack_68,_DAT_100cdd44);
        if (cVar5 != '\0') {
          .debug::_OpenAndSetPlayerFileFromFS__10TDelverAppFR6FSSpec(param_1,auStack_68);
          .debug::_myprintf__13TStatusWindowFPce(*(undefined4 *)puVar1,PTR_s__Game_Opened__100ce2d8)
          ;
          return 1;
        }
        return 1;
      }
    }
    else {
      if (param_2 == 7) {
        sVar4 = .debug::_MyAlert__Fs(0x87);
        if (sVar4 == 1) {
          .debug::_OpenAndSetPlayerFileFromFS__10TDelverAppFR6FSSpec(param_1,_DAT_100cdd44);
          .debug::_myprintf__13TStatusWindowFPce
                    (*(undefined4 *)puVar1,PTR_s__Game_Reverted__100ce2dc);
          return 1;
        }
        return 1;
      }
      if (param_2 < 7) {
        .debug::_DoSaveAs__10TDelverAppFUc(param_1,1);
        return 1;
      }
    }
  }
  else {
    if (param_2 == 1000) {
      if (*_DAT_100cdcc8 != 0) {
        .glue::SysBeep(1);
        return 1;
      }
      if (*(int *)(param_1 + 0x30) != 0) {
        return 1;
      }
      for (iVar2 = .glue::FrontWindow(); *(char *)(iVar2 + 0x70) == '\0';
          iVar2 = *(int *)(iVar2 + 0x90)) {
      }
      if ((iVar2 != 0) && (iVar2 = .debug::_GetTWindow__7TWindowFP8GrafPort(iVar2), iVar2 != 0)) {
        FUN_100c50e8(iVar2);
      }
      return 1;
    }
    if ((param_2 < 1000) && (param_2 == 0x2ee)) {
      .debug::_DoPrefs__Fv();
      return 1;
    }
  }
  uVar3 = .debug::_DefaultCommand__4TAppFl(param_1,param_2);
  return uVar3;
}


// ==== .DefaultMenu__10TDelverAppFss @ 10015b10 ====
// CyDecompAt: created, body 10015b10-100160a7

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DefaultMenu__10TDelverAppFss(undefined4 param_1,undefined4 param_2,int param_3)

{
  bool bVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined4 uVar5;
  undefined4 uVar6;
  short sVar7;
  short sVar8;
  short asStack_28 [8];
  
  uVar5 = _DAT_100cdd24;
  puVar4 = PTR_DAT_100cdbec;
  puVar3 = PTR_DAT_100cdbe4;
  puVar2 = PTR_DAT_100cdb84;
  sVar7 = (short)param_2;
  sVar8 = (short)param_3;
  if ((sVar7 == 0x80) && (sVar8 == 1)) {
    .debug::_DoCredits__Fv();
  }
  else if (sVar7 == 0x88) {
    uVar5 = .glue::GetMenuHandle(0x88);
    if (sVar8 == 1) {
      DAT_100d3e20 = DAT_100d3e20 & 0xbf | 0x40;
      .glue::CheckItem(uVar5,1,1);
      .glue::CheckItem(uVar5,2,0);
    }
    else if (sVar8 == 2) {
      DAT_100d3e20 = DAT_100d3e20 & 0xbf;
      .glue::CheckItem(uVar5,1,0);
      .glue::CheckItem(uVar5,2,1);
    }
    else if (sVar8 == 4) {
      bVar1 = (DAT_100d3e20 & 1) == 0;
      DAT_100d3e20 = bVar1 | DAT_100d3e20 & 0xfe;
      .glue::CheckItem(uVar5,4,bVar1);
      *(byte *)(*(int *)puVar2 + 0x67) = DAT_100d3e20 & 1;
      *(byte *)(*(int *)puVar2 + 0x68) = DAT_100d3e20 & 1;
      *(byte *)(*(int *)puVar2 + 0x69) = DAT_100d3e20 & 1;
    }
    else if (sVar8 == 6) {
      DAT_100d3e20 = DAT_100d3e20 & 0x7d | 0x82;
      .glue::CheckItem(uVar5,6,1);
      .glue::CheckItem(uVar5,7,0);
      .glue::CheckItem(uVar5,8,0);
    }
    else if (sVar8 == 7) {
      DAT_100d3e20 = DAT_100d3e20 & 0x7d | 0x80;
      .glue::CheckItem(uVar5,6,0);
      .glue::CheckItem(uVar5,7,1);
      .glue::CheckItem(uVar5,8,0);
    }
    else if (sVar8 == 8) {
      DAT_100d3e20 = DAT_100d3e20 & 0x7d;
      .glue::CheckItem(uVar5,6,0);
      .glue::CheckItem(uVar5,7,0);
      .glue::CheckItem(uVar5,8,1);
    }
    else if (sVar8 == 10) {
      DAT_100d3e20 = DAT_100d3e20 & 0xc3 | 0x10;
      .glue::CheckItem(uVar5,10,1);
      .glue::CheckItem(uVar5,0xb,0);
      .glue::CheckItem(uVar5,0xc,0);
    }
    else if (sVar8 == 0xb) {
      DAT_100d3e20 = DAT_100d3e20 & 0xc3 | 0x18;
      .glue::CheckItem(uVar5,10,0);
      .glue::CheckItem(uVar5,0xb,1);
      .glue::CheckItem(uVar5,0xc,0);
    }
    else if (sVar8 == 0xc) {
      DAT_100d3e20 = DAT_100d3e20 & 0xc3 | 0x20;
      .glue::CheckItem(uVar5,10,0);
      .glue::CheckItem(uVar5,0xb,0);
      .glue::CheckItem(uVar5,0xc,1);
    }
    uVar5 = .debug::_Instance__6TPrefsFv();
    .debug::_SavePrefs__6TPrefsFPCUcPvl(uVar5,PTR_DAT_100ce388,&DAT_100d3e20,4);
  }
  else if (sVar7 == 200) {
    if (sVar8 == 1) {
      *(undefined4 *)PTR_DAT_100cdbe8 = 1;
      *(undefined2 *)puVar4 = 1;
    }
    else {
      *(undefined4 *)PTR_DAT_100cdbe8 = 0;
      *(undefined2 *)PTR_DAT_100cdbec = *(undefined2 *)(puVar3 + (sVar8 + -3) * 2);
    }
    .debug::_RebuildParty__Fv();
    .debug::_DrawRoutine__11TGameViewerFs(*(undefined4 *)PTR_DAT_100cdbb8,1);
  }
  else if ((sVar7 == 0x83) && (sVar8 == 1)) {
    .debug::_SetSoundVolume__6TAudioFsUc(_DAT_100cdd24,0xffffffff,1);
  }
  else if ((sVar7 == 0x83) && ((1 < sVar8 && (sVar8 < 0xb)))) {
    .debug::_SetSoundVolume__6TAudioFsUc(_DAT_100cdd24,param_3 + -2,1);
  }
  else if ((sVar7 == 0x83) && (sVar8 == 0xc)) {
    uVar6 = .glue::GetMenuHandle(0x83);
    .glue::GetItemMark(uVar6,param_3,asStack_28);
    if (asStack_28[0] == 0) {
      .debug::_EnableAmbient__6TAudioFUcUc(uVar5,1,1);
    }
    else {
      .debug::_EnableAmbient__6TAudioFUcUc(uVar5,0,1);
    }
  }
  else if (((sVar7 == 0x83) && (0xd < sVar8)) && (sVar8 < 0x12)) {
    .debug::_SetMusicVolume__6TAudioFsUc(_DAT_100cdd24,param_3 + -0xe,1);
  }
  else {
    .debug::_DefaultMenu__4TAppFss(param_1,param_2,param_3);
  }
  return;
}


// ==== .KeyRoutine__9TRunStartFs @ 10016690 ====
// CyDecompAt: created, body 10016690-10016897

void _KeyRoutine__9TRunStartFs(int param_1,short param_2)

{
  short sVar1;
  ushort uVar2;
  
  if (param_2 == 0x51) {
LAB_100167d0:
    .debug::_HiliteItem__9TRunStartFs(param_1,5);
    .debug::_DoItemHit__9TRunStartFs(param_1,5);
    return;
  }
  if (param_2 < 0x51) {
    if (param_2 != 0x41) {
      if (param_2 < 0x41) {
        if (param_2 != 0xd) {
          if (0xc < param_2) {
            if (param_2 != 0x1b) {
              return;
            }
            goto LAB_100167d0;
          }
          if (param_2 != 3) {
            return;
          }
        }
      }
      else {
        if (param_2 == 0x4e) goto LAB_100167b0;
        if (0x4d < param_2) {
          if (0x4f < param_2) goto LAB_10016810;
          goto LAB_10016790;
        }
        if (param_2 != 0x47) {
          return;
        }
      }
LAB_10016764:
      if (*(char *)(param_1 + 0xb8) == '\0') {
        return;
      }
      .debug::_HiliteItem__9TRunStartFs(param_1,0);
      .debug::_DoItemHit__9TRunStartFs(param_1,0);
      return;
    }
LAB_100167f0:
    .debug::_HiliteItem__9TRunStartFs(param_1,4);
    .debug::_DoItemHit__9TRunStartFs(param_1,4);
  }
  else {
    if (param_2 == 0x6e) {
LAB_100167b0:
      .debug::_HiliteItem__9TRunStartFs(param_1,1);
      .debug::_DoItemHit__9TRunStartFs(param_1,1);
      return;
    }
    if (param_2 < 0x6e) {
      if (param_2 == 0x61) goto LAB_100167f0;
      if (0x60 < param_2) {
        if (param_2 != 0x67) {
          return;
        }
        goto LAB_10016764;
      }
      if (param_2 != 0x58) {
        return;
      }
    }
    else {
      if (param_2 == 0x71) goto LAB_100167d0;
      if (param_2 < 0x71) {
        if (0x6f < param_2) {
LAB_10016810:
          .debug::_HiliteItem__9TRunStartFs(param_1,3);
          .debug::_DoItemHit__9TRunStartFs(param_1,3);
          return;
        }
LAB_10016790:
        .debug::_HiliteItem__9TRunStartFs(param_1,2);
        .debug::_DoItemHit__9TRunStartFs(param_1,2);
        return;
      }
      if (param_2 != 0x78) {
        return;
      }
    }
    sVar1 = *(short *)(param_1 + 0xba);
    while (sVar1 == *(short *)(param_1 + 0xba)) {
      uVar2 = .glue::Random();
      *(ushort *)(param_1 + 0xba) = uVar2 + (short)((int)(uint)uVar2 >> 3) * -8;
    }
    FUN_100c50e8(param_1);
  }
  return;
}


// ==== .MouseRoutine__9TRunStartF5Points @ 100169fc ====
// CyDecompAt: created, body 100169fc-10016c33

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _MouseRoutine__9TRunStartF5Points(int param_1,undefined4 param_2)

{
  int iVar1;
  char cVar2;
  int iVar3;
  undefined4 uVar4;
  int iVar5;
  bool bVar6;
  int iVar7;
  undefined4 uStack_28;
  undefined4 uStack_24;
  short sVar8;
  
  iVar5 = 0;
  while ((iVar7 = -1, (short)iVar5 < 6 &&
         (cVar2 = .glue::PtInRect(param_2,param_1 + (short)iVar5 * 8 + 0x54), iVar7 = iVar5,
         cVar2 == '\0'))) {
    iVar5 = iVar5 + 1;
  }
  sVar8 = (short)iVar7;
  if ((sVar8 != -1) &&
     (((sVar8 != 0 || (*(char *)(param_1 + 0xb8) != '\0')) &&
      (iVar5 = .glue::GetPicture(iVar7 + 0x8b), iVar5 != 0)))) {
    .glue::ClipRect(param_1 + sVar8 * 8 + 0x54);
    bVar6 = false;
    uVar4 = *(undefined4 *)(**(int **)(param_1 + 0x94) + 2);
    uStack_24 = *(undefined4 *)(**(int **)(param_1 + 0x94) + 6);
    uStack_28._2_2_ = (short)uVar4;
    iVar3 = (int)uStack_28._2_2_;
    uStack_28._0_2_ = (short)((uint)uVar4 >> 0x10);
    iVar1 = (int)uStack_28._0_2_;
    uStack_28 = uVar4;
    .glue::OffsetRect(&uStack_28,-iVar3,-iVar1);
    .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(_DAT_100cdd24,6);
    do {
      cVar2 = .glue::PtInRect(param_2,param_1 + sVar8 * 8 + 0x54);
      if (bVar6 != (bool)cVar2) {
        bVar6 = bVar6 == false;
        .glue::ClipRect(param_1 + sVar8 * 8 + 0x54);
        if (bVar6) {
          .glue::DrawPicture(iVar5,param_1 + sVar8 * 8 + 0x54);
        }
        else {
          .glue::DrawPicture(*(undefined4 *)(param_1 + 0x94),&uStack_28);
        }
      }
      .glue::GetMouse(&stack0x0000001c);
      FUN_100c50e8(param_1);
      cVar2 = .glue::StillDown();
    } while (cVar2 != '\0');
    if (bVar6 != false) {
      .glue::ClipRect(param_1 + sVar8 * 8 + 0x54);
      .glue::DrawPicture(*(undefined4 *)(param_1 + 0x94),&uStack_28);
    }
    .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(_DAT_100cdd24,7);
    .glue::ReleaseResource(iVar5);
    .glue::ClipRect(*(int *)(param_1 + 4) + 0x10);
    if (bVar6 != false) {
      .debug::_DoItemHit__9TRunStartFs(param_1,iVar7);
    }
  }
  return;
}


// ==== .IdleRoutine__9TRunStartFv @ 10016c68 ====
// CyDecompAt: created, body 10016c68-10016dbb

void _IdleRoutine__9TRunStartFv(int param_1)

{
  short sVar1;
  undefined *puVar2;
  undefined *puVar3;
  int iVar4;
  uint uVar5;
  int iVar6;
  undefined4 uVar7;
  undefined4 uStack_18;
  undefined4 uStack_14;
  
  puVar3 = PTR_DAT_100ce2c8;
  puVar2 = PTR_DAT_100ce2c4;
  if (*PTR_DAT_100ce2c8 == '\0') {
    *(undefined4 *)PTR_DAT_100ce2c4 = 0;
    *puVar3 = 1;
  }
  uVar5 = .glue::TickCount();
  if (*(uint *)puVar2 < uVar5) {
    .glue::SetPort(*(undefined4 *)(param_1 + 4));
    *(short *)(param_1 + 0xb0) = *(short *)(param_1 + 0xb0) + 1;
    sVar1 = *(short *)(param_1 + 0xb0);
    iVar4 = (int)sVar1 / 7 + ((int)sVar1 >> 0x1f);
    *(short *)(param_1 + 0xb0) = sVar1 + ((short)iVar4 - (short)(iVar4 >> 0x1f)) * -7;
    if (*(short *)(param_1 + 0xb0) == 0) {
      .glue::ClipRect(param_1 + 0x8c);
      uVar7 = *(undefined4 *)(**(int **)(param_1 + 0x94) + 2);
      uStack_14 = *(undefined4 *)(**(int **)(param_1 + 0x94) + 6);
      uStack_18._2_2_ = (short)uVar7;
      iVar6 = (int)uStack_18._2_2_;
      uStack_18._0_2_ = (short)((uint)uVar7 >> 0x10);
      iVar4 = (int)uStack_18._0_2_;
      uStack_18 = uVar7;
      .glue::OffsetRect(&uStack_18,-iVar6,-iVar4);
      .glue::DrawPicture(*(undefined4 *)(param_1 + 0x94),&uStack_18);
      .glue::ClipRect(*(int *)(param_1 + 4) + 0x10);
    }
    else {
      .glue::DrawPicture(*(undefined4 *)(param_1 + (*(short *)(param_1 + 0xb0) + -1) * 4 + 0x98),
                         param_1 + 0x8c);
    }
    iVar4 = .glue::TickCount();
    *(int *)puVar2 = iVar4 + 5;
  }
  return;
}


// ==== .DrawRoutine__9TRunStartFv @ 10016f84 ====
// CyDecompAt: created, body 10016f84-10017153

void _DrawRoutine__9TRunStartFv(int param_1)

{
  int iVar1;
  short sVar2;
  int iVar3;
  undefined4 uVar4;
  char cStack_128;
  undefined1 auStack_127 [257];
  undefined4 uStack_26;
  undefined4 uStack_22;
  
  .glue::SetPort(*(undefined4 *)(param_1 + 4));
  uVar4 = *(undefined4 *)(**(int **)(param_1 + 0x94) + 2);
  uStack_22 = *(undefined4 *)(**(int **)(param_1 + 0x94) + 6);
  uStack_26._2_2_ = (short)uVar4;
  iVar3 = (int)uStack_26._2_2_;
  uStack_26._0_2_ = (short)((uint)uVar4 >> 0x10);
  iVar1 = (int)uStack_26._0_2_;
  uStack_26 = uVar4;
  .glue::OffsetRect(&uStack_26,-iVar3,-iVar1);
  .glue::DrawPicture(*(undefined4 *)(param_1 + 0x94),&uStack_26);
  .debug::_ShowPName__9TRunStartFv(param_1);
  if (*(char *)(param_1 + 0xb8) == '\0') {
    iVar1 = .glue::GetPicture(0x91);
    if (iVar1 != 0) {
      .glue::DrawPicture(iVar1,param_1 + 0x54);
      .glue::ReleaseResource(iVar1);
    }
  }
  if (*(short *)(param_1 + 0xb0) != 0) {
    .glue::DrawPicture(*(undefined4 *)(param_1 + (*(short *)(param_1 + 0xb0) + -1) * 4 + 0x98),
                       param_1 + 0x8c);
  }
  cStack_128 = '\0';
  sVar2 = FUN_100b8f80(&cStack_128);
  if ((sVar2 == 0) && (cStack_128 != '\0')) {
    sVar2 = FUN_100b947c(auStack_127);
  }
  .glue::MoveTo(10,*(short *)(*(int *)(param_1 + 4) + 0x14) + -10);
  .glue::ForeColor(0x1e);
  if ((sVar2 == 0) && (cStack_128 != '\0')) {
    if (*(short *)(param_1 + 0xba) == 0) {
      .glue::DrawString(PTR_DAT_100ce2b4);
      .glue::DrawString(auStack_127);
    }
    else {
      .glue::DrawString((&PTR_DAT_100d4280)[*(short *)(param_1 + 0xba) + -1]);
    }
  }
  else {
    .glue::DrawString(PTR_DAT_100ce2bc);
  }
  .glue::ForeColor(0x21);
  return;
}


// ==== .CloseRoutine__9TRunStartFv @ 10017180 ====
// CyDecompAt: created, body 10017180-1001722b

void _CloseRoutine__9TRunStartFv(int param_1)

{
  short sVar1;
  
  if (*(int *)(param_1 + 4) != 0) {
    FUN_100c50e8(param_1);
    .glue::DisposeWindow(*(undefined4 *)(param_1 + 4));
    *(undefined4 *)(param_1 + 4) = 0;
    .glue::ReleaseResource(*(undefined4 *)(param_1 + 0x94));
    for (sVar1 = 0; sVar1 < 6; sVar1 = sVar1 + 1) {
      if (*(int *)(param_1 + sVar1 * 4 + 0x98) != 0) {
        .glue::ReleaseResource(*(undefined4 *)(param_1 + 0x94));
      }
    }
  }
  return;
}


// ==== .__dt__9TRunStartFv @ 10017408 ====
// CyDecompAt: created, body 10017408-1001746b

undefined4 * ___dt__9TRunStartFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d42b8;
    .debug::___dt__7TWindowFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .DoStartup__10TDelverAppFv @ 10017494 ====
// CyDecompAt: created, body 10017494-100174c7

void _DoStartup__10TDelverAppFv(undefined4 param_1)

{
  .debug::_InitWorld__10TDelverAppFv();
  .debug::_RunStart__10TDelverAppFv(param_1);
  return;
}


// ==== .LowOnMemory__10TDelverAppFv @ 100174f4 ====
// CyDecompAt: created, body 100174f4-1001755f

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _LowOnMemory__10TDelverAppFv(void)

{
  undefined **appuStack_20 [4];
  
  appuStack_20[0] = &PTR_PTR_100d3c68;
  FUN_100bdef4(PTR_s__std_exception__std_bad_alloc__100ce370,appuStack_20,_DAT_100cdb6c);
  return;
}


// ==== .GetAppSignature__10TDelverAppFv @ 10017908 ====
// CyDecompAt: created, body 10017908-10017913

undefined4 _GetAppSignature__10TDelverAppFv(void)

{
  return 0x44656c76;
}


// ==== .Log__10TDelverAppFPCce @ 10017948 ====
// CyDecompAt: created, body 10017948-10017963

void _Log__10TDelverAppFPCce(void)

{
  return;
}


// ==== .Align__13TMemoryStreamFs @ 10018448 ====
// CyDecompAt: created, body 10018448-10018473

undefined4 _Align__13TMemoryStreamFs(int param_1,short param_2)

{
  *(uint *)(param_1 + 0xc) = ~((int)param_2 - 1U) & *(int *)(param_1 + 0xc) + param_2 + -1;
  return 0;
}


// ==== .GetSize__13TMemoryStreamFv @ 100184dc ====
// CyDecompAt: created, body 100184dc-100184eb

int _GetSize__13TMemoryStreamFv(int param_1)

{
  return *(int *)(param_1 + 0x10) - *(int *)(param_1 + 8);
}


// ==== .SetPos__13TMemoryStreamFl @ 1001851c ====
// CyDecompAt: created, body 1001851c-1001852b

void _SetPos__13TMemoryStreamFl(int param_1,int param_2)

{
  *(int *)(param_1 + 0xc) = *(int *)(param_1 + 8) + param_2;
  return;
}


// ==== .Write__13TMemoryStreamFPvl @ 10018558 ====
// CyDecompAt: created, body 10018558-100185af

undefined4 _Write__13TMemoryStreamFPvl(int param_1,undefined4 param_2,int param_3)

{
  .glue::BlockMove(param_2,*(undefined4 *)(param_1 + 0xc));
  *(int *)(param_1 + 0xc) = *(int *)(param_1 + 0xc) + param_3;
  return 0;
}


// ==== .Read__13TMemoryStreamFPvl @ 100185e0 ====
// CyDecompAt: created, body 100185e0-10018637

undefined4 _Read__13TMemoryStreamFPvl(int param_1,undefined4 param_2,int param_3)

{
  .glue::BlockMove(*(undefined4 *)(param_1 + 0xc),param_2);
  *(int *)(param_1 + 0xc) = *(int *)(param_1 + 0xc) + param_3;
  return 0;
}


// ==== .ReadTo__13TMemoryStreamFPvRl @ 10018664 ====
// CyDecompAt: created, body 10018664-100186bf

undefined4 _ReadTo__13TMemoryStreamFPvRl(int param_1,undefined4 param_2,int *param_3)

{
  .glue::BlockMove(*(undefined4 *)(param_1 + 0xc),param_3,*param_3);
  *(int *)(param_1 + 0xc) = *(int *)(param_1 + 0xc) + *param_3;
  return 0;
}


// ==== .__dt__Q23std16invalid_argumentFv @ 10018dec ====
// CyDecompAt: created, body 10018dec-10018e8b

undefined4 * ___dt__Q23std16invalid_argumentFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d44e8;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d3cb8;
      if (param_1 != (undefined4 *)0xfffffffc) {
        .debug::___dt__28_RefCountedPtr<c,9_Array<c>>Fv(param_1 + 1,0xffffffff);
      }
      if (param_1 != (undefined4 *)0x0) {
        *param_1 = &PTR_PTR_100d3cc8;
      }
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__Q23std292_EmptyMemberOpt<Q23std231allocator<Q33std206__tree<Q23std24pair<CUl,PFP7TStream_Pv>,Q33std90map<Ul,PFP7TStream_Pv,Q23std8less<Ul>,Q23std43allocator<Q23std24pair<CUl,PFP7TStream_Pv>>>13value_compare,Q23std43allocator<Q23std24pair<CUl,PFP7TStream_Pv>>>4node>,Q33std19__red_black_tree<1>6anchor>Fv @ 10019774 ====
// CyDecompAt: created, body 10019774-100197cf

int ___dt__Q23std292_EmptyMemberOpt<Q23std231allocator<Q33std206__tree<Q23std24pair<CUl,PFP7TStream_Pv>,Q33std90map<Ul,PFP7TStream_Pv,Q23std8less<Ul>,Q23std43allocator<Q23std24pair<CUl,PFP7TStream_Pv>>>13value_compare,Q23std43allocator<Q23std24pair<CUl,PFP7TStream_Pv>>>4node>,Q33std19__red_black_tree<1>6anchor>Fv
              (int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .__dt__Q23std71_EmptyMemberOpt<Q23std43allocator<Q23std24pair<CUl,PFP7TStream_Pv>>,Ul>Fv @ 1001991c ====
// CyDecompAt: created, body 1001991c-10019977

int ___dt__Q23std71_EmptyMemberOpt<Q23std43allocator<Q23std24pair<CUl,PFP7TStream_Pv>>,Ul>Fv
              (int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .__dt__Q23std90map<Ul,PFP7TStream_Pv,Q23std8less<Ul>,Q23std43allocator<Q23std24pair<CUl,PFP7TStream_Pv>>>Fv @ 100199e4 ====
// CyDecompAt: created, body 100199e4-10019a77

int ___dt__Q23std90map<Ul,PFP7TStream_Pv,Q23std8less<Ul>,Q23std43allocator<Q23std24pair<CUl,PFP7TStream_Pv>>>Fv
              (int param_1,short param_2)

{
  if (param_1 != 0) {
    if ((param_1 != 0) && (*(int *)(param_1 + 4) != 0)) {
      FUN_10019bb4(param_1,*(undefined4 *)(param_1 + 4));
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__Q23std43allocator<Q23std24pair<CUl,PFP7TStream_Pv>>Fv @ 10019af8 ====
// CyDecompAt: created, body 10019af8-10019b63

int ___dt__Q23std43allocator<Q23std24pair<CUl,PFP7TStream_Pv>>Fv(int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .PlayOnceCB__FllP11STSoundSpec @ 1001ad44 ====
// CyDecompAt: created, body 1001ad44-1001ada3

void _PlayOnceCB__FllP11STSoundSpec(int param_1,undefined4 param_2,undefined4 *param_3)

{
  if (param_3 == (undefined4 *)0x0) {
    .glue::DebugStr(PTR_DAT_100ce450);
  }
  else if ((param_1 == 1) || (param_1 == 2)) {
    .debug::_QueueUnlock__FPc(*param_3);
  }
  return;
}


// ==== .LoopSpotCB__FllP11STSoundSpec @ 1001add4 ====
// CyDecompAt: created, body 1001add4-1001ae4b

void _LoopSpotCB__FllP11STSoundSpec(int param_1,undefined4 param_2,undefined4 *param_3)

{
  undefined4 uVar1;
  
  if (param_3 == (undefined4 *)0x0) {
    .glue::DebugStr(PTR_DAT_100ce44c);
  }
  else if (param_1 == 1) {
    uVar1 = FUN_100b7a58(param_3);
    *(undefined4 *)param_3[4] = uVar1;
  }
  else if (param_1 == 2) {
    .debug::_QueueUnlock__FPc(*param_3);
  }
  return;
}


// ==== .LoopCB__FllP11STSoundSpec @ 1001ae7c ====
// CyDecompAt: created, body 1001ae7c-1001af8f

void _LoopCB__FllP11STSoundSpec(int param_1,undefined4 param_2,undefined4 *param_3)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined4 uVar3;
  
  puVar2 = PTR_DAT_100ce440;
  puVar1 = PTR_DAT_100ce43c;
  if (param_3 == (undefined4 *)0x0) {
    .glue::DebugStr(PTR_DAT_100ce448);
  }
  else {
    *(undefined2 *)((int)param_3 + 0x16) = *(undefined2 *)(PTR_DAT_100ce444 + param_3[4] * 2);
    *(undefined2 *)(param_3 + 6) = *(undefined2 *)(puVar2 + param_3[4] * 2);
    if (param_1 == 1) {
      if ((*(short *)((int)param_3 + 0x16) == 0) && (*(short *)(param_3 + 6) == 0)) {
        *(undefined4 *)(puVar1 + param_3[4] * 4) = 0;
        .debug::_QueueUnlock__FPc(*param_3);
      }
      else {
        uVar3 = FUN_100b7a58(param_3);
        *(undefined4 *)(puVar1 + param_3[4] * 4) = uVar3;
      }
    }
    else if (param_1 == 3) {
      FUN_100b80f4(param_2,param_3);
    }
    else if (param_1 == 2) {
      *(undefined4 *)(puVar1 + param_3[4] * 4) = 0;
      .debug::_QueueUnlock__FPc(*param_3);
    }
  }
  return;
}


// ==== .__dt__6TAudioFv @ 1001b00c ====
// CyDecompAt: created, body 1001b00c-1001b0a3

undefined4 * ___dt__6TAudioFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = 0x100d4574;
    if (*(short *)((int)param_1 + 6) != 0) {
      .debug::_GMSQuit__Fv();
      *(undefined2 *)((int)param_1 + 6) = 0;
    }
    if (*(short *)(param_1 + 2) != 0) {
      FUN_100b7d60(0);
      .debug::_ConsumeUnlockQueue__Fv();
      FUN_100b7890();
      *(undefined2 *)(param_1 + 2) = 0;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__17TAdjustTaskMasterFv @ 1001cb0c ====
// CyDecompAt: created, body 1001cb0c-1001cb63

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined2 * ___dt__17TAdjustTaskMasterFv(undefined2 *param_1,short param_2)

{
  if (param_1 != (undefined2 *)0x0) {
    *_DAT_100cdd84 = *param_1;
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .MyScheduler__11TTaskMasterFP16SchedulerInfoRec @ 1001cb94 ====
// CyDecompAt: created, body 1001cb94-1001ced7

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

int _MyScheduler__11TTaskMasterFP16SchedulerInfoRec(int param_1)

{
  short *psVar1;
  int *piVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  undefined *puVar6;
  undefined *puVar7;
  undefined *puVar8;
  undefined *puVar9;
  undefined4 uVar10;
  uint uVar11;
  int iVar12;
  char cVar14;
  uint uVar13;
  undefined1 auStack_48 [16];
  short asStack_38 [4];
  
  puVar9 = PTR_DAT_100ce4fc;
  puVar8 = PTR_DAT_100ce4ec;
  puVar7 = PTR_DAT_100ce4e4;
  puVar6 = PTR_DAT_100ce4dc;
  puVar4 = PTR_DAT_100ce4d4;
  puVar3 = PTR_DAT_100cdd8c;
  piVar2 = _DAT_100cdd88;
  psVar1 = _DAT_100cdd84;
  .debug::_CheckSanity__12TSanityChunkFv();
  .debug::_HandleISPseudoMouse__Fv();
  puVar5 = PTR_DAT_100ce4f0;
  if (*PTR_DAT_100ce4f0 == '\0') {
    *(undefined4 *)puVar8 = 0;
    *puVar5 = 1;
  }
  puVar5 = PTR_DAT_100ce4e8;
  if (*PTR_DAT_100ce4e8 == '\0') {
    *(undefined4 *)puVar7 = 0;
    *puVar5 = 1;
  }
  puVar5 = PTR_DAT_100ce4e0;
  if (*PTR_DAT_100ce4e0 == '\0') {
    *(undefined4 *)puVar6 = 0;
    *puVar5 = 1;
  }
  puVar5 = PTR_DAT_100ce4d8;
  if (*PTR_DAT_100ce4d8 == '\0') {
    *(undefined2 *)puVar4 = 1;
    *puVar5 = 1;
  }
  if (*(int *)puVar8 == 0) {
    uVar10 = .glue::TickCount();
    *(undefined4 *)puVar8 = uVar10;
  }
  uVar11 = .glue::TickCount();
  while (uVar11 < *(uint *)puVar7) {
    uVar11 = .glue::TickCount();
  }
  .glue::GetThreadState(*piVar2,asStack_38);
  if (asStack_38[0] == 0) {
    if (*PTR_DAT_100cdd00 == '\0') {
      cVar14 = .debug::_AnyNeedsRedraw__7TWindowFv();
      if (cVar14 == '\0') {
        cVar14 = .glue::OSEventAvail(10,auStack_48);
        if ((cVar14 == '\0') || (*_DAT_100cdd74 != 0)) {
          if (*(char *)(*(int *)PTR_DAT_100cdb84 + 0x1e) == '\0') {
            iVar12 = 2;
          }
          else if ((*psVar1 == 2) && (*(short *)puVar4 < 1)) {
            *(undefined2 *)puVar4 = 1;
            iVar12 = *(int *)puVar3;
          }
          else if ((*psVar1 == 1) && (*(int *)(puVar9 + 0x18) != 0)) {
            iVar12 = *(int *)puVar3;
          }
          else if (((*psVar1 == 0) && (*(int *)(param_1 + 4) != *(int *)puVar3)) &&
                  (*(int *)(param_1 + 8) != *piVar2)) {
            iVar12 = *(int *)puVar3;
          }
          else {
            if ((*psVar1 == 3) && (uVar11 < *(uint *)puVar8)) {
              *(undefined4 *)puVar7 = *(undefined4 *)puVar8;
              while (uVar13 = .glue::TickCount(), uVar13 < *(uint *)puVar8) {
                uVar11 = .glue::TickCount();
              }
            }
            if (((uVar11 < *(uint *)puVar8) && (*psVar1 != 3)) || (*(int *)(param_1 + 4) == *piVar2)
               ) {
              *(uint *)puVar6 = uVar11;
              iVar12 = 2;
            }
            else {
              if (uVar11 < *(uint *)puVar8) {
                *(uint *)puVar8 = *(int *)puVar8 + (DAT_100d3e20 >> 2 & 0xf);
              }
              else {
                *(uint *)puVar8 = uVar11 + (DAT_100d3e20 >> 2 & 0xf);
              }
              if (0 < *(short *)puVar4) {
                *(short *)puVar4 = *(short *)puVar4 + -1;
              }
              if (*psVar1 == 3) {
                *psVar1 = 2;
              }
              iVar12 = *piVar2;
            }
          }
        }
        else {
          iVar12 = 2;
        }
      }
      else {
        iVar12 = 2;
      }
    }
    else {
      iVar12 = *(int *)(param_1 + 4);
    }
  }
  else {
    *(uint *)puVar6 = uVar11;
    iVar12 = 2;
  }
  return iVar12;
}


// ==== .TaskThread__11TTaskMasterFPv @ 1001d334 ====
// CyDecompAt: created, body 1001d334-1001d767

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _TaskThread__11TTaskMasterFPv(void)

{
  undefined *puVar1;
  undefined4 *puVar2;
  undefined *puVar3;
  undefined *puVar4;
  int *piVar5;
  ushort uVar7;
  int iVar6;
  uint *puVar8;
  int aiStack_2e4 [7];
  uint uStack_2c8;
  uint uStack_2c4;
  undefined1 *puStack_98;
  short sStack_94;
  undefined4 uStack_90;
  uint uStack_8c;
  uint uStack_88;
  uint uStack_84;
  undefined1 *puStack_6c;
  undefined **appuStack_68 [6];
  undefined1 *puStack_50;
  
  puVar4 = PTR_DAT_100ce500;
  puVar3 = PTR_DAT_100ce4fc;
  puVar1 = PTR_DAT_100cdc44;
  puStack_50 = &stack0xfffffce0;
  do {
    while( true ) {
      do {
        while( true ) {
          if (*(int *)(*(int *)PTR_DAT_100cdb84 + 0x60) == 0) {
            appuStack_68[0] = &PTR_PTR_100d3c68;
            FUN_100bdef4(PTR_s__std_exception__std_bad_alloc__100ce4c4,appuStack_68,_DAT_100cdb6c);
          }
          if (*(int *)(puVar3 + 0x18) != 0) break;
          .glue::YieldToAnyThread();
        }
        puStack_6c = &stack0xfffffce0;
        piVar5 = (int *).debug::___vc__Q23std34__cdeque<Pv,Q23std13allocator<Pv>>FUl
                                  (puVar3 + 4,*(uint *)(puVar3 + 0x14) / *(uint *)puVar3);
        puVar8 = (uint *)(*piVar5 +
                         (*(uint *)(puVar3 + 0x14) -
                         (*(uint *)(puVar3 + 0x14) / *(uint *)puVar3) * *(uint *)puVar3) * 0x10);
        uStack_90 = *puVar8;
        uStack_8c = puVar8[1];
        uStack_88 = puVar8[2];
        uStack_84 = CONCAT22(*(undefined2 *)(puVar8 + 3),uStack_84._2_2_);
        .debug::_pop_front__Q23std47deque<9TaskEvent,Q23std21allocator<9TaskEvent>>Fv(puVar3);
      } while ((*(uint *)puVar4 & 1 << ((int)uStack_90._2_2_ & 0x3fU)) != 0);
      if (uStack_90._0_2_ != 3) break;
      .glue::TickCount();
      .debug::_MoveAll__14TActiveMonsterFv();
    }
    if (uStack_90._0_2_ < 3) {
      if (uStack_90._0_2_ == 1) {
        .glue::TickCount();
        .glue::SetPort(*(undefined4 *)(uStack_8c + 4));
        while ((*(int *)(puVar3 + 0x18) != 0 &&
               (piVar5 = (int *).debug::___vc__Q23std34__cdeque<Pv,Q23std13allocator<Pv>>FUl
                                          (puVar3 + 4,*(uint *)(puVar3 + 0x14) / *(uint *)puVar3),
               *(short *)(*piVar5 +
                         (*(uint *)(puVar3 + 0x14) -
                         (*(uint *)(puVar3 + 0x14) / *(uint *)puVar3) * *(uint *)puVar3) * 0x10) ==
               1))) {
          piVar5 = (int *).debug::___vc__Q23std34__cdeque<Pv,Q23std13allocator<Pv>>FUl
                                    (puVar3 + 4,*(uint *)(puVar3 + 0x14) / *(uint *)puVar3);
          puVar8 = (uint *)(*piVar5 +
                           (*(uint *)(puVar3 + 0x14) -
                           (*(uint *)(puVar3 + 0x14) / *(uint *)puVar3) * *(uint *)puVar3) * 0x10);
          uStack_90 = *puVar8;
          uStack_8c = puVar8[1];
          uStack_88 = puVar8[2];
          uStack_84 = puVar8[3];
          .debug::_pop_front__Q23std47deque<9TaskEvent,Q23std21allocator<9TaskEvent>>Fv(puVar3);
          uStack_90 = uStack_90 & 0xfffffffc | 2;
        }
        .debug::_MouseRoutine__16TDroppableWindowF5Points(uStack_8c,uStack_88,(int)uStack_90._2_2_);
      }
      else if (0 < uStack_90._0_2_) {
        .glue::TickCount();
        .glue::SetPort(*(undefined4 *)(uStack_8c + 4));
        .debug::_KeyRoutine__16TDroppableWindowFs(uStack_8c,(int)(short)uStack_84._0_2_);
      }
    }
    else if (uStack_90._0_2_ == 5) {
      *(uint *)puVar4 = *(uint *)puVar4 & ~(1 << ((int)uStack_90._2_2_ & 0x3fU));
    }
    else if (uStack_90._0_2_ < 5) {
      uVar7 = .debug::_FindSkill__Fss((int)*(short *)PTR_DAT_100cdbec,(int)(short)uStack_84._0_2_);
      if ((uVar7 == 0) && (0xbf < (short)uStack_84._0_2_)) {
        *(undefined1 *)(*(int *)puVar1 + 0x3fff0) = 0x1c;
        uVar7 = 0x3fff;
        *(ushort *)(*(int *)puVar1 + 0x3fff4) =
             uStack_84._0_2_ & 0x3ff | *(ushort *)(*(int *)puVar1 + 0x3fff4) & 0xfc00;
        iVar6 = *(int *)puVar1;
        *(uint *)(iVar6 + 0x3fff0) =
             *(uint *)(iVar6 + 0x3fff0) & 0xff0000 | 0x3fff |
             *(uint *)(iVar6 + 0x3fff0) & 0xff000000;
      }
      if (uVar7 != 0) {
        uStack_2c4 = uVar7 | 0x40500000;
        .debug::_HasProperty__7TInterpFs5VAddr(aiStack_2e4,9,uStack_2c4);
        if (aiStack_2e4[0] != *(int *)PTR_DAT_100cdbb0) {
          sStack_94 = .debug::_MakeActive__14TActiveMonsterFsUc((int)uStack_90._2_2_,1);
          puVar2 = _DAT_100cdcd0;
          *_DAT_100cdcd4 = *_DAT_100cdcd4 + 1;
          uStack_2c8 = uVar7 | 0x40500000;
          puStack_98 = &stack0xfffffce0;
          .debug::_DoUse__8TGameSysF5VAddr(*puVar2,uStack_2c8);
          *_DAT_100cdcd4 = *_DAT_100cdcd4 + -1;
          .debug::_MakeActive__14TActiveMonsterFsUc((int)sStack_94,1);
          .debug::_HeartBeat__8TGameSysFs(*_DAT_100cdcd0,3);
        }
      }
    }
  } while( true );
}


// ==== .__dt__Q23std52__cdeque<P9TaskEvent,Q23std22allocator<P9TaskEvent>>Fv @ 1001ded0 ====
// CyDecompAt: created, body 1001ded0-1001df5b

int ___dt__Q23std52__cdeque<P9TaskEvent,Q23std22allocator<P9TaskEvent>>Fv(int param_1,short param_2)

{
  if (param_1 != 0) {
    if ((param_1 != 0) && (*(int *)(param_1 + 0xc) != 0)) {
      FUN_100be848(*(undefined4 *)(param_1 + 0xc));
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__Q23std49_EmptyMemberOpt<Q23std21allocator<9TaskEvent>,Ul>Fv @ 100229bc ====
// CyDecompAt: created, body 100229bc-10022a17

int ___dt__Q23std49_EmptyMemberOpt<Q23std21allocator<9TaskEvent>,Ul>Fv(int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .__dt__Q23std73queue<9TaskEvent,Q23std47deque<9TaskEvent,Q23std21allocator<9TaskEvent>>>Fv @ 10022b60 ====
// CyDecompAt: created, body 10022b60-10022c0f

int ___dt__Q23std73queue<9TaskEvent,Q23std47deque<9TaskEvent,Q23std21allocator<9TaskEvent>>>Fv
              (int param_1,short param_2)

{
  if (param_1 != 0) {
    if ((((param_1 != 0) &&
         (.debug::_tear_down__Q23std47deque<9TaskEvent,Q23std21allocator<9TaskEvent>>Fv(param_1),
         param_1 != -4)) && (param_1 != -4)) && (*(int *)(param_1 + 0x10) != 0)) {
      FUN_100be848(*(undefined4 *)(param_1 + 0x10));
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__Q23std47deque<9TaskEvent,Q23std21allocator<9TaskEvent>>Fv @ 10022c80 ====
// CyDecompAt: created, body 10022c80-10022d27

int ___dt__Q23std47deque<9TaskEvent,Q23std21allocator<9TaskEvent>>Fv(int param_1,short param_2)

{
  if (param_1 != 0) {
    .debug::_tear_down__Q23std47deque<9TaskEvent,Q23std21allocator<9TaskEvent>>Fv(param_1);
    if (((param_1 != -4) && (param_1 != -4)) && (*(int *)(param_1 + 0x10) != 0)) {
      FUN_100be848(*(undefined4 *)(param_1 + 0x10));
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__Q23std21allocator<9TaskEvent>Fv @ 10022d7c ====
// CyDecompAt: created, body 10022d7c-10022de7

int ___dt__Q23std21allocator<9TaskEvent>Fv(int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .PointToProp__16TDroppableWindowF5Point @ 100259e4 ====
// CyDecompAt: created, body 100259e4-100259eb

undefined4 _PointToProp__16TDroppableWindowF5Point(void)

{
  return 0;
}


// ==== .PointToContainterProp__16TDroppableWindowF5Point @ 10025a28 ====
// CyDecompAt: created, body 10025a28-10025a2f

undefined4 _PointToContainterProp__16TDroppableWindowF5Point(void)

{
  return 0;
}


// ==== .PropToPoint__16TDroppableWindowFsP5Point @ 10025a74 ====
// CyDecompAt: created, body 10025a74-10025a7b

undefined4 _PropToPoint__16TDroppableWindowFsP5Point(void)

{
  return 0;
}


// ==== .IsReadOnly__16TDroppableWindowFv @ 10025bfc ====
// CyDecompAt: created, body 10025bfc-10025c03

undefined4 _IsReadOnly__16TDroppableWindowFv(void)

{
  return 0;
}


// ==== .PointToCoordinate__16TDroppableWindowF5PointRsRs @ 10025c38 ====
// CyDecompAt: created, body 10025c38-10025c3f

undefined4 _PointToCoordinate__16TDroppableWindowF5PointRsRs(void)

{
  return 0;
}


// ==== .CanSearch__16TDroppableWindowF5Point @ 10025c84 ====
// CyDecompAt: created, body 10025c84-10025e63

undefined4 _CanSearch__16TDroppableWindowF5Point(undefined4 param_1,undefined4 param_2)

{
  ushort uVar1;
  ushort uVar2;
  undefined *puVar3;
  undefined *puVar4;
  char cVar7;
  uint uVar5;
  undefined4 uVar6;
  short sStack_38;
  short asStack_36 [3];
  
  puVar4 = PTR_DAT_100cdbf0;
  puVar3 = PTR_DAT_100cdbec;
  cVar7 = FUN_100c50e8(param_1,param_2,asStack_36,&sStack_38);
  if (cVar7 == '\0') {
    uVar6 = 0;
  }
  else {
    uVar1 = (ushort)(*(uint *)(puVar4 + *(short *)puVar3 * 0x20) >> 0xc) & 0xfff;
    uVar2 = (ushort)*(undefined4 *)(puVar4 + *(short *)puVar3 * 0x20) & 0xfff;
    if (((((int)asStack_36[0] < (short)uVar1 + -1) || ((short)uVar1 + 1 < (int)asStack_36[0])) ||
        ((int)sStack_38 < (short)uVar2 + -1)) || ((short)uVar2 + 1 < (int)sStack_38)) {
      uVar6 = 0;
    }
    else {
      if ((int)asStack_36[0] == (short)uVar1 + 1) {
        uVar5 = .debug::_GetTileBits__7TViewerFssss
                          (*(undefined4 *)PTR_DAT_100cdbb8,(int)(short)(asStack_36[0] << 2),
                           (int)(short)(sStack_38 << 2),4,4);
        if (((uVar5 & 8) != 0) || ((uVar5 & 4) == 0)) {
          return 1;
        }
        if (((uVar5 & 0x600) == 0x600) && ((uVar5 & 0x4000) == 0)) {
          return 2;
        }
      }
      if ((int)sStack_38 == (short)uVar2 + 1) {
        uVar5 = .debug::_GetTileBits__7TViewerFssss
                          (*(undefined4 *)PTR_DAT_100cdbb8,(int)(short)(asStack_36[0] << 2),
                           (int)(short)(sStack_38 << 2),4,4);
        if (((uVar5 & 8) != 0) || ((uVar5 & 4) == 0)) {
          return 1;
        }
        if (((uVar5 & 0x600) == 0x600) && ((uVar5 & 0x2000) == 0)) {
          return 2;
        }
      }
      uVar6 = 1;
    }
  }
  return uVar6;
}


// ==== .GetGesture__16TDroppableWindowF5PointUls @ 10026aa8 ====
// CyDecompAt: created, body 10026aa8-10026d47

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4
_GetGesture__16TDroppableWindowF5PointUls(int param_1,undefined4 param_2,int param_3,uint param_4)

{
  undefined2 uVar1;
  undefined *puVar2;
  undefined2 *puVar3;
  undefined4 uVar4;
  char cVar8;
  int iVar5;
  int iVar6;
  uint uVar7;
  short sVar9;
  short sStack_46;
  short sStack_44;
  undefined1 auStack_40 [16];
  undefined1 uStack_30;
  
  puVar3 = _DAT_100cdd84;
  uVar4 = _DAT_100cdd24;
  puVar2 = PTR_DAT_100cdb84;
  uStack_30 = 0;
  .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(_DAT_100cdd24,6);
  if ((param_4 & 0x1000) == 0) {
    if ((param_4 & 0x800) == 0) {
      if ((param_4 & 3) < 2) {
        while( true ) {
          cVar8 = .glue::StillDown();
          if ((cVar8 == '\0') && (cVar8 = .debug::_ISButton__Fv(), cVar8 == '\0')) {
            iVar5 = .glue::LMGetDoubleTime();
            iVar6 = .glue::TickCount();
            while( true ) {
              uVar7 = .glue::TickCount();
              if ((uint)(iVar6 + iVar5) < uVar7) {
                return 0;
              }
              *(short *)(*(int *)puVar2 + 0x24) = *(short *)(*(int *)puVar2 + 0x24) + 1;
              cVar8 = FUN_100c50e8(*(undefined4 *)puVar2,2,auStack_40,0);
              if (cVar8 != '\0') break;
              *(short *)(*(int *)puVar2 + 0x24) = *(short *)(*(int *)puVar2 + 0x24) + -1;
            }
            FUN_100c50e8(*(undefined4 *)puVar2,2,auStack_40,1);
            .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(uVar4,5);
            .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(uVar4,7);
            *(short *)(*(int *)puVar2 + 0x24) = *(short *)(*(int *)puVar2 + 0x24) + -1;
            return 1;
          }
          iVar5 = .glue::LMGetDoubleTime();
          uVar7 = .glue::TickCount();
          if ((uint)(param_3 + iVar5 * 2) < uVar7) {
            return 3;
          }
          .glue::GetMouse(&sStack_46);
          if (((((int)sStack_44 < (short)param_2 + -3) || ((short)param_2 + 3 < (int)sStack_44)) ||
              (sVar9 = (short)((uint)param_2 >> 0x10), (int)sStack_46 < sVar9 + -3)) ||
             (sVar9 + 3 < (int)sStack_46)) break;
          *(short *)(*(int *)puVar2 + 0x24) = *(short *)(*(int *)puVar2 + 0x24) + 1;
          uVar1 = *puVar3;
          *puVar3 = 0;
          .glue::YieldToAnyThread();
          .glue::SetPort(*(undefined4 *)(param_1 + 4));
          *(short *)(*(int *)puVar2 + 0x24) = *(short *)(*(int *)puVar2 + 0x24) + -1;
          *puVar3 = uVar1;
        }
        uVar4 = 2;
      }
      else {
        .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(uVar4,5);
        .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(uVar4,7);
        uVar4 = 1;
      }
    }
    else {
      .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(uVar4,5);
      .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(uVar4,7);
      uVar4 = 1;
    }
  }
  else {
    uVar4 = 3;
  }
  return uVar4;
}


// ==== .__dt__9TSavePortFv @ 10028b98 ====
// CyDecompAt: created, body 10028b98-10028bef

undefined4 * ___dt__9TSavePortFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    .glue::SetPort(*param_1);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .ChildToGlobalCoord__16TDroppableWindowFsR5Point @ 1002a724 ====
// CyDecompAt: created, body 1002a724-1002a737

void _ChildToGlobalCoord__16TDroppableWindowFsR5Point
               (undefined4 param_1,undefined4 param_2,undefined2 *param_3)

{
  param_3[1] = 0;
  *param_3 = 0;
  return;
}


// ==== .BecomeKeyTarget__16TDroppableWindowFv @ 1002a77c ====
// CyDecompAt: created, body 1002a77c-1002a783

undefined4 _BecomeKeyTarget__16TDroppableWindowFv(void)

{
  return 0;
}


// ==== .KeyTargetToProp__16TDroppableWindowFv @ 1002a7bc ====
// CyDecompAt: created, body 1002a7bc-1002a7c3

undefined4 _KeyTargetToProp__16TDroppableWindowFv(void)

{
  return 0;
}


// ==== .StopKeyTarget__16TDroppableWindowFv @ 1002a7fc ====
// CyDecompAt: created, body 1002a7fc-1002a7ff

void _StopKeyTarget__16TDroppableWindowFv(void)

{
  return;
}


// ==== .MoveKeyTarget__16TDroppableWindowFQ28TGameSys10EDirection @ 1002a838 ====
// CyDecompAt: created, body 1002a838-1002a83b

void _MoveKeyTarget__16TDroppableWindowFQ28TGameSys10EDirection(void)

{
  return;
}


// ==== .__dt__16TDroppableWindowFv @ 1002aa20 ====
// CyDecompAt: created, body 1002aa20-1002aa83

undefined4 * ___dt__16TDroppableWindowFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d4614;
    .debug::___dt__7TWindowFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .LDEFDraw__12TAbilityListFUcP4Rect5Pointss @ 1002abdc ====
// CyDecompAt: created, body 1002abdc-1002b0e7

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _LDEFDraw__12TAbilityListFUcP4Rect5Pointss
               (int param_1,char param_2,undefined4 *param_3,undefined4 param_4,undefined4 param_5,
               short param_6)

{
  bool bVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  uint uVar6;
  undefined4 uVar7;
  short sVar8;
  uint uVar9;
  int iVar10;
  uint uVar11;
  undefined4 uStack_298;
  undefined4 uStack_294;
  short sStack_290;
  short sStack_28e;
  short sStack_28c;
  short sStack_28a;
  undefined *puStack_288;
  undefined4 uStack_284;
  undefined4 uStack_280;
  undefined4 uStack_27c;
  undefined4 uStack_278;
  undefined4 uStack_274;
  undefined4 uStack_270;
  undefined4 uStack_26c;
  undefined4 uStack_268;
  undefined4 uStack_264;
  undefined4 uStack_260;
  undefined4 uStack_25c;
  undefined2 uStack_258;
  undefined1 uStack_256;
  undefined1 auStack_255 [255];
  undefined1 uStack_156;
  undefined1 auStack_155 [255];
  short asStack_56 [2];
  short sStack_52;
  short asStack_4e [9];
  
  puVar5 = PTR_DAT_100ce6b8;
  puVar4 = PTR_DAT_100ce6b4;
  puVar3 = PTR_DAT_100cdc44;
  puVar2 = PTR_DAT_100cdb94;
  .glue::ForeColor(0x21);
  .glue::BackColor(0x1e);
  .glue::PenPat(puVar2 + 0xba);
  .glue::PenNormal();
  .glue::EraseRect(param_3);
  if (param_6 == 2) {
    .debug::_SetText__Fs(2);
    if (param_2 == '\0') {
      .glue::ForeColor(0x21);
    }
    else {
      .glue::ForeColor(0xcd);
    }
    .glue::LGetCell(asStack_4e,&stack0x0000002e,param_4,*(undefined4 *)(param_1 + 4));
    .glue::LRect(asStack_56,param_4,*(undefined4 *)(param_1 + 4));
    .debug::___ct__5VAddrFcUsUs(&uStack_298,4,0x50,asStack_4e[0]);
    .debug::_DoInterp__7TInterpFs5VAddr(&uStack_294,2,uStack_298);
    uVar7 = .debug::_VAddrToPtr__7TInterpF5VAddr(uStack_294);
    uVar11 = *(ushort *)(*(int *)puVar3 + asStack_4e[0] * 0x10 + 4) & 0x3ff;
    sVar8 = .debug::_SkillToFKey__13TStatusWindowFs(*(undefined4 *)PTR_DAT_100cdb98,uVar11);
    if (sVar8 != 0) {
      .debug::_SetText__Fs(3);
      uVar9 = (int)asStack_56[0] + (int)sStack_52;
      uVar6 = (uint)*(short *)(_DAT_100cdb90 + 8);
      .glue::MoveTo(*(short *)((int)param_3 + 2) + 2,
                    (int)(short)((short)((int)uVar9 >> 1) +
                                (ushort)((int)uVar9 < 0 && (uVar9 & 1) != 0)) +
                    ((int)uVar6 >> 1) + (uint)((int)uVar6 < 0 && (uVar6 & 1) != 0));
      if (9 < sVar8) {
        .glue::TextFace(*(byte *)(*(int *)(puVar2 + 0xca) + 0x46) + 0x20);
      }
      .glue::DrawChar(0x46);
      .glue::NumToString((int)sVar8,&uStack_156);
      .debug::_AADrawText__FPcss(auStack_155,0,uStack_156);
      .glue::TextFace(0);
    }
    .debug::_SetText__Fs(2);
    if ((ushort)uVar11 < 0xc0) {
      iVar10 = 0x14;
    }
    else {
      iVar10 = 8;
    }
    uVar9 = (uint)*(short *)(_DAT_100cdb90 + 0x10);
    uVar6 = (int)asStack_56[0] + (int)sStack_52;
    .glue::MoveTo(*(short *)((int)param_3 + 2) + iVar10,
                  (int)(short)((short)((int)uVar6 >> 1) +
                              (ushort)((int)uVar6 < 0 && (uVar6 & 1) != 0)) +
                  ((int)uVar9 >> 1) + (uint)((int)uVar9 < 0 && (uVar9 & 1) != 0));
    if ((*(byte *)(*(int *)puVar3 + asStack_4e[0] * 0x10 + 4) >> 2 & 0x1f) == 0) {
      sVar8 = FUN_100b6ce8(uVar7);
      .debug::_AADrawText__FPcss(uVar7,0,(int)sVar8);
    }
    else {
      if ((*(byte *)(*(int *)puVar3 + asStack_4e[0] * 0x10 + 4) >> 2 & 0x10) != 0) {
        .glue::TextFace(2);
      }
      sVar8 = FUN_100b6ce8(uVar7);
      .debug::_AADrawText__FPcss(uVar7,0,(int)sVar8);
      .debug::_AADrawText__FPcss(puVar5 + 1,0,*puVar5);
      .glue::NumToString(*(byte *)(*(int *)puVar3 + asStack_4e[0] * 0x10 + 4) >> 2 & 0xf,&uStack_256
                        );
      .debug::_AADrawText__FPcss(auStack_255,0,uStack_256);
      .debug::_AADrawText__FPcss(puVar4 + 1,0,*puVar4);
      .glue::TextFace(0);
    }
    .glue::ForeColor(0x21);
    bVar1 = false;
    if (*(int *)(*(int *)PTR_DAT_100cdc2c + ((int)(uVar11 + 0x8a00 & 0xffff) >> 8) * 4 + 8) != 0) {
      if (*(int *)(*(int *)(*(int *)PTR_DAT_100cdc2c +
                           ((int)(uVar11 + 0x8a00 & 0xffff) >> 8) * 4 + 8) +
                  ((uVar11 + 0x8a00) * 8 & 0x7f8)) != 0) {
        bVar1 = true;
      }
    }
    if (bVar1) {
      puStack_288 = _DAT_100d3de4;
      uStack_284 = uRam100d3de8;
      uStack_280 = uRam100d3dec;
      uStack_27c = uRam100d3df0;
      uStack_278 = uRam100d3df4;
      uStack_274 = uRam100d3df8;
      uStack_270 = uRam100d3dfc;
      uStack_26c = uRam100d3e00;
      uStack_268 = uRam100d3e04;
      uStack_264 = uRam100d3e08;
      uStack_260 = uRam100d3e0c;
      uStack_25c = uRam100d3e10;
      uStack_258 = uRam100d3e14;
      .glue::SetRect((int)&uStack_284 + 2,0,0,0x20,0x10);
      .debug::_LoadSegment__8TSegFileFUsPvll
                (*(undefined4 *)PTR_DAT_100cdc2c,uVar11 + 0x8a00,PTR_DAT_100ce6b0,0,0x200);
      puStack_288 = PTR_DAT_100ce6b0;
      sStack_28a = (short)param_3[1];
      sStack_290 = (short)((uint)*param_3 >> 0x10);
      _sStack_290 = CONCAT22(sStack_290,sStack_28a + -0x20);
      _sStack_28c = CONCAT22(sStack_290 + 0x10,sStack_28a);
      .glue::CopyBits(&puStack_288,*(int *)(puVar2 + 0xca) + 2,(int)&uStack_284 + 2,&sStack_290,0,0)
      ;
    }
    if (param_2 != '\0') {
      uVar11 = .glue::LMGetHiliteMode();
      .glue::LMSetHiliteMode(uVar11 & 0xffffff7f);
      .glue::InvertRect(param_3);
    }
  }
  return;
}


// ==== .CloseRoutine__16TCharacterWindowFv @ 1002b2d4 ====
// CyDecompAt: created, body 1002b2d4-1002b3a7

void _CloseRoutine__16TCharacterWindowFv(int param_1)

{
  undefined4 uVar1;
  undefined4 auStack_18 [4];
  
  uVar1 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_18);
  .glue::SetPort(uVar1);
  .glue::HidePen();
  FUN_100c50e8();
  if (*(int *)(param_1 + 0x20) != 0) {
    FUN_100c50e8(*(int *)(param_1 + 0x20),1);
  }
  FUN_100c50e8();
  if (*(int *)(param_1 + 0x70) != 0) {
    FUN_100c50e8(*(int *)(param_1 + 0x70),1);
  }
  .debug::_CloseRoutine__16TInventoryWindowFv(param_1);
  .glue::SetPort(auStack_18[0]);
  return;
}


// ==== .__dt__12TAbilityListFv @ 1002b3e0 ====
// CyDecompAt: created, body 1002b3e0-1002b443

undefined4 * ___dt__12TAbilityListFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d490c;
    .debug::___dt__8TListBoxFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__14TInventoryListFv @ 1002b470 ====
// CyDecompAt: created, body 1002b470-1002b4d3

undefined4 * ___dt__14TInventoryListFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d4cbc;
    .debug::___dt__8TListBoxFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .CloseAtDistance__16TCharacterWindowFss @ 1002b500 ====
// CyDecompAt: created, body 1002b500-1002b727

void _CloseAtDistance__16TCharacterWindowFss(int param_1,short param_2,short param_3)

{
  short sVar1;
  bool bVar2;
  uint uVar3;
  short sVar4;
  uint uVar5;
  undefined4 *puVar6;
  int iVar7;
  
  puVar6 = (undefined4 *)(*(int *)PTR_DAT_100cdc44 + *(short *)(param_1 + 0x10) * 0x10);
  sVar1 = *(short *)((int)puVar6 + 2);
  sVar4 = (short)((uint)*puVar6 >> 8) >> 4;
  if ((PTR_DAT_100cdbf0[*(short *)(param_1 + 0x1c) * 0x20 + 8] & 0x40) == 0) {
    iVar7 = *(int *)PTR_DAT_100cdbb8;
    bVar2 = false;
    sVar1 = (short)((ushort)((uint)((int)sVar1 << 0x14) >> 0x10) | (ushort)(sVar1 >> 0xf) >> 0xc) >>
            4;
    if (-(int)*(short *)(iVar7 + 2) <= (int)(short)(sVar4 - param_2)) {
      if ((short)(sVar4 - param_2) <= *(short *)(iVar7 + 2)) {
        if (-(int)*(short *)(iVar7 + 2) <= (int)(short)(sVar1 - param_3)) {
          if ((short)(sVar1 - param_3) <= *(short *)(iVar7 + 2)) {
            uVar5 = (uint)*(short *)(iVar7 + 4);
            uVar3 = (uint)*(short *)(iVar7 + 4);
            if ((*(byte *)((int)(short)(sVar4 - param_2) +
                          ((int)uVar5 >> 1) + (uint)((int)uVar5 < 0 && (uVar5 & 1) != 0) +
                          (int)*(short *)(iVar7 + 4) *
                          ((int)(short)(sVar1 - param_3) +
                          ((int)uVar3 >> 1) + (uint)((int)uVar3 < 0 && (uVar3 & 1) != 0)) + iVar7 +
                          0xc0c8) & 3) != 0) {
              bVar2 = true;
            }
          }
        }
      }
    }
    if (bVar2) {
      if ((PTR_DAT_100cdbf0[*(short *)(param_1 + 0x1c) * 0x20 + 8] & 0x40) == 0) {
        if (((((int)sVar4 < param_2 + -1) || (param_2 + 1 < (int)sVar4)) ||
            ((int)sVar1 < param_3 + -1)) || (param_3 + 1 < (int)sVar1)) {
          if (*(short *)(*(int *)(param_1 + 4) + 0x14) != 0x42) {
            .glue::SizeWindow(*(undefined4 *)(param_1 + 4),0xdc,0x42,0);
          }
        }
        else if (*(short *)(*(int *)(param_1 + 4) + 0x14) != 0x110) {
          .glue::SizeWindow(*(undefined4 *)(param_1 + 4),0xdc,0x110,0);
          FUN_100c50e8(param_1);
        }
      }
    }
    else {
      FUN_100c50e8(param_1);
    }
  }
  return;
}


// ==== .cmpskills__FPCsPCs @ 1002bb64 ====
// CyDecompAt: created, body 1002bb64-1002bbeb

undefined4 _cmpskills__FPCsPCs(short *param_1,short *param_2)

{
  undefined4 uVar1;
  int iVar2;
  int iVar3;
  
  iVar3 = *(int *)PTR_DAT_100cdc44 + *param_1 * 0x10;
  iVar2 = *(int *)PTR_DAT_100cdc44 + *param_2 * 0x10;
  if ((*(ushort *)(iVar3 + 4) & 0x3ff) < (*(ushort *)(iVar2 + 4) & 0x3ff)) {
    uVar1 = 0xffffffff;
  }
  else if ((*(ushort *)(iVar2 + 4) & 0x3ff) < (*(ushort *)(iVar3 + 4) & 0x3ff)) {
    uVar1 = 1;
  }
  else {
    uVar1 = 0;
  }
  return uVar1;
}


// ==== .CalcSubRefreshRect__16TCharacterWindowFR4Rect @ 1002bda0 ====
// CyDecompAt: created, body 1002bda0-1002bf2b

void _CalcSubRefreshRect__16TCharacterWindowFR4Rect(int param_1,undefined2 *param_2)

{
  if ((*(ushort *)(param_1 + 0x12) & 0x200) != 0) {
    if (*(short *)(param_1 + 0x86) != 2) {
      .debug::_RecalcSkills__16TCharacterWindowFv(param_1);
      *(ushort *)(param_1 + 0x12) = *(ushort *)(param_1 + 0x12) & 0xfdff;
    }
  }
  if ((*(ushort *)(param_1 + 0x12) & 0x100) != 0) {
    if (*(short *)(param_1 + 0x86) != 1) {
      .debug::_RecalcWieldList__16TCharacterWindowFv(param_1);
      *(ushort *)(param_1 + 0x12) = *(ushort *)(param_1 + 0x12) & 0xfeff;
    }
  }
  if ((*(ushort *)(param_1 + 0x12) & 2) != 0) {
    if (*(short *)(param_1 + 0x86) == 2) {
      .debug::_RecalcInventory__16TCharacterWindowFv(param_1);
      *(ushort *)(param_1 + 0x12) = *(ushort *)(param_1 + 0x12) & 0xfffd;
    }
  }
  if ((*(ushort *)(param_1 + 0x12) & 0x800) != 0) {
    if (*(short *)(param_1 + 0x86) != 2) {
      *(ushort *)(param_1 + 0x12) = *(ushort *)(param_1 + 0x12) & 0xf7ff;
    }
  }
  if ((*(ushort *)(param_1 + 0x12) & 0x1000) != 0) {
    .debug::_RecalcUserAIMenu__16TCharacterWindowFv(param_1);
    if (*(short *)(param_1 + 0x86) != 2) {
      *(ushort *)(param_1 + 0x12) = *(ushort *)(param_1 + 0x12) & 0xefff;
    }
  }
  if (*(short *)(param_1 + 0x12) == 0) {
    .glue::SetRect(param_2,0,0,0,0);
  }
  else if (*(short *)(param_1 + 0x12) == 0x400) {
    param_2[1] = 0x42;
    *param_2 = 0x12;
    param_2[2] = 0x40;
    param_2[3] = 0xda;
    .glue::InsetRect(param_2,2,2);
  }
  else {
    .debug::_CalcSubRefreshRect__16TInventoryWindowFR4Rect(param_1,param_2);
  }
  return;
}


// ==== .DrawIntoPort__16TCharacterWindowFP8GrafPort @ 1002bf6c ====
// CyDecompAt: created, body 1002bf6c-1002c20b

void _DrawIntoPort__16TCharacterWindowFP8GrafPort(int param_1,int param_2)

{
  undefined4 uVar1;
  short sVar2;
  undefined1 uStack_128;
  undefined1 auStack_127 [255];
  undefined4 uStack_28;
  undefined4 uStack_24;
  undefined4 auStack_20 [5];
  
  .glue::GetPort(auStack_20);
  .glue::SetPort(param_2);
  if (*(short *)(param_1 + 0x12) == 0x400) {
    .debug::_DrawStatPart__16TCharacterWindowFP8GrafPort(param_1,param_2);
    .glue::SetPort(auStack_20[0]);
  }
  else {
    uStack_28 = *(undefined4 *)(param_2 + 0x10);
    uStack_24 = *(undefined4 *)(param_2 + 0x14);
    uVar1 = .debug::_SetTilePat__Fs(0x1a4);
    .glue::FillCRect(&uStack_28,uVar1);
    uStack_28 = CONCAT22(uStack_28._0_2_,0x40);
    .glue::InsetRect(&uStack_28,2,2);
    uStack_28 = CONCAT22(0x12,uStack_28._2_2_);
    uStack_24 = CONCAT22(0x40,uStack_24._2_2_);
    .debug::_Bevel__FRC4Rects(&uStack_28,1);
    if ((*(ushort *)(param_1 + 0x12) & 2) == 0) {
      if ((*(ushort *)(param_1 + 0x12) & 0x100) != 0) {
        .debug::_RecalcWieldList__16TCharacterWindowFv(param_1);
      }
    }
    else {
      .debug::_RecalcInventory__16TCharacterWindowFv(param_1);
      .debug::_RecalcWieldList__16TCharacterWindowFv(param_1);
    }
    if (*(short *)(param_1 + 0x86) != 2) {
      .debug::_DrawInvPart__16TCharacterWindowFP8GrafPort(param_1,param_2);
    }
    if ((*(ushort *)(param_1 + 0x12) & 0x200) != 0) {
      .debug::_RecalcSkills__16TCharacterWindowFv(param_1);
    }
    if (*(short *)(param_1 + 0x86) == 2) {
      .debug::_DrawSkillPart__16TCharacterWindowFP8GrafPort(param_1,param_2);
    }
    if (*(short *)(param_1 + 0x86) == 1) {
      .debug::_DrawWieldPart__16TCharacterWindowFP8GrafPort(param_1,param_2);
    }
    if (((PTR_DAT_100cdbf0[*(short *)(param_1 + 0x1c) * 0x20 + 8] & 0x40) != 0) &&
       (*(short *)(param_1 + 0x86) == 1)) {
      .debug::_DrawWeightPart__16TCharacterWindowFP8GrafPort(param_1,param_2);
    }
    .debug::_DrawStatPart__16TCharacterWindowFP8GrafPort(param_1,param_2);
    if (*(short *)(param_1 + 0x86) == 2) {
      if (*(short *)(param_1 + 0x1c) == *(short *)PTR_DAT_100cdbec) {
        .debug::_DrawStat2Part__16TCharacterWindowFP8GrafPort(param_1,param_2);
      }
    }
    .debug::_DrawTabsPart__16TCharacterWindowFP8GrafPort(param_1,param_2);
    .debug::_DrawPortraitPart__16TCharacterWindowFP8GrafPort(param_1,param_2);
    .debug::_GetCharacterName__FsPcUc((int)*(short *)(param_1 + 0x1c),auStack_127,0);
    uStack_128 = FUN_100b6ce8(auStack_127);
    sVar2 = FUN_100bca34(**(undefined4 **)(*(int *)(param_1 + 4) + 0x86),&uStack_128);
    if (sVar2 != 0) {
      .glue::EndUpdate(*(undefined4 *)(param_1 + 4));
      .glue::SetWTitle(*(undefined4 *)(param_1 + 4),&uStack_128);
      .glue::BeginUpdate(*(undefined4 *)(param_1 + 4));
    }
    .glue::SetPort(auStack_20[0]);
  }
  return;
}


// ==== .CanDrop__16TCharacterWindowFsR5Point @ 1002dcf8 ====
// CyDecompAt: created, body 1002dcf8-1002e6bf

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */
/* WARNING: Restarted to delay deadcode elimination for space: stack */

undefined4 _CanDrop__16TCharacterWindowFsR5Point(int param_1,ushort param_2,undefined4 *param_3)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined *puVar3;
  int iVar4;
  undefined4 uVar5;
  char cVar6;
  uint *puVar7;
  ushort uVar8;
  short sVar9;
  int iStack_c4;
  uint *puStack_c0;
  uint *puStack_bc;
  uint *puStack_b8;
  int iStack_b4;
  uint *puStack_b0;
  uint *puStack_ac;
  uint *puStack_a8;
  uint *puStack_a4;
  uint *puStack_a0;
  undefined *puStack_9c;
  uint uStack_98;
  uint uStack_94;
  uint uStack_90;
  uint uStack_8c;
  uint uStack_88;
  uint uStack_84;
  uint uStack_80;
  uint uStack_7c;
  uint uStack_78;
  uint uStack_74;
  uint uStack_70;
  uint uStack_6c;
  short sStack_68;
  short sStack_66;
  short sStack_64;
  short sStack_62;
  undefined2 uStack_60;
  undefined2 uStack_5e;
  undefined2 uStack_5c;
  undefined2 uStack_5a;
  undefined4 uStack_58;
  undefined2 uStack_54;
  short sStack_52;
  uint uStack_50;
  undefined2 uStack_4c;
  undefined2 uStack_4a;
  
  puVar3 = PTR_s__Wield__100ce5c8;
  puVar2 = PTR_s__Wear__100ce5c4;
  puVar1 = PTR_DAT_100cdb98;
  puStack_9c = PTR_DAT_100cdbf0 + *(short *)(param_1 + 0x1c) * 0x20;
  if ((puStack_9c[8] & 0x40) == 0) {
    .debug::_AutoEye__13TStatusWindowFPc
              (*(undefined4 *)PTR_DAT_100cdb98,PTR_s__Not_your_stuff__100c6067_0x10_100ce5d8);
    uVar5 = 0;
  }
  else if (*(short *)(param_1 + 0x86) == 0) {
    uStack_50 = *(uint *)(param_1 + 0x24) & 0xffff0000;
    _uStack_4c = CONCAT22((short)((uint)*(undefined4 *)(param_1 + 0x28) >> 0x10),0xcc);
    cVar6 = .glue::PtInRect(*param_3,&uStack_50);
    if (cVar6 == '\0') {
      .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Can_t_drop_there__100ce5cc);
      uVar5 = 0;
    }
    else if ((*(char *)(*(int *)PTR_DAT_100cdc44 + (short)param_2 * 0x10) == '\x10') &&
            (puStack_a0 = (uint *)(*(int *)PTR_DAT_100cdc44 + (short)param_2 * 0x10),
            (int)*(short *)(param_1 + 0x1c) == (*puStack_a0 & 0xffff))) {
      .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Abort__100ce5d4);
      uVar5 = 0;
    }
    else {
      .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Take__100ce5d0);
      uVar5 = 1;
    }
  }
  else {
    if (*(short *)(param_1 + 0x86) == 1) {
      uStack_58 = *(undefined4 *)(param_1 + 0x24);
      sStack_52 = (short)*(undefined4 *)(param_1 + 0x28);
      _uStack_54 = CONCAT22((short)((uint)*(undefined4 *)(param_1 + 0x28) >> 0x10),sStack_52 + -0x10
                           );
      cVar6 = .glue::PtInRect(*param_3,&uStack_58);
      if (cVar6 != '\0') {
        if ((*(char *)(*(int *)PTR_DAT_100cdc44 + (short)param_2 * 0x10) == '\x10') &&
           (puStack_a4 = (uint *)(*(int *)PTR_DAT_100cdc44 + (short)param_2 * 0x10),
           (int)*(short *)(param_1 + 0x1c) == (*puStack_a4 & 0xffff))) {
          .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Abort__100ce5d4);
          return 0;
        }
        .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Take__100ce5d0);
        return 1;
      }
    }
    if (*(short *)(param_1 + 0x86) == 1) {
      if ((*(char *)(*(int *)PTR_DAT_100cdc44 + (short)param_2 * 0x10) == '\x18') &&
         (puStack_a8 = (uint *)(*(int *)PTR_DAT_100cdc44 + (short)param_2 * 0x10),
         (int)*(short *)(param_1 + 0x1c) == (*puStack_a8 & 0xffff))) {
        .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Abort__100ce5d4);
        return 0;
      }
      for (sVar9 = 0; sVar9 < 10; sVar9 = sVar9 + 1) {
        cVar6 = .glue::PtInRect(*param_3,_DAT_100cddc4 + sVar9 * 8);
        if (cVar6 != '\0') {
          if (*(short *)(param_1 + sVar9 * 2 + 0x2c) != 0) {
            .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Occupied__100ce59c);
            return 0;
          }
          uStack_70 = param_2 | 0x40000000;
          .debug::_GetProperty__7TInterpFs5VAddrs(&uStack_6c,0x26,uStack_70,0);
          switch((int)(uStack_6c << 4 | uStack_6c >> 0x1c) >> 4) {
          case 0:
            if (sVar9 == 0) {
              .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,puVar2);
              return 1;
            }
            break;
          case 1:
            if (sVar9 == 1) {
              .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,puVar2);
              return 1;
            }
            break;
          case 2:
            if (sVar9 == 2) {
              .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,puVar2);
              return 1;
            }
            break;
          case 3:
          case 4:
            if ((sVar9 == 6) || (sVar9 == 7)) {
              .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,puVar3);
              return 1;
            }
            break;
          case 5:
            if ((((sVar9 == 6) || (sVar9 == 7)) && (*(short *)(param_1 + 0x38) == 0)) &&
               (*(short *)(param_1 + 0x3a) == 0)) {
              .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,puVar3);
              return 1;
            }
            break;
          case 6:
            if ((sVar9 == 8) || (sVar9 == 9)) {
              .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,puVar2);
              return 1;
            }
            break;
          case 7:
            if (sVar9 == 3) {
              .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,puVar2);
              return 1;
            }
            break;
          case 8:
            if (sVar9 == 4) {
              .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,puVar2);
              return 1;
            }
            break;
          case 9:
            if (sVar9 == 5) {
              .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,puVar2);
              return 1;
            }
          }
          switch(sVar9) {
          case 0:
            .debug::_AutoEye__13TStatusWindowFPc
                      (*(undefined4 *)puVar1,PTR_s__Not_worn_on_head__100ce5b0);
            break;
          case 1:
            .debug::_AutoEye__13TStatusWindowFPc
                      (*(undefined4 *)puVar1,PTR_s__Not_worn_on_neck__100ce5ac);
            break;
          case 2:
            .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Not_armor__100ce5b4);
            break;
          case 3:
            .debug::_AutoEye__13TStatusWindowFPc
                      (*(undefined4 *)puVar1,PTR_s__Not_worn_on_waist__100ce5a0);
            break;
          case 4:
            .debug::_AutoEye__13TStatusWindowFPc
                      (*(undefined4 *)puVar1,PTR_s__Not_footgear__100ce5a4);
            break;
          case 5:
            .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Not_a_cloak__100ce5a8)
            ;
            break;
          case 6:
          case 7:
            puStack_ac = &uStack_78;
            uStack_78 = param_2 | 0x40000000;
            .debug::_GetProperty__7TInterpFs5VAddrs(&uStack_74,0x26,uStack_78,0);
            puStack_b0 = &uStack_74;
            if ((int)(uStack_74 << 4 | uStack_74 >> 0x1c) >> 4 == 5) {
              .debug::_AutoEye__13TStatusWindowFPc
                        (*(undefined4 *)puVar1,PTR_s__Needs_both_hands__100ce5c0);
            }
            else {
              .debug::_AutoEye__13TStatusWindowFPc
                        (*(undefined4 *)puVar1,PTR_s__Not_weildable__100ce5bc);
            }
            break;
          case 8:
          case 9:
            .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Not_a_ring__100ce5b8);
          }
          return 0;
        }
      }
      uStack_5e = *(undefined2 *)(_DAT_100cddc4 + 0x36);
      uStack_5a = *(undefined2 *)(_DAT_100cddc4 + 0x3a);
      uStack_60 = *(undefined2 *)(_DAT_100cddc4 + 4);
      uStack_5c = *(undefined2 *)(_DAT_100cddc4 + 0x20);
      cVar6 = .glue::PtInRect(*param_3,&uStack_60);
      if (cVar6 != '\0') {
        puStack_b8 = &uStack_7c;
        uStack_7c = param_2 | 0x40000000;
        sStack_62 = 0;
        sStack_64 = 0;
        sVar9 = 0;
        sStack_66 = 0;
        sStack_68 = 0xffff;
        .debug::_HasProperty__7TInterpFs5VAddr(&iStack_b4,0x26,uStack_7c);
        if (iStack_b4 == *(int *)PTR_DAT_100cdbb0) {
          .debug::_AutoEye__13TStatusWindowFPc
                    (*(undefined4 *)puVar1,PTR_s__Can_t_Wear_Wield__100ce598);
          return 0;
        }
        puStack_bc = &uStack_84;
        uStack_84 = param_2 | 0x40000000;
        .debug::_GetProperty__7TInterpFs5VAddrs(&uStack_80,0x26,uStack_84,0);
        puStack_c0 = &uStack_80;
        sStack_68 = (short)((int)(uStack_80 << 4 | uStack_80 >> 0x1c) >> 4);
        if (sStack_68 == 5) {
          sStack_62 = 2;
        }
        else if (sStack_68 < 5) {
          if (sStack_68 == 3) {
            sStack_62 = 1;
          }
          else if (2 < sStack_68) {
            sStack_62 = 1;
          }
        }
        else if (sStack_68 < 7) {
          sStack_66 = 1;
        }
        uVar8 = 0;
        puVar7 = *(uint **)PTR_DAT_100cdc44;
        do {
          if (*(short *)PTR_DAT_100cdc3c <= (short)uVar8) {
            if (2 < (int)sVar9 + (int)sStack_62) {
              .debug::_AutoEye__13TStatusWindowFPc
                        (*(undefined4 *)puVar1,PTR_s__Needs_both_hands__100ce5c0);
              return 0;
            }
            if ((int)sStack_64 + (int)sStack_66 < 3) {
              if ((sStack_68 < 6) && (2 < sStack_68)) {
                .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,puVar3);
              }
              else {
                .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,puVar2);
              }
              return 1;
            }
            .debug::_AutoEye__13TStatusWindowFPc
                      (*(undefined4 *)puVar1,PTR_s__Needs_both_hands__100ce5c0);
            return 0;
          }
          if ((*(char *)puVar7 == '\x18') && ((int)*(short *)(param_1 + 0x1c) == (*puVar7 & 0xffff))
             ) {
            uStack_88 = uVar8 | 0x40000000;
            .debug::_HasProperty__7TInterpFs5VAddr(&iStack_c4,0x26,uStack_88);
            if (iStack_c4 != *(int *)PTR_DAT_100cdbb0) {
              uStack_90 = uVar8 | 0x40000000;
              .debug::_GetProperty__7TInterpFs5VAddrs(&uStack_8c,0x26,uStack_90,0);
              iVar4 = (int)(uStack_8c << 4 | uStack_8c >> 0x1c) >> 4;
              if (iVar4 == 5) {
                sVar9 = sVar9 + 2;
              }
              else if (iVar4 < 5) {
                if (iVar4 == 3) {
                  sVar9 = sVar9 + 1;
                }
                else {
                  if (iVar4 < 3) goto LAB_1002e558;
                  sVar9 = sVar9 + 1;
                }
              }
              else if (iVar4 < 7) {
                sStack_64 = sStack_64 + 1;
              }
              else {
LAB_1002e558:
                uStack_98 = uVar8 | 0x40000000;
                .debug::_GetProperty__7TInterpFs5VAddrs(&uStack_94,0x26,uStack_98,0);
                if ((int)sStack_68 == (int)(uStack_94 << 4 | uStack_94 >> 0x1c) >> 4) {
                  .debug::_AutoEye__13TStatusWindowFPc
                            (*(undefined4 *)puVar1,PTR_s__Occupied__100ce59c);
                  return 0;
                }
              }
            }
          }
          puVar7 = puVar7 + 4;
          uVar8 = uVar8 + 1;
        } while( true );
      }
    }
    .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Can_t_drop_there__100ce5cc);
    uVar5 = 0;
  }
  return uVar5;
}


// ==== .DoDrop__16TCharacterWindowFs5Point @ 1002e6f8 ====
// CyDecompAt: created, body 1002e6f8-1002e7af

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DoDrop__16TCharacterWindowFs5Point(int param_1,undefined4 param_2,undefined4 param_3)

{
  char cVar1;
  undefined4 uStack_18;
  undefined2 uStack_14;
  short sStack_12;
  
  if (*(short *)(param_1 + 0x86) != 2) {
    uStack_18 = *(undefined4 *)(param_1 + 0x24);
    sStack_12 = (short)*(undefined4 *)(param_1 + 0x28);
    _uStack_14 = CONCAT22((short)((uint)*(undefined4 *)(param_1 + 0x28) >> 0x10),sStack_12 + -0x10);
    cVar1 = .glue::PtInRect(param_3,&uStack_18);
    if (cVar1 != '\0') {
      .debug::_TakeCommand__8TGameSysFss(*_DAT_100cdcd0,param_2,(int)*(short *)(param_1 + 0x1c));
      return;
    }
  }
  if (*(short *)(param_1 + 0x86) == 1) {
    .debug::_WieldCommand__8TGameSysFss(*_DAT_100cdcd0,param_2,(int)*(short *)(param_1 + 0x1c));
  }
  return;
}


// ==== .PointToProp__16TCharacterWindowF5Point @ 1002e7e8 ====
// CyDecompAt: created, body 1002e7e8-1002e917

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

int _PointToProp__16TCharacterWindowF5Point(int param_1,undefined4 param_2)

{
  int iVar1;
  char cVar2;
  short sVar3;
  undefined4 uStack_18;
  undefined2 uStack_14;
  short sStack_12;
  
  iVar1 = _DAT_100cddc4;
  if (*(short *)(param_1 + 0x86) == 2) {
    iVar1 = 0;
  }
  else {
    uStack_18 = *(undefined4 *)(param_1 + 0x24);
    sStack_12 = (short)*(undefined4 *)(param_1 + 0x28);
    _uStack_14 = CONCAT22((short)((uint)*(undefined4 *)(param_1 + 0x28) >> 0x10),sStack_12 + -0x10);
    cVar2 = .glue::PtInRect(param_2,&uStack_18);
    if (cVar2 == '\0') {
      if (*(short *)(param_1 + 0x86) == 1) {
        for (sVar3 = 0; sVar3 < 10; sVar3 = sVar3 + 1) {
          cVar2 = .glue::PtInRect(param_2,iVar1 + sVar3 * 8);
          if ((cVar2 != '\0') && (0 < *(short *)(param_1 + sVar3 * 2 + 0x2c))) {
            return (int)*(short *)(param_1 + sVar3 * 2 + 0x2c);
          }
        }
      }
      iVar1 = 0;
    }
    else {
      iVar1 = .debug::_LocToProp__14TInventoryListF5PointUc
                        (*(undefined4 *)(param_1 + 0x20),param_2,0);
      if ((short)iVar1 < 0) {
        iVar1 = 0;
      }
    }
  }
  return iVar1;
}


// ==== .PropToPoint__16TCharacterWindowFsP5Point @ 1002e954 ====
// CyDecompAt: created, body 1002e954-1002eae3

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 _PropToPoint__16TCharacterWindowFsP5Point(int param_1,undefined4 param_2,short *param_3)

{
  int iVar1;
  undefined4 uVar2;
  uint uVar3;
  char cVar4;
  short sVar5;
  undefined4 uStack_38;
  undefined4 auStack_34 [4];
  
  iVar1 = _DAT_100cddc4;
  if (*(short *)(param_1 + 0x86) == 2) {
    uVar2 = 0;
  }
  else {
    if (*(short *)(param_1 + 0x86) == 1) {
      for (sVar5 = 0; sVar5 < 10; sVar5 = sVar5 + 1) {
        if (*(short *)(param_1 + sVar5 * 2 + 0x2c) == (short)param_2) {
          uVar3 = (int)*(short *)(_DAT_100cddc4 + sVar5 * 8 + 2) +
                  (int)*(short *)(_DAT_100cddc4 + sVar5 * 8 + 6);
          param_3[1] = (short)((int)uVar3 >> 1) + (ushort)((int)uVar3 < 0 && (uVar3 & 1) != 0);
          uVar3 = (int)*(short *)(iVar1 + sVar5 * 8) + (int)*(short *)(iVar1 + sVar5 * 8 + 4);
          *param_3 = (short)((int)uVar3 >> 1) + (ushort)((int)uVar3 < 0 && (uVar3 & 1) != 0);
          uVar2 = *(undefined4 *)(param_1 + 4);
          .glue::GetPort(auStack_34);
          .glue::SetPort(uVar2);
          .glue::LocalToGlobal(param_3);
          .glue::SetPort(auStack_34[0]);
          return 1;
        }
      }
    }
    cVar4 = .debug::_PropToLoc__14TInventoryListFsP5Point
                      (*(undefined4 *)(param_1 + 0x20),param_2,param_3);
    if (cVar4 == '\0') {
      uVar2 = 0;
    }
    else {
      uVar2 = *(undefined4 *)(param_1 + 4);
      .glue::GetPort(&uStack_38);
      .glue::SetPort(uVar2);
      .glue::LocalToGlobal(param_3);
      .glue::SetPort(uStack_38);
      uVar2 = 1;
    }
  }
  return uVar2;
}


// ==== .CanSearch__16TCharacterWindowF5Point @ 1002eb20 ====
// CyDecompAt: created, body 1002eb20-1002eb27

undefined4 _CanSearch__16TCharacterWindowF5Point(void)

{
  return 1;
}


// ==== .Size__8TListBoxFll @ 1002f094 ====
// CyDecompAt: created, body 1002f094-1002f0db

void _Size__8TListBoxFll(int param_1,short param_2,short param_3)

{
  .glue::LSize((int)param_2,(int)param_3,*(undefined4 *)(param_1 + 4));
  return;
}


// ==== .MouseRoutine__16TCharacterWindowF5Points @ 1002f104 ====
// CyDecompAt: created, body 1002f104-1002f917

void _MouseRoutine__16TCharacterWindowF5Points(int param_1,undefined4 param_2,short param_3)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  int iVar6;
  short sVar8;
  undefined1 uVar10;
  short sVar9;
  uint uVar7;
  char cVar11;
  int iStack_90;
  int iStack_8c;
  undefined4 uStack_88;
  undefined1 auStack_84 [4];
  undefined4 uStack_80;
  undefined4 uStack_7c;
  undefined2 uStack_78;
  short sStack_76;
  undefined4 uStack_74;
  int iStack_70;
  undefined2 uStack_6c;
  short sStack_6a;
  char cStack_68;
  int iStack_66;
  undefined2 uStack_62;
  undefined2 uStack_60;
  int iStack_5e;
  undefined2 uStack_5a;
  short sStack_58;
  int iStack_56;
  undefined2 uStack_52;
  short sStack_50;
  short sStack_4e;
  int iStack_4c;
  short sStack_48;
  
  puVar5 = PTR_DAT_100cdbf0;
  puVar4 = PTR_DAT_100cdbe4;
  puVar3 = PTR_DAT_100cdbb0;
  puVar2 = PTR_DAT_100cdb9c;
  puVar1 = PTR_DAT_100cdb94;
  .glue::SetPort(*(undefined4 *)(param_1 + 4));
  if ((short)((uint)param_2 >> 0x10) < 0x111) {
    iStack_4c = 0;
    .glue::FindControl(param_2,*(undefined4 *)(param_1 + 4),&iStack_4c);
    if (*(short *)(param_1 + 0x86) == 2) {
      FUN_100c50e8(param_1,param_2);
      sVar9 = 0;
      while( true ) {
        if (7 < sVar9) break;
        if (iStack_4c == *(int *)(param_1 + sVar9 * 4 + 0x40)) {
          .debug::_SetTilePat__Fs(0x1a4);
          .glue::BackPixPat();
          sVar8 = .glue::TrackControl(iStack_4c,param_2,0);
          if (sVar8 == 0) {
            .glue::BackPat(puVar1 + 0xc2);
            return;
          }
          uVar7 = .glue::GetControlReference(iStack_4c);
          if ((byte)puVar5[*(short *)(param_1 + 0x1c) * 0x20 + 0x1e] != uVar7) {
            for (sVar8 = 0; sVar8 < 8; sVar8 = sVar8 + 1) {
              uVar7 = .glue::GetControlReference(*(undefined4 *)(param_1 + sVar8 * 4 + 0x40));
              if ((byte)puVar5[*(short *)(param_1 + 0x1c) * 0x20 + 0x1e] == uVar7) {
                .glue::SetControlValue(*(undefined4 *)(param_1 + sVar8 * 4 + 0x40),0);
              }
            }
            .glue::SetControlValue(iStack_4c,1);
            uVar10 = .glue::GetControlReference(iStack_4c);
            puVar5[*(short *)(param_1 + 0x1c) * 0x20 + 0x1e] = uVar10;
            FUN_100c50e8(param_1,0x4000);
          }
          .glue::BackPat(puVar1 + 0xc2);
        }
        sVar9 = sVar9 + 1;
      }
      if (iStack_4c == *(int *)(param_1 + 0x60)) {
        sStack_4e = .glue::GetControlValue(*(undefined4 *)(param_1 + 0x60));
        .debug::_SetTilePat__Fs(0x1a4);
        .glue::BackPixPat();
        .glue::TrackControl(*(undefined4 *)(param_1 + 0x60),param_2,0xffffffff);
        sVar9 = .glue::GetControlValue(*(undefined4 *)(param_1 + 0x60));
        if (sVar9 == 1) {
          .debug::_EditUserBehaviors__Fv();
          .glue::SetControlValue(*(undefined4 *)(param_1 + 0x60),(int)sStack_4e);
          for (sVar9 = 0; sVar9 < *(short *)puVar2; sVar9 = sVar9 + 1) {
            .debug::_Invalidate__16TInventoryWindowFss((int)*(short *)(puVar4 + sVar9 * 2),0x1000);
          }
        }
        else {
          .glue::SetControlReference(*(undefined4 *)(param_1 + 0x5c),sVar9 + 0xad);
          for (sVar8 = 0; sVar8 < 8; sVar8 = sVar8 + 1) {
            uVar7 = .glue::GetControlReference(*(undefined4 *)(param_1 + sVar8 * 4 + 0x40));
            if ((byte)puVar5[*(short *)(param_1 + 0x1c) * 0x20 + 0x1e] == uVar7) {
              .glue::SetControlValue(*(undefined4 *)(param_1 + sVar8 * 4 + 0x40),0);
            }
          }
          puVar5[*(short *)(param_1 + 0x1c) * 0x20 + 0x1e] = (char)sVar9 + -0x53;
          .glue::SetControlValue(*(undefined4 *)(param_1 + 0x5c),1);
          FUN_100c50e8(param_1,0x4000);
        }
        .glue::BackPat(puVar1 + 0xc2);
      }
      else if (iStack_4c == *(int *)(param_1 + 100)) {
        sVar9 = .glue::TrackControl(*(undefined4 *)(param_1 + 100),param_2,0);
        if (sVar9 != 0) {
          uStack_52 = 2;
          iStack_56 = (uint)iStack_56._0_2_ << 0x10;
          sVar9 = FUN_100c50e8();
          iStack_56 = CONCAT22(sVar9,iStack_56._2_2_);
          if (-1 < sVar9) {
            .glue::LGetCell(&sStack_50,&uStack_52,iStack_56,
                            *(undefined4 *)(*(int *)(param_1 + 0x70) + 4));
            .debug::___ct__5VAddrFcUsUs(&uStack_7c,4,0x50,sStack_50);
            .debug::_HasProperty__7TInterpFs5VAddr(&iStack_8c,9,uStack_7c);
            if ((iStack_8c != *(int *)puVar3) &&
               (cVar11 = .debug::_DefineFKey__13TStatusWindowFs
                                   (*(undefined4 *)PTR_DAT_100cdb98,(int)sStack_50), cVar11 != '\0')
               ) {
              FUN_100c50e8(*(undefined4 *)(param_1 + 0x70),
                           *(undefined4 *)(*(int *)(param_1 + 4) + 0x18));
            }
          }
        }
      }
      else if (iStack_4c == *(int *)(param_1 + 0x6c)) {
        sVar9 = .glue::TrackControl(*(undefined4 *)(param_1 + 0x6c),param_2,0);
        if (sVar9 != 0) {
          uStack_5a = 2;
          iStack_5e = (uint)iStack_5e._0_2_ << 0x10;
          sVar9 = FUN_100c50e8();
          iStack_5e = CONCAT22(sVar9,iStack_5e._2_2_);
          if (-1 < sVar9) {
            .glue::LGetCell(&sStack_58,&uStack_5a,iStack_5e,
                            *(undefined4 *)(*(int *)(param_1 + 0x70) + 4));
            .debug::___ct__5VAddrFcUsUs(&uStack_80,4,0x50,sStack_58);
            .debug::_HasProperty__7TInterpFs5VAddr(&iStack_90,9,uStack_80);
            if (iStack_90 != *(int *)puVar3) {
              .debug::_ScheduleSkill__11TTaskMasterFss
                        (*(ushort *)(*(int *)PTR_DAT_100cdc44 + sStack_58 * 0x10 + 4) & 0x3ff,
                         (int)*(short *)(param_1 + 0x1c));
            }
          }
        }
      }
      else if (iStack_4c == *(int *)(param_1 + 0x68)) {
        sVar9 = .glue::TrackControl(*(undefined4 *)(param_1 + 0x68),param_2,0);
        if (sVar9 != 0) {
          uStack_62 = 2;
          iStack_66 = (uint)iStack_66._0_2_ << 0x10;
          sVar9 = FUN_100c50e8();
          iStack_66 = CONCAT22(sVar9,iStack_66._2_2_);
          if (-1 < sVar9) {
            .glue::LGetCell(&uStack_60,&uStack_62,iStack_66,
                            *(undefined4 *)(*(int *)(param_1 + 0x70) + 4));
            .debug::___ct__5VAddrFcUsUs(&uStack_88,4,0x50,uStack_60);
            .debug::_DoInterp__7TInterpFs5VAddr(auStack_84,8,uStack_88);
          }
        }
      }
      else {
        cVar11 = .glue::PtInRect(param_2,param_1 + 0x74);
        if (cVar11 != '\0') {
          cStack_68 = FUN_100c50e8(*(undefined4 *)(param_1 + 0x70),param_2,(int)param_3);
          FUN_100c50e8(param_1,0x4000);
          if (*(short *)(param_1 + 0x1c) == *(short *)PTR_DAT_100cdbec) {
            uStack_6c = 2;
            iStack_70 = (uint)iStack_70._0_2_ << 0x10;
            sVar9 = FUN_100c50e8();
            iStack_70 = CONCAT22(sVar9,iStack_70._2_2_);
            if (-1 < sVar9) {
              .glue::LGetCell(&sStack_6a,&uStack_6c,iStack_70,
                              *(undefined4 *)(*(int *)(param_1 + 0x70) + 4));
              if (cStack_68 != '\0') {
                .debug::_ScheduleSkill__11TTaskMasterFss
                          (*(ushort *)(*(int *)PTR_DAT_100cdc44 + sStack_6a * 0x10 + 4) & 0x3ff,
                           (int)*(short *)(param_1 + 0x1c));
              }
              .debug::_AdjustSkillControls__16TCharacterWindowFv(param_1);
            }
          }
        }
      }
    }
    else if (iStack_4c == 0) {
      .debug::_MouseRoutine__16TDroppableWindowF5Points(param_1,param_2,(int)param_3);
    }
    else {
      FUN_100c50e8(param_1,param_2);
      FUN_100c50e8(param_1,0x4000);
      uStack_74 = *(undefined4 *)(param_1 + 0x28);
      _uStack_78 = CONCAT22((short)((uint)*(undefined4 *)(param_1 + 0x24) >> 0x10),
                            uStack_74._2_2_ + -0x10);
      cVar11 = .glue::PtInRect(param_2,&uStack_78);
      if (cVar11 != '\0') {
        FUN_100c50e8(*(undefined4 *)(param_1 + 0x20),param_2,(int)param_3);
      }
    }
  }
  else {
    FUN_100c50e8(param_1,param_2);
    iVar6 = (int)(short)param_2 / 0x49 + ((int)(short)param_2 >> 0x1f);
    sStack_48 = (short)iVar6 - (short)(iVar6 >> 0x1f);
    .debug::_ChangePane__16TCharacterWindowFs(param_1,(int)sStack_48);
  }
  return;
}


// ==== .Update__8TListBoxFPP9MacRegion @ 1002f954 ====
// CyDecompAt: created, body 1002f954-1002f98b

void _Update__8TListBoxFPP9MacRegion(int param_1,undefined4 param_2)

{
  .glue::LUpdate(param_2,*(undefined4 *)(param_1 + 4));
  return;
}


// ==== .IsReadOnly__16TCharacterWindowFv @ 1002f9c0 ====
// CyDecompAt: created, body 1002f9c0-1002fa17

undefined4 _IsReadOnly__16TCharacterWindowFv(int param_1)

{
  undefined4 uVar1;
  
  if (((PTR_DAT_100cdbf0[*(short *)(param_1 + 0x1c) * 0x20 + 8] & 0x40) == 0) &&
     ((*(ushort *)(PTR_DAT_100cdbf0 + *(short *)(param_1 + 0x1c) * 0x20 + 6) & 1) != 0)) {
    uVar1 = 1;
  }
  else {
    uVar1 = 0;
  }
  return uVar1;
}


// ==== .RenumberChild__16TCharacterWindowFss @ 1002fa4c ====
// CyDecompAt: created, body 1002fa4c-1002fb1f

void _RenumberChild__16TCharacterWindowFss(int param_1,undefined4 param_2,undefined4 param_3)

{
  short sVar1;
  
  if (*(char *)(*(int *)PTR_DAT_100cdc44 + (short)param_2 * 0x10) == '\x1c') {
    .debug::_RenumberChild__12TAbilityListFss(*(undefined4 *)(param_1 + 0x70),param_2,param_3);
  }
  else {
    .debug::_RenumberChild__14TInventoryListFss(*(undefined4 *)(param_1 + 0x20),param_2,param_3);
    for (sVar1 = 0; sVar1 < 10; sVar1 = sVar1 + 1) {
      if (*(short *)(param_1 + sVar1 * 2 + 0x2c) == (short)param_2) {
        *(short *)(param_1 + sVar1 * 2 + 0x2c) = (short)param_3;
      }
    }
  }
  return;
}


// ==== .__dt__11TSaveGWorldFv @ 10030698 ====
// CyDecompAt: created, body 10030698-100306f3

int ___dt__11TSaveGWorldFv(int param_1,short param_2)

{
  if (param_1 != 0) {
    .glue::SetGWorld(*(undefined4 *)(param_1 + 4),*(undefined4 *)(param_1 + 8));
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .Marshal__16TCharacterWindowFP7TStream @ 100309c4 ====
// CyDecompAt: created, body 100309c4-10030a97

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Marshal__16TCharacterWindowFP7TStream(int param_1,undefined4 param_2)

{
  undefined4 uVar1;
  undefined4 uStack_18;
  undefined4 auStack_14 [2];
  
  FUN_100c50e8(param_2,PTR_DAT_100ce55c,0x43687257);
  .debug::_Marshal__16TInventoryWindowFP7TStream(param_1,param_2);
  uVar1 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_14);
  .glue::SetPort(uVar1);
  uStack_18 = _DAT_100d4794;
  .glue::LocalToGlobal(&uStack_18);
  FUN_100c50e8(param_2,_DAT_100ce560,(int)uStack_18._2_2_,(int)uStack_18._0_2_,
               (int)*(short *)(param_1 + 0x86));
  .glue::SetPort(auStack_14[0]);
  return;
}


// ==== .__dt__16TCharacterWindowFv @ 10030ad0 ====
// CyDecompAt: created, body 10030ad0-10030b33

undefined4 * ___dt__16TCharacterWindowFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d47f4;
    .debug::___dt__16TInventoryWindowFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .GetCount__8TListBoxFv @ 10030b64 ====
// CyDecompAt: created, body 10030b64-10030b73

int _GetCount__8TListBoxFv(int param_1)

{
  return (int)*(short *)(**(int **)(param_1 + 4) + 0x4c);
}


// ==== .GetData__8TListBoxFv @ 10030b9c ====
// CyDecompAt: created, body 10030b9c-10030bab

undefined4 _GetData__8TListBoxFv(int param_1)

{
  return *(undefined4 *)(**(int **)(param_1 + 4) + 0x50);
}


// ==== .RenumberChild__16TInventoryWindowFss @ 100314ec ====
// CyDecompAt: created, body 100314ec-100314ef

void _RenumberChild__16TInventoryWindowFss(void)

{
  return;
}


// ==== .Invalidate__16TInventoryWindowFs @ 10031bb4 ====
// CyDecompAt: created, body 10031bb4-10031c5b

void _Invalidate__16TInventoryWindowFs(int param_1,ushort param_2)

{
  undefined4 uVar1;
  undefined4 auStack_18 [4];
  
  *(ushort *)(param_1 + 0x12) = *(ushort *)(param_1 + 0x12) | param_2;
  uVar1 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_18);
  .glue::SetPort(uVar1);
  if (((int)*(short *)(param_1 + 0x12) & 0x8000U) == 0) {
    .glue::InvalRect(*(int *)(param_1 + 4) + 0x10);
  }
  else {
    FUN_100c50e8(param_1);
    *(undefined2 *)(param_1 + 0x12) = 0;
  }
  .glue::SetPort(auStack_18[0]);
  return;
}


// ==== .NeedsRedraw__16TInventoryWindowFv @ 10031c90 ====
// CyDecompAt: created, body 10031c90-10031cd7

undefined4 _NeedsRedraw__16TInventoryWindowFv(int param_1)

{
  undefined4 uVar1;
  
  if (*(short *)(param_1 + 0x12) == 0) {
    uVar1 = .debug::_NeedsRedraw__7TWindowFv(param_1);
  }
  else {
    uVar1 = 1;
  }
  return uVar1;
}


// ==== .DrawRoutine__16TInventoryWindowFv @ 1003254c ====
// CyDecompAt: created, body 1003254c-100326d7

void _DrawRoutine__16TInventoryWindowFv(int param_1)

{
  char cVar1;
  undefined4 uVar2;
  undefined4 uStack_28;
  undefined4 uStack_24;
  undefined1 auStack_20 [8];
  undefined4 uStack_18;
  undefined4 uStack_14;
  undefined4 auStack_10 [2];
  
  uVar2 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_10);
  .glue::SetPort(uVar2);
  *(ushort *)(param_1 + 0x12) = *(ushort *)(param_1 + 0x12) & 0x7fff;
  if (*(short *)(param_1 + 0x12) == 0x4000) {
    uStack_18 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x10);
    uStack_14 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x14);
    cVar1 = .debug::_CanUseBackingStore__16TInventoryWindowFv(param_1);
    if (cVar1 != '\0') {
      .debug::_DrawToBackingStore__16TInventoryWindowFR4Rect(param_1,&uStack_18);
    }
  }
  else if (*(short *)(param_1 + 0x12) == 0) {
    uStack_28 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x10);
    uStack_24 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x14);
    cVar1 = .debug::_IsBackingStoreValid__16TInventoryWindowFv(param_1);
    if (cVar1 == '\0') {
      cVar1 = .debug::_CanUseBackingStore__16TInventoryWindowFv(param_1);
      if (cVar1 == '\0') {
        .debug::_DrawViaBuffer__16TInventoryWindowFR4Rect(param_1,&uStack_28);
      }
      else {
        .debug::_DrawToBackingStore__16TInventoryWindowFR4Rect(param_1,&uStack_28);
        .debug::_RefreshViaBackingStore__16TInventoryWindowFR4Rect(param_1,&uStack_28);
      }
    }
    else {
      .debug::_RefreshViaBackingStore__16TInventoryWindowFR4Rect(param_1,&uStack_28);
    }
  }
  else {
    FUN_100c50e8(param_1,auStack_20);
    cVar1 = .glue::EmptyRect(auStack_20);
    if (cVar1 == '\0') {
      cVar1 = .debug::_CanUseBackingStore__16TInventoryWindowFv(param_1);
      if (cVar1 == '\0') {
        .debug::_DrawViaBuffer__16TInventoryWindowFR4Rect(param_1,auStack_20);
      }
      else {
        .debug::_DrawToBackingStore__16TInventoryWindowFR4Rect(param_1,auStack_20);
        .debug::_RefreshViaBackingStore__16TInventoryWindowFR4Rect(param_1,auStack_20);
      }
    }
  }
  *(undefined2 *)(param_1 + 0x12) = 0;
  .glue::SetPort(auStack_10[0]);
  return;
}


// ==== .CloseAtDistance__16TInventoryWindowFss @ 100327d8 ====
// CyDecompAt: created, body 100327d8-10032927

void _CloseAtDistance__16TInventoryWindowFss(int param_1,short param_2,short param_3)

{
  short sVar1;
  ushort uVar2;
  ushort uVar3;
  uint uVar4;
  undefined4 *puVar5;
  
  uVar3 = 0;
  uVar2 = 0;
  puVar5 = (undefined4 *)(*(int *)PTR_DAT_100cdc44 + *(short *)(param_1 + 0x10) * 0x10);
  uVar4 = *(uint *)(PTR_DAT_100cdc14 +
                   (short)((*(byte *)(puVar5 + 1) >> 2 & 0x1f) +
                          *(short *)(PTR_DAT_100cdbf4 + (*(ushort *)(puVar5 + 1) & 0x3ff) * 2)) * 4)
  ;
  sVar1 = (short)((uint)*puVar5 >> 8) >> 4;
  if (*(char *)(puVar5 + 1) < '\0') {
    uVar3 = (ushort)((uVar4 & 0x40) != 0);
    if ((uVar4 & 0x80) != 0) {
      uVar2 = 1;
    }
  }
  else {
    uVar2 = (ushort)((uVar4 & 0x40) != 0);
    if ((uVar4 & 0x80) != 0) {
      uVar3 = 1;
    }
  }
  if (((((int)sVar1 < param_2 + -1) || (param_2 + 1 < (int)sVar1 - (int)(short)uVar3)) ||
      (sVar1 = (short)((ushort)((uint)((int)*(short *)((int)puVar5 + 2) << 0x14) >> 0x10) |
                      (ushort)(*(short *)((int)puVar5 + 2) >> 0xf) >> 0xc) >> 4,
      (int)sVar1 < param_3 + -1)) || (param_3 + 1 < (int)sVar1 - (int)(short)uVar2)) {
    FUN_100c50e8(param_1);
  }
  return;
}


// ==== .HandleMonitorChanged__13TStatusWindowFPP7GDeviceR4RectR4Rect @ 100339ac ====
// CyDecompAt: created, body 100339ac-10033a17

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleMonitorChanged__13TStatusWindowFPP7GDeviceR4RectR4Rect
               (undefined4 param_1,int param_2,undefined4 param_3,undefined4 param_4)

{
  if (param_2 == *_DAT_100cdd40) {
    .debug::_HandleMonitorChanged__7TWindowFPP7GDeviceR4RectR4Rect(param_1,param_2,param_3,param_4);
    .debug::_LayoutObjects__13TStatusWindowFv(param_1);
  }
  return;
}


// ==== .GetOwningGD__13TStatusWindowFPP7GDeviceR4Rect @ 10033a68 ====
// CyDecompAt: created, body 10033a68-10033a73

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 _GetOwningGD__13TStatusWindowFPP7GDeviceR4Rect(void)

{
  return *_DAT_100cdd40;
}


// ==== .DrawRoutine__13TStatusWindowFv @ 10034708 ====
// CyDecompAt: created, body 10034708-1003497b

void _DrawRoutine__13TStatusWindowFv(int param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined *puVar3;
  int iVar4;
  int iVar5;
  undefined4 *puVar6;
  undefined4 uVar7;
  short sVar8;
  undefined4 uStack_38;
  undefined4 uStack_34;
  undefined4 uStack_30;
  undefined4 uStack_2c;
  undefined4 auStack_28 [3];
  
  puVar3 = PTR_DAT_100cde00;
  puVar2 = PTR_DAT_100cdbe4;
  puVar1 = PTR_DAT_100cdb9c;
  uVar7 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_28);
  .glue::SetPort(uVar7);
  uStack_30 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x10);
  uStack_2c = *(undefined4 *)(*(int *)(param_1 + 4) + 0x14);
  .debug::_SpanBits__FR4RectR6PixMapssss(&uStack_30,puVar3,0x20,0x40,0x20,0);
  .glue::DrawControls(*(undefined4 *)(param_1 + 4));
  .glue::BackPat(PTR_DAT_100cdb94 + 0xc2);
  uStack_30 = *(undefined4 *)(param_1 + 0x90);
  uStack_2c = *(undefined4 *)(param_1 + 0x94);
  .debug::_SpanBits__FR4RectR6PixMapssss(&uStack_30,puVar3 + 0x96,0x10,0x20,0x10,0x24);
  FUN_100c50e8(*(undefined4 *)(param_1 + 0x14),*(undefined4 *)(*(int *)(param_1 + 4) + 0x18));
  .debug::_ExpandHorizontally__FR4RectsUc(param_1 + 0x1c,0x19c,0);
  .debug::_AutoEye__13TStatusWindowFPc(param_1,0);
  .debug::_KeyboardMode__13TStatusWindowFs(param_1,(int)*(short *)PTR_DAT_100ce73c);
  .glue::CopyBits(puVar3 + 200,*(int *)(PTR_DAT_100cdb94 + 0xca) + 2,puVar3 + 0xce,param_1 + 0x98,
                  0x24,0);
  uVar7 = *(undefined4 *)(param_1 + 0x38);
  uStack_2c = *(undefined4 *)(param_1 + 0x3c);
  uStack_30._2_2_ = (short)uVar7;
  iVar5 = (int)uStack_30._2_2_;
  uStack_30._0_2_ = (short)((uint)uVar7 >> 0x10);
  iVar4 = (int)uStack_30._0_2_;
  uStack_30 = uVar7;
  .glue::OffsetRect(&uStack_30,-iVar5,-iVar4);
  .glue::CopyBits(*(int *)(param_1 + 0x80) + 2,*(int *)(param_1 + 4) + 2,&uStack_30,param_1 + 0x38,0
                  ,0);
  for (sVar8 = 0; sVar8 < 8; sVar8 = sVar8 + 1) {
    puVar6 = (undefined4 *)(param_1 + sVar8 * 8 + 0x40);
    uStack_38 = *puVar6;
    uStack_34 = puVar6[1];
    if (sVar8 < *(short *)puVar1) {
      .debug::_DrawCharStatus__13TStatusWindowFsRC4RectUc
                (param_1,(int)*(short *)(puVar2 + sVar8 * 2),&uStack_38,0);
    }
    else {
      .debug::_DrawCharStatus__13TStatusWindowFsRC4RectUc(param_1,0,&uStack_38,0);
    }
  }
  for (iVar4 = 0; (short)iVar4 < 8; iVar4 = iVar4 + 1) {
    if ((short)iVar4 < *(short *)puVar1) {
      .debug::_DrawDoPopUp__FsUc(iVar4,0);
    }
  }
  .debug::_DrawMacros__13TStatusWindowFv(param_1);
  .glue::ValidRect(*(int *)(param_1 + 4) + 0x10);
  .glue::SetPort(auStack_28[0]);
  return;
}


// ==== .PointToProp__13TStatusWindowF5Point @ 10034c68 ====
// CyDecompAt: created, body 10034c68-10034e97

int _PointToProp__13TStatusWindowF5Point(int param_1,undefined4 param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  uint uVar6;
  undefined4 uVar7;
  char cVar8;
  short sVar9;
  undefined4 uStack_28;
  undefined4 uStack_24;
  
  puVar5 = PTR_DAT_100cddb8;
  puVar4 = PTR_DAT_100cddb4;
  puVar3 = PTR_DAT_100cddb0;
  puVar2 = PTR_DAT_100cdbe4;
  puVar1 = PTR_DAT_100cdb9c;
  uStack_28 = *(undefined4 *)(param_1 + 0x40);
  uStack_24 = *(undefined4 *)(param_1 + 0x44);
  .glue::UnionRect(&uStack_28,param_1 + 0x78,&uStack_28);
  cVar8 = .glue::PtInRect(param_2,&uStack_28);
  if (cVar8 != '\0') {
    *(undefined2 *)puVar5 = 2;
    uVar6 = (int)*(short *)(param_1 + 0x42) + (int)*(short *)(param_1 + 0x46);
    *(ushort *)(puVar4 + 2) =
         (short)((int)uVar6 >> 1) + (ushort)((int)uVar6 < 0 && (uVar6 & 1) != 0);
    uVar6 = (int)*(short *)(param_1 + 0x40) + (int)*(short *)(param_1 + 0x44);
    *(ushort *)puVar4 = (short)((int)uVar6 >> 1) + (ushort)((int)uVar6 < 0 && (uVar6 & 1) != 0);
    *(undefined4 *)puVar3 = uStack_28;
    *(undefined4 *)(puVar3 + 4) = uStack_24;
  }
  cVar8 = .glue::PtInRect(param_2,param_1 + 0x24);
  if (cVar8 != '\0') {
    *(undefined2 *)puVar5 = 3;
    *(undefined2 *)(puVar4 + 2) = *(undefined2 *)(param_1 + 0x2a);
    uVar6 = (int)*(short *)(param_1 + 0x24) + (int)*(short *)(param_1 + 0x28);
    *(ushort *)puVar4 = (short)((int)uVar6 >> 1) + (ushort)((int)uVar6 < 0 && (uVar6 & 1) != 0);
    uVar7 = *(undefined4 *)(param_1 + 0x28);
    *(undefined4 *)puVar3 = *(undefined4 *)(param_1 + 0x24);
    *(undefined4 *)(puVar3 + 4) = uVar7;
  }
  cVar8 = .glue::PtInRect(param_2,param_1 + 0x1c);
  if (cVar8 != '\0') {
    *(undefined2 *)puVar5 = 4;
    *(undefined2 *)(puVar4 + 2) = *(undefined2 *)(param_1 + 0x22);
    uVar6 = (int)*(short *)(param_1 + 0x1c) + (int)*(short *)(param_1 + 0x20);
    *(ushort *)puVar4 = (short)((int)uVar6 >> 1) + (ushort)((int)uVar6 < 0 && (uVar6 & 1) != 0);
    uVar7 = *(undefined4 *)(param_1 + 0x20);
    *(undefined4 *)puVar3 = *(undefined4 *)(param_1 + 0x1c);
    *(undefined4 *)(puVar3 + 4) = uVar7;
  }
  cVar8 = .glue::PtInRect(param_2,param_1 + 0x38);
  if (cVar8 != '\0') {
    *(undefined2 *)puVar5 = 5;
    uVar6 = (int)*(short *)(param_1 + 0x3e) + (int)*(short *)(param_1 + 0x3a);
    *(ushort *)(puVar4 + 2) =
         (short)((int)uVar6 >> 1) + (ushort)((int)uVar6 < 0 && (uVar6 & 1) != 0);
    uVar6 = (int)*(short *)(param_1 + 0x38) + (int)*(short *)(param_1 + 0x3c);
    *(ushort *)puVar4 = (short)((int)uVar6 >> 1) + (ushort)((int)uVar6 < 0 && (uVar6 & 1) != 0);
    uVar7 = *(undefined4 *)(param_1 + 0x3c);
    *(undefined4 *)puVar3 = *(undefined4 *)(param_1 + 0x38);
    *(undefined4 *)(puVar3 + 4) = uVar7;
  }
  sVar9 = 0;
  while( true ) {
    if (*(short *)puVar1 <= sVar9) {
      return 0;
    }
    cVar8 = .glue::PtInRect(param_2,param_1 + sVar9 * 8 + 0x40);
    if (cVar8 != '\0') break;
    sVar9 = sVar9 + 1;
  }
  return (int)*(short *)(puVar2 + sVar9 * 2);
}


// ==== .PropToPoint__13TStatusWindowFsP5Point @ 10034ed0 ====
// CyDecompAt: created, body 10034ed0-10034fcb

undefined4 _PropToPoint__13TStatusWindowFsP5Point(int param_1,short param_2,short *param_3)

{
  uint uVar1;
  undefined4 uVar2;
  short sVar3;
  undefined4 auStack_28 [2];
  
  sVar3 = 0;
  while( true ) {
    if (*(short *)PTR_DAT_100cdb9c <= sVar3) {
      return 0;
    }
    if (param_2 == *(short *)(PTR_DAT_100cdbe4 + sVar3 * 2)) break;
    sVar3 = sVar3 + 1;
  }
  uVar1 = (int)*(short *)(param_1 + sVar3 * 8 + 0x42) + (int)*(short *)(param_1 + sVar3 * 8 + 0x46);
  param_3[1] = (short)((int)uVar1 >> 1) + (ushort)((int)uVar1 < 0 && (uVar1 & 1) != 0);
  *param_3 = *(short *)(param_1 + sVar3 * 8 + 0x40) + 0x14;
  uVar2 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_28);
  .glue::SetPort(uVar2);
  .glue::LocalToGlobal(param_3);
  .glue::SetPort(auStack_28[0]);
  return 1;
}


// ==== .CursorRoutine__13TStatusWindowF5Points @ 10035004 ====
// CyDecompAt: created, body 10035004-10035263

void _CursorRoutine__13TStatusWindowF5Points(int param_1,undefined4 param_2,short param_3)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined *puVar4;
  uint uVar5;
  uint uVar6;
  char cVar8;
  ushort uVar7;
  undefined4 uVar9;
  short sVar10;
  undefined4 uStack_254;
  undefined1 auStack_250 [256];
  undefined1 auStack_150 [256];
  undefined4 uStack_50;
  undefined4 uStack_4c;
  undefined4 uStack_48;
  undefined4 uStack_44;
  undefined4 uStack_40;
  undefined4 uStack_3c;
  undefined2 uStack_38;
  short sStack_36;
  undefined4 uStack_34;
  
  puVar4 = PTR_DAT_100ce750;
  puVar3 = PTR_s_F_d___s_100c62e7_0x1e_100ce734;
  puVar2 = PTR_s_F_d__Undefined_100ce730;
  puVar1 = PTR_DAT_100cdbec;
  uVar9 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(&uStack_34);
  .glue::SetPort(uVar9);
  uStack_3c = *(undefined4 *)(param_1 + 0x24);
  sStack_36 = (short)*(undefined4 *)(param_1 + 0x28);
  _uStack_38 = CONCAT22((short)((uint)*(undefined4 *)(param_1 + 0x28) >> 0x10),sStack_36 + -0x10);
  if (*PTR_DAT_100cdd00 == '\0') {
    uStack_44 = *(undefined4 *)puVar4;
    uStack_40 = *(undefined4 *)(puVar4 + 4);
    .glue::UnionRect(&uStack_44,puVar4 + 0x48,&uStack_44);
    cVar8 = .glue::PtInRect(param_2,&uStack_44);
    if (cVar8 != '\0') {
      uVar5 = (int)*(short *)(puVar4 + 10) + (int)*(short *)(puVar4 + 0xe);
      uVar6 = (int)*(short *)(puVar4 + 8) + (int)*(short *)(puVar4 + 0xc);
      uStack_48 = CONCAT22((short)((int)uVar6 >> 1) + (ushort)((int)uVar6 < 0 && (uVar6 & 1) != 0),
                           (short)((int)uVar5 >> 1) + (ushort)((int)uVar5 < 0 && (uVar5 & 1) != 0));
      .debug::_ShowHelp__16TDroppableWindowFs5PointR4Rect(param_1,1,uStack_48,&uStack_44);
    }
    for (sVar10 = 0; sVar10 < 10; sVar10 = sVar10 + 1) {
      uStack_50 = *(undefined4 *)(puVar4 + sVar10 * 8);
      uStack_4c = *(undefined4 *)((int)(puVar4 + sVar10 * 8) + 4);
      cVar8 = .glue::PtInRect(param_2,&uStack_50);
      if (cVar8 != '\0') {
        uVar7 = 0;
        if (*(short *)(&DAT_100d4a7c + sVar10 * 2) != -1) {
          uVar7 = .debug::_FindSkill__Fss
                            ((int)*(short *)puVar1,(int)*(short *)(&DAT_100d4a7c + sVar10 * 2));
        }
        if (uVar7 == 0) {
          FUN_100b6a80(auStack_250,puVar2,sVar10 + 1);
          .debug::_AutoEye__13TStatusWindowFPc(param_1,auStack_250);
        }
        else {
          .debug::_DoInterp__7TInterpFs5VAddr(&uStack_254,2,uVar7 | 0x40500000);
          uVar9 = .debug::_VAddrToPtr__7TInterpF5VAddr(uStack_254);
          FUN_100b6a80(auStack_150,puVar3,sVar10 + 1,uVar9);
          .debug::_AutoEye__13TStatusWindowFPc(param_1,auStack_150);
        }
        .glue::SetPort(uStack_34);
        return;
      }
    }
    .debug::_CursorRoutine__16TDroppableWindowF5Points(param_1,param_2,(int)param_3);
  }
  else {
    .debug::_ChangeCursor__Fs(0x2b);
  }
  .glue::SetPort(uStack_34);
  return;
}


// ==== .MouseRoutine__13TStatusWindowF5Points @ 100352a0 ====
// CyDecompAt: created, body 100352a0-1003590b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */
/* WARNING: Restarted to delay deadcode elimination for space: stack */

void _MouseRoutine__13TStatusWindowF5Points(int param_1,undefined4 param_2,short param_3)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined4 *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  undefined4 uVar6;
  uint *puVar7;
  char cVar10;
  short sVar8;
  ushort uVar9;
  bool bVar11;
  int iVar12;
  undefined4 uStack_74;
  undefined4 uStack_70;
  short sStack_6c;
  undefined4 uStack_68;
  undefined4 uStack_64;
  int iStack_60;
  undefined4 uStack_5c;
  undefined4 uStack_58;
  undefined4 uStack_54;
  undefined4 auStack_50 [4];
  
  puVar5 = PTR_DAT_100ce760;
  puVar4 = PTR_DAT_100ce75c;
  puVar2 = PTR_DAT_100cdbec;
  puVar1 = PTR_DAT_100cdbe4;
  uVar6 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_50);
  .glue::SetPort(uVar6);
  cVar10 = .glue::PtInRect(param_2,param_1 + 0x24);
  if (cVar10 != '\0') {
    FUN_100c50e8(*(undefined4 *)(param_1 + 0x14),param_2,0);
    .glue::SetPort(auStack_50[0]);
    return;
  }
  if (*PTR_DAT_100cdd00 == '\0') {
    sVar8 = .glue::FindControl(param_2,*(undefined4 *)(param_1 + 4),&uStack_54);
    if (sVar8 != 0) {
      .glue::TrackControl(uStack_54,param_2,0);
      *(undefined1 *)(*(int *)PTR_DAT_100cdc44 + 0x3fff0) = 0x1c;
      sVar8 = .glue::GetControlReference(uStack_54);
      puVar3 = _DAT_100cdcd0;
      puVar1 = PTR_DAT_100cdc44;
      *(ushort *)(*(int *)PTR_DAT_100cdc44 + 0x3fff4) =
           0xffU - sVar8 & 0x3ff | *(ushort *)(*(int *)PTR_DAT_100cdc44 + 0x3fff4) & 0xfc00;
      puVar7 = (uint *)(*(int *)puVar1 + 0x3fff0);
      *puVar7 = *puVar7 & 0xff0000 | 0x3fff | *puVar7 & 0xff000000;
      uStack_70 = 0x40003fff;
                    /* WARNING: Ignoring partial resolution of indirect */
      uStack_70._0_2_ = 0x4050;
      .debug::_DoUse__8TGameSysF5VAddr(*puVar3,0x40503fff);
      .debug::_HeartBeat__8TGameSysFs(*_DAT_100cdcd0,0);
      .glue::SetPort(auStack_50[0]);
      return;
    }
    if ((*(int *)PTR_DAT_100cddac != 0) || (*(short *)PTR_DAT_100cdda8 != 0)) {
      .debug::_MouseRoutine__16TDroppableWindowF5Points(param_1,param_2,(int)param_3);
      .glue::SetPort(auStack_50[0]);
      return;
    }
    for (sVar8 = 0; sVar8 < 10; sVar8 = sVar8 + 1) {
      uStack_5c = *(undefined4 *)(PTR_DAT_100ce750 + sVar8 * 8);
      uStack_58 = *(undefined4 *)((int)(PTR_DAT_100ce750 + sVar8 * 8) + 4);
      cVar10 = .glue::PtInRect(param_2,&uStack_5c);
      if (cVar10 != '\0') {
        uVar9 = 0;
        if (*(short *)(&DAT_100d4a7c + sVar8 * 2) != -1) {
          uVar9 = .debug::_FindSkill__Fss
                            ((int)*(short *)puVar2,(int)*(short *)(&DAT_100d4a7c + sVar8 * 2));
        }
        if (uVar9 == 0) {
          .debug::_myprintf__13TStatusWindowFPce(param_1,PTR_s_F_d__Undefined_100ce728,sVar8 + 1);
        }
        else {
          bVar11 = false;
          do {
            cVar10 = .glue::PtInRect(param_2,&uStack_5c);
            if (bVar11 != (bool)cVar10) {
              bVar11 = bVar11 == false;
              .debug::_DrawAMacro__FR4RectsUc
                        (&uStack_5c,(int)*(short *)(&DAT_100d4a7c + sVar8 * 2),bVar11);
            }
            .glue::GetMouse(&stack0x0000001c);
            cVar10 = .glue::StillDown();
          } while (cVar10 != '\0');
          if (bVar11 == false) {
            .glue::SetPort(auStack_50[0]);
            return;
          }
          .debug::_DrawAMacro__FR4RectsUc(&uStack_5c,(int)*(short *)(&DAT_100d4a7c + sVar8 * 2),0);
          .debug::_DoInterp__7TInterpFs5VAddr(&uStack_74,2,uVar9 | 0x40500000);
          uVar6 = .debug::_VAddrToPtr__7TInterpF5VAddr(uStack_74);
          .debug::_myprintf__13TStatusWindowFPce(param_1,PTR_s_F_d___s_100ce72c,sVar8 + 1,uVar6);
          .debug::_ScheduleSkill__11TTaskMasterFss
                    (*(ushort *)(*(int *)PTR_DAT_100cdc44 + (short)uVar9 * 0x10 + 4) & 0x3ff,
                     (int)*(short *)puVar2);
        }
        .glue::SetPort(auStack_50[0]);
        return;
      }
    }
    for (iVar12 = 0; sVar8 = (short)iVar12, sVar8 < *(short *)PTR_DAT_100cdb9c; iVar12 = iVar12 + 1)
    {
      cVar10 = .glue::PtInRect(param_2,param_1 + sVar8 * 8 + 0x40);
      if (cVar10 != '\0') {
        bVar11 = false;
        while (cVar10 = .glue::StillDown(), cVar10 != '\0') {
          cVar10 = .glue::PtInRect(param_2,param_1 + sVar8 * 8 + 0x40);
          if (bVar11 != (bool)cVar10) {
            bVar11 = bVar11 == false;
            .debug::_DrawCharStatus__13TStatusWindowFsRC4RectUc
                      (param_1,(int)*(short *)(puVar1 + sVar8 * 2),param_1 + sVar8 * 8 + 0x40,bVar11
                      );
          }
          .glue::GetMouse(&stack0x0000001c);
        }
        if (bVar11 != false) {
          .debug::_DrawCharStatus__13TStatusWindowFsRC4RectUc
                    (param_1,(int)*(short *)(puVar1 + sVar8 * 2),param_1 + sVar8 * 8 + 0x40,0);
          iVar12 = .debug::_FindInventory__16TInventoryWindowFs((int)*(short *)(puVar1 + sVar8 * 2))
          ;
          if (iVar12 == 0) {
            iStack_60 = FUN_100be7c8(0x88);
            if (iStack_60 != 0) {
              .debug::___ct__16TCharacterWindowFs(iStack_60,(int)*(short *)(puVar1 + sVar8 * 2));
            }
          }
          else {
            FUN_100c50e8(iVar12);
          }
        }
        .glue::SetPort(auStack_50[0]);
        return;
      }
      cVar10 = .glue::PtInRect(param_2,puVar5 + sVar8 * 8);
      if (cVar10 != '\0') {
        .debug::_MyInitCursor__Fs(0x2a);
        .debug::_DrawDoPopUp__FsUc(iVar12,1);
        .glue::TextFont(3);
        .glue::TextSize(9);
        uStack_68 = 0;
        uStack_64 = CONCAT22(*(undefined2 *)(puVar5 + sVar8 * 8),
                             *(undefined2 *)(puVar5 + sVar8 * 8 + 2));
        .glue::LocalToGlobal(&uStack_64);
        .debug::_RedoDoPopUps__Fs(iVar12);
        uVar6 = .glue::CountMItems(*(undefined4 *)(puVar4 + sVar8 * 4));
        uVar9 = .debug::_PopUpMenuSelectWithCurFont
                          (*(undefined4 *)(puVar4 + sVar8 * 4),uStack_64,uVar6,3,9);
        .debug::_DrawDoPopUp__FsUc(iVar12,0);
        if (uVar9 != 0) {
          sStack_6c = *(short *)(*(int *)(PTR_DAT_100ce724 + sVar8 * 0xc + 8) + (uVar9 - 1) * 2);
          .debug::_ScheduleSkill__11TTaskMasterFss
                    ((int)sStack_6c,(int)*(short *)(puVar1 + sVar8 * 2));
        }
      }
    }
  }
  .glue::SetPort(auStack_50[0]);
  return;
}


// ==== .ForceOut__13TStatusWindowFv @ 10035d48 ====
// CyDecompAt: created, body 10035d48-10035d8f

void _ForceOut__13TStatusWindowFv(int param_1)

{
  if (*(int *)(param_1 + 0x34) != 0) {
    FUN_100c50e8();
  }
  return;
}


// ==== .__dt__13TStatusWindowFv @ 10035f60 ====
// CyDecompAt: created, body 10035f60-10035fd3

undefined4 * ___dt__13TStatusWindowFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d4b08;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d4614;
      .debug::___dt__7TWindowFv(param_1,0);
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .CanDrop__13TStatusWindowFsR5Point @ 100366e4 ====
// CyDecompAt: created, body 100366e4-100367c3

undefined4 _CanDrop__13TStatusWindowFsR5Point(int param_1,undefined4 param_2,undefined4 *param_3)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  undefined *puVar6;
  char cVar7;
  short sVar8;
  
  puVar6 = PTR_s__Take__100ce714;
  puVar5 = PTR_s__Give_To__100ce710;
  puVar4 = PTR_DAT_100cdbec;
  puVar3 = PTR_DAT_100cdbe4;
  puVar2 = PTR_DAT_100cdb9c;
  puVar1 = PTR_DAT_100cdb98;
  sVar8 = 0;
  while( true ) {
    if (*(short *)puVar2 <= sVar8) {
      .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Can_t_drop_there__100ce70c);
      return 0;
    }
    cVar7 = .glue::PtInRect(*param_3,param_1 + sVar8 * 8 + 0x40);
    if (cVar7 != '\0') break;
    sVar8 = sVar8 + 1;
  }
  *(undefined2 *)param_3 = *(undefined2 *)(puVar3 + sVar8 * 2);
  if (*(short *)puVar4 == *(short *)(puVar3 + sVar8 * 2)) {
    .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,puVar6);
  }
  else {
    .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,puVar5);
  }
  return 1;
}


// ==== .DoDrop__13TStatusWindowFs5Point @ 100367f8 ====
// CyDecompAt: created, body 100367f8-10036833

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DoDrop__13TStatusWindowFs5Point(undefined4 param_1,short param_2,undefined4 param_3)

{
  .debug::_TakeCommand__8TGameSysFss
            (*_DAT_100cdcd0,(int)param_2,(int)(short)((uint)param_3 >> 0x10));
  return;
}


// ==== .__arraydtor$2299 @ 10037f08 ====
// CyDecompAt: created, body 10037f08-10037f3b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void ___arraydtor_2299(void)

{
  FUN_100be4e4(PTR_DAT_100ce724,_DAT_100cdde0,0xc,8);
  return;
}


// ==== .__dt__Q23std30vector<s,Q23std12allocator<s>>Fv @ 10037f60 ====
// CyDecompAt: created, body 10037f60-10037fcf

int ___dt__Q23std30vector<s,Q23std12allocator<s>>Fv(int param_1,short param_2)

{
  if ((param_1 != 0) &&
     (.debug::_tear_down__Q23std30vector<s,Q23std12allocator<s>>Fv(param_1), 0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .__ct__Q23std30vector<s,Q23std12allocator<s>>Fv @ 10038014 ====
// CyDecompAt: created, body 10038014-1003807f

undefined4 * ___ct__Q23std30vector<s,Q23std12allocator<s>>Fv(undefined4 *param_1)

{
  *param_1 = 0;
  param_1[1] = 0;
  param_1[2] = 0;
  return param_1;
}


// ==== .DrawRoutine__13TBackdropWindFv @ 10038440 ====
// CyDecompAt: created, body 10038440-100384d3

void _DrawRoutine__13TBackdropWindFv(int param_1)

{
  .glue::SetPort(*(undefined4 *)(param_1 + 4));
  if (*(int *)PTR_DAT_100ce77c == 0) {
    .glue::FillRect(*(int *)(param_1 + 4) + 0x10,PTR_DAT_100cdb94 + 0xba);
  }
  else {
    .glue::FillCRect(*(int *)(param_1 + 4) + 0x10,*(undefined4 *)PTR_DAT_100ce77c);
  }
  .debug::_SetTilePat__Fs(0x1a4);
  .glue::ValidRgn(*(undefined4 *)(*(int *)(param_1 + 4) + 0x18));
  return;
}


// ==== .MouseRoutine__13TBackdropWindF5Points @ 10038508 ====
// CyDecompAt: created, body 10038508-1003850b

void _MouseRoutine__13TBackdropWindF5Points(void)

{
  return;
}


// ==== .CursorRoutine__13TBackdropWindF5Points @ 10038544 ====
// CyDecompAt: created, body 10038544-1003858f

void _CursorRoutine__13TBackdropWindF5Points(void)

{
  if (*(int *)PTR_DAT_100cdb98 != 0) {
    .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)PTR_DAT_100cdb98,0);
  }
  .debug::_ChangeCursor__Fs(0x2a);
  return;
}


// ==== .HandleMonitorChanged__13TBackdropWindFPP7GDeviceR4RectR4Rect @ 100385cc ====
// CyDecompAt: created, body 100385cc-100386bf

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleMonitorChanged__13TBackdropWindFPP7GDeviceR4RectR4Rect(int param_1)

{
  int *piVar1;
  char cVar2;
  undefined4 uStack_18;
  undefined4 uStack_14;
  undefined4 uStack_10;
  undefined4 uStack_c;
  
  uStack_10 = *(undefined4 *)(*(int *)*_DAT_100cdd40 + 0x22);
  uStack_c = *(undefined4 *)(*(int *)*_DAT_100cdd40 + 0x26);
  for (piVar1 = (int *).glue::GetDeviceList(); piVar1 != (int *)0x0;
      piVar1 = *(int **)(*piVar1 + 0x1e)) {
    cVar2 = .glue::TestDeviceAttribute(piVar1,0xd);
    if (cVar2 != '\0') {
      uStack_18 = *(undefined4 *)(*piVar1 + 0x22);
      uStack_14 = *(undefined4 *)(*piVar1 + 0x26);
      .glue::UnionRect(&uStack_18,&uStack_10,&uStack_10);
    }
  }
  .glue::MoveWindow(*(undefined4 *)(param_1 + 4),(int)uStack_10._2_2_,(int)uStack_10._0_2_,0);
  .glue::SizeWindow(*(undefined4 *)(param_1 + 4),(int)uStack_c._2_2_ - (int)uStack_10._2_2_,
                    (int)uStack_c._0_2_ - (int)uStack_10._0_2_,1);
  return;
}


// ==== .__dt__13TBackdropWindFv @ 10038710 ====
// CyDecompAt: created, body 10038710-10038773

undefined4 * ___dt__13TBackdropWindFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d4bf4;
    .debug::___dt__7TWindowFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .cmpprops__FPCsPCs @ 100388a8 ====
// CyDecompAt: created, body 100388a8-1003899f

undefined4 _cmpprops__FPCsPCs(short *param_1,short *param_2)

{
  undefined4 uVar1;
  int iVar2;
  int iVar3;
  
  iVar3 = *(int *)PTR_DAT_100cdc44 + *param_1 * 0x10;
  iVar2 = *(int *)PTR_DAT_100cdc44 + *param_2 * 0x10;
  if ((*(ushort *)(iVar3 + 4) & 0x3ff) < (*(ushort *)(iVar2 + 4) & 0x3ff)) {
    uVar1 = 0xffffffff;
  }
  else if ((*(ushort *)(iVar2 + 4) & 0x3ff) < (*(ushort *)(iVar3 + 4) & 0x3ff)) {
    uVar1 = 1;
  }
  else if ((*(byte *)(iVar3 + 4) >> 2 & 0x1f) < (*(byte *)(iVar2 + 4) >> 2 & 0x1f)) {
    uVar1 = 0xffffffff;
  }
  else if ((*(byte *)(iVar3 + 4) >> 2 & 0x1f) < (*(byte *)(iVar2 + 4) >> 2 & 0x1f)) {
    uVar1 = 1;
  }
  else if (*(byte *)(iVar3 + 6) < *(byte *)(iVar2 + 6)) {
    uVar1 = 0xffffffff;
  }
  else if (*(byte *)(iVar2 + 6) < *(byte *)(iVar3 + 6)) {
    uVar1 = 1;
  }
  else {
    uVar1 = 0;
  }
  return uVar1;
}


// ==== .LDEFDraw__14TInventoryListFUcP4Rect5Pointss @ 10038c0c ====
// CyDecompAt: created, body 10038c0c-10038d47

void _LDEFDraw__14TInventoryListFUcP4Rect5Pointss
               (int param_1,char param_2,short *param_3,undefined4 param_4,undefined4 param_5,
               short param_6)

{
  uint uVar1;
  short asStack_18 [6];
  
  if ((int)(short)param_4 +
      (int)(short)((uint)param_4 >> 0x10) * (int)*(short *)(**(int **)(param_1 + 4) + 6) <
      (int)*(short *)(param_1 + 0x10)) {
    .glue::FillRect(param_3,PTR_DAT_100cdb94 + 0xaa);
    .glue::PenSize(2,2);
    .glue::FrameRect(param_3);
    .glue::PenNormal();
  }
  else {
    .glue::EraseRect(param_3);
  }
  if (param_6 == 2) {
    .glue::LGetCell(asStack_18,&stack0x0000002e,param_4,*(undefined4 *)(param_1 + 4));
    .debug::_DrawInventoryIcon__FssP8PropItem
              (param_3[1] + 1,*param_3 + 1,*(int *)PTR_DAT_100cdc44 + asStack_18[0] * 0x10);
    if (param_2 != '\0') {
      uVar1 = .glue::LMGetHiliteMode();
      .glue::LMSetHiliteMode(uVar1 & 0xffffff7f);
      .glue::InvertRect(param_3);
    }
  }
  return;
}


// ==== .LDEFHilite__14TInventoryListFUcP4Rect5Pointss @ 10038d88 ====
// CyDecompAt: created, body 10038d88-10038dd7

void _LDEFHilite__14TInventoryListFUcP4Rect5Pointss
               (undefined4 param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,
               undefined4 param_5,short param_6)

{
  uint uVar1;
  
  if (param_6 == 2) {
    uVar1 = .glue::LMGetHiliteMode();
    .glue::LMSetHiliteMode(uVar1 & 0xffffff7f);
    .glue::InvertRect(param_3);
  }
  return;
}


// ==== .GetSelection__14TInventoryListFv @ 10038e18 ====
// CyDecompAt: created, body 10038e18-10038ea7

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

int _GetSelection__14TInventoryListFv(int param_1)

{
  char cVar2;
  int iVar1;
  short sStack_18;
  short sStack_16;
  undefined4 auStack_14 [4];
  
  auStack_14[0] = _DAT_100d4c7c;
  cVar2 = .glue::LGetSelect(1,auStack_14,*(undefined4 *)(param_1 + 4));
  if (cVar2 == '\0') {
    iVar1 = -1;
  }
  else {
    sStack_18 = 2;
    .glue::LGetCell(&sStack_16,&sStack_18,auStack_14[0],*(undefined4 *)(param_1 + 4));
    if (sStack_18 == 2) {
      iVar1 = (int)sStack_16;
    }
    else {
      iVar1 = -1;
    }
  }
  return iVar1;
}


// ==== .myListSearch @ 10038f9c ====
// CyDecompAt: created, body 10038f9c-10038fd7

undefined4 _myListSearch(short *param_1,short *param_2,short param_3,short param_4)

{
  if (((param_3 == param_4) && (param_3 == 2)) && (*param_1 == *param_2)) {
    return 0;
  }
  return 0xffffffff;
}


// ==== .LDEFDraw__8TTextOutFUcP4Rect5Pointss @ 10039480 ====
// CyDecompAt: created, body 10039480-1003969f

void _LDEFDraw__8TTextOutFUcP4Rect5Pointss
               (int param_1,undefined4 param_2,int param_3,undefined4 param_4,short param_5,
               short param_6)

{
  bool bVar1;
  char cVar2;
  char *pcVar3;
  char *pcVar4;
  
  .glue::EraseRect(param_3);
  .glue::MoveTo(*(short *)(param_3 + 2) + 3,*(short *)(param_3 + 4) + -4);
  cVar2 = .glue::HGetState(*(undefined4 *)(**(int **)(param_1 + 4) + 0x50));
  .glue::HLock(*(undefined4 *)(**(int **)(param_1 + 4) + 0x50));
  .debug::_SetText__Fs(4);
  .glue::ForeColor(0x21);
  bVar1 = false;
  pcVar3 = (char *)(**(int **)(**(int **)(param_1 + 4) + 0x50) + (int)param_5);
  for (; (((0 < param_6 && (pcVar3[param_6] == ' ')) || (pcVar3[param_6] == '\n')) ||
         ((pcVar3[param_6] == '\r' || (pcVar4 = pcVar3, pcVar3[param_6] == '\t'))));
      param_6 = param_6 + -1) {
  }
  while (0 < param_6) {
    if (((bVar1) && ((*pcVar4 < 'A' || ('Z' < *pcVar4)))) && ((*pcVar4 < 'a' || ('z' < *pcVar4)))) {
      .glue::ForeColor(0x199);
      .debug::_AADrawText__FPcss(pcVar3,0,(int)pcVar4 - (int)pcVar3);
      .glue::ForeColor(0x21);
      bVar1 = false;
      pcVar3 = pcVar4;
    }
    else if ((bVar1) || (*pcVar4 != '@')) {
      param_6 = param_6 + -1;
      pcVar4 = pcVar4 + 1;
    }
    else {
      .debug::_AADrawText__FPcss(pcVar3,0,(int)pcVar4 - (int)pcVar3);
      pcVar3 = pcVar4 + 1;
      param_6 = param_6 + -1;
      bVar1 = true;
      pcVar4 = pcVar4 + 1;
    }
  }
  if (pcVar3 < pcVar4) {
    .debug::_AADrawText__FPcss(pcVar3,0,(int)pcVar4 - (int)pcVar3);
  }
  .glue::HSetState(*(undefined4 *)(**(int **)(param_1 + 4) + 0x50),(int)cVar2);
  return;
}


// ==== .LDEFHilite__8TTextOutFUcP4Rect5Pointss @ 100396d8 ====
// CyDecompAt: created, body 100396d8-100396db

void _LDEFHilite__8TTextOutFUcP4Rect5Pointss(void)

{
  return;
}


// ==== .__dt__8TTextOutFv @ 1003a238 ====
// CyDecompAt: created, body 1003a238-1003a29b

undefined4 * ___dt__8TTextOutFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d4ddc;
    .debug::___dt__8TListBoxFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__15TScriptedWindowFv @ 1003ac48 ====
// CyDecompAt: created, body 1003ac48-1003acf3

undefined4 * ___dt__15TScriptedWindowFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d69e8;
    if (((param_1 != (undefined4 *)0xffffffe4) && (param_1 != (undefined4 *)0xffffffe4)) &&
       (param_1[9] != 0)) {
      FUN_100be848(param_1[9]);
    }
    .debug::___dt__16TInventoryWindowFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__13TConversationFv @ 1003b1fc ====
// CyDecompAt: created, body 1003b1fc-1003b2d7

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 * ___dt__13TConversationFv(undefined4 *param_1,short param_2)

{
  short sVar1;
  
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d5298;
    FUN_100c50e8(param_1);
    .debug::_ConvMore__13TConversationFv(param_1);
    for (sVar1 = 0; sVar1 < 100; sVar1 = sVar1 + 1) {
      if (param_1[sVar1 + 0x22e] != 0) {
        FUN_100b2ccc(param_1[sVar1 + 0x22e]);
      }
    }
    *_DAT_100cdcc8 = 0;
    .debug::___dt__12TInteractionFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .CloseRoutine__13TConversationFv @ 1003b304 ====
// CyDecompAt: created, body 1003b304-1003b3e7

void _CloseRoutine__13TConversationFv(int param_1)

{
  int *piVar1;
  undefined1 auStack_18 [16];
  
  .glue::HidePen();
  for (piVar1 = *(int **)(param_1 + 0x24);
      piVar1 != (int *)(*(int *)(param_1 + 0x24) + *(int *)(param_1 + 0x20) * 4);
      piVar1 = piVar1 + 1) {
    .debug::_FreeScriptedWidget__15TScriptedWindowFPQ215TScriptedWindow7TWidget(*piVar1);
    if (*piVar1 != 0) {
      FUN_100c50e8(*piVar1,1);
    }
    *piVar1 = 0;
  }
  *(undefined4 *)(param_1 + 0x20) = 0;
  .debug::_FreeScriptedWindow__15TScriptedWindowFP15TScriptedWindow(param_1);
  .glue::ShowPen();
  FUN_100c50e8(param_1,auStack_18);
  .glue::ValidRect(auStack_18);
  FUN_100c50e8(param_1);
  return;
}


// ==== .__dt__Q215TScriptedWindow7TWidgetFv @ 1003b41c ====
// CyDecompAt: created, body 1003b41c-1003b46f

undefined4 * ___dt__Q215TScriptedWindow7TWidgetFv(undefined4 *param_1,short param_2)

{
  if ((param_1 != (undefined4 *)0x0) && (*param_1 = &PTR_PTR_100d71b8, 0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .OffsetOrigin__13TConversationFRsRs @ 1003b4a8 ====
// CyDecompAt: created, body 1003b4a8-1003b4cb

void _OffsetOrigin__13TConversationFRsRs(int param_1,short *param_2,short *param_3)

{
  *param_2 = *param_2 + *(short *)(param_1 + 0xa50);
  *param_3 = *param_3 + *(short *)(param_1 + 0xa52);
  return;
}


// ==== .Show__13TConversationFv @ 1003b9f0 ====
// CyDecompAt: created, body 1003b9f0-1003bb97

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Show__13TConversationFv(int param_1)

{
  int iVar1;
  uint uVar2;
  short sVar3;
  short sVar4;
  undefined4 uVar5;
  int iVar6;
  undefined1 auStack_138 [256];
  undefined1 auStack_38 [4];
  undefined1 auStack_34 [4];
  undefined1 auStack_30 [4];
  undefined4 uStack_2c;
  undefined4 auStack_28 [2];
  
  iVar1 = _DAT_100cdb90;
  uVar5 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_28);
  .glue::SetPort(uVar5);
  .debug::_Show__12TInteractionFv(param_1);
  *(undefined2 *)(param_1 + 0x452) = 0;
  *(undefined2 *)(param_1 + 0x854) = 0;
  .debug::_ShowTalking__13TConversationFv(param_1);
  .debug::_ShowMessage__13TConversationFv(param_1);
  uVar5 = *(undefined4 *)(param_1 + 0x44);
  .glue::GetGWorld(auStack_34,auStack_30);
  .glue::SetGWorld(uVar5,0);
  iVar6 = 0;
  uStack_2c = uVar5;
  while( true ) {
    if (2 < (short)iVar6) break;
    sVar3 = *(short *)(param_1 + (short)iVar6 * 2 + 0xa48);
    if (0 < sVar3) {
      .debug::_DrawPortrait__Fssss(0x20,iVar6 * 0x58 + 0xc,(int)sVar3,0x24);
      .debug::_GetCharacterName__FsPcUc((int)sVar3,auStack_138,0);
      .debug::_FitText__FPCcs(auStack_138,0x54);
      sVar3 = FUN_100b6ce8(auStack_138);
      sVar4 = FUN_100b6ce8(auStack_138);
      uVar5 = .glue::TextWidth(auStack_138,0,(int)sVar4);
      uVar5 = .debug::_Justify__12TTextContextFsss(0x40,uVar5,1);
      uVar2 = (uint)*(short *)(iVar1 + 0x30);
      .debug::_DrawTextOutlined__12TTextContextFssPcsll
                (uVar5,iVar6 * 0x58 + ((int)uVar2 >> 1) + (uint)((int)uVar2 < 0 && (uVar2 & 1) != 0)
                       + 0x58,auStack_138,(int)sVar3,0x1e,0x21);
      .glue::CharExtra(0);
    }
    iVar6 = iVar6 + 1;
  }
  .debug::___dt__13TBufferGWorldFv(auStack_38,0xffffffff);
  .glue::SetPort(auStack_28[0]);
  return;
}


// ==== .Hide__12TInteractionFv @ 1003bbc4 ====
// CyDecompAt: created, body 1003bbc4-1003bce3

void _Hide__12TInteractionFv(int param_1)

{
  undefined4 *puVar1;
  undefined4 uVar2;
  undefined4 uStack_18;
  undefined4 uStack_14;
  undefined4 auStack_10 [2];
  
  if ((*(int *)(param_1 + 0x40) != 0) && (*(int *)(param_1 + 4) != 0)) {
    uVar2 = *(undefined4 *)(param_1 + 4);
    .glue::GetPort(auStack_10);
    .glue::SetPort(uVar2);
    uStack_18 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x10);
    uStack_14 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x14);
    puVar1 = (undefined4 *).glue::GetGWorldPixMap(*(undefined4 *)(param_1 + 0x40));
    .glue::CopyBits(*puVar1,*(int *)(param_1 + 4) + 2,&uStack_18,*(int *)(param_1 + 4) + 0x10,0,0);
    .glue::LMSetPaintWhite(0);
    .debug::_Hide__7TWindowFv(param_1);
    .glue::LMSetPaintWhite(0xffffffff);
    .glue::SetPort(auStack_10[0]);
  }
  if (*(int *)(param_1 + 4) != 0) {
    .debug::_Hide__7TWindowFv(param_1);
    FUN_100c50e8();
  }
  *PTR_DAT_100cdd00 = 0;
  .debug::_DisableKeyboard__Fv();
  return;
}


// ==== .NeedsRedraw__12TInteractionFv @ 1003bd10 ====
// CyDecompAt: created, body 1003bd10-1003bd17

undefined4 _NeedsRedraw__12TInteractionFv(void)

{
  return 0;
}


// ==== .DrawRoutine__12TInteractionFv @ 1003bd48 ====
// CyDecompAt: created, body 1003bd48-1003bf37

void _DrawRoutine__12TInteractionFv(int param_1)

{
  undefined4 uVar1;
  undefined4 uVar2;
  undefined4 *puVar3;
  undefined4 uVar4;
  undefined4 uStack_38;
  undefined4 uStack_34;
  undefined4 uStack_30;
  undefined4 uStack_2c;
  undefined4 auStack_28 [5];
  
  *(undefined2 *)(param_1 + 0x12) = 0;
  uVar4 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_28);
  .glue::SetPort(uVar4);
  uStack_30 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x10);
  uStack_2c = *(undefined4 *)(*(int *)(param_1 + 4) + 0x14);
  uVar4 = .glue::NewRgn();
  .glue::GetClip();
  uVar1 = .glue::NewRgn();
  .glue::CopyRgn(uVar4,uVar1);
  uVar2 = .glue::NewRgn();
  .glue::InsetRect(&uStack_30,0,0);
  .glue::RectRgn(uVar2,&uStack_30);
  .glue::DiffRgn(uVar1,uVar2,uVar2);
  .glue::SetClip(uVar2);
  uStack_30 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x10);
  uStack_2c = *(undefined4 *)(*(int *)(param_1 + 4) + 0x14);
  puVar3 = (undefined4 *).glue::GetGWorldPixMap(*(undefined4 *)(param_1 + 0x40));
  .debug::_MyCopyBitsBevel__12TInteractionFPC6BitMapPC6BitMapPC4RectPC4RectsPP9MacRegion
            (param_1,*puVar3,*(int *)(param_1 + 4) + 2,&uStack_30,*(int *)(param_1 + 4) + 0x10,0,0);
  .glue::SetClip(uVar4);
  .glue::DisposeRgn(uVar4);
  .glue::DisposeRgn(uVar1);
  .glue::DisposeRgn(uVar2);
  uStack_30 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x10);
  uStack_2c = *(undefined4 *)(*(int *)(param_1 + 4) + 0x14);
  .glue::InsetRect(&uStack_30,0,0);
  uStack_38 = uStack_30;
  uStack_34 = uStack_2c;
  puVar3 = (undefined4 *).glue::GetGWorldPixMap(*(undefined4 *)(param_1 + 0x44));
  .glue::CopyBits(*puVar3,*(int *)(param_1 + 4) + 2,&uStack_38,&uStack_30,0,0);
  if (*(int *)(param_1 + 0x3c) != 0) {
    FUN_100c50e8();
  }
  .glue::SetPort(auStack_28[0]);
  return;
}


// ==== .DrawRoutine__9TConvModeFv @ 1003bf68 ====
// CyDecompAt: created, body 1003bf68-1003bf6b

void _DrawRoutine__9TConvModeFv(void)

{
  return;
}


// ==== .MouseRoutine__12TInteractionF5Points @ 1003bf98 ====
// CyDecompAt: created, body 1003bf98-1003bfef

void _MouseRoutine__12TInteractionF5Points(int param_1,undefined4 param_2,short param_3)

{
  if (*(int *)(param_1 + 0x3c) != 0) {
    FUN_100c50e8(*(undefined4 *)(param_1 + 0x3c),param_2,(int)param_3);
  }
  return;
}


// ==== .MouseRoutine__9TConvModeF5Points @ 1003c028 ====
// CyDecompAt: created, body 1003c028-1003c02b

void _MouseRoutine__9TConvModeF5Points(void)

{
  return;
}


// ==== .IdleRoutine__12TInteractionFv @ 1003c060 ====
// CyDecompAt: created, body 1003c060-1003c0b7

void _IdleRoutine__12TInteractionFv(int param_1)

{
  if (*(int *)(param_1 + 0x3c) == 0) {
    .debug::_IdleRoutine__15TScriptedWindowFv(param_1);
  }
  else {
    FUN_100c50e8();
  }
  return;
}


// ==== .IdleRoutine__9TConvModeFv @ 1003c0e8 ====
// CyDecompAt: created, body 1003c0e8-1003c0eb

void _IdleRoutine__9TConvModeFv(void)

{
  return;
}


// ==== .CursorRoutine__12TInteractionF5Points @ 1003c118 ====
// CyDecompAt: created, body 1003c118-1003c18f

void _CursorRoutine__12TInteractionF5Points(int param_1,undefined4 param_2,undefined4 param_3)

{
  if (*(int *)(param_1 + 0x3c) == 0) {
    .debug::_CursorRoutine__15TScriptedWindowF5Points(param_1,param_2,param_3);
  }
  else {
    FUN_100c50e8(*(undefined4 *)(param_1 + 0x3c),param_2,param_3);
  }
  return;
}


// ==== .CursorRoutine__9TConvModeF5Points @ 1003c1c8 ====
// CyDecompAt: created, body 1003c1c8-1003c1cb

void _CursorRoutine__9TConvModeF5Points(void)

{
  return;
}


// ==== .KeyRoutine__12TInteractionFs @ 1003c200 ====
// CyDecompAt: created, body 1003c200-1003c26b

void _KeyRoutine__12TInteractionFs(int param_1,undefined4 param_2)

{
  if (*(int *)(param_1 + 0x3c) == 0) {
    .debug::_KeyRoutine__15TScriptedWindowFs(param_1,param_2);
  }
  else {
    FUN_100c50e8(*(undefined4 *)(param_1 + 0x3c),param_2);
  }
  return;
}


// ==== .KeyRoutine__9TConvModeFs @ 1003c29c ====
// CyDecompAt: created, body 1003c29c-1003c29f

void _KeyRoutine__9TConvModeFs(void)

{
  return;
}


// ==== .EraseArea__12TInteractionFRC4Rect @ 1003c2cc ====
// CyDecompAt: created, body 1003c2cc-1003c32f

void _EraseArea__12TInteractionFRC4Rect(int param_1,undefined4 param_2)

{
  undefined4 *puVar1;
  
  puVar1 = (undefined4 *).glue::GetGWorldPixMap(*(undefined4 *)(param_1 + 0x44));
  .glue::CopyBits(*puVar1,*(int *)(param_1 + 4) + 2,param_2,param_2,0,0);
  return;
}


// ==== .ClearData__12TInteractionFv @ 1003c364 ====
// CyDecompAt: created, body 1003c364-1003c367

void _ClearData__12TInteractionFv(void)

{
  return;
}


// ==== .ClearData__13TConversationFv @ 1003c398 ====
// CyDecompAt: created, body 1003c398-1003c4b3

void _ClearData__13TConversationFv(int param_1)

{
  undefined4 *puVar1;
  undefined4 uVar2;
  undefined1 auStack_38 [4];
  undefined1 auStack_34 [4];
  undefined1 auStack_30 [4];
  undefined4 uStack_2c;
  undefined1 auStack_28 [8];
  undefined4 auStack_20 [4];
  
  *(undefined2 *)(param_1 + 0x50) = 0;
  *(undefined2 *)(param_1 + 0x452) = 0;
  *(undefined2 *)(param_1 + 0x854) = 0;
  uVar2 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_20);
  .glue::SetPort(uVar2);
  .debug::_ShowTalking__13TConversationFv(param_1);
  .debug::_ShowMessage__13TConversationFv(param_1);
  FUN_100c50e8(param_1,auStack_28);
  uVar2 = *(undefined4 *)(param_1 + 0x44);
  .glue::GetGWorld(auStack_34,auStack_30);
  .glue::SetGWorld(uVar2,0);
  uStack_2c = uVar2;
  puVar1 = (undefined4 *).glue::GetGWorldPixMap(*(undefined4 *)(param_1 + 0x40));
  .debug::_MyCopyBits__12TInteractionFPC6BitMapPC6BitMapPC4RectPC4RectsPP9MacRegion
            (param_1,*puVar1,*(int *)(PTR_DAT_100cdb94 + 0xca) + 2,auStack_28,auStack_28,0,0);
  .debug::___dt__13TBufferGWorldFv(auStack_38,0xffffffff);
  .glue::SetPort(auStack_20[0]);
  return;
}


// ==== .IsJournalable__13TConversationF5Point @ 1003c4e4 ====
// CyDecompAt: created, body 1003c4e4-1003c5ef

undefined4 _IsJournalable__13TConversationF5Point(int param_1,undefined4 param_2)

{
  char cVar1;
  short sStack_18;
  short sStack_16;
  short sStack_14;
  short sStack_12;
  short sStack_10;
  short sStack_e;
  short sStack_c;
  short sStack_a;
  
  *(undefined4 *)PTR_DAT_100ce800 = param_2;
  cVar1 = .glue::EmptyRect(param_1 + 0x858);
  if (cVar1 == '\0') {
    sStack_10 = (short)((uint)*(undefined4 *)(param_1 + 0x858) >> 0x10);
    sStack_a = (short)*(undefined4 *)(param_1 + 0x85c);
    _sStack_10 = CONCAT22(sStack_10,sStack_a);
    _sStack_c = CONCAT22(sStack_10 + 0x18,sStack_a + 0x18);
    cVar1 = .glue::PtInRect(param_2,&sStack_10);
    if (cVar1 != '\0') {
      return 1;
    }
  }
  cVar1 = .glue::EmptyRect(param_1 + 0x860);
  if (cVar1 == '\0') {
    sStack_18 = (short)((uint)*(undefined4 *)(param_1 + 0x860) >> 0x10);
    sStack_12 = (short)*(undefined4 *)(param_1 + 0x864);
    _sStack_18 = CONCAT22(sStack_18,sStack_12);
    _sStack_14 = CONCAT22(sStack_18 + 0x18,sStack_12 + 0x18);
    cVar1 = .glue::PtInRect(param_2,&sStack_18);
    if (cVar1 != '\0') {
      return 2;
    }
  }
  return 0;
}


// ==== .WriteJournal__13TConversationFs @ 1003c628 ====
// CyDecompAt: created, body 1003c628-1003c823

void _WriteJournal__13TConversationFs(int param_1,short param_2)

{
  char cVar1;
  bool bVar2;
  undefined4 uStack_28;
  undefined4 uStack_24;
  undefined4 uStack_20;
  undefined4 uStack_1c;
  undefined4 uStack_18;
  
  if (param_2 == 1) {
    uStack_1c._0_2_ = (short)((uint)*(undefined4 *)(param_1 + 0x858) >> 0x10);
    uStack_18._2_2_ = (short)*(undefined4 *)(param_1 + 0x85c);
  }
  else if (param_2 < 1) {
    if (-1 < param_2) {
      return;
    }
  }
  else if (param_2 < 3) {
    uStack_18._2_2_ = (short)*(undefined4 *)(param_1 + 0x864);
    uStack_1c._0_2_ = (short)((uint)*(undefined4 *)(param_1 + 0x860) >> 0x10);
  }
  uStack_1c = CONCAT22(uStack_1c._0_2_,uStack_18._2_2_);
  uStack_18 = CONCAT22(uStack_1c._0_2_ + 0x18,uStack_18._2_2_ + 0x18);
  uStack_24 = uStack_1c;
  uStack_20 = uStack_18;
  .glue::InsetRect(&uStack_24,4,4);
  bVar2 = false;
  while (cVar1 = .glue::StillDown(), cVar1 != '\0') {
    .glue::GetMouse(&uStack_28);
    cVar1 = .glue::PtInRect(uStack_28,&uStack_1c);
    if (bVar2 != (bool)cVar1) {
      .debug::_DrawButton__FR4RectPUc12eButtonState(&uStack_1c,0,bVar2 == false);
      .debug::_MaskSubIcon__FsssUcUc
                (0x187,(int)uStack_24._2_2_,(int)uStack_24._0_2_,bVar2 == false,0);
      bVar2 = bVar2 == false;
    }
  }
  if (bVar2 != false) {
    .debug::_DrawButton__FR4RectPUc12eButtonState(&uStack_1c,0,0);
    .debug::_MaskSubIcon__FsssUcUc(0x187,(int)uStack_24._2_2_,(int)uStack_24._0_2_,0,0);
    if (param_2 == 2) {
      *(undefined1 *)(param_1 + *(short *)(param_1 + 0x854) + 0x454) = 0;
      .debug::_AddToJournal__8TJournalFPc(param_1 + 0x454);
    }
    else if ((param_2 < 2) && (0 < param_2)) {
      *(undefined1 *)(param_1 + *(short *)(param_1 + 0x452) + 0x52) = 0;
      .debug::_SaidToJournal__8TJournalFsPc
                ((int)*(short *)(param_1 + *(short *)(param_1 + 0xa4e) * 2 + 0xa48),param_1 + 0x52);
    }
  }
  return;
}


// ==== .GetInteractRect__13TConversationFR4Rect @ 1003c858 ====
// CyDecompAt: created, body 1003c858-1003c893

void _GetInteractRect__13TConversationFR4Rect(undefined4 param_1,undefined4 param_2)

{
  .glue::SetRect(param_2,0x74,0xbc,0x200,0x114);
  return;
}


// ==== .GetWorkRect__12TInteractionFR4Rect @ 1003c8d0 ====
// CyDecompAt: created, body 1003c8d0-1003c90b

void _GetWorkRect__12TInteractionFR4Rect(undefined4 param_1,undefined4 param_2)

{
  FUN_100c50e8(param_1,param_2);
  return;
}


// ==== .GetWorkRect__13TConversationFR4Rect @ 1003c944 ====
// CyDecompAt: created, body 1003c944-1003c9a3

void _GetWorkRect__13TConversationFR4Rect(int param_1,undefined4 *param_2)

{
  undefined4 uVar1;
  
  uVar1 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x14);
  *param_2 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x10);
  param_2[1] = uVar1;
  .glue::InsetRect(param_2,0,0);
  *(undefined2 *)((int)param_2 + 2) = 0x68;
  return;
}


// ==== .WantAutoKey__9TConvModeFv @ 1003cb6c ====
// CyDecompAt: created, body 1003cb6c-1003cb73

undefined4 _WantAutoKey__9TConvModeFv(void)

{
  return 1;
}


// ==== .CursorRoutine__13TConvMoreModeF5Points @ 1003cbdc ====
// CyDecompAt: created, body 1003cbdc-1003cc67

void _CursorRoutine__13TConvMoreModeF5Points(int param_1,undefined4 param_2)

{
  short sVar1;
  
  sVar1 = FUN_100c50e8(*(undefined4 *)(param_1 + 4),param_2);
  if (sVar1 == 0) {
    .debug::_ChangeCursor__Fs(0x20);
    .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)PTR_DAT_100cdb98,PTR_s__MORE__100ce7f8);
  }
  else {
    .debug::_ChangeCursor__Fs(0x28);
    .debug::_AutoEye__13TStatusWindowFPc
              (*(undefined4 *)PTR_DAT_100cdb98,PTR_s__Write_To_Journal__100ce7fc);
  }
  return;
}


// ==== .IsJournalable__12TInteractionF5Point @ 1003cca4 ====
// CyDecompAt: created, body 1003cca4-1003ccab

undefined4 _IsJournalable__12TInteractionF5Point(void)

{
  return 0;
}


// ==== .MouseRoutine__13TConvMoreModeF5Points @ 1003cce4 ====
// CyDecompAt: created, body 1003cce4-1003cdc3

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _MouseRoutine__13TConvMoreModeF5Points(int param_1,undefined4 param_2)

{
  undefined4 uVar1;
  char cVar2;
  
  uVar1 = FUN_100c50e8(*(undefined4 *)(param_1 + 4),param_2);
  if ((short)uVar1 == 0) {
    .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)PTR_DAT_100cdb98,PTR_s__MORE__100ce7f8);
    .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(_DAT_100cdd24,6);
    do {
      cVar2 = .glue::StillDown();
    } while (cVar2 != '\0');
    .debug::_Done__9TConvModeFv(param_1);
    .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(_DAT_100cdd24,7);
  }
  else {
    .debug::_ChangeCursor__Fs(0x28);
    .debug::_AutoEye__13TStatusWindowFPc
              (*(undefined4 *)PTR_DAT_100cdb98,PTR_s__Write_To_Journal__100ce7fc);
    FUN_100c50e8(*(undefined4 *)(param_1 + 4),uVar1);
  }
  return;
}


// ==== .WriteJournal__12TInteractionFs @ 1003cdfc ====
// CyDecompAt: created, body 1003cdfc-1003cdff

void _WriteJournal__12TInteractionFs(void)

{
  return;
}


// ==== .KeyRoutine__13TConvMoreModeFs @ 1003ce34 ====
// CyDecompAt: created, body 1003ce34-1003ce7f

void _KeyRoutine__13TConvMoreModeFs(int param_1,short param_2)

{
  if (param_2 == 0x1b) {
    *(undefined1 *)(*(int *)(param_1 + 4) + 0x38) = 1;
  }
  .debug::_Done__9TConvModeFv(param_1);
  return;
}


// ==== .__dt__9TConvModeFv @ 1003cfd8 ====
// CyDecompAt: created, body 1003cfd8-1003d02b

undefined4 * ___dt__9TConvModeFv(undefined4 *param_1,short param_2)

{
  if ((param_1 != (undefined4 *)0x0) && (*param_1 = &PTR_PTR_100d5130, 0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .myprintstr__13TConversationFPcs @ 1003d054 ====
// CyDecompAt: created, body 1003d054-1003d207

void _myprintstr__13TConversationFPcs(int param_1,char *param_2,short param_3)

{
  undefined *puVar1;
  undefined4 uVar2;
  char *pcVar3;
  undefined4 auStack_28 [3];
  
  puVar1 = PTR_DAT_100ce7f4;
  uVar2 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_28);
  .glue::SetPort(uVar2);
  pcVar3 = param_2;
  for (; param_3 != 0; param_3 = param_3 + -1) {
    if (*param_2 == '*') {
      if (*(char *)(param_1 + 0x4c) == '\0') {
        .debug::_AppendMessage__13TConversationFPcs(param_1,pcVar3,param_2 + (-1 - (int)pcVar3));
        .debug::_ShowMessage__13TConversationFv(param_1);
      }
      else {
        .debug::_AppendConv__13TConversationFPcs(param_1,pcVar3,param_2 + (-1 - (int)pcVar3));
        .debug::_ShowTalking__13TConversationFv(param_1);
      }
      .debug::_ConvMore__13TConversationFv(param_1);
      pcVar3 = param_2 + 1;
    }
    else if (*param_2 == '\"') {
      if (*(char *)(param_1 + 0x4c) == '\0') {
        .debug::_AppendMessage__13TConversationFPcs(param_1,pcVar3,(int)param_2 - (int)pcVar3);
        .debug::_ShowMessage__13TConversationFv(param_1);
        *(undefined1 *)(param_1 + 0x4c) = 1;
        pcVar3 = param_2;
      }
      else {
        .debug::_AppendConv__13TConversationFPcs(param_1,pcVar3,(int)param_2 - (int)pcVar3);
        .debug::_AppendConv__13TConversationFPcs(param_1,puVar1,1);
        .debug::_ShowTalking__13TConversationFv(param_1);
        *(undefined1 *)(param_1 + 0x4c) = 0;
        pcVar3 = param_2 + 1;
      }
    }
    param_2 = param_2 + 1;
  }
  if (pcVar3 < param_2) {
    if (*(char *)(param_1 + 0x4c) == '\0') {
      .debug::_AppendMessage__13TConversationFPcs(param_1,pcVar3,(int)param_2 - (int)pcVar3);
    }
    else {
      .debug::_AppendConv__13TConversationFPcs(param_1,pcVar3,(int)param_2 - (int)pcVar3);
    }
  }
  .glue::SetPort(auStack_28[0]);
  return;
}


// ==== .ForceOut__13TConversationFv @ 1003dfd4 ====
// CyDecompAt: created, body 1003dfd4-1003e037

void _ForceOut__13TConversationFv(int param_1)

{
  if (*(char *)(param_1 + 0x4f) == '\0') {
    if (*(char *)(param_1 + 0x4d) == '\0') {
      .debug::_ShowTalking__13TConversationFv(param_1);
    }
    if (*(char *)(param_1 + 0x4e) == '\0') {
      .debug::_ShowMessage__13TConversationFv(param_1);
    }
  }
  *(undefined1 *)(param_1 + 0x4c) = 0;
  return;
}


// ==== .DrawRoutine__17TConvResponseModeFv @ 1003e17c ====
// CyDecompAt: created, body 1003e17c-1003e33f

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DrawRoutine__17TConvResponseModeFv(int param_1)

{
  int iVar1;
  undefined *puVar2;
  undefined *puVar3;
  uint uVar4;
  uint uVar5;
  short sVar7;
  int iVar6;
  short sVar8;
  undefined4 uStack_28;
  undefined4 uStack_24;
  
  puVar3 = PTR_DAT_100ce7f0;
  puVar2 = PTR_DAT_100ce7ec;
  iVar1 = _DAT_100cdb90;
  if (*(short *)(param_1 + 0x18) != 0) {
    for (sVar8 = 0; sVar8 < *(short *)(param_1 + 0x18); sVar8 = sVar8 + 1) {
      .debug::_SetText__Fs(6);
      uVar4 = (uint)*(short *)(iVar1 + 0x30);
      uVar5 = (int)*(short *)(*(int *)(param_1 + 0x20) + sVar8 * 8) +
              (int)*(short *)(*(int *)(param_1 + 0x20) + sVar8 * 8 + 4);
      .debug::_DrawTextOutlined__12TTextContextFssPcsll
                ((int)*(short *)(*(int *)(param_1 + 0x20) + sVar8 * 8 + 2),
                 (int)(short)((short)((int)uVar5 >> 1) +
                             (ushort)((int)uVar5 < 0 && (uVar5 & 1) != 0)) +
                 ((int)uVar4 >> 1) + (uint)((int)uVar4 < 0 && (uVar4 & 1) != 0),puVar3,2,0x45,0x21);
      sVar7 = FUN_100b6ce8(*(undefined4 *)(*(int *)(param_1 + 0x1c) + sVar8 * 4));
      iVar6 = .glue::StringWidth(puVar2);
      uVar5 = (uint)*(short *)(iVar1 + 0x30);
      uVar4 = (int)*(short *)(*(int *)(param_1 + 0x20) + sVar8 * 8) +
              (int)*(short *)(*(int *)(param_1 + 0x20) + sVar8 * 8 + 4);
      .debug::_DrawTextOutlined__12TTextContextFssPcsll
                (*(short *)(*(int *)(param_1 + 0x20) + sVar8 * 8 + 2) + iVar6,
                 (int)(short)((short)((int)uVar4 >> 1) +
                             (ushort)((int)uVar4 < 0 && (uVar4 & 1) != 0)) +
                 ((int)uVar5 >> 1) + (uint)((int)uVar5 < 0 && (uVar5 & 1) != 0),
                 *(undefined4 *)(*(int *)(param_1 + 0x1c) + sVar8 * 4),(int)sVar7,0x45,0x21);
    }
  }
  if (*(int *)(param_1 + 0xc) != 0) {
    uStack_28 = *(undefined4 *)(**(int **)(param_1 + 0xc) + 8);
    uStack_24 = *(undefined4 *)(**(int **)(param_1 + 0xc) + 0xc);
    .glue::EraseRect(&uStack_28);
    .glue::TEUpdate(param_1 + 0x10,*(undefined4 *)(param_1 + 0xc));
  }
  return;
}


// ==== .MouseRoutine__17TConvResponseModeF5Points @ 1003e378 ====
// CyDecompAt: created, body 1003e378-1003e6c3

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _MouseRoutine__17TConvResponseModeF5Points(int param_1,undefined4 param_2,ushort param_3)

{
  int iVar1;
  undefined4 uVar2;
  undefined *puVar3;
  undefined *puVar4;
  uint uVar5;
  char cVar9;
  short sVar8;
  int iVar6;
  undefined4 uVar7;
  uint uVar10;
  bool bVar11;
  short sVar12;
  
  puVar4 = PTR_DAT_100ce7f0;
  puVar3 = PTR_DAT_100ce7ec;
  uVar2 = _DAT_100cdd24;
  iVar1 = _DAT_100cdb90;
  cVar9 = .glue::PtInRect(param_2,param_1 + 0x10);
  if ((cVar9 != '\0') && (*(int *)(param_1 + 0xc) != 0)) {
    .glue::ClipRect(param_1 + 0x10);
    .glue::TEClick(param_2,param_3 & 0x200,*(undefined4 *)(param_1 + 0xc));
    .glue::ClipRect(*(int *)(PTR_DAT_100cdb94 + 0xca) + 0x10);
    return;
  }
  .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(uVar2,6);
  bVar11 = false;
  sVar12 = 0;
  while( true ) {
    if (*(short *)(param_1 + 0x18) <= sVar12) goto LAB_1003e634;
    cVar9 = .glue::PtInRect(param_2,*(int *)(param_1 + 0x20) + sVar12 * 8);
    if (cVar9 != '\0') break;
    sVar12 = sVar12 + 1;
  }
  bVar11 = false;
  do {
    cVar9 = .glue::PtInRect(param_2,*(int *)(param_1 + 0x20) + sVar12 * 8);
    if (bVar11 != (bool)cVar9) {
      uVar10 = (uint)*(short *)(iVar1 + 0x30);
      uVar5 = (int)*(short *)(*(int *)(param_1 + 0x20) + sVar12 * 8) +
              (int)*(short *)(*(int *)(param_1 + 0x20) + sVar12 * 8 + 4);
      bVar11 = bVar11 == false;
      if (bVar11) {
        uVar7 = 0xcd;
      }
      else {
        uVar7 = 0x45;
      }
      .debug::_DrawTextOutlined__12TTextContextFssPcsll
                ((int)*(short *)(*(int *)(param_1 + 0x20) + sVar12 * 8 + 2),
                 (int)(short)((short)((int)uVar5 >> 1) +
                             (ushort)((int)uVar5 < 0 && (uVar5 & 1) != 0)) +
                 ((int)uVar10 >> 1) + (uint)((int)uVar10 < 0 && (uVar10 & 1) != 0),puVar4,2,uVar7,
                 0x21);
      sVar8 = FUN_100b6ce8(*(undefined4 *)(*(int *)(param_1 + 0x1c) + sVar12 * 4));
      iVar6 = .glue::StringWidth(puVar3);
      uVar5 = (uint)*(short *)(iVar1 + 0x30);
      uVar10 = (int)*(short *)(*(int *)(param_1 + 0x20) + sVar12 * 8) +
               (int)*(short *)(*(int *)(param_1 + 0x20) + sVar12 * 8 + 4);
      if (bVar11) {
        uVar7 = 0xcd;
      }
      else {
        uVar7 = 0x45;
      }
      .debug::_DrawTextOutlined__12TTextContextFssPcsll
                (*(short *)(*(int *)(param_1 + 0x20) + sVar12 * 8 + 2) + iVar6,
                 (int)(short)((short)((int)uVar10 >> 1) +
                             (ushort)((int)uVar10 < 0 && (uVar10 & 1) != 0)) +
                 ((int)uVar5 >> 1) + (uint)((int)uVar5 < 0 && (uVar5 & 1) != 0),
                 *(undefined4 *)(*(int *)(param_1 + 0x1c) + sVar12 * 4),(int)sVar8,uVar7,0x21);
    }
    .glue::GetMouse(&stack0x0000001c);
    cVar9 = .glue::StillDown();
  } while (cVar9 != '\0');
  if (bVar11 != false) {
    **(short **)(param_1 + 0x30) = sVar12;
    if (*(short *)(param_1 + 0x2c) != 0) {
      FUN_100b6d08(*(undefined4 *)(param_1 + 0x28),
                   *(undefined4 *)(*(int *)(param_1 + 0x1c) + sVar12 * 4));
    }
    .debug::_Done__9TConvModeFv(param_1);
  }
  bVar11 = true;
LAB_1003e634:
  if ((!bVar11) && (uVar7 = FUN_100c50e8(*(undefined4 *)(param_1 + 4),param_2), (short)uVar7 != 0))
  {
    .debug::_ChangeCursor__Fs(0x28);
    FUN_100c50e8(*(undefined4 *)(param_1 + 4),uVar7);
    bVar11 = true;
  }
  .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(uVar2,7);
  if (bVar11) {
    return;
  }
  .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(uVar2,0);
  return;
}


// ==== .IdleRoutine__17TConvResponseModeFv @ 1003e700 ====
// CyDecompAt: created, body 1003e700-1003e73f

void _IdleRoutine__17TConvResponseModeFv(int param_1)

{
  if (*(int *)(param_1 + 0xc) != 0) {
    .glue::TEIdle(*(undefined4 *)(param_1 + 0xc));
  }
  return;
}


// ==== .CursorRoutine__17TConvResponseModeF5Points @ 1003e778 ====
// CyDecompAt: created, body 1003e778-1003e8ab

void _CursorRoutine__17TConvResponseModeF5Points(int param_1,undefined4 param_2)

{
  bool bVar1;
  char cVar3;
  short sVar2;
  
  if ((*(int *)(param_1 + 0xc) != 0) &&
     (cVar3 = .glue::PtInRect(param_2,param_1 + 0x10), cVar3 != '\0')) {
    .debug::_ChangeCursor__Fs(0x2d);
    return;
  }
  bVar1 = false;
  sVar2 = 0;
  do {
    if (*(short *)(param_1 + 0x18) <= sVar2) {
LAB_1003e824:
      if (!bVar1) {
        sVar2 = FUN_100c50e8(*(undefined4 *)(param_1 + 4),param_2);
        if (sVar2 == 0) {
          .debug::_ChangeCursor__Fs(0x2b);
          .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)PTR_DAT_100cdb98,0);
        }
        else {
          .debug::_ChangeCursor__Fs(0x28);
          .debug::_AutoEye__13TStatusWindowFPc
                    (*(undefined4 *)PTR_DAT_100cdb98,PTR_s__Write_To_Journal__100ce7fc);
        }
      }
      return;
    }
    cVar3 = .glue::PtInRect(param_2,*(int *)(param_1 + 0x20) + sVar2 * 8);
    if (cVar3 != '\0') {
      .debug::_ChangeCursor__Fs(0x20);
      bVar1 = true;
      goto LAB_1003e824;
    }
    sVar2 = sVar2 + 1;
  } while( true );
}


// ==== .KeyRoutine__17TConvResponseModeFs @ 1003e8ec ====
// CyDecompAt: created, body 1003e8ec-1003ebf7

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _KeyRoutine__17TConvResponseModeFs(int param_1,uint param_2)

{
  int iVar1;
  undefined *puVar2;
  undefined *puVar3;
  ushort uVar5;
  uint uVar4;
  undefined4 *puVar6;
  int iVar7;
  uint uVar8;
  short sVar9;
  short sVar10;
  undefined1 uStack_38;
  undefined1 uStack_37;
  
  puVar3 = PTR_DAT_100ce7f0;
  puVar2 = PTR_DAT_100ce7ec;
  iVar1 = _DAT_100cdb90;
  if ((short)param_2 == -1) {
    uVar5 = 0xffff;
  }
  else {
    uVar5 = (ushort)(byte)(&DAT_100d8a86)[param_2 & 0xff];
  }
  if ((uVar5 == 0xd) || (((short)uVar5 < 0xd && (uVar5 == 3)))) {
    if (*(int *)(param_1 + 0xc) != 0) {
      puVar6 = (undefined4 *).glue::TEGetText(*(undefined4 *)(param_1 + 0xc));
      .glue::BlockMove(*puVar6,*(undefined4 *)(param_1 + 0x28),(int)*(short *)(param_1 + 0x2c));
      if (*(short *)(**(int **)(param_1 + 0xc) + 0x3c) < *(short *)(param_1 + 0x2c)) {
        *(undefined1 *)
         (*(int *)(param_1 + 0x28) + (int)*(short *)(**(int **)(param_1 + 0xc) + 0x3c)) = 0;
      }
      .debug::_Done__9TConvModeFv(param_1);
    }
  }
  else {
    uStack_38 = (undefined1)uVar5;
    uStack_37 = 0;
    if (((*(int *)(param_1 + 0x24) == 0) ||
        (iVar7 = FUN_100b6e38(&uStack_38,*(undefined4 *)(param_1 + 0x24)), iVar7 != 0)) ||
       ((uVar5 == 8 && (*(int *)(param_1 + 0xc) != 0)))) {
      if (*(int *)(param_1 + 0xc) == 0) {
        if ((*(int *)(param_1 + 0x24) != 0) && (*(short *)(param_1 + 0x18) != 0)) {
          for (sVar10 = 0; sVar10 < *(short *)(param_1 + 0x18); sVar10 = sVar10 + 1) {
            if ((int)(short)uVar5 == (int)*(char *)(*(int *)(param_1 + 0x24) + (int)sVar10)) {
              uVar4 = (uint)*(short *)(iVar1 + 0x30);
              uVar8 = (int)*(short *)(*(int *)(param_1 + 0x20) + sVar10 * 8) +
                      (int)*(short *)(*(int *)(param_1 + 0x20) + sVar10 * 8 + 4);
              .debug::_DrawTextOutlined__12TTextContextFssPcsll
                        ((int)*(short *)(*(int *)(param_1 + 0x20) + sVar10 * 8 + 2),
                         (int)(short)((short)((int)uVar8 >> 1) +
                                     (ushort)((int)uVar8 < 0 && (uVar8 & 1) != 0)) +
                         ((int)uVar4 >> 1) + (uint)((int)uVar4 < 0 && (uVar4 & 1) != 0),puVar3,2,
                         0xcd,0x21);
              sVar9 = FUN_100b6ce8(*(undefined4 *)(*(int *)(param_1 + 0x1c) + sVar10 * 4));
              iVar7 = .glue::StringWidth(puVar2);
              uVar8 = (uint)*(short *)(iVar1 + 0x30);
              uVar4 = (int)*(short *)(*(int *)(param_1 + 0x20) + sVar10 * 8) +
                      (int)*(short *)(*(int *)(param_1 + 0x20) + sVar10 * 8 + 4);
              .debug::_DrawTextOutlined__12TTextContextFssPcsll
                        (*(short *)(*(int *)(param_1 + 0x20) + sVar10 * 8 + 2) + iVar7,
                         (int)(short)((short)((int)uVar4 >> 1) +
                                     (ushort)((int)uVar4 < 0 && (uVar4 & 1) != 0)) +
                         ((int)uVar8 >> 1) + (uint)((int)uVar8 < 0 && (uVar8 & 1) != 0),
                         *(undefined4 *)(*(int *)(param_1 + 0x1c) + sVar10 * 4),(int)sVar9,0xcd,0x21
                        );
              **(short **)(param_1 + 0x30) = sVar10;
              .debug::_Done__9TConvModeFv(param_1);
              return;
            }
          }
        }
      }
      else {
        .glue::ClipRect(param_1 + 0x10);
        .glue::TEKey(*(uint *)(*(int *)PTR_DAT_100cdb84 + 6) & 0xff,*(undefined4 *)(param_1 + 0xc));
        .glue::ClipRect(*(int *)(PTR_DAT_100cdb94 + 0xca) + 0x10);
      }
    }
    else {
      .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(_DAT_100cdd24,0);
    }
  }
  return;
}


// ==== .mygets__13TConversationFPcsUc @ 1003f314 ====
// CyDecompAt: created, body 1003f314-1003f4ab

void _mygets__13TConversationFPcsUc(int param_1,char *param_2,undefined4 param_3,char param_4)

{
  char cVar1;
  int iVar2;
  short sVar3;
  short sVar4;
  undefined4 auStack_68 [20];
  
  FUN_100c50e8();
  if (param_4 == '\0') {
    .debug::_GetResponse__12TInteractionFPcPcsPPcs(param_1,param_2,0,param_3,0,0);
  }
  else {
    iVar2 = 0;
    for (sVar4 = 0; sVar4 < 100; sVar4 = sVar4 + 1) {
      if ((*(int *)(param_1 + sVar4 * 4 + 0x8b8) != 0) &&
         (*(int *)(param_1 + sVar4 * 4 + 0x8b8) != -1)) {
        iVar2 = iVar2 + 1;
        sVar3 = (short)iVar2;
        auStack_68[0x14 - sVar3] = *(undefined4 *)(param_1 + sVar4 * 4 + 0x8b8);
        cVar1 = *(char *)auStack_68[0x14 - sVar3];
        if (('`' < cVar1) && (cVar1 < '{')) {
          cVar1 = cVar1 + -0x20;
        }
        *(char *)auStack_68[0x14 - sVar3] = cVar1;
        if (sVar3 == 0x14) break;
      }
    }
    .debug::_GetResponse__12TInteractionFPcPcsPPcs
              (param_1,param_2,0,param_3,&stack0xffffffe8 + (short)iVar2 * -4,iVar2);
    if (*param_2 != '\0') {
      .debug::_RemoveAnswer__13TConversationFPc(param_1,param_2);
    }
  }
  return;
}


// ==== .mygetch__13TConversationFPc @ 1003f4dc ====
// CyDecompAt: created, body 1003f4dc-1003f61f

undefined1 _mygetch__13TConversationFPc(undefined4 param_1,int param_2)

{
  char cVar1;
  short sVar3;
  int iVar2;
  int iVar4;
  char acStack_98 [8];
  undefined1 auStack_90 [36];
  undefined *apuStack_6c [22];
  
  FUN_100c50e8();
  sVar3 = FUN_100b6ce8(param_2);
  iVar4 = (int)sVar3;
  if (0x14 < sVar3) {
    .glue::SysBeep(1);
    iVar4 = 0x14;
  }
  iVar2 = FUN_100b6d94(param_2,PTR_DAT_100ce7e4);
  if (iVar2 == 0) {
    apuStack_6c[0] = PTR_DAT_100ce7e0;
    apuStack_6c[1] = PTR_DAT_100ce7dc;
  }
  else {
    for (sVar3 = 0; sVar3 < (short)iVar4; sVar3 = sVar3 + 1) {
      apuStack_6c[sVar3] = auStack_90;
      cVar1 = *(char *)(param_2 + sVar3);
      if (('`' < cVar1) && (cVar1 < '{')) {
        cVar1 = cVar1 + -0x20;
      }
      acStack_98[sVar3 * 2] = cVar1;
      acStack_98[sVar3 * 2 + 1] = '\0';
    }
  }
  sVar3 = .debug::_GetResponse__12TInteractionFPcPcsPPcs(param_1,0,param_2,0,apuStack_6c,iVar4);
  return *(undefined1 *)(param_2 + sVar3);
}


// ==== .mygetnum__13TConversationFv @ 1003f650 ====
// CyDecompAt: created, body 1003f650-1003f6ef

int _mygetnum__13TConversationFv(undefined4 param_1)

{
  char *pcVar1;
  int iVar2;
  char acStack_28 [15];
  undefined1 uStack_19;
  
  FUN_100c50e8();
  .debug::_GetResponse__12TInteractionFPcPcsPPcs
            (param_1,acStack_28,PTR_s_0123456789_100ce7d8,0xf,0,0);
  uStack_19 = 0;
  pcVar1 = acStack_28;
  iVar2 = 0;
  while( true ) {
    if (*pcVar1 == '\0') break;
    iVar2 = (int)*pcVar1 + iVar2 * 10 + -0x30;
    pcVar1 = pcVar1 + 1;
  }
  return iVar2;
}


// ==== .ForceOut__12TInteractionFv @ 1003f878 ====
// CyDecompAt: created, body 1003f878-1003f87b

void _ForceOut__12TInteractionFv(void)

{
  return;
}


// ==== .__dt__9TPickModeFv @ 1003faf0 ====
// CyDecompAt: created, body 1003faf0-1003fb9b

undefined4 * ___dt__9TPickModeFv(undefined4 *param_1,short param_2)

{
  undefined1 auStack_18 [20];
  
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d509c;
    FUN_100c50e8(param_1[1],auStack_18);
    FUN_100c50e8(param_1[1],auStack_18);
    if (param_1[9] != 0) {
      .glue::DisposeControl(param_1[9]);
    }
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d5130;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .DrawRoutine__9TPickModeFv @ 1003fd3c ====
// CyDecompAt: created, body 1003fd3c-1003ffcf

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DrawRoutine__9TPickModeFv(int param_1)

{
  uint uVar1;
  short sVar3;
  short sVar4;
  undefined4 uVar2;
  int iVar5;
  char acStack_129 [257];
  short sStack_28;
  short sStack_26;
  undefined4 uStack_24;
  undefined1 auStack_20 [2];
  short sStack_1e;
  undefined4 uStack_1c;
  
  FUN_100c50e8(*(undefined4 *)(param_1 + 4),auStack_20);
  FUN_100c50e8(*(undefined4 *)(param_1 + 4),&sStack_28);
  if (*(int *)(param_1 + 0x24) != 0) {
    uStack_24 = CONCAT22(uStack_24._0_2_,uStack_24._2_2_ + -0x10);
  }
  FUN_100c50e8(*(undefined4 *)(param_1 + 4),&sStack_28);
  .debug::_DrawTheList__9TPickModeFv(param_1);
  if (*(int *)(param_1 + 0x24) != 0) {
    .glue::Draw1Control(*(undefined4 *)(param_1 + 0x24));
  }
  _sStack_28 = CONCAT22(0x14,sStack_26);
  uStack_24 = CONCAT22(*(short *)(param_1 + 0x1c) + 0x14,uStack_24._2_2_);
  sVar3 = FUN_100b6ce8(*(undefined4 *)(param_1 + 0x20));
  sVar4 = FUN_100b6ce8(*(undefined4 *)(param_1 + 0x20));
  uVar2 = .glue::TextWidth(*(undefined4 *)(param_1 + 0x20),0,(int)sVar4);
  uVar1 = (int)sStack_26 + (int)uStack_24._2_2_;
  uVar2 = .debug::_Justify__12TTextContextFsss
                    ((int)(short)((short)((int)uVar1 >> 1) +
                                 (ushort)((int)uVar1 < 0 && (uVar1 & 1) != 0)),uVar2,1);
  uVar1 = (uint)*(short *)(_DAT_100cdb90 + 0x30);
  .debug::_DrawTextOutlined__12TTextContextFssPcsll
            (uVar2,((int)uVar1 >> 1) + (uint)((int)uVar1 < 0 && (uVar1 & 1) != 0) + 10,
             *(undefined4 *)(param_1 + 0x20),(int)sVar3,0x45,0x21);
  uStack_24 = uStack_1c;
  uVar2 = uStack_24;
  uStack_24._0_2_ = (short)((uint)uStack_1c >> 0x10);
  uStack_24._2_2_ = (short)uStack_1c;
  iVar5 = ((int)uStack_24._2_2_ - (int)sStack_1e) + -0x18;
  iVar5 = iVar5 / 5 + (iVar5 >> 0x1f);
  sVar3 = (short)iVar5 - (short)(iVar5 >> 0x1f);
  _sStack_28 = CONCAT22(uStack_24._0_2_ + -0x20,uStack_24._2_2_ - sVar3);
  uStack_24 = uVar2;
  for (sVar4 = 0; sVar4 < *(short *)(param_1 + 0x10); sVar4 = sVar4 + 1) {
    acStack_129[1] = FUN_100b6ce8(*(undefined4 *)(*(int *)(param_1 + 0x18) + sVar4 * 4));
    uVar2 = FUN_100b6ce8(*(undefined4 *)(*(int *)(param_1 + 0x18) + sVar4 * 4));
    FUN_100b4104(acStack_129 + 2,*(undefined4 *)(*(int *)(param_1 + 0x18) + sVar4 * 4),uVar2);
    for (; (2 < (byte)acStack_129[1] && (acStack_129[(byte)acStack_129[1]] == '/'));
        acStack_129[1] = acStack_129[1] - 2) {
    }
    .debug::_DrawButton__FR4RectPUc12eButtonState(&sStack_28,acStack_129 + 1,0);
    .glue::OffsetRect(&sStack_28,-6 - sVar3,0);
  }
  return;
}


// ==== .KeyRoutine__9TPickModeFs @ 1003fffc ====
// CyDecompAt: created, body 1003fffc-100401d3

void _KeyRoutine__9TPickModeFs(int param_1,ushort param_2)

{
  int iVar1;
  undefined4 uVar2;
  short sVar3;
  char acStack_129 [257];
  short sStack_28;
  short sStack_26;
  short sStack_24;
  undefined4 uStack_22;
  undefined1 auStack_1e [2];
  short sStack_1c;
  undefined4 uStack_1a;
  
  FUN_100c50e8(*(undefined4 *)(param_1 + 4),auStack_1e);
  uStack_22 = uStack_1a;
  uVar2 = uStack_22;
  uStack_22._0_2_ = (short)((uint)uStack_1a >> 0x10);
  _sStack_26 = CONCAT22(uStack_22._0_2_ + -0x20,sStack_1c);
  uStack_22._2_2_ = (short)uStack_1a;
  iVar1 = ((int)uStack_22._2_2_ - (int)sStack_1c) + -0x18;
  iVar1 = iVar1 / 5 + (iVar1 >> 0x1f);
  sStack_28 = (short)iVar1 - (short)(iVar1 >> 0x1f);
  if ((0x40 < (short)param_2) && ((short)param_2 < 0x5b)) {
    param_2 = param_2 + 0x20;
  }
  sVar3 = 0;
  uStack_22 = uVar2;
  do {
    if (*(short *)(param_1 + 0x10) <= sVar3) {
      return;
    }
    acStack_129[1] = FUN_100b6ce8(*(undefined4 *)(*(int *)(param_1 + 0x18) + sVar3 * 4));
    uVar2 = FUN_100b6ce8(*(undefined4 *)(*(int *)(param_1 + 0x18) + sVar3 * 4));
    FUN_100b4104(acStack_129 + 2,*(undefined4 *)(*(int *)(param_1 + 0x18) + sVar3 * 4),uVar2);
    while ((2 < (byte)acStack_129[1] && (acStack_129[(byte)acStack_129[1]] == '/'))) {
      if (param_2 == (byte)acStack_129[(byte)acStack_129[1] + 1]) {
        for (; (2 < (byte)acStack_129[1] && (acStack_129[(byte)acStack_129[1]] == '/'));
            acStack_129[1] = acStack_129[1] - 2) {
        }
        .debug::_DrawButton__FR4RectPUc12eButtonState(&sStack_26,acStack_129 + 1,4);
        **(short **)(param_1 + 0xc) = -(sVar3 + 1);
        .debug::_Done__9TConvModeFv(param_1);
        return;
      }
    }
    sVar3 = sVar3 + 1;
  } while( true );
}


// ==== .MouseRoutine__9TPickModeF5Points @ 10040200 ====
// CyDecompAt: created, body 10040200-10040887

void _MouseRoutine__9TPickModeF5Points(int param_1,undefined4 param_2)

{
  short sVar3;
  short sVar4;
  short sVar5;
  int iVar1;
  char cVar6;
  undefined4 uVar2;
  uint uVar7;
  int iVar8;
  int iVar9;
  undefined4 *puVar10;
  bool bVar11;
  undefined1 uStack_184;
  undefined1 auStack_183 [255];
  short sStack_84;
  int *piStack_80;
  undefined2 uStack_7c;
  short sStack_7a;
  short sStack_78;
  undefined4 uStack_76;
  undefined4 uStack_72;
  undefined4 uStack_6e;
  undefined4 uStack_6a;
  short asStack_66 [2];
  short sStack_62;
  int *piStack_60;
  short sStack_5c;
  short sStack_5a;
  undefined4 uStack_58;
  undefined1 auStack_54 [2];
  short sStack_52;
  undefined4 uStack_50;
  
  FUN_100c50e8(*(undefined4 *)(param_1 + 4),auStack_54);
  FUN_100c50e8(*(undefined4 *)(param_1 + 4),&sStack_5c);
  if (*(int *)(param_1 + 0x24) != 0) {
    uStack_58._2_2_ = uStack_58._2_2_ + -0x10;
  }
  sStack_5c = 0x14;
  uStack_58._0_2_ = uStack_50._0_2_ + -0x20;
  sVar3 = .glue::FindControl(param_2,*(undefined4 *)(*(int *)(param_1 + 4) + 4),&piStack_60);
  if (((sVar3 == 0) || (*(int *)(param_1 + 0x24) == 0)) || (piStack_60 != *(int **)(param_1 + 0x24))
     ) {
    uStack_58 = CONCAT22(sStack_5c + *(short *)(param_1 + 0x1c),uStack_58._2_2_);
    sVar3 = *(short *)(param_1 + 0x28);
    for (puVar10 = (undefined4 *)
                   (*(int *)(*(int *)(param_1 + 0x14) + 8) + *(short *)(param_1 + 0x28) * 4);
        puVar10 !=
        (undefined4 *)
        (*(int *)(*(int *)(param_1 + 0x14) + 8) + *(int *)(*(int *)(param_1 + 0x14) + 4) * 4);
        puVar10 = puVar10 + 1) {
      cVar6 = .glue::PtInRect(param_2,&sStack_5c);
      if (cVar6 != '\0') {
        FUN_100c50e8(*puVar10,&sStack_5c,1);
        bVar11 = true;
        while (cVar6 = .glue::StillDown(), cVar6 != '\0') {
          cVar6 = .glue::PtInRect(param_2,&sStack_5c);
          if (bVar11 != (bool)cVar6) {
            bVar11 = bVar11 == false;
            FUN_100c50e8(*puVar10,&sStack_5c,bVar11);
          }
          .glue::GetMouse(&stack0x0000001c);
        }
        if (bVar11 != false) {
          FUN_100c50e8(*puVar10,&sStack_5c,0);
          **(short **)(param_1 + 0xc) = sVar3;
          .debug::_Done__9TConvModeFv(param_1);
          return;
        }
      }
      sVar3 = sVar3 + 1;
      .glue::OffsetRect(&sStack_5c,0,*(short *)(param_1 + 0x1c) + 4);
      if (uStack_50._0_2_ + -0x20 < (int)uStack_58._0_2_) break;
    }
    uStack_58 = uStack_50;
    uVar2 = uStack_58;
    uStack_58._0_2_ = (short)((uint)uStack_50 >> 0x10);
    uStack_58._2_2_ = (short)uStack_50;
    iVar8 = ((int)uStack_58._2_2_ - (int)sStack_52) + -0x18;
    iVar8 = iVar8 / 5 + (iVar8 >> 0x1f);
    sStack_84 = (short)iVar8 - (short)(iVar8 >> 0x1f);
    _sStack_5c = CONCAT22(uStack_58._0_2_ + -0x20,uStack_58._2_2_ - sStack_84);
    uStack_58 = uVar2;
    for (sVar3 = 0; sVar3 < *(short *)(param_1 + 0x10); sVar3 = sVar3 + 1) {
      cVar6 = .glue::PtInRect(param_2,&sStack_5c);
      if (cVar6 != '\0') {
        uStack_184 = FUN_100b6ce8(*(undefined4 *)(*(int *)(param_1 + 0x18) + sVar3 * 4));
        uVar2 = FUN_100b6ce8(*(undefined4 *)(*(int *)(param_1 + 0x18) + sVar3 * 4));
        FUN_100b4104(auStack_183,*(undefined4 *)(*(int *)(param_1 + 0x18) + sVar3 * 4),uVar2);
        .debug::_DrawButton__FR4RectPUc12eButtonState(&sStack_5c,&uStack_184,1);
        bVar11 = true;
        while (cVar6 = .glue::StillDown(), cVar6 != '\0') {
          cVar6 = .glue::PtInRect(param_2,&sStack_5c);
          if (bVar11 != (bool)cVar6) {
            .debug::_DrawButton__FR4RectPUc12eButtonState(&sStack_5c,&uStack_184,bVar11 == false);
            bVar11 = bVar11 == false;
          }
          .glue::GetMouse(&stack0x0000001c);
        }
        if (bVar11 != false) {
          .debug::_DrawButton__FR4RectPUc12eButtonState(&sStack_5c,&uStack_184,1);
          **(short **)(param_1 + 0xc) = -(sVar3 + 1);
          .debug::_Done__9TConvModeFv(param_1);
          return;
        }
      }
      .glue::OffsetRect(&sStack_5c,-6 - sStack_84,0);
    }
  }
  else {
    sStack_62 = (short)(((int)uStack_58._0_2_ - (int)sStack_5c) / (int)*(short *)(param_1 + 0x1c));
    if (sVar3 == 0x17) {
      iVar8 = sStack_62 + -1;
    }
    else {
      if (0x16 < sVar3) {
        if (sVar3 != 0x81) {
          return;
        }
        uStack_76 = *(undefined4 *)(*piStack_60 + 8);
        uStack_72 = *(undefined4 *)(*piStack_60 + 0xc);
        uStack_6e = uStack_76;
        uStack_6a = uStack_72;
        .glue::InsetRect(&uStack_76,0xfffffff0,0xfffffff0);
        sVar3 = (uStack_6a._0_2_ - uStack_6e._0_2_) + -0x30;
        sStack_78 = .glue::GetControlMaximum(piStack_60);
        iVar8 = .glue::GetControlMinimum(piStack_60);
        sStack_7a = sStack_78 - (short)iVar8;
        uStack_7c = .glue::GetControlValue(piStack_60);
        while (cVar6 = .glue::StillDown(), cVar6 != '\0') {
          .glue::GetMouse(asStack_66);
          sVar4 = .glue::GetControlValue(piStack_60);
          sVar5 = asStack_66[0] - (uStack_6e._0_2_ + 0x18);
          if (sVar5 < 0) {
            sVar5 = 0;
          }
          if (sVar3 < sVar5) {
            sVar5 = sVar3;
          }
          uVar7 = (uint)sVar3;
          iVar1 = iVar8 + (int)(((int)uVar7 >> 1) + (uint)((int)uVar7 < 0 && (uVar7 & 1) != 0) +
                               (int)sVar5 * (int)sStack_7a) / (int)sVar3;
          sVar5 = (short)iVar1;
          if (sVar5 != sVar4) {
            .glue::SetControlValue(piStack_60,iVar1);
            *(short *)(param_1 + 0x28) = sVar5;
            .debug::_DrawTheList__9TPickModeFv(param_1);
          }
        }
        return;
      }
      if (sVar3 == 0x15) {
        iVar8 = 1;
      }
      else if (sVar3 < 0x15) {
        if (sVar3 < 0x14) {
          return;
        }
        iVar8 = -1;
      }
      else {
        iVar8 = (int)(short)-(sStack_62 + -1);
      }
    }
    while (cVar6 = .glue::StillDown(), cVar6 != '\0') {
      sVar5 = .glue::FindControl(param_2,*(undefined4 *)(*(int *)(param_1 + 4) + 4),&piStack_80);
      if ((sVar3 == sVar5) && (piStack_80 == piStack_60)) {
        iVar1 = .glue::GetControlValue(piStack_60);
        iVar9 = iVar1 + iVar8;
        if ((short)iVar9 < 0) {
          iVar9 = 0;
        }
        sVar5 = .glue::GetControlMaximum(piStack_60);
        if (sVar5 < (short)iVar9) {
          iVar9 = .glue::GetControlMaximum(piStack_60);
        }
        if ((short)iVar9 != (short)iVar1) {
          .glue::SetControlValue(piStack_60,iVar9);
          *(short *)(param_1 + 0x28) = (short)iVar9;
          .debug::_DrawTheList__9TPickModeFv(param_1);
        }
      }
    }
  }
  return;
}


// ==== .GetInteractRect__18TSimpleInteractionFR4Rect @ 10041088 ====
// CyDecompAt: created, body 10041088-100410d3

void _GetInteractRect__18TSimpleInteractionFR4Rect(int param_1,undefined4 param_2)

{
  .glue::SetRect(param_2,0,0x14,(int)*(short *)(param_1 + 0x4c),*(short *)(param_1 + 0x4e) + 0x14);
  return;
}


// ==== .__dt__12THowManyModeFv @ 10041500 ====
// CyDecompAt: created, body 10041500-1004159b

undefined4 * ___dt__12THowManyModeFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d4e98;
    .glue::DisposeControl(param_1[6]);
    .glue::DisposeControl(param_1[8]);
    .glue::DisposeControl(param_1[9]);
    .glue::ValidRect(*(int *)(param_1[1] + 4) + 0x10);
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d5130;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .DrawRoutine__12THowManyModeFv @ 100415c8 ====
// CyDecompAt: created, body 100415c8-10041613

void _DrawRoutine__12THowManyModeFv(int param_1)

{
  .glue::Draw1Control(*(undefined4 *)(param_1 + 0x18));
  .glue::Draw1Control(*(undefined4 *)(param_1 + 0x20));
  .glue::Draw1Control(*(undefined4 *)(param_1 + 0x24));
  return;
}


// ==== .MouseRoutine__12THowManyModeF5Points @ 10041644 ====
// CyDecompAt: created, body 10041644-100418db

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _MouseRoutine__12THowManyModeF5Points(int param_1,undefined4 param_2)

{
  bool bVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  char cVar6;
  short sVar5;
  short sVar7;
  short sStack_28;
  short sStack_26;
  short sStack_24;
  short sStack_22;
  int aiStack_20 [3];
  
  uVar2 = _DAT_100cdd24;
  bVar1 = false;
  .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(_DAT_100cdd24,6);
  .glue::FindControl(param_2,*(undefined4 *)(*(int *)(param_1 + 4) + 4),aiStack_20);
  if (aiStack_20[0] == *(int *)(param_1 + 0x18)) {
    uVar4 = *(undefined4 *)(**(int **)(param_1 + 0x18) + 8);
    uVar3 = *(undefined4 *)(**(int **)(param_1 + 0x18) + 0xc);
    sVar5 = **(short **)(param_1 + 0x14);
    do {
      sStack_28 = (short)((uint)uVar4 >> 0x10);
      sVar7 = (short)((uint)param_2 >> 0x10);
      if (((int)sVar7 < sStack_28 + -0x10) ||
         (sStack_24 = (short)((uint)uVar3 >> 0x10), sStack_24 + 0x10 < (int)sVar7)) {
        .debug::_SetValue__12THowManyModeFs(param_1,(int)sVar5);
      }
      else {
        sStack_26 = (short)uVar4;
        sVar7 = (short)param_2;
        if ((int)sVar7 < sStack_26 + 0x10) {
          .debug::_SetValue__12THowManyModeFs(param_1,(int)*(short *)(param_1 + 0xc));
        }
        else {
          sStack_22 = (short)uVar3;
          if ((int)sVar7 < sStack_22 + -0x10) {
            .debug::_SetValue__12THowManyModeFs
                      (param_1,(int)*(short *)(param_1 + 0xc) +
                               (((int)*(short *)(param_1 + 0xe) - (int)*(short *)(param_1 + 0xc)) *
                               ((int)sVar7 - (sStack_26 + 0x10))) /
                               (((int)sStack_22 - (int)sStack_26) + -0x20));
          }
          else {
            .debug::_SetValue__12THowManyModeFs(param_1,(int)*(short *)(param_1 + 0xe));
          }
        }
      }
      .glue::GetMouse(&stack0x0000001c);
      cVar6 = .glue::StillDown();
    } while (cVar6 != '\0');
    bVar1 = true;
  }
  else if (aiStack_20[0] == *(int *)(param_1 + 0x20)) {
    sVar5 = .glue::TrackControl(aiStack_20[0],param_2,0);
    if (sVar5 != 0) {
      .debug::_Done__9TConvModeFv(param_1);
    }
    bVar1 = true;
  }
  else if (aiStack_20[0] == *(int *)(param_1 + 0x24)) {
    sVar5 = .glue::TrackControl(aiStack_20[0],param_2,0);
    if (sVar5 != 0) {
      **(undefined2 **)(param_1 + 0x14) = 0;
      .debug::_Done__9TConvModeFv(param_1);
    }
    bVar1 = true;
  }
  else {
    uVar3 = FUN_100c50e8(*(undefined4 *)(param_1 + 4),param_2);
    if ((short)uVar3 != 0) {
      .debug::_ChangeCursor__Fs(0x28);
      FUN_100c50e8(*(undefined4 *)(param_1 + 4),uVar3);
      bVar1 = true;
    }
  }
  .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(uVar2,7);
  if (!bVar1) {
    .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(uVar2,0);
  }
  return;
}


// ==== .CursorRoutine__12THowManyModeF5Points @ 10041914 ====
// CyDecompAt: created, body 10041914-1004199f

void _CursorRoutine__12THowManyModeF5Points(int param_1,undefined4 param_2)

{
  short sVar1;
  
  sVar1 = FUN_100c50e8(*(undefined4 *)(param_1 + 4),param_2);
  if (sVar1 == 0) {
    .debug::_ChangeCursor__Fs(0x2a);
    .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)PTR_DAT_100cdb98,0);
  }
  else {
    .debug::_ChangeCursor__Fs(0x28);
    .debug::_AutoEye__13TStatusWindowFPc
              (*(undefined4 *)PTR_DAT_100cdb98,PTR_s__Write_To_Journal__100ce7fc);
  }
  return;
}


// ==== .KeyRoutine__12THowManyModeFs @ 10041a78 ====
// CyDecompAt: created, body 10041a78-10041c23

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _KeyRoutine__12THowManyModeFs(int param_1,int param_2)

{
  short sVar1;
  
  sVar1 = (short)param_2;
  if (sVar1 == 0x1d) {
    if (*(short *)(param_1 + 0xe) <= **(short **)(param_1 + 0x14)) {
      return;
    }
    .debug::_SetValue__12THowManyModeFs
              (param_1,(int)**(short **)(param_1 + 0x14) + (int)*(short *)(param_1 + 0x10));
    return;
  }
  if (sVar1 < 0x1d) {
    if (sVar1 == 0xd) {
LAB_10041b14:
      .debug::_Done__9TConvModeFv(param_1);
      return;
    }
    if (sVar1 < 0xd) {
      if (sVar1 == 8) goto LAB_10041bc4;
      if ((sVar1 < 8) && (sVar1 == 3)) goto LAB_10041b14;
    }
    else {
      if (sVar1 == 0x1b) {
        .debug::_SetValue__12THowManyModeFs(param_1,(int)*(short *)(param_1 + 0xc));
        .debug::_Done__9TConvModeFv(param_1);
        return;
      }
      if (0x1a < sVar1) {
        if (**(short **)(param_1 + 0x14) <= *(short *)(param_1 + 0xc)) {
          return;
        }
        .debug::_SetValue__12THowManyModeFs
                  (param_1,(int)**(short **)(param_1 + 0x14) - (int)*(short *)(param_1 + 0x10));
        return;
      }
    }
  }
  else {
    if (sVar1 == 0x110) {
LAB_10041bc4:
      .debug::_SetValue__12THowManyModeFs(param_1,(int)*(short *)(param_1 + 0xc));
      return;
    }
    if (sVar1 < 0x110) {
      if (sVar1 < 0x30) {
        if (sVar1 == 0x1f) goto LAB_10041bd4;
        if (sVar1 < 0x1f) goto LAB_10041bc4;
      }
      else if (sVar1 < 0x3a) {
        if ((int)*(short *)(param_1 + 0xe) <= (int)sVar1 + **(short **)(param_1 + 0x14) * 10 + -0x30
           ) {
          return;
        }
        .debug::_SetValue__12THowManyModeFs
                  (param_1,param_2 + **(short **)(param_1 + 0x14) * 10 + -0x30);
        return;
      }
    }
    else if (sVar1 == 0x113) {
LAB_10041bd4:
      .debug::_SetValue__12THowManyModeFs(param_1,(int)*(short *)(param_1 + 0xe));
      return;
    }
  }
  .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(_DAT_100cdd24,0);
  return;
}


// ==== .__dt__10TModalModeFv @ 10041fec ====
// CyDecompAt: created, body 10041fec-10042067

undefined4 * ___dt__10TModalModeFv(undefined4 *param_1,short param_2)

{
  undefined1 auStack_18 [20];
  
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d4e60;
    FUN_100c50e8(param_1[1],auStack_18);
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d5130;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .DrawRoutine__10TModalModeFv @ 10042090 ====
// CyDecompAt: created, body 10042090-100420cb

void _DrawRoutine__10TModalModeFv(int param_1)

{
  .debug::_DrawIntoPort__15TScriptedWindowFP8GrafPort
            (*(undefined4 *)(param_1 + 4),*(undefined4 *)(*(int *)(param_1 + 4) + 4));
  return;
}


// ==== .MouseRoutine__10TModalModeF5Points @ 100420fc ====
// CyDecompAt: created, body 100420fc-1004213b

void _MouseRoutine__10TModalModeF5Points(int param_1,undefined4 param_2,short param_3)

{
  .debug::_MouseRoutine__15TScriptedWindowF5Points
            (*(undefined4 *)(param_1 + 4),param_2,(int)param_3);
  return;
}


// ==== .CursorRoutine__10TModalModeF5Points @ 10042174 ====
// CyDecompAt: created, body 10042174-100421b3

void _CursorRoutine__10TModalModeF5Points(int param_1,undefined4 param_2,short param_3)

{
  .debug::_CursorRoutine__15TScriptedWindowF5Points
            (*(undefined4 *)(param_1 + 4),param_2,(int)param_3);
  return;
}


// ==== .KeyRoutine__10TModalModeFs @ 100421ec ====
// CyDecompAt: created, body 100421ec-10042223

void _KeyRoutine__10TModalModeFs(int param_1,short param_2)

{
  .debug::_KeyRoutine__15TScriptedWindowFs(*(undefined4 *)(param_1 + 4),(int)param_2);
  return;
}


// ==== .GetField__12TInteractionFs @ 10042330 ====
// CyDecompAt: created, body 10042330-1004244b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _GetField__12TInteractionFs(undefined4 *param_1,int param_2,short param_3)

{
  undefined *puVar1;
  int iVar2;
  undefined4 uVar3;
  undefined4 auStack_28 [4];
  
  puVar1 = PTR_DAT_100ce7bc;
  if (param_3 == 0x37) {
    uVar3 = *(undefined4 *)(param_2 + 4);
    .glue::GetPort(auStack_28);
    .glue::SetPort(uVar3);
    *(undefined4 *)puVar1 = *(undefined4 *)PTR_DAT_100cdbb0;
    *(undefined1 *)(param_2 + 0x38) = 0;
    FUN_100c50e8(param_2);
    iVar2 = FUN_100be7c8(0xc);
    if (iVar2 != 0) {
      .debug::___ct__10TModalModeFP12TInteraction(iVar2,*_DAT_100cde3c);
    }
    *(int *)(param_2 + 0x3c) = iVar2;
    FUN_100c50e8();
    .debug::_Perform__9TConvModeFv(*(undefined4 *)(param_2 + 0x3c));
    if (*(int *)(param_2 + 0x3c) != 0) {
      FUN_100c50e8(*(int *)(param_2 + 0x3c),1);
    }
    *(undefined4 *)(param_2 + 0x3c) = 0;
    *param_1 = *(undefined4 *)puVar1;
    .glue::SetPort(auStack_28[0]);
  }
  else {
    .debug::_GetField__15TScriptedWindowFs(param_1,param_2,(int)param_3);
  }
  return;
}


// ==== .DispatchCommand__12TInteractionFPQ215TScriptedWindow7TWidget @ 1004247c ====
// CyDecompAt: created, body 1004247c-100424bb

void _DispatchCommand__12TInteractionFPQ215TScriptedWindow7TWidget(int param_1,undefined4 param_2)

{
  .debug::_Done__9TConvModeFv(*(undefined4 *)(param_1 + 0x3c));
  .debug::_FindScriptedWidget__15TScriptedWindowFPQ215TScriptedWindow7TWidget
            (PTR_DAT_100ce7bc,param_2);
  return;
}


// ==== .__dt__18TSimpleInteractionFv @ 1004250c ====
// CyDecompAt: created, body 1004250c-1004256b

undefined4 * ___dt__18TSimpleInteractionFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d4f78;
    .debug::___dt__12TInteractionFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .HandleDragWindow__12TInteractionF5Point @ 1004259c ====
// CyDecompAt: created, body 1004259c-1004259f

void _HandleDragWindow__12TInteractionF5Point(void)

{
  return;
}


// ==== .__dt__17TConvResponseModeFv @ 100425dc ====
// CyDecompAt: created, body 100425dc-1004263f

undefined4 * ___dt__17TConvResponseModeFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d50d4;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d5130;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__13TConvMoreModeFv @ 10042670 ====
// CyDecompAt: created, body 10042670-100426d3

undefined4 * ___dt__13TConvMoreModeFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d510c;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d5130;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .WantAutoKey__13TConvMoreModeFv @ 10042700 ====
// CyDecompAt: created, body 10042700-10042707

undefined4 _WantAutoKey__13TConvMoreModeFv(void)

{
  return 0;
}


// ==== .BeginAnim__10TMapWindowFv @ 10042a8c ====
// CyDecompAt: created, body 10042a8c-10042ac7

void _BeginAnim__10TMapWindowFv(int param_1)

{
  .glue::SetThreadState(*(undefined4 *)(param_1 + 0x10),0,*(undefined4 *)(param_1 + 0x10));
  return;
}


// ==== .StopAnim__10TMapWindowFv @ 10042af4 ====
// CyDecompAt: created, body 10042af4-10042b2b

void _StopAnim__10TMapWindowFv(int param_1)

{
  .glue::SetThreadState(*(undefined4 *)(param_1 + 0x10),1,0);
  return;
}


// ==== .DrawRoutine__10TMapWindowFv @ 10042b58 ====
// CyDecompAt: created, body 10042b58-10042bab

void _DrawRoutine__10TMapWindowFv(int param_1)

{
  .glue::SetPort(*(undefined4 *)(param_1 + 4));
  if (*(int *)PTR_DAT_100cdbb8 != 0) {
    .debug::_DrawRoutine__11TGameViewerFs(*(undefined4 *)PTR_DAT_100cdbb8,0);
  }
  return;
}


// ==== .PointToCoordinate__10TMapWindowF5PointRsRs @ 10042bdc ====
// CyDecompAt: created, body 10042bdc-10042d4b

undefined4
_PointToCoordinate__10TMapWindowF5PointRsRs
          (undefined4 param_1,undefined4 param_2,short *param_3,short *param_4)

{
  undefined *puVar1;
  undefined *puVar2;
  uint uVar3;
  undefined4 uVar4;
  byte bVar5;
  byte bVar6;
  uint uVar7;
  int iVar8;
  
  puVar1 = PTR_DAT_100cdbb8;
  if (DAT_100d3e20 < '\0') {
    bVar6 = *(byte *)(*(int *)PTR_DAT_100cdc44 + *(short *)PTR_DAT_100cdbec * 0x10 + 6) & 3;
    bVar5 = *(byte *)(*(int *)PTR_DAT_100cdc44 + *(short *)PTR_DAT_100cdbec * 0x10 + 6) >> 4 & 3;
  }
  else {
    bVar6 = 0;
    bVar5 = 0;
  }
  if ((bVar6 == 0) && (bVar5 == 0)) {
    uVar7 = *(uint *)(PTR_DAT_100cdbf0 + *(short *)PTR_DAT_100cdbec * 0x20);
    uVar4 = *(undefined4 *)(PTR_DAT_100cdbf0 + *(short *)PTR_DAT_100cdbec * 0x20);
    *param_3 = (short)param_2;
    *param_4 = (short)((uint)param_2 >> 0x10);
    puVar2 = PTR_DAT_100cdbb8;
    iVar8 = *(int *)puVar1;
    uVar3 = (int)*param_3 + 0x10;
    *param_3 = ((short)((int)uVar3 >> 5) + (ushort)((int)uVar3 < 0 && (uVar3 & 0x1f) != 0)) -
               *(short *)(iVar8 + 2);
    uVar3 = (int)*param_4 + 0x10;
    *param_4 = ((short)((int)uVar3 >> 5) + (ushort)((int)uVar3 < 0 && (uVar3 & 0x1f) != 0)) -
               *(short *)(iVar8 + 2);
    *param_3 = *param_3 + ((ushort)(uVar7 >> 0xc) & 0xfff);
    *param_4 = *param_4 + ((ushort)uVar4 & 0xfff);
    if ((*param_3 < 0) ||
       (((*(short *)(*(int *)puVar2 + 0x20c1c) <= *param_3 || (*param_4 < 0)) ||
        (*(short *)(*(int *)puVar2 + 0x20c1e) <= *param_4)))) {
      uVar4 = 0;
    }
    else {
      uVar4 = 1;
    }
  }
  else {
    uVar4 = 0;
  }
  return uVar4;
}


// ==== .PointToProp__10TMapWindowF5Point @ 10042d8c ====
// CyDecompAt: created, body 10042d8c-10042fbf

undefined4 _PointToProp__10TMapWindowF5Point(undefined4 param_1,undefined4 param_2)

{
  bool bVar1;
  uint uVar2;
  uint uVar3;
  undefined4 uVar4;
  uint uVar5;
  uint uVar6;
  byte bVar7;
  byte bVar8;
  short sVar9;
  short sVar10;
  int iVar11;
  int iVar12;
  short sVar13;
  short sVar14;
  
  if (DAT_100d3e20 < '\0') {
    bVar8 = *(byte *)(*(int *)PTR_DAT_100cdc44 + *(short *)PTR_DAT_100cdbec * 0x10 + 6) & 3;
    bVar7 = *(byte *)(*(int *)PTR_DAT_100cdc44 + *(short *)PTR_DAT_100cdbec * 0x10 + 6) >> 4 & 3;
  }
  else {
    bVar8 = 0;
    bVar7 = 0;
  }
  if ((bVar8 != 0) || (bVar7 != 0)) {
    return 0;
  }
  sVar13 = (short)((uint)param_2 >> 0x10);
  sVar14 = (short)param_2;
  uVar6 = (int)sVar13 + 0x10;
  uVar2 = (int)sVar14 + 0x10;
  iVar11 = *(int *)PTR_DAT_100cdbb8;
  sVar10 = ((short)((int)uVar2 >> 5) + (ushort)((int)uVar2 < 0 && (uVar2 & 0x1f) != 0)) -
           *(short *)(*(int *)PTR_DAT_100cdbb8 + 2);
  sVar9 = ((short)((int)uVar6 >> 5) + (ushort)((int)uVar6 < 0 && (uVar6 & 0x1f) != 0)) -
          *(short *)(*(int *)PTR_DAT_100cdbb8 + 2);
  if (DAT_100d3e20 < '\0') {
    uVar2 = (int)sVar14 + 0x10;
    uVar2 = uVar2 + (((int)uVar2 >> 5) + (uint)((int)uVar2 < 0 && (uVar2 & 0x1f) != 0)) * -0x20;
    uVar6 = (int)sVar14 + 0x10;
    uVar5 = (int)sVar13 + 0x10;
    uVar5 = uVar5 + (((int)uVar5 >> 5) + (uint)((int)uVar5 < 0 && (uVar5 & 0x1f) != 0)) * -0x20;
    uVar3 = (int)sVar13 + 0x10;
    iVar12 = ((int)uVar2 >> 3) + (uint)((int)uVar2 < 0 && (uVar2 & 7) != 0) +
             (int)(short)((((short)((int)uVar6 >> 5) +
                           (ushort)((int)uVar6 < 0 && (uVar6 & 0x1f) != 0)) - *(short *)(iVar11 + 2)
                          ) * 4);
    iVar11 = ((int)uVar5 >> 3) + (uint)((int)uVar5 < 0 && (uVar5 & 7) != 0) +
             (int)(short)((((short)((int)uVar3 >> 5) +
                           (ushort)((int)uVar3 < 0 && (uVar3 & 0x1f) != 0)) - *(short *)(iVar11 + 2)
                          ) * 4);
  }
  else {
    uVar2 = (int)sVar14 + 0x10;
    uVar6 = (int)sVar13 + 0x10;
    iVar12 = (int)(short)((((short)((int)uVar2 >> 5) +
                           (ushort)((int)uVar2 < 0 && (uVar2 & 0x1f) != 0)) - *(short *)(iVar11 + 2)
                          ) * 4);
    iVar11 = (int)(short)((((short)((int)uVar6 >> 5) +
                           (ushort)((int)uVar6 < 0 && (uVar6 & 0x1f) != 0)) - *(short *)(iVar11 + 2)
                          ) * 4);
  }
  bVar1 = false;
  if ((((-0x10 < sVar10) && (sVar10 < 0x10)) && (-0x10 < sVar9)) && (sVar9 < 0x10)) {
    bVar1 = true;
  }
  if (bVar1) {
    uVar4 = .debug::_GetBestPropRel__7TViewerFss(*(undefined4 *)PTR_DAT_100cdbb8,iVar12,iVar11);
    return uVar4;
  }
  return 0;
}


// ==== .PropToPoint__10TMapWindowFsP5Point @ 10042ff4 ====
// CyDecompAt: created, body 10042ff4-100430df

bool _PropToPoint__10TMapWindowFsP5Point(int param_1,short param_2,short *param_3)

{
  char cVar1;
  short sVar2;
  short sVar3;
  short sVar4;
  undefined4 uVar5;
  char *pcVar6;
  int iVar7;
  undefined4 auStack_28 [3];
  
  pcVar6 = (char *)(*(int *)PTR_DAT_100cdc44 + param_2 * 0x10);
  cVar1 = *pcVar6;
  if (cVar1 != -1) {
    sVar2 = *(short *)(pcVar6 + 2);
    iVar7 = *(int *)PTR_DAT_100cdbb8;
    sVar3 = *(short *)(iVar7 + 10);
    sVar4 = *(short *)(iVar7 + 2);
    param_3[1] = (*(short *)(iVar7 + 2) +
                 (((short)((uint)*(undefined4 *)pcVar6 >> 8) >> 4) - *(short *)(iVar7 + 8))) * 0x20;
    *param_3 = (short)((int)sVar4 +
                      (((int)((int)sVar2 << 0x14 | (uint)(int)sVar2 >> 0xc) >> 0x14) - (int)sVar3))
               * 0x20;
    uVar5 = *(undefined4 *)(param_1 + 4);
    .glue::GetPort(auStack_28);
    .glue::SetPort(uVar5);
    .glue::LocalToGlobal(param_3);
    .glue::SetPort(auStack_28[0]);
  }
  return cVar1 != -1;
}


// ==== .IdleRoutine__10TMapWindowFv @ 1004320c ====
// CyDecompAt: created, body 1004320c-1004324f

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _IdleRoutine__10TMapWindowFv(void)

{
  if (*PTR_DAT_100cdd00 != '\0') {
    FUN_100c50e8();
  }
  return;
}


// ==== .AnimThread__10TMapWindowFPv @ 10043280 ====
// CyDecompAt: created, body 10043280-1004334b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _AnimThread__10TMapWindowFPv(void)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined *puVar3;
  int *piVar4;
  uint uVar5;
  
  piVar4 = _DAT_100cdcdc;
  puVar3 = PTR_DAT_100cdbf0;
  puVar2 = PTR_DAT_100cdbec;
  puVar1 = PTR_DAT_100cdbb8;
  do {
    .debug::_DrawRoutine__11TGameViewerFs(*(undefined4 *)puVar1,1);
    .debug::_ColorCycle__FP8GrafPort(*(undefined4 *)(*piVar4 + 4));
    uVar5 = (int)*(short *)(*(int *)puVar1 + 0xba) + 1;
    *(short *)(*(int *)puVar1 + 0xba) =
         (short)uVar5 + (short)(((int)uVar5 >> 3) + (uint)((int)uVar5 < 0 && (uVar5 & 7) != 0)) * -8
    ;
    .debug::_AdvanceDisplacementFilters__Fv();
    if (_DAT_100d53b8 != 0) {
      .debug::_CloseDistantWindows__16TInventoryWindowFss
                ((ushort)(*(uint *)(puVar3 + *(short *)puVar2 * 0x20) >> 0xc) & 0xfff,
                 (ushort)*(undefined4 *)(puVar3 + *(short *)puVar2 * 0x20) & 0xfff);
    }
    .glue::YieldToAnyThread();
  } while( true );
}


// ==== .HandleResizeWindow__10TMapWindowF5Point @ 1004337c ====
// CyDecompAt: created, body 1004337c-10043417

void _HandleResizeWindow__10TMapWindowF5Point(int param_1,undefined4 param_2)

{
  uint uVar1;
  undefined1 auStack_18 [16];
  
  .glue::SetRect(auStack_18,0x80,0x80,0x1c0,0x1c0);
  uVar1 = .glue::GrowWindow(*(undefined4 *)(param_1 + 4),param_2,auStack_18);
  if (uVar1 != 0) {
    .glue::SizeWindow(*(undefined4 *)(param_1 + 4),uVar1 & 0xffff,(int)(short)(uVar1 >> 0x10),1);
    FUN_100c50e8(param_1);
  }
  return;
}


// ==== .ResizeRoutine__10TMapWindowFv @ 10043454 ====
// CyDecompAt: created, body 10043454-100435b7

void _ResizeRoutine__10TMapWindowFv(int param_1)

{
  undefined *puVar1;
  uint uVar2;
  undefined4 uVar3;
  short asStack_18 [2];
  undefined4 auStack_14 [2];
  
  puVar1 = PTR_DAT_100cdbb8;
  uVar3 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_14);
  .glue::SetPort(uVar3);
  asStack_18[0] =
       *(short *)(*(int *)(param_1 + 4) + 0x16) - *(short *)(*(int *)(param_1 + 4) + 0x12);
  if ((int)*(short *)(*(int *)(param_1 + 4) + 0x14) - (int)*(short *)(*(int *)(param_1 + 4) + 0x10)
      < (int)asStack_18[0]) {
    asStack_18[0] =
         *(short *)(*(int *)(param_1 + 4) + 0x14) - *(short *)(*(int *)(param_1 + 4) + 0x10);
  }
  uVar2 = (int)asStack_18[0] + 0x20;
  asStack_18[0] = (short)(((int)uVar2 >> 6) + (uint)((int)uVar2 < 0 && (uVar2 & 0x3f) != 0)) * 2 + 1
  ;
  .debug::_Resize__7TViewerFRs(*(undefined4 *)puVar1,asStack_18);
  .glue::SizeWindow(*(undefined4 *)(param_1 + 4),asStack_18[0] * 0x20 + -0x20,
                    asStack_18[0] * 0x20 + -0x20,0);
  .glue::SetRect(*(int *)puVar1 + 0x20c36,0,0,asStack_18[0] * 0x20 + -0x20,
                 asStack_18[0] * 0x20 + -0x20);
  .debug::_SetLight__11TGameViewerFs
            (*(undefined4 *)puVar1,(int)*(short *)(*(int *)puVar1 + 0x20c2c));
  .debug::_DrawRoutine__11TGameViewerFs(*(undefined4 *)puVar1,1);
  .glue::SetPort(auStack_14[0]);
  return;
}


// ==== .CanDrop__10TMapWindowFsR5Point @ 100435e8 ====
// CyDecompAt: created, body 100435e8-1004370f

undefined4 _CanDrop__10TMapWindowFsR5Point(undefined4 param_1,undefined4 param_2,short *param_3)

{
  ushort uVar1;
  ushort uVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  char cVar7;
  undefined4 uVar6;
  short sStack_28;
  short asStack_26 [3];
  
  puVar5 = PTR_DAT_100cdbf0;
  puVar4 = PTR_DAT_100cdbec;
  puVar3 = PTR_DAT_100cdb98;
  cVar7 = FUN_100c50e8(param_1,*(undefined4 *)param_3,asStack_26,&sStack_28);
  if (cVar7 == '\0') {
    .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar3,PTR_s__Can_t_drop_there__100ce868);
    uVar6 = 0;
  }
  else {
    param_3[1] = asStack_26[0];
    *param_3 = sStack_28;
    uVar1 = (ushort)(*(uint *)(puVar5 + *(short *)puVar4 * 0x20) >> 0xc) & 0xfff;
    uVar2 = (ushort)*(undefined4 *)(puVar5 + *(short *)puVar4 * 0x20) & 0xfff;
    if (((((int)asStack_26[0] < (short)uVar1 + -1) || ((short)uVar1 + 1 < (int)asStack_26[0])) ||
        ((int)sStack_28 < (short)uVar2 + -1)) || ((short)uVar2 + 1 < (int)sStack_28)) {
      .debug::_AutoEye__13TStatusWindowFPc
                (*(undefined4 *)puVar3,PTR_s__Throw__100c6612_0xe_100ce870);
    }
    else {
      .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar3,PTR_s__Drop__100ce86c);
    }
    uVar6 = 1;
  }
  return uVar6;
}


// ==== .DoDrop__10TMapWindowFs5Point @ 10043744 ====
// CyDecompAt: created, body 10043744-10043787

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DoDrop__10TMapWindowFs5Point(undefined4 param_1,short param_2,undefined4 param_3)

{
  .debug::_DropCommand__8TGameSysFsss
            (*_DAT_100cdcd0,(int)param_2,(int)(short)param_3,(int)(short)((uint)param_3 >> 0x10));
  return;
}


// ==== .BecomeKeyTarget__10TMapWindowFv @ 100446f8 ====
// CyDecompAt: created, body 100446f8-10044747

undefined4 _BecomeKeyTarget__10TMapWindowFv(int param_1)

{
  undefined *puVar1;
  
  puVar1 = PTR_DAT_100cdbb8;
  *(undefined2 *)(param_1 + 0xe) = 0;
  *(undefined2 *)(param_1 + 0xc) = 0;
  .debug::_ShowSelector__11TGameViewerFss(*(undefined4 *)puVar1,0,0);
  return 1;
}


// ==== .StopKeyTarget__10TMapWindowFv @ 1004477c ====
// CyDecompAt: created, body 1004477c-100447a7

void _StopKeyTarget__10TMapWindowFv(void)

{
  .debug::_HideSelector__11TGameViewerFv(*(undefined4 *)PTR_DAT_100cdbb8);
  return;
}


// ==== .MoveKeyTarget__10TMapWindowFQ28TGameSys10EDirection @ 100447d8 ====
// CyDecompAt: created, body 100447d8-100448e7

void _MoveKeyTarget__10TMapWindowFQ28TGameSys10EDirection(int param_1,int param_2)

{
  undefined *puVar1;
  short sVar2;
  
  if (param_2 == 8) {
    FUN_100c50e8(param_1);
    *(undefined4 *)PTR_DAT_100cdd94 = 0;
  }
  else {
    if ((param_2 < 1) || (3 < param_2)) {
      if ((param_2 < 5) || (7 < param_2)) {
        sVar2 = 0;
      }
      else {
        sVar2 = -1;
      }
    }
    else {
      sVar2 = 1;
    }
    *(short *)(param_1 + 0xc) = *(short *)(param_1 + 0xc) + sVar2;
    puVar1 = PTR_DAT_100cdbb8;
    if (((param_2 < 0) || (1 < param_2)) && (param_2 != 7)) {
      if ((param_2 < 3) || (5 < param_2)) {
        sVar2 = 0;
      }
      else {
        sVar2 = 1;
      }
    }
    else {
      sVar2 = -1;
    }
    *(short *)(param_1 + 0xe) = *(short *)(param_1 + 0xe) + sVar2;
    .debug::_ShowSelector__11TGameViewerFss
              (*(undefined4 *)puVar1,(int)*(short *)(param_1 + 0xc),(int)*(short *)(param_1 + 0xe));
  }
  return;
}


// ==== .KeyTargetToProp__10TMapWindowFv @ 10044930 ====
// CyDecompAt: created, body 10044930-1004498f

void _KeyTargetToProp__10TMapWindowFv(int param_1)

{
  .debug::_GetBestPropRel__7TViewerFss
            (*(undefined4 *)PTR_DAT_100cdbb8,(int)(short)(*(short *)(param_1 + 0xc) << 2),
             (int)(short)(*(short *)(param_1 + 0xe) << 2));
  return;
}


// ==== .__dt__10TMapWindowFv @ 100449c4 ====
// CyDecompAt: created, body 100449c4-10044a37

undefined4 * ___dt__10TMapWindowFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d53f4;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d4614;
      .debug::___dt__7TWindowFv(param_1,0);
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__Q23std66list<18ActivityQueueEntry,Q23std31allocator<18ActivityQueueEntry>>Fv @ 100451bc ====
// CyDecompAt: created, body 100451bc-10045237

int ___dt__Q23std66list<18ActivityQueueEntry,Q23std31allocator<18ActivityQueueEntry>>Fv
              (int param_1,short param_2)

{
  if ((param_1 != 0) &&
     (.debug::_clear__Q23std66list<18ActivityQueueEntry,Q23std31allocator<18ActivityQueueEntry>>Fv
                (param_1), 0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .__dt__Q23std31allocator<18ActivityQueueEntry>Fv @ 100452a0 ====
// CyDecompAt: created, body 100452a0-1004530b

int ___dt__Q23std31allocator<18ActivityQueueEntry>Fv(int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .__dt__Q23std280_EmptyMemberOpt<Q23std219allocator<Q33std194__tree<Q23std19pair<C8TSpellFX,Us>,Q33std88map<8TSpellFX,Us,Q23std15less<8TSpellFX>,Q23std38allocator<Q23std19pair<C8TSpellFX,Us>>>13value_compare,Q23std38allocator<Q23std19pair<C8TSpellFX,Us>>>4node>,Q33std19__red_black_tree<1>6anchor>Fv @ 10059bf0 ====
// CyDecompAt: created, body 10059bf0-10059c4b

int ___dt__Q23std280_EmptyMemberOpt<Q23std219allocator<Q33std194__tree<Q23std19pair<C8TSpellFX,Us>,Q33std88map<8TSpellFX,Us,Q23std15less<8TSpellFX>,Q23std38allocator<Q23std19pair<C8TSpellFX,Us>>>13value_compare,Q23std38allocator<Q23std19pair<C8TSpellFX,Us>>>4node>,Q33std19__red_black_tree<1>6anchor>Fv
              (int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .__dt__Q23std66_EmptyMemberOpt<Q23std38allocator<Q23std19pair<C8TSpellFX,Us>>,Ul>Fv @ 10059d8c ====
// CyDecompAt: created, body 10059d8c-10059de7

int ___dt__Q23std66_EmptyMemberOpt<Q23std38allocator<Q23std19pair<C8TSpellFX,Us>>,Ul>Fv
              (int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .__dt__Q23std88map<8TSpellFX,Us,Q23std15less<8TSpellFX>,Q23std38allocator<Q23std19pair<C8TSpellFX,Us>>>Fv @ 10059e50 ====
// CyDecompAt: created, body 10059e50-10059ee3

int ___dt__Q23std88map<8TSpellFX,Us,Q23std15less<8TSpellFX>,Q23std38allocator<Q23std19pair<C8TSpellFX,Us>>>Fv
              (int param_1,short param_2)

{
  if (param_1 != 0) {
    if ((param_1 != 0) && (*(int *)(param_1 + 4) != 0)) {
      FUN_1005a018(param_1,*(undefined4 *)(param_1 + 4));
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__Q23std38allocator<Q23std19pair<C8TSpellFX,Us>>Fv @ 10059f60 ====
// CyDecompAt: created, body 10059f60-10059fcb

int ___dt__Q23std38allocator<Q23std19pair<C8TSpellFX,Us>>Fv(int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .RenderMissiles__11TGameViewerFv @ 1005e4f8 ====
// CyDecompAt: created, body 1005e4f8-1005e6a3

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _RenderMissiles__11TGameViewerFv(int param_1)

{
  undefined4 uVar1;
  short sVar2;
  
  uVar1 = _DAT_100cdd24;
  if (*(int *)(param_1 + 0x20c44) != 0) {
    FUN_100c50e8(*(undefined4 *)(param_1 + 0x20c44),*(undefined4 *)(param_1 + 0xb0));
    if (*(short *)(*(int *)PTR_DAT_100cdd98 + 8) != *(short *)PTR_DAT_100cdbec) {
      *(undefined1 *)(*(int *)PTR_DAT_100cdc40 + (int)*(short *)PTR_DAT_100cdbec) = 1;
    }
  }
  .debug::_PostProcessSounds__11TGameViewerFv(param_1);
  .debug::_ResetAmbient__6TAudioFv(uVar1);
  for (sVar2 = 0; sVar2 < *(short *)(param_1 + 0x1dc14); sVar2 = sVar2 + 1) {
    if (*(short *)(param_1 + sVar2 * 8 + 0x1d818) != 0) {
      if (*(short *)(param_1 + sVar2 * 8 + 0x1d81a) == 0) {
        .debug::_Ambient__6TAudioFUsss
                  (uVar1,*(undefined2 *)(param_1 + sVar2 * 8 + 0x1d818),
                   (int)*(short *)(param_1 + sVar2 * 8 + 0x1d814),
                   (int)*(short *)(param_1 + sVar2 * 8 + 0x1d816));
      }
      else {
        .debug::_PlayAmbientSound__6TAudioFUsssUc
                  (uVar1,*(undefined2 *)(param_1 + sVar2 * 8 + 0x1d818),
                   (int)*(short *)(param_1 + sVar2 * 8 + 0x1d814),
                   (int)*(short *)(param_1 + sVar2 * 8 + 0x1d816),0);
      }
    }
  }
  .debug::_CalcAmbient__6TAudioFv(uVar1);
  return;
}


// ==== .Show__11TTileShowerFPc @ 1005e9a0 ====
// CyDecompAt: created, body 1005e9a0-1005e9d7

void _Show__11TTileShowerFPc(int param_1)

{
  .debug::_MaskAMissile__11TGameViewerFPcl
            (*(undefined4 *)(param_1 + 4),*(undefined4 *)(param_1 + 8),
             *(undefined4 *)(param_1 + 0xc));
  return;
}


// ==== .DoBresPixel__15TMissileThrowerFl @ 1005ead0 ====
// CyDecompAt: created, body 1005ead0-1005eba3

undefined4 _DoBresPixel__15TMissileThrowerFl(int param_1,undefined4 param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  uint uVar3;
  uint uVar4;
  
  puVar2 = PTR_DAT_100cea60;
  puVar1 = PTR_DAT_100cea5c;
  if (*PTR_DAT_100cea60 == '\0') {
    *(undefined2 *)PTR_DAT_100cea5c = 0;
    *puVar2 = 1;
  }
  if (*(short *)puVar1 == 0) {
    *(undefined4 *)(param_1 + 0x18) = param_2;
    .debug::_DrawRoutine__11TGameViewerFs(*(undefined4 *)(param_1 + 0x10),2);
  }
  if (*(int *)(param_1 + 0x1c) != 0) {
    uVar4 = *(uint *)(param_1 + 4);
    uVar3 = *(uint *)(param_1 + 8);
    .debug::_MoveTo__13TSoundTrackerFss
              (*(undefined4 *)(param_1 + 0x1c),
               (int)(short)((short)((int)uVar4 >> 5) +
                           (ushort)((int)uVar4 < 0 && (uVar4 & 0x1f) != 0)),
               (int)(short)((short)((int)uVar3 >> 5) +
                           (ushort)((int)uVar3 < 0 && (uVar3 & 0x1f) != 0)));
  }
  uVar3 = (int)*(short *)puVar1 + 1;
  *(short *)puVar1 =
       (short)uVar3 +
       (short)(((int)uVar3 >> 4) + (uint)((int)uVar3 < 0 && (uVar3 & 0xf) != 0)) * -0x10;
  return 1;
}


// ==== .DoBresPixel__15TMissileSpinnerFl @ 1005ecc8 ====
// CyDecompAt: created, body 1005ecc8-1005edcf

undefined4 _DoBresPixel__15TMissileSpinnerFl(int param_1,undefined4 param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  uint uVar3;
  uint uVar4;
  int iVar5;
  
  puVar2 = PTR_DAT_100cea58;
  puVar1 = PTR_DAT_100cea54;
  if (*PTR_DAT_100cea58 == '\0') {
    *(undefined2 *)PTR_DAT_100cea54 = 0;
    *puVar2 = 1;
  }
  if (*(short *)puVar1 == 0) {
    *(undefined4 *)(param_1 + 0x18) = param_2;
    .debug::_DrawRoutine__11TGameViewerFs(*(undefined4 *)(param_1 + 0x10),2);
    iVar5 = *(short *)(param_1 + 0x20) + 1;
    *(short *)(param_1 + 0x20) =
         (short)iVar5 -
         (short)(iVar5 / (int)*(short *)(param_1 + 0x22)) * *(short *)(param_1 + 0x22);
    *(undefined4 *)(param_1 + 0x14) =
         *(undefined4 *)(*(int *)(param_1 + 0x24) + *(short *)(param_1 + 0x20) * 4);
  }
  if (*(int *)(param_1 + 0x1c) != 0) {
    uVar4 = *(uint *)(param_1 + 4);
    uVar3 = *(uint *)(param_1 + 8);
    .debug::_MoveTo__13TSoundTrackerFss
              (*(undefined4 *)(param_1 + 0x1c),
               (int)(short)((short)((int)uVar4 >> 5) +
                           (ushort)((int)uVar4 < 0 && (uVar4 & 0x1f) != 0)),
               (int)(short)((short)((int)uVar3 >> 5) +
                           (ushort)((int)uVar3 < 0 && (uVar3 & 0x1f) != 0)));
  }
  uVar3 = (int)*(short *)puVar1 + 1;
  *(short *)puVar1 =
       (short)uVar3 +
       (short)(((int)uVar3 >> 4) + (uint)((int)uVar3 < 0 && (uVar3 & 0xf) != 0)) * -0x10;
  return 1;
}


// ==== .DoBresPixel__14TMissileStreamFl @ 1005eea4 ====
// CyDecompAt: created, body 1005eea4-1005ef4f

undefined4 _DoBresPixel__14TMissileStreamFl(int param_1,undefined4 param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  int iVar3;
  int iVar4;
  
  puVar2 = PTR_DAT_100cea50;
  puVar1 = PTR_DAT_100cea4c;
  if (*PTR_DAT_100cea50 == '\0') {
    *(undefined2 *)PTR_DAT_100cea4c = 0;
    *puVar2 = 1;
  }
  if (*(short *)puVar1 == 0) {
    .debug::_MaskAMissile__11TGameViewerFPcl
              (*(undefined4 *)(param_1 + 0x10),*(undefined4 *)(param_1 + 0x14),param_2);
  }
  iVar4 = *(short *)puVar1 + 1;
  iVar3 = iVar4 / 0xc + (iVar4 >> 0x1f);
  *(short *)puVar1 = (short)iVar4 + ((short)iVar3 - (short)(iVar3 >> 0x1f)) * -0xc;
  return 1;
}


// ==== .Show__14TMissileStreamFPc @ 1005ef84 ====
// CyDecompAt: created, body 1005ef84-1005efcf

void _Show__14TMissileStreamFPc(int param_1)

{
  .debug::_DrawBres__5TBresFiiiilii
            (param_1,*(undefined4 *)(param_1 + 0x18),*(undefined4 *)(param_1 + 0x1c),
             *(undefined4 *)(param_1 + 0x20),*(undefined4 *)(param_1 + 0x24),
             *(undefined4 *)(param_1 + 0x28),*(undefined4 *)(param_1 + 0x2c),
             *(undefined4 *)(param_1 + 0x30));
  return;
}


// ==== .Show__13TCircleShowerFPc @ 1005f8cc ====
// CyDecompAt: created, body 1005f8cc-1005f8f3

void _Show__13TCircleShowerFPc(undefined4 param_1)

{
  .debug::_ShowCircle__13TCircleShowerFv(param_1);
  return;
}


// ==== .Show__12TBurstShowerFPc @ 1005f920 ====
// CyDecompAt: created, body 1005f920-1005f987

void _Show__12TBurstShowerFPc(int param_1)

{
  ushort uVar1;
  ushort uVar2;
  
  uVar1 = *(ushort *)(param_1 + 8);
  for (uVar2 = uVar1 & 1; (short)uVar2 <= *(short *)(param_1 + 8); uVar2 = uVar2 + 2) {
    *(ushort *)(param_1 + 8) = uVar2;
    .debug::_ShowCircle__13TCircleShowerFv(param_1);
  }
  *(ushort *)(param_1 + 8) = uVar1;
  return;
}


// ==== .__dt__11TGameViewerFv @ 10061a04 ====
// CyDecompAt: created, body 10061a04-10061a67

int ___dt__11TGameViewerFv(int param_1,short param_2)

{
  if (param_1 != 0) {
    *(undefined ***)(param_1 + 0x10) = &PTR_PTR_100d5f64;
    .debug::___dt__7TViewerFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__5TBarkFv @ 10061e74 ====
// CyDecompAt: created, body 10061e74-10061ec7

undefined4 * ___dt__5TBarkFv(undefined4 *param_1,short param_2)

{
  if ((param_1 != (undefined4 *)0x0) && (*param_1 = &PTR_PTR_100d5f80, 0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .RenderMissiles__7TViewerFv @ 100693b0 ====
// CyDecompAt: created, body 100693b0-100693b3

void _RenderMissiles__7TViewerFv(void)

{
  return;
}


// ==== .DoBresPixel__13TStraightBresFl @ 1006bdbc ====
// CyDecompAt: created, body 1006bdbc-1006bdeb

undefined4 _DoBresPixel__13TStraightBresFl(int param_1,int param_2)

{
  if ((*(uint *)(*(int *)(param_1 + 0xc) + param_2 * 8) & 4) != 0) {
    **(undefined1 **)(param_1 + 0x10) = 0;
    return 0;
  }
  return 1;
}


// ==== .Hide__8TListBoxFv @ 1006cd28 ====
// CyDecompAt: created, body 1006cd28-1006ce33

void _Hide__8TListBoxFv(int param_1)

{
  if (*(short *)(**(int **)(param_1 + 4) + 2) < 0x4000) {
    .glue::InvalRect(**(undefined4 **)(param_1 + 4));
    .glue::OffsetRect(**(undefined4 **)(param_1 + 4),0x4000,0);
    if (*(int *)(**(int **)(param_1 + 4) + 0x1c) != 0) {
      .glue::MoveControl(*(undefined4 *)(**(int **)(param_1 + 4) + 0x1c),
                         *(short *)(**(int **)(**(int **)(param_1 + 4) + 0x1c) + 10) + 0x4000,
                         (int)*(short *)(**(int **)(**(int **)(param_1 + 4) + 0x1c) + 8));
    }
    if (*(int *)(**(int **)(param_1 + 4) + 0x20) != 0) {
      .glue::MoveControl(*(undefined4 *)(**(int **)(param_1 + 4) + 0x20),
                         *(short *)(**(int **)(**(int **)(param_1 + 4) + 0x20) + 10) + 0x4000,
                         (int)*(short *)(**(int **)(**(int **)(param_1 + 4) + 0x20) + 8));
    }
  }
  return;
}


// ==== .Show__8TListBoxFv @ 1006ce58 ====
// CyDecompAt: created, body 1006ce58-1006cf63

void _Show__8TListBoxFv(int param_1)

{
  if (0x3fff < *(short *)(**(int **)(param_1 + 4) + 2)) {
    .glue::OffsetRect(**(undefined4 **)(param_1 + 4),0xffffc000,0);
    .glue::InvalRect(**(undefined4 **)(param_1 + 4));
    if (*(int *)(**(int **)(param_1 + 4) + 0x1c) != 0) {
      .glue::MoveControl(*(undefined4 *)(**(int **)(param_1 + 4) + 0x1c),
                         *(short *)(**(int **)(**(int **)(param_1 + 4) + 0x1c) + 10) + -0x4000,
                         (int)*(short *)(**(int **)(**(int **)(param_1 + 4) + 0x1c) + 8));
    }
    if (*(int *)(**(int **)(param_1 + 4) + 0x20) != 0) {
      .glue::MoveControl(*(undefined4 *)(**(int **)(param_1 + 4) + 0x20),
                         *(short *)(**(int **)(**(int **)(param_1 + 4) + 0x20) + 10) + -0x4000,
                         (int)*(short *)(**(int **)(**(int **)(param_1 + 4) + 0x20) + 8));
    }
  }
  return;
}


// ==== .MoveList__8TListBoxFss @ 1006cf88 ====
// CyDecompAt: created, body 1006cf88-1006d0bb

void _MoveList__8TListBoxFss(int param_1,short param_2,short param_3)

{
  int iVar1;
  int iVar2;
  
  .glue::InvalRect(**(undefined4 **)(param_1 + 4));
  iVar2 = (int)param_2 - ((int)*(short *)(**(int **)(param_1 + 4) + 2) & 0x3fffU);
  iVar1 = (int)param_3 - (int)*(short *)**(undefined4 **)(param_1 + 4);
  .glue::OffsetRect(**(undefined4 **)(param_1 + 4),iVar2,iVar1);
  if (*(int *)(**(int **)(param_1 + 4) + 0x1c) != 0) {
    .glue::MoveControl(*(undefined4 *)(**(int **)(param_1 + 4) + 0x1c),
                       *(short *)(**(int **)(**(int **)(param_1 + 4) + 0x1c) + 10) + iVar2,
                       *(short *)(**(int **)(**(int **)(param_1 + 4) + 0x1c) + 8) + iVar1);
  }
  if (*(int *)(**(int **)(param_1 + 4) + 0x20) != 0) {
    .glue::MoveControl(*(undefined4 *)(**(int **)(param_1 + 4) + 0x20),
                       *(short *)(**(int **)(**(int **)(param_1 + 4) + 0x20) + 10) + iVar2,
                       *(short *)(**(int **)(**(int **)(param_1 + 4) + 0x20) + 8) + iVar1);
  }
  return;
}


// ==== .AdjustForGrow__8TListBoxFv @ 1006d0e8 ====
// CyDecompAt: created, body 1006d0e8-1006d223

void _AdjustForGrow__8TListBoxFv(int param_1)

{
  if ((*(int *)(**(int **)(param_1 + 4) + 0x1c) == 0) ||
     (*(int *)(**(int **)(param_1 + 4) + 0x20) == 0)) {
    if (*(int *)(**(int **)(param_1 + 4) + 0x1c) == 0) {
      if (*(int *)(**(int **)(param_1 + 4) + 0x20) != 0) {
        .glue::SizeControl(*(undefined4 *)(**(int **)(param_1 + 4) + 0x20),
                           ((int)*(short *)(**(int **)(param_1 + 4) + 6) -
                           (int)*(short *)(**(int **)(param_1 + 4) + 2)) + -0xf,
                           (int)*(short *)(**(int **)(**(int **)(param_1 + 4) + 0x20) + 0xc) -
                           (int)*(short *)(**(int **)(**(int **)(param_1 + 4) + 0x20) + 8));
      }
    }
    else {
      .glue::SizeControl(*(undefined4 *)(**(int **)(param_1 + 4) + 0x1c),
                         (int)*(short *)(**(int **)(**(int **)(param_1 + 4) + 0x1c) + 0xe) -
                         (int)*(short *)(**(int **)(**(int **)(param_1 + 4) + 0x1c) + 10),
                         ((int)*(short *)(**(int **)(param_1 + 4) + 4) -
                         (int)*(short *)**(undefined4 **)(param_1 + 4)) + -0xf);
    }
  }
  return;
}


// ==== .SetNumCols__8TListBoxFs @ 1006d254 ====
// CyDecompAt: created, body 1006d254-1006d2f7

void _SetNumCols__8TListBoxFs(int param_1,undefined4 param_2)

{
  if ((short)param_2 !=
      (short)(*(short *)(**(int **)(param_1 + 4) + 0x4e) -
             *(short *)(**(int **)(param_1 + 4) + 0x4a))) {
    .glue::LDelColumn(0,0,*(undefined4 *)(param_1 + 4));
    .glue::LAddColumn(param_2,0,*(undefined4 *)(param_1 + 4));
    .glue::LDelRow(0,0,*(undefined4 *)(param_1 + 4));
  }
  return;
}


// ==== .SetNumRows__8TListBoxFs @ 1006d324 ====
// CyDecompAt: created, body 1006d324-1006d3c7

void _SetNumRows__8TListBoxFs(int param_1,undefined4 param_2)

{
  if ((short)param_2 !=
      (short)(*(short *)(**(int **)(param_1 + 4) + 0x4c) -
             *(short *)(**(int **)(param_1 + 4) + 0x48))) {
    .glue::LDelColumn(0,0,*(undefined4 *)(param_1 + 4));
    .glue::LAddColumn(param_2,0,*(undefined4 *)(param_1 + 4));
    .glue::LDelRow(0,0,*(undefined4 *)(param_1 + 4));
  }
  return;
}


// ==== .LDEFHilite__8TListBoxFUcP4Rect5Pointss @ 1006d508 ====
// CyDecompAt: created, body 1006d508-1006d563

void _LDEFHilite__8TListBoxFUcP4Rect5Pointss
               (undefined4 param_1,undefined1 param_2,undefined4 param_3,undefined4 param_4,
               short param_5,short param_6)

{
  FUN_100c50e8(param_1,param_2,param_3,param_4,(int)param_5,(int)param_6);
  return;
}


// ==== .MyLDEF @ 1006d5a0 ====
// CyDecompAt: created, body 1006d5a0-1006d67b

void _MyLDEF(short param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,
            undefined4 param_5,undefined4 param_6,int *param_7)

{
  int iVar1;
  
  if (((param_1 != 0) && (param_1 != 3)) && (iVar1 = *(int *)(*param_7 + 0x44), iVar1 != 0)) {
    if (param_1 == 2) {
      FUN_100c50e8(iVar1,param_2,param_3,param_4,param_5,param_6);
    }
    else if ((param_1 < 2) && (0 < param_1)) {
      FUN_100c50e8(iVar1,param_2,param_3,param_4,param_5,param_6);
    }
  }
  return;
}


// ==== .GetSelection__8TListBoxFv @ 1006d698 ====
// CyDecompAt: created, body 1006d698-1006d713

int _GetSelection__8TListBoxFv(int param_1)

{
  char cVar2;
  int iVar1;
  undefined4 uStack_18;
  
  uStack_18 = *(undefined4 *)(**(int **)(param_1 + 4) + 0x48);
  cVar2 = .glue::LGetSelect(1,&uStack_18,*(undefined4 *)(param_1 + 4));
  if (cVar2 == '\0') {
    iVar1 = -1;
  }
  else {
    iVar1 = (int)uStack_18._2_2_ +
            (int)uStack_18._0_2_ * (int)*(short *)(**(int **)(param_1 + 4) + 0x4e);
  }
  return iVar1;
}


// ==== .SetSelection__8TListBoxFs @ 1006d740 ====
// CyDecompAt: created, body 1006d740-1006d8c3

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetSelection__8TListBoxFs(int param_1,short param_2)

{
  short sVar1;
  char cVar2;
  undefined4 uStack_18;
  
  uStack_18 = CONCAT22(*(undefined2 *)(**(int **)(param_1 + 4) + 0x48),
                       *(undefined2 *)(**(int **)(param_1 + 4) + 0x4a));
  while( true ) {
    cVar2 = .glue::LGetSelect(1,&uStack_18,*(undefined4 *)(param_1 + 4));
    if (cVar2 == '\0') break;
    if ((int)param_2 ==
        (int)uStack_18._2_2_ +
        (int)uStack_18._0_2_ * (int)*(short *)(**(int **)(param_1 + 4) + 0x4e)) {
      if (uStack_18._2_2_ + 1 == (int)*(short *)(**(int **)(param_1 + 4) + 0x4e)) {
        uStack_18 = CONCAT22(uStack_18._0_2_ + 1,*(undefined2 *)(**(int **)(param_1 + 4) + 0x4a));
      }
      else {
        uStack_18 = CONCAT22(uStack_18._0_2_,uStack_18._2_2_ + 1);
      }
    }
    else {
      .glue::LSetSelect(0,uStack_18,*(undefined4 *)(param_1 + 4));
    }
  }
  if (-1 < param_2) {
    sVar1 = *(short *)(**(int **)(param_1 + 4) + 0x4e);
    uStack_18 = CONCAT22(param_2 / *(short *)(**(int **)(param_1 + 4) + 0x4e),
                         param_2 - (param_2 / sVar1) * sVar1);
    .glue::LSetSelect(1,uStack_18,*(undefined4 *)(param_1 + 4));
    FUN_100c50e8(param_1,uStack_18);
  }
  return;
}


// ==== .RevealCell__8TListBoxF5Point @ 1006d8f0 ====
// CyDecompAt: created, body 1006d8f0-1006da27

void _RevealCell__8TListBoxF5Point(int param_1,undefined4 param_2)

{
  int iVar1;
  int iVar2;
  short sVar3;
  
  iVar2 = 0;
  iVar1 = 0;
  sVar3 = (short)((uint)param_2 >> 0x10);
  if (sVar3 < *(short *)(**(int **)(param_1 + 4) + 0x18)) {
    if (sVar3 < *(short *)(**(int **)(param_1 + 4) + 0x14)) {
      iVar1 = ((int)sVar3 - (int)*(short *)(**(int **)(param_1 + 4) + 0x14)) + -1;
    }
  }
  else {
    iVar1 = ((int)sVar3 - (int)*(short *)(**(int **)(param_1 + 4) + 0x18)) + 1;
  }
  sVar3 = (short)param_2;
  if (sVar3 < *(short *)(**(int **)(param_1 + 4) + 0x1a)) {
    if (sVar3 < *(short *)(**(int **)(param_1 + 4) + 0x16)) {
      iVar2 = ((int)sVar3 - (int)*(short *)(**(int **)(param_1 + 4) + 0x16)) + -1;
    }
  }
  else {
    iVar2 = ((int)sVar3 - (int)*(short *)(**(int **)(param_1 + 4) + 0x1a)) + 1;
  }
  if (((short)iVar2 != 0) || ((short)iVar1 != 0)) {
    .glue::LScroll(iVar2,iVar1,*(undefined4 *)(param_1 + 4));
  }
  return;
}


// ==== .Key__8TListBoxFss @ 1006da58 ====
// CyDecompAt: created, body 1006da58-1006deb7

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Key__8TListBoxFss(int param_1,short param_2,uint param_3)

{
  ushort uVar1;
  short sVar2;
  uint uVar3;
  uint uVar4;
  short sVar5;
  char cVar6;
  undefined4 uStack_20;
  undefined4 uStack_1c;
  
  uStack_1c = _DAT_100d6188;
  cVar6 = .glue::LGetSelect(1,&uStack_1c,*(undefined4 *)(param_1 + 4));
  uVar3 = uStack_1c;
  if (cVar6 != '\0') {
    uStack_20 = uStack_1c;
    uVar4 = uStack_20;
    uStack_20._2_2_ = (short)uStack_1c;
    sVar2 = uStack_20._2_2_;
    uStack_20._0_2_ = (short)(uStack_1c >> 0x10);
    sVar5 = uStack_20._0_2_;
    if (param_2 == 0x1e) {
      uStack_20 = CONCAT22(uStack_20._0_2_ + -1,uStack_20._2_2_);
      uVar4 = uStack_20;
    }
    else if (param_2 < 0x1e) {
      if (param_2 == 0x1c) {
        uStack_20 = CONCAT22(uStack_20._0_2_,uStack_20._2_2_ + -1);
        uVar4 = uStack_20;
      }
      else if (0x1b < param_2) {
        uStack_20 = CONCAT22(uStack_20._0_2_,uStack_20._2_2_ + 1);
        uVar4 = uStack_20;
      }
    }
    else if (param_2 < 0x20) {
      uStack_20 = CONCAT22(uStack_20._0_2_ + 1,uStack_20._2_2_);
      uVar4 = uStack_20;
    }
    uStack_20 = uVar4;
    if (uStack_20._2_2_ < 0) {
      uStack_20 = uStack_20 & 0xffff0000;
    }
    if ((int)uStack_20 < 0) {
      uStack_20 = uStack_20 & 0xffff;
    }
    if (*(short *)(**(int **)(param_1 + 4) + 0x4e) <= uStack_20._2_2_) {
      uStack_20 = CONCAT22(uStack_20._0_2_,*(undefined2 *)(**(int **)(param_1 + 4) + 0x4e));
    }
    if (*(short *)(**(int **)(param_1 + 4) + 0x4c) <= uStack_20._0_2_) {
      uStack_20 = CONCAT22(*(undefined2 *)(**(int **)(param_1 + 4) + 0x4c),uStack_20._2_2_);
    }
    if ((uStack_20._2_2_ != sVar2) || (uStack_20._0_2_ != sVar5)) {
      .glue::LSetSelect(0,uStack_1c,*(undefined4 *)(param_1 + 4));
      .glue::LSetSelect(1,uStack_20,*(undefined4 *)(param_1 + 4));
      FUN_100c50e8(param_1,uStack_1c);
      return;
    }
  }
  uVar1 = *(ushort *)(**(int **)(param_1 + 4) + 0x16);
  sVar5 = *(short *)(**(int **)(param_1 + 4) + 0x14);
  if (param_2 != 0x112) {
    if (param_2 < 0x112) {
      if (param_2 == 0x110) {
        uStack_1c = (uint)uVar1;
        FUN_100c50e8(param_1,uStack_1c);
        if ((param_3 & 0x200) != 0) {
          if (cVar6 != '\0') {
            .glue::LSetSelect(0,uVar3,*(undefined4 *)(param_1 + 4));
          }
          .glue::LSetSelect(1,uStack_1c,*(undefined4 *)(param_1 + 4));
        }
      }
      else if (0x10f < param_2) {
        sVar5 = sVar5 - ((*(short *)(**(int **)(param_1 + 4) + 0x18) -
                         *(short *)(**(int **)(param_1 + 4) + 0x14)) + -1);
        uStack_1c = CONCAT22(sVar5,uVar1);
        if (sVar5 < 0) {
          uStack_1c = (uint)uVar1;
        }
        .glue::LScroll(0,(int)uStack_1c._0_2_ - (int)*(short *)(**(int **)(param_1 + 4) + 0x14),
                       *(undefined4 *)(param_1 + 4));
        if ((param_3 & 0x200) != 0) {
          if (cVar6 != '\0') {
            .glue::LSetSelect(0,uVar3,*(undefined4 *)(param_1 + 4));
          }
          .glue::LSetSelect(1,uStack_1c,*(undefined4 *)(param_1 + 4));
        }
      }
    }
    else if (param_2 == 0x114) {
      sVar5 = (*(short *)(**(int **)(param_1 + 4) + 0x18) -
              *(short *)(**(int **)(param_1 + 4) + 0x14)) + sVar5 + -1;
      if (*(short *)(**(int **)(param_1 + 4) + 0x4c) <= sVar5) {
        sVar5 = *(short *)(**(int **)(param_1 + 4) + 0x4c);
      }
      uStack_1c = CONCAT22(sVar5,uVar1);
      .glue::LScroll(0,(int)sVar5 - (int)*(short *)(**(int **)(param_1 + 4) + 0x14),
                     *(undefined4 *)(param_1 + 4));
      if ((param_3 & 0x200) != 0) {
        if (cVar6 != '\0') {
          .glue::LSetSelect(0,uVar3,*(undefined4 *)(param_1 + 4));
        }
        .glue::LSetSelect(1,uStack_1c,*(undefined4 *)(param_1 + 4));
      }
    }
    else if (param_2 < 0x114) {
      uStack_1c = CONCAT22(*(short *)(**(int **)(param_1 + 4) + 0x4c) + -1,uVar1);
      FUN_100c50e8(param_1,uStack_1c);
      if ((param_3 & 0x200) != 0) {
        if (cVar6 != '\0') {
          .glue::LSetSelect(0,uVar3,*(undefined4 *)(param_1 + 4));
        }
        .glue::LSetSelect(1,uStack_1c,*(undefined4 *)(param_1 + 4));
      }
    }
  }
  return;
}


// ==== .Click__8TListBoxF5Points @ 1006dedc ====
// CyDecompAt: created, body 1006dedc-1006e0ff

undefined4 _Click__8TListBoxF5Points(int param_1,undefined4 param_2,short param_3)

{
  bool bVar1;
  short sVar6;
  short sVar7;
  int iVar2;
  int iVar3;
  uint uVar4;
  char cVar8;
  undefined4 uVar5;
  int iVar9;
  short sVar10;
  undefined4 uStack_46;
  undefined4 uStack_42;
  undefined4 uStack_3e;
  undefined4 uStack_3a;
  short sStack_36;
  short sStack_34;
  int *apiStack_30 [2];
  
  sVar6 = .glue::FindControl(param_2,*(undefined4 *)(PTR_DAT_100cdb94 + 0xca),apiStack_30);
  bVar1 = apiStack_30[0] != *(int **)(**(int **)(param_1 + 4) + 0x20);
  if (sVar6 == 0x81) {
    uStack_46 = *(undefined4 *)(*apiStack_30[0] + 8);
    uStack_42 = *(undefined4 *)(*apiStack_30[0] + 0xc);
    uStack_3e = uStack_46;
    uStack_3a = uStack_42;
    .glue::InsetRect(&uStack_46,0xfffffff0,0xfffffff0);
    if (bVar1) {
      sVar6 = uStack_3a._0_2_ - uStack_3e._0_2_;
    }
    else {
      sVar6 = uStack_3a._2_2_ - uStack_3e._2_2_;
    }
    sVar6 = sVar6 + -0x30;
    sVar7 = .glue::GetControlMaximum(apiStack_30[0]);
    iVar2 = .glue::GetControlMinimum(apiStack_30[0]);
    .glue::GetControlValue(apiStack_30[0]);
    while (cVar8 = .glue::StillDown(), cVar8 != '\0') {
      .glue::GetMouse(&sStack_36);
      iVar3 = .glue::GetControlValue(apiStack_30[0]);
      if (bVar1) {
        sVar10 = sStack_36 - (uStack_3e._0_2_ + 0x18);
      }
      else {
        sVar10 = sStack_34 - (uStack_3e._2_2_ + 0x18);
      }
      if (sVar10 < 0) {
        sVar10 = 0;
      }
      if (sVar6 < sVar10) {
        sVar10 = sVar6;
      }
      uVar4 = (uint)sVar6;
      iVar9 = iVar2 + (int)(((int)uVar4 >> 1) + (uint)((int)uVar4 < 0 && (uVar4 & 1) != 0) +
                           (int)sVar10 * (int)(short)(sVar7 - (short)iVar2)) / (int)sVar6;
      if ((short)iVar9 != (short)iVar3) {
        if (bVar1) {
          .glue::LScroll(0,iVar9 - iVar3,*(undefined4 *)(param_1 + 4));
        }
        else {
          .glue::LScroll(iVar9 - iVar3,0,*(undefined4 *)(param_1 + 4));
        }
      }
    }
    uVar5 = 0;
  }
  else {
    uVar5 = .glue::LClick(param_2,(int)param_3,*(undefined4 *)(param_1 + 4));
  }
  return uVar5;
}


// ==== .ResetMouseUp__8TListBoxFv @ 1006e2b4 ====
// CyDecompAt: created, body 1006e2b4-1006e2eb

void _ResetMouseUp__8TListBoxFv(int param_1)

{
  undefined4 uVar1;
  
  uVar1 = .glue::TickCount();
  *(undefined4 *)(**(int **)(param_1 + 4) + 0x28) = uVar1;
  return;
}


// ==== .DrawIntoPort__8TListBoxFP8GrafPort @ 1006e474 ====
// CyDecompAt: created, body 1006e474-1006e6ff

void _DrawIntoPort__8TListBoxFP8GrafPort(int param_1,int param_2)

{
  char cVar3;
  undefined4 uVar1;
  undefined4 uVar2;
  int iVar4;
  int *piVar5;
  int *piVar6;
  short sVar7;
  short sVar8;
  undefined4 uStack_58;
  undefined4 uStack_54;
  short sStack_50;
  short sStack_4e;
  undefined4 uStack_4c;
  undefined4 uStack_48;
  undefined4 uStack_44;
  undefined4 uStack_40;
  undefined4 uStack_3c;
  undefined4 uStack_38;
  undefined4 uStack_34;
  
  iVar4 = *(int *)(**(int **)(param_1 + 4) + 8);
  if (param_2 == iVar4) {
    FUN_100c50e8(param_1,*(undefined4 *)(param_2 + 0x18));
  }
  else {
    *(int *)(**(int **)(param_1 + 4) + 8) = param_2;
    piVar6 = *(int **)(**(int **)(param_1 + 4) + 0x20);
    if (piVar6 != (int *)0x0) {
      *(int *)(*piVar6 + 4) = param_2;
    }
    piVar5 = *(int **)(**(int **)(param_1 + 4) + 0x1c);
    if (piVar5 != (int *)0x0) {
      *(int *)(*piVar5 + 4) = param_2;
    }
    if (piVar6 != (int *)0x0) {
      .glue::Draw1Control(piVar6);
    }
    if (piVar5 != (int *)0x0) {
      .glue::Draw1Control(piVar5);
    }
    uStack_38 = *(undefined4 *)**(undefined4 **)(param_1 + 4);
    uStack_34 = ((undefined4 *)**(undefined4 **)(param_1 + 4))[1];
    .glue::EraseRect(&uStack_38);
    uStack_40 = *(undefined4 *)(**(int **)(param_1 + 4) + 0x14);
    uStack_3c = *(undefined4 *)(**(int **)(param_1 + 4) + 0x18);
    uStack_48 = *(undefined4 *)(**(int **)(param_1 + 4) + 0x48);
    uStack_44 = *(undefined4 *)(**(int **)(param_1 + 4) + 0x4c);
    .glue::SectRect(&uStack_40,&uStack_48,&uStack_40);
    cVar3 = .glue::EmptyRect(&uStack_40);
    if (cVar3 == '\0') {
      uVar1 = .glue::NewRgn();
      .glue::GetClip();
      for (sVar7 = uStack_40._2_2_; sVar7 < uStack_3c._2_2_; sVar7 = sVar7 + 1) {
        sVar8 = uStack_40._0_2_;
        while( true ) {
          if (uStack_3c._0_2_ <= sVar8) break;
          uStack_4c = CONCAT22(sVar8,sVar7);
          .glue::LRect(&uStack_48,uStack_4c,*(undefined4 *)(param_1 + 4));
          .glue::LGetCellDataLocation(&sStack_50,&sStack_4e,uStack_4c,*(undefined4 *)(param_1 + 4));
          uVar2 = .glue::LGetSelect(0,&uStack_4c,*(undefined4 *)(param_1 + 4));
          uStack_58 = uStack_48;
          uStack_54 = uStack_44;
          .glue::SectRect(&uStack_58,&uStack_38,&uStack_58);
          cVar3 = .glue::EmptyRect(&uStack_58);
          if (cVar3 == '\0') {
            .glue::ClipRect(&uStack_58);
            FUN_100c50e8(param_1,uVar2,&uStack_48,uStack_4c,(int)sStack_50,(int)sStack_4e);
          }
          sVar8 = sVar8 + 1;
        }
      }
      .glue::SetClip(uVar1);
      .glue::DisposeRgn(uVar1);
    }
    *(int *)(**(int **)(param_1 + 4) + 8) = iVar4;
    if (piVar6 != (int *)0x0) {
      *(int *)(*piVar6 + 4) = iVar4;
    }
    if (piVar5 != (int *)0x0) {
      *(int *)(*piVar5 + 4) = iVar4;
    }
  }
  return;
}


// ==== .MyCDEF @ 1006e738 ====
// CyDecompAt: created, body 1006e738-1006ebbb

uint _MyCDEF(undefined4 param_1,int *param_2,short param_3,short *param_4)

{
  undefined4 uVar1;
  char cVar3;
  short sVar2;
  uint uVar4;
  int iVar5;
  
  uVar4 = 0;
  if (param_3 == 0x1b) {
    uVar4 = 0x206f6b20;
  }
  else if (param_3 == 3) {
    uVar1 = .debug::_CreateController__13TCDEFRegisterFPP13ControlRecords(param_2,param_1);
    *(undefined4 *)(*param_2 + 0x1c) = uVar1;
  }
  else {
    iVar5 = *(int *)(*param_2 + 0x1c);
    if (iVar5 == 0) {
      uVar4 = 0;
    }
    else {
      cVar3 = .glue::HGetState(param_2);
      .glue::HLock(param_2);
      sVar2 = (short)param_4;
      switch(param_3) {
      case 0:
        if (*(char *)(*param_2 + 0x10) != '\0') {
          FUN_100c50e8(iVar5,param_1,(int)sVar2);
        }
        break;
      case 1:
        sVar2 = FUN_100c50e8(iVar5,param_1,param_4);
        uVar4 = (uint)sVar2;
        break;
      case 2:
        if (((uint)param_4 & 0x80000000) == 0) {
          FUN_100c50e8(iVar5,param_1,(uint)param_4 & 0x7fffffff);
        }
        else {
          FUN_100c50e8(iVar5,param_1,(uint)param_4 & 0x7fffffff);
        }
        break;
      case 4:
        if (iVar5 != 0) {
          FUN_100c50e8(iVar5,1);
        }
        break;
      case 5:
        FUN_100c50e8(iVar5,param_1,(int)(short)((uint)param_4 >> 0x10),(int)sVar2);
        break;
      case 6:
        FUN_100c50e8(iVar5,param_1,param_4,param_4);
        break;
      case 7:
        uVar4 = FUN_100c50e8(iVar5,param_1,param_4 != (short *)0x0);
        uVar4 = uVar4 & 0xff;
        break;
      case 8:
        FUN_100c50e8(iVar5,param_1,(int)sVar2);
        break;
      case 10:
        FUN_100c50e8(iVar5,param_1,param_4);
        break;
      case 0xb:
        FUN_100c50e8(iVar5,param_1,param_4);
        break;
      case 0xd:
        FUN_100c50e8(iVar5,param_1,param_4);
        break;
      case 0xe:
        FUN_100c50e8(iVar5,param_1,param_4 + 1,param_4,param_4 + 2);
        break;
      case 0xf:
        sVar2 = FUN_100c50e8(iVar5,param_1,*(undefined4 *)param_4,(int)param_4[2],
                             *(undefined4 *)(param_4 + 3));
        uVar4 = (uint)sVar2;
        break;
      case 0x10:
        sVar2 = FUN_100c50e8(iVar5,param_1,(int)sVar2);
        uVar4 = (uint)sVar2;
        break;
      case 0x11:
        sVar2 = FUN_100c50e8(iVar5,param_1,(int)param_4[1],(int)param_4[2],(int)*param_4);
        uVar4 = (uint)sVar2;
        break;
      case 0x12:
        FUN_100c50e8(iVar5,param_1);
        break;
      case 0x13:
        uVar4 = FUN_100c50e8(iVar5,param_1);
        break;
      case 0x14:
        sVar2 = FUN_100c50e8(iVar5,param_1,(int)(short)*(undefined4 *)(param_4 + 2),
                             *(undefined4 *)param_4,*(undefined4 *)(param_4 + 6),param_4 + 4);
        uVar4 = (uint)sVar2;
        break;
      case 0x15:
        sVar2 = FUN_100c50e8(iVar5,param_1,(int)(short)*(undefined4 *)(param_4 + 2),
                             *(undefined4 *)param_4,*(undefined4 *)(param_4 + 6),param_4 + 4);
        uVar4 = (uint)sVar2;
        break;
      case 0x16:
        FUN_100c50e8(iVar5,param_1,(uint)param_4 & 0xff);
        break;
      case 0x17:
        FUN_100c50e8(iVar5,param_1,(int)*param_4,*(undefined1 *)(param_4 + 1));
        break;
      case 0x1a:
        FUN_100c50e8(iVar5,param_1,param_4);
      }
      .glue::HSetState(param_2,(int)cVar3);
    }
  }
  return uVar4;
}


// ==== .Draw__5TCDEFFss @ 1006eca4 ====
// CyDecompAt: created, body 1006eca4-1006f0cf

void _Draw__5TCDEFFss(int param_1,short param_2,short param_3)

{
  bool bVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined4 *puVar4;
  short sVar6;
  int *piVar5;
  undefined4 unaff_r19;
  undefined4 unaff_r20;
  undefined4 uVar7;
  undefined4 uVar8;
  int iVar9;
  undefined4 *unaff_r25;
  undefined4 *unaff_r26;
  int iVar10;
  undefined4 uStack_88;
  undefined4 uStack_84;
  int iStack_80;
  undefined4 uStack_7c;
  undefined4 uStack_78;
  undefined4 uStack_74;
  undefined4 uStack_70;
  undefined1 auStack_6c [6];
  undefined1 auStack_66 [6];
  int *piStack_60;
  undefined1 auStack_5c [20];
  undefined4 auStack_48 [4];
  
  uVar8 = 0;
  uVar7 = 0;
  iVar9 = **(int **)(param_1 + 4);
  iVar10 = *(int *)(iVar9 + 4);
  bVar1 = ((int)*(short *)(iVar10 + 6) & 0xc000U) == 0xc000;
  .glue::GetPort(auStack_48);
  .glue::SetPort(iVar10);
  uVar2 = .glue::NewRgn();
  .glue::GetClip();
  uVar3 = .glue::NewRgn();
  .glue::RectRgn(uVar3,iVar9 + 8);
  .glue::SectRgn(uVar3,uVar2,uVar3);
  .glue::SetClip(uVar3);
  .glue::DisposeRgn(uVar3);
  .glue::GetPenState(auStack_5c);
  .glue::PenNormal();
  if (bVar1) {
    .glue::GetForeColor(auStack_66);
    .glue::GetBackColor(auStack_6c);
    .glue::GetAuxWin(iVar10,&piStack_60);
    unaff_r26 = *(undefined4 **)(*piStack_60 + 8);
    unaff_r19 = .glue::HGetState(unaff_r26);
    .glue::HLock(unaff_r26);
    uVar8 = *unaff_r26;
    .glue::GetAuxiliaryControlRecord(*(undefined4 *)(param_1 + 4),&piStack_60);
    unaff_r25 = *(undefined4 **)(*piStack_60 + 8);
    unaff_r20 = .glue::HGetState(unaff_r25);
    .glue::HLock(unaff_r25);
    uVar7 = *unaff_r25;
  }
  uStack_74 = *(undefined4 *)(**(int **)(param_1 + 4) + 8);
  uStack_70 = *(undefined4 *)(**(int **)(param_1 + 4) + 0xc);
  uStack_7c = *(undefined4 *)(**(int **)(param_1 + 4) + 8);
  uStack_78 = *(undefined4 *)(**(int **)(param_1 + 4) + 0xc);
  .glue::LocalToGlobal(&uStack_7c);
  .glue::LocalToGlobal(&uStack_78);
  iStack_80 = 0;
  .glue::GetGWorld(&uStack_84,&uStack_88);
  puVar4 = (undefined4 *)FUN_100c50e8(param_1);
  if (puVar4 == (undefined4 *)0x0) {
    sVar6 = .glue::NewGWorld(&iStack_80,0,&uStack_7c,0,0,0);
    if (sVar6 != 0) {
      iStack_80 = 0;
    }
  }
  else {
    sVar6 = .glue::NewGWorld(&iStack_80,8,&uStack_7c,puVar4,0,0);
    if (sVar6 == 0) {
      uVar3 = *(undefined4 *)*puVar4;
      piVar5 = (int *).glue::GetGWorldPixMap(iStack_80);
      *(undefined4 *)**(undefined4 **)(*piVar5 + 0x2a) = uVar3;
    }
    else {
      iStack_80 = 0;
    }
  }
  if (iStack_80 != 0) {
    .glue::GetGWorldPixMap(iStack_80);
    .glue::LockPixels();
    .glue::SetGWorld(iStack_80,0);
    .glue::SetOrigin((int)uStack_74._2_2_,(int)uStack_74._0_2_);
    if (bVar1) {
      .glue::RGBForeColor(auStack_66);
      .glue::RGBBackColor(auStack_6c);
      if (*(int *)(iVar10 + 0x20) != 0) {
        .glue::FillCRect(&uStack_74,*(undefined4 *)(iVar10 + 0x20));
        *(undefined4 *)(iStack_80 + 0x3e) = 0;
        .glue::PortChanged(iStack_80);
        goto LAB_1006efcc;
      }
    }
    .glue::FillRect(&uStack_74,iVar10 + 0x20);
  }
LAB_1006efcc:
  FUN_100c50e8(param_1,iVar9,(int)param_2,(int)param_3,uVar8,uVar7,bVar1);
  if (iStack_80 != 0) {
    .glue::SetGWorld(uStack_84,uStack_88);
    puVar4 = (undefined4 *).glue::GetGWorldPixMap(iStack_80);
    .glue::CopyBits(*puVar4,iVar10 + 2,&uStack_74,&uStack_74,0,0);
    .glue::DisposeGWorld(iStack_80);
  }
  if (bVar1) {
    .glue::HSetState(unaff_r26,unaff_r19);
    .glue::HSetState(unaff_r25,unaff_r20);
    .glue::RGBForeColor(auStack_66);
    .glue::RGBBackColor(auStack_6c);
  }
  .glue::SetPenState(auStack_5c);
  .glue::SetClip(uVar2);
  .glue::DisposeRgn(uVar2);
  .glue::SetPort(auStack_48[0]);
  return;
}


// ==== .GetPreferedCTable__5TCDEFFv @ 1006f0f4 ====
// CyDecompAt: created, body 1006f0f4-1006f0fb

undefined4 _GetPreferedCTable__5TCDEFFv(void)

{
  return 0;
}


// ==== .DrawAPart__5TCDEFFP13ControlRecordssP10ColorTableP10ColorTableUc @ 1006f12c ====
// CyDecompAt: created, body 1006f12c-1006f12f

void _DrawAPart__5TCDEFFP13ControlRecordssP10ColorTableP10ColorTableUc(void)

{
  return;
}


// ==== .Test__5TCDEFFs5Point @ 1006f184 ====
// CyDecompAt: created, body 1006f184-1006f1db

undefined1 _Test__5TCDEFFs5Point(int param_1,undefined4 param_2,undefined4 param_3)

{
  undefined1 uVar1;
  undefined4 uStack_18;
  undefined4 uStack_14;
  
  uStack_18 = *(undefined4 *)(**(int **)(param_1 + 4) + 8);
  uStack_14 = *(undefined4 *)(**(int **)(param_1 + 4) + 0xc);
  uVar1 = .glue::PtInRect(param_3,&uStack_18);
  return uVar1;
}


// ==== .CalcControlRegion__5TCDEFFsPP9MacRegion @ 1006f204 ====
// CyDecompAt: created, body 1006f204-1006f273

void _CalcControlRegion__5TCDEFFsPP9MacRegion(int param_1,undefined4 param_2,int *param_3)

{
  undefined4 uStack_18;
  undefined4 uStack_14;
  
  if ((param_3 != (int *)0x0) && (*param_3 != 0)) {
    uStack_18 = *(undefined4 *)(**(int **)(param_1 + 4) + 8);
    uStack_14 = *(undefined4 *)(**(int **)(param_1 + 4) + 0xc);
    .glue::RectRgn(param_3,&uStack_18);
  }
  return;
}


// ==== .CalcThumbRegion__5TCDEFFsPP9MacRegion @ 1006f2b0 ====
// CyDecompAt: created, body 1006f2b0-1006f2b3

void _CalcThumbRegion__5TCDEFFsPP9MacRegion(void)

{
  return;
}


// ==== .Pos__5TCDEFFsss @ 1006f2ec ====
// CyDecompAt: created, body 1006f2ec-1006f2ef

void _Pos__5TCDEFFsss(void)

{
  return;
}


// ==== .Thumb__5TCDEFFs5PointP23IndicatorDragConstraint @ 1006f314 ====
// CyDecompAt: created, body 1006f314-1006f317

void _Thumb__5TCDEFFs5PointP23IndicatorDragConstraint(void)

{
  return;
}


// ==== .Drag__5TCDEFFsUc @ 1006f35c ====
// CyDecompAt: created, body 1006f35c-1006f363

undefined4 _Drag__5TCDEFFsUc(void)

{
  return 0;
}


// ==== .Action__5TCDEFFss @ 1006f388 ====
// CyDecompAt: created, body 1006f388-1006f38b

void _Action__5TCDEFFss(void)

{
  return;
}


// ==== .GetFeatures__5TCDEFFs @ 1006f3b0 ====
// CyDecompAt: created, body 1006f3b0-1006f3b7

undefined4 _GetFeatures__5TCDEFFs(void)

{
  return 0;
}


// ==== .GetData__5TCDEFFssUlPcPl @ 1006f3e0 ====
// CyDecompAt: created, body 1006f3e0-1006f3e7

undefined4 _GetData__5TCDEFFssUlPcPl(void)

{
  return 0xffff888b;
}


// ==== .SetData__5TCDEFFssUlPcPl @ 1006f414 ====
// CyDecompAt: created, body 1006f414-1006f41b

undefined4 _SetData__5TCDEFFssUlPcPl(void)

{
  return 0xffff888b;
}


// ==== .DrawGhost__5TCDEFFsPP9MacRegion @ 1006f448 ====
// CyDecompAt: created, body 1006f448-1006f44b

void _DrawGhost__5TCDEFFsPP9MacRegion(void)

{
  return;
}


// ==== .CalcValueFromPos__5TCDEFFsPP9MacRegion @ 1006f480 ====
// CyDecompAt: created, body 1006f480-1006f483

void _CalcValueFromPos__5TCDEFFsPP9MacRegion(void)

{
  return;
}


// ==== .CalcBestRect__5TCDEFFsPsPsPs @ 1006f4c0 ====
// CyDecompAt: created, body 1006f4c0-1006f4c3

void _CalcBestRect__5TCDEFFsPsPsPs(void)

{
  return;
}


// ==== .HandleTracking__5TCDEFFs5PointsP17RoutineDescriptor @ 1006f4f4 ====
// CyDecompAt: created, body 1006f4f4-1006f4fb

undefined4 _HandleTracking__5TCDEFFs5PointsP17RoutineDescriptor(void)

{
  return 0;
}


// ==== .Focus__5TCDEFFss @ 1006f544 ====
// CyDecompAt: created, body 1006f544-1006f54b

undefined4 _Focus__5TCDEFFss(void)

{
  return 0;
}


// ==== .Idle__5TCDEFFs @ 1006f570 ====
// CyDecompAt: created, body 1006f570-1006f573

void _Idle__5TCDEFFs(void)

{
  return;
}


// ==== .Activate__5TCDEFFsUc @ 1006f598 ====
// CyDecompAt: created, body 1006f598-1006f59b

void _Activate__5TCDEFFsUc(void)

{
  return;
}


// ==== .SetUpBackground__5TCDEFFssUc @ 1006f5c4 ====
// CyDecompAt: created, body 1006f5c4-1006f5c7

void _SetUpBackground__5TCDEFFssUc(void)

{
  return;
}


// ==== .KeyDown__5TCDEFFssss @ 1006f5f8 ====
// CyDecompAt: created, body 1006f5f8-1006f5ff

undefined4 _KeyDown__5TCDEFFssss(void)

{
  return 0;
}


// ==== .MyWDEF @ 1006f9ac ====
// CyDecompAt: created, body 1006f9ac-1006fc0f

int _MyWDEF(undefined4 param_1,int param_2,short param_3,undefined4 *param_4)

{
  bool bVar1;
  undefined4 uVar2;
  short sVar3;
  undefined4 unaff_r23;
  int iVar4;
  int iVar5;
  int iStack_38;
  undefined4 uStack_34;
  undefined4 uStack_30;
  undefined4 auStack_2c [2];
  
  iVar4 = 0;
  if (param_3 == 3) {
    uVar2 = .debug::_CreateController__13TWDEFRegisterFP12WindowRecords(param_2,param_1);
    *(undefined4 *)(param_2 + 0x82) = uVar2;
  }
  else {
    bVar1 = false;
    if ((((param_3 == 0) || (param_3 == 1)) || (param_3 == 5)) || (param_3 == 6)) {
      bVar1 = true;
    }
    if (bVar1) {
      .glue::GetPort(auStack_2c);
      unaff_r23 = .debug::_SyncPorts__Fv();
    }
    iVar5 = *(int *)(param_2 + 0x82);
    if (iVar5 == 0) {
      iVar4 = 0;
    }
    else {
      switch(param_3) {
      case 0:
        if (*(char *)(param_2 + 0x6e) != '\0') {
          FUN_100c50e8(iVar5,param_1,(int)(short)param_4);
        }
        break;
      case 1:
        sVar3 = FUN_100c50e8(iVar5,param_1,param_4);
        iVar4 = (int)sVar3;
        break;
      case 2:
        uStack_34 = *(undefined4 *)(*(int *)(iVar5 + 4) + 0x10);
        uStack_30 = *(undefined4 *)(*(int *)(iVar5 + 4) + 0x14);
        .glue::OffsetRect(&uStack_34,-(int)*(short *)(*(int *)(iVar5 + 4) + 10),
                          -(int)*(short *)(*(int *)(iVar5 + 4) + 8));
        FUN_100c50e8(iVar5,param_1,&uStack_34);
        break;
      case 4:
        if (iVar5 != 0) {
          FUN_100c50e8(iVar5,1);
        }
        break;
      case 5:
        FUN_100c50e8(iVar5,param_1,param_4);
        break;
      case 6:
        FUN_100c50e8(iVar5,param_1);
        break;
      case 7:
        iVar4 = FUN_100c50e8(iVar5,param_1);
        break;
      case 8:
        sVar3 = FUN_100c50e8(iVar5,param_1,*param_4,(int)*(short *)(param_4 + 1));
        iVar4 = (int)sVar3;
      }
      if (bVar1) {
        .glue::GetCWMgrPort(&iStack_38);
        *(undefined4 *)(iStack_38 + 0x3e) = unaff_r23;
        .glue::SetPort(auStack_2c[0]);
      }
    }
  }
  return iVar4;
}


// ==== .Draw__5TWDEFFss @ 1006fd00 ====
// CyDecompAt: created, body 1006fd00-1006fe37

void _Draw__5TWDEFFss(int param_1,undefined4 param_2,short param_3)

{
  if (param_3 == 4) {
    *(bool *)(param_1 + 8) = *(char *)(param_1 + 8) == '\0';
    if (*(char *)(*(int *)(param_1 + 4) + 0x70) != '\0') {
      FUN_100c50e8(param_1,param_2,*(undefined1 *)(param_1 + 8));
    }
  }
  else if ((param_3 == 5) || (param_3 == 6)) {
    *(bool *)(param_1 + 9) = *(char *)(param_1 + 9) == '\0';
    if (*(char *)(*(int *)(param_1 + 4) + 0x71) != '\0') {
      FUN_100c50e8(param_1,param_2,*(undefined1 *)(param_1 + 9));
    }
  }
  else if (*(char *)(*(int *)(param_1 + 4) + 0x6f) == '\0') {
    FUN_100c50e8(param_1,param_2);
  }
  else {
    FUN_100c50e8(param_1,param_2,*(undefined1 *)(*(int *)(param_1 + 4) + 0x70),
                 *(undefined1 *)(*(int *)(param_1 + 4) + 0x71));
  }
  return;
}


// ==== .DrawUnhilited__5TWDEFFs @ 1006fe5c ====
// CyDecompAt: created, body 1006fe5c-1006fe5f

void _DrawUnhilited__5TWDEFFs(void)

{
  return;
}


// ==== .DrawHilited__5TWDEFFsUcUc @ 1006fe8c ====
// CyDecompAt: created, body 1006fe8c-1006fe8f

void _DrawHilited__5TWDEFFsUcUc(void)

{
  return;
}


// ==== .HiliteCloseBox__5TWDEFFsUc @ 1006febc ====
// CyDecompAt: created, body 1006febc-1006febf

void _HiliteCloseBox__5TWDEFFsUc(void)

{
  return;
}


// ==== .HiliteZoomBox__5TWDEFFsUc @ 1006fef0 ====
// CyDecompAt: created, body 1006fef0-1006fef3

void _HiliteZoomBox__5TWDEFFsUc(void)

{
  return;
}


// ==== .Grow__5TWDEFFsP4Rect @ 1006ff20 ====
// CyDecompAt: created, body 1006ff20-1006ff53

void _Grow__5TWDEFFsP4Rect(int param_1)

{
  .glue::FrameRgn(*(undefined4 *)(*(int *)(param_1 + 4) + 0x72));
  return;
}


// ==== .DrawSizeBox__5TWDEFFs @ 1006ff7c ====
// CyDecompAt: created, body 1006ff7c-1006ff7f

void _DrawSizeBox__5TWDEFFs(void)

{
  return;
}


// ==== .GetFeatures__5TWDEFFs @ 1006ffa8 ====
// CyDecompAt: created, body 1006ffa8-1006ffaf

undefined4 _GetFeatures__5TWDEFFs(void)

{
  return 0;
}


// ==== .GetRegion__5TWDEFFsPP9MacRegions @ 1006ffd8 ====
// CyDecompAt: created, body 1006ffd8-1006ffdf

undefined4 _GetRegion__5TWDEFFsPP9MacRegions(void)

{
  return 0xffff887f;
}


// ==== .__dt__9TSaveFontFv @ 10070db8 ====
// CyDecompAt: created, body 10070db8-10070e27

short * ___dt__9TSaveFontFv(short *param_1,short param_2)

{
  if (param_1 != (short *)0x0) {
    .glue::TextFont((int)*param_1);
    .glue::TextFace((int)param_1[1]);
    .glue::TextSize((int)param_1[2]);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .DelverDialogerRoutine @ 1007305c ====
// CyDecompAt: created, body 1007305c-100732f7

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 _DelverDialogerRoutine(uint param_1,ushort *param_2,short *param_3)

{
  uint uVar1;
  undefined4 uVar2;
  int iVar3;
  int iVar4;
  short sVar5;
  byte abStack_8136 [32694];
  undefined1 auStack_148 [4];
  undefined4 uStack_144;
  undefined1 auStack_140 [2];
  undefined4 uStack_13e;
  undefined4 uStack_13a;
  byte abStack_136 [258];
  undefined1 auStack_34 [4];
  undefined1 auStack_30 [2];
  undefined4 uStack_2e;
  undefined4 uStack_2a;
  undefined4 auStack_24 [4];
  
  if (*param_2 == 6) {
    if (*param_2 != param_1) {
      iVar3 = *(int *)PTR_DAT_100cdb84;
      uVar2 = *(undefined4 *)(param_2 + 2);
      *(undefined4 *)(iVar3 + 4) = *(undefined4 *)param_2;
      *(undefined4 *)(iVar3 + 8) = uVar2;
      uVar2 = *(undefined4 *)(param_2 + 6);
      *(undefined4 *)(iVar3 + 0xc) = *(undefined4 *)(param_2 + 4);
      *(undefined4 *)(iVar3 + 0x10) = uVar2;
      FUN_100c50e8();
    }
    .glue::GetPort(auStack_24);
    .glue::SetPort(param_1);
    .debug::_SetTilePat__Fs(0x1a4);
    .glue::BackPixPat();
    uStack_2e = *(undefined4 *)(param_1 + 0x10);
    uStack_2a = *(undefined4 *)(param_1 + 0x14);
    uVar2 = .debug::_SetTilePat__Fs(0x1a4);
    .glue::FillCRect(&uStack_2e,uVar2);
    .glue::DrawDialog(param_1);
    .glue::ValidRect(param_1 + 0x10);
    .glue::GetDialogItem(param_1,(int)_DAT_100d637c,auStack_30,auStack_34,&uStack_2e);
    .glue::InsetRect(&uStack_2e,0xfffffffb,0xfffffffb);
    .debug::_Bevel__FRC4Rects(&uStack_2e,3);
    .glue::SetPort(auStack_24[0]);
    return 0;
  }
  if (*param_2 != 3) {
    return 0;
  }
  .glue::GetWTitle(param_1,abStack_136);
  uVar1 = *(uint *)(param_2 + 1) & 0xff;
  if (uVar1 == 0x1b) {
    iVar3 = 2;
  }
  else {
    if (uVar1 < 0x1b) {
      if ((uVar1 == 0xd) || ((uVar1 < 0xd && (uVar1 == 3)))) {
        iVar3 = (int)_DAT_100d637c;
        goto LAB_1007326c;
      }
    }
    else if (uVar1 == 0x2e) {
      iVar3 = 0;
      if ((param_2[7] & 0x100) != 0) {
        iVar3 = 2;
      }
      goto LAB_1007326c;
    }
    iVar4 = 1;
    for (sVar5 = 1; iVar3 = 0, sVar5 < (short)(ushort)abStack_136[0]; sVar5 = sVar5 + 1) {
      if (abStack_136[sVar5] == 0x3b) {
        iVar4 = iVar4 + 1;
      }
      else {
        iVar3 = iVar4;
        if ((uint)abStack_136[sVar5] == (*(uint *)(param_2 + 1) & 0xff)) break;
      }
    }
  }
LAB_1007326c:
  if ((short)iVar3 == 0) {
    return 0;
  }
  *param_3 = (short)iVar3;
  uStack_13e = *(undefined4 *)(param_1 + 0x10);
  uStack_13a = *(undefined4 *)(param_1 + 0x14);
  .glue::GetDialogItem(param_1,iVar3,auStack_140,&uStack_144,&uStack_13e);
  .glue::HiliteControl(uStack_144,10);
  .glue::Delay(8,auStack_148);
  .glue::HiliteControl(uStack_144,0);
  return 1;
}


// ==== .ExactMatchRoutine @ 1007378c ====
// CyDecompAt: created, body 1007378c-100737eb

bool _ExactMatchRoutine(undefined4 param_1,byte *param_2)

{
  int *piVar1;
  
  piVar1 = (int *).glue::GetGDevice();
  return (uint)*param_2 != *(uint *)(*(int *)(*piVar1 + 0x1a) + 6);
}


// ==== .__dt__13THandleLockerFv @ 10073c78 ====
// CyDecompAt: created, body 10073c78-10073cd7

undefined4 * ___dt__13THandleLockerFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    .glue::HSetState(*param_1,(int)(char)*(undefined2 *)(param_1 + 1));
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .GetData__27TPixCacheFromCachedSegFilesFs @ 10074224 ====
// CyDecompAt: created, body 10074224-10074263

void _GetData__27TPixCacheFromCachedSegFilesFs(int param_1,short param_2)

{
  .debug::_GetSegment__15TCachedSegFilesFUs(*(undefined4 *)(param_1 + 0xa08),param_2 + 0x8f00);
  return;
}


// ==== .DoneData__27TPixCacheFromCachedSegFilesFPc @ 100742a0 ====
// CyDecompAt: created, body 100742a0-100742f3

void _DoneData__27TPixCacheFromCachedSegFilesFPc(int param_1,int param_2)

{
  if (param_2 != 0) {
    .debug::_Free__6TCacheFPvUc(**(undefined4 **)(param_1 + 0xa08),param_2,1);
  }
  return;
}


// ==== .DoneData__13TPixCacheBaseFPc @ 10074660 ====
// CyDecompAt: created, body 10074660-10074663

void _DoneData__13TPixCacheBaseFPc(void)

{
  return;
}


// ==== .DoBresPixel__5TBresFl @ 10074a54 ====
// CyDecompAt: created, body 10074a54-10074a5b

undefined4 _DoBresPixel__5TBresFl(void)

{
  return 1;
}


// ==== .LDEFDraw__9TToDoListFUcP4Rect5Pointss @ 10076a44 ====
// CyDecompAt: created, body 10076a44-10076c73

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _LDEFDraw__9TToDoListFUcP4Rect5Pointss
               (int param_1,char param_2,short *param_3,undefined4 param_4,undefined4 param_5,
               short param_6)

{
  uint uVar1;
  int iVar2;
  short sVar3;
  int iStack_58;
  undefined4 uStack_54;
  undefined4 uStack_50;
  undefined4 uStack_4c;
  undefined4 uStack_48;
  undefined4 uStack_44;
  undefined4 uStack_40;
  undefined4 uStack_3c;
  undefined4 uStack_38;
  undefined4 uStack_34;
  undefined4 uStack_30;
  undefined4 uStack_2c;
  undefined2 uStack_28;
  undefined4 uStack_26;
  undefined4 uStack_22;
  undefined4 uStack_1e;
  undefined4 uStack_1a;
  char *apcStack_14 [2];
  
  .glue::EraseRect(param_3);
  if (param_6 == 4) {
    apcStack_14[0] = (char *)0x0;
    .glue::LGetCell(apcStack_14,&stack0x0000002e,param_4,*(undefined4 *)(param_1 + 4));
    uStack_26 = _DAT_100d6418;
    uStack_22 = uRam100d641c;
    uVar1 = (int)*param_3 + (int)param_3[2];
    uStack_1e = uStack_26;
    uStack_1a = uStack_22;
    .glue::OffsetRect(&uStack_26,param_3[1] + 2,
                      ((int)uVar1 >> 1) + (uint)((int)uVar1 < 0 && (uVar1 & 1) != 0) + -8);
    uStack_54 = uRam100d3de8;
    uStack_50 = uRam100d3dec;
    uStack_4c = uRam100d3df0;
    uStack_48 = uRam100d3df4;
    uStack_44 = uRam100d3df8;
    uStack_40 = uRam100d3dfc;
    uStack_3c = uRam100d3e00;
    uStack_38 = uRam100d3e04;
    uStack_34 = uRam100d3e08;
    uStack_30 = uRam100d3e0c;
    uStack_2c = uRam100d3e10;
    uStack_28 = uRam100d3e14;
    iStack_58 = *(int *)PTR_DAT_100cdc64 + 0x6ac00;
    if (*apcStack_14[0] != '\0') {
      .glue::OffsetRect(&uStack_1e,0x10,0);
    }
    .glue::CopyBits(&iStack_58,*(int *)(PTR_DAT_100cdb94 + 0xca) + 2,&uStack_1e,&uStack_26,0x24,0);
    iVar2 = .debug::_VAddrToPtr__7TInterpF5VAddr(*(undefined4 *)(apcStack_14[0] + 4));
    .glue::MoveTo(uStack_22._2_2_ + 3,uStack_22._0_2_ + -4);
    .debug::_SetText__Fs(4);
    if (iVar2 != 0) {
      sVar3 = FUN_100b6ce8(iVar2);
      .debug::_AADrawText__FPcss(iVar2,0,(int)sVar3);
    }
    if (param_2 != '\0') {
      uVar1 = .glue::LMGetHiliteMode();
      .glue::LMSetHiliteMode(uVar1 & 0xffffff7f);
      .glue::InvertRect(param_3);
    }
  }
  return;
}


// ==== .LDEFHilite__9TToDoListFUcP4Rect5Pointss @ 10076cac ====
// CyDecompAt: created, body 10076cac-10076ceb

void _LDEFHilite__9TToDoListFUcP4Rect5Pointss
               (undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  uint uVar1;
  
  uVar1 = .glue::LMGetHiliteMode();
  .glue::LMSetHiliteMode(uVar1 & 0xffffff7f);
  .glue::InvertRect(param_3);
  return;
}


// ==== .__dt__13TDrawerWindowFv @ 100770f8 ====
// CyDecompAt: created, body 100770f8-1007715b

undefined4 * ___dt__13TDrawerWindowFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d7f10;
    .debug::___dt__7TWindowFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__5TToDoFv @ 10077188 ====
// CyDecompAt: created, body 10077188-10077207

undefined4 * ___dt__5TToDoFv(undefined4 *param_1,short param_2)

{
  undefined *puVar1;
  
  puVar1 = PTR_DAT_100cddfc;
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d645c;
    *(undefined4 *)puVar1 = 0;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d7f10;
      .debug::___dt__7TWindowFv(param_1,0);
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .CloseRoutine__5TToDoFv @ 1007722c ====
// CyDecompAt: created, body 1007722c-100772b3

void _CloseRoutine__5TToDoFv(int param_1)

{
  .glue::HideWindow(*(undefined4 *)(param_1 + 4));
  if (*(int *)(param_1 + 0x10) != 0) {
    FUN_100c50e8(*(int *)(param_1 + 0x10),1);
  }
  .glue::DisposeWindow(*(undefined4 *)(param_1 + 4));
  *(undefined4 *)(param_1 + 4) = 0;
  if (param_1 != 0) {
    FUN_100c50e8(param_1,1);
  }
  return;
}


// ==== .__dt__9TToDoListFv @ 100772e0 ====
// CyDecompAt: created, body 100772e0-10077343

undefined4 * ___dt__9TToDoListFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d6520;
    .debug::___dt__8TListBoxFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .DrawRoutine__5TToDoFv @ 1007736c ====
// CyDecompAt: created, body 1007736c-100773bf

void _DrawRoutine__5TToDoFv(int param_1)

{
  .glue::EraseRect(*(int *)(param_1 + 4) + 0x10);
  FUN_100c50e8(*(undefined4 *)(param_1 + 0x10),*(undefined4 *)(*(int *)(param_1 + 4) + 0x18));
  return;
}


// ==== .MouseRoutine__5TToDoF5Points @ 100773e8 ====
// CyDecompAt: created, body 100773e8-1007758b

void _MouseRoutine__5TToDoF5Points(int param_1,undefined4 param_2,short param_3)

{
  undefined *puVar1;
  char cVar2;
  ushort uVar4;
  undefined4 uVar3;
  undefined4 uStack_38;
  undefined2 auStack_34 [2];
  char *pcStack_30;
  int iStack_2c;
  
  puVar1 = PTR_DAT_100cdb98;
  FUN_100c50e8(*(undefined4 *)(param_1 + 0x10),param_2,(int)param_3);
  uVar4 = FUN_100c50e8();
  if (-1 < (short)uVar4) {
    iStack_2c = (uint)uVar4 << 0x10;
    auStack_34[0] = 4;
    .glue::LGetCell(&pcStack_30,auStack_34,iStack_2c,*(undefined4 *)(*(int *)(param_1 + 0x10) + 4));
    .debug::_myprintf__13TStatusWindowFPce(*(undefined4 *)puVar1,PTR_s_>_To_Do_Details____100cec0c);
    if (pcStack_30[4] < '\0') {
      cVar2 = -1;
    }
    else {
      cVar2 = pcStack_30[4] >> 4;
    }
    if (cVar2 == '\x03') {
      uStack_38._0_2_ = (ushort)((uint)*(undefined4 *)(pcStack_30 + 4) >> 0x10);
      uStack_38 = CONCAT22(uStack_38._0_2_ & 0xf000 | (uStack_38._0_2_ & 0xfff) + 0x400,
                           (short)*(undefined4 *)(pcStack_30 + 4));
      uVar3 = .debug::_VAddrToPtr__7TInterpF5VAddr(uStack_38);
      .debug::_myprintf__13TStatusWindowFPce(*(undefined4 *)puVar1,PTR_DAT_100cec08,uVar3);
    }
    else {
      uVar3 = .debug::_VAddrToPtr__7TInterpF5VAddr(*(undefined4 *)(pcStack_30 + 4));
      .debug::_myprintf__13TStatusWindowFPce
                (*(undefined4 *)puVar1,PTR_s__s__no_further_info_available__100cec04,uVar3);
    }
    if (*pcStack_30 == '\0') {
      .debug::_myprintf__13TStatusWindowFPce
                (*(undefined4 *)puVar1,PTR_s_This_task_is_not_yet_completed__100cebfc);
    }
    else {
      .debug::_myprintf__13TStatusWindowFPce
                (*(undefined4 *)puVar1,PTR_s_This_task_is_done__100cec00);
    }
    FUN_100c50e8(*(undefined4 *)(param_1 + 0x10),0xffffffff);
  }
  return;
}


// ==== .ResizeRoutine__5TToDoFv @ 100775bc ====
// CyDecompAt: created, body 100775bc-10077623

void _ResizeRoutine__5TToDoFv(int param_1)

{
  FUN_100c50e8(*(undefined4 *)(param_1 + 0x10),
               ((int)*(short *)(*(int *)(param_1 + 4) + 0x16) -
               (int)*(short *)(*(int *)(param_1 + 4) + 0x12)) + -0x10,
               (int)*(short *)(*(int *)(param_1 + 4) + 0x14) -
               (int)*(short *)(*(int *)(param_1 + 4) + 0x10));
  return;
}


// ==== .BecomeVisible__5TToDoFv @ 10077650 ====
// CyDecompAt: created, body 10077650-1007767b

void _BecomeVisible__5TToDoFv(int param_1)

{
  .debug::_RebuildList__9TToDoListFv(*(undefined4 *)(param_1 + 0x10));
  return;
}


// ==== .__ct__Q25TToDo9ToDoEntryFv @ 10077a44 ====
// CyDecompAt: created, body 10077a44-10077a4f

void ___ct__Q25TToDo9ToDoEntryFv(int param_1)

{
  *(undefined4 *)(param_1 + 4) = 0;
  return;
}


// ==== .LDEFDraw__12TJournalListFUcP4Rect5Pointss @ 10078100 ====
// CyDecompAt: created, body 10078100-100783d7

/* WARNING: Removing unreachable block (ram,0x100781d4) */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _LDEFDraw__12TJournalListFUcP4Rect5Pointss
               (int param_1,char param_2,short *param_3,undefined4 param_4,short param_5,
               short param_6)

{
  byte bVar1;
  int iVar2;
  undefined *puVar3;
  undefined *puVar4;
  uint uVar5;
  short sVar8;
  uint uVar6;
  uint uVar7;
  undefined4 *puVar9;
  byte *pbVar10;
  undefined1 auStack_78 [16];
  int iStack_68;
  undefined1 auStack_64 [32];
  undefined4 uStack_44;
  undefined2 uStack_40;
  
  puVar4 = PTR_DAT_100cec30;
  puVar3 = PTR_DAT_100cec28;
  iVar2 = _DAT_100cdb90;
  .glue::EraseRect(param_3);
  if (param_6 != 0) {
    pbVar10 = (byte *)(**(int **)(**(int **)(param_1 + 4) + 0x50) + (int)param_5);
    .debug::_SetText__Fs(4);
    puVar9 = (undefined4 *)
             (**(int **)PTR_DAT_100cdc78 + *(short *)(&DAT_100d6578 + (uint)*pbVar10 * 2) * 8 + 10);
    uStack_44 = *puVar9;
    uStack_40 = *(undefined2 *)(puVar9 + 1);
    .glue::RGBForeColor(&uStack_44);
    bVar1 = pbVar10[1];
    if (bVar1 == 0xff) {
      iStack_68 = (int)*(short *)(pbVar10 + 8);
      .debug::___ct__15TJournalSegmentFl(auStack_78,*(undefined4 *)(pbVar10 + 4));
      .debug::_Read__15TJournalSegmentFPlPv(auStack_78,&iStack_68,puVar4);
      uVar5 = (int)param_3[2] + (int)*param_3;
      uVar7 = (uint)*(short *)(iVar2 + 0x20);
      .glue::MoveTo(param_3[1] + 0xc,
                    (int)(short)((short)((int)uVar5 >> 1) +
                                (ushort)((int)uVar5 < 0 && (uVar5 & 1) != 0)) +
                    ((int)uVar7 >> 1) + (uint)((int)uVar7 < 0 && (uVar7 & 1) != 0));
      .debug::_AADrawText__FPcss(puVar4,0,(int)(short)iStack_68);
      .debug::___dt__15TJournalSegmentFv(auStack_78,0xffffffff);
    }
    else if ((bVar1 != 0xff) && (bVar1 < 3)) {
      FUN_100b6a80(puVar4,PTR_s_Day__d_100cec2c,pbVar10[8]);
      uVar5 = (int)param_3[2] + (int)*param_3;
      uVar7 = (uint)*(short *)(iVar2 + 0x20);
      .glue::MoveTo(param_3[1] + 2,
                    (int)(short)((short)((int)uVar5 >> 1) +
                                (ushort)((int)uVar5 < 0 && (uVar5 & 1) != 0)) +
                    ((int)uVar7 >> 1) + (uint)((int)uVar7 < 0 && (uVar7 & 1) != 0));
      sVar8 = FUN_100b6ce8(puVar4);
      .debug::_AADrawText__FPcss(puVar4,0,(int)sVar8);
      uVar7 = (int)param_3[1] + (int)param_3[3];
      uVar5 = (uint)*(short *)(iVar2 + 0x20);
      uVar6 = (int)param_3[2] + (int)*param_3;
      .glue::MoveTo((int)(short)((short)((int)uVar7 >> 1) +
                                (ushort)((int)uVar7 < 0 && (uVar7 & 1) != 0)),
                    (int)(short)((short)((int)uVar6 >> 1) +
                                (ushort)((int)uVar6 < 0 && (uVar6 & 1) != 0)) +
                    ((int)uVar5 >> 1) + (uint)((int)uVar5 < 0 && (uVar5 & 1) != 0));
      if (pbVar10[1] == 2) {
        .debug::_AADrawText__FPcss(puVar3 + 1,0,*puVar3);
      }
      else if (pbVar10[1] == 0) {
        .debug::_GetCharacterName__FsPcUc(pbVar10[9],auStack_64,0);
        FUN_100b6a80(puVar4,PTR_s__s_said__100c6ffd_5_100cec24,auStack_64);
        sVar8 = FUN_100b6ce8(puVar4);
        .debug::_AADrawText__FPcss(puVar4,0,(int)sVar8);
      }
    }
    .glue::ForeColor(0x21);
    if (param_2 != '\0') {
      uVar7 = .glue::LMGetHiliteMode();
      .glue::LMSetHiliteMode(uVar7 & 0xffffff7f);
      .glue::InvertRect(param_3);
    }
  }
  return;
}


// ==== .LDEFHilite__12TJournalListFUcP4Rect5Pointss @ 10078414 ====
// CyDecompAt: created, body 10078414-10078453

void _LDEFHilite__12TJournalListFUcP4Rect5Pointss
               (undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  uint uVar1;
  
  uVar1 = .glue::LMGetHiliteMode();
  .glue::LMSetHiliteMode(uVar1 & 0xffffff7f);
  .glue::InvertRect(param_3);
  return;
}


// ==== .__dt__8TJournalFv @ 10078954 ====
// CyDecompAt: created, body 10078954-100789c7

undefined4 * ___dt__8TJournalFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d65bc;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d7f10;
      .debug::___dt__7TWindowFv(param_1,0);
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .CloseRoutine__8TJournalFv @ 100789ec ====
// CyDecompAt: created, body 100789ec-10078a67

void _CloseRoutine__8TJournalFv(int param_1)

{
  .glue::HideWindow(*(undefined4 *)(param_1 + 4));
  if (*(int *)(param_1 + 0x10) != 0) {
    FUN_100c50e8(*(int *)(param_1 + 0x10),1);
  }
  *(undefined4 *)(param_1 + 4) = 0;
  if (param_1 != 0) {
    FUN_100c50e8(param_1,1);
  }
  return;
}


// ==== .__dt__12TJournalListFv @ 10078a94 ====
// CyDecompAt: created, body 10078a94-10078af7

undefined4 * ___dt__12TJournalListFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d6680;
    .debug::___dt__8TListBoxFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .DrawRoutine__8TJournalFv @ 10078b24 ====
// CyDecompAt: created, body 10078b24-10078b77

void _DrawRoutine__8TJournalFv(int param_1)

{
  .glue::EraseRect(*(int *)(param_1 + 4) + 0x10);
  FUN_100c50e8(*(undefined4 *)(param_1 + 0x10),*(undefined4 *)(*(int *)(param_1 + 4) + 0x18));
  return;
}


// ==== .MouseRoutine__8TJournalF5Points @ 10078ba4 ====
// CyDecompAt: created, body 10078ba4-1007916b

void _MouseRoutine__8TJournalF5Points(int param_1,undefined4 param_2,short param_3)

{
  byte bVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined4 uVar4;
  short sVar5;
  char cVar6;
  int iVar7;
  byte *pbVar8;
  int iStack_9c;
  char cStack_98;
  int iStack_94;
  undefined4 uStack_90;
  undefined1 auStack_8c [16];
  undefined1 auStack_7c [16];
  undefined4 uStack_6c;
  undefined1 auStack_68 [3];
  undefined1 uStack_65;
  char cStack_63;
  undefined4 uStack_62;
  short sStack_5e;
  short asStack_5c [2];
  int iStack_58;
  undefined4 uStack_54;
  char cStack_50;
  int iStack_4e;
  short sStack_4a;
  undefined1 auStack_48 [8];
  
  puVar2 = PTR_DAT_100cec18;
  sStack_4a = .glue::FindControl(param_2,*(undefined4 *)(PTR_DAT_100cdb94 + 0xca),auStack_48);
  if (sStack_4a == 0) {
    .debug::_PointToCell__8TListBoxF5Point(&iStack_9c,*(undefined4 *)(param_1 + 0x10),param_2);
    puVar3 = PTR_DAT_100cec1c;
    iStack_4e = iStack_9c;
    cStack_50 = (char)(iStack_9c >> 0x17) + '\x01';
    if (*PTR_DAT_100cec1c == '\0') {
      *(undefined4 *)puVar2 = 0;
      *puVar3 = 1;
    }
    if (*(int *)puVar2 == 0) {
      uVar4 = .glue::GetMenu(0x89);
      *(undefined4 *)puVar2 = uVar4;
      .glue::InsertMenu(*(undefined4 *)puVar2,0xffffffff);
    }
    if (iStack_4e < 0) {
      for (iVar7 = 1; (short)iVar7 < 8; iVar7 = iVar7 + 1) {
        .glue::DisableItem(*(undefined4 *)puVar2,iVar7);
      }
      .glue::EnableItem(*(undefined4 *)puVar2,1);
      uStack_54 = param_2;
      .glue::LocalToGlobal(&uStack_54);
      sVar5 = .glue::PopUpMenuSelect
                        (*(undefined4 *)puVar2,(int)uStack_54._0_2_,(int)uStack_54._2_2_,1);
      iStack_58 = (int)sVar5;
      for (iVar7 = 1; (short)iVar7 < 8; iVar7 = iVar7 + 1) {
        .glue::EnableItem(*(undefined4 *)puVar2,iVar7);
      }
      if (iStack_58 == 1) {
        .debug::_MakeNote__8TJournalFv();
      }
    }
    else {
      .glue::LGetCellDataLocation
                (asStack_5c,&sStack_5e,iStack_4e,*(undefined4 *)(*(int *)(param_1 + 0x10) + 4));
      pbVar8 = (byte *)(**(int **)(**(int **)(*(int *)(param_1 + 0x10) + 4) + 0x50) +
                       (int)asStack_5c[0]);
      while (pbVar8[1] == 0xff) {
        iStack_4e = CONCAT22(iStack_4e._0_2_ + -1,iStack_4e._2_2_);
        .glue::LGetCellDataLocation
                  (asStack_5c,&sStack_5e,iStack_4e,*(undefined4 *)(*(int *)(param_1 + 0x10) + 4));
        pbVar8 = (byte *)(**(int **)(**(int **)(*(int *)(param_1 + 0x10) + 4) + 0x50) +
                         (int)asStack_5c[0]);
      }
      uStack_62 = 0;
      while (cVar6 = .glue::LGetSelect(1,&uStack_62,*(undefined4 *)(*(int *)(param_1 + 0x10) + 4)),
            cVar6 != '\0') {
        .glue::LSetSelect(0,uStack_62,*(undefined4 *)(*(int *)(param_1 + 0x10) + 4));
      }
      uStack_6c = 6;
      .debug::___ct__15TJournalSegmentFl(auStack_7c,*(undefined4 *)(pbVar8 + 4));
      .debug::_Read__15TJournalSegmentFPlPv(auStack_7c,&uStack_6c,auStack_68);
      .debug::___dt__15TJournalSegmentFv(auStack_7c,0xffffffff);
      .debug::___ct__15TJournalSegmentFl(auStack_8c,*(undefined4 *)(pbVar8 + 4));
      bVar1 = *pbVar8;
      .glue::LSetSelect(1,iStack_4e,*(undefined4 *)(*(int *)(param_1 + 0x10) + 4));
      iStack_4e = CONCAT22(iStack_4e._0_2_ + 1,iStack_4e._2_2_);
      .glue::LGetCellDataLocation
                (asStack_5c,&sStack_5e,iStack_4e,*(undefined4 *)(*(int *)(param_1 + 0x10) + 4));
      iVar7 = **(int **)(**(int **)(*(int *)(param_1 + 0x10) + 4) + 0x50) + (int)asStack_5c[0];
      while ((sStack_5e != 0 && (*(char *)(iVar7 + 1) == -1))) {
        .glue::LSetSelect(1,iStack_4e,*(undefined4 *)(*(int *)(param_1 + 0x10) + 4));
        iStack_4e = CONCAT22(iStack_4e._0_2_ + 1,iStack_4e._2_2_);
        .glue::LGetCellDataLocation
                  (asStack_5c,&sStack_5e,iStack_4e,*(undefined4 *)(*(int *)(param_1 + 0x10) + 4));
        iVar7 = **(int **)(**(int **)(*(int *)(param_1 + 0x10) + 4) + 0x50) + (int)asStack_5c[0];
      }
      iVar7 = 4;
      while( true ) {
        if (7 < (short)iVar7) break;
        .glue::CheckItem(*(undefined4 *)puVar2,iVar7,(int)(short)(ushort)bVar1 == (short)iVar7 + -4)
        ;
        iVar7 = iVar7 + 1;
      }
      uStack_90 = param_2;
      .glue::LocalToGlobal(&uStack_90);
      sVar5 = .glue::PopUpMenuSelect
                        (*(undefined4 *)puVar2,(int)uStack_90._0_2_,(int)uStack_90._2_2_,bVar1 + 4);
      cStack_98 = '\0';
      iStack_94 = (int)sVar5;
      if (iStack_94 == 2) {
        uStack_6c = 6;
        uStack_65 = 3;
        .debug::_Write__15TJournalSegmentFPlPv(auStack_8c,&uStack_6c,auStack_68);
        .debug::_Flush__15TJournalSegmentFv(auStack_8c);
        cStack_98 = '\x01';
      }
      else {
        if ((iStack_94 < 2) && (0 < iStack_94)) {
          .debug::_MakeNote__8TJournalFv();
          .debug::___dt__15TJournalSegmentFv(auStack_8c,0xffffffff);
          return;
        }
        if (((3 < iStack_94) && (iStack_94 < 8)) && (sVar5 + -4 != (int)(short)(ushort)bVar1)) {
          uStack_6c = 6;
          cStack_63 = (char)sVar5 + -4;
          .debug::_Write__15TJournalSegmentFPlPv(auStack_8c,&uStack_6c,auStack_68);
          .debug::_Flush__15TJournalSegmentFv(auStack_8c);
          cStack_98 = '\x01';
        }
      }
      uStack_62 = 0;
      while (cVar6 = .glue::LGetSelect(1,&uStack_62,*(undefined4 *)(*(int *)(param_1 + 0x10) + 4)),
            cVar6 != '\0') {
        .glue::LSetSelect(0,uStack_62,*(undefined4 *)(*(int *)(param_1 + 0x10) + 4));
      }
      if (cStack_98 != '\0') {
        .debug::_RebuildList__12TJournalListFv(*(undefined4 *)(param_1 + 0x10));
      }
      .debug::___dt__15TJournalSegmentFv(auStack_8c,0xffffffff);
    }
  }
  else {
    FUN_100c50e8(*(undefined4 *)(param_1 + 0x10),param_2,(int)param_3);
  }
  return;
}


// ==== .ResizeRoutine__8TJournalFv @ 100791a0 ====
// CyDecompAt: created, body 100791a0-1007920f

void _ResizeRoutine__8TJournalFv(int param_1)

{
  .debug::_RebuildList__12TJournalListFv(*(undefined4 *)(param_1 + 0x10));
  FUN_100c50e8(*(undefined4 *)(param_1 + 0x10),
               ((int)*(short *)(*(int *)(param_1 + 4) + 0x16) -
               (int)*(short *)(*(int *)(param_1 + 4) + 0x12)) + -0x10,
               (int)*(short *)(*(int *)(param_1 + 4) + 0x14) -
               (int)*(short *)(*(int *)(param_1 + 4) + 0x10));
  return;
}


// ==== .__dt__Q23std60set<9FileRange,12CompareRange,Q23std21allocator<9FileRange>>Fv @ 1007b6b8 ====
// CyDecompAt: created, body 1007b6b8-1007b74b

int ___dt__Q23std60set<9FileRange,12CompareRange,Q23std21allocator<9FileRange>>Fv
              (int param_1,short param_2)

{
  if (param_1 != 0) {
    if ((param_1 != 0) && (*(int *)(param_1 + 4) != 0)) {
      .debug::
      _destroy__Q23std63__tree<9FileRange,12CompareRange,Q23std21allocator<9FileRange>>FPQ33std63__tree<9FileRange,12CompareRange,Q23std21allocator<9FileRange>>4node
                (param_1,*(undefined4 *)(param_1 + 4));
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__Q23std21allocator<9FileRange>Fv @ 1007b7ac ====
// CyDecompAt: created, body 1007b7ac-1007b817

int ___dt__Q23std21allocator<9FileRange>Fv(int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .__dt__Q23std147_EmptyMemberOpt<Q23std87allocator<Q33std63__tree<9FileRange,12CompareRange,Q23std21allocator<9FileRange>>4node>,Q33std19__red_black_tree<1>6anchor>Fv @ 1007c134 ====
// CyDecompAt: created, body 1007c134-1007c18f

int ___dt__Q23std147_EmptyMemberOpt<Q23std87allocator<Q33std63__tree<9FileRange,12CompareRange,Q23std21allocator<9FileRange>>4node>,Q33std19__red_black_tree<1>6anchor>Fv
              (int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .__dt__Q23std49_EmptyMemberOpt<Q23std21allocator<9FileRange>,Ul>Fv @ 1007c248 ====
// CyDecompAt: created, body 1007c248-1007c2a3

int ___dt__Q23std49_EmptyMemberOpt<Q23std21allocator<9FileRange>,Ul>Fv(int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .WriteBlock__6TCacheFPv @ 1007c920 ====
// CyDecompAt: created, body 1007c920-1007c923

void _WriteBlock__6TCacheFPv(void)

{
  return;
}


// ==== .__dt__15XIInvalidOpcodeFv @ 100807c8 ====
// CyDecompAt: created, body 100807c8-1008082b

undefined4 * ___dt__15XIInvalidOpcodeFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d6914;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d6940;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__16XIInvalidSegmentFv @ 10080858 ====
// CyDecompAt: created, body 10080858-100808bb

undefined4 * ___dt__16XIInvalidSegmentFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d6934;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d6940;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__7XInterpFv @ 100808ec ====
// CyDecompAt: created, body 100808ec-1008093f

undefined4 * ___dt__7XInterpFv(undefined4 *param_1,short param_2)

{
  if ((param_1 != (undefined4 *)0x0) && (*param_1 = &PTR_PTR_100d6940, 0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .__dt__9XIEndGameFv @ 100825cc ====
// CyDecompAt: created, body 100825cc-1008262f

undefined4 * ___dt__9XIEndGameFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d68d4;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d6940;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__14XIInvalidVAddrFv @ 1008332c ====
// CyDecompAt: created, body 1008332c-1008338f

undefined4 * ___dt__14XIInvalidVAddrFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d68b4;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d6940;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .RangeIter__FP5VAddr @ 10083ca8 ====
// CyDecompAt: created, body 10083ca8-10083d87

void _RangeIter__FP5VAddr(int *param_1,undefined4 *param_2)

{
  int iVar1;
  int *piVar2;
  
  piVar2 = (int *).debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  iVar1 = param_2[1];
  if (iVar1 == 1) {
    if (*piVar2 < piVar2[1]) {
      *param_1 = *(int *)PTR_DAT_100cde70;
    }
    else {
      *param_1 = *(int *)PTR_DAT_100cddec;
    }
  }
  else {
    if (iVar1 < 1) {
      if (-1 < iVar1) {
        *piVar2 = param_2[2];
        piVar2[1] = param_2[3];
        *param_1 = param_2[2];
        return;
      }
    }
    else if (iVar1 < 3) {
      *piVar2 = *piVar2 + 1;
      *param_1 = *piVar2;
      return;
    }
    *param_1 = *(int *)PTR_DAT_100cdbb0;
  }
  return;
}


// ==== .EachIter__FP5VAddr @ 10083db0 ====
// CyDecompAt: created, body 10083db0-10083f0f

void _EachIter__FP5VAddr(undefined4 *param_1,undefined4 *param_2)

{
  undefined *puVar1;
  int iVar2;
  int *piVar3;
  short sVar4;
  
  puVar1 = PTR_DAT_100cdbb0;
  piVar3 = (int *).debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  iVar2 = param_2[1];
  if (iVar2 == 1) {
    if (*piVar3 == *(int *)puVar1) {
      *param_1 = *(undefined4 *)PTR_DAT_100cddec;
    }
    else {
      *param_1 = *(undefined4 *)PTR_DAT_100cde70;
    }
  }
  else {
    if (iVar2 < 1) {
      if (-1 < iVar2) {
        *piVar3 = *(int *)puVar1;
        piVar3[1] = 0;
        if ((param_2[2] & 0xf0000000) == 0) {
          *param_1 = param_2[2];
          return;
        }
        sVar4 = .debug::_Len__7TInterpF5VAddr(param_2[2]);
        if (sVar4 == 0) {
          *param_1 = *(undefined4 *)puVar1;
          return;
        }
        *piVar3 = param_2[2];
        .debug::_At__7TInterpF5VAddrs(param_1,param_2[2],0);
        return;
      }
    }
    else if (iVar2 < 3) {
      piVar3[1] = piVar3[1] + 1;
      sVar4 = .debug::_Len__7TInterpF5VAddr(*piVar3);
      if ((int)sVar4 <= piVar3[1]) {
        *piVar3 = *(int *)puVar1;
        *param_1 = *(undefined4 *)puVar1;
        return;
      }
      .debug::_At__7TInterpF5VAddrs(param_1,*piVar3,(int)(short)piVar3[1]);
      return;
    }
    *param_1 = *(undefined4 *)puVar1;
  }
  return;
}


// ==== .__dt__7XIRaiseFv @ 100840a4 ====
// CyDecompAt: created, body 100840a4-10084107

undefined4 * ___dt__7XIRaiseFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d68f4;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d6940;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__ct__5VAddrFv @ 1008418c ====
// CyDecompAt: created, body 1008418c-10084197

void ___ct__5VAddrFv(undefined4 *param_1)

{
  *param_1 = 0;
  return;
}


// ==== .OffsetOrigin__15TScriptedWindowFRsRs @ 10084730 ====
// CyDecompAt: created, body 10084730-10084733

void _OffsetOrigin__15TScriptedWindowFRsRs(void)

{
  return;
}


// ==== .__dt__Q23std84vector<PQ215TScriptedWindow7TWidget,Q23std39allocator<PQ215TScriptedWindow7TWidget>>Fv @ 10086184 ====
// CyDecompAt: created, body 10086184-1008620f

int ___dt__Q23std84vector<PQ215TScriptedWindow7TWidget,Q23std39allocator<PQ215TScriptedWindow7TWidget>>Fv
              (int param_1,short param_2)

{
  if (param_1 != 0) {
    if ((param_1 != 0) && (*(int *)(param_1 + 8) != 0)) {
      FUN_100be848(*(undefined4 *)(param_1 + 8));
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .CloseRoutine__15TScriptedWindowFv @ 10086340 ====
// CyDecompAt: created, body 10086340-1008640f

void _CloseRoutine__15TScriptedWindowFv(int param_1)

{
  int *piVar1;
  undefined4 uStack_18;
  undefined1 auStack_14 [4];
  
  .debug::___ct__5VAddrFcUsUs(&uStack_18,4,0,*(undefined2 *)(param_1 + 0x10));
  .debug::_DoInterp__7TInterpFs5VAddr(auStack_14,1,uStack_18);
  for (piVar1 = *(int **)(param_1 + 0x24);
      piVar1 != (int *)(*(int *)(param_1 + 0x24) + *(int *)(param_1 + 0x20) * 4);
      piVar1 = piVar1 + 1) {
    .debug::_FreeScriptedWidget__15TScriptedWindowFPQ215TScriptedWindow7TWidget(*piVar1);
    if (*piVar1 != 0) {
      FUN_100c50e8(*piVar1,1);
    }
    *piVar1 = 0;
  }
  .debug::_FreeScriptedWindow__15TScriptedWindowFP15TScriptedWindow(param_1);
  .debug::_CloseRoutine__16TInventoryWindowFv(param_1);
  return;
}


// ==== .FocusRoutine__Q215TScriptedWindow7TWidgetFs @ 1008674c ====
// CyDecompAt: created, body 1008674c-10086753

undefined4 _FocusRoutine__Q215TScriptedWindow7TWidgetFs(void)

{
  return 0;
}


// ==== .WantsFocus__Q215TScriptedWindow7TWidgetFv @ 10086a38 ====
// CyDecompAt: created, body 10086a38-10086a3f

undefined4 _WantsFocus__Q215TScriptedWindow7TWidgetFv(void)

{
  return 0;
}


// ==== .PointToProp__15TScriptedWindowF5Point @ 10086e54 ====
// CyDecompAt: created, body 10086e54-10086ef3

undefined4 _PointToProp__15TScriptedWindowF5Point(int param_1,undefined4 param_2)

{
  int iVar1;
  undefined4 uVar2;
  undefined4 auStack_28 [5];
  
  uVar2 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_28);
  .glue::SetPort(uVar2);
  iVar1 = .debug::_FindWidget__15TScriptedWindowF5Point(param_1,param_2);
  if (iVar1 == 0) {
    .glue::SetPort(auStack_28[0]);
    uVar2 = 0;
  }
  else {
    uVar2 = FUN_100c50e8(iVar1,param_2);
    .glue::SetPort(auStack_28[0]);
  }
  return uVar2;
}


// ==== .PropToPoint__15TScriptedWindowFsP5Point @ 10086f2c ====
// CyDecompAt: created, body 10086f2c-10086feb

undefined4
_PropToPoint__15TScriptedWindowFsP5Point(int param_1,undefined4 param_2,undefined4 param_3)

{
  char cVar1;
  undefined4 uVar2;
  undefined4 *puVar3;
  undefined4 auStack_28 [3];
  
  uVar2 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_28);
  .glue::SetPort(uVar2);
  puVar3 = *(undefined4 **)(param_1 + 0x24);
  while( true ) {
    if (puVar3 == (undefined4 *)(*(int *)(param_1 + 0x24) + *(int *)(param_1 + 0x20) * 4)) {
      .glue::SetPort(auStack_28[0]);
      return 0;
    }
    cVar1 = FUN_100c50e8(*puVar3,param_2,param_3);
    if (cVar1 != '\0') break;
    puVar3 = puVar3 + 1;
  }
  .glue::SetPort(auStack_28[0]);
  return 1;
}


// ==== .CanSearch__15TScriptedWindowF5Point @ 10087028 ====
// CyDecompAt: created, body 10087028-1008702f

undefined4 _CanSearch__15TScriptedWindowF5Point(void)

{
  return 1;
}


// ==== .CanDrop__15TScriptedWindowFsR5Point @ 10087068 ====
// CyDecompAt: created, body 10087068-10087123

undefined4 _CanDrop__15TScriptedWindowFsR5Point(int param_1,undefined4 param_2,undefined4 *param_3)

{
  int iVar1;
  undefined4 uVar2;
  undefined4 auStack_28 [3];
  
  uVar2 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_28);
  .glue::SetPort(uVar2);
  iVar1 = .debug::_FindWidget__15TScriptedWindowF5Point(param_1,*param_3);
  if (iVar1 == 0) {
    uVar2 = .debug::_CanDrop__16TDroppableWindowFsR5Point(param_1,param_2,param_3);
    .glue::SetPort(auStack_28[0]);
  }
  else {
    uVar2 = FUN_100c50e8(iVar1,param_2,param_3);
    .glue::SetPort(auStack_28[0]);
  }
  return uVar2;
}


// ==== .HiliteDrop__15TScriptedWindowFs5Point @ 1008715c ====
// CyDecompAt: created, body 1008715c-10087213

void _HiliteDrop__15TScriptedWindowFs5Point(int param_1,undefined4 param_2,undefined4 param_3)

{
  int iVar1;
  undefined4 uVar2;
  undefined4 auStack_18 [2];
  
  uVar2 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_18);
  .glue::SetPort(uVar2);
  iVar1 = .debug::_FindWidget__15TScriptedWindowF5Point(param_1,param_3);
  if (iVar1 == 0) {
    .debug::_HiliteDrop__16TDroppableWindowFs5Point(param_1,param_2,param_3);
  }
  else {
    FUN_100c50e8(iVar1,param_2,param_3);
  }
  .glue::SetPort(auStack_18[0]);
  return;
}


// ==== .UnhiliteDrop__15TScriptedWindowFs5Point @ 1008724c ====
// CyDecompAt: created, body 1008724c-10087303

void _UnhiliteDrop__15TScriptedWindowFs5Point(int param_1,undefined4 param_2,undefined4 param_3)

{
  int iVar1;
  undefined4 uVar2;
  undefined4 auStack_18 [2];
  
  uVar2 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_18);
  .glue::SetPort(uVar2);
  iVar1 = .debug::_FindWidget__15TScriptedWindowF5Point(param_1,param_3);
  if (iVar1 == 0) {
    .debug::_UnhiliteDrop__16TDroppableWindowFs5Point(param_1,param_2,param_3);
  }
  else {
    FUN_100c50e8(iVar1,param_2,param_3);
  }
  .glue::SetPort(auStack_18[0]);
  return;
}


// ==== .DoDrop__15TScriptedWindowFs5Point @ 10087340 ====
// CyDecompAt: created, body 10087340-100873f7

void _DoDrop__15TScriptedWindowFs5Point(int param_1,undefined4 param_2,undefined4 param_3)

{
  int iVar1;
  undefined4 uVar2;
  undefined4 auStack_18 [2];
  
  uVar2 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_18);
  .glue::SetPort(uVar2);
  iVar1 = .debug::_FindWidget__15TScriptedWindowF5Point(param_1,param_3);
  if (iVar1 == 0) {
    .debug::_DoDrop__16TDroppableWindowFs5Point(param_1,param_2,param_3);
  }
  else {
    FUN_100c50e8(iVar1,param_2,param_3);
  }
  .glue::SetPort(auStack_18[0]);
  return;
}


// ==== .RenumberParent__15TScriptedWindowFss @ 1008742c ====
// CyDecompAt: created, body 1008742c-100874bb

void _RenumberParent__15TScriptedWindowFss(int param_1,undefined4 param_2,undefined4 param_3)

{
  undefined4 *puVar1;
  
  .debug::_RenumberParent__16TInventoryWindowFss();
  for (puVar1 = *(undefined4 **)(param_1 + 0x24);
      puVar1 != (undefined4 *)(*(int *)(param_1 + 0x24) + *(int *)(param_1 + 0x20) * 4);
      puVar1 = puVar1 + 1) {
    FUN_100c50e8(*puVar1,param_2,param_3);
  }
  return;
}


// ==== .RenumberChild__15TScriptedWindowFss @ 100874f4 ====
// CyDecompAt: created, body 100874f4-1008757b

void _RenumberChild__15TScriptedWindowFss(int param_1,undefined4 param_2,undefined4 param_3)

{
  undefined4 *puVar1;
  
  for (puVar1 = *(undefined4 **)(param_1 + 0x24);
      puVar1 != (undefined4 *)(*(int *)(param_1 + 0x24) + *(int *)(param_1 + 0x20) * 4);
      puVar1 = puVar1 + 1) {
    FUN_100c50e8(*puVar1,param_2,param_3);
  }
  return;
}


// ==== .IsPoint__Q215TScriptedWindow7TWidgetF5Point @ 100876d4 ====
// CyDecompAt: created, body 100876d4-1008771f

bool _IsPoint__Q215TScriptedWindow7TWidgetF5Point(int param_1,undefined4 param_2)

{
  char cVar1;
  
  cVar1 = .glue::PtInRect(param_2,param_1 + 0x10);
  return cVar1 != '\0';
}


// ==== .CursorRoutine__Q215TScriptedWindow7TWidgetF5Point @ 10087760 ====
// CyDecompAt: created, body 10087760-10087767

undefined4 _CursorRoutine__Q215TScriptedWindow7TWidgetF5Point(void)

{
  return 0;
}


// ==== .KeyRoutine__Q215TScriptedWindow7TWidgetFs @ 10087854 ====
// CyDecompAt: created, body 10087854-100878fb

void _KeyRoutine__Q215TScriptedWindow7TWidgetFs(int param_1,short param_2)

{
  short sVar1;
  
  if ((0x40 < param_2) && (param_2 < 0x5b)) {
    param_2 = param_2 + 0x20;
  }
  sVar1 = 0;
  while( true ) {
    if (3 < sVar1) {
      return;
    }
    if (*(short *)(param_1 + sVar1 * 2 + 0x18) == param_2) break;
    sVar1 = sVar1 + 1;
  }
  FUN_100c50e8(param_1);
  return;
}


// ==== .Flash__Q215TScriptedWindow7TWidgetFv @ 10087938 ====
// CyDecompAt: created, body 10087938-1008793b

void _Flash__Q215TScriptedWindow7TWidgetFv(void)

{
  return;
}


// ==== .PointToProp__Q215TScriptedWindow7TWidgetF5Point @ 10087974 ====
// CyDecompAt: created, body 10087974-1008797b

undefined4 _PointToProp__Q215TScriptedWindow7TWidgetF5Point(void)

{
  return 0;
}


// ==== .PropToPoint__Q215TScriptedWindow7TWidgetFsP5Point @ 100879c0 ====
// CyDecompAt: created, body 100879c0-100879c7

undefined4 _PropToPoint__Q215TScriptedWindow7TWidgetFsP5Point(void)

{
  return 0;
}


// ==== .CanDrop__Q215TScriptedWindow7TWidgetFsR5Point @ 10087a0c ====
// CyDecompAt: created, body 10087a0c-10087a3f

undefined4 _CanDrop__Q215TScriptedWindow7TWidgetFsR5Point(void)

{
  .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)PTR_DAT_100cdb98,uRam100cedac);
  return 0;
}


// ==== .HiliteDrop__Q215TScriptedWindow7TWidgetFs5Point @ 10087a80 ====
// CyDecompAt: created, body 10087a80-10087a83

void _HiliteDrop__Q215TScriptedWindow7TWidgetFs5Point(void)

{
  return;
}


// ==== .UnhiliteDrop__Q215TScriptedWindow7TWidgetFs5Point @ 10087ac8 ====
// CyDecompAt: created, body 10087ac8-10087acb

void _UnhiliteDrop__Q215TScriptedWindow7TWidgetFs5Point(void)

{
  return;
}


// ==== .DoDrop__Q215TScriptedWindow7TWidgetFs5Point @ 10087b10 ====
// CyDecompAt: created, body 10087b10-10087b13

void _DoDrop__Q215TScriptedWindow7TWidgetFs5Point(void)

{
  return;
}


// ==== .RebuildInv__Q215TScriptedWindow7TWidgetFv @ 10087b54 ====
// CyDecompAt: created, body 10087b54-10087b57

void _RebuildInv__Q215TScriptedWindow7TWidgetFv(void)

{
  return;
}


// ==== .RenumberParent__Q215TScriptedWindow7TWidgetFss @ 10087b94 ====
// CyDecompAt: created, body 10087b94-10087b97

void _RenumberParent__Q215TScriptedWindow7TWidgetFss(void)

{
  return;
}


// ==== .RenumberChild__Q215TScriptedWindow7TWidgetFss @ 10087bdc ====
// CyDecompAt: created, body 10087bdc-10087bdf

void _RenumberChild__Q215TScriptedWindow7TWidgetFss(void)

{
  return;
}


// ==== .DispatchWidgetMethod__Q215TScriptedWindow7TWidgetFssP5VAddr @ 10087c20 ====
// CyDecompAt: created, body 10087c20-10087c2f

void _DispatchWidgetMethod__Q215TScriptedWindow7TWidgetFssP5VAddr(undefined4 *param_1)

{
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .DispatchWindowMethod__15TScriptedWindowFssP5VAddr @ 10087f34 ====
// CyDecompAt: created, body 10087f34-10087fe3

void _DispatchWindowMethod__15TScriptedWindowFssP5VAddr
               (undefined4 *param_1,int param_2,short param_3,undefined4 param_4,undefined4 *param_5
               )

{
  char cVar1;
  int *piVar2;
  undefined1 auStack_18 [8];
  
  if (param_3 == 4) {
    piVar2 = *(int **)(param_2 + 0x24);
    while( true ) {
      if (piVar2 == (int *)(*(int *)(param_2 + 0x24) + *(int *)(param_2 + 0x20) * 4)) break;
      cVar1 = .debug::_IsEqual__7TInterpF5VAddr5VAddr(*(undefined4 *)(*piVar2 + 0xc),*param_5);
      if (cVar1 != '\0') {
        .debug::_FindScriptedWidget__15TScriptedWindowFPQ215TScriptedWindow7TWidget
                  (auStack_18,*piVar2);
      }
      piVar2 = piVar2 + 1;
    }
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .SetField__15TScriptedWindowFs5VAddr @ 1008826c ====
// CyDecompAt: created, body 1008826c-1008826f

void _SetField__15TScriptedWindowFs5VAddr(void)

{
  return;
}


// ==== .DispatchCommand__15TScriptedWindowFPQ215TScriptedWindow7TWidget @ 100882a8 ====
// CyDecompAt: created, body 100882a8-100882ab

void _DispatchCommand__15TScriptedWindowFPQ215TScriptedWindow7TWidget(void)

{
  return;
}


// ==== .__dt__Q23std12allocator<c>Fv @ 100884b8 ====
// CyDecompAt: created, body 100884b8-10088523

int ___dt__Q23std12allocator<c>Fv(int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .Marshal__6TWTextFP7TStream @ 10088664 ====
// CyDecompAt: created, body 10088664-100886fb

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Marshal__6TWTextFP7TStream(int param_1,undefined4 param_2)

{
  FUN_100c50e8(param_2,_DAT_100ceda0,0x77547874);
  .debug::_Marshal__Q215TScriptedWindow7TWidgetFP7TStream(param_1,param_2);
  FUN_100c50e8(param_2,_DAT_100ceda4,*(undefined4 *)(param_1 + 0x28),*(undefined1 *)(param_1 + 0x2c)
               ,*(undefined1 *)(param_1 + 0x2d),(int)*(short *)(param_1 + 0x2e),
               (int)*(short *)(param_1 + 0x30));
  return;
}


// ==== .Draw__6TWTextFP8GrafPort @ 1008872c ====
// CyDecompAt: created, body 1008872c-10088b27

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Draw__6TWTextFP8GrafPort(int param_1)

{
  uint uVar1;
  short sVar3;
  int iVar2;
  uint uVar4;
  int iVar5;
  int iVar6;
  short sVar7;
  int iVar8;
  int iVar9;
  undefined1 auStack_78 [12];
  undefined1 auStack_6c [12];
  undefined1 auStack_60 [12];
  undefined1 auStack_54 [12];
  short sStack_48;
  undefined1 auStack_44 [24];
  
  iVar2 = _DAT_100cdb90;
  uVar1 = (int)*(short *)(param_1 + 0x16) + (int)*(short *)(param_1 + 0x12);
  iVar9 = (int)(short)((short)((int)uVar1 >> 1) + (ushort)((int)uVar1 < 0 && (uVar1 & 1) != 0));
  if (*(short *)(param_1 + 0x2e) == 0) {
    iVar9 = *(short *)(param_1 + 0x12) + 2;
  }
  else if (*(short *)(param_1 + 0x2e) == -1) {
    iVar9 = *(short *)(param_1 + 0x16) + -2;
  }
  iVar8 = (int)*(short *)(param_1 + 0x30);
  if (*(char *)(param_1 + 0x2d) != '\0') {
    iVar8 = 0xcd;
  }
  .debug::___ct__12TTextContextFPCcssss
            (auStack_44,*(undefined4 *)(*(int *)(param_1 + 0x24) + 0xc),
             (int)(short)**(undefined4 **)(param_1 + 0x24),
             (int)*(short *)(param_1 + 0x16) - (int)*(short *)(param_1 + 0x12),0,
             *(short *)PTR_DAT_100cdcf4 * 2 + 1);
  sStack_48 = *(short *)(iVar2 + 0x28) + *(short *)(iVar2 + 0x2a) + *(short *)(iVar2 + 0x2e);
  iVar6 = (int)*(short *)(iVar2 + 0x38) +
          (int)*(short *)(iVar2 + 0x3a) + (int)*(short *)(iVar2 + 0x3e);
  iVar5 = (int)*(short *)(iVar2 + 0x30) +
          (int)*(short *)(iVar2 + 0x32) + (int)*(short *)(iVar2 + 0x36);
  sVar3 = .debug::_NumLines__12TTextContextFv(auStack_44);
  if (sVar3 == 0) {
    .debug::___ct__12TTextContextFPCcssss
              (auStack_6c,*(undefined4 *)(*(int *)(param_1 + 0x24) + 0xc),
               (int)(short)**(undefined4 **)(param_1 + 0x24),
               (int)*(short *)(param_1 + 0x16) - (int)*(short *)(param_1 + 0x12),2,0);
    sVar3 = .debug::_NumLines__12TTextContextFv(auStack_6c);
    sVar7 = (short)iVar6;
    if ((int)(short)(*(short *)(param_1 + 0x14) - *(short *)(param_1 + 0x10)) <
        (int)sVar7 * (int)sVar3 - (int)*(short *)(iVar2 + 0x3e)) {
      .debug::___ct__12TTextContextFPCcssss
                (auStack_78,*(undefined4 *)(*(int *)(param_1 + 0x24) + 0xc),
                 (int)(short)**(undefined4 **)(param_1 + 0x24),
                 (int)*(short *)(param_1 + 0x16) - (int)*(short *)(param_1 + 0x12),1,0);
      sVar3 = .debug::_NumLines__12TTextContextFv(auStack_78);
      uVar4 = (int)(short)iVar5 * (int)sVar3;
      uVar1 = (int)*(short *)(param_1 + 0x10) + (int)*(short *)(param_1 + 0x14);
      .debug::_Draw__12TTextContextFssssll
                (auStack_78,iVar9,
                 (int)*(short *)(iVar2 + 0x30) +
                 ((((int)uVar1 >> 1) + (uint)((int)uVar1 < 0 && (uVar1 & 1) != 0)) -
                 (((int)uVar4 >> 1) + (uint)((int)uVar4 < 0 && (uVar4 & 1) != 0))),
                 (int)*(short *)(param_1 + 0x2e),iVar5,iVar8,0x199);
      .debug::___dt__12TTextContextFv(auStack_78,0xffffffff);
    }
    else {
      sVar3 = .debug::_NumLines__12TTextContextFv(auStack_6c);
      uVar4 = (int)sVar7 * (int)sVar3;
      uVar1 = (int)*(short *)(param_1 + 0x10) + (int)*(short *)(param_1 + 0x14);
      .debug::_Draw__12TTextContextFssssll
                (auStack_6c,iVar9,
                 (int)*(short *)(iVar2 + 0x38) +
                 ((((int)uVar1 >> 1) + (uint)((int)uVar1 < 0 && (uVar1 & 1) != 0)) -
                 (((int)uVar4 >> 1) + (uint)((int)uVar4 < 0 && (uVar4 & 1) != 0))),
                 (int)*(short *)(param_1 + 0x2e),iVar6,iVar8,0x199);
    }
    .debug::___dt__12TTextContextFv(auStack_6c,0xffffffff);
  }
  else {
    .debug::___ct__12TTextContextFPCcssss
              (auStack_54,*(undefined4 *)(*(int *)(param_1 + 0x24) + 0xc),
               (int)(short)**(undefined4 **)(param_1 + 0x24),
               (int)*(short *)(param_1 + 0x16) - (int)*(short *)(param_1 + 0x12),2,0);
    sVar3 = .debug::_NumLines__12TTextContextFv(auStack_54);
    if ((short)(*(short *)(param_1 + 0x14) - *(short *)(param_1 + 0x10)) + -0xf < sVar3 * 0x14) {
      .debug::___ct__12TTextContextFPCcssss
                (auStack_60,*(undefined4 *)(*(int *)(param_1 + 0x24) + 0xc),
                 (int)(short)**(undefined4 **)(param_1 + 0x24),
                 (int)*(short *)(param_1 + 0x16) - (int)*(short *)(param_1 + 0x12),1,0);
      .debug::_Draw__12TTextContextFssssll
                (auStack_60,iVar9,0x14,(int)*(short *)(param_1 + 0x2e),0x14,iVar8,0x199);
      .debug::___dt__12TTextContextFv(auStack_60,0xffffffff);
    }
    else {
      .debug::_Draw__12TTextContextFssssll
                (auStack_54,iVar9,0x14,(int)*(short *)(param_1 + 0x2e),0x14,iVar8,0x199);
    }
    .debug::_SetText__Fs(5);
    iVar2 = .debug::_NumLines__12TTextContextFv(auStack_44);
    .debug::_Draw__12TTextContextFssssll
              (auStack_44,iVar9,(int)*(short *)(param_1 + 0x14) + iVar2 * -10 + 5,
               (int)*(short *)(param_1 + 0x2e),10,0x111,0x199);
    .debug::___dt__12TTextContextFv(auStack_54,0xffffffff);
  }
  .debug::___dt__12TTextContextFv(auStack_44,0xffffffff);
  return;
}


// ==== .MouseRoutine__6TWTextF5Point @ 10088b54 ====
// CyDecompAt: created, body 10088b54-10088cbb

undefined4 _MouseRoutine__6TWTextF5Point(int param_1,undefined4 param_2)

{
  char cVar2;
  undefined4 uVar1;
  bool bVar3;
  undefined4 uStack_1c;
  undefined4 uStack_18;
  undefined1 auStack_14 [8];
  
  if (*(char *)(param_1 + 0x2c) == '\0') {
    uVar1 = .debug::_MouseRoutine__Q215TScriptedWindow7TWidgetF5Point(param_1,param_2);
  }
  else {
    bVar3 = false;
    while( true ) {
      cVar2 = .glue::StillDown();
      if (cVar2 == '\0') break;
      cVar2 = .glue::PtInRect(param_2,param_1 + 0x10);
      if (bVar3 != (bool)cVar2) {
        bVar3 = bVar3 == false;
        *(bool *)(param_1 + 0x2d) = bVar3;
        FUN_100c50e8(param_1,0);
      }
      .glue::GetMouse(&stack0x0000001c);
    }
    if (bVar3 != false) {
      *(undefined1 *)(param_1 + 0x2d) = 0;
      FUN_100c50e8(param_1,0);
      if (*(int *)(param_1 + 8) == *(int *)PTR_DAT_100cdbb0) {
        FUN_100c50e8(*(undefined4 *)(param_1 + 0x20),param_1);
      }
      else {
        .debug::_FindScriptedWidget__15TScriptedWindowFPQ215TScriptedWindow7TWidget
                  (&uStack_1c,param_1);
        uStack_18 = *(undefined4 *)(param_1 + 4);
        .debug::_DoInterp__7TInterpFs5VAddr5VAddr5VAddr
                  (auStack_14,0xffffffff,*(undefined4 *)(param_1 + 8),uStack_18,uStack_1c);
      }
    }
    uVar1 = 1;
  }
  return uVar1;
}


// ==== .GetField__6TWTextFs @ 10088cec ====
// CyDecompAt: created, body 10088cec-10088d93

void _GetField__6TWTextFs(uint *param_1,int param_2,short param_3)

{
  uint *puVar1;
  
  if (param_3 == 0x40) {
    puVar1 = (uint *)PTR_DAT_100cde70;
    if (*(char *)(param_2 + 0x2c) != '\0') {
      puVar1 = (uint *)PTR_DAT_100cddec;
    }
    *param_1 = *puVar1;
  }
  else if (param_3 == 0x41) {
    *param_1 = (int)*(short *)(param_2 + 0x30) & 0xfffffff;
  }
  else if (param_3 == 0x3c) {
    *param_1 = (int)*(short *)(param_2 + 0x2e) & 0xfffffff;
  }
  else {
    .debug::_GetField__Q215TScriptedWindow7TWidgetFs(param_1,param_2,(int)param_3);
  }
  return;
}


// ==== .SetField__6TWTextFs5VAddr @ 10088dbc ====
// CyDecompAt: created, body 10088dbc-10088f23

void _SetField__6TWTextFs5VAddr(int param_1,undefined4 param_2,uint param_3)

{
  undefined4 uVar1;
  short sVar2;
  undefined1 auStack_20 [4];
  undefined1 auStack_1c [4];
  undefined4 auStack_18 [2];
  
  sVar2 = (short)param_2;
  if (sVar2 == 0x40) {
    *(bool *)(param_1 + 0x2c) = *(uint *)PTR_DAT_100cddec == param_3;
  }
  else if (sVar2 == 0x41) {
    *(short *)(param_1 + 0x30) = (short)((int)(param_3 << 4 | param_3 >> 0x1c) >> 4);
  }
  else if (sVar2 == 0x3c) {
    *(short *)(param_1 + 0x2e) = (short)((int)(param_3 << 4 | param_3 >> 0x1c) >> 4);
  }
  else if (sVar2 == 0x3d) {
    uVar1 = .debug::_VAddrToStr__F5VAddr(param_3);
    .debug::
    ___ct__Q23std59basic_string<c,Q23std14char_traits<c>,Q23std12allocator<c>>FPCcRCQ23std12allocator<c>
              (auStack_20,uVar1,auStack_1c);
    .debug::
    _assign__Q23std59basic_string<c,Q23std14char_traits<c>,Q23std12allocator<c>>FRCQ23std59basic_string<c,Q23std14char_traits<c>,Q23std12allocator<c>>UlUl
              (param_1 + 0x24,auStack_20,0,0xffffffff);
    .debug::___dt__Q23std59basic_string<c,Q23std14char_traits<c>,Q23std12allocator<c>>Fv
              (auStack_20,0xffffffff);
    uVar1 = *(undefined4 *)(*(int *)(param_1 + 0x20) + 4);
    .glue::GetPort(auStack_18);
    .glue::SetPort(uVar1);
    .glue::InvalRect(param_1 + 0x10);
    .glue::SetPort(auStack_18[0]);
  }
  else if (sVar2 != 0x37) {
    .debug::_SetField__Q215TScriptedWindow7TWidgetFs5VAddr(param_1,param_2,param_3);
  }
  return;
}


// ==== .__dt__11TWTextEntryFv @ 100891cc ====
// CyDecompAt: created, body 100891cc-10089247

undefined4 * ___dt__11TWTextEntryFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d70e4;
    if (param_1[9] != 0) {
      .glue::TEDispose(param_1[9]);
    }
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d71b8;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .Marshal__11TWTextEntryFP7TStream @ 10089270 ====
// CyDecompAt: created, body 10089270-100892fb

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Marshal__11TWTextEntryFP7TStream(int param_1,undefined4 param_2)

{
  undefined4 uVar1;
  
  FUN_100c50e8(param_2,_DAT_100ceda0,0x77544564);
  .debug::_Marshal__Q215TScriptedWindow7TWidgetFP7TStream(param_1,param_2);
  uVar1 = .glue::TEGetText(*(undefined4 *)(param_1 + 0x24));
  FUN_100c50e8(param_2,PTR_DAT_100ced9c,uVar1);
  return;
}


// ==== .Draw__11TWTextEntryFP8GrafPort @ 10089330 ====
// CyDecompAt: created, body 10089330-10089387

void _Draw__11TWTextEntryFP8GrafPort(int param_1,undefined4 param_2)

{
  .glue::EraseRect(param_1 + 0x10);
  .glue::FrameRect(param_1 + 0x10);
  .debug::_DrawTEInPort__FPC4RectPP5TERecP8GrafPort
            (param_1 + 0x10,*(undefined4 *)(param_1 + 0x24),param_2);
  return;
}


// ==== .GetField__11TWTextEntryFs @ 100893bc ====
// CyDecompAt: created, body 100893bc-100894cf

void _GetField__11TWTextEntryFs(uint *param_1,int param_2,short param_3)

{
  undefined4 *puVar1;
  char cVar5;
  int iVar2;
  undefined4 uVar3;
  int iVar4;
  ushort auStack_28 [4];
  
  if (param_3 == 0x37) {
    puVar1 = (undefined4 *).glue::TEGetText(*(undefined4 *)(param_2 + 0x24));
    cVar5 = .glue::HGetState();
    .glue::HLock(puVar1);
    iVar2 = .glue::GetHandleSize(puVar1);
    .debug::___ct__8THeapObjF10HeapObjTagsUs(auStack_28,3,iVar2 + 1,0);
    .debug::_IncRef__8THeapObjFv(auStack_28);
    iVar2 = .debug::_GetString__8THeapObjFv(auStack_28);
    uVar3 = .glue::GetHandleSize(puVar1);
    FUN_100b6d24(iVar2,*puVar1,uVar3);
    iVar4 = .glue::GetHandleSize(puVar1);
    *(undefined1 *)(iVar2 + iVar4) = 0;
    .glue::HSetState(puVar1,(int)cVar5);
    *param_1 = auStack_28[0] | 0x70000000;
  }
  else {
    .debug::_GetField__Q215TScriptedWindow7TWidgetFs(param_1,param_2,(int)param_3);
  }
  return;
}


// ==== .SetField__11TWTextEntryFs5VAddr @ 100894fc ====
// CyDecompAt: created, body 100894fc-100895b3

void _SetField__11TWTextEntryFs5VAddr(int param_1,undefined4 param_2,undefined4 param_3)

{
  undefined4 uVar1;
  undefined4 uVar2;
  
  if ((short)param_2 == 0x37) {
    uVar1 = .debug::_VAddrToPtr__7TInterpF5VAddr(param_3);
    uVar2 = FUN_100b6ce8();
    .glue::TESetText(uVar1,uVar2,*(undefined4 *)(param_1 + 0x24));
  }
  else {
    .debug::_SetField__Q215TScriptedWindow7TWidgetFs5VAddr(param_1,param_2,param_3);
  }
  return;
}


// ==== .MouseRoutine__11TWTextEntryF5Point @ 100895e8 ====
// CyDecompAt: created, body 100895e8-1008964f

undefined4 _MouseRoutine__11TWTextEntryF5Point(int param_1,undefined4 param_2)

{
  .glue::TEClick(param_2,*(ushort *)(*(int *)PTR_DAT_100cdb84 + 0x12) & 0x200,
                 *(undefined4 *)(param_1 + 0x24));
  FUN_100c50e8(*(undefined4 *)(param_1 + 0x20),0x4000);
  return 1;
}


// ==== .CursorRoutine__11TWTextEntryF5Point @ 10089688 ====
// CyDecompAt: created, body 10089688-100896b3

undefined4 _CursorRoutine__11TWTextEntryF5Point(void)

{
  .debug::_ChangeCursor__Fs(0x2d);
  return 1;
}


// ==== .KeyRoutine__11TWTextEntryFs @ 100896ec ====
// CyDecompAt: created, body 100896ec-1008973f

void _KeyRoutine__11TWTextEntryFs(int param_1,short param_2)

{
  .glue::TEKey((int)param_2,*(undefined4 *)(param_1 + 0x24));
  FUN_100c50e8(*(undefined4 *)(param_1 + 0x20),0x4000);
  return;
}


// ==== .FocusRoutine__11TWTextEntryFs @ 10089770 ====
// CyDecompAt: created, body 10089770-1008980b

undefined4 _FocusRoutine__11TWTextEntryFs(int param_1,short param_2)

{
  if (param_2 == 1) {
    .glue::TEDeactivate(*(undefined4 *)(param_1 + 0x24));
  }
  else if (param_2 < 1) {
    if (-1 < param_2) {
      .glue::TEActivate(*(undefined4 *)(param_1 + 0x24));
    }
  }
  else if (param_2 < 3) {
    .glue::TEIdle(*(undefined4 *)(param_1 + 0x24));
  }
  FUN_100c50e8(*(undefined4 *)(param_1 + 0x20),0x4000);
  return 1;
}


// ==== .Marshal__12TWScrollTextFP7TStream @ 100899a4 ====
// CyDecompAt: created, body 100899a4-10089a2b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Marshal__12TWScrollTextFP7TStream(int param_1,undefined4 param_2)

{
  FUN_100c50e8(param_2,_DAT_100ceda0,0x77535478);
  .debug::_Marshal__Q215TScriptedWindow7TWidgetFP7TStream(param_1,param_2);
  FUN_100c50e8(param_2,_DAT_100ceda0,*(undefined4 *)(param_1 + 0x30));
  return;
}


// ==== .__dt__12TWScrollTextFv @ 10089cec ====
// CyDecompAt: created, body 10089cec-10089d7f

undefined4 * ___dt__12TWScrollTextFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d7070;
    if (param_1[10] != 0) {
      .glue::KillPicture(param_1[10]);
    }
    if (param_1[9] != 0) {
      .glue::DisposeControl(param_1[9]);
    }
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d71b8;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .Draw__12TWScrollTextFP8GrafPort @ 10089dac ====
// CyDecompAt: created, body 10089dac-10089ebb

void _Draw__12TWScrollTextFP8GrafPort(int param_1,undefined4 param_2)

{
  undefined4 uVar1;
  undefined4 uStack_18;
  undefined2 uStack_14;
  short sStack_12;
  
  uStack_18 = *(undefined4 *)(param_1 + 0x10);
  sStack_12 = (short)*(undefined4 *)(param_1 + 0x14);
  _uStack_14 = CONCAT22((short)((uint)*(undefined4 *)(param_1 + 0x14) >> 0x10),sStack_12 + -0x10);
  uVar1 = .glue::NewRgn();
  .glue::GetClip();
  .glue::ClipRect(&uStack_18);
  .debug::_BlastBackground__15TScriptedWindowFP8GrafPort(*(undefined4 *)(param_1 + 0x20),param_2);
  if (*(int *)(param_1 + 0x28) != 0) {
    .glue::SetOrigin(0xfffffffc,(int)*(short *)(param_1 + 0x2c));
    .glue::OffsetRect(&uStack_18,0xfffffffc,(int)*(short *)(param_1 + 0x2c));
    .glue::ClipRect(&uStack_18);
    .glue::DrawPicture(*(undefined4 *)(param_1 + 0x28),**(int **)(param_1 + 0x28) + 2);
    .glue::SetOrigin(0,0);
  }
  .glue::SetClip(uVar1);
  .glue::DisposeRgn(uVar1);
  .debug::_DrawControlInPort__FPP13ControlRecordP8GrafPort(*(undefined4 *)(param_1 + 0x24),param_2);
  return;
}


// ==== .ScrollTextTrack__12TWScrollTextFPP13ControlRecords @ 10089fd4 ====
// CyDecompAt: created, body 10089fd4-1008a09b

void _ScrollTextTrack__12TWScrollTextFPP13ControlRecords(undefined4 param_1,short param_2)

{
  short *psVar1;
  int iVar2;
  short sVar3;
  
  psVar1 = (short *).glue::GetControlReference();
  if (psVar1[1] == param_2) {
    sVar3 = *psVar1;
    iVar2 = .glue::GetControlValue(param_1);
    iVar2 = iVar2 + sVar3;
    if ((short)iVar2 < 0) {
      iVar2 = 0;
    }
    sVar3 = .glue::GetControlMaximum(param_1);
    if (sVar3 < (short)iVar2) {
      iVar2 = .glue::GetControlMaximum(param_1);
    }
    .glue::SetControlValue(param_1,iVar2);
    .debug::_Scrolled__12TWScrollTextFv(*(undefined4 *)(psVar1 + 2));
  }
  return;
}


// ==== .MouseRoutine__12TWScrollTextF5Point @ 1008a0e4 ====
// CyDecompAt: created, body 1008a0e4-1008a2cb

undefined4 _MouseRoutine__12TWScrollTextF5Point(int param_1,undefined4 param_2)

{
  undefined *puVar1;
  int iVar2;
  char cVar5;
  short sVar4;
  undefined4 uVar3;
  short sStack_28;
  short sStack_26;
  int iStack_24;
  undefined2 uStack_20;
  short sStack_1e;
  undefined4 uStack_1c;
  
  uStack_1c = *(undefined4 *)(param_1 + 0x14);
  _uStack_20 = CONCAT22((short)((uint)*(undefined4 *)(param_1 + 0x10) >> 0x10),
                        uStack_1c._2_2_ + -0x10);
  cVar5 = .glue::PtInRect(param_2,&uStack_20);
  if (cVar5 == '\0') {
    uVar3 = .debug::_MouseRoutine__Q215TScriptedWindow7TWidgetF5Point(param_1,param_2);
    return uVar3;
  }
  sStack_26 = .glue::TestControl(*(undefined4 *)(param_1 + 0x24),param_2);
  if (sStack_26 == 0) {
    return 1;
  }
  if (sStack_26 == 0x81) {
    sVar4 = .glue::TrackControl(*(undefined4 *)(param_1 + 0x24),param_2,0);
    if (sVar4 == 0) {
      return 1;
    }
    .debug::_Scrolled__12TWScrollTextFv(param_1);
    return 1;
  }
  if (sStack_26 == 0x16) {
    iVar2 = -((int)*(short *)(param_1 + 0x14) - (int)*(short *)(param_1 + 0x10));
    iVar2 = iVar2 / 10 + (iVar2 >> 0x1f);
    sStack_28 = (short)iVar2 - (short)(iVar2 >> 0x1f);
    goto LAB_1008a230;
  }
  if (sStack_26 < 0x16) {
    if (sStack_26 == 0x14) {
      sStack_28 = -1;
      goto LAB_1008a230;
    }
    if (0x13 < sStack_26) {
      sStack_28 = 1;
      goto LAB_1008a230;
    }
  }
  else if (sStack_26 < 0x18) {
    iVar2 = (int)*(short *)(param_1 + 0x14) - (int)*(short *)(param_1 + 0x10);
    iVar2 = iVar2 / 10 + (iVar2 >> 0x1f);
    sStack_28 = (short)iVar2 - (short)(iVar2 >> 0x1f);
    goto LAB_1008a230;
  }
  sStack_28 = 0;
LAB_1008a230:
  iStack_24 = param_1;
  .glue::SetControlReference(*(undefined4 *)(param_1 + 0x24),&sStack_28);
  if (*PTR_DAT_100ced98 == '\0') {
    uVar3 = .glue::NewRoutineDescriptor(PTR_PTR_100cdff8,0x2c0,1);
    puVar1 = PTR_DAT_100ced98;
    *(undefined4 *)PTR_DAT_100ced94 = uVar3;
    *puVar1 = 1;
  }
  .glue::TrackControl(*(undefined4 *)(param_1 + 0x24),param_2,*(undefined4 *)PTR_DAT_100ced94);
  return 1;
}


// ==== .Draw__9TWControlFP8GrafPort @ 1008a6e8 ====
// CyDecompAt: created, body 1008a6e8-1008a717

void _Draw__9TWControlFP8GrafPort(int param_1)

{
  .glue::Draw1Control(*(undefined4 *)(param_1 + 0x24));
  return;
}


// ==== .GetField__9TWControlFs @ 1008a748 ====
// CyDecompAt: created, body 1008a748-1008a7ff

void _GetField__9TWControlFs(uint *param_1,int param_2,short param_3)

{
  short sVar1;
  
  if (param_3 == 0x37) {
    sVar1 = .glue::GetControlValue(*(undefined4 *)(param_2 + 0x24));
    *param_1 = (int)sVar1 & 0xfffffff;
  }
  else if (param_3 == 0x3e) {
    sVar1 = .glue::GetControlMinimum(*(undefined4 *)(param_2 + 0x24));
    *param_1 = (int)sVar1 & 0xfffffff;
  }
  else if (param_3 == 0x3f) {
    sVar1 = .glue::GetControlMaximum(*(undefined4 *)(param_2 + 0x24));
    *param_1 = (int)sVar1 & 0xfffffff;
  }
  else {
    .debug::_GetField__Q215TScriptedWindow7TWidgetFs(param_1,param_2,(int)param_3);
  }
  return;
}


// ==== .SetField__9TWControlFs5VAddr @ 1008a82c ====
// CyDecompAt: created, body 1008a82c-1008a95f

void _SetField__9TWControlFs5VAddr(int param_1,undefined4 param_2,uint param_3)

{
  short sVar1;
  
  sVar1 = (short)param_2;
  if (sVar1 == 0x37) {
    if ((param_3 & 0xf0000000) == 0) {
      .glue::SetControlValue
                (*(undefined4 *)(param_1 + 0x24),
                 (int)(short)((int)(param_3 << 4 | param_3 >> 0x1c) >> 4));
    }
  }
  else if (sVar1 == 0x40) {
    if (param_3 == *(uint *)PTR_DAT_100cddec) {
      .glue::HiliteControl(*(undefined4 *)(param_1 + 0x24),0);
    }
    else if (param_3 == *(uint *)PTR_DAT_100cde70) {
      .glue::HiliteControl(*(undefined4 *)(param_1 + 0x24),1);
    }
  }
  else if (sVar1 == 0x3e) {
    .glue::SetControlMinimum
              (*(undefined4 *)(param_1 + 0x24),
               (int)(short)((int)(param_3 << 4 | param_3 >> 0x1c) >> 4));
  }
  else if (sVar1 == 0x3f) {
    .glue::SetControlMaximum
              (*(undefined4 *)(param_1 + 0x24),
               (int)(short)((int)(param_3 << 4 | param_3 >> 0x1c) >> 4));
  }
  else {
    .debug::_SetField__Q215TScriptedWindow7TWidgetFs5VAddr(param_1,param_2,param_3);
  }
  return;
}


// ==== .MouseRoutine__9TWControlF5Point @ 1008a990 ====
// CyDecompAt: created, body 1008a990-1008aa5b

undefined4 _MouseRoutine__9TWControlF5Point(int param_1,undefined4 param_2)

{
  short sVar1;
  undefined4 uStack_1c;
  undefined4 uStack_18;
  undefined1 auStack_14 [12];
  
  sVar1 = .glue::TrackControl(*(undefined4 *)(param_1 + 0x24),param_2,0);
  if (sVar1 != 0) {
    if (*(int *)(param_1 + 8) == *(int *)PTR_DAT_100cdbb0) {
      FUN_100c50e8(*(undefined4 *)(param_1 + 0x20),param_1);
    }
    else {
      .debug::_FindScriptedWidget__15TScriptedWindowFPQ215TScriptedWindow7TWidget
                (&uStack_1c,param_1);
      uStack_18 = *(undefined4 *)(param_1 + 4);
      .debug::_DoInterp__7TInterpFs5VAddr5VAddr5VAddr
                (auStack_14,0xffffffff,*(undefined4 *)(param_1 + 8),uStack_18,uStack_1c);
    }
  }
  return 1;
}


// ==== .CursorRoutine__9TWControlF5Point @ 1008aa90 ====
// CyDecompAt: created, body 1008aa90-1008aabb

undefined4 _CursorRoutine__9TWControlF5Point(void)

{
  .debug::_ChangeCursor__Fs(0x2a);
  return 1;
}


// ==== .Marshal__8TWButtonFP7TStream @ 1008ac0c ====
// CyDecompAt: created, body 1008ac0c-1008ac63

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Marshal__8TWButtonFP7TStream(undefined4 param_1,undefined4 param_2)

{
  FUN_100c50e8(param_2,_DAT_100ceda0,0x77427574);
  .debug::_Marshal__9TWControlFP7TStream(param_1,param_2);
  return;
}


// ==== .Flash__8TWButtonFv @ 1008ac94 ====
// CyDecompAt: created, body 1008ac94-1008ad6b

void _Flash__8TWButtonFv(int param_1)

{
  undefined4 uStack_1c;
  undefined4 uStack_18;
  undefined1 auStack_14 [4];
  undefined1 auStack_10 [8];
  
  .glue::HiliteControl(*(undefined4 *)(param_1 + 0x24),1);
  .glue::Delay(8,auStack_10);
  .glue::HiliteControl(*(undefined4 *)(param_1 + 0x24),0);
  if (*(int *)(param_1 + 8) == *(int *)PTR_DAT_100cdbb0) {
    FUN_100c50e8(*(undefined4 *)(param_1 + 0x20),param_1);
  }
  else {
    .debug::_FindScriptedWidget__15TScriptedWindowFPQ215TScriptedWindow7TWidget(&uStack_1c,param_1);
    uStack_18 = *(undefined4 *)(param_1 + 4);
    .debug::_DoInterp__7TInterpFs5VAddr5VAddr5VAddr
              (auStack_14,0xffffffff,*(undefined4 *)(param_1 + 8),uStack_18,uStack_1c);
  }
  return;
}


// ==== .Marshal__6TWIconFP7TStream @ 1008aef0 ====
// CyDecompAt: created, body 1008aef0-1008af6f

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Marshal__6TWIconFP7TStream(int param_1,undefined4 param_2)

{
  FUN_100c50e8(param_2,_DAT_100ceda0,0x7749636e);
  .debug::_Marshal__Q215TScriptedWindow7TWidgetFP7TStream(param_1,param_2);
  FUN_100c50e8(param_2,PTR_DAT_100ced8c,(int)*(short *)(param_1 + 0x24));
  return;
}


// ==== .Draw__6TWIconFP8GrafPort @ 1008afa0 ====
// CyDecompAt: created, body 1008afa0-1008b077

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Draw__6TWIconFP8GrafPort(int param_1,int param_2)

{
  int iStack_48;
  undefined4 uStack_44;
  undefined4 uStack_40;
  undefined4 uStack_3c;
  undefined4 uStack_38;
  undefined4 uStack_34;
  undefined4 uStack_30;
  undefined4 uStack_2c;
  undefined4 uStack_28;
  undefined4 uStack_24;
  undefined4 uStack_20;
  undefined4 uStack_1c;
  undefined2 uStack_18;
  
  uStack_44 = uRam100d3de8;
  uStack_40 = uRam100d3dec;
  uStack_3c = uRam100d3df0;
  uStack_38 = uRam100d3df4;
  uStack_34 = uRam100d3df8;
  uStack_30 = uRam100d3dfc;
  uStack_2c = uRam100d3e00;
  uStack_28 = uRam100d3e04;
  uStack_24 = uRam100d3e08;
  uStack_20 = uRam100d3e0c;
  uStack_1c = uRam100d3e10;
  uStack_18 = uRam100d3e14;
  iStack_48 = *(int *)PTR_DAT_100cdc64 + *(short *)(param_1 + 0x24) * 0x400;
  .glue::CopyBits(&iStack_48,param_2 + 2,(int)&uStack_44 + 2,param_1 + 0x10,0x24,0);
  return;
}


// ==== .__dt__5TWPixFv @ 1008b3f4 ====
// CyDecompAt: created, body 1008b3f4-1008b46b

undefined4 * ___dt__5TWPixFv(undefined4 *param_1,short param_2)

{
  undefined *puVar1;
  
  puVar1 = PTR_DAT_100cdec0;
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d6eac;
    .debug::_ReleasePix__13TPixCacheBaseFs(*(undefined4 *)puVar1,(int)*(short *)(param_1 + 9));
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d71b8;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .Marshal__5TWPixFP7TStream @ 1008b490 ====
// CyDecompAt: created, body 1008b490-1008b50f

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Marshal__5TWPixFP7TStream(int param_1,undefined4 param_2)

{
  FUN_100c50e8(param_2,_DAT_100ceda0,0x77506978);
  .debug::_Marshal__Q215TScriptedWindow7TWidgetFP7TStream(param_1,param_2);
  FUN_100c50e8(param_2,PTR_DAT_100ced8c,(int)*(short *)(param_1 + 0x24));
  return;
}


// ==== .Draw__5TWPixFP8GrafPort @ 1008b53c ====
// CyDecompAt: created, body 1008b53c-1008b5af

void _Draw__5TWPixFP8GrafPort(int param_1)

{
  .debug::_LoadPix__13TPixCacheBaseFR6PixMaps
            (*(undefined4 *)PTR_DAT_100cdec0,param_1 + 0x26,(int)*(short *)(param_1 + 0x24));
  if (*(int *)(param_1 + 0x26) != 0) {
    .glue::CopyBits(param_1 + 0x26,*(int *)(PTR_DAT_100cdb94 + 0xca) + 2,param_1 + 0x2c,
                    param_1 + 0x10,0x24,0);
  }
  return;
}


// ==== .GetField__5TWPixFs @ 1008b5dc ====
// CyDecompAt: created, body 1008b5dc-1008b64f

void _GetField__5TWPixFs(uint *param_1,int param_2,short param_3)

{
  if (param_3 == 0x37) {
    *param_1 = (int)*(short *)(param_2 + 0x24) & 0xfffffff;
  }
  else {
    .debug::_GetField__Q215TScriptedWindow7TWidgetFs(param_1,param_2,(int)param_3);
  }
  return;
}


// ==== .SetField__5TWPixFs5VAddr @ 1008b678 ====
// CyDecompAt: created, body 1008b678-1008b763

void _SetField__5TWPixFs5VAddr(int param_1,undefined4 param_2,uint param_3)

{
  undefined *puVar1;
  short sVar2;
  
  if ((short)param_2 == 0x37) {
    if ((param_3 & 0xf0000000) == 0) {
      if (*(int *)(param_1 + 0x26) != 0) {
        .glue::DisposePtr(*(undefined4 *)(param_1 + 0x26));
      }
      puVar1 = PTR_DAT_100cdec0;
      *(short *)(param_1 + 0x24) = (short)((int)(param_3 << 4 | param_3 >> 0x1c) >> 4);
      sVar2 = .debug::_NewPix__13TPixCacheBaseFR6PixMaps
                        (*(undefined4 *)puVar1,param_1 + 0x26,(int)*(short *)(param_1 + 0x24));
      if (sVar2 != 0) {
        *(undefined4 *)(param_1 + 0x26) = 0;
      }
      FUN_100c50e8(param_1,*(undefined4 *)(*(int *)(param_1 + 0x20) + 4));
      FUN_100c50e8(*(undefined4 *)(param_1 + 0x20),0x4000);
    }
  }
  else {
    .debug::_SetField__Q215TScriptedWindow7TWidgetFs5VAddr(param_1,param_2,param_3);
  }
  return;
}


// ==== .__dt__11TWPixButtonFv @ 1008bb6c ====
// CyDecompAt: created, body 1008bb6c-1008bc0b

undefined4 * ___dt__11TWPixButtonFv(undefined4 *param_1,short param_2)

{
  undefined *puVar1;
  
  puVar1 = PTR_DAT_100cdec0;
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d6e38;
    .debug::_ReleasePix__13TPixCacheBaseFs(*(undefined4 *)puVar1,(int)*(short *)(param_1 + 9));
    .debug::_ReleasePix__13TPixCacheBaseFs(*(undefined4 *)puVar1,(int)*(short *)(param_1 + 10));
    .debug::_ReleasePix__13TPixCacheBaseFs
              (*(undefined4 *)puVar1,(int)*(short *)((int)param_1 + 0x26));
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d71b8;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .Marshal__11TWPixButtonFP7TStream @ 1008bc34 ====
// CyDecompAt: created, body 1008bc34-1008bcbf

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Marshal__11TWPixButtonFP7TStream(int param_1,undefined4 param_2)

{
  FUN_100c50e8(param_2,_DAT_100ceda0,0x77507842);
  .debug::_Marshal__Q215TScriptedWindow7TWidgetFP7TStream(param_1,param_2);
  FUN_100c50e8(param_2,PTR_DAT_100ced88,(int)*(short *)(param_1 + 0x24),
               (int)*(short *)(param_1 + 0x26),(int)*(short *)(param_1 + 0x28),
               (int)*(short *)(param_1 + 0x2a));
  return;
}


// ==== .Draw__11TWPixButtonFP8GrafPort @ 1008bcf4 ====
// CyDecompAt: created, body 1008bcf4-1008bde7

void _Draw__11TWPixButtonFP8GrafPort(int param_1)

{
  short sVar1;
  int iVar2;
  int *piVar3;
  
  piVar3 = (int *)0x0;
  iVar2 = 0;
  sVar1 = *(short *)(param_1 + 0x2a);
  if (sVar1 == 1) {
    iVar2 = (int)*(short *)(param_1 + 0x26);
    piVar3 = (int *)(param_1 + 0x5e);
  }
  else if (sVar1 < 1) {
    if (-1 < sVar1) {
      iVar2 = (int)*(short *)(param_1 + 0x24);
      piVar3 = (int *)(param_1 + 0x2c);
    }
  }
  else if (sVar1 < 3) {
    piVar3 = (int *)(param_1 + 0x90);
    iVar2 = (int)*(short *)(param_1 + 0x28);
  }
  if ((piVar3 != (int *)0x0) && ((short)iVar2 != 0)) {
    .debug::_LoadPix__13TPixCacheBaseFR6PixMaps(*(undefined4 *)PTR_DAT_100cdec0,piVar3,iVar2);
  }
  if (((piVar3 != (int *)0x0) && ((short)iVar2 != 0)) && (*piVar3 != 0)) {
    .glue::CopyBits(piVar3,*(int *)(PTR_DAT_100cdb94 + 0xca) + 2,param_1 + 0x32,param_1 + 0x10,0x24,
                    0);
  }
  return;
}


// ==== .GetField__11TWPixButtonFs @ 1008be1c ====
// CyDecompAt: created, body 1008be1c-1008bf37

void _GetField__11TWPixButtonFs(undefined4 *param_1,int param_2,short param_3)

{
  short sVar1;
  
  if (param_3 == 0x40) {
    sVar1 = *(short *)(param_2 + 0x2a);
    if (sVar1 == 2) {
      *param_1 = *(undefined4 *)PTR_DAT_100cde70;
    }
    else if ((sVar1 < 2) && (-1 < sVar1)) {
      *param_1 = *(undefined4 *)PTR_DAT_100cddec;
    }
    else {
      *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
    }
  }
  else if (param_3 == 0x37) {
    sVar1 = *(short *)(param_2 + 0x2a);
    if (sVar1 == 1) {
      *param_1 = *(undefined4 *)PTR_DAT_100cddec;
    }
    else {
      if (sVar1 < 1) {
        if (-1 < sVar1) {
          *param_1 = *(undefined4 *)PTR_DAT_100cde70;
          return;
        }
      }
      else if (sVar1 < 3) {
        *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
        return;
      }
      *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
    }
  }
  else {
    .debug::_GetField__Q215TScriptedWindow7TWidgetFs(param_1,param_2,(int)param_3);
  }
  return;
}


// ==== .SetField__11TWPixButtonFs5VAddr @ 1008bf64 ====
// CyDecompAt: created, body 1008bf64-1008c16b

void _SetField__11TWPixButtonFs5VAddr(int param_1,undefined4 param_2,int param_3)

{
  undefined4 uVar1;
  undefined4 uStack_48;
  undefined4 uStack_44;
  undefined4 uStack_40;
  undefined4 uStack_3c;
  undefined4 auStack_38 [5];
  
  if ((short)param_2 == 0x40) {
    if (param_3 == *(int *)PTR_DAT_100cddec) {
      *(undefined2 *)(param_1 + 0x2a) = 0;
      uVar1 = *(undefined4 *)(*(int *)(param_1 + 0x20) + 4);
      .glue::GetPort(auStack_38);
      .glue::SetPort(uVar1);
      .glue::InvalRect(param_1 + 0x10);
      .glue::SetPort(auStack_38[0]);
    }
    else if (param_3 == *(int *)PTR_DAT_100cde70) {
      *(undefined2 *)(param_1 + 0x2a) = 2;
      uVar1 = *(undefined4 *)(*(int *)(param_1 + 0x20) + 4);
      .glue::GetPort(&uStack_3c);
      .glue::SetPort(uVar1);
      .glue::InvalRect(param_1 + 0x10);
      .glue::SetPort(uStack_3c);
    }
  }
  else if ((short)param_2 == 0x37) {
    if (param_3 == *(int *)PTR_DAT_100cddec) {
      *(undefined2 *)(param_1 + 0x2a) = 1;
      uVar1 = *(undefined4 *)(*(int *)(param_1 + 0x20) + 4);
      .glue::GetPort(&uStack_40);
      .glue::SetPort(uVar1);
      .glue::InvalRect(param_1 + 0x10);
      .glue::SetPort(uStack_40);
    }
    else if (param_3 == *(int *)PTR_DAT_100cde70) {
      *(undefined2 *)(param_1 + 0x2a) = 0;
      uVar1 = *(undefined4 *)(*(int *)(param_1 + 0x20) + 4);
      .glue::GetPort(&uStack_44);
      .glue::SetPort(uVar1);
      .glue::InvalRect(param_1 + 0x10);
      .glue::SetPort(uStack_44);
    }
    else if (param_3 == *(int *)PTR_DAT_100cdbb0) {
      *(undefined2 *)(param_1 + 0x2a) = 2;
      uVar1 = *(undefined4 *)(*(int *)(param_1 + 0x20) + 4);
      .glue::GetPort(&uStack_48);
      .glue::SetPort(uVar1);
      .glue::InvalRect(param_1 + 0x10);
      .glue::SetPort(uStack_48);
    }
  }
  else {
    .debug::_SetField__Q215TScriptedWindow7TWidgetFs5VAddr(param_1,param_2,param_3);
  }
  return;
}


// ==== .MouseRoutine__11TWPixButtonF5Point @ 1008c1a0 ====
// CyDecompAt: created, body 1008c1a0-1008c35f

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 _MouseRoutine__11TWPixButtonF5Point(int param_1,undefined4 param_2)

{
  char cVar2;
  undefined4 uVar1;
  bool bVar3;
  undefined4 uStack_1c;
  undefined4 uStack_18;
  undefined1 auStack_14 [8];
  
  if ((*(short *)(param_1 + 0x2a) == 0) &&
     (cVar2 = .debug::_IsPixelHit__FR6PixMapss5Point
                        (param_1 + 0x2c,(int)*(short *)(param_1 + 0x12),
                         (int)*(short *)(param_1 + 0x10),param_2), cVar2 != '\0')) {
    bVar3 = false;
    .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(_DAT_100cdd24,6);
    while (cVar2 = .glue::StillDown(), cVar2 != '\0') {
      cVar2 = .debug::_IsPixelHit__FR6PixMapss5Point
                        (param_1 + 0x2c,(int)*(short *)(param_1 + 0x12),
                         (int)*(short *)(param_1 + 0x10),param_2);
      if (bVar3 != (bool)cVar2) {
        *(ushort *)(param_1 + 0x2a) = (ushort)(bVar3 == false);
        FUN_100c50e8(param_1,0);
        bVar3 = bVar3 == false;
      }
      .glue::GetMouse(&stack0x0000001c);
    }
    .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(_DAT_100cdd24,7);
    if (bVar3 != false) {
      *(undefined2 *)(param_1 + 0x2a) = 0;
      FUN_100c50e8(param_1,0);
      if (*(int *)(param_1 + 8) == *(int *)PTR_DAT_100cdbb0) {
        FUN_100c50e8(*(undefined4 *)(param_1 + 0x20),param_1);
      }
      else {
        .debug::_FindScriptedWidget__15TScriptedWindowFPQ215TScriptedWindow7TWidget
                  (&uStack_1c,param_1);
        uStack_18 = *(undefined4 *)(param_1 + 4);
        .debug::_DoInterp__7TInterpFs5VAddr5VAddr5VAddr
                  (auStack_14,0xffffffff,*(undefined4 *)(param_1 + 8),uStack_18,uStack_1c);
      }
    }
    uVar1 = 1;
  }
  else {
    uVar1 = .debug::_MouseRoutine__Q215TScriptedWindow7TWidgetF5Point(param_1,param_2);
  }
  return uVar1;
}


// ==== .__dt__9TWAutoMapFv @ 1008c6b4 ====
// CyDecompAt: created, body 1008c6b4-1008c737

undefined4 * ___dt__9TWAutoMapFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d6dc4;
    if (param_1[0x16] != 0) {
      .glue::DisposePtr(param_1[0x16]);
    }
    param_1[0x16] = 0;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d71b8;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .Marshal__9TWAutoMapFP7TStream @ 1008c760 ====
// CyDecompAt: created, body 1008c760-1008c7e3

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Marshal__9TWAutoMapFP7TStream(int param_1,undefined4 param_2)

{
  FUN_100c50e8(param_2,_DAT_100ceda0,0x774d6170);
  .debug::_Marshal__Q215TScriptedWindow7TWidgetFP7TStream(param_1,param_2);
  FUN_100c50e8(param_2,PTR_DAT_100ced84,(int)*(short *)(param_1 + 0x60),
               (int)*(short *)(param_1 + 0x62));
  return;
}


// ==== .Draw__9TWAutoMapFP8GrafPort @ 1008c814 ====
// CyDecompAt: created, body 1008c814-1008c90f

void _Draw__9TWAutoMapFP8GrafPort(int param_1,int param_2)

{
  undefined *puVar1;
  uint uVar2;
  uint uVar3;
  int iVar4;
  int iVar5;
  
  puVar1 = PTR_DAT_100cdbb8;
  if (*(int *)(param_1 + 0x58) == 0) {
    .glue::FillRect(param_1 + 0x10,PTR_DAT_100cdb94 + 0xba);
  }
  else {
    if (*(char *)(param_1 + 100) != '\0') {
      *(undefined1 *)(param_1 + 100) = 0;
      iVar5 = (int)*(short *)(param_1 + 0x30) - (int)*(short *)(param_1 + 0x2c);
      uVar2 = (uint)(short)iVar5;
      iVar4 = (int)*(short *)(param_1 + 0x2e) - (int)*(short *)(param_1 + 0x2a);
      uVar3 = (uint)(short)iVar4;
      .debug::_MagicMap__11TGameViewerFssssPcls
                (*(undefined4 *)puVar1,
                 (int)*(short *)(param_1 + 0x60) -
                 (((int)uVar2 >> 1) + (uint)((int)uVar2 < 0 && (uVar2 & 1) != 0)),
                 (int)*(short *)(param_1 + 0x62) -
                 (((int)uVar3 >> 1) + (uint)((int)uVar3 < 0 && (uVar3 & 1) != 0)),iVar5,iVar4,
                 *(undefined4 *)(param_1 + 0x58),*(undefined4 *)(param_1 + 0x5c),5);
    }
    .glue::CopyBits(param_1 + 0x24,param_2 + 2,param_1 + 0x2a,param_1 + 0x10,0,0);
  }
  return;
}


// ==== .MouseRoutine__9TWAutoMapF5Point @ 1008c9d0 ====
// CyDecompAt: created, body 1008c9d0-1008cac7

undefined4 _MouseRoutine__9TWAutoMapF5Point(int param_1,undefined4 param_2)

{
  short sVar1;
  short sVar2;
  uint uVar3;
  char cVar4;
  short sVar5;
  short sVar6;
  short sVar7;
  
  sVar1 = *(short *)(param_1 + 0x60);
  sVar2 = *(short *)(param_1 + 0x62);
  sVar5 = sVar2;
  sVar6 = sVar1;
  do {
    cVar4 = .glue::StillDown();
    if (cVar4 == '\0') {
      return 1;
    }
    uVar3 = (int)(short)param_2 - (int)(short)param_2;
    *(ushort *)(param_1 + 0x60) =
         sVar1 - ((short)((int)uVar3 >> 2) + (ushort)((int)uVar3 < 0 && (uVar3 & 3) != 0));
    sVar7 = (short)((uint)param_2 >> 0x10);
    uVar3 = (int)sVar7 - (int)sVar7;
    *(ushort *)(param_1 + 0x62) =
         sVar2 - ((short)((int)uVar3 >> 2) + (ushort)((int)uVar3 < 0 && (uVar3 & 3) != 0));
    if (sVar6 == *(short *)(param_1 + 0x60)) {
      if (sVar5 != *(short *)(param_1 + 0x60)) goto LAB_1008ca68;
    }
    else {
LAB_1008ca68:
      *(undefined1 *)(param_1 + 100) = 1;
      FUN_100c50e8(param_1,*(undefined4 *)(*(int *)(param_1 + 0x20) + 4));
      sVar6 = *(short *)(param_1 + 0x60);
      sVar5 = *(short *)(param_1 + 0x62);
    }
    .glue::GetMouse(&stack0x0000001c);
  } while( true );
}


// ==== .Marshal__13TWNumberEntryFP7TStream @ 1008cc20 ====
// CyDecompAt: created, body 1008cc20-1008cc77

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Marshal__13TWNumberEntryFP7TStream(undefined4 param_1,undefined4 param_2)

{
  FUN_100c50e8(param_2,_DAT_100ceda0,0x774e6d45);
  .debug::_Marshal__9TWControlFP7TStream(param_1,param_2);
  return;
}


// ==== .MouseRoutine__13TWNumberEntryF5Point @ 1008ccb0 ====
// CyDecompAt: created, body 1008ccb0-1008cd7b

undefined4 _MouseRoutine__13TWNumberEntryF5Point(int param_1,undefined4 param_2)

{
  short sVar1;
  undefined4 uStack_1c;
  undefined4 uStack_18;
  undefined1 auStack_14 [12];
  
  sVar1 = .glue::TrackControl(*(undefined4 *)(param_1 + 0x24),param_2,0xffffffff);
  if (sVar1 != 0) {
    if (*(int *)(param_1 + 8) == *(int *)PTR_DAT_100cdbb0) {
      FUN_100c50e8(*(undefined4 *)(param_1 + 0x20),param_1);
    }
    else {
      .debug::_FindScriptedWidget__15TScriptedWindowFPQ215TScriptedWindow7TWidget
                (&uStack_1c,param_1);
      uStack_18 = *(undefined4 *)(param_1 + 4);
      .debug::_DoInterp__7TInterpFs5VAddr5VAddr5VAddr
                (auStack_14,0xffffffff,*(undefined4 *)(param_1 + 8),uStack_18,uStack_1c);
    }
  }
  return 1;
}


// ==== .Marshal__8TWNumberFP7TStream @ 1008cedc ====
// CyDecompAt: created, body 1008cedc-1008cf33

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Marshal__8TWNumberFP7TStream(undefined4 param_1,undefined4 param_2)

{
  FUN_100c50e8(param_2,_DAT_100ceda0,0x774e756d);
  .debug::_Marshal__9TWControlFP7TStream(param_1,param_2);
  return;
}


// ==== .Marshal__10TWMusicBoxFP7TStream @ 1008d128 ====
// CyDecompAt: created, body 1008d128-1008d1b7

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Marshal__10TWMusicBoxFP7TStream(int param_1,undefined4 param_2)

{
  FUN_100c50e8(param_2,_DAT_100ceda0,0x774d7573);
  .debug::_Marshal__Q215TScriptedWindow7TWidgetFP7TStream(param_1,param_2);
  FUN_100c50e8(param_2,PTR_DAT_100ced80,(int)*(short *)(param_1 + 0x24),
               (int)*(short *)(param_1 + 0x4c),(int)*(short *)(param_1 + 0x26),0x20,param_1 + 0x28);
  return;
}


// ==== .Draw__10TWMusicBoxFP8GrafPort @ 1008d1ec ====
// CyDecompAt: created, body 1008d1ec-1008d2f7

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Draw__10TWMusicBoxFP8GrafPort(int param_1)

{
  int iVar1;
  short sVar2;
  undefined4 uVar3;
  uint uVar4;
  uint uVar5;
  int iVar6;
  char cStack_28;
  undefined1 uStack_27;
  
  iVar1 = _DAT_100cdb90;
  sVar2 = (short)(((int)*(short *)(param_1 + 0x16) - (int)*(short *)(param_1 + 0x12)) /
                 (int)*(short *)(param_1 + 0x26));
  for (iVar6 = 0; (short)iVar6 < *(short *)(param_1 + 0x26); iVar6 = iVar6 + 1) {
    cStack_28 = (char)*(undefined2 *)(param_1 + (short)iVar6 * 2 + 0x28) + 'A';
    uStack_27 = (undefined1)_DAT_100d69e0;
    .debug::_SetText__Fs(5);
    uVar3 = .glue::CharWidth((int)cStack_28);
    uVar4 = (uint)sVar2;
    uVar3 = .debug::_Justify__12TTextContextFsss
                      ((int)*(short *)(param_1 + 0x12) +
                       sVar2 * iVar6 +
                       ((int)uVar4 >> 1) + (uint)((int)uVar4 < 0 && (uVar4 & 1) != 0),uVar3,1);
    uVar4 = (uint)*(short *)(iVar1 + 0x28);
    uVar5 = (int)*(short *)(param_1 + 0x14) + (int)*(short *)(param_1 + 0x10);
    .debug::_DrawTextOutlined__12TTextContextFssPcsll
              (uVar3,(int)(short)((short)((int)uVar5 >> 1) +
                                 (ushort)((int)uVar5 < 0 && (uVar5 & 1) != 0)) +
                     ((int)uVar4 >> 1) + (uint)((int)uVar4 < 0 && (uVar4 & 1) != 0),&cStack_28,1,
               0x45,0x21);
  }
  return;
}


// ==== .MouseRoutine__10TWMusicBoxF5Point @ 1008d328 ====
// CyDecompAt: created, body 1008d328-1008d567

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 _MouseRoutine__10TWMusicBoxF5Point(int param_1,undefined4 param_2)

{
  short sVar2;
  uint uVar1;
  undefined4 uVar3;
  uint uVar4;
  short sVar5;
  undefined4 uStack_30;
  undefined1 auStack_2c [4];
  char cStack_28;
  undefined1 uStack_27;
  
  sVar5 = (short)(((int)*(short *)(param_1 + 0x16) - (int)*(short *)(param_1 + 0x12)) /
                 (int)*(short *)(param_1 + 0x26));
  sVar2 = (short)(((int)(short)param_2 - (int)*(short *)(param_1 + 0x12)) / (int)sVar5);
  if ((sVar2 < 0) || (*(short *)(param_1 + 0x26) <= sVar2)) {
    uVar3 = .debug::_MouseRoutine__Q215TScriptedWindow7TWidgetF5Point(param_1,param_2);
  }
  else {
    cStack_28 = (char)*(undefined2 *)(param_1 + sVar2 * 2 + 0x28) + 'A';
    uStack_27 = (undefined1)_DAT_100d69e2;
    .debug::_SetText__Fs(5);
    uVar3 = .glue::CharWidth((int)cStack_28);
    uVar4 = (uint)sVar5;
    uVar3 = .debug::_Justify__12TTextContextFsss
                      ((int)*(short *)(param_1 + 0x12) +
                       (int)sVar5 * (int)sVar2 +
                       ((int)uVar4 >> 1) + (uint)((int)uVar4 < 0 && (uVar4 & 1) != 0),uVar3,1);
    uVar4 = (int)*(short *)(param_1 + 0x14) + (int)*(short *)(param_1 + 0x10);
    uVar1 = (uint)*(short *)(_DAT_100cdb90 + 0x28);
    .debug::_DrawTextOutlined__12TTextContextFssPcsll
              (uVar3,(int)(short)((short)((int)uVar4 >> 1) +
                                 (ushort)((int)uVar4 < 0 && (uVar4 & 1) != 0)) +
                     ((int)uVar1 >> 1) + (uint)((int)uVar1 < 0 && (uVar1 & 1) != 0),&cStack_28,1,
               0x199,0x21);
    .debug::_PlayNote__6TAudioFsss
              (_DAT_100cdd24,(int)*(short *)(param_1 + 0x24),
               *(short *)(param_1 + sVar2 * 2 + 0x28) + 0x40,0x14);
    uVar3 = .glue::CharWidth((int)cStack_28);
    uVar4 = (uint)sVar5;
    uVar3 = .debug::_Justify__12TTextContextFsss
                      ((int)*(short *)(param_1 + 0x12) +
                       (int)sVar5 * (int)sVar2 +
                       ((int)uVar4 >> 1) + (uint)((int)uVar4 < 0 && (uVar4 & 1) != 0),uVar3,1);
    uVar4 = (int)*(short *)(param_1 + 0x14) + (int)*(short *)(param_1 + 0x10);
    uVar1 = (uint)*(short *)(_DAT_100cdb90 + 0x28);
    .debug::_DrawTextOutlined__12TTextContextFssPcsll
              (uVar3,(int)(short)((short)((int)uVar4 >> 1) +
                                 (ushort)((int)uVar4 < 0 && (uVar4 & 1) != 0)) +
                     ((int)uVar1 >> 1) + (uint)((int)uVar1 < 0 && (uVar1 & 1) != 0),&cStack_28,1,
               0x45,0x21);
    *(int *)(param_1 + 0x48) =
         *(int *)(param_1 + 0x48) << 4 | (int)*(short *)(param_1 + sVar2 * 2 + 0x28);
    uVar4 = *(uint *)(param_1 + 0x48);
    .debug::___ct__5VAddrFcUsUs(&uStack_30,4,0,*(undefined2 *)(param_1 + 0x4c));
    .debug::_DoInterp__7TInterpFs5VAddr5VAddr(auStack_2c,10,uStack_30,uVar4 & 0xfffffff);
    uVar3 = 1;
  }
  return uVar3;
}


// ==== .Marshal__8TWInventFP7TStream @ 1008d798 ====
// CyDecompAt: created, body 1008d798-1008d817

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Marshal__8TWInventFP7TStream(int param_1,undefined4 param_2)

{
  FUN_100c50e8(param_2,_DAT_100ceda0,0x77496e76);
  .debug::_Marshal__Q215TScriptedWindow7TWidgetFP7TStream(param_1,param_2);
  FUN_100c50e8(param_2,PTR_DAT_100ced8c,(int)*(short *)(param_1 + 0x30));
  return;
}


// ==== .__dt__8TWInventFv @ 1008d848 ====
// CyDecompAt: created, body 1008d848-1008d8ff

undefined4 * ___dt__8TWInventFv(undefined4 *param_1,short param_2)

{
  undefined4 *puVar1;
  
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d6be4;
    puVar1 = (undefined4 *)param_1[9];
    if (puVar1 != (undefined4 *)0x0) {
      *puVar1 = &PTR_PTR_100d80e4;
      if (puVar1 != (undefined4 *)0xfffffffc) {
        .debug::
        _tear_down__Q23std84vector<Q214TInventoryPile9PileEntry,Q23std39allocator<Q214TInventoryPile9PileEntry>>Fv
                  (puVar1 + 1);
      }
      FUN_100be848(puVar1);
    }
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d71b8;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .RebuildInv__8TWInventFv @ 1008d928 ====
// CyDecompAt: created, body 1008d928-1008d977

void _RebuildInv__8TWInventFv(int param_1)

{
  .debug::_RebuildInventory__14TInventoryPileFs
            (*(undefined4 *)(param_1 + 0x24),(int)*(short *)(param_1 + 0x30));
  FUN_100c50e8(*(undefined4 *)(param_1 + 0x20),1);
  return;
}


// ==== .RenumberChild__8TWInventFss @ 1008d9a4 ====
// CyDecompAt: created, body 1008d9a4-1008d9e3

void _RenumberChild__8TWInventFss(int param_1,short param_2,short param_3)

{
  .debug::_RenumberChild__14TInventoryPileFss
            (*(undefined4 *)(param_1 + 0x24),(int)param_2,(int)param_3);
  return;
}


// ==== .RenumberParent__8TWInventFss @ 1008da14 ====
// CyDecompAt: created, body 1008da14-1008da2b

void _RenumberParent__8TWInventFss(int param_1,short param_2,undefined2 param_3)

{
  if (param_2 != *(short *)(param_1 + 0x30)) {
    return;
  }
  *(undefined2 *)(param_1 + 0x30) = param_3;
  return;
}


// ==== .Draw__8TWInventFP8GrafPort @ 1008da5c ====
// CyDecompAt: created, body 1008da5c-1008daaf

void _Draw__8TWInventFP8GrafPort(int param_1,undefined4 param_2)

{
  FUN_100c50e8(*(undefined4 *)(param_1 + 0x24),param_2);
  return;
}


// ==== .CanDrop__8TWInventFsR5Point @ 1008dae0 ====
// CyDecompAt: created, body 1008dae0-1008dc37

undefined4 _CanDrop__8TWInventFsR5Point(int param_1,undefined4 param_2,undefined4 *param_3)

{
  undefined *puVar1;
  undefined4 uVar2;
  short sVar4;
  char cVar5;
  undefined4 *puVar3;
  undefined1 auStack_38 [4];
  undefined4 uStack_34;
  undefined4 uStack_30;
  undefined4 uStack_2c;
  undefined4 uStack_28;
  
  puVar1 = PTR_DAT_100cdb98;
  if ((short)param_2 == *(short *)(param_1 + 0x30)) {
    .debug::_AutoEye__13TStatusWindowFPc
              (*(undefined4 *)PTR_DAT_100cdb98,PTR_s__Fold_Space__100ced74);
    uVar2 = 0;
  }
  else {
    sVar4 = .debug::_GetPropParent__Fs(param_2);
    if (*(short *)(param_1 + 0x30) == sVar4) {
      .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Abort__100ced70);
      uVar2 = 0;
    }
    else {
      uStack_2c = *(undefined4 *)(param_1 + 0x28);
      uStack_28 = *(undefined4 *)(param_1 + 0x2c);
      cVar5 = .glue::PtInRect(*param_3,&uStack_2c);
      if (cVar5 == '\0') {
        .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,uRam100cedac);
        uVar2 = 0;
      }
      else {
        .debug::___ct__5VAddrFcUsUs(&uStack_34,4,0,*(undefined2 *)(param_1 + 0x30));
        puVar3 = (undefined4 *).debug::___ct__5VAddrFcUsUs(auStack_38,4,0,param_2);
        .debug::_DoInterp__7TInterpFs5VAddr5VAddr(&uStack_30,0x17,uStack_34,*puVar3);
        cVar5 = .debug::_IsTrue__7TInterpF5VAddr(uStack_30);
        if (cVar5 == '\0') {
          .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Doesn_t_fit__100ced6c);
          uVar2 = 0;
        }
        else {
          .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Put_In__100ced68);
          uVar2 = 1;
        }
      }
    }
  }
  return uVar2;
}


// ==== .HiliteDrop__8TWInventFs5Point @ 1008dc68 ====
// CyDecompAt: created, body 1008dc68-1008dc6b

void _HiliteDrop__8TWInventFs5Point(void)

{
  return;
}


// ==== .UnhiliteDrop__8TWInventFs5Point @ 1008dc9c ====
// CyDecompAt: created, body 1008dc9c-1008dc9f

void _UnhiliteDrop__8TWInventFs5Point(void)

{
  return;
}


// ==== .DoDrop__8TWInventFs5Point @ 1008dcd4 ====
// CyDecompAt: created, body 1008dcd4-1008dd43

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DoDrop__8TWInventFs5Point(int param_1,short param_2,undefined4 param_3)

{
  char cVar1;
  undefined4 uStack_18;
  undefined4 uStack_14;
  
  uStack_18 = *(undefined4 *)(param_1 + 0x28);
  uStack_14 = *(undefined4 *)(param_1 + 0x2c);
  cVar1 = .glue::PtInRect(param_3,&uStack_18);
  if (cVar1 != '\0') {
    .debug::_TakeCommand__8TGameSysFss(*_DAT_100cdcd0,(int)param_2,(int)*(short *)(param_1 + 0x30));
  }
  return;
}


// ==== .PointToProp__8TWInventF5Point @ 1008dd70 ====
// CyDecompAt: created, body 1008dd70-1008ddfb

undefined4 _PointToProp__8TWInventF5Point(int param_1,undefined4 param_2)

{
  char cVar2;
  undefined4 uVar1;
  undefined4 uStack_18;
  undefined4 uStack_14;
  
  uStack_18 = *(undefined4 *)(param_1 + 0x28);
  uStack_14 = *(undefined4 *)(param_1 + 0x2c);
  cVar2 = .glue::PtInRect(param_2,&uStack_18);
  if (cVar2 == '\0') {
    uVar1 = 0;
  }
  else {
    uVar1 = .debug::_LocToProp__14TInventoryPileF5PointUc(*(undefined4 *)(param_1 + 0x24),param_2,0)
    ;
    if ((short)uVar1 < 0) {
      uVar1 = 0;
    }
  }
  return uVar1;
}


// ==== .PropToPoint__8TWInventFsP5Point @ 1008de2c ====
// CyDecompAt: created, body 1008de2c-1008de8f

bool _PropToPoint__8TWInventFsP5Point(int param_1,short param_2,undefined4 param_3)

{
  char cVar1;
  
  cVar1 = .debug::_PropToLoc__14TInventoryPileFsP5Point
                    (*(undefined4 *)(param_1 + 0x24),(int)param_2);
  if (cVar1 != '\0') {
    .glue::LocalToGlobal(param_3);
  }
  return cVar1 != '\0';
}


// ==== .MouseRoutine__8TWInventF5Point @ 1008dec4 ====
// CyDecompAt: created, body 1008dec4-1008df33

bool _MouseRoutine__8TWInventF5Point(int param_1,undefined4 param_2)

{
  short sVar1;
  
  sVar1 = .debug::_LocToProp__14TInventoryPileF5PointUc(*(undefined4 *)(param_1 + 0x24),param_2,0);
  if (sVar1 != 0) {
    .debug::_MouseRoutine__16TDroppableWindowF5Points
              (*(undefined4 *)(param_1 + 0x20),param_2,
               (int)*(short *)(*(int *)PTR_DAT_100cdb84 + 0x12));
  }
  return sVar1 != 0;
}


// ==== .LDEFDraw__10TWListListFUcP4Rect5Pointss @ 1008e030 ====
// CyDecompAt: created, body 1008e030-1008e113

void _LDEFDraw__10TWListListFUcP4Rect5Pointss
               (int param_1,char param_2,short *param_3,undefined4 param_4,short param_5,
               short param_6)

{
  uint uVar1;
  short sStack_18;
  short sStack_16;
  
  .glue::GetFontInfo(&sStack_18);
  .glue::EraseRect(param_3);
  uVar1 = (int)*param_3 + (int)sStack_18 + (int)sStack_16 + (int)param_3[2];
  .glue::MoveTo(param_3[1] + 3,
                (((int)uVar1 >> 1) + (uint)((int)uVar1 < 0 && (uVar1 & 1) != 0)) - (int)sStack_16);
  .debug::_AADrawText__FPcss
            (**(undefined4 **)(**(int **)(param_1 + 4) + 0x50),param_5 + 4,param_6 + -4);
  if (param_2 != '\0') {
    uVar1 = .glue::LMGetHiliteMode();
    .glue::LMSetHiliteMode(uVar1 & 0xffffff7f);
    .glue::InvertRect(param_3);
  }
  return;
}


// ==== .LDEFHilite__10TWListListFUcP4Rect5Pointss @ 1008e150 ====
// CyDecompAt: created, body 1008e150-1008e18f

void _LDEFHilite__10TWListListFUcP4Rect5Pointss
               (undefined4 param_1,undefined4 param_2,undefined4 param_3)

{
  uint uVar1;
  
  uVar1 = .glue::LMGetHiliteMode();
  .glue::LMSetHiliteMode(uVar1 & 0xffffff7f);
  .glue::InvertRect(param_3);
  return;
}


// ==== .Marshal__6TWListFP7TStream @ 1008e3bc ====
// CyDecompAt: created, body 1008e3bc-1008e433

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Marshal__6TWListFP7TStream(undefined4 param_1,undefined4 param_2)

{
  undefined *apuStack_18 [5];
  
  FUN_100c50e8(param_2,_DAT_100ceda0,0x774c7374);
  .debug::_Marshal__Q215TScriptedWindow7TWidgetFP7TStream(param_1,param_2);
  apuStack_18[0] = PTR_s_Marshalling_TWList_not_supported_100ced64;
  FUN_100bdef4(_DAT_100cede4,apuStack_18,0);
  return;
}


// ==== .__dt__6TWListFv @ 1008e464 ====
// CyDecompAt: created, body 1008e464-1008e4e7

undefined4 * ___dt__6TWListFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d6adc;
    if (param_1[9] != 0) {
      FUN_100c50e8(param_1[9],1);
    }
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d71b8;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .Draw__6TWListFP8GrafPort @ 1008e50c ====
// CyDecompAt: created, body 1008e50c-1008e56f

void _Draw__6TWListFP8GrafPort(int param_1)

{
  undefined4 uStack_18;
  undefined4 uStack_14;
  
  uStack_18 = *(undefined4 *)(param_1 + 0x28);
  uStack_14 = *(undefined4 *)(param_1 + 0x2c);
  .glue::EraseRect(&uStack_18);
  FUN_100c50e8(*(undefined4 *)(param_1 + 0x24),
               *(undefined4 *)(*(int *)(PTR_DAT_100cdb94 + 0xca) + 0x18));
  return;
}


// ==== .CanDrop__6TWListFsR5Point @ 1008e59c ====
// CyDecompAt: created, body 1008e59c-1008e6f3

undefined4 _CanDrop__6TWListFsR5Point(int param_1,undefined4 param_2,undefined4 *param_3)

{
  undefined *puVar1;
  undefined4 uVar2;
  short sVar4;
  char cVar5;
  undefined4 *puVar3;
  undefined1 auStack_38 [4];
  undefined4 uStack_34;
  undefined4 uStack_30;
  undefined4 uStack_2c;
  undefined4 uStack_28;
  
  puVar1 = PTR_DAT_100cdb98;
  if ((short)param_2 == *(short *)(param_1 + 0x30)) {
    .debug::_AutoEye__13TStatusWindowFPc
              (*(undefined4 *)PTR_DAT_100cdb98,PTR_s__Fold_Space__100ced74);
    uVar2 = 0;
  }
  else {
    sVar4 = .debug::_GetPropParent__Fs(param_2);
    if (*(short *)(param_1 + 0x30) == sVar4) {
      .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Abort__100ced70);
      uVar2 = 0;
    }
    else {
      uStack_2c = *(undefined4 *)(param_1 + 0x28);
      uStack_28 = *(undefined4 *)(param_1 + 0x2c);
      cVar5 = .glue::PtInRect(*param_3,&uStack_2c);
      if (cVar5 == '\0') {
        .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,uRam100cedac);
        uVar2 = 0;
      }
      else {
        .debug::___ct__5VAddrFcUsUs(&uStack_34,4,0,*(undefined2 *)(param_1 + 0x30));
        puVar3 = (undefined4 *).debug::___ct__5VAddrFcUsUs(auStack_38,4,0,param_2);
        .debug::_DoInterp__7TInterpFs5VAddr5VAddr(&uStack_30,0x17,uStack_34,*puVar3);
        cVar5 = .debug::_IsTrue__7TInterpF5VAddr(uStack_30);
        if (cVar5 == '\0') {
          .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Doesn_t_fit__100ced6c);
          uVar2 = 0;
        }
        else {
          .debug::_AutoEye__13TStatusWindowFPc(*(undefined4 *)puVar1,PTR_s__Put_In__100ced68);
          uVar2 = 1;
        }
      }
    }
  }
  return uVar2;
}


// ==== .DoDrop__6TWListFs5Point @ 1008e720 ====
// CyDecompAt: created, body 1008e720-1008e78f

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DoDrop__6TWListFs5Point(int param_1,short param_2,undefined4 param_3)

{
  char cVar1;
  undefined4 uStack_18;
  undefined4 uStack_14;
  
  uStack_18 = *(undefined4 *)(param_1 + 0x28);
  uStack_14 = *(undefined4 *)(param_1 + 0x2c);
  cVar1 = .glue::PtInRect(param_3,&uStack_18);
  if (cVar1 != '\0') {
    .debug::_TakeCommand__8TGameSysFss(*_DAT_100cdcd0,(int)param_2,(int)*(short *)(param_1 + 0x30));
  }
  return;
}


// ==== .PointToProp__6TWListF5Point @ 1008e7bc ====
// CyDecompAt: created, body 1008e7bc-1008e7c3

undefined4 _PointToProp__6TWListF5Point(void)

{
  return 0;
}


// ==== .MouseRoutine__6TWListF5Point @ 1008e7f4 ====
// CyDecompAt: created, body 1008e7f4-1008e967

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 _MouseRoutine__6TWListF5Point(int param_1,undefined4 param_2)

{
  short sVar2;
  undefined4 uVar1;
  char cVar4;
  ushort uVar3;
  undefined4 uStack_40;
  undefined4 uStack_3c;
  undefined4 uStack_38;
  undefined1 auStack_34 [4];
  short sStack_30;
  int iStack_2e;
  undefined4 uStack_28;
  undefined1 auStack_24 [8];
  
  sVar2 = .glue::FindControl(param_2,*(undefined4 *)(PTR_DAT_100cdb94 + 0xca),auStack_24);
  if (sVar2 == 0) {
    cVar4 = FUN_100c50e8(*(undefined4 *)(param_1 + 0x24),param_2,0);
    uVar3 = FUN_100c50e8();
    if (-1 < (short)uVar3) {
      uStack_28 = 0;
      iStack_2e = (uint)uVar3 << 0x10;
      sStack_30 = 4;
      .glue::LGetCell(&uStack_28,&sStack_30,iStack_2e,*(undefined4 *)(*(int *)(param_1 + 0x24) + 4))
      ;
      uVar1 = uStack_28;
      if (sStack_30 == 4) {
        if (cVar4 == '\0') {
          uStack_38 = uStack_28;
          .debug::_DoInterp__7TInterpFs5VAddr(auStack_34,8,uStack_28);
        }
        else {
          .debug::___ct__5VAddrFcUsUs(&uStack_40,4,0,*(undefined2 *)(param_1 + 0x30));
          .debug::_DoInterp__7TInterpFs5VAddr5VAddr(&uStack_3c,10,uStack_40,uVar1);
          .debug::_PostUse__8TGameSysF5VAddr5VAddr(*_DAT_100cdcd0,uStack_28,uStack_3c);
        }
      }
    }
    uVar1 = 0;
  }
  else {
    FUN_100c50e8(*(undefined4 *)(param_1 + 0x24),param_2,0);
    uVar1 = 1;
  }
  return uVar1;
}


// ==== .AddItem__6TWListF5VAddr5VAddr @ 1008e998 ====
// CyDecompAt: created, body 1008e998-1008ea8f

void _AddItem__6TWListF5VAddr5VAddr(int param_1,undefined4 param_2,undefined4 param_3)

{
  short sVar2;
  ushort uVar3;
  undefined4 uVar1;
  int iStack_38;
  
  .glue::LSetDrawingMode(0,*(undefined4 *)(*(int *)(param_1 + 0x24) + 4));
  sVar2 = FUN_100c50e8();
  uVar3 = .glue::LAddRow(1,(int)sVar2,*(undefined4 *)(*(int *)(param_1 + 0x24) + 4));
  iStack_38 = (uint)uVar3 << 0x10;
  .glue::LSetCell(&stack0x0000001c,4,iStack_38,*(undefined4 *)(*(int *)(param_1 + 0x24) + 4));
  uVar1 = .debug::_VAddrToStr__F5VAddr(param_3);
  sVar2 = FUN_100b6ce8();
  .glue::LAddToCell(uVar1,(int)sVar2,iStack_38,*(undefined4 *)(*(int *)(param_1 + 0x24) + 4));
  .glue::LSetDrawingMode(1,*(undefined4 *)(*(int *)(param_1 + 0x24) + 4));
  .glue::InvalRect(param_1 + 0x28);
  return;
}


// ==== .CreateFromStream__22TRegistrar<9TWAutoMap>FP7TStream @ 1008ee68 ====
// CyDecompAt: created, body 1008ee68-1008eeb3

int _CreateFromStream__22TRegistrar<9TWAutoMap>FP7TStream(undefined4 param_1)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x68);
  if (iVar1 != 0) {
    .debug::___ct__9TWAutoMapFP7TStream(iVar1,param_1);
  }
  return iVar1;
}


// ==== .CreateFromStream__25TRegistrar<11TWPixButton>FP7TStream @ 1008eefc ====
// CyDecompAt: created, body 1008eefc-1008ef47

int _CreateFromStream__25TRegistrar<11TWPixButton>FP7TStream(undefined4 param_1)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0xc4);
  if (iVar1 != 0) {
    .debug::___ct__11TWPixButtonFP7TStream(iVar1,param_1);
  }
  return iVar1;
}


// ==== .CreateFromStream__18TRegistrar<5TWPix>FP7TStream @ 1008ef94 ====
// CyDecompAt: created, body 1008ef94-1008efdf

int _CreateFromStream__18TRegistrar<5TWPix>FP7TStream(undefined4 param_1)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x58);
  if (iVar1 != 0) {
    .debug::___ct__5TWPixFP7TStream(iVar1,param_1);
  }
  return iVar1;
}


// ==== .CreateFromStream__27TRegistrar<13TWNumberEntry>FP7TStream @ 1008f024 ====
// CyDecompAt: created, body 1008f024-1008f06f

int _CreateFromStream__27TRegistrar<13TWNumberEntry>FP7TStream(undefined4 param_1)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x28);
  if (iVar1 != 0) {
    .debug::___ct__13TWNumberEntryFP7TStream(iVar1,param_1);
  }
  return iVar1;
}


// ==== .CreateFromStream__21TRegistrar<8TWNumber>FP7TStream @ 1008f0bc ====
// CyDecompAt: created, body 1008f0bc-1008f107

int _CreateFromStream__21TRegistrar<8TWNumber>FP7TStream(undefined4 param_1)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x28);
  if (iVar1 != 0) {
    .debug::___ct__8TWNumberFP7TStream(iVar1,param_1);
  }
  return iVar1;
}


// ==== .CreateFromStream__21TRegistrar<8TWButton>FP7TStream @ 1008f150 ====
// CyDecompAt: created, body 1008f150-1008f19b

int _CreateFromStream__21TRegistrar<8TWButton>FP7TStream(undefined4 param_1)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x28);
  if (iVar1 != 0) {
    .debug::___ct__8TWButtonFP7TStream(iVar1,param_1);
  }
  return iVar1;
}


// ==== .CreateFromStream__19TRegistrar<6TWIcon>FP7TStream @ 1008f1e4 ====
// CyDecompAt: created, body 1008f1e4-1008f22f

int _CreateFromStream__19TRegistrar<6TWIcon>FP7TStream(undefined4 param_1)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x28);
  if (iVar1 != 0) {
    .debug::___ct__6TWIconFP7TStream(iVar1,param_1);
  }
  return iVar1;
}


// ==== .CreateFromStream__21TRegistrar<8TWInvent>FP7TStream @ 1008f274 ====
// CyDecompAt: created, body 1008f274-1008f2bf

int _CreateFromStream__21TRegistrar<8TWInvent>FP7TStream(undefined4 param_1)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x34);
  if (iVar1 != 0) {
    .debug::___ct__8TWInventFP7TStream(iVar1,param_1);
  }
  return iVar1;
}


// ==== .CreateFromStream__19TRegistrar<6TWList>FP7TStream @ 1008f308 ====
// CyDecompAt: created, body 1008f308-1008f353

int _CreateFromStream__19TRegistrar<6TWList>FP7TStream(undefined4 param_1)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x34);
  if (iVar1 != 0) {
    .debug::___ct__6TWListFP7TStream(iVar1,param_1);
  }
  return iVar1;
}


// ==== .CreateFromStream__24TRegistrar<10TWMusicBox>FP7TStream @ 1008f398 ====
// CyDecompAt: created, body 1008f398-1008f3e3

int _CreateFromStream__24TRegistrar<10TWMusicBox>FP7TStream(undefined4 param_1)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x50);
  if (iVar1 != 0) {
    .debug::___ct__10TWMusicBoxFP7TStream(iVar1,param_1);
  }
  return iVar1;
}


// ==== .CreateFromStream__26TRegistrar<12TWScrollText>FP7TStream @ 1008f430 ====
// CyDecompAt: created, body 1008f430-1008f47b

int _CreateFromStream__26TRegistrar<12TWScrollText>FP7TStream(undefined4 param_1)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x34);
  if (iVar1 != 0) {
    .debug::___ct__12TWScrollTextFP7TStream(iVar1,param_1);
  }
  return iVar1;
}


// ==== .CreateFromStream__25TRegistrar<11TWTextEntry>FP7TStream @ 1008f4c8 ====
// CyDecompAt: created, body 1008f4c8-1008f513

int _CreateFromStream__25TRegistrar<11TWTextEntry>FP7TStream(undefined4 param_1)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x28);
  if (iVar1 != 0) {
    .debug::___ct__11TWTextEntryFP7TStream(iVar1,param_1);
  }
  return iVar1;
}


// ==== .CreateFromStream__19TRegistrar<6TWText>FP7TStream @ 1008f560 ====
// CyDecompAt: created, body 1008f560-1008f5ab

int _CreateFromStream__19TRegistrar<6TWText>FP7TStream(undefined4 param_1)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x34);
  if (iVar1 != 0) {
    .debug::___ct__6TWTextFP7TStream(iVar1,param_1);
  }
  return iVar1;
}


// ==== .Marshal__15TScriptedWindowFP7TStream @ 1008f5f0 ====
// CyDecompAt: created, body 1008f5f0-1008f737

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _Marshal__15TScriptedWindowFP7TStream(int param_1,undefined4 param_2)

{
  undefined4 uVar1;
  undefined4 *puVar2;
  undefined4 uStack_20;
  undefined4 auStack_1c [3];
  
  FUN_100c50e8(param_2,_DAT_100ceda0,0x53637257);
  .debug::_Marshal__16TInventoryWindowFP7TStream(param_1,param_2);
  uVar1 = *(undefined4 *)(param_1 + 4);
  .glue::GetPort(auStack_1c);
  .glue::SetPort(uVar1);
  uStack_20 = uRam100d69e4;
  .glue::LocalToGlobal(&uStack_20);
  FUN_100c50e8(param_2,_DAT_100ced54,
               (int)*(short *)(*(int *)(param_1 + 4) + 0x16) -
               (int)*(short *)(*(int *)(param_1 + 4) + 0x12),
               (int)*(short *)(*(int *)(param_1 + 4) + 0x14) -
               (int)*(short *)(*(int *)(param_1 + 4) + 0x10),(int)uStack_20._2_2_,
               (int)uStack_20._0_2_,*(undefined4 *)(param_1 + 0x30),(int)*(short *)(param_1 + 0x34),
               *(undefined4 *)(param_1 + 0x20));
  for (puVar2 = *(undefined4 **)(param_1 + 0x24);
      puVar2 != (undefined4 *)(*(int *)(param_1 + 0x24) + *(int *)(param_1 + 0x20) * 4);
      puVar2 = puVar2 + 1) {
    FUN_100c50e8(*puVar2,param_2);
  }
  .glue::SetPort(auStack_1c[0]);
  return;
}


// ==== .__dt__10TWListListFv @ 1008f94c ====
// CyDecompAt: created, body 1008f94c-1008f9af

undefined4 * ___dt__10TWListListFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d6b78;
    .debug::___dt__8TListBoxFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__10TWMusicBoxFv @ 1008f9d8 ====
// CyDecompAt: created, body 1008f9d8-1008fa3b

undefined4 * ___dt__10TWMusicBoxFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d6c58;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d71b8;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__8TWNumberFv @ 1008fa64 ====
// CyDecompAt: created, body 1008fa64-1008fac3

undefined4 * ___dt__8TWNumberFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d6ce8;
    .debug::___dt__9TWControlFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__13TWNumberEntryFv @ 1008fae8 ====
// CyDecompAt: created, body 1008fae8-1008fb47

undefined4 * ___dt__13TWNumberEntryFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d6d64;
    .debug::___dt__9TWControlFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__6TWIconFv @ 1008fb74 ====
// CyDecompAt: created, body 1008fb74-1008fbd7

undefined4 * ___dt__6TWIconFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d6f20;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d71b8;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__8TWButtonFv @ 1008fbfc ====
// CyDecompAt: created, body 1008fbfc-1008fc5b

undefined4 * ___dt__8TWButtonFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d6f9c;
    .debug::___dt__9TWControlFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .WantsFocus__11TWTextEntryFv @ 1008fc80 ====
// CyDecompAt: created, body 1008fc80-1008fc87

undefined4 _WantsFocus__11TWTextEntryFv(void)

{
  return 1;
}


// ==== .__dt__6TWTextFv @ 1008fcb8 ====
// CyDecompAt: created, body 1008fcb8-1008fd2b

undefined4 * ___dt__6TWTextFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d7158;
    .debug::___dt__Q23std59basic_string<c,Q23std14char_traits<c>,Q23std12allocator<c>>Fv
              (param_1 + 9,0xffffffff);
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d71b8;
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__Q23std40_EmptyMemberOpt<Q23std12allocator<c>,Ul>Fv @ 10090288 ====
// CyDecompAt: created, body 10090288-100902e3

int ___dt__Q23std40_EmptyMemberOpt<Q23std12allocator<c>,Ul>Fv(int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .__dt__Q23std12out_of_rangeFv @ 10090330 ====
// CyDecompAt: created, body 10090330-100903cb

undefined4 * ___dt__Q23std12out_of_rangeFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d725c;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d3cb8;
      if (param_1 != (undefined4 *)0xfffffffc) {
        .debug::___dt__28_RefCountedPtr<c,9_Array<c>>Fv(param_1 + 1,0xffffffff);
      }
      if (param_1 != (undefined4 *)0x0) {
        *param_1 = &PTR_PTR_100d3cc8;
      }
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__Q23std192_EmptyMemberOpt<Q23std88allocator<Q33std59basic_string<c,Q23std14char_traits<c>,Q23std12allocator<c>>9CharArray>,PQ33std59basic_string<c,Q23std14char_traits<c>,Q23std12allocator<c>>9CharArray>Fv @ 100906a4 ====
// CyDecompAt: created, body 100906a4-100906ff

int ___dt__Q23std192_EmptyMemberOpt<Q23std88allocator<Q33std59basic_string<c,Q23std14char_traits<c>,Q23std12allocator<c>>9CharArray>,PQ33std59basic_string<c,Q23std14char_traits<c>,Q23std12allocator<c>>9CharArray>Fv
              (int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .cbEndGame__FP5VAddr @ 10093f90 ====
// CyDecompAt: created, body 10093f90-100941cb

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbEndGame__FP5VAddr(undefined4 *param_1,undefined4 *param_2)

{
  undefined *puVar1;
  uint uVar2;
  int iVar3;
  undefined4 uVar4;
  short sVar5;
  char cVar6;
  uint uVar7;
  undefined4 uStack_28;
  undefined4 uStack_24;
  undefined1 auStack_20 [16];
  
  .debug::_GammaFadeOut(200);
  .glue::HideCursor();
  .glue::GetPort(auStack_20);
  uStack_28 = *(undefined4 *)(*(int *)*_DAT_100cdd40 + 0x22);
  uStack_24 = *(undefined4 *)(*(int *)*_DAT_100cdd40 + 0x26);
  iVar3 = .glue::NewCWindow(0,&uStack_28,PTR_DAT_100cee30,1,2,0xffffffff,0,0);
  .glue::SetPort();
  .glue::FillRect(iVar3 + 0x10,PTR_DAT_100cdb94 + 0xba);
  uVar4 = .debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  .debug::_SetText__Fs(0);
  .glue::ForeColor(0x1e);
  sVar5 = FUN_100b6ce8(uVar4);
  sVar5 = .glue::TextWidth(uVar4,0,(int)sVar5);
  uVar7 = ((int)*(short *)(iVar3 + 0x12) + (int)*(short *)(iVar3 + 0x16)) - (int)sVar5;
  uVar2 = (int)*(short *)(iVar3 + 0x14) + (int)*(short *)(iVar3 + 0x10);
  .glue::MoveTo((int)(short)((short)((int)uVar7 >> 1) + (ushort)((int)uVar7 < 0 && (uVar7 & 1) != 0)
                            ),
                (int)(short)((short)((int)uVar2 >> 1) + (ushort)((int)uVar2 < 0 && (uVar2 & 1) != 0)
                            ));
  sVar5 = FUN_100b6ce8(uVar4);
  .glue::DrawText(uVar4,0,(int)sVar5);
  .debug::_GammaFadeIn(300);
  iVar3 = .glue::TickCount();
  do {
    uVar2 = .glue::TickCount();
    if (iVar3 + 600U <= uVar2) break;
    cVar6 = .glue::Button();
  } while (cVar6 == '\0');
  .debug::_GammaFadeOut(200);
  puVar1 = PTR_DAT_100cdce0;
  *_DAT_100cdcc8 = 0;
  *(undefined4 *)puVar1 = 0;
  FUN_100c50e8();
  FUN_100c50e8();
  .debug::_GammaFadeIn(0x32);
  .glue::ShowCursor();
  .glue::FlushEvents(10,0);
  .glue::ExitToShell();
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbHeartBeat__FP5VAddr @ 100941f4 ====
// CyDecompAt: created, body 100941f4-1009422f

void _cbHeartBeat__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  undefined *puVar1;
  int iVar2;
  
  puVar1 = PTR_DAT_100cdbb0;
  iVar2 = *(short *)PTR_DAT_100cdbec * 0x20 + 0x12;
  PTR_DAT_100cdbf0[iVar2] =
       PTR_DAT_100cdbf0[iVar2] + (char)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  *param_1 = *(undefined4 *)puVar1;
  return;
}


// ==== .cbsetportrait__FP5VAddr @ 10094258 ====
// CyDecompAt: created, body 10094258-100942df

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbsetportrait__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  .debug::_ShowPortrait__13TConversationFss
            (*_DAT_100cdcc8,(int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
             (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4));
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbanimatetiles__FP5VAddr @ 1009430c ====
// CyDecompAt: created, body 1009430c-100943cf

void _cbanimatetiles__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  uint uVar3;
  uint uVar4;
  uint uVar5;
  short sVar6;
  
  puVar2 = PTR_DAT_100cdc64;
  puVar1 = PTR_DAT_100cdc28;
  uVar3 = *param_2;
  uVar5 = param_2[1];
  uVar4 = param_2[2];
  for (sVar6 = 0; sVar6 < 8; sVar6 = sVar6 + 1) {
    *(uint *)(puVar1 + sVar6 * 0x2800 +
                       (short)((ushort)((int)(uVar3 << 4 | uVar3 >> 0x1c) >> 4) & 0x9ff) * 4) =
         *(int *)puVar2 +
         ((int)(short)((ushort)((int)(uVar5 << 4 | uVar5 >> 0x1c) >> 4) & 0x9ff) +
          ((int)(short)((ushort)((int)(uVar4 << 4 | uVar4 >> 0x1c) >> 4) & 7) - 1U & (int)sVar6 / 1)
         & 0x9ff) * 0x400;
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbrender__FP5VAddr @ 100943fc ====
// CyDecompAt: created, body 100943fc-100944af

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbrender__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  short sVar1;
  undefined4 *puVar2;
  
  sVar1 = (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  if (sVar1 < 2) {
    FUN_100c50e8();
    *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  }
  else {
    puVar2 = (undefined4 *).glue::GetCursor(4);
    .glue::SetCursor(*puVar2);
    .debug::_ShowTileAnimate__10TMapWindowFs(*_DAT_100cdcdc,(int)sVar1);
    *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  }
  return;
}


// ==== .cbRenderAt__FP5VAddr @ 100944d8 ====
// CyDecompAt: created, body 100944d8-1009464f

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbRenderAt__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  undefined2 uVar1;
  bool bVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  undefined *puVar6;
  short sVar7;
  short sVar8;
  char cVar9;
  
  puVar6 = PTR_DAT_100cdc44;
  puVar4 = PTR_DAT_100cdbec;
  puVar3 = PTR_DAT_100cdbb8;
  sVar7 = (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  sVar8 = (short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4);
  if (sVar7 < 0) {
    bVar2 = false;
  }
  else if (sVar7 < *(short *)(*(int *)PTR_DAT_100cdbb8 + 0x20c1c)) {
    if (sVar8 < 0) {
      bVar2 = false;
    }
    else if (sVar8 < *(short *)(*(int *)PTR_DAT_100cdbb8 + 0x20c1e)) {
      bVar2 = true;
    }
    else {
      bVar2 = false;
    }
  }
  else {
    bVar2 = false;
  }
  if (bVar2) {
    cVar9 = .debug::_InZone__11TGameViewerFss(*(undefined4 *)PTR_DAT_100cdbb8,(int)sVar7,(int)sVar8)
    ;
    puVar5 = PTR_DAT_100cdbf0;
    if (cVar9 == '\0') {
      *param_1 = *(undefined4 *)PTR_DAT_100cde70;
    }
    else {
      *(undefined1 *)(*(int *)puVar6 + 6) = 0;
      **(uint **)puVar6 =
           ((int)sVar7 & 0xfffU) << 0xc | (int)sVar8 & 0xfffU | **(uint **)puVar6 & 0xff000000;
      *(uint *)puVar5 = **(uint **)puVar6 & 0xffffff;
      uVar1 = *(undefined2 *)puVar4;
      *(undefined2 *)puVar4 = 0;
      .debug::_DrawRoutine__11TGameViewerFs(*(undefined4 *)puVar3,1);
      .debug::_ShowTileAnimate__10TMapWindowFs(*_DAT_100cdcdc,1);
      *(undefined2 *)puVar4 = uVar1;
      *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
    }
  }
  else {
    *param_1 = *(undefined4 *)PTR_DAT_100cde70;
  }
  return;
}


// ==== .cbdeleteprop__FP5VAddr @ 10094678 ====
// CyDecompAt: created, body 10094678-10094703

void _cbdeleteprop__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  undefined4 uVar1;
  
  uVar1 = .debug::_GetPropParent__Fs((int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4));
  .debug::_DeleteProp__Fs((int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4));
  .debug::_Invalidate__16TInventoryWindowFss(uVar1,2);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbaddinv__FP5VAddr @ 10094730 ====
// CyDecompAt: created, body 10094730-100948f3

void _cbaddinv__FP5VAddr(uint *param_1,uint *param_2)

{
  undefined *puVar1;
  uint uVar2;
  ushort uVar3;
  short sVar4;
  short sVar5;
  uint uVar6;
  uint *puVar7;
  uint *puVar8;
  
  puVar1 = PTR_DAT_100cdc44;
  uVar3 = .debug::_NewProp__Fv();
  if ((short)uVar3 < 1) {
    *param_1 = *(uint *)PTR_DAT_100cdbb0;
  }
  else {
    puVar8 = (uint *)(*(int *)puVar1 + (short)uVar3 * 0x10);
    *(undefined1 *)puVar8 = 0x10;
    uVar6 = (uint)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
    *puVar8 = uVar6 & 0xfff | *puVar8 & 0xff000000;
    *(byte *)(puVar8 + 1) =
         (byte)(((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 0xe) << 2) & 0x7c |
         *(byte *)(puVar8 + 1) & 0x83;
    *(ushort *)(puVar8 + 1) =
         (ushort)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4) & 0x3ff |
         *(ushort *)(puVar8 + 1) & 0xfc00;
    *(char *)((int)puVar8 + 6) = (char)((int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4);
    *(undefined1 *)((int)puVar8 + 7) = 0;
    .debug::_SetItemCount__FP8PropItems
              (puVar8,(int)(short)((int)(param_2[3] << 4 | param_2[3] >> 0x1c) >> 4));
    if (((int)(param_2[3] << 4 | param_2[3] >> 0x1c) >> 4 < 2) ||
       (sVar4 = .debug::_GetItemCount__FP8PropItem(puVar8), 1 < sVar4)) {
      .debug::_ConjoinProp__FP8PropItem(puVar8);
    }
    else {
      for (sVar4 = 1; (int)sVar4 < (int)(param_2[3] << 4 | param_2[3] >> 0x1c) >> 4;
          sVar4 = sVar4 + 1) {
        sVar5 = .debug::_NewProp__Fv();
        uVar2 = puVar8[1];
        puVar7 = (uint *)(*(int *)puVar1 + sVar5 * 0x10);
        *puVar7 = *puVar8;
        puVar7[1] = uVar2;
        uVar2 = puVar8[3];
        puVar7[2] = puVar8[2];
        puVar7[3] = uVar2;
      }
    }
    .debug::_Invalidate__16TInventoryWindowFss(uVar6,2);
    *param_1 = uVar3 | 0x40000000;
  }
  return;
}


// ==== .cbsetmap__FP5VAddr @ 1009491c ====
// CyDecompAt: created, body 1009491c-1009492b

void _cbsetmap__FP5VAddr(undefined4 *param_1)

{
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbgetmap__FP5VAddr @ 10094954 ====
// CyDecompAt: created, body 10094954-100949fb

void _cbgetmap__FP5VAddr(uint *param_1,uint *param_2)

{
  short sVar1;
  short sVar2;
  uint uVar3;
  int iVar4;
  
  iVar4 = *(int *)PTR_DAT_100cdbb8;
  sVar1 = (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  sVar2 = (short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4);
  if ((((sVar1 < 0) || (*(short *)(iVar4 + 0x20c1c) <= sVar1)) || (sVar2 < 0)) ||
     (*(short *)(iVar4 + 0x20c1e) <= sVar2)) {
    uVar3 = 0xff;
  }
  else {
    uVar3 = (uint)*(ushort *)
                   (*(int *)PTR_DAT_100cdc5c +
                   sVar1 * 2 + (int)sVar2 * (int)*(short *)(iVar4 + 0x20c1c) * 2);
  }
  *param_1 = uVar3;
  return;
}


// ==== .cbsetpropowner__FP5VAddr @ 10094a24 ====
// CyDecompAt: created, body 10094a24-10094b8f

void _cbsetpropowner__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  ushort uVar3;
  short sVar4;
  short sVar5;
  short sVar6;
  uint uVar7;
  int iVar8;
  uint *puVar9;
  
  puVar2 = PTR_DAT_100cdc3c;
  puVar1 = PTR_DAT_100cdbb0;
  iVar8 = 0x100;
  uVar7 = param_2[1];
  uVar3 = (ushort)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  sVar6 = (short)((int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4);
  sVar4 = (short)((int)(param_2[3] << 4 | param_2[3] >> 0x1c) >> 4);
  puVar9 = (uint *)(*(int *)PTR_DAT_100cdc44 + 0x1000);
  while( true ) {
    if (*(short *)puVar2 <= (short)iVar8) {
      *param_1 = *(undefined4 *)puVar1;
      return;
    }
    if (((((*(ushort *)(puVar9 + 1) & 0x3ff) == (uVar3 & 0x3ff)) &&
         ((ushort)(*(byte *)(puVar9 + 1) >> 2 & 0x1f) == (short)uVar3 >> 10)) &&
        (sVar5 = .debug::_GetItemQuality__FP8PropItem(puVar9),
        (short)((int)(uVar7 << 4 | uVar7 >> 0x1c) >> 4) == sVar5)) &&
       (sVar5 = .debug::_GetPropUltimateParent__Fs(iVar8), sVar5 == sVar6)) break;
    puVar9 = puVar9 + 4;
    iVar8 = iVar8 + 1;
  }
  *puVar9 = *puVar9 & 0xff0000 | (int)sVar4 & 0xffffffU | *puVar9 & 0xff000000;
  *(undefined1 *)puVar9 = 0x10;
  .debug::_Invalidate__16TInventoryWindowFss((int)sVar6,2);
  .debug::_Invalidate__16TInventoryWindowFss((int)sVar4,2);
  *param_1 = *(undefined4 *)puVar1;
  return;
}


// ==== .cbrnd__FP5VAddr @ 10094bbc ====
// CyDecompAt: created, body 10094bbc-10094c5b

void _cbrnd__FP5VAddr(uint *param_1,uint *param_2)

{
  short sVar1;
  short sVar3;
  short sVar4;
  uint uVar2;
  
  sVar3 = (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  sVar1 = (short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4);
  if (sVar3 < sVar1) {
    sVar4 = .glue::Random();
    uVar2 = (int)sVar1 - (int)sVar3;
    *param_1 = (int)sVar3 + ((int)sVar4 - ((uint)(int)sVar4 / uVar2) * uVar2) & 0xfffffff;
  }
  else {
    *param_1 = (int)sVar3 & 0xfffffff;
  }
  return;
}


// ==== .cbcreateprop__FP5VAddr @ 10094c80 ====
// CyDecompAt: created, body 10094c80-10094e17

void _cbcreateprop__FP5VAddr(uint *param_1,uint *param_2)

{
  uint uVar1;
  uint uVar2;
  uint uVar3;
  ushort uVar5;
  undefined4 uVar4;
  uint uVar6;
  uint uVar7;
  uint uVar8;
  uint uVar9;
  uint *puVar10;
  
  uVar6 = *param_2;
  uVar1 = param_2[1];
  uVar8 = param_2[2];
  uVar7 = param_2[3];
  uVar3 = param_2[4];
  uVar2 = param_2[5];
  uVar9 = param_2[6];
  uVar5 = .debug::_NewProp__Fv();
  if (uVar5 != 0xffff) {
    puVar10 = (uint *)(*(int *)PTR_DAT_100cdc44 + (short)uVar5 * 0x10);
    *(char *)puVar10 = (char)((int)(uVar6 << 4 | uVar6 >> 0x1c) >> 4);
    *puVar10 = ((int)(short)((int)(uVar1 << 4 | uVar1 >> 0x1c) >> 4) & 0xfffU) << 0xc |
               (int)(short)((int)(uVar8 << 4 | uVar8 >> 0x1c) >> 4) & 0xfffU | *puVar10 & 0xff000000
    ;
    *(byte *)(puVar10 + 1) =
         (byte)((int)(short)((int)(uVar7 << 4 | uVar7 >> 0x1c) >> 4) << 2) & 0x7c |
         *(byte *)(puVar10 + 1) & 0x83;
    *(ushort *)(puVar10 + 1) =
         (ushort)((int)(uVar3 << 4 | uVar3 >> 0x1c) >> 4) & 0x3ff |
         *(ushort *)(puVar10 + 1) & 0xfc00;
    *(char *)((int)puVar10 + 6) = (char)((int)(uVar2 << 4 | uVar2 >> 0x1c) >> 4);
    *(char *)((int)puVar10 + 7) = '\0';
    .debug::_SetItemCount__FP8PropItems
              (puVar10,(int)(short)((int)(uVar9 << 4 | uVar9 >> 0x1c) >> 4));
    *(undefined1 *)(*(int *)PTR_DAT_100cdbb8 + 0xc) = 1;
    uVar4 = .debug::_GetPropParent__FP8PropItem(puVar10);
    if ((short)uVar4 != 0) {
      if (*(char *)puVar10 == '\x1c') {
        .debug::_Invalidate__16TInventoryWindowFss(uVar4,0x202);
      }
      else {
        .debug::_Invalidate__16TInventoryWindowFss(uVar4,2);
      }
    }
  }
  *param_1 = uVar5 | 0x40000000;
  return;
}


// ==== .cbwhohas__FP5VAddr @ 10094e44 ====
// CyDecompAt: created, body 10094e44-10094f8b

void _cbwhohas__FP5VAddr(uint *param_1,uint *param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  ushort uVar3;
  ushort uVar4;
  ushort uVar5;
  int iVar6;
  int iVar7;
  uint uStack_38;
  
  puVar2 = PTR_DAT_100cdc3c;
  puVar1 = PTR_DAT_100cdbf0;
  iVar6 = 0x100;
  uVar4 = (ushort)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  iVar7 = *(int *)PTR_DAT_100cdc44 + 0x1000;
  uVar3 = (ushort)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4);
  do {
    if (*(short *)puVar2 <= (short)iVar6) {
      *param_1 = *(uint *)PTR_DAT_100cdbb0;
      return;
    }
    if ((((*(ushort *)(iVar7 + 4) & 0x3ff) == (uVar4 & 0x3ff)) &&
        ((ushort)(*(byte *)(iVar7 + 4) >> 2 & 0x1f) == (short)uVar4 >> 10)) &&
       ((uVar3 == 0 || (*(byte *)(iVar7 + 6) == uVar3)))) {
      uVar5 = .debug::_GetPropUltimateParent__Fs(iVar6);
      if (0xff < (short)uVar5) {
        uVar5 = 0;
      }
      if ((uVar5 != 0) && ((puVar1[(short)uVar5 * 0x20 + 8] & 0x40) != 0)) {
        uStack_38 = uVar5 | 0x40400000;
        *param_1 = uStack_38;
        return;
      }
    }
    iVar7 = iVar7 + 0x10;
    iVar6 = iVar6 + 1;
  } while( true );
}


// ==== .cbgetinv__FP5VAddr @ 10094fb4 ====
// CyDecompAt: created, body 10094fb4-100950ef

void _cbgetinv__FP5VAddr(uint *param_1,uint *param_2)

{
  undefined *puVar1;
  uint uVar2;
  uint uVar3;
  short sVar4;
  ushort uVar5;
  uint uVar6;
  int iVar7;
  
  puVar1 = PTR_DAT_100cdc3c;
  uVar6 = 0x100;
  uVar2 = *param_2;
  uVar3 = param_2[2];
  uVar5 = (ushort)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4);
  iVar7 = *(int *)PTR_DAT_100cdc44 + 0x1000;
  do {
    if (*(short *)puVar1 <= (short)uVar6) {
      *param_1 = *(uint *)PTR_DAT_100cdbb0;
      return;
    }
    if ((((*(ushort *)(iVar7 + 4) & 0x3ff) == (uVar5 & 0x3ff)) &&
        ((ushort)(*(byte *)(iVar7 + 4) >> 2 & 0x1f) == (short)uVar5 >> 10)) &&
       ((ushort)*(byte *)(iVar7 + 6) == (ushort)((int)(uVar3 << 4 | uVar3 >> 0x1c) >> 4))) {
      sVar4 = .debug::_GetPropUltimateParent__Fs(uVar6);
      if (0xff < sVar4) {
        sVar4 = 0;
      }
      if (sVar4 == (short)((int)(uVar2 << 4 | uVar2 >> 0x1c) >> 4)) {
        *param_1 = uVar6 & 0xffff | 0x40000000;
        return;
      }
    }
    iVar7 = iVar7 + 0x10;
    uVar6 = uVar6 + 1;
  } while( true );
}


// ==== .cbcountinv__FP5VAddr @ 10095118 ====
// CyDecompAt: created, body 10095118-1009521b

void _cbcountinv__FP5VAddr(uint *param_1,uint *param_2)

{
  undefined *puVar1;
  ushort uVar2;
  short sVar3;
  uint uVar4;
  short sVar5;
  int iVar6;
  int iVar7;
  
  puVar1 = PTR_DAT_100cdc3c;
  sVar5 = 0;
  uVar4 = *param_2;
  uVar2 = (ushort)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4);
  iVar7 = *(int *)PTR_DAT_100cdc44 + 0x1000;
  for (iVar6 = 0x100; (short)iVar6 < *(short *)puVar1; iVar6 = iVar6 + 1) {
    if (((*(ushort *)(iVar7 + 4) & 0x3ff) == (uVar2 & 0x3ff)) &&
       ((ushort)(*(byte *)(iVar7 + 4) >> 2 & 0x1f) == (short)uVar2 >> 10)) {
      sVar3 = .debug::_GetPropUltimateParent__Fs(iVar6);
      if (0xff < sVar3) {
        sVar3 = 0;
      }
      if (sVar3 == (short)((int)(uVar4 << 4 | uVar4 >> 0x1c) >> 4)) {
        sVar3 = .debug::_GetItemCount__FP8PropItem(iVar7);
        sVar5 = sVar5 + sVar3;
      }
    }
    iVar7 = iVar7 + 0x10;
  }
  *param_1 = (int)sVar5 & 0xfffffff;
  return;
}


// ==== .cbsubinv__FP5VAddr @ 10095244 ====
// CyDecompAt: created, body 10095244-100953f3

void _cbsubinv__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  undefined *puVar1;
  uint uVar2;
  short sVar4;
  int iVar3;
  ushort uVar5;
  short sVar6;
  int iVar7;
  int iVar8;
  int iVar9;
  
  puVar1 = PTR_DAT_100cdc3c;
  uVar2 = param_2[2];
  uVar5 = (ushort)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4);
  sVar4 = (short)((int)(param_2[3] << 4 | param_2[3] >> 0x1c) >> 4);
  iVar8 = (int)sVar4;
  sVar6 = (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  if (sVar4 == 0) {
    iVar8 = 1;
  }
  iVar7 = 0x100;
  iVar9 = *(int *)PTR_DAT_100cdc44 + 0x1000;
  while( true ) {
    if ((*(short *)puVar1 <= (short)iVar7) || ((short)iVar8 == 0)) break;
    if (((*(ushort *)(iVar9 + 4) & 0x3ff) == (uVar5 & 0x3ff)) &&
       ((ushort)(*(byte *)(iVar9 + 4) >> 2 & 0x1f) == (short)uVar5 >> 10)) {
      sVar4 = .debug::_GetItemQuality__FP8PropItem(iVar9);
      if ((short)((int)(uVar2 << 4 | uVar2 >> 0x1c) >> 4) == sVar4) {
        sVar4 = .debug::_GetPropUltimateParent__Fs(iVar7);
        if (0xff < sVar4) {
          sVar4 = 0;
        }
        if (sVar4 == sVar6) {
          sVar4 = .debug::_GetItemCount__FP8PropItem(iVar9);
          if ((short)iVar8 < sVar4) {
            iVar3 = .debug::_GetItemCount__FP8PropItem(iVar9);
            .debug::_SetItemCount__FP8PropItems(iVar9,iVar3 - iVar8);
            iVar8 = 0;
          }
          else {
            iVar3 = .debug::_GetItemCount__FP8PropItem(iVar9);
            iVar8 = iVar8 - iVar3;
            .debug::_DeleteProp__Fs(iVar7);
          }
        }
      }
    }
    iVar9 = iVar9 + 0x10;
    iVar7 = iVar7 + 1;
  }
  .debug::_Invalidate__16TInventoryWindowFss((int)sVar6,2);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbpartychar__FP5VAddr @ 1009541c ====
// CyDecompAt: created, body 1009541c-1009551b

void _cbpartychar__FP5VAddr(uint *param_1,uint *param_2)

{
  short sVar1;
  short sVar2;
  uint uStack_40;
  uint uStack_3c;
  
  sVar1 = (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  if ((short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4) == 1) {
    uStack_3c = *(ushort *)(PTR_DAT_100cdbe4 + sVar1 * 2) | 0x40400000;
    *param_1 = uStack_3c;
  }
  else {
    for (sVar2 = 0; sVar2 < *(short *)PTR_DAT_100cdb9c; sVar2 = sVar2 + 1) {
      if ((*(ushort *)(PTR_DAT_100cdbf0 + *(short *)(PTR_DAT_100cdbe4 + sVar2 * 2) * 0x20 + 6) & 1)
          != 0) {
        if (sVar1 == 0) {
          uStack_40 = *(ushort *)(PTR_DAT_100cdbe4 + sVar2 * 2) | 0x40400000;
          *param_1 = uStack_40;
          return;
        }
        sVar1 = sVar1 + -1;
      }
    }
    *param_1 = *(uint *)PTR_DAT_100cdbb0;
  }
  return;
}


// ==== .cbwhowill__FP5VAddr @ 10095544 ====
// CyDecompAt: created, body 10095544-100955d3

void _cbwhowill__FP5VAddr(uint *param_1,uint *param_2)

{
  ushort uVar1;
  uint uStack_28;
  
  uVar1 = .debug::_WhoWill__12TInteractionFPcUc
                    (PTR_s_Who_Will_100c790b_8_100cee2c,
                     (int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4 & 0xff);
  if (uVar1 == 0) {
    *param_1 = *(uint *)PTR_DAT_100cdbb0;
  }
  else {
    uStack_28 = uVar1 | 0x40400000;
    *param_1 = uStack_28;
  }
  return;
}


// ==== .cbhowmany__FP5VAddr @ 100955fc ====
// CyDecompAt: created, body 100955fc-1009568b

void _cbhowmany__FP5VAddr(uint *param_1,int *param_2)

{
  uint uVar1;
  undefined4 uVar2;
  short sVar3;
  uint uVar4;
  
  uVar1 = param_2[1];
  uVar4 = param_2[2];
  if (*param_2 == *(int *)PTR_DAT_100cdbb0) {
    uVar2 = 0;
  }
  else {
    uVar2 = .debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  }
  sVar3 = .debug::_HowMany__12TInteractionFPcss
                    (uVar2,(int)(short)((int)(uVar1 << 4 | uVar1 >> 0x1c) >> 4),
                     (int)(short)((int)(uVar4 << 4 | uVar4 >> 0x1c) >> 4));
  *param_1 = (int)sVar3 & 0xfffffff;
  return;
}


// ==== .cbgetdigit__FP5VAddr @ 100956b4 ====
// CyDecompAt: created, body 100956b4-10095747

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbgetdigit__FP5VAddr(uint *param_1)

{
  undefined4 *puVar1;
  char cVar2;
  
  puVar1 = _DAT_100cdcc8;
  cVar2 = FUN_100c50e8(*_DAT_100cdcc8,PTR_s_0123456789_100cee28);
  FUN_100c50e8();
  .debug::_myprintf__13TConversationFPce(*puVar1,PTR_DAT_100cee24,(int)(short)(cVar2 + -0x30));
  *param_1 = (int)(short)(cVar2 + -0x30) & 0xfffffff;
  return;
}


// ==== .cbwhosaid__FP5VAddr @ 10095770 ====
// CyDecompAt: created, body 10095770-1009577f

void _cbwhosaid__FP5VAddr(undefined4 *param_1)

{
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbinvspace__FP5VAddr @ 100957a8 ====
// CyDecompAt: created, body 100957a8-1009583f

void _cbinvspace__FP5VAddr(uint *param_1,uint *param_2)

{
  short sVar1;
  short sVar2;
  int iVar3;
  
  iVar3 = (int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  sVar1 = .debug::_GetMaxInvEncumb__Fs(iVar3);
  sVar2 = .debug::_GetCurInvEncumb__Fs(iVar3);
  if ((short)(sVar1 - sVar2) < 0) {
    *param_1 = 0;
  }
  else {
    *param_1 = (int)(short)(sVar1 - sVar2) & 0xfffffff;
  }
  return;
}


// ==== .cbgetweight__FP5VAddr @ 10095868 ====
// CyDecompAt: created, body 10095868-100958ef

void _cbgetweight__FP5VAddr(uint *param_1,uint *param_2)

{
  uint uVar1;
  short sVar2;
  short sVar3;
  
  uVar1 = param_2[1];
  sVar3 = (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  sVar2 = .debug::_GetCurInvEncumb__Fs((int)sVar3);
  sVar3 = .debug::_GetObjectWeight__Fsss
                    ((int)sVar3 & 0x3ff,(int)(sVar3 >> 10),
                     (int)(short)((int)(uVar1 << 4 | uVar1 >> 0x1c) >> 4));
  *param_1 = (int)sVar3 + (int)sVar2 & 0xfffffff;
  return;
}


// ==== .cbpartyjoin__FP5VAddr @ 10095918 ====
// CyDecompAt: created, body 10095918-100959e7

void _cbpartyjoin__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  short sVar1;
  int iVar2;
  
  sVar1 = (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  if (*(int *)PTR_DAT_100cdbe8 == 2) {
    *param_1 = 1;
  }
  else if (*(short *)PTR_DAT_100cdb9c == 8) {
    *param_1 = 2;
  }
  else {
    iVar2 = sVar1 * 0x20 + 8;
    PTR_DAT_100cdbf0[iVar2] = PTR_DAT_100cdbf0[iVar2] | 0x40;
    .debug::_RebuildParty__Fv();
    .debug::_Rebuild__13TStatusWindowFv(*(undefined4 *)PTR_DAT_100cdb98);
    .debug::_JoinParty__14TActiveMonsterFs((int)sVar1);
    *param_1 = 0;
  }
  return;
}


// ==== .cbpartyleave__FP5VAddr @ 10095a10 ====
// CyDecompAt: created, body 10095a10-10095ac3

void _cbpartyleave__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  short sVar1;
  int iVar2;
  
  sVar1 = (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  if (*(int *)PTR_DAT_100cdbe8 == 2) {
    *param_1 = 1;
  }
  else {
    iVar2 = sVar1 * 0x20 + 8;
    PTR_DAT_100cdbf0[iVar2] = PTR_DAT_100cdbf0[iVar2] & 0xbf;
    .debug::_RebuildParty__Fv();
    .debug::_Rebuild__13TStatusWindowFv(*(undefined4 *)PTR_DAT_100cdb98);
    .debug::_LeaveParty__14TActiveMonsterFs((int)sVar1);
    *param_1 = 0;
  }
  return;
}


// ==== .cbwhichofyou__FP5VAddr @ 10095af0 ====
// CyDecompAt: created, body 10095af0-10095b93

void _cbwhichofyou__FP5VAddr(uint *param_1,undefined4 *param_2)

{
  undefined4 uVar1;
  ushort uVar2;
  uint uStack_18;
  
  uVar1 = .debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  uVar2 = .debug::_WhoWill__12TInteractionFPcUc(uVar1,0);
  if (uVar2 == 0) {
    *param_1 = *(uint *)PTR_DAT_100cdbb0;
  }
  else {
    uStack_18 = uVar2 | 0x40400000;
    *param_1 = uStack_18;
  }
  return;
}


// ==== .cbnearby__FP5VAddr @ 10095bc0 ====
// CyDecompAt: created, body 10095bc0-1009602f

void _cbnearby__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  ushort uVar1;
  bool bVar2;
  ushort uVar3;
  char cVar6;
  undefined4 *puVar4;
  uint uVar5;
  uint uVar7;
  uint *puVar8;
  short sVar9;
  short sVar10;
  short sVar11;
  int iVar12;
  
  uVar1 = (ushort)(*(uint *)(PTR_DAT_100cdbf0 + *(short *)PTR_DAT_100cdbec * 0x20) >> 0xc) & 0xfff;
  uVar3 = (ushort)*(undefined4 *)(PTR_DAT_100cdbf0 + *(short *)PTR_DAT_100cdbec * 0x20) & 0xfff;
  if (*(char *)param_2 < '\0') {
    cVar6 = -1;
  }
  else {
    cVar6 = *(char *)param_2 >> 4;
  }
  if ((cVar6 != '\x04') || ((*param_2 & 0xfff0000) != 0)) {
    if (*(char *)param_2 < '\0') {
      cVar6 = -1;
    }
    else {
      cVar6 = *(char *)param_2 >> 4;
    }
    if ((cVar6 != '\0') || ((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4 < 0x100)) {
      if (*(char *)param_2 < '\0') {
        cVar6 = -1;
      }
      else {
        cVar6 = *(char *)param_2 >> 4;
      }
      if ((cVar6 != '\x04') || ((*param_2 & 0xfff0000) != 0x400000)) {
        if (*(char *)param_2 < '\0') {
          cVar6 = -1;
        }
        else {
          cVar6 = *(char *)param_2 >> 4;
        }
        if ((cVar6 != '\0') || (0xff < (int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4)) {
          *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
          return;
        }
      }
      sVar10 = (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
      puVar8 = (uint *)(PTR_DAT_100cdbf0 + sVar10 * 0x20);
      if (*(uint *)(PTR_DAT_100cdbf0 + *(short *)PTR_DAT_100cdbec * 0x20) >> 0x18 != *puVar8 >> 0x18
         ) {
        *param_1 = *(undefined4 *)PTR_DAT_100cde70;
        return;
      }
      iVar12 = *(int *)PTR_DAT_100cdbb8;
      sVar11 = ((ushort)(*puVar8 >> 0xc) & 0xfff) - uVar1;
      sVar9 = ((ushort)*puVar8 & 0xfff) - uVar3;
      bVar2 = false;
      if ((((-(int)*(short *)(iVar12 + 2) <= (int)sVar11) && (sVar11 <= *(short *)(iVar12 + 2))) &&
          (-(int)*(short *)(iVar12 + 2) <= (int)sVar9)) && (sVar9 <= *(short *)(iVar12 + 2))) {
        uVar5 = (uint)*(short *)(iVar12 + 4);
        uVar7 = (uint)*(short *)(iVar12 + 4);
        if ((*(byte *)((int)sVar11 +
                      ((int)uVar5 >> 1) + (uint)((int)uVar5 < 0 && (uVar5 & 1) != 0) +
                      (int)*(short *)(iVar12 + 4) *
                      ((int)sVar9 + ((int)uVar7 >> 1) + (uint)((int)uVar7 < 0 && (uVar7 & 1) != 0))
                      + iVar12 + 0xc0c8) & 3) != 0) {
          bVar2 = true;
        }
      }
      if (bVar2) {
        if ((*(char *)((int)puVar8 + 0x16) != -0x6f) &&
           ((*(ushort *)(PTR_DAT_100cdbf0 + sVar10 * 0x20 + 6) & 0x4000) == 0)) {
          *param_1 = *(undefined4 *)PTR_DAT_100cddec;
          return;
        }
        *param_1 = *(undefined4 *)PTR_DAT_100cde70;
        return;
      }
      *param_1 = *(undefined4 *)PTR_DAT_100cde70;
      return;
    }
  }
  bVar2 = false;
  sVar9 = (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  iVar12 = *(int *)PTR_DAT_100cdbb8;
  puVar4 = (undefined4 *)(*(int *)PTR_DAT_100cdc44 + sVar9 * 0x10);
  sVar10 = *(short *)((int)puVar4 + 2);
  sVar11 = ((short)((uint)*puVar4 >> 8) >> 4) - uVar1;
  sVar10 = ((short)((ushort)((uint)((int)sVar10 << 0x14) >> 0x10) | (ushort)(sVar10 >> 0xf) >> 0xc)
           >> 4) - uVar3;
  if (((-(int)*(short *)(iVar12 + 2) <= (int)sVar11) && (sVar11 <= *(short *)(iVar12 + 2))) &&
     ((-(int)*(short *)(iVar12 + 2) <= (int)sVar10 && (sVar10 <= *(short *)(iVar12 + 2))))) {
    uVar5 = (uint)*(short *)(iVar12 + 4);
    uVar7 = (uint)*(short *)(iVar12 + 4);
    if ((*(byte *)((int)sVar11 +
                  ((int)uVar5 >> 1) + (uint)((int)uVar5 < 0 && (uVar5 & 1) != 0) +
                  (int)*(short *)(iVar12 + 4) *
                  ((int)sVar10 + ((int)uVar7 >> 1) + (uint)((int)uVar7 < 0 && (uVar7 & 1) != 0)) +
                  iVar12 + 0xc0c8) & 3) != 0) {
      bVar2 = true;
    }
  }
  if (bVar2) {
    if (sVar9 < 0x100) {
      if ((PTR_DAT_100cdbf0[sVar9 * 0x20 + 0x16] != -0x6f) &&
         ((*(ushort *)(PTR_DAT_100cdbf0 + sVar9 * 0x20 + 6) & 0x4000) == 0)) {
        *param_1 = *(undefined4 *)PTR_DAT_100cddec;
        return;
      }
      *param_1 = *(undefined4 *)PTR_DAT_100cde70;
    }
    else {
      *param_1 = *(undefined4 *)PTR_DAT_100cddec;
    }
  }
  else {
    *param_1 = *(undefined4 *)PTR_DAT_100cde70;
  }
  return;
}


// ==== .cbpasstime__FP5VAddr @ 10096058 ====
// CyDecompAt: created, body 10096058-100960ef

void _cbpasstime__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  undefined *puVar1;
  
  puVar1 = PTR_DAT_100cdbb8;
  .debug::_DoTicks__11TGameViewerFlUc
            (*(undefined4 *)PTR_DAT_100cdbb8,
             (int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),0);
  .debug::_DoTicks__11TGameViewerFlUc(*(undefined4 *)puVar1,0,1);
  .debug::_DrawRoutine__11TGameViewerFs(*(undefined4 *)puVar1,1);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .GetItemHeight__21TScriptPickItemDrawerFv @ 10096118 ====
// CyDecompAt: created, body 10096118-10096167

undefined4 _GetItemHeight__21TScriptPickItemDrawerFv(int param_1)

{
  undefined4 uVar1;
  char *pcVar2;
  
  uVar1 = 0x14;
  for (pcVar2 = *(char **)(param_1 + 4); *pcVar2 != '\0'; pcVar2 = pcVar2 + 1) {
    if (*pcVar2 == '%') {
      if (pcVar2[1] == 'i') {
        uVar1 = 0x20;
      }
    }
  }
  return uVar1;
}


// ==== .DrawItem__21TScriptPickItemDrawerFRC4RectUc @ 100961a4 ====
// CyDecompAt: created, body 100961a4-10096757

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DrawItem__21TScriptPickItemDrawerFRC4RectUc(int param_1,short *param_2,char param_3)

{
  char *pcVar1;
  char cVar2;
  int iVar3;
  undefined *puVar4;
  undefined *puVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  uint uVar8;
  int iVar9;
  uint uVar10;
  int iVar11;
  short sVar12;
  undefined4 uVar13;
  short sVar14;
  char *pcVar15;
  char *pcVar16;
  uint uStack_f4;
  uint uStack_f0;
  undefined4 uStack_ec;
  uint uStack_e8;
  uint uStack_e4;
  undefined1 auStack_e0 [8];
  int iStack_d8;
  undefined4 uStack_d4;
  undefined4 uStack_d0;
  undefined4 uStack_cc;
  undefined4 uStack_c8;
  undefined4 uStack_c4;
  undefined4 uStack_c0;
  undefined4 uStack_bc;
  undefined4 uStack_b8;
  undefined4 uStack_b4;
  undefined4 uStack_b0;
  undefined4 uStack_ac;
  undefined2 uStack_a8;
  uint uStack_a4;
  undefined4 uStack_a0;
  char acStack_9c [92];
  
  puVar5 = PTR_DAT_100cdbf4;
  puVar4 = PTR_DAT_100cdb94;
  iVar3 = _DAT_100cdb90;
  pcVar15 = acStack_9c;
  acStack_9c[0] = '\0';
  uStack_a0 = *(undefined4 *)(param_1 + 4);
  pcVar16 = *(char **)(param_1 + 4);
  if (param_3 == '\0') {
    uVar6 = 0x45;
  }
  else {
    uVar6 = 0xcd;
  }
  uVar13 = 0;
  iVar11 = param_2[1] + 2;
  sVar12 = 0;
  do {
    do {
      do {
        while( true ) {
          if (*pcVar16 == '\0') {
            if (pcVar15 != acStack_9c) {
              uVar7 = .glue::TextWidth(acStack_9c,0,(int)pcVar15 - (int)acStack_9c);
              uVar13 = .debug::_Justify__12TTextContextFsss(iVar11,uVar7,uVar13);
              uVar8 = (uint)*(short *)(iVar3 + 0x30);
              uVar10 = (int)*param_2 + ((int)param_2[2] - (int)*(short *)(iVar3 + 0x32));
              .debug::_DrawTextOutlined__12TTextContextFssPcsll
                        (uVar13,(int)(short)((short)((int)uVar10 >> 1) +
                                            (ushort)((int)uVar10 < 0 && (uVar10 & 1) != 0)) +
                                ((int)uVar8 >> 1) + (uint)((int)uVar8 < 0 && (uVar8 & 1) != 0),
                         acStack_9c,(int)pcVar15 - (int)acStack_9c,uVar6,0x21);
            }
            return;
          }
          if (*pcVar16 == '|') break;
          if (*pcVar16 == '%') {
            pcVar1 = pcVar16 + 1;
            if (*pcVar1 == 'd') {
              iVar9 = (int)sVar12;
              sVar12 = sVar12 + 1;
              .debug::_At__7TInterpF5VAddrs(&uStack_e8,*(undefined4 *)(param_1 + 8),iVar9);
              iVar9 = FUN_100b6a80(pcVar15,PTR_DAT_100cee20,
                                   (int)(uStack_e8 << 4 | uStack_e8 >> 0x1c) >> 4);
              pcVar15 = pcVar15 + iVar9;
              pcVar16 = pcVar16 + 2;
            }
            else if (*pcVar1 == 's') {
              iVar9 = (int)sVar12;
              sVar12 = sVar12 + 1;
              .debug::_At__7TInterpF5VAddrs(&uStack_ec,*(undefined4 *)(param_1 + 8),iVar9);
              uVar7 = .debug::_VAddrToPtr__7TInterpF5VAddr(uStack_ec);
              iVar9 = FUN_100b6a80(pcVar15,_DAT_100cee78,uVar7);
              pcVar15 = pcVar15 + iVar9;
              pcVar16 = pcVar16 + 2;
            }
            else if (*pcVar1 == 'i') {
              iVar9 = (int)sVar12;
              sVar12 = sVar12 + 1;
              .debug::_At__7TInterpF5VAddrs(&uStack_f0,*(undefined4 *)(param_1 + 8),iVar9);
              sVar14 = 0;
              uStack_a4 = uStack_f0;
              if ((uStack_f0 & 0xf0000000) == 0) {
                sVar14 = (short)((int)(uStack_f0 << 4 | uStack_f0 >> 0x1c) >> 4);
                sVar14 = (sVar14 >> 10) + *(short *)(puVar5 + ((int)sVar14 & 0x3ffU) * 2);
              }
              if (sVar14 != 0) {
                uStack_d4 = uRam100d3de8;
                uStack_d0 = uRam100d3dec;
                uStack_cc = uRam100d3df0;
                uStack_c8 = uRam100d3df4;
                uStack_c4 = uRam100d3df8;
                uStack_c0 = uRam100d3dfc;
                uStack_bc = uRam100d3e00;
                uStack_b8 = uRam100d3e04;
                uStack_b4 = uRam100d3e08;
                uStack_b0 = uRam100d3e0c;
                uStack_ac = uRam100d3e10;
                uStack_a8 = uRam100d3e14;
                iStack_d8 = *(int *)PTR_DAT_100cdc64 + sVar14 * 0x400;
                .glue::SetRect(auStack_e0,0,0,0x20,0x20);
                uVar8 = (int)*param_2 + (int)param_2[2];
                .glue::OffsetRect(auStack_e0,iVar11,
                                  ((int)uVar8 >> 1) + (uint)((int)uVar8 < 0 && (uVar8 & 1) != 0) +
                                  -0x10);
                if ((short)uVar13 == 1) {
                  .glue::OffsetRect(auStack_e0,0xfffffff0,0);
                }
                if ((short)uVar13 == -1) {
                  .glue::OffsetRect(auStack_e0,0xffffffe0,0);
                }
                .glue::CopyBits(&iStack_d8,*(int *)(puVar4 + 0xca) + 2,(int)&uStack_d4 + 2,
                                auStack_e0,0x24,0);
                .glue::Move(0,0x24);
                iVar11 = iVar11 + 0x24;
              }
              pcVar16 = pcVar16 + 2;
            }
            else if (*pcVar1 == 'n') {
              iVar9 = (int)sVar12;
              sVar12 = sVar12 + 1;
              .debug::_At__7TInterpF5VAddrs(&uStack_f4,*(undefined4 *)(param_1 + 8),iVar9);
              iVar9 = 0;
              uStack_e4 = uStack_f4;
              if ((uStack_f4 & 0xf0000000) == 0) {
                sVar14 = (short)((int)(uStack_f4 << 4 | uStack_f4 >> 0x1c) >> 4);
                iVar9 = ((int)sVar14 >> 10) + (int)*(short *)(puVar5 + ((int)sVar14 & 0x3ffU) * 2);
              }
              .debug::_GetTileName__FsPcUcUc(iVar9,pcVar15,1,0);
              iVar9 = FUN_100b6ce8(pcVar15);
              pcVar15 = pcVar15 + iVar9;
              pcVar16 = pcVar16 + 2;
            }
            else if (*pcVar1 == 'p') {
              sVar12 = sVar12 + 1;
              pcVar16 = pcVar16 + 2;
            }
            else {
              sVar12 = sVar12 + 1;
              pcVar16 = pcVar16 + 2;
            }
          }
          else {
            cVar2 = *pcVar16;
            pcVar16 = pcVar16 + 1;
            *pcVar15 = cVar2;
            pcVar15 = pcVar15 + 1;
          }
        }
        if (pcVar15 != acStack_9c) {
          uVar7 = .glue::TextWidth(acStack_9c,0,(int)pcVar15 - (int)acStack_9c);
          uVar13 = .debug::_Justify__12TTextContextFsss(iVar11,uVar7,uVar13);
          uVar10 = (uint)*(short *)(iVar3 + 0x30);
          uVar8 = (int)*param_2 + ((int)param_2[2] - (int)*(short *)(iVar3 + 0x32));
          .debug::_DrawTextOutlined__12TTextContextFssPcsll
                    (uVar13,(int)(short)((short)((int)uVar8 >> 1) +
                                        (ushort)((int)uVar8 < 0 && (uVar8 & 1) != 0)) +
                            ((int)uVar10 >> 1) + (uint)((int)uVar10 < 0 && (uVar10 & 1) != 0),
                     acStack_9c,(int)pcVar15 - (int)acStack_9c,uVar6,0x21);
          pcVar15 = acStack_9c;
          iVar11 = (int)*(short *)(*(int *)(puVar4 + 0xca) + 0x32);
        }
        pcVar1 = pcVar16 + 1;
        uVar13 = 0;
        if (*pcVar1 == '.') {
          uVar13 = 1;
          pcVar1 = pcVar16 + 2;
        }
        else if (*pcVar1 == '-') {
          uVar13 = 0xffffffff;
          pcVar1 = pcVar16 + 2;
        }
        pcVar16 = pcVar1;
      } while (*pcVar16 < '0');
    } while ('9' < *pcVar16);
    sVar14 = 0;
    while( true ) {
      if (*pcVar16 < '0') break;
      if ('9' < *pcVar16) break;
      sVar14 = (short)*pcVar16 + sVar14 * 10 + -0x30;
      pcVar16 = pcVar16 + 1;
    }
    iVar11 = (int)sVar14 * ((int)param_2[3] - (int)param_2[1]) + 0x32;
    iVar11 = iVar11 / 100 + (iVar11 >> 0x1f);
    iVar11 = (int)param_2[1] + (iVar11 - (iVar11 >> 0x1f));
  } while( true );
}


// ==== .cbPickItem__FP5VAddr @ 10096798 ====
// CyDecompAt: created, body 10096798-10096bd7

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbPickItem__FP5VAddr(uint *param_1,int *param_2)

{
  undefined *puVar1;
  undefined4 *puVar2;
  int iVar3;
  undefined4 uVar4;
  short sVar7;
  int *piVar5;
  undefined4 *puVar6;
  short sVar8;
  undefined4 *puVar9;
  uint uVar10;
  undefined4 *puVar11;
  undefined **ppuStack_10c;
  undefined4 *puStack_108;
  undefined ***pppuStack_104;
  uint *puStack_e8;
  int iStack_e4;
  undefined **ppuStack_e0;
  undefined1 auStack_dc [8];
  undefined4 uStack_d4;
  undefined4 uStack_d0;
  uint *puStack_b4;
  uint *puStack_ac;
  uint *puStack_a4;
  undefined *puStack_a0;
  undefined4 uStack_9c;
  undefined **ppuStack_98;
  undefined4 uStack_94;
  undefined4 uStack_90;
  undefined4 uStack_8c;
  short sStack_88;
  uint uStack_84;
  uint uStack_80;
  undefined4 *puStack_7c;
  short sStack_78;
  undefined4 auStack_74 [10];
  undefined4 uStack_4c;
  undefined4 uStack_48;
  
  puVar1 = PTR_DAT_100cee18;
  if (*param_2 == *(int *)PTR_DAT_100cdbb0) {
    uStack_48 = 0;
  }
  else {
    uStack_48 = .debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  }
  if (param_2[1] == *(int *)PTR_DAT_100cdbb0) {
    uStack_4c = 0;
  }
  else {
    uStack_4c = .debug::_VAddrToPtr__7TInterpF5VAddr(param_2[1]);
  }
  sStack_78 = 0;
  for (sVar8 = 0; sVar7 = .debug::_Len__7TInterpF5VAddr(param_2[3]), sVar8 < sVar7;
      sVar8 = sVar8 + 1) {
    .debug::_At__7TInterpF5VAddrs(&uStack_8c,param_2[3],(int)sVar8);
    uVar4 = .debug::_VAddrToPtr__7TInterpF5VAddr(uStack_8c);
    iVar3 = (int)sStack_78;
    sStack_78 = sStack_78 + 1;
    auStack_74[iVar3] = uVar4;
  }
  auStack_74[sStack_78] = 0;
  if (*PTR_DAT_100cee1c == '\0') {
    FUN_100be3e4(puVar1,PTR_PTR_100ce01c,0,0xc,0x14);
    *PTR_DAT_100cee1c = 1;
  }
  puStack_e8 = &uStack_84;
  uStack_84 = 0;
  uStack_80 = 0;
  puStack_7c = (undefined4 *)0x0;
  puStack_b4 = puStack_e8;
  puStack_ac = puStack_e8;
  puStack_a4 = puStack_e8;
  for (sVar8 = 0;
      (sVar7 = .debug::_Len__7TInterpF5VAddr(param_2[2]), sVar8 < sVar7 && (sVar8 < 0x14));
      sVar8 = sVar8 + 1) {
    .debug::_At__7TInterpF5VAddrs(&uStack_9c,param_2[2],(int)sVar8);
    uStack_d0 = uStack_9c;
    ppuStack_98 = &PTR_PTR_100d76f4;
    uStack_94 = uStack_4c;
    uStack_90 = uStack_9c;
    *(undefined4 *)(puVar1 + sVar8 * 0xc + 4) = uStack_4c;
    puStack_a0 = puVar1 + sVar8 * 0xc;
    *(undefined4 *)(puVar1 + sVar8 * 0xc + 8) = uStack_9c;
    if (_DAT_100d760c < _DAT_100d7610) {
      piVar5 = (int *)&DAT_100d7610;
    }
    else {
      piVar5 = (int *)&DAT_100d760c;
    }
    iStack_e4 = *piVar5;
    if (iStack_e4 - 1U < uStack_80) {
      ppuStack_e0 = &PTR_PTR_100d3cb8;
      FUN_100c15b4(auStack_dc,PTR_s_vector_insert_length_error_100cee0c);
      ppuStack_e0 = &PTR_PTR_100d3ca8;
      pppuStack_104 = &ppuStack_e0;
      FUN_100bdef4(PTR_s__std_exception__std_logic_erro_100cee08,&ppuStack_e0,PTR_PTR_100cdb74);
    }
    puVar2 = puStack_7c;
    if (uStack_80 < uStack_84) {
      uStack_d4 = 0;
      puStack_7c[uStack_80] = puStack_a0;
      uVar10 = uStack_84;
    }
    else {
      if (uStack_84 == 0) {
        uVar10 = 1;
      }
      else {
        uVar10 = uStack_84 << 1;
      }
      puVar6 = (undefined4 *)FUN_100be7c8(uVar10 << 2);
      if (puVar6 == (undefined4 *)0x0) {
        ppuStack_10c = &PTR_PTR_100d3c68;
        FUN_100bdef4(PTR_s__std_exception__std_bad_alloc__100cee04,&ppuStack_10c,_DAT_100cdb6c);
      }
      if (uStack_80 != 0) {
        puVar9 = puVar6;
        for (puVar11 = puVar2; puVar11 != puVar2 + uStack_80; puVar11 = puVar11 + 1) {
          *puVar9 = *puVar11;
          puVar9 = puVar9 + 1;
        }
      }
      puVar6[uStack_80] = puStack_a0;
      puStack_108 = puVar6;
      puStack_7c = puVar6;
      if (puVar2 != (undefined4 *)0x0) {
        FUN_100be848(puVar2);
      }
    }
    uStack_84 = uVar10;
    uStack_80 = uStack_80 + 1;
  }
  sStack_88 = .debug::
              _PickItem__12TInteractionFPcRQ23std64vector<P15TPickItemDrawer,Q23std29allocator<P15TPickItemDrawer>>PPcs
                        (uStack_48,&uStack_84,auStack_74,(int)sStack_78);
  *param_1 = (int)sStack_88 & 0xfffffff;
  if (puStack_7c != (undefined4 *)0x0) {
    FUN_100be848(puStack_7c);
  }
  return;
}


// ==== .__dt__Q23std64vector<P15TPickItemDrawer,Q23std29allocator<P15TPickItemDrawer>>Fv @ 10096c00 ====
// CyDecompAt: created, body 10096c00-10096c8b

int ___dt__Q23std64vector<P15TPickItemDrawer,Q23std29allocator<P15TPickItemDrawer>>Fv
              (int param_1,short param_2)

{
  if (param_1 != 0) {
    if ((param_1 != 0) && (*(int *)(param_1 + 8) != 0)) {
      FUN_100be848(*(undefined4 *)(param_1 + 8));
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__ct__21TScriptPickItemDrawerFv @ 10096cf0 ====
// CyDecompAt: created, body 10096cf0-10096d1f

void ___ct__21TScriptPickItemDrawerFv(undefined4 *param_1)

{
  undefined4 uVar1;
  
  uVar1 = *(undefined4 *)PTR_DAT_100cdbb0;
  *param_1 = &PTR_PTR_100d76d0;
  *param_1 = &PTR_PTR_100d76f4;
  param_1[1] = 0;
  param_1[2] = uVar1;
  return;
}


// ==== .cbAddKeyword__FP5VAddr @ 10096d54 ====
// CyDecompAt: created, body 10096d54-10096dbf

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbAddKeyword__FP5VAddr(undefined4 *param_1,undefined4 *param_2)

{
  undefined4 uVar1;
  
  if (*_DAT_100cdcc8 != 0) {
    uVar1 = .debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
    .debug::_AddAnswer__13TConversationFPc(*_DAT_100cdcc8,uVar1);
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbAddAbility__FP5VAddr @ 10096dec ====
// CyDecompAt: created, body 10096dec-10096e53

void _cbAddAbility__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  .debug::_AddAbility__8TSpellFXFss
            ((int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
             (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4));
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbRemoveAbility__FP5VAddr @ 10096e80 ====
// CyDecompAt: created, body 10096e80-10096ee7

void _cbRemoveAbility__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  .debug::_RemoveAbility__8TSpellFXFss
            ((int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
             (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4));
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbTempAbility__FP5VAddr @ 10096f14 ====
// CyDecompAt: created, body 10096f14-10096f8b

void _cbTempAbility__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  .debug::_TempAbility__8TSpellFXFssUs
            ((int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
             (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4),
             (int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4 & 0xffff);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbHasAbility__FP5VAddr @ 10096fb8 ====
// CyDecompAt: created, body 10096fb8-10097053

void _cbHasAbility__FP5VAddr(uint *param_1,uint *param_2)

{
  ushort uVar1;
  
  uVar1 = .debug::_HasAbility__8TSpellFXFss
                    ((int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
                     (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4));
  if (uVar1 < 0xf000) {
    if (uVar1 == 0) {
      *param_1 = *(uint *)PTR_DAT_100cdbb0;
    }
    else {
      *param_1 = (uint)uVar1;
    }
  }
  else {
    *param_1 = *(uint *)PTR_DAT_100cddec;
  }
  return;
}


// ==== .cbAllProps__FP5VAddr @ 10097080 ====
// CyDecompAt: created, body 10097080-100971b7

void _cbAllProps__FP5VAddr(uint *param_1,undefined4 *param_2)

{
  undefined *puVar1;
  int iVar2;
  uint *puVar3;
  
  puVar3 = (uint *).debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  puVar1 = PTR_DAT_100cdc3c;
  iVar2 = param_2[1];
  if (iVar2 == 1) {
    if ((int)*puVar3 < (int)puVar3[1]) {
      *param_1 = *(uint *)PTR_DAT_100cde70;
    }
    else {
      *param_1 = *(uint *)PTR_DAT_100cddec;
    }
  }
  else {
    if (iVar2 < 1) {
      if (-1 < iVar2) {
        *puVar3 = 0;
        puVar3[1] = (int)*(short *)puVar1 & 0xfffffff;
        *param_1 = 0x40000100;
        return;
      }
    }
    else if (iVar2 < 3) {
      *puVar3 = *puVar3 + 1;
      *param_1 = (int)(*puVar3 << 4 | *puVar3 >> 0x1c) >> 4 & 0xffffU | 0x40000000;
      return;
    }
    *param_1 = *(uint *)PTR_DAT_100cdbb0;
  }
  return;
}


// ==== .cbInventory__FP5VAddr @ 100971e0 ====
// CyDecompAt: created, body 100971e0-10097393

void _cbInventory__FP5VAddr(uint *param_1,undefined4 *param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  int iVar3;
  uint *puVar4;
  short sVar5;
  
  puVar2 = PTR_DAT_100cdc3c;
  puVar1 = PTR_DAT_100cdbb0;
  puVar4 = (uint *).debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  iVar3 = param_2[1];
  if (iVar3 == 1) {
    if ((int)*(short *)puVar2 <= (int)*puVar4) {
      *param_1 = *(uint *)PTR_DAT_100cddec;
      return;
    }
    *param_1 = *(uint *)PTR_DAT_100cde70;
    return;
  }
  if (iVar3 < 1) {
    if (-1 < iVar3) {
      *puVar4 = 0xff;
      puVar4[1] = param_2[2];
      if ((*(ushort *)(param_2 + 2) & 0xfff) == 0x40) {
        iVar3 = .debug::_GetCharacter__14TActiveMonsterFP9CharEntry
                          (PTR_DAT_100cdbf0 + (param_2[2] & 0xffff) * 0x20);
        if (iVar3 == 0) {
          *puVar4 = (int)*(short *)puVar2;
          *param_1 = *(uint *)puVar1;
          return;
        }
        *(undefined2 *)((int)puVar4 + 6) = *(undefined2 *)(iVar3 + 8);
      }
LAB_100972d4:
      *puVar4 = *puVar4 + 1;
      while (((int)*puVar4 < (int)*(short *)puVar2 &&
             (sVar5 = .debug::_GetPropParent__Fs((int)(short)*puVar4),
             (int)sVar5 != (puVar4[1] & 0xffff)))) {
        *puVar4 = *puVar4 + 1;
      }
      if ((int)*(short *)puVar2 <= (int)*puVar4) {
        *param_1 = *(uint *)puVar1;
        return;
      }
      *param_1 = (int)(*puVar4 << 4 | *puVar4 >> 0x1c) >> 4 & 0xffffU | 0x40000000;
      return;
    }
  }
  else if (iVar3 < 3) goto LAB_100972d4;
  *param_1 = *(uint *)puVar1;
  return;
}


// ==== .cbWithin__FP5VAddr @ 100973bc ====
// CyDecompAt: created, body 100973bc-1009758f

void _cbWithin__FP5VAddr(uint *param_1,undefined4 *param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  int iVar3;
  uint *puVar4;
  undefined4 uVar5;
  
  puVar2 = PTR_DAT_100cdc3c;
  puVar1 = PTR_DAT_100cdbb0;
  puVar4 = (uint *).debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  iVar3 = param_2[1];
  if (iVar3 == 1) {
    if ((int)*(short *)puVar2 <= (int)*puVar4) {
      *param_1 = *(uint *)PTR_DAT_100cddec;
      return;
    }
    *param_1 = *(uint *)PTR_DAT_100cde70;
    return;
  }
  if (iVar3 < 1) {
    if (-1 < iVar3) {
      *puVar4 = 0xff;
      puVar4[1] = param_2[2];
      if ((*(ushort *)(param_2 + 2) & 0xfff) == 0x40) {
        iVar3 = .debug::_GetCharacter__14TActiveMonsterFP9CharEntry
                          (PTR_DAT_100cdbf0 + (param_2[2] & 0xffff) * 0x20);
        if (iVar3 == 0) {
          *puVar4 = (int)*(short *)puVar2;
          *param_1 = *(uint *)puVar1;
          return;
        }
        *(undefined2 *)((int)puVar4 + 6) = *(undefined2 *)(iVar3 + 8);
      }
LAB_100974b0:
      *puVar4 = *puVar4 + 1;
      while ((int)*puVar4 < (int)*(short *)puVar2) {
        for (uVar5 = .debug::_GetPropParent__Fs((int)(short)*puVar4); (short)uVar5 != 0;
            uVar5 = .debug::_GetPropParent__Fs(uVar5)) {
          if ((int)(short)uVar5 == (puVar4[1] & 0xffff)) goto LAB_10097520;
        }
        *puVar4 = *puVar4 + 1;
      }
LAB_10097520:
      if ((int)*(short *)puVar2 <= (int)*puVar4) {
        *param_1 = *(uint *)puVar1;
        return;
      }
      *param_1 = (int)(*puVar4 << 4 | *puVar4 >> 0x1c) >> 4 & 0xffffU | 0x40000000;
      return;
    }
  }
  else if (iVar3 < 3) goto LAB_100974b0;
  *param_1 = *(uint *)puVar1;
  return;
}


// ==== .cbInParty__FP5VAddr @ 100975b8 ====
// CyDecompAt: created, body 100975b8-100976d3

void _cbInParty__FP5VAddr(uint *param_1,undefined4 *param_2)

{
  undefined *puVar1;
  int iVar2;
  int *piVar3;
  uint uStack_28;
  
  piVar3 = (int *).debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  iVar2 = param_2[1];
  if (iVar2 == 1) {
    if ((int)*(short *)PTR_DAT_100cdb9c <= *piVar3) {
      *param_1 = *(uint *)PTR_DAT_100cddec;
      return;
    }
    *param_1 = *(uint *)PTR_DAT_100cde70;
    return;
  }
  if (iVar2 < 1) {
    if (-1 < iVar2) {
      *piVar3 = -1;
      piVar3[1] = param_2[2];
LAB_10097618:
      puVar1 = PTR_DAT_100cdb9c;
      *piVar3 = *piVar3 + 1;
      if ((int)*(short *)puVar1 <= *piVar3) {
        *param_1 = *(uint *)PTR_DAT_100cdbb0;
        return;
      }
      uStack_28 = *(ushort *)(PTR_DAT_100cdbe4 + *piVar3 * 2) | 0x40400000;
      *param_1 = uStack_28;
      return;
    }
  }
  else if (iVar2 < 3) goto LAB_10097618;
  *param_1 = *(uint *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbPropsAt__FP5VAddr @ 100976fc ====
// CyDecompAt: created, body 100976fc-100978c7

void _cbPropsAt__FP5VAddr(uint *param_1,undefined4 *param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  int iVar3;
  uint *puVar4;
  byte *pbVar5;
  
  puVar2 = PTR_DAT_100cdc44;
  puVar1 = PTR_DAT_100cdc3c;
  puVar4 = (uint *).debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  iVar3 = param_2[1];
  if (iVar3 == 1) {
    if ((int)*(short *)puVar1 <= (int)*puVar4) {
      *param_1 = *(uint *)PTR_DAT_100cddec;
      return;
    }
    *param_1 = *(uint *)PTR_DAT_100cde70;
    return;
  }
  if (iVar3 < 1) {
    if (-1 < iVar3) {
      *puVar4 = 0;
      puVar4[1] = ((int)(param_2[2] << 4 | (uint)param_2[2] >> 0x1c) >> 4) << 0x10 |
                  (int)(param_2[3] << 4 | (uint)param_2[3] >> 0x1c) >> 4;
LAB_100977b8:
      *puVar4 = *puVar4 + 1;
      while (((int)*puVar4 < (int)*(short *)puVar1 &&
             (((pbVar5 = (byte *)(*(int *)puVar2 + *puVar4 * 0x10), (*pbVar5 & 0x1a) != 0 ||
               ((short)(puVar4[1] >> 0x10) !=
                (short)((short)((uint)*(undefined4 *)pbVar5 >> 8) >> 4))) ||
              ((short)puVar4[1] !=
               (short)((ushort)((uint)((int)*(short *)(pbVar5 + 2) << 0x14) >> 0x10) |
                      (ushort)(*(short *)(pbVar5 + 2) >> 0xf) >> 0xc) >> 4))))) {
        *puVar4 = *puVar4 + 1;
      }
      if ((int)*(short *)puVar1 <= (int)*puVar4) {
        *param_1 = *(uint *)PTR_DAT_100cdbb0;
        return;
      }
      *param_1 = (int)(*puVar4 << 4 | *puVar4 >> 0x1c) >> 4 & 0xffffU | 0x40000000;
      return;
    }
  }
  else if (iVar3 < 3) goto LAB_100977b8;
  *param_1 = *(uint *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbInRange__FP5VAddr @ 100978f0 ====
// CyDecompAt: created, body 100978f0-10097b2f

void _cbInRange__FP5VAddr(uint *param_1,undefined4 *param_2)

{
  ushort uVar1;
  ushort uVar2;
  undefined *puVar3;
  undefined *puVar4;
  int iVar5;
  uint *puVar6;
  short sVar7;
  byte *pbVar8;
  
  puVar4 = PTR_DAT_100cdc44;
  puVar3 = PTR_DAT_100cdc3c;
  puVar6 = (uint *).debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  iVar5 = param_2[1];
  if (iVar5 == 1) {
    if ((int)*(short *)puVar3 <= (int)*puVar6) {
      *param_1 = *(uint *)PTR_DAT_100cddec;
      return;
    }
    *param_1 = *(uint *)PTR_DAT_100cde70;
    return;
  }
  if (iVar5 < 1) {
    if (-1 < iVar5) {
      *puVar6 = 0;
      puVar6[1] = (int)(param_2[3] << 4 | (uint)param_2[3] >> 0x1c) >> 4 |
                  ((int)(param_2[4] << 4 | (uint)param_2[4] >> 0x1c) >> 4) << 0x18 |
                  ((int)(param_2[2] << 4 | (uint)param_2[2] >> 0x1c) >> 4) << 0xc;
LAB_100979c0:
      *puVar6 = *puVar6 + 1;
      sVar7 = (short)(char)(puVar6[1] >> 0x18);
      uVar1 = (ushort)(puVar6[1] >> 0xc) & 0xfff;
      uVar2 = (ushort)puVar6[1] & 0xfff;
      while (((int)*puVar6 < (int)*(short *)puVar3 &&
             (((pbVar8 = (byte *)(*(int *)puVar4 + *puVar6 * 0x10), (*pbVar8 & 0x1a) != 0 &&
               (*pbVar8 != 2)) ||
              ((int)sVar7 * (int)sVar7 <
               ((int)(short)((short)((uint)*(undefined4 *)pbVar8 >> 8) >> 4) - (int)(short)uVar1) *
               ((int)(short)((short)((uint)*(undefined4 *)pbVar8 >> 8) >> 4) - (int)(short)uVar1) +
               ((int)((short)((ushort)((uint)((int)*(short *)(pbVar8 + 2) << 0x14) >> 0x10) |
                             (ushort)(*(short *)(pbVar8 + 2) >> 0xf) >> 0xc) >> 4) -
               (int)(short)uVar2) *
               ((int)((short)((ushort)((uint)((int)*(short *)(pbVar8 + 2) << 0x14) >> 0x10) |
                             (ushort)(*(short *)(pbVar8 + 2) >> 0xf) >> 0xc) >> 4) -
               (int)(short)uVar2)))))) {
        *puVar6 = *puVar6 + 1;
      }
      if ((int)*(short *)puVar3 <= (int)*puVar6) {
        *param_1 = *(uint *)PTR_DAT_100cdbb0;
        return;
      }
      *param_1 = (int)(*puVar6 << 4 | *puVar6 >> 0x1c) >> 4 & 0xffffU | 0x40000000;
      return;
    }
  }
  else if (iVar5 < 3) goto LAB_100979c0;
  *param_1 = *(uint *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbPropsOf__FP5VAddr @ 10097b58 ====
// CyDecompAt: created, body 10097b58-10097cbf

void _cbPropsOf__FP5VAddr(uint *param_1,undefined4 *param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  int iVar3;
  uint *puVar4;
  
  puVar2 = PTR_DAT_100cdc44;
  puVar1 = PTR_DAT_100cdc3c;
  puVar4 = (uint *).debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  iVar3 = param_2[1];
  if (iVar3 == 1) {
    if ((int)*(short *)puVar1 <= (int)*puVar4) {
      *param_1 = *(uint *)PTR_DAT_100cddec;
      return;
    }
    *param_1 = *(uint *)PTR_DAT_100cde70;
    return;
  }
  if (iVar3 < 1) {
    if (-1 < iVar3) {
      *puVar4 = 0xff;
      puVar4[1] = param_2[2];
LAB_10097bf8:
      *puVar4 = *puVar4 + 1;
      while (((int)*puVar4 < (int)*(short *)puVar1 &&
             ((*(ushort *)(*(int *)puVar2 + *puVar4 * 0x10 + 4) & 0x3ff) != puVar4[1]))) {
        *puVar4 = *puVar4 + 1;
      }
      if ((int)*(short *)puVar1 <= (int)*puVar4) {
        *param_1 = *(uint *)PTR_DAT_100cdbb0;
        return;
      }
      *param_1 = (int)(*puVar4 << 4 | *puVar4 >> 0x1c) >> 4 & 0xffffU | 0x40000000;
      return;
    }
  }
  else if (iVar3 < 3) goto LAB_10097bf8;
  *param_1 = *(uint *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbWorn__FP5VAddr @ 10097ce8 ====
// CyDecompAt: created, body 10097ce8-10097eb7

void _cbWorn__FP5VAddr(uint *param_1,undefined4 *param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined *puVar3;
  int iVar4;
  uint *puVar5;
  short sVar6;
  
  puVar3 = PTR_DAT_100cdc44;
  puVar2 = PTR_DAT_100cdc3c;
  puVar1 = PTR_DAT_100cdbb0;
  puVar5 = (uint *).debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  iVar4 = param_2[1];
  if (iVar4 == 1) {
    if ((int)*(short *)puVar2 <= (int)*puVar5) {
      *param_1 = *(uint *)PTR_DAT_100cddec;
      return;
    }
    *param_1 = *(uint *)PTR_DAT_100cde70;
    return;
  }
  if (iVar4 < 1) {
    if (-1 < iVar4) {
      *puVar5 = 0xff;
      puVar5[1] = param_2[2];
      if ((*(ushort *)(param_2 + 2) & 0xfff) == 0x40) {
        iVar4 = .debug::_GetCharacter__14TActiveMonsterFP9CharEntry
                          (PTR_DAT_100cdbf0 + (param_2[2] & 0xffff) * 0x20);
        if (iVar4 == 0) {
          *puVar5 = (int)*(short *)puVar2;
          *param_1 = *(uint *)puVar1;
          return;
        }
        *(undefined2 *)((int)puVar5 + 6) = *(undefined2 *)(iVar4 + 8);
      }
LAB_10097de0:
      *puVar5 = *puVar5 + 1;
      while (((int)*puVar5 < (int)*(short *)puVar2 &&
             ((sVar6 = .debug::_GetPropParent__Fs((int)(short)*puVar5),
              (int)sVar6 != (puVar5[1] & 0xffff) ||
              (*(char *)(*(int *)puVar3 + *puVar5 * 0x10) != '\x18'))))) {
        *puVar5 = *puVar5 + 1;
      }
      if ((int)*(short *)puVar2 <= (int)*puVar5) {
        *param_1 = *(uint *)puVar1;
        return;
      }
      *param_1 = (int)(*puVar5 << 4 | *puVar5 >> 0x1c) >> 4 & 0xffffU | 0x40000000;
      return;
    }
  }
  else if (iVar4 < 3) goto LAB_10097de0;
  *param_1 = *(uint *)puVar1;
  return;
}


// ==== .cbAreaOfEffect__FP5VAddr @ 10097edc ====
// CyDecompAt: created, body 10097edc-10097ffb

void _cbAreaOfEffect__FP5VAddr(uint *param_1,undefined4 *param_2)

{
  undefined *puVar1;
  int iVar2;
  uint *puVar3;
  uint uStack_28;
  
  puVar1 = PTR_DAT_100cee00;
  puVar3 = (uint *).debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  iVar2 = param_2[1];
  if (iVar2 == 1) {
    if (0x1ff < (int)*puVar3) {
      *param_1 = *(uint *)PTR_DAT_100cddec;
      return;
    }
    *param_1 = *(uint *)PTR_DAT_100cde70;
    return;
  }
  if (iVar2 < 1) {
    if (-1 < iVar2) {
      *puVar3 = 0xffffffff;
LAB_10097f38:
      *puVar3 = *puVar3 + 1;
      while( true ) {
        if (0x1ff < (int)*puVar3) {
          *param_1 = *(uint *)PTR_DAT_100cdbb0;
          return;
        }
        if (puVar1[*puVar3] != '\0') break;
        *puVar3 = *puVar3 + 1;
      }
      uStack_28 = *puVar3 & 0xffff | 0x40400000;
      *param_1 = uStack_28;
      return;
    }
  }
  else if (iVar2 < 3) goto LAB_10097f38;
  *param_1 = *(uint *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbEnemies__FP5VAddr @ 10098028 ====
// CyDecompAt: created, body 10098028-100981db

void _cbEnemies__FP5VAddr(uint *param_1,undefined4 *param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  int iVar3;
  uint *puVar4;
  int iVar5;
  uint uStack_38;
  
  puVar2 = PTR_DAT_100cdbf0;
  puVar1 = PTR_DAT_100cdbb0;
  puVar4 = (uint *).debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  iVar3 = param_2[1];
  if (iVar3 == 1) {
    iVar3 = .debug::_GetCharacter__14TActiveMonsterFP9CharEntry
                      (puVar2 + ((int)(puVar4[1] << 4 | puVar4[1] >> 0x1c) >> 4) * 0x20);
    if (iVar3 == 0) {
      *param_1 = *(uint *)PTR_DAT_100cddec;
      return;
    }
    if (0x1ff < (int)*puVar4) {
      *param_1 = *(uint *)PTR_DAT_100cddec;
      return;
    }
    *param_1 = *(uint *)PTR_DAT_100cde70;
    return;
  }
  if (iVar3 < 1) {
    if (-1 < iVar3) {
      *puVar4 = 0;
      puVar4[1] = param_2[2];
LAB_10098090:
      iVar3 = .debug::_GetCharacter__14TActiveMonsterFP9CharEntry
                        (puVar2 + ((int)(puVar4[1] << 4 | puVar4[1] >> 0x1c) >> 4) * 0x20);
      if (iVar3 == 0) {
        *param_1 = *(uint *)puVar1;
        return;
      }
      *puVar4 = *puVar4 + 1;
      while( true ) {
        if (0x1ff < (int)*puVar4) {
          *param_1 = *(uint *)puVar1;
          return;
        }
        iVar5 = .debug::_GetCharacter__14TActiveMonsterFP9CharEntry
                          (puVar2 + ((int)(*puVar4 << 4 | *puVar4 >> 0x1c) >> 4) * 0x20);
        if ((iVar5 != 0) &&
           (iVar5 = .debug::_GetEnemyStatus__14TActiveMonsterFP14TActiveMonster(iVar3,iVar5),
           iVar5 == 0)) break;
        *puVar4 = *puVar4 + 1;
      }
      uStack_38 = *puVar4 & 0xffff | 0x40400000;
      *param_1 = uStack_38;
      return;
    }
  }
  else if (iVar3 < 3) goto LAB_10098090;
  *param_1 = *(uint *)puVar1;
  return;
}


// ==== .cbMonsterParts__FP5VAddr @ 10098204 ====
// CyDecompAt: created, body 10098204-100983eb

void _cbMonsterParts__FP5VAddr(uint *param_1,undefined4 *param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  int iVar3;
  uint *puVar4;
  uint *puVar5;
  
  puVar2 = PTR_DAT_100cdc3c;
  puVar1 = PTR_DAT_100cdbb0;
  puVar4 = (uint *).debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  iVar3 = param_2[1];
  if (iVar3 == 1) {
    if ((int)*(short *)puVar2 <= (int)*puVar4) {
      *param_1 = *(uint *)PTR_DAT_100cddec;
      return;
    }
    *param_1 = *(uint *)PTR_DAT_100cde70;
    return;
  }
  if (iVar3 < 1) {
    if (-1 < iVar3) {
      puVar5 = (uint *)0x0;
      *puVar4 = 0;
      if (((*(ushort *)(param_2 + 2) & 0xfff) == 0) || ((param_2[2] & 0xf0000000) == 0)) {
        puVar5 = (uint *).debug::_GetCharacter__14TActiveMonsterFs((int)(short)param_2[2]);
      }
      else if ((*(ushort *)(param_2 + 2) & 0xfff) == 0x40) {
        puVar5 = (uint *).debug::_GetCharacter__14TActiveMonsterFP9CharEntry
                                   (PTR_DAT_100cdbf0 + (param_2[2] & 0xffff) * 0x20);
      }
      if (puVar5 == (uint *)0x0) {
        *puVar4 = (int)*(short *)puVar2;
        *param_1 = *(uint *)puVar1;
        return;
      }
      puVar4[1] = *puVar5;
LAB_10098328:
      *puVar4 = *puVar4 + 1;
      while (((int)*puVar4 < (int)*(short *)puVar2 &&
             ((puVar5 = (uint *).debug::_GetCharacter__14TActiveMonsterFs((int)(short)*puVar4),
              puVar5 == (uint *)0x0 || (*puVar5 != puVar4[1]))))) {
        *puVar4 = *puVar4 + 1;
      }
      if ((int)*(short *)puVar2 <= (int)*puVar4) {
        *param_1 = *(uint *)puVar1;
        return;
      }
      *param_1 = (int)(*puVar4 << 4 | *puVar4 >> 0x1c) >> 4 & 0xffffU | 0x40000000;
      return;
    }
  }
  else if (iVar3 < 3) goto LAB_10098328;
  *param_1 = *(uint *)puVar1;
  return;
}


// ==== .cbSendSignal__FP5VAddr @ 10098418 ====
// CyDecompAt: created, body 10098418-10098473

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbSendSignal__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  .debug::_SendSignal__8TGameSysFs
            (*_DAT_100cdcd0,(int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4));
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbShortName__FP5VAddr @ 100984a0 ====
// CyDecompAt: created, body 100984a0-100984f3

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbShortName__FP5VAddr(undefined4 *param_1,undefined4 *param_2)

{
  .debug::_ShortName__8TGameSysFs(*_DAT_100cdcd0,(int)(short)*param_2);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbPlayNote__FP5VAddr @ 1009851c ====
// CyDecompAt: created, body 1009851c-10098597

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbPlayNote__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  .debug::_PlayNote__6TAudioFsss
            (_DAT_100cdd24,(int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
             (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4),
             (int)(short)((int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4));
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbPlaySound__FP5VAddr @ 100985c0 ====
// CyDecompAt: created, body 100985c0-10098723

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbPlaySound__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  uint uVar1;
  undefined4 uVar2;
  uint uVar3;
  int iVar4;
  short sVar5;
  int iVar6;
  short sVar7;
  int iVar8;
  
  if ((*param_2 & 0xf0000000) != 0) goto LAB_10098704;
  uVar2 = 0;
  iVar8 = *(int *)PTR_DAT_100cdbb8;
  iVar6 = ((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4) -
          (int)(short)((ushort)(*(uint *)(PTR_DAT_100cdbf0 + *(short *)PTR_DAT_100cdbec * 0x20) >>
                               0xc) & 0xfff);
  sVar7 = (short)iVar6;
  iVar4 = ((int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4) -
          (int)(short)((ushort)*(undefined4 *)(PTR_DAT_100cdbf0 + *(short *)PTR_DAT_100cdbec * 0x20)
                      & 0xfff);
  if (((int)sVar7 < -(int)*(short *)(iVar8 + 2)) || (*(short *)(iVar8 + 2) < sVar7)) {
LAB_100986f8:
    uVar2 = 1;
  }
  else {
    sVar5 = (short)iVar4;
    if ((int)sVar5 < -(int)*(short *)(iVar8 + 2)) goto LAB_100986f8;
    if (*(short *)(iVar8 + 2) < sVar5) goto LAB_100986f8;
    uVar3 = (uint)*(short *)(iVar8 + 4);
    uVar1 = (uint)*(short *)(iVar8 + 4);
    if ((*(byte *)((int)sVar7 +
                  ((int)uVar3 >> 1) + (uint)((int)uVar3 < 0 && (uVar3 & 1) != 0) +
                  (int)*(short *)(iVar8 + 4) *
                  ((int)sVar5 + ((int)uVar1 >> 1) + (uint)((int)uVar1 < 0 && (uVar1 & 1) != 0)) +
                  iVar8 + 0xc0c8) & 3) == 0) goto LAB_100986f8;
  }
  .debug::_PlaySound__6TAudioFUsssUcUc
            (_DAT_100cdd24,(int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4 & 0xffff,iVar6,iVar4,0,uVar2
            );
LAB_10098704:
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbPlaySoundSync__FP5VAddr @ 1009874c ====
// CyDecompAt: created, body 1009874c-100988af

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbPlaySoundSync__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  uint uVar1;
  undefined4 uVar2;
  uint uVar3;
  int iVar4;
  short sVar5;
  int iVar6;
  short sVar7;
  int iVar8;
  
  if ((*param_2 & 0xf0000000) != 0) goto LAB_10098890;
  uVar2 = 0;
  iVar8 = *(int *)PTR_DAT_100cdbb8;
  iVar6 = ((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4) -
          (int)(short)((ushort)(*(uint *)(PTR_DAT_100cdbf0 + *(short *)PTR_DAT_100cdbec * 0x20) >>
                               0xc) & 0xfff);
  sVar7 = (short)iVar6;
  iVar4 = ((int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4) -
          (int)(short)((ushort)*(undefined4 *)(PTR_DAT_100cdbf0 + *(short *)PTR_DAT_100cdbec * 0x20)
                      & 0xfff);
  if (((int)sVar7 < -(int)*(short *)(iVar8 + 2)) || (*(short *)(iVar8 + 2) < sVar7)) {
LAB_10098884:
    uVar2 = 1;
  }
  else {
    sVar5 = (short)iVar4;
    if ((int)sVar5 < -(int)*(short *)(iVar8 + 2)) goto LAB_10098884;
    if (*(short *)(iVar8 + 2) < sVar5) goto LAB_10098884;
    uVar3 = (uint)*(short *)(iVar8 + 4);
    uVar1 = (uint)*(short *)(iVar8 + 4);
    if ((*(byte *)((int)sVar7 +
                  ((int)uVar3 >> 1) + (uint)((int)uVar3 < 0 && (uVar3 & 1) != 0) +
                  (int)*(short *)(iVar8 + 4) *
                  ((int)sVar5 + ((int)uVar1 >> 1) + (uint)((int)uVar1 < 0 && (uVar1 & 1) != 0)) +
                  iVar8 + 0xc0c8) & 3) == 0) goto LAB_10098884;
  }
  .debug::_PlaySound__6TAudioFUsssUcUc
            (_DAT_100cdd24,(int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4 & 0xffff,iVar6,iVar4,1,uVar2
            );
LAB_10098890:
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbPlayMusic__FP5VAddr @ 100988dc ====
// CyDecompAt: created, body 100988dc-1009896b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbPlayMusic__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  undefined *puVar1;
  
  puVar1 = PTR_DAT_100cdbb0;
  if (*param_2 == *(uint *)PTR_DAT_100cdbb0) {
    .debug::_PlayMusic__6TAudioFsUc(_DAT_100cdd24,0xffffffff,1);
  }
  else {
    .debug::_PlayMusic__6TAudioFsUc
              (_DAT_100cdd24,(int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),1);
  }
  *param_1 = *(undefined4 *)puVar1;
  return;
}


// ==== .cbPlayAmbientMusic__FP5VAddr @ 10098994 ====
// CyDecompAt: created, body 10098994-10098a23

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbPlayAmbientMusic__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  undefined *puVar1;
  
  puVar1 = PTR_DAT_100cdbb0;
  if (*param_2 == *(uint *)PTR_DAT_100cdbb0) {
    .debug::_PlayMusic__6TAudioFsUc(_DAT_100cdd24,0xffffffff,0);
  }
  else {
    .debug::_PlayMusic__6TAudioFsUc
              (_DAT_100cdd24,(int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),0);
  }
  *param_1 = *(undefined4 *)puVar1;
  return;
}


// ==== .cbPlayAmbientSound__FP5VAddr @ 10098a54 ====
// CyDecompAt: created, body 10098a54-10098bb3

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbPlayAmbientSound__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  bool bVar1;
  uint uVar2;
  uint uVar3;
  int iVar4;
  short sVar5;
  int iVar6;
  short sVar7;
  int iVar8;
  
  bVar1 = false;
  iVar8 = *(int *)PTR_DAT_100cdbb8;
  iVar6 = ((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4) -
          (int)(short)((ushort)(*(uint *)(PTR_DAT_100cdbf0 + *(short *)PTR_DAT_100cdbec * 0x20) >>
                               0xc) & 0xfff);
  sVar7 = (short)iVar6;
  iVar4 = ((int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4) -
          (int)(short)((ushort)*(undefined4 *)(PTR_DAT_100cdbf0 + *(short *)PTR_DAT_100cdbec * 0x20)
                      & 0xfff);
  if (-(int)*(short *)(iVar8 + 2) <= (int)sVar7) {
    if (sVar7 <= *(short *)(iVar8 + 2)) {
      sVar5 = (short)iVar4;
      if (-(int)*(short *)(iVar8 + 2) <= (int)sVar5) {
        if (sVar5 <= *(short *)(iVar8 + 2)) {
          uVar3 = (uint)*(short *)(iVar8 + 4);
          uVar2 = (uint)*(short *)(iVar8 + 4);
          if ((*(byte *)((int)sVar7 +
                        ((int)uVar3 >> 1) + (uint)((int)uVar3 < 0 && (uVar3 & 1) != 0) +
                        (int)*(short *)(iVar8 + 4) *
                        ((int)sVar5 + ((int)uVar2 >> 1) + (uint)((int)uVar2 < 0 && (uVar2 & 1) != 0)
                        ) + iVar8 + 0xc0c8) & 3) != 0) {
            bVar1 = true;
          }
        }
      }
    }
  }
  if (bVar1) {
    .debug::_PlayAmbientSound__6TAudioFUsssUc
              (_DAT_100cdd24,(int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4 & 0xffff,iVar6,iVar4,0);
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbSetAmbientLight__FP5VAddr @ 10098be4 ====
// CyDecompAt: created, body 10098be4-10098c6f

void _cbSetAmbientLight__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  undefined *puVar1;
  
  puVar1 = PTR_DAT_100cdbb8;
  if (((*param_2 & 0xf0000000) == 0) &&
     (*(short *)PTR_DAT_100cdea4 = (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
     *(int *)puVar1 != 0)) {
    .debug::_DoTicks__11TGameViewerFlUc(*(undefined4 *)PTR_DAT_100cdbb8,0,0);
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbSetZonePic__FP5VAddr @ 10098ca0 ====
// CyDecompAt: created, body 10098ca0-10098d4b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbSetZonePic__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  bool bVar1;
  short sVar2;
  
  if ((*param_2 & 0xf0000000) == 0) {
    sVar2 = (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
    bVar1 = -1 < sVar2;
    if (!bVar1) {
      sVar2 = -sVar2;
    }
    *(short *)PTR_DAT_100cddf0 = sVar2;
    .debug::_ChangeOutdoor__13TStatusWindowFUcs
              (*(undefined4 *)PTR_DAT_100cdb98,bVar1,(int)(short)(_DAT_100d3e18 >> 0xc));
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbSetZoneName__FP5VAddr @ 10098d78 ====
// CyDecompAt: created, body 10098d78-10098e33

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbSetZoneName__FP5VAddr(undefined4 *param_1,undefined4 *param_2)

{
  int *piVar1;
  int iVar2;
  undefined1 uStack_118;
  undefined1 auStack_117 [267];
  
  piVar1 = _DAT_100cdcdc;
  iVar2 = .debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
  if (iVar2 != 0) {
    uStack_118 = FUN_100b6ce8(iVar2);
    FUN_100b6d08(auStack_117,iVar2);
    if ((*piVar1 != 0) && (*(int *)(*piVar1 + 4) != 0)) {
      .glue::SetWTitle(*(undefined4 *)(*piVar1 + 4),&uStack_118);
    }
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbteleport__FP5VAddr @ 10098e60 ====
// CyDecompAt: created, body 10098e60-10098edf

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbteleport__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  .debug::_TeleportTo__8TGameSysFsss
            (*_DAT_100cdcd0,(int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
             (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4),
             (int)(short)((int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4));
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbShowWindow__FP5VAddr @ 10098f08 ====
// CyDecompAt: created, body 10098f08-10098f83

void _cbShowWindow__FP5VAddr(undefined4 *param_1,undefined4 *param_2)

{
  int iVar1;
  
  iVar1 = .debug::_FindScriptedWindow__15TScriptedWindowF5VAddr(*param_2);
  if (iVar1 == 0) {
    *param_1 = *(undefined4 *)PTR_DAT_100cde70;
  }
  else {
    FUN_100c50e8(iVar1);
    *param_1 = *(undefined4 *)PTR_DAT_100cddec;
  }
  return;
}


// ==== .cbGetQV__FP5VAddr @ 10098fb0 ====
// CyDecompAt: created, body 10098fb0-10098fd3

void _cbGetQV__FP5VAddr(uint *param_1,uint *param_2)

{
  *param_1 = (uint)(byte)PTR_DAT_100cdbbc[(int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4];
  return;
}


// ==== .cbSetQV__FP5VAddr @ 10098ff8 ====
// CyDecompAt: created, body 10098ff8-10099027

void _cbSetQV__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  undefined *puVar1;
  
  puVar1 = PTR_DAT_100cdbb0;
  PTR_DAT_100cdbbc[(int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4] =
       (char)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4);
  *param_1 = *(undefined4 *)puVar1;
  return;
}


// ==== .cbGetQF__FP5VAddr @ 1009904c ====
// CyDecompAt: created, body 1009904c-100990a7

void _cbGetQF__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  uint uVar1;
  uint uVar2;
  
  uVar1 = *param_2 << 4;
  uVar2 = uVar1 | *param_2 >> 0x1c;
  if ((1 << ((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4 & 0x1fU) &
      *(uint *)(PTR_DAT_100cdbc0 +
               (((int)uVar2 >> 9) + (uint)((int)uVar2 < 0 && (uVar1 & 0x1f0) != 0)) * 4)) != 0) {
    *param_1 = *(undefined4 *)PTR_DAT_100cddec;
    return;
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cde70;
  return;
}


// ==== .cbSetQF__FP5VAddr @ 100990cc ====
// CyDecompAt: created, body 100990cc-10099193

void _cbSetQF__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  int iVar1;
  short sVar3;
  uint uVar2;
  char cVar4;
  
  sVar3 = (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  cVar4 = .debug::_IsTrue__7TInterpF5VAddr(param_2[1]);
  if (cVar4 == '\0') {
    uVar2 = (uint)sVar3;
    iVar1 = (((int)uVar2 >> 5) + (uint)((int)uVar2 < 0 && (uVar2 & 0x1f) != 0)) * 4;
    *(uint *)(PTR_DAT_100cdbc0 + iVar1) =
         *(uint *)(PTR_DAT_100cdbc0 + iVar1) & ~(1 << ((int)sVar3 & 0x1fU));
  }
  else {
    uVar2 = (uint)sVar3;
    iVar1 = (((int)uVar2 >> 5) + (uint)((int)uVar2 < 0 && (uVar2 & 0x1f) != 0)) * 4;
    *(uint *)(PTR_DAT_100cdbc0 + iVar1) =
         *(uint *)(PTR_DAT_100cdbc0 + iVar1) | 1 << ((int)sVar3 & 0x1fU);
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbRecalcLight__FP5VAddr @ 100991b8 ====
// CyDecompAt: created, body 100991b8-10099213

void _cbRecalcLight__FP5VAddr(undefined4 *param_1)

{
  .debug::_RecalcPartyLight__13TStatusWindowFv(*(undefined4 *)PTR_DAT_100cdb98);
  .debug::_DoTicks__11TGameViewerFlUc(*(undefined4 *)PTR_DAT_100cdbb8,0,0);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbIsLOS__FP5VAddr @ 10099240 ====
// CyDecompAt: created, body 10099240-100992e7

void _cbIsLOS__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  char cVar1;
  
  cVar1 = .debug::_IsStraightAbs__7TViewerFssss
                    (*(undefined4 *)PTR_DAT_100cdbb8,
                     (int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
                     (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4),
                     (int)(short)((int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4),
                     (int)(short)((int)(param_2[3] << 4 | param_2[3] >> 0x1c) >> 4));
  if (cVar1 == '\0') {
    *param_1 = *(undefined4 *)PTR_DAT_100cde70;
  }
  else {
    *param_1 = *(undefined4 *)PTR_DAT_100cddec;
  }
  return;
}


// ==== .DoBresPixel__11TLineEffectFl @ 1009930c ====
// CyDecompAt: created, body 1009930c-10099403

undefined4 _DoBresPixel__11TLineEffectFl(undefined4 param_1,undefined4 param_2)

{
  bool bVar1;
  short sVar3;
  uint uVar2;
  undefined4 uVar4;
  int *piVar5;
  short sVar6;
  short sVar7;
  
  sVar3 = (short)((uint)param_2 >> 0x10);
  bVar1 = false;
  sVar7 = sVar3 - *(short *)(*(int *)PTR_DAT_100cdbb8 + 8);
  sVar6 = (short)param_2 - *(short *)(*(int *)PTR_DAT_100cdbb8 + 10);
  if ((((-0x10 < sVar7) && (sVar7 < 0x10)) && (-0x10 < sVar6)) && (sVar6 < 0x10)) {
    bVar1 = true;
  }
  if (bVar1) {
    uVar4 = .debug::_GetBestProp__7TViewerFss
                      (*(undefined4 *)PTR_DAT_100cdbb8,(int)(short)(sVar3 << 2),
                       (int)(short)((short)param_2 << 2));
    if ((short)uVar4 != 0) {
      piVar5 = (int *).debug::_GetCharacter__14TActiveMonsterFs(uVar4);
      if (piVar5 != (int *)0x0) {
        uVar2 = *piVar5 - (int)PTR_DAT_100cdbf0;
        PTR_DAT_100cee00[((int)uVar2 >> 5) + (uint)((int)uVar2 < 0 && (uVar2 & 0x1f) != 0)] = 1;
      }
    }
  }
  return 1;
}


// ==== .cbMissileFX__FP5VAddr @ 10099434 ====
// CyDecompAt: created, body 10099434-100996f7

void _cbMissileFX__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined *puVar3;
  short sVar4;
  uint uVar5;
  ushort uVar6;
  short sVar7;
  short sVar8;
  int iVar9;
  int iVar10;
  short sVar11;
  short sVar12;
  short sVar13;
  undefined **appuStack_58 [3];
  short sStack_4c;
  short sStack_4a;
  short sStack_48;
  short sStack_46;
  short sStack_44;
  
  puVar3 = PTR_DAT_100cee00;
  puVar2 = PTR_DAT_100cdbf0;
  puVar1 = PTR_DAT_100cdbec;
  FUN_100b46a0(PTR_DAT_100cee00,0,0x200);
  uVar5 = (int)(param_2[5] << 4 | param_2[5] >> 0x1c) >> 4;
  uVar6 = (ushort)uVar5;
  sStack_44 = (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  sStack_46 = (short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4);
  sStack_48 = (short)((int)(param_2[4] << 4 | param_2[4] >> 0x1c) >> 4);
  sStack_4a = (short)((int)(param_2[6] << 4 | param_2[6] >> 0x1c) >> 4);
  sStack_4c = (short)((int)(param_2[7] << 4 | param_2[7] >> 0x1c) >> 4);
  iVar10 = (int)(short)((ushort)(*(uint *)(puVar2 + *(short *)puVar1 * 0x20) >> 0xc) & 0xfff);
  iVar9 = (int)(short)((ushort)*(undefined4 *)(puVar2 + *(short *)puVar1 * 0x20) & 0xfff);
  sVar8 = (short)((int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4);
  sVar7 = (short)((int)(param_2[3] << 4 | param_2[3] >> 0x1c) >> 4);
  if ((uVar6 & 0xf) != 0xf) {
    .debug::_DoMissile__11TGameViewerFsssssssss
              (*(undefined4 *)PTR_DAT_100cdbb8,sStack_44 - iVar10,sStack_46 - iVar9,sVar8 - iVar10,
               sVar7 - iVar9,(int)sStack_48,0,0xffffffff,uVar6 & 7,(int)sStack_4c);
    if ((uVar5 & 8) == 0) {
      appuStack_58[0] = &PTR_PTR_100d76bc;
      .debug::_DrawBres__5TBresFiiiilii
                (appuStack_58,(int)sStack_44,(int)sStack_46,(int)sVar8,(int)sVar7,
                 (int)sStack_44 << 0x10 | (int)sStack_46,0x10000,1);
      puVar3[*(short *)puVar1] = 0;
    }
  }
  if ((int)(param_2[6] << 4 | param_2[6] >> 0x1c) >> 4 != 0) {
    .debug::_DoBurst__11TGameViewerFsssssUc
              (*(undefined4 *)PTR_DAT_100cdbb8,sVar8 - iVar10,sVar7 - iVar9,(int)sStack_4a,
               (int)sStack_48,(int)((short)uVar6 >> 4),1);
    sVar11 = sStack_4a * sStack_4a;
    for (sVar13 = 0; sVar13 < 0x200; sVar13 = sVar13 + 1) {
      iVar9 = .debug::_GetCharacter__14TActiveMonsterFP9CharEntry(puVar2 + sVar13 * 0x20);
      if ((iVar9 != 0) &&
         (sVar12 = *(short *)(*(int *)(iVar9 + 0x10) + 2),
         sVar4 = (short)((uint)**(undefined4 **)(iVar9 + 0x10) >> 8) >> 4,
         sVar12 = (short)((ushort)((uint)((int)sVar12 << 0x14) >> 0x10) |
                         (ushort)(sVar12 >> 0xf) >> 0xc) >> 4,
         ((int)sVar4 - (int)sVar8) * ((int)sVar4 - (int)sVar8) +
         ((int)sVar12 - (int)sVar7) * ((int)sVar12 - (int)sVar7) <= (int)sVar11)) {
        puVar3[sVar13] = 1;
      }
    }
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbCastSpellFX__FP5VAddr @ 10099720 ====
// CyDecompAt: created, body 10099720-1009978b

void _cbCastSpellFX__FP5VAddr(undefined4 *param_1,undefined4 *param_2)

{
  .debug::_ShowMagic__11TGameViewerFssUc
            (*(undefined4 *)PTR_DAT_100cdbb8,(int)(short)*param_2,
             (int)(short)((int)(param_2[1] << 4 | (uint)param_2[1] >> 0x1c) >> 4),1);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbHitFX__FP5VAddr @ 100997b8 ====
// CyDecompAt: created, body 100997b8-1009983b

void _cbHitFX__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  .debug::_ShowHit__11TGameViewerFsssUc
            (*(undefined4 *)PTR_DAT_100cdbb8,
             (int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
             (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4),
             (int)(short)((int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4),1);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbAttackFX__FP5VAddr @ 10099860 ====
// CyDecompAt: created, body 10099860-10099987

void _cbAttackFX__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  undefined4 uVar1;
  short sVar2;
  uint uStack_48;
  undefined2 auStack_44 [24];
  
  uVar1 = .debug::_Len__7TInterpF5VAddr(param_2[4]);
  if ((short)uVar1 == 0) {
    uVar1 = 1;
    auStack_44[0] = (undefined2)((int)(param_2[4] << 4 | param_2[4] >> 0x1c) >> 4);
  }
  else {
    if (0x10 < (short)uVar1) {
      uVar1 = 0x10;
    }
    for (sVar2 = 0; sVar2 < (short)uVar1; sVar2 = sVar2 + 1) {
      .debug::_At__7TInterpF5VAddrs(&uStack_48,param_2[4],(int)sVar2);
      auStack_44[sVar2] = (short)((int)(uStack_48 << 4 | uStack_48 >> 0x1c) >> 4);
    }
  }
  .debug::_ShowAttack__11TGameViewerFsssssPsUc
            (*(undefined4 *)PTR_DAT_100cdbb8,
             (int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
             (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4),
             (int)(short)((int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4),
             (int)(short)((int)(param_2[3] << 4 | param_2[3] >> 0x1c) >> 4),uVar1,auStack_44,1);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbNext__FP5VAddr @ 100999b0 ====
// CyDecompAt: created, body 100999b0-10099a8b

void _cbNext__FP5VAddr(undefined4 *param_1,ushort *param_2)

{
  undefined *puVar1;
  short sVar2;
  short sVar3;
  short sVar4;
  char *pcVar5;
  undefined4 uStack_28;
  
  puVar1 = PTR_DAT_100cdc3c;
  if ((*param_2 & 0xfff) == 0) {
    sVar2 = (short)*(undefined4 *)param_2;
    pcVar5 = (char *)(*(int *)PTR_DAT_100cdc44 + sVar2 * 0x10);
    sVar3 = .debug::_GetPropParent__FP8PropItem(pcVar5);
    do {
      sVar2 = sVar2 + 1;
      pcVar5 = pcVar5 + 0x10;
      if (*(short *)puVar1 <= sVar2) goto LAB_10099a6c;
    } while ((*pcVar5 == -1) ||
            (sVar4 = .debug::_GetPropParent__FP8PropItem(pcVar5), sVar3 != sVar4));
    uStack_28 = CONCAT22((short)((uint)*(undefined4 *)param_2 >> 0x10),sVar2);
    *param_1 = uStack_28;
  }
  else {
LAB_10099a6c:
    *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  }
  return;
}


// ==== .cbFadeFX__FP5VAddr @ 10099ab0 ====
// CyDecompAt: created, body 10099ab0-10099adf

void _cbFadeFX__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  undefined *puVar1;
  
  puVar1 = PTR_DAT_100cdbb0;
  *(short *)(*(int *)PTR_DAT_100cdbb8 + 0x20c28) =
       (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  *param_1 = *(undefined4 *)puVar1;
  return;
}


// ==== .cbScreenFX__FP5VAddr @ 10099b08 ====
// CyDecompAt: created, body 10099b08-10099cab

void _cbScreenFX__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  ushort uVar1;
  ushort uVar2;
  undefined *puVar3;
  undefined *puVar4;
  int iVar5;
  uint uVar6;
  char cVar7;
  undefined1 auStack_48 [28];
  
  puVar4 = PTR_DAT_100cdbb8;
  puVar3 = PTR_DAT_100cdb84;
  iVar5 = (int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4;
  if (iVar5 == 2) {
    uVar1 = (ushort)(*(uint *)(PTR_DAT_100cdbf0 + *(short *)PTR_DAT_100cdbec * 0x20) >> 0xc) & 0xfff
    ;
    uVar2 = (ushort)*(undefined4 *)(PTR_DAT_100cdbf0 + *(short *)PTR_DAT_100cdbec * 0x20) & 0xfff;
    .debug::_MakeZone__11TGameViewerFss(*(undefined4 *)PTR_DAT_100cdbb8,uVar1,uVar2);
    .debug::_MagicMap__11TGameViewerFsss(*(undefined4 *)puVar4,uVar1,uVar2,4);
    .glue::FlushEvents(10,0);
    do {
      cVar7 = FUN_100c50e8(*(undefined4 *)puVar3,8,auStack_48,1);
      if (cVar7 != '\0') break;
      cVar7 = FUN_100c50e8(*(undefined4 *)puVar3,2,auStack_48,1);
    } while (cVar7 == '\0');
  }
  else if (iVar5 < 2) {
    if (iVar5 == 0) {
      .debug::_Tremor__11TGameViewerFss(*(undefined4 *)PTR_DAT_100cdbb8,4,0x14);
    }
    else if (-1 < iVar5) {
      .debug::_DoGammaFade(0x639c);
      iVar5 = .glue::TickCount();
      do {
        uVar6 = .glue::TickCount();
      } while (uVar6 < iVar5 + 10U);
      .debug::_DoGammaFade(100);
    }
  }
  else if (iVar5 == 4) {
    .debug::_GammaFadeIn(200);
  }
  else if (iVar5 < 4) {
    .debug::_GammaFadeOut(200);
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbSetWaypoint__FP5VAddr @ 10099cd4 ====
// CyDecompAt: created, body 10099cd4-10099d6f

void _cbSetWaypoint__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  int iVar1;
  
  iVar1 = .debug::_GetCharacter__14TActiveMonsterFP9CharEntry
                    (PTR_DAT_100cdbf0 + (*param_2 & 0xffff) * 0x20);
  if (iVar1 != 0) {
    .debug::_SetWaypoint__14TActiveMonsterFss
              (iVar1,(int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4),
               (int)(short)((int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4));
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbQueueAction__FP5VAddr @ 10099d9c ====
// CyDecompAt: created, body 10099d9c-10099e4b

void _cbQueueAction__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  int iVar1;
  
  iVar1 = .debug::_GetCharacter__14TActiveMonsterFP9CharEntry
                    (PTR_DAT_100cdbf0 + (*param_2 & 0xffff) * 0x20);
  if (iVar1 != 0) {
    .debug::_QueueActivity__14TActiveMonsterFUcss5VAddr
              (iVar1,(int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4 & 0xff,
               (int)(short)((int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4),
               (int)(short)((int)(param_2[3] << 4 | param_2[3] >> 0x1c) >> 4),param_2[4]);
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbWaitForFlag__FP5VAddr @ 10099e78 ====
// CyDecompAt: created, body 10099e78-10099fc7

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbWaitForFlag__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  undefined2 uVar1;
  int iVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined2 *puVar5;
  short sVar7;
  uint uVar6;
  uint uVar8;
  undefined1 auStack_16 [6];
  
  puVar5 = _DAT_100cdd84;
  puVar4 = PTR_DAT_100cdbc0;
  sVar7 = (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  uVar8 = (uint)sVar7;
  uVar6 = (uint)sVar7;
  iVar2 = (((int)uVar6 >> 5) + (uint)((int)uVar6 < 0 && (uVar6 & 0x1f) != 0)) * 4;
  *(uint *)(PTR_DAT_100cdbc0 + iVar2) = *(uint *)(PTR_DAT_100cdbc0 + iVar2) & ~(1 << (uVar8 & 0x1f))
  ;
  .debug::___ct__11TSpinCursorFs(auStack_16,0x80);
  uVar1 = *puVar5;
  *puVar5 = 2;
  .debug::_SyncTaskMaster__11TTaskMasterFv();
  .debug::_LockOutUI__11TTaskMasterFv();
  while( true ) {
    uVar6 = (uint)sVar7;
    if ((1 << (uVar8 & 0x1f) &
        *(uint *)(puVar4 + (((int)uVar6 >> 5) + (uint)((int)uVar6 < 0 && (uVar6 & 0x1f) != 0)) * 4))
        != 0) break;
    .debug::_Guide__14TActiveMonsterFv();
    .debug::_Spin__11TSpinCursorFs(auStack_16,1);
  }
  .debug::_UnlockOutUI__11TTaskMasterFv();
  puVar3 = PTR_DAT_100cdbb0;
  uVar6 = (uint)sVar7;
  iVar2 = (((int)uVar6 >> 5) + (uint)((int)uVar6 < 0 && (uVar6 & 0x1f) != 0)) * 4;
  *(uint *)(puVar4 + iVar2) = *(uint *)(puVar4 + iVar2) & ~(1 << (uVar8 & 0x1f));
  *param_1 = *(undefined4 *)puVar3;
  *puVar5 = uVar1;
  .debug::___dt__11TSpinCursorFv(auStack_16,0xffffffff);
  return;
}


// ==== .cbShowConversation__FP5VAddr @ 10099ff4 ====
// CyDecompAt: created, body 10099ff4-1009a05f

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbShowConversation__FP5VAddr(undefined4 *param_1)

{
  if (*_DAT_100cdcc8 != 0) {
    FUN_100c50e8();
    .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(_DAT_100cdd24,1);
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbHideConversation__FP5VAddr @ 1009a090 ====
// CyDecompAt: created, body 1009a090-1009a0fb

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbHideConversation__FP5VAddr(undefined4 *param_1)

{
  if (*_DAT_100cdcc8 != 0) {
    FUN_100c50e8();
    .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(_DAT_100cdd24,2);
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbBeginConversation__FP5VAddr @ 1009a12c ====
// CyDecompAt: created, body 1009a12c-1009a17f

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbBeginConversation__FP5VAddr(undefined4 *param_1)

{
  if (*_DAT_100cdcc8 == 0) {
    .debug::_BeginTalking__13TStatusWindowFv(*(undefined4 *)PTR_DAT_100cdb98);
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbEndConversation__FP5VAddr @ 1009a1b0 ====
// CyDecompAt: created, body 1009a1b0-1009a203

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbEndConversation__FP5VAddr(undefined4 *param_1)

{
  if (*_DAT_100cdcc8 != 0) {
    .debug::_EndTalking__13TStatusWindowFv(*(undefined4 *)PTR_DAT_100cdb98);
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbBeginCutScene__FP5VAddr @ 1009a234 ====
// CyDecompAt: created, body 1009a234-1009a327

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbBeginCutScene__FP5VAddr(undefined4 *param_1)

{
  undefined *puVar1;
  undefined4 uVar2;
  undefined4 uStack_18;
  undefined4 uStack_14;
  undefined4 auStack_10 [2];
  
  puVar1 = PTR_DAT_100cedfc;
  .glue::GetPort(auStack_10);
  if (*(int *)puVar1 == 0) {
    uStack_18 = *(undefined4 *)(*(int *)*_DAT_100cdd40 + 0x22);
    uStack_14 = *(undefined4 *)(*(int *)*_DAT_100cdd40 + 0x26);
    uVar2 = .glue::NewCWindow(0,&uStack_18,PTR_DAT_100cee30,1,2,0xffffffff,0,0);
    *(undefined4 *)puVar1 = uVar2;
    .glue::SetPort(*(undefined4 *)puVar1);
    .glue::FillRect(*(int *)puVar1 + 0x10,PTR_DAT_100cdb94 + 0xba);
    *PTR_DAT_100cedf8 = 0;
    .glue::SetPort(auStack_10[0]);
    .glue::HideCursor();
    *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  }
  else {
    *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  }
  return;
}


// ==== .cbEndCutScene__FP5VAddr @ 1009a354 ====
// CyDecompAt: created, body 1009a354-1009a3df

void _cbEndCutScene__FP5VAddr(undefined4 *param_1)

{
  undefined *puVar1;
  
  puVar1 = PTR_DAT_100cedfc;
  if (*(int *)PTR_DAT_100cedfc != 0) {
    .glue::HideWindow(*(undefined4 *)PTR_DAT_100cedfc);
    .glue::DisposeWindow(*(undefined4 *)puVar1);
    FUN_100c50e8();
    *(undefined4 *)puVar1 = 0;
    .glue::ShowCursor();
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbScrollText__FP5VAddr @ 1009a40c ====
// CyDecompAt: created, body 1009a40c-1009a9e7

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbScrollText__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  ushort uVar1;
  bool bVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined4 uVar5;
  undefined *puVar6;
  undefined *puVar7;
  undefined *puVar8;
  uint uVar9;
  uint uVar10;
  int iVar11;
  undefined4 uVar12;
  undefined4 uStack_168;
  undefined4 uStack_164;
  undefined4 uStack_160;
  undefined4 uStack_15c;
  undefined4 uStack_158;
  undefined4 uStack_154;
  undefined4 uStack_150;
  undefined4 uStack_14c;
  undefined4 uStack_148;
  undefined4 uStack_144;
  undefined4 uStack_140;
  undefined4 uStack_13c;
  undefined4 uStack_138;
  undefined4 uStack_134;
  undefined4 uStack_130;
  undefined **ppuStack_12c;
  undefined4 uStack_128;
  undefined2 uStack_124;
  undefined4 uStack_120;
  undefined4 uStack_11c;
  undefined4 uStack_118;
  undefined4 uStack_114;
  undefined4 uStack_110;
  undefined4 uStack_10c;
  undefined1 auStack_108 [60];
  undefined4 uStack_cc;
  undefined4 uStack_c8;
  undefined4 uStack_c4;
  undefined4 uStack_c0;
  undefined4 uStack_bc;
  undefined4 uStack_b8;
  undefined **ppuStack_b4;
  undefined4 uStack_b0;
  undefined2 uStack_ac;
  undefined4 uStack_a8;
  undefined4 uStack_a4;
  undefined4 uStack_a0;
  undefined4 uStack_9c;
  undefined4 uStack_98;
  undefined4 uStack_94;
  undefined **ppuStack_90;
  undefined4 uStack_8c;
  undefined2 uStack_88;
  undefined4 uStack_84;
  undefined4 uStack_80;
  undefined4 uStack_7c;
  undefined4 uStack_78;
  undefined4 uStack_74;
  undefined4 uStack_70;
  undefined4 uStack_6c;
  undefined4 uStack_64;
  undefined4 auStack_60 [2];
  undefined4 uStack_58;
  undefined4 uStack_54;
  undefined4 auStack_50 [4];
  
  puVar8 = PTR_DAT_100cedfc;
  puVar7 = PTR_DAT_100cedf8;
  puVar6 = PTR_DAT_100cddec;
  uVar5 = _DAT_100cdd24;
  puVar4 = PTR_DAT_100cdbb0;
  puVar3 = PTR_DAT_100cdb84;
  if ((*(int *)PTR_DAT_100cedfc == 0) || (*PTR_DAT_100cedf8 != '\0')) {
    *param_1 = *(undefined4 *)PTR_DAT_100cddec;
  }
  else {
    uVar12 = *(undefined4 *)PTR_DAT_100cedfc;
    .glue::GetPort(auStack_50);
    .glue::SetPort(uVar12);
    .debug::_ResetWorkAllocater__Fv();
    uVar12 = *(undefined4 *)PTR_DAT_100cde44;
    .glue::GetGWorld(&uStack_58,&uStack_54);
    .glue::SetGWorld(uVar12,0);
    .glue::EraseRect(*(int *)PTR_DAT_100cde44 + 0x10);
    .debug::_SetText__Fs(6);
    iVar11 = *_DAT_100cde40;
    .glue::GetGWorld(&uStack_64,auStack_60);
    .glue::SetGWorld(iVar11,0);
    .glue::EraseRect(*_DAT_100cde40 + 0x10);
    .debug::_SetText__Fs(6);
    .glue::SetGWorld(uStack_64,auStack_60[0]);
    .glue::SetGWorld(uStack_58,uStack_54);
    uStack_6c = _DAT_100d7614;
    .debug::_AllocateWorkArea__Fss(&uStack_144,0x220,0x110);
    uStack_78 = uStack_144;
    uStack_74 = uStack_140;
    uStack_70 = uStack_13c;
    uStack_8c = uStack_6c;
    uStack_88 = 0;
    ppuStack_90 = &PTR_PTR_100d77b0;
    uStack_84 = uStack_144;
    uStack_80 = uStack_140;
    uStack_7c = uStack_13c;
    uVar12 = .glue::GetPicture((int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4));
    .debug::_LoadPicture__18TStaticImageObjectFPP7Picture(&ppuStack_90,uVar12);
    .glue::ReleaseResource(uVar12);
    if (param_2[1] == *(uint *)puVar4) {
      uVar9 = ((int)*(short *)(*(int *)puVar8 + 0x16) - (int)*(short *)(*(int *)puVar8 + 0x12)) -
              0x220;
      uVar10 = ((int)*(short *)(*(int *)puVar8 + 0x14) - (int)*(short *)(*(int *)puVar8 + 0x10)) -
               0x110;
      uStack_6c = CONCAT22((short)((int)uVar10 >> 1) +
                           (ushort)((int)uVar10 < 0 && (uVar10 & 1) != 0),
                           (short)((int)uVar9 >> 1) + (ushort)((int)uVar9 < 0 && (uVar9 & 1) != 0));
      .debug::_AllocateWorkArea__Fss(&uStack_150,0x220,0x110);
      uStack_9c = uStack_150;
      uStack_98 = uStack_14c;
      uStack_94 = uStack_148;
      uStack_b0 = uStack_6c;
      uStack_ac = 0;
      ppuStack_b4 = &PTR_PTR_100d77b0;
      uStack_a8 = uStack_150;
      uStack_a4 = uStack_14c;
      uStack_a0 = uStack_148;
      uStack_c0 = *(undefined4 *)puVar8;
      uStack_b8 = *(undefined4 *)(*(int *)puVar8 + 0x14);
      uStack_bc = *(undefined4 *)(*(int *)puVar8 + 0x10);
      .debug::_Apply__18TStaticImageObjectFR9TWorkArea(&ppuStack_90,&uStack_9c);
      .debug::_Apply__18TStaticImageObjectFR9TWorkArea(&ppuStack_b4,&uStack_c0);
      *param_1 = *(undefined4 *)PTR_DAT_100cde70;
      .glue::SetPort(auStack_50[0]);
    }
    else {
      .debug::_AllocateWorkArea__Fss(&uStack_15c,0x220,0x110);
      uStack_cc = uStack_15c;
      uStack_c8 = uStack_158;
      uStack_c4 = uStack_154;
      uVar12 = .debug::_VAddrToPtr__7TInterpF5VAddr(param_2[1]);
      .debug::___ct__28TStringFadeInTextImageObjectFRC9TWorkAreaRC9TWorkArea5PointsPcUc
                (auStack_108,&uStack_cc,&uStack_78,uStack_6c,0x16,uVar12,0);
      uVar9 = ((int)*(short *)(*(int *)puVar8 + 0x16) - (int)*(short *)(*(int *)puVar8 + 0x12)) -
              0x220;
      uVar10 = ((int)*(short *)(*(int *)puVar8 + 0x14) - (int)*(short *)(*(int *)puVar8 + 0x10)) -
               0x110;
      uStack_6c = CONCAT22((short)((int)uVar10 >> 1) +
                           (ushort)((int)uVar10 < 0 && (uVar10 & 1) != 0),
                           (short)((int)uVar9 >> 1) + (ushort)((int)uVar9 < 0 && (uVar9 & 1) != 0));
      .debug::_AllocateWorkArea__Fss(&uStack_168,0x220,0x110);
      uStack_114 = uStack_168;
      bVar2 = false;
      uStack_110 = uStack_164;
      uStack_10c = uStack_160;
      uStack_128 = uStack_6c;
      uStack_124 = 0;
      ppuStack_12c = &PTR_PTR_100d77b0;
      uStack_120 = uStack_168;
      uStack_11c = uStack_164;
      uStack_118 = uStack_160;
      uStack_138 = *(undefined4 *)puVar8;
      uStack_130 = *(undefined4 *)(*(int *)puVar8 + 0x14);
      uStack_134 = *(undefined4 *)(*(int *)puVar8 + 0x10);
      uVar9 = .glue::TickCount();
      while (!bVar2) {
        .glue::GetOSEvent(10,*(int *)puVar3 + 4);
        .debug::_Idle__6TAudioFv(uVar5);
        uVar1 = *(ushort *)(*(int *)puVar3 + 4);
        if (uVar1 != 2) {
          if (uVar1 < 2) {
            if (uVar1 != 0) {
              bVar2 = true;
            }
          }
          else if (uVar1 < 4) {
            switch(*(uint *)(*(int *)puVar3 + 6) & 0xff) {
            case 10:
            case 0xd:
            case 0x20:
              bVar2 = true;
              break;
            case 0x1b:
              *puVar7 = 1;
              bVar2 = true;
            }
          }
        }
        uVar10 = .glue::TickCount();
        if (uVar9 < uVar10) {
          iVar11 = .glue::TickCount();
          uVar9 = iVar11 + 1;
          FUN_100c50e8(auStack_108);
          .debug::_Apply__18TStaticImageObjectFR9TWorkArea(&ppuStack_90,&uStack_114);
          FUN_100c50e8(auStack_108,&uStack_114);
          .debug::_Apply__18TStaticImageObjectFR9TWorkArea(&ppuStack_12c,&uStack_138);
        }
      }
      if ((*(int *)puVar8 == 0) || (*puVar7 != '\0')) {
        *param_1 = *(undefined4 *)puVar6;
        .glue::SetPort(auStack_50[0]);
      }
      else {
        *param_1 = *(undefined4 *)puVar4;
        .glue::SetPort(auStack_50[0]);
      }
    }
  }
  return;
}


// ==== .cbAddToDo__FP5VAddr @ 1009aa14 ====
// CyDecompAt: created, body 1009aa14-1009aa6f

void _cbAddToDo__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  .debug::_AddToDo__5TToDoFs5VAddr
            ((int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),param_2[1]);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbDoneToDo__FP5VAddr @ 1009aa98 ====
// CyDecompAt: created, body 1009aa98-1009aaeb

void _cbDoneToDo__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  .debug::_DoneToDo__5TToDoFs((int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4));
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbGetSkill__FP5VAddr @ 1009ab14 ====
// CyDecompAt: created, body 1009ab14-1009abab

void _cbGetSkill__FP5VAddr(uint *param_1,uint *param_2)

{
  ushort uVar1;
  uint uStack_28;
  
  uVar1 = .debug::_FindSkill__Fss
                    ((int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
                     (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4));
  if (uVar1 == 0) {
    *param_1 = *(uint *)PTR_DAT_100cdbb0;
  }
  else {
    uStack_28 = uVar1 | 0x40500000;
    *param_1 = uStack_28;
  }
  return;
}


// ==== .cbReschedule__FP5VAddr @ 1009abd4 ====
// CyDecompAt: created, body 1009abd4-1009ac23

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbReschedule__FP5VAddr(undefined4 *param_1)

{
  .debug::_ScheduleTime__FsUc((int)(short)(_DAT_100d3e18 >> 0xc),0);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbGetNamedProxy__FP5VAddr @ 1009ac50 ====
// CyDecompAt: created, body 1009ac50-1009ac5f

void _cbGetNamedProxy__FP5VAddr(undefined4 *param_1)

{
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbGetNamedProp__FP5VAddr @ 1009ac8c ====
// CyDecompAt: created, body 1009ac8c-1009ad13

void _cbGetNamedProp__FP5VAddr(uint *param_1,uint *param_2)

{
  int iVar1;
  ushort uVar2;
  
  uVar2 = 0;
  iVar1 = *(int *)PTR_DAT_100cdc44;
  while( true ) {
    if (*(short *)PTR_DAT_100cdc3c <= (short)uVar2) {
      *param_1 = *(uint *)PTR_DAT_100cdbb0;
      return;
    }
    if ((uint)*(ushort *)(iVar1 + 8) == (int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4) break;
    iVar1 = iVar1 + 0x10;
    uVar2 = uVar2 + 1;
  }
  *param_1 = uVar2 | 0x40000000;
  return;
}


// ==== .cbNewUniqueName__FP5VAddr @ 1009ad40 ====
// CyDecompAt: created, body 1009ad40-1009ad67

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _cbNewUniqueName__FP5VAddr(uint *param_1)

{
  uint uVar1;
  
  uVar1 = (uint)_DAT_100d73f4;
  _DAT_100d73f4 = _DAT_100d73f4 + 1;
  *param_1 = uVar1 & 0xfffffff;
  return;
}


// ==== .cbEnableAutoMap__FP5VAddr @ 1009ad94 ====
// CyDecompAt: created, body 1009ad94-1009ae0b

void _cbEnableAutoMap__FP5VAddr(undefined4 *param_1,undefined4 *param_2)

{
  char cVar1;
  undefined1 uVar3;
  undefined4 *puVar2;
  
  cVar1 = *(char *)(*(int *)PTR_DAT_100cdbb8 + 0xd);
  uVar3 = .debug::_IsTrue__7TInterpF5VAddr(*param_2);
  *(undefined1 *)(*(int *)PTR_DAT_100cdbb8 + 0xd) = uVar3;
  puVar2 = (undefined4 *)PTR_DAT_100cde70;
  if (cVar1 != '\0') {
    puVar2 = (undefined4 *)PTR_DAT_100cddec;
  }
  *param_1 = *puVar2;
  return;
}


// ==== .cbSetFillColor__FP5VAddr @ 1009ae38 ====
// CyDecompAt: created, body 1009ae38-1009ae93

void _cbSetFillColor__FP5VAddr(undefined4 *param_1,uint *param_2)

{
  .debug::_SetEraseColor__7TViewerFs
            (*(undefined4 *)PTR_DAT_100cdbb8,
             (int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4));
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .cbCD_Tool__FP5VAddr @ 1009aec0 ====
// CyDecompAt: created, body 1009aec0-1009b103

void _cbCD_Tool__FP5VAddr(uint *param_1,uint *param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  char cVar4;
  short sVar3;
  char acStack_38 [2];
  short sStack_36;
  undefined1 auStack_34 [6];
  undefined1 auStack_2e [6];
  undefined1 auStack_28 [2];
  undefined1 auStack_26 [2];
  ushort uStack_24;
  short asStack_22 [3];
  
  puVar2 = PTR_DAT_100cdd08;
  puVar1 = PTR_DAT_100cdbb0;
  if (*(short *)PTR_DAT_100cdd0c == 0) {
    FUN_100bf8b0(*(undefined4 *)PTR_DAT_100cdd08,asStack_22,&uStack_24,auStack_26,auStack_28,
                 auStack_2e,auStack_34);
    switch((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4) {
    case 0:
      FUN_100bfff0(*(undefined4 *)puVar2);
      *param_1 = *(uint *)puVar1;
      break;
    case 1:
      FUN_100bfcf0(*(undefined4 *)puVar2,(int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4 & 0xffff);
      *param_1 = *(uint *)puVar1;
      break;
    case 2:
      FUN_100bff28(*(undefined4 *)puVar2,*(uint *)PTR_DAT_100cddec == param_2[1]);
      *param_1 = *(uint *)puVar1;
      break;
    case 3:
      *param_1 = (int)asStack_22[0] & 0xfffffff;
      break;
    case 4:
      cVar4 = FUN_100bf4fc(*(undefined4 *)puVar2);
      if (cVar4 == '\0') {
        *param_1 = *(uint *)PTR_DAT_100cde70;
      }
      else {
        *param_1 = *(uint *)PTR_DAT_100cddec;
      }
      break;
    case 5:
      *param_1 = (uint)uStack_24;
      break;
    case 6:
      sVar3 = FUN_100bf52c(*(undefined4 *)puVar2,&sStack_36,acStack_38);
      if ((sVar3 == 0) && (acStack_38[0] != '\0')) {
        *param_1 = (int)sStack_36 & 0xfffffff;
      }
      else {
        *param_1 = *(uint *)puVar1;
      }
      break;
    case 7:
      sStack_36 = (short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4);
      if (sStack_36 < 0) {
        sStack_36 = 0;
      }
      if (0xff < sStack_36) {
        sStack_36 = 0xff;
      }
      FUN_100bf61c(*(undefined4 *)puVar2,(int)sStack_36);
      *param_1 = *(uint *)puVar1;
      break;
    case 8:
      FUN_100bfd88(*(undefined4 *)puVar2,1);
      *param_1 = *(uint *)puVar1;
      break;
    case 9:
      FUN_100bfd88(*(undefined4 *)puVar2,0);
      *param_1 = *(uint *)puVar1;
      break;
    case 10:
      FUN_100bf768(*(undefined4 *)puVar2);
      *param_1 = *(uint *)puVar1;
      break;
    default:
      goto LAB_1009b0e8;
    }
  }
  else {
LAB_1009b0e8:
    *param_1 = *(uint *)puVar1;
  }
  return;
}


// ==== .cbDebugStr__FP5VAddr @ 1009b12c ====
// CyDecompAt: created, body 1009b12c-1009b13b

void _cbDebugStr__FP5VAddr(undefined4 *param_1)

{
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== .__dt__Q23std154_EmptyMemberOpt<Q23std94allocator<Q33std70__tree<8MemRange,Q23std15less<8MemRange>,Q23std20allocator<8MemRange>>4node>,Q33std19__red_black_tree<1>6anchor>Fv @ 1009bb40 ====
// CyDecompAt: created, body 1009bb40-1009bb9b

int ___dt__Q23std154_EmptyMemberOpt<Q23std94allocator<Q33std70__tree<8MemRange,Q23std15less<8MemRange>,Q23std20allocator<8MemRange>>4node>,Q33std19__red_black_tree<1>6anchor>Fv
              (int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .__dt__Q23std48_EmptyMemberOpt<Q23std20allocator<8MemRange>,Ul>Fv @ 1009bc5c ====
// CyDecompAt: created, body 1009bc5c-1009bcb7

int ___dt__Q23std48_EmptyMemberOpt<Q23std20allocator<8MemRange>,Ul>Fv(int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .__dt__Q23std67set<8MemRange,Q23std15less<8MemRange>,Q23std20allocator<8MemRange>>Fv @ 1009bd0c ====
// CyDecompAt: created, body 1009bd0c-1009bd9f

int ___dt__Q23std67set<8MemRange,Q23std15less<8MemRange>,Q23std20allocator<8MemRange>>Fv
              (int param_1,short param_2)

{
  if (param_1 != 0) {
    if ((param_1 != 0) && (*(int *)(param_1 + 4) != 0)) {
      .debug::
      _destroy__Q23std70__tree<8MemRange,Q23std15less<8MemRange>,Q23std20allocator<8MemRange>>FPQ33std70__tree<8MemRange,Q23std15less<8MemRange>,Q23std20allocator<8MemRange>>4node
                (param_1,*(undefined4 *)(param_1 + 4));
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__Q23std20allocator<8MemRange>Fv @ 1009be08 ====
// CyDecompAt: created, body 1009be08-1009be73

int ___dt__Q23std20allocator<8MemRange>Fv(int param_1,short param_2)

{
  if ((param_1 != 0) && (0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .Tick__12TImageObjectFv @ 1009d7e0 ====
// CyDecompAt: created, body 1009d7e0-1009d7e3

void _Tick__12TImageObjectFv(void)

{
  return;
}


// ==== .Apply__12TImageObjectFR9TWorkArea @ 1009d810 ====
// CyDecompAt: created, body 1009d810-1009d813

void _Apply__12TImageObjectFR9TWorkArea(void)

{
  return;
}


// ==== .Tick__22TFadeInTextImageObjectFv @ 1009d9ac ====
// CyDecompAt: created, body 1009d9ac-1009dbaf

void _Tick__22TFadeInTextImageObjectFv(int param_1)

{
  int iVar1;
  int iVar2;
  undefined4 uVar3;
  short sStack_28;
  short sStack_26;
  undefined4 uStack_24;
  undefined4 uStack_20;
  undefined4 uStack_18;
  undefined4 auStack_14 [3];
  
  if (*(short *)(param_1 + 0x2e) == 0) {
    uVar3 = *(undefined4 *)(param_1 + 0xc);
    .glue::GetGWorld(&uStack_18,auStack_14);
    .glue::SetGWorld(uVar3,0);
    *(undefined2 *)(param_1 + 0x32) = 0x400;
    *(undefined2 *)(param_1 + 0x34) = 0x400;
    *(undefined2 *)(param_1 + 0x36) = 0x400;
    sStack_28 = (short)((uint)*(undefined4 *)(param_1 + 4) >> 0x10);
    uVar3 = *(undefined4 *)(param_1 + 0x10);
    uStack_20 = *(undefined4 *)(param_1 + 0x14);
    uStack_24._2_2_ = (short)uVar3;
    iVar2 = (int)uStack_24._2_2_;
    uStack_24._0_2_ = (short)((uint)uVar3 >> 0x10);
    iVar1 = (int)uStack_24._0_2_;
    sStack_26 = (short)*(undefined4 *)(param_1 + 4);
    uStack_24 = uVar3;
    .glue::OffsetRect(&uStack_24,((int)sStack_26 + (int)*(short *)(param_1 + 0x1e)) - iVar2,
                      ((int)sStack_28 + (int)*(short *)(param_1 + 0x1c)) - iVar1);
    .glue::CopyBits(*(int *)(param_1 + 0x18) + 2,*(int *)(param_1 + 0xc) + 2,&uStack_24,
                    param_1 + 0x10,0,0);
    FUN_100c50e8(param_1,param_1 + 0x10);
    .glue::SetGWorld(uStack_18,auStack_14[0]);
  }
  else if (((uint)*(ushort *)(param_1 + 0x32) * 6) / 5 < 0xffff) {
    *(short *)(param_1 + 0x32) = (short)(((uint)*(ushort *)(param_1 + 0x32) * 6) / 5);
    *(short *)(param_1 + 0x34) = (short)(((uint)*(ushort *)(param_1 + 0x34) * 6) / 5);
    *(short *)(param_1 + 0x36) = (short)(((uint)*(ushort *)(param_1 + 0x36) * 6) / 5);
  }
  else {
    *(undefined2 *)(param_1 + 0x32) = 0xffff;
    *(undefined2 *)(param_1 + 0x34) = 0xffff;
    *(undefined2 *)(param_1 + 0x36) = 0xffff;
  }
  *(short *)(param_1 + 0x2e) = *(short *)(param_1 + 0x2e) + 1;
  return;
}


// ==== .Apply__22TFadeInTextImageObjectFR9TWorkArea @ 1009de14 ====
// CyDecompAt: created, body 1009de14-1009df8b

void _Apply__22TFadeInTextImageObjectFR9TWorkArea(int param_1,int *param_2)

{
  ushort uVar1;
  uint uVar2;
  char cVar6;
  int *piVar3;
  int *piVar4;
  int iVar5;
  int iVar7;
  int iVar8;
  undefined4 uVar9;
  int iVar10;
  short sStack_30;
  short sStack_2e;
  undefined4 uStack_2c;
  undefined4 uStack_28;
  
  sStack_30 = (short)((uint)*(undefined4 *)(param_1 + 4) >> 0x10);
  uVar9 = *(undefined4 *)(param_1 + 0x10);
  uStack_28 = *(undefined4 *)(param_1 + 0x14);
  uStack_2c._2_2_ = (short)uVar9;
  iVar10 = (int)uStack_2c._2_2_;
  uStack_2c._0_2_ = (short)((uint)uVar9 >> 0x10);
  iVar7 = (int)uStack_2c._0_2_;
  sStack_2e = (short)*(undefined4 *)(param_1 + 4);
  uStack_2c = uVar9;
  .glue::OffsetRect(&uStack_2c,((int)sStack_2e + (int)*(short *)((int)param_2 + 6)) - iVar10,
                    ((int)sStack_30 + (int)*(short *)(param_2 + 1)) - iVar7);
  cVar6 = .debug::_IsDone__22TFadeInTextImageObjectFv(param_1);
  if (cVar6 == '\0') {
    piVar3 = (int *).glue::GetGWorldPixMap(*(undefined4 *)(param_1 + 0xc));
    piVar4 = (int *).glue::GetGWorldPixMap(*param_2);
    uVar1 = *(ushort *)(*piVar3 + 4);
    uVar2 = (int)*(short *)(*piVar4 + 4) & 0x3fff;
    iVar10 = .glue::GetPixBaseAddr();
    iVar8 = (int)uStack_2c._0_2_;
    iVar7 = (int)uStack_2c._2_2_;
    iVar5 = .glue::GetPixBaseAddr(piVar3);
    .debug::_DisBits__22TFadeInTextImageObjectFPcPcssssssll
              (iVar5 + uVar2 * (int)*(short *)(param_1 + 0x10) + (int)*(short *)(param_1 + 0x12),
               iVar10 + uVar2 * iVar8 + iVar7,*(short *)(param_1 + 0x2e) * 10,0,0,0,
               (int)*(short *)(param_1 + 0x16) - (int)*(short *)(param_1 + 0x12),
               (int)*(short *)(param_1 + 0x14) - (int)*(short *)(param_1 + 0x10),uVar1 & 0x3fff,
               uVar2);
  }
  else {
    .glue::CopyBits(*(int *)(param_1 + 0xc) + 2,*param_2 + 2,param_1 + 0x10,&uStack_2c,0,0);
  }
  return;
}


// ==== .Render__28TStringFadeInTextImageObjectFR4Rect @ 1009e0ec ====
// CyDecompAt: created, body 1009e0ec-1009e2df

void _Render__28TStringFadeInTextImageObjectFR4Rect(int param_1,short *param_2)

{
  uint uVar1;
  short sVar3;
  undefined4 uVar2;
  char cVar5;
  short sVar4;
  int iVar6;
  short sVar8;
  int iVar7;
  int iStack_38;
  int iStack_34;
  int iStack_30;
  int aiStack_2c [2];
  
  sVar4 = 1;
  iVar6 = 0;
  while( true ) {
    sVar8 = (short)iVar6;
    iStack_30 = 1;
    aiStack_2c[0] = ((int)param_2[3] - (int)param_2[1]) * 0x10000;
    sVar3 = FUN_100b6ce8(*(int *)(param_1 + 0x38) + (int)sVar8);
    uVar2 = .glue::VisibleLength(*(int *)(param_1 + 0x38) + (int)sVar8,(int)sVar3);
    cVar5 = .glue::StyledLineBreak
                      (*(int *)(param_1 + 0x38) + (int)sVar8,(int)sVar3,0,uVar2,0,aiStack_2c,
                       &iStack_30);
    if (cVar5 == '\x02') break;
    sVar4 = sVar4 + 1;
    iVar6 = iVar6 + iStack_30;
  }
  iVar7 = 0;
  uVar1 = ((int)param_2[2] - (int)*param_2) - (int)sVar4 * (int)*(short *)(param_1 + 0x30);
  iVar6 = (int)*param_2 + ((int)uVar1 >> 1) + (uint)((int)uVar1 < 0 && (uVar1 & 1) != 0);
  .glue::ForeColor(0x111);
  while( true ) {
    sVar3 = (short)iVar7;
    iStack_38 = 1;
    iStack_34 = ((int)param_2[3] - (int)param_2[1]) * 0x10000;
    sVar4 = FUN_100b6ce8(*(int *)(param_1 + 0x38) + (int)sVar3);
    uVar2 = .glue::VisibleLength(*(int *)(param_1 + 0x38) + (int)sVar3,(int)sVar4);
    cVar5 = .glue::StyledLineBreak
                      (*(int *)(param_1 + 0x38) + (int)sVar3,(int)sVar4,0,uVar2,0,&iStack_34,
                       &iStack_38);
    .glue::MoveTo((int)param_2[1],iVar6);
    iVar6 = iVar6 + *(short *)(param_1 + 0x30);
    if (cVar5 == '\x02') break;
    .glue::DrawText(*(undefined4 *)(param_1 + 0x38),iVar7,(int)(short)iStack_38);
    iVar7 = iVar7 + iStack_38;
  }
  .glue::DrawText(*(undefined4 *)(param_1 + 0x38),iVar7,(int)sVar4);
  .glue::ForeColor(0x21);
  return;
}


// ==== .Tick__27TScrollingCreditImageObjectFv @ 1009e478 ====
// CyDecompAt: created, body 1009e478-1009e5db

void _Tick__27TScrollingCreditImageObjectFv(int param_1)

{
  undefined2 uVar1;
  undefined4 uVar2;
  int iVar3;
  undefined4 uStack_28;
  undefined4 uStack_24;
  undefined1 auStack_20 [8];
  undefined4 uStack_18;
  undefined4 auStack_14 [2];
  
  if (*(short *)(param_1 + 0x22) == 0) {
    uVar2 = *(undefined4 *)(param_1 + 0xc);
    .glue::GetGWorld(&uStack_18,auStack_14);
    .glue::SetGWorld(uVar2,0);
    .debug::___ct__21TDisableAntiAliasTextFv(auStack_20);
    uStack_28 = *(undefined4 *)(param_1 + 0x1a);
    uStack_24 = *(undefined4 *)(param_1 + 0x1e);
    iVar3 = (int)*(short *)(param_1 + 0x1a) - (int)*(short *)(param_1 + 0x10);
    .glue::OffsetRect(&uStack_28,0,-iVar3);
    .glue::CopyBits(*(int *)(PTR_DAT_100cdb94 + 0xca) + 2,*(int *)(PTR_DAT_100cdb94 + 0xca) + 2,
                    param_1 + 0x1a,&uStack_28,0,0);
    uStack_28 = CONCAT22(uStack_24._0_2_,uStack_28._2_2_);
    uStack_24 = CONCAT22(*(undefined2 *)(param_1 + 0x14),uStack_24._2_2_);
    .glue::EraseRect(&uStack_28);
    uVar1 = FUN_100c50e8(param_1,&uStack_28);
    *(undefined2 *)(param_1 + 0x22) = uVar1;
    .glue::OffsetRect(param_1 + 0x1a,0,-iVar3);
    .debug::___dt__21TDisableAntiAliasTextFv(auStack_20,0xffffffff);
    .glue::SetGWorld(uStack_18,auStack_14[0]);
  }
  *(short *)(param_1 + 0x22) = *(short *)(param_1 + 0x22) + -1;
  .glue::OffsetRect(param_1 + 0x1a,0,1);
  return;
}


// ==== .Apply__27TScrollingCreditImageObjectFR9TWorkArea @ 1009e614 ====
// CyDecompAt: created, body 1009e614-1009e6cf

void _Apply__27TScrollingCreditImageObjectFR9TWorkArea(int param_1,int *param_2)

{
  int iVar1;
  int iVar2;
  undefined4 uVar3;
  undefined4 uStack_18;
  undefined4 uStack_14;
  undefined4 uStack_10;
  undefined4 uStack_c;
  
  uStack_10 = *(undefined4 *)(param_1 + 0x1a);
  uStack_c = *(undefined4 *)(param_1 + 0x1e);
  uStack_14 = *(undefined4 *)(param_1 + 0x1e);
  uVar3 = *(undefined4 *)(param_1 + 0x1a);
  uStack_18._0_2_ = (short)((uint)uVar3 >> 0x10);
  iVar1 = (int)uStack_18._0_2_;
  uStack_18._2_2_ = (short)uVar3;
  iVar2 = (int)uStack_18._2_2_;
  uStack_18 = uVar3;
  .glue::OffsetRect(&uStack_18,
                    ((int)*(short *)(param_1 + 6) + (int)*(short *)((int)param_2 + 6)) - iVar2,
                    ((int)*(short *)(param_1 + 4) + (int)*(short *)(param_2 + 1)) - iVar1);
  .glue::CopyBits(*(int *)(param_1 + 0xc) + 2,*param_2 + 2,&uStack_10,&uStack_18,
                  (int)*(short *)(param_1 + 8),0);
  return;
}


// ==== .RenderNextLine__30TSTRScrollingCreditImageObjectFR4Rect @ 1009e7d0 ====
// CyDecompAt: created, body 1009e7d0-1009e93b

int _RenderNextLine__30TSTRScrollingCreditImageObjectFR4Rect(int param_1,short *param_2)

{
  uint uVar1;
  uint uVar2;
  int iVar3;
  short sVar4;
  int iVar5;
  char *pcVar6;
  byte bStack_118;
  char cStack_117;
  char acStack_116 [258];
  
  .glue::GetIndString(&bStack_118,(int)*(short *)(param_1 + 0x28),(int)*(short *)(param_1 + 0x2a));
  if (bStack_118 == 0) {
    *(undefined2 *)(param_1 + 0x2a) = 1;
    .glue::GetIndString(&bStack_118,(int)*(short *)(param_1 + 0x28),(int)*(short *)(param_1 + 0x2a))
    ;
  }
  *(short *)(param_1 + 0x2a) = *(short *)(param_1 + 0x2a) + 1;
  uVar1 = (int)param_2[1] + (int)param_2[3];
  .glue::MoveTo((int)(short)((short)((int)uVar1 >> 1) + (ushort)((int)uVar1 < 0 && (uVar1 & 1) != 0)
                            ),*param_2 + 0xe);
  pcVar6 = &cStack_117;
  iVar5 = (int)*(short *)(param_1 + 0x24);
  uVar1 = (uint)bStack_118;
  if (cStack_117 == '-') {
    iVar5 = 6;
  }
  else {
    if (cStack_117 == -0x5b) {
      pcVar6 = acStack_116;
      uVar1 = uVar1 - 1;
      .glue::ForeColor(0x111);
      iVar3 = .glue::TextWidth(pcVar6,0,uVar1);
      .glue::Move(-iVar3,6);
    }
    else {
      .glue::ForeColor(0x45);
      sVar4 = .glue::TextWidth(pcVar6,0,uVar1);
      uVar2 = -(int)sVar4;
      .glue::Move((int)(short)((short)((int)uVar2 >> 1) +
                              (ushort)((int)uVar2 < 0 && (uVar2 & 1) != 0)),0);
    }
    .glue::DrawText(pcVar6,0,uVar1);
    .glue::ForeColor(0x21);
  }
  return iVar5;
}


// ==== .LDEFDraw__13TPortraitListFUcP4Rect5Pointss @ 100a06f8 ====
// CyDecompAt: created, body 100a06f8-100a0893

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _LDEFDraw__13TPortraitListFUcP4Rect5Pointss
               (undefined4 param_1,undefined4 param_2,short *param_3,undefined4 param_4)

{
  int iVar1;
  undefined1 auStack_58 [6];
  undefined1 auStack_52 [10];
  undefined *puStack_48;
  undefined2 uStack_44;
  undefined2 uStack_42;
  undefined2 uStack_40;
  undefined2 uStack_3e;
  undefined2 uStack_3c;
  undefined2 uStack_3a;
  undefined4 uStack_38;
  undefined4 uStack_34;
  undefined4 uStack_30;
  undefined4 uStack_2c;
  undefined4 uStack_28;
  undefined4 uStack_24;
  undefined4 uStack_20;
  undefined4 uStack_1c;
  undefined2 uStack_18;
  
  puStack_48 = _DAT_100d3de4;
  uStack_44 = (undefined2)((uint)uRam100d3de8 >> 0x10);
  uStack_42 = (undefined2)uRam100d3de8;
  uStack_40 = (undefined2)((uint)uRam100d3dec >> 0x10);
  uStack_3e = (undefined2)uRam100d3dec;
  uStack_3c = (undefined2)((uint)uRam100d3df0 >> 0x10);
  uStack_3a = (undefined2)uRam100d3df0;
  uStack_38 = uRam100d3df4;
  uStack_34 = uRam100d3df8;
  uStack_30 = uRam100d3dfc;
  uStack_2c = uRam100d3e00;
  uStack_28 = uRam100d3e04;
  uStack_24 = uRam100d3e08;
  uStack_20 = uRam100d3e0c;
  uStack_1c = uRam100d3e10;
  uStack_18 = uRam100d3e14;
  .glue::SetRect(auStack_52,0,0,0x40,0x40);
  uStack_42 = SUB42(auStack_52._0_4_,2);
  uStack_40 = (undefined2)auStack_52._0_4_;
  uStack_3e = SUB42(auStack_52._4_4_,2);
  uStack_3c = (undefined2)auStack_52._4_4_;
  uStack_44 = 0x8040;
  .glue::OffsetRect(auStack_52,(int)param_3[1],(int)*param_3);
  iVar1 = .debug::_GetSegment__15TCachedSegFilesFUs
                    (*_DAT_100cdbc4,
                     (int)(short)((uint)param_4 >> 0x10) + (short)param_4 * 6 + 0x88ef);
  if (iVar1 == 0) {
    .glue::EraseRect(auStack_52);
  }
  else {
    FUN_1007573c(iVar1,PTR_DAT_100cef68);
    puStack_48 = PTR_DAT_100cef68;
    .glue::EraseRect(auStack_52);
    .glue::GetBackColor(auStack_58);
    .glue::RGBBackColor(auStack_58);
    .glue::RGBBackColor(auStack_58);
    .glue::CopyBits(&puStack_48,*(int *)(PTR_DAT_100cdb94 + 0xca) + 2,&uStack_42,auStack_52,0x24,0);
  }
  return;
}


// ==== .LDEFHilite__13TPortraitListFUcP4Rect5Pointss @ 100a08d4 ====
// CyDecompAt: created, body 100a08d4-100a08d7

void _LDEFHilite__13TPortraitListFUcP4Rect5Pointss(void)

{
  return;
}


// ==== .LDEFDraw__14TArchetypeListFUcP4Rect5Pointss @ 100a09e0 ====
// CyDecompAt: created, body 100a09e0-100a0a57

void _LDEFDraw__14TArchetypeListFUcP4Rect5Pointss
               (undefined4 param_1,undefined1 param_2,undefined4 param_3,undefined4 param_4,
               short param_5,short param_6)

{
  .glue::BackPat(PTR_DAT_100cdb94 + 0xc2);
  .debug::_LDEFDraw__8TListBoxFUcP4Rect5Pointss
            (param_1,param_2,param_3,param_4,(int)param_5,(int)param_6);
  .debug::_SetTilePat__Fs(0x1a4);
  .glue::BackPixPat();
  return;
}


// ==== .DrawRoutine__19TCreatePlayerDialogFv @ 100a114c ====
// CyDecompAt: created, body 100a114c-100a119f

void _DrawRoutine__19TCreatePlayerDialogFv(int param_1)

{
  undefined4 uVar1;
  
  uVar1 = .debug::_SetTilePat__Fs(0x1a4);
  .glue::FillCRect(*(int *)(param_1 + 4) + 0x10,uVar1);
  .debug::_DrawRoutine__7TDialogFv(param_1);
  return;
}


// ==== .__dt__19TCreatePlayerDialogFv @ 100a11d8 ====
// CyDecompAt: created, body 100a11d8-100a12d3

undefined4 * ___dt__19TCreatePlayerDialogFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d79e8;
    if (param_1[5] != 0) {
      FUN_100c50e8(param_1[5],1);
    }
    if (param_1[1] != 0) {
      .glue::DisposeDialog(param_1[1]);
    }
    if (param_1[7] != 0) {
      .glue::DisposeHandle(param_1[7]);
    }
    if (param_1[8] != 0) {
      .glue::DisposeHandle(param_1[8]);
    }
    if (param_1[9] != 0) {
      .glue::DisposeHandle(param_1[9]);
    }
    param_1[1] = 0;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d414c;
      .debug::___dt__7TWindowFv(param_1,0);
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__13TPortraitListFv @ 100a1304 ====
// CyDecompAt: created, body 100a1304-100a1367

undefined4 * ___dt__13TPortraitListFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d7b24;
    .debug::___dt__8TListBoxFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .DialogItemRoutine__19TCreatePlayerDialogFs @ 100a140c ====
// CyDecompAt: created, body 100a140c-100a15d7

void _DialogItemRoutine__19TCreatePlayerDialogFs(int param_1,short param_2)

{
  undefined *puVar1;
  undefined2 uVar2;
  undefined1 auStack_28 [8];
  undefined4 uStack_20;
  undefined1 auStack_1c [16];
  
  puVar1 = PTR_DAT_100cdb84;
  if (param_2 == 5) {
    if (*(short *)(param_1 + 0xe) == 0) {
      *(undefined2 *)(param_1 + 0xe) = 1;
      .glue::GetDialogItem(*(undefined4 *)(param_1 + 4),6,auStack_1c,&uStack_20,auStack_28);
      .glue::SetControlValue(uStack_20,0);
      .glue::GetDialogItem(*(undefined4 *)(param_1 + 4),5,auStack_1c,&uStack_20,auStack_28);
      .glue::SetControlValue(uStack_20,1);
      .glue::LScroll(0xffffffff,0,*(undefined4 *)(*(int *)(param_1 + 0x14) + 4));
    }
  }
  else if (param_2 < 5) {
    if (param_2 == 2) {
      *(undefined2 *)(param_1 + 0xc) = 0;
      *(undefined1 *)(*(int *)puVar1 + 0x1d) = 1;
    }
    else if ((param_2 < 2) && (0 < param_2)) {
      *(undefined2 *)(param_1 + 0xc) = 1;
      uVar2 = FUN_100c50e8();
      puVar1 = PTR_DAT_100cdb84;
      *(undefined2 *)(param_1 + 0x10) = uVar2;
      *(undefined1 *)(*(int *)puVar1 + 0x1d) = 1;
    }
  }
  else if ((param_2 < 7) && (*(short *)(param_1 + 0xe) == 1)) {
    *(undefined2 *)(param_1 + 0xe) = 0;
    .glue::GetDialogItem(*(undefined4 *)(param_1 + 4),5,auStack_1c,&uStack_20,auStack_28);
    .glue::SetControlValue(uStack_20,0);
    .glue::GetDialogItem(*(undefined4 *)(param_1 + 4),6,auStack_1c,&uStack_20,auStack_28);
    .glue::SetControlValue(uStack_20,1);
    .glue::LScroll(1,0,*(undefined4 *)(*(int *)(param_1 + 0x14) + 4));
  }
  return;
}


// ==== .DialogDrawRoutine__19TCreatePlayerDialogFs @ 100a1618 ====
// CyDecompAt: created, body 100a1618-100a16eb

void _DialogDrawRoutine__19TCreatePlayerDialogFs(int param_1,undefined4 param_2)

{
  short sVar1;
  undefined1 auStack_18 [8];
  undefined1 auStack_10 [4];
  undefined1 auStack_c [4];
  
  .glue::GetDialogItem(*(undefined4 *)(param_1 + 4),param_2,auStack_c,auStack_10,auStack_18);
  sVar1 = (short)param_2;
  if (sVar1 == 3) {
    FUN_100c50e8(*(undefined4 *)(param_1 + 0x14),*(undefined4 *)(*(int *)(param_1 + 4) + 0x18));
    .glue::FrameRect(auStack_18);
  }
  else if (sVar1 == 7) {
    FUN_100c50e8(*(undefined4 *)(param_1 + 0x18),*(undefined4 *)(*(int *)(param_1 + 4) + 0x18));
    .glue::FrameRect(auStack_18);
  }
  else if (sVar1 == 8) {
    .debug::_AdjustCurArch__19TCreatePlayerDialogFs(param_1,(int)*(short *)(param_1 + 0x10));
  }
  return;
}


// ==== .MouseRoutine__19TCreatePlayerDialogF5Points @ 100a172c ====
// CyDecompAt: created, body 100a172c-100a1883

void _MouseRoutine__19TCreatePlayerDialogF5Points(int param_1,undefined4 param_2,undefined4 param_3)

{
  char cVar4;
  short sVar2;
  short sVar3;
  undefined4 uVar1;
  undefined1 auStack_24 [8];
  undefined1 auStack_1c [4];
  undefined1 auStack_18 [12];
  
  .glue::GetDialogItem(*(undefined4 *)(param_1 + 4),7,auStack_18,auStack_1c,auStack_24);
  cVar4 = .glue::PtInRect(param_2,auStack_24);
  if (cVar4 == '\0') {
    .glue::GetDialogItem(*(undefined4 *)(param_1 + 4),3,auStack_18,auStack_1c,auStack_24);
    cVar4 = .glue::PtInRect(param_2,auStack_24);
    if (cVar4 == '\0') {
      .debug::_MouseRoutine__7TDialogF5Points(param_1,param_2,param_3);
    }
    else {
      FUN_100c50e8(*(undefined4 *)(param_1 + 0x14),param_2,param_3);
    }
  }
  else {
    sVar2 = FUN_100c50e8();
    FUN_100c50e8(*(undefined4 *)(param_1 + 0x18),param_2,param_3);
    sVar3 = FUN_100c50e8();
    if (sVar2 != sVar3) {
      uVar1 = FUN_100c50e8();
      .debug::_AdjustCurArch__19TCreatePlayerDialogFs(param_1,uVar1);
    }
  }
  return;
}


// ==== .__dt__16TImageCompositorFv @ 100a2028 ====
// CyDecompAt: created, body 100a2028-100a20c3

undefined4 * ___dt__16TImageCompositorFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d77d4;
    if (((param_1 != (undefined4 *)0xfffffff4) && (param_1 != (undefined4 *)0xfffffff4)) &&
       (param_1[5] != 0)) {
      FUN_100be848(param_1[5]);
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .KeyRoutine__13TApPrefWindowFs @ 100a3578 ====
// CyDecompAt: created, body 100a3578-100a36c3

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _KeyRoutine__13TApPrefWindowFs(undefined4 param_1,undefined4 param_2)

{
  char cVar1;
  short sVar2;
  
  sVar2 = (short)param_2;
  if (sVar2 == 0x1b) {
    FUN_100c50e8(param_1,&PTR_PTR_100d3d2c,0,0x63616e63,0);
  }
  else {
    if (sVar2 < 0x1b) {
      if ((sVar2 == 0xd) || ((sVar2 < 0xd && (sVar2 == 3)))) {
        FUN_100c50e8(param_1,&PTR_PTR_100d3d2c,0,0x73617665,0);
        return;
      }
    }
    else if ((sVar2 == 0x69) && (cVar1 = .debug::_HasISSupport__Fv(), cVar1 != '\0')) {
      FUN_100c50e8(param_1,&PTR_PTR_100d3d2c,0,0x69736366,0);
      return;
    }
    FUN_100c50e8(_DAT_100d940c,param_1,param_2);
  }
  return;
}


// ==== .HandleMessage__13TApPrefWindowF9TApWidgetls @ 100a36f4 ====
// CyDecompAt: created, body 100a36f4-100a3a5b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleMessage__13TApPrefWindowF9TApWidgetls
               (int param_1,undefined4 param_2,undefined4 param_3,int param_4,short param_5)

{
  undefined4 uVar1;
  short sVar2;
  
  uVar1 = _DAT_100cdd24;
  if (param_4 == 0x6d766f6c) {
    FUN_100c50e8(param_1 + 0x34,0);
    .debug::_AdjustSettings__13TApPrefWindowFRQ213TApPrefWindow13AudioSettings
              (param_1,param_1 + 0x7a);
    .debug::_ApplySettings__13TApPrefWindowFRQ213TApPrefWindow13AudioSettings
              (param_1,param_1 + 0x7a);
    return;
  }
  if (param_4 < 0x6d766f6c) {
    if (param_4 == 0x63616e63) {
      .debug::_ApplySettings__13TApPrefWindowFRQ213TApPrefWindow13AudioSettings
                (param_1,param_1 + 0x74);
      *(undefined1 *)(*(int *)PTR_DAT_100cdb84 + 0x1d) = 1;
      return;
    }
    if (param_4 < 0x63616e63) {
      if (param_4 == 0x616d6273) {
        .debug::_AdjustSettings__13TApPrefWindowFRQ213TApPrefWindow13AudioSettings
                  (param_1,param_1 + 0x7a);
        .debug::_ApplySettings__13TApPrefWindowFRQ213TApPrefWindow13AudioSettings
                  (param_1,param_1 + 0x7a);
        .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(uVar1,5);
        return;
      }
      if ((param_4 < 0x616d6273) && (param_4 == 0)) {
        .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(_DAT_100cdd24,5);
      }
    }
    else {
      if (param_4 == 0x6d6d7574) {
        .debug::_AdjustSettings__13TApPrefWindowFRQ213TApPrefWindow13AudioSettings
                  (param_1,param_1 + 0x7a);
        .debug::_ApplySettings__13TApPrefWindowFRQ213TApPrefWindow13AudioSettings
                  (param_1,param_1 + 0x7a);
        return;
      }
      if ((param_4 < 0x6d6d7574) && (param_4 == 0x69736366)) {
        .debug::_ConfigureIS__Fv();
        return;
      }
    }
  }
  else {
    if (param_4 == 0x73737973) {
      sVar2 = FUN_100c50e8(param_1 + 0x24);
      if (sVar2 == 0) {
        FUN_100c50e8(param_1 + 0x1c);
      }
      else {
        FUN_100c50e8(param_1 + 0x1c);
      }
      .debug::_AdjustSettings__13TApPrefWindowFRQ213TApPrefWindow13AudioSettings
                (param_1,param_1 + 0x7a);
      .debug::_ApplySettings__13TApPrefWindowFRQ213TApPrefWindow13AudioSettings
                (param_1,param_1 + 0x7a);
      .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(uVar1,5);
      return;
    }
    if (param_4 < 0x73737973) {
      if (param_4 == 0x736d7574) {
        sVar2 = FUN_100c50e8(param_1 + 0x1c);
        if (sVar2 == 0) {
          FUN_100c50e8(param_1 + 0x24);
        }
        else {
          FUN_100c50e8(param_1 + 0x24);
        }
        .debug::_AdjustSettings__13TApPrefWindowFRQ213TApPrefWindow13AudioSettings
                  (param_1,param_1 + 0x7a);
        .debug::_ApplySettings__13TApPrefWindowFRQ213TApPrefWindow13AudioSettings
                  (param_1,param_1 + 0x7a);
        .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(uVar1,5);
        return;
      }
      if ((param_4 < 0x736d7574) && (param_4 == 0x73617665)) {
        *(undefined1 *)(*(int *)PTR_DAT_100cdb84 + 0x1d) = 1;
        .debug::_SaveSettings__13TApPrefWindowFv(param_1);
        return;
      }
    }
    else if (param_4 == 0x73766f6c) {
      FUN_100c50e8(param_1 + 0x1c,0);
      FUN_100c50e8(param_1 + 0x1c);
      FUN_100c50e8(param_1 + 0x24,0);
      FUN_100c50e8(param_1 + 0x24);
      .debug::_AdjustSettings__13TApPrefWindowFRQ213TApPrefWindow13AudioSettings
                (param_1,param_1 + 0x7a);
      .debug::_ApplySettings__13TApPrefWindowFRQ213TApPrefWindow13AudioSettings
                (param_1,param_1 + 0x7a);
      .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(uVar1,5);
      return;
    }
  }
  .debug::_HandleMessage__9TApWindowF9TApWidgetls(param_1,param_2,param_3,param_4,(int)param_5);
  return;
}


// ==== .__dt__13TApPrefWindowFv @ 100a3d1c ====
// CyDecompAt: created, body 100a3d1c-100a3d7f

undefined4 * ___dt__13TApPrefWindowFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d7930;
    .debug::___dt__9TApWindowFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__14TArchetypeListFv @ 100a3dac ====
// CyDecompAt: created, body 100a3dac-100a3e0f

undefined4 * ___dt__14TArchetypeListFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d7ab0;
    .debug::___dt__8TListBoxFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .RemoveConsole @ 100a3e68 ====
// CyDecompAt: created, body 100a3e68-100a3e6b

void _RemoveConsole(void)

{
  return;
}


// ==== .Create__11TBorderWDEFFP12WindowRecords @ 100a3f24 ====
// CyDecompAt: created, body 100a3f24-100a3f7b

int _Create__11TBorderWDEFFP12WindowRecords(undefined4 param_1,short param_2)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0xc);
  if (iVar1 != 0) {
    .debug::___ct__11TBorderWDEFFP12WindowRecords(iVar1,param_1,(int)param_2);
  }
  return iVar1;
}


// ==== .DrawUnhilited__11TBorderWDEFFs @ 100a403c ====
// CyDecompAt: created, body 100a403c-100a418f

void _DrawUnhilited__11TBorderWDEFFs(int param_1,short param_2)

{
  short sVar1;
  char cVar2;
  int iVar3;
  undefined4 uVar4;
  undefined4 uStack_20;
  undefined4 uStack_1c;
  
  iVar3 = **(int **)(*(int *)(param_1 + 4) + 0x72);
  uStack_20 = *(undefined4 *)(iVar3 + 2);
  uStack_1c = *(undefined4 *)(iVar3 + 6);
  if (*(char *)(*(int *)(param_1 + 4) + 0x70) == '\0') {
    sVar1 = 0;
  }
  else {
    sVar1 = 2;
  }
  iVar3 = (int)sVar1;
  if (param_2 == 4) {
    iVar3 = iVar3 + 4;
  }
  else if ((param_2 < 4) && (param_2 == 1)) {
    iVar3 = iVar3 + 1;
  }
  if (((param_2 == 1) || (*(int *)(*(int *)(param_1 + 4) + 0x86) == 0)) ||
     (**(int **)(*(int *)(param_1 + 4) + 0x86) == 0)) {
    .debug::_FrameBox__FR4RectsPUc(&uStack_20,iVar3,0);
  }
  else {
    uVar4 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x86);
    cVar2 = .glue::HGetState(uVar4);
    .glue::HLock(uVar4);
    .debug::_FrameBox__FR4RectsPUc(&uStack_20,iVar3,**(undefined4 **)(*(int *)(param_1 + 4) + 0x86))
    ;
    .glue::HSetState(uVar4,(int)cVar2);
  }
  .debug::_TryDrawContent__FP12WindowRecord(*(undefined4 *)(param_1 + 4));
  return;
}


// ==== .HiliteCloseBox__11TBorderWDEFFsUc @ 100a41c4 ====
// CyDecompAt: created, body 100a41c4-100a4217

void _HiliteCloseBox__11TBorderWDEFFsUc(int param_1,undefined4 param_2,undefined1 param_3)

{
  int iVar1;
  undefined4 uStack_8;
  undefined4 uStack_4;
  
  iVar1 = **(int **)(*(int *)(param_1 + 4) + 0x72);
  uStack_8 = *(undefined4 *)(iVar1 + 2);
  uStack_4 = *(undefined4 *)(iVar1 + 6);
  .debug::_HiliteGoAwayFrame__FR4RectUc(&uStack_8,param_3);
  return;
}


// ==== .DrawHilited__11TBorderWDEFFsUcUc @ 100a424c ====
// CyDecompAt: created, body 100a424c-100a4287

void _DrawHilited__11TBorderWDEFFsUcUc(undefined4 param_1,short param_2)

{
  FUN_100c50e8(param_1,(int)param_2);
  return;
}


// ==== .Grow__11TBorderWDEFFsP4Rect @ 100a42bc ====
// CyDecompAt: created, body 100a42bc-100a43cf

void _Grow__11TBorderWDEFFsP4Rect(undefined4 param_1,undefined4 param_2,undefined4 *param_3)

{
  int iVar1;
  uint uVar2;
  char cVar3;
  undefined4 uVar4;
  undefined4 uStack_18;
  undefined4 uStack_14;
  
  uVar4 = *param_3;
  uStack_14._2_2_ = (short)param_3[1];
  uStack_18._2_2_ = (short)uVar4;
  uStack_18._0_2_ = (short)((uint)uVar4 >> 0x10);
  uStack_14._0_2_ = (short)((uint)param_3[1] >> 0x10);
  uStack_14._2_2_ = uStack_14._2_2_ - uStack_18._2_2_;
  if ((int)uStack_14._0_2_ - (int)uStack_18._0_2_ < (int)uStack_14._2_2_) {
    uStack_14._2_2_ = uStack_14._0_2_ - uStack_18._0_2_;
  }
  uVar2 = (int)uStack_14._2_2_ + 0x20;
  iVar1 = (((int)uVar2 >> 6) + (uint)((int)uVar2 < 0 && (uVar2 & 0x3f) != 0)) * 2;
  uVar2 = iVar1 + 1;
  if ((uVar2 & 1) == 0) {
    uVar2 = iVar1 + 2;
  }
  uStack_14 = CONCAT22(uStack_18._0_2_ + (short)(uVar2 << 5) + -0x20,
                       uStack_18._2_2_ + (short)(uVar2 << 5) + -0x20);
  uStack_18 = uVar4;
  cVar3 = .glue::StillDown();
  if (cVar3 == '\0') {
    *param_3 = uStack_18;
    param_3[1] = uStack_14;
  }
  .glue::FrameRect(&uStack_18);
  .glue::InsetRect(&uStack_18,0xfffffff0,0xfffffff0);
  .glue::FrameRect(&uStack_18);
  return;
}


// ==== .Test__11TBorderWDEFFs5Point @ 100a4400 ====
// CyDecompAt: created, body 100a4400-100a4523

undefined4 _Test__11TBorderWDEFFs5Point(int param_1,short param_2,undefined4 param_3)

{
  char cVar2;
  undefined4 uVar1;
  short sStack_18;
  short sStack_16;
  undefined4 uStack_14;
  undefined4 uStack_10;
  short sStack_c;
  short sStack_a;
  
  cVar2 = .glue::PtInRgn(param_3,*(undefined4 *)(*(int *)(param_1 + 4) + 0x76));
  if (cVar2 == '\0') {
    if (*(char *)(*(int *)(param_1 + 4) + 0x70) != '\0') {
      uVar1 = *(undefined4 *)(**(int **)(*(int *)(param_1 + 4) + 0x72) + 2);
      uStack_10._2_2_ = (short)uVar1;
      uStack_10._0_2_ = (short)((uint)uVar1 >> 0x10);
      _sStack_c = CONCAT22(uStack_10._0_2_ + 0x10,uStack_10._2_2_ + 0x10);
      uStack_10 = uVar1;
      cVar2 = .glue::PtInRect(param_3,&uStack_10);
      if (cVar2 != '\0') {
        return 4;
      }
    }
    if (param_2 == 4) {
      uVar1 = *(undefined4 *)(**(int **)(*(int *)(param_1 + 4) + 0x72) + 6);
      uStack_14._2_2_ = (short)uVar1;
      uStack_14._0_2_ = (short)((uint)uVar1 >> 0x10);
      _sStack_18 = CONCAT22(uStack_14._0_2_ + -0x10,uStack_14._2_2_ + -0x10);
      uStack_14 = uVar1;
      cVar2 = .glue::PtInRect(param_3,&sStack_18);
      if (cVar2 != '\0') {
        return 3;
      }
    }
    uVar1 = 2;
  }
  else {
    uVar1 = 1;
  }
  return uVar1;
}


// ==== .CalcRegions__11TBorderWDEFFsR4Rect @ 100a4554 ====
// CyDecompAt: created, body 100a4554-100a45d3

void _CalcRegions__11TBorderWDEFFsR4Rect(int param_1,undefined4 param_2,undefined4 *param_3)

{
  undefined4 uStack_18;
  undefined4 uStack_14;
  
  .glue::RectRgn(*(undefined4 *)(*(int *)(param_1 + 4) + 0x76),param_3);
  uStack_18 = *param_3;
  uStack_14 = param_3[1];
  .glue::InsetRect(&uStack_18,0xfffffff0,0xfffffff0);
  .glue::RectRgn(*(undefined4 *)(*(int *)(param_1 + 4) + 0x72),&uStack_18);
  return;
}


// ==== .Create__15TThinBorderWDEFFP12WindowRecords @ 100a460c ====
// CyDecompAt: created, body 100a460c-100a4663

int _Create__15TThinBorderWDEFFP12WindowRecords(undefined4 param_1,short param_2)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0xc);
  if (iVar1 != 0) {
    .debug::___ct__15TThinBorderWDEFFP12WindowRecords(iVar1,param_1,(int)param_2);
  }
  return iVar1;
}


// ==== .DrawUnhilited__15TThinBorderWDEFFs @ 100a472c ====
// CyDecompAt: created, body 100a472c-100a478b

void _DrawUnhilited__15TThinBorderWDEFFs(int param_1)

{
  int iVar1;
  undefined4 uStack_18;
  undefined4 uStack_14;
  
  iVar1 = **(int **)(*(int *)(param_1 + 4) + 0x72);
  uStack_18 = *(undefined4 *)(iVar1 + 2);
  uStack_14 = *(undefined4 *)(iVar1 + 6);
  .debug::_FrameBox__FR4RectsPUc(&uStack_18,8,0);
  .debug::_TryDrawContent__FP12WindowRecord(*(undefined4 *)(param_1 + 4));
  return;
}


// ==== .DrawHilited__15TThinBorderWDEFFsUcUc @ 100a47c4 ====
// CyDecompAt: created, body 100a47c4-100a47ff

void _DrawHilited__15TThinBorderWDEFFsUcUc(undefined4 param_1,short param_2)

{
  FUN_100c50e8(param_1,(int)param_2);
  return;
}


// ==== .Test__15TThinBorderWDEFFs5Point @ 100a4838 ====
// CyDecompAt: created, body 100a4838-100a4887

bool _Test__15TThinBorderWDEFFs5Point(int param_1,undefined4 param_2,undefined4 param_3)

{
  char cVar1;
  
  cVar1 = .glue::PtInRgn(param_3,*(undefined4 *)(*(int *)(param_1 + 4) + 0x76));
  return cVar1 != '\0';
}


// ==== .CalcRegions__15TThinBorderWDEFFsR4Rect @ 100a48bc ====
// CyDecompAt: created, body 100a48bc-100a493b

void _CalcRegions__15TThinBorderWDEFFsR4Rect(int param_1,undefined4 param_2,undefined4 *param_3)

{
  undefined4 uStack_18;
  undefined4 uStack_14;
  
  .glue::RectRgn(*(undefined4 *)(*(int *)(param_1 + 4) + 0x76),param_3);
  uStack_18 = *param_3;
  uStack_14 = param_3[1];
  .glue::InsetRect(&uStack_18,0xfffffff8,0xfffffffc);
  .glue::RectRgn(*(undefined4 *)(*(int *)(param_1 + 4) + 0x72),&uStack_18);
  return;
}


// ==== .Create__9TPixsWDEFFP12WindowRecords @ 100a4978 ====
// CyDecompAt: created, body 100a4978-100a49cf

int _Create__9TPixsWDEFFP12WindowRecords(undefined4 param_1,short param_2)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x4c);
  if (iVar1 != 0) {
    .debug::___ct__9TPixsWDEFFP12WindowRecords(iVar1,param_1,(int)param_2);
  }
  return iVar1;
}


// ==== .__dt__9TPixsWDEFFv @ 100a4a08 ====
// CyDecompAt: created, body 100a4a08-100a4a97

undefined4 * ___dt__9TPixsWDEFFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d8004;
    if (*(short *)(param_1 + 0x12) != 0) {
      .debug::_ReleasePix__13TPixCacheBaseFs
                (*(undefined4 *)PTR_DAT_100cdec0,(int)*(short *)(param_1 + 0x12));
    }
    .glue::DisposeRgn(param_1[0x10]);
    .debug::___dt__5TWDEFFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .HiliteCloseBox__9TPixsWDEFFsUc @ 100a4c30 ====
// CyDecompAt: created, body 100a4c30-100a4d97

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HiliteCloseBox__9TPixsWDEFFsUc(int param_1,undefined4 param_2,char param_3)

{
  undefined4 uVar1;
  uint uVar2;
  undefined4 uVar3;
  int iVar4;
  int iVar5;
  int iStack_58;
  undefined4 uStack_54;
  undefined4 uStack_50;
  undefined4 uStack_4c;
  undefined4 uStack_48;
  int iStack_44;
  undefined4 uStack_40;
  undefined4 uStack_3c;
  undefined4 uStack_38;
  undefined4 uStack_34;
  undefined4 uStack_30;
  undefined4 uStack_2c;
  undefined4 uStack_28;
  undefined4 uStack_24;
  undefined4 uStack_20;
  undefined4 uStack_1c;
  undefined4 uStack_18;
  undefined2 uStack_14;
  undefined4 uStack_12;
  undefined4 uStack_e;
  
  iVar4 = **(int **)(*(int *)(param_1 + 4) + 0x72);
  uVar3 = *(undefined4 *)(iVar4 + 2);
  uVar1 = *(undefined4 *)(iVar4 + 6);
  uStack_12._0_2_ = (short)((uint)uVar3 >> 0x10);
  iVar5 = (int)uStack_12._0_2_;
  uStack_40 = uRam100d3de8;
  uStack_3c = uRam100d3dec;
  uStack_38 = uRam100d3df0;
  uStack_34 = uRam100d3df4;
  uStack_30 = uRam100d3df8;
  uStack_2c = uRam100d3dfc;
  uStack_28 = uRam100d3e00;
  uStack_24 = uRam100d3e04;
  uStack_20 = uRam100d3e08;
  uStack_1c = uRam100d3e0c;
  uStack_18 = uRam100d3e10;
  uStack_14 = uRam100d3e14;
  uStack_4c = _DAT_100d7b7c;
  uStack_48 = uRam100d7b80;
  uStack_54 = _DAT_100d7b7c;
  uStack_50 = uRam100d7b80;
  iStack_44 = *(int *)PTR_DAT_100cdc64 + 0x6bc00;
  uStack_e._0_2_ = (short)((uint)uVar1 >> 0x10);
  uStack_12._2_2_ = (short)uVar3;
  iVar4 = (int)uStack_12._2_2_;
  uVar2 = (int)uStack_e._0_2_ - (int)uStack_12._0_2_;
  uStack_12 = uVar3;
  uStack_e = uVar1;
  .glue::OffsetRect(&uStack_54,iVar4,
                    iVar5 + ((int)uVar2 >> 2) + (uint)((int)uVar2 < 0 && (uVar2 & 3) != 0) + -4);
  if (param_3 != '\0') {
    .glue::OffsetRect(&uStack_4c,0,0x10);
  }
  .glue::GetPort(&iStack_58);
  .glue::CopyBits(&iStack_44,iStack_58 + 2,&uStack_4c,&uStack_54,0,0);
  return;
}


// ==== .DrawUnhilited__9TPixsWDEFFs @ 100a4dcc ====
// CyDecompAt: created, body 100a4dcc-100a51b7

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DrawUnhilited__9TPixsWDEFFs(int param_1,short param_2)

{
  uint uVar1;
  short sVar2;
  undefined4 uVar3;
  int iVar4;
  int iVar5;
  int iStack_78;
  int iStack_74;
  int iStack_70;
  int iStack_6c;
  undefined4 uStack_68;
  undefined2 uStack_64;
  short sStack_62;
  undefined4 uStack_60;
  undefined2 uStack_5c;
  short sStack_5a;
  int iStack_58;
  undefined4 uStack_54;
  undefined4 uStack_50;
  undefined4 uStack_4c;
  undefined4 uStack_48;
  undefined4 uStack_44;
  undefined4 uStack_40;
  undefined4 uStack_3c;
  undefined4 uStack_38;
  undefined4 uStack_34;
  undefined4 uStack_30;
  undefined4 uStack_2c;
  undefined2 uStack_28;
  undefined4 uStack_26;
  undefined4 uStack_22;
  
  if (param_2 == 0) {
    .debug::_LoadPix__13TPixCacheBaseFR6PixMaps
              (*(undefined4 *)PTR_DAT_100cdec0,param_1 + 0xc,(int)*(short *)(param_1 + 0x48));
  }
  if (*(int *)(param_1 + 0xc) != 0) {
    iVar4 = **(int **)(*(int *)(param_1 + 4) + 0x72);
    uVar3 = *(undefined4 *)(iVar4 + 2);
    uStack_22 = *(undefined4 *)(iVar4 + 6);
    if (*(char *)(*(int *)(param_1 + 4) + 0x70) != '\0') {
      uStack_26._0_2_ = (short)((uint)uVar3 >> 0x10);
      uStack_22._0_2_ = (short)((uint)uStack_22 >> 0x10);
      uStack_26._2_2_ = (short)uVar3;
      iVar5 = (int)uStack_26._2_2_;
      uVar1 = (int)uStack_22._0_2_ - (int)uStack_26._0_2_;
      iVar4 = (int)uStack_26._0_2_;
      uStack_26 = uVar3;
      .glue::OffsetRgn(*(undefined4 *)(param_1 + 0x40),
                       iVar5 - *(short *)(**(int **)(param_1 + 0x40) + 4),
                       iVar4 + ((((int)uVar1 >> 2) + (uint)((int)uVar1 < 0 && (uVar1 & 3) != 0) + -4
                                ) - (int)*(short *)(**(int **)(param_1 + 0x40) + 2)));
      uStack_54 = uRam100d3de8;
      uStack_50 = uRam100d3dec;
      uStack_4c = uRam100d3df0;
      uStack_44 = uRam100d3df8;
      uStack_48 = uRam100d3df4;
      uStack_3c = uRam100d3e00;
      uStack_40 = uRam100d3dfc;
      uStack_34 = uRam100d3e08;
      uStack_38 = uRam100d3e04;
      uStack_2c = uRam100d3e10;
      uStack_30 = uRam100d3e0c;
      uStack_28 = uRam100d3e14;
      uStack_68 = _DAT_100d7b84;
      uStack_5c = 0x10;
      sStack_5a = 0x10;
      iStack_58 = *(int *)PTR_DAT_100cdc64 + 0x6bc00;
      sStack_62 = 0x10;
      uStack_64 = 0x10;
      uVar1 = (int)uStack_22._0_2_ - (int)uStack_26._0_2_;
      uStack_60 = uStack_68;
      .glue::OffsetRect(&uStack_68,(int)uStack_26._2_2_,
                        (int)uStack_26._0_2_ +
                        ((int)uVar1 >> 2) + (uint)((int)uVar1 < 0 && (uVar1 & 3) != 0) + -4);
      uVar1 = (int)uStack_26._2_2_ + (int)uStack_22._2_2_ + 0x10;
      sVar2 = (short)((int)uVar1 >> 1) + (ushort)((int)uVar1 < 0 && (uVar1 & 1) != 0);
      if ((int)sVar2 < uStack_68._2_2_ + 0x20) {
        sVar2 = uStack_68._2_2_ + 0x20;
      }
      .glue::GetPort(&iStack_6c);
      .glue::CopyBits(&iStack_58,iStack_6c + 2,&uStack_60,&uStack_68,0,0);
      .glue::OffsetRect(&uStack_60,0x10,0);
      _uStack_5c = CONCAT22(uStack_5c,uStack_60._2_2_ + 8);
      .glue::OffsetRect(&uStack_68,0x10,0);
      sStack_62 = uStack_68._2_2_ + 8;
      while (sStack_62 < sVar2) {
        .glue::GetPort(&iStack_70);
        .glue::CopyBits(&iStack_58,iStack_70 + 2,&uStack_60,&uStack_68,0,
                        *(undefined4 *)(param_1 + 0x40));
        .glue::OffsetRect(&uStack_68,8,0);
      }
      .glue::OffsetRect(&uStack_60,8,0);
      _uStack_64 = CONCAT22(uStack_64,sVar2);
      uStack_68 = CONCAT22(uStack_68._0_2_,sVar2 + -8);
      .glue::GetPort(&iStack_74);
      .glue::CopyBits(&iStack_58,iStack_74 + 2,&uStack_60,&uStack_68,0,
                      *(undefined4 *)(param_1 + 0x40));
    }
    uStack_26 = CONCAT22(uStack_22._0_2_ - (*(short *)(param_1 + 0x16) - *(short *)(param_1 + 0x12))
                         ,uStack_22._2_2_ -
                          (*(short *)(param_1 + 0x18) - *(short *)(param_1 + 0x14)));
    uVar3 = .glue::NewRgn();
    .glue::DiffRgn(*(undefined4 *)(*(int *)(param_1 + 4) + 0x72),
                   *(undefined4 *)(*(int *)(param_1 + 4) + 0x76),uVar3);
    .glue::DiffRgn(uVar3,*(undefined4 *)(param_1 + 0x40),uVar3);
    .glue::GetPort(&iStack_78);
    .glue::CopyBits(param_1 + 0xc,iStack_78 + 2,param_1 + 0x12,&uStack_26,0,uVar3);
    .glue::DisposeRgn(uVar3);
  }
  .debug::_TryDrawContent__FP12WindowRecord(*(undefined4 *)(param_1 + 4));
  return;
}


// ==== .DrawHilited__9TPixsWDEFFsUcUc @ 100a5344 ====
// CyDecompAt: created, body 100a5344-100a537f

void _DrawHilited__9TPixsWDEFFsUcUc(undefined4 param_1,short param_2)

{
  FUN_100c50e8(param_1,(int)param_2);
  return;
}


// ==== .Test__9TPixsWDEFFs5Point @ 100a53b0 ====
// CyDecompAt: created, body 100a53b0-100a548f

undefined4 _Test__9TPixsWDEFFs5Point(int param_1,undefined4 param_2,undefined4 param_3)

{
  uint uVar1;
  char cVar3;
  undefined4 uVar2;
  int iVar4;
  short sStack_18;
  short sStack_16;
  short sStack_14;
  short sStack_12;
  
  cVar3 = .glue::PtInRgn(param_3,*(undefined4 *)(*(int *)(param_1 + 4) + 0x76));
  if (cVar3 == '\0') {
    if (*(char *)(*(int *)(param_1 + 4) + 0x70) != '\0') {
      iVar4 = **(int **)(*(int *)(param_1 + 4) + 0x72);
      uVar2 = *(undefined4 *)(iVar4 + 2);
      sStack_16 = (short)uVar2;
      sStack_14 = (short)((uint)*(undefined4 *)(iVar4 + 6) >> 0x10);
      sStack_18 = (short)((uint)uVar2 >> 0x10);
      uVar1 = (int)sStack_14 - (int)sStack_18;
      sStack_18 = sStack_18 +
                  (short)((int)uVar1 >> 2) + (ushort)((int)uVar1 < 0 && (uVar1 & 3) != 0) + -4;
      _sStack_14 = CONCAT22(sStack_18 + 0x10,sStack_16 + 0x10);
      cVar3 = .glue::PtInRect(param_3,&sStack_18);
      if (cVar3 != '\0') {
        return 4;
      }
    }
    uVar2 = 2;
  }
  else {
    uVar2 = 1;
  }
  return uVar2;
}


// ==== .CalcRegions__9TPixsWDEFFsR4Rect @ 100a54bc ====
// CyDecompAt: created, body 100a54bc-100a56b7

void _CalcRegions__9TPixsWDEFFsR4Rect(int param_1,short param_2,short *param_3)

{
  short sVar1;
  undefined4 uVar2;
  uint uVar3;
  short sVar4;
  int iVar5;
  undefined4 uVar6;
  undefined4 uStack_18;
  undefined4 uStack_14;
  short sStack_10;
  short sStack_e;
  short sStack_c;
  short sStack_a;
  
  .glue::RectRgn(*(undefined4 *)(*(int *)(param_1 + 4) + 0x76),param_3);
  if (param_2 == 0) {
    .debug::_LoadPix__13TPixCacheBaseFR6PixMaps
              (*(undefined4 *)PTR_DAT_100cdec0,param_1 + 0xc,(int)*(short *)(param_1 + 0x48));
  }
  if ((*(int *)(param_1 + 0xc) != 0) &&
     (sVar4 = .debug::_MyPMToRegion__FR6PixMapPP9MacRegion
                        (param_1 + 0xc,*(undefined4 *)(*(int *)(param_1 + 4) + 0x72)), sVar4 == 0))
  {
    .glue::OffsetRgn(*(undefined4 *)(*(int *)(param_1 + 4) + 0x72),
                     (int)param_3[1] - (int)*(short *)(param_1 + 0x44),
                     (int)*param_3 - (int)*(short *)(param_1 + 0x46));
    .glue::SectRgn(*(undefined4 *)(*(int *)(param_1 + 4) + 0x72),
                   *(undefined4 *)(*(int *)(param_1 + 4) + 0x76),
                   *(undefined4 *)(*(int *)(param_1 + 4) + 0x76));
    if (*(char *)(*(int *)(param_1 + 4) + 0x70) == '\0') {
      return;
    }
    iVar5 = **(int **)(*(int *)(param_1 + 4) + 0x72);
    uVar6 = *(undefined4 *)(iVar5 + 2);
    uVar2 = *(undefined4 *)(iVar5 + 6);
    sStack_c = (short)((uint)uVar2 >> 0x10);
    sStack_10 = (short)((uint)uVar6 >> 0x10);
    uVar3 = (int)sStack_c - (int)sStack_10;
    sStack_10 = sStack_10 +
                (short)((int)uVar3 >> 2) + (ushort)((int)uVar3 < 0 && (uVar3 & 3) != 0) + -4;
    sStack_e = (short)uVar6;
    sVar1 = sStack_e;
    sStack_a = (short)uVar2;
    uVar3 = (int)sStack_e + (int)sStack_a;
    sVar4 = (short)((int)uVar3 >> 1) + (ushort)((int)uVar3 < 0 && (uVar3 & 1) != 0);
    sStack_e = sStack_e + -0x10;
    if ((int)sVar4 < sStack_e + 0x20) {
      sVar4 = sVar1 + 0x10;
    }
    _sStack_c = CONCAT22(sStack_10 + 0x10,sVar4);
    .glue::RectRgn(*(undefined4 *)(param_1 + 0x40),&sStack_10);
    .glue::DiffRgn(*(undefined4 *)(param_1 + 0x40),*(undefined4 *)(*(int *)(param_1 + 4) + 0x72),
                   *(undefined4 *)(param_1 + 0x40));
    .glue::UnionRgn(*(undefined4 *)(param_1 + 0x40),*(undefined4 *)(*(int *)(param_1 + 4) + 0x72),
                    *(undefined4 *)(*(int *)(param_1 + 4) + 0x72));
    return;
  }
  uStack_18 = *(undefined4 *)param_3;
  uStack_14 = *(undefined4 *)(param_3 + 2);
  .glue::RectRgn(*(undefined4 *)(*(int *)(param_1 + 4) + 0x72),&uStack_18);
  return;
}


// ==== .Create__11TDrawerWDEFFP12WindowRecords @ 100a56ec ====
// CyDecompAt: created, body 100a56ec-100a5743

int _Create__11TDrawerWDEFFP12WindowRecords(undefined4 param_1,short param_2)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(0x10);
  if (iVar1 != 0) {
    .debug::___ct__11TDrawerWDEFFP12WindowRecords(iVar1,param_1,(int)param_2);
  }
  return iVar1;
}


// ==== .DrawUnhilited__11TDrawerWDEFFs @ 100a5814 ====
// CyDecompAt: created, body 100a5814-100a5a37

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DrawUnhilited__11TDrawerWDEFFs(int param_1)

{
  uint uVar1;
  char cVar4;
  short sVar3;
  uint uVar2;
  int iVar5;
  uint uVar6;
  short sVar7;
  undefined1 *puVar8;
  undefined4 uVar9;
  int iStack_48;
  undefined2 uStack_44;
  short sStack_42;
  short sStack_40;
  short sStack_3e;
  undefined4 uStack_3c;
  short sStack_38;
  short sStack_34;
  ushort uStack_32;
  short sStack_30;
  undefined4 uStack_2e;
  undefined4 uStack_2a;
  
  iVar5 = **(int **)(*(int *)(param_1 + 4) + 0x72);
  uStack_2e = *(undefined4 *)(iVar5 + 2);
  uStack_2a = *(undefined4 *)(iVar5 + 6);
  .glue::FrameRect(&uStack_2e);
  uStack_2a._0_2_ = uStack_2e._0_2_ + 0x12;
  .glue::FrameRect(&uStack_2e);
  .glue::InsetRect(&uStack_2e,1,1);
  .debug::_ExpandHorizontally__FR4RectsUc(&uStack_2e,0x19c,1);
  .glue::GetPort(&iStack_48);
  sStack_34 = *(short *)(iStack_48 + 0x44);
  uStack_32 = (ushort)*(byte *)(iStack_48 + 0x46);
  sStack_30 = *(short *)(iStack_48 + 0x4a);
  .debug::_SetText__Fs(0);
  uVar9 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x86);
  uStack_3c = uVar9;
  cVar4 = .glue::HGetState(uVar9);
  sStack_38 = (short)cVar4;
  .glue::HLock(uVar9);
  sVar3 = .glue::StringWidth(**(undefined4 **)(*(int *)(param_1 + 4) + 0x86));
  uVar6 = ((int)uStack_2a._2_2_ + (int)uStack_2e._2_2_) - (int)sVar3;
  sVar7 = (short)((int)uVar6 >> 1) + (ushort)((int)uVar6 < 0 && (uVar6 & 1) != 0) + -8;
  _uStack_44 = CONCAT22((short)((uint)uStack_2e >> 0x10),sVar7);
  _sStack_40 = CONCAT22(uStack_2a._0_2_,sVar7 + sVar3 + 0x10);
  .debug::_ExpandHorizontally__FR4RectsUc(&uStack_44,0x19c,0);
  uVar6 = ((int)uStack_2a._2_2_ + (int)uStack_2e._2_2_) - (int)sVar3;
  uVar1 = (uint)*_DAT_100cdb90;
  uVar2 = (int)uStack_2a._0_2_ + (int)uStack_2e._0_2_;
  .glue::MoveTo((int)(short)((short)((int)uVar6 >> 1) + (ushort)((int)uVar6 < 0 && (uVar6 & 1) != 0)
                            ),
                (int)(short)((short)((int)uVar2 >> 1) + (ushort)((int)uVar2 < 0 && (uVar2 & 1) != 0)
                            ) + ((int)uVar1 >> 1) + (uint)((int)uVar1 < 0 && (uVar1 & 1) != 0));
  puVar8 = (undefined1 *)**(undefined4 **)(*(int *)(param_1 + 4) + 0x86);
  .debug::_AADrawText__FPcss(puVar8 + 1,0,*puVar8);
  .debug::_TryDrawContent__FP12WindowRecord(*(undefined4 *)(param_1 + 4));
  .glue::HSetState(uStack_3c,(int)(char)sStack_38);
  .glue::TextFont((int)sStack_34);
  .glue::TextFace((int)(short)uStack_32);
  .glue::TextSize((int)sStack_30);
  return;
}


// ==== .DrawHilited__11TDrawerWDEFFsUcUc @ 100a5a6c ====
// CyDecompAt: created, body 100a5a6c-100a5aa7

void _DrawHilited__11TDrawerWDEFFsUcUc(undefined4 param_1,short param_2)

{
  FUN_100c50e8(param_1,(int)param_2);
  return;
}


// ==== .Grow__11TDrawerWDEFFsP4Rect @ 100a5adc ====
// CyDecompAt: created, body 100a5adc-100a5cbf

void _Grow__11TDrawerWDEFFsP4Rect(int param_1,undefined4 param_2,undefined4 *param_3)

{
  uint uVar1;
  char cVar2;
  int iVar3;
  short sVar4;
  undefined4 uStack_18;
  undefined4 uStack_14;
  
  uStack_14._0_2_ = (short)((uint)param_3[1] >> 0x10);
  uStack_18._0_2_ = (short)((uint)*param_3 >> 0x10);
  uStack_14._0_2_ = uStack_14._0_2_ - uStack_18._0_2_;
  if (uStack_14._0_2_ < 1) {
    sVar4 = 0;
  }
  else if (*(short *)(param_1 + 0xc) < uStack_14._0_2_) {
    uVar1 = (uint)*(short *)(param_1 + 0xe);
    sVar4 = *(short *)(param_1 + 0xc) +
            *(short *)(param_1 + 0xe) *
            (short)((int)(((int)uVar1 >> 1) + (uint)((int)uVar1 < 0 && (uVar1 & 1) != 0) +
                         ((int)uStack_14._0_2_ - (int)*(short *)(param_1 + 0xc))) /
                   (int)*(short *)(param_1 + 0xe));
  }
  else {
    sVar4 = *(short *)(param_1 + 0xc);
  }
  iVar3 = **(int **)(*(int *)(param_1 + 4) + 0x76);
  uStack_18 = *(uint *)(iVar3 + 2);
  uStack_14 = *(undefined4 *)(iVar3 + 6);
  cVar2 = .glue::EmptyRect(&uStack_18);
  if (cVar2 != '\0') {
    iVar3 = **(int **)(*(int *)(param_1 + 4) + 0x72);
    uStack_18 = *(uint *)(iVar3 + 2);
    uStack_14 = *(undefined4 *)(iVar3 + 6);
    .glue::InsetRect(&uStack_18,1,1);
    uStack_18 = uStack_18 & 0xffff;
  }
  uStack_18 = CONCAT22(uStack_14._0_2_ - sVar4,uStack_18._2_2_);
  while( true ) {
    if (0x14 < uStack_18._0_2_ + -0x10) break;
    uStack_18 = CONCAT22(uStack_18._0_2_ + *(short *)(param_1 + 0xe),uStack_18._2_2_);
  }
  cVar2 = .glue::StillDown();
  if (cVar2 == '\0') {
    *param_3 = uStack_18;
    param_3[1] = uStack_14;
  }
  .glue::InsetRect(&uStack_18,0xffffffff,0);
  uStack_18._0_2_ = uStack_18._0_2_ + -0x12;
  .glue::FrameRect(&uStack_18);
  if (uStack_18._0_2_ + 0x12 < (int)uStack_14._0_2_) {
    .glue::MoveTo(uStack_18._2_2_ + 1,uStack_18._0_2_ + 0x12);
    .glue::LineTo(uStack_14._2_2_ + -2,uStack_18._0_2_ + 0x12);
  }
  return;
}


// ==== .Test__11TDrawerWDEFFs5Point @ 100a5cf0 ====
// CyDecompAt: created, body 100a5cf0-100a5d3f

undefined4 _Test__11TDrawerWDEFFs5Point(int param_1,undefined4 param_2,undefined4 param_3)

{
  char cVar2;
  undefined4 uVar1;
  
  cVar2 = .glue::PtInRgn(param_3,*(undefined4 *)(*(int *)(param_1 + 4) + 0x76));
  if (cVar2 == '\0') {
    uVar1 = 3;
  }
  else {
    uVar1 = 1;
  }
  return uVar1;
}


// ==== .CalcRegions__11TDrawerWDEFFsR4Rect @ 100a5d70 ====
// CyDecompAt: created, body 100a5d70-100a5e33

void _CalcRegions__11TDrawerWDEFFsR4Rect(int param_1,undefined4 param_2,undefined4 *param_3)

{
  undefined4 uVar1;
  undefined4 uVar2;
  undefined4 uStack_18;
  undefined4 uStack_14;
  
  .glue::RectRgn(*(undefined4 *)(*(int *)(param_1 + 4) + 0x76),param_3);
  uVar2 = *param_3;
  uVar1 = param_3[1];
  uStack_18._0_2_ = (short)((uint)uVar2 >> 0x10);
  uStack_14._0_2_ = (short)((uint)uVar1 >> 0x10);
  uStack_18 = uVar2;
  uStack_14 = uVar1;
  if (uStack_14._0_2_ == uStack_18._0_2_) {
    .glue::InsetRect(&uStack_18,0xffffffff,0xffffffff);
    uStack_18 = CONCAT22(uStack_18._0_2_ + -0x10,uStack_18._2_2_);
  }
  else {
    .glue::InsetRect(&uStack_18,0xffffffff,0xffffffff);
    uStack_18 = CONCAT22(uStack_18._0_2_ + -0x11,uStack_18._2_2_);
  }
  .glue::RectRgn(*(undefined4 *)(*(int *)(param_1 + 4) + 0x72),&uStack_18);
  return;
}


// ==== .HandleResizeWindow__13TDrawerWindowF5Point @ 100a5e6c ====
// CyDecompAt: created, body 100a5e6c-100a627f

void _HandleResizeWindow__13TDrawerWindowF5Point(int param_1,undefined4 param_2)

{
  bool bVar1;
  char cVar3;
  int iVar2;
  int iVar4;
  int iVar5;
  undefined4 uVar6;
  short sVar7;
  short sStack_48;
  short sStack_46;
  short sStack_44;
  short sStack_42;
  undefined4 uStack_40;
  undefined4 uStack_3c;
  undefined4 uStack_38;
  int iStack_34;
  undefined4 auStack_30 [4];
  
  uVar6 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x82);
  cVar3 = .glue::WaitMouseUp();
  if (cVar3 != '\0') {
    .glue::GetPort(auStack_30);
    .glue::GetWMgrPort(&iStack_34);
    .glue::SetPort(iStack_34);
    .glue::GetGrayRgn();
    .glue::SetClip();
    iVar2 = .glue::FrontWindow();
    while( true ) {
      if (iVar2 == *(int *)(param_1 + 4)) break;
      .glue::DiffRgn(*(undefined4 *)(iStack_34 + 0x1c),*(undefined4 *)(iVar2 + 0x72),
                     *(undefined4 *)(iStack_34 + 0x1c));
      iVar2 = *(int *)(iVar2 + 0x90);
    }
    uStack_3c = *(undefined4 *)(*(int *)(param_1 + 4) + 0x10);
    uStack_38 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x14);
    .glue::PenPat(PTR_DAT_100cdb94 + 0xb2);
    .glue::PenMode(10);
    FUN_100c50e8(uVar6,0,&uStack_3c);
    bVar1 = false;
LAB_100a5ff0:
    cVar3 = .glue::StillDown();
    if (cVar3 != '\0') {
      .glue::GetMouse(&uStack_40);
      sVar7 = (short)((uint)param_2 >> 0x10);
      if (uStack_40._2_2_ == (short)param_2) goto code_r0x100a5f84;
      goto LAB_100a5f94;
    }
    FUN_100c50e8(uVar6,0,&uStack_3c);
    .glue::PenPat(PTR_DAT_100cdb94 + 0xba);
    .glue::PenMode(8);
    .glue::SetPort(auStack_30[0]);
    if (!bVar1) {
      if (*(short *)(*(int *)(param_1 + 4) + 0x14) == *(short *)(*(int *)(param_1 + 4) + 0x10)) {
        if (*(short *)(param_1 + 0xe) == 0) {
          uStack_38 = CONCAT22(uStack_3c._0_2_ + 1,uStack_38._2_2_);
          FUN_100c50e8(uVar6,0,&uStack_3c);
        }
        else {
          uStack_38 = CONCAT22(uStack_3c._0_2_,uStack_38._2_2_);
          uStack_3c = CONCAT22(uStack_3c._0_2_ - *(short *)(param_1 + 0xe),uStack_3c._2_2_);
        }
      }
      else {
        *(short *)(param_1 + 0xe) =
             *(short *)(*(int *)(param_1 + 4) + 0x14) - *(short *)(*(int *)(param_1 + 4) + 0x10);
        uStack_3c = CONCAT22(uStack_38._0_2_,uStack_3c._2_2_);
      }
    }
    iVar5 = (int)uStack_38._0_2_ - (int)uStack_3c._0_2_;
    iVar4 = iVar5 - ((int)*(short *)(*(int *)(param_1 + 4) + 0x14) -
                    (int)*(short *)(*(int *)(param_1 + 4) + 0x10));
    if (((short)iVar5 == 0) && (*(char *)(param_1 + 0xc) != '\0')) {
      *(undefined1 *)(param_1 + 0xc) = 0;
      FUN_100c50e8(param_1);
    }
    else if (((short)iVar5 != 0) && (*(char *)(param_1 + 0xc) == '\0')) {
      *(undefined1 *)(param_1 + 0xc) = 1;
      FUN_100c50e8(param_1);
    }
    if ((short)iVar4 < 1) {
      if ((short)iVar4 < 0) {
        uVar6 = *(undefined4 *)(**(int **)(iVar2 + 0x76) + 2);
        sStack_48 = (short)((uint)uVar6 >> 0x10);
        sStack_46 = (short)uVar6;
        .glue::MoveWindow(*(undefined4 *)(param_1 + 4),(int)sStack_46,sStack_48 - iVar4,0);
        .glue::SizeWindow(*(undefined4 *)(param_1 + 4),
                          (int)*(short *)(*(int *)(param_1 + 4) + 0x16) -
                          (int)*(short *)(*(int *)(param_1 + 4) + 0x12),iVar5,0);
        FUN_100c50e8(param_1);
      }
    }
    else {
      .glue::SizeWindow(*(undefined4 *)(param_1 + 4),
                        (int)*(short *)(*(int *)(param_1 + 4) + 0x16) -
                        (int)*(short *)(*(int *)(param_1 + 4) + 0x12),iVar5,0);
      uVar6 = *(undefined4 *)(**(int **)(iVar2 + 0x76) + 2);
      sStack_44 = (short)((uint)uVar6 >> 0x10);
      sStack_42 = (short)uVar6;
      .glue::MoveWindow(*(undefined4 *)(param_1 + 4),(int)sStack_42,sStack_44 - iVar4,0);
      FUN_100c50e8(param_1);
    }
    FUN_100c50e8();
  }
  return;
code_r0x100a5f84:
  if (uStack_40._0_2_ != sVar7) {
LAB_100a5f94:
    FUN_100c50e8(uVar6,0,&uStack_3c);
    uStack_3c = CONCAT22(uStack_3c._0_2_ + (uStack_40._0_2_ - sVar7),uStack_3c._2_2_);
    FUN_100c50e8(uVar6,0,&uStack_3c);
    bVar1 = true;
    param_2 = uStack_40;
  }
  goto LAB_100a5ff0;
}


// ==== .HandleMonitorChanged__13TDrawerWindowFPP7GDeviceR4RectR4Rect @ 100a62c0 ====
// CyDecompAt: created, body 100a62c0-100a631b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleMonitorChanged__13TDrawerWindowFPP7GDeviceR4RectR4Rect
               (undefined4 param_1,int param_2,undefined4 param_3,undefined4 param_4)

{
  if (param_2 == *_DAT_100cdd40) {
    .debug::_HandleMonitorChanged__7TWindowFPP7GDeviceR4RectR4Rect(param_1,param_2,param_3,param_4);
  }
  return;
}


// ==== .GetOwningGD__13TDrawerWindowFPP7GDeviceR4Rect @ 100a636c ====
// CyDecompAt: created, body 100a636c-100a6377

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 _GetOwningGD__13TDrawerWindowFPP7GDeviceR4Rect(void)

{
  return *_DAT_100cdd40;
}


// ==== .BecomeVisible__13TDrawerWindowFv @ 100a63b8 ====
// CyDecompAt: created, body 100a63b8-100a63bb

void _BecomeVisible__13TDrawerWindowFv(void)

{
  return;
}


// ==== .BecomeNotVisible__13TDrawerWindowFv @ 100a63f0 ====
// CyDecompAt: created, body 100a63f0-100a63f3

void _BecomeNotVisible__13TDrawerWindowFv(void)

{
  return;
}


// ==== .Create__15TPushButtonCDEFFPP13ControlRecords @ 100a64b8 ====
// CyDecompAt: created, body 100a64b8-100a650b

int _Create__15TPushButtonCDEFFPP13ControlRecords(undefined4 param_1,short param_2)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(8);
  if (iVar1 != 0) {
    .debug::___ct__15TPushButtonCDEFFPP13ControlRecords(iVar1,param_1,(int)param_2);
  }
  return iVar1;
}


// ==== .DrawAPart__15TPushButtonCDEFFP13ControlRecordssP10ColorTableP10ColorTableUc @ 100a654c ====
// CyDecompAt: created, body 100a654c-100a663f

void _DrawAPart__15TPushButtonCDEFFP13ControlRecordssP10ColorTableP10ColorTableUc
               (int param_1,int param_2,ushort param_3)

{
  undefined4 uVar1;
  undefined4 uStack_28;
  undefined4 uStack_24;
  
  uVar1 = 0;
  if ((*(char *)(param_2 + 0x11) == '\n') || (*(char *)(param_2 + 0x11) == '\x01')) {
    uVar1 = 1;
  }
  else if (*(char *)(**(int **)(param_1 + 4) + 0x11) == -1) {
    uVar1 = 2;
  }
  uStack_28 = *(undefined4 *)(**(int **)(param_1 + 4) + 8);
  uStack_24 = *(undefined4 *)(**(int **)(param_1 + 4) + 0xc);
  if ((param_3 & 8) != 0) {
    .glue::TextFont((int)*(short *)(*(int *)(param_2 + 4) + 0x44));
    .glue::TextSize((int)*(short *)(*(int *)(param_2 + 4) + 0x4a));
    .glue::TextFace(*(undefined1 *)(*(int *)(param_2 + 4) + 0x46));
  }
  .debug::_DrawButton__FR4RectPUc12eButtonState(&uStack_28,**(int **)(param_1 + 4) + 0x28,uVar1);
  return;
}


// ==== .Create__16TCheckButtonCDEFFPP13ControlRecords @ 100a672c ====
// CyDecompAt: created, body 100a672c-100a677f

int _Create__16TCheckButtonCDEFFPP13ControlRecords(undefined4 param_1,short param_2)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(8);
  if (iVar1 != 0) {
    .debug::___ct__16TCheckButtonCDEFFPP13ControlRecords(iVar1,param_1,(int)param_2);
  }
  return iVar1;
}


// ==== .DrawAPart__16TCheckButtonCDEFFP13ControlRecordssP10ColorTableP10ColorTableUc @ 100a67c0 ====
// CyDecompAt: created, body 100a67c0-100a68d3

void _DrawAPart__16TCheckButtonCDEFFP13ControlRecordssP10ColorTableP10ColorTableUc
               (int param_1,int param_2,ushort param_3)

{
  undefined4 uVar1;
  undefined4 uStack_28;
  undefined4 uStack_24;
  
  uVar1 = 0;
  if ((*(char *)(param_2 + 0x11) == '\n') || (*(char *)(param_2 + 0x11) == '\x01')) {
    uVar1 = 1;
  }
  else if (*(char *)(**(int **)(param_1 + 4) + 0x11) == -1) {
    uVar1 = 2;
  }
  else if (*(short *)(**(int **)(param_1 + 4) + 0x12) != 0) {
    uVar1 = 3;
  }
  uStack_28 = *(undefined4 *)(**(int **)(param_1 + 4) + 8);
  uStack_24 = *(undefined4 *)(**(int **)(param_1 + 4) + 0xc);
  if ((param_3 & 8) != 0) {
    .glue::TextFont((int)*(short *)(*(int *)(param_2 + 4) + 0x44));
    .glue::TextSize((int)*(short *)(*(int *)(param_2 + 4) + 0x4a));
    .glue::TextFace(*(undefined1 *)(*(int *)(param_2 + 4) + 0x46));
  }
  .debug::_DrawCheck__FR4RectPUc12eButtonStates
            (&uStack_28,**(int **)(param_1 + 4) + 0x28,uVar1,0x1ab);
  return;
}


// ==== .Create__16TRadioButtonCDEFFPP13ControlRecords @ 100a69c0 ====
// CyDecompAt: created, body 100a69c0-100a6a13

int _Create__16TRadioButtonCDEFFPP13ControlRecords(undefined4 param_1,short param_2)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(8);
  if (iVar1 != 0) {
    .debug::___ct__16TRadioButtonCDEFFPP13ControlRecords(iVar1,param_1,(int)param_2);
  }
  return iVar1;
}


// ==== .DrawAPart__16TRadioButtonCDEFFP13ControlRecordssP10ColorTableP10ColorTableUc @ 100a6a54 ====
// CyDecompAt: created, body 100a6a54-100a6b67

void _DrawAPart__16TRadioButtonCDEFFP13ControlRecordssP10ColorTableP10ColorTableUc
               (int param_1,int param_2,ushort param_3)

{
  undefined4 uVar1;
  undefined4 uStack_28;
  undefined4 uStack_24;
  
  uVar1 = 0;
  if ((*(char *)(param_2 + 0x11) == '\n') || (*(char *)(param_2 + 0x11) == '\x01')) {
    uVar1 = 1;
  }
  else if (*(char *)(**(int **)(param_1 + 4) + 0x11) == -1) {
    uVar1 = 2;
  }
  else if (*(short *)(**(int **)(param_1 + 4) + 0x12) != 0) {
    uVar1 = 3;
  }
  uStack_28 = *(undefined4 *)(**(int **)(param_1 + 4) + 8);
  uStack_24 = *(undefined4 *)(**(int **)(param_1 + 4) + 0xc);
  if ((param_3 & 8) != 0) {
    .glue::TextFont((int)*(short *)(*(int *)(param_2 + 4) + 0x44));
    .glue::TextSize((int)*(short *)(*(int *)(param_2 + 4) + 0x4a));
    .glue::TextFace(*(undefined1 *)(*(int *)(param_2 + 4) + 0x46));
  }
  .debug::_DrawCheck__FR4RectPUc12eButtonStates
            (&uStack_28,**(int **)(param_1 + 4) + 0x28,uVar1,0x1ac);
  return;
}


// ==== .Create__11TNumberCDEFFPP13ControlRecords @ 100a6c50 ====
// CyDecompAt: created, body 100a6c50-100a6ca3

int _Create__11TNumberCDEFFPP13ControlRecords(undefined4 param_1,short param_2)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(8);
  if (iVar1 != 0) {
    .debug::___ct__11TNumberCDEFFPP13ControlRecords(iVar1,param_1,(int)param_2);
  }
  return iVar1;
}


// ==== .DrawAPart__11TNumberCDEFFP13ControlRecordssP10ColorTableP10ColorTableUc @ 100a6ce0 ====
// CyDecompAt: created, body 100a6ce0-100a6d8f

void _DrawAPart__11TNumberCDEFFP13ControlRecordssP10ColorTableP10ColorTableUc
               (int param_1,int param_2,ushort param_3)

{
  undefined4 uStack_14;
  undefined4 uStack_10;
  
  uStack_14 = *(undefined4 *)(**(int **)(param_1 + 4) + 8);
  uStack_10 = *(undefined4 *)(**(int **)(param_1 + 4) + 0xc);
  if ((param_3 & 8) != 0) {
    .glue::TextFont((int)*(short *)(*(int *)(param_2 + 4) + 0x44));
    .glue::TextSize((int)*(short *)(*(int *)(param_2 + 4) + 0x4a));
    .glue::TextFace(*(undefined1 *)(*(int *)(param_2 + 4) + 0x46));
  }
  .debug::_DrawNumberField__FR4Rectss(&uStack_14,(int)*(short *)(param_2 + 0x12),0xffffffff);
  return;
}


// ==== .Create__15TEditNumberCDEFFPP13ControlRecords @ 100a6e88 ====
// CyDecompAt: created, body 100a6e88-100a6edb

int _Create__15TEditNumberCDEFFPP13ControlRecords(undefined4 param_1,short param_2)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(8);
  if (iVar1 != 0) {
    .debug::___ct__15TEditNumberCDEFFPP13ControlRecords(iVar1,param_1,(int)param_2);
  }
  return iVar1;
}


// ==== .Test__15TEditNumberCDEFFs5Point @ 100a6f1c ====
// CyDecompAt: created, body 100a6f1c-100a6f6f

void _Test__15TEditNumberCDEFFs5Point(int param_1,undefined4 param_2,undefined4 param_3)

{
  undefined4 uStack_18;
  undefined4 uStack_14;
  
  uStack_18 = *(undefined4 *)(**(int **)(param_1 + 4) + 8);
  uStack_14 = *(undefined4 *)(**(int **)(param_1 + 4) + 0xc);
  .debug::_FindNumberFieldPart__FR4Rect5Point(&uStack_18,param_3);
  return;
}


// ==== .Action__15TEditNumberCDEFFss @ 100a6fa4 ====
// CyDecompAt: created, body 100a6fa4-100a70bf

void _Action__15TEditNumberCDEFFss(int param_1,undefined4 param_2,short param_3)

{
  undefined *puVar1;
  uint uVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  
  puVar1 = PTR_DAT_100ce0a8;
  if (param_3 == 0x14) {
    iVar5 = 1;
  }
  else {
    if (param_3 != 0x15) {
      return;
    }
    iVar5 = -1;
  }
  uVar2 = .glue::TickCount();
  if (*(uint *)puVar1 < uVar2) {
    if (*(int *)puVar1 == 0) {
      iVar3 = .glue::LMGetDoubleTime();
      iVar4 = .glue::TickCount();
      *(int *)puVar1 = iVar4 + iVar3;
    }
    else {
      iVar3 = .glue::TickCount();
      *(int *)puVar1 = iVar3 + 10;
    }
    if (((int)*(short *)(**(int **)(param_1 + 4) + 0x12) + (int)(short)iVar5 <=
         (int)*(short *)(**(int **)(param_1 + 4) + 0x16)) &&
       ((int)*(short *)(**(int **)(param_1 + 4) + 0x14) <=
        (int)*(short *)(**(int **)(param_1 + 4) + 0x12) + (int)(short)iVar5)) {
      .glue::SetControlValue
                (*(undefined4 *)(param_1 + 4),*(short *)(**(int **)(param_1 + 4) + 0x12) + iVar5);
    }
  }
  return;
}


// ==== .DrawAPart__15TEditNumberCDEFFP13ControlRecordssP10ColorTableP10ColorTableUc @ 100a70f0 ====
// CyDecompAt: created, body 100a70f0-100a71b7

void _DrawAPart__15TEditNumberCDEFFP13ControlRecordssP10ColorTableP10ColorTableUc
               (int param_1,int param_2,ushort param_3)

{
  undefined4 uStack_14;
  undefined4 uStack_10;
  
  uStack_14 = *(undefined4 *)(**(int **)(param_1 + 4) + 8);
  uStack_10 = *(undefined4 *)(**(int **)(param_1 + 4) + 0xc);
  if ((param_3 & 8) != 0) {
    .glue::TextFont((int)*(short *)(*(int *)(param_2 + 4) + 0x44));
    .glue::TextSize((int)*(short *)(*(int *)(param_2 + 4) + 0x4a));
    .glue::TextFace(*(undefined1 *)(*(int *)(param_2 + 4) + 0x46));
  }
  .debug::_DrawNumberField__FR4Rectss
            (&uStack_14,(int)*(short *)(param_2 + 0x12),*(undefined1 *)(param_2 + 0x11));
  if (*(char *)(param_2 + 0x11) == '\0') {
    *(undefined4 *)PTR_DAT_100ce0a8 = 0;
  }
  return;
}


// ==== .Create__12TProgBarCDEFFPP13ControlRecords @ 100a72a0 ====
// CyDecompAt: created, body 100a72a0-100a72f3

int _Create__12TProgBarCDEFFPP13ControlRecords(undefined4 param_1,short param_2)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(8);
  if (iVar1 != 0) {
    .debug::___ct__12TProgBarCDEFFPP13ControlRecords(iVar1,param_1,(int)param_2);
  }
  return iVar1;
}


// ==== .DrawAPart__12TProgBarCDEFFP13ControlRecordssP10ColorTableP10ColorTableUc @ 100a7400 ====
// CyDecompAt: created, body 100a7400-100a7637

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DrawAPart__12TProgBarCDEFFP13ControlRecordssP10ColorTableP10ColorTableUc
               (int param_1,int param_2)

{
  uint uVar1;
  undefined4 uVar2;
  short sVar4;
  uint uVar3;
  uint uVar5;
  int iStack_168;
  undefined1 uStack_164;
  undefined1 auStack_163 [255];
  undefined4 uStack_64;
  undefined4 uStack_60;
  undefined4 uStack_5c;
  undefined4 uStack_58;
  int iStack_54;
  undefined4 uStack_50;
  undefined4 uStack_4c;
  undefined4 uStack_48;
  undefined4 uStack_44;
  undefined4 uStack_40;
  undefined4 uStack_3c;
  undefined4 uStack_38;
  undefined4 uStack_34;
  undefined4 uStack_30;
  undefined4 uStack_2c;
  undefined4 uStack_28;
  undefined2 uStack_24;
  undefined4 uStack_22;
  undefined4 uStack_1e;
  
  uStack_22 = *(undefined4 *)(**(int **)(param_1 + 4) + 8);
  uStack_1e = *(undefined4 *)(**(int **)(param_1 + 4) + 0xc);
  .debug::_ExpandHorizontally__FR4RectsUc(&uStack_22,0x1a5,0);
  if (*(short *)(param_2 + 0x14) < *(short *)(param_2 + 0x16)) {
    uStack_50 = uRam100d3de8;
    uStack_4c = uRam100d3dec;
    uStack_48 = uRam100d3df0;
    uStack_44 = uRam100d3df4;
    uStack_40 = uRam100d3df8;
    uStack_3c = uRam100d3dfc;
    uStack_38 = uRam100d3e00;
    uStack_34 = uRam100d3e04;
    uStack_30 = uRam100d3e08;
    uStack_2c = uRam100d3e0c;
    uStack_28 = uRam100d3e10;
    uStack_24 = uRam100d3e14;
    uStack_5c = _DAT_100d7b8c;
    uStack_58 = uRam100d7b90;
    iStack_54 = *(int *)PTR_DAT_100cdc64 + 0x69400;
    .glue::SetRect(&uStack_5c,0,0,0x20,0x10);
    uStack_64 = uStack_5c;
    uStack_60 = uStack_58;
    uVar2 = .debug::_CalcThumb__12TProgBarCDEFFv(param_1);
    .glue::OffsetRect(&uStack_64,uVar2,(int)uStack_22._0_2_);
    .glue::GetPort(&iStack_168);
    .glue::CopyBits(&iStack_54,iStack_168 + 2,&uStack_5c,&uStack_64,0,0);
    .debug::_SetText__Fs(1);
    .glue::NumToString(*(undefined4 *)(**(int **)(param_1 + 4) + 0x24),&uStack_164);
    sVar4 = .glue::StringWidth(&uStack_164);
    uVar1 = (uint)*(short *)(_DAT_100cdb90 + 8);
    uVar5 = ((int)uStack_64._2_2_ + (int)uStack_60._2_2_) - (int)sVar4;
    uVar3 = (int)uStack_60._0_2_ + (int)uStack_64._0_2_;
    .glue::MoveTo((int)(short)((short)((int)uVar5 >> 1) +
                              (ushort)((int)uVar5 < 0 && (uVar5 & 1) != 0)),
                  (int)(short)((short)((int)uVar3 >> 1) +
                              (ushort)((int)uVar3 < 0 && (uVar3 & 1) != 0)) +
                  ((int)uVar1 >> 1) + (uint)((int)uVar1 < 0 && (uVar1 & 1) != 0));
    .debug::_AADrawText__FPcss(auStack_163,0,uStack_164);
  }
  return;
}


// ==== .CalcThumbRegion__14TScrollBarCDEFFsPP9MacRegion @ 100a7694 ====
// CyDecompAt: created, body 100a7694-100a771b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _CalcThumbRegion__14TScrollBarCDEFFsPP9MacRegion
               (int param_1,undefined4 param_2,undefined4 param_3)

{
  undefined4 uVar1;
  undefined4 uStack_18;
  undefined4 uStack_14;
  undefined4 uStack_10;
  undefined4 uStack_c;
  
  uStack_10 = *(undefined4 *)(**(int **)(param_1 + 4) + 8);
  uStack_c = *(undefined4 *)(**(int **)(param_1 + 4) + 0xc);
  uStack_18 = _DAT_100d7b94;
  uStack_14 = uRam100d7b98;
  uVar1 = .debug::_CalcThumb__14TScrollBarCDEFFv();
  .glue::OffsetRect(&uStack_18,(int)uStack_10._2_2_,uVar1);
  .glue::RectRgn(param_3,&uStack_18);
  return;
}


// ==== .Create__14TScrollBarCDEFFPP13ControlRecords @ 100a77e8 ====
// CyDecompAt: created, body 100a77e8-100a783b

int _Create__14TScrollBarCDEFFPP13ControlRecords(undefined4 param_1,short param_2)

{
  int iVar1;
  
  iVar1 = FUN_100be7c8(8);
  if (iVar1 != 0) {
    .debug::___ct__14TScrollBarCDEFFPP13ControlRecords(iVar1,param_1,(int)param_2);
  }
  return iVar1;
}


// ==== .Pos__14TScrollBarCDEFFsss @ 100a7950 ====
// CyDecompAt: created, body 100a7950-100a7b17

void _Pos__14TScrollBarCDEFFsss(int param_1,undefined4 param_2,short param_3)

{
  uint uVar1;
  int iVar2;
  int iVar3;
  short sVar4;
  undefined2 uStack_28;
  undefined2 uStack_24;
  
  uStack_24 = (short)((uint)*(undefined4 *)(**(int **)(param_1 + 4) + 0xc) >> 0x10);
  uStack_28 = (short)((uint)*(undefined4 *)(**(int **)(param_1 + 4) + 8) >> 0x10);
  iVar2 = ((int)uStack_24 - (int)uStack_28) + -0x30;
  iVar3 = (int)*(short *)(**(int **)(param_1 + 4) + 0x16) -
          (int)*(short *)(**(int **)(param_1 + 4) + 0x14);
  if ((iVar2 < 0x10) || (iVar3 < 1)) {
    *(undefined2 *)(**(int **)(param_1 + 4) + 0x12) =
         *(undefined2 *)(**(int **)(param_1 + 4) + 0x14);
    FUN_100c50e8(param_1,param_2,0);
  }
  else {
    param_3 = uStack_28 +
              (short)((iVar2 * ((int)*(short *)(**(int **)(param_1 + 4) + 0x12) -
                               (int)*(short *)(**(int **)(param_1 + 4) + 0x14))) / iVar3) + 0x10 +
              param_3;
    if ((int)param_3 < uStack_28 + 0x10) {
      sVar4 = *(short *)(**(int **)(param_1 + 4) + 0x14);
    }
    else if ((int)param_3 < uStack_24 + -0x20) {
      uVar1 = (uStack_24 + -0x20) - (uStack_28 + 0x10);
      sVar4 = *(short *)(**(int **)(param_1 + 4) + 0x14) +
              (short)((int)(((int)uVar1 >> 1) + (uint)((int)uVar1 < 0 && (uVar1 & 1) != 0) +
                           iVar3 * ((int)param_3 - (uStack_28 + 0x10))) /
                     ((uStack_24 + -0x20) - (uStack_28 + 0x10)));
    }
    else {
      sVar4 = *(short *)(**(int **)(param_1 + 4) + 0x16);
    }
    *(short *)(**(int **)(param_1 + 4) + 0x12) = sVar4;
    FUN_100c50e8(param_1,param_2,0);
  }
  return;
}


// ==== .Thumb__14TScrollBarCDEFFs5PointP23IndicatorDragConstraint @ 100a7b44 ====
// CyDecompAt: created, body 100a7b44-100a7c17

void _Thumb__14TScrollBarCDEFFs5PointP23IndicatorDragConstraint
               (int param_1,undefined4 param_2,undefined4 param_3,short *param_4)

{
  short sVar1;
  short sVar2;
  undefined4 uVar3;
  int iVar4;
  undefined4 uVar5;
  short sStack_28;
  short sStack_26;
  short sStack_24;
  short sStack_22;
  
  param_4[8] = 2;
  sVar1 = param_4[1];
  sVar2 = *param_4;
  uVar5 = *(undefined4 *)(**(int **)(param_1 + 4) + 8);
  uVar3 = *(undefined4 *)(**(int **)(param_1 + 4) + 0xc);
  iVar4 = .debug::_CalcThumb__14TScrollBarCDEFFv();
  sStack_28 = (short)((uint)uVar5 >> 0x10);
  sStack_24 = (short)((uint)uVar3 >> 0x10);
  .glue::SetRect(param_4,(int)sVar1,(int)sStack_28 + (sVar2 - iVar4) + 0x10,(int)sVar1,
                 (int)sStack_24 + (sVar2 - iVar4) + -0x1f);
  sStack_26 = (short)uVar5;
  sStack_22 = (short)uVar3;
  .glue::SetRect(param_4 + 4,sStack_26 + -8,sStack_28 + -0x20,sStack_22 + 8,sStack_24 + 0x20);
  return;
}


// ==== .Test__14TScrollBarCDEFFs5Point @ 100a7c64 ====
// CyDecompAt: created, body 100a7c64-100a7d53

undefined4 _Test__14TScrollBarCDEFFs5Point(int param_1,undefined4 param_2,undefined4 param_3)

{
  char cVar3;
  undefined4 uVar1;
  short sVar2;
  short sVar4;
  undefined4 uStack_18;
  undefined4 uStack_14;
  
  uStack_18 = *(undefined4 *)(**(int **)(param_1 + 4) + 8);
  uStack_14 = *(undefined4 *)(**(int **)(param_1 + 4) + 0xc);
  cVar3 = .glue::PtInRect(param_3,&uStack_18);
  if (cVar3 == '\0') {
    uVar1 = 0;
  }
  else {
    sVar4 = (short)((uint)param_3 >> 0x10);
    if ((int)sVar4 < uStack_18._0_2_ + 0x10) {
      uVar1 = 0x14;
    }
    else if ((int)sVar4 < uStack_14._0_2_ + -0x10) {
      sVar2 = .debug::_CalcThumb__14TScrollBarCDEFFv(param_1);
      if (sVar4 < sVar2) {
        uVar1 = 0x16;
      }
      else if ((int)sVar4 < sVar2 + 0x10) {
        uVar1 = 0x81;
      }
      else {
        uVar1 = 0x17;
      }
    }
    else {
      uVar1 = 0x15;
    }
  }
  return uVar1;
}


// ==== .DrawAPart__14TScrollBarCDEFFP13ControlRecordssP10ColorTableP10ColorTableUc @ 100a7d88 ====
// CyDecompAt: created, body 100a7d88-100a8293

/* WARNING: Removing unreachable block (ram,0x100a7e6c) */
/* WARNING: Removing unreachable block (ram,0x100a7ef4) */
/* WARNING: Removing unreachable block (ram,0x100a7f00) */
/* WARNING: Removing unreachable block (ram,0x100a80c4) */
/* WARNING: Removing unreachable block (ram,0x100a81a4) */
/* WARNING: Removing unreachable block (ram,0x100a81b0) */
/* WARNING: Removing unreachable block (ram,0x100a81bc) */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DrawAPart__14TScrollBarCDEFFP13ControlRecordssP10ColorTableP10ColorTableUc
               (int param_1,int param_2)

{
  undefined *puVar1;
  undefined4 uVar2;
  int iVar3;
  int iVar4;
  int iStack_88;
  int iStack_84;
  int iStack_80;
  int iStack_7c;
  int iStack_78;
  int iStack_74;
  undefined4 uStack_70;
  undefined4 uStack_6c;
  undefined4 uStack_68;
  undefined4 uStack_64;
  int iStack_60;
  undefined4 uStack_5c;
  undefined4 uStack_58;
  undefined4 uStack_54;
  undefined4 uStack_50;
  undefined4 uStack_4c;
  undefined4 uStack_48;
  undefined4 uStack_44;
  undefined4 uStack_40;
  undefined4 uStack_3c;
  undefined4 uStack_38;
  undefined4 uStack_34;
  undefined2 uStack_30;
  undefined4 uStack_2e;
  undefined4 uStack_2a;
  
  puVar1 = PTR_DAT_100cdc64;
  uVar2 = *(undefined4 *)(**(int **)(param_1 + 4) + 8);
  uStack_2a = *(undefined4 *)(**(int **)(param_1 + 4) + 0xc);
  uStack_5c = uRam100d3de8;
  uStack_58 = uRam100d3dec;
  uStack_54 = uRam100d3df0;
  uStack_50 = uRam100d3df4;
  uStack_4c = uRam100d3df8;
  uStack_48 = uRam100d3dfc;
  uStack_44 = uRam100d3e00;
  uStack_40 = uRam100d3e04;
  uStack_3c = uRam100d3e08;
  uStack_38 = uRam100d3e0c;
  uStack_34 = uRam100d3e10;
  uStack_30 = uRam100d3e14;
  uStack_68 = _DAT_100d7b9c;
  uStack_64 = uRam100d7ba0;
  uStack_70 = _DAT_100d7b9c;
  uStack_6c = uRam100d7ba0;
  if (*(char *)(param_2 + 0x11) == '\x14') {
    iStack_60 = *(int *)PTR_DAT_100cdc64 + 0x6b800;
  }
  else {
    iStack_60 = *(int *)PTR_DAT_100cdc64 + 0x6b400;
  }
  uStack_2e._0_2_ = (short)((uint)uVar2 >> 0x10);
  iVar4 = (int)uStack_2e._0_2_;
  uStack_2e._2_2_ = (short)uVar2;
  iVar3 = (int)uStack_2e._2_2_;
  uStack_2e = uVar2;
  .glue::OffsetRect(&uStack_70,iVar3,iVar4);
  .glue::GetPort(&iStack_74);
  .glue::CopyBits(&iStack_60,iStack_74 + 2,&uStack_68,&uStack_70,0,0);
  iStack_60 = *(int *)puVar1 + 0x6b400;
  if (0x20 < (int)uStack_2a._0_2_ - (int)uStack_2e._0_2_) {
    .glue::SetRect(&uStack_68,0x10,0,0x20,0x10);
    uStack_70 = uStack_68;
    uStack_6c = uStack_64;
    .glue::OffsetRect(&uStack_70,uStack_2e._2_2_ + -0x10,uStack_2e._0_2_ + 0x10);
    .glue::GetPort(&iStack_78);
    .glue::CopyBits(&iStack_60,iStack_78 + 2,&uStack_68,&uStack_70,0,0);
    uStack_68 = CONCAT22(8,uStack_68._2_2_);
    uStack_64 = CONCAT22(0x18,uStack_64._2_2_);
    uStack_70 = uStack_68;
    uStack_6c = uStack_64;
    .glue::OffsetRect(&uStack_70,uStack_2e._2_2_ + -0x10,uStack_2e._0_2_ + 0x18);
    while( true ) {
      if (uStack_2a._0_2_ + -0x20 <= (int)uStack_70._0_2_) break;
      .glue::GetPort(&iStack_7c);
      .glue::CopyBits(&iStack_60,iStack_7c + 2,&uStack_68,&uStack_70,0,0);
      .glue::OffsetRect(&uStack_70,0,0x10);
    }
    .glue::SetRect(&uStack_68,0x10,0x10,0x20,0x20);
    uStack_70 = uStack_68;
    uStack_6c = uStack_64;
    .glue::OffsetRect(&uStack_70,uStack_2e._2_2_ + -0x10,uStack_2a._0_2_ + -0x30);
    .glue::GetPort(&iStack_80);
    .glue::CopyBits(&iStack_60,iStack_80 + 2,&uStack_68,&uStack_70,0,0);
  }
  if (*(char *)(param_2 + 0x11) == '\x15') {
    iStack_60 = *(int *)puVar1 + 0x6b800;
  }
  else {
    iStack_60 = *(int *)puVar1 + 0x6b400;
  }
  .glue::SetRect(&uStack_68,0,0x10,0x10,0x20);
  uStack_70 = uStack_68;
  uStack_6c = uStack_64;
  .glue::OffsetRect(&uStack_70,(int)uStack_2e._2_2_,uStack_2a._0_2_ + -0x20);
  .glue::GetPort(&iStack_84);
  .glue::CopyBits(&iStack_60,iStack_84 + 2,&uStack_68,&uStack_70,0,0);
  if ((*(char *)(**(int **)(param_1 + 4) + 0x11) != -1) &&
     (*(short *)(param_2 + 0x14) < *(short *)(param_2 + 0x16))) {
    if (0x10 < ((int)uStack_2a._0_2_ - (int)uStack_2e._0_2_) + -0x20) {
      iStack_60 = *(int *)puVar1 + 0x6b800;
      .glue::SetRect(&uStack_68,0x10,0,0x20,0x10);
      uStack_70 = uStack_68;
      uStack_6c = uStack_64;
      uVar2 = .debug::_CalcThumb__14TScrollBarCDEFFv(param_1);
      .glue::OffsetRect(&uStack_70,uStack_2e._2_2_ + -0x10,uVar2);
      .glue::GetPort(&iStack_88);
      .glue::CopyBits(&iStack_60,iStack_88 + 2,&uStack_68,&uStack_70,0,0);
    }
  }
  return;
}


// ==== .MyMenuDef @ 100a8360 ====
// CyDecompAt: created, body 100a8360-100a840f

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _MyMenuDef(short param_1)

{
  undefined2 uStack_16;
  undefined2 uStack_14;
  
  uStack_16 = (undefined2)uRam100d3e0c;
  uStack_14 = (undefined2)((uint)uRam100d3e10 >> 0x10);
  *(ushort *)(*(int *)CONCAT22(uStack_16,uStack_14) + 4) =
       *(ushort *)(*(int *)CONCAT22(uStack_16,uStack_14) + 4) | 0x4000;
  if (param_1 == 2) {
    return;
  }
  if (1 < param_1) {
    if (3 < param_1) {
      return;
    }
    return;
  }
  if (param_1 == 0) {
    return;
  }
  if (-1 < param_1) {
    return;
  }
  return;
}


// ==== .__dt__14TScrollBarCDEFFv @ 100a8754 ====
// CyDecompAt: created, body 100a8754-100a87b7

undefined4 * ___dt__14TScrollBarCDEFFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d7bc0;
    .debug::___dt__5TCDEFFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .GetPreferedCTable__14TScrollBarCDEFFv @ 100a87e4 ====
// CyDecompAt: created, body 100a87e4-100a87ef

undefined4 _GetPreferedCTable__14TScrollBarCDEFFv(void)

{
  return *(undefined4 *)PTR_DAT_100cdc78;
}


// ==== .__dt__12TProgBarCDEFFv @ 100a8828 ====
// CyDecompAt: created, body 100a8828-100a888b

undefined4 * ___dt__12TProgBarCDEFFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d7c38;
    .debug::___dt__5TCDEFFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .GetPreferedCTable__12TProgBarCDEFFv @ 100a88b8 ====
// CyDecompAt: created, body 100a88b8-100a88c3

undefined4 _GetPreferedCTable__12TProgBarCDEFFv(void)

{
  return *(undefined4 *)PTR_DAT_100cdc78;
}


// ==== .__dt__15TEditNumberCDEFFv @ 100a88fc ====
// CyDecompAt: created, body 100a88fc-100a895f

undefined4 * ___dt__15TEditNumberCDEFFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d7cb0;
    .debug::___dt__5TCDEFFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .GetPreferedCTable__15TEditNumberCDEFFv @ 100a898c ====
// CyDecompAt: created, body 100a898c-100a8997

undefined4 _GetPreferedCTable__15TEditNumberCDEFFv(void)

{
  return *(undefined4 *)PTR_DAT_100cdc78;
}


// ==== .__dt__11TNumberCDEFFv @ 100a89d4 ====
// CyDecompAt: created, body 100a89d4-100a8a37

undefined4 * ___dt__11TNumberCDEFFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d7d28;
    .debug::___dt__5TCDEFFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .GetPreferedCTable__11TNumberCDEFFv @ 100a8a60 ====
// CyDecompAt: created, body 100a8a60-100a8a6b

undefined4 _GetPreferedCTable__11TNumberCDEFFv(void)

{
  return *(undefined4 *)PTR_DAT_100cdc78;
}


// ==== .__dt__16TRadioButtonCDEFFv @ 100a8aa4 ====
// CyDecompAt: created, body 100a8aa4-100a8b07

undefined4 * ___dt__16TRadioButtonCDEFFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d7da0;
    .debug::___dt__5TCDEFFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .GetPreferedCTable__16TRadioButtonCDEFFv @ 100a8b38 ====
// CyDecompAt: created, body 100a8b38-100a8b43

undefined4 _GetPreferedCTable__16TRadioButtonCDEFFv(void)

{
  return *(undefined4 *)PTR_DAT_100cdc78;
}


// ==== .__dt__16TCheckButtonCDEFFv @ 100a8b80 ====
// CyDecompAt: created, body 100a8b80-100a8be3

undefined4 * ___dt__16TCheckButtonCDEFFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d7e18;
    .debug::___dt__5TCDEFFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .GetPreferedCTable__16TCheckButtonCDEFFv @ 100a8c14 ====
// CyDecompAt: created, body 100a8c14-100a8c1f

undefined4 _GetPreferedCTable__16TCheckButtonCDEFFv(void)

{
  return *(undefined4 *)PTR_DAT_100cdc78;
}


// ==== .__dt__15TPushButtonCDEFFv @ 100a8c5c ====
// CyDecompAt: created, body 100a8c5c-100a8cbf

undefined4 * ___dt__15TPushButtonCDEFFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d7e90;
    .debug::___dt__5TCDEFFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .GetPreferedCTable__15TPushButtonCDEFFv @ 100a8cec ====
// CyDecompAt: created, body 100a8cec-100a8cf7

undefined4 _GetPreferedCTable__15TPushButtonCDEFFv(void)

{
  return *(undefined4 *)PTR_DAT_100cdc78;
}


// ==== .__dt__11TDrawerWDEFFv @ 100a8d34 ====
// CyDecompAt: created, body 100a8d34-100a8d97

undefined4 * ___dt__11TDrawerWDEFFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d7fb8;
    .debug::___dt__5TWDEFFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__15TThinBorderWDEFFv @ 100a8dc0 ====
// CyDecompAt: created, body 100a8dc0-100a8e23

undefined4 * ___dt__15TThinBorderWDEFFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d8050;
    .debug::___dt__5TWDEFFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__11TBorderWDEFFv @ 100a8e50 ====
// CyDecompAt: created, body 100a8e50-100a8eb3

undefined4 * ___dt__11TBorderWDEFFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d809c;
    .debug::___dt__5TWDEFFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__Q23std84vector<Q214TInventoryPile9PileEntry,Q23std39allocator<Q214TInventoryPile9PileEntry>>Fv @ 100a8fc4 ====
// CyDecompAt: created, body 100a8fc4-100a9033

int ___dt__Q23std84vector<Q214TInventoryPile9PileEntry,Q23std39allocator<Q214TInventoryPile9PileEntry>>Fv
              (int param_1,short param_2)

{
  if ((param_1 != 0) &&
     (.debug::
      _tear_down__Q23std84vector<Q214TInventoryPile9PileEntry,Q23std39allocator<Q214TInventoryPile9PileEntry>>Fv
                (param_1), 0 < param_2)) {
    FUN_100be848(param_1);
  }
  return param_1;
}


// ==== .DrawIntoPort__14TInventoryPileFP8GrafPort @ 100a948c ====
// CyDecompAt: created, body 100a948c-100a9553

void _DrawIntoPort__14TInventoryPileFP8GrafPort(int param_1,undefined4 param_2)

{
  undefined *puVar1;
  undefined4 uStack_28;
  
  puVar1 = PTR_DAT_100cdc44;
  .glue::SetPort(param_2);
  for (uStack_28 = *(int *)(param_1 + 0xc) + *(int *)(param_1 + 8) * 6;
      uStack_28 != *(int *)(param_1 + 0xc); uStack_28 = uStack_28 + -6) {
    .debug::_DrawInventoryIcon__FssP8PropItem
              (*(short *)(uStack_28 + -4) + 1,*(short *)(uStack_28 + -2) + 1,
               *(int *)puVar1 + *(short *)(uStack_28 + -6) * 0x10);
  }
  return;
}


// ==== .__ct__Q29THeapDict12mappingentryFv @ 100aa448 ====
// CyDecompAt: created, body 100aa448-100aa453

void ___ct__Q29THeapDict12mappingentryFv(int param_1)

{
  *(undefined4 *)(param_1 + 4) = 0;
  return;
}


// ==== .MyMenuHook @ 100ac3ac ====
// CyDecompAt: created, body 100ac3ac-100ac417

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _MyMenuHook(void)

{
  int iVar1;
  int aiStack_8 [2];
  
  if (*_DAT_100cf004 != '\0') {
    iVar1 = .glue::ISpElement_GetSimpleState(*(undefined4 *)(PTR_DAT_100ceffc + 8),aiStack_8);
    if ((iVar1 == 0) && (aiStack_8[0] == 0)) {
      FUN_100c1ab4(*(undefined4 *)PTR_DAT_100ceff4);
    }
    .debug::_HandleISPseudoMouse__Fv();
  }
  return;
}


// ==== .__dt__8TAIDebugFv @ 100ad774 ====
// CyDecompAt: created, body 100ad774-100ad813

undefined4 * ___dt__8TAIDebugFv(undefined4 *param_1,short param_2)

{
  undefined4 uVar1;
  
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d8768;
    .glue::LDispose(param_1[8]);
    uVar1 = .glue::GetMenu(0x81);
    .glue::EnableItem(uVar1,0);
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d414c;
      .debug::___dt__7TWindowFv(param_1,0);
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .DialogItemRoutine__8TAIDebugFs @ 100ada10 ====
// CyDecompAt: created, body 100ada10-100ada67

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DialogItemRoutine__8TAIDebugFs(int param_1,short param_2)

{
  if (param_2 == 3) {
    return;
  }
  if (param_2 < 3) {
    if (param_2 != 1) {
      if (param_2 < 1) {
        return;
      }
      *(undefined1 *)(*(short *)(param_1 + 0x16) + _DAT_100cf0fc + -0xb0) = 0;
    }
  }
  else if (4 < param_2) {
    return;
  }
  *(short *)(param_1 + 0xc) = param_2;
  *(undefined1 *)(*(int *)PTR_DAT_100cdb84 + 0x1d) = 1;
  return;
}


// ==== .DialogDrawRoutine__8TAIDebugFs @ 100ada9c ====
// CyDecompAt: created, body 100ada9c-100adccf

void _DialogDrawRoutine__8TAIDebugFs(int param_1,undefined4 param_2)

{
  undefined *puVar1;
  uint uVar2;
  short sVar3;
  undefined1 auStack_168 [256];
  undefined1 auStack_68 [64];
  short sStack_28;
  short sStack_26;
  undefined1 auStack_20 [4];
  undefined1 auStack_1c [16];
  
  puVar1 = PTR_DAT_100cdbf0;
  .glue::GetDialogItem(*(undefined4 *)(param_1 + 4),param_2,auStack_1c,auStack_20,&sStack_28);
  sVar3 = (short)param_2;
  if (sVar3 == 3) {
    .glue::EraseRect(&sStack_28);
    .glue::LUpdate(*(undefined4 *)(*(int *)(param_1 + 4) + 0x18),*(undefined4 *)(param_1 + 0x20));
    .glue::FrameRect(&sStack_28);
  }
  else if (sVar3 == 5) {
    .glue::EraseRect(&sStack_28);
    .glue::MoveTo(sStack_26 + 3,sStack_28 + 0xc);
    .glue::DrawString(PTR_DAT_100cf0f8);
    uVar2 = **(int **)(param_1 + 0x1c) - (int)puVar1;
    .debug::_GetCharacterName__FsPcUc
              ((int)(short)((short)((int)uVar2 >> 5) +
                           (ushort)((int)uVar2 < 0 && (uVar2 & 0x1f) != 0)),auStack_68,0);
    sVar3 = FUN_100b6ce8(auStack_68);
    .glue::DrawText(auStack_68,0,(int)sVar3);
    .glue::MoveTo(sStack_26 + 3,sStack_28 + 0x1b);
    .glue::DrawString(PTR_DAT_100cf0f4);
    if (*(int *)(*(int *)(param_1 + 0x1c) + 0x1c) == 0) {
      .glue::DrawString(PTR_DAT_100cf0f0);
    }
    else {
      uVar2 = **(int **)(*(int *)(param_1 + 0x1c) + 0x1c) - (int)puVar1;
      .debug::_GetCharacterName__FsPcUc
                ((int)(short)((short)((int)uVar2 >> 5) +
                             (ushort)((int)uVar2 < 0 && (uVar2 & 0x1f) != 0)),auStack_68,0);
      sVar3 = FUN_100b6ce8(auStack_68);
      .glue::DrawText(auStack_68,0,(int)sVar3);
    }
    .glue::MoveTo(sStack_26 + 3,sStack_28 + 0x2a);
    .debug::_GetCombatAIName__FsPUc((int)*(short *)(param_1 + 0x16),auStack_168);
    .glue::DrawString(PTR_DAT_100cf0ec);
    .glue::DrawString(auStack_168);
    .glue::FrameRect(&sStack_28);
  }
  else if (sVar3 == 6) {
    uVar2 = **(int **)(param_1 + 0x1c) - (int)puVar1;
    .debug::_DrawPortrait__Fssss
              ((int)sStack_26,(int)sStack_28,
               (int)(short)((short)((int)uVar2 >> 5) +
                           (ushort)((int)uVar2 < 0 && (uVar2 & 0x1f) != 0)),0x24);
  }
  return;
}


// ==== .DrawRoutine__8TAIDebugFv @ 100add04 ====
// CyDecompAt: created, body 100add04-100add2f

void _DrawRoutine__8TAIDebugFv(undefined4 param_1)

{
  .debug::_DrawRoutine__7TDialogFv(param_1);
  return;
}


// ==== .MouseRoutine__8TAIDebugF5Points @ 100add5c ====
// CyDecompAt: created, body 100add5c-100addff

void _MouseRoutine__8TAIDebugF5Points(int param_1,undefined4 param_2,undefined4 param_3)

{
  char cVar1;
  undefined1 auStack_24 [2];
  short sStack_22;
  short sStack_1e;
  undefined1 auStack_1c [4];
  undefined1 auStack_18 [16];
  
  .glue::GetDialogItem(*(undefined4 *)(param_1 + 4),3,auStack_18,auStack_1c,auStack_24);
  sStack_22 = sStack_1e + -0x10;
  cVar1 = .glue::PtInRect(param_2,auStack_24);
  if (cVar1 == '\0') {
    .debug::_MouseRoutine__7TDialogF5Points(param_1,param_2,param_3);
  }
  else {
    .glue::LClick(param_2,param_3,*(undefined4 *)(param_1 + 0x20));
  }
  return;
}


// ==== .LDEFDraw__7TAIListFUcP4Rect5Pointss @ 100b1290 ====
// CyDecompAt: created, body 100b1290-100b139b

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _LDEFDraw__7TAIListFUcP4Rect5Pointss
               (undefined4 param_1,char param_2,short *param_3,undefined4 param_4)

{
  uint uVar1;
  short sVar2;
  short sStack_118;
  short sStack_116;
  undefined1 auStack_110 [268];
  
  sVar2 = (short)((uint)param_4 >> 0x10);
  .debug::_GetCombatAIName__FsPUc(sVar2 + 0xb0,auStack_110);
  .glue::GetFontInfo(&sStack_118);
  .glue::FillRect(param_3,PTR_DAT_100cdb94 + 0xc2);
  uVar1 = (int)*param_3 + (int)sStack_118 + (int)sStack_116 + (int)param_3[2];
  .glue::MoveTo(param_3[1] + 3,
                (((int)uVar1 >> 1) + (uint)((int)uVar1 < 0 && (uVar1 & 1) != 0)) - (int)sStack_116);
  if (*(char *)(_DAT_100cf0fc + sVar2) != '\0') {
    .glue::ForeColor(0xcd);
    .glue::DrawString(PTR_DAT_100cf020);
    .glue::ForeColor(0x21);
  }
  .glue::DrawString(auStack_110);
  if (param_2 != '\0') {
    uVar1 = .glue::LMGetHiliteMode();
    .glue::LMSetHiliteMode(uVar1 & 0xffffff7f);
    .glue::InvertRect(param_3);
  }
  return;
}


// ==== .DrawRoutine__17TEditUserBehaviorFv @ 100b1588 ====
// CyDecompAt: created, body 100b1588-100b15db

void _DrawRoutine__17TEditUserBehaviorFv(int param_1)

{
  undefined4 uVar1;
  
  uVar1 = .debug::_SetTilePat__Fs(0x1a4);
  .glue::FillCRect(*(int *)(param_1 + 4) + 0x10,uVar1);
  .debug::_DrawRoutine__7TDialogFv(param_1);
  return;
}


// ==== .__dt__17TEditUserBehaviorFv @ 100b1614 ====
// CyDecompAt: created, body 100b1614-100b16c7

undefined4 * ___dt__17TEditUserBehaviorFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d862c;
    if (param_1[5] != 0) {
      FUN_100c50e8(param_1[5],1);
    }
    if (param_1[1] != 0) {
      .glue::DisposeDialog(param_1[1]);
    }
    param_1[1] = 0;
    if (param_1 != (undefined4 *)0x0) {
      *param_1 = &PTR_PTR_100d414c;
      .debug::___dt__7TWindowFv(param_1,0);
    }
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__7TAIListFv @ 100b16f8 ====
// CyDecompAt: created, body 100b16f8-100b175b

undefined4 * ___dt__7TAIListFv(undefined4 *param_1,short param_2)

{
  if (param_1 != (undefined4 *)0x0) {
    *param_1 = &PTR_PTR_100d86f4;
    .debug::___dt__8TListBoxFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .DialogItemRoutine__17TEditUserBehaviorFs @ 100b1780 ====
// CyDecompAt: created, body 100b1780-100b18eb

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _DialogItemRoutine__17TEditUserBehaviorFs(int param_1,short param_2)

{
  undefined *puVar1;
  char cVar2;
  undefined4 uStack_88;
  undefined4 auStack_84 [4];
  undefined1 auStack_74 [70];
  undefined4 auStack_2e [6];
  
  puVar1 = PTR_DAT_100cdb84;
  if (param_2 != 3) {
    if (param_2 < 3) {
      if (param_2 == 1) {
        *(undefined1 *)(*(int *)PTR_DAT_100cdb84 + 0x1d) = 1;
      }
      else if (0 < param_2) {
        auStack_2e[0] = _DAT_100d85e8;
        cVar2 = .glue::LGetSelect(1,auStack_2e,*(undefined4 *)(*(int *)(param_1 + 0x14) + 4));
        if (cVar2 != '\0') {
          auStack_84[0] = 0x54455854;
          cVar2 = FUN_100c50e8(*(undefined4 *)puVar1,auStack_74,1,auStack_84,1,PTR_DAT_100cf014);
          FUN_100c50e8();
          if (cVar2 != '\0') {
            .debug::_CompileAIFile__FR6FSSpecs(auStack_74,auStack_2e[0]._0_2_ + 0xb0);
            .glue::InvalRect(*(int *)(param_1 + 4) + 0x10);
          }
        }
      }
    }
    else if (param_2 < 5) {
      uStack_88 = _DAT_100d85ec;
      cVar2 = .glue::LGetSelect(1,&uStack_88,*(undefined4 *)(*(int *)(param_1 + 0x14) + 4));
      if (cVar2 != '\0') {
        *(bool *)(_DAT_100cf0fc + uStack_88._0_2_) =
             *(char *)(_DAT_100cf0fc + uStack_88._0_2_) == '\0';
        .glue::InvalRect(*(int *)(param_1 + 4) + 0x10);
      }
    }
  }
  return;
}


// ==== .DialogDrawRoutine__17TEditUserBehaviorFs @ 100b1928 ====
// CyDecompAt: created, body 100b1928-100b19a7

void _DialogDrawRoutine__17TEditUserBehaviorFs(int param_1,undefined4 param_2)

{
  undefined1 auStack_18 [8];
  undefined1 auStack_10 [4];
  undefined1 auStack_c [4];
  
  .glue::GetDialogItem(*(undefined4 *)(param_1 + 4),param_2,auStack_c,auStack_10,auStack_18);
  if ((short)param_2 == 3) {
    FUN_100c50e8(*(undefined4 *)(param_1 + 0x14),*(undefined4 *)(*(int *)(param_1 + 4) + 0x18));
    .glue::FrameRect(auStack_18);
  }
  return;
}


// ==== .MouseRoutine__17TEditUserBehaviorF5Points @ 100b19e4 ====
// CyDecompAt: created, body 100b19e4-100b1afb

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _MouseRoutine__17TEditUserBehaviorF5Points(int param_1,undefined4 param_2,undefined4 param_3)

{
  char cVar1;
  undefined4 auStack_28 [2];
  undefined1 auStack_20 [8];
  undefined1 auStack_18 [4];
  undefined1 auStack_14 [8];
  
  .glue::GetDialogItem(*(undefined4 *)(param_1 + 4),3,auStack_14,auStack_18,auStack_20);
  cVar1 = .glue::PtInRect(param_2,auStack_20);
  if (cVar1 == '\0') {
    .debug::_MouseRoutine__7TDialogF5Points(param_1,param_2,param_3);
  }
  else {
    FUN_100c50e8(*(undefined4 *)(param_1 + 0x14),param_2,param_3);
    auStack_28[0] = _DAT_100d85f0;
    cVar1 = .glue::LGetSelect(1,auStack_28,*(undefined4 *)(*(int *)(param_1 + 0x14) + 4));
    if (cVar1 == '\0') {
      .glue::HiliteControl(*(undefined4 *)(param_1 + 0xc),0xff);
      .glue::HiliteControl(*(undefined4 *)(param_1 + 0x10),0xff);
    }
    else {
      .glue::HiliteControl(*(undefined4 *)(param_1 + 0xc),0);
      .glue::HiliteControl(*(undefined4 *)(param_1 + 0x10),0);
    }
  }
  return;
}


// ==== .AuditStartup__6TAuditFv @ 100b1e80 ====
// CyDecompAt: created, body 100b1e80-100b1e83

void _AuditStartup__6TAuditFv(void)

{
  return;
}

