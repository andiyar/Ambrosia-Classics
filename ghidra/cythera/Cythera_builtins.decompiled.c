
// ==== Builtin_A0 @ 10083ca8 (Builtin_A0) ====

void Builtin_A0(int *param_1,undefined4 *param_2)

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


// ==== Builtin_A1 @ 10083db0 (Builtin_A1) ====

void Builtin_A1(undefined4 *param_1,undefined4 *param_2)

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


// ==== Builtin_A2 @ 10093f90 (Builtin_A2) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_A2(undefined4 *param_1,undefined4 *param_2)

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


// ==== Builtin_A3 @ 100941f4 (Builtin_A3) ====

void Builtin_A3(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_A4 @ 10094258 (Builtin_A4) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_A4(undefined4 *param_1,uint *param_2)

{
  .debug::_ShowPortrait__13TConversationFss
            (*_DAT_100cdcc8,(int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
             (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4));
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_A5 @ 1009430c (Builtin_A5) ====

void Builtin_A5(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_A6 @ 100943fc (Builtin_A6) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_A6(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_A7 @ 10094678 (Builtin_A7) ====

void Builtin_A7(undefined4 *param_1,uint *param_2)

{
  undefined4 uVar1;
  
  uVar1 = .debug::_GetPropParent__Fs((int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4));
  .debug::_DeleteProp__Fs((int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4));
  .debug::_Invalidate__16TInventoryWindowFss(uVar1,2);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_A8 @ 10094730 (Builtin_A8) ====

void Builtin_A8(uint *param_1,uint *param_2)

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


// ==== Builtin_A9 @ 10094954 (Builtin_A9) ====

void Builtin_A9(uint *param_1,uint *param_2)

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


// ==== Builtin_AA @ 1009491c (Builtin_AA) ====

void Builtin_AA(undefined4 *param_1)

{
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_AB @ 10094a24 (Builtin_AB) ====

void Builtin_AB(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_AC @ 10094bbc (Builtin_AC) ====

void Builtin_AC(uint *param_1,uint *param_2)

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


// ==== Builtin_AD @ 10094c80 (Builtin_AD) ====

void Builtin_AD(uint *param_1,uint *param_2)

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


// ==== Builtin_AE @ 10094e44 (Builtin_AE) ====

void Builtin_AE(uint *param_1,uint *param_2)

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


// ==== Builtin_AF @ 10094fb4 (Builtin_AF) ====

void Builtin_AF(uint *param_1,uint *param_2)

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


// ==== Builtin_B0 @ 10095118 (Builtin_B0) ====

void Builtin_B0(uint *param_1,uint *param_2)

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


// ==== Builtin_B1 @ 10095244 (Builtin_B1) ====

void Builtin_B1(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_B2 @ 1009541c (Builtin_B2) ====

void Builtin_B2(uint *param_1,uint *param_2)

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


// ==== Builtin_B3 @ 10095544 (Builtin_B3) ====

void Builtin_B3(uint *param_1,uint *param_2)

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


// ==== Builtin_B4 @ 100955fc (Builtin_B4) ====

void Builtin_B4(uint *param_1,int *param_2)

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


// ==== Builtin_B5 @ 100956b4 (Builtin_B5) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_B5(uint *param_1)

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


// ==== Builtin_B6 @ 10095770 (Builtin_B6) ====

void Builtin_B6(undefined4 *param_1)

{
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_B7 @ 100957a8 (Builtin_B7) ====

void Builtin_B7(uint *param_1,uint *param_2)

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


// ==== Builtin_B8 @ 10095868 (Builtin_B8) ====

void Builtin_B8(uint *param_1,uint *param_2)

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


// ==== Builtin_B9 @ 10095918 (Builtin_B9) ====

void Builtin_B9(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_BA @ 10095a10 (Builtin_BA) ====

void Builtin_BA(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_BB @ 10095af0 (Builtin_BB) ====

void Builtin_BB(uint *param_1,undefined4 *param_2)

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


// ==== Builtin_BC @ 10095bc0 (Builtin_BC) ====

void Builtin_BC(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_BD @ 10096058 (Builtin_BD) ====

void Builtin_BD(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_BE @ 100991b8 (Builtin_BE) ====

void Builtin_BE(undefined4 *param_1)

{
  .debug::_RecalcPartyLight__13TStatusWindowFv(*(undefined4 *)PTR_DAT_100cdb98);
  .debug::_DoTicks__11TGameViewerFlUc(*(undefined4 *)PTR_DAT_100cdbb8,0,0);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_BF @ 10098e60 (Builtin_BF) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_BF(undefined4 *param_1,uint *param_2)

{
  .debug::_TeleportTo__8TGameSysFsss
            (*_DAT_100cdcd0,(int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
             (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4),
             (int)(short)((int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4));
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_C0 @ 10096798 (Builtin_C0) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_C0(uint *param_1,int *param_2)

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


// ==== Builtin_C1 @ 10096dec (Builtin_C1) ====

void Builtin_C1(undefined4 *param_1,uint *param_2)

{
  .debug::_AddAbility__8TSpellFXFss
            ((int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
             (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4));
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_C2 @ 10096e80 (Builtin_C2) ====

void Builtin_C2(undefined4 *param_1,uint *param_2)

{
  .debug::_RemoveAbility__8TSpellFXFss
            ((int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
             (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4));
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_C3 @ 10096f14 (Builtin_C3) ====

void Builtin_C3(undefined4 *param_1,uint *param_2)

{
  .debug::_TempAbility__8TSpellFXFssUs
            ((int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
             (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4),
             (int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4 & 0xffff);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_C4 @ 10096fb8 (Builtin_C4) ====

void Builtin_C4(uint *param_1,uint *param_2)

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


// ==== Builtin_C5 @ 10098418 (Builtin_C5) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_C5(undefined4 *param_1,uint *param_2)

{
  .debug::_SendSignal__8TGameSysFs
            (*_DAT_100cdcd0,(int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4));
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_C6 @ 100984a0 (Builtin_C6) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_C6(undefined4 *param_1,undefined4 *param_2)

{
  .debug::_ShortName__8TGameSysFs(*_DAT_100cdcd0,(int)(short)*param_2);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_C7 @ 10097080 (Builtin_C7) ====

void Builtin_C7(uint *param_1,undefined4 *param_2)

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


// ==== Builtin_C8 @ 100971e0 (Builtin_C8) ====

void Builtin_C8(uint *param_1,undefined4 *param_2)

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


// ==== Builtin_C9 @ 100973bc (Builtin_C9) ====

void Builtin_C9(uint *param_1,undefined4 *param_2)

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


// ==== Builtin_CA @ 100975b8 (Builtin_CA) ====

void Builtin_CA(uint *param_1,undefined4 *param_2)

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


// ==== Builtin_CB @ 100976fc (Builtin_CB) ====

void Builtin_CB(uint *param_1,undefined4 *param_2)

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


// ==== Builtin_CC @ 10097ce8 (Builtin_CC) ====

void Builtin_CC(uint *param_1,undefined4 *param_2)

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


// ==== Builtin_CD @ 10097b58 (Builtin_CD) ====

void Builtin_CD(uint *param_1,undefined4 *param_2)

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


// ==== Builtin_CE @ 10098028 (Builtin_CE) ====

void Builtin_CE(uint *param_1,undefined4 *param_2)

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


// ==== Builtin_CF @ 10097edc (Builtin_CF) ====

void Builtin_CF(uint *param_1,undefined4 *param_2)

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


// ==== Builtin_D0 @ 10098204 (Builtin_D0) ====

void Builtin_D0(uint *param_1,undefined4 *param_2)

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


// ==== Builtin_D1 @ 100978f0 (Builtin_D1) ====

void Builtin_D1(uint *param_1,undefined4 *param_2)

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


// ==== Builtin_D2 @ 1009851c (Builtin_D2) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_D2(undefined4 *param_1,uint *param_2)

{
  .debug::_PlayNote__6TAudioFsss
            (_DAT_100cdd24,(int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
             (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4),
             (int)(short)((int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4));
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_D3 @ 100985c0 (Builtin_D3) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_D3(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_D4 @ 1009874c (Builtin_D4) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_D4(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_D5 @ 100988dc (Builtin_D5) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_D5(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_D6 @ 10098994 (Builtin_D6) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_D6(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_D7 @ 10098a54 (Builtin_D7) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_D7(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_D8 @ 10098be4 (Builtin_D8) ====

void Builtin_D8(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_D9 @ 10098ca0 (Builtin_D9) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_D9(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_DA @ 10098d78 (Builtin_DA) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_DA(undefined4 *param_1,undefined4 *param_2)

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


// ==== Builtin_DB @ 10098f08 (Builtin_DB) ====

void Builtin_DB(undefined4 *param_1,undefined4 *param_2)

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


// ==== Builtin_DC @ 10098fb0 (Builtin_DC) ====

void Builtin_DC(uint *param_1,uint *param_2)

{
  *param_1 = (uint)(byte)PTR_DAT_100cdbbc[(int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4];
  return;
}


// ==== Builtin_DD @ 10098ff8 (Builtin_DD) ====

void Builtin_DD(undefined4 *param_1,uint *param_2)

{
  undefined *puVar1;
  
  puVar1 = PTR_DAT_100cdbb0;
  PTR_DAT_100cdbbc[(int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4] =
       (char)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4);
  *param_1 = *(undefined4 *)puVar1;
  return;
}


// ==== Builtin_DE @ 1009904c (Builtin_DE) ====

void Builtin_DE(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_DF @ 100990cc (Builtin_DF) ====

void Builtin_DF(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_E0 @ 1009abd4 (Builtin_E0) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_E0(undefined4 *param_1)

{
  .debug::_ScheduleTime__FsUc((int)(short)(_DAT_100d3e18 >> 0xc),0);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_E1 @ 10099720 (Builtin_E1) ====

void Builtin_E1(undefined4 *param_1,undefined4 *param_2)

{
  .debug::_ShowMagic__11TGameViewerFssUc
            (*(undefined4 *)PTR_DAT_100cdbb8,(int)(short)*param_2,
             (int)(short)((int)(param_2[1] << 4 | (uint)param_2[1] >> 0x1c) >> 4),1);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_E2 @ 10099434 (Builtin_E2) ====

void Builtin_E2(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_E3 @ 100997b8 (Builtin_E3) ====

void Builtin_E3(undefined4 *param_1,uint *param_2)

{
  .debug::_ShowHit__11TGameViewerFsssUc
            (*(undefined4 *)PTR_DAT_100cdbb8,
             (int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),
             (int)(short)((int)(param_2[1] << 4 | param_2[1] >> 0x1c) >> 4),
             (int)(short)((int)(param_2[2] << 4 | param_2[2] >> 0x1c) >> 4),1);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_E4 @ 10099860 (Builtin_E4) ====

void Builtin_E4(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_E5 @ 100999b0 (Builtin_E5) ====

void Builtin_E5(undefined4 *param_1,ushort *param_2)

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


// ==== Builtin_E6 @ 10099ab0 (Builtin_E6) ====

void Builtin_E6(undefined4 *param_1,uint *param_2)

{
  undefined *puVar1;
  
  puVar1 = PTR_DAT_100cdbb0;
  *(short *)(*(int *)PTR_DAT_100cdbb8 + 0x20c28) =
       (short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4);
  *param_1 = *(undefined4 *)puVar1;
  return;
}


// ==== Builtin_E7 @ 10099b08 (Builtin_E7) ====

void Builtin_E7(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_E8 @ 1009a12c (Builtin_E8) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_E8(undefined4 *param_1)

{
  if (*_DAT_100cdcc8 == 0) {
    .debug::_BeginTalking__13TStatusWindowFv(*(undefined4 *)PTR_DAT_100cdb98);
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_E9 @ 1009a1b0 (Builtin_E9) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_E9(undefined4 *param_1)

{
  if (*_DAT_100cdcc8 != 0) {
    .debug::_EndTalking__13TStatusWindowFv(*(undefined4 *)PTR_DAT_100cdb98);
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_EA @ 1009a090 (Builtin_EA) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_EA(undefined4 *param_1)

{
  if (*_DAT_100cdcc8 != 0) {
    FUN_100c50e8();
    .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(_DAT_100cdd24,2);
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_EB @ 10099ff4 (Builtin_EB) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_EB(undefined4 *param_1)

{
  if (*_DAT_100cdcc8 != 0) {
    FUN_100c50e8();
    .debug::_PlayIFSound__6TAudioFQ26TAudio11EIntfSounds(_DAT_100cdd24,1);
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_EC @ 1009a234 (Builtin_EC) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_EC(undefined4 *param_1)

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


// ==== Builtin_ED @ 1009a354 (Builtin_ED) ====

void Builtin_ED(undefined4 *param_1)

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


// ==== Builtin_EE @ 1009a40c (Builtin_EE) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_EE(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_EF @ 10099cd4 (Builtin_EF) ====

void Builtin_EF(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_F0 @ 10099d9c (Builtin_F0) ====

void Builtin_F0(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_F1 @ 10099e78 (Builtin_F1) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_F1(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_F2 @ 1009aa14 (Builtin_F2) ====

void Builtin_F2(undefined4 *param_1,uint *param_2)

{
  .debug::_AddToDo__5TToDoFs5VAddr
            ((int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4),param_2[1]);
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_F3 @ 1009aa98 (Builtin_F3) ====

void Builtin_F3(undefined4 *param_1,uint *param_2)

{
  .debug::_DoneToDo__5TToDoFs((int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4));
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_F4 @ 10096d54 (Builtin_F4) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_F4(undefined4 *param_1,undefined4 *param_2)

{
  undefined4 uVar1;
  
  if (*_DAT_100cdcc8 != 0) {
    uVar1 = .debug::_VAddrToPtr__7TInterpF5VAddr(*param_2);
    .debug::_AddAnswer__13TConversationFPc(*_DAT_100cdcc8,uVar1);
  }
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_F5 @ 1009ab14 (Builtin_F5) ====

void Builtin_F5(uint *param_1,uint *param_2)

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


// ==== Builtin_F6 @ 100944d8 (Builtin_F6) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_F6(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_F7 @ 10099240 (Builtin_F7) ====

void Builtin_F7(undefined4 *param_1,uint *param_2)

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


// ==== Builtin_F8 @ 1009aec0 (Builtin_F8) ====

void Builtin_F8(uint *param_1,uint *param_2)

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


// ==== Builtin_F9 @ 1009ad40 (Builtin_F9) ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void Builtin_F9(uint *param_1)

{
  uint uVar1;
  
  uVar1 = (uint)_DAT_100d73f4;
  _DAT_100d73f4 = _DAT_100d73f4 + 1;
  *param_1 = uVar1 & 0xfffffff;
  return;
}


// ==== Builtin_FA @ 1009ac8c (Builtin_FA) ====

void Builtin_FA(uint *param_1,uint *param_2)

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


// ==== Builtin_FB @ 1009ac50 (Builtin_FB) ====

void Builtin_FB(undefined4 *param_1)

{
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_FC @ 1009ad94 (Builtin_FC) ====

void Builtin_FC(undefined4 *param_1,undefined4 *param_2)

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


// ==== Builtin_FD @ 1009ae38 (Builtin_FD) ====

void Builtin_FD(undefined4 *param_1,uint *param_2)

{
  .debug::_SetEraseColor__7TViewerFs
            (*(undefined4 *)PTR_DAT_100cdbb8,
             (int)(short)((int)(*param_2 << 4 | *param_2 >> 0x1c) >> 4));
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}


// ==== Builtin_FE @ 1009b12c (Builtin_FE) ====

void Builtin_FE(undefined4 *param_1)

{
  *param_1 = *(undefined4 *)PTR_DAT_100cdbb0;
  return;
}

