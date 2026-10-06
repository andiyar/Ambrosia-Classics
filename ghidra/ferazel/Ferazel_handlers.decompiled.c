
// ==== .MySleepProc @ 10005f5c ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 _MySleepProc(undefined4 param_1)

{
  char *pcVar1;
  char *pcVar2;
  
  pcVar2 = _DAT_100a0050;
  pcVar1 = pcRam1009fe3c;
  switch(param_1) {
  case 1:
  case 2:
  case 7:
  case 9:
    *_DAT_1009fe40 = 1;
    if (*pcVar2 != '\0') {
      *pcVar1 = '\x01';
    }
    break;
  case 3:
  case 4:
  case 8:
  case 0x14:
    *_DAT_1009fe40 = 0;
    if (*pcVar1 != '\0') {
      *_DAT_1009fe38 = 1;
    }
  }
  return 0;
}


// ==== .HandlePxSprite @ 10033378 ====

void _HandlePxSprite(int param_1)

{
  short sVar1;
  undefined *puVar2;
  int iVar3;
  short *psVar4;
  
  puVar2 = PTR_DAT_1009fe78;
  psVar4 = (short *)(PTR_DAT_1009fe78 + 2);
  iVar3 = (int)(short)*(undefined4 *)(param_1 + 0x154);
  *(short *)(param_1 + 0xc) =
       (short)*(undefined4 *)(param_1 + 0x14c) +
       (short)((uint)(*(short *)(PTR_DAT_1009fe78 + 2) * iVar3) >> 8);
  sVar1 = *(short *)puVar2;
  *(short *)(param_1 + 0xc) =
       ((short)*(undefined4 *)(param_1 + 0x14c) - (short)((uint)(*psVar4 * iVar3) >> 8)) + *psVar4;
  *(short *)(param_1 + 10) =
       ((short)*(undefined4 *)(param_1 + 0x150) -
       (short)((uint)((int)sVar1 * (int)(short)*(undefined4 *)(param_1 + 0x158)) >> 8)) +
       *(short *)puVar2 + 0xe8;
  return;
}


// ==== .SetupPxSprite @ 10033418 ====

void _SetupPxSprite(int param_1)

{
  undefined4 uVar1;
  
  .debug::_InitSprite();
  .glue::SetRect(param_1 + 0x34,0,0,0,0);
  uVar1 = uRam100a01c0;
  *(undefined2 *)(param_1 + 0x48) = 0x1ff;
  *(undefined1 *)(param_1 + 0xea) = 1;
  *(undefined2 *)(param_1 + 4) = 1;
  *(undefined1 *)(param_1 + 0x88) = 0;
  *(undefined4 *)(param_1 + 0x5c) = 0;
  *(undefined4 *)(param_1 + 0x1f8) = 0;
  *(undefined4 *)(param_1 + 0x4c) = uVar1;
  *(undefined4 *)(param_1 + 0xb8) = 0x80000;
  return;
}


// ==== .DoOpenAppAE @ 10033d94 ====

undefined4 _DoOpenAppAE(void)

{
  return 0;
}


// ==== .DoOpenDocAE @ 10033dbc ====

void _DoOpenDocAE(undefined4 param_1)

{
  undefined2 uVar1;
  undefined4 *puVar2;
  undefined4 *puVar3;
  undefined4 uVar4;
  short sVar5;
  undefined4 *puVar6;
  undefined4 *puVar7;
  short sVar8;
  int iVar9;
  undefined4 uStack_ca;
  undefined4 auStack_c2 [3];
  undefined2 auStack_b6 [35];
  undefined4 uStack_70;
  undefined1 auStack_6c [4];
  undefined4 auStack_68 [3];
  undefined2 auStack_5c [30];
  undefined1 auStack_20 [4];
  int iStack_1c;
  undefined1 auStack_18 [12];
  
  .glue::AEGetParamDesc(param_1,0x2d2d2d2d,0x6c697374,auStack_18);
  .glue::AECountItems(auStack_18,&iStack_1c);
  sVar8 = 1;
  while( true ) {
    if (iStack_1c < sVar8) {
      .debug::_MyGotRequiredParams(param_1);
      return;
    }
    sVar5 = .glue::AEGetNthPtr(auStack_18,(int)sVar8,0x66737320,auStack_6c,&uStack_70,auStack_68,
                               0x46,auStack_20);
    if (sVar5 == 0) break;
    sVar8 = sVar8 + 1;
  }
  iVar9 = 8;
  puVar2 = &uStack_70;
  puVar3 = &uStack_ca;
  do {
    puVar7 = puVar3;
    puVar6 = puVar2;
    uVar4 = puVar6[3];
    puVar7[2] = puVar6[2];
    puVar7[3] = uVar4;
    iVar9 = iVar9 + -1;
    puVar2 = puVar6 + 2;
    puVar3 = puVar7 + 2;
  } while (iVar9 != 0);
  uVar1 = *(undefined2 *)(puVar6 + 5);
  puVar7[4] = puVar6[4];
  *(undefined2 *)(puVar7 + 5) = uVar1;
  uStack_ca._2_1_ = 1;
  if (DAT_100a5106 != '\0') {
    .debug::_ContinueGame((int)&uStack_ca + 2);
  }
  .debug::_MyGotRequiredParams(param_1);
  return;
}


// ==== .DoPrintDocAE @ 10033efc ====

undefined4 _DoPrintDocAE(void)

{
  return 0xfffff954;
}


// ==== .DoQuitAppAE @ 10033f24 ====

void _DoQuitAppAE(undefined4 param_1)

{
  .debug::_Quit();
  .debug::_MyGotRequiredParams(param_1);
  return;
}


// ==== .TintFadeProc @ 10034f40 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 _TintFadeProc(undefined4 param_1,int param_2,undefined4 param_3,uint *param_4)

{
  short sVar1;
  uint *puVar2;
  uint uStack_a8;
  uint uStack_a4;
  uint uStack_a0;
  
  puVar2 = param_4;
  for (sVar1 = 0; (uint)(int)sVar1 < *param_4; sVar1 = sVar1 + 1) {
    uStack_a8 = puVar2[1];
    uStack_a4 = puVar2[2];
    uStack_a0 = puVar2[3];
    if (param_2 == 2) {
      uStack_a0 = FUN_10090a64();
      uStack_a8 = FUN_10090a64();
      uStack_a4 = FUN_10090a64();
    }
    else if (param_2 < 2) {
      if (param_2 == 0) {
        uStack_a8 = FUN_10090a64();
        uStack_a4 = FUN_10090a64();
        uStack_a0 = FUN_10090a64();
      }
      else if (-1 < param_2) {
        uStack_a4 = FUN_10090a64();
        uStack_a8 = FUN_10090a64();
        uStack_a0 = FUN_10090a64();
      }
    }
    else if (param_2 < 4) {
      uStack_a0 = FUN_10090a64();
      uStack_a4 = FUN_10090a64();
      uStack_a8 = FUN_10090a64();
    }
    puVar2[1] = uStack_a8;
    puVar2[2] = uStack_a4;
    puVar2 = puVar2 + 3;
    *puVar2 = uStack_a0;
  }
  .debug::_MusicAIFFTickle();
  return 0;
}


// ==== .STLoopCallBack @ 10047dd8 ====

void _STLoopCallBack(int param_1,undefined4 param_2,int param_3)

{
  if ((param_1 == 1) && (param_3 != 0)) {
    FUN_10091208(param_3);
  }
  return;
}


// ==== .SetupPlayerSprite @ 1004aefc ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupPlayerSprite(int param_1)

{
  undefined2 uVar1;
  undefined2 *puVar2;
  undefined2 *puVar3;
  undefined2 *puVar4;
  int iVar5;
  undefined *puVar6;
  undefined *puVar7;
  undefined *puVar8;
  undefined *puVar9;
  undefined *puVar10;
  undefined *puVar11;
  undefined1 *puVar12;
  undefined1 *puVar13;
  undefined4 uVar14;
  undefined2 *puVar15;
  short sVar16;
  undefined4 *puVar17;
  
  puVar11 = PTR_DAT_100a053c;
  puVar8 = PTR_DAT_100a0520;
  puVar7 = PTR_PTR_100a0518;
  puVar6 = PTR_DAT_100a0514;
  iVar5 = _DAT_1009ffc0;
  .debug::_InitSprite();
  .debug::_ClearPlayerVars();
  puVar17 = _DAT_100a0680;
  _DAT_100a5fd8 = 0xffff;
  *(undefined4 *)PTR_DAT_100a0558 = 0;
  puVar15 = _DAT_100a069c;
  *puVar17 = 0;
  puVar9 = PTR_DAT_100a0530;
  *puVar15 = 0;
  .glue::SetRect(puVar9,0x26,0x22,0x3e,0x55);
  puVar10 = PTR_PTR_100a052c;
  *(undefined2 *)(param_1 + 4) = 0x45;
  puVar9 = PTR_PTR_100a0528;
  *(undefined4 *)(param_1 + 0x2c) = 0;
  puVar2 = _DAT_1009fd44;
  *(undefined4 *)(param_1 + 0x24) = 0;
  puVar4 = _DAT_1009fe68;
  *(undefined4 *)(param_1 + 0x80) = 10;
  puVar3 = _DAT_1009fe64;
  puVar15 = _DAT_1009fd40;
  *(undefined2 *)(param_1 + 0xa4) = *(undefined2 *)(iVar5 + 4);
  *(undefined2 *)(param_1 + 0x110) = 0x1b8;
  *(undefined **)(param_1 + 0x4c) = puVar10;
  *(undefined4 *)(param_1 + 0x5c) = 0;
  *(undefined **)(param_1 + 0x1f8) = puVar9;
  uVar1 = *(undefined2 *)(param_1 + 8);
  *puVar2 = uVar1;
  *puVar4 = uVar1;
  uVar1 = *(undefined2 *)(param_1 + 6);
  *puVar15 = uVar1;
  *puVar3 = uVar1;
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  *(undefined4 *)(param_1 + 0xc0) = 0;
  .glue::SetRect(param_1 + 0x34,0x26,0x22,0x3e,0x55);
  uVar14 = .debug::_MTNewSprite(100,0,0,0x14,0x1ff,PTR_PTR_100a0524);
  puVar15 = _DAT_100a06a4;
  *_DAT_100a065c = uVar14;
  *puVar15 = 0;
  *(undefined2 *)(param_1 + 0x13c) = 0x100;
  *(undefined1 *)(param_1 + 0xe4) = 1;
  *(undefined2 *)(param_1 + 0x90) = 0x100;
  puVar15 = (undefined2 *)puVar8;
  for (sVar16 = 0; sVar16 < 6; sVar16 = sVar16 + 8) {
    puVar15[1] = 0xffff;
    *puVar15 = 0xffff;
    *(undefined1 *)(puVar15 + 2) = 0;
    *(undefined4 *)(puVar15 + 4) = 0;
    puVar15[9] = 0xffff;
    puVar15[8] = 0xffff;
    *(undefined1 *)(puVar15 + 10) = 0;
    *(undefined4 *)(puVar15 + 0xc) = 0;
    puVar15[0x11] = 0xffff;
    puVar15[0x10] = 0xffff;
    *(undefined1 *)(puVar15 + 0x12) = 0;
    *(undefined4 *)(puVar15 + 0x14) = 0;
    puVar15[0x19] = 0xffff;
    puVar15[0x18] = 0xffff;
    *(undefined1 *)(puVar15 + 0x1a) = 0;
    *(undefined4 *)(puVar15 + 0x1c) = 0;
    puVar15[0x21] = 0xffff;
    puVar15[0x20] = 0xffff;
    *(undefined1 *)(puVar15 + 0x22) = 0;
    *(undefined4 *)(puVar15 + 0x24) = 0;
    puVar15[0x29] = 0xffff;
    puVar15[0x28] = 0xffff;
    *(undefined1 *)(puVar15 + 0x2a) = 0;
    *(undefined4 *)(puVar15 + 0x2c) = 0;
    puVar15[0x31] = 0xffff;
    puVar15[0x30] = 0xffff;
    *(undefined1 *)(puVar15 + 0x32) = 0;
    *(undefined4 *)(puVar15 + 0x34) = 0;
    puVar15[0x39] = 0xffff;
    puVar15[0x38] = 0xffff;
    *(undefined1 *)(puVar15 + 0x3a) = 0;
    *(undefined4 *)(puVar15 + 0x3c) = 0;
    puVar15 = puVar15 + 0x40;
  }
  puVar15 = (undefined2 *)(puVar8 + sVar16 * 0x10);
  for (; sVar16 < 0xe; sVar16 = sVar16 + 1) {
    puVar15[1] = 0xffff;
    *puVar15 = 0xffff;
    *(undefined1 *)(puVar15 + 2) = 0;
    *(undefined4 *)(puVar15 + 4) = 0;
    puVar15 = puVar15 + 8;
  }
  puVar17 = (undefined4 *)PTR_DAT_100a051c;
  for (sVar16 = 0; puVar15 = _DAT_100a0688, sVar16 < 5; sVar16 = sVar16 + 1) {
    *(undefined2 *)((int)puVar17 + 10) = 0xffff;
    *(undefined2 *)(puVar17 + 2) = 0xffff;
    puVar17[1] = 0;
    *(undefined1 *)(puVar17 + 3) = 0;
    uVar14 = .debug::_MTNewSprite
                       (1,0xffffffff,0xffffffff,*(int *)(param_1 + 0x80) + -1,0x1ff,puVar7);
    *puVar17 = uVar14;
    puVar17 = puVar17 + 4;
  }
  *(undefined4 *)(puVar6 + 8) = 0;
  puVar2 = _DAT_100a068c;
  *(undefined4 *)(puVar6 + 0xc) = 0x30;
  puVar3 = _DAT_100a06d4;
  *(undefined4 *)(puVar6 + 0x10) = 0xa00;
  puVar7 = PTR_DAT_100a0560;
  *(undefined4 *)puVar6 = 0;
  puVar6[4] = 0;
  *(undefined2 *)puVar11 = 0;
  *(undefined4 *)(puVar6 + 0x1c) = 0x4800;
  *(undefined4 *)(puVar6 + 0x20) = 0x30;
  *(undefined4 *)(puVar6 + 0x24) = 0xa00;
  *(undefined4 *)(puVar6 + 0x14) = 0;
  puVar6[0x18] = 0;
  *(undefined2 *)puVar11 = 0;
  *(undefined4 *)(puVar6 + 0x30) = 0x9000;
  *(undefined4 *)(puVar6 + 0x34) = 0x30;
  *(undefined4 *)(puVar6 + 0x38) = 0xa00;
  *(undefined4 *)(puVar6 + 0x28) = 0;
  puVar6[0x2c] = 0;
  *(undefined2 *)puVar11 = 0;
  *(undefined4 *)(puVar6 + 0x44) = 0xd800;
  *(undefined4 *)(puVar6 + 0x48) = 0x30;
  *(undefined4 *)(puVar6 + 0x4c) = 0xa00;
  *(undefined4 *)(puVar6 + 0x3c) = 0;
  puVar6[0x40] = 0;
  *(undefined2 *)puVar11 = 0;
  *(undefined4 *)(puVar6 + 0x58) = 0x12000;
  *(undefined4 *)(puVar6 + 0x5c) = 0x30;
  *(undefined4 *)(puVar6 + 0x60) = 0xa00;
  *(undefined4 *)(puVar6 + 0x50) = 0;
  puVar6[0x54] = 0;
  *(undefined2 *)puVar11 = 0;
  *(undefined4 *)(puVar6 + 0x6c) = 0x16800;
  *(undefined4 *)(puVar6 + 0x70) = 0x30;
  *(undefined4 *)(puVar6 + 0x74) = 0xa00;
  *(undefined4 *)(puVar6 + 100) = 0;
  puVar6[0x68] = 0;
  *(undefined2 *)puVar11 = 0;
  *(undefined4 *)(puVar6 + 0x80) = 0x1b000;
  *(undefined4 *)(puVar6 + 0x84) = 0x30;
  *(undefined4 *)(puVar6 + 0x88) = 0xa00;
  *(undefined4 *)(puVar6 + 0x78) = 0;
  puVar6[0x7c] = 0;
  *(undefined2 *)puVar11 = 0;
  *(undefined4 *)(puVar6 + 0x94) = 0x1f800;
  *(undefined4 *)(puVar6 + 0x98) = 0x30;
  *(undefined4 *)(puVar6 + 0x9c) = 0xa00;
  *(undefined4 *)(puVar6 + 0x8c) = 0;
  puVar6[0x90] = 0;
  *(undefined2 *)puVar11 = 0;
  *puVar15 = 0;
  *puVar2 = 0;
  *puVar3 = 0;
  *puVar7 = 0;
  if (*(short *)(iVar5 + 0x16) == 0) {
    *(undefined1 *)(param_1 + 0x17e) = 0;
    _DAT_100a5f5c = 2;
    _DAT_100a5f5a = 2;
  }
  else {
    *(undefined1 *)(param_1 + 0x17e) = 1;
    _DAT_100a5f5c = 1;
    _DAT_100a5f5a = 1;
  }
  puVar6 = PTR_DAT_100a0594;
  *_DAT_100a06f0 = 0;
  puVar13 = _DAT_100a0568;
  *(undefined2 *)puVar6 = 0;
  puVar12 = _DAT_100a0564;
  *puVar13 = 0;
  puVar13 = _DAT_100a05e0;
  *puVar12 = 0;
  *puVar13 = 0;
  return;
}


// ==== .HandleTrailSprite @ 1004b354 ====

void _HandleTrailSprite(undefined4 param_1)

{
  .debug::_StandardSpriteHandles();
  .debug::_StandardSpriteCleanup(param_1);
  return;
}


// ==== .SetupTrailSprite @ 1004b3b4 ====

void _SetupTrailSprite(int param_1)

{
  .debug::_InitSprite();
  *(undefined **)(param_1 + 0x4c) = PTR_PTR_100a0508;
  return;
}


// ==== .HandleShadowSprite @ 1004b4f0 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleShadowSprite(int param_1)

{
  short sVar1;
  int iVar2;
  undefined *puVar3;
  undefined *puVar4;
  short *psVar5;
  undefined *puVar6;
  undefined *puVar7;
  short sVar8;
  
  puVar7 = PTR_DAT_100a0608;
  puVar6 = PTR_DAT_100a05c0;
  puVar4 = PTR_DAT_100a0590;
  puVar3 = PTR_DAT_100a0520;
  if (*PTR_DAT_100a0654 != '\0') {
    iVar2 = ((int)*(short *)PTR_DAT_100a0590 >> 1) * 0x10;
    if (*(short *)(PTR_DAT_100a0520 + iVar2 + 2) == -1) {
      *(undefined4 *)(param_1 + 0xc0) = 0;
    }
    else {
      sVar8 = *_DAT_100a06d4;
      if ((sVar8 < 1) || ((sVar1 = *_DAT_100a06d0, 3 < sVar1 && (*PTR_DAT_100a0674 == '\0')))) {
        sVar8 = *_DAT_100a071c;
        if ((sVar8 == 0) || (PTR_DAT_100a0520[iVar2 + 4] == '\0')) {
          if (*PTR_DAT_100a0674 == '\0') {
            sVar8 = *(short *)PTR_DAT_100a05c0;
            if (sVar8 < 1) {
              if (sVar8 < 0) {
                *(short *)PTR_DAT_100a05c0 = sVar8 + 1;
              }
            }
            else {
              *(short *)PTR_DAT_100a05c0 = sVar8 + -1;
            }
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar3 + iVar2 + 8);
          }
          else if (PTR_DAT_100a0520[iVar2 + 4] == '\0') {
            .debug::_ShadowBob();
            *(undefined4 *)(param_1 + 0xc0) =
                 *(undefined4 *)(puVar3 + ((int)*(short *)puVar4 >> 1) * 0x10 + 8);
          }
          else {
            *(int *)(param_1 + 0xc0) =
                 *_DAT_100a07ec + ((int)*(short *)PTR_DAT_100a0590 >> 1) * 0x34;
            *puVar7 = 0;
            sVar8 = *(short *)puVar6;
            if (sVar8 < 1) {
              if (sVar8 < 0) {
                *(short *)puVar6 = sVar8 + 1;
              }
            }
            else {
              *(short *)puVar6 = sVar8 + -1;
            }
          }
        }
        else {
          sVar1 = *(short *)PTR_DAT_100a05c0;
          if (sVar1 < 1) {
            if (sVar1 < 0) {
              *(short *)PTR_DAT_100a05c0 = sVar1 + 1;
            }
          }
          else {
            *(short *)PTR_DAT_100a05c0 = sVar1 + -1;
          }
          *(int *)(param_1 + 0xc0) = *_DAT_100a07e0 + (sVar8 + -1) * 0x34;
        }
      }
      else {
        if (*PTR_DAT_100a0674 == '\0') {
          if (sVar1 == 2) {
            sVar8 = 2;
          }
          else if (sVar1 == 3) {
            sVar8 = 1;
          }
        }
        if (PTR_DAT_100a0520[iVar2 + 4] == '\0') {
          .debug::_ShadowBob();
        }
        else {
          sVar1 = *(short *)PTR_DAT_100a05c0;
          if (sVar1 < 1) {
            if (sVar1 < 0) {
              *(short *)PTR_DAT_100a05c0 = sVar1 + 1;
            }
          }
          else {
            *(short *)PTR_DAT_100a05c0 = sVar1 + -1;
          }
        }
        *(int *)(param_1 + 0xc0) = *_DAT_100a07d4 + (sVar8 + -1) * 0x34;
      }
    }
    psVar5 = _DAT_100a05bc;
    *(undefined4 *)(param_1 + 10) = *(undefined4 *)(puVar3 + ((int)*(short *)puVar4 >> 1) * 0x10);
    *(undefined *)(param_1 + 0x17e) = puVar3[((int)*(short *)puVar4 >> 1) * 0x10 + 0xc];
    *(undefined4 *)(param_1 + 0xb8) = 0x1000b;
    *(short *)(param_1 + 0xc) = *(short *)(param_1 + 0xc) + (*psVar5 >> 1);
    *(short *)(param_1 + 10) = *(short *)(param_1 + 10) + *(short *)puVar6;
    *(undefined1 *)(param_1 + 0x88) = 0;
    return;
  }
  *(undefined4 *)(param_1 + 0xc0) = 0;
  return;
}


// ==== .SetupShadowSprite @ 1004b7d4 ====

void _SetupShadowSprite(int param_1)

{
  undefined *puVar1;
  
  .debug::_InitSprite();
  puVar1 = PTR_PTR_100a0500;
  *(undefined4 *)(param_1 + 0x5c) = 0;
  *(undefined4 *)(param_1 + 0x1f8) = 0;
  *(undefined **)(param_1 + 0x4c) = puVar1;
  return;
}


// ==== .SetupHeldItemSprite @ 1004bdd0 ====

void _SetupHeldItemSprite(int param_1)

{
  undefined *puVar1;
  
  .debug::_InitSprite();
  puVar1 = PTR_PTR_100a04f8;
  *(undefined2 *)(param_1 + 4) = 100;
  *(undefined4 *)(param_1 + 0xc0) = 0;
  *(undefined2 *)(param_1 + 10) = 0;
  *(undefined2 *)(param_1 + 0xc) = 0;
  *(undefined4 *)(param_1 + 0x80) = 0x14;
  *(undefined4 *)(param_1 + 0x5c) = 0;
  *(undefined4 *)(param_1 + 0x1f8) = 0;
  *(undefined **)(param_1 + 0x4c) = puVar1;
  .glue::SetRect(param_1 + 0x34,0xfffffffe,2,0x1a,0x16);
  return;
}


// ==== .HandleHeldItemSprite @ 1004be74 ====

void _HandleHeldItemSprite(int param_1)

{
  undefined4 uVar1;
  int iVar2;
  
  *(undefined4 *)(param_1 + 0x2c) = 0;
  *(undefined4 *)(param_1 + 0x24) = 0;
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
  *(undefined2 *)(param_1 + 8) = *(undefined2 *)(param_1 + 0xc);
  *(undefined2 *)(param_1 + 6) = *(undefined2 *)(param_1 + 10);
  *(undefined4 *)(param_1 + 0x80) = 0x14;
  *(undefined2 *)(param_1 + 4) = 100;
  iVar2 = *(int *)(param_1 + 0xc0);
  if (iVar2 != 0) {
    uVar1 = *(undefined4 *)(iVar2 + 0xc);
    *(undefined4 *)(param_1 + 0x34) = *(undefined4 *)(iVar2 + 8);
    *(undefined4 *)(param_1 + 0x38) = uVar1;
    *(short *)(param_1 + 0x36) = *(short *)(param_1 + 0x36) + 1;
    *(short *)(param_1 + 0x3a) = *(short *)(param_1 + 0x3a) + -1;
  }
  if (-1 < *(short *)(param_1 + 0xa6)) {
    return;
  }
  *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
  return;
}


// ==== .HandlePlayerSprite @ 1004d5fc ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */
/* WARNING: Restarted to delay deadcode elimination for space: ram */

void _HandlePlayerSprite(int param_1)

{
  undefined4 *puVar1;
  char cVar2;
  bool bVar3;
  undefined1 *puVar4;
  undefined *puVar5;
  undefined2 *puVar6;
  undefined2 *puVar7;
  char *pcVar8;
  int iVar9;
  undefined *puVar10;
  undefined *puVar11;
  short *psVar12;
  short *psVar13;
  short *psVar14;
  int *piVar15;
  short *psVar16;
  short *psVar17;
  ushort *puVar18;
  undefined *puVar19;
  undefined *puVar20;
  short *psVar21;
  undefined *puVar22;
  short *psVar23;
  short *psVar24;
  short *psVar25;
  short *psVar26;
  ushort uVar28;
  int iVar27;
  undefined2 uVar29;
  short sVar36;
  undefined4 uVar30;
  uint uVar31;
  int iVar32;
  char cVar38;
  int *piVar33;
  int iVar34;
  short sVar37;
  undefined4 *puVar35;
  undefined4 *puVar39;
  undefined1 uVar40;
  short *psVar41;
  undefined2 uStack_c6;
  undefined2 uStack_c4;
  undefined2 uStack_c2;
  undefined2 uStack_c0;
  undefined2 auStack_be [5];
  undefined1 auStack_b4 [4];
  undefined1 auStack_b0 [22];
  short sStack_9a;
  short sStack_98;
  undefined1 auStack_94 [22];
  short sStack_7e;
  undefined2 uStack_7c;
  short sStack_6e;
  bool bStack_6c;
  char cStack_6b;
  short sStack_6a;
  short sStack_68;
  undefined4 uStack_64;
  undefined8 uStack_60;
  undefined8 uStack_58;
  
  psVar26 = _DAT_100a0758;
  psVar25 = _DAT_100a0748;
  psVar24 = _DAT_100a0718;
  psVar23 = _DAT_100a0714;
  puVar22 = PTR_DAT_100a0710;
  psVar21 = _DAT_100a06d4;
  puVar20 = PTR_DAT_100a06c8;
  puVar19 = PTR_DAT_100a06c4;
  puVar18 = _DAT_100a069c;
  psVar17 = _DAT_100a068c;
  psVar16 = _DAT_100a0688;
  piVar15 = _DAT_100a0680;
  puVar5 = PTR_DAT_100a0668;
  psVar14 = _DAT_100a05dc;
  psVar12 = _DAT_100a05d4;
  psVar41 = _DAT_100a0574;
  puVar39 = _DAT_100a03cc;
  iVar9 = _DAT_1009ffc0;
  pcVar8 = _DAT_1009fec4;
  cStack_6b = '\0';
  *(undefined4 *)PTR_DAT_100a0558 = *(undefined4 *)(param_1 + 0xdc);
  _DAT_100a5f5c = _DAT_100a5f5a;
  *puVar19 = 0;
  if (*pcVar8 != '\0') {
    sVar36 = FUN_100916dc(*_DAT_1009fe20);
    if (sVar36 == 0) {
      uVar30 = .debug::_STPlayLoopedSound(*_DAT_1009fe20,0x14,0x100);
      *(undefined4 *)PTR_DAT_100a0534 = uVar30;
    }
    if ((*_DAT_1009fec0 == 2) && (*(int *)PTR_DAT_100a0534 != 0)) {
      sVar36 = *_DAT_1009fd94 - *(short *)(PTR_DAT_1009fe78 + 2);
      if (sVar36 < 0) {
        sVar36 = 0;
      }
      sVar36 = 0x300 - sVar36;
      sStack_68 = (short)((ulonglong)((longlong)(int)sVar36 * 0x55555556) >> 0x20) -
                  ((short)((short)((int)sVar36 / 0x30000) + (sVar36 >> 0xf)) >> 0xf);
      FUN_10091a60(*(int *)PTR_DAT_100a0534,auStack_94);
      sStack_7e = sStack_68;
      if (0xff < sStack_68) {
        sStack_7e = 0x100;
      }
      uVar31 = (uint)sStack_68;
      iVar32 = ((int)uVar31 >> 1) + (uint)((int)uVar31 < 0 && (uVar31 & 1) != 0);
      if (0xff < iVar32) {
        iVar32 = 0x100;
      }
      uStack_7c = (undefined2)iVar32;
      FUN_10091890(*(undefined4 *)PTR_DAT_100a0534,auStack_94);
    }
    if ((*_DAT_1009fec0 == 4) && (*(int *)PTR_DAT_100a0534 != 0)) {
      sVar36 = *_DAT_1009fd90 - *(short *)PTR_DAT_1009fe78;
      if (sVar36 < 0) {
        sVar36 = 0;
      }
      uVar28 = 0x200 - sVar36;
      sStack_6a = ((short)uVar28 >> 1) + (ushort)((short)uVar28 < 0 && (uVar28 & 1) != 0);
      FUN_10091a60(*(int *)PTR_DAT_100a0534,auStack_b0);
      sStack_9a = sStack_6a;
      if (0xff < sStack_6a) {
        sStack_9a = 0x100;
      }
      sStack_98 = sStack_9a;
      FUN_10091890(*(undefined4 *)PTR_DAT_100a0534,auStack_b0);
    }
  }
  iVar32 = *(int *)PTR_DAT_100a0558;
  if (iVar32 == 0) {
    *PTR_DAT_100a05a4 = 0;
  }
  else {
    uVar40 = 1;
    if ((*(short *)(iVar32 + 4) != 0x438) && (*(short *)(iVar32 + 4) != 0x439)) {
      uVar40 = 0;
    }
    *PTR_DAT_100a05a4 = uVar40;
    *_DAT_1009fd34 = 1;
    puVar11 = PTR_DAT_100a0554;
    *psVar17 = 0;
    if ((*(int *)puVar11 == 0) && (*(short *)(iVar32 + 4) == 0x6a4)) {
      .debug::_STPlay3DSoundRand(*_DAT_100a02b4,1,0xbf,*(undefined4 *)(iVar32 + 0xe));
    }
  }
  *(undefined4 *)PTR_DAT_100a0554 = *(undefined4 *)PTR_DAT_100a0558;
  if (*PTR_DAT_100a05a4 != '\0') {
    *(undefined4 *)(param_1 + 0x24) = 0;
  }
  if (*(char *)(param_1 + 0xe9) != '\0') {
    return;
  }
  if (*(char *)(param_1 + 0x1b2) != '\0') {
    return;
  }
  if (*PTR_DAT_100a0620 == '\0') {
    if (((*(int *)(param_1 + 0x11c) == 0) && (*(int *)(param_1 + 0x120) == 0)) ||
       (*(short *)(param_1 + 0x128) != 5)) {
      _DAT_100a600a = 0x76c;
      _DAT_100a600c = 0xc80;
      _DAT_100a600e = 0x76c;
      _DAT_100a6010 = 0xc80;
    }
    else {
      iVar34 = (int)*(short *)(param_1 + 0x38);
      iVar27 = *(int *)(param_1 + 0x120) - (int)*(short *)(param_1 + 0x34);
      iVar32 = iVar34;
      if (iVar27 < iVar34) {
        iVar32 = iVar27;
      }
      iVar34 = iVar34 - *(short *)(param_1 + 0x34);
      iVar34 = ((iVar34 - iVar32) * 0x100) / iVar34;
      _DAT_100a600a = 0x76c - (short)((uint)(iVar34 * 0x3b6) >> 8);
      _DAT_100a600c = 0xc80 - (short)((uint)(iVar34 * 0x640) >> 8);
      _DAT_100a600e = 0x76c - (short)((uint)(iVar34 * 0x3b6) >> 8);
      _DAT_100a6010 = 0xc80 - (short)((uint)(iVar34 * 0x640) >> 8);
    }
  }
  else {
    *psVar17 = 0;
    _DAT_100a600a = 0xd82;
    _DAT_100a600c = 0x15e0;
    _DAT_100a600e = 0xd82;
    _DAT_100a6010 = 0x15e0;
  }
  pcVar8 = _DAT_100a0584;
  *psVar17 = *psVar17 + 1;
  *(undefined1 *)(param_1 + 0x18c) = 0;
  *(bool *)(param_1 + 0x8a) = *psVar26 == 0;
  *pcVar8 = *_DAT_100a0588;
  *_DAT_100a0588 = '\0';
  if ((short)*puVar18 < 1) {
    .debug::_RopeCollide(param_1);
  }
  if (*_DAT_100a05e0 == '\0') {
    *(undefined2 *)(param_1 + 0x110) = 0x1b8;
  }
  if (*(char *)(param_1 + 0xce) == '\0') {
    if (((*psVar23 != 0) || (*(int *)(param_1 + 0x11c) == 1)) &&
       (*(undefined2 *)(param_1 + 0x110) = 0x50, *puVar5 != '\0')) {
      *(undefined2 *)(param_1 + 0x110) = 0x118;
    }
    if (*(int *)(param_1 + 0x11c) == 1) {
      if (*puVar5 == '\0') {
        if (0x6a4 < *(int *)(param_1 + 0x2c)) {
          *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + -0x200;
        }
      }
      else if (3000 < *(int *)(param_1 + 0x2c)) {
        *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + -0x200;
      }
      if (((*puVar5 == '\0') && (*psVar23 == 0)) && (*(short *)(param_1 + 0x128) != 5)) {
        *psVar23 = 1;
      }
    }
    if (*_DAT_100a0588 != '\0') {
      *(undefined2 *)(param_1 + 0x110) = 0;
    }
    psVar13 = _DAT_100a05d8;
    if ((*_DAT_100a05e0 != '\0') && (*psVar12 == 0)) {
      sVar36 = *_DAT_100a05d8;
      iVar32 = (int)sVar36;
      if (sVar36 < 0) {
        if (sVar36 < 1) {
          iVar32 = -iVar32;
        }
        *(short *)(param_1 + 0x110) = (short)(-0x28 / (6 - iVar32)) + 0x3c;
        sVar36 = *psVar13;
        iVar32 = (int)sVar36;
        if (sVar36 < 1) {
          iVar32 = -iVar32;
        }
        *(short *)(param_1 + 0x90) = (short)(0xfa / (6 - iVar32)) + 0x100;
      }
      else if (sVar36 < 1) {
        *(undefined2 *)(param_1 + 0x90) = 0x100;
        *(undefined2 *)(param_1 + 0x110) = 0x3c;
      }
      else {
        if (sVar36 < 1) {
          iVar32 = -iVar32;
        }
        *(short *)(param_1 + 0x110) = (short)(0x3c / (6 - iVar32)) + 0x3c;
        sVar36 = *psVar13;
        iVar32 = (int)sVar36;
        if (sVar36 < 1) {
          iVar32 = -iVar32;
        }
        *(short *)(param_1 + 0x90) = 0x100 - (short)(0xdc / (6 - iVar32));
      }
    }
  }
  else {
    *(undefined2 *)(param_1 + 0x110) = 0x1b8;
  }
  if (((*(char *)(param_1 + 0xce) != '\0') || (*psVar26 != 0)) && (*(int *)PTR_DAT_100a0558 == 0)) {
    *_DAT_100a0678 = 0;
  }
  if (*PTR_DAT_100a0638 != '\0') {
    *_DAT_100a0678 = 0xfffff768;
  }
  if (*PTR_DAT_100a062c != '\0') {
    if (0 < *(int *)(param_1 + 0x2c)) {
      *(undefined2 *)(param_1 + 0x110) = 0x40;
    }
    if (0x352 < *(int *)(param_1 + 0x2c)) {
      *(undefined4 *)(param_1 + 0x2c) = 0x352;
    }
  }
  .debug::_StandardSpriteHandles(param_1);
  if ((*PTR_DAT_100a0654 == '\0') || (*_DAT_100a0658 != 0)) {
    if ((*PTR_DAT_100a0654 == '\0') && (*_DAT_100a0658 != 0)) {
      *(undefined1 *)(*_DAT_100a0658 + 0xe9) = 1;
      *_DAT_100a0658 = 0;
    }
  }
  else {
    iVar32 = .debug::_MTNewSprite
                       (0x1b39,(int)*(short *)(param_1 + 0xc),(int)*(short *)(param_1 + 10),
                        *(int *)(param_1 + 0x80) + -1,0xffffffff,PTR_PTR_100a04dc);
    *_DAT_100a0658 = iVar32;
  }
  if ((*puVar5 == '\0') && (*(char *)(param_1 + 0xce) == '\0')) {
    *(undefined1 *)(param_1 + 0xeb) = 0;
  }
  else {
    *(undefined1 *)(param_1 + 0xeb) = 1;
  }
  if ((*(short *)PTR_DAT_100a06c0 < *(short *)(param_1 + 0x116)) && (*_DAT_100a06f0 == 0)) {
    *(undefined2 *)PTR_DAT_100a06bc = 3;
  }
  if (0 < *(short *)PTR_DAT_100a06bc) {
    *(short *)PTR_DAT_100a06bc = *(short *)PTR_DAT_100a06bc + -1;
  }
  if (0 < *(short *)PTR_DAT_100a04d8) {
    *(short *)PTR_DAT_100a04d8 = *(short *)PTR_DAT_100a04d8 + -1;
  }
  if (0 < *_DAT_100a05f4) {
    *_DAT_100a05f4 = *_DAT_100a05f4 + -1;
  }
  if (0 < *(short *)PTR_DAT_100a06b8) {
    *(short *)PTR_DAT_100a06b8 = *(short *)PTR_DAT_100a06b8 + -1;
  }
  if (0 < *(short *)PTR_DAT_100a060c) {
    *(short *)PTR_DAT_100a060c = *(short *)PTR_DAT_100a060c + -1;
  }
  if (0 < *(short *)PTR_DAT_100a05c4) {
    *(short *)PTR_DAT_100a05c4 = *(short *)PTR_DAT_100a05c4 + -1;
  }
  sVar36 = *_DAT_100a0684;
  if (sVar36 < 1) {
    if (sVar36 < 0) {
      *_DAT_100a0684 = sVar36 + 1;
    }
  }
  else {
    *_DAT_100a0684 = sVar36 + -1;
  }
  if (0 < *(short *)PTR_DAT_100a05f0) {
    *(short *)PTR_DAT_100a05f0 = *(short *)PTR_DAT_100a05f0 + -1;
  }
  if (0 < *(short *)PTR_DAT_100a05a8) {
    *(short *)PTR_DAT_100a05a8 = *(short *)PTR_DAT_100a05a8 + -1;
  }
  if (0 < *(short *)PTR_DAT_1009fdbc) {
    *(short *)PTR_DAT_1009fdbc = *(short *)PTR_DAT_1009fdbc + -1;
  }
  if (0 < *_DAT_1009fdb8) {
    *_DAT_1009fdb8 = *_DAT_1009fdb8 + -1;
  }
  if (0 < *(short *)PTR_DAT_1009fda8) {
    *(short *)PTR_DAT_1009fda8 = *(short *)PTR_DAT_1009fda8 + -1;
  }
  if (0 < *_DAT_100a059c) {
    *_DAT_100a059c = *_DAT_100a059c + -1;
  }
  if (0 < *_DAT_100a0570) {
    *_DAT_100a0570 = *_DAT_100a0570 + -1;
  }
  if (((0 < *_DAT_100a073c) && (*_DAT_100a073c = *_DAT_100a073c + -1, *_DAT_100a073c == 0)) &&
     (cVar38 = .debug::_HasItemWhichSlot(0x13,auStack_b4), cVar38 != '\0')) {
    .debug::_RemoveItem(0x13);
    .debug::_UpdateStatusBar(1,1,0);
  }
  .debug::_TickTock(PTR_DAT_100a0650);
  .debug::_TickTock(PTR_DAT_100a064c);
  if ((*(short *)PTR_DAT_100a064c < 1) || (cRam100a5fd4 == '\0')) {
    *PTR_DAT_100a0654 = 0;
  }
  else {
    *PTR_DAT_100a0654 = 1;
  }
  .debug::_TickTock(PTR_DAT_100a0640);
  if (*(short *)PTR_DAT_100a0640 < 1) {
    *PTR_DAT_100a0648 = 0;
  }
  else {
    *PTR_DAT_100a0648 = 1;
    if (cRam100a5fd4 == '\0') {
      *PTR_DAT_100a0644 = 0;
    }
    else {
      *PTR_DAT_100a0644 = 1;
    }
  }
  .debug::_TickTock(PTR_DAT_100a0630);
  if (*(short *)PTR_DAT_100a0630 < 1) {
    *PTR_DAT_100a0638 = 0;
  }
  else {
    *PTR_DAT_100a0638 = 1;
    if (cRam100a5fd4 == '\0') {
      *PTR_DAT_100a0634 = 0;
    }
    else {
      *PTR_DAT_100a0634 = 1;
    }
  }
  .debug::_TickTock(PTR_DAT_100a0624);
  if (*(short *)PTR_DAT_100a0624 < 1) {
    *PTR_DAT_100a062c = 0;
  }
  else {
    *PTR_DAT_100a062c = 1;
    if (cRam100a5fd4 == '\0') {
      *PTR_DAT_100a0628 = 0;
    }
    else {
      *PTR_DAT_100a0628 = 1;
    }
  }
  .debug::_TickTock(PTR_DAT_100a0618);
  if (*(short *)PTR_DAT_100a0618 < 1) {
    *PTR_DAT_100a0620 = 0;
  }
  else {
    *PTR_DAT_100a0620 = 1;
    if (cRam100a5fd4 == '\0') {
      *PTR_DAT_100a061c = 0;
    }
    else {
      *PTR_DAT_100a061c = 1;
    }
  }
  *(short *)PTR_DAT_100a0610 = *(short *)PTR_DAT_100a0610 + -1;
  if (*(short *)PTR_DAT_100a0610 < 1) {
    *PTR_DAT_100a0614 = 0;
  }
  else {
    *PTR_DAT_100a0614 = 1;
  }
  *(undefined2 *)PTR_DAT_100a06c0 = *(undefined2 *)(param_1 + 0x116);
  *PTR_DAT_100a0704 = 0;
  iVar32 = *(int *)(param_1 + 0x120);
  if (((iVar32 < 1) || (0x15 < iVar32)) || (*(short *)(param_1 + 0x128) == 5)) {
    if (((*(char *)(param_1 + 0xce) != '\0') || (0x2b < iVar32)) || (*(int *)(param_1 + 0x120) == 0)
       ) {
      *_DAT_100a05fc = '\0';
    }
  }
  else {
    *_DAT_100a05fc = '\x01';
  }
  if (0 < *_DAT_100a0578) {
    cVar38 = .debug::_TickTockLong(_DAT_100a0578);
    *_DAT_100a056c = cVar38;
    puVar11 = PTR_DAT_100a04d4;
    if (*_DAT_100a0578 < 1) {
      *(undefined2 *)(iVar9 + 4) = 0;
      *(undefined2 *)(param_1 + 0xa4) = 0;
      puVar10 = PTR_DAT_100a04d0;
      *(short *)(param_1 + 0xc) = (short)*(undefined4 *)puVar11;
      puVar11 = PTR_DAT_100a0550;
      *(short *)(param_1 + 10) = (short)*(undefined4 *)puVar10;
      *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
      *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
      if (*(int *)puVar11 != 0) {
        *(undefined1 *)(*(int *)puVar11 + 0xe9) = 1;
      }
    }
    else {
      *(undefined1 *)(param_1 + 0xce) = 0;
      if (*psVar23 == 0) {
        *psVar23 = 1;
      }
      *_DAT_100a05fc = '\x01';
      *(undefined2 *)(param_1 + 0x110) = 0x50;
      if (0x3ff < *(int *)(param_1 + 0x2c)) {
        *(undefined4 *)(param_1 + 0x2c) = 0x400;
      }
    }
  }
  if (((*(int *)(param_1 + 0x120) == 0) && (*(int *)(param_1 + 0x11c) == 0)) ||
     ((sVar36 = *(short *)(param_1 + 0x128), sVar36 < 1 &&
      (*(char *)(*(int *)*_DAT_100a0058 + 0x26cd) == '\0')))) {
    *(undefined2 *)PTR_DAT_100a0538 = 0;
  }
  else if (*(short *)PTR_DAT_100a0538 < 2) {
    *(short *)PTR_DAT_100a0538 = *(short *)PTR_DAT_100a0538 + 1;
  }
  else if (sVar36 == 3) {
    bStack_6c = false;
    if (0 < *(short *)(param_1 + 0xa4)) {
      *(short *)(iVar9 + 6) = *(short *)(iVar9 + 6) + 8;
      if (*(short *)(iVar9 + 10) < *(short *)(iVar9 + 6)) {
        *(short *)(iVar9 + 6) = *(short *)(iVar9 + 10);
      }
      bStack_6c = *(short *)(iVar9 + 4) < *(short *)(iVar9 + 10);
      if (bStack_6c) {
        *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + 4;
      }
      if (*(short *)(iVar9 + 0xe) < *(short *)(iVar9 + 0xc)) {
        *(short *)(iVar9 + 0xe) = *(short *)(iVar9 + 0xe) + 4;
        bStack_6c = true;
      }
    }
    if ((bStack_6c == false) || (sVar36 = FUN_100916dc(*_DAT_1009fe5c), sVar36 != 0)) {
      if (bStack_6c == false) {
        FUN_10091504(*_DAT_1009fe5c);
      }
    }
    else {
      .debug::_STPlayRegSound(*_DAT_1009fe5c,1,0xab);
    }
  }
  else if (sVar36 < 3) {
    if (sVar36 == 0) {
      if (((*(short *)(param_1 + 0x116) == 0) && (*_DAT_100a06d8 == 0)) &&
         (4 < *(short *)(param_1 + 0xa4))) {
        .debug::_STPlayRegSound(*_DAT_100a0404,1,0x100);
        *_DAT_100a06d8 = 0x23;
        *(undefined2 *)(param_1 + 0xaa) = 0xd;
        *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -0x70;
        *(undefined2 *)(param_1 + 0x116) = 0x3c;
      }
    }
    else if (((-1 < sVar36) && (*(short *)(param_1 + 0x116) == 0)) &&
            ((*_DAT_100a06d8 == 0 && (4 < *(short *)(param_1 + 0xa4))))) {
      .debug::_STPlayRegSound(*_DAT_100a0404,1,0x100);
      *_DAT_100a06d8 = 0x23;
      *(undefined2 *)(param_1 + 0xaa) = 0xd;
      *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -0x70;
      *(undefined2 *)(param_1 + 0x116) = 0x3c;
    }
  }
  if (0 < *_DAT_100a06d8) {
    *_DAT_100a06d8 = *_DAT_100a06d8 + -1;
  }
  if (0 < *(short *)PTR_DAT_100a06cc) {
    *(short *)PTR_DAT_100a06cc = *(short *)PTR_DAT_100a06cc + -1;
  }
  *_DAT_100a067c = 0;
  .debug::_SeparateFromTiles2(param_1);
  if (*puVar18 == 0) {
    if (((*_DAT_100a0738 == '\0') && (*(char *)(param_1 + 0xce) == '\0')) &&
       (*_DAT_100a05b8 != '\0')) {
      .glue::SetRect(param_1 + 0x34,0x26,0x22,0x3e,0x55);
    }
    else {
      .glue::SetRect(param_1 + 0x34,0x26,0x22,0x3e,0x55);
    }
  }
  pcVar8 = _DAT_100a0738;
  if (*(int *)PTR_DAT_100a0558 == 0) {
    *_DAT_100a0738 = *(char *)(param_1 + 0xce);
  }
  else {
    *(undefined1 *)(param_1 + 0xce) = 3;
    *pcVar8 = '\x03';
  }
  pcVar8 = _DAT_100a0738;
  if (*(int *)(param_1 + 0x14c) == 1) {
    *psVar24 = 8;
    *pcVar8 = '\0';
    *(undefined1 *)(param_1 + 0xce) = 0;
    *(undefined4 *)(param_1 + 0x14c) = 0;
  }
  *_DAT_100a0660 = *(undefined4 *)(param_1 + 0x2c);
  if (*_DAT_100a06f0 == 0) {
    .debug::_HandleKeys(param_1,*(undefined4 *)PTR_DAT_100a0558);
  }
  else {
    *_DAT_100a0734 = '\0';
    *_DAT_100a0730 = '\0';
    *(undefined4 *)(param_1 + 0x2c) = 0;
    *(undefined4 *)(param_1 + 0x24) = 0;
  }
  if (((*(int *)(param_1 + 0x11c) != 0) || (*(int *)(param_1 + 0x120) != 0)) &&
     (*(short *)(param_1 + 0x128) == 5)) {
    uStack_58 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x2c) ^ 0x80000000);
    iVar32 = (int)((uStack_58 - _DAT_100a1a38) * dRam100a1a30);
    uStack_60 = (double)(longlong)iVar32;
    *(int *)(param_1 + 0x2c) = iVar32;
  }
  if (*psVar26 == 0) {
    if ((*(int *)(param_1 + 0x120) == 0) || (*(short *)(param_1 + 0x19e) == 0)) {
      *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + (int)*(short *)(param_1 + 0x110);
    }
    if (12000 < *(int *)(param_1 + 0x2c)) {
      *(undefined4 *)(param_1 + 0x2c) = 12000;
    }
    if (*(int *)(param_1 + 0x2c) == 0) {
      *(undefined4 *)(param_1 + 0x2c) = 1;
    }
  }
  if ((*(char *)(param_1 + 0xce) == '\0') || (*_DAT_100a05e0 != '\0')) {
    if (*_DAT_100a05e0 == '\0') {
      if (*_DAT_100a0588 == '\0') {
        if ((0 < *(int *)(param_1 + 0x24)) &&
           (*(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + -100, *(int *)(param_1 + 0x24) < 0
           )) {
          *(undefined4 *)(param_1 + 0x24) = 0;
        }
        if ((*(int *)(param_1 + 0x24) < 0) &&
           (*(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + 100, 0 < *(int *)(param_1 + 0x24))
           ) {
          *(undefined4 *)(param_1 + 0x24) = 0;
        }
      }
      else {
        if ((0 < *(int *)(param_1 + 0x24)) &&
           (*(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + -600, *(int *)(param_1 + 0x24) < 0
           )) {
          *(undefined4 *)(param_1 + 0x24) = 0;
        }
        if ((*(int *)(param_1 + 0x24) < 0) &&
           (*(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + 600, 0 < *(int *)(param_1 + 0x24))
           ) {
          *(undefined4 *)(param_1 + 0x24) = 0;
        }
      }
    }
    else {
      if ((0 < *(int *)(param_1 + 0x24)) &&
         (*(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + -0x14, *(int *)(param_1 + 0x24) < 0)
         ) {
        *(undefined4 *)(param_1 + 0x24) = 0;
      }
      if ((*(int *)(param_1 + 0x24) < 0) &&
         (*(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + 0x14, 0 < *(int *)(param_1 + 0x24)))
      {
        *(undefined4 *)(param_1 + 0x24) = 0;
      }
    }
  }
  else {
    *psVar23 = 0;
    iVar32 = *(int *)(param_1 + 0x24);
    if ((0 < iVar32) && (*_DAT_100a0734 == '\0')) {
      if (*psVar25 == 0) {
        if (*_DAT_100a0694 == 0) {
          *(int *)(param_1 + 0x24) = iVar32 + -800;
        }
        else {
          cVar38 = *(char *)(param_1 + 0xce);
          if ((((cVar38 == '\x03') || (cVar38 == '\x04')) || (cVar38 == '\a')) ||
             (*(short *)(param_1 + 0x112) == 0)) {
            *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) - (int)*_DAT_100a0694;
          }
        }
      }
      else {
        *(int *)(param_1 + 0x24) = iVar32 + -300;
      }
      if (*(int *)(param_1 + 0x24) < 0) {
        *(undefined4 *)(param_1 + 0x24) = 0;
      }
    }
    iVar32 = *(int *)(param_1 + 0x24);
    if ((iVar32 < 0) && (*_DAT_100a0730 == '\0')) {
      if (*psVar25 == 0) {
        if (*_DAT_100a0694 == 0) {
          *(int *)(param_1 + 0x24) = iVar32 + 800;
        }
        else {
          cVar38 = *(char *)(param_1 + 0xce);
          if (((cVar38 == '\x03') || (cVar38 == '\x04')) ||
             ((cVar38 == '\a' || (*(short *)(param_1 + 0x112) == 0)))) {
            *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + (int)*_DAT_100a0694;
          }
        }
      }
      else {
        *(int *)(param_1 + 0x24) = iVar32 + 300;
      }
      if (0 < *(int *)(param_1 + 0x24)) {
        *(undefined4 *)(param_1 + 0x24) = 0;
      }
    }
  }
  *(undefined1 *)(param_1 + 0xce) = 0;
  *(undefined1 *)(param_1 + 0xcf) = 0;
  if (*(short *)(iVar9 + *(short *)(iVar9 + 0x172) * 10 + 0x24) == -1) {
    if (*(short *)(iVar9 + 0x24) == -1) {
      *(undefined2 *)(iVar9 + 0x172) = 0xffff;
    }
    else {
      *(undefined2 *)(iVar9 + 0x172) = 0;
    }
  }
  sVar36 = *psVar26;
  *(short *)PTR_DAT_100a0754 = sVar36;
  if (sVar36 != 0) {
    *puVar5 = 0;
    sVar36 = FUN_100916dc(*puVar39);
    if (sVar36 != 0) {
      FUN_10091504(*puVar39);
    }
    iVar32 = *(int *)(param_1 + 0x2c);
    if (iVar32 < 0) {
      *(int *)(param_1 + 0x2c) = iVar32 + 100;
      if (*(int *)(param_1 + 0x2c) < 1) {
        if (*(int *)(param_1 + 0x2c) < -4000) {
          *(undefined4 *)(param_1 + 0x2c) = 0xfffff060;
        }
      }
      else {
        *(undefined4 *)(param_1 + 0x2c) = 0;
      }
    }
    else if (0 < iVar32) {
      *(int *)(param_1 + 0x2c) = iVar32 + -100;
      if (*(int *)(param_1 + 0x2c) < 0) {
        *(undefined4 *)(param_1 + 0x2c) = 0;
      }
      else if (4000 < *(int *)(param_1 + 0x2c)) {
        *(undefined4 *)(param_1 + 0x2c) = 4000;
      }
    }
    if (*(short *)PTR_DAT_100a074c == 1) {
      *(undefined4 *)(param_1 + 0x24) = 0xfffff800;
    }
    else {
      *(undefined4 *)(param_1 + 0x24) = 0x800;
    }
    *psVar26 = 0;
  }
  puVar4 = _DAT_100a0724;
  uStack_64 = 0;
  *_DAT_100a0720 = 0;
  *puVar4 = 0;
  .debug::_ApplySpeedAndSeparateFromTiles(param_1);
  if (*(short *)(param_1 + 0xd8) == 2) {
    if ((*(short *)(param_1 + 0x116) == 0) && (*puVar18 == 0)) {
      sStack_6e = *(short *)(*(int *)*_DAT_100a0058 + 0x270e);
      if (sStack_6e == 0) {
        sStack_6e = 0x70;
      }
      *psVar25 = 1;
      *puVar5 = 0;
      sVar36 = FUN_100916dc(*puVar39);
      if (sVar36 != 0) {
        FUN_10091504(*puVar39);
      }
      .debug::_STPlayRegSound(*_DAT_100a02dc,1,0x100);
      *(undefined2 *)(param_1 + 0x116) = 0x3c;
      *(undefined2 *)(param_1 + 0xaa) = 0x12;
      *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) - sStack_6e;
    }
  }
  else if (*(short *)(param_1 + 0xd8) == 3) {
    piVar33 = (int *)*_DAT_100a0058;
    *_DAT_100a0694 = (short)((uint)((0x100 - *(short *)(*piVar33 + 10000)) * 800) >> 8);
    if (*_DAT_100a0694 < 1) {
      *_DAT_100a0694 = 1;
    }
    *(short *)(param_1 + 0x112) = *(short *)(*piVar33 + 10000) >> 4;
  }
  else {
    *_DAT_100a0694 = (short)uStack_64;
    *(short *)(param_1 + 0x112) = (short)uStack_64;
  }
  if ((*(short *)PTR_DAT_100a0754 != 0) && (*psVar26 == 0)) {
    *(undefined4 *)(param_1 + 0x2c) = 0;
    *(undefined4 *)(param_1 + 0x24) = 0;
  }
  .debug::_HandleBreathing(param_1);
  *(undefined4 *)(*_DAT_100a065c + 0xc0) = 0;
  if (*_DAT_100a06ec == '\0') {
    if ((*PTR_DAT_100a06e8 != '\0') && (*psVar21 = *psVar21 + 1, 2 < *psVar21)) {
      *PTR_DAT_100a06e8 = 0;
      *_DAT_100a06ec = '\x01';
    }
  }
  else {
    *psVar21 = *psVar21 + 1;
    if (*psVar21 == 4) {
      if (0 < *(short *)(iVar9 + 0xe)) {
        .debug::_CastSpell(param_1);
      }
    }
    else if (6 < *psVar21) {
      *_DAT_100a06ec = '\0';
      *psVar21 = 3;
    }
  }
  sVar36 = *psVar21;
  if (sVar36 == 3) {
    *_DAT_100a06d0 = *_DAT_100a06d0 + 1;
    if (*_DAT_100a06d0 == 0x12) {
      *psVar21 = 2;
    }
  }
  else if ((*_DAT_100a06d0 == 0x12) && (sVar36 == 2)) {
    *psVar21 = 1;
  }
  else if ((*_DAT_100a06d0 == 0x12) && (sVar36 == 1)) {
    *_DAT_100a06d0 = 0;
    *psVar21 = 0;
  }
  else {
    *_DAT_100a06d0 = 0;
  }
  if (0 < *_DAT_100a05b0) {
    *_DAT_100a05b0 = *_DAT_100a05b0 + 1;
    puVar1 = _DAT_100a02d8;
    puVar35 = _DAT_100a02d0;
    sVar36 = *_DAT_100a05b0;
    if (sVar36 == 0x14) {
      if (_DAT_100a5fd6 == 5) {
        uVar29 = *(undefined2 *)(iVar9 + 10);
        *(undefined2 *)(iVar9 + 6) = uVar29;
        *(undefined2 *)(iVar9 + 4) = uVar29;
        *(undefined2 *)(param_1 + 0xa4) = uVar29;
        .debug::_STPlayRegSound(*puVar35,1,0x100);
        .debug::_STPlayRegSound(*_DAT_100a03f4,1,0x100);
        .debug::_RemoveItem((int)_DAT_100a5fd6);
        *(undefined2 *)PTR_DAT_100a05a8 = 6;
        *(undefined2 *)PTR_DAT_1009fdbc = 0xb;
      }
      else if (_DAT_100a5fd6 < 5) {
        if (3 < _DAT_100a5fd6) {
          *(undefined2 *)(iVar9 + 0xe) = *(undefined2 *)(iVar9 + 0xc);
          .debug::_STPlayRegSound(*puVar1,1,0x100);
          .debug::_STPlayRegSound(*_DAT_100a03f4,1,0x100);
          .debug::_RemoveItem((int)_DAT_100a5fd6);
          *(undefined2 *)PTR_DAT_100a05a8 = 6;
          *_DAT_1009fdb8 = 0xb;
        }
      }
      else if (_DAT_100a5fd6 == 0x19) {
        .debug::_STPlayRegSound(*_DAT_100a03f4,1,0x100);
        .debug::_RemoveItem((int)_DAT_100a5fd6);
        *(undefined2 *)PTR_DAT_100a05a8 = 6;
      }
    }
    else if (sVar36 == 0x28) {
      if (_DAT_100a5fd6 == 0x19) {
        *psVar41 = 1;
      }
    }
    else if (0x28 < sVar36) {
      *_DAT_100a05b0 = 0;
    }
  }
  psVar13 = _DAT_100a05e4;
  if (*_DAT_100a05e0 != '\0') {
    *psVar17 = 0;
    *psVar25 = 0;
    .glue::SetRect(param_1 + 0x34,0x37,0x3e,99,0x61);
    if (((*(char *)(param_1 + 0xce) == '\0') && (*(char *)(param_1 + 0xcd) == '\0')) ||
       (*(int *)(param_1 + 0xdc) != 0)) {
      *(undefined2 *)PTR_DAT_100a05c8 = 0;
    }
    else {
      *(short *)PTR_DAT_100a05c8 = *(short *)PTR_DAT_100a05c8 + 1;
      uStack_60 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
      iVar32 = (int)((uStack_60 - _DAT_100a1a38) * dRam100a1a28);
      uStack_58 = (double)(longlong)iVar32;
      *(int *)(param_1 + 0x24) = iVar32;
      *(undefined4 *)(param_1 + 0x2c) = 0x100;
    }
    if ((0xc < *(short *)PTR_DAT_100a05c8) && (*psVar12 == 0)) {
      *psVar12 = -0x17;
    }
    if ((2000 < *(int *)(param_1 + 0x2c)) && (*puVar18 == 0)) {
      *(undefined4 *)(param_1 + 0x2c) = 2000;
    }
    sVar36 = *psVar12;
    iVar32 = (int)sVar36;
    if (sVar36 == 0) {
      *psVar14 = *psVar14 + 1;
      if (0x1f < *psVar14) {
        *psVar14 = 0;
      }
      psVar41 = _DAT_100a05d0;
      *(undefined4 *)(param_1 + 0xc0) =
           *(undefined4 *)(_DAT_100a0774 + ((int)*psVar14 >> 3) * 4 + 4);
      sVar36 = *psVar41;
      if (sVar36 == 0) {
        sVar36 = *psVar21;
        if (sVar36 < 3) {
          sVar36 = *_DAT_100a05d8;
          if (sVar36 == 0) {
            *(undefined2 *)PTR_DAT_100a05cc = 0;
          }
          else {
            sVar37 = sVar36;
            if (sVar36 < 1) {
              sVar37 = -sVar36;
            }
            iVar32 = (int)(sVar37 >> 1);
            if (sVar36 < 0) {
              *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0770 + iVar32 * 4 + 4);
            }
            else {
              *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0770 + iVar32 * 4 + 0x10);
              if (iVar32 == 2) {
                if (*(short *)PTR_DAT_100a05cc < 0x1e) {
                  *(short *)PTR_DAT_100a05cc = *(short *)PTR_DAT_100a05cc + 1;
                }
                if (*(char *)(param_1 + 0x17e) == '\0') {
                  if (*(int *)(param_1 + 0x24) < 0xc80) {
                    *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + 0x50;
                  }
                }
                else if (-0xc80 < *(int *)(param_1 + 0x24)) {
                  *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + -0x50;
                }
              }
              else if (0 < *(short *)PTR_DAT_100a05cc) {
                iVar32 = *(short *)PTR_DAT_100a05cc * -0x640;
                iVar32 = iVar32 / 0x1e + (iVar32 >> 0x1f);
                *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + (iVar32 - (iVar32 >> 0x1f));
              }
            }
          }
        }
        else if (0 < sVar36) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a076c + sVar36 * 4 + -8);
        }
      }
      else {
        if (sVar36 < 0) {
          *_DAT_100a05d0 = sVar36 + 1;
        }
        else if (0 < sVar36) {
          *_DAT_100a05d0 = sVar36 + -1;
        }
        iVar32 = (int)*_DAT_100a05d0;
        if (*_DAT_100a05d0 < 1) {
          iVar32 = -iVar32;
        }
        sVar37 = (short)(iVar32 >> 1);
        if (5 < sVar37) {
          sVar37 = 5;
        }
        iVar32 = (int)sVar37;
        if (iVar32 < 3) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0778 + (5 - iVar32) * 4 + 4);
          if (sVar36 < 1) {
            *(undefined1 *)(param_1 + 0x17e) = 0;
            _DAT_100a5f5a = 2;
          }
          else {
            *(undefined1 *)(param_1 + 0x17e) = 1;
            _DAT_100a5f5a = 1;
          }
        }
        else {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0778 + iVar32 * 4 + 4);
          if (sVar36 < 1) {
            *(undefined1 *)(param_1 + 0x17e) = 1;
            _DAT_100a5f5a = 1;
          }
          else {
            *(undefined1 *)(param_1 + 0x17e) = 0;
            _DAT_100a5f5a = 2;
          }
        }
        if (*_DAT_100a05d0 == 0) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0774 + 4);
        }
      }
    }
    else if (sVar36 < 1) {
      if (sVar36 < 1) {
        iVar32 = -iVar32;
      }
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0778 + (iVar32 >> 2) * 4 + 4);
      *(undefined4 *)(param_1 + 0x2c) = 0;
      *(undefined2 *)(param_1 + 0x110) = 0;
      *(undefined4 *)(param_1 + 0x24) = 0;
      *(undefined4 *)(param_1 + 0x2c) = 0x100;
      if (*psVar12 < -0x10) {
        *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + -0x200;
        *(short *)(param_1 + 10) = (short)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
      }
      *psVar12 = *psVar12 + 1;
      if (*psVar12 == 0) {
        .debug::_MTNewSprite
                  (0xbea,(int)*(short *)(param_1 + 0xc),(int)*(short *)(param_1 + 10),2,0xffffffff,
                   _DAT_1009ff38);
        *(undefined2 *)PTR_DAT_100a05c4 = 0xb4;
        *_DAT_100a05e0 = '\0';
        *(undefined2 *)(param_1 + 0x110) = 0x1b8;
        puVar5 = PTR_DAT_100a04cc;
        *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + 0x1e00;
        if (*puVar5 == '\0') {
          *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + 0x2000;
        }
        else {
          *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + 0xa00;
        }
        *(int *)(param_1 + 0xc0) = *_DAT_100a07ec;
        .glue::SetRect(param_1 + 0x34,0x26,0x22,0x3e,0x55);
      }
    }
    else {
      if (iVar32 == 1) {
        *(undefined4 *)(param_1 + 0x2c) = 0;
        *(undefined2 *)(param_1 + 0x110) = 0;
      }
      if (*psVar12 < 0x18) {
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(_DAT_100a0778 + ((int)*psVar12 >> 2) * 4 + 4);
        *psVar12 = *psVar12 + 1;
        if (0x10 < *psVar12) {
          *(undefined2 *)(param_1 + 0x110) = 0xff88;
        }
        *(undefined4 *)(param_1 + 0x24) = 0;
      }
      else if (*(short *)(param_1 + 0x110) < 100) {
        *psVar14 = *psVar14 + 1;
        if (0x1f < *psVar14) {
          *psVar14 = 0;
        }
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(_DAT_100a0774 + ((int)*psVar14 >> 3) * 4 + 4);
        *(short *)(param_1 + 0x110) = *(short *)(param_1 + 0x110) + 0x1e;
      }
      else {
        *psVar14 = *psVar14 + 1;
        if (0x1f < *psVar14) {
          *psVar14 = 0;
        }
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(_DAT_100a0774 + ((int)*psVar14 >> 3) * 4 + 4);
        *psVar12 = 0;
      }
    }
    if (0 < (short)*puVar18) {
      bVar3 = false;
      if (0 < *psVar17) {
        *psVar17 = *psVar16;
      }
      puVar5 = PTR_DAT_100a0654;
      *(undefined4 *)(param_1 + 0x5c) = 0;
      *puVar5 = 0;
      psVar41 = _DAT_100a05d8;
      *(undefined4 *)(param_1 + 0x24) = 0;
      *psVar26 = 0;
      *psVar12 = 0;
      *(undefined2 *)(param_1 + 0x110) = 0x17c;
      if (*psVar41 < 5) {
        *_DAT_100a05d8 = *psVar41 + 1;
      }
      if ((short)*puVar18 < 0x1e) {
        *(ushort *)(param_1 + 0x19e) = (*puVar18 & 1) + *(short *)(param_1 + 0x19e) + 1;
        *(undefined2 *)(param_1 + 0x1a0) = 0xffea;
        if (8 < (short)*puVar18) {
          if (*(char *)(param_1 + 0x17e) == '\0') {
            *(short *)(param_1 + 0x36) = *(short *)(param_1 + 0x36) + 2;
            *(short *)(param_1 + 0x3a) = *(short *)(param_1 + 0x3a) + 2;
          }
          else {
            *(short *)(param_1 + 0x36) = *(short *)(param_1 + 0x36) + -2;
            *(short *)(param_1 + 0x3a) = *(short *)(param_1 + 0x3a) + -2;
          }
        }
      }
      *(undefined2 *)(param_1 + 0x116) = 0;
      *puVar18 = *puVar18 + 1;
      if (*PTR_DAT_100a0560 == '\0') {
        if (0x50 < (short)*puVar18) {
          bVar3 = true;
        }
      }
      else if (100 < (short)*puVar18) {
        bVar3 = true;
      }
      if (bVar3) {
        auStack_be[0] = 0;
        cVar38 = .debug::_HasItemWhichSlot(0x17,auStack_be);
        puVar5 = PTR_DAT_1009fda8;
        if (((cVar38 == '\0') || (*_DAT_100a0568 != '\0')) || (*_DAT_100a05e0 != '\0')) {
          DAT_100a5106 = 1;
        }
        else if (((*_DAT_1009fd94 < 0) ||
                 ((int)*(short *)(*(int *)*_DAT_100a0058 + 0xb280) << 5 < (int)*_DAT_1009fd94)) ||
                ((*_DAT_1009fd90 < 0 ||
                 ((int)*(short *)(*(int *)*_DAT_100a0058 + 0xb282) << 5 < (int)*_DAT_1009fd90)))) {
          DAT_100a5106 = 1;
        }
        else {
          *_DAT_1009fda0 = 0;
          *(undefined2 *)puVar5 = 0x1e;
          *_DAT_1009fda4 = auStack_be[0];
          puVar5 = PTR_DAT_100a0594;
          *puVar18 = 0x1e;
          *(undefined2 *)puVar5 = 1;
          .debug::_STPlay3DSoundPitched(*_DAT_100a03e0,1,0x100,*(undefined4 *)(param_1 + 0xe),48000)
          ;
          *(undefined2 *)PTR_DAT_100a05a8 = 0x14;
        }
      }
    }
    goto LAB_10050e6c;
  }
  if (0 < (short)*puVar18) {
    bVar3 = false;
    if (0 < *psVar17) {
      *psVar17 = *psVar16;
    }
    puVar5 = PTR_DAT_100a0654;
    *(undefined4 *)(param_1 + 0x5c) = 0;
    *puVar5 = 0;
    *(undefined4 *)(param_1 + 0x24) = 0;
    *psVar26 = 0;
    if ((short)*puVar18 < 0x1e) {
      *(ushort *)(param_1 + 0x19e) = (*puVar18 & 1) + *(short *)(param_1 + 0x19e) + 1;
      piVar33 = _DAT_100a07c8;
      *(undefined2 *)(param_1 + 0x1a0) = 0xffea;
      *(int *)(param_1 + 0xc0) = *piVar33 + ((int)(short)*puVar18 / 3) * 0x34;
      if (8 < (short)*puVar18) {
        if (*(char *)(param_1 + 0x17e) == '\0') {
          *(short *)(param_1 + 0x36) = *(short *)(param_1 + 0x36) + 2;
          *(short *)(param_1 + 0x3a) = *(short *)(param_1 + 0x3a) + 2;
        }
        else {
          *(short *)(param_1 + 0x36) = *(short *)(param_1 + 0x36) + -2;
          *(short *)(param_1 + 0x3a) = *(short *)(param_1 + 0x3a) + -2;
        }
      }
    }
    else {
      *(int *)(param_1 + 0xc0) = *_DAT_100a07c8 + 0x1d4;
    }
    *(undefined2 *)(param_1 + 0x116) = 0;
    *puVar18 = *puVar18 + 1;
    if (0 < *(short *)PTR_DAT_100a0594) {
      *(undefined2 *)(param_1 + 0x19e) = 0;
      *(int *)(param_1 + 0xc0) = *_DAT_100a07c8 + ((0x1e - *(short *)PTR_DAT_100a0594) / 3) * 0x34;
      *(short *)PTR_DAT_100a0594 = *(short *)PTR_DAT_100a0594 + 1;
      if (0x1e < *(short *)PTR_DAT_100a0594) {
        uVar29 = *(undefined2 *)(iVar9 + 10);
        *(undefined2 *)(iVar9 + 6) = uVar29;
        *(undefined2 *)(iVar9 + 4) = uVar29;
        *(undefined2 *)(param_1 + 0xa4) = uVar29;
        puVar5 = PTR_DAT_100a0594;
        *puVar18 = 0;
        *(undefined2 *)puVar5 = 0;
        puVar5 = PTR_DAT_100a055c;
        *(undefined2 *)(param_1 + 0x116) = 0x3c;
        *puVar5 = 1;
        .debug::_RemoveItem(0x17);
        .glue::SetRect(param_1 + 0x34,0x26,0x22,0x3e,0x55);
      }
    }
    if (*PTR_DAT_100a0560 == '\0') {
      if (0x50 < (short)*puVar18) {
        bVar3 = true;
      }
    }
    else if (100 < (short)*puVar18) {
      bVar3 = true;
    }
    if (bVar3) {
      uStack_c0 = 0;
      cVar38 = .debug::_HasItemWhichSlot(0x17,&uStack_c0);
      puVar5 = PTR_DAT_1009fda8;
      if (((cVar38 == '\0') || (*_DAT_100a0568 != '\0')) || (*_DAT_100a05e0 != '\0')) {
        DAT_100a5106 = 1;
      }
      else if (((*_DAT_1009fd94 < 0) ||
               ((int)*(short *)(*(int *)*_DAT_100a0058 + 0xb280) << 5 < (int)*_DAT_1009fd94)) ||
              ((*_DAT_1009fd90 < 0 ||
               ((int)*(short *)(*(int *)*_DAT_100a0058 + 0xb282) << 5 < (int)*_DAT_1009fd90)))) {
        DAT_100a5106 = 1;
      }
      else {
        *_DAT_1009fda0 = 0;
        *(undefined2 *)puVar5 = 0x1e;
        *_DAT_1009fda4 = uStack_c0;
        puVar5 = PTR_DAT_100a0594;
        *puVar18 = 0x1e;
        *(undefined2 *)puVar5 = 1;
        .debug::_STPlay3DSoundPitched(*_DAT_100a03e0,1,0x100,*(undefined4 *)(param_1 + 0xe),40000);
        *(undefined2 *)PTR_DAT_100a05a8 = 0x14;
      }
    }
    goto LAB_10050e6c;
  }
  if (0 < *psVar41) {
    *(undefined4 *)(param_1 + 0x2c) = 0;
    *(undefined4 *)(param_1 + 0x24) = 0;
    iVar32 = (int)*psVar41;
    if (iVar32 < 0xd) {
      *(int *)(param_1 + 0xc0) = *_DAT_100a0780 + (iVar32 >> 2) * 0x34;
      *psVar41 = *psVar41 + 1;
      puVar5 = PTR_DAT_100a04d4;
      if (*psVar41 == 0xd) {
        *(undefined4 *)(param_1 + 0x2c) = 0xfffffca4;
        uVar30 = _DAT_1009ff38;
        *(int *)puVar5 = (int)*(short *)(param_1 + 0xc);
        *(int *)PTR_DAT_100a04d0 = (int)*(short *)(param_1 + 10);
        *_DAT_100a0578 = 600;
        pcVar8 = _DAT_100a056c;
        *psVar41 = 0;
        *pcVar8 = '\0';
        uVar30 = .debug::_MTNewSprite
                           (0x45,(int)*(short *)(param_1 + 0xc),(int)*(short *)(param_1 + 10),
                            (int)(short)*(undefined4 *)(param_1 + 0x80),0xffffffff,uVar30);
        *(undefined4 *)PTR_DAT_100a0550 = uVar30;
        *(undefined1 *)(*(int *)PTR_DAT_100a0550 + 0x17e) = *(undefined1 *)(param_1 + 0x17e);
      }
    }
    else if (0xd < iVar32) {
      *(int *)(param_1 + 0xc0) = *_DAT_100a0780 + (0x1b - iVar32 >> 2) * 0x34;
      *psVar41 = *psVar41 + 1;
      if (0x1a < *psVar41) {
        *psVar41 = 0;
        *_DAT_100a0578 = 0;
      }
    }
    goto LAB_10050e6c;
  }
  iVar32 = (int)*_DAT_100a0570;
  if (0 < *_DAT_100a0570) {
    uStack_60 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
    iVar27 = iVar32 / 0xc + (iVar32 >> 0x1f);
    iVar34 = (int)((uStack_60 - _DAT_100a1a38) * dRam100a1a28);
    uStack_58 = (double)(longlong)iVar34;
    sVar36 = (short)(iVar32 + (iVar27 - (iVar27 >> 0x1f)) * -0xc >> 1);
    *(int *)(param_1 + 0x24) = iVar34;
    if (0 < *psVar17) {
      *psVar17 = *psVar16;
    }
    *PTR_DAT_100a0670 = 0;
    *psVar26 = 0;
    *puVar5 = 0;
    sVar37 = FUN_100916dc(*puVar39);
    if (sVar37 != 0) {
      FUN_10091504(*puVar39);
    }
    *_DAT_100a071c = 0;
    if (sVar36 == 3) {
      *(int *)(param_1 + 0xc0) = *_DAT_100a0784 + 0x68;
    }
    else if (sVar36 < 3) {
      if (sVar36 == 1) {
        *(int *)(param_1 + 0xc0) = *_DAT_100a0784 + 0x34;
      }
      else if (sVar36 < 1) {
        if (-1 < sVar36) {
          *(int *)(param_1 + 0xc0) = *_DAT_100a0784;
        }
      }
      else {
        *(int *)(param_1 + 0xc0) = *_DAT_100a0784;
      }
    }
    else if (sVar36 == 5) {
      *(int *)(param_1 + 0xc0) = *_DAT_100a0784 + 0x68;
    }
    else if (sVar36 < 5) {
      *(int *)(param_1 + 0xc0) = *_DAT_100a0784 + 0x9c;
    }
    goto LAB_10050e6c;
  }
  if (0 < *psVar25) {
    if (0 < *psVar17) {
      *psVar17 = *psVar16;
    }
    *PTR_DAT_100a0670 = 0;
    *psVar26 = 0;
    *puVar5 = 0;
    sVar36 = FUN_100916dc(*puVar39);
    if (sVar36 != 0) {
      FUN_10091504(*puVar39);
    }
    *_DAT_100a071c = 0;
    iVar32 = (int)*psVar25;
    if (iVar32 < 5) {
      *(int *)(param_1 + 0xc0) = *_DAT_100a07d8 + (iVar32 + -1) * 0x34;
    }
    else if (iVar32 < 8) {
      *(int *)(param_1 + 0xc0) = *_DAT_100a07d8 + 0x9c;
    }
    else {
      *(int *)(param_1 + 0xc0) = *_DAT_100a07d8 + (3 - (iVar32 + -8)) * 0x34;
    }
    *psVar25 = *psVar25 + 1;
    if (10 < *psVar25) {
      *psVar25 = 0;
    }
    goto LAB_10050e6c;
  }
  sVar36 = *_DAT_100a05f8;
  iVar32 = (int)sVar36;
  if (sVar36 != 0) {
    if (sVar36 < 1) {
      iVar32 = -iVar32;
    }
    *psVar17 = 0;
    sVar37 = (short)(iVar32 >> 1);
    if (sVar36 < 1) {
      sVar37 = sVar37 >> 1;
      if (2 < sVar37) {
        sVar37 = 2;
      }
      *(int *)(param_1 + 0xc0) = *_DAT_100a07ac + sVar37 * 0x34;
    }
    else {
      if (5 < sVar37) {
        sVar37 = 5;
      }
      *(int *)(param_1 + 0xc0) = *_DAT_100a07a0 + sVar37 * 0x34;
    }
    *_DAT_100a05f8 = *_DAT_100a05f8 + 1;
    goto LAB_10050e6c;
  }
  if (*_DAT_100a0588 != '\0') {
    *psVar17 = 0;
    psVar41 = _DAT_100a058c;
    iVar32 = *(int *)(param_1 + 0x24);
    if (iVar32 < 1) {
      iVar32 = -iVar32;
    }
    if (iVar32 < 0x81) {
      *_DAT_100a058c = 0;
      *(int *)(param_1 + 0xc0) = *_DAT_100a0798;
      sVar36 = *psVar21;
      if (0 < sVar36) {
        if (0 < *psVar17) {
          *psVar17 = *psVar16;
        }
        if (*_DAT_100a0768 == '\0') {
          *(int *)(param_1 + 0xc0) = *_DAT_100a0798 + sVar36 * 0x34;
        }
      }
    }
    else {
      *(int *)(param_1 + 0xc0) = *_DAT_100a0794 + ((int)*_DAT_100a058c >> 1) * 0x34;
      *_DAT_100a058c = *psVar41 + 1;
      if (0xf < *_DAT_100a058c) {
        *_DAT_100a058c = 0;
      }
    }
    goto LAB_10050e6c;
  }
  if (*psVar23 != 0) {
    sVar36 = *psVar23 + -1;
    if (0 < *psVar17) {
      *psVar17 = *psVar16;
    }
    *(undefined2 *)(param_1 + 0x110) = 0x50;
    if (0xb < sVar36) {
      *psVar23 = 1;
      sVar36 = 0;
    }
    psVar41 = _DAT_100a0698;
    *(int *)(param_1 + 0xc0) = *_DAT_100a07b8 + ((int)sVar36 >> 1) * 0x34;
    if (*psVar41 != 0) {
      .debug::_HandleItemUse(param_1);
    }
    if (1 < *psVar23) {
      *psVar23 = *psVar23 + 1;
    }
    if (*_DAT_100a05f4 == 0) {
      *_DAT_100a0764 = 6;
    }
    if (*_DAT_100a05fc == '\0') {
      if (*(int *)(param_1 + 0x2c) < 0) {
        *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + 200;
      }
      if ((0x12 < *(int *)(param_1 + 0x120)) && (sVar36 == 5)) {
        .debug::_Splash(param_1,3);
      }
    }
    if (((*(int *)(param_1 + 0x120) == 0) && (*(int *)(param_1 + 0x11c) == 0)) &&
       (*_DAT_100a0578 < 1)) {
      *psVar23 = 0;
    }
    goto LAB_10050e6c;
  }
  if (*psVar26 != 0) {
    if (0 < *psVar17) {
      *psVar17 = *psVar16;
    }
    *PTR_DAT_100a0670 = 0;
    *psVar24 = 0;
    *puVar5 = 0;
    sVar36 = FUN_100916dc(*puVar39);
    if (sVar36 != 0) {
      FUN_10091504(*puVar39);
    }
    *_DAT_100a071c = 0;
    sVar36 = *_DAT_100a06a0;
    if (sVar36 == 0) {
      if (_DAT_100a5f54 < 0xd) {
        if (_DAT_100a5f54 < 1) {
          _DAT_100a5f54 = 0xc;
        }
      }
      else {
        _DAT_100a5f54 = 1;
      }
      sVar36 = *psVar21;
      if (sVar36 < 1) {
        *(int *)(param_1 + 0xc0) = *_DAT_100a07dc + (_DAT_100a5f54 + -1 >> 1) * 0x34;
      }
      else {
        _DAT_100a5f54 = 1;
        *(undefined4 *)(param_1 + 0x2c) = 0;
        if (sVar36 == 6) {
          sVar36 = 5;
        }
        *(int *)(param_1 + 0xc0) = *_DAT_100a07a8 + sVar36 * 0x34;
      }
    }
    else {
      if (sVar36 == 0x14) {
        *(int *)(param_1 + 0xc0) = *_DAT_100a07c4 + 0x1d4;
      }
      else {
        *(int *)(param_1 + 0xc0) = *_DAT_100a07c4 + (sVar36 + -1 >> 1) * 0x34;
      }
      *_DAT_100a06a0 = *_DAT_100a06a0 + 1;
      if (0x14 < *_DAT_100a06a0) {
        if (*(char *)(param_1 + 0x17e) == '\0') {
          *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + 0x2000;
        }
        else {
          *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + -0x2000;
        }
        *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + -0x1600;
        *_DAT_100a06a0 = 0;
        *psVar26 = 0;
        *psVar24 = 0;
        *puVar5 = 0;
        sVar36 = FUN_100916dc(*puVar39);
        if (sVar36 != 0) {
          FUN_10091504(*puVar39);
        }
        *_DAT_100a071c = 2;
        pcVar8 = _DAT_100a0738;
        *(undefined1 *)(param_1 + 0xce) = 1;
        *pcVar8 = '\x01';
        *(int *)(param_1 + 0xc0) = *_DAT_100a07e0 + 0x68;
      }
    }
    goto LAB_10050e6c;
  }
  if (*_DAT_100a0698 != 0) {
    .debug::_HandleItemUse(param_1);
    goto LAB_10050e6c;
  }
  if ((*_DAT_100a0738 != '\0') || (*(char *)(param_1 + 0xce) != '\0')) {
    if (*_DAT_100a071c != 0) {
      if (0 < *psVar17) {
        *psVar17 = *psVar16;
      }
      *psVar24 = 0;
      *puVar5 = 0;
      sVar36 = FUN_100916dc(*puVar39);
      if (sVar36 != 0) {
        FUN_10091504(*puVar39);
      }
      sVar36 = *psVar21;
      if ((sVar36 < 2) || (*_DAT_100a071c < 4)) {
        if (*(short *)PTR_DAT_100a05e8 < 1) {
          *(int *)(param_1 + 0xc0) = *_DAT_100a07e0 + (*_DAT_100a071c + -1) * 0x34;
        }
        else {
          if (*_DAT_100a05e4 < 7) {
            *_DAT_100a05e4 = *_DAT_100a05e4 + 1;
          }
          cVar38 = .debug::_HasItem(0xf);
          if ((cVar38 == '\0') || (*(short *)PTR_DAT_100a05e8 < 4)) {
            iVar32 = *(short *)PTR_DAT_100a05e8 + -1;
            if (4 < iVar32) {
              iVar32 = 5;
            }
            *(int *)(param_1 + 0xc0) = *_DAT_100a077c + iVar32 * 0x34;
          }
          else {
            iVar32 = *(short *)PTR_DAT_100a05e8 + 2;
            if (7 < iVar32) {
              iVar32 = 8;
            }
            *(int *)(param_1 + 0xc0) = *_DAT_100a077c + iVar32 * 0x34;
          }
          if (5 < *(short *)PTR_DAT_100a05e8) {
            *(short *)PTR_DAT_100a05e8 = *(short *)PTR_DAT_100a05e8 + -1;
          }
        }
      }
      else {
        if (0 < *psVar17) {
          *psVar17 = *psVar16;
        }
        *(int *)(param_1 + 0xc0) = *_DAT_100a0790 + (sVar36 + -2) * 0x34;
      }
      goto LAB_10050e6c;
    }
    *psVar24 = 0;
    *puVar5 = 0;
    *psVar13 = 0;
    sVar36 = FUN_100916dc(*puVar39);
    if (sVar36 != 0) {
      FUN_10091504(*puVar39);
    }
    if ((*_DAT_100a0730 != '\0') || (*_DAT_100a0734 != '\0')) {
      if (0 < *psVar17) {
        *psVar17 = *psVar16;
      }
      if (*_DAT_100a0728 == '\0') {
        *(undefined2 *)(param_1 + 0x46) = 0xc;
      }
      pcVar8 = _DAT_100a072c;
      *_DAT_100a0728 = '\x01';
      *PTR_DAT_100a0670 = 0;
      if (*pcVar8 != '\0') {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 2;
        *(undefined2 *)puVar20 = 0;
        if (0x17 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        puVar5 = PTR_DAT_100a0620;
        *(int *)(param_1 + 0xc0) = *_DAT_100a07c0 + ((int)*(short *)(param_1 + 0x46) >> 1) * 0x34;
        if (((*puVar5 == '\0') &&
            ((*(short *)(param_1 + 0x46) == 6 || (*(short *)(param_1 + 0x46) == 0x10)))) ||
           ((*puVar5 != '\0' &&
            ((*(short *)(param_1 + 0x46) == 8 || (*(short *)(param_1 + 0x46) == 0x10)))))) {
          sVar36 = .debug::_FastRand(2);
          *(short *)puVar22 = sVar36 + *(short *)puVar22 + 1;
          if (3 < *(short *)puVar22) {
            *(short *)puVar22 = *(short *)puVar22 + -4;
          }
          if (*(int *)(param_1 + 0x120) == 0) {
            .debug::_STPlayRegSound(*(undefined4 *)(_DAT_100a025c + *(short *)puVar22 * 4),1,0x78);
          }
          else {
            .debug::_STPlay3DSoundRand(*_DAT_100a0378,1,0x2a,*(undefined4 *)(param_1 + 0xe));
          }
        }
        goto LAB_10050e6c;
      }
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 2;
      if (0x1f < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0;
      }
      piVar33 = _DAT_100a07d0;
      iVar32 = *(int *)(param_1 + 0x24);
      if (iVar32 < 1) {
        iVar32 = -iVar32;
      }
      if (((0x5db < iVar32) || (_DAT_100a5f5a == _DAT_100a5f5c)) && (*(short *)puVar20 < 1)) {
        *(undefined2 *)puVar20 = 0;
        puVar5 = PTR_DAT_100a0620;
        *(int *)(param_1 + 0xc0) = *piVar33 + ((int)*(short *)(param_1 + 0x46) >> 1) * 0x34;
        if (((*puVar5 == '\0') &&
            ((*(short *)(param_1 + 0x46) == 6 || (*(short *)(param_1 + 0x46) == 0x16)))) ||
           ((*puVar5 != '\0' &&
            ((*(short *)(param_1 + 0x46) == 8 || (*(short *)(param_1 + 0x46) == 0x20)))))) {
          sVar36 = .debug::_FastRand(2);
          *(short *)puVar22 = sVar36 + *(short *)puVar22 + 1;
          if (3 < *(short *)puVar22) {
            *(short *)puVar22 = *(short *)puVar22 + -4;
          }
          if (*(int *)(param_1 + 0x120) == 0) {
            .debug::_STPlayRegSound(*(undefined4 *)(_DAT_100a025c + *(short *)puVar22 * 4),1,0x55);
          }
          else {
            .debug::_STPlay3DSoundRand(*_DAT_100a0378,1,0x2a,*(undefined4 *)(param_1 + 0xe));
          }
        }
        goto LAB_10050e6c;
      }
    }
    *_DAT_100a0728 = '\0';
    if (*PTR_DAT_100a0670 == '\0') {
      *(undefined2 *)PTR_DAT_100a04fc = 3;
    }
    *PTR_DAT_100a0670 = 1;
    piVar33 = _DAT_100a07ac;
    if (*psVar17 < 0x96) {
      if (*(short *)puVar20 < 1) {
        if (_DAT_100a5f5c == _DAT_100a5f5a) {
          *(int *)(param_1 + 0xc0) = *_DAT_100a07ec + *(short *)PTR_DAT_100a04fc * 0x34;
        }
        else {
          *(undefined2 *)puVar20 = 4;
          *(int *)(param_1 + 0xc0) = *piVar33;
          *puVar19 = 1;
        }
      }
      else {
        *(short *)puVar20 = *(short *)puVar20 + -1;
        sVar36 = *(short *)puVar20;
        if (sVar36 == 2) {
          *(int *)(param_1 + 0xc0) = *_DAT_100a07ac + 0x68;
          *puVar19 = 1;
        }
        else if (sVar36 < 2) {
          if (sVar36 == 0) {
            *(int *)(param_1 + 0xc0) = *_DAT_100a07ac;
            *puVar19 = 0;
          }
          else if (-1 < sVar36) {
            *(int *)(param_1 + 0xc0) = *_DAT_100a07ac + 0x34;
            *puVar19 = 0;
          }
        }
        else if (sVar36 < 4) {
          *(int *)(param_1 + 0xc0) = *_DAT_100a07ac + 0x34;
          *puVar19 = 1;
        }
      }
      iVar32 = (int)*_DAT_100a05b0;
      if (0 < *_DAT_100a05b0) {
        if (iVar32 < 0x14) {
          iVar32 = iVar32 + -1 >> 1;
          if (4 < iVar32) {
            iVar32 = 5;
          }
          *(int *)(param_1 + 0xc0) = *_DAT_100a0788 + iVar32 * 0x34;
        }
        else {
          iVar34 = 0x27 - iVar32 >> 1;
          iVar32 = iVar34;
          if (iVar34 < 1) {
            iVar32 = 0;
          }
          if (iVar32 < 5) {
            if (iVar34 < 1) {
              iVar34 = 0;
            }
          }
          else {
            iVar34 = 5;
          }
          *(int *)(param_1 + 0xc0) = *_DAT_100a0788 + iVar34 * 0x34;
        }
      }
      sVar36 = *psVar21;
      if (sVar36 < 1) {
        if (_DAT_100a5f5a == 1) {
          if ((*(char *)(param_1 + 0xce) == '\f') || ((byte)(*(char *)(param_1 + 0xce) - 0x2cU) < 2)
             ) {
            *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a07e8;
            *(undefined2 *)puVar20 = 0;
            *puVar19 = 0;
          }
        }
        else if ((*(char *)(param_1 + 0xce) == '\x0f') ||
                ((byte)(*(char *)(param_1 + 0xce) - 0x2eU) < 2)) {
          *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a07e8;
          *(undefined2 *)puVar20 = 0;
          *puVar19 = 0;
        }
      }
      else {
        *(undefined2 *)puVar20 = 0;
        *puVar19 = 0;
        if (0 < *psVar17) {
          *psVar17 = *psVar16;
        }
        if (*_DAT_100a0768 == '\0') {
          *(int *)(param_1 + 0xc0) = *_DAT_100a07d4 + (sVar36 + -1) * 0x34;
        }
        else {
          *(int *)(param_1 + 0xc0) = *_DAT_100a07a4 + (sVar36 + -1) * 0x34;
        }
      }
    }
    else {
      sVar36 = *psVar17 + -0x96;
      iVar32 = (int)sVar36;
      iVar34 = iVar32 / 0x14 + (iVar32 >> 0x1f);
      if (*psVar16 < 3) {
        if (iVar32 < 100) {
          if (7 < iVar32) {
            sVar36 = 8;
          }
          *(int *)(param_1 + 0xc0) = *_DAT_100a07b0 + ((int)sVar36 / 3) * 0x34;
        }
        if ((sVar36 < 100) || (0x8b < sVar36)) {
          if ((sVar36 < 0x8c) || (0x9b < sVar36)) {
            if (0x9b < sVar36) {
              *psVar17 = 0;
              *psVar16 = *psVar16 + 1;
            }
          }
          else {
            sVar36 = sVar36 + -0x8c;
            if (0xe < sVar36) {
              sVar36 = 0xf;
            }
            *(int *)(param_1 + 0xc0) = *_DAT_100a07b0 + ((int)(short)(0xf - sVar36) / 3) * 0x34;
          }
        }
        else {
          sVar36 = sVar36 + -0x5c;
          if (0xe < sVar36) {
            sVar36 = 0xf;
          }
          *(int *)(param_1 + 0xc0) = *_DAT_100a07b0 + ((int)sVar36 / 3) * 0x34;
        }
      }
      else {
        *(int *)(param_1 + 0xc0) =
             *_DAT_100a07b4 +
             ((int)(short)(sVar36 + ((short)iVar34 - (short)(iVar34 >> 0x1f)) * -0x14) >> 1) * 0x34;
        if (0xf0 < iVar32) {
          sVar36 = .debug::_FastRand(0x3c);
          *psVar17 = -sVar36;
          *psVar16 = 0;
        }
      }
    }
    goto LAB_10050e6c;
  }
  if (0 < *psVar17) {
    *psVar17 = *psVar16;
  }
  *PTR_DAT_100a0670 = 0;
  *_DAT_100a071c = 0;
  sVar36 = *psVar24;
  if (sVar36 < 10) {
    if ((*(int *)(param_1 + 0x2c) < 1) && (*puVar5 == '\0')) {
      *psVar24 = sVar36 + 1;
    }
    else if (sVar36 < 3) {
      *psVar24 = 0x12;
    }
    else {
      *psVar24 = *psVar24 + 2;
    }
  }
  else if (((0 < *(int *)(param_1 + 0x2c)) && (*puVar5 == '\0')) &&
          (*(char *)(param_1 + 0x92) == '\0')) {
    *psVar24 = sVar36 + 1;
  }
  if ((*(char *)(param_1 + 0x92) != '\0') && (0xe < *psVar24)) {
    *psVar24 = *psVar24 + -1;
  }
  cVar38 = *puVar5;
  if (cVar38 != '\0') {
    *psVar24 = 0x1a;
  }
  if (*PTR_DAT_100a062c != '\0') {
    sVar36 = *psVar24;
    if (0xe < sVar36) {
      sVar36 = 0xf;
    }
    *psVar24 = sVar36;
  }
  cVar2 = *_DAT_100a05b8;
  if (cVar2 != '\0') {
    *_DAT_100a05b4 = *_DAT_100a05b4 + 1;
    if (7 < *_DAT_100a05b4) {
      *_DAT_100a05b4 = 0;
    }
    sVar36 = *psVar24;
    if (0xe < sVar36) {
      sVar36 = 0xf;
    }
    *psVar24 = sVar36;
  }
  sVar36 = *psVar24;
  if (sVar36 < 0x10) {
    if (sVar36 < 4) {
      if (sVar36 < 2) {
        if (sVar36 < 0) goto LAB_100504f0;
        sVar36 = 0;
      }
      else {
        sVar36 = 1;
      }
    }
    else if (sVar36 < 8) {
      if (sVar36 < 6) {
        sVar36 = 2;
      }
      else {
        sVar36 = 3;
      }
    }
    else {
      sVar36 = 4;
    }
  }
  else if (sVar36 < 0x24) {
    if (sVar36 < 0x1e) {
      if (sVar36 < 0x18) {
        sVar36 = 5;
      }
      else {
        sVar36 = 6;
      }
    }
    else {
      sVar36 = 7;
    }
  }
  else if (sVar36 < 0x2a) {
    sVar36 = 8;
  }
  else {
LAB_100504f0:
    sVar36 = 9;
  }
  if (cVar38 == '\0') {
    *(undefined2 *)puVar20 = 0;
    *puVar19 = 0;
    if (cVar2 == '\0') {
      *(int *)(param_1 + 0xc0) = *_DAT_100a07e4 + sVar36 * 0x34;
    }
    else {
      cStack_6b = '\x01';
      *(int *)(param_1 + 0xc0) = *_DAT_100a079c + *_DAT_100a05b4 * 0x34;
    }
  }
  else {
    *_DAT_100a05b8 = '\0';
    *_DAT_100a0664 = *_DAT_100a0664 + 1;
    if (7 < *_DAT_100a0664) {
      *_DAT_100a0664 = 0;
    }
    *(int *)(param_1 + 0xc0) = *_DAT_100a07bc + *_DAT_100a0664 * 0x34;
  }
LAB_10050e6c:
  if (*psVar26 == 0) {
    *_DAT_100a06a0 = 0;
  }
  if ((cStack_6b == '\0') && (*(bool *)(param_1 + 0x17e) = _DAT_100a5f5a != 2, *puVar19 != '\0')) {
    *(bool *)(param_1 + 0x17e) = *(char *)(param_1 + 0x17e) == '\0';
  }
  cVar38 = .debug::_ShouldEmitBubbles(param_1);
  if (cVar38 != '\0') {
    if (*(short *)(param_1 + 0x128) == 5) {
      *(short *)(iVar9 + 6) = *(short *)(iVar9 + 6) + -8;
    }
    else {
      *(short *)(iVar9 + 6) = *(short *)(iVar9 + 6) + -1;
    }
    puVar39 = _DAT_100a0394;
    if ((*(short *)(iVar9 + 6) < 1) && (*(short *)(param_1 + 0x116) == 0)) {
      psVar41 = (short *)(iVar9 + 8);
      if (*(short *)(iVar9 + 8) == 0) {
        *(undefined2 *)(iVar9 + 6) = 0;
        .debug::_STPlayRegSound(*puVar39,1,0x100);
        *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -0x70;
        *(undefined2 *)(param_1 + 0x116) = 0x28;
        if (*(short *)(param_1 + 0x128) == 5) {
          *psVar41 = 0xf;
        }
        else {
          *psVar41 = 0x1e;
        }
      }
      else {
        *psVar41 = *(short *)(iVar9 + 8) + -1;
      }
    }
    if (_DAT_100a5f56 == 0) {
      if (*(short *)(param_1 + 0x128) != 5) {
        .debug::_EmitBubble(param_1);
      }
      _DAT_100a5f56 = .debug::_FastRand(0x96);
      _DAT_100a5f56 = _DAT_100a5f56 + 200;
    }
    else {
      _DAT_100a5f56 = _DAT_100a5f56 + -1;
    }
  }
  *PTR_DAT_100a0708 = 0;
  if ((*PTR_DAT_100a070c == '\0') && (sVar36 = *(short *)PTR_DAT_100a0700, -1 < sVar36)) {
    if ((0 < sVar36) && (*(short *)PTR_DAT_100a0700 = sVar36 + -8, *(short *)PTR_DAT_100a0700 < 0))
    {
      *(undefined2 *)PTR_DAT_100a0700 = 0;
    }
  }
  else {
    *(short *)PTR_DAT_100a0700 = *(short *)PTR_DAT_100a0700 + 1;
  }
  sVar36 = *(short *)PTR_DAT_100a0700;
  if (sVar36 == 0) {
    if (((*_DAT_1009fd30 == '\0') || (*(short *)(param_1 + 0x116) < 0xf)) || (*psVar25 != 0)) {
      if ((*PTR_DAT_100a0644 == '\0') || (*PTR_DAT_100a0648 == '\0')) {
        if ((*PTR_DAT_100a0634 == '\0') || (*PTR_DAT_100a0638 == '\0')) {
          if ((*PTR_DAT_100a0628 == '\0') || (*PTR_DAT_100a062c == '\0')) {
            if ((*PTR_DAT_100a061c == '\0') || (*PTR_DAT_100a0620 == '\0')) {
              *(undefined4 *)(param_1 + 0xb8) = 0;
            }
            else {
              *(undefined4 *)(param_1 + 0xb8) = 0x10008;
              *(undefined2 *)(param_1 + 0x1a6) = 0xdf;
            }
          }
          else {
            *(undefined4 *)(param_1 + 0xb8) = 0x10003;
            *(undefined2 *)(param_1 + 0x1a6) = 0xdf;
          }
        }
        else {
          *(undefined4 *)(param_1 + 0xb8) = 0x1000c;
          *(undefined2 *)(param_1 + 0x1a6) = 9;
        }
      }
      else {
        sVar36 = *(short *)PTR_DAT_100a063c;
        if (sVar36 == 1) {
          *(undefined4 *)(param_1 + 0xb8) = 0x1000a;
        }
        else if (sVar36 < 1) {
          if (-1 < sVar36) {
            *(undefined4 *)(param_1 + 0xb8) = 0x10004;
          }
        }
        else if (sVar36 < 3) {
          *(undefined4 *)(param_1 + 0xb8) = 0x10001;
        }
        *(short *)(param_1 + 0x1a6) = *(short *)PTR_DAT_100a063c + 0xdc;
      }
      if (*(int *)(param_1 + 0xb8) == 0) {
        *(undefined2 *)(param_1 + 0x1a6) = 0;
        *(undefined2 *)(param_1 + 0x1a8) = 0;
        *(undefined1 *)(param_1 + 0x88) = 1;
      }
      else {
        *(undefined1 *)(param_1 + 0x88) = 0;
        *(undefined2 *)(param_1 + 0x1a8) = 8;
      }
    }
    else {
      *(undefined4 *)(param_1 + 0xb8) = 0x10006;
      *(undefined1 *)(param_1 + 0x18c) = 1;
      if (0x3c < *(short *)(param_1 + 0x116)) {
        *(undefined4 *)(param_1 + 0xb8) = 0x10009;
        *(undefined2 *)(param_1 + 0x1a6) = 0xdc;
        *(undefined2 *)(param_1 + 0x1a8) = 0x10;
      }
    }
  }
  else {
    sVar37 = sVar36;
    if ((sVar36 < 1) && (sVar36 < 1)) {
      sVar37 = -sVar36;
    }
    iVar32 = (int)sVar37;
    if (iVar32 < 0x3c) {
      if (iVar32 < 0x15) {
        *(undefined4 *)(param_1 + 0xb8) = 0;
        *(undefined1 *)(param_1 + 0x18c) = 0;
      }
      else {
        sVar36 = (short)(iVar32 + -0xc >> 2) + 2;
        if (0xf < sVar36) {
          sVar36 = 0xf;
        }
        sVar37 = .debug::_FastRand(6);
        sVar36 = sVar37 + sVar36 + -3;
        if (0xf < sVar36) {
          sVar36 = 0xf;
        }
        if (sVar36 < 0) {
          sVar36 = 0;
        }
        *(int *)(param_1 + 0xb8) = sVar36 + 0x50000;
        *(undefined1 *)(param_1 + 0x18c) = 1;
      }
    }
    else if (iVar32 < 0x50) {
      *(undefined2 *)PTR_DAT_100a0700 = 0x4f;
    }
    else if (sVar36 == 0x50) {
      *PTR_DAT_100a0708 = 1;
    }
  }
  *PTR_DAT_100a070c = 0;
  puVar4 = _DAT_1009fd34;
  sVar36 = *(short *)(*(int *)*_DAT_100a0058 + 0x272c);
  iVar32 = (int)sVar36;
  if (sVar36 != 0) {
    if ((*(char *)(param_1 + 0xce) == '\0') && (*(int *)PTR_DAT_100a0558 == 0)) {
      if (sVar36 < 0) {
        if (iVar32 * 5 < *(int *)(param_1 + 0x24)) {
          *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + iVar32;
        }
      }
      else if (*(int *)(param_1 + 0x24) < iVar32 * 5) {
        *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + iVar32;
      }
    }
    else {
      *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + (iVar32 >> 2);
      *puVar4 = 1;
    }
  }
  .debug::_PlayerConstraints(param_1);
  puVar7 = _DAT_1009fe68;
  puVar6 = _DAT_1009fe64;
  uVar29 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
  *(undefined2 *)(param_1 + 8) = uVar29;
  *(undefined2 *)(param_1 + 0xc) = uVar29;
  *puVar7 = uVar29;
  uVar29 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
  *(undefined2 *)(param_1 + 6) = uVar29;
  *(undefined2 *)(param_1 + 10) = uVar29;
  *puVar6 = uVar29;
  psVar41 = _DAT_1009fd94;
  sVar36 = *(short *)(param_1 + 0xc) +
           *(short *)(param_1 + 0x36) +
           (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  *(short *)(param_1 + 0x10) = sVar36;
  *psVar41 = sVar36;
  psVar41 = _DAT_1009fd90;
  sVar36 = *(short *)(param_1 + 10) +
           *(short *)(param_1 + 0x34) +
           (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  *(short *)(param_1 + 0xe) = sVar36;
  *psVar41 = sVar36;
  if ((((*(char *)(param_1 + 0xce) != '\0') || (*(int *)PTR_DAT_100a0558 != 0)) || (*psVar26 != 0))
     || (*_DAT_100a05a0 != '\0')) {
    *_DAT_100a0740 = *(undefined2 *)(param_1 + 0xe);
  }
  uRam100a5114 = 1;
  iVar32 = *(int *)(param_1 + 0x24);
  if (iVar32 < 0x101) {
    if (iVar32 < -0x100) {
      *piVar15 = *piVar15 + (iVar32 >> 2);
      if (0 < *piVar15) {
        *piVar15 = *piVar15 + (*(int *)(param_1 + 0x24) >> 2);
      }
      if (*piVar15 < -0x5000) {
        *piVar15 = -0x5000;
      }
    }
    else if ((_DAT_100a5f5a == 1) && (0 < *piVar15)) {
      *piVar15 = *piVar15 + -0x200;
      uRam100a5114 = 0;
    }
    else if ((_DAT_100a5f5a == 2) && (*piVar15 < 0)) {
      uRam100a5114 = 0;
      *piVar15 = *piVar15 + 0x200;
    }
  }
  else {
    *piVar15 = *piVar15 + (iVar32 >> 2);
    if (*piVar15 < 0) {
      *piVar15 = *piVar15 + (*(int *)(param_1 + 0x24) >> 2);
    }
    if (0x5000 < *piVar15) {
      *piVar15 = 0x5000;
    }
  }
  .debug::_PlayerScroll(param_1);
  puVar5 = PTR_DAT_100a0704;
  *_DAT_100a05a0 = '\0';
  *puVar5 = 1;
  .debug::_SeparateFromTiles2(param_1);
  if (*_DAT_100a06a0 == 0) {
    if (((0 < (short)*puVar18) || (*PTR_DAT_100a055c != '\0')) &&
       (*(char *)(param_1 + 0x17e) != '\0')) {
      *(short *)(param_1 + 0xc) = *(short *)(param_1 + 0xc) + -0x32;
    }
  }
  else if (*(char *)(param_1 + 0x17e) != '\0') {
    *(short *)(param_1 + 0xc) = *(short *)(param_1 + 0xc) + -0x14;
  }
  *PTR_DAT_100a055c = 0;
  if (((*(short *)(param_1 + 0xa4) < 1) && (*puVar18 == 0)) && (*psVar25 == 0)) {
    *(undefined2 *)(param_1 + 0x90) = 0;
    puVar39 = _DAT_100a03ec;
    uVar40 = 1;
    if ((*(int *)(param_1 + 0x11c) == 0) && (*(int *)(param_1 + 0x120) == 0)) {
      uVar40 = 0;
    }
    *PTR_DAT_100a0560 = uVar40;
    .debug::_STPlayRegSound(*puVar39,1,0x100);
    *puVar18 = 1;
  }
  iVar32 = *(int *)(param_1 + 0x11c);
  if (((iVar32 < 1) || (9 < iVar32)) || (*PTR_DAT_100a066c != '\0')) {
    if (((10 < iVar32) || (*(int *)(param_1 + 0x11c) == 0)) && (*PTR_DAT_100a066c != '\0')) {
      *PTR_DAT_100a066c = 0;
      .debug::_TintScreen(0,0);
    }
  }
  else {
    uStack_c2 = 0;
    uStack_c4 = 0;
    uStack_c6 = 0;
    sVar36 = *(short *)(param_1 + 0x128);
    if (sVar36 == 1) {
      uStack_c4 = 64000;
    }
    else if (sVar36 < 1) {
      if (-1 < sVar36) {
        uStack_c2 = 64000;
      }
    }
    else if (sVar36 < 3) {
      uStack_c6 = 64000;
    }
    .debug::_TintScreen(&uStack_c6,0xf);
    *PTR_DAT_100a066c = 1;
  }
  cVar38 = .debug::_ShouldEmitBubbles(param_1);
  if (cVar38 == '\0') {
    psVar41 = (short *)(iVar9 + 6);
    if (*(short *)(iVar9 + 6) < *(short *)(param_1 + 0xa4)) {
      *psVar41 = *(short *)(iVar9 + 6) + 8;
    }
    if (*psVar41 < 0) {
      *psVar41 = 1;
    }
    if (*(short *)(param_1 + 0xa4) < *psVar41) {
      *psVar41 = *(short *)(param_1 + 0xa4);
    }
    *(undefined2 *)(iVar9 + 8) = 0x1e;
  }
  puVar39 = _DAT_1009fd3c;
  *(undefined2 *)(iVar9 + 4) = *(undefined2 *)(param_1 + 0xa4);
  puVar5 = PTR_DAT_100a04c8;
  *puVar39 = *(undefined4 *)(param_1 + 0x24);
  *(undefined4 *)puVar5 = *(undefined4 *)(param_1 + 0x2c);
  if (*(short *)(*(int *)*_DAT_100a0058 + 0xb282) * 0x20 + 100 < (int)*(short *)(param_1 + 10)) {
    *(undefined2 *)(param_1 + 0xa4) = 0;
  }
  if ((((*(short *)(param_1 + 0xc) == *(short *)(param_1 + 0xc6)) && (*_DAT_100a05a0 == '\0')) &&
      ((*_DAT_100a05e0 == '\0' &&
       ((*(char *)(param_1 + 0x92) == '\0' &&
        (*(short *)(param_1 + 10) == *(short *)(param_1 + 0xc4))))))) && (*_DAT_100a06a0 == 0)) {
    if (0 < *_DAT_100a0744) {
      *_DAT_100a0744 = *_DAT_100a0744 + -1;
    }
    if (*_DAT_100a0744 == 0) {
      *PTR_DAT_100a0674 = 1;
    }
    else {
      *PTR_DAT_100a0674 = 0;
    }
  }
  else {
    *_DAT_100a0744 = 1;
    *PTR_DAT_100a0674 = 0;
  }
  if (*(int *)PTR_DAT_100a0558 == 0) {
    if ((0 < *(short *)PTR_DAT_100a0590) || (0 < *_DAT_100a05bc)) {
      *(short *)PTR_DAT_100a0590 = *(short *)PTR_DAT_100a0590 + -2;
      if (*(short *)PTR_DAT_100a0590 < 0) {
        *(undefined2 *)PTR_DAT_100a0590 = 0;
      }
      if (0 < *_DAT_100a05bc) {
        *_DAT_100a05bc = *_DAT_100a05bc + -1;
      }
    }
  }
  else {
    if ((*(short *)PTR_DAT_100a0590 < 0x1b) &&
       (*(short *)PTR_DAT_100a0590 = *(short *)PTR_DAT_100a0590 + 2,
       0x1b < *(short *)PTR_DAT_100a0590)) {
      *(undefined2 *)PTR_DAT_100a0590 = 0x1b;
    }
    if (*_DAT_100a05bc < 8) {
      *_DAT_100a05bc = *_DAT_100a05bc + 1;
    }
  }
  if (*PTR_DAT_100a0674 == '\0') {
    puVar35 = (undefined4 *)(PTR_DAT_100a0520 + 0x10);
    puVar39 = puVar35;
    for (sVar36 = 1; sVar36 < 6; sVar36 = sVar36 + 8) {
      uVar30 = puVar35[1];
      puVar39[-4] = *puVar35;
      puVar39[-3] = uVar30;
      uVar30 = puVar35[3];
      puVar39[-2] = puVar35[2];
      puVar39[-1] = uVar30;
      uVar30 = puVar35[5];
      *puVar39 = puVar35[4];
      puVar39[1] = uVar30;
      uVar30 = puVar35[7];
      puVar39[2] = puVar35[6];
      puVar39[3] = uVar30;
      uVar30 = puVar35[9];
      puVar39[4] = puVar35[8];
      puVar39[5] = uVar30;
      uVar30 = puVar35[0xb];
      puVar39[6] = puVar35[10];
      puVar39[7] = uVar30;
      uVar30 = puVar35[0xd];
      puVar39[8] = puVar35[0xc];
      puVar39[9] = uVar30;
      uVar30 = puVar35[0xf];
      puVar39[10] = puVar35[0xe];
      puVar39[0xb] = uVar30;
      uVar30 = puVar35[0x11];
      puVar39[0xc] = puVar35[0x10];
      puVar39[0xd] = uVar30;
      uVar30 = puVar35[0x13];
      puVar39[0xe] = puVar35[0x12];
      puVar39[0xf] = uVar30;
      uVar30 = puVar35[0x15];
      puVar39[0x10] = puVar35[0x14];
      puVar39[0x11] = uVar30;
      uVar30 = puVar35[0x17];
      puVar39[0x12] = puVar35[0x16];
      puVar39[0x13] = uVar30;
      uVar30 = puVar35[0x19];
      puVar39[0x14] = puVar35[0x18];
      puVar39[0x15] = uVar30;
      uVar30 = puVar35[0x1b];
      puVar39[0x16] = puVar35[0x1a];
      puVar39[0x17] = uVar30;
      uVar30 = puVar35[0x1d];
      puVar39[0x18] = puVar35[0x1c];
      puVar39[0x19] = uVar30;
      puVar1 = puVar35 + 0x1e;
      uVar30 = puVar35[0x1f];
      puVar35 = puVar35 + 0x20;
      puVar39[0x1a] = *puVar1;
      puVar39[0x1b] = uVar30;
      puVar39 = puVar39 + 0x20;
    }
    puVar35 = (undefined4 *)(PTR_DAT_100a0520 + sVar36 * 0x10);
    puVar39 = puVar35;
    for (; sVar36 < 0xe; sVar36 = sVar36 + 1) {
      uVar30 = puVar35[1];
      puVar39[-4] = *puVar35;
      puVar39[-3] = uVar30;
      puVar1 = puVar35 + 2;
      uVar30 = puVar35[3];
      puVar35 = puVar35 + 4;
      puVar39[-2] = *puVar1;
      puVar39[-1] = uVar30;
      puVar39 = puVar39 + 4;
    }
    uVar40 = 0;
    *PTR_DAT_100a0674 = 0;
    *(undefined4 *)(PTR_DAT_100a0520 + 0xd0) = *(undefined4 *)(param_1 + 10);
    if ((*(char *)(param_1 + 0xce) != '\0') && (*(int *)(param_1 + 0xdc) == 0)) {
      uVar40 = 1;
    }
    PTR_DAT_100a0520[0xd4] = uVar40;
    *(undefined4 *)(PTR_DAT_100a0520 + 0xd8) = *(undefined4 *)(param_1 + 0xc0);
    PTR_DAT_100a0520[0xdc] = *(undefined1 *)(param_1 + 0x17e);
  }
  .debug::_DoubleSpeedTrail(param_1);
  .debug::_StandardSpriteCleanup(param_1);
  *(short *)PTR_DAT_100a05ec = *(short *)PTR_DAT_100a05ec + 1;
  if (0x1f < *(short *)PTR_DAT_100a05ec) {
    *(undefined2 *)PTR_DAT_100a05ec = 0;
  }
  *_DAT_100a057c = *_DAT_100a057c + 2;
  if (0x167 < *_DAT_100a057c) {
    *_DAT_100a057c = *_DAT_100a057c + -0x168;
  }
  if (0 < *(short *)PTR_DAT_100a05a8) {
    if (*(short *)PTR_DAT_100a05a8 < 3) {
      *(undefined4 *)(param_1 + 0xb8) = 0x10008;
    }
    else {
      *(undefined4 *)(param_1 + 0xb8) = 0x10009;
    }
  }
  if (0 < *_DAT_100a0578) {
    if (*_DAT_100a056c == '\0') {
      *(undefined4 *)(param_1 + 0xb8) = 0xb0001;
    }
    else {
      *(undefined4 *)(param_1 + 0xb8) = 0xb0005;
    }
    *(undefined1 *)(param_1 + 0x88) = 0;
  }
  if (*_DAT_100a0564 != '\0') {
    *(undefined4 *)(param_1 + 0xb8) = 0x10007;
  }
  if (*PTR_DAT_100a04cc != '\0') {
    *PTR_DAT_100a04cc = *PTR_DAT_100a04cc + -1;
  }
  .debug::_UpdatePentSprites(param_1);
  return;
}


// ==== .HitPlayerTileSprite @ 10054ca8 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitPlayerTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  bool bVar1;
  bool bVar2;
  undefined4 *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  undefined1 *puVar6;
  undefined *puVar7;
  short *psVar8;
  undefined2 *puVar9;
  undefined *puVar10;
  undefined *puVar11;
  undefined2 *puVar12;
  short sVar14;
  int iVar13;
  char cVar15;
  undefined2 uVar16;
  uint uVar17;
  ushort unaff_r23;
  short sVar18;
  short sVar19;
  undefined4 uStack_84;
  undefined4 uStack_80;
  short sStack_72;
  short sStack_70;
  undefined1 auStack_52 [18];
  longlong lStack_40;
  undefined4 uStack_38;
  uint uStack_34;
  
  puVar12 = _DAT_100a0758;
  puVar11 = PTR_DAT_100a0754;
  puVar10 = PTR_DAT_100a074c;
  psVar8 = _DAT_100a06a0;
  puVar7 = PTR_DAT_100a0668;
  puVar5 = PTR_DAT_100a060c;
  puVar4 = PTR_DAT_100a0558;
  puVar3 = _DAT_100a03cc;
  sStack_70 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_72 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  .glue::SetRect(auStack_52,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                 (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
  if (0 < *_DAT_100a0578) {
    return;
  }
  if (((*PTR_DAT_100a0648 != '\0') && (param_4 == 0)) &&
     (sVar14 = .debug::_GetWaterTileKind(param_3), *(short *)PTR_DAT_100a063c == sVar14)) {
    param_4 = 1;
    param_3 = 3;
    param_2 = CONCAT22((short)((uint)param_2 >> 0x10) + -0x10,(short)param_2);
  }
  sVar14 = (short)param_3;
  if (param_4 == 1) {
    sVar19 = (short)((uint)param_2 >> 0x10);
    iVar13 = (int)sVar14 / 100 + ((int)sVar14 >> 0x1f);
    sVar14 = sVar14 + ((short)iVar13 - (short)(iVar13 >> 0x1f)) * -100;
    sVar18 = ((short)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8) + sStack_72) - (sVar19 + 0x10);
    bVar1 = false;
    bVar2 = false;
    if ((*(int *)(param_1 + 0x24) < 0) &&
       ((cVar15 = .debug::_IsInputKeyPressed(0), cVar15 != '\0' || (*(short *)puVar11 != 0)))) {
      if (sVar14 == 0) {
        bVar1 = true;
      }
      else if (((sVar14 == 4) || (sVar14 == 0x14)) || (sVar14 == 0x2d)) {
        bVar2 = true;
        if (0 < sVar18) {
          bVar1 = true;
        }
      }
      else if ((sVar14 == 5) && (sVar18 < 4)) {
        bVar1 = true;
      }
      unaff_r23 = 1;
    }
    else if ((0 < *(int *)(param_1 + 0x24)) &&
            ((cVar15 = .debug::_IsInputKeyPressed(1), cVar15 != '\0' || (*(short *)puVar11 != 0))))
    {
      if (sVar14 == 2) {
        bVar1 = true;
      }
      else if (((sVar14 == 7) || (sVar14 == 0x13)) || (sVar14 == 0x2f)) {
        bVar2 = true;
        if (0 < sVar18) {
          bVar1 = true;
        }
      }
      else if ((sVar14 == 6) && (sVar18 < 4)) {
        bVar1 = true;
      }
      unaff_r23 = 2;
    }
    puVar3 = _DAT_100a0374;
    if ((((bVar1) && (*_DAT_100a0738 == '\0')) && (*_DAT_100a0588 == '\0')) &&
       ((*(short *)PTR_DAT_100a05f0 == 0 && (*_DAT_100a05e0 == '\0')))) {
      if (*(short *)puVar11 == 0) {
        *_DAT_100a0764 = 0;
        .debug::_STPlay3DSoundRand(*puVar3,1,0x3c,*(undefined4 *)(param_1 + 0xe));
      }
      puVar6 = _DAT_100a05b8;
      *puVar12 = 1;
      puVar9 = _DAT_100a0714;
      _DAT_100a5f5a = unaff_r23 & 0xff;
      *puVar6 = 0;
      *puVar9 = 0;
      if (*(int *)(param_1 + 0x24) < 0) {
        *(undefined2 *)puVar10 = 1;
        *(undefined1 *)(param_1 + 0x17e) = 1;
      }
      else {
        *(undefined2 *)puVar10 = 2;
        *(undefined1 *)(param_1 + 0x17e) = 0;
      }
      if ((bVar2) && (*psVar8 == 0)) {
        sVar14 = .debug::_GetFGTile((int)(short)((short)param_2 >> 5),((int)sVar19 >> 5) + -1);
        puVar3 = _DAT_100a03f0;
        if (sVar14 == -1) {
          if ((short)(((short)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8) + sStack_72 + -4) -
                     (sVar19 + 0x10)) < 1) {
            *psVar8 = 1;
            .debug::_STPlayRegSound(*puVar3,1,0xab);
          }
        }
        else {
          *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + 1000;
          uVar16 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
          *(undefined2 *)(param_1 + 6) = uVar16;
          *(undefined2 *)(param_1 + 10) = uVar16;
          *(undefined4 *)(param_1 + 0x2c) = 0;
          *puVar12 = 1;
        }
      }
      *(undefined4 *)(param_1 + 0x2c) = 0;
      *(undefined4 *)(param_1 + 0x24) = 0;
    }
    if (0 < *(short *)PTR_DAT_100a04d8) {
      return;
    }
    cVar15 = .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_72,0,param_1 + 0x34,0,0);
    puVar5 = PTR_DAT_100a05a4;
    if (((cVar15 != '\0') && (*_DAT_100a059c = 2, *puVar5 != '\0')) && (*(int *)puVar4 != 0)) {
      *(int *)(param_1 + 0xdc) = *(int *)puVar4;
      *(short *)(*(int *)puVar4 + 10) =
           (*(short *)(param_1 + 10) + *(short *)(param_1 + 0x38)) -
           *(short *)(*(int *)puVar4 + 0x34);
      *(int *)(*(int *)puVar4 + 0x1c) = (int)*(short *)(*(int *)puVar4 + 10) << 8;
      uVar17 = *(uint *)(param_1 + 0x24);
      iVar13 = -((int)~uVar17 >> 0x1f);
      if ((iVar13 + (uint)(0xff < uVar17) & 1) == 0) {
        uVar17 = -(iVar13 + (uint)(0xff < uVar17) & 1);
      }
      else {
        uVar17 = iVar13 + (uint)(0xff < uVar17) & 1;
      }
      if (uVar17 != 0) {
        *(undefined4 *)(*(int *)puVar4 + 0x24) = 0;
      }
    }
    .debug::_CheckGroundCeilingHitEffects(param_1);
    return;
  }
  if (param_4 != 0) {
    if (param_4 == 2) {
      if ((*(short *)puVar5 == 0) && (0x9c4 < *(int *)(param_1 + 0x2c))) {
        *(undefined1 *)(param_1 + 0xeb) = 1;
      }
      else {
        *(undefined1 *)(param_1 + 0xeb) = 0;
      }
      cVar15 = .debug::_CrunchTile(param_2,*(undefined1 *)(param_1 + 0xeb));
      if (cVar15 != '\0') {
        uStack_84 = _DAT_100a624c;
        uStack_80 = uRam100a6250;
        if (*(char *)(param_1 + 0xeb) != '\0') {
          uStack_34 = *(uint *)(param_1 + 0x2c) ^ 0x80000000;
          uStack_38 = 0x43300000;
          iVar13 = (int)(dRam100a1a20 * ((double)CONCAT44(0x43300000,uStack_34) - _DAT_100a1a38));
          lStack_40 = (longlong)iVar13;
          .debug::_RectBounceFake2(param_1,&stack0x0000001c,&uStack_84,&sStack_72,0,auStack_52);
          *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
          *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
          cVar15 = .debug::_IsInputKeyPressed(3);
          if (cVar15 == '\0') {
            *puVar7 = 0;
            sVar14 = FUN_100916dc(*puVar3);
            if (sVar14 != 0) {
              FUN_10091504(*puVar3);
            }
            *(undefined4 *)(param_1 + 0x2c) = 0;
          }
          else {
            .debug::_STPlayRegSound(*puVar3,1,0xba);
            *puVar7 = 1;
            *(int *)(param_1 + 0x2c) = iVar13;
            if (0 < *(int *)(param_1 + 0x2c)) {
              *(int *)(param_1 + 0x2c) = -*(int *)(param_1 + 0x2c);
            }
          }
          *(undefined2 *)puVar5 = 5;
          *(undefined1 *)(param_1 + 0xce) = 0;
        }
      }
      return;
    }
    return;
  }
  if (sVar14 < 100) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_72,0,param_1 + 0x34,0,0);
    .debug::_CheckGroundCeilingHitEffects(param_1);
    return;
  }
  if (sVar14 < 200) {
    cVar15 = .debug::_WallBounceBG
                       (param_1,param_3 + -100,&stack0x0000001c,&sStack_72,0,param_1 + 0x34,0,0);
    if ((cVar15 != '\0') && (*(char *)(param_1 + 0xce) != '\0')) {
      *PTR_DAT_100a04cc = 0xf;
    }
    .debug::_CheckGroundCeilingHitEffects(param_1);
    return;
  }
  if ((param_3 - 600U & 0xffff) < 2) {
    return;
  }
  cVar15 = .debug::_IsWaterTile(param_3);
  if (cVar15 == '\0') {
    return;
  }
  if (*PTR_DAT_100a0704 == '\0') {
    return;
  }
  if (*(char *)(param_1 + 0x140) != '\0') {
    return;
  }
  .debug::_HandleUnderWater(param_1,param_2);
  return;
}


// ==== .HitPlayerSprite @ 100556f4 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */
/* WARNING: Restarted to delay deadcode elimination for space: ram */

void _HitPlayerSprite(int param_1,int param_2)

{
  int iVar1;
  int iVar2;
  undefined1 uVar3;
  short sVar4;
  bool bVar5;
  bool bVar6;
  short *psVar7;
  short *psVar8;
  short *psVar9;
  short *psVar10;
  undefined2 *puVar11;
  undefined4 *puVar12;
  short *psVar13;
  undefined4 *puVar14;
  short *psVar15;
  short *psVar16;
  int *piVar17;
  undefined *puVar18;
  undefined1 *puVar19;
  int *piVar20;
  undefined4 *puVar21;
  undefined4 *puVar22;
  undefined4 *puVar23;
  undefined4 *puVar24;
  undefined *puVar25;
  undefined *puVar26;
  undefined1 *puVar27;
  undefined *puVar28;
  undefined *puVar29;
  undefined *puVar30;
  undefined *puVar31;
  undefined *puVar32;
  undefined *puVar33;
  undefined1 *puVar34;
  undefined *puVar35;
  short sVar36;
  int iVar37;
  short sVar40;
  short sVar41;
  uint uVar38;
  short sVar42;
  char cVar43;
  undefined *puVar39;
  int iVar44;
  int *piVar45;
  short *psVar46;
  int *piVar47;
  undefined4 uVar48;
  undefined4 uVar49;
  undefined2 uVar50;
  char *pcVar51;
  double dVar52;
  double dVar53;
  undefined4 uStack_1e2;
  undefined4 uStack_1de;
  short sStack_1d4;
  short sStack_1d2;
  undefined1 auStack_1c0 [266];
  short sStack_b6;
  short sStack_b4;
  short sStack_b2;
  short sStack_b0;
  char cStack_ae;
  int iStack_ac;
  int iStack_a8;
  int iStack_a4;
  int iStack_a0;
  int iStack_9c;
  longlong lStack_98;
  undefined4 uStack_90;
  uint uStack_8c;
  longlong lStack_88;
  undefined4 uStack_80;
  uint uStack_7c;
  longlong lStack_78;
  undefined4 uStack_70;
  uint uStack_6c;
  undefined8 uStack_68;
  undefined8 uStack_60;
  
  puVar34 = _DAT_100a0724;
  puVar33 = PTR_DAT_100a0654;
  puVar32 = PTR_DAT_100a0650;
  puVar31 = PTR_DAT_100a0644;
  puVar30 = PTR_DAT_100a0634;
  puVar29 = PTR_DAT_100a0628;
  puVar28 = PTR_DAT_100a061c;
  puVar27 = _DAT_100a05e0;
  puVar11 = _DAT_100a0574;
  puVar26 = PTR_DAT_100a053c;
  puVar25 = PTR_DAT_100a0514;
  puVar24 = _DAT_100a0384;
  puVar23 = _DAT_100a02dc;
  puVar22 = _DAT_100a02d8;
  puVar21 = _DAT_100a02d4;
  puVar12 = _DAT_100a02d0;
  puVar14 = _DAT_100a0058;
  piVar20 = _DAT_1009ffc0;
  puVar19 = _DAT_1009fec4;
  puVar18 = PTR_DAT_1009fe78;
  piVar17 = _DAT_1009fe74;
  piVar47 = _DAT_1009fe70;
  psVar16 = _DAT_1009fe68;
  psVar15 = _DAT_1009fe64;
  puVar39 = PTR_DAT_1009fdbc;
  psVar13 = _DAT_1009fdb8;
  psVar10 = _DAT_1009fd94;
  psVar9 = _DAT_1009fd90;
  psVar8 = _DAT_1009fd84;
  psVar7 = _DAT_1009fd44;
  psVar46 = _DAT_1009fd40;
  pcVar51 = &DAT_100ac02c;
  if (0 < *_DAT_100a069c) {
    return;
  }
  if ((0 < *_DAT_100a0578) && (*(undefined **)(param_2 + 0x4c) != PTR_PTR_100a047c)) {
    return;
  }
  puVar35 = *(undefined **)(param_2 + 0x4c);
  if (((puVar35 == PTR_PTR_100a047c) && (*(short *)(param_2 + 0xa6) == 0)) &&
     (*(short *)(param_2 + 0xb0) == 0)) {
    iVar37 = (int)*(short *)(param_2 + 4);
    if (iVar37 == 0x50d) {
      .debug::_STPlayRegSound(*_DAT_100a02d4,1,0x100);
      sVar40 = .debug::_FastRand(10000);
      .debug::_STPlay3DSoundPitched
                (*_DAT_100a0300,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar40 + 40000);
      sVar40 = .debug::_FastRand(10000);
      .debug::_STPlay3DSoundPitched
                (*_DAT_100a0300,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar40 + 30000);
      *piVar20 = *piVar20 + 100;
      *(short *)(piVar20 + 4) = *(short *)(piVar20 + 4) + 0x19;
      *(undefined1 *)(param_2 + 0xe9) = 1;
      return;
    }
    if (iVar37 < 0x50d) {
      if (iVar37 == 0x423) {
        if (*(short *)(*(int *)*_DAT_100a0058 + *(short *)(param_2 + 0x48) * 0x10 + 8) != 0) {
          .debug::_STPlayRegSound(*_DAT_100a02c4,1,0x100);
        }
        FUN_1009f80c(param_2);
        return;
      }
      if (iVar37 < 0x423) {
        if (iVar37 < 0x41f) {
          if (iVar37 == 0x45) {
            if (0x167 < *_DAT_100a0578) {
              return;
            }
            *_DAT_100a0578 = -1;
            puVar39 = PTR_DAT_100a05a8;
            *puVar11 = 0xe;
            *(undefined2 *)puVar39 = 6;
            .debug::_STPlayRegSound(*_DAT_100a03e0,1,0x100);
            puVar18 = PTR_DAT_100a04d4;
            *(undefined1 *)(param_2 + 0xe9) = 1;
            puVar39 = PTR_DAT_100a04d0;
            *(short *)(param_1 + 0xc) = (short)*(undefined4 *)puVar18;
            *(short *)(param_1 + 10) = (short)*(undefined4 *)puVar39;
            *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
            *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
            *(undefined4 *)(param_1 + 0x2c) = 0;
            *(undefined4 *)(param_1 + 0x24) = 0;
            return;
          }
        }
        else if (iVar37 != 0x421) {
          if (0x420 < iVar37) {
            iVar37 = *(int *)*_DAT_100a0058 + *(short *)(param_2 + 0x48) * 0x10;
            if (*(short *)(iVar37 + 10) == 0) {
              *(undefined2 *)((int)_DAT_1009ffc0 + *(short *)(iVar37 + 8) * 2 + 0xad8) = 1;
            }
            else {
              *(short *)((int)_DAT_1009ffc0 + *(short *)(iVar37 + 8) * 2 + 0xad8) =
                   *(short *)(iVar37 + 10);
            }
            FUN_1009f80c(param_2);
            return;
          }
          uVar48 = *(undefined4 *)PTR_DAT_100a0478;
          if (iVar37 == 0x41f) {
            *_DAT_1009ffc0 = *_DAT_1009ffc0 + 10;
            *(short *)(piVar20 + 5) = *(short *)(piVar20 + 5) + 1;
            .debug::_STPlayRegSound(*puVar21,1,0x55);
          }
          else {
            *_DAT_1009ffc0 = *_DAT_1009ffc0 + 1000;
            *(short *)(piVar20 + 5) = *(short *)(piVar20 + 5) + 100;
            sVar40 = .debug::_FastRand(10000);
            .debug::_STPlay3DSoundPitched
                      (*_DAT_100a0300,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar40 + 40000);
            sVar40 = .debug::_FastRand(10000);
            .debug::_STPlay3DSoundPitched
                      (*_DAT_100a0300,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar40 + 30000);
            .debug::_STPlayRegSound(*puVar21,1,0x55);
          }
          FUN_1009f80c(param_2);
          if (99 < *(short *)(piVar20 + 5)) {
            uVar48 = *_DAT_100a0474;
          }
          if ((*(short *)(_DAT_1009fe44 + 6) == 1) && (*_DAT_100a019c < 1000)) {
            .debug::_ExplodeFaceIntoParticles(uVar48,*(undefined4 *)(param_2 + 10),1,1,1,0x28,0x65);
          }
          else if ((*(short *)(_DAT_1009fe44 + 6) == 2) && (*_DAT_100a019c < 0x5dc)) {
            .debug::_ExplodeFaceIntoParticles(uVar48,*(undefined4 *)(param_2 + 10),2,1,7,0x28,0x65);
          }
          else {
            .debug::_ExplodeFaceIntoParticles(uVar48,*(undefined4 *)(param_2 + 10),2,2,7,0x28,0x65);
          }
          puVar14 = _DAT_100a037c;
          if (*(short *)(piVar20 + 5) < 100) {
            return;
          }
          *(short *)(piVar20 + 5) = 0;
          sVar40 = -1;
          .debug::_STPlayRegSound(*puVar14,1,0x100);
          .debug::_STPlayRegSound(*_DAT_100a038c,1,0x100);
          sVar36 = 0;
          while (sVar36 < 0x1b) {
            sVar42 = *(short *)((int)piVar20 + sVar36 * 10 + 0x24);
            if ((sVar42 == -1) ||
               ((sVar41 = sVar36, sVar42 == 0x16 &&
                (*(char *)((int)piVar20 + sVar36 * 10 + 0x2c) == '\0')))) {
              sVar41 = 0x1e;
              sVar40 = sVar36;
            }
            sVar36 = sVar41 + 1;
          }
          if (sVar40 == -1) {
            return;
          }
          iVar37 = sVar40 * 10;
          *(undefined2 *)((int)piVar20 + iVar37 + 0x24) = 0x16;
          psVar46 = (short *)((int)piVar20 + iVar37 + 0x26);
          *psVar46 = *(short *)((int)piVar20 + iVar37 + 0x26) + 1;
          if (99 < *psVar46) {
            *psVar46 = 99;
          }
          *(undefined1 *)((int)piVar20 + iVar37 + 0x2c) = 0;
          *(undefined1 *)(param_2 + 0xe9) = 1;
          .debug::_STPlayRegSound(*puVar21,1,0x100);
          .debug::_UpdateStatusBar(1,1,0);
          return;
        }
      }
      else {
        if (iVar37 == 0x50a) {
          *(undefined1 *)(param_2 + 0xe9) = 1;
          .debug::_STPlayRegSound(*puVar22,1,0x100);
          *piVar20 = *piVar20 + 100;
          *(short *)((int)piVar20 + 0xe) = *(short *)((int)piVar20 + 0xe) + 0x2a0;
          if (*(short *)((int)piVar20 + 0xe) <= *(short *)(piVar20 + 3)) {
            return;
          }
          *(short *)((int)piVar20 + 0xe) = *(short *)(piVar20 + 3);
          return;
        }
        if (0x509 < iVar37) {
          if (0x50b < iVar37) {
            .debug::_STPlayRegSound(*_DAT_100a02d4,1,0x100);
            sVar40 = .debug::_FastRand(10000);
            .debug::_STPlay3DSoundPitched
                      (*_DAT_100a0300,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar40 + 40000);
            *piVar20 = *piVar20 + 0x19;
            *(short *)(piVar20 + 4) = *(short *)(piVar20 + 4) + 5;
            *(undefined1 *)(param_2 + 0xe9) = 1;
            return;
          }
          *(undefined1 *)(param_2 + 0xe9) = 1;
          .debug::_STPlayRegSound(*puVar12,1,0x100);
          *piVar20 = *piVar20 + 100;
          *(short *)(piVar20 + 1) = *(short *)(piVar20 + 1) + 0x2a0;
          *(short *)((int)piVar20 + 6) = *(short *)((int)piVar20 + 6) + 0x2a0;
          *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + 0xe0;
          if (*(short *)((int)piVar20 + 10) < *(short *)(piVar20 + 1)) {
            *(short *)(piVar20 + 1) = *(short *)((int)piVar20 + 10);
          }
          sVar40 = *(short *)((int)piVar20 + 10);
          if (sVar40 < *(short *)((int)piVar20 + 6)) {
            *(short *)((int)piVar20 + 6) = sVar40;
          }
          sVar40 = *(short *)((int)piVar20 + 10);
          if (*(short *)(param_1 + 0xa4) <= sVar40) {
            return;
          }
          *(short *)(param_1 + 0xa4) = sVar40;
          return;
        }
        if (iVar37 == 0x4bf) {
          return;
        }
      }
    }
    else {
      if (iVar37 == 0x51a) {
        .debug::_STPlayRegSound(*_DAT_100a02d4,1,0xab);
        *piVar20 = *piVar20 + 5;
        *(short *)(piVar20 + 4) = *(short *)(piVar20 + 4) + 100;
        *(undefined1 *)(param_2 + 0xe9) = 1;
        return;
      }
      if (iVar37 < 0x51a) {
        if (iVar37 == 0x516) {
          .debug::_STPlayRegSound(*_DAT_100a02d4,1,0xab);
          *piVar20 = *piVar20 + 5;
          *(short *)(piVar20 + 4) = *(short *)(piVar20 + 4) + 1;
          *(undefined1 *)(param_2 + 0xe9) = 1;
          return;
        }
        if (iVar37 < 0x516) {
          if (iVar37 == 0x514) {
            *(undefined1 *)(param_2 + 0xe9) = 1;
            .debug::_STPlayRegSound(*puVar22,1,0xab);
            *piVar20 = *piVar20 + 0x19;
            *(short *)((int)piVar20 + 0xe) = *(short *)((int)piVar20 + 0xe) + 0xe0;
            if (*(short *)((int)piVar20 + 0xe) <= *(short *)(piVar20 + 3)) {
              return;
            }
            *(short *)((int)piVar20 + 0xe) = *(short *)(piVar20 + 3);
            return;
          }
          if (0x513 < iVar37) {
            *(undefined1 *)(param_2 + 0xe9) = 1;
            .debug::_STPlayRegSound(*puVar12,1,0x100);
            *piVar20 = *piVar20 + 0x19;
            *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + 0xe0;
            *(short *)((int)piVar20 + 6) = *(short *)((int)piVar20 + 6) + 0xe0;
            *(undefined2 *)(piVar20 + 2) = 0x1e;
            if (*(short *)((int)piVar20 + 10) < *(short *)((int)piVar20 + 6)) {
              *(short *)((int)piVar20 + 6) = *(short *)((int)piVar20 + 10);
            }
            if (*(short *)((int)piVar20 + 10) < *(short *)(param_1 + 0xa4)) {
              *(short *)(param_1 + 0xa4) = *(short *)((int)piVar20 + 10);
            }
            *(undefined2 *)(piVar20 + 1) = *(undefined2 *)(param_1 + 0xa4);
            return;
          }
        }
        else if (0x518 < iVar37) {
          .debug::_STPlayRegSound(*_DAT_100a02d4,1,0xab);
          *piVar20 = *piVar20 + 5;
          *(short *)(piVar20 + 4) = *(short *)(piVar20 + 4) + 10;
          *(undefined1 *)(param_2 + 0xe9) = 1;
          return;
        }
      }
      else {
        if (iVar37 == 0x546) {
          .debug::_STPlayRegSound(*_DAT_100a0370,1,0x100);
          *(short *)((int)piVar20 + 6) = *(short *)((int)piVar20 + 6) + 0x230;
          if (*(short *)(piVar20 + 1) < *(short *)((int)piVar20 + 6)) {
            *(short *)((int)piVar20 + 6) = *(short *)(piVar20 + 1);
          }
          *(undefined1 *)(param_2 + 0xe9) = 1;
          return;
        }
        if (iVar37 < 0x546) {
          if ((iVar37 < 0x53e) && (0x53b < iVar37)) {
            .debug::_STPlayRegSound(*_DAT_100a037c,1,0xab);
            *piVar20 = *piVar20 + 2000;
            *(undefined1 *)(param_2 + 0xe9) = 1;
            if (*(short *)(param_2 + 4) == 0x53d) {
              .debug::_GammaFadeOutAsync(2,*_DAT_100a07f0,_DAT_100a07f0[1],0xc,0x10);
            }
            else if (*(short *)(param_2 + 4) == 0x53c) {
              .debug::_GammaFadeOutAsync(2,*_DAT_100a07f4,_DAT_100a07f4[1],0xc,0x10);
            }
            for (sVar40 = 0; sVar40 < 5; sVar40 = sVar40 + 1) {
              uVar38 = .glue::TickCount();
              do {
                iVar37 = .glue::TickCount();
              } while (iVar37 - 2U < uVar38);
              .debug::_HandleAsyncGammaFade();
            }
            .debug::_GammaFadeInAsync(0x28);
            for (sVar40 = 0; sVar40 < 10; sVar40 = sVar40 + 1) {
              uVar38 = .glue::TickCount();
              .debug::_HandleAsyncGammaFade();
              do {
                iVar37 = .glue::TickCount();
              } while (iVar37 - 1U < uVar38);
            }
            if (*(short *)(param_2 + 4) == 0x53c) {
              *(undefined2 *)puVar39 = 0xb;
            }
            else if (*(short *)(param_2 + 4) == 0x53d) {
              *psVar13 = 0xb;
            }
            for (sVar40 = 0; sVar40 < 0xb; sVar40 = sVar40 + 1) {
              uVar38 = .glue::TickCount();
              if (*(short *)(param_2 + 4) == 0x53c) {
                *(short *)puVar39 = *(short *)puVar39 + -1;
              }
              else if (*(short *)(param_2 + 4) == 0x53d) {
                *psVar13 = *psVar13 + -1;
              }
              .debug::_UpdateStatusBar(1,0,1);
              .debug::_HandleAsyncGammaFade();
              do {
                iVar37 = .glue::TickCount();
              } while (iVar37 - 2U < uVar38);
            }
            if (*(short *)(param_2 + 4) == 0x53c) {
              *(undefined2 *)((int)piVar20 + 6) = *(undefined2 *)((int)piVar20 + 10);
              *(undefined2 *)(piVar20 + 1) = *(undefined2 *)((int)piVar20 + 10);
              *(undefined2 *)(piVar20 + 2) = 8;
            }
            else if (*(short *)(param_2 + 4) == 0x53d) {
              *(undefined2 *)((int)piVar20 + 0xe) = *(undefined2 *)(piVar20 + 3);
            }
            for (sVar40 = 0; sVar40 < 0x70; sVar40 = sVar40 + 8) {
              uVar38 = .glue::TickCount();
              if (*(short *)(param_2 + 4) == 0x53c) {
                *(short *)((int)piVar20 + 10) = *(short *)((int)piVar20 + 10) + 8;
              }
              else if (*(short *)(param_2 + 4) == 0x53d) {
                *(short *)(piVar20 + 3) = *(short *)(piVar20 + 3) + 8;
              }
              .debug::_UpdateStatusBar(1,0,1);
              .debug::_HandleAsyncGammaFade();
              do {
                iVar37 = .glue::TickCount();
              } while (iVar37 - 2U < uVar38);
            }
            piVar47 = piVar20 + 1;
            for (sVar40 = 0; sVar40 < 0x70; sVar40 = sVar40 + 8) {
              uVar38 = .glue::TickCount();
              if (*(short *)(param_2 + 4) == 0x53c) {
                *(short *)piVar47 = *(short *)piVar47 + 8;
                *(short *)((int)piVar20 + 6) = *(short *)((int)piVar20 + 6) + 8;
                *(short *)(param_1 + 0xa4) = *(short *)piVar47;
              }
              else if (*(short *)(param_2 + 4) == 0x53d) {
                *(short *)((int)piVar20 + 0xe) = *(short *)((int)piVar20 + 0xe) + 8;
              }
              .debug::_UpdateStatusBar(1,0,1);
              .debug::_HandleAsyncGammaFade();
              do {
                iVar37 = .glue::TickCount();
              } while (iVar37 - 2U < uVar38);
            }
            if (*(short *)(param_2 + 4) == 0x53c) {
              *(undefined2 *)puVar39 = 0xb;
            }
            else if (*(short *)(param_2 + 4) == 0x53d) {
              *psVar13 = 0xb;
            }
            for (sVar40 = 0; sVar40 < 0xb; sVar40 = sVar40 + 1) {
              uVar38 = .glue::TickCount();
              if (*(short *)(param_2 + 4) == 0x53c) {
                *(short *)puVar39 = *(short *)puVar39 + -1;
              }
              else if (*(short *)(param_2 + 4) == 0x53d) {
                *psVar13 = *psVar13 + -1;
              }
              .debug::_UpdateStatusBar(1,0,1);
              .debug::_HandleAsyncGammaFade();
              do {
                iVar37 = .glue::TickCount();
              } while (iVar37 - 2U < uVar38);
            }
            return;
          }
        }
        else if (iVar37 == 0xbea) {
          if (*(short *)PTR_DAT_100a05c4 != 0) {
            return;
          }
          *(undefined1 *)(param_2 + 0xe9) = 1;
          puVar11 = _DAT_100a05d4;
          *puVar27 = 1;
          puVar39 = PTR_DAT_100a05c8;
          *puVar11 = 1;
          iVar37 = _DAT_100a0778;
          *(undefined2 *)puVar39 = 0;
          *(undefined4 *)(param_1 + 0x14) = *(undefined4 *)(param_2 + 0x14);
          *(undefined4 *)(param_1 + 0x1c) = *(undefined4 *)(param_2 + 0x1c);
          *(short *)(param_1 + 0xc) = (short)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
          *(short *)(param_1 + 10) = (short)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar37 + 4);
          .glue::SetRect(param_1 + 0x34,0x37,0x3e,99,0x6e);
          return;
        }
      }
    }
    if ((1999 < iVar37) && (iVar37 < 0x802)) {
      sVar40 = -1;
      if (iVar37 == 2000) {
        iVar37 = (int)*(short *)(*(int *)*_DAT_100a0058 + *(short *)(param_2 + 0x48) * 0x10 + 8);
      }
      else {
        iVar37 = iVar37 + -2000;
      }
      sVar36 = 0;
      while (sVar36 < 0x1b) {
        iVar44 = (int)*(short *)((int)_DAT_1009ffc0 + sVar36 * 10 + 0x24);
        if ((iVar44 == -1) ||
           ((sVar42 = sVar36, iVar44 == iVar37 &&
            (*(char *)((int)_DAT_1009ffc0 + sVar36 * 10 + 0x2c) != '\0')))) {
          sVar42 = 0x1e;
          sVar40 = sVar36;
        }
        sVar36 = sVar42 + 1;
      }
      if (sVar40 == -1) {
        return;
      }
      iVar44 = sVar40 * 10;
      *(short *)((int)_DAT_1009ffc0 + iVar44 + 0x24) = (short)iVar37;
      psVar46 = (short *)((int)piVar20 + iVar44 + 0x24);
      if (*psVar46 == 2) {
        *psVar46 = 3;
      }
      puVar14 = _DAT_100a02cc;
      *(undefined1 *)((int)piVar20 + iVar44 + 0x2c) = 1;
      *(undefined1 *)(param_2 + 0xe9) = 1;
      .debug::_STPlayRegSound(*puVar14,1,0x100);
      psVar46 = _DAT_1009fda4;
      *(undefined2 *)PTR_DAT_1009fda8 = 0x20;
      puVar11 = _DAT_1009fda0;
      *psVar46 = sVar40;
      *puVar11 = 0;
      .debug::_UpdateStatusBar(1,1,0);
      return;
    }
    if (0xc7f < iVar37) {
      sVar40 = -1;
      if (iVar37 == 0xc95) {
        .debug::_RemoveItem(0);
      }
      if (*(short *)(param_2 + 4) == 0xc8f) {
        .debug::_RemoveItem(0xe);
      }
      sVar36 = 0;
      while (sVar36 < 0x1b) {
        iVar37 = (int)*(short *)((int)piVar20 + sVar36 * 10 + 0x24);
        if ((iVar37 == -1) ||
           ((sVar42 = sVar36, iVar37 == *(short *)(param_2 + 4) + -0xc80 &&
            (*(char *)((int)piVar20 + sVar36 * 10 + 0x2c) == '\0')))) {
          sVar42 = 0x1e;
          sVar40 = sVar36;
        }
        sVar36 = sVar42 + 1;
      }
      if (sVar40 == -1) {
        return;
      }
      iVar37 = sVar40 * 10;
      *(short *)((int)piVar20 + iVar37 + 0x24) = *(short *)(param_2 + 4) + -0xc80;
      if (*(short *)(param_2 + 4) == 0xc86) {
        *(short *)((int)piVar20 + iVar37 + 0x26) = *(short *)((int)piVar20 + iVar37 + 0x26) + 3;
      }
      else {
        *(short *)((int)piVar20 + iVar37 + 0x26) = *(short *)((int)piVar20 + iVar37 + 0x26) + 1;
      }
      psVar46 = (short *)((int)piVar20 + iVar37 + 0x26);
      if (99 < *psVar46) {
        *psVar46 = 99;
      }
      puVar14 = _DAT_100a02c0;
      *(undefined1 *)((int)piVar20 + iVar37 + 0x2c) = 0;
      *(undefined1 *)(param_2 + 0xe9) = 1;
      .debug::_STPlayRegSound(*puVar14,1,0x100);
      psVar46 = _DAT_1009fda4;
      *(undefined2 *)PTR_DAT_1009fda8 = 0x20;
      puVar11 = _DAT_1009fda0;
      *psVar46 = sVar40;
      *puVar11 = 0;
      .debug::_UpdateStatusBar(1,1,0);
      return;
    }
    if (iVar37 < 0x532) {
      return;
    }
    if (0x53b < iVar37) {
      return;
    }
    uVar50 = 0;
    switch(iVar37) {
    case 0x532:
      *(undefined2 *)PTR_DAT_100a064c = 600;
      uVar50 = 600;
      *puVar33 = 1;
      .debug::_STPlayRegSound(*puVar24,1,0x100);
      break;
    case 0x533:
    case 0x534:
    case 0x535:
      *(undefined2 *)PTR_DAT_100a0640 = 600;
      uVar50 = 600;
      *PTR_DAT_100a0648 = 1;
      *puVar31 = 1;
      *(short *)PTR_DAT_100a063c = *(short *)(param_2 + 4) + -0x533;
      .debug::_STPlayRegSound(*_DAT_100a0390,1,0x100);
      break;
    case 0x536:
      *(undefined2 *)PTR_DAT_100a0630 = 600;
      puVar39 = PTR_DAT_100a0638;
      uVar50 = 600;
      *puVar30 = 1;
      puVar14 = _DAT_1009fde4;
      *puVar39 = 1;
      .debug::_STPlayRegSound(*puVar14,1,0x100);
      break;
    case 0x537:
      *(undefined2 *)(param_1 + 0x116) = 0x1c2;
      *(undefined2 *)puVar32 = 0x1c2;
      if (*(short *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 10) == 0) {
        uVar50 = 32000;
      }
      else {
        uVar50 = 0x1c2;
      }
      .debug::_STPlayRegSound(*_DAT_100a0388,1,0x100);
      break;
    case 0x538:
      *(undefined2 *)PTR_DAT_100a0624 = 900;
      puVar39 = PTR_DAT_100a062c;
      uVar50 = 900;
      *puVar29 = 1;
      *puVar39 = 1;
      .debug::_STPlayRegSound(*_DAT_100a038c,1,0x100);
      break;
    case 0x539:
      *(undefined2 *)PTR_DAT_100a0618 = 600;
      puVar39 = PTR_DAT_100a0620;
      uVar50 = 600;
      *puVar28 = 1;
      *puVar39 = 1;
      .debug::_STPlayRegSound(*puVar24,1,0x100);
      break;
    case 0x53a:
      *(short *)PTR_DAT_100a053c = *(short *)PTR_DAT_100a053c + 5;
      if (8 < *(short *)puVar26) {
        *(undefined2 *)puVar26 = 8;
      }
      piVar47 = (int *)puVar25;
      for (sVar40 = 0; iVar37 = (int)*(short *)puVar26, sVar40 < iVar37; sVar40 = sVar40 + 1) {
        piVar47[2] = (int)sVar40 * (0x168 / iVar37) * 0x100;
        piVar47[3] = 0x30;
        piVar47[4] = 0xa00;
        *(undefined1 *)(piVar47 + 1) = 1;
        if (*piVar47 != 0) {
          *(undefined1 *)(*piVar47 + 0xe9) = 1;
          *piVar47 = 0;
        }
        piVar47 = piVar47 + 5;
      }
      piVar47 = (int *)(puVar25 + iVar37 * 0x14);
      for (; (short)iVar37 < 8; iVar37 = iVar37 + 1) {
        *(undefined1 *)(piVar47 + 1) = 0;
        if (*piVar47 != 0) {
          *(undefined1 *)(*piVar47 + 0xe9) = 1;
          *piVar47 = 0;
        }
        piVar47 = piVar47 + 5;
      }
      uVar50 = 32000;
      *PTR_DAT_100a0614 = 1;
      .debug::_STPlayRegSound(*_DAT_100a0390,1,0x100);
      break;
    case 0x53b:
      *(undefined1 *)(param_2 + 0xe9) = 1;
      .debug::_STPlayRegSound(*puVar23,1,0xab);
      *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -0x380;
      *(undefined2 *)(param_1 + 0x116) = 0x1e;
      *(undefined2 *)(param_1 + 0xaa) = 0x1e;
    }
    *(undefined2 *)(param_2 + 0xa6) = uVar50;
    return;
  }
  if (puVar35 == _DAT_100a0200) {
    sStack_b4 = *(short *)(param_1 + 0x36) +
                (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
    sStack_b6 = *(short *)(param_1 + 0x34) +
                (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
    *_DAT_100a0720 = 0;
    *puVar34 = 0;
    if (((*(short *)(param_2 + 4) == 0x582) || (*(short *)(param_2 + 4) == 0x583)) &&
       (*(short *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 8) == 2)) {
      return;
    }
    .debug::_PlatformBounce(param_1,param_2,&sStack_b6,0,param_1 + 0x34,0);
    if ((((*(short *)(param_2 + 4) == 0x57d) &&
         ((*(short *)(param_2 + 0xe) <= *(short *)(param_1 + 0xe) ||
          (*(int *)(param_1 + 0x2c) < -0x200)))) && (*(short *)(param_1 + 0x116) < 1)) &&
       (*(int *)(param_1 + 0xdc) != param_2)) {
      .debug::_STPlayRegSound(*_DAT_100a02dc,1,0xab);
      *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -0x70;
      *(undefined2 *)(param_1 + 0x116) = 0x3c;
      *(undefined2 *)(param_1 + 0xaa) = 0xc;
      return;
    }
    .debug::_CheckGroundCeilingHitEffects(param_1);
    return;
  }
  if ((puVar35 == PTR_PTR_100a0484) || (puVar35 == _DAT_100a01c8)) {
    uVar38 = *(uint *)(param_1 + 0x2c);
    uStack_60 = (double)CONCAT44(0x43300000,uVar38 ^ 0x80000000);
    iVar37 = *(int *)(param_1 + 0x24);
    iStack_ac = (int)(dRam100a1a20 * (uStack_60 - _DAT_100a1a38));
    uStack_68 = (double)(longlong)iStack_ac;
    if (puVar35 == _DAT_100a01c8) {
      sVar40 = *(short *)(param_1 + 0xc) +
               (short)((int)*(short *)(param_1 + 0x36) + (int)*(short *)(param_1 + 0x3a) >> 1);
      if (sVar40 < (short)(*(short *)(param_2 + 0xc) + *(short *)(param_2 + 0x36))) {
        return;
      }
      if ((short)(*(short *)(param_2 + 0xc) + *(short *)(param_2 + 0x3a)) < sVar40) {
        return;
      }
      *(undefined2 *)(param_2 + 0xb2) = 1;
      *_DAT_100a067c = 1;
    }
    sStack_b4 = *(short *)(param_1 + 0x10) - *(short *)(param_1 + 0xc);
    sStack_b6 = *(short *)(param_1 + 0xe) - *(short *)(param_1 + 10);
    iVar44 = (int)*(short *)(param_2 + 4);
    if ((iVar44 == 0x434) && (*(int *)(param_2 + 0x160) < 0)) {
      return;
    }
    if ((iVar44 == 0x433) && (-1 < *(int *)(param_2 + 0x160))) {
      if ((*(short *)(param_2 + 0xe) < *(short *)(param_1 + 0xe)) &&
         (599 < *(int *)(param_2 + 0x2c))) {
        .debug::_HurtPlayer(param_1,param_2,0x38,1,0x1e,0);
        .debug::_KillBox(param_2);
        return;
      }
    }
    else if ((iVar44 == 0x434) && (-1 < *(int *)(param_2 + 0x160))) {
      if ((*(short *)(param_2 + 0xe) < *(short *)(param_1 + 0xe)) &&
         (599 < *(int *)(param_2 + 0x2c))) {
        .debug::_HurtPlayer(param_1,param_2,0x70,1,0x3c,0);
        .debug::_KillBox(param_2);
        return;
      }
    }
    else if ((iVar44 - 0x5c3U & 0xffff) < 2) {
      sVar40 = .debug::_FastRand(100);
      if (sVar40 < 0x33) {
        uVar50 = 0;
      }
      else {
        uVar50 = 5;
      }
      .debug::_HurtPlayer(param_1,param_2,0xa8,1,0x3c,uVar50);
      return;
    }
    if ((0xb86 < iVar44) && (iVar44 < 0xb9a)) {
      if (*(short *)(param_2 + 0xb0) != 0) {
        return;
      }
      if (*(short *)PTR_DAT_100a06cc != 0) {
        return;
      }
      *(undefined2 *)PTR_DAT_100a06cc = 0x96;
      .debug::_Conversation
                ((int)*(short *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 8),
                 (int)*(short *)(param_2 + 0x48),param_2);
      return;
    }
    if ((iVar44 - 0xb5eU & 0xffff) < 2) {
      cStack_ae = '\x01';
      bVar5 = false;
      sVar40 = *(short *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 8);
      if (sVar40 != 0) {
        bVar5 = true;
        if (sVar40 < 1) {
          sVar40 = -sVar40;
        }
        sStack_b0 = sVar40;
        cVar43 = .debug::_HaveItem((int)sVar40);
        if (cVar43 == '\0') {
          cStack_ae = '\0';
        }
      }
      if (cStack_ae != '\0') {
        if (bVar5) {
          .debug::_RemoveItem((int)sStack_b0);
          puVar12 = _DAT_100a03a8;
          *(undefined2 *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 8) = 0;
          .debug::_STPlayRegSound(*puVar12,1,0x100);
        }
        else {
          .debug::_STPlayRegSound(*_DAT_100a03a4,1,0x100);
        }
        if (*(short *)(param_2 + 4) == 0xb5e) {
          if ((0 < iVar37) && (*(short *)(param_2 + 0x46) == 0)) {
            *(undefined2 *)(param_2 + 0x46) = 1;
          }
        }
        else if ((iVar37 < 0) && (*(short *)(param_2 + 0x46) == 0)) {
          *(undefined2 *)(param_2 + 0x46) = 1;
        }
      }
    }
    if ((*(short *)(param_2 + 4) == 0x51c) && (*(short *)(param_2 + 0x46) == 0)) {
      bVar5 = true;
      bVar6 = false;
      sVar40 = *(short *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 8);
      if (sVar40 != 0) {
        bVar6 = true;
        if (sVar40 < 1) {
          sVar40 = -sVar40;
        }
        sStack_b2 = sVar40;
        cVar43 = .debug::_HaveItem((int)sVar40);
        if (cVar43 == '\0') {
          bVar5 = false;
        }
      }
      if ((bVar5) && (0 < *(short *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 0xc))) {
        if (bVar6) {
          .debug::_RemoveItem((int)sStack_b2);
        }
        .debug::_STPlayRegSound(*_DAT_100a03a0,1,0x100);
        *(undefined2 *)(param_2 + 0x46) = 1;
      }
    }
    puVar12 = _DAT_1009fdb4;
    if ((*(short *)(param_2 + 4) == 0xb5b) && (*(short *)(param_2 + 0xa6) == 0)) {
      *(undefined2 *)(param_2 + 0xa6) = 100;
      .debug::_STPlay3DSoundPitched(*puVar12,1,0x100,*(undefined4 *)(param_1 + 0xe),44000);
      iRam100a5110 = *(short *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 8) * 0x1e +
                     -1;
    }
    iVar37 = (int)*(short *)(param_2 + 4);
    if ((((((0xb55 < iVar37) && (iVar37 < 0xb5e)) && (iVar37 != 0xb5b)) ||
         ((iVar37 - 0xb11U & 0xffff) < 4)) &&
        ((cVar43 = .debug::_IsInputKeyPressed(2), cVar43 != '\0' ||
         (*(short *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 0xe) == 0)))) &&
       ((piVar45 = (int *)*puVar14,
        *(short *)(*piVar45 + *(short *)(param_2 + 0x48) * 0x10 + 8) != 0 &&
        (*(short *)PTR_DAT_100a06cc == 0)))) {
      *(undefined2 *)PTR_DAT_100a06cc = 0x5a;
      *(undefined2 *)(*piVar45 + *(short *)(param_2 + 0x48) * 0x10 + 0xe) = 1;
      if ((*(short *)(param_2 + 4) == 0xb56) &&
         (0 < *(short *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 8))) {
        .debug::_SetResWorldFile();
        .glue::GetIndString(auStack_1c0,500,
                            (int)*(short *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 8
                                           ));
        .debug::_RestoreResWorldFile();
        .debug::_SimpleConv(0xfb4,&DAT_100a6254,auStack_1c0);
      }
      else {
        iVar37 = (int)*(short *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 8);
        if (100 < iVar37) {
          .debug::_Conversation(iVar37,(int)*(short *)(param_2 + 0x48),param_2);
        }
      }
    }
    if (((0xb55 < *(short *)(param_2 + 4)) && (*(short *)(param_2 + 4) < 0xb5e)) &&
       (*(int *)(param_2 + 0x15c) == 0)) {
      return;
    }
    sVar40 = .debug::_PlatformBounce(param_1,param_2,&sStack_b6,0,param_1 + 0x34,0);
    if (sVar40 != 1) {
      return;
    }
    uVar48 = 0x70;
    if ((*(short *)(param_2 + 4) == 0x5a9) && (iVar37 = *(int *)(param_2 + 0x14c), 0 < iVar37)) {
      if ((iVar37 == 1) && ((*PTR_DAT_100a0648 != '\0' && (*(short *)PTR_DAT_100a063c == 1)))) {
        return;
      }
      if (iVar37 == 2) {
        uVar48 = 0x150;
        if ((*PTR_DAT_100a0648 != '\0') && (*(short *)PTR_DAT_100a063c == 2)) {
          return;
        }
        piVar45 = piVar20;
        for (sVar40 = 0; sVar40 < 0x1b; sVar40 = sVar40 + 1) {
          if ((*(short *)(piVar45 + 9) == 0x18) && (*(char *)(piVar45 + 0xb) == '\0')) {
            return;
          }
          piVar45 = (int *)((int)piVar45 + 10);
        }
      }
      if (*(short *)(param_2 + 0x10) < *(short *)(param_1 + 0x10)) {
        sVar40 = 400;
      }
      else {
        sVar40 = -400;
      }
      cVar43 = .debug::_HurtSprite(param_1,uVar48,(int)sVar40,0xfffff9c0,0x3c,0xc);
      if (cVar43 != '\0') {
        *_DAT_100a0748 = 1;
      }
    }
    puVar11 = _DAT_100a068c;
    puVar12 = _DAT_100a01e4;
    iVar37 = (int)*(short *)(param_2 + 4);
    if (iVar37 == 0x5be) {
      *(undefined2 *)(param_2 + 0x46) = 1;
      puVar14 = _DAT_100a027c;
      if ((int)uVar38 < 0xa5b) {
        return;
      }
      uStack_68 = (double)CONCAT44(0x43300000,(int)*(short *)(param_1 + 0x110) ^ 0x80000000);
      uStack_60 = (double)CONCAT44(0x43300000,-uVar38 ^ 0x80000000);
      dVar52 = -(dRam100a1a10 * (uStack_68 - _DAT_100a1a38) - (uStack_60 - _DAT_100a1a38));
      dVar53 = dRam100a1a08;
      if (dRam100a1a08 < dVar52) {
        dVar53 = dVar52;
      }
      uStack_68 = (double)(longlong)(int)dVar53;
      *(int *)(param_1 + 0x2c) = (int)dVar53;
      .debug::_STPlayRegSound(*puVar14,1,0x100);
      *_DAT_100a0718 = 1;
      *(undefined1 *)(param_1 + 0xce) = 0;
      return;
    }
    if ((((*PTR_DAT_100a0668 != '\0') && (0 < *(short *)(param_2 + 0xa4))) &&
        (((0x4e1 < iVar37 && (iVar37 < 0x500)) || ((0xc11 < iVar37 && (iVar37 < 0xc1c)))))) &&
       ((*(short *)PTR_DAT_100a060c == 0 &&
        ((0x9c4 < (int)uVar38 &&
         (*(short *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 0xe) != 1)))))) {
      if ((iVar37 < 0x4e2) || (0x4ff < iVar37)) {
        if ((0xc11 < iVar37) && (iVar37 < 0xc1c)) {
          *(short *)(param_2 + 0xa4) = *(short *)(param_2 + 0xa4) + -100;
        }
      }
      else {
        *(short *)(param_2 + 0xa4) = *(short *)(param_2 + 0xa4) + -1;
        .debug::_STPlay3DSoundRand(*puVar12,1,0x100,*(undefined4 *)(param_2 + 0xe));
      }
      cVar43 = .debug::_IsInputKeyPressed(3);
      if (cVar43 == '\0') {
        *PTR_DAT_100a0668 = 0;
        sVar40 = FUN_100916dc(*_DAT_100a03cc);
        if (sVar40 != 0) {
          FUN_10091504(*_DAT_100a03cc);
        }
        puVar11 = _DAT_100a0718;
        *(int *)(param_1 + 0x2c) = iStack_ac;
        *puVar11 = 1;
        if (0 < *(int *)(param_1 + 0x2c)) {
          *(int *)(param_1 + 0x2c) = -*(int *)(param_1 + 0x2c);
        }
      }
      else {
        .debug::_STPlayRegSound(*_DAT_100a03cc,1,0xba);
        *PTR_DAT_100a0668 = 1;
        *(int *)(param_1 + 0x2c) = iStack_ac;
        if (0 < *(int *)(param_1 + 0x2c)) {
          *(int *)(param_1 + 0x2c) = -*(int *)(param_1 + 0x2c);
        }
      }
      puVar19 = _DAT_100a0738;
      *(undefined2 *)PTR_DAT_100a060c = 5;
      *(undefined1 *)(param_1 + 0xce) = 0;
      *puVar19 = 0;
      *(undefined4 *)(param_1 + 0xdc) = 0;
      return;
    }
    if ((iVar37 - 0x424U & 0xffff) < 3) {
      *PTR_DAT_100a070c = 1;
      puVar39 = PTR_DAT_100a0708;
      *puVar11 = 0;
      if (*puVar39 == '\0') {
        return;
      }
      .debug::_STPlayRegSound(*_DAT_100a03dc,1,0x100);
      .debug::_MosaicTransition(1,3,0x14);
      iStack_9c = (int)(short)(*(short *)(param_1 + 0xc) - *(short *)(param_2 + 0xc));
      iStack_a0 = (int)(short)(*(short *)(param_1 + 10) - *(short *)(param_2 + 10));
      for (sVar40 = 0; sVar40 < 0x1ff; sVar40 = sVar40 + 1) {
        if ((*pcVar51 != '\0') &&
           (*(short *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 8) ==
            *(short *)(pcVar51 + 0xe))) {
          uVar3 = *puVar19;
          sVar36 = (short)iStack_9c + *(short *)(pcVar51 + 10);
          *(short *)(param_1 + 0xc) = sVar36;
          *psVar16 = sVar36;
          sVar36 = (short)iStack_a0 + *(short *)(pcVar51 + 0xc);
          *(short *)(param_1 + 10) = sVar36;
          *psVar15 = sVar36;
          sVar36 = *(short *)(param_1 + 0xc) +
                   *(short *)(param_1 + 0x36) +
                   (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
          *(short *)(param_1 + 0x10) = sVar36;
          *psVar10 = sVar36;
          sVar36 = *(short *)(param_1 + 10) +
                   *(short *)(param_1 + 0x34) +
                   (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
          *(short *)(param_1 + 0xe) = sVar36;
          *psVar9 = sVar36;
          *psVar7 = *psVar10;
          *psVar46 = *psVar9;
          *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
          *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
          *(undefined4 *)(param_1 + 0xdc) = 0;
          sVar36 = *(short *)(param_1 + 0xc) + -0x142;
          psVar8[1] = sVar36;
          *(short *)(puVar18 + 2) = sVar36;
          sVar36 = *(short *)(param_1 + 10) + -0xc0;
          *psVar8 = sVar36;
          *(short *)puVar18 = sVar36;
          *puVar19 = 0;
          for (sVar36 = 0; sVar36 < 0x78; sVar36 = sVar36 + 1) {
            .debug::_FindUpperLeftCorner();
          }
          *puVar19 = uVar3;
          *piVar17 = (int)*(short *)(puVar18 + 2);
          *piVar47 = (int)*(short *)puVar18;
          .debug::_RedrawEntireScrollGrid();
        }
        pcVar51 = pcVar51 + 0x220;
      }
      .debug::_HandleIdleSprites();
      .debug::_WrapDrawSprites();
      .debug::_STPlayRegSound(*_DAT_100a03e0,1,0x100);
      .debug::_MosaicTransition(0,3,0x14);
      .debug::_RedrawEntireScrollGrid();
      puVar39 = PTR_DAT_100a0700;
      *PTR_DAT_100a0708 = 0;
      *(undefined2 *)puVar39 = 0xffc5;
      return;
    }
    if (iVar37 != 0x429) {
      return;
    }
    if (DAT_100a53d6 == '\0') {
      return;
    }
    if (*(short *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 8) != 0) {
      return;
    }
    *_DAT_100a0684 = *_DAT_100a0684 + 2;
    if (*_DAT_100a0684 < 0x10) {
      return;
    }
    *_DAT_100a0684 = -0x96;
    .debug::_MTSetPortScreen();
    *(ushort *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 8) =
         *(byte *)(param_1 + 0x17e) + 1;
    .debug::_ShowCursorSafe();
    *(ushort *)((int)piVar20 + 0x16) = (ushort)*(byte *)(param_1 + 0x17e);
    cVar43 = .debug::_SavePointSave();
    if (cVar43 == '\0') {
      *(undefined2 *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 8) = 0;
    }
    else {
      .debug::_STPlayRegSound(*_DAT_100a03e0,1,0x100);
      .debug::_STPlayRegSound(*_DAT_100a03dc,1,0x100);
      .debug::_GammaFadeOutAsync(2,uRam100a53ca,uRam100a53ce,0xc,0x10);
      .debug::_HandleAsyncGammaFade();
      .debug::_HandleAsyncGammaFade();
      .debug::_HandleAsyncGammaFade();
      .debug::_GammaFadeInAsync(0x2d);
    }
    .debug::_HideCursorSafe();
    return;
  }
  if (puVar35 == PTR_PTR_100a01f8) {
    sStack_b4 = *(short *)(param_1 + 0x36) +
                (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
    sStack_b6 = *(short *)(param_1 + 0x34) +
                (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
    .debug::_PlatformBounce(param_1,param_2,&sStack_b6,0,param_1 + 0x34,0);
    return;
  }
  if ((((((puVar35 != PTR_PTR_100a04b8) && (puVar35 != PTR_PTR_100a04a0)) &&
        (puVar35 != PTR_PTR_100a0488)) &&
       (((puVar35 != PTR_PTR_100a0498 && (puVar35 != PTR_PTR_100a0494)) &&
        ((puVar35 != PTR_PTR_100a04a4 &&
         ((puVar35 != PTR_PTR_100a04b0 && (puVar35 != PTR_PTR_100a04bc)))))))) &&
      (puVar35 != PTR_PTR_100a0490)) &&
     ((((puVar35 != PTR_PTR_100a04a8 && (puVar35 != PTR_PTR_100a04c4)) &&
       (puVar35 != PTR_PTR_100a04c0)) && (puVar35 != PTR_PTR_100a0470)))) {
    if (puVar35 == PTR_PTR_100a049c) {
      sVar40 = .debug::_FastRand(100);
      if (sVar40 < 0x51) {
        uVar50 = 0;
      }
      else {
        uVar50 = 3;
      }
      .debug::_HurtPlayer(param_1,param_2,0x70,0,0x3c,uVar50);
      return;
    }
    if ((puVar35 == PTR_PTR_100a04ac) && (0xc < *(short *)(param_2 + 0x46))) {
      sVar40 = .debug::_FastRand(100);
      if (sVar40 < 0x51) {
        uVar50 = 0;
      }
      else {
        uVar50 = 3;
      }
      .debug::_HurtPlayer(param_1,param_2,0x70,0,0x3c,uVar50);
      return;
    }
    if (puVar35 == PTR_PTR_100a046c) {
      sVar40 = .debug::_FastRand(100);
      if (sVar40 < 0x3d) {
        uVar50 = 0;
      }
      else {
        uVar50 = 3;
      }
      .debug::_HurtPlayer(param_1,param_2,0x70,0,0x3c,uVar50);
      return;
    }
    if (puVar35 == PTR_PTR_100a04b4) {
      if (*(short *)(param_2 + 4) == 0x74e) {
        sVar40 = .debug::_FastRand(100);
        if (sVar40 < 0x3d) {
          uVar50 = 0;
        }
        else {
          uVar50 = 4;
        }
        .debug::_HurtPlayer(param_1,param_2,0xe0,0,0x3c,uVar50);
        return;
      }
      if (*(short *)(param_2 + 4) != 0x74f) {
        return;
      }
      .debug::_HurtPlayer(param_1,param_2,0x1c0,0,0x3c,6);
      return;
    }
    if (puVar35 == PTR_PTR_100a0480) {
      sStack_1d2 = *(short *)(param_1 + 0x10) - *(short *)(param_2 + 0xc);
      sStack_1d4 = *(short *)(param_1 + 0xe) - *(short *)(param_2 + 10);
      if (((*(short *)(param_2 + 4) == 0x4b8) ||
          (((int)*(short *)(param_2 + 4) - 0x4bbU & 0xffff) < 3)) &&
         ((cVar43 = .debug::_HasItem(0x18), cVar43 == '\0' || (0 < *(int *)(param_2 + 0x14c))))) {
        .debug::_HurtPlayer(param_1,param_2,0xe0,1,0x3c,0);
      }
      puVar39 = PTR_DAT_100a05f0;
      iVar37 = (int)*(short *)(param_2 + 4);
      if ((0x5c7 < iVar37) && (iVar37 < 0x5d2)) {
        if ((*(short *)(param_1 + 0x116) == 0) && (*(int *)(param_2 + 0x170) == 1)) {
          .debug::_HurtPlayer(param_1,param_2,0xe0,1,0x3c,5);
          *(undefined2 *)(param_1 + 0x116) = 0x1e;
        }
        if (*(char *)(param_2 + 0x185) != '\0') {
          return;
        }
        .debug::_PlatformBounce(param_1,param_2,&sStack_1d4,0,param_1 + 0x34,0);
        return;
      }
      if ((iVar37 - 0xb54U & 0xffff) < 2) {
        if ((*_DAT_100a06f0 == 0) && (cVar43 = .debug::_IsInputKeyPressed(2), cVar43 == '\0')) {
          return;
        }
        if (*_DAT_100a06f0 == 0) {
          *_DAT_100a05f8 = 1;
          .debug::_GammaFadeOutAsync(0x14,_DAT_100a5f60,uRam100a5f64,0xc,0x10);
        }
        *_DAT_100a06f0 = *_DAT_100a06f0 + 1;
        sVar40 = *_DAT_100a06f0;
        if (sVar40 == 0x15) {
          *_DAT_100a0680 = 0;
        }
        if (sVar40 != 0x16) {
          return;
        }
        piVar45 = (int *)*puVar14;
        sVar40 = *(short *)(param_2 + 0xc);
        sVar36 = *(short *)(param_1 + 0xc);
        sVar42 = *(short *)(*piVar45 + *(short *)(param_2 + 0x48) * 0x10 + 10);
        sVar41 = *(short *)(param_2 + 10);
        sVar4 = *(short *)(param_1 + 10);
        *_DAT_100a0680 = 0;
        if (sVar42 != 0) {
          if (sVar42 == -1) {
            *(undefined1 *)(piVar20 + 8) = 0;
            *(undefined2 *)(*piVar45 + 0x2706) = *(undefined2 *)((int)piVar20 + 0x22);
          }
          else {
            if (sVar42 == 10) {
              sVar42 = 0;
            }
            *(undefined1 *)(piVar20 + 8) = 1;
            *(short *)(*piVar45 + 0x2706) = sVar42;
          }
        }
        iStack_a4 = (int)(short)(sVar36 - sVar40);
        iStack_a8 = (int)(short)(sVar4 - sVar41);
        for (sVar40 = 0; sVar40 < 0x1ff; sVar40 = sVar40 + 1) {
          if ((*pcVar51 != '\0') &&
             (*(short *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 8) ==
              *(short *)(pcVar51 + 0xe))) {
            uVar3 = *puVar19;
            sVar36 = (short)iStack_a4 + *(short *)(pcVar51 + 10);
            *(short *)(param_1 + 0xc) = sVar36;
            *psVar16 = sVar36;
            sVar36 = (short)iStack_a8 + *(short *)(pcVar51 + 0xc);
            *(short *)(param_1 + 10) = sVar36;
            *psVar15 = sVar36;
            sVar36 = *(short *)(param_1 + 0xc) +
                     *(short *)(param_1 + 0x36) +
                     (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1)
            ;
            *(short *)(param_1 + 0x10) = sVar36;
            *psVar10 = sVar36;
            sVar36 = *(short *)(param_1 + 10) +
                     *(short *)(param_1 + 0x34) +
                     (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1)
            ;
            *(short *)(param_1 + 0xe) = sVar36;
            *psVar9 = sVar36;
            *psVar7 = *psVar10;
            *psVar46 = *psVar9;
            *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
            *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
            sVar36 = *(short *)(param_1 + 0xc) + -0x142;
            psVar8[1] = sVar36;
            *(short *)(puVar18 + 2) = sVar36;
            sVar36 = *(short *)(param_1 + 10) + -0xc0;
            *psVar8 = sVar36;
            *(short *)puVar18 = sVar36;
            *puVar19 = 0;
            for (sVar36 = 0; sVar36 < 0x5a; sVar36 = sVar36 + 1) {
              .debug::_FindUpperLeftCorner();
            }
            *puVar19 = uVar3;
            *piVar17 = (int)*(short *)(puVar18 + 2);
            *piVar47 = (int)*(short *)puVar18;
            .debug::_RedrawEntireScrollGrid();
          }
          pcVar51 = pcVar51 + 0x220;
        }
        .debug::_HandleIdleSprites();
        .debug::_WrapDrawSprites();
        .debug::_RedrawEntireScrollGrid();
        .debug::_GammaFadeInAsync(0x14);
        *_DAT_100a05f8 = 0xfff1;
        *_DAT_100a06f0 = -0x16;
        return;
      }
      if (iVar37 == 0xbf4) {
        uStack_1e2 = *(undefined4 *)(param_1 + 0x34);
        uStack_1de = *(undefined4 *)(param_1 + 0x38);
        .glue::OffsetRect(&uStack_1e2,(int)*(short *)(param_1 + 0xc),(int)*(short *)(param_1 + 10));
        uStack_1e2 = CONCAT22(uStack_1e2._0_2_ + 6,uStack_1e2._2_2_);
        uStack_1de = CONCAT22(uStack_1de._0_2_ + -8,uStack_1de._2_2_);
        uStack_7c = (int)*(short *)(param_2 + 0x10) ^ 0x80000000;
        uStack_8c = (int)*(short *)(param_2 + 0xe) ^ 0x80000000;
        iVar37 = *(short *)(param_2 + 0x46) * 8;
        dVar53 = *(double *)(_DAT_100a0168 + iVar37);
        dVar52 = *(double *)(_DAT_100a0164 + iVar37);
        uStack_68 = (double)CONCAT44(0x43300000,uStack_7c);
        uStack_70 = 0x43300000;
        uStack_80 = 0x43300000;
        uStack_90 = 0x43300000;
        iVar37 = (int)(dRam100a19f8 * dVar53 + (uStack_68 - _DAT_100a1a38));
        uStack_60 = (double)(longlong)iVar37;
        iVar44 = (int)(dRam100a19f0 * dVar53 +
                      ((double)CONCAT44(0x43300000,uStack_7c) - _DAT_100a1a38));
        lStack_88 = (longlong)iVar44;
        iVar1 = (int)-(dRam100a19f0 * dVar52 -
                      ((double)CONCAT44(0x43300000,uStack_8c) - _DAT_100a1a38));
        lStack_98 = (longlong)iVar1;
        iVar2 = (int)-(dRam100a19f8 * dVar52 -
                      ((double)CONCAT44(0x43300000,uStack_8c) - _DAT_100a1a38));
        lStack_78 = (longlong)iVar2;
        uStack_6c = uStack_8c;
        cVar43 = .debug::_SectRectLineSeg(&uStack_1e2,iVar37,iVar2,iVar44,iVar1);
        if (cVar43 == '\0') {
          return;
        }
        uVar48 = *(undefined4 *)(param_2 + 0x24);
        if (*(short *)(param_2 + 0x10) < *(short *)(param_1 + 0x10)) {
          *(undefined4 *)(param_2 + 0x24) = 0x8fc;
        }
        else {
          *(undefined4 *)(param_2 + 0x24) = 0xfffff704;
        }
        sVar40 = .debug::_FastRand(100);
        if (sVar40 < 0x33) {
          uVar50 = 0;
        }
        else {
          uVar50 = 4;
        }
        .debug::_HurtPlayer(param_1,param_2,0x70,0,0x3c,uVar50);
        *(undefined4 *)(param_2 + 0x24) = uVar48;
        return;
      }
      if (iVar37 == 0xcb1) {
        .debug::_STPlayRegSound(*_DAT_100a03dc,1,0x100);
        uRam100a5116 = *(undefined2 *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 8);
        sVar40 = *(short *)(*(int *)*puVar14 + *(short *)(param_2 + 0x48) * 0x10 + 10);
        if (sVar40 != 0) {
          _DAT_100a5118 = sVar40;
        }
        *_DAT_100a0088 = 1;
        return;
      }
      if ((iVar37 - 0x730U & 0xffff) < 4) {
        *_DAT_100a0758 = 0;
        *(undefined2 *)puVar39 = 3;
        if (*(short *)(param_1 + 0x116) != 0) {
          return;
        }
        .debug::_HurtPlayer(param_1,param_2,0x70,1,0x3c,0);
        *(undefined2 *)(param_1 + 0x116) = 0x1e;
        return;
      }
      if (1 < (iVar37 - 0x73fU & 0xffff)) {
        return;
      }
      if (*(short *)(param_1 + 0x116) != 0) {
        return;
      }
      .debug::_HurtPlayer(param_1,param_2,0x38,1,0x3c,0);
      *(undefined2 *)(param_1 + 0x116) = 0x28;
      return;
    }
    if (((puVar35 != PTR_PTR_100a0460) || (*(short *)(param_2 + 4) != 0x4b7)) ||
       (7 < *(short *)(param_2 + 0x46))) {
      if (*(short *)(param_2 + 4) != 0x5a0) {
        return;
      }
      if (*(int *)(param_2 + 0x14c) < 1) {
        return;
      }
    }
    uVar48 = 0x70;
    if (*(short *)(param_2 + 4) == 0x5a0) {
      if (((*(int *)(param_2 + 0x14c) == 1) && (*PTR_DAT_100a0648 != '\0')) &&
         (*(short *)PTR_DAT_100a063c == 1)) {
        return;
      }
      if (*(int *)(param_2 + 0x14c) == 2) {
        uVar48 = 0x150;
        if ((*PTR_DAT_100a0648 != '\0') && (*(short *)PTR_DAT_100a063c == 2)) {
          return;
        }
        cVar43 = .debug::_HasItem(0x18);
        if (cVar43 != '\0') {
          return;
        }
      }
    }
    if (*(short *)(param_2 + 0x10) < *(short *)(param_1 + 0x10)) {
      sVar40 = 300;
    }
    else {
      sVar40 = -300;
    }
    cVar43 = .debug::_HurtSprite(param_1,uVar48,(int)sVar40,0xfffff9c0,0x3c,0xc);
    if (cVar43 == '\0') {
      return;
    }
    *_DAT_100a0748 = 1;
    return;
  }
  sVar40 = *(short *)(param_2 + 4);
  iVar37 = 0x70;
  uVar49 = 0x3c;
  uVar48 = 0;
  if ((((0x76b < sVar40) && (sVar40 < 0x776)) || (sVar40 == 0x754)) &&
     (0 < *(short *)(param_2 + 0x110))) {
    return;
  }
  if (((puVar35 == PTR_PTR_100a0488) && (sVar40 == 0x77b)) && (*(int *)(param_2 + 0x14c) != 0)) {
    return;
  }
  cVar43 = .debug::_ShieldBlock(param_1,param_2);
  if (cVar43 != '\0') {
    return;
  }
  sVar40 = *(short *)(param_2 + 4);
  if ((sVar40 == 0x6e6) && (1 < *(int *)(param_2 + 0x164))) {
    return;
  }
  if (sVar40 == 0x74d) {
    return;
  }
  if (((0x739 < sVar40) && (sVar40 < 0x73f)) && (*(int *)(param_2 + 0x160) != 0)) {
    return;
  }
  puVar39 = *(undefined **)(param_2 + 0x4c);
  if (puVar39 == PTR_PTR_100a04a4) {
    iVar37 = 0xe0;
  }
  if ((puVar39 == PTR_PTR_100a04b8) || (puVar39 == PTR_PTR_100a04a0)) {
    iVar37 = 0x38;
  }
  else if (puVar39 == PTR_PTR_100a04c4) {
    iVar37 = 0x38;
  }
  else if (puVar39 == PTR_PTR_100a04c0) {
    iVar37 = 0x38;
  }
  else if (puVar39 == PTR_PTR_100a0494) {
    iVar37 = 0x70;
  }
  else if (puVar39 == PTR_PTR_100a04a8) {
    iVar37 = 0x70;
  }
  else if (puVar39 == PTR_PTR_100a0490) {
    iVar37 = 0x70;
  }
  else if (puVar39 == PTR_PTR_100a04bc) {
    iVar37 = 0x70;
  }
  else if (puVar39 == PTR_PTR_100a0488) {
    if (sVar40 == 0x71f) {
      iVar37 = 0x70;
    }
    else {
      if (sVar40 < 0x71f) {
        if (sVar40 == 0x46c) {
          iVar37 = 0xa8;
          goto LAB_10057b64;
        }
        if (sVar40 < 0x46c) {
          if (0x469 < sVar40) {
            iVar37 = 0x70;
            goto LAB_10057b64;
          }
        }
        else if (sVar40 == 0x6f4) {
          iVar37 = 0x70;
          goto LAB_10057b64;
        }
      }
      else if (sVar40 < 0x775) {
        if (sVar40 < 0x755) {
          if (0x752 < sVar40) {
            iVar37 = (int)*(short *)(param_2 + 0xa4);
            goto LAB_10057b64;
          }
        }
        else if (0x770 < sVar40) {
          iVar37 = (int)*(short *)(param_2 + 0xa4);
          goto LAB_10057b64;
        }
      }
      else if (sVar40 == 0x77b) {
        iVar37 = 0x70;
        goto LAB_10057b64;
      }
      iVar37 = 0x38;
    }
  }
LAB_10057b64:
  if (sVar40 == 0x6a9) {
    iVar37 = 0x70;
  }
  if (sVar40 == 0x6d6) {
    iVar37 = 0x70;
    uVar49 = 0x24;
  }
  if ((short)iVar37 == 0x70) {
    sVar40 = .debug::_FastRand(100);
    if (0x50 < sVar40) {
      uVar48 = 3;
    }
  }
  else if (0x70 < (short)iVar37) {
    uVar48 = 5;
  }
  cVar43 = .debug::_HurtPlayer(param_1,param_2,iVar37,1,uVar49,uVar48);
  if ((cVar43 != '\0') && (*(undefined **)(param_2 + 0x4c) == PTR_PTR_100a0488)) {
    *_DAT_100a0570 = 0;
  }
  if (*(undefined **)(param_2 + 0x4c) == PTR_PTR_100a0488) {
    if (*(short *)(param_2 + 4) == 0x77b) {
      *(undefined4 *)(param_2 + 0x15c) = 1;
      uStack_68 = (double)CONCAT44(0x43300000,*(uint *)(param_2 + 0x24) ^ 0x80000000);
      *(int *)(param_2 + 0x24) = (int)((uStack_68 - _DAT_100a1a38) * dRam100a1a00);
      if (*(short *)(param_2 + 0x110) < 1) {
        *(undefined2 *)(param_2 + 0x110) = 0x15e;
      }
    }
    else {
      .debug::_KillEnemyShot(param_2);
    }
  }
  return;
}


// ==== .HandleCannonedSprite @ 10058710 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleCannonedSprite(int param_1)

{
  short *psVar1;
  short *psVar2;
  int *piVar3;
  undefined2 *puVar4;
  undefined2 *puVar5;
  undefined4 uVar6;
  undefined4 *puVar7;
  undefined1 *puVar8;
  short *psVar9;
  undefined *puVar10;
  double dVar11;
  short sVar12;
  char cVar18;
  uint uVar13;
  int iVar14;
  int iVar15;
  undefined1 uVar19;
  undefined2 uVar17;
  int iVar16;
  short sVar21;
  uint uVar20;
  uint uVar22;
  int iVar23;
  int iVar24;
  double dVar25;
  undefined8 uStack_80;
  undefined8 uStack_78;
  undefined8 uStack_70;
  undefined8 uStack_68;
  undefined8 uStack_60;
  undefined8 uStack_58;
  
  puVar8 = _DAT_100a05a0;
  puVar7 = _DAT_100a0058;
  uVar6 = _DAT_1009fef8;
  piVar3 = _DAT_1009fdd8;
  psVar2 = _DAT_1009fd94;
  psVar1 = _DAT_1009fd90;
  sVar21 = *(short *)(param_1 + 0x10) - *(short *)(param_1 + 0xc);
  *(undefined4 *)(param_1 + 0xc0) = 0;
  sVar12 = *(short *)(param_1 + 0xe) - *(short *)(param_1 + 10);
  *(short *)(param_1 + 0xc) = *(short *)(*(int *)(param_1 + 0x1e4) + 0x10) - sVar21;
  *(short *)(param_1 + 10) = *(short *)(*(int *)(param_1 + 0x1e4) + 0xe) - sVar12;
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
  *(short *)(param_1 + 0x10) = *(short *)(param_1 + 0xc) + sVar21;
  *(short *)(param_1 + 0xe) = *(short *)(param_1 + 10) + sVar12;
  if (param_1 == *piVar3) {
    *puVar8 = 1;
    *psVar2 = *(short *)(param_1 + 0x10);
    *psVar1 = *(short *)(param_1 + 0xe);
    .debug::_PlayerScroll(param_1);
    if (*(short *)(param_1 + 0xa4) < 1) {
      *(undefined4 *)(param_1 + 0x130) = 0xffffffff;
    }
    .debug::_DoubleSpeedTrail(param_1);
  }
  if ((param_1 == *piVar3) &&
     (*(short *)(*(int *)*puVar7 + *(short *)(*(int *)(param_1 + 0x1e4) + 0x48) * 0x10 + 8) < 0)) {
    *puVar8 = 1;
    if (*(int *)(param_1 + 0x130) < 2) {
      cVar18 = .debug::_IsInputKeyPressed(5);
      if (cVar18 != '\0') {
        *(int *)(param_1 + 0x130) = *(int *)(param_1 + 0x130) + -1;
      }
    }
    else {
      *(int *)(param_1 + 0x130) = *(int *)(param_1 + 0x130) + -1;
    }
  }
  else {
    *(int *)(param_1 + 0x130) = *(int *)(param_1 + 0x130) + -1;
  }
  *(undefined4 *)(param_1 + 0x2c) = 0;
  *(undefined4 *)(param_1 + 0x24) = 0;
  *(undefined4 *)(param_1 + 0x80) = 2;
  *(undefined4 *)(param_1 + 0x2c) = 0;
  *(undefined4 *)(param_1 + 0x24) = 0;
  if (*(int *)(param_1 + 0x130) < 1) {
    uVar13 = (uint)*(short *)(*(int *)(param_1 + 0x1e4) + 0x46);
    if (uVar13 == (((int)uVar13 >> 2) + (uint)((int)uVar13 < 0 && (uVar13 & 3) != 0)) * 4) {
      uVar13 = 0;
      uVar20 = *(uint *)(*(int *)(param_1 + 0x1e4) + 0x164);
      if (param_1 == *piVar3) {
        *(undefined4 *)(param_1 + 0x130) = 0xfffffffb;
      }
      else {
        *(undefined4 *)(param_1 + 0x130) = 0xffffffdd;
      }
      iVar14 = *(int *)(param_1 + 0x1e4);
      uVar22 = 0;
      switch((int)*(short *)(iVar14 + 0x46) >> 2) {
      case 0:
        uVar22 = -uVar20;
        break;
      case 1:
        uStack_58 = (double)CONCAT44(0x43300000,uVar20 ^ 0x80000000);
        uStack_68 = (double)CONCAT44(0x43300000,-uVar20 ^ 0x80000000);
        uVar13 = (uint)(dRam100a19e8 * (uStack_58 - _DAT_100a1a38));
        uVar22 = (uint)(dRam100a19e8 * (uStack_68 - _DAT_100a1a38));
        break;
      case 2:
        uStack_70 = (double)CONCAT44(0x43300000,-uVar20 ^ 0x80000000);
        uVar22 = (uint)(dRam100a19e0 * (uStack_70 - _DAT_100a1a38));
        uVar13 = uVar20;
        break;
      case 3:
        uStack_70 = (double)CONCAT44(0x43300000,uVar20 ^ 0x80000000);
        uStack_60 = (double)CONCAT44(0x43300000,uVar20 ^ 0x80000000);
        uVar22 = (uint)(dRam100a19d0 * (uStack_60 - _DAT_100a1a38));
        uVar13 = (int)(dRam100a19d8 * (uStack_70 - _DAT_100a1a38));
        break;
      case 4:
        uVar22 = uVar20;
        break;
      case 5:
        uStack_70 = (double)CONCAT44(0x43300000,-uVar20 ^ 0x80000000);
        uStack_60 = (double)CONCAT44(0x43300000,uVar20 ^ 0x80000000);
        uVar22 = (int)(dRam100a19d0 * (uStack_60 - _DAT_100a1a38));
        uVar13 = (int)(dRam100a19d8 * (uStack_70 - _DAT_100a1a38));
        break;
      case 6:
        uStack_70 = (double)CONCAT44(0x43300000,-uVar20 ^ 0x80000000);
        uVar22 = (int)(dRam100a19e0 * (uStack_70 - _DAT_100a1a38));
        uVar13 = -uVar20;
        break;
      case 7:
        uStack_70 = (double)CONCAT44(0x43300000,-uVar20 ^ 0x80000000);
        uVar22 = (uint)(dRam100a19e8 * (uStack_70 - _DAT_100a1a38));
        uVar13 = uVar22;
      }
      uStack_70 = (double)CONCAT44(0x43300000,uVar13 ^ 0x80000000);
      uStack_58 = (double)CONCAT44(0x43300000,uVar22 ^ 0x80000000);
      uStack_68 = (double)CONCAT44(0x43300000,(int)*(short *)(iVar14 + 0x10) ^ 0x80000000);
      uStack_78 = (double)CONCAT44(0x43300000,(int)*(short *)(iVar14 + 0xe) ^ 0x80000000);
      iVar14 = (int)((dRam100a19c8 * (uStack_70 - _DAT_100a1a38) * dRam100a19c0 +
                     (uStack_68 - _DAT_100a1a38)) - dRam100a19b8);
      iVar16 = (int)((dRam100a19c8 * (uStack_58 - _DAT_100a1a38) * dRam100a19c0 +
                     (uStack_78 - _DAT_100a1a38)) - dRam100a19b8);
      dVar25 = _DAT_100a1a38;
      iVar15 = .debug::_MTNewSprite(0x442,iVar14,iVar16,0xb,0xffffffff,uVar6);
      uVar19 = .debug::_FastRand(2);
      *(undefined1 *)(iVar15 + 0x17e) = uVar19;
      uVar17 = .debug::_FastRand(4);
      *(undefined2 *)(iVar15 + 0x46) = uVar17;
      .debug::_ChangeLightColor((int)*(short *)(iVar15 + 0x9a),0);
      iVar15 = .debug::_FastRand(8);
      iVar24 = (int)(short)iVar16;
      iVar16 = .debug::_FastRand(8);
      iVar23 = (int)(short)iVar14;
      iVar14 = .debug::_MTNewSprite
                         (0x442,iVar23 - iVar16,iVar24 - iVar15,
                          *(int *)(*(int *)(param_1 + 0x1e4) + 0x80) + 1,0xffffffff,uVar6);
      uVar19 = .debug::_FastRand(2);
      *(undefined1 *)(iVar14 + 0x17e) = uVar19;
      uVar17 = .debug::_FastRand(4);
      *(undefined2 *)(iVar14 + 0x46) = uVar17;
      .debug::_ChangeLightColor((int)*(short *)(iVar14 + 0x9a),0);
      iVar14 = .debug::_FastRand(8);
      iVar16 = .debug::_FastRand(8);
      iVar14 = .debug::_MTNewSprite
                         (0x442,iVar23 + iVar16,iVar24 + iVar14,
                          *(int *)(*(int *)(param_1 + 0x1e4) + 0x80) + 1,0xffffffff,uVar6);
      uVar19 = .debug::_FastRand(2);
      *(undefined1 *)(iVar14 + 0x17e) = uVar19;
      uVar17 = .debug::_FastRand(4);
      *(undefined2 *)(iVar14 + 0x46) = uVar17;
      .debug::_ChangeLightColor((int)*(short *)(iVar14 + 0x9a),0);
      dVar11 = dRam100a19b0;
      iVar14 = *(int *)(param_1 + 0x1e4);
      if (-1 < *(short *)(*(int *)*puVar7 + *(short *)(iVar14 + 0x48) * 0x10 + 8)) {
        uStack_80 = (double)CONCAT44(0x43300000,uVar13 ^ 0x80000000);
        uStack_78 = (double)CONCAT44(0x43300000,*(uint *)(iVar14 + 0x14) ^ 0x80000000);
        uStack_68 = (double)CONCAT44(0x43300000,uVar22 ^ 0x80000000);
        *(int *)(iVar14 + 0x14) = (int)-(dRam100a19b0 * (uStack_80 - dVar25) - (uStack_78 - dVar25))
        ;
        uStack_60 = (double)CONCAT44(0x43300000,
                                     *(uint *)(*(int *)(param_1 + 0x1e4) + 0x1c) ^ 0x80000000);
        *(int *)(*(int *)(param_1 + 0x1e4) + 0x1c) =
             (int)-(dVar11 * (uStack_68 - dVar25) - (uStack_60 - dVar25));
        *(short *)(*(int *)(param_1 + 0x1e4) + 0xc) =
             (short)((uint)*(undefined4 *)(*(int *)(param_1 + 0x1e4) + 0x14) >> 8);
        *(short *)(*(int *)(param_1 + 0x1e4) + 10) =
             (short)((uint)*(undefined4 *)(*(int *)(param_1 + 0x1e4) + 0x1c) >> 8);
      }
      if (*(short *)(param_1 + 4) == 0x5a) {
        *(undefined2 *)(param_1 + 0x110) = 0x15e;
      }
      *(uint *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + uVar13;
      *(uint *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + uVar22;
      *(short *)(param_1 + 0xc) = (short)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
      *(short *)(param_1 + 10) = (short)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
      if (0 < (int)uVar22) {
        uStack_80 = (double)CONCAT44(0x43300000,uVar13 ^ 0x80000000);
        uStack_70 = (double)CONCAT44(0x43300000,uVar22 ^ 0x80000000);
        uVar13 = (uint)((uStack_80 - _DAT_100a1a38) * dRam100a19a8);
        uVar22 = (uint)((uStack_70 - _DAT_100a1a38) * dRam100a19a0);
      }
      *(uint *)(param_1 + 0x24) = uVar13;
      puVar7 = _DAT_100a0310;
      *(uint *)(param_1 + 0x2c) = uVar22;
      .debug::_STPlay3DSoundRand(*puVar7,1,0x100,*(undefined4 *)(param_1 + 0xe));
      *(undefined4 *)(param_1 + 0x4c) = *(undefined4 *)(param_1 + 0x1ec);
      *(undefined4 *)(param_1 + 0x5c) = *(undefined4 *)(param_1 + 0x1f0);
      *(undefined4 *)(param_1 + 0x1f8) = *(undefined4 *)(param_1 + 500);
      psVar9 = _DAT_100a05b4;
      if (param_1 == *piVar3) {
        *_DAT_100a05b8 = 1;
        puVar5 = _DAT_100a0758;
        puVar4 = _DAT_100a0714;
        puVar10 = PTR_DAT_100a0668;
        *(int *)(param_1 + 0xc0) = *_DAT_100a079c + *psVar9 * 0x34;
        *puVar4 = 0;
        *puVar10 = 0;
        *puVar5 = 0;
        .debug::_PlayerScroll(param_1);
        puVar5 = _DAT_1009fe68;
        puVar4 = _DAT_1009fe64;
        uVar17 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
        *(undefined2 *)(param_1 + 8) = uVar17;
        *(undefined2 *)(param_1 + 0xc) = uVar17;
        *puVar5 = uVar17;
        uVar17 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
        *(undefined2 *)(param_1 + 6) = uVar17;
        *(undefined2 *)(param_1 + 10) = uVar17;
        *puVar4 = uVar17;
        sVar12 = *(short *)(param_1 + 0xc) +
                 *(short *)(param_1 + 0x36) +
                 (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
        *(short *)(param_1 + 0x10) = sVar12;
        *psVar2 = sVar12;
        sVar12 = *(short *)(param_1 + 10) +
                 *(short *)(param_1 + 0x34) +
                 (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
        *(short *)(param_1 + 0xe) = sVar12;
        *psVar1 = sVar12;
      }
    }
  }
  return;
}


// ==== .SetupPlayerShotSprite @ 1005925c ====

/* WARNING: Type propagation algorithm not settling */

void _SetupPlayerShotSprite(int param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined *puVar3;
  int iVar4;
  undefined2 uVar6;
  undefined4 uVar5;
  short sVar7;
  short sVar8;
  short sVar9;
  undefined4 *puVar10;
  int iVar11;
  undefined4 auStack_34 [5];
  
  puVar3 = PTR_PTR_100a04ec;
  .debug::_InitSprite();
  *(undefined1 *)(param_1 + 0xeb) = 1;
  *(undefined1 *)(param_1 + 0x88) = 0;
  *(undefined2 *)(param_1 + 0x84) = 0;
  *(undefined2 *)(param_1 + 0x86) = 0;
  uVar6 = .debug::_FastRand(5);
  *(undefined2 *)(param_1 + 0x46) = uVar6;
  puVar1 = PTR_PTR_100a04e8;
  *(undefined4 *)(param_1 + 0x80) = 0xb;
  puVar2 = PTR_PTR_100a04e4;
  *(undefined **)(param_1 + 0x4c) = puVar1;
  puVar1 = PTR_PTR_100a04e0;
  *(undefined **)(param_1 + 0x5c) = puVar2;
  *(undefined **)(param_1 + 0x1f8) = puVar1;
  *(undefined2 *)(param_1 + 0xa6) = 0;
  *(undefined2 *)(param_1 + 0x90) = 0x100;
  *(undefined4 *)(param_1 + 0x158) = 1;
  .glue::SetRect(param_1 + 0x34,8,3,0xf,0xc);
  *(uint *)(param_1 + 0x170) = (int)*(short *)(param_1 + 4) & 0xff;
  *(short *)(param_1 + 4) = (short)(char)((ushort)*(undefined2 *)(param_1 + 4) >> 8);
  *(undefined4 *)(param_1 + 0xc0) = 0;
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  *(undefined1 *)(param_1 + 0xe4) = 1;
  sVar7 = *(short *)(param_1 + 4);
  if (sVar7 == 7) {
    .glue::SetRect(param_1 + 0x34,6,6,0x16,0x16);
    *(undefined2 *)(param_1 + 0x110) = 0xfa;
  }
  else if (sVar7 < 7) {
    if (sVar7 == 3) {
      *(undefined2 *)(param_1 + 0x110) = 0xfa;
    }
    else if (sVar7 < 3) {
      if (sVar7 == 1) {
        *(undefined2 *)(param_1 + 0x110) = 0xfa;
      }
      else if (sVar7 < 1) {
        if (-1 < sVar7) {
          *(undefined2 *)(param_1 + 0x110) = 0xfa;
        }
      }
      else {
        *(undefined2 *)(param_1 + 0x110) = 0;
      }
    }
    else if (sVar7 == 5) {
      .glue::SetRect(param_1 + 0x34,10,10,0x16,0x16);
      *(undefined2 *)(param_1 + 0x110) = 0;
    }
    else if (sVar7 < 5) {
      *(undefined2 *)(param_1 + 0x110) = 0xfa;
    }
    else {
      .glue::SetRect(param_1 + 0x34,8,8,0x18,0x20);
      *(undefined2 *)(param_1 + 0x110) = 0;
    }
  }
  else if (sVar7 == 0x50) {
    .glue::SetRect(param_1 + 0x34,0,0,0x14,0x14);
    *(undefined2 *)(param_1 + 0x110) = 0;
    *(undefined2 *)(param_1 + 0xa4) = 300;
    *(undefined4 *)(param_1 + 0x168) = 3;
    sVar7 = .debug::_FastRand(0xe);
    *(int *)(param_1 + 0x16c) = (int)sVar7;
    *(undefined4 *)(param_1 + 0x1f8) = 0;
  }
  else if (sVar7 < 0x50) {
    if (sVar7 == 0x3c) {
      .glue::SetRect(param_1 + 0x34,0xfffffff6,0,0x18,6);
      *(undefined2 *)(param_1 + 0x110) = 0;
    }
  }
  else if (sVar7 == 0x5a) {
    .glue::SetRect(param_1 + 0x34,2,0xfffffffa,10,6);
    *(undefined2 *)(param_1 + 0x110) = 0xfa;
    *(undefined4 *)(param_1 + 0x158) = 2;
  }
  if (*(int *)(param_1 + 0x170) < 2) {
    if (*(int *)(param_1 + 0x170) == 0) {
      *(undefined4 *)(param_1 + 0x5c) = 0;
      *(undefined4 *)(param_1 + 0x1f8) = 0;
      *(undefined2 *)(param_1 + 0x110) = 0;
    }
  }
  else {
    sVar7 = 0;
    sVar8 = 0;
    if ((*(short *)(param_1 + 4) == 6) || (*(short *)(param_1 + 4) == 0x3c)) {
      sVar7 = 10;
    }
    else {
      sVar8 = 6;
    }
    iVar11 = (int)sVar7;
    *(int *)(param_1 + 0x160) = iVar11;
    *(int *)(param_1 + 0x164) = (int)sVar8;
    sVar7 = ((short)*(undefined4 *)(param_1 + 0x170) + -1) * (short)(iVar11 >> 1);
    *(int *)(param_1 + 0x168) = (int)sVar7;
    sVar8 = ((short)*(undefined4 *)(param_1 + 0x170) + -1) * (short)((int)sVar8 >> 1);
    *(int *)(param_1 + 0x16c) = (int)sVar8;
    iVar4 = *(int *)(param_1 + 0x170);
    if (4 < iVar4) {
      iVar4 = 5;
    }
    *(int *)(param_1 + 0x170) = iVar4;
    auStack_34[1] = 0;
    auStack_34[2] = 0;
    puVar10 = auStack_34;
    auStack_34[3] = 0;
    iVar4 = iVar11;
    for (sVar9 = 1; puVar10 = (undefined4 *)((int)puVar10 + 4),
        (int)sVar9 <= *(int *)(param_1 + 0x170) + -1; sVar9 = sVar9 + 1) {
      uVar5 = .debug::_MTNewSprite
                        ((int)(short)(*(short *)(param_1 + 4) << 8),
                         ((int)*(short *)(param_1 + 0xc) + (int)sVar7) - iVar4,
                         ((int)*(short *)(param_1 + 10) + (int)sVar8) - iVar4,0xb,0xffffffff,puVar3)
      ;
      puVar10[0xffffffff] = uVar5;
      iVar4 = iVar4 + iVar11;
    }
    *(undefined4 *)(param_1 + 0x1d4) = 0;
    *(undefined4 *)(param_1 + 0x1d8) = auStack_34[1];
    *(undefined4 *)(param_1 + 0x1dc) = auStack_34[2];
    *(undefined4 *)(param_1 + 0x1e0) = auStack_34[3];
    *(short *)(param_1 + 0xc) = *(short *)(param_1 + 0xc) + (short)*(undefined4 *)(param_1 + 0x168);
    *(short *)(param_1 + 10) = *(short *)(param_1 + 10) + (short)*(undefined4 *)(param_1 + 0x16c);
    *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
    *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
    *(short *)(param_1 + 0x36) =
         *(short *)(param_1 + 0x36) - (short)*(undefined4 *)(param_1 + 0x168);
    *(short *)(param_1 + 0x3a) =
         *(short *)(param_1 + 0x3a) - (short)*(undefined4 *)(param_1 + 0x168);
    *(short *)(param_1 + 0x34) =
         *(short *)(param_1 + 0x34) - (short)*(undefined4 *)(param_1 + 0x16c);
    *(short *)(param_1 + 0x38) =
         *(short *)(param_1 + 0x38) - (short)*(undefined4 *)(param_1 + 0x16c);
  }
  *(undefined4 *)(param_1 + 0x14c) = 0xffffffff;
  return;
}


// ==== .HandlePlayerShotSprite @ 10059704 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandlePlayerShotSprite(int param_1)

{
  short sVar1;
  bool bVar2;
  short *psVar3;
  undefined4 *puVar4;
  int *piVar5;
  int *piVar6;
  short sVar10;
  short sVar11;
  int iVar7;
  int iVar8;
  undefined4 uVar9;
  undefined2 uVar12;
  short sVar13;
  int iVar14;
  short sVar15;
  undefined4 uStack_36;
  undefined4 uStack_32;
  undefined4 uStack_2e;
  undefined4 uStack_28;
  undefined4 uStack_22;
  undefined4 uStack_1e;
  
  piVar6 = _DAT_100a0810;
  piVar5 = _DAT_100a080c;
  puVar4 = _DAT_100a0800;
  psVar3 = _DAT_1009fd90;
  if (*(char *)(param_1 + 0xe9) != '\0') {
    return;
  }
  .debug::_StandardSpriteHandles(param_1);
  if (1 < *(int *)(param_1 + 0x170)) {
    *(short *)(param_1 + 0xc) = *(short *)(param_1 + 0xc) - (short)*(undefined4 *)(param_1 + 0x168);
    *(short *)(param_1 + 10) = *(short *)(param_1 + 10) - (short)*(undefined4 *)(param_1 + 0x16c);
    *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + *(int *)(param_1 + 0x168) * -0x100;
    *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + *(int *)(param_1 + 0x16c) * -0x100;
    *(short *)(param_1 + 0x36) =
         *(short *)(param_1 + 0x36) + (short)*(undefined4 *)(param_1 + 0x168);
    *(short *)(param_1 + 0x3a) =
         *(short *)(param_1 + 0x3a) + (short)*(undefined4 *)(param_1 + 0x168);
    *(short *)(param_1 + 0x34) =
         *(short *)(param_1 + 0x34) + (short)*(undefined4 *)(param_1 + 0x16c);
    *(short *)(param_1 + 0x38) =
         *(short *)(param_1 + 0x38) + (short)*(undefined4 *)(param_1 + 0x16c);
  }
  if (*(int *)(param_1 + 0x14c) < 200) {
    *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + 1;
  }
  if (0 < *(int *)(param_1 + 0x14c)) {
    sVar13 = *(short *)(param_1 + 4);
    if (sVar13 == 7) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (5 < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0;
      }
      *(int *)(param_1 + 0xc0) = *piVar5 + *(short *)(param_1 + 0x46) * 0x34;
    }
    else if (sVar13 < 7) {
      if (sVar13 == 3) {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (5 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        *(int *)(param_1 + 0xc0) = *piVar5 + *(short *)(param_1 + 0x46) * 0x34;
        for (sVar13 = 0; sVar13 < 5; sVar13 = sVar13 + 1) {
          .debug::_FastRand(400);
          sVar10 = .debug::_FastRand(6);
          sVar1 = *(short *)(param_1 + 0xc);
          sVar11 = .debug::_FastRand(6);
          uStack_22 = CONCAT22(*(short *)(param_1 + 10) + sVar11 + 5,sVar1 + sVar10 + 10);
          sVar10 = .debug::_FastRand(800);
          iVar14 = *(int *)(param_1 + 0x2c);
          iVar7 = .debug::_FastRand(400);
          sVar1 = *(short *)(param_1 + 0x86);
          iVar8 = .debug::_FastRand(2);
          .debug::_NewParticle
                    (3,0x15e,uStack_22,iVar8 + 1,(iVar7 + -200) - (int)sVar1,sVar10 + iVar14 + -400,
                     0,1);
        }
      }
      else if (sVar13 < 3) {
        if (sVar13 == 1) {
          *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
          if (5 < *(short *)(param_1 + 0x46)) {
            *(undefined2 *)(param_1 + 0x46) = 0;
          }
          if (*(int *)(param_1 + 0x24) < 1) {
            *(int *)(param_1 + 0xc0) = *_DAT_100a0820 + *(short *)(param_1 + 0x46) * 0x34;
          }
          else {
            *(int *)(param_1 + 0xc0) = *_DAT_100a0824 + *(short *)(param_1 + 0x46) * 0x34;
          }
        }
        else if (sVar13 < 1) {
          if (-1 < sVar13) {
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
            if (5 < *(short *)(param_1 + 0x46)) {
              *(undefined2 *)(param_1 + 0x46) = 0;
            }
            if (*(int *)(param_1 + 0x24) < 1) {
              *(int *)(param_1 + 0xc0) = *_DAT_100a0828 + *(short *)(param_1 + 0x46) * 0x34;
            }
            else {
              *(int *)(param_1 + 0xc0) = *_DAT_100a082c + *(short *)(param_1 + 0x46) * 0x34;
            }
          }
        }
        else {
          *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
          if (5 < *(short *)(param_1 + 0x46)) {
            *(undefined2 *)(param_1 + 0x46) = 0;
          }
          if (*(int *)(param_1 + 0x24) < 1) {
            *(int *)(param_1 + 0xc0) = *_DAT_100a0818 + *(short *)(param_1 + 0x46) * 0x34;
          }
          else {
            *(int *)(param_1 + 0xc0) = *_DAT_100a081c + *(short *)(param_1 + 0x46) * 0x34;
          }
          for (sVar13 = 0; sVar13 < 2; sVar13 = sVar13 + 1) {
            iVar14 = .debug::_FastRand(400);
            iVar14 = (iVar14 + -200) - (int)*(short *)(param_1 + 0x84);
            sVar10 = .debug::_FastRand(6);
            sVar1 = *(short *)(param_1 + 0xc);
            sVar11 = .debug::_FastRand(6);
            uStack_1e = CONCAT22(*(short *)(param_1 + 10) + sVar11 + 5,sVar1 + sVar10 + 10);
            if ((short)iVar14 < 0) {
              iVar14 = 0;
            }
            iVar7 = .debug::_FastRand(400);
            sVar1 = *(short *)(param_1 + 0x86);
            iVar8 = .debug::_FastRand(2);
            .debug::_NewParticle
                      (200,0xfa,uStack_1e,iVar8 + 1,(iVar7 + -200) - (int)sVar1,iVar14,0,1);
          }
        }
      }
      else if (sVar13 == 5) {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (5 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        *(int *)(param_1 + 0xc0) = *_DAT_100a0814 + *(short *)(param_1 + 0x46) * 0x34;
        if (0xc < *(int *)(param_1 + 0x14c)) {
          uStack_2e._0_2_ = (short)((uint)*(undefined4 *)(*_DAT_1009fdd8 + 0xe) >> 0x10);
          uStack_2e = CONCAT22(uStack_2e._0_2_ + -4,(short)*(undefined4 *)(*_DAT_1009fdd8 + 0xe));
          uVar9 = .debug::_FindDesiredDirectionGeneric(uStack_2e,*(undefined4 *)(param_1 + 0xe));
          FUN_1003f218(param_1,uVar9,800);
          .debug::_EnforceMaxSpeed(param_1,0x1450);
        }
      }
      else if (sVar13 < 5) {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (5 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        for (sVar13 = 0; sVar13 < 7; sVar13 = sVar13 + 1) {
          .debug::_FastRand(400);
          sVar10 = .debug::_FastRand(8);
          sVar1 = *(short *)(param_1 + 0xc);
          sVar11 = .debug::_FastRand(8);
          uStack_28 = CONCAT22(*(short *)(param_1 + 10) + sVar11 + 4,sVar1 + sVar10 + 9);
          iVar14 = .debug::_FastRand(400);
          iVar7 = .debug::_FastRand(400);
          sVar1 = *(short *)(param_1 + 0x86);
          iVar8 = .debug::_FastRand(2);
          .debug::_NewParticle
                    (9,0,uStack_28,iVar8 + 1,(iVar7 + -200) - (int)sVar1,iVar14 + -200,0,1);
        }
      }
      else {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (9 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        *(int *)(param_1 + 0xc0) = *piVar6 + *(short *)(param_1 + 0x46) * 0x34;
        if ((int)*(short *)(param_1 + 0xe) < *psVar3 + -500) {
          *(undefined1 *)(param_1 + 0xe9) = 1;
        }
        if (*psVar3 + 500 < (int)*(short *)(param_1 + 0xe)) {
          *(undefined1 *)(param_1 + 0xe9) = 1;
        }
      }
    }
    else if (sVar13 == 0x50) {
      *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0804;
      *(int *)(param_1 + 0x16c) = *(int *)(param_1 + 0x16c) + 1;
      if (0xf < *(int *)(param_1 + 0x16c)) {
        *(undefined4 *)(param_1 + 0x16c) = 0;
      }
      *(undefined1 *)(param_1 + 0x88) = 0;
      iVar14 = *(int *)(param_1 + 0x16c) >> 1;
      if (iVar14 < 4) {
        if (iVar14 < 2) {
          if (-1 < iVar14) {
            *(undefined4 *)(param_1 + 0xb8) = 0;
          }
        }
        else {
LAB_10059e48:
          *(undefined4 *)(param_1 + 0xb8) = 0x10008;
        }
      }
      else if (iVar14 < 8) {
        if (5 < iVar14) goto LAB_10059e48;
        *(undefined4 *)(param_1 + 0xb8) = 0x10009;
      }
      if (*(int *)(param_1 + 0x164) < 0) {
        *(int *)(param_1 + 0x164) = *(int *)(param_1 + 0x164) + 1;
        iVar14 = *(int *)(param_1 + 0x164);
        if (iVar14 < -3) {
          if (iVar14 < -6) {
            if (iVar14 < -9) goto LAB_10059ed0;
            *(undefined4 *)(param_1 + 0xb8) = 0xb0002;
          }
          else {
            *(undefined4 *)(param_1 + 0xb8) = 0xb0000;
          }
        }
        else if (iVar14 < 0) {
          *(undefined4 *)(param_1 + 0xb8) = 0xb0001;
        }
        else {
LAB_10059ed0:
          *(undefined4 *)(param_1 + 0xb8) = 0;
        }
      }
    }
    else if (sVar13 < 0x50) {
      if (sVar13 == 0x3c) {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (9 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        *(int *)(param_1 + 0xc0) = *piVar6 + (*(short *)(param_1 + 0x46) + 10) * 0x34;
        if ((int)*(short *)(param_1 + 0xe) < *psVar3 + -500) {
          *(undefined1 *)(param_1 + 0xe9) = 1;
        }
        if (*psVar3 + 500 < (int)*(short *)(param_1 + 0xe)) {
          *(undefined1 *)(param_1 + 0xe9) = 1;
        }
      }
    }
    else if (sVar13 == 0x5a) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (7 < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0;
      }
      *(int *)(param_1 + 0xc0) = *_DAT_100a0808 + *(short *)(param_1 + 0x46) * 0x34;
      if (*(int *)(param_1 + 0xf0) != 0) {
        *(undefined4 *)(param_1 + 0xc0) = 0;
      }
      *(undefined2 *)(param_1 + 0xa6) = 0;
      if (*(int *)(param_1 + 0xf4) == 0) {
        *(undefined2 *)(param_1 + 0xa4) = 800;
      }
      else {
        *(undefined2 *)(param_1 + 0xa4) = 0x578;
        *(undefined4 *)(param_1 + 0xb8) = 0x10004;
      }
    }
  }
  if ((*(int *)(param_1 + 0x14c) == 1) && (0 < *(int *)(param_1 + 0x170))) {
    bVar2 = true;
    .debug::_StandardSpriteCleanup(param_1);
    iVar14 = *(int *)(param_1 + 0xc0);
    if ((iVar14 != 0) &&
       ((*(short *)(iVar14 + 0xe) <= *(short *)(param_1 + 0x1b6) ||
        (*(short *)(param_1 + 0x1b8) <= *(short *)(iVar14 + 10))))) {
      bVar2 = false;
    }
    *(short *)(param_1 + 0xa4) =
         *(short *)(param_1 + 0xa4) * (short)*(undefined4 *)(param_1 + 0x170);
    if (bVar2) {
      sVar13 = *(short *)(param_1 + 0xc);
      sVar1 = *(short *)(param_1 + 10);
      sVar11 = (short)((uint)*(undefined4 *)(param_1 + 0x24) >> 8);
      uStack_32 = CONCAT22(sVar1 + 8,sVar13 + 0xc + sVar11);
      sVar10 = *(short *)(param_1 + 4);
      sVar15 = (short)*(undefined4 *)(param_1 + 0x24);
      if (sVar10 != 6) {
        if (sVar10 < 6) {
          if (sVar10 == 2) {
            uVar12 = .debug::_AddLight(*puVar4,uStack_32,(int)sVar15,
                                       (int)(short)*(undefined4 *)(param_1 + 0x2c),
                                       (int)*(short *)(param_1 + 0x110),0x21);
            *(undefined2 *)(param_1 + 0x9a) = uVar12;
          }
          else if (sVar10 < 2) {
            if (sVar10 == 0) {
              uVar12 = .debug::_AddLight(*puVar4,uStack_32,(int)sVar15,
                                         (int)(short)*(undefined4 *)(param_1 + 0x2c),
                                         (int)*(short *)(param_1 + 0x110),0x16);
              *(undefined2 *)(param_1 + 0x9a) = uVar12;
            }
            else if (-1 < sVar10) {
              uVar12 = .debug::_AddLight(*puVar4,uStack_32,(int)sVar15,
                                         (int)(short)*(undefined4 *)(param_1 + 0x2c),
                                         (int)*(short *)(param_1 + 0x110),0x21);
              *(undefined2 *)(param_1 + 0x9a) = uVar12;
            }
          }
          else if (sVar10 == 4) {
            uVar12 = .debug::_AddLight(*puVar4,uStack_32,(int)sVar15,
                                       (int)(short)*(undefined4 *)(param_1 + 0x2c),
                                       (int)*(short *)(param_1 + 0x110),0x42);
            *(undefined2 *)(param_1 + 0x9a) = uVar12;
          }
          else if (sVar10 < 4) {
            uVar12 = .debug::_AddLight(*puVar4,uStack_32,(int)sVar15,
                                       (int)(short)*(undefined4 *)(param_1 + 0x2c),
                                       (int)*(short *)(param_1 + 0x110),0x4d);
            *(undefined2 *)(param_1 + 0x9a) = uVar12;
          }
          else {
            uStack_32 = CONCAT22(sVar1 + 0x10,sVar13 + 0x10 + sVar11);
            uVar12 = .debug::_AddLight(*puVar4,uStack_32,(int)sVar15,
                                       (int)(short)*(undefined4 *)(param_1 + 0x2c),
                                       (int)*(short *)(param_1 + 0x110),0x16);
            *(undefined2 *)(param_1 + 0x9a) = uVar12;
          }
          goto LAB_1005a20c;
        }
        if (sVar10 != 0x3c) {
          if ((sVar10 < 0x3c) && (sVar10 < 8)) {
            uStack_32 = CONCAT22(sVar1 + 0xe,sVar13 + 0xe + sVar11);
            uVar12 = .debug::_AddLight(*puVar4,uStack_32,(int)sVar15,
                                       (int)(short)*(undefined4 *)(param_1 + 0x2c),
                                       (int)*(short *)(param_1 + 0x110),0x21);
            *(undefined2 *)(param_1 + 0x9a) = uVar12;
          }
          goto LAB_1005a20c;
        }
      }
      uStack_32 = CONCAT22(sVar1 + 0x14,sVar13 + 0x10 + sVar11);
      uVar12 = .debug::_AddLight(*_DAT_100a07fc,uStack_32,(int)sVar15,
                                 (int)(short)*(undefined4 *)(param_1 + 0x2c),
                                 (int)*(short *)(param_1 + 0x110),0x2c);
      *(undefined2 *)(param_1 + 0x9a) = uVar12;
    }
  }
LAB_1005a20c:
  *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + (int)*(short *)(param_1 + 0x110);
  *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + *(int *)(param_1 + 0x24);
  *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + *(int *)(param_1 + 0x2c);
  .debug::_ChangeLightSpeed
            ((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(param_1 + 0x24),
             *(undefined4 *)(param_1 + 0x2c));
  sVar13 = *(short *)(param_1 + 4);
  if (((sVar13 < 100) || (sVar13 == 0x5a)) || ((sVar13 == 100 && (0 < *(int *)(param_1 + 0x158)))))
  {
    .debug::_SeparateFromTiles2(param_1);
  }
  if (((0 < *(int *)(param_1 + 0x11c)) && (*(short *)(param_1 + 4) < 100)) &&
     (*(short *)(param_1 + 4) != 6)) {
    iVar14 = .debug::_MTNewSprite
                       (5,*(short *)(param_1 + 0xc) + -8,*(short *)(param_1 + 10) + -0xc,0xb,
                        0xffffffff,_DAT_1009fef8);
    .debug::_ChangeLightColor((int)*(short *)(iVar14 + 0x9a),0);
    *(undefined1 *)(param_1 + 0xe9) = 1;
    if ((*(short *)(param_1 + 4) == 3) && (*(short *)(param_1 + 0x128) == 0)) {
      .debug::_CalcCenterPos(param_1);
      iVar14 = .debug::_MTNewSprite
                         (0x57c,*(short *)(param_1 + 0xc) + -10,*(short *)(param_1 + 0xe) + -4,2,
                          0xffffffff,_DAT_1009ff2c);
      *(undefined2 *)(iVar14 + 0xa6) = 0xb4;
      *(undefined2 *)(iVar14 + 0xb0) = 4;
      *(undefined2 *)(iVar14 + 0x13a) = 4;
    }
    if (1 < *(int *)(param_1 + 0x170)) {
      if (*(int *)(param_1 + 0x1d4) != 0) {
        *(undefined1 *)(*(int *)(param_1 + 0x1d4) + 0xe9) = 1;
      }
      if (*(int *)(param_1 + 0x1d8) != 0) {
        *(undefined1 *)(*(int *)(param_1 + 0x1d8) + 0xe9) = 1;
      }
      if (*(int *)(param_1 + 0x1dc) != 0) {
        *(undefined1 *)(*(int *)(param_1 + 0x1dc) + 0xe9) = 1;
      }
      if (*(int *)(param_1 + 0x1e0) != 0) {
        *(undefined1 *)(*(int *)(param_1 + 0x1e0) + 0xe9) = 1;
      }
    }
  }
  if ((int)*(short *)(*(int *)*_DAT_100a0058 + 0xb282) << 5 < (int)*(short *)(param_1 + 10)) {
    *(undefined1 *)(param_1 + 0xe9) = 1;
  }
  if (*(short *)(param_1 + 4) < 100) {
    uVar12 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
    *(undefined2 *)(param_1 + 8) = uVar12;
    *(undefined2 *)(param_1 + 0xc) = uVar12;
    uVar12 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
    *(undefined2 *)(param_1 + 6) = uVar12;
    *(undefined2 *)(param_1 + 10) = uVar12;
  }
  else {
    *(undefined4 *)(param_1 + 6) = *(undefined4 *)(param_1 + 10);
  }
  *(short *)(param_1 + 0x10) =
       *(short *)(param_1 + 0xc) +
       *(short *)(param_1 + 0x36) +
       (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  *(short *)(param_1 + 0xe) =
       *(short *)(param_1 + 10) +
       *(short *)(param_1 + 0x34) +
       (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  if (0 < *(short *)(param_1 + 0x110)) {
    uStack_36 = *(undefined4 *)(param_1 + 10);
    if (1 < *(int *)(param_1 + 0x170)) {
      uStack_36._0_2_ = (short)((uint)uStack_36 >> 0x10);
      uStack_36 = CONCAT22(uStack_36._0_2_ + (short)*(undefined4 *)(param_1 + 0x16c),
                           uStack_36._2_2_ + (short)*(undefined4 *)(param_1 + 0x168));
    }
    sVar13 = .debug::_FindDesiredDirectionGeneric(*(undefined4 *)(param_1 + 0xc4),uStack_36);
    if (*(int *)(param_1 + 0x24) < 0) {
      sVar13 = sVar13 + 0x12;
    }
    if (0x23 < sVar13) {
      sVar13 = sVar13 + -0x24;
    }
    *(short *)(param_1 + 0x1aa) = sVar13 * 10;
  }
  if (1 < *(int *)(param_1 + 0x170)) {
    if (*(int *)(param_1 + 0x1d4) != 0) {
      *(short *)(*(int *)(param_1 + 0x1d4) + 0xc) =
           (*(short *)(param_1 + 0xc) + (short)*(undefined4 *)(param_1 + 0x168)) -
           (short)*(undefined4 *)(param_1 + 0x160);
      *(short *)(*(int *)(param_1 + 0x1d4) + 10) =
           (*(short *)(param_1 + 10) + (short)*(undefined4 *)(param_1 + 0x16c)) -
           (short)*(undefined4 *)(param_1 + 0x164);
      *(int *)(*(int *)(param_1 + 0x1d4) + 0x14) =
           (int)*(short *)(*(int *)(param_1 + 0x1d4) + 0xc) << 8;
      *(int *)(*(int *)(param_1 + 0x1d4) + 0x1c) =
           (int)*(short *)(*(int *)(param_1 + 0x1d4) + 10) << 8;
      *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0x24) = *(undefined4 *)(param_1 + 0x24);
    }
    if (*(int *)(param_1 + 0x1d8) != 0) {
      *(short *)(*(int *)(param_1 + 0x1d8) + 0xc) =
           (*(short *)(param_1 + 0xc) + (short)*(undefined4 *)(param_1 + 0x168)) -
           (short)(*(int *)(param_1 + 0x160) << 1);
      *(short *)(*(int *)(param_1 + 0x1d8) + 10) =
           (*(short *)(param_1 + 10) + (short)*(undefined4 *)(param_1 + 0x16c)) -
           (short)(*(int *)(param_1 + 0x164) << 1);
      *(int *)(*(int *)(param_1 + 0x1d8) + 0x14) =
           (int)*(short *)(*(int *)(param_1 + 0x1d8) + 0xc) << 8;
      *(int *)(*(int *)(param_1 + 0x1d8) + 0x1c) =
           (int)*(short *)(*(int *)(param_1 + 0x1d8) + 10) << 8;
      *(undefined4 *)(*(int *)(param_1 + 0x1d8) + 0x24) = *(undefined4 *)(param_1 + 0x24);
    }
    if (*(int *)(param_1 + 0x1dc) != 0) {
      *(short *)(*(int *)(param_1 + 0x1dc) + 0xc) =
           *(short *)(param_1 + 0xc) + (short)*(undefined4 *)(param_1 + 0x168) +
           (short)*(undefined4 *)(param_1 + 0x160) * -3;
      *(short *)(*(int *)(param_1 + 0x1dc) + 10) =
           *(short *)(param_1 + 10) + (short)*(undefined4 *)(param_1 + 0x16c) +
           (short)*(undefined4 *)(param_1 + 0x164) * -3;
      *(int *)(*(int *)(param_1 + 0x1dc) + 0x14) =
           (int)*(short *)(*(int *)(param_1 + 0x1dc) + 0xc) << 8;
      *(int *)(*(int *)(param_1 + 0x1dc) + 0x1c) =
           (int)*(short *)(*(int *)(param_1 + 0x1dc) + 10) << 8;
      *(undefined4 *)(*(int *)(param_1 + 0x1dc) + 0x24) = *(undefined4 *)(param_1 + 0x24);
    }
    if (*(int *)(param_1 + 0x1e0) != 0) {
      *(short *)(*(int *)(param_1 + 0x1e0) + 0xc) =
           (*(short *)(param_1 + 0xc) + (short)*(undefined4 *)(param_1 + 0x168)) -
           (short)(*(int *)(param_1 + 0x160) << 2);
      *(short *)(*(int *)(param_1 + 0x1e0) + 10) =
           (*(short *)(param_1 + 10) + (short)*(undefined4 *)(param_1 + 0x16c)) -
           (short)(*(int *)(param_1 + 0x164) << 2);
      *(int *)(*(int *)(param_1 + 0x1e0) + 0x14) =
           (int)*(short *)(*(int *)(param_1 + 0x1e0) + 0xc) << 8;
      *(int *)(*(int *)(param_1 + 0x1e0) + 0x1c) =
           (int)*(short *)(*(int *)(param_1 + 0x1e0) + 10) << 8;
      *(undefined4 *)(*(int *)(param_1 + 0x1e0) + 0x24) = *(undefined4 *)(param_1 + 0x24);
    }
    *(short *)(param_1 + 0xc) = *(short *)(param_1 + 0xc) + (short)*(undefined4 *)(param_1 + 0x168);
    *(short *)(param_1 + 10) = *(short *)(param_1 + 10) + (short)*(undefined4 *)(param_1 + 0x16c);
    *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + *(int *)(param_1 + 0x168) * 0x100;
    *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + *(int *)(param_1 + 0x16c) * 0x100;
    *(short *)(param_1 + 0x36) =
         *(short *)(param_1 + 0x36) - (short)*(undefined4 *)(param_1 + 0x168);
    *(short *)(param_1 + 0x3a) =
         *(short *)(param_1 + 0x3a) - (short)*(undefined4 *)(param_1 + 0x168);
    *(short *)(param_1 + 0x34) =
         *(short *)(param_1 + 0x34) - (short)*(undefined4 *)(param_1 + 0x16c);
    *(short *)(param_1 + 0x38) =
         *(short *)(param_1 + 0x38) - (short)*(undefined4 *)(param_1 + 0x16c);
    if (*(int *)(param_1 + 0x1d4) != 0) {
      *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0x1aa) = *(undefined2 *)(param_1 + 0x1aa);
    }
    if (*(int *)(param_1 + 0x1d8) != 0) {
      *(undefined2 *)(*(int *)(param_1 + 0x1d8) + 0x1aa) = *(undefined2 *)(param_1 + 0x1aa);
    }
    if (*(int *)(param_1 + 0x1dc) != 0) {
      *(undefined2 *)(*(int *)(param_1 + 0x1dc) + 0x1aa) = *(undefined2 *)(param_1 + 0x1aa);
    }
    if (*(int *)(param_1 + 0x1e0) != 0) {
      *(undefined2 *)(*(int *)(param_1 + 0x1e0) + 0x1aa) = *(undefined2 *)(param_1 + 0x1aa);
    }
  }
  .debug::_StandardSpriteCleanup(param_1);
  iVar14 = *(int *)(param_1 + 0xc0);
  if ((iVar14 != 0) &&
     ((*(short *)(iVar14 + 0xe) <= *(short *)(param_1 + 0x1b6) ||
      (*(short *)(param_1 + 0x1b8) <= *(short *)(iVar14 + 10))))) {
    .debug::_RemoveLight(param_1 + 0x9a);
  }
  return;
}


// ==== .HitPlayerShotSprite @ 1005a7fc ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitPlayerShotSprite(int param_1,int param_2)

{
  byte *pbVar1;
  undefined4 *puVar2;
  undefined4 *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  undefined *puVar6;
  undefined *puVar7;
  int iVar8;
  int iVar9;
  short sVar10;
  short sStack_28;
  short sStack_26;
  
  puVar6 = PTR_PTR_100a052c;
  puVar5 = PTR_PTR_100a0488;
  puVar4 = PTR_PTR_100a0484;
  puVar2 = _DAT_100a041c;
  iVar9 = _DAT_1009ffc0;
  if (((*(undefined **)(param_2 + 0x4c) == PTR_PTR_100a052c) && (*(short *)(param_1 + 4) == 5)) &&
     (10 < *(int *)(param_1 + 0x14c))) {
    *(undefined1 *)(param_1 + 0xe9) = 1;
    *(short *)(iVar9 + 0xe) = *(short *)(iVar9 + 0xe) + 8;
    if (1 < *(int *)(param_1 + 0x170)) {
      if (*(int *)(param_1 + 0x1d4) != 0) {
        *(undefined1 *)(*(int *)(param_1 + 0x1d4) + 0xe9) = 1;
      }
      if (*(int *)(param_1 + 0x1d8) != 0) {
        *(undefined1 *)(*(int *)(param_1 + 0x1d8) + 0xe9) = 1;
      }
      if (*(int *)(param_1 + 0x1dc) != 0) {
        *(undefined1 *)(*(int *)(param_1 + 0x1dc) + 0xe9) = 1;
      }
      if (*(int *)(param_1 + 0x1e0) != 0) {
        *(undefined1 *)(*(int *)(param_1 + 0x1e0) + 0xe9) = 1;
      }
    }
  }
  if ((*(undefined **)(param_2 + 0x4c) == puVar5) && (*(short *)(param_2 + 4) == 0x77b)) {
    .debug::_STPlay3DSound(*puVar2,1,0xab,*(undefined4 *)(param_2 + 0xe));
    .debug::_KillPlayerShot(param_1,0,1);
  }
  puVar3 = _DAT_100a03e4;
  puVar7 = *(undefined **)(param_2 + 0x4c);
  if ((puVar7 == puVar5) && (*(short *)(param_1 + 4) == 0x50)) {
    .debug::_STPlay3DSound(*puVar2,1,0x55,*(undefined4 *)(param_2 + 0xe));
    .debug::_KillPlayerShot(param_1,1,1);
    .debug::_KillEnemyShot(param_2);
  }
  else {
    sVar10 = *(short *)(param_1 + 4);
    if ((sVar10 != 0x50) || (*(short *)(param_2 + 4) != 0xb7c)) {
      if ((puVar7 == puVar4) &&
         ((*(short *)(param_2 + 4) == 0x2c8 || (*(short *)(param_2 + 4) == 0x2c9)))) {
        if (sVar10 == 4) {
          do {
            iVar9 = param_2;
            param_2 = *(int *)(iVar9 + 0x1d4);
          } while (*(int *)(iVar9 + 0x1d4) != 0);
          iVar8 = .debug::_MTNewSprite
                            (0x2c9,(int)*(short *)(iVar9 + 0xc),*(short *)(iVar9 + 10) + -0x10,2,
                             0xffffffff,_DAT_1009ff34);
          pbVar1 = _DAT_1009fd30;
          *(int *)(iVar9 + 0x1d4) = iVar8;
          *(ushort *)(iVar8 + 0xa6) = *pbVar1 + 0x78;
          if (*(short *)(iVar9 + 0xa6) < 0x23) {
            *(undefined2 *)(iVar9 + 0xa6) = 0x23;
          }
          iVar9 = .debug::_MTNewSprite
                            (2,*(short *)(iVar8 + 0xc) + -6,*(short *)(iVar8 + 10) + -9,0xb,
                             0xffffffff,_DAT_1009fef8);
          *(undefined2 *)(iVar9 + 0x46) = 8;
          .debug::_ChangeLightColor((int)*(short *)(iVar9 + 0x9a),0x42);
          puVar2 = _DAT_100a01fc;
          *(undefined1 *)(param_1 + 0xe9) = 1;
          .debug::_STPlay3DSound(*puVar2,1,0x100,*(undefined4 *)(iVar9 + 0xe));
        }
      }
      else if ((puVar7 != puVar6) && (puVar7 != PTR_PTR_100a0460)) {
        if (puVar7 == PTR_PTR_100a047c) {
          if (((*(short *)(param_2 + 4) == 0x517) || (*(short *)(param_2 + 4) == 0x51b)) &&
             ((sVar10 != 0x50 && (*(short *)(param_2 + 0xb0) != 0)))) {
            .debug::_KillPlayerShot(param_1,1,1);
          }
        }
        else if ((puVar7 == PTR_PTR_100a01f8) || (puVar7 == puVar4)) {
          if ((*(char *)(param_2 + 0x185) == '\0') && (*(int *)(param_2 + 0x1e8) == 0)) {
            if (((*(short *)(param_2 + 4) == 0xb7d) && (*(short *)(param_2 + 0x116) < 1)) &&
               (*(short *)(param_1 + 0xa4) == 300)) {
              *(short *)(param_2 + 0xa4) = *(short *)(param_2 + 0xa4) + -0x50;
              *(undefined2 *)(param_2 + 0xaa) = 10;
              *(undefined2 *)(param_2 + 0x116) = 10;
              .debug::_STPlay3DSoundPitched(*puVar3,1,0x100,*(undefined4 *)(param_1 + 10),35000);
            }
            .debug::_KillPlayerShot(param_1,1,1);
          }
          else {
            sStack_26 = *(short *)(param_1 + 0x36) +
                        (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >>
                               1);
            sStack_28 = *(short *)(param_1 + 0x34) +
                        (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >>
                               1);
            sVar10 = .debug::_PlatformBounce(param_1,param_2,&sStack_28,0,param_1 + 0x34,0);
            if (sVar10 != 0) {
              .debug::_KillPlayerShot(param_1,1,1);
            }
          }
        }
        else if (puVar7 == PTR_PTR_100a04b8) {
          .debug::_KillPlayerShot(param_1,0,0);
        }
      }
    }
  }
  return;
}


// ==== .HitPlayerShotTileSprite @ 1005b0bc ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitPlayerShotTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  bool bVar1;
  short sVar2;
  bool bVar3;
  bool bVar4;
  undefined4 uVar5;
  undefined4 uVar6;
  undefined4 *puVar7;
  char cVar9;
  int iVar8;
  short sVar10;
  undefined4 uVar11;
  short sStack_50;
  short sStack_4e;
  undefined1 auStack_30 [20];
  
  uVar6 = _DAT_1009ff34;
  uVar5 = _DAT_1009ff2c;
  uVar11 = 0;
  sStack_4e = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_50 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  bVar1 = *(short *)(param_1 + 4) == 0x5a;
  if (bVar1) {
    uVar11 = 0xa0;
  }
  if (((*_DAT_100a0064 == '\0') || (cVar9 = .debug::_IsPressed(0x32), cVar9 == '\0')) &&
     (*(char *)(param_1 + 0xe9) == '\0')) {
    .glue::SetRect(auStack_30,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                   (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
    sVar2 = *(short *)(param_1 + 4);
    if (((sVar2 != 6) && (sVar2 != 0x3c)) || (param_4 == 2)) {
      sVar10 = (short)param_3;
      if ((param_4 == 1) && (sVar2 != 100)) {
        if ((sVar2 != 0x50) &&
           (cVar9 = .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_50,uVar11,
                                        param_1 + 0x34,0,bVar1), cVar9 != '\0')) {
          bVar1 = true;
          if (sVar10 != 0) {
            bVar3 = false;
            if (((param_3 - 4U & 0xffff) < 2) && (*(int *)(param_1 + 0x24) == 0)) {
              bVar3 = true;
            }
            if (!bVar3) {
              bVar1 = false;
            }
          }
          bVar3 = true;
          if (sVar10 != 2) {
            bVar4 = false;
            if (((param_3 - 6U & 0xffff) < 2) && (*(int *)(param_1 + 0x24) == 0)) {
              bVar4 = true;
            }
            if (!bVar4) {
              bVar3 = false;
            }
          }
          if ((*(short *)(param_1 + 4) == 3) && ((bVar3 || (bVar1)))) {
            if (bVar3) {
              iVar8 = .debug::_MTNewSprite
                                (0x57c,(short)param_2 + -0x17,(int)*(short *)(param_1 + 0xe),2,
                                 0xffffffff,uVar5);
              *(undefined4 *)(iVar8 + 0x16c) = 1;
            }
            else {
              iVar8 = .debug::_MTNewSprite
                                (0x57c,(short)param_2 + 0xf,(int)*(short *)(param_1 + 0xe),2,
                                 0xffffffff,uVar5);
              *(undefined4 *)(iVar8 + 0x16c) = 2;
            }
            *(undefined2 *)(iVar8 + 0xa6) = 0xb4;
            *(undefined2 *)(iVar8 + 0xb0) = 4;
          }
          if ((*(char *)(param_1 + 0xce) == '\0') || (*(short *)(param_1 + 4) != 4)) {
            if (*(short *)(param_1 + 4) == 0x5a) {
              iVar8 = *(int *)(param_1 + 0x2c);
              if (iVar8 < 1) {
                iVar8 = -iVar8;
              }
              if (iVar8 < 0x200) {
                .debug::_KillPlayerShot(param_1,1,1);
              }
            }
            else {
              .debug::_KillPlayerShot(param_1,1,1);
            }
          }
          else {
            iVar8 = .debug::_MTNewSprite
                              (0x2c8,*(short *)(param_1 + 0x10) + -8,*(short *)(param_1 + 0xe) + -6,
                               2,0xffffffff,uVar6);
            uVar5 = _DAT_1009fef8;
            *(ushort *)(iVar8 + 0xa6) = *_DAT_1009fd30 + 0x78;
            iVar8 = .debug::_MTNewSprite
                              (2,*(short *)(iVar8 + 0xc) + -6,*(short *)(iVar8 + 10) + -9,0xb,
                               0xffffffff,uVar5);
            *(undefined2 *)(iVar8 + 0x46) = 8;
            .debug::_ChangeLightColor((int)*(short *)(iVar8 + 0x9a),0x42);
            puVar7 = _DAT_100a01fc;
            *(undefined1 *)(param_1 + 0xe9) = 1;
            .debug::_STPlay3DSound(*puVar7,1,0x100,*(undefined4 *)(param_1 + 0xe));
          }
        }
      }
      else if ((param_4 == 0) && (sVar2 != 100)) {
        if (sVar10 < 100) {
          if ((sVar2 != 0x50) &&
             (cVar9 = .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_50,uVar11,
                                          param_1 + 0x34,0,bVar1), cVar9 != '\0')) {
            if (*(short *)(param_1 + 4) == 0x5a) {
              iVar8 = *(int *)(param_1 + 0x2c);
              if (iVar8 < 1) {
                iVar8 = -iVar8;
              }
              if (iVar8 < 0x200) {
                .debug::_KillPlayerShot(param_1,1,1);
              }
            }
            else {
              .debug::_KillPlayerShot(param_1,1,1);
            }
          }
        }
        else if (sVar10 < 200) {
          if ((sVar2 != 0x50) &&
             (cVar9 = .debug::_WallBounceBG
                                (param_1,param_3 + -100,&stack0x0000001c,&sStack_50,uVar11,
                                 param_1 + 0x34,0,bVar1), cVar9 != '\0')) {
            if ((*(char *)(param_1 + 0xce) != '\0') && (*(short *)(param_1 + 4) == 4)) {
              iVar8 = .debug::_MTNewSprite
                                (0x2c8,*(short *)(param_1 + 0x10) + -8,
                                 *(short *)(param_1 + 0xe) + -6,2,0xffffffff,uVar6);
              *(undefined2 *)(iVar8 + 0xa6) = 0x78;
            }
            if (*(short *)(param_1 + 4) == 0x5a) {
              iVar8 = *(int *)(param_1 + 0x2c);
              if (iVar8 < 1) {
                iVar8 = -iVar8;
              }
              if (iVar8 < 0x200) {
                .debug::_KillPlayerShot(param_1,1,1);
              }
            }
            else {
              .debug::_KillPlayerShot(param_1,1,1);
            }
          }
        }
        else {
          cVar9 = .debug::_IsWaterTile(param_3);
          if ((cVar9 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
            .debug::_HandleUnderWater(param_1,param_2);
          }
        }
      }
      else if ((((param_4 == 2) &&
                (cVar9 = .debug::_CrunchTile(param_2,(int)(short)*(undefined4 *)(param_1 + 0x158)),
                cVar9 != '\0')) && (*(short *)(param_1 + 4) != 6)) &&
              (*(short *)(param_1 + 4) != 0x3c)) {
        .debug::_KillPlayerShot(param_1,1,1);
      }
    }
  }
  return;
}


// ==== .SetupEnemyShotSprite @ 1005ba5c ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 * _SetupEnemyShotSprite(int param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined4 *puVar3;
  undefined2 uVar6;
  int iVar4;
  undefined4 *puVar5;
  short sVar7;
  
  .debug::_InitSprite();
  *(undefined2 *)(param_1 + 0x84) = 0;
  *(undefined2 *)(param_1 + 0x86) = 0;
  uVar6 = .debug::_FastRand(5);
  *(undefined2 *)(param_1 + 0x46) = uVar6;
  puVar2 = PTR_PTR_100a0838;
  *(undefined **)(param_1 + 0x4c) = PTR_PTR_100a0488;
  puVar1 = PTR_PTR_100a0834;
  *(undefined **)(param_1 + 0x5c) = puVar2;
  *(undefined **)(param_1 + 0x1f8) = puVar1;
  *(undefined2 *)(param_1 + 0xa6) = 0;
  *(undefined2 *)(param_1 + 0x90) = 0x100;
  *(undefined2 *)(param_1 + 0x110) = 0xaf;
  *(undefined4 *)(param_1 + 0xc0) = 0;
  *(undefined1 *)(param_1 + 0x8c) = 1;
  iVar4 = (int)*(short *)(param_1 + 4);
  if (iVar4 == 0x6a9) {
    *(undefined4 *)(param_1 + 0x80) = 0x14;
    puVar5 = (undefined4 *).glue::SetRect(param_1 + 0x34,0,0,0x5a,0xe);
    *(undefined4 *)(param_1 + 0x14c) = 2;
    *(undefined2 *)(param_1 + 0x110) = 0;
  }
  else if ((iVar4 - 0x6e1U & 0xffff) < 2) {
    .glue::SetRect(param_1 + 0x34,8,8,0x18,0x18);
    *(undefined2 *)(param_1 + 0x110) = 300;
    sVar7 = .debug::_FastRand(2);
    *(int *)(param_1 + 0x150) = -2 - sVar7;
    *(undefined2 *)(param_1 + 0xa4) = 200;
    puVar5 = (undefined4 *).debug::_FastRand(100);
    if (0x56 < (short)puVar5) {
      sVar7 = .debug::_FastRand(5);
      puVar5 = (undefined4 *)(3 - sVar7);
      *(int *)(param_1 + 0x150) = *(int *)(param_1 + 0x150) - (int)puVar5;
    }
    *(undefined1 *)(param_1 + 0xeb) = 1;
  }
  else if (iVar4 == 0x6e6) {
    puVar5 = (undefined4 *).glue::SetRect(param_1 + 0x34,6,6,10,10);
  }
  else if (iVar4 == 0x709) {
    *(undefined2 *)(param_1 + 0x110) = 0;
    puVar5 = (undefined4 *).glue::SetRect(param_1 + 0x34,8,3,0xf,0xc);
  }
  else if (iVar4 == 0x712) {
    *(undefined2 *)(param_1 + 0x110) = 0;
    puVar5 = (undefined4 *).glue::SetRect(param_1 + 0x34,8,3,0xf,0xc);
  }
  else if (iVar4 == 0x6d6) {
    *(undefined4 *)(param_1 + 0xc0) = 0;
    puVar5 = (undefined4 *).glue::SetRect(param_1 + 0x34,0,0,0x3c,0x18);
    *(undefined2 *)(param_1 + 0xa6) = 3;
    *(undefined2 *)(param_1 + 0xa4) = 0x70;
  }
  else if (iVar4 == 0x6f4) {
    *(undefined4 *)(param_1 + 0xc0) = 0;
    .glue::SetRect(param_1 + 0x34,5,5,0x12,0xc);
    puVar5 = (undefined4 *).debug::_FastRand(0xf);
    *(short *)(param_1 + 0x46) = (short)puVar5;
    *(undefined2 *)(param_1 + 0x110) = 0;
    *(undefined2 *)(param_1 + 0xa4) = 0x70;
    *(undefined1 *)(param_1 + 0x88) = 0;
    *(undefined2 *)(param_1 + 0xa6) = 0;
  }
  else if (iVar4 == 0x709) {
    *(undefined2 *)(param_1 + 0xa4) = 0x38;
    puVar5 = (undefined4 *)0x709;
  }
  else if (iVar4 == 0x753) {
    .glue::SetRect(param_1 + 0x34,4,0,0x14,0xe);
    *(undefined2 *)(param_1 + 0xa4) = 0x1c0;
    *(undefined2 *)(param_1 + 0x46) = 6;
    sVar7 = .debug::_FastRand(100);
    *(byte *)(param_1 + 0x17e) = ((uint)(int)sVar7 < 0x33) - ((char)~(byte)(sVar7 >> 0xf) >> 7) & 1;
    *(undefined4 *)(param_1 + 0x15c) = 0xf0;
    puVar5 = (undefined4 *)(0x32 - sVar7);
  }
  else if (iVar4 == 0x754) {
    puVar5 = (undefined4 *).glue::SetRect(param_1 + 0x34,8,3,10,8);
    *(undefined4 *)(param_1 + 0x80) = 0xc;
    *(undefined2 *)(param_1 + 0x110) = 0;
  }
  else if (iVar4 == 0x71f) {
    puVar5 = (undefined4 *).glue::SetRect(param_1 + 0x34,0x12,0x12,0x1e,0x1e);
    *(undefined2 *)(param_1 + 0x46) = 0;
    *(undefined2 *)(param_1 + 0x110) = 0;
  }
  else if ((iVar4 - 0x771U & 0xffff) < 2) {
    .glue::SetRect(param_1 + 0x34,2,0xfffffffc,0x3a,4);
    *(undefined2 *)(param_1 + 0xa4) = 0x38;
    *(undefined2 *)(param_1 + 0x46) = 0;
    *(undefined2 *)(param_1 + 0x110) = 0;
    puVar3 = _DAT_100a0858;
    puVar5 = _DAT_100a0854;
    if (*(short *)(param_1 + 4) == 0x771) {
      *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0858;
      puVar5 = puVar3;
    }
    else {
      *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0854;
    }
  }
  else if ((iVar4 - 0x773U & 0xffff) < 2) {
    .glue::SetRect(param_1 + 0x34,0,0xc,8,0x30);
    *(undefined2 *)(param_1 + 0x46) = 0;
    *(undefined2 *)(param_1 + 0x110) = 0;
    *(undefined2 *)(param_1 + 0xa4) = 0x38;
    puVar3 = _DAT_100a0850;
    puVar5 = _DAT_100a084c;
    if (*(short *)(param_1 + 4) == 0x773) {
      *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0850;
      puVar5 = puVar3;
    }
    else {
      *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a084c;
    }
  }
  else if (iVar4 == 0x77b) {
    puVar5 = (undefined4 *).glue::SetRect(param_1 + 0x34,0x20,0x20,0x50,0x38);
    *(undefined2 *)(param_1 + 0x110) = 0x140;
    *(undefined4 *)(param_1 + 0x15c) = 0;
    *(undefined4 *)(param_1 + 0x1f8) = 0;
  }
  else if (iVar4 == 0x46a) {
    *(undefined4 *)(param_1 + 0x80) = 8;
    .glue::SetRect(param_1 + 0x34,6,6,0x2a,0x1a);
    *(undefined2 *)(param_1 + 0x110) = 0;
    puVar5 = (undefined4 *).debug::_FastRand(5);
    *(short *)(param_1 + 0x46) = (short)puVar5;
    *(undefined1 *)(param_1 + 0x88) = 0;
  }
  else if (iVar4 == 0x46b) {
    *(undefined4 *)(param_1 + 0x80) = 8;
    .glue::SetRect(param_1 + 0x34,8,8,0x38,0x32);
    *(undefined2 *)(param_1 + 0x110) = 0;
    puVar5 = (undefined4 *).debug::_FastRand(5);
    *(short *)(param_1 + 0x46) = (short)puVar5;
    *(undefined1 *)(param_1 + 0x88) = 0;
  }
  else if (iVar4 == 0x46c) {
    *(undefined4 *)(param_1 + 0x80) = 8;
    .glue::SetRect(param_1 + 0x34,8,8,0x38,0x32);
    *(undefined2 *)(param_1 + 0x110) = 0;
    puVar5 = (undefined4 *).debug::_FastRand(5);
    *(short *)(param_1 + 0x46) = (short)puVar5;
    *(undefined1 *)(param_1 + 0x88) = 0;
  }
  else {
    puVar5 = (undefined4 *).glue::SetRect(param_1 + 0x34,8,8,0x10,0x10);
  }
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  return puVar5;
}


// ==== .HandleEnemyShotSprite @ 1005bffc ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleEnemyShotSprite(int param_1)

{
  short sVar1;
  bool bVar2;
  undefined *puVar3;
  undefined4 *puVar4;
  undefined4 *puVar5;
  int *piVar6;
  undefined4 *puVar7;
  uint uVar8;
  undefined4 uVar9;
  short sVar11;
  short sVar12;
  short sVar13;
  short sVar14;
  int iVar10;
  short sVar16;
  int iVar15;
  short sVar17;
  undefined4 uStack_48;
  undefined4 uStack_44;
  undefined4 uStack_40;
  
  puVar5 = _DAT_100a0070;
  puVar4 = _DAT_100a0058;
  puVar3 = PTR_DAT_1009fe78;
  bVar2 = false;
  sVar16 = 0;
  sVar14 = 0;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b2) == '\0')) {
    .debug::_StandardSpriteHandles(param_1);
    *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
    if ((0 < *(int *)(param_1 + 0x14c)) &&
       (*(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + -1, *(int *)(param_1 + 0x14c) == 0))
    {
      *(undefined1 *)(param_1 + 0xe9) = 1;
    }
    if (*(short *)(param_1 + 4) == 1) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1;
    }
    else if (*(short *)(param_1 + 4) == 0) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
    }
    puVar7 = _DAT_100a0860;
    sVar11 = *(short *)(param_1 + 4);
    if (sVar11 == 0x6a9) {
      *(undefined4 *)(param_1 + 0xc0) = 0;
    }
    else if (sVar11 == 0x6d6) {
      *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
      if (*(short *)(param_1 + 0xa6) < 1) {
        *(undefined1 *)(param_1 + 0xe9) = 1;
      }
    }
    else if (sVar11 == 0x6e1) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (*(short *)(param_1 + 0x46) < 8) {
        if (*(short *)(param_1 + 0x46) < 0) {
          *(undefined2 *)(param_1 + 0x46) = 7;
        }
      }
      else {
        *(undefined2 *)(param_1 + 0x46) = 0;
      }
      *(int *)(param_1 + 0xc0) = *_DAT_100a0884 + *(short *)(param_1 + 0x46) * 0x34;
    }
    else if (sVar11 == 0x6e2) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (*(short *)(param_1 + 0x46) < 8) {
        if (*(short *)(param_1 + 0x46) < 0) {
          *(undefined2 *)(param_1 + 0x46) = 7;
        }
      }
      else {
        *(undefined2 *)(param_1 + 0x46) = 0;
      }
      *(int *)(param_1 + 0xc0) = *_DAT_100a0880 + *(short *)(param_1 + 0x46) * 0x34;
    }
    else if (sVar11 == 0x6e6) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (*(short *)(param_1 + 0x46) < 8) {
        if (*(short *)(param_1 + 0x46) < 0) {
          *(undefined2 *)(param_1 + 0x46) = 7;
        }
      }
      else {
        *(undefined2 *)(param_1 + 0x46) = 0;
      }
      piVar6 = _DAT_100a087c;
      *(int *)(param_1 + 0x164) = *(int *)(param_1 + 0x164) + 1;
      *(int *)(param_1 + 0xc0) = *piVar6 + *(short *)(param_1 + 0x46) * 0x34;
    }
    else if (sVar11 == 0x6f4) {
      sVar11 = *(short *)(param_1 + 0xa6);
      if (sVar11 < 3) {
        *(undefined4 *)(param_1 + 0xb8) = 0xb0002;
      }
      else if (sVar11 < 5) {
        *(undefined4 *)(param_1 + 0xb8) = 0xb0000;
      }
      else if (sVar11 < 7) {
        *(undefined4 *)(param_1 + 0xb8) = 0xb0001;
      }
      else {
        *(undefined4 *)(param_1 + 0xb8) = 0;
      }
      if (*(short *)(param_1 + 0xa6) < 0x14) {
        uStack_40 = CONCAT22(*(short *)(param_1 + 10) + 0xc,*(short *)(param_1 + 0xc) + 0xc);
        uStack_44 = CONCAT22(*_DAT_1009fd90 + 8,*_DAT_1009fd94);
        uVar9 = .debug::_FindDesiredDirectionGeneric(uStack_44,uStack_40);
        FUN_1003f218(param_1,uVar9,0x8c);
      }
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (0xe < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0;
      }
      *(int *)(param_1 + 0xc0) = *_DAT_100a0868 + *(short *)(param_1 + 0x46) * 0x34;
    }
    else if (sVar11 == 0x709) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (5 < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0;
      }
      if (*(int *)(param_1 + 0x24) < 1) {
        *(int *)(param_1 + 0xc0) = *_DAT_100a0874 + *(short *)(param_1 + 0x46) * 0x34;
      }
      else {
        *(int *)(param_1 + 0xc0) = *_DAT_100a0878 + *(short *)(param_1 + 0x46) * 0x34;
      }
    }
    else if (sVar11 == 0x712) {
      *(undefined1 *)(param_1 + 0x88) = 0;
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (5 < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0;
      }
      if (*(int *)(param_1 + 0x24) < 1) {
        *(int *)(param_1 + 0xc0) = *_DAT_100a086c + *(short *)(param_1 + 0x46) * 0x34;
      }
      else {
        *(int *)(param_1 + 0xc0) = *_DAT_100a0870 + *(short *)(param_1 + 0x46) * 0x34;
      }
    }
    else if (sVar11 == 0x71f) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (0xf < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0;
      }
      piVar6 = _DAT_100a085c;
      *(byte *)(param_1 + 0x17e) =
           (*(int *)(param_1 + 0x24) == 0) -
           ((char)~(byte)((uint)*(int *)(param_1 + 0x24) >> 0x18) >> 7) & 1;
      *(int *)(param_1 + 0xc0) = *piVar6 + *(short *)(param_1 + 0x46) * 0x34;
    }
    else if (sVar11 == 0x753) {
      *(undefined2 *)(param_1 + 0x110) = 0x100;
      *(undefined4 *)(param_1 + 0xc0) = *puVar7;
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1;
      if (*(short *)(param_1 + 0x46) < 1) {
        *(undefined2 *)(param_1 + 0xaa) = 5;
        *(undefined2 *)(param_1 + 0x46) = 0x2d;
      }
      *(int *)(param_1 + 0x15c) = *(int *)(param_1 + 0x15c) + -1;
      if (*(int *)(param_1 + 0x15c) < 1) {
        .debug::_KillEnemyShot(param_1);
      }
      *(int *)(param_1 + 0x24) =
           (int)(((double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000) - dRam100a1a50
                 ) * dRam100a1a58);
      if (*(char *)(param_1 + 0xce) != '\0') {
        *(undefined4 *)(param_1 + 0x24) = 0;
      }
    }
    else if (sVar11 == 0x754) {
      *(int *)(param_1 + 0xc0) = *_DAT_100a0864 + *(short *)(param_1 + 0x46) * 0x34;
    }
    else if ((sVar11 < 0x76c) || (0x775 < sVar11)) {
      if (sVar11 == 0x77b) {
        if (*(int *)(param_1 + 0x15c) == 0) {
          *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        }
        else {
          *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1;
        }
        if (0xf < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        if (*(short *)(param_1 + 0x46) < 0) {
          *(undefined2 *)(param_1 + 0x46) = 0xf;
        }
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(_DAT_100a083c + *(short *)(param_1 + 0x46) * 4 + 4);
        uVar9 = *(undefined4 *)(*(int *)(param_1 + 0xc0) + 0xc);
        *(undefined4 *)(param_1 + 0x34) = *(undefined4 *)(*(int *)(param_1 + 0xc0) + 8);
        *(undefined4 *)(param_1 + 0x38) = uVar9;
        *(short *)(param_1 + 0x34) = *(short *)(param_1 + 0x34) + 4;
        *(short *)(param_1 + 0x36) = *(short *)(param_1 + 0x36) + 4;
        *(short *)(param_1 + 0x3a) = *(short *)(param_1 + 0x3a) + -4;
        *(short *)(param_1 + 0x38) = *(short *)(param_1 + 0x38) + -3;
        if (*(short *)(*(int *)*puVar4 + 0xb282) * 0x20 + 0x20 < (int)*(short *)(param_1 + 10)) {
          *(undefined1 *)(param_1 + 0xe9) = 1;
        }
      }
      else if (sVar11 == 0x46a) {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (5 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        bVar2 = true;
        sVar16 = 0x18;
        sVar14 = 0x18;
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(_DAT_100a0848 + *(short *)(param_1 + 0x46) * 4 + 4);
        if (*(short *)(*(int *)*puVar4 + 0x2722) == 0) {
          sVar11 = .debug::_FastRand(3);
          for (sVar17 = 0; sVar17 < (short)(sVar11 + 5); sVar17 = sVar17 + 1) {
            sVar12 = .debug::_FastRand(0x24);
            uVar9 = *(undefined4 *)(param_1 + 0x24);
            sVar1 = *(short *)(param_1 + 0xc);
            sVar13 = .debug::_FastRand(0x24);
            uStack_48 = CONCAT22(*(short *)(param_1 + 10) +
                                 (short)((uint)*(undefined4 *)(param_1 + 0x2c) >> 8) + 6 + sVar13,
                                 sVar1 + (short)((uint)uVar9 >> 8) + 6 + sVar12);
            iVar15 = .debug::_FastRand(2);
            .debug::_NewParticle(1,0xbe,uStack_48,iVar15 + 1,0,0,0,1);
          }
        }
      }
      else if (sVar11 == 0x46b) {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (5 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(_DAT_100a0844 + *(short *)(param_1 + 0x46) * 4 + 4);
      }
      else if (sVar11 == 0x46c) {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (5 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(_DAT_100a0840 + *(short *)(param_1 + 0x46) * 4 + 4);
      }
      else {
        if (*(short *)(param_1 + 0x46) < 8) {
          if (*(short *)(param_1 + 0x46) < 0) {
            *(undefined2 *)(param_1 + 0x46) = 7;
          }
        }
        else {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        *(int *)(param_1 + 0xc0) = *_DAT_100a0888 + *(short *)(param_1 + 0x46) * 0x34;
      }
    }
    .debug::_ApplyGravityAndSeparateFromTiles(param_1);
    if (0 < *(int *)(param_1 + 0x154)) {
      *(int *)(param_1 + 0x154) = *(int *)(param_1 + 0x154) + -1;
    }
    if ((int)*(short *)(*(int *)*puVar4 + 0xb282) << 5 < (int)*(short *)(param_1 + 10)) {
      *(undefined1 *)(param_1 + 0xe9) = 1;
    }
    .debug::_StandardSpriteCleanup(param_1);
    if ((bVar2) && (*(short *)(*(int *)*puVar4 + 0x2722) != 0)) {
      sVar16 = (*(short *)(param_1 + 0xc) + sVar16) - *(short *)(puVar3 + 2);
      iVar15 = (int)sVar16;
      uVar8 = ((int)*(short *)(param_1 + 10) + (int)sVar14) - (int)*(short *)puVar3;
      sVar14 = (short)((int)uVar8 >> 2) + (ushort)((int)uVar8 < 0 && (uVar8 & 3) != 0);
      if ((-1 < sVar16) && (((iVar15 < 0x270 && (-1 < sVar14)) && (sVar14 < 0x5e)))) {
        for (sVar16 = 0; sVar16 < 0x1a; sVar16 = sVar16 + 1) {
          iVar10 = .debug::_FastRand(0x18);
          .debug::_FlameAddSpark(*puVar5,(int)(short)iVar15,(int)sVar14,iVar10 + 0xe6);
          iVar10 = .debug::_FastRand(0x18);
          .debug::_FlameAddSpark(*puVar5,(int)(short)iVar15,(int)(short)(sVar14 + 1),iVar10 + 0xe6);
          iVar15 = iVar15 + 1;
        }
      }
    }
    if ((int)*(short *)(puVar3 + 2) - (int)*(short *)(param_1 + 0xc) < 0x3e9) {
      if (1000 < (int)*(short *)(param_1 + 0xc) - (*(short *)(puVar3 + 2) + 0x280)) {
        *(undefined1 *)(param_1 + 0xe9) = 1;
      }
    }
    else {
      *(undefined1 *)(param_1 + 0xe9) = 1;
    }
  }
  return;
}


// ==== .HitEnemyShotSprite @ 1005c9a8 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitEnemyShotSprite(int param_1,int param_2)

{
  short sVar1;
  undefined *puVar2;
  short sStack_14;
  short sStack_12;
  
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b2) == '\0')) {
    puVar2 = *(undefined **)(param_2 + 0x4c);
    if ((((((puVar2 == PTR_PTR_100a052c) &&
           (((sVar1 = *(short *)(param_1 + 4), sVar1 != 0x6e6 && (sVar1 != 0x709)) &&
            (sVar1 != 0x712)))) && (((sVar1 < 0x76c || (0x775 < sVar1)) && (sVar1 != 0x6f4)))) &&
         (((sVar1 != 0x753 && (sVar1 != 0x754)) &&
          ((sVar1 != 0x71f && (((sVar1 != 0 && (sVar1 != 1)) && (sVar1 != 0x77b)))))))) &&
        (((sVar1 != 0x46a && (sVar1 != 0x46b)) && (sVar1 != 0x46c)))) ||
       ((((sVar1 = *(short *)(param_1 + 4), sVar1 == 0x6e1 || (sVar1 == 0x6e2)) || (sVar1 == 0x753))
        && (puVar2 == PTR_PTR_100a04e8)))) {
      sVar1 = *(short *)(param_1 + 4);
      if (((sVar1 != 1) && (sVar1 != 0x6a9)) && (sVar1 != 0x6d6)) {
        .debug::_KillEnemyShot(param_1);
      }
    }
    else if ((puVar2 == _DAT_100a0200) && (*(short *)(param_2 + 4) == 0x584)) {
      .debug::_PlatformBounce(param_1,param_2,0,0,param_1 + 0x34,0);
    }
    else if (((puVar2 == PTR_PTR_100a01f8) ||
             ((puVar2 == PTR_PTR_100a0484 &&
              ((*(short *)(param_2 + 4) < 0x5aa || (0x5b3 < *(short *)(param_2 + 4))))))) &&
            (*(int *)(param_1 + 0x16c) == 0)) {
      if ((*(char *)(param_2 + 0x185) == '\0') && (*(int *)(param_2 + 0x1e8) == 0)) {
        if (sVar1 != 0x6e6) {
          .debug::_KillEnemyShot(param_1);
        }
      }
      else {
        sStack_12 = *(short *)(param_1 + 0x36) +
                    (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
        sStack_14 = *(short *)(param_1 + 0x34) +
                    (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
        if ((*(short *)(param_1 + 4) != 0x6e6) &&
           (sVar1 = .debug::_PlatformBounce(param_1,param_2,&sStack_14,0,param_1 + 0x34,0),
           sVar1 != 0)) {
          .debug::_KillEnemyShot(param_1);
        }
      }
    }
  }
  return;
}


// ==== .HitEnemyShotTileSprite @ 1005d034 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitEnemyShotTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  bool bVar1;
  undefined4 *puVar2;
  char cVar4;
  int iVar3;
  short sStack_48;
  short sStack_46;
  undefined1 auStack_28 [24];
  
  puVar2 = _DAT_100a03ac;
  if (*(int *)(param_1 + 0x16c) == 0) {
    sStack_46 = *(short *)(param_1 + 0x36) +
                (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
    sStack_48 = *(short *)(param_1 + 0x34) +
                (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
    if ((*_DAT_100a0064 == '\0') || (cVar4 = .debug::_IsPressed(0x32), cVar4 == '\0')) {
      .glue::SetRect(auStack_28,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                     (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
      if (param_4 == 1) {
        if (*(int *)(param_1 + 0x154) == 0) {
          iVar3 = *(int *)(param_1 + 0x24);
          bVar1 = true;
          if (iVar3 < 1) {
            iVar3 = -iVar3;
          }
          if (iVar3 < 0x1195) {
            iVar3 = *(int *)(param_1 + 0x2c);
            if (iVar3 < 1) {
              iVar3 = -iVar3;
            }
            if (iVar3 < 0x1965) {
              bVar1 = false;
            }
          }
          cVar4 = .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,0xa0,
                                      param_1 + 0x34,0,1);
          if (cVar4 != '\0') {
            if (*(short *)(param_1 + 4) == 0x753) {
              iVar3 = *(int *)(param_1 + 0x2c);
              if (iVar3 < 1) {
                iVar3 = -iVar3;
              }
              if (iVar3 < 300) {
                *(undefined4 *)(param_1 + 0x2c) = 0;
                *(undefined2 *)(param_1 + 0x110) = 0x200;
                *(undefined4 *)(param_1 + 0x24) = 0;
              }
            }
            else {
              if (((int)*(short *)(param_1 + 4) - 0x6e1U & 0xffff) < 2) {
                .debug::_STPlay3DSoundRand(*puVar2,1,0x55,*(undefined4 *)(param_1 + 0xe));
              }
              if (*(int *)(param_1 + 0x154) == 0) {
                *(int *)(param_1 + 0x150) = *(int *)(param_1 + 0x150) + 1;
              }
              *(undefined4 *)(param_1 + 0x154) = 1;
              if ((-1 < *(int *)(param_1 + 0x150)) || (bVar1)) {
                .debug::_KillEnemyShot(param_1);
              }
            }
          }
        }
      }
      else if ((*(short *)(param_1 + 4) < 0x46a) || (0x46f < *(short *)(param_1 + 4))) {
        if ((short)param_3 < 100) {
          iVar3 = *(int *)(param_1 + 0x24);
          bVar1 = true;
          if (iVar3 < 1) {
            iVar3 = -iVar3;
          }
          if (iVar3 < 0x1195) {
            iVar3 = *(int *)(param_1 + 0x2c);
            if (iVar3 < 1) {
              iVar3 = -iVar3;
            }
            if (iVar3 < 0x1965) {
              bVar1 = false;
            }
          }
          cVar4 = .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,0xa0,
                                      param_1 + 0x34,0,1);
          if (cVar4 != '\0') {
            if (*(short *)(param_1 + 4) == 0x753) {
              iVar3 = *(int *)(param_1 + 0x2c);
              if (iVar3 < 1) {
                iVar3 = -iVar3;
              }
              if (iVar3 < 300) {
                *(undefined4 *)(param_1 + 0x2c) = 0;
                *(undefined2 *)(param_1 + 0x110) = 0x200;
                *(undefined4 *)(param_1 + 0x24) = 0;
              }
            }
            else {
              if (((int)*(short *)(param_1 + 4) - 0x6e1U & 0xffff) < 2) {
                .debug::_STPlay3DSoundRand(*puVar2,1,0x55,*(undefined4 *)(param_1 + 0xe));
              }
              if (*(int *)(param_1 + 0x154) == 0) {
                *(int *)(param_1 + 0x150) = *(int *)(param_1 + 0x150) + 1;
              }
              *(undefined4 *)(param_1 + 0x154) = 1;
              if ((-1 < *(int *)(param_1 + 0x150)) || (bVar1)) {
                .debug::_KillEnemyShot(param_1);
              }
            }
          }
        }
        else if ((short)param_3 < 200) {
          iVar3 = *(int *)(param_1 + 0x24);
          bVar1 = true;
          if (iVar3 < 1) {
            iVar3 = -iVar3;
          }
          if (iVar3 < 0x1195) {
            iVar3 = *(int *)(param_1 + 0x2c);
            if (iVar3 < 1) {
              iVar3 = -iVar3;
            }
            if (iVar3 < 0x1965) {
              bVar1 = false;
            }
          }
          .debug::_WallBounceBG
                    (param_1,param_3 + -100,&stack0x0000001c,&sStack_48,0xa0,param_1 + 0x34,0,1);
          if (*(short *)(param_1 + 4) == 0x753) {
            iVar3 = *(int *)(param_1 + 0x2c);
            if (iVar3 < 1) {
              iVar3 = -iVar3;
            }
            if (iVar3 < 300) {
              *(undefined4 *)(param_1 + 0x2c) = 0;
              *(undefined2 *)(param_1 + 0x110) = 0x200;
              *(undefined4 *)(param_1 + 0x24) = 0;
            }
          }
          else {
            if (((int)*(short *)(param_1 + 4) - 0x6e1U & 0xffff) < 2) {
              .debug::_STPlay3DSoundRand(*puVar2,1,0x55,*(undefined4 *)(param_1 + 0xe));
            }
            if (*(int *)(param_1 + 0x154) == 0) {
              *(int *)(param_1 + 0x150) = *(int *)(param_1 + 0x150) + 1;
            }
            *(undefined4 *)(param_1 + 0x154) = 1;
            if ((-1 < *(int *)(param_1 + 0x150)) || (bVar1)) {
              .debug::_KillEnemyShot(param_1);
            }
          }
        }
        else {
          cVar4 = .debug::_IsWaterTile(param_3);
          if ((cVar4 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
            .debug::_HandleUnderWater(param_1,param_2);
          }
        }
      }
    }
  }
  return;
}


// ==== .SetupBonusSprite @ 1005d988 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupBonusSprite(int param_1)

{
  char *pcVar1;
  int *piVar2;
  undefined4 *puVar3;
  undefined *puVar4;
  int iVar5;
  int iVar6;
  undefined4 *puVar7;
  undefined *puVar8;
  undefined *puVar9;
  undefined *puVar10;
  undefined *puVar11;
  undefined4 *puVar12;
  int iVar13;
  char cVar17;
  int iVar14;
  undefined2 uVar15;
  short sVar16;
  uint uVar18;
  undefined4 uVar19;
  undefined4 uStack_38;
  undefined4 uStack_34;
  undefined4 uStack_30;
  undefined4 uStack_2c;
  undefined4 uStack_28;
  
  puVar12 = _DAT_100a08c0;
  puVar11 = PTR_PTR_100a0898;
  puVar8 = PTR_DAT_100a088c;
  puVar7 = _DAT_100a07fc;
  puVar3 = _DAT_100a0058;
  pcVar1 = _DAT_1009fe8c;
  iVar14 = _DAT_1009fe44;
  .debug::_InitSprite();
  puVar4 = PTR_PTR_100a047c;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar10 = PTR_PTR_100a0894;
  *(undefined2 *)(param_1 + 0x86) = 0;
  puVar9 = PTR_PTR_100a0890;
  *(undefined4 *)(param_1 + 0x80) = 1;
  *(undefined **)(param_1 + 0x4c) = puVar4;
  *(undefined **)(param_1 + 0x5c) = puVar11;
  *(undefined **)(param_1 + 0x1f8) = puVar10;
  *(undefined **)(param_1 + 0x50) = puVar9;
  *(undefined2 *)(param_1 + 0xa6) = 0;
  *(undefined2 *)(param_1 + 0x110) = 0x151;
  if (*(short *)(param_1 + 4) == 0x51a) {
    *(undefined2 *)(param_1 + 0x110) = 0x151;
  }
  *(undefined4 *)(param_1 + 0xc0) = 0;
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  *(undefined2 *)(param_1 + 0x9a) = 0xffff;
  iVar13 = (int)*(short *)(param_1 + 0x48);
  if ((-1 < iVar13) && (iVar13 < 0x1ff)) {
    *(int *)(param_1 + 0x168) = (int)*(short *)(*(int *)*puVar3 + iVar13 * 0x10 + 0xe);
  }
  sVar16 = *(short *)(param_1 + 4);
  if (sVar16 < 0x50e) {
    if (sVar16 == 0x423) {
      *(undefined1 *)(param_1 + 0x88) = 0;
      *(undefined1 *)(param_1 + 0x183) = 1;
      .glue::SetRect(param_1 + 0x34,0,0,0x60,0x60);
      *(undefined2 *)(param_1 + 0x110) = 0;
      *(undefined4 *)(param_1 + 0x5c) = 0;
      *(undefined4 *)(param_1 + 0x1f8) = 0;
      *(undefined4 *)(param_1 + 0xc0) = 0;
      if (*pcVar1 != '\0') {
        *(undefined1 *)(param_1 + 0x1b5) = 1;
        *_DAT_1009ffac = *_DAT_1009ffac + 1;
      }
      goto LAB_1005e8bc;
    }
    if (sVar16 < 0x423) {
      if (sVar16 < 0x41f) {
        if (sVar16 == 0x45) {
          .glue::SetRect(param_1 + 0x34,0x23,0x23,0x41,0x50);
          piVar2 = _DAT_100a0780;
          *(undefined1 *)(param_1 + 0x183) = 1;
          *(undefined4 *)(param_1 + 0xb8) = 0;
          *(int *)(param_1 + 0xc0) = *piVar2 + 0x9c;
          *(undefined2 *)(param_1 + 0xb0) = 0;
          *(undefined2 *)(param_1 + 0xa6) = 0;
          goto LAB_1005e8bc;
        }
      }
      else if (sVar16 != 0x421) {
        if (sVar16 < 0x421) {
          *(undefined1 *)(param_1 + 0x88) = 0;
          *(undefined1 *)(param_1 + 0x183) = 1;
          .glue::SetRect(param_1 + 0x34,2,0xfffffffc,0x12,0x10);
          uVar15 = .debug::_FastRand(0x13);
          *(undefined2 *)(param_1 + 0x46) = uVar15;
          sVar16 = .debug::_FastRand(6);
          *(short *)(param_1 + 0x112) = sVar16 + 0x1c;
          sVar16 = .debug::_FastRand(3);
          *(short *)(param_1 + 0x114) = sVar16 + 2;
          *(undefined2 *)(param_1 + 0x110) = 0;
          .debug::_GetBGTile((int)(short)(*(short *)(param_1 + 0xc) + 0x10 >> 5),
                             (int)(short)(*(short *)(param_1 + 10) + 0x10 >> 5));
          .debug::_LookupBGTileKind();
          cVar17 = .debug::_IsWaterTile();
          if (cVar17 == '\0') {
            *(undefined4 *)(param_1 + 0x15c) = 0;
          }
          else {
            *(undefined4 *)(param_1 + 0x15c) = 1;
          }
          if ((*(short *)(iVar14 + 6) == 1) && (*_DAT_100a0124 < 0x96)) {
            uStack_2c = CONCAT22(*(short *)(param_1 + 10) + 0x10,*(short *)(param_1 + 0xc) + 0x10);
            if (*(short *)(param_1 + 4) == 0x41f) {
              uVar15 = .debug::_AddLight(*puVar7,uStack_2c,0,0,0,0x16);
              *(undefined2 *)(param_1 + 0x9a) = uVar15;
            }
            else {
              uVar15 = .debug::_AddLight(*puVar7,uStack_2c,0,0,0,0x2c);
              *(undefined2 *)(param_1 + 0x9a) = uVar15;
            }
          }
          piVar2 = _DAT_1009ffb0;
          if (*pcVar1 != '\0') {
            *(undefined1 *)(param_1 + 0x1b5) = 1;
            *piVar2 = *piVar2 + 1;
          }
        }
        else {
          *(undefined1 *)(param_1 + 0x88) = 0;
          *(undefined1 *)(param_1 + 0x183) = 1;
          .glue::SetRect(param_1 + 0x34,0,0,0x60,0x60);
          *(undefined2 *)(param_1 + 0x110) = 0;
          *(undefined4 *)(param_1 + 0x5c) = 0;
          *(undefined4 *)(param_1 + 0x1f8) = 0;
          *(undefined4 *)(param_1 + 0xc0) = 0;
        }
        goto LAB_1005e8bc;
      }
    }
    else {
      if (0x509 < sVar16) {
        if (sVar16 < 0x50c) {
          if (*(short *)(iVar14 + 6) == 1) {
            uStack_30 = CONCAT22(*(short *)(param_1 + 10) + 0x10,*(short *)(param_1 + 0xc) + 10);
            if (sVar16 == 0x50a) {
              uVar15 = .debug::_AddLight(*puVar7,uStack_30,0,0,0,0x37);
              *(undefined2 *)(param_1 + 0x9a) = uVar15;
            }
            else {
              uVar15 = .debug::_AddLight(*puVar7,uStack_30,0,0,0,0x21);
              *(undefined2 *)(param_1 + 0x9a) = uVar15;
            }
          }
          iVar14 = (int)*(short *)(param_1 + 0x48);
          if (((iVar14 != -1) && (iVar14 != 0x1ff)) &&
             (*(short *)(*(int *)*puVar3 + iVar14 * 0x10 + 8) != 0)) {
            *(undefined2 *)(param_1 + 0x110) = 0;
          }
          *(undefined1 *)(param_1 + 0x88) = 0;
          *(undefined1 *)(param_1 + 0x183) = 1;
          .glue::SetRect(param_1 + 0x34,2,0xe,0x12,0x1e);
          uVar15 = .debug::_FastRand(10);
          *(undefined2 *)(param_1 + 0x46) = uVar15;
          sVar16 = .debug::_FastRand(6);
          *(short *)(param_1 + 0x112) = sVar16 + 0x1c;
          *(undefined2 *)(param_1 + 0x114) = 10;
        }
        else {
          if (*(short *)(iVar14 + 6) == 1) {
            uStack_34 = CONCAT22(*(short *)(param_1 + 10) + 0x10,*(short *)(param_1 + 0xc) + 0x10);
            uVar15 = .debug::_AddLight(*puVar7,uStack_34,0,0,0,99);
            *(undefined2 *)(param_1 + 0x9a) = uVar15;
          }
          *(undefined1 *)(param_1 + 0x88) = 0;
          *(undefined1 *)(param_1 + 0x183) = 1;
          if (*(short *)(param_1 + 4) == 0x50c) {
            .glue::SetRect(param_1 + 0x34,6,0xc,0x1a,0x12);
          }
          else {
            .glue::SetRect(param_1 + 0x34,2,0xc,0x1e,0x18);
          }
          sVar16 = .debug::_FastRand(10);
          *(short *)(param_1 + 0x46) = -5 - sVar16;
          *(undefined2 *)(param_1 + 0x112) = 0;
          *(undefined2 *)(param_1 + 0x114) = 0x32;
        }
        goto LAB_1005e8bc;
      }
      if ((sVar16 < 0x4c3) && (0x4be < sVar16)) {
        *(int *)(param_1 + 0x80) = *(int *)(*_DAT_1009fdd8 + 0x80) + 1;
        *(undefined2 *)(param_1 + 0x110) = 0x151;
        *(undefined2 *)(param_1 + 0xa6) = 0xffd8;
        .glue::SetRect(param_1 + 0x34,0,0xfffffffc,0x10,10);
        *(int *)(param_1 + 0xc0) = *_DAT_100a08ec + (*(short *)(param_1 + 4) + -0x4bf) * 0x34;
        goto LAB_1005e8bc;
      }
    }
  }
  else {
    if (sVar16 == 0x51b) {
      *(undefined1 *)(param_1 + 0x88) = 0;
      if (*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xe) == 0) {
        *(undefined2 *)(param_1 + 0xb0) = 1;
      }
      else {
        *(undefined2 *)(param_1 + 0xb0) = 0;
        *(undefined4 *)(param_1 + 0x5c) = 0;
      }
      .glue::SetRect(param_1 + 0x34,0xfffffffc,0xfffffffe,0xe,0x1e);
      *(undefined2 *)(param_1 + 0x110) = 0;
      uVar15 = .debug::_FastRand(10);
      *(undefined2 *)(param_1 + 0x46) = uVar15;
      *(undefined2 *)(param_1 + 300) = 1;
      uStack_28 = CONCAT22(*(short *)(param_1 + 10) + 8,*(short *)(param_1 + 0xc) + 5);
      if (*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xc) == 0) {
        uVar15 = 0x16;
      }
      else {
        uVar15 = 0x58;
      }
      uVar15 = .debug::_AddLight(*puVar12,uStack_28,0,0,0,uVar15);
      *(undefined2 *)(param_1 + 0x9a) = uVar15;
      goto LAB_1005e8bc;
    }
    if (sVar16 < 0x51b) {
      if (sVar16 == 0x517) {
        .glue::SetRect(param_1 + 0x34,2,0xfffffff8,0x1c,0xb);
        goto LAB_1005e8bc;
      }
      if (sVar16 < 0x517) {
        if (0x515 < sVar16) {
LAB_1005e02c:
          *(undefined1 *)(param_1 + 0x183) = 1;
          .glue::SetRect(param_1 + 0x34,2,0xfffffffc,8,7);
          uVar15 = .debug::_FastRand(9);
          *(undefined2 *)(param_1 + 0x46) = uVar15;
          sVar16 = .debug::_FastRand(6);
          *(short *)(param_1 + 0x112) = sVar16 + 0x1c;
          sVar16 = .debug::_FastRand(3);
          *(short *)(param_1 + 0x114) = sVar16 + 2;
          goto LAB_1005e8bc;
        }
        if (0x513 < sVar16) {
          if (*(short *)(iVar14 + 6) == 1) {
            uStack_38 = CONCAT22(*(short *)(param_1 + 10) + 0x10,*(short *)(param_1 + 0xc) + 10);
            if (sVar16 == 0x514) {
              uVar15 = .debug::_AddLight(*puVar7,uStack_38,0,0,0,0x37);
              *(undefined2 *)(param_1 + 0x9a) = uVar15;
            }
            else {
              uVar15 = .debug::_AddLight(*puVar7,uStack_38,0,0,0,0x21);
              *(undefined2 *)(param_1 + 0x9a) = uVar15;
            }
          }
          *(undefined1 *)(param_1 + 0x88) = 0;
          *(undefined1 *)(param_1 + 0x183) = 1;
          .glue::SetRect(param_1 + 0x34,2,0xfffffffc,0x12,0x10);
          uVar15 = .debug::_FastRand(4);
          *(undefined2 *)(param_1 + 0x46) = uVar15;
          sVar16 = .debug::_FastRand(6);
          *(short *)(param_1 + 0x112) = sVar16 + 0x1c;
          sVar16 = .debug::_FastRand(3);
          *(short *)(param_1 + 0x114) = sVar16 + 2;
          goto LAB_1005e8bc;
        }
      }
      else if (0x518 < sVar16) goto LAB_1005e02c;
    }
    else {
      if (sVar16 == 0xbea) {
        *(undefined2 *)(param_1 + 0x110) = 0;
        .glue::SetRect(param_1 + 0x34,0x47,0x44,0x5a,0x6d);
        puVar3 = _DAT_100a08a8;
        *(undefined1 *)(param_1 + 0x18b) = 1;
        iVar6 = _DAT_100a0778;
        *(undefined1 *)(param_1 + 0x188) = 1;
        iVar5 = _DAT_100a0774;
        iVar14 = _DAT_100a076c;
        *(undefined4 *)(param_1 + 0xc0) = *puVar3;
        iVar13 = _DAT_100a0770;
        *(undefined1 *)(iVar6 + 1) = 1;
        *(undefined1 *)(iVar5 + 1) = 1;
        *(undefined1 *)(iVar14 + 1) = 1;
        *(undefined1 *)(iVar13 + 1) = 1;
        goto LAB_1005e8bc;
      }
      if ((sVar16 < 0xbea) && (sVar16 == 0x546)) {
        *(undefined1 *)(param_1 + 0x88) = 0;
        .glue::SetRect(param_1 + 0x34,8,8,0x18,0x18);
        *(undefined2 *)(param_1 + 0x110) = 0;
        uVar15 = .debug::_FastRand(10);
        *(undefined2 *)(param_1 + 0x46) = uVar15;
        puVar3 = _DAT_100a08ac;
        *(undefined2 *)(param_1 + 300) = 1;
        *(undefined1 *)(param_1 + 0x188) = 1;
        *(undefined4 *)(param_1 + 0xc0) = *puVar3;
        goto LAB_1005e8bc;
      }
    }
  }
  *(undefined1 *)(param_1 + 0x183) = 1;
  *(undefined1 *)(param_1 + 0x88) = 0;
  *(undefined2 *)(param_1 + 0x110) = 200;
  puVar7 = _DAT_100a08f0;
  iVar14 = (int)*(short *)(param_1 + 4);
  if ((iVar14 < 0xc1c) || (0xc25 < iVar14)) {
    if ((iVar14 < 2000) || (0x833 < iVar14)) {
      if ((iVar14 < 0x532) || (0x53b < iVar14)) {
        if ((iVar14 - 0x53cU & 0xffff) < 2) {
          *(undefined2 *)(param_1 + 0x110) = 0;
          .glue::SetRect(param_1 + 0x34,4,8,0x28,0x1e);
          uStack_28 = CONCAT22(*(short *)(param_1 + 10) + 0x14,*(short *)(param_1 + 0xc) + 0x16);
          if (*(short *)(param_1 + 4) == 0x53d) {
            uVar15 = .debug::_AddLight(*(undefined4 *)puVar8,uStack_28,0,0,0,0x21);
            *(undefined2 *)(param_1 + 0x9a) = uVar15;
          }
          else if (*(short *)(param_1 + 4) == 0x53c) {
            uVar15 = .debug::_AddLight(*(undefined4 *)puVar8,uStack_28,0,0,0,0x4d);
            *(undefined2 *)(param_1 + 0x9a) = uVar15;
          }
          sVar16 = .debug::_FastRand(0x10);
          *(int *)(param_1 + 0x15c) = (int)sVar16;
        }
        else {
          uVar19 = 99;
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a08a0 + iVar14 * 4 + -0x3200);
          .glue::SetRect(param_1 + 0x34,4,4,0x1c,0x18);
          uStack_28 = CONCAT22(*(short *)(param_1 + 10) + 0xc,*(short *)(param_1 + 0xc) + 0x10);
          uVar15 = .debug::_FastRand(0x10);
          *(undefined2 *)(param_1 + 0x46) = uVar15;
          if ((*(short *)(param_1 + 4) == 0xc86) || (*(short *)(param_1 + 4) == 0xc9a)) {
            *(short *)(param_1 + 0x34) = *(short *)(param_1 + 0x34) + 6;
          }
          if (*(short *)(param_1 + 4) < 0xc84) {
            *(short *)(param_1 + 0x38) = *(short *)(param_1 + 0x38) + -6;
          }
          iVar14 = (int)*(short *)(param_1 + 4);
          if ((((iVar14 == 0xc87) || (iVar14 == 0xc88)) || ((iVar14 - 0xc8bU & 0xffff) < 5)) ||
             ((iVar14 == 0xc99 || ((iVar14 - 0xc93U & 0xffff) < 2)))) {
            *(undefined2 *)(param_1 + 0x38) = 0x1f;
            *(short *)(param_1 + 0x34) = *(short *)(param_1 + 0x34) + 7;
          }
          iVar14 = (int)*(short *)(param_1 + 4);
          if (((iVar14 == 0xc92) || (iVar14 == 0xc95)) || ((iVar14 - 0xc97U & 0xffff) < 2)) {
            *(short *)(param_1 + 0x34) = *(short *)(param_1 + 0x34) + 0xd;
            *(undefined2 *)(param_1 + 0x38) = 0x26;
          }
          iVar14 = (int)*(short *)(param_1 + 4);
          if ((iVar14 == 0xc97) || ((iVar14 - 0xc99U & 0xffff) < 2)) {
            uVar19 = 0x21;
          }
          if ((iVar14 == 0xc86) || (iVar14 == 0xc98)) {
            uVar19 = 0x2c;
          }
          if (iVar14 == 0xc93) {
            uVar19 = 0x4d;
          }
          uVar15 = .debug::_AddLight(*(undefined4 *)puVar8,uStack_28,0,0,0,uVar19);
          *(undefined2 *)(param_1 + 0x9a) = uVar15;
          *(undefined2 *)(param_1 + 0x114) = 6;
          uVar18 = (uint)*(short *)(param_1 + 4);
          if (((((int)uVar18 >> 0x1f) + (uint)(0xc7f < uVar18) &
               (uint)(0xcb1 < uVar18) - ((int)~uVar18 >> 0x1f) & 1) != 0) &&
             (*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 8) != 0)) {
            *(undefined2 *)(param_1 + 0x110) = 0;
          }
        }
      }
      else {
        *(undefined4 *)(param_1 + 0xc0) = 0;
        .glue::SetRect(param_1 + 0x34,0,0,0x20,0x1b);
        uStack_28 = CONCAT22(*(short *)(param_1 + 10) + 0x10,*(short *)(param_1 + 0xc) + 0x10);
        uVar15 = .debug::_AddLight(*(undefined4 *)puVar8,uStack_28,0,0,0,99);
        *(undefined2 *)(param_1 + 0x9a) = uVar15;
        uVar15 = .debug::_FastRand(0x10);
        *(undefined2 *)(param_1 + 0x46) = uVar15;
        if (*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 8) != 0) {
          *(undefined2 *)(param_1 + 0x110) = 0;
        }
      }
    }
    else {
      *(undefined2 *)(param_1 + 0x110) = 0;
      *(undefined4 *)(param_1 + 0xc0) = *puVar7;
      .glue::SetRect(param_1 + 0x34,4,4,0x1c,0x1c);
      uStack_28 = CONCAT22(*(short *)(param_1 + 10) + 0xc,*(short *)(param_1 + 0xc) + 0x10);
      uVar15 = .debug::_AddLight(*(undefined4 *)puVar8,uStack_28,0,0,0,99);
      *(undefined2 *)(param_1 + 0x9a) = uVar15;
      uVar15 = .debug::_FastRand(0x10);
      *(undefined2 *)(param_1 + 0x46) = uVar15;
      if (*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 8) != 0) {
        *(undefined2 *)(param_1 + 0x110) = 0;
      }
    }
  }
  else {
    *(undefined2 *)(param_1 + 0xb0) = 1;
    iVar14 = _DAT_100a08a4;
    uVar19 = 99;
    *(undefined1 *)(param_1 + 0x183) = 0;
    *(undefined2 *)(param_1 + 0x110) = 0;
    *(undefined **)(param_1 + 0x5c) = puVar11;
    *(undefined4 *)(param_1 + 0x1f8) = 0;
    *(undefined4 *)(param_1 + 0xc0) =
         *(undefined4 *)(iVar14 + *(short *)(param_1 + 4) * 4 + -0x3070);
    if (*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xe) == 0) {
      *(undefined2 *)(param_1 + 0xb0) = 1;
    }
    else {
      *(undefined2 *)(param_1 + 0xb0) = 0;
      *(undefined4 *)(param_1 + 0x5c) = 0;
    }
    switch(*(undefined2 *)(param_1 + 4)) {
    case 0xc1c:
      uStack_28 = CONCAT22(*(short *)(param_1 + 10) + 0x10,*(short *)(param_1 + 0xc) + 0xf);
      break;
    case 0xc1d:
      uStack_28 = CONCAT22(*(short *)(param_1 + 10) + 0xf,*(short *)(param_1 + 0xc) + 0x12);
      break;
    case 0xc1e:
      uStack_28 = CONCAT22(*(short *)(param_1 + 10) + 8,*(short *)(param_1 + 0xc) + 0x11);
      break;
    case 0xc1f:
      uVar19 = 0x4d;
      uStack_28 = CONCAT22(*(short *)(param_1 + 10) + 8,*(short *)(param_1 + 0xc) + 0xf);
      break;
    case 0xc20:
      uStack_28 = CONCAT22(*(short *)(param_1 + 10) + 9,*(short *)(param_1 + 0xc) + 0x14);
      break;
    case 0xc21:
      uStack_28 = CONCAT22(*(short *)(param_1 + 10) + 9,*(short *)(param_1 + 0xc) + 0x14);
      break;
    case 0xc22:
      uStack_28 = CONCAT22(*(short *)(param_1 + 10) + 7,*(short *)(param_1 + 0xc) + 0x13);
      break;
    case 0xc23:
      uVar19 = 0x37;
      uStack_28 = CONCAT22(*(short *)(param_1 + 10) + 0x1a,*(short *)(param_1 + 0xc) + 0x13);
      break;
    case 0xc24:
      uVar19 = 0x42;
      uStack_28 = CONCAT22(*(short *)(param_1 + 10) + 0x18,*(short *)(param_1 + 0xc) + 0x13);
    }
    .glue::SetRect(param_1 + 0x34,(uStack_28._2_2_ + -8) - (int)*(short *)(param_1 + 0xc),
                   (uStack_28._0_2_ + -8) - (int)*(short *)(param_1 + 10),
                   (uStack_28._2_2_ + 8) - (int)*(short *)(param_1 + 0xc),
                   (uStack_28._0_2_ + 8) - (int)*(short *)(param_1 + 10));
    uVar15 = .debug::_AddLight(*puVar12,uStack_28,0,0,0,uVar19);
    *(undefined2 *)(param_1 + 0x9a) = uVar15;
    uVar15 = .debug::_FastRand(0x10);
    *(undefined2 *)(param_1 + 0x46) = uVar15;
  }
LAB_1005e8bc:
  sVar16 = .debug::_FastRand(0x3c);
  *(int *)(param_1 + 0x14c) = (int)sVar16;
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  .debug::_CalcCenterPos(param_1);
  *(undefined1 *)(param_1 + 0xe4) = 1;
  return;
}


// ==== .HandleBonusSprite @ 1005e934 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleBonusSprite(int param_1)

{
  char *pcVar1;
  undefined *puVar2;
  short sVar3;
  short sVar8;
  int iVar4;
  int iVar5;
  undefined4 uVar6;
  int iVar7;
  int iVar9;
  short sVar10;
  short sVar11;
  undefined4 uStack_3c;
  undefined4 uStack_36;
  undefined4 uStack_32;
  undefined4 uStack_2e;
  undefined4 uStack_2a;
  undefined4 uStack_26;
  
  puVar2 = PTR_DAT_100a088c;
  iVar7 = _DAT_1009fe44;
  if (*(char *)(param_1 + 0xe9) != '\0') {
    return;
  }
  if (*(char *)(param_1 + 0x1b2) != '\0') {
    return;
  }
  .debug::_StandardSpriteHandles(param_1);
  if (*(short *)(param_1 + 0xa6) < 0) {
    *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
  }
  sVar3 = *(short *)(param_1 + 4);
  if (sVar3 < 0x514) {
    if (sVar3 < 0x4bf) {
      if (sVar3 < 0x421) {
        if (sVar3 == 0x45) {
          return;
        }
        if ((0x44 < sVar3) && (0x41e < sVar3)) {
          .glue::SetRect(param_1 + 0x34,2,2,0x1e,0x1e);
          *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
          if (0x13 < *(short *)(param_1 + 0x46)) {
            *(undefined2 *)(param_1 + 0x46) = 0;
          }
          *(int *)(param_1 + 0xc0) =
               *(int *)PTR_DAT_100a0478 + ((int)*(short *)(param_1 + 0x46) >> 1) * 0x34;
          if (*(int *)(param_1 + 0x15c) != 0) {
            *(undefined4 *)(param_1 + 0x120) = 1;
            *(undefined4 *)(param_1 + 0x11c) = 1;
          }
          if (*(short *)(param_1 + 4) == 0x420) {
            *(undefined4 *)(param_1 + 0xb8) = 0x10001;
          }
          goto LAB_1005fc30;
        }
      }
      else if (sVar3 == 0x423) goto LAB_1005fc30;
    }
    else {
      if (sVar3 == 0x50b) {
        if (0 < *(short *)(param_1 + 0xb0)) {
          *(short *)(param_1 + 0xb0) = *(short *)(param_1 + 0xb0) + -1;
        }
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (10 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        sVar3 = *(short *)(param_1 + 0x46);
        if (sVar3 < 4) {
          if (sVar3 < 2) {
            if (sVar3 < 0) goto LAB_1005ecc0;
            *(undefined4 *)(param_1 + 0xb8) = 0;
          }
          else {
            *(undefined4 *)(param_1 + 0xb8) = 0x10008;
          }
        }
        else if (sVar3 < 8) {
          if (sVar3 < 6) {
            *(undefined4 *)(param_1 + 0xb8) = 0x10009;
          }
          else {
            *(undefined4 *)(param_1 + 0xb8) = 0x10008;
          }
        }
        else {
LAB_1005ecc0:
          *(undefined4 *)(param_1 + 0xb8) = 0;
        }
        *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a08e4;
        goto LAB_1005fc30;
      }
      if (sVar3 < 0x50b) {
        if (0x509 < sVar3) {
          if (0 < *(short *)(param_1 + 0xb0)) {
            *(short *)(param_1 + 0xb0) = *(short *)(param_1 + 0xb0) + -1;
          }
          *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
          if (10 < *(short *)(param_1 + 0x46)) {
            *(undefined2 *)(param_1 + 0x46) = 0;
          }
          sVar3 = *(short *)(param_1 + 0x46);
          if (sVar3 < 4) {
            if (sVar3 < 2) {
              if (sVar3 < 0) goto LAB_1005ec04;
              *(undefined4 *)(param_1 + 0xb8) = 0;
            }
            else {
              *(undefined4 *)(param_1 + 0xb8) = 0x10008;
            }
          }
          else if (sVar3 < 8) {
            if (sVar3 < 6) {
              *(undefined4 *)(param_1 + 0xb8) = 0x10009;
            }
            else {
              *(undefined4 *)(param_1 + 0xb8) = 0x10008;
            }
          }
          else {
LAB_1005ec04:
            *(undefined4 *)(param_1 + 0xb8) = 0;
          }
          *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a08e8;
          goto LAB_1005fc30;
        }
        if (sVar3 < 0x4c3) {
          *(undefined1 *)(param_1 + 0x88) = 0;
          if (-0xd < *(short *)(param_1 + 0xa6)) {
            *(undefined4 *)(param_1 + 0xb8) = 0xb0001;
          }
          if (-9 < *(short *)(param_1 + 0xa6)) {
            *(undefined4 *)(param_1 + 0xb8) = 0xb0000;
          }
          if (-5 < *(short *)(param_1 + 0xa6)) {
            *(undefined4 *)(param_1 + 0xb8) = 0xb0002;
          }
          if (-1 < *(short *)(param_1 + 0xa6)) {
            *(undefined4 *)(param_1 + 0xb8) = 0;
            *(undefined4 *)(param_1 + 0xc0) = 0;
            if (*(char *)(param_1 + 0xe9) == '\0') {
              *(undefined1 *)(param_1 + 0xe9) = 1;
            }
          }
          goto LAB_1005fc30;
        }
      }
      else {
        if (sVar3 == 0x50d) {
          if (0 < *(short *)(param_1 + 0xb0)) {
            *(short *)(param_1 + 0xb0) = *(short *)(param_1 + 0xb0) + -1;
          }
          *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
          if (0x28 < *(short *)(param_1 + 0x46)) {
            *(undefined2 *)(param_1 + 0x46) = 0;
          }
          sVar3 = *(short *)(param_1 + 0x46);
          if (sVar3 < 4) {
            if (sVar3 < 2) {
              if (sVar3 < 0) goto LAB_1005ee38;
              *(undefined4 *)(param_1 + 0xb8) = 0;
            }
            else {
              *(undefined4 *)(param_1 + 0xb8) = 0x10008;
            }
          }
          else if (sVar3 < 8) {
            if (sVar3 < 6) {
              *(undefined4 *)(param_1 + 0xb8) = 0x10009;
            }
            else {
              *(undefined4 *)(param_1 + 0xb8) = 0x10008;
            }
          }
          else {
LAB_1005ee38:
            *(undefined4 *)(param_1 + 0xb8) = 0;
          }
          *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a08dc;
          goto LAB_1005fc30;
        }
        if (sVar3 < 0x50d) {
          if (0 < *(short *)(param_1 + 0xb0)) {
            *(short *)(param_1 + 0xb0) = *(short *)(param_1 + 0xb0) + -1;
          }
          *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
          if (0x28 < *(short *)(param_1 + 0x46)) {
            *(undefined2 *)(param_1 + 0x46) = 0;
          }
          sVar3 = *(short *)(param_1 + 0x46);
          if (sVar3 < 4) {
            if (sVar3 < 2) {
              if (sVar3 < 0) goto LAB_1005ed7c;
              *(undefined4 *)(param_1 + 0xb8) = 0;
            }
            else {
              *(undefined4 *)(param_1 + 0xb8) = 0x10008;
            }
          }
          else if (sVar3 < 8) {
            if (sVar3 < 6) {
              *(undefined4 *)(param_1 + 0xb8) = 0x10009;
            }
            else {
              *(undefined4 *)(param_1 + 0xb8) = 0x10008;
            }
          }
          else {
LAB_1005ed7c:
            *(undefined4 *)(param_1 + 0xb8) = 0;
          }
          *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a08e0;
          goto LAB_1005fc30;
        }
      }
    }
  }
  else {
    if (sVar3 == 0x546) {
      *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a08ac;
      *(undefined4 *)(param_1 + 0x11c) = 1;
      goto LAB_1005fc30;
    }
    if (sVar3 < 0x546) {
      if (sVar3 != 0x518) {
        if (sVar3 < 0x518) {
          if (sVar3 != 0x516) {
            if (sVar3 < 0x516) {
              *(undefined2 *)(param_1 + 0xa6) = 0;
              *(undefined2 *)(param_1 + 0xb0) = 0;
              *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
              if (5 < *(short *)(param_1 + 0x46)) {
                *(undefined2 *)(param_1 + 0x46) = 0;
              }
              if (*(short *)(param_1 + 4) == 0x514) {
                *(int *)(param_1 + 0xc0) = *_DAT_100a08d8 + *(short *)(param_1 + 0x46) * 0x34;
              }
              else {
                *(int *)(param_1 + 0xc0) = *_DAT_100a08d4 + *(short *)(param_1 + 0x46) * 0x34;
              }
            }
            else {
              *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)PTR_DAT_100a08f4;
            }
            goto LAB_1005fc30;
          }
        }
        else {
          if (sVar3 == 0x51b) goto LAB_1005f00c;
          if (0x51a < sVar3) goto LAB_1005f808;
        }
        if (0 < *(short *)(param_1 + 0xb0)) {
          *(short *)(param_1 + 0xb0) = *(short *)(param_1 + 0xb0) + -1;
        }
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (0x11 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        sVar3 = *(short *)(param_1 + 4);
        if (sVar3 == 0x516) {
          *(int *)(param_1 + 0xc0) = *_DAT_100a08d0 + ((int)*(short *)(param_1 + 0x46) >> 1) * 0x34;
        }
        else if (sVar3 == 0x519) {
          *(int *)(param_1 + 0xc0) = *_DAT_100a08cc + ((int)*(short *)(param_1 + 0x46) >> 1) * 0x34;
        }
        else if (sVar3 == 0x51a) {
          *(int *)(param_1 + 0xc0) = *_DAT_100a08c8 + ((int)*(short *)(param_1 + 0x46) >> 1) * 0x34;
        }
        if ((int)*(short *)(*(int *)*_DAT_100a0058 + 0xb282) << 5 < (int)*(short *)(param_1 + 10)) {
          .debug::_KillBonus(param_1);
        }
        if (*(int *)(param_1 + 0x16c) < 0) {
          *(int *)(param_1 + 0x16c) = *(int *)(param_1 + 0x16c) + 1;
          pcVar1 = _DAT_1009fd30;
          if (-0x2d < *(int *)(param_1 + 0x16c)) {
            *(undefined1 *)(param_1 + 0x88) = 0;
            if (*pcVar1 == '\0') {
              *(undefined4 *)(param_1 + 0xb8) = 0;
            }
            else {
              *(undefined4 *)(param_1 + 0xb8) = 0xb0000;
            }
          }
          if (-1 < *(int *)(param_1 + 0x16c)) {
            .debug::_KillBonus(param_1);
          }
        }
        goto LAB_1005fc30;
      }
    }
    else if (sVar3 < 0xc1c) {
      if (sVar3 == 0xbea) {
        *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a08a8;
        goto LAB_1005fc30;
      }
    }
    else if (sVar3 < 0xc26) {
LAB_1005f00c:
      sVar11 = 1;
      uStack_2a = uRam100a1a60;
      uStack_2e = uRam100a1a64;
      uStack_32 = uRam100a1a68;
      uStack_36 = uRam100a1a6c;
      sVar3 = .debug::_FastRand(100);
      uStack_26 = *(undefined4 *)(param_1 + 0xe);
      switch(*(undefined2 *)(param_1 + 4)) {
      case 0xc1c:
        sVar8 = *(short *)(param_1 + 0xc);
        sVar10 = *(short *)(param_1 + 10);
        uStack_2a = CONCAT22(sVar10 + 0x17,sVar8 + 6);
        uStack_2e = CONCAT22(sVar10 + 0x10,sVar8 + 0xd);
        uStack_32 = CONCAT22(sVar10 + 0x10,sVar8 + 0x13);
        uStack_36 = CONCAT22(sVar10 + 0x16,sVar8 + 0x19);
        if (sVar3 < 0x4c) {
          if (sVar3 < 0x33) {
            if (sVar3 < 0x1a) {
              uStack_26 = uStack_36;
            }
            else {
              uStack_26 = uStack_32;
            }
          }
          else {
            uStack_26 = uStack_2e;
          }
        }
        else {
          uStack_26 = uStack_2a;
        }
        break;
      case 0xc1d:
        sVar8 = *(short *)(param_1 + 0xc);
        sVar10 = *(short *)(param_1 + 10);
        uStack_2a = CONCAT22(sVar10 + 0x13,sVar8 + 8);
        uStack_2e = CONCAT22(sVar10 + 0xf,sVar8 + 0x12);
        uStack_32 = CONCAT22(sVar10 + 0xb,sVar8 + 0x1b);
        if (sVar3 < 0x43) {
          if (sVar3 < 0x22) {
            uStack_26 = uStack_32;
          }
          else {
            uStack_26 = uStack_2e;
          }
        }
        else {
          uStack_26 = uStack_2a;
        }
        break;
      case 0xc1e:
        uStack_2a = CONCAT22(*(short *)(param_1 + 10) + 10,*(short *)(param_1 + 0xc) + 0xb);
        uStack_2e = CONCAT22(*(short *)(param_1 + 10) + 6,*(short *)(param_1 + 0xc) + 0x17);
        if (sVar3 < 0x33) {
          uStack_26 = uStack_2e;
        }
        else {
          uStack_26 = uStack_2a;
        }
        break;
      case 0xc1f:
        sVar11 = 0xb;
        uStack_26 = CONCAT22(*(short *)(param_1 + 10) + 8,*(short *)(param_1 + 0xc) + 0xf);
        break;
      case 0xc20:
      case 0xc21:
        sVar3 = *(short *)(param_1 + 0xc);
        sVar8 = *(short *)(param_1 + 10) + 0xe;
        sVar10 = *(short *)(param_1 + 10) + 9;
        uStack_2a = CONCAT22(sVar8,sVar3 + 0xd);
        uStack_2e = CONCAT22(sVar10,sVar3 + 0x14);
        uStack_32 = CONCAT22(sVar8,sVar3 + 0x1b);
        uStack_26 = CONCAT22(sVar10,sVar3 + 0x14);
        break;
      case 0xc22:
        sVar3 = *(short *)(param_1 + 0xc);
        sVar8 = *(short *)(param_1 + 10);
        uStack_2a = CONCAT22(sVar8 + 3,sVar3 + 10);
        uStack_2e = CONCAT22(sVar8 + 7,sVar3 + 0x13);
        uStack_32 = CONCAT22(sVar8 + 0xb,sVar3 + 0x1c);
        uStack_26 = CONCAT22(sVar8 + 7,sVar3 + 0x13);
        break;
      case 0xc23:
        sVar11 = 0xc;
        uStack_26 = CONCAT22(*(short *)(param_1 + 10) + 0x1a,*(short *)(param_1 + 0xc) + 0x13);
        break;
      case 0xc24:
        sVar8 = *(short *)(param_1 + 10) + 0x18;
        uStack_2a = CONCAT22(sVar8,*(short *)(param_1 + 0xc) + 0xc);
        uStack_2e = CONCAT22(sVar8,*(short *)(param_1 + 0xc) + 0x1c);
        if (sVar3 < 0x33) {
          uStack_26 = uStack_2e;
        }
        else {
          uStack_26 = uStack_2a;
        }
      }
      if (*(short *)(param_1 + 0xb0) == 1) {
        if (*(short *)(iVar7 + 6) == 3) {
          if (*(short *)(param_1 + 0xb2) == 0) {
            *(undefined2 *)(param_1 + 0xb2) = 1;
          }
          else {
            *(undefined2 *)(param_1 + 0xb2) = 0;
          }
          if (*(short *)(param_1 + 0xb2) == 1) {
            iVar9 = .debug::_FastRand(1000);
            iVar4 = .debug::_FastRand(1000);
            iVar5 = .debug::_FastRand(2);
            .debug::_NewParticle(sVar11,0,uStack_26,iVar5 + 1,iVar4 + -500,iVar9 + -500,0,1);
          }
        }
        else {
          iVar9 = .debug::_FastRand(1000);
          iVar4 = .debug::_FastRand(1000);
          iVar5 = .debug::_FastRand(2);
          .debug::_NewParticle(sVar11,0,uStack_26,iVar5 + 1,iVar4 + -500,iVar9 + -500,0,1);
          if (*(short *)(iVar7 + 6) == 1) {
            iVar9 = .debug::_FastRand(1000);
            iVar4 = .debug::_FastRand(1000);
            iVar5 = .debug::_FastRand(2);
            .debug::_NewParticle(sVar11,0,uStack_26,iVar5 + 1,iVar4 + -500,iVar9 + -500,0,1);
          }
        }
      }
      if ((sVar11 == 1) && (*(short *)(param_1 + 4) != 0x51b)) {
        if ((uStack_2a._2_2_ != 0) || (uStack_2a._0_2_ != 0)) {
          sVar3 = .debug::_FastRand(3);
          uStack_2a = CONCAT22(uStack_2a._0_2_,uStack_2a._2_2_ + -1 + sVar3);
          iVar9 = .debug::_FastRand(100);
          .debug::_NewParticle(1,0,uStack_2a,1,0,-0x32 - iVar9,0,0);
        }
        if ((uStack_2e._2_2_ != 0) || (uStack_2e._0_2_ != 0)) {
          sVar3 = .debug::_FastRand(3);
          uStack_2e = CONCAT22(uStack_2e._0_2_,uStack_2e._2_2_ + -1 + sVar3);
          iVar9 = .debug::_FastRand(100);
          .debug::_NewParticle(1,0,uStack_2e,1,0,-0x32 - iVar9,0,0);
        }
        if ((uStack_32._2_2_ != 0) || (uStack_32._0_2_ != 0)) {
          sVar3 = .debug::_FastRand(3);
          uStack_32 = CONCAT22(uStack_32._0_2_,uStack_32._2_2_ + -1 + sVar3);
          iVar9 = .debug::_FastRand(100);
          .debug::_NewParticle(1,0,uStack_32,1,0,-0x32 - iVar9,0,0);
        }
        if ((uStack_36._2_2_ != 0) || (uStack_36._0_2_ != 0)) {
          sVar3 = .debug::_FastRand(3);
          uStack_36 = CONCAT22(uStack_36._0_2_,uStack_36._2_2_ + -1 + sVar3);
          iVar9 = .debug::_FastRand(100);
          .debug::_NewParticle(1,0,uStack_36,1,0,-0x32 - iVar9,0,0);
        }
      }
      if (*(short *)(iVar7 + 6) == 1) {
        .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*_DAT_100a08c0);
        *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + -1;
        iVar7 = *(int *)(param_1 + 0x14c);
        if (iVar7 < 0xb) {
          if ((iVar7 == 3) || (iVar7 == 7)) {
            .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*_DAT_100a08bc);
          }
          if (*(int *)(param_1 + 0x14c) < 1) {
            sVar3 = .debug::_FastRand(0xf);
            *(int *)(param_1 + 0x14c) = sVar3 + 5;
          }
        }
      }
      if (*(short *)(param_1 + 4) == 0x51b) {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (0xb < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        *(int *)(param_1 + 0xc0) = *_DAT_100a08c4 + ((int)*(short *)(param_1 + 0x46) >> 1) * 0x34;
        sVar3 = .debug::_FastRand(0x1e);
        if (sVar3 == 1) {
          uStack_3c = CONCAT22(*(short *)(param_1 + 10) + 8,*(short *)(param_1 + 0xc) + 4);
          uVar6 = .debug::_FastRand(600);
          iVar7 = .debug::_FastRand(600);
          .debug::_NewParticle(1,0xb4,uStack_3c,4,iVar7 + -300,uVar6,0,1);
        }
      }
      goto LAB_1005fc30;
    }
  }
LAB_1005f808:
  if (0 < *(short *)(param_1 + 0xb0)) {
    *(short *)(param_1 + 0xb0) = *(short *)(param_1 + 0xb0) + -1;
  }
  iVar9 = (int)*(short *)(param_1 + 4);
  if ((iVar9 < 2000) || (*(short *)(iVar7 + 6) == 3)) {
    if ((iVar9 < 0x532) || (0x53b < iVar9)) {
      if ((iVar9 - 0x53cU & 0xffff) < 2) {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (0x13 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        sVar3 = *(short *)(param_1 + 0x46) >> 1;
        if (5 < sVar3) {
          sVar3 = 10 - sVar3;
        }
        if (*(short *)(param_1 + 4) == 0x53c) {
          *(int *)(param_1 + 0xc0) = *_DAT_100a08b4 + sVar3 * 0x34;
        }
        else if (*(short *)(param_1 + 4) == 0x53d) {
          *(int *)(param_1 + 0xc0) = *_DAT_100a08b0 + sVar3 * 0x34;
        }
        *(undefined1 *)(param_1 + 0x88) = 0;
        *(int *)(param_1 + 0x15c) = *(int *)(param_1 + 0x15c) + 1;
        iVar7 = *(int *)(param_1 + 0x15c);
        sVar3 = (short)((ulonglong)((longlong)iVar7 * 0x55555556) >> 0x20) -
                ((short)((short)(iVar7 / 0x30000) + (short)(iVar7 >> 0x1f)) >> 0xf);
        sVar3 = sVar3 + ((short)((ulonglong)((longlong)(int)sVar3 * 0x2aaaaaab) >> 0x20) -
                        ((short)((short)((int)sVar3 / 0x60000) + (sVar3 >> 0xf)) >> 0xf)) * -6;
        if (sVar3 == 3) {
          .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar2 + 8));
        }
        else if (sVar3 < 3) {
          if (sVar3 == 1) {
            .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)puVar2);
          }
          else if (sVar3 < 1) {
            if (-1 < sVar3) {
              *(undefined4 *)(param_1 + 0xb8) = 0;
              .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*_DAT_100a08b8);
            }
          }
          else {
            .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar2 + 4));
          }
        }
        else if (sVar3 == 5) {
          .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)puVar2);
        }
        else if (sVar3 < 5) {
          .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar2 + 4));
        }
      }
    }
    else if (*(short *)(param_1 + 0xa6) < 1) {
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a089c + iVar9 * 4 + -0x14c8);
      *(undefined1 *)(param_1 + 0x88) = 0;
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      sVar3 = *(short *)(param_1 + 0x46);
      sVar3 = (short)((ulonglong)((longlong)(int)sVar3 * 0x55555556) >> 0x20) -
              ((short)((short)((int)sVar3 / 0x30000) + (sVar3 >> 0xf)) >> 0xf);
      sVar3 = sVar3 + ((short)((ulonglong)((longlong)(int)sVar3 * 0x2aaaaaab) >> 0x20) -
                      ((short)((short)((int)sVar3 / 0x60000) + (sVar3 >> 0xf)) >> 0xf)) * -6;
      if (sVar3 == 3) {
        *(undefined4 *)(param_1 + 0xb8) = 0xb0002;
        .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar2 + 0xc));
      }
      else if (sVar3 < 3) {
        if (sVar3 == 1) {
          *(undefined4 *)(param_1 + 0xb8) = 0xb0001;
          .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar2 + 4));
        }
        else if (sVar3 < 1) {
          if (-1 < sVar3) {
            *(undefined4 *)(param_1 + 0xb8) = 0;
            .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)puVar2);
          }
        }
        else {
          *(undefined4 *)(param_1 + 0xb8) = 0xb0000;
          .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar2 + 8));
        }
      }
      else if (sVar3 == 5) {
        *(undefined4 *)(param_1 + 0xb8) = 0xb0001;
        .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar2 + 4));
      }
      else if (sVar3 < 5) {
        *(undefined4 *)(param_1 + 0xb8) = 0xb0000;
        .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar2 + 8));
      }
    }
    else {
      *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
      *(undefined4 *)(param_1 + 0xc0) = 0;
      .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),0);
    }
  }
  else {
    *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
    sVar3 = *(short *)(param_1 + 0x46) >> 2;
    sVar3 = sVar3 + ((short)((ulonglong)((longlong)(int)sVar3 * 0x2aaaaaab) >> 0x20) -
                    ((short)((short)((int)sVar3 / 0x60000) + (*(short *)(param_1 + 0x46) >> 0xf)) >>
                    0xf)) * -6;
    if (sVar3 == 3) {
      .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar2 + 0xc));
    }
    else if (sVar3 < 3) {
      if (sVar3 == 1) {
        .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar2 + 4));
      }
      else if (sVar3 < 1) {
        if (-1 < sVar3) {
          .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)puVar2);
        }
      }
      else {
        .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar2 + 8));
      }
    }
    else if (sVar3 == 5) {
      .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar2 + 4));
    }
    else if (sVar3 < 5) {
      .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar2 + 8));
    }
  }
LAB_1005fc30:
  if ((0 < *(int *)(param_1 + 0x24)) &&
     (*(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) - (int)*(short *)(param_1 + 0x114),
     *(int *)(param_1 + 0x24) < 0)) {
    *(undefined4 *)(param_1 + 0x24) = 0;
  }
  if ((*(int *)(param_1 + 0x24) < 0) &&
     (*(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + (int)*(short *)(param_1 + 0x114),
     0 < *(int *)(param_1 + 0x24))) {
    *(undefined4 *)(param_1 + 0x24) = 0;
  }
  if ((((0 < *(short *)(param_1 + 0x110)) && (sVar3 = *(short *)(param_1 + 4), sVar3 != 0x517)) &&
      (sVar3 != 0x41f)) && (sVar3 != 0x420)) {
    .debug::_ApplyGravityAndSeparateFromTiles(param_1);
  }
  .debug::_StandardSpriteCleanup(param_1);
  if (((*(short *)(param_1 + 0x9a) != -1) && (sVar3 = *(short *)(param_1 + 4), sVar3 != 0x51b)) &&
     ((sVar3 < 0xc1c || (0xc25 < sVar3)))) {
    .debug::_SetLightPos
              ((int)*(short *)(param_1 + 0x9a),(int)*(short *)(param_1 + 0x10),
               (int)*(short *)(param_1 + 0xe));
  }
  return;
}


// ==== .HitBonusSprite @ 1005fd38 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitBonusSprite(int param_1,int param_2)

{
  short sVar1;
  short sVar2;
  short sVar3;
  short sVar4;
  undefined4 uVar5;
  int *piVar6;
  int iVar7;
  short sVar9;
  undefined *puVar8;
  uint uVar10;
  int *piVar11;
  short sStack_38;
  short sStack_36;
  
  piVar6 = _DAT_1009ffc0;
  uVar5 = _DAT_1009ff38;
  sVar9 = *(short *)(param_1 + 4);
  if (sVar9 == 0x4bf) {
    return;
  }
  if (sVar9 == 0x51b) {
LAB_1005fd94:
    if ((((*(undefined **)(param_2 + 0x4c) != PTR_PTR_100a04e8) || (*(short *)(param_2 + 4) != 0x50)
         ) && (*(undefined **)(param_2 + 0x4c) == PTR_PTR_100a04e8)) &&
       (*(short *)(param_2 + 0xa6) == 0)) {
      piVar11 = _DAT_1009ffc0 + 1;
      sVar1 = *(short *)((int)_DAT_1009ffc0 + 0xe);
      sVar2 = *(short *)(_DAT_1009ffc0 + 1);
      sVar3 = *(short *)((int)_DAT_1009ffc0 + 10);
      sVar4 = *(short *)(_DAT_1009ffc0 + 3);
      if ((sVar9 == 0x51b) || ((0xc1b < sVar9 && (sVar9 < 0xc26)))) {
        if (*(short *)(param_1 + 0xb0) == 0) {
          return;
        }
        *(undefined2 *)(param_1 + 0xb0) = 0;
        .glue::SetRect(param_1 + 0x34,0,0,0,0);
        *(undefined2 *)(*(int *)*_DAT_100a0058 + *(short *)(param_1 + 0x48) * 0x10 + 0xe) = 1;
      }
      else {
        .debug::_KillBonus(param_1);
      }
      .debug::_KillPlayerShot(param_2,1,1);
      *piVar6 = *piVar6 + 0x96;
      if ((((int)sVar1 << 8) / (int)sVar4 < ((int)sVar2 << 8) / (int)sVar3) &&
         (0x25 < *(short *)piVar11)) {
        iVar7 = .debug::_MTNewSprite
                          (0x514,*(short *)(param_1 + 0x10) + -9,*(short *)(param_1 + 0xe) + -9,2,
                           0xffffffff,uVar5);
        sVar9 = .debug::_FastRand(1000);
        *(int *)(iVar7 + 0x2c) = -2000 - sVar9;
      }
      else {
        iVar7 = .debug::_MTNewSprite
                          (0x515,*(short *)(param_1 + 0x10) + -9,*(short *)(param_1 + 0xe) + -9,2,
                           0xffffffff,uVar5);
        sVar9 = .debug::_FastRand(1000);
        *(int *)(iVar7 + 0x2c) = -2000 - sVar9;
      }
    }
  }
  else {
    if (sVar9 < 0x51b) {
      if (sVar9 == 0x517) goto LAB_1005fd94;
    }
    else if ((sVar9 < 0xc26) && (0xc1b < sVar9)) goto LAB_1005fd94;
    puVar8 = *(undefined **)(param_2 + 0x4c);
    if ((((puVar8 != PTR_PTR_100a052c) &&
         ((puVar8 == _DAT_100a0200 || (puVar8 == PTR_PTR_100a0484)))) &&
        ((sVar9 < 2000 || (0xc80 < sVar9)))) && (sVar9 = 0x80, *(short *)(param_2 + 4) != 0x51c)) {
      sStack_36 = *(short *)(param_1 + 0x36) +
                  (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
      sStack_38 = *(short *)(param_1 + 0x34) +
                  (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
      if (*(int *)(param_1 + 0x2c) < 0x180) {
        sVar9 = 0;
      }
      uVar10 = (uint)sVar9;
      .debug::_PlatformBounce
                (param_1,param_2,&sStack_38,uVar10,param_1 + 0x34,
                 (uint)(uVar10 == 0) - ((int)~uVar10 >> 0x1f) & 1);
    }
  }
  return;
}


// ==== .HitBonusTileSprite @ 1006010c ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitBonusTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  int iVar1;
  char cVar2;
  short sVar3;
  undefined4 uVar4;
  short sStack_48;
  short sStack_46;
  undefined1 auStack_28 [20];
  
  uVar4 = 0x80;
  sStack_46 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_48 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  if ((*_DAT_100a0064 == '\0') || (cVar2 = .debug::_IsPressed(0x32), cVar2 == '\0')) {
    sVar3 = *(short *)(param_1 + 4);
    if ((sVar3 == 0x50c) || (sVar3 == 0x50d)) {
      uVar4 = 0x40;
    }
    if ((0x4be < sVar3) && (sVar3 < 0x4c2)) {
      uVar4 = 0xe0;
    }
    .glue::SetRect(auStack_28,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                   (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
    sVar3 = (short)param_3;
    if (param_4 == 1) {
      if (((sVar3 != 0x67) || (-1 < *(int *)(param_1 + 0x2c))) &&
         (cVar2 = .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,uVar4,
                                      param_1 + 0x34,0,1), cVar2 != '\0')) {
        iVar1 = *(int *)(param_1 + 0x2c);
        if (iVar1 < 1) {
          iVar1 = -iVar1;
        }
        if ((0x100 < iVar1) &&
           ((*(short *)(param_1 + 4) == 0x50c || (*(short *)(param_1 + 4) == 0x50d)))) {
          .debug::_STPlay3DSoundRand(*_DAT_100a0300,1,0x55,*(undefined4 *)(param_1 + 0xe));
        }
      }
    }
    else if (param_4 == 0) {
      if (sVar3 < 100) {
        .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,uVar4,param_1 + 0x34,0,1);
      }
      else if (sVar3 < 200) {
        .debug::_WallBounceBG
                  (param_1,param_3 + -100,&stack0x0000001c,&sStack_48,uVar4,param_1 + 0x34,0,1);
      }
      else {
        cVar2 = .debug::_IsWaterTile(param_3);
        if ((cVar2 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
          .debug::_HandleUnderWater(param_1,param_2);
        }
      }
    }
    else if (param_4 == 2) {
      *(undefined2 *)(param_1 + 0x118) = 0;
    }
  }
  return;
}


// ==== .SetupEffectSprite @ 10060680 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupEffectSprite(int param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  short sVar9;
  int iVar6;
  int iVar7;
  int iVar8;
  undefined2 uVar10;
  short sVar11;
  short sVar12;
  undefined4 *puVar13;
  undefined4 uVar14;
  undefined4 uStack_38;
  undefined4 uStack_30;
  
  puVar4 = PTR_PTR_100a0908;
  puVar3 = PTR_DAT_100a0904;
  puVar2 = PTR_PTR_100a08fc;
  puVar1 = PTR_PTR_100a0460;
  .debug::_InitSprite();
  puVar5 = PTR_PTR_100a090c;
  *(undefined1 *)(param_1 + 0x88) = 0;
  *(undefined2 *)(param_1 + 0x84) = 0;
  *(undefined2 *)(param_1 + 0x86) = 0;
  *(undefined2 *)(param_1 + 0x46) = 0;
  *(undefined4 *)(param_1 + 0x80) = 0xb;
  *(undefined **)(param_1 + 0x4c) = puVar1;
  *(undefined **)(param_1 + 0x5c) = puVar5;
  *(undefined **)(param_1 + 0x1f8) = puVar4;
  *(undefined2 *)(param_1 + 0xa6) = 3;
  .glue::SetRect(param_1 + 0x34,0x10,0x10,0x20,0x20);
  *(undefined4 *)(param_1 + 0xc0) = 0;
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  *(undefined1 *)(param_1 + 0xe4) = 1;
  *(undefined1 *)(param_1 + 0x13e) = 0;
  if (*(short *)(param_1 + 4) == 0x410) {
    .glue::SetRect(param_1 + 0x34,0,0xfffffff6,8,0xfffffffe);
  }
  if (*(short *)(param_1 + 4) == 0x4b7) {
    .glue::SetRect(param_1 + 0x34,8,8,0x58,0x58);
    *(undefined1 *)(param_1 + 0xeb) = 2;
  }
  if (*(short *)(param_1 + 4) == 0x4b6) {
    *(short *)puVar3 = *(short *)puVar3 + 1;
  }
  sVar11 = *(short *)(param_1 + 4);
  if (((((sVar11 != 0x4b1) && (sVar11 != 0x4b2)) && (sVar11 != 0x4b3)) &&
      (((sVar11 != 0x4b4 && (sVar11 != 0x4b5)) &&
       ((sVar11 != 0x4b6 && ((sVar11 != 0x4c4 && (sVar11 != 0x410)))))))) &&
     ((sVar11 != 0x596 &&
      (((((sVar11 != 0x4e3 && (sVar11 != 0x4ba)) && (sVar11 != 0xc1b)) &&
        ((sVar11 != 0x5a0 && (sVar11 != 0x59b)))) && ((sVar11 != 0x726 && (sVar11 < 0xc80)))))))) {
    uVar14 = 1;
    if (sVar11 == 0x4b7) {
      uStack_30 = CONCAT22(*(short *)(param_1 + 10) + 0x30,*(short *)(param_1 + 0xc) + 0x30);
    }
    else {
      uStack_30 = CONCAT22(*(short *)(param_1 + 10) + 0x18,*(short *)(param_1 + 0xc) + 0x18);
    }
    if ((sVar11 == 5) || (sVar11 == 0x442)) {
      uVar14 = 4;
    }
    if (sVar11 == 2) {
      uVar14 = 9;
    }
    for (sVar11 = 0; sVar11 < 0x2d; sVar11 = sVar11 + 1) {
      if (*(short *)(param_1 + 4) == 0x4b7) {
        sVar9 = 0x20;
      }
      else {
        sVar9 = 0x10;
      }
      if (*(short *)(param_1 + 4) == 0x4b7) {
        sVar12 = 0x30;
      }
      else {
        sVar12 = 0x18;
      }
      uStack_38 = CONCAT22(*(short *)(param_1 + 10) + sVar12,*(short *)(param_1 + 0xc) + sVar9);
      iVar6 = .debug::_FastRand(2000);
      iVar7 = .debug::_FastRand(2000);
      iVar8 = .debug::_FastRand(2);
      .debug::_NewParticle(uVar14,0x96,uStack_38,iVar8 + 1,iVar7 + -1000,iVar6 + -1000,0,1);
    }
    sVar11 = *(short *)(param_1 + 4);
    if ((((sVar11 != 0x4b7) && (sVar11 != 0x442)) && (sVar11 != -1)) &&
       ((*(short *)(_DAT_1009fe44 + 6) == 1 && (*(short *)puVar3 < 3)))) {
      .debug::_MTNewSprite
                (0x4b6,*(short *)(param_1 + 0xc) + -8,*(short *)(param_1 + 10) + -0x5a,0x14,
                 0xffffffff,_DAT_1009fef8);
    }
    if (*(short *)(param_1 + 4) != 0x442) {
      uVar10 = .debug::_AddLight(*(undefined4 *)(PTR_DAT_100a088c + 0xc),uStack_30,0,0,0,0x16);
      *(undefined2 *)(param_1 + 0x9a) = uVar10;
    }
  }
  if (*(short *)(param_1 + 4) == 0xcb2) {
    *(undefined4 *)(param_1 + 0x80) = 100;
  }
  else if (0xcb2 < *(short *)(param_1 + 4)) {
    *(undefined4 *)(param_1 + 0x80) = 0x65;
  }
  if (*(short *)(param_1 + 4) == 0x442) {
    *(undefined4 *)(param_1 + 0x80) = 0x7fbc;
  }
  if (*(short *)(param_1 + 4) == 0x5a0) {
    *(undefined **)(param_1 + 0x4c) = PTR_PTR_100a0900;
    *(undefined4 *)(param_1 + 0x5c) = 0;
    *(undefined4 *)(param_1 + 0x1f8) = 0;
    .glue::SetRect(param_1 + 0x34,4,0x18,0x10,0x20);
    *(undefined4 *)(param_1 + 0x80) = 1;
  }
  if (*(short *)(param_1 + 4) == 0xc1b) {
    sVar11 = .debug::_FastRand(100);
    if (sVar11 < 0x33) {
      *(undefined4 *)(param_1 + 0x14c) = 1;
    }
    else {
      *(undefined4 *)(param_1 + 0x14c) = 0;
    }
    uVar10 = .debug::_FastRand(8);
    *(undefined2 *)(param_1 + 0x46) = uVar10;
    *(undefined2 *)(param_1 + 0x110) = 0x5a;
    *(undefined **)(param_1 + 0x1f8) = puVar4;
    .glue::SetRect(param_1 + 0x34,10,10,0xe,0xe);
  }
  if (*(short *)(param_1 + 4) == 0x4c4) {
    *(undefined **)(param_1 + 0x4c) = puVar1;
    *(undefined4 *)(param_1 + 0x5c) = 0;
    *(undefined4 *)(param_1 + 0x1f8) = 0;
    *(undefined4 *)(param_1 + 0x80) = 0x7fff;
    *(undefined1 *)(param_1 + 0x88) = 0;
    uVar14 = .debug::_AllocateGameMem(0x1c);
    *(undefined4 *)(param_1 + 0x9c) = uVar14;
    puVar13 = *(undefined4 **)(param_1 + 0x9c);
    uVar14 = .debug::_MTNewSprite
                       (0x4c5,(int)*(short *)(param_1 + 0xc),(int)*(short *)(param_1 + 10),0x7fff,
                        0xffffffff,puVar2);
    *puVar13 = uVar14;
    uVar14 = .debug::_MTNewSprite
                       (0x4c5,(int)*(short *)(param_1 + 0xc),(int)*(short *)(param_1 + 10),0x7fff,
                        0xffffffff,puVar2);
    puVar13[1] = uVar14;
    uVar14 = .debug::_MTNewSprite
                       (0x4c5,(int)*(short *)(param_1 + 0xc),(int)*(short *)(param_1 + 10),0x7fff,
                        0xffffffff,puVar2);
    puVar13[2] = uVar14;
    uVar14 = .debug::_MTNewSprite
                       (0x4c5,(int)*(short *)(param_1 + 0xc),(int)*(short *)(param_1 + 10),0x7fff,
                        0xffffffff,puVar2);
    puVar13[3] = uVar14;
    uVar14 = .debug::_MTNewSprite
                       (0x4c5,(int)*(short *)(param_1 + 0xc),(int)*(short *)(param_1 + 10),0x7fff,
                        0xffffffff,puVar2);
    puVar13[4] = uVar14;
    uVar14 = .debug::_MTNewSprite
                       (0x4c5,(int)*(short *)(param_1 + 0xc),(int)*(short *)(param_1 + 10),0x7fff,
                        0xffffffff,puVar2);
    puVar13[5] = uVar14;
  }
  return;
}


// ==== .SetupDigitSprite @ 10060c0c ====

void _SetupDigitSprite(int param_1)

{
  undefined *puVar1;
  
  .debug::_InitSprite();
  puVar1 = PTR_PTR_100a08f8;
  *(undefined1 *)(param_1 + 0x88) = 0;
  *(undefined4 *)(param_1 + 0x80) = 0x7fff;
  *(undefined **)(param_1 + 0x4c) = puVar1;
  return;
}


// ==== .anon_10060c78 @ 10060c78 ====

void _anon_10060c78(undefined4 param_1)

{
  .debug::_StandardSpriteHandles();
  .debug::_StandardSpriteCleanup(param_1);
  return;
}


// ==== .HandleGeyserSegSprite @ 10060cd8 ====

void _HandleGeyserSegSprite(void)

{
  return;
}


// ==== .HandleEffectSprite @ 10061160 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleEffectSprite(int param_1)

{
  undefined *puVar1;
  int *piVar2;
  undefined *puVar3;
  short sVar5;
  int iVar4;
  int iVar6;
  undefined2 uVar7;
  short *psVar8;
  undefined4 uStack_28;
  
  puVar3 = PTR_DAT_100a0940;
  piVar2 = _DAT_100a092c;
  puVar1 = PTR_DAT_100a088c;
  iVar4 = _DAT_1009ffc0;
  if (*(char *)(param_1 + 0xe9) != '\0') {
    return;
  }
  if (*(char *)(param_1 + 0x1b2) != '\0') {
    return;
  }
  .debug::_StandardSpriteHandles(param_1);
  iVar6 = (int)*(short *)(param_1 + 4);
  if (iVar6 == 0x4b1) {
    *(undefined1 *)(param_1 + 0x88) = 1;
    *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
    if (*(short *)(param_1 + 0x46) < 6) {
      *(int *)(param_1 + 0xc0) = *_DAT_100a0938 + *(short *)(param_1 + 0x46) * 0x34;
    }
    else {
      if (*(char *)(param_1 + 0xe9) == '\0') {
        *(undefined1 *)(param_1 + 0xe9) = 1;
      }
      *(undefined4 *)(param_1 + 0xc0) = 0;
    }
  }
  else if ((iVar6 < 0x4b2) || (0x4b4 < iVar6)) {
    if (iVar6 == 0x4b5) {
      *(undefined1 *)(param_1 + 0x88) = 0;
      *(undefined4 *)(param_1 + 0xb8) = 0xb0004;
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (*(short *)(param_1 + 0x46) < 0x21) {
        *(undefined4 *)(param_1 + 0xc0) = 0;
      }
      else {
        *(undefined1 *)(param_1 + 0xe9) = 1;
        *(undefined4 *)(param_1 + 0xc0) = 0;
      }
    }
    else if (iVar6 == 0x4b6) {
      *(undefined1 *)(param_1 + 0x88) = 0;
      *(undefined4 *)(param_1 + 0xb8) = 0xb0004;
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      puVar1 = PTR_DAT_100a0904;
      if (*(short *)(param_1 + 0x46) < 0x22) {
        *(int *)(param_1 + 0xc0) = *_DAT_100a0930 + *(short *)(param_1 + 0x46) * 0x34;
      }
      else {
        *(undefined1 *)(param_1 + 0xe9) = 1;
        *(undefined4 *)(param_1 + 0xc0) = 0;
        *(short *)puVar1 = *(short *)puVar1 + -1;
      }
    }
    else if (iVar6 == 0x4ba) {
      *(undefined1 *)(param_1 + 0x88) = 1;
      if (0 < *(short *)(param_1 + 0x46)) {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1;
      }
      if ((*(int *)(param_1 + 0x16c) == 1) && (*(short *)(param_1 + 0x46) == 0)) {
        *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -1;
      }
      if (*(short *)(param_1 + 0xa4) < 1) {
        *(undefined4 *)(param_1 + 0xc0) = 0;
        *(undefined1 *)(param_1 + 0xe9) = 1;
        *(undefined4 *)(*(int *)(param_1 + 0x150) * 4 + 0x100a53d8) = 0;
        if ((*(short *)(param_1 + 0xa4) == 0) && (*(int *)(param_1 + 0x16c) == 1)) {
          .debug::_STPlay3DSound(*_DAT_100a01e0,1,0x100,*(undefined4 *)(param_1 + 0xe));
          .debug::_DestroyCrunchTile
                    ((int)(short)*(undefined4 *)(param_1 + 0x154),
                     (int)(short)*(undefined4 *)(param_1 + 0x158),
                     (int)(short)*(undefined4 *)(param_1 + 0x15c),1,1,0);
          psVar8 = (short *)(iVar4 + 0xad6);
          if (*(short *)(iVar4 + 0xad6) < 20000) {
            *(char *)(iVar4 + *(short *)(iVar4 + 0xad6) + 0x12d8) = (char)*_DAT_1009feac;
            *(short *)(iVar4 + *psVar8 * 4 + 0x60fa) = (short)*(undefined4 *)(param_1 + 0x154);
            *(short *)(iVar4 + *psVar8 * 4 + 0x60f8) = (short)*(undefined4 *)(param_1 + 0x158);
            *psVar8 = *psVar8 + 1;
          }
        }
      }
      else {
        sVar5 = (short)*(undefined4 *)(param_1 + 0x14c) - *(short *)(param_1 + 0xa4);
        if ((sVar5 < 0) || (2 < sVar5)) {
          .debug::_ReportError(s_Crunch_sprite_face_out_of_range__100a62f0);
        }
        else {
          *(int *)(param_1 + 0xc0) = *_DAT_100a0914 + sVar5 * 0x34;
        }
      }
    }
    else if (iVar6 == 0x4c4) {
      .debug::_UpdateDigits(param_1);
    }
    else if (iVar6 == 0x4e3) {
      *(int *)(param_1 + 0xc0) = *_DAT_100a0918 + ((int)*(short *)(param_1 + 0x46) >> 1) * 0x34;
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (0xb < *(short *)(param_1 + 0x46)) {
        *(undefined1 *)(param_1 + 0xe9) = 1;
      }
    }
    else if (iVar6 == 0x726) {
      if (*(short *)(param_1 + 0x9a) == -1) {
        uStack_28 = CONCAT22(*(short *)(param_1 + 10) + 8,*(short *)(param_1 + 0xc) + 0x20);
        uVar7 = .debug::_AddLight(*_DAT_100a0928,uStack_28,0,0,0,
                                  (int)*(short *)(*(int *)*_DAT_100a0058 +
                                                  *(short *)(param_1 + 0x48) * 0x10 + 8));
        *(undefined2 *)(param_1 + 0x9a) = uVar7;
      }
    }
    else if (iVar6 == 0x410) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (7 < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0;
      }
      *(int *)(param_1 + 0xc0) = *_DAT_100a0934 + ((int)*(short *)(param_1 + 0x46) >> 1) * 0x34;
      *(undefined4 *)(param_1 + 0x2c) = 0xfffffe0c;
      .debug::_SeparateFromTiles2(param_1);
      if (*(int *)(param_1 + 0x11c) == 0) {
        *(undefined4 *)(param_1 + 0xc0) = 0;
        .debug::_RemoveLight(param_1 + 0x9a);
        *(undefined1 *)(param_1 + 0xe9) = 1;
      }
    }
    else if (iVar6 == 0xc1b) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (7 < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0;
      }
      .debug::_ApplyGravityAndSeparateFromTiles(param_1);
      *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + (int)*(short *)(param_1 + 0x110);
      if (*(int *)(param_1 + 0x14c) == 0) {
        *(int *)(param_1 + 0xc0) = *piVar2 + *(short *)(param_1 + 0x46) * 0x34;
      }
      else {
        *(int *)(param_1 + 0xc0) = *piVar2 + (*(short *)(param_1 + 0x46) + 8) * 0x34;
      }
      if (3 < *(int *)(param_1 + 0x16c)) {
        *(undefined1 *)(param_1 + 0xe9) = 1;
      }
      if (*(short *)(_DAT_1009fe44 + 6) == 1) {
        iVar4 = *(int *)(param_1 + 0x16c);
        if (iVar4 == 1) {
          *(undefined4 *)(param_1 + 0xb8) = 0xb0001;
        }
        else {
          if (iVar4 < 1) {
            if (-1 < iVar4) {
              *(undefined4 *)(param_1 + 0xb8) = 0;
              goto LAB_100618dc;
            }
          }
          else if (iVar4 < 3) {
            *(undefined4 *)(param_1 + 0xb8) = 0xb0000;
            goto LAB_100618dc;
          }
          *(undefined4 *)(param_1 + 0xb8) = 0xb0002;
        }
      }
    }
    else if (iVar6 == -1) {
      if (*(short *)(param_1 + 0x46) < 0x1a) {
        *(int *)(param_1 + 0xc0) = *(int *)puVar3 + ((int)*(short *)(param_1 + 0x46) >> 1) * 0x34;
      }
      else {
        *(undefined1 *)(param_1 + 0xe9) = 1;
        *(undefined4 *)(param_1 + 0xc0) = 0;
      }
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
    }
    else if (iVar6 < 0xcb2) {
      if ((0 < *(short *)(param_1 + 4)) && (iVar6 < 0x10)) {
        *(int *)(param_1 + 0xb8) = iVar6 + 0x10000;
      }
      if (*(short *)(param_1 + 4) == 0x442) {
        *(undefined4 *)(param_1 + 0xb8) = 0x10005;
      }
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      sVar5 = *(short *)(param_1 + 0x46);
      if (sVar5 == 2) {
        .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar1 + 8));
      }
      else if (sVar5 == 4) {
        .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar1 + 4));
      }
      else if (sVar5 == 6) {
        .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)puVar1);
      }
      else if (sVar5 == 0xe) {
        .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar1 + 4));
      }
      else if (sVar5 == 0x11) {
        .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar1 + 8));
      }
      else if (sVar5 == 0x14) {
        .debug::_ChangeLightFace((int)*(short *)(param_1 + 0x9a),*(undefined4 *)(puVar1 + 0xc));
      }
      else if (sVar5 == 0x17) {
        .debug::_RemoveLight(param_1 + 0x9a);
      }
      if (*(short *)(param_1 + 0x46) < 0x1a) {
        if (*(short *)(param_1 + 4) == -1) {
          *(undefined4 *)(param_1 + 0xc0) = 0;
        }
        else if (*(short *)(param_1 + 4) == 0x4b7) {
          .debug::_ApplyGravityAndSeparateFromTiles(param_1);
          *(int *)(param_1 + 0xc0) = *_DAT_100a093c + ((int)*(short *)(param_1 + 0x46) >> 1) * 0x34;
        }
        else {
          *(int *)(param_1 + 0xc0) = *(int *)puVar3 + ((int)*(short *)(param_1 + 0x46) >> 1) * 0x34;
        }
      }
      else {
        *(undefined1 *)(param_1 + 0xe9) = 1;
        *(undefined4 *)(param_1 + 0xc0) = 0;
      }
    }
  }
  else {
    if (iVar6 == 0x4b2) {
      *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0924;
    }
    else if (iVar6 == 0x4b3) {
      *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0920;
    }
    else if (iVar6 == 0x4b4) {
      *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a091c;
    }
    if (*(short *)PTR_DAT_1009fe78 + 0x180 < (int)*(short *)(param_1 + 10)) {
      *(undefined1 *)(param_1 + 0xe9) = 1;
    }
  }
LAB_100618dc:
  *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + *(int *)(param_1 + 0x24);
  *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + *(int *)(param_1 + 0x2c);
  if (*(short *)(param_1 + 4) != 0x596) {
    uVar7 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
    *(undefined2 *)(param_1 + 8) = uVar7;
    *(undefined2 *)(param_1 + 0xc) = uVar7;
    uVar7 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
    *(undefined2 *)(param_1 + 6) = uVar7;
    *(undefined2 *)(param_1 + 10) = uVar7;
  }
  .debug::_StandardSpriteCleanup(param_1);
  return;
}


// ==== .HitEffectSprite @ 10061978 ====

void _HitEffectSprite(void)

{
  return;
}


// ==== .HitEffectTileSprite @ 100619a0 ====

void _HitEffectTileSprite(int param_1,undefined4 param_2,undefined4 param_3,short param_4)

{
  char cVar1;
  short sStack_18;
  short sStack_16;
  
  if (param_4 == 1) {
    if (*(short *)(param_1 + 4) == 0xc1b) {
      sStack_16 = *(short *)(param_1 + 0x10) - *(short *)(param_1 + 0xc);
      sStack_18 = *(short *)(param_1 + 0xe) - *(short *)(param_1 + 10);
      cVar1 = .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_18,0x80,param_1 + 0x34,0,
                                  0x80);
      if (cVar1 != '\0') {
        *(int *)(param_1 + 0x16c) = *(int *)(param_1 + 0x16c) + 1;
      }
    }
  }
  else if (param_4 == 0) {
    cVar1 = .debug::_IsWaterTile(param_3);
    if ((cVar1 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
      .debug::_HandleUnderWater(param_1,param_2);
    }
  }
  else if ((param_4 == 2) && (*(char *)(param_1 + 0xeb) != '\0')) {
    .debug::_CrunchTile(param_2);
  }
  return;
}


// ==== .SetupPlatformSprite @ 10061f94 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupPlatformSprite(int param_1)

{
  undefined4 uVar1;
  undefined *puVar2;
  undefined *puVar3;
  
  .debug::_InitSprite();
  uVar1 = _DAT_100a0200;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar3 = PTR_PTR_100a0960;
  *(undefined2 *)(param_1 + 0x86) = 0;
  puVar2 = PTR_PTR_100a095c;
  *(undefined4 *)(param_1 + 0x80) = 0xffffffff;
  *(undefined4 *)(param_1 + 0x4c) = uVar1;
  *(undefined **)(param_1 + 0x5c) = puVar3;
  *(undefined **)(param_1 + 0x1f8) = puVar2;
  *(undefined4 *)(param_1 + 0xc0) = 0;
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  *(undefined1 *)(param_1 + 0x185) = 1;
  *(undefined4 *)(param_1 + 400) = 0;
  *(undefined2 *)(param_1 + 0x110) = 0;
  *(undefined2 *)(param_1 + 0x13a) = 0x50;
  if (*(short *)(param_1 + 4) != 0x6a4) {
    *(undefined2 *)(param_1 + 0xa6) = 1;
  }
  *(undefined1 *)(param_1 + 0x188) = 1;
  *(undefined1 *)(param_1 + 0x17c) = 0;
  .glue::SetRect(param_1 + 0x34,0,0,0,0);
  return;
}


// ==== .HandlePlatformSprite @ 100635b4 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandlePlatformSprite(int param_1)

{
  uint uVar1;
  undefined4 *puVar2;
  undefined4 *puVar3;
  int *piVar4;
  undefined *puVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  uint uVar8;
  short sVar9;
  undefined2 uVar10;
  short sVar12;
  int iVar11;
  int iVar13;
  int iVar14;
  short unaff_r26;
  undefined4 uVar15;
  int unaff_r27;
  short sStack_52;
  undefined8 uStack_38;
  undefined8 uStack_30;
  
  puVar5 = PTR_DAT_100a098c;
  piVar4 = _DAT_100a0984;
  puVar3 = _DAT_100a035c;
  puVar2 = _DAT_100a0058;
  if (*(char *)(param_1 + 0xe9) != '\0') {
    return;
  }
  if (*(char *)(param_1 + 0x1b2) != '\0') {
    return;
  }
  if (*(char *)(param_1 + 0x17c) == '\0') {
    .debug::_DoSetupPlatformSprite(param_1);
    *(undefined1 *)(param_1 + 0x17c) = 1;
  }
  .debug::_StandardSpriteHandles(param_1);
  sVar12 = *(short *)(param_1 + 0xb0);
  if (sVar12 == 0x1e) {
    *(undefined4 *)(param_1 + 0x2c) = 0;
    *(undefined4 *)(param_1 + 0x24) = 0;
    if (*(short *)(param_1 + 0xa6) < 0) {
      *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
    }
    else {
      *(undefined2 *)(param_1 + 0xa6) = 0;
    }
    if ((*(char *)(param_1 + 0x186) != '\0') && (-1 < *(short *)(param_1 + 0xa6))) {
      *(undefined2 *)(param_1 + 0xb2) = 1;
      .debug::_RadialWheelStep(param_1,*(undefined4 *)(param_1 + 0x150));
    }
    .debug::_UpdateRadialPos(param_1);
    .debug::_UpdateRadiusSprites(param_1,1,0x4b);
    if (*(short *)(param_1 + 0xb2) == 1) {
      if ((*(char *)(param_1 + 0x186) == '\0') || (*(int *)(param_1 + 0x150) == 0)) {
        iVar13 = *(int *)(param_1 + 0x198);
        if (*(short *)(param_1 + 0x48) == -1) {
          if (*(int *)(iVar13 + 0x18) < 0xb200) {
            *(int *)(iVar13 + 0x14) = *(int *)(iVar13 + 0x14) + 0x18;
          }
          else if (0xb600 < *(int *)(iVar13 + 0x18)) {
            *(int *)(iVar13 + 0x14) = *(int *)(iVar13 + 0x14) + -0x18;
          }
        }
        else {
          iVar11 = *(int *)(iVar13 + 0x18);
          if ((iVar11 < 0xb400) && (0x200 < iVar11)) {
            *(int *)(iVar13 + 0x14) = *(int *)(iVar13 + 0x14) + -0x18;
          }
          else if ((0xb400 < iVar11) && (iVar11 < 0x16600)) {
            *(int *)(iVar13 + 0x14) = *(int *)(iVar13 + 0x14) + 0x18;
          }
        }
      }
      *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0xb2) = 0;
      *(int *)(*(int *)(*(int *)(param_1 + 0x1d4) + 0x198) + 0x18) =
           *(int *)(*(int *)(param_1 + 0x198) + 0x18) + 0xb400;
      *(undefined4 *)(*(int *)(*(int *)(param_1 + 0x1d4) + 0x198) + 0x14) =
           *(undefined4 *)(*(int *)(param_1 + 0x198) + 0x14);
      **(undefined4 **)(*(int *)(param_1 + 0x1d4) + 0x198) = **(undefined4 **)(param_1 + 0x198);
      *(undefined4 *)(*(int *)(*(int *)(param_1 + 0x1d4) + 0x198) + 4) =
           *(undefined4 *)(*(int *)(param_1 + 0x198) + 4);
    }
    *(undefined1 *)(param_1 + 0x186) = 0;
    *(undefined4 *)(param_1 + 0x194) = 0;
    *(undefined4 *)(param_1 + 0xc0) = 0;
    goto LAB_10064968;
  }
  if (sVar12 < 0x1e) {
    if (sVar12 < 0xc) {
      if (sVar12 == 2) {
        if ((*(int *)(param_1 + 0x15c) == 1) && (*(char *)(param_1 + 0x186) == '\0')) {
          uStack_38 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
          *(int *)(param_1 + 0x24) = (int)((uStack_38 - _DAT_100a1a78) * dRam100a1a70);
        }
        else {
          if (*(int *)(param_1 + 0x158) != 1) {
            *(undefined1 *)(param_1 + 0x186) = 0;
          }
          if (*(short *)(param_1 + 0xa6) == 1) {
            if (*(int *)(param_1 + 0x154) < *(int *)(param_1 + 0x14)) {
              *(undefined2 *)(param_1 + 0xa6) = 0xffff;
            }
            else if (*(int *)(param_1 + 0x24) < *(int *)(param_1 + 0x14c)) {
              *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + (*(int *)(param_1 + 0x14c) >> 4)
              ;
            }
          }
          else if (*(int *)(param_1 + 0x14) < *(int *)(param_1 + 0x150)) {
            *(undefined2 *)(param_1 + 0xa6) = 1;
          }
          else if (-*(int *)(param_1 + 0x14c) < *(int *)(param_1 + 0x24)) {
            *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) - (*(int *)(param_1 + 0x14c) >> 4);
          }
          *(undefined4 *)(param_1 + 0x194) = 0;
        }
      }
      else if (sVar12 < 2) {
        if (0 < sVar12) {
          if ((*(int *)(param_1 + 0x15c) == 1) && (*(char *)(param_1 + 0x186) == '\0')) {
            uStack_30 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x2c) ^ 0x80000000);
            *(int *)(param_1 + 0x2c) = (int)((uStack_30 - _DAT_100a1a78) * dRam100a1a70);
          }
          else {
            if (*(int *)(param_1 + 0x158) != 1) {
              *(undefined1 *)(param_1 + 0x186) = 0;
            }
            if (*(short *)(param_1 + 0xa6) == 1) {
              if (*(int *)(param_1 + 0x154) < *(int *)(param_1 + 0x1c)) {
                *(undefined2 *)(param_1 + 0xa6) = 0xffff;
              }
              else if (*(int *)(param_1 + 0x2c) < *(int *)(param_1 + 0x14c)) {
                *(int *)(param_1 + 0x2c) =
                     *(int *)(param_1 + 0x2c) + (*(int *)(param_1 + 0x14c) >> 4);
              }
            }
            else if (*(int *)(param_1 + 0x1c) < *(int *)(param_1 + 0x150)) {
              *(undefined2 *)(param_1 + 0xa6) = 1;
            }
            else if (-*(int *)(param_1 + 0x14c) < *(int *)(param_1 + 0x2c)) {
              *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) - (*(int *)(param_1 + 0x14c) >> 4)
              ;
            }
            *(undefined4 *)(param_1 + 0x194) = 0;
          }
        }
      }
      else if (9 < sVar12) {
        if (*(short *)(param_1 + 0xa6) < 0) {
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
        }
        else {
          *(undefined2 *)(param_1 + 0xa6) = 0;
        }
        *(undefined4 *)(param_1 + 0x2c) = 0;
        *(undefined4 *)(param_1 + 0x24) = 0;
        .debug::_UpdateRadialPos(param_1);
        .debug::_UpdateRadiusSprites(param_1,0,0);
        *(undefined4 *)(param_1 + 0x194) = 0;
      }
    }
    else if (sVar12 == 0x15) {
      *(undefined4 *)(param_1 + 0x2c) = 0;
      *(undefined4 *)(param_1 + 0x24) = 0;
      if (*(short *)(param_1 + 0xa6) < 0) {
        *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
      }
      else {
        *(undefined2 *)(param_1 + 0xa6) = 0;
      }
      if ((*(char *)(param_1 + 0x186) != '\0') && (-1 < *(short *)(param_1 + 0xa6))) {
        *(undefined2 *)(param_1 + 0xb2) = 1;
        .debug::_RadialWheelStep(param_1,0x100);
      }
      .debug::_UpdateRadialPos(param_1);
      .debug::_UpdateRadiusSprites(param_1,0,0);
      *(undefined1 *)(param_1 + 0x186) = 0;
      if (*(short *)(param_1 + 0xb2) == 1) {
        *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0xb2) = 0;
        *(int *)(*(int *)(*(int *)(param_1 + 0x1d4) + 0x198) + 0x18) =
             *(int *)(*(int *)(param_1 + 0x198) + 0x18) + 0xb400;
        *(undefined4 *)(*(int *)(*(int *)(param_1 + 0x1d4) + 0x198) + 0x14) =
             *(undefined4 *)(*(int *)(param_1 + 0x198) + 0x14);
        **(undefined4 **)(*(int *)(param_1 + 0x1d4) + 0x198) = **(undefined4 **)(param_1 + 0x198);
        *(undefined4 *)(*(int *)(*(int *)(param_1 + 0x1d4) + 0x198) + 4) =
             *(undefined4 *)(*(int *)(param_1 + 0x198) + 4);
      }
      *(undefined4 *)(param_1 + 0x194) = 0;
    }
    else if (sVar12 < 0x15) {
      if (0x13 < sVar12) {
        *(undefined4 *)(param_1 + 0x2c) = 0;
        *(undefined4 *)(param_1 + 0x24) = 0;
        if (*(short *)(param_1 + 0xa6) < 0) {
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
        }
        else {
          *(undefined2 *)(param_1 + 0xa6) = 0;
        }
        if ((*(char *)(param_1 + 0x186) != '\0') && (-1 < *(short *)(param_1 + 0xa6))) {
          *(undefined2 *)(param_1 + 0xb2) = 1;
          .debug::_RadialWheelStep(param_1,0x100);
        }
        .debug::_UpdateRadialPos(param_1);
        .debug::_UpdateRadiusSprites(param_1,0,0);
        *(undefined1 *)(param_1 + 0x186) = 0;
        if (*(short *)(param_1 + 0xb2) == 1) {
          *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0xb2) = 0;
          *(undefined2 *)(*(int *)(param_1 + 0x1d8) + 0xb2) = 0;
          *(int *)(*(int *)(*(int *)(param_1 + 0x1d4) + 0x198) + 0x18) =
               *(int *)(*(int *)(param_1 + 0x198) + 0x18) + 0x7800;
          *(int *)(*(int *)(*(int *)(param_1 + 0x1d8) + 0x198) + 0x18) =
               *(int *)(*(int *)(param_1 + 0x198) + 0x18) + 0xf000;
          *(undefined4 *)(*(int *)(*(int *)(param_1 + 0x1d4) + 0x198) + 0x14) =
               *(undefined4 *)(*(int *)(param_1 + 0x198) + 0x14);
          *(undefined4 *)(*(int *)(*(int *)(param_1 + 0x1d8) + 0x198) + 0x14) =
               *(undefined4 *)(*(int *)(param_1 + 0x198) + 0x14);
          **(undefined4 **)(*(int *)(param_1 + 0x1d4) + 0x198) = **(undefined4 **)(param_1 + 0x198);
          *(undefined4 *)(*(int *)(*(int *)(param_1 + 0x1d4) + 0x198) + 4) =
               *(undefined4 *)(*(int *)(param_1 + 0x198) + 4);
          **(undefined4 **)(*(int *)(param_1 + 0x1d8) + 0x198) = **(undefined4 **)(param_1 + 0x198);
          *(undefined4 *)(*(int *)(*(int *)(param_1 + 0x1d8) + 0x198) + 4) =
               *(undefined4 *)(*(int *)(param_1 + 0x198) + 4);
        }
        *(undefined4 *)(param_1 + 0x194) = 0;
      }
    }
    else if (sVar12 < 0x17) {
      *(undefined4 *)(param_1 + 0x2c) = 0;
      *(undefined4 *)(param_1 + 0x24) = 0;
      if (*(short *)(param_1 + 0xa6) < 0) {
        *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
      }
      else {
        *(undefined2 *)(param_1 + 0xa6) = 0;
      }
      if ((*(char *)(param_1 + 0x186) != '\0') && (-1 < *(short *)(param_1 + 0xa6))) {
        *(undefined2 *)(param_1 + 0xb2) = 1;
        .debug::_RadialWheelStep(param_1,0x100);
      }
      .debug::_UpdateRadialPos(param_1);
      .debug::_UpdateRadiusSprites(param_1,0,0);
      *(undefined1 *)(param_1 + 0x186) = 0;
      if (*(short *)(param_1 + 0xb2) == 1) {
        *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0xb2) = 0;
        *(undefined2 *)(*(int *)(param_1 + 0x1d8) + 0xb2) = 0;
        *(undefined2 *)(*(int *)(param_1 + 0x1dc) + 0xb2) = 0;
        *(int *)(*(int *)(*(int *)(param_1 + 0x1d4) + 0x198) + 0x18) =
             *(int *)(*(int *)(param_1 + 0x198) + 0x18) + 0x5a00;
        *(int *)(*(int *)(*(int *)(param_1 + 0x1d8) + 0x198) + 0x18) =
             *(int *)(*(int *)(param_1 + 0x198) + 0x18) + 0xb400;
        *(int *)(*(int *)(*(int *)(param_1 + 0x1dc) + 0x198) + 0x18) =
             *(int *)(*(int *)(param_1 + 0x198) + 0x18) + 0x10e00;
        *(undefined4 *)(*(int *)(*(int *)(param_1 + 0x1d4) + 0x198) + 0x14) =
             *(undefined4 *)(*(int *)(param_1 + 0x198) + 0x14);
        *(undefined4 *)(*(int *)(*(int *)(param_1 + 0x1d8) + 0x198) + 0x14) =
             *(undefined4 *)(*(int *)(param_1 + 0x198) + 0x14);
        *(undefined4 *)(*(int *)(*(int *)(param_1 + 0x1dc) + 0x198) + 0x14) =
             *(undefined4 *)(*(int *)(param_1 + 0x198) + 0x14);
        **(undefined4 **)(*(int *)(param_1 + 0x1d4) + 0x198) = **(undefined4 **)(param_1 + 0x198);
        *(undefined4 *)(*(int *)(*(int *)(param_1 + 0x1d4) + 0x198) + 4) =
             *(undefined4 *)(*(int *)(param_1 + 0x198) + 4);
        **(undefined4 **)(*(int *)(param_1 + 0x1d8) + 0x198) = **(undefined4 **)(param_1 + 0x198);
        *(undefined4 *)(*(int *)(*(int *)(param_1 + 0x1d8) + 0x198) + 4) =
             *(undefined4 *)(*(int *)(param_1 + 0x198) + 4);
        **(undefined4 **)(*(int *)(param_1 + 0x1dc) + 0x198) = **(undefined4 **)(param_1 + 0x198);
        *(undefined4 *)(*(int *)(*(int *)(param_1 + 0x1dc) + 0x198) + 4) =
             *(undefined4 *)(*(int *)(param_1 + 0x198) + 4);
      }
      *(undefined4 *)(param_1 + 0x194) = 0;
    }
    goto LAB_10064968;
  }
  if (sVar12 < 0x582) {
    if (sVar12 == 0x33) {
      if (*(short *)(param_1 + 0xb2) == 10) {
        if (*(char *)(param_1 + 0x186) != '\0') {
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
        }
        *(undefined1 *)(param_1 + 0x186) = 0;
        if (*(short *)(param_1 + 0xa6) < 1) {
          *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
          if (*(short *)(param_1 + 0x46) == 1) {
            sVar12 = *(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 0xe);
            if (sVar12 == 0) {
              .debug::_STPlay3DSoundRand(*puVar3,1,0xab,*(undefined4 *)(param_1 + 0xe));
            }
            else {
              .debug::_STPlay3DSoundPitched
                        (*puVar3,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar12 * 0xf3b + 0x10000);
            }
          }
          if (2 < *(short *)(param_1 + 0x46)) {
            *(undefined1 *)(param_1 + 0x88) = 0;
          }
          if (6 < *(short *)(param_1 + 0x46)) {
            *(undefined4 *)(param_1 + 0xb8) = 0xb0001;
          }
          if (10 < *(short *)(param_1 + 0x46)) {
            *(undefined4 *)(param_1 + 0xb8) = 0xb0000;
          }
          if (0xe < *(short *)(param_1 + 0x46)) {
            *(undefined4 *)(param_1 + 0xb8) = 0xb0002;
          }
          if (0x12 < *(short *)(param_1 + 0x46)) {
            if (*(int *)(param_1 + 0x150) == -1) {
              *(undefined2 *)(param_1 + 0x46) = 7;
              *(undefined2 *)(param_1 + 0xb2) = 0xb;
            }
            else {
              .glue::SetRect(param_1 + 0x34,0,0,0,0);
              *(undefined2 *)(param_1 + 0x1ba) = 0;
            }
          }
        }
        else {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        if ((0 < *(int *)(param_1 + 0x150)) &&
           (*(int *)(param_1 + 0x150) < (int)*(short *)(param_1 + 0x46))) {
          *(undefined2 *)(param_1 + 0xb2) = 0xb;
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
      }
      else {
        .glue::SetRect(param_1 + 0x34,0x10,6,0x3d,0x1e);
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (4 < *(short *)(param_1 + 0x46)) {
          *(undefined4 *)(param_1 + 0xb8) = 0xb0002;
          *(undefined2 *)(param_1 + 0x1ba) = 32000;
        }
        if (8 < *(short *)(param_1 + 0x46)) {
          *(undefined4 *)(param_1 + 0xb8) = 0xb0000;
        }
        if (0xc < *(short *)(param_1 + 0x46)) {
          *(undefined4 *)(param_1 + 0xb8) = 0;
          *(undefined1 *)(param_1 + 0x88) = 1;
          .glue::SetRect(param_1 + 0x34,0x10,6,0x3d,0x1e);
          *(short *)(param_1 + 0xa6) = (short)*(undefined4 *)(param_1 + 0x14c);
          *(undefined2 *)(param_1 + 0x46) = 0;
          *(undefined2 *)(param_1 + 0xb2) = 10;
        }
      }
    }
    else if (sVar12 < 0x33) {
      if (0x31 < sVar12) {
        .debug::_ApplyGravityAndSeparateFromTiles(param_1);
        if (*(short *)(param_1 + 0xb2) == 10) {
          if (*(char *)(param_1 + 0x186) != '\0') {
            *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
          }
          *(undefined1 *)(param_1 + 0x186) = 0;
          if (*(short *)(param_1 + 0xa6) < 1) {
            if (*(short *)(param_1 + 0x110) < 400) {
              *(short *)(param_1 + 0x110) = *(short *)(param_1 + 0x110) + 0x1e;
            }
          }
          else {
            *(undefined4 *)(param_1 + 0x2c) = 0;
            *(undefined2 *)(param_1 + 0x110) = 0;
          }
          if (*(int *)(param_1 + 0x15c) + *(int *)(param_1 + 0x150) < (int)*(short *)(param_1 + 10))
          {
            *(undefined2 *)(param_1 + 0xb2) = 0xb;
          }
        }
        else {
          *(undefined2 *)(param_1 + 0x110) = 0;
          *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + -0x32;
          if (*(int *)(param_1 + 0x2c) < -0x200) {
            *(undefined4 *)(param_1 + 0x2c) = 0xfffffe00;
          }
          if ((int)*(short *)(param_1 + 10) <= *(int *)(param_1 + 0x15c)) {
            *(undefined4 *)(param_1 + 0x2c) = 0;
            *(undefined2 *)(param_1 + 0x110) = 0;
            *(undefined2 *)(param_1 + 0xb2) = 10;
            *(short *)(param_1 + 0xa6) = (short)*(undefined4 *)(param_1 + 0x14c);
          }
        }
      }
    }
    else if (sVar12 < 0x35) {
      *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
      if (*(int *)(param_1 + 0x154) < (int)*(short *)(param_1 + 0xa6)) {
        *(undefined2 *)(param_1 + 0xa6) = 0;
      }
      if ((int)*(short *)(param_1 + 0xa6) < *(int *)(param_1 + 0x150)) {
        if (*(short *)(param_1 + 0x46) < 1) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        else {
          *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1;
        }
      }
      else if (*(short *)(param_1 + 0x46) < 0x14) {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      }
      else {
        *(undefined2 *)(param_1 + 0x46) = 0x14;
      }
      if (2 < *(short *)(param_1 + 0x46)) {
        *(undefined4 *)(param_1 + 0xb8) = 0;
        *(undefined2 *)(param_1 + 0x1ba) = 32000;
        *(undefined1 *)(param_1 + 0x88) = 1;
      }
      if (6 < *(short *)(param_1 + 0x46)) {
        *(undefined4 *)(param_1 + 0xb8) = 0xb0001;
        *(undefined1 *)(param_1 + 0x88) = 0;
      }
      if (10 < *(short *)(param_1 + 0x46)) {
        *(undefined4 *)(param_1 + 0xb8) = 0xb0000;
      }
      if (0xe < *(short *)(param_1 + 0x46)) {
        *(undefined4 *)(param_1 + 0xb8) = 0xb0002;
      }
      if (*(short *)(param_1 + 0x46) < 0x13) {
        .glue::SetRect(param_1 + 0x34,0x10,6,0x3d,0x1e);
      }
      else {
        .glue::SetRect(param_1 + 0x34,0,0,0,0);
        *(undefined2 *)(param_1 + 0x1ba) = 0;
      }
    }
    goto LAB_10064968;
  }
  if (sVar12 != 0x58c) {
    if ((sVar12 < 0x58c) && (sVar12 < 0x584)) {
      sVar12 = 0;
      if (((*(char *)(*(int *)(param_1 + 0x1d4) + 0x186) != '\0') &&
          (*(short *)(param_1 + 0x46) == 0)) || (0 < *(short *)(param_1 + 0x46))) {
        if (*(short *)(param_1 + 0x46) == 0) {
          .debug::_STPlay3DSoundRand(*_DAT_100a039c,1,0x100,*(undefined4 *)(param_1 + 0xe));
        }
        if (*(short *)(param_1 + 0x46) == 6) {
          .debug::_STPlay3DSoundRand(*_DAT_100a0398,1,0x100,*(undefined4 *)(param_1 + 0xe));
        }
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (*(short *)puVar5 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        sVar12 = *(short *)(puVar5 + *(short *)(param_1 + 0x46) * 2 + 2);
      }
      if ((sVar12 == 5) && (iVar13 = *(int *)(*(int *)(param_1 + 0x1d4) + 0xe0), iVar13 != 0)) {
        iVar11 = 6000;
        if (*(char *)(param_1 + 0x17e) != '\0') {
          iVar11 = -6000;
        }
        if (iVar13 == *_DAT_1009fdd8) {
          *(undefined4 *)(*_DAT_1009fdd8 + 0x14c) = 1;
        }
        iVar13 = *(int *)(*(int *)(param_1 + 0x1d4) + 0xe0);
        *(int *)(iVar13 + 0x24) = *(int *)(iVar13 + 0x24) + iVar11;
        iVar13 = *(int *)(*(int *)(param_1 + 0x1d4) + 0xe0);
        *(int *)(iVar13 + 0x2c) = *(int *)(iVar13 + 0x2c) + -0x9c4;
      }
      if (*(char *)(*(int *)(param_1 + 0x1d4) + 0x186) != '\0') {
        *(undefined1 *)(*(int *)(param_1 + 0x1d4) + 0x186) = 0;
      }
      *(int *)(param_1 + 0xc0) = *_DAT_100a0964 + sVar12 * 0x34;
      switch((int)sVar12) {
      case 0:
        unaff_r27 = 2;
        unaff_r26 = 0x80;
        break;
      case 1:
        unaff_r27 = 3;
        unaff_r26 = 0x89;
        break;
      case 2:
        unaff_r27 = 5;
        unaff_r26 = 0x92;
        break;
      case 3:
        unaff_r27 = 0x23;
        unaff_r26 = 0x36;
        break;
      case 4:
        unaff_r27 = 0x78;
        unaff_r26 = 0x19;
        break;
      case 5:
        unaff_r27 = 0x96;
        unaff_r26 = 0x11;
        break;
      case 6:
        unaff_r27 = 0xc1;
        unaff_r26 = 0x15;
      }
      if (*(char *)(param_1 + 0x17e) != '\0') {
        iVar13 = .debug::_FlipHCoord(unaff_r27,0xd8);
        unaff_r27 = iVar13 + -0x18;
      }
      if (*(char *)(param_1 + 0x17e) == '\0') {
        sVar12 = 0x74;
      }
      else {
        sVar12 = .debug::_FlipHCoord(0x74,0xd8);
        sVar12 = sVar12 + -0x2d;
      }
      if (*(int *)(param_1 + 0x1d4) != 0) {
        *(short *)(*(int *)(param_1 + 0x1d4) + 0xc) = *(short *)(param_1 + 0xc) + (short)unaff_r27;
        *(short *)(*(int *)(param_1 + 0x1d4) + 10) = *(short *)(param_1 + 10) + unaff_r26;
        *(int *)(*(int *)(param_1 + 0x1d4) + 0x14) =
             (int)*(short *)(*(int *)(param_1 + 0x1d4) + 0xc) << 8;
        *(int *)(*(int *)(param_1 + 0x1d4) + 0x1c) =
             (int)*(short *)(*(int *)(param_1 + 0x1d4) + 10) << 8;
      }
      if (*(int *)(param_1 + 0x1d8) != 0) {
        *(short *)(*(int *)(param_1 + 0x1d8) + 0xc) = *(short *)(param_1 + 0xc) + sVar12;
        *(short *)(*(int *)(param_1 + 0x1d8) + 10) = *(short *)(param_1 + 10) + 0x68;
        *(int *)(*(int *)(param_1 + 0x1d8) + 0x14) =
             (int)*(short *)(*(int *)(param_1 + 0x1d8) + 0xc) << 8;
        *(int *)(*(int *)(param_1 + 0x1d8) + 0x1c) =
             (int)*(short *)(*(int *)(param_1 + 0x1d8) + 10) << 8;
      }
    }
    goto LAB_10064968;
  }
  uVar6 = *(undefined4 *)(param_1 + 10);
  uVar15 = *(undefined4 *)(param_1 + 0x2c);
  *(short *)(param_1 + 10) = (short)*(undefined4 *)(param_1 + 0x14c);
  uVar7 = *(undefined4 *)(param_1 + 0x14c);
  sStack_52 = (short)uVar6;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
  .glue::SetRect(param_1 + 0x34,5,0,0x2d,0x32);
  *(undefined4 *)(param_1 + 0x2c) = *(undefined4 *)(param_1 + 0x154);
  .debug::_ApplyGravityAndSeparateFromTiles(param_1);
  *(undefined4 *)(param_1 + 0x154) = *(undefined4 *)(param_1 + 0x2c);
  *(undefined4 *)(param_1 + 0x2c) = uVar15;
  sVar12 = *(short *)(param_1 + 10);
  sStack_52 = *(short *)(param_1 + 0xc) - sStack_52;
  *(undefined4 *)(param_1 + 10) = uVar6;
  sVar12 = (short)((uint)*(undefined4 *)(param_1 + 0x154) >> 8) + (sVar12 - (short)uVar7);
  iVar14 = (int)sVar12;
  iVar13 = sStack_52 * 0x100;
  iVar11 = iVar14 * 0x100;
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
  *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + iVar14;
  *(int *)(param_1 + 0x150) = *(int *)(param_1 + 0x150) + iVar14;
  *(short *)(param_1 + 0xc) = *(short *)(param_1 + 0xc) + sStack_52;
  *(short *)(param_1 + 10) = *(short *)(param_1 + 10) + sVar12;
  *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + iVar13;
  *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + iVar11;
  *(short *)(*(int *)(param_1 + 0x1d4) + 0xc) =
       *(short *)(*(int *)(param_1 + 0x1d4) + 0xc) + sStack_52;
  *(short *)(*(int *)(param_1 + 0x1d4) + 10) = *(short *)(*(int *)(param_1 + 0x1d4) + 10) + sVar12;
  *(int *)(*(int *)(param_1 + 0x1d4) + 0x14) = *(int *)(*(int *)(param_1 + 0x1d4) + 0x14) + iVar13;
  *(int *)(*(int *)(param_1 + 0x1d4) + 0x1c) = *(int *)(*(int *)(param_1 + 0x1d4) + 0x1c) + iVar11;
  *(short *)(*(int *)(param_1 + 0x1d8) + 0xc) =
       *(short *)(*(int *)(param_1 + 0x1d8) + 0xc) + sStack_52;
  *(short *)(*(int *)(param_1 + 0x1d8) + 10) = *(short *)(*(int *)(param_1 + 0x1d8) + 10) + sVar12;
  *(int *)(*(int *)(param_1 + 0x1d8) + 0x14) = *(int *)(*(int *)(param_1 + 0x1d8) + 0x14) + iVar13;
  *(int *)(*(int *)(param_1 + 0x1d8) + 0x1c) = *(int *)(*(int *)(param_1 + 0x1d8) + 0x1c) + iVar11;
  iVar11 = (int)*(short *)(param_1 + 10);
  iVar13 = *(int *)(param_1 + 0x150);
  if (iVar11 < iVar13) {
    if ((iVar11 < *(int *)(param_1 + 0x14c)) && (*(int *)(param_1 + 0x2c) < 0)) {
      *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + 600;
    }
    else {
      *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + (iVar13 - iVar11) * 0x10;
    }
  }
  else if (iVar11 < *(int *)(param_1 + 0x14c) + 0x29) {
    if (iVar11 == iVar13) {
      iVar13 = *(int *)(param_1 + 0x2c);
      if (iVar13 < 1) {
        iVar13 = -iVar13;
      }
      if (iVar13 < 0xdc) {
        *(undefined4 *)(param_1 + 0x2c) = 0;
        goto LAB_10064800;
      }
    }
    .debug::_HandleFlotation(param_1);
  }
  else {
    *(short *)(param_1 + 10) = (short)*(int *)(param_1 + 0x14c) + 0x28;
    if (0 < *(int *)(param_1 + 0x2c)) {
      *(int *)(param_1 + 0x2c) = -*(int *)(param_1 + 0x2c);
    }
  }
LAB_10064800:
  if (*(char *)(param_1 + 0x186) == '\0') {
LAB_10064850:
    *(undefined4 *)(param_1 + 0x194) = 0;
  }
  else {
    if ((int)*(short *)(param_1 + 10) <= *(int *)(param_1 + 0x150)) goto LAB_10064850;
    iVar13 = (int)*(short *)(param_1 + 10) - *(int *)(param_1 + 0x150);
    if (0x1c < iVar13) {
      iVar13 = 0x1c;
    }
    *(int *)(param_1 + 0x194) = iVar13 * -0x80;
    if (0 < *(int *)(param_1 + 0x194)) {
      *(undefined4 *)(param_1 + 0x194) = 0xffffffff;
    }
  }
  if (0 < *(int *)(param_1 + 0x194)) {
    *(undefined4 *)(param_1 + 0x194) = 0;
  }
  *(short *)(*(int *)(param_1 + 0x1d8) + 0xc) = *(short *)(param_1 + 0xc) + 0xe;
  *(short *)(*(int *)(param_1 + 0x1d8) + 10) =
       (short)((uint)(*(int *)(param_1 + 0x1c) + *(int *)(param_1 + 0x2c)) >> 8) + 10;
  *(int *)(*(int *)(param_1 + 0x1d8) + 0x1c) = (int)*(short *)(*(int *)(param_1 + 0x1d8) + 10) << 8;
  uVar8 = (uint)(short)(((short)*(undefined4 *)(param_1 + 0x14c) + 0x2d) -
                       (short)((uint)(*(int *)(param_1 + 0x1c) + *(int *)(param_1 + 0x2c)) >> 8));
  uVar1 = uVar8 << 8;
  iVar13 = (int)uVar1 / 0x2d + ((int)(uVar1 | uVar8 >> 0x18) >> 0x1f);
  iVar13 = (int)(short)((short)iVar13 - (short)(iVar13 >> 0x1f));
  if (iVar13 < 0xb) {
    *(undefined4 *)(*(int *)(param_1 + 0x1d8) + 0xc0) = 0;
    *(undefined4 *)(*(int *)(param_1 + 0x1d8) + 0xb8) = 0;
  }
  else {
    if (iVar13 < 0xfb) {
      *(int *)(*(int *)(param_1 + 0x1d8) + 0xb8) = iVar13 + 0xa0000;
    }
    else {
      *(undefined4 *)(*(int *)(param_1 + 0x1d8) + 0xb8) = 0;
    }
    *(undefined4 *)(*(int *)(param_1 + 0x1d8) + 0xc0) = *_DAT_100a0978;
  }
  .glue::SetRect(param_1 + 0x34,5,0,0x2d,
                 0x32 - ((int)*(short *)(param_1 + 10) - *(int *)(param_1 + 0x14c)));
LAB_10064968:
  if (((*(short *)(param_1 + 0xb0) == 3) || (*(short *)(param_1 + 0xb0) == 4)) ||
     (*(short *)(param_1 + 4) == 0x6a4)) {
    if (((*(short *)(param_1 + 4) == 0x6a4) && (*(short *)(param_1 + 0x19e) < 0x50)) &&
       (sVar12 = .debug::_FastRand(2), sVar12 == 1)) {
      *(short *)(param_1 + 0x19e) = *(short *)(param_1 + 0x19e) + 1;
    }
    if ((*(int *)(param_1 + 0x11c) == 0) && (*(int *)(param_1 + 0x120) == 0)) {
      *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + (int)*(short *)(param_1 + 0x110);
    }
    if (*(short *)(param_1 + 0xb0) == 3) {
      sVar12 = 0;
      if ((*(char *)(param_1 + 0x186) != '\0') && (*(int *)(param_1 + 0xe0) != 0)) {
        sVar9 = *(short *)(*(int *)(param_1 + 0xe0) + 0x10) - *(short *)(param_1 + 0x10);
        iVar13 = (int)sVar9;
        if (sVar9 < 1) {
          iVar13 = -iVar13;
        }
        iVar13 = iVar13 / 5 + (iVar13 >> 0x1f);
        sVar12 = (short)iVar13 - (short)(iVar13 >> 0x1f);
        if (0 < sVar9) {
          sVar12 = -sVar12;
        }
        *(undefined1 *)(param_1 + 0x186) = 0;
      }
      sVar9 = *(short *)(param_1 + 0x46);
      if ((int)sVar9 < sVar12 + -1) {
        *(short *)(param_1 + 0x46) = sVar9 + 2;
      }
      else if (sVar12 + 1 < (int)sVar9) {
        *(short *)(param_1 + 0x46) = sVar9 + -2;
      }
      sVar12 = *(short *)(param_1 + 0x46);
      if (sVar12 < 0) {
        sVar12 = sVar12 + 0x168;
      }
      *(short *)(param_1 + 0x1aa) = sVar12;
      *(undefined1 *)(param_1 + 0x88) = 0;
      *(undefined1 *)(param_1 + 0x89) = 1;
    }
    .debug::_ApplyFriction(param_1,100);
    if (0 < *(short *)(param_1 + 0xa6)) {
      *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
      if (*(short *)(param_1 + 0xa6) < 1) {
        .debug::_ExplodeFaceIntoParticles
                  (*(undefined4 *)(param_1 + 0xc0),*(undefined4 *)(param_1 + 10),1,2,4,0x32,100);
        *(undefined1 *)(param_1 + 0xe9) = 1;
      }
      if (*(short *)(param_1 + 0xa6) < 0x2d) {
        if (*_DAT_1009fd30 == '\0') {
          *(undefined1 *)(param_1 + 0x88) = 1;
          *(undefined4 *)(param_1 + 0xb8) = 0;
          *(int *)(param_1 + 0xc0) = *piVar4 + *(int *)(param_1 + 0x16c) * 0x34;
        }
        else {
          *(undefined1 *)(param_1 + 0x88) = 1;
          *(int *)(param_1 + 0xc0) = *piVar4 + *(int *)(param_1 + 0x16c) * 0x34;
          *(undefined4 *)(param_1 + 0xb8) = 0xb0000;
        }
      }
    }
  }
  if ((*(short *)(param_1 + 0xb0) < 10) || (0x58b < *(short *)(param_1 + 0xb0))) {
    *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + *(int *)(param_1 + 0x24);
    *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + *(int *)(param_1 + 0x2c);
  }
  if (*(short *)(param_1 + 0xb0) == 2) {
    iVar13 = (int)*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 0x10);
    iVar11 = *(int *)(param_1 + 0x1c) >> 8;
    if (iVar11 == iVar13) {
      _DAT_100a6312 = 0x100;
      *PTR_DAT_100a094c = 0;
    }
    else if (iVar13 < iVar11) {
      iVar13 = *(int *)(param_1 + 0x2c);
      if (iVar13 < 1) {
        if (-0x180 < iVar13) {
          *(int *)(param_1 + 0x2c) = iVar13 + -0x40;
        }
      }
      else {
        *(int *)(param_1 + 0x2c) = iVar13 >> 1;
        if (*(int *)(param_1 + 0x2c) < 0x81) {
          *(undefined4 *)(param_1 + 0x2c) = 0xffffff80;
        }
      }
    }
    else {
      *(int *)(param_1 + 0x1c) = iVar13 << 8;
    }
  }
  sVar12 = *(short *)(param_1 + 0xb0);
  if (sVar12 < 10) {
    uVar10 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
    *(undefined2 *)(param_1 + 8) = uVar10;
    *(undefined2 *)(param_1 + 0xc) = uVar10;
    uVar10 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
    *(undefined2 *)(param_1 + 6) = uVar10;
    *(undefined2 *)(param_1 + 10) = uVar10;
    .debug::_SeparateFromTiles2(param_1);
    uVar10 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
    *(undefined2 *)(param_1 + 8) = uVar10;
    *(undefined2 *)(param_1 + 0xc) = uVar10;
    uVar10 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
    *(undefined2 *)(param_1 + 6) = uVar10;
    *(undefined2 *)(param_1 + 10) = uVar10;
  }
  else if (((sVar12 < 0x58c) && (sVar12 != 0x1e)) && (sVar12 != 0x32)) {
    if ((*(short *)(param_1 + 4) == 0x582) || (*(short *)(param_1 + 4) == 0x583)) {
      .debug::_ApplyFriction(param_1,(int)*(short *)(param_1 + 0x114));
      .debug::_ApplyGravityAndSeparateFromTiles(param_1);
    }
    else {
      .debug::_SeparateFromTiles2(param_1);
    }
  }
  else if (0x58b < sVar12) {
    uVar10 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
    *(undefined2 *)(param_1 + 8) = uVar10;
    *(undefined2 *)(param_1 + 0xc) = uVar10;
    uVar10 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
    *(undefined2 *)(param_1 + 6) = uVar10;
    *(undefined2 *)(param_1 + 10) = uVar10;
  }
  .debug::_StandardSpriteCleanup(param_1);
  return;
}


// ==== .HitPlatformSprite @ 10064d94 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitPlatformSprite(int param_1,int param_2)

{
  short sVar1;
  undefined4 uVar2;
  short sStack_18;
  short sStack_16;
  
  if (*(undefined **)(param_2 + 0x4c) == PTR_PTR_100a04e8) {
    if (*(short *)(param_2 + 4) == 1) {
      *(undefined1 *)(param_2 + 0xe9) = 1;
      *(undefined4 *)(param_1 + 400) = 0;
      .debug::_TurnIntoStatue(param_1);
    }
  }
  else if (*(undefined **)(param_2 + 0x4c) == _DAT_100a0200) {
    sVar1 = *(short *)(param_1 + 0xb0);
    uVar2 = *(undefined4 *)(param_1 + 0x2c);
    if ((((sVar1 != 4) && (sVar1 != 3)) ||
        ((*(short *)(param_2 + 0xb0) != 4 && (*(short *)(param_2 + 0xb0) != 3)))) &&
       ((((sVar1 < 0x582 || (0x585 < sVar1)) || (*(short *)(param_2 + 0xb0) < 0x582)) ||
        (0x585 < *(short *)(param_2 + 0xb0))))) {
      sStack_16 = *(short *)(param_1 + 0x36) +
                  (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
      sStack_18 = *(short *)(param_1 + 0x34) +
                  (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
      if (*(short *)(param_1 + 0xb0) == 0x58c) {
        *(undefined4 *)(param_1 + 0x2c) = *(undefined4 *)(param_1 + 0x154);
      }
      .debug::_PlatformBounce(param_1,param_2,&sStack_18,0,param_1 + 0x34,0);
      if (*(short *)(param_1 + 0xb0) == 0x58c) {
        *(undefined4 *)(param_1 + 0x154) = *(undefined4 *)(param_1 + 0x2c);
        *(undefined4 *)(param_1 + 0x2c) = uVar2;
      }
    }
  }
  return;
}


// ==== .HitPlatformTileSprite @ 10064f04 ====

void _HitPlatformTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  short sVar1;
  int iVar2;
  undefined4 uVar3;
  char cVar4;
  undefined4 uVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  undefined4 uVar8;
  undefined4 uStack_58;
  short sStack_4c;
  short sStack_4a;
  undefined1 auStack_2c [24];
  
  uVar5 = *(undefined4 *)(param_1 + 0x34);
  uVar3 = *(undefined4 *)(param_1 + 0x38);
  if ((param_4 == 1) && (*(short *)(param_1 + 0xb0) == 4)) {
    .glue::SetRect(param_1 + 0x34,0,0xfffffffa,0x28,6);
  }
  sStack_4a = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_4c = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  .glue::SetRect(auStack_2c,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                 (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
  if (param_4 == 1) {
    uVar6 = 0x80;
    uVar8 = *(undefined4 *)(param_1 + 0x14);
    uVar7 = *(undefined4 *)(param_1 + 0x1c);
    if (*(short *)(param_1 + 4) == 0x58c) {
      iVar2 = *(int *)(param_1 + 0x154);
      if (iVar2 < 1) {
        iVar2 = -iVar2;
      }
      if (iVar2 < 0x200) {
        uVar6 = 0;
      }
    }
    if (*(short *)(param_1 + 0xb0) == 0x32) {
      uVar6 = 0x20;
    }
    cVar4 = .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_4c,uVar6,param_1 + 0x34,0,1
                               );
    if (cVar4 != '\0') {
      sVar1 = *(short *)(param_1 + 0xb0);
      if ((sVar1 < 10) || (0x1d < sVar1)) {
        if (sVar1 == 0x32) {
          *(undefined2 *)(param_1 + 0xb2) = 0xb;
          *(short *)(param_1 + 10) = *(short *)(param_1 + 10) + -1;
          *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
        }
      }
      else {
        *(undefined4 *)(param_1 + 0x14) = uVar8;
        *(undefined4 *)(param_1 + 0x1c) = uVar7;
        *(short *)(param_1 + 0xc) = (short)((uint)uVar8 >> 8);
        *(short *)(param_1 + 10) = (short)((uint)uVar7 >> 8);
        *(undefined4 *)(param_1 + 6) = *(undefined4 *)(param_1 + 10);
        if ((*(short *)(param_1 + 0xa6) == 0) && (*(char *)(param_1 + 0x180) == '\0')) {
          uStack_58._2_2_ = (short)param_2;
          uStack_58._0_2_ = (short)((uint)param_2 >> 0x10);
          uStack_58 = CONCAT22(uStack_58._0_2_ + 0x10,uStack_58._2_2_ + 0x10);
          *(undefined2 *)(param_1 + 0xb2) = 1;
          if (*(int *)(param_1 + 0x1d4) != 0) {
            *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0xb2) = 0;
            *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0xa6) = 0xfffb;
          }
          if (*(int *)(param_1 + 0x1d8) != 0) {
            *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0xb2) = 0;
            *(undefined2 *)(*(int *)(param_1 + 0x1d8) + 0xa6) = 0xfffb;
          }
          if (*(int *)(param_1 + 0x1dc) != 0) {
            *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0xb2) = 0;
            *(undefined2 *)(*(int *)(param_1 + 0x1dc) + 0xa6) = 0xfffb;
          }
          if (*(int *)(param_1 + 0x1e0) != 0) {
            *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0xb2) = 0;
            *(undefined2 *)(*(int *)(param_1 + 0x1e0) + 0xa6) = 0xfffb;
          }
          *(undefined2 *)(param_1 + 0xa6) = 0xfffb;
          .debug::_BounceRadial(param_1,uStack_58);
          .debug::_BounceRadial(*(undefined4 *)(param_1 + 0x1d4),uStack_58);
          .debug::_BounceRadial(*(undefined4 *)(param_1 + 0x1d8),uStack_58);
          .debug::_BounceRadial(*(undefined4 *)(param_1 + 0x1dc),uStack_58);
          .debug::_BounceRadial(*(undefined4 *)(param_1 + 0x1e0),uStack_58);
        }
        *(undefined1 *)(param_1 + 0x180) = 1;
      }
    }
  }
  else if ((short)param_3 < 100) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_4c,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 200) {
    .debug::_WallBounceBG(param_1,param_3 + -100,&stack0x0000001c,&sStack_4c,0,param_1 + 0x34,0,0);
  }
  else {
    cVar4 = .debug::_IsWaterTile(param_3);
    if ((cVar4 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
      .debug::_HandleUnderWater(param_1,param_2);
    }
  }
  if ((param_4 == 1) && (*(short *)(param_1 + 0xb0) == 4)) {
    *(undefined4 *)(param_1 + 0x34) = uVar5;
    *(undefined4 *)(param_1 + 0x38) = uVar3;
  }
  return;
}


// ==== .SetupChainSprite @ 100652c0 ====

void _SetupChainSprite(int param_1)

{
  .debug::_InitSprite();
  *(undefined **)(param_1 + 0x4c) = PTR_PTR_100a0948;
  if (*(short *)(param_1 + 4) == 0x59a) {
    .glue::SetRect(param_1 + 0x34,0,0,0x18,0x18);
  }
  else {
    .glue::SetRect(param_1 + 0x34,0,0,0x10,0x10);
  }
  *(undefined **)(param_1 + 0x1f8) = PTR_PTR_100a0944;
  *(undefined1 *)(param_1 + 0x13f) = 0;
  return;
}


// ==== .HandleChainSprite @ 10065374 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleChainSprite(int param_1)

{
  int *piVar1;
  short sVar2;
  int iVar3;
  
  piVar1 = _DAT_100a096c;
  sVar2 = *(short *)(param_1 + 4);
  if (sVar2 == 0x596) {
    sVar2 = *(short *)(param_1 + 0xb0);
    sVar2 = (short)((ulonglong)((longlong)(int)sVar2 * 0x2aaaaaab) >> 0x20) -
            ((short)((short)((int)sVar2 / 0x60000) + (sVar2 >> 0xf)) >> 0xf);
    if (sVar2 < 0x3c) {
      if (sVar2 < 0) {
        sVar2 = 0x3b;
      }
    }
    else {
      sVar2 = 0;
    }
    *(undefined1 *)(param_1 + 0x88) = 1;
    *(int *)(param_1 + 0xc0) = *piVar1 + sVar2 * 0x34;
  }
  else if (sVar2 == 0x59a) {
    *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0974;
    .debug::_MTChangeSpriteLayer(param_1,*(short *)(param_1 + 0x1ae) + -0x100);
    iVar3 = *(short *)(param_1 + 0xb0) + 0x5a;
    *(short *)(param_1 + 0x1aa) =
         (short)iVar3 +
         ((short)((ulonglong)((longlong)iVar3 * 0xb60b60b7) >> 0x28) -
         (short)(iVar3 / 0x168 + (iVar3 >> 0x1f) >> 0x1f)) * -0x168;
    *(undefined1 *)(param_1 + 0x88) = 0;
    if (*(short *)(param_1 + 0x1ae) == 0x100) {
      *(undefined1 *)(param_1 + 0x89) = 1;
    }
  }
  else if (sVar2 == 0x59c) {
    *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0970;
    .debug::_MTChangeSpriteLayer(param_1,*(short *)(param_1 + 0x1ae) + -0x100);
    iVar3 = *(short *)(param_1 + 0xb0) + 0x5a;
    *(short *)(param_1 + 0x1aa) =
         (short)iVar3 +
         ((short)((ulonglong)((longlong)iVar3 * 0xb60b60b7) >> 0x28) -
         (short)(iVar3 / 0x168 + (iVar3 >> 0x1f) >> 0x1f)) * -0x168;
    *(undefined1 *)(param_1 + 0x88) = 0;
  }
  return;
}


// ==== .SetupSeeSawSegSprite @ 10065508 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupSeeSawSegSprite(int param_1)

{
  undefined4 uVar1;
  undefined *puVar2;
  
  .debug::_InitSprite();
  uVar1 = _DAT_100a01c8;
  *(undefined1 *)(param_1 + 0x185) = 1;
  puVar2 = PTR_PTR_100a0944;
  *(undefined4 *)(param_1 + 0x4c) = uVar1;
  *(undefined4 *)(param_1 + 0x5c) = 0;
  *(undefined **)(param_1 + 0x1f8) = puVar2;
  *(undefined1 *)(param_1 + 0x13f) = 0;
  .glue::SetRect(param_1 + 0x34,0,0,0,0);
  .glue::SetRect(param_1 + 0x34,0,0,0x18,0x58);
  *(undefined2 *)(param_1 + 0xd2) = 0x57;
  *(undefined2 *)(param_1 + 0xd4) = 0x57;
  return;
}


// ==== .HandleSeeSawSegSprite @ 100655c8 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleSeeSawSegSprite(int param_1)

{
  int *piVar1;
  undefined4 uVar2;
  ushort uVar5;
  undefined4 uVar3;
  int iVar4;
  int iVar6;
  bool bVar7;
  
  .debug::_StandardSpriteHandles();
  piVar1 = _DAT_100a0968;
  if (*(short *)(param_1 + 4) == 0x59b) {
    uVar5 = *(ushort *)(param_1 + 0xb0);
    bVar7 = 0xb4 < (short)uVar5;
    if (bVar7) {
      uVar5 = -(uVar5 - 0x168);
    }
    if (0x59 < (short)uVar5) {
      uVar5 = 0x59 - (uVar5 - 0x5a);
      bVar7 = !bVar7;
    }
    *(undefined1 *)(param_1 + 0x88) = 1;
    *(int *)(param_1 + 0xc0) =
         *piVar1 + (short)(((short)uVar5 >> 1) + (ushort)((short)uVar5 < 0 && (uVar5 & 1) != 0)) *
                   0x34;
    *(bool *)(param_1 + 0x17e) = bVar7;
    if ((*(char *)(param_1 + 0x186) != '\0') && (*(short *)(param_1 + 0xb2) == 1)) {
      *(undefined1 *)(param_1 + 0x186) = 0;
      *(undefined1 *)(*(int *)(param_1 + 0x1d4) + 0x186) = 1;
      iVar6 = (int)(short)*(undefined4 *)(param_1 + 0x150);
      *(int *)(*(int *)(param_1 + 0x1d4) + 0x150) =
           ((iVar6 - (short)((short)*(undefined4 *)(param_1 + 0x14c) + 1)) * 0x100) / iVar6;
    }
    *(undefined4 *)(param_1 + 0x154) = 0;
    if ((((short)uVar5 < 0xb4) && (5 < (short)uVar5)) ||
       ((0xb3 < (short)uVar5 && ((short)uVar5 < 0x163)))) {
      uVar3 = *(undefined4 *)(param_1 + 0x34);
      uVar2 = *(undefined4 *)(param_1 + 0x38);
      *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
      *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
      iVar4 = (int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0xd2);
      iVar6 = (int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0xd4);
      if (iVar6 < iVar4) {
        iVar6 = iVar4;
      }
      *(short *)(param_1 + 0x38) = (short)iVar6 + 8;
      .debug::_SeparateFromTiles2(param_1);
      *(undefined4 *)(param_1 + 0x34) = uVar3;
      *(undefined4 *)(param_1 + 0x38) = uVar2;
    }
  }
  .debug::_StandardSpriteCleanup(param_1);
  return;
}


// ==== .HitChainTileSprite @ 10065798 ====

void _HitChainTileSprite(int param_1,undefined4 param_2,undefined4 param_3,short param_4)

{
  char cVar1;
  
  if (param_4 != 1) {
    cVar1 = .debug::_IsWaterTile(param_3);
    if ((cVar1 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
      .debug::_HandleUnderWater(param_1,param_2);
    }
  }
  return;
}


// ==== .SetupCrawlerSprite @ 100659a0 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupCrawlerSprite(int param_1)

{
  short sVar1;
  char *pcVar2;
  int *piVar3;
  undefined4 *puVar4;
  undefined *puVar5;
  undefined *puVar6;
  undefined *puVar7;
  int iVar8;
  int iVar9;
  int iVar10;
  undefined *puVar11;
  
  puVar11 = PTR_DAT_100a09b0;
  puVar4 = _DAT_100a0058;
  .debug::_InitSprite();
  puVar5 = PTR_PTR_100a04b8;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar7 = PTR_PTR_100a0994;
  *(undefined2 *)(param_1 + 0x86) = 0;
  puVar6 = PTR_PTR_100a0990;
  *(undefined4 *)(param_1 + 0x80) = 0xb;
  iVar10 = _DAT_100a09a8;
  *(undefined **)(param_1 + 0x4c) = puVar5;
  iVar9 = _DAT_100a09a4;
  *(undefined **)(param_1 + 0x5c) = puVar7;
  iVar8 = _DAT_100a09a0;
  *(undefined **)(param_1 + 0x1f8) = puVar6;
  *(undefined2 *)(param_1 + 0xa6) = 3;
  *(undefined1 *)(iVar10 + 1) = 1;
  *(undefined1 *)(iVar9 + 1) = 1;
  *(undefined1 *)(iVar8 + 1) = 1;
  *(undefined2 *)(param_1 + 0xb2) = 0xffff;
  if (*(short *)(*(int *)*puVar4 + *(short *)(param_1 + 0x48) * 0x10 + 8) == 0) {
    *(undefined2 *)(param_1 + 0xb0) = 0;
    *(undefined2 *)(param_1 + 0x110) = 0xfeaf;
    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)puVar11;
  }
  else {
    *(undefined2 *)(param_1 + 0xb0) = 2;
    *(undefined2 *)(param_1 + 0x110) = 0x151;
    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar11 + 4);
  }
  *(undefined4 *)(param_1 + 0x15c) = 300;
  sVar1 = *(short *)(*(int *)*puVar4 + *(short *)(param_1 + 0x48) * 0x10 + 10);
  if (sVar1 == 2) {
    *(undefined4 *)(param_1 + 0xb8) = 0x10003;
    *(undefined2 *)(param_1 + 0xa4) = 1000;
    *(undefined4 *)(param_1 + 0x154) = 1000;
    *(undefined4 *)(param_1 + 0x158) = 0x60e;
  }
  else if (sVar1 < 2) {
    if (sVar1 == 0) {
      *(undefined2 *)(param_1 + 0xa4) = 500;
      *(undefined4 *)(param_1 + 0x154) = 500;
      *(undefined4 *)(param_1 + 0x158) = 0x4b0;
    }
    else if (-1 < sVar1) {
      *(undefined4 *)(param_1 + 0xb8) = 0x10002;
      *(undefined2 *)(param_1 + 0xa4) = 300;
      *(undefined4 *)(param_1 + 0x154) = 300;
      *(undefined4 *)(param_1 + 0x158) = 0x352;
      *(undefined4 *)(param_1 + 0x15c) = 100;
    }
  }
  else if (sVar1 < 4) {
    *(undefined4 *)(param_1 + 0xb8) = 0x1000f;
    *(undefined2 *)(param_1 + 0xa4) = 0x640;
    *(undefined4 *)(param_1 + 0x154) = 0x640;
    *(undefined4 *)(param_1 + 0x158) = 2000;
    *(undefined4 *)(param_1 + 0x15c) = 200;
  }
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  .glue::SetRect(param_1 + 0x34,0x14,0xc,0x2c,0x21);
  pcVar2 = _DAT_1009fe8c;
  *(undefined4 *)(param_1 + 0x150) = 0xffffffff;
  piVar3 = _DAT_1009ffb4;
  if (*pcVar2 != '\0') {
    *(undefined1 *)(param_1 + 0x1b5) = 1;
    *piVar3 = *piVar3 + 1;
  }
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  return;
}


// ==== .HandleCrawlerSprite @ 10065c00 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleCrawlerSprite(int param_1)

{
  short *psVar1;
  short *psVar2;
  undefined4 *puVar3;
  int iVar4;
  uint uVar5;
  short sVar6;
  short sVar9;
  short sVar10;
  int iVar7;
  undefined4 uVar8;
  short sVar11;
  undefined4 uStack_38;
  
  iVar7 = _DAT_100a09a4;
  uVar8 = _DAT_1009ff38;
  psVar2 = _DAT_1009fd94;
  psVar1 = _DAT_1009fd90;
  sVar11 = 0;
  if (*(char *)(param_1 + 0xe9) != '\0') {
    return;
  }
  if (*(char *)(param_1 + 0x1b2) != '\0') {
    return;
  }
  .debug::_StandardSpriteHandles(param_1);
  *(undefined4 *)(param_1 + 0x80) = 0xb;
  if (*(short *)(param_1 + 0xb0) != 1) {
    if ((*(short *)(param_1 + 0xb0) == 2) && (0 < *(short *)(param_1 + 0xb2))) {
      iVar4 = 6 - *(short *)(param_1 + 0xb2);
      if (3 < iVar4) {
        iVar4 = 4;
      }
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar7 + iVar4 * 4 + 4);
    }
    else if ((*(int *)(param_1 + 0xc0) != *(int *)(iVar7 + 0x18)) ||
            (*(char *)(param_1 + 0xce) != '\0')) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (0xb < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0;
      }
      *(undefined4 *)(param_1 + 0xc0) =
           *(undefined4 *)(_DAT_100a09a8 + ((int)*(short *)(param_1 + 0x46) >> 1) * 4 + 4);
    }
  }
  sVar9 = *(short *)(param_1 + 0xb0);
  if (sVar9 == 2) {
    *(undefined2 *)(param_1 + 0x110) = 0x151;
    if (0 < *(short *)(param_1 + 0xb2)) {
      *(short *)(param_1 + 0xb2) = *(short *)(param_1 + 0xb2) + -1;
    }
    if (*(short *)(param_1 + 0xb2) == 0) {
      .debug::_STPlay3DSound(*_DAT_100a0278,1,0x100,*(undefined4 *)(param_1 + 0xe));
      iVar7 = .debug::_FastRand(1000);
      .debug::_SetSpriteSpeed(param_1,0,-2000 - iVar7);
      sVar9 = .debug::_FastRand(500);
      .debug::_AccelerateBasedOnSlope
                (param_1,-(int)sVar9 - *(int *)(param_1 + 0x158),*(int *)(param_1 + 0x158) << 1);
      sVar9 = .debug::_FastRand(10);
      *(short *)(param_1 + 0xa6) = sVar9 + 10;
      *(undefined4 *)(param_1 + 0x14c) = *(undefined4 *)(param_1 + 0x24);
      if (*(short *)(param_1 + 0x10) < *psVar2) {
        iVar7 = *(int *)(param_1 + 0x24);
        *(int *)(param_1 + 0x24) = -iVar7;
        *(int *)(param_1 + 0x14c) = -iVar7;
      }
      *(undefined2 *)(param_1 + 0xb2) = 0xffff;
    }
    if (*(char *)(param_1 + 0xce) != '\0') {
      if (*(short *)(param_1 + 0x10) + 0x3c < (int)*psVar2) {
        .debug::_AccelerateBasedOnSlope(param_1,0xfa,*(undefined4 *)(param_1 + 0x158));
      }
      else if ((int)*psVar2 < *(short *)(param_1 + 0x10) + -0x3c) {
        .debug::_AccelerateBasedOnSlope(param_1,0xffffff06,*(undefined4 *)(param_1 + 0x158));
      }
      if (0 < *(short *)(param_1 + 0xa6)) {
        *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
      }
      if ((*(short *)(param_1 + 0xa6) == 0) && (*(short *)(param_1 + 0xb2) == -1)) {
        iVar7 = (int)*(short *)(param_1 + 0x10) - (int)*psVar2;
        if (iVar7 < 1) {
          iVar7 = -iVar7;
        }
        if (iVar7 < 0x46) {
          iVar7 = (int)*(short *)(param_1 + 0xe) - (int)*psVar1;
          if (iVar7 < 1) {
            iVar7 = -iVar7;
          }
          if (iVar7 < 100) {
            *(undefined2 *)(param_1 + 0xb2) = 5;
          }
        }
      }
      if (((int)*(short *)(param_1 + 0xa4) <= *(int *)(param_1 + 0x15c)) &&
         (*(short *)(param_1 + 0xb2) == -1)) {
        *(undefined2 *)(param_1 + 0xb0) = 3;
      }
    }
    goto LAB_10066100;
  }
  if (1 < sVar9) {
    if (sVar9 == 4) {
      *(undefined2 *)(param_1 + 0x110) = 0x151;
    }
    else if (sVar9 < 4) {
      *(undefined2 *)(param_1 + 0x110) = 0x151;
      if ((*(short *)(param_1 + 0xa6) == 0) && (*(char *)(param_1 + 0xce) != '\0')) {
        iVar7 = .debug::_FastRand(400);
        .debug::_SetSpriteSpeed(param_1,0,-900 - iVar7);
        iVar7 = .debug::_FastRand(800);
        .debug::_AccelerateBasedOnSlope(param_1,-0x6a4 - iVar7,2000);
        *(undefined4 *)(param_1 + 0x14c) = *(undefined4 *)(param_1 + 0x24);
        if (*psVar2 < *(short *)(param_1 + 0x10)) {
          iVar7 = *(int *)(param_1 + 0x24);
          *(int *)(param_1 + 0x24) = -iVar7;
          *(int *)(param_1 + 0x14c) = -iVar7;
        }
        sVar9 = .debug::_FastRand(0x1e);
        *(short *)(param_1 + 0xa6) = sVar9 + 0x14;
      }
      if (*(char *)(param_1 + 0xce) == '\0') {
        *(undefined4 *)(param_1 + 0x24) = *(undefined4 *)(param_1 + 0x14c);
      }
      else {
        if ((*(short *)(param_1 + 0x10) < *psVar2) &&
           (uVar5 = *(uint *)(param_1 + 0x24), (int)uVar5 < 0)) {
          *(uint *)(param_1 + 0x24) = ((int)uVar5 >> 1) + (uint)((int)uVar5 < 0 && (uVar5 & 1) != 0)
          ;
        }
        else if ((*psVar2 < *(short *)(param_1 + 0x10)) &&
                (uVar5 = *(uint *)(param_1 + 0x24), 300 < (int)uVar5)) {
          *(uint *)(param_1 + 0x24) = ((int)uVar5 >> 1) + (uint)((int)uVar5 < 0 && (uVar5 & 1) != 0)
          ;
        }
        else {
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
        }
        if (*(short *)(param_1 + 0xa4) < 300) {
          *(undefined2 *)(param_1 + 0xb0) = 3;
        }
      }
    }
    goto LAB_10066100;
  }
  if (sVar9 != 0) {
    if (-1 < sVar9) {
      *(undefined2 *)(*(int *)*_DAT_100a0058 + *(short *)(param_1 + 0x48) * 0x10 + 8) = 1;
      *(undefined2 *)(param_1 + 0x110) = 0x151;
      if (*(char *)(param_1 + 0xce) != '\0') {
        *(undefined2 *)(param_1 + 0xb0) = 2;
      }
    }
    goto LAB_10066100;
  }
  *(undefined2 *)(param_1 + 0x110) = 0xfeaf;
  iVar7 = (int)*(short *)(param_1 + 0x10) - (int)*psVar2;
  if (iVar7 < 1) {
    iVar7 = -iVar7;
  }
  if (iVar7 < 0x8c) {
    iVar4 = (int)*(short *)(param_1 + 0xe) - (int)*psVar1;
    iVar7 = iVar4;
    if (iVar4 < 1) {
      iVar7 = -iVar4;
    }
    if ((0xdb < iVar7) || (-1 < iVar4)) goto LAB_10065d7c;
LAB_10065d90:
    *(undefined2 *)(param_1 + 0xb0) = 1;
  }
  else {
LAB_10065d7c:
    if ((int)*(short *)(param_1 + 0xa4) <= *(int *)(param_1 + 0x154) + -100) goto LAB_10065d90;
  }
  iVar7 = *(int *)(param_1 + 0x24);
  if (iVar7 < 1) {
    iVar7 = -iVar7;
  }
  if (0 < iVar7) {
    uVar5 = *(uint *)(param_1 + 0x24);
    *(uint *)(param_1 + 0x24) = ((int)uVar5 >> 1) + (uint)((int)uVar5 < 0 && (uVar5 & 1) != 0);
  }
LAB_10066100:
  if (*(short *)(param_1 + 0xa4) < 1) {
    *(undefined2 *)(param_1 + 0xb0) = 4;
  }
  if (*(short *)(param_1 + 0xb0) == 0) {
    *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
    if (1 < *(short *)(param_1 + 0x46)) {
      *(undefined2 *)(param_1 + 0x46) = 0;
    }
    *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a09ac;
  }
  else if (*(short *)(param_1 + 0xb0) == 4) {
    sVar9 = .debug::_FastRand(3);
    *(undefined4 *)(param_1 + 0x5c) = 0;
    if (*(int *)(param_1 + 0x150) == -1) {
      *(undefined4 *)(param_1 + 0x150) = 1;
    }
    if (0 < *(int *)(param_1 + 0x150)) {
      *(int *)(param_1 + 0x150) = *(int *)(param_1 + 0x150) + 1;
      sVar6 = (short)(*(int *)(param_1 + 0x150) + -2 >> 1);
      if (5 < sVar6) {
        sVar6 = 5;
      }
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a09a0 + sVar6 * 4 + 4);
      *(int *)(param_1 + 0x24) =
           (int)(((double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000) - dRam100a1a98
                 ) * dRam100a1aa0);
      if (0x15 < *(int *)(param_1 + 0x150)) {
        .debug::_STPlay3DSound(*_DAT_100a026c,1,0x100,*(undefined4 *)(param_1 + 0xe));
        *(undefined4 *)(param_1 + 0xc0) = 0;
        .debug::_KillCrawler(param_1);
        *_DAT_1009ffc0 = *_DAT_1009ffc0 + 500;
        for (sVar6 = 0; sVar6 < (short)(sVar9 + 2); sVar6 = sVar6 + 1) {
          iVar7 = .debug::_MTNewSprite
                            (0x516,*(short *)(param_1 + 0x10) + -4,*(short *)(param_1 + 0xe) + -4,2,
                             0xffffffff,uVar8);
          sVar10 = .debug::_FastRand(0x640);
          *(int *)(iVar7 + 0x2c) = -0x578 - sVar10;
          sVar10 = .debug::_FastRand(1000);
          *(int *)(iVar7 + 0x24) = sVar10 + -500;
        }
        for (sVar9 = 0; sVar9 < 100; sVar9 = sVar9 + 1) {
          uStack_38 = CONCAT22(*(short *)(param_1 + 0xe) + 6,*(short *)(param_1 + 0x10) + -1);
          iVar7 = .debug::_FastRand(700);
          iVar4 = .debug::_FastRand(600);
          .debug::_NewParticle(2,0x50,uStack_38,4,iVar4 + -300,-0x15e - iVar7,0,1);
        }
      }
    }
  }
  if (*(short *)(param_1 + 0x10) < *psVar2) {
    *(undefined1 *)(param_1 + 0x17e) = 1;
  }
  else if (*psVar2 < *(short *)(param_1 + 0x10)) {
    *(undefined1 *)(param_1 + 0x17e) = 0;
  }
  if ((*(short *)(param_1 + 0xb0) == 2) && (-1 < *(short *)(param_1 + 0xb2))) {
    uVar8 = *(undefined4 *)(param_1 + 0x24);
    *(undefined4 *)(param_1 + 0x24) = 0;
    sVar11 = (short)uVar8;
  }
  .debug::_ApplyGravityAndSeparateFromTiles(param_1);
  puVar3 = _DAT_100a0274;
  if ((*(int *)(param_1 + 0x11c) != 0) &&
     (((*(int *)(param_1 + 0x11c) == 1 && (*(short *)(param_1 + 0x128) == 0)) ||
      (0 < *(short *)(param_1 + 0x128))))) {
    sVar9 = *(short *)(param_1 + 0x128);
    if (sVar9 == 3) {
      if (*(short *)(param_1 + 0xa4) < 500) {
        *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + 4;
      }
    }
    else if (((sVar9 < 3) && (0 < sVar9)) && (*(short *)(param_1 + 0x116) == 0)) {
      *(undefined2 *)(param_1 + 0x116) = 0x13;
      *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -100;
      *(undefined2 *)(param_1 + 0xaa) = 0x11;
      .debug::_STPlay3DSound(*puVar3,1,0x55,*(undefined4 *)(param_1 + 0xe));
    }
  }
  if ((*(short *)(param_1 + 0xb0) == 2) && (-1 < *(short *)(param_1 + 0xb2))) {
    *(int *)(param_1 + 0x24) = (int)sVar11;
  }
  .debug::_StandardSpriteCleanup(param_1);
  return;
}


// ==== .HandleStatueSprite @ 100664a8 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleStatueSprite(int param_1)

{
  undefined2 uVar1;
  
  if (*(short *)(param_1 + 0x9a) == -1) {
    uVar1 = .debug::_AddLight(*_DAT_100a099c,*(undefined4 *)(param_1 + 0xe),0,0,0,0x21);
    *(undefined2 *)(param_1 + 0x9a) = uVar1;
  }
  *(undefined4 *)(param_1 + 0xb8) = 0x1000b;
  *(int *)(param_1 + 0x130) = *(int *)(param_1 + 0x130) + -1;
  *(undefined4 *)(param_1 + 0x2c) = 0;
  *(undefined4 *)(param_1 + 0x24) = 0;
  *(undefined4 *)(param_1 + 0x80) = 2;
  *(undefined4 *)(param_1 + 0x2c) = 0;
  *(undefined4 *)(param_1 + 0x24) = 0;
  if (((int)*(uint *)(param_1 + 0x130) < 0x14) && ((*(uint *)(param_1 + 0x130) & 1) != 0)) {
    *(undefined4 *)(param_1 + 0xb8) = 0;
  }
  if (*(int *)(param_1 + 0x130) < 1) {
    *(undefined4 *)(param_1 + 0x4c) = *(undefined4 *)(param_1 + 0x1ec);
    *(undefined4 *)(param_1 + 0x5c) = *(undefined4 *)(param_1 + 0x1f0);
    *(undefined4 *)(param_1 + 0x1f8) = *(undefined4 *)(param_1 + 500);
    *(undefined4 *)(param_1 + 0xb8) = *(undefined4 *)(param_1 + 0x134);
    *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -200;
    .debug::_RemoveLight(param_1 + 0x9a);
  }
  return;
}


// ==== .HitCrawlerSprite @ 100665bc ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitCrawlerSprite(int param_1,int param_2)

{
  undefined4 *puVar1;
  undefined4 *puVar2;
  int iVar3;
  char cVar6;
  int iVar4;
  short sVar5;
  undefined *puVar7;
  int iVar8;
  short sStack_28;
  short sStack_26;
  undefined8 uStack_20;
  undefined8 uStack_18;
  
  puVar2 = _DAT_100a0274;
  puVar1 = _DAT_100a0270;
  puVar7 = *(undefined **)(param_2 + 0x4c);
  if ((puVar7 == PTR_PTR_100a04e8) && (*(short *)(param_2 + 0xa6) == 0)) {
    .debug::_KillPlayerShot(param_2,0,0);
    if (*(short *)(param_2 + 4) == 1) {
      .debug::_TurnIntoStatue(param_1);
    }
    else {
      uStack_18 = (double)CONCAT44(0x43300000,*(uint *)(param_2 + 0x24) ^ 0x80000000);
      iVar8 = (int)(dRam100a1a90 * (uStack_18 - dRam100a1a98));
      uStack_20 = (double)(longlong)iVar8;
      cVar6 = .debug::_HurtSprite(param_1,(int)*(short *)(param_2 + 0xa4),iVar8,0xfffffc18,4,10);
      if (cVar6 != '\0') {
        iVar8 = *(int *)(param_1 + 0x24);
        if (iVar8 < 1) {
          iVar4 = -iVar8;
          iVar3 = -*(int *)(param_1 + 0x24);
        }
        else {
          iVar3 = *(int *)(param_1 + 0x24);
          iVar4 = iVar8;
        }
        if (iVar4 < iVar3) {
          if (iVar8 < 0) {
            iVar8 = -1;
            iVar4 = -1;
          }
          else {
            iVar8 = 1;
            iVar4 = 1;
          }
          if (iVar4 == iVar8) {
            uStack_20 = (double)CONCAT44(0x43300000,*(uint *)(param_2 + 0x24) ^ 0x80000000);
            iVar8 = (int)(dRam100a1a88 * (uStack_20 - dRam100a1a98));
            uStack_18 = (double)(longlong)iVar8;
            *(int *)(param_1 + 0x24) = iVar8;
          }
        }
        .debug::_BloodSpray(param_1,param_2,0x28,400,0x96,2);
        if (*(short *)(param_1 + 0xa4) < 0xc9) {
          .debug::_STPlay3DSound(*puVar1,1,0x100,*(undefined4 *)(param_1 + 0xe));
        }
        else if (0 < *(short *)(param_1 + 0xa4)) {
          .debug::_STPlay3DSound(*puVar2,1,0x100,*(undefined4 *)(param_1 + 0xe));
        }
      }
    }
  }
  else if ((puVar7 == PTR_PTR_100a01f8) || (puVar7 == PTR_PTR_100a0484)) {
    sStack_26 = *(short *)(param_1 + 0x36) +
                (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
    sStack_28 = *(short *)(param_1 + 0x34) +
                (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
    sVar5 = .debug::_PlatformBounce(param_1,param_2,&sStack_28,0,param_1 + 0x34,0);
    if ((sVar5 == 2) && ((0 < *(int *)(param_2 + 0x2c) || (*(char *)(param_1 + 0xce) != '\0')))) {
      *(undefined2 *)(param_1 + 0xa4) = 0;
      *(undefined4 *)(param_1 + 0x150) = 0x16;
    }
  }
  else if ((((puVar7 == PTR_PTR_100a0460) && (*(short *)(param_2 + 4) == 0x4b7)) &&
           (*(short *)(param_2 + 0x46) < 8)) ||
          ((*(short *)(param_2 + 4) == 0x5a0 &&
           ((*(int *)(param_2 + 0x14c) == 1 || (*(int *)(param_2 + 0x150) == 2)))))) {
    uStack_20 = (double)CONCAT44(0x43300000,*(uint *)(param_2 + 0x24) ^ 0x80000000);
    iVar8 = (int)(dRam100a1a90 * (uStack_20 - dRam100a1a98));
    uStack_18 = (double)(longlong)iVar8;
    cVar6 = .debug::_HurtSprite(param_1,100,iVar8,0xfffffc18,4,10);
    if (cVar6 != '\0') {
      iVar8 = *(int *)(param_1 + 0x24);
      if (iVar8 < 1) {
        iVar4 = -iVar8;
        iVar3 = -*(int *)(param_1 + 0x24);
      }
      else {
        iVar3 = *(int *)(param_1 + 0x24);
        iVar4 = iVar8;
      }
      if (iVar4 < iVar3) {
        if (iVar8 < 0) {
          iVar8 = -1;
          iVar4 = -1;
        }
        else {
          iVar8 = 1;
          iVar4 = 1;
        }
        if (iVar4 == iVar8) {
          uStack_20 = (double)CONCAT44(0x43300000,*(uint *)(param_2 + 0x24) ^ 0x80000000);
          iVar8 = (int)(dRam100a1a88 * (uStack_20 - dRam100a1a98));
          uStack_18 = (double)(longlong)iVar8;
          *(int *)(param_1 + 0x24) = iVar8;
        }
      }
      .debug::_BloodSpray(param_1,param_2,0x28,400,0x96,2);
      if (*(short *)(param_1 + 0xa4) < 0xc9) {
        .debug::_STPlay3DSound(*puVar1,1,0x100,*(undefined4 *)(param_1 + 0xe));
      }
      else if (0 < *(short *)(param_1 + 0xa4)) {
        .debug::_STPlay3DSound(*puVar2,1,0x100,*(undefined4 *)(param_1 + 0xe));
      }
    }
  }
  return;
}


// ==== .HitCrawlerTileSprite @ 10066aa4 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitCrawlerTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  char cVar1;
  short sStack_48;
  short sStack_46;
  undefined1 auStack_28 [28];
  
  sStack_46 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_48 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  if ((*_DAT_100a0064 != '\0') && (cVar1 = .debug::_IsPressed(0x32), cVar1 != '\0')) {
    return;
  }
  .glue::SetRect(auStack_28,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                 (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
  if (param_4 == 1) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 100) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 200) {
    .debug::_WallBounceBG(param_1,param_3 + -100,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else {
    cVar1 = .debug::_IsWaterTile(param_3);
    if ((cVar1 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
      .debug::_HandleUnderWater(param_1,param_2);
    }
  }
  return;
}


// ==== .SetupWalkerSprite @ 10067318 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupWalkerSprite(int param_1)

{
  short *psVar1;
  int *piVar2;
  undefined4 *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  undefined *puVar6;
  undefined *puVar7;
  int iVar8;
  int iVar9;
  int iVar10;
  int iVar11;
  int iVar12;
  int iVar13;
  int iVar14;
  short sVar15;
  
  iVar14 = _DAT_100a09f0;
  iVar13 = _DAT_100a09ec;
  iVar9 = _DAT_100a09dc;
  iVar8 = _DAT_100a09c0;
  puVar3 = _DAT_100a0058;
  psVar1 = _DAT_1009fd94;
  .debug::_InitSprite();
  puVar4 = PTR_PTR_100a0498;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar7 = PTR_PTR_100a09bc;
  *(undefined2 *)(param_1 + 0x86) = 0;
  puVar6 = PTR_PTR_100a09b8;
  *(undefined4 *)(param_1 + 0x80) = 4;
  puVar5 = PTR_PTR_100a09b4;
  *(undefined **)(param_1 + 0x4c) = puVar4;
  *(undefined **)(param_1 + 0x5c) = puVar7;
  *(undefined **)(param_1 + 0x1f8) = puVar6;
  *(undefined **)(param_1 + 0x50) = puVar5;
  *(undefined2 *)(param_1 + 0xa6) = 0;
  *(undefined4 *)(param_1 + 0x158) = 8;
  if ((*(short *)(param_1 + 4) == 0x6a4) || (*(short *)(param_1 + 4) == 0x6d6)) {
    *(undefined2 *)(param_1 + 0xb0) = 2;
  }
  else {
    *(undefined2 *)(param_1 + 0xb0) = 5;
  }
  if (*(short *)(param_1 + 4) == 0x6e0) {
    *(undefined1 *)(param_1 + 0x17e) = 1;
  }
  else {
    *(undefined1 *)(param_1 + 0x17e) = 0;
  }
  *(undefined1 *)(param_1 + 0x17c) = 0;
  *(undefined2 *)(param_1 + 0x110) = 0x151;
  *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar14 + 4);
  *(undefined2 *)(param_1 + 0xa4) = 500;
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  sVar15 = .debug::_FastRand(0x5fff);
  *(int *)(param_1 + 0xf0) = sVar15 * 2 + 0xbfff;
  iVar12 = _DAT_100a09e4;
  iVar11 = _DAT_100a09d8;
  iVar10 = _DAT_100a09d0;
  sVar15 = *(short *)(param_1 + 4);
  if (sVar15 == 0x6a4) {
    *(undefined1 *)(iVar14 + 1) = 1;
    iVar8 = _DAT_100a09e8;
    *(undefined1 *)(iVar12 + 1) = 1;
    *(undefined1 *)(iVar8 + 1) = 1;
    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar14 + 4);
    if ((int)*psVar1 < *(short *)(param_1 + 0xc) + 0x32) {
      *(undefined1 *)(param_1 + 0x17e) = 1;
    }
    .glue::SetRect(param_1 + 0x34,0x28,10,0x3c,0x46);
  }
  else if (sVar15 == 0x6a9) {
    *(undefined1 *)(iVar9 + 1) = 1;
    iVar8 = _DAT_100a09d4;
    *(undefined1 *)(iVar11 + 1) = 1;
    *(undefined1 *)(iVar8 + 1) = 1;
    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar9 + 4);
    if ((int)*psVar1 < *(short *)(param_1 + 0xc) + 0x32) {
      *(undefined1 *)(param_1 + 0x17e) = 1;
    }
    .glue::SetRect(param_1 + 0x34,0x4c,10,0x7c,0x47);
  }
  else if ((sVar15 < 0x6d6) || (0x6df < sVar15)) {
    if ((0x6df < sVar15) && (sVar15 < 0x6ea)) {
      *(undefined1 *)(iVar8 + 1) = 1;
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar8 + 4);
      if (*(short *)(param_1 + 0xc) + 0x32 < (int)*psVar1) {
        *(undefined1 *)(param_1 + 0x17e) = 1;
      }
      .glue::SetRect(param_1 + 0x34,0x17,0x1e,0x38,0x55);
    }
  }
  else {
    *(undefined1 *)(iVar13 + 1) = 1;
    iVar8 = _DAT_100a09c8;
    *(undefined1 *)(iVar10 + 1) = 1;
    iVar9 = _DAT_100a09cc;
    *(undefined1 *)(iVar8 + 1) = 1;
    iVar8 = _DAT_100a09c4;
    *(undefined1 *)(iVar9 + 1) = 1;
    *(undefined1 *)(iVar8 + 1) = 1;
    *(undefined2 *)(param_1 + 0xb0) = 1;
    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar13 + 4);
    if ((int)*psVar1 < *(short *)(param_1 + 0xc) + 0x32) {
      *(undefined1 *)(param_1 + 0x17e) = 1;
    }
    .glue::SetRect(param_1 + 0x34,0x5e,0x23,0x7f,0x5c);
  }
  sVar15 = *(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xc);
  if (sVar15 == 4) {
    *(undefined4 *)(param_1 + 0x158) = 4;
    *(undefined4 *)(param_1 + 0x100) = 1;
    if (*(short *)(param_1 + 4) == 0x6d6) {
      *(undefined2 *)(param_1 + 0xa4) = 2000;
    }
    else {
      *(undefined2 *)(param_1 + 0xa4) = 0x5dc;
    }
    *(undefined4 *)(param_1 + 0xb8) = 0x10013;
  }
  else if (sVar15 < 4) {
    if (sVar15 == 2) {
      *(undefined4 *)(param_1 + 0x158) = 6;
      if (*(short *)(param_1 + 4) == 0x6d6) {
        *(undefined2 *)(param_1 + 0xa4) = 0x4b0;
      }
      else {
        *(undefined2 *)(param_1 + 0xa4) = 0x2a3;
      }
      *(undefined4 *)(param_1 + 0xb8) = 0x10011;
    }
    else if (sVar15 < 2) {
      if (0 < sVar15) {
        *(undefined4 *)(param_1 + 0x158) = 0x10;
        if (*(short *)(param_1 + 4) == 0x6d6) {
          *(undefined2 *)(param_1 + 0xa4) = 500;
        }
        else {
          *(undefined2 *)(param_1 + 0xa4) = 0xfa;
        }
        *(undefined4 *)(param_1 + 0xb8) = 0x10010;
      }
    }
    else {
      *(undefined4 *)(param_1 + 0x158) = 0xd;
      if (*(short *)(param_1 + 4) == 0x6d6) {
        *(undefined2 *)(param_1 + 0xa4) = 0x690;
      }
      else {
        *(undefined2 *)(param_1 + 0xa4) = 0x3b6;
      }
      *(undefined4 *)(param_1 + 0xb8) = 0x10012;
    }
  }
  else if (sVar15 == 6) {
    *(undefined4 *)(param_1 + 0x158) = 6;
    if (*(short *)(param_1 + 4) == 0x6d6) {
      *(undefined2 *)(param_1 + 0xa4) = 0x546;
    }
    else {
      *(undefined2 *)(param_1 + 0xa4) = 0x2ee;
    }
    *(undefined4 *)(param_1 + 0xb8) = 0x10015;
  }
  else if (sVar15 < 6) {
    *(undefined4 *)(param_1 + 0x158) = 10;
    if (*(short *)(param_1 + 4) == 0x6d6) {
      *(undefined2 *)(param_1 + 0xa4) = 0x5dc;
    }
    else {
      *(undefined2 *)(param_1 + 0xa4) = 0x352;
    }
    *(undefined4 *)(param_1 + 0xb8) = 0x10014;
  }
  sVar15 = .debug::_FastRand(0x46);
  *(int *)(param_1 + 0x14c) = sVar15 + 0x78;
  *(undefined4 *)(param_1 + 0x150) = 0xffffffff;
  sVar15 = .debug::_FastRand(400);
  *(int *)(param_1 + 0x154) = sVar15 + 1000;
  if (*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xe) != 0) {
    *(undefined2 *)(param_1 + 0x1ce) = 0x5f4;
    *(undefined2 *)(param_1 + 0x1cc) = 0x5f4;
    *(undefined2 *)(param_1 + 0x1ca) = 0x5f4;
    *(undefined2 *)(param_1 + 0x1c8) = 0x5f4;
  }
  piVar2 = _DAT_1009ffb4;
  if (*_DAT_1009fe8c != '\0') {
    *(undefined1 *)(param_1 + 0x1b5) = 1;
    *piVar2 = *piVar2 + 1;
  }
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  return;
}


// ==== .HandleWalkerSprite @ 100683b8 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleWalkerSprite(int param_1)

{
  ushort uVar1;
  short *psVar2;
  ushort *puVar3;
  short *psVar4;
  int *piVar5;
  undefined4 *puVar6;
  undefined4 *puVar7;
  undefined4 *puVar8;
  undefined4 *puVar9;
  undefined *puVar10;
  int iVar11;
  int iVar12;
  int iVar13;
  int *piVar14;
  int iVar15;
  int iVar16;
  int iVar17;
  uint uVar18;
  undefined4 uVar19;
  short sVar21;
  int iVar20;
  short sVar22;
  undefined4 *puVar23;
  int iVar24;
  undefined8 uStack_68;
  undefined8 uStack_60;
  
  iVar16 = _DAT_100a09ec;
  iVar15 = _DAT_100a09e4;
  piVar14 = _DAT_100a09e0;
  iVar13 = _DAT_100a09dc;
  iVar12 = _DAT_100a09d8;
  iVar11 = _DAT_100a09d4;
  iVar24 = _DAT_100a09cc;
  iVar20 = _DAT_100a09c8;
  iVar17 = _DAT_100a09c0;
  puVar10 = PTR_PTR_100a0830;
  puVar9 = _DAT_100a0350;
  puVar8 = _DAT_100a0340;
  puVar7 = _DAT_100a0274;
  puVar23 = _DAT_100a026c;
  puVar6 = _DAT_100a0058;
  piVar5 = _DAT_1009ffc0;
  puVar3 = _DAT_1009fd94;
  psVar2 = _DAT_1009fd90;
  if (*(char *)(param_1 + 0xe9) != '\0') {
    return;
  }
  if (*(char *)(param_1 + 0x1b2) != '\0') {
    return;
  }
  .debug::_StandardSpriteHandles(param_1);
  if (*(char *)(param_1 + 0x17c) == '\0') {
    *(undefined1 *)(param_1 + 0x17c) = 1;
    if (*(char *)(param_1 + 0x17e) == '\0') {
      *(undefined2 *)(param_1 + 0xb4) = 3;
    }
    else {
      *(undefined2 *)(param_1 + 0xb4) = 0xfffd;
    }
  }
  *(undefined4 *)(param_1 + 0x80) = 0xb;
  if (0 < *(int *)(param_1 + 0x170)) {
    *(undefined4 *)(param_1 + 0x16c) = 0;
    *(int *)(param_1 + 0x170) = *(int *)(param_1 + 0x170) + -1;
  }
  if (*(short *)(param_1 + 0xb0) != 4) {
    .debug::_GoblinRandomCry(param_1);
  }
  sVar22 = *(short *)(param_1 + 4);
  if (sVar22 == 0x6a4) {
    sVar22 = *(short *)(param_1 + 0xb0);
    if (sVar22 != 3) {
      if (sVar22 < 3) {
        if (sVar22 == 1) {
          if (*(char *)(param_1 + 0xce) != '\0') {
            uVar1 = *puVar3;
            sVar22 = *(short *)(param_1 + 0x10);
            if ((short)uVar1 < sVar22) {
              sVar21 = uVar1 + (short)*(undefined4 *)(param_1 + 0x14c);
              if (sVar22 < (short)(sVar21 + -0x19)) {
                *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1;
                .debug::_SetSpriteSpeed(param_1,1000,0x200);
              }
              else if ((short)(sVar21 + 0x19) < sVar22) {
                *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
                .debug::_SetSpriteSpeed(param_1,0xfffffc18,0x200);
              }
              else {
                sVar22 = *(short *)(param_1 + 0x46);
                if ((sVar22 == 0) || (sVar22 == 3)) {
                  *(undefined2 *)(param_1 + 0xb0) = 2;
                  *(undefined2 *)(param_1 + 0x46) = 0;
                  .debug::_SetSpriteSpeed(param_1,0,0);
                }
                else if (*(int *)(param_1 + 0x24) < 0) {
                  *(short *)(param_1 + 0x46) = sVar22 + 1;
                }
                else {
                  *(short *)(param_1 + 0x46) = sVar22 + -1;
                }
              }
            }
            else {
              sVar21 = uVar1 - (short)*(undefined4 *)(param_1 + 0x14c);
              if (sVar22 < (short)(sVar21 + -0x19)) {
                *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
                .debug::_SetSpriteSpeed(param_1,1000,0x200);
              }
              else if ((short)(sVar21 + 0x19) < sVar22) {
                *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1;
                .debug::_SetSpriteSpeed(param_1,0xfffffc18,0x200);
              }
              else {
                sVar22 = *(short *)(param_1 + 0x46);
                if ((sVar22 == 0) || (sVar22 == 3)) {
                  *(undefined2 *)(param_1 + 0xb0) = 2;
                  *(undefined2 *)(param_1 + 0x46) = 0;
                  .debug::_SetSpriteSpeed(param_1,0,0);
                }
                else if (*(int *)(param_1 + 0x24) < 1) {
                  *(short *)(param_1 + 0x46) = sVar22 + -1;
                }
                else {
                  *(short *)(param_1 + 0x46) = sVar22 + 1;
                }
              }
            }
            if (*(short *)(param_1 + 0x46) < 0) {
              *(undefined2 *)(param_1 + 0x46) = 0xf;
            }
            else if (0xf < *(short *)(param_1 + 0x46)) {
              *(undefined2 *)(param_1 + 0x46) = 0;
            }
            *(undefined4 *)(param_1 + 0xc0) =
                 *(undefined4 *)(_DAT_100a09e8 + ((int)*(short *)(param_1 + 0x46) >> 1) * 4 + 4);
          }
        }
        else if ((0 < sVar22) &&
                (*(undefined2 *)(param_1 + 0x110) = 0x151, *(char *)(param_1 + 0xce) != '\0')) {
          sVar22 = *(short *)(param_1 + 0x10);
          if ((short)*puVar3 < sVar22) {
            sVar21 = (short)*(undefined4 *)(param_1 + 0x14c);
          }
          else {
            sVar21 = -(short)*(undefined4 *)(param_1 + 0x14c);
          }
          sVar21 = *puVar3 + sVar21;
          if (((sVar22 < (short)(sVar21 + -0x19)) || ((short)(sVar21 + 0x19) < sVar22)) &&
             (*(short *)(*(int *)*puVar6 + *(short *)(param_1 + 0x48) * 0x10 + 8) != 1)) {
            *(undefined2 *)(param_1 + 0x46) = 0;
            *(undefined2 *)(param_1 + 0xb0) = 1;
          }
          else {
            puVar23 = (undefined4 *)(_DAT_100a09f0 + 4);
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a09f0 + 4);
            iVar17 = *(int *)(param_1 + 0x24);
            if (iVar17 < 1) {
              iVar17 = -iVar17;
            }
            if (0 < iVar17) {
              uVar18 = *(uint *)(param_1 + 0x24);
              *(uint *)(param_1 + 0x24) =
                   ((int)uVar18 >> 1) + (uint)((int)uVar18 < 0 && (uVar18 & 1) != 0);
            }
            if (*(short *)(param_1 + 0xa6) == 0) {
              *(undefined4 *)(param_1 + 0xc0) =
                   *(undefined4 *)(iVar15 + ((int)*(short *)(param_1 + 0x46) >> 1) * 4 + 4);
              *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
              if (*(short *)(param_1 + 0x46) == 8) {
                .debug::_STPlay3DSound(*_DAT_100a0268,1,0x100,*(undefined4 *)(param_1 + 0xe));
                sVar22 = .debug::_FastRand(0x1a);
                *(short *)(param_1 + 0xa6) = (short)*(undefined4 *)(param_1 + 0x158) + sVar22;
                iVar17 = .debug::_MTNewSprite
                                   (*(char *)(param_1 + 0x17e),
                                    (int)*(short *)(param_1 + 0xc) +
                                    (uint)(*(char *)(param_1 + 0x17e) == '\0') * 0x50 + 10,
                                    *(short *)(param_1 + 10) + 0x14,0,0xffffffff,puVar10);
                if (*(char *)(param_1 + 0x17e) == '\0') {
                  sVar22 = .debug::_FastRand(0x1c2);
                  *(int *)(iVar17 + 0x24) = sVar22 + 0x618;
                  sVar22 = .debug::_FastRand(0x1c2);
                  *(int *)(iVar17 + 0x2c) = -0x334 - sVar22;
                  sVar22 = .debug::_FastRand(100);
                  if (0x5a < sVar22) {
                    sVar22 = .debug::_FastRand(0x578);
                    *(int *)(iVar17 + 0x24) = *(int *)(iVar17 + 0x24) + (int)sVar22;
                    sVar22 = .debug::_FastRand(0x578);
                    *(int *)(iVar17 + 0x2c) = *(int *)(iVar17 + 0x2c) - (int)sVar22;
                  }
                }
                else {
                  sVar22 = .debug::_FastRand(0x1c2);
                  *(int *)(iVar17 + 0x24) = -0x618 - sVar22;
                  sVar22 = .debug::_FastRand(0x1c2);
                  *(int *)(iVar17 + 0x2c) = -0x334 - sVar22;
                  sVar22 = .debug::_FastRand(100);
                  if (0x5a < sVar22) {
                    sVar22 = .debug::_FastRand(0x578);
                    *(int *)(iVar17 + 0x24) = *(int *)(iVar17 + 0x24) - (int)sVar22;
                    sVar22 = .debug::_FastRand(0x578);
                    *(int *)(iVar17 + 0x2c) = *(int *)(iVar17 + 0x2c) - (int)sVar22;
                  }
                }
              }
            }
            else {
              *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
              if (*(short *)(param_1 + 0x46) < 1) {
                *(undefined4 *)(param_1 + 0xc0) = *puVar23;
              }
              else {
                *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
                *(undefined4 *)(param_1 + 0xc0) =
                     *(undefined4 *)(iVar15 + ((int)*(short *)(param_1 + 0x46) >> 1) * 4 + 4);
                if (0xb < *(short *)(param_1 + 0x46)) {
                  *(undefined2 *)(param_1 + 0x46) = 0;
                  *(undefined4 *)(param_1 + 0xc0) = *puVar23;
                }
              }
            }
          }
        }
      }
      else if (sVar22 < 5) {
        sVar22 = *(short *)(param_1 + 0xb2);
        *(undefined1 *)(param_1 + 0xea) = 1;
        sVar22 = (short)((ulonglong)((longlong)(int)sVar22 * 0x55555556) >> 0x20) -
                 ((short)((short)((int)sVar22 / 0x30000) + (sVar22 >> 0xf)) >> 0xf);
        if (*(short *)(param_1 + 0xb2) == 0x16) {
          *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + -800;
        }
        if (7 < sVar22) {
          sVar22 = 7;
        }
        if (*(short *)(param_1 + 0xb2) == 0) {
          .debug::_STPlay3DSound(*puVar23,1,0x100,*(undefined4 *)(param_1 + 0xe));
        }
        *(int *)(param_1 + 0xc0) = *piVar14 + sVar22 * 0x34;
        *(undefined4 *)(param_1 + 0x80) = 1;
        iVar17 = *(int *)(param_1 + 0x24);
        if (iVar17 < 1) {
          iVar17 = -iVar17;
        }
        if (iVar17 < 0x81) {
          *(undefined4 *)(param_1 + 0x24) = 0;
        }
        else {
          uStack_60 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
          *(int *)(param_1 + 0x24) = (int)((uStack_60 - dRam100a1aa8) * dRam100a1ab8);
        }
        *(short *)(param_1 + 0xb2) = *(short *)(param_1 + 0xb2) + 1;
        psVar4 = _DAT_1009feac;
        if (0x32 < *(short *)(param_1 + 0xb2)) {
          if ((*(int *)(param_1 + 0x11c) == 0) && (*(int *)(param_1 + 0x120) == 0)) {
            *(int *)(param_1 + 0x15c) = *(int *)(param_1 + 0x15c) + 1;
            if ((2 < *(int *)(param_1 + 0x15c)) && (*(short *)(param_1 + 0x1a2) < 1)) {
              *(undefined2 *)(param_1 + 0x1a2) = 1;
            }
            *(undefined1 *)(*(int *)*puVar6 + *(short *)(param_1 + 0x48) * 0x10 + 4) = 0;
            iVar17 = (int)(short)*puVar3 - (int)*(short *)(param_1 + 0x10);
            if (iVar17 < 1) {
              iVar17 = -iVar17;
            }
            if (iVar17 < 0x1c3) {
              iVar17 = (int)*psVar2 - (int)*(short *)(param_1 + 0xe);
              if (iVar17 < 1) {
                iVar17 = -iVar17;
              }
              if (iVar17 < 0x15f) goto LAB_10068c24;
            }
            .debug::_KillWalker(param_1);
          }
          else {
            if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b5) != '\0')) {
              *_DAT_1009ffb4 = *_DAT_1009ffb4 + -1;
              *(short *)((int)piVar5 + *psVar4 * 2 + 0x306) =
                   *(short *)((int)piVar5 + *psVar4 * 2 + 0x306) + 1;
            }
            *(undefined4 *)(param_1 + 0x4c) = _DAT_100a0200;
            .glue::SetRect(param_1 + 0x34,0x10,0x35,0x42,0x47);
            *(undefined2 *)(param_1 + 0x1a0) = 0xfffa;
            *(undefined1 *)(param_1 + 0x185) = 1;
            *(undefined2 *)(param_1 + 0xa6) = 0;
            *(undefined2 *)(param_1 + 0x116) = 0;
            *(undefined1 *)(param_1 + 0x17c) = 1;
            *(undefined2 *)(param_1 + 0x13a) = 0x20;
            *(undefined2 *)(param_1 + 0x138) = 0x3c;
          }
        }
      }
    }
LAB_10068c24:
    if (*(short *)(param_1 + 0xb0) != 4) {
      if (*(short *)(param_1 + 0x10) < (short)*puVar3) {
        *(undefined1 *)(param_1 + 0x17e) = 0;
      }
      else if ((short)*puVar3 < *(short *)(param_1 + 0x10)) {
        *(undefined1 *)(param_1 + 0x17e) = 1;
      }
    }
    goto LAB_10069a8c;
  }
  if (sVar22 == 0x6a9) {
    if (*(short *)(*(int *)*puVar6 + *(short *)(param_1 + 0x48) * 0x10 + 0xc) < 3) {
      iVar17 = *(int *)(param_1 + 0x24);
      if (iVar17 < 1) {
        iVar17 = -iVar17;
      }
      if (iVar17 < 0x81) {
        *(undefined4 *)(param_1 + 0x24) = 0;
      }
      else {
        uStack_68 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
        *(int *)(param_1 + 0x24) = (int)((uStack_68 - dRam100a1aa8) * dRam100a1ab8);
      }
    }
    else {
      iVar17 = *(int *)(param_1 + 0x24);
      if (iVar17 < 1) {
        iVar17 = -iVar17;
      }
      if (iVar17 < 0x81) {
        *(undefined4 *)(param_1 + 0x24) = 0;
      }
      else {
        uStack_68 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
        *(int *)(param_1 + 0x24) = (int)((uStack_68 - dRam100a1aa8) * dRam100a1ab0);
      }
    }
    sVar22 = *(short *)(param_1 + 0xb0);
    if (sVar22 == 5) {
      *(short *)(param_1 + 0xb2) = *(short *)(param_1 + 0xb2) + 1;
      if (*(short *)(param_1 + 0xb2) < 1) {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar13 + 8);
      }
      else {
        sVar22 = *(short *)(param_1 + 0xb2) >> 2;
        if (sVar22 == 0) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar13 + 4);
        }
        else if (sVar22 == 1) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar13 + 8);
        }
        else if (sVar22 == 2) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar13 + 0xc);
        }
        else if (sVar22 == 3) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar13 + 8);
        }
        else {
          sVar22 = .debug::_FastRand(0x3c);
          *(short *)(param_1 + 0xb2) = -(sVar22 + 0x3c);
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar13 + 8);
        }
      }
      if (*(short *)(param_1 + 0x10) < (short)*puVar3) {
        if (*(short *)(param_1 + 0xb4) < 3) {
          *(short *)(param_1 + 0xb4) = *(short *)(param_1 + 0xb4) + 1;
          if (*(short *)(param_1 + 0xb4) == 0) {
            *(undefined2 *)(param_1 + 0xb4) = 1;
          }
          sVar22 = *(short *)(param_1 + 0xb4);
          if (sVar22 < 3) {
            if (sVar22 < -2) {
              sVar22 = -2;
            }
            else if (2 < sVar22) {
              sVar22 = 2;
            }
            if (sVar22 < 1) {
              sVar22 = -sVar22;
            }
            if (*(short *)(param_1 + 0xb2) < 0) {
              *(undefined1 *)(param_1 + 0x17e) = 1;
            }
            else {
              *(undefined1 *)(param_1 + 0x17e) = 0;
            }
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar12 + sVar22 * 4);
          }
          else {
            *(undefined1 *)(param_1 + 0x17e) = 0;
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar13 + 4);
          }
        }
        else {
          *(undefined1 *)(param_1 + 0x17e) = 0;
        }
      }
      else if (*(short *)(param_1 + 0xb4) < -2) {
        *(undefined1 *)(param_1 + 0x17e) = 1;
      }
      else {
        *(short *)(param_1 + 0xb4) = *(short *)(param_1 + 0xb4) + -1;
        if (*(short *)(param_1 + 0xb4) == 0) {
          *(undefined2 *)(param_1 + 0xb4) = 0xffff;
        }
        sVar22 = *(short *)(param_1 + 0xb4);
        if (sVar22 < -2) {
          *(undefined1 *)(param_1 + 0x17e) = 1;
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar13 + 4);
        }
        else {
          if (sVar22 < -2) {
            sVar22 = -2;
          }
          else if (2 < sVar22) {
            sVar22 = 2;
          }
          if (sVar22 < 1) {
            sVar22 = -sVar22;
          }
          if (*(short *)(param_1 + 0xb2) < 0) {
            *(undefined1 *)(param_1 + 0x17e) = 1;
          }
          else {
            *(undefined1 *)(param_1 + 0x17e) = 0;
          }
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar12 + sVar22 * 4);
        }
      }
      iVar24 = (int)(short)*puVar3;
      iVar20 = (int)*(short *)(param_1 + 0x10);
      iVar17 = iVar20 - iVar24;
      if (iVar17 < 1) {
        iVar17 = -iVar17;
      }
      if (iVar17 < 0x78) {
        iVar17 = (int)*psVar2 - (int)*(short *)(param_1 + 0xe);
        if (iVar17 < 1) {
          iVar17 = -iVar17;
        }
        if ((iVar17 < 100) &&
           ((((*(char *)(param_1 + 0x17e) != '\0' && (iVar24 < iVar20)) &&
             (*(short *)(param_1 + 0xb4) == -3)) ||
            (((*(char *)(param_1 + 0x17e) == '\0' && (iVar20 < iVar24)) &&
             (*(short *)(param_1 + 0xb4) == 3)))))) {
          *(undefined2 *)(param_1 + 0xb0) = 2;
          *(undefined2 *)(param_1 + 0xb2) = 0;
        }
      }
    }
    else if ((sVar22 < 5) && (sVar22 == 2)) {
      iVar17 = (int)(*(short *)(param_1 + 0xb2) >> 1);
      if (iVar17 < 0xd) {
        if (*(short *)(param_1 + 0xb2) == 6) {
          .debug::_STPlay3DSound(*_DAT_100a0418,1,0x100,*(undefined4 *)(param_1 + 0xe));
        }
        if (*(short *)(param_1 + 0xb2) == 0x10) {
          iVar20 = .debug::_MTNewSprite
                             (0x6a9,(int)*(short *)(param_1 + 0x10) +
                                    (uint)*(byte *)(param_1 + 0x17e) * -0x50,
                              *(short *)(param_1 + 0xe) + -10,0,0xffffffff,puVar10);
          if (*(char *)(param_1 + 0x17e) == '\0') {
            uVar19 = 3000;
          }
          else {
            uVar19 = 0xfffff448;
          }
          *(undefined4 *)(iVar20 + 0x24) = uVar19;
        }
        if (iVar17 < 9) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar11 + iVar17 * 4 + 4);
        }
        else if (iVar17 < 0xc) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar11 + (0x11 - iVar17) * 4 + 4);
        }
        else {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar11 + 4);
        }
      }
      else {
        *(undefined2 *)(param_1 + 0xb0) = 5;
        *(undefined2 *)(param_1 + 0xb2) = 0;
      }
      *(short *)(param_1 + 0xb2) = *(short *)(param_1 + 0xb2) + 1;
    }
    goto LAB_10069a8c;
  }
  if (sVar22 != 0x6d6) {
    if (sVar22 == 0x6e0) {
      iVar20 = *(int *)(param_1 + 0x24);
      if (iVar20 < 1) {
        iVar20 = -iVar20;
      }
      if (iVar20 < 0x81) {
        *(undefined4 *)(param_1 + 0x24) = 0;
      }
      else {
        uStack_68 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
        *(int *)(param_1 + 0x24) = (int)((uStack_68 - dRam100a1aa8) * dRam100a1ab0);
      }
      sVar22 = *(short *)(param_1 + 0xb0);
      if (sVar22 == 5) {
        *(short *)(param_1 + 0xb2) = *(short *)(param_1 + 0xb2) + 1;
        sVar22 = *(short *)(param_1 + 0xb4);
        if (sVar22 < -0x14) {
          *(short *)(param_1 + 0xb4) = sVar22 + 1;
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar17 + 0x24);
        }
        else {
          *(short *)(param_1 + 0xb4) = sVar22 + 1;
          sVar22 = .debug::_FastRand(0x19);
          if ((sVar22 == 1) && (-1 < *(short *)(param_1 + 0xb4))) {
            *(undefined2 *)(param_1 + 0xb4) = 0xffe4;
          }
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar17 + 4);
        }
        if (*(short *)(param_1 + 0x10) < (short)*puVar3) {
          *(undefined1 *)(param_1 + 0x17e) = 1;
        }
        else {
          *(undefined1 *)(param_1 + 0x17e) = 0;
        }
        iVar17 = (int)*(short *)(param_1 + 0x10) - (int)(short)*puVar3;
        if (iVar17 < 1) {
          iVar17 = -iVar17;
        }
        if ((iVar17 < 500) && (-1 < *(short *)(param_1 + 0xb2))) {
          *(undefined2 *)(param_1 + 0xb0) = 2;
          *(undefined2 *)(param_1 + 0xb2) = 0;
        }
      }
      else if ((sVar22 < 5) && (sVar22 == 2)) {
        iVar20 = (int)(*(short *)(param_1 + 0xb2) >> 1);
        if (iVar20 < 9) {
          if (*(short *)(param_1 + 0xb2) == 6) {
            .debug::_STPlay3DSound(*_DAT_100a0418,1,0x100,*(undefined4 *)(param_1 + 0xe));
          }
          if (*(short *)(param_1 + 0xb2) == 8) {
            if (*(char *)(param_1 + 0x17e) == '\0') {
              iVar24 = -0x1c;
            }
            else {
              iVar24 = 0x1c;
            }
            iVar24 = .debug::_MTNewSprite
                               (*(short *)(*(int *)*puVar6 + *(short *)(param_1 + 0x48) * 0x10 + 8)
                                + 0x6e1,*(short *)(param_1 + 0x10) + iVar24 + -0x10,
                                *(short *)(param_1 + 0xe) + -0x26,*(int *)(param_1 + 0x80) + 1,
                                0xffffffff,puVar10);
            *(undefined2 *)(iVar24 + 0xa6) = 0xffe2;
            sVar22 = .debug::_FastRand(0x28a);
            *(int *)(iVar24 + 0x2c) = -0x6a4 - sVar22;
            sVar22 = .debug::_FastRand(0x28a);
            *(int *)(iVar24 + 0x24) = -0x514 - sVar22;
            if (*(char *)(param_1 + 0x17e) != '\0') {
              *(int *)(iVar24 + 0x24) = -*(int *)(iVar24 + 0x24);
            }
          }
          if (iVar20 < 9) {
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar17 + iVar20 * 4 + 4);
          }
          else {
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar17 + 4);
          }
        }
        else {
          *(undefined2 *)(param_1 + 0xb0) = 5;
          sVar22 = .debug::_FastRand(0x50);
          *(short *)(param_1 + 0xb2) = -(sVar22 + 0x28);
        }
        *(short *)(param_1 + 0xb2) = *(short *)(param_1 + 0xb2) + 1;
      }
    }
    goto LAB_10069a8c;
  }
  switch(*(undefined2 *)(param_1 + 0xb0)) {
  default:
    .debug::_ReportError(&DAT_100a63b0);
    break;
  case 1:
    if (*(char *)(param_1 + 0xce) != '\0') {
      uVar18 = (uint)(*(ushort *)(param_1 + 0x10) <= *puVar3) -
               (~(int)(short)(*(ushort *)(param_1 + 0x10) ^ *puVar3) >> 0x1f) & 1;
      if (*(short *)(param_1 + 0xb2) == 1) {
        uVar18 = (uint)(uVar18 == 0);
      }
      if ((*(short *)(param_1 + 0xb6) == 3) && (*(int *)(param_1 + 0x174) == 0)) {
        uVar18 = (uint)(uVar18 == 0);
      }
      if (uVar18 == 0) {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        .debug::_SetSpriteSpeed(param_1,0xfffffa88,0x200);
      }
      else {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        .debug::_SetSpriteSpeed(param_1,0x578,0x200);
      }
      if (*(short *)(param_1 + 0x46) < 0) {
        *(undefined2 *)(param_1 + 0x46) = 0xf;
      }
      else if (0xf < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0;
      }
      *(undefined4 *)(param_1 + 0xc0) =
           *(undefined4 *)(_DAT_100a09d0 + ((int)*(short *)(param_1 + 0x46) >> 1) * 4 + 4);
      .debug::_AxGoblinCoreLogic(param_1);
    }
    break;
  case 2:
    *(undefined2 *)(param_1 + 0x110) = 0x151;
    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar16 + 4);
    iVar17 = *(int *)(param_1 + 0x24);
    if (iVar17 < 1) {
      iVar17 = -iVar17;
    }
    if (0 < iVar17) {
      uVar18 = *(uint *)(param_1 + 0x24);
      *(uint *)(param_1 + 0x24) = ((int)uVar18 >> 1) + (uint)((int)uVar18 < 0 && (uVar18 & 1) != 0);
    }
    switch(*(undefined2 *)(param_1 + 0x46)) {
    case 0:
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar16 + 4);
      break;
    case 1:
    case 2:
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar24 + 4);
      break;
    case 3:
    case 4:
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar24 + 8);
      break;
    case 5:
    case 6:
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar24 + 0xc);
      break;
    case 7:
    case 8:
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar24 + 0x10);
      break;
    case 9:
    case 10:
    case 0xb:
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar24 + 0x14);
      break;
    case 0xc:
    case 0xd:
    case 0xe:
    case 0xf:
    case 0x10:
    case 0x11:
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar24 + 0x18);
    }
    if (0 < *(short *)(param_1 + 0xa6)) {
      *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
    }
    if (*(short *)(param_1 + 0xa6) == 0) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (*(short *)(param_1 + 0x46) == 5) {
        .debug::_STPlay3DSoundPitched(*_DAT_100a0268,1,0x100,*(undefined4 *)(param_1 + 0xe),45000);
      }
      if (*(short *)(param_1 + 0x46) == 8) {
        sVar22 = .debug::_FastRand(0xc);
        *(short *)(param_1 + 0xa6) = sVar22 + 10;
        if (*(char *)(param_1 + 0x17e) == '\0') {
          .debug::_MTNewSprite
                    ((int)*(short *)(param_1 + 4),*(short *)(param_1 + 0xc) + 0x99,
                     *(short *)(param_1 + 10) + 0x2c,0,0xffffffff,puVar10);
        }
        else {
          .debug::_MTNewSprite
                    ((int)*(short *)(param_1 + 4),*(short *)(param_1 + 0xc) + 3,
                     *(short *)(param_1 + 10) + 0x2c,0,0xffffffff,puVar10);
        }
      }
    }
    else if (*(short *)(param_1 + 0x46) < 1) {
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar16 + 4);
    }
    else {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (0xe < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0;
        .debug::_AxGoblinCoreLogic(param_1);
      }
    }
    break;
  case 4:
    uVar1 = *(ushort *)(param_1 + 0xb2);
    sVar22 = ((short)uVar1 >> 2) + (ushort)((short)uVar1 < 0 && (uVar1 & 3) != 0);
    if (uVar1 == 0x14) {
      *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + -800;
    }
    if (5 < sVar22) {
      sVar22 = 5;
    }
    if (*(short *)(param_1 + 0xb2) == 0) {
      .debug::_STPlay3DSound(*puVar23,1,0x100,*(undefined4 *)(param_1 + 0xe));
    }
    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a09c4 + sVar22 * 4 + 4);
    *(undefined4 *)(param_1 + 0x80) = 1;
    iVar17 = *(int *)(param_1 + 0x24);
    if (iVar17 < 1) {
      iVar17 = -iVar17;
    }
    if (iVar17 < 0x81) {
      *(undefined4 *)(param_1 + 0x24) = 0;
    }
    else {
      uStack_68 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
      *(int *)(param_1 + 0x24) = (int)((uStack_68 - dRam100a1aa8) * dRam100a1ab8);
    }
    *(short *)(param_1 + 0xb2) = *(short *)(param_1 + 0xb2) + 1;
    if (0x3c < *(short *)(param_1 + 0xb2)) {
      *(int *)(param_1 + 0x15c) = *(int *)(param_1 + 0x15c) + 1;
      if ((2 < *(int *)(param_1 + 0x15c)) && (*(short *)(param_1 + 0x1a2) < 1)) {
        *(undefined2 *)(param_1 + 0x1a2) = 1;
      }
      *(undefined1 *)(*(int *)*puVar6 + *(short *)(param_1 + 0x48) * 0x10 + 4) = 0;
      iVar17 = (int)(short)*puVar3 - (int)*(short *)(param_1 + 0x10);
      if (iVar17 < 1) {
        iVar17 = -iVar17;
      }
      if (iVar17 < 0x1c3) {
        iVar17 = (int)*psVar2 - (int)*(short *)(param_1 + 0xe);
        if (iVar17 < 1) {
          iVar17 = -iVar17;
        }
        if (iVar17 < 0x15f) break;
      }
      .debug::_KillWalker(param_1);
    }
    break;
  case 6:
    sVar22 = *(short *)(param_1 + 0x46);
    if (sVar22 < 0) {
      *(short *)(param_1 + 0x46) = sVar22 + 1;
      if (*(short *)(param_1 + 0x46) == 0) {
        *(undefined4 *)(param_1 + 0x2c) = 0xffffec78;
        *(undefined1 *)(param_1 + 0xce) = 0;
      }
    }
    else if ((*(int *)(param_1 + 0x2c) < 0) && (sVar22 < 8)) {
      *(short *)(param_1 + 0x46) = sVar22 + 1;
    }
    else if ((2000 < *(int *)(param_1 + 0x2c)) && (1 < sVar22)) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1;
    }
    if (*(short *)(param_1 + 0x46) < 0) {
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar20 + 4);
    }
    else {
      *(undefined4 *)(param_1 + 0xc0) =
           *(undefined4 *)(iVar20 + ((*(short *)(param_1 + 0x46) + -1) / 3) * 4 + 4);
    }
    if ((*(char *)(param_1 + 0xce) == '\0') && (*(char *)(param_1 + 0xcd) == '\0')) {
      iVar17 = *(int *)(param_1 + 0x168);
      if (*(int *)(param_1 + 0x24) < iVar17) {
        if (iVar17 < 1) {
          iVar17 = -iVar17;
        }
        *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + iVar17 / 6;
      }
      else if (iVar17 < *(int *)(param_1 + 0x24)) {
        if (iVar17 < 1) {
          iVar17 = -iVar17;
        }
        *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) - iVar17 / 6;
      }
    }
    if (*(char *)(param_1 + 0xce) != '\0') {
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar16 + 4);
      *(undefined4 *)(param_1 + 0x24) = 0;
      if (*(short *)(param_1 + 0xa6) < 1) {
        if (-1 < *(short *)(param_1 + 0x46)) {
          .debug::_AxGoblinCoreLogic(param_1);
        }
      }
      else {
        *(undefined4 *)(param_1 + 0x170) = 0x32;
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar16 + 4);
        *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
        *(undefined4 *)(param_1 + 0x16c) = 0;
      }
    }
    break;
  case 7:
    .debug::_AxGoblinCoreLogic(param_1);
  }
  if ((*(short *)(param_1 + 0xb0) != 4) &&
     ((*(short *)(param_1 + 0xb0) != 2 || (*(short *)(param_1 + 0x46) == 0)))) {
    if (*(short *)(param_1 + 0x10) < (short)*puVar3) {
      *(bool *)(param_1 + 0x17e) = *(short *)(param_1 + 0xb2) == 2;
    }
    else if ((short)*puVar3 < *(short *)(param_1 + 0x10)) {
      *(bool *)(param_1 + 0x17e) = *(short *)(param_1 + 0xb2) != 2;
    }
    if ((*(short *)(param_1 + 0xb6) == 3) && (*(int *)(param_1 + 0x174) == 0)) {
      *(bool *)(param_1 + 0x17e) = *(char *)(param_1 + 0x17e) == '\0';
    }
  }
LAB_10069a8c:
  if ((*(short *)(param_1 + 0xa4) < 1) && (*(short *)(param_1 + 0xb0) != 4)) {
    *(undefined2 *)(param_1 + 0xb2) = 0;
    iVar17 = _DAT_100a09c4;
    sVar22 = *(short *)(param_1 + 4);
    if (sVar22 == 0x6a4) {
      .glue::SetRect(param_1 + 0x34,0x28,10,0x3c,0x46);
      *(short *)(param_1 + 0x34) = *(short *)(param_1 + 0x34) + 0x28;
      *(undefined2 *)(param_1 + 0xb0) = 4;
      sVar22 = .debug::_FastRand(100);
      if (sVar22 < 0x33) {
        sVar22 = .debug::_FastRand(10000);
        .debug::_STPlay3DSoundPitchedGob
                  (param_1,*puVar8,1,0xab,*(undefined4 *)(param_1 + 0xe),sVar22 + 55000);
      }
      else {
        sVar22 = .debug::_FastRand(10000);
        .debug::_STPlay3DSoundPitchedGob
                  (param_1,*puVar9,1,0xab,*(undefined4 *)(param_1 + 0xe),sVar22 + 50000);
      }
      *(undefined4 *)(param_1 + 0x15c) = 0;
      *piVar5 = *piVar5 + 500;
      if (*(char *)(param_1 + 0x17e) == '\0') {
        *(short *)(param_1 + 0x36) = *(short *)(param_1 + 0x36) + -0x10;
        *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + -0x1800;
      }
      else {
        *(short *)(param_1 + 0x3a) = *(short *)(param_1 + 0x3a) + 0x10;
        *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + 0x1800;
      }
      *(int *)(param_1 + 0xc0) = *piVar14;
    }
    else if (sVar22 == 0x6a9) {
      .glue::SetRect(param_1 + 0x34,0x28,10,0x3c,0x46);
      *(undefined2 *)(param_1 + 4) = 0x6a4;
      *(undefined2 *)(param_1 + 0xb0) = 4;
      sVar22 = .debug::_FastRand(100);
      if (sVar22 < 0x33) {
        sVar22 = .debug::_FastRand(10000);
        .debug::_STPlay3DSoundPitchedGob
                  (param_1,*puVar8,1,0xab,*(undefined4 *)(param_1 + 0xe),sVar22 + 55000);
      }
      else {
        sVar22 = .debug::_FastRand(10000);
        .debug::_STPlay3DSoundPitchedGob
                  (param_1,*puVar9,1,0xab,*(undefined4 *)(param_1 + 0xe),sVar22 + 50000);
      }
      *(undefined4 *)(param_1 + 0x15c) = 0;
      if (*(char *)(param_1 + 0x17e) == '\0') {
        *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + 0x2300;
      }
      else {
        *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + 0x4b00;
      }
      *(int *)(param_1 + 0xc0) = *piVar14;
      *(short *)(param_1 + 0x34) = *(short *)(param_1 + 0x34) + 0x28;
      *piVar5 = *piVar5 + 600;
    }
    else if (sVar22 == 0x6d6) {
      *(undefined2 *)(param_1 + 0xb0) = 4;
      *(undefined4 *)(param_1 + 0x15c) = 0;
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar17 + 4);
      sVar22 = .debug::_FastRand(100);
      if (sVar22 < 0x33) {
        sVar22 = .debug::_FastRand(10000);
        .debug::_STPlay3DSoundPitchedGob
                  (param_1,*puVar8,1,0xab,*(undefined4 *)(param_1 + 0xe),sVar22 + 55000);
      }
      else {
        sVar22 = .debug::_FastRand(10000);
        .debug::_STPlay3DSoundPitchedGob
                  (param_1,*puVar9,1,0xab,*(undefined4 *)(param_1 + 0xe),sVar22 + 50000);
      }
      *piVar5 = *piVar5 + 800;
    }
    else if (sVar22 == 0x6e0) {
      .glue::SetRect(param_1 + 0x34,0x28,10,0x3c,0x46);
      *(undefined2 *)(param_1 + 4) = 0x6a4;
      *(undefined2 *)(param_1 + 0xb0) = 4;
      sVar22 = .debug::_FastRand(100);
      if (sVar22 < 0x33) {
        sVar22 = .debug::_FastRand(10000);
        .debug::_STPlay3DSoundPitchedGob
                  (param_1,*puVar8,1,0xab,*(undefined4 *)(param_1 + 0xe),sVar22 + 55000);
      }
      else {
        sVar22 = .debug::_FastRand(10000);
        .debug::_STPlay3DSoundPitchedGob
                  (param_1,*puVar9,1,0xab,*(undefined4 *)(param_1 + 0xe),sVar22 + 50000);
      }
      *(undefined4 *)(param_1 + 0x15c) = 0;
      *(bool *)(param_1 + 0x17e) = *(char *)(param_1 + 0x17e) == '\0';
      *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + 0x1400;
      if (*(char *)(param_1 + 0x17e) == '\0') {
        *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + -0x1900;
      }
      else {
        *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + 0xf00;
      }
      *(int *)(param_1 + 0xc0) = *piVar14;
      *(short *)(param_1 + 0x34) = *(short *)(param_1 + 0x34) + 0x2a;
      *piVar5 = *piVar5 + 400;
    }
  }
  *(undefined4 *)(param_1 + 0x16c) = 0;
  .debug::_ApplyGravityAndSeparateFromTiles(param_1);
  if ((*(char *)(param_1 + 0xce) != '\0') && (*(char *)(param_1 + 0xcd) == '\0')) {
    if ((*(short *)(param_1 + 4) == 0x6d6) && (*(short *)(param_1 + 0xb0) == 6)) {
      sVar22 = .debug::_FastRand(4);
      *(short *)(param_1 + 0xa6) = sVar22 + 2;
      *(undefined2 *)(param_1 + 0x46) = 0;
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar16 + 4);
    }
    if (2000 < *(int *)(param_1 + 0x30)) {
      sVar22 = .debug::_FastRand(4000);
      .debug::_STPlay3DSoundPitchedGob
                (param_1,*_DAT_100a0284,1,0x55,*(undefined4 *)(param_1 + 0xe),sVar22 + 40000);
    }
  }
  if ((*(int *)(param_1 + 0x11c) != 0) &&
     (((*(int *)(param_1 + 0x11c) == 1 && (*(short *)(param_1 + 0x128) == 0)) ||
      (0 < *(short *)(param_1 + 0x128))))) {
    sVar22 = *(short *)(param_1 + 0x128);
    if (sVar22 == 3) {
      if (*(short *)(param_1 + 0xa4) < 500) {
        *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + 4;
      }
    }
    else if (sVar22 < 3) {
      if (sVar22 == 0) {
        if (*(short *)(param_1 + 0x116) == 0) {
          *(undefined2 *)(param_1 + 0x116) = 0xc;
          *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -0x96;
          *(undefined2 *)(param_1 + 0xaa) = 0xc;
          .debug::_STPlay3DSound(*puVar7,1,0x55,*(undefined4 *)(param_1 + 0xe));
        }
      }
      else if ((-1 < sVar22) && (*(short *)(param_1 + 0x116) == 0)) {
        *(undefined2 *)(param_1 + 0x116) = 0x13;
        *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -100;
        *(undefined2 *)(param_1 + 0xaa) = 0x11;
        .debug::_STPlay3DSound(*puVar7,1,0x55,*(undefined4 *)(param_1 + 0xe));
      }
    }
  }
  if (((*(short *)(param_1 + 0xd8) == 2) && (*(short *)(param_1 + 0x116) == 0)) &&
     (0 < *(short *)(param_1 + 0xa4))) {
    .debug::_STPlay3DSound(*puVar7,1,0x55,*(undefined4 *)(param_1 + 0xe));
    *(undefined2 *)(param_1 + 0x116) = 0x14;
    *(undefined2 *)(param_1 + 0xaa) = 0x12;
    *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) - *(short *)(*(int *)*puVar6 + 0x270e);
  }
  if ((*(int *)(param_1 + 0xc0) != 0) &&
     ((int)*(short *)(param_1 + 0x1a2) == *(short *)(*(int *)(param_1 + 0xc0) + 8) + 0x12)) {
    .debug::_PopupGoblinCoins(param_1);
  }
  if ((((*(char *)(param_1 + 0xce) == '\0') && (*(char *)(param_1 + 0xcd) == '\0')) &&
      (*(short *)(param_1 + 0xb0) != 4)) && (*(short *)(param_1 + 4) == 0x6a4)) {
    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a09e8 + 0x1c);
  }
  .debug::_StandardSpriteCleanup(param_1);
  return;
}


// ==== .HitWalkerSprite @ 1006a260 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitWalkerSprite(int param_1,int param_2)

{
  undefined *puVar1;
  char cVar3;
  short sVar2;
  undefined *puVar4;
  int iVar5;
  short sStack_18;
  short sStack_16;
  
  puVar1 = PTR_PTR_100a04e8;
  puVar4 = *(undefined **)(param_2 + 0x4c);
  if (((puVar4 == PTR_PTR_100a04e8) && (*(short *)(param_2 + 0xa6) == 0)) ||
     ((puVar4 == PTR_PTR_100a0488 &&
      ((2 < *(short *)(param_2 + 0xa6) && (*(short *)(param_2 + 4) != *(short *)(param_1 + 4)))))))
  {
    if ((*(short *)(param_2 + 4) == 1) && (puVar4 == PTR_PTR_100a04e8)) {
      .debug::_KillPlayerShot(param_2,1,1);
      .debug::_TurnIntoStatue(param_1);
    }
    else if (*(short *)(param_1 + 0xb0) != 4) {
      if (((*(short *)(param_1 + 4) == 0x6a9) && (*(short *)(param_1 + 0xb0) == 5)) &&
         (*(short *)(param_2 + 4) != 0x5a)) {
        .debug::_STPlay3DSound(*_DAT_100a041c,1,0x100,*(undefined4 *)(param_2 + 0xe));
        if (*(undefined **)(param_2 + 0x4c) == puVar1) {
          .debug::_KillPlayerShot(param_2,1,1);
        }
        else {
          .debug::_KillEnemyShot(param_2);
        }
        *(undefined2 *)(param_1 + 0xb2) = 0;
      }
      else {
        if (*(short *)(*(int *)*_DAT_100a0058 + *(short *)(param_1 + 0x48) * 0x10 + 10) == 0) {
          iVar5 = *(int *)(param_2 + 0x24);
          iVar5 = (int)(short)((short)((ulonglong)((longlong)iVar5 * 0x55555556) >> 0x20) -
                              ((short)((short)(iVar5 / 0x30000) + (short)(iVar5 >> 0x1f)) >> 0xf));
        }
        else {
          iVar5 = 0;
        }
        if (*(short *)(param_1 + 4) == 0x6d6) {
          iVar5 = iVar5 / 3;
        }
        cVar3 = .debug::_HurtSprite(param_1,(int)*(short *)(param_2 + 0xa4),iVar5,0xfffffc18,4,8);
        if (cVar3 != '\0') {
          iVar5 = (int)*(short *)(param_2 + 0xa4) / 100 + ((int)*(short *)(param_2 + 0xa4) >> 0x1f);
          iVar5 = iVar5 - (iVar5 >> 0x1f);
          if (iVar5 < 2) {
            iVar5 = 1;
          }
          iVar5 = (int)(short)iVar5;
          .debug::_GoblinHurtCry(param_1);
          if (*(undefined **)(param_2 + 0x4c) == puVar1) {
            .debug::_KillPlayerShot(param_2,0,0);
          }
          else {
            .debug::_KillEnemyShot(param_2);
          }
          .debug::_BloodSpray(param_1,param_2,iVar5 * 0x28,iVar5 * 0x32 + 0x15e,iVar5 * 0x96,2);
          if (0 < *(short *)(param_1 + 0xa4)) {
            .debug::_STPlay3DSound(*_DAT_100a0274,1,0x55,*(undefined4 *)(param_1 + 0xe));
          }
        }
      }
    }
  }
  else if (((puVar4 == PTR_PTR_100a01f8) || (puVar4 == PTR_PTR_100a0484)) ||
          (puVar4 == _DAT_100a0200)) {
    sStack_16 = *(short *)(param_1 + 0x36) +
                (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
    sStack_18 = *(short *)(param_1 + 0x34) +
                (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
    if (((*(short *)(param_1 + 0xb0) != 4) &&
        (sVar2 = .debug::_PlatformBounce(param_1,param_2,&sStack_18,0,param_1 + 0x34,0), sVar2 == 2)
        ) && ((*(char *)(param_2 + 0x185) == '\0' &&
              ((*(short *)(param_2 + 4) < 0x5d2 || (0x5d6 < *(short *)(param_2 + 4))))))) {
      *(undefined2 *)(param_1 + 0xa4) = 0;
    }
  }
  else if ((((puVar4 == PTR_PTR_100a0460) && (*(short *)(param_2 + 4) == 0x4b7)) &&
           (*(short *)(param_2 + 0x46) < 8)) ||
          ((sVar2 = *(short *)(param_2 + 4), sVar2 == 0x5a0 &&
           ((*(int *)(param_2 + 0x14c) == 1 || (*(int *)(param_2 + 0x14c) == 2)))))) {
    .debug::_HurtGoblin(param_1,param_2,100,0,0xfffffc18,4,8);
  }
  else if ((puVar4 == PTR_PTR_100a0480) &&
          (((sVar2 == 0x4b8 ||
            ((((0x5c7 < sVar2 && (sVar2 < 0x5d2)) && (*(int *)(param_2 + 0x170) == 1)) ||
             ((0x72f < sVar2 && (sVar2 < 0x736)))))) && (*(int *)(param_1 + 0x100) == 0)))) {
    if ((sVar2 < 0x730) || (0x735 < sVar2)) {
      .debug::_HurtGoblin(param_1,param_2,100,0,0xfffffc18,4,8);
    }
    else {
      .debug::_HurtGoblin(param_1,param_2,0x113,0,0xfffffc18,4,8);
    }
  }
  return;
}


// ==== .HitWalkerTileSprite @ 1006a740 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitWalkerTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  char cVar1;
  short sVar2;
  short sStack_48;
  short sStack_46;
  short sStack_44;
  short sStack_42;
  undefined1 auStack_24 [24];
  
  sStack_42 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_44 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  if ((*_DAT_100a0064 != '\0') && (cVar1 = .debug::_IsPressed(0x32), cVar1 != '\0')) {
    return;
  }
  .glue::SetRect(auStack_24,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                 (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
  sVar2 = (short)param_3;
  if (param_4 == 1) {
    sStack_46 = *(short *)(param_1 + 0x36) +
                (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
    sStack_48 = *(short *)(param_1 + 0x34) +
                (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
    cVar1 = .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
    if (((cVar1 != '\0') &&
        ((((((((-1 < sVar2 && (sVar2 < 3)) || ((sVar2 == 4 && (*(char *)(param_1 + 0x17e) == '\0')))
              ) || ((sVar2 == 7 && (*(char *)(param_1 + 0x17e) != '\0')))) ||
            ((cVar1 = *(char *)(param_1 + 0x17e), cVar1 != '\0' &&
             ((sVar2 == 10 || (sVar2 == 0x1c)))))) ||
           ((cVar1 == '\0' && ((sVar2 == 9 || (sVar2 == 0x1b)))))) ||
          ((cVar1 != '\0' &&
           ((sVar2 == 5 && ((short)param_2 + 0x10 < (int)*(short *)(param_1 + 0x10))))))) ||
         ((((cVar1 == '\0' &&
            ((sVar2 == 7 && ((int)*(short *)(param_1 + 0x10) < (short)param_2 + 0x10)))) ||
           ((sVar2 == 0x13 && (cVar1 != '\0')))) ||
          (((sVar2 == 0x14 && (cVar1 == '\0')) || ((0x1f < sVar2 && (sVar2 < 0x24)))))))))) &&
       (*(int *)(param_1 + 0x170) == 0)) {
      *(int *)(param_1 + 0x16c) = *(int *)(param_1 + 0x16c) + 1;
    }
  }
  else if (sVar2 < 100) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_44,0,param_1 + 0x34,0,0);
  }
  else if (sVar2 < 200) {
    .debug::_WallBounceBG(param_1,param_3 + -100,&stack0x0000001c,&sStack_44,0,param_1 + 0x34,0,0);
  }
  else {
    cVar1 = .debug::_IsWaterTile(param_3);
    if ((cVar1 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
      .debug::_HandleUnderWater(param_1,param_2);
    }
  }
  return;
}


// ==== .GetRopeBridgeHeight @ 1006b3d8 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

int _GetRopeBridgeHeight(undefined4 param_1,short param_2)

{
  if (param_2 < 1) {
    param_2 = 0;
  }
  if (0x10a < param_2) {
    param_2 = 0x10b;
  }
  return (int)*(short *)(_DAT_100a0a00 + param_2 * 2);
}


// ==== .SetupBoxSprite @ 1006b43c ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupBoxSprite(int param_1)

{
  short *psVar1;
  undefined4 *puVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  undefined *puVar6;
  int *piVar7;
  int iVar8;
  int iVar9;
  int iVar10;
  int iVar11;
  int iVar12;
  int iVar13;
  undefined4 *puVar14;
  int iVar15;
  int iVar16;
  char cVar21;
  undefined2 uVar19;
  undefined4 uVar17;
  undefined4 uVar18;
  short sVar20;
  int iVar22;
  
  puVar14 = _DAT_100a0a98;
  iVar13 = _DAT_100a0a74;
  iVar12 = _DAT_100a0a64;
  iVar11 = _DAT_100a0a60;
  iVar10 = _DAT_100a0a40;
  iVar9 = _DAT_100a0a38;
  iVar8 = _DAT_100a0a30;
  iVar22 = _DAT_100a0a2c;
  puVar6 = PTR_DAT_100a09f4;
  puVar3 = PTR_PTR_100a01f0;
  puVar2 = _DAT_100a0058;
  uVar18 = _DAT_1009ff34;
  .debug::_InitSprite();
  puVar5 = PTR_PTR_100a0484;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar4 = PTR_PTR_100a01f4;
  *(undefined2 *)(param_1 + 0x86) = 0;
  *(undefined4 *)(param_1 + 0x80) = 2;
  *(undefined **)(param_1 + 0x4c) = puVar5;
  *(undefined **)(param_1 + 0x5c) = puVar4;
  *(undefined **)(param_1 + 0x1f8) = puVar3;
  *(undefined2 *)(param_1 + 0xa6) = 3;
  *(undefined2 *)(param_1 + 0x110) = 0x151;
  *(undefined2 *)(param_1 + 0xa4) = 600;
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  piVar7 = _DAT_100a0a28;
  iVar15 = _DAT_100a0a18;
  iVar16 = (int)*(short *)(param_1 + 4);
  if (iVar16 < 0x5bc) {
    if (iVar16 < 0x431) {
      if (iVar16 == 0x425) {
        *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0aac;
        *(undefined2 *)(param_1 + 0x110) = 0;
        *(undefined1 *)(param_1 + 0x185) = 1;
        .glue::SetRect(param_1 + 0x34,0,0xfffffffc,0x20,0x1a);
        .debug::_GetBGTile((int)(*(short *)(param_1 + 0xc) >> 5),
                           (int)(short)(*(short *)(param_1 + 10) + 0xc >> 5));
        .debug::_LookupBGTileKind();
        cVar21 = .debug::_IsWaterTile();
        if (cVar21 != '\0') {
          *(undefined4 *)(param_1 + 0xb8) = 0x90000;
        }
        goto LAB_1006cf1c;
      }
      if (iVar16 < 0x425) {
        if (iVar16 == 0x2c9) {
          *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0ab4;
          *(undefined2 *)(param_1 + 0x110) = 0;
          .glue::SetRect(param_1 + 0x34,3,3,0x1d,0x15);
          *(undefined1 *)(param_1 + 0x88) = 0;
          goto LAB_1006cf1c;
        }
        if (iVar16 < 0x2c9) {
          if (0x2c7 < iVar16) {
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)PTR_DAT_100a0ab8;
            *(undefined2 *)(param_1 + 0x110) = 0x15e;
            .glue::SetRect(param_1 + 0x34,3,4,0x1d,0x18);
            *(undefined1 *)(param_1 + 0x88) = 0;
            goto LAB_1006cf1c;
          }
        }
        else if (0x423 < iVar16) {
          *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0ab0;
          *(undefined2 *)(param_1 + 0x110) = 0;
          *(undefined1 *)(param_1 + 0x185) = 1;
          .glue::SetRect(param_1 + 0x34,0,0xfffffffc,0x20,0x1a);
          .debug::_GetBGTile((int)(*(short *)(param_1 + 0xc) >> 5),
                             (int)(short)(*(short *)(param_1 + 10) + 0xc >> 5));
          .debug::_LookupBGTileKind();
          cVar21 = .debug::_IsWaterTile();
          if (cVar21 != '\0') {
            *(undefined4 *)(param_1 + 0xb8) = 0x90000;
          }
          goto LAB_1006cf1c;
        }
      }
      else {
        if (iVar16 == 0x429) {
          *(undefined4 *)(param_1 + 10) = *(undefined4 *)(param_1 + 6);
          *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
          *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
          *(int *)(param_1 + 0xc0) =
               *piVar7 + *(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 8) * 0x34;
          *(undefined2 *)(param_1 + 0x110) = 0;
          *(undefined1 *)(param_1 + 0x185) = 1;
          .glue::SetRect(param_1 + 0x34,0x21,0x3f,0x33,99);
          goto LAB_1006cf1c;
        }
        if (iVar16 < 0x429) {
          if (iVar16 < 0x427) {
            *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0aa8;
            *(undefined2 *)(param_1 + 0x110) = 0;
            *(undefined1 *)(param_1 + 0x185) = 1;
            .glue::SetRect(param_1 + 0x34,0,0xfffffffc,0x20,0x1a);
            .debug::_GetBGTile((int)(*(short *)(param_1 + 0xc) >> 5),
                               (int)(short)(*(short *)(param_1 + 10) + 0xc >> 5));
            .debug::_LookupBGTileKind();
            cVar21 = .debug::_IsWaterTile();
            if (cVar21 != '\0') {
              *(undefined4 *)(param_1 + 0xb8) = 0x90000;
            }
            goto LAB_1006cf1c;
          }
        }
        else if (0x42d < iVar16) goto LAB_1006b89c;
      }
    }
    else {
      if (iVar16 == 0x51c) {
        .debug::_GetBGTile((int)(*(short *)(param_1 + 0xc) >> 5),
                           (int)(short)(*(short *)(param_1 + 10) + 0xc >> 5));
        .debug::_LookupBGTileKind();
        cVar21 = .debug::_IsWaterTile();
        if (cVar21 != '\0') {
          *(undefined4 *)(param_1 + 0xb8) = 0x90000;
        }
        puVar2 = _DAT_100a0a94;
        *(undefined4 *)(param_1 + 0x80) = 0;
        *(undefined4 *)(param_1 + 0xc0) = *puVar2;
        *(undefined2 *)(param_1 + 0x110) = 0;
        *(undefined2 *)(param_1 + 0xa6) = 4;
        *(undefined1 *)(param_1 + 0x185) = 1;
        *(undefined2 *)(param_1 + 0x46) = 0;
        *(undefined4 *)(param_1 + 0x5c) = 0;
        .glue::SetRect(param_1 + 0x34,0,7,0x1c,0x1e);
        goto LAB_1006cf1c;
      }
      if (iVar16 < 0x51c) {
        if (iVar16 < 0x438) {
          if ((iVar16 < 0x435) && (0x432 < iVar16)) {
LAB_1006b89c:
            if ((iVar16 == 0x42e) || ((iVar16 - 0x433U & 0xffff) < 2)) {
              *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0aa4;
            }
            else if (iVar16 == 0x42f) {
              *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0aa0;
            }
            else if (iVar16 == 0x430) {
              *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0a9c;
            }
            *(undefined2 *)(param_1 + 0x1ca) = 0x80;
            *(undefined2 *)(param_1 + 0x1c8) = 0x80;
            *(undefined2 *)(param_1 + 0x1ce) = 0x80;
            *(undefined2 *)(param_1 + 0x1cc) = 0x80;
            *(undefined2 *)(param_1 + 0x112) = 0x14;
            *(undefined2 *)(param_1 + 0x138) = 0x8c;
            *(undefined2 *)(param_1 + 0x114) = 0x46;
            *(undefined2 *)(param_1 + 0x46) = 0;
            *(undefined2 *)(param_1 + 0x110) = 0x100;
            *(undefined4 *)(param_1 + 0x24) = 0;
            *(undefined2 *)(param_1 + 0x90) = 0x100;
            .glue::SetRect(param_1 + 0x34,4,0,0x1c,0x1c);
            goto LAB_1006cf1c;
          }
        }
        else if (iVar16 < 0x43a) {
          *(undefined1 *)(_DAT_100a0a10 + 1) = 1;
          if (*(short *)(param_1 + 4) == 0x438) {
            *(undefined2 *)(param_1 + 0x46) = 0;
            *(undefined4 *)(param_1 + 0x1f8) = 0;
            .glue::SetRect(param_1 + 0x34,0x34,4,0x35,0xc);
          }
          else {
            *(undefined **)(param_1 + 0x1f8) = puVar3;
            sVar20 = .debug::_FastRand(4);
            *(short *)(param_1 + 0x46) = sVar20 + 2;
            .glue::SetRect(param_1 + 0x34,0x12,4,0x5b,0x12);
          }
          *(undefined1 *)(param_1 + 0x185) = 1;
          *(undefined2 *)(param_1 + 0x110) = 0;
          *(undefined2 *)(param_1 + 0x138) = 0;
          *(undefined2 *)(param_1 + 0xa6) = 0;
          *(int *)(param_1 + 0x14c) =
               *(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 10) * 0x1e;
          if (*(int *)(param_1 + 0x14c) == 0) {
            *(undefined4 *)(param_1 + 0x14c) = 0xffffffff;
          }
          *(int *)(param_1 + 0x150) =
               (int)*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 8);
          *(int *)(param_1 + 0xb8) = *(int *)(param_1 + 0x150) + 0x10000;
          goto LAB_1006cf1c;
        }
      }
      else {
        if (iVar16 == 0x5a9) {
          .glue::SetRect(param_1 + 0x34,8,8,0x28,0x20);
          *(undefined1 *)(param_1 + 0x185) = 1;
          *(undefined4 *)(param_1 + 0x1f8) = 0;
          *(undefined2 *)(param_1 + 0x110) = 0;
          *(undefined2 *)(param_1 + 0x138) = 0;
          *(undefined2 *)(param_1 + 0x13a) = 0;
          goto LAB_1006cf1c;
        }
        if (iVar16 < 0x5a9) {
          if (0x59f < iVar16) {
            *(undefined1 *)(_DAT_100a0a14 + 1) = 1;
            iVar22 = _DAT_100a0a1c;
            *(undefined1 *)(iVar15 + 1) = 1;
            *(undefined1 *)(iVar22 + 1) = 1;
            .glue::SetRect(param_1 + 0x34,0,2,0x18,0x18);
            *(undefined4 *)(param_1 + 0x1f8) = 0;
            *(undefined1 *)(param_1 + 0x185) = 1;
            *(undefined2 *)(param_1 + 0x110) = 0;
            *(undefined4 *)(param_1 + 0x80) = 0;
            *(undefined1 *)(param_1 + 0x189) = 1;
            *(int *)(param_1 + 0x150) = (int)*(short *)(param_1 + 10);
            *(int *)(param_1 + 0x154) =
                 (int)*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 8) << 8;
            if (*(int *)(param_1 + 0x154) == 0) {
              *(undefined4 *)(param_1 + 0x154) = 0x6400;
            }
            *(undefined4 *)(param_1 + 0xf4) = *(undefined4 *)(param_1 + 0x154);
            *(undefined4 *)(param_1 + 0x16c) = *(undefined4 *)(param_1 + 0x154);
            *(int *)(param_1 + 0x158) =
                 (int)*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 10);
            if (*(int *)(param_1 + 0x158) == 0) {
              *(undefined4 *)(param_1 + 0x158) = 0x3c;
            }
            *(int *)(param_1 + 0x15c) =
                 (int)*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 0xc);
            if (*(int *)(param_1 + 0x15c) == 0) {
              *(undefined4 *)(param_1 + 0x15c) = 0x3c;
            }
            *(undefined2 *)(param_1 + 0xa6) =
                 *(undefined2 *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 0xe);
            *(undefined4 *)(param_1 + 0x164) = 0;
            *(undefined4 *)(param_1 + 0x168) = 0;
            *(short *)(param_1 + 0x1cc) = (short)((uint)*(undefined4 *)(param_1 + 0x154) >> 8);
            *(undefined2 *)(param_1 + 0x1ca) = 0x40;
            *(undefined2 *)(param_1 + 0x1c8) = 0x40;
            uVar19 = .debug::_FastRand(4);
            *(undefined2 *)(param_1 + 0x46) = uVar19;
            uVar17 = .debug::_AllocateGameMem(0x44);
            *(undefined4 *)(param_1 + 0x9c) = uVar17;
            iVar15 = (int)*(short *)(param_1 + 4);
            if (iVar15 < 0x5a5) {
              *(int *)(param_1 + 0x14c) = iVar15 + -0x5a0;
              *(undefined4 *)(param_1 + 0x170) = 0;
              *(undefined2 *)(param_1 + 4) = 0x5a0;
            }
            else {
              *(int *)(param_1 + 0x14c) = iVar15 + -0x5a5;
              *(undefined4 *)(param_1 + 0x170) = 1;
              *(undefined2 *)(param_1 + 4) = 0x5a5;
              *(undefined4 *)(param_1 + 0xac) = 0xffffffff;
              uVar17 = .debug::_MTNewSprite
                                 (0x5a0,*(short *)(param_1 + 0xc) + 0x48,
                                  (int)*(short *)(param_1 + 10),
                                  (int)(short)*(undefined4 *)(param_1 + 0x80),
                                  (int)*(short *)(param_1 + 0x48),uVar18);
              *(undefined4 *)(param_1 + 0x1d4) = uVar17;
              *(undefined1 *)(*(int *)(param_1 + 0x1d4) + 0x188) = 1;
              uVar18 = .debug::_MTNewSprite
                                 (0x5a0,*(short *)(param_1 + 0xc) + 0x90,
                                  (int)*(short *)(param_1 + 10),
                                  (int)(short)*(undefined4 *)(param_1 + 0x80),
                                  (int)*(short *)(param_1 + 0x48),uVar18);
              *(undefined4 *)(param_1 + 0x1d8) = uVar18;
              *(undefined1 *)(*(int *)(param_1 + 0x1d8) + 0x188) = 1;
              *(undefined4 *)(*(int *)(param_1 + 0x1d8) + 0xac) = 0xffffffff;
            }
            goto LAB_1006cf1c;
          }
        }
        else if (0x5b3 < iVar16) {
          *(undefined2 *)(param_1 + 0x110) = 0;
          *(undefined1 *)(param_1 + 0x185) = 0;
          *(undefined4 *)(param_1 + 0x80) = 0;
          *(undefined1 *)(param_1 + 0x17e) = 0;
          *(undefined4 *)(param_1 + 0x5c) = 0;
          puVar3 = PTR_PTR_100a09f8;
          switch(*(undefined2 *)(param_1 + 4)) {
          case 0x5b4:
            *(undefined1 *)(_DAT_100a0a44 + 1) = 1;
            .glue::SetRect(param_1 + 0x34,0,0,0x108,0x18);
            break;
          case 0x5b5:
            *(undefined1 *)(iVar10 + 1) = 1;
            .glue::SetRect(param_1 + 0x34,6,0,0x9e,0x18);
            break;
          case 0x5b6:
            *(undefined1 *)(iVar10 + 1) = 1;
            *(undefined1 *)(param_1 + 0x17e) = 1;
            .glue::SetRect(param_1 + 0x34,6,0,0x9e,0x18);
            break;
          case 0x5b7:
            *(undefined1 *)(_DAT_100a0a3c + 1) = 1;
            .glue::SetRect(param_1 + 0x34,0,0,0x108,0x28);
            break;
          case 0x5b8:
            *(undefined1 *)(iVar9 + 1) = 1;
            .glue::SetRect(param_1 + 0x34,8,0,0x8c,0x28);
            break;
          case 0x5b9:
            *(undefined1 *)(iVar9 + 1) = 1;
            *(undefined1 *)(param_1 + 0x17e) = 1;
            .glue::SetRect(param_1 + 0x34,0xe,0,0x92,0x28);
            break;
          case 0x5ba:
            *(undefined1 *)(_DAT_100a0a34 + 1) = 1;
            *(undefined1 *)(iVar8 + 1) = 1;
            *(undefined **)(param_1 + 0x1e8) = puVar3;
            .glue::SetRect(param_1 + 0x34,0xfffffff0,0x32,0x11c,0x78);
            break;
          case 0x5bb:
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar8 + 4);
            *(undefined4 *)(param_1 + 0x80) = 0x32;
            .glue::SetRect(param_1 + 0x34,0,0,0,0);
          }
          goto LAB_1006cf1c;
        }
      }
    }
  }
  else {
    if (iVar16 == 0xb5f) {
      *(undefined4 *)(param_1 + 0xc0) = *puVar14;
      *(undefined1 *)(param_1 + 0x17e) = 1;
      *(undefined2 *)(param_1 + 0x46) = 0;
      *(undefined2 *)(param_1 + 0x110) = 0;
      *(undefined4 *)(param_1 + 0x80) = 0;
      .glue::SetRect(param_1 + 0x34,0x24,0xffffffc0,0x3c,0x98);
      goto LAB_1006cf1c;
    }
    if (iVar16 < 0xb5f) {
      if (iVar16 == 0x5c4) {
        puVar6[0x71] = 1;
        .glue::SetRect(param_1 + 0x34,0x16,0x16,0x4e,0x4e);
        *(undefined2 *)(param_1 + 0x110) = 0x100;
        *(undefined4 *)(param_1 + 0x14c) = 1;
        *(undefined1 *)(param_1 + 0x185) = 1;
        goto LAB_1006cf1c;
      }
      if (iVar16 < 0x5c4) {
        if (iVar16 == 0x5be) {
          *(undefined4 *)(param_1 + 0x1f8) = 0;
          *(undefined4 *)(param_1 + 0x5c) = 0;
          *(undefined1 *)(iVar22 + 1) = 1;
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar22 + 4);
          *(undefined2 *)(param_1 + 0x46) = 0;
          *(undefined2 *)(param_1 + 0x110) = 0;
          *(undefined1 *)(param_1 + 0x185) = 1;
          *(undefined4 *)(param_1 + 0x80) = 0x3c;
          .glue::SetRect(param_1 + 0x34,7,0x10,0x2c,0x37);
          goto LAB_1006cf1c;
        }
        if ((0x5bd < iVar16) && (0x5c2 < iVar16)) {
          puVar6[0x71] = 1;
          .glue::SetRect(param_1 + 0x34,0x16,0x16,0x4e,0x4e);
          *(undefined2 *)(param_1 + 0x110) = 0x100;
          *(undefined2 *)(param_1 + 0xa6) = 0x1e;
          *(undefined4 *)(param_1 + 0x14c) = 1;
          *(undefined1 *)(param_1 + 0x185) = 1;
          goto LAB_1006cf1c;
        }
      }
      else {
        if (0xb55 < iVar16) {
          if (iVar16 < 0xb5e) {
            *(undefined4 *)(param_1 + 0x1f8) = 0;
            *(undefined4 *)(param_1 + 0x5c) = 0;
            *(undefined4 *)(param_1 + 0xc0) =
                 *(undefined4 *)(*(short *)(param_1 + 4) * 4 + 0x100a36d4);
            *(undefined2 *)(param_1 + 0x46) = 0;
            *(undefined2 *)(param_1 + 0x110) = 0;
            *(undefined1 *)(param_1 + 0x185) = 1;
            *(undefined4 *)(param_1 + 0x80) = 0;
            sVar20 = *(short *)(param_1 + 4);
            if (sVar20 == 0xb59) {
              .glue::SetRect(param_1 + 0x34,0,0,0x48,0x2d);
            }
            else if (sVar20 < 0xb59) {
              if (sVar20 == 0xb57) {
                .glue::SetRect(param_1 + 0x34,0,0,0x1a,0x28);
              }
              else if (sVar20 < 0xb57) {
                if (0xb55 < sVar20) {
                  .glue::SetRect(param_1 + 0x34,4,7,0x22,0x1f);
                  *(undefined4 *)(param_1 + 0x15c) = 1;
                }
              }
              else {
                .glue::SetRect(param_1 + 0x34,0,0,0x14,0x1e);
              }
            }
            else if (sVar20 == 0xb5b) {
              .glue::SetRect(param_1 + 0x34,4,7,0x22,0x1f);
              *(undefined4 *)(param_1 + 0x15c) = 1;
            }
            else if (sVar20 < 0xb5b) {
              .glue::SetRect(param_1 + 0x34,0,0,0x34,0x20);
            }
          }
          else {
            *(undefined4 *)(param_1 + 0xc0) = *puVar14;
            *(undefined2 *)(param_1 + 0x46) = 0;
            *(undefined2 *)(param_1 + 0x110) = 0;
            *(undefined4 *)(param_1 + 0x80) = 0;
            .glue::SetRect(param_1 + 0x34,0,0xffffffc0,0x18,0x98);
          }
          goto LAB_1006cf1c;
        }
        if ((iVar16 < 0x5d6) && (0x5d1 < iVar16)) {
          *(undefined4 *)(param_1 + 0x80) = 1;
          psVar1 = (short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 10);
          if (*psVar1 == 0) {
            *psVar1 = 100;
          }
          uVar19 = .debug::_Deviation((int)*(short *)(*(int *)*puVar2 +
                                                      *(short *)(param_1 + 0x48) * 0x10 + 10));
          *(undefined2 *)(param_1 + 0xa6) = uVar19;
          *(int *)(param_1 + 0x15c) =
               (int)*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 8);
          *(undefined1 *)(iVar13 + *(short *)(param_1 + 4) * 0x10 + -0x5d1f) = 1;
          *(undefined4 *)(param_1 + 0xc0) =
               *(undefined4 *)(iVar13 + *(short *)(param_1 + 4) * 0x10 + -0x5d1c);
          uVar18 = (*(undefined4 **)(param_1 + 0xc0))[1];
          *(undefined4 *)(param_1 + 0x34) = **(undefined4 **)(param_1 + 0xc0);
          *(undefined4 *)(param_1 + 0x38) = uVar18;
          *(short *)(param_1 + 0x36) = *(short *)(param_1 + 0x36) + 3;
          *(short *)(param_1 + 0x3a) = *(short *)(param_1 + 0x3a) + -3;
          *(short *)(param_1 + 0x34) = *(short *)(param_1 + 0x34) + 3;
          *(short *)(param_1 + 0x38) = *(short *)(param_1 + 0x38) + -3;
          *(undefined2 *)(param_1 + 0x110) = 0;
          *(undefined4 *)(param_1 + 0x1f8) = 0;
          *(undefined4 *)(param_1 + 0x5c) = 0;
          iVar15 = .debug::_GenerateSprite
                             ((int)*(short *)(param_1 + 0xc),(int)*(short *)(param_1 + 10),
                              (int)(short)*(undefined4 *)(param_1 + 0x15c),0x200,1,
                              *(int *)(param_1 + 0x80) + 1);
          if (iVar15 != 0) {
            *(undefined1 *)(iVar15 + 0xe9) = 1;
          }
          goto LAB_1006cf1c;
        }
      }
    }
    else if (iVar16 < 0xb7e) {
      if (iVar16 == 0xb74) {
        if (*(short *)(param_1 + 0x48) == -1) {
          *(undefined2 *)(param_1 + 0x110) = 0;
          *(undefined4 *)(param_1 + 0x5c) = 0;
          *(undefined4 *)(param_1 + 0x1f8) = 0;
          *(undefined4 *)(param_1 + 0x80) = 1;
        }
        else {
          *(undefined2 *)(param_1 + 0x110) = 0;
          *(undefined1 *)(param_1 + 0x185) = 1;
          .glue::SetRect(param_1 + 0x34,9,10,0x18,0x2a);
          *(int *)(param_1 + 0xc0) =
               *_DAT_100a0a58 +
               *(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 8) * 0x34;
          *(undefined2 *)(param_1 + 0xa4) =
               *(undefined2 *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 10);
          if (*(short *)(param_1 + 0xa4) == 0) {
            *(undefined2 *)(param_1 + 0xa4) = 0x96;
          }
          *(int *)(param_1 + 0x14c) =
               (int)*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 0xc);
          if (*(int *)(param_1 + 0x14c) == 0) {
            *(undefined4 *)(param_1 + 0x14c) = 0x40;
          }
          *(int *)(param_1 + 0x150) =
               (int)*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 0xe);
          if (*(int *)(param_1 + 0x150) == 0) {
            *(undefined4 *)(param_1 + 0x150) = 100;
          }
          *(int *)(param_1 + 0x154) = (int)*(short *)(param_1 + 0xc);
          uVar18 = .debug::_MTNewSprite
                             ((int)*(short *)(param_1 + 4),(int)*(short *)(param_1 + 8),
                              (int)*(short *)(param_1 + 6),*(int *)(param_1 + 0x80) + -1,0xffffffff,
                              uVar18);
          *(undefined4 *)(param_1 + 0x1d4) = uVar18;
          *(int *)(*(int *)(param_1 + 0x1d4) + 0xc0) =
               *_DAT_100a0a5c +
               *(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 8) * 0x34;
        }
        goto LAB_1006cf1c;
      }
      if (iVar16 < 0xb74) {
        if (iVar16 == 0xb71) {
          if (*(short *)(param_1 + 0x48) != 0x1ff) {
            *(undefined1 *)(_DAT_100a0a68 + 1) = 1;
            *(undefined4 *)(param_1 + 0x80) = 0;
            uVar17 = .debug::_MTNewSprite
                               (0xb71,(int)*(short *)(param_1 + 8),(int)*(short *)(param_1 + 6),100,
                                0x1ff,uVar18);
            *(undefined4 *)(param_1 + 0x1d4) = uVar17;
            if (*(int *)(param_1 + 0x1d4) != 0) {
              *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0x80) = 100;
            }
            uVar18 = .debug::_MTNewSprite
                               (0xb71,(int)*(short *)(param_1 + 8),(int)*(short *)(param_1 + 6),1,
                                0x1ff,uVar18);
            *(undefined4 *)(param_1 + 0x1d8) = uVar18;
            .glue::SetRect(param_1 + 0x34,7,0x1c,0x3d,0x29);
            if (*(int *)(param_1 + 0x1d4) != 0) {
              .glue::SetRect(*(int *)(param_1 + 0x1d4) + 0x34,0xfffffffc,0,0xc,0x29);
            }
            if (*(int *)(param_1 + 0x1d8) != 0) {
              .glue::SetRect(*(int *)(param_1 + 0x1d8) + 0x34,0x37,0,0x47,0x29);
            }
          }
          goto LAB_1006cf1c;
        }
        if (0xb70 < iVar16) {
          if (*(short *)(param_1 + 0x48) == -1) {
            .glue::SetRect(param_1 + 0x34,0,0,0,0);
            *(undefined2 *)(param_1 + 0x110) = 0;
          }
          else {
            *(undefined1 *)(iVar11 + 1) = 1;
            *(undefined1 *)(iVar12 + 1) = 1;
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar12 + 4);
            *(undefined2 *)(param_1 + 0x138) = 0xa0;
            *(undefined2 *)(param_1 + 0x112) = 0;
            *(undefined2 *)(param_1 + 0x46) = 0;
            *(undefined2 *)(param_1 + 0x110) = 0x208;
            *(undefined4 *)(param_1 + 0x80) = 0;
            *(undefined2 *)(param_1 + 0x114) = 6;
            *(undefined4 *)(param_1 + 0x14c) = 0;
            uVar17 = .debug::_MTNewSprite
                               (0xb72,(int)*(short *)(param_1 + 8),(int)*(short *)(param_1 + 6),100,
                                0xffffffff,uVar18);
            *(undefined4 *)(param_1 + 0x1d4) = uVar17;
            if (*(int *)(param_1 + 0x1d4) != 0) {
              *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0x80) = 100;
            }
            if (*(int *)(param_1 + 0x1d4) != 0) {
              *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0xc0) = *(undefined4 *)(iVar12 + 0x20);
            }
            uVar18 = .debug::_MTNewSprite
                               (0xb73,(int)*(short *)(param_1 + 8),(int)*(short *)(param_1 + 6),
                                *(int *)(param_1 + 0x80) + -1,0xffffffff,uVar18);
            *(undefined4 *)(param_1 + 0x1d8) = uVar18;
            if (*(int *)(param_1 + 0x1d8) != 0) {
              *(undefined4 *)(*(int *)(param_1 + 0x1d8) + 0x80) = 0xffffffff;
            }
            if (*(int *)(param_1 + 0x1d8) != 0) {
              *(undefined4 *)(*(int *)(param_1 + 0x1d8) + 0xc0) = *(undefined4 *)(iVar11 + 4);
            }
            .glue::SetRect(param_1 + 0x34,0x1e,0x32,0x5a,0x50);
          }
          goto LAB_1006cf1c;
        }
      }
      else if (0xb7b < iVar16) {
        *(undefined1 *)(param_1 + 0x188) = 1;
        if (*(short *)(param_1 + 4) == 0xb7c) {
          *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0a24;
        }
        else {
          *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0a20;
          *(undefined2 *)(param_1 + 0xa4) = 300;
          *(undefined1 *)(param_1 + 0x1b4) = 1;
        }
        *(undefined2 *)(param_1 + 0x138) = 0;
        *(undefined2 *)(param_1 + 0x112) = 0;
        *(undefined2 *)(param_1 + 0x46) = 0;
        *(undefined2 *)(param_1 + 0x110) = 0xb4;
        *(undefined4 *)(param_1 + 0x80) = 0;
        *(undefined2 *)(param_1 + 0x114) = 6;
        *(undefined4 *)(param_1 + 0x14c) = 0;
        *(undefined1 *)(param_1 + 0x185) = 0;
        *(undefined2 *)(param_1 + 0x1bc) = 4;
        *(int *)(param_1 + 0x158) = (int)*(short *)(param_1 + 10);
        *(undefined4 *)(param_1 + 0x1f8) = 0;
        *(undefined4 *)(param_1 + 0x5c) = 0;
        *(undefined2 *)(param_1 + 0x110) = 0;
        .glue::SetRect(param_1 + 0x34,0,0,0x20,0x74);
        if ((*(char *)(*(int *)*puVar2 + 0x26cd) != '\0') && (*(short *)(param_1 + 4) == 0xb7c)) {
          *(undefined4 *)(param_1 + 0xb8) = 0x10018;
        }
        goto LAB_1006cf1c;
      }
    }
    else if (iVar16 < 0xc12) {
      if (iVar16 == 0xbfe) {
        *(int *)(param_1 + 0x14c) =
             (int)*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 8);
        if (*(int *)(param_1 + 0x14c) == 0) {
          *(undefined4 *)(param_1 + 0x14c) = 0x20;
        }
        *(int *)(param_1 + 0x150) =
             (int)*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 10);
        if (*(int *)(param_1 + 0x150) == 0) {
          *(undefined4 *)(param_1 + 0x150) = 0x60;
        }
        if (0x60 < *(int *)(param_1 + 0x150)) {
          *(undefined4 *)(param_1 + 0x150) = 0x60;
        }
        iVar15 = _DAT_100a0a84;
        *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) << 8;
        iVar8 = _DAT_100a0a8c;
        iVar22 = _DAT_100a0a88;
        *(int *)(param_1 + 0x150) = *(int *)(param_1 + 0x150) << 8;
        *(undefined2 *)(param_1 + 0x112) = 0x18;
        *(undefined2 *)(param_1 + 0x138) = 0x8c;
        *(undefined2 *)(param_1 + 0x114) = 0x46;
        *(undefined2 *)(param_1 + 0x46) = 0;
        *(undefined2 *)(param_1 + 0x90) = 0x100;
        *(undefined2 *)(param_1 + 0x110) = 0x100;
        *(undefined1 *)(iVar15 + 1) = 1;
        *(undefined1 *)(iVar22 + 1) = 1;
        *(undefined1 *)(iVar8 + 1) = 1;
        sVar20 = (short)(*(int *)(param_1 + 0x14c) >> 9);
        iVar15 = (int)(short)(0x40 - sVar20);
        iVar22 = (int)(short)(sVar20 + 0x40);
        .glue::SetRect(param_1 + 0x34,iVar15,iVar15,iVar22,iVar22);
        goto LAB_1006cf1c;
      }
    }
    else if (iVar16 < 0xc15) {
      *(int *)(param_1 + 0x14c) =
           (int)*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 8);
      *(undefined2 *)(param_1 + 0x110) = 0;
      *(undefined1 *)(param_1 + 0x185) = 0;
      sVar20 = *(short *)(param_1 + 4);
      if (sVar20 == 0xc13) {
        *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0a7c;
      }
      else if (sVar20 < 0xc13) {
        if (0xc11 < sVar20) {
          *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0a80;
        }
      }
      else if (sVar20 < 0xc15) {
        *(undefined4 *)(param_1 + 0xc0) = *_DAT_100a0a78;
      }
      *(undefined2 *)(param_1 + 0xa4) = 5;
      *(undefined1 *)(param_1 + 0x88) = 1;
      *(undefined2 *)(param_1 + 0x138) = 0x78;
      *(undefined2 *)(param_1 + 0x114) = 0x5a;
      *(undefined2 *)(param_1 + 0x46) = 0;
      *(undefined2 *)(param_1 + 0x110) = 0x100;
      *(undefined2 *)(param_1 + 0x90) = 0x100;
      .glue::SetRect(param_1 + 0x34,4,0,0x23,0x20);
      goto LAB_1006cf1c;
    }
  }
  if ((0x4e1 < iVar16) && (iVar16 < 0x500)) {
    *(short *)(param_1 + 8) = *(short *)(param_1 + 8) >> 3;
    *(short *)(param_1 + 8) = *(short *)(param_1 + 8) << 3;
    *(short *)(param_1 + 6) = *(short *)(param_1 + 6) >> 3;
    *(short *)(param_1 + 6) = *(short *)(param_1 + 6) << 3;
    *(short *)(param_1 + 0xc) = *(short *)(param_1 + 0xc) >> 3;
    *(short *)(param_1 + 0xc) = *(short *)(param_1 + 0xc) << 3;
    *(short *)(param_1 + 10) = *(short *)(param_1 + 10) >> 3;
    *(short *)(param_1 + 10) = *(short *)(param_1 + 10) << 3;
    *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) >> 3;
    *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) << 3;
    *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) >> 3;
    *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) << 3;
    if (*(short *)(param_1 + 0x48) != -1) {
      *(int *)(param_1 + 0x14c) =
           (int)*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 8);
    }
    .glue::SetRect(param_1 + 0x34,1,1,0x23,0x23);
    piVar7 = _DAT_100a0a54;
    *(undefined2 *)(param_1 + 0x110) = 0;
    *(undefined1 *)(param_1 + 0x185) = 0;
    *(int *)(param_1 + 0xc0) = *piVar7 + (*(short *)(param_1 + 4) + -0x4e2) * 0x34;
    *(int *)(param_1 + 0x80) = -(*(short *)(param_1 + 10) * 2 + (int)*(short *)(param_1 + 0xc));
    *(undefined2 *)(param_1 + 0xa4) = 1;
    *(undefined4 *)(param_1 + 0x5c) = 0;
    *(undefined4 *)(param_1 + 0x1f8) = 0;
    if (*(short *)(param_1 + 4) == 0x4f6) {
      *(undefined4 *)(param_1 + 0xb8) = 0xb0001;
      *(undefined1 *)(param_1 + 0x88) = 1;
    }
  }
  piVar7 = _DAT_100a0a4c;
  if ((0x5a9 < *(short *)(param_1 + 4)) && (*(short *)(param_1 + 4) < 0x5b4)) {
    *(undefined1 *)(param_1 + 0x185) = 0;
    *(int *)(param_1 + 0xc0) = *piVar7 + (*(short *)(param_1 + 4) + -0x5aa) * 0x34;
    *(undefined2 *)(param_1 + 0x110) = 0;
    *(undefined4 *)(param_1 + 0x80) = 10;
    *(undefined2 *)(param_1 + 0xa6) = 0;
  }
  iVar15 = (int)*(short *)(param_1 + 4);
  if ((0xb67 < iVar15) && (iVar15 < 0xb71)) {
    *(undefined1 *)(_DAT_100a0a04 + iVar15 * 0x10 + -0xb67f) = 1;
    *(undefined2 *)(param_1 + 0x46) = 0;
    *(undefined2 *)(param_1 + 0x110) = 0;
    *(undefined4 *)(param_1 + 0x80) = 0;
    switch(*(undefined2 *)(param_1 + 4)) {
    case 0xb68:
      .glue::SetRect(param_1 + 0x34,4,0,0x33,0x3a);
      break;
    case 0xb69:
      .glue::SetRect(param_1 + 0x34,5,1,0x32,0x3a);
      break;
    case 0xb6a:
      .glue::SetRect(param_1 + 0x34,10,1,0x2e,0x38);
      *(undefined1 *)(param_1 + 0x185) = 1;
      break;
    case 0xb6b:
      .glue::SetRect(param_1 + 0x34,0,0,0x17,0x28);
      *(undefined1 *)(param_1 + 0x185) = 1;
      break;
    case 0xb6c:
      .glue::SetRect(param_1 + 0x34,4,0x16,0x22,0x33);
      *(undefined1 *)(param_1 + 0x185) = 1;
      break;
    case 0xb6d:
      .glue::SetRect(param_1 + 0x34,0xe,0x17,0x28,0x28);
      *(undefined1 *)(param_1 + 0x185) = 1;
      break;
    case 0xb6e:
      .glue::SetRect(param_1 + 0x34,6,0,0x37,0x20);
      break;
    case 0xb6f:
      .glue::SetRect(param_1 + 0x34,2,3,0x4b,0x1a);
      break;
    case 0xb70:
      .glue::SetRect(param_1 + 0x34,3,5,0x4d,0x20);
    }
  }
  if ((0xaf4 < *(short *)(param_1 + 4)) && (*(short *)(param_1 + 4) < 0xb22)) {
    *(undefined4 *)(param_1 + 0x5c) = 0;
    *(undefined4 *)(param_1 + 0x1f8) = 0;
    *(undefined4 *)(param_1 + 0x80) = 0xffffffff;
    *(undefined1 *)(param_1 + 0x88) = 1;
    .glue::SetRect(param_1 + 0x34,0,0,0,0);
    *(undefined1 *)(*(short *)(param_1 + 4) * 0x10 + 0x1009b4fd) = 1;
    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(*(short *)(param_1 + 4) * 0x10 + 0x1009b500);
    *(undefined1 *)(param_1 + 0x185) = 1;
    switch(*(undefined2 *)(param_1 + 4)) {
    case 0xb0b:
      .glue::SetRect(param_1 + 0x34,0xf,0xd,0x32,0x28);
      *(undefined1 *)(param_1 + 0x185) = 0;
      break;
    case 0xb10:
      .glue::SetRect(param_1 + 0x34,0xe,4,0x27,0x45);
      break;
    case 0xb11:
      .glue::SetRect(param_1 + 0x34,5,4,0x3b,0x46);
      break;
    case 0xb12:
      .glue::SetRect(param_1 + 0x34,2,6,0x1c,0x23);
      break;
    case 0xb13:
      .glue::SetRect(param_1 + 0x34,10,4,0x1e,0x21);
      break;
    case 0xb14:
      .glue::SetRect(param_1 + 0x34,0,0xe,0x1f,0x24);
    }
    if (*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 8) != 0) {
      *(undefined1 *)(param_1 + 0x17e) = 1;
      .debug::_FlipHRect(param_1 + 0x34,(int)*(short *)(*(int *)(param_1 + 0xc0) + 6));
    }
    sVar20 = *(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 10);
    if (sVar20 != 0) {
      *(int *)(param_1 + 0xb8) = sVar20 + 0x10000;
    }
    if (*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 0xc) != 0) {
      *(undefined4 *)(param_1 + 0x80) = 10000;
    }
    *(undefined2 *)(param_1 + 0x110) = 0;
  }
  if ((0xb21 < *(short *)(param_1 + 4)) && (*(short *)(param_1 + 4) < 0xb36)) {
    *(undefined4 *)(param_1 + 0x5c) = 0;
    *(undefined4 *)(param_1 + 0x1f8) = 0;
    *(undefined4 *)(param_1 + 0x80) = 0x96;
    *(undefined1 *)(param_1 + 0x88) = 0;
    sVar20 = .debug::_GetAmbDarkVal((int)*(short *)(param_1 + 0xc),(int)*(short *)(param_1 + 10));
    if (4 < sVar20) {
      *(undefined4 *)(param_1 + 0xb8) = 0x10006;
    }
    sVar20 = .debug::_GetAmbDarkVal((int)*(short *)(param_1 + 0xc),(int)*(short *)(param_1 + 10));
    if (7 < sVar20) {
      *(undefined4 *)(param_1 + 0xb8) = 0x10007;
    }
    if (*(short *)(param_1 + 4) == 0xb28) {
      *(undefined4 *)(param_1 + 0xb8) = 0xb0005;
    }
    *(undefined1 *)(_DAT_100a0a0c + *(short *)(param_1 + 4) * 0x10 + -0xb21f) = 1;
    .glue::SetRect(param_1 + 0x34,0x15,0x14,0x47,0x54);
    *(undefined1 *)(param_1 + 0x185) = 1;
    *(undefined2 *)(param_1 + 0x110) = 0;
  }
  iVar15 = _DAT_100a0a08;
  if ((0xb35 < *(short *)(param_1 + 4)) && (*(short *)(param_1 + 4) < 0xb4a)) {
    *(undefined4 *)(param_1 + 0x5c) = 0;
    *(undefined4 *)(param_1 + 0x1f8) = 0;
    *(undefined4 *)(param_1 + 0x80) = 0x78;
    *(undefined1 *)(iVar15 + *(short *)(param_1 + 4) * 0x10 + -0xb35f) = 1;
    *(undefined1 *)(param_1 + 0x185) = 1;
    *(undefined2 *)(param_1 + 0x110) = 0;
    .glue::SetRect(param_1 + 0x34,0,0,0,0);
  }
  iVar15 = (int)*(short *)(param_1 + 4);
  if ((0xb86 < iVar15) && (iVar15 < 0xb9a)) {
    *(undefined1 *)(_DAT_100a0a6c + iVar15 * 0x10 + -0xb85f) = 1;
    *(undefined2 *)(param_1 + 0x46) = 0;
    *(undefined2 *)(param_1 + 0x110) = 0;
    *(undefined4 *)(param_1 + 0x80) = 0;
    *(undefined1 *)(param_1 + 0x185) = 1;
  }
LAB_1006cf1c:
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  *(undefined4 *)(param_1 + 10) = *(undefined4 *)(param_1 + 6);
  *(undefined2 *)(param_1 + 0x13c) = 0x80;
  return;
}


// ==== .HandleBoxSprite @ 1006d878 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleBoxSprite(int param_1)

{
  short sVar1;
  bool bVar2;
  bool bVar3;
  short *psVar4;
  int *piVar5;
  undefined *puVar6;
  undefined4 *puVar7;
  undefined *puVar8;
  undefined4 *puVar9;
  undefined *puVar10;
  int iVar11;
  int *piVar12;
  uint uVar13;
  int iVar14;
  short sVar17;
  undefined2 uVar18;
  int iVar15;
  undefined4 uVar16;
  int iVar19;
  int iVar20;
  short *psVar21;
  ushort uVar22;
  uint uVar23;
  ushort uVar24;
  bool bVar25;
  uint unaff_r19;
  double dVar26;
  double dVar27;
  undefined1 auStack_a8 [6];
  undefined4 uStack_a2;
  undefined4 uStack_9e;
  undefined8 uStack_68;
  undefined8 uStack_60;
  
  piVar12 = _DAT_100a0a94;
  iVar11 = _DAT_100a0a68;
  iVar20 = _DAT_100a0a64;
  iVar14 = _DAT_100a0a40;
  iVar15 = _DAT_100a0a38;
  puVar10 = PTR_DAT_100a09f4;
  puVar8 = PTR_PTR_100a0830;
  puVar9 = _DAT_100a0360;
  puVar6 = PTR_PTR_100a01f0;
  puVar7 = _DAT_100a0058;
  piVar5 = _DAT_1009fdd8;
  psVar4 = _DAT_1009fd94;
  psVar21 = _DAT_1009fd90;
  if (*(char *)(param_1 + 0xe9) != '\0') {
    return;
  }
  if (*(char *)(param_1 + 0x1b2) != '\0') {
    return;
  }
  .debug::_StandardSpriteHandles(param_1);
  *(undefined1 *)(param_1 + 0x182) = 0;
  iVar19 = (int)*(short *)(param_1 + 4);
  if (iVar19 == 0x5c3) {
    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar10 + 0x74);
    if (0 < *(short *)(param_1 + 0xa6)) {
      *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
    }
    goto LAB_1006f948;
  }
  if (iVar19 < 0x5c3) {
    if (iVar19 == 0x51c) {
      if (*(short *)(param_1 + 0x46) < 1) {
        if (*(short *)(*(int *)*puVar7 + *(short *)(param_1 + 0x48) * 0x10 + 0xc) == 0) {
          *(int *)(param_1 + 0xc0) = *piVar12 + 0x9c;
        }
        else {
          *(int *)(param_1 + 0xc0) = *piVar12;
          sVar17 = *(short *)(*(int *)*puVar7 + *(short *)(param_1 + 0x48) * 0x10 + 8);
          if (sVar17 != 0) {
            iVar15 = (int)*psVar4 - (int)*(short *)(param_1 + 0x10);
            if (iVar15 < 1) {
              iVar15 = -iVar15;
            }
            if (iVar15 < 0x4b) {
              iVar15 = (int)*psVar21 - (int)*(short *)(param_1 + 0xe);
              if (iVar15 < 1) {
                iVar15 = -iVar15;
              }
              if (iVar15 < 0x4b) {
                if (*(int *)(param_1 + 0x1d4) == 0) {
                  uStack_9e._2_2_ = (short)*(undefined4 *)(param_1 + 0xe);
                  uStack_9e._0_2_ = (short)((uint)*(undefined4 *)(param_1 + 0xe) >> 0x10);
                  if (*(char *)(param_1 + 0x17e) == '\0') {
                    uStack_9e._2_2_ = uStack_9e._2_2_ + -0x36;
                  }
                  else {
                    uStack_9e._2_2_ = uStack_9e._2_2_ + 6;
                  }
                  uStack_9e = CONCAT22(uStack_9e._0_2_ + -0x2d,uStack_9e._2_2_);
                  if (sVar17 < 1) {
                    sVar17 = -sVar17;
                  }
                  .debug::_CreateBalloonSprite
                            (param_1,uStack_9e,*(char *)(param_1 + 0x17e),(int)sVar17);
                }
                goto LAB_1006f948;
              }
            }
            if (*(int *)(param_1 + 0x1d4) != 0) {
              .debug::_DestructBalloonSprite(param_1);
            }
          }
        }
      }
      else {
        if (*(int *)(param_1 + 0x1d4) != 0) {
          .debug::_DestructBalloonSprite(param_1);
        }
        *(int *)(param_1 + 0xc0) = *piVar12 + ((int)*(short *)(param_1 + 0x46) / 3) * 0x34;
        if (*(short *)(param_1 + 0x46) < 0xb) {
          *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        }
        *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
        if ((*(short *)(param_1 + 0xa6) == 0) &&
           (iVar15 = *(int *)*puVar7 + *(short *)(param_1 + 0x48) * 0x10,
           0 < *(short *)(iVar15 + 0xc))) {
          iVar15 = .debug::_MTNewSprite
                             ((int)*(short *)(iVar15 + 10),*(short *)(param_1 + 0xc) + 0x10,
                              *(short *)(param_1 + 10) + 0xd,*(int *)(*piVar5 + 0x80) + 1,0xffffffff
                              ,_DAT_1009ff38);
          .debug::_MTChangeSpriteLayer(iVar15,*(int *)(*piVar5 + 0x80) + 1);
          *(short *)(iVar15 + 0xc) =
               *(short *)(iVar15 + 0xc) -
               (short)((int)*(short *)(iVar15 + 0x36) + (int)*(short *)(iVar15 + 0x3a) >> 1);
          *(short *)(iVar15 + 10) =
               *(short *)(iVar15 + 10) -
               (short)((int)*(short *)(iVar15 + 0x34) + (int)*(short *)(iVar15 + 0x38) >> 1);
          *(int *)(iVar15 + 0x14) = (int)*(short *)(iVar15 + 0xc) << 8;
          *(int *)(iVar15 + 0x1c) = (int)*(short *)(iVar15 + 10) << 8;
          if ((2 < *(short *)(*(int *)*puVar7 + *(short *)(param_1 + 0x48) * 0x10 + 0xc)) &&
             (-1 < *(short *)(iVar15 + 0x9a))) {
            .debug::_RemoveLight(iVar15 + 0x9a);
          }
          sVar17 = .debug::_FastRand(1000);
          *(int *)(iVar15 + 0x2c) = -2000 - sVar17;
          sVar17 = .debug::_FastRand(800);
          *(int *)(iVar15 + 0x24) = sVar17 + -400;
          if (*(short *)(iVar15 + 0x110) == 0) {
            *(undefined2 *)(iVar15 + 0x110) = 0x151;
          }
          *(undefined2 *)(iVar15 + 0xb0) = 0xc;
          *(undefined2 *)(param_1 + 0xa6) = 4;
          iVar15 = *(int *)*puVar7 + *(short *)(param_1 + 0x48) * 0x10;
          *(short *)(iVar15 + 0xc) = *(short *)(iVar15 + 0xc) + -1;
        }
      }
      goto LAB_1006f948;
    }
    if (iVar19 < 0x51c) {
      if (iVar19 < 0x431) {
        if (iVar19 == 0x429) {
          *(int *)(param_1 + 0xc0) =
               *_DAT_100a0a28 +
               *(short *)(*(int *)*puVar7 + *(short *)(param_1 + 0x48) * 0x10 + 8) * 0x34;
          goto LAB_1006f948;
        }
        if (iVar19 < 0x429) {
          if ((iVar19 < 0x2ca) && (0x2c7 < iVar19)) {
            *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
            sVar17 = *(short *)(param_1 + 0xa6);
            if (sVar17 < 0x17) {
              if (sVar17 < 0x15) {
                if (sVar17 < 0xb) {
                  *(undefined4 *)(param_1 + 0xb8) = 0xb0002;
                }
                else {
                  *(undefined4 *)(param_1 + 0xb8) = 0xb0000;
                }
              }
              else {
                *(undefined4 *)(param_1 + 0xb8) = 0xb0001;
              }
            }
            if (*(short *)(param_1 + 0xa6) < 1) {
              *(undefined1 *)(param_1 + 0xe9) = 1;
            }
            goto LAB_1006f948;
          }
        }
        else if (0x42d < iVar19) goto LAB_1006dafc;
      }
      else if (iVar19 < 0x438) {
        if ((iVar19 < 0x435) && (0x432 < iVar19)) {
LAB_1006dafc:
          if (*(int *)(param_1 + 0x160) < 0) {
            *(undefined4 *)(param_1 + 0x5c) = 0;
            *(undefined4 *)(param_1 + 0x1f8) = 0;
            *(undefined1 *)(param_1 + 0x88) = 0;
            *(undefined2 *)(param_1 + 0x110) = 0;
            *(int *)(param_1 + 0x160) = *(int *)(param_1 + 0x160) + 1;
            uVar13 = *(uint *)(param_1 + 0x160);
            if ((int)uVar13 < -10) {
              if ((uVar13 & 1) == 0) {
                *(undefined4 *)(param_1 + 0xb8) = 0xb0000;
              }
              else {
                *(undefined4 *)(param_1 + 0xb8) = 0xb0002;
              }
            }
            else if ((uVar13 & 1) == 0) {
              *(undefined4 *)(param_1 + 0xb8) = 0xb0002;
            }
            else {
              *(undefined4 *)(param_1 + 0xb8) = 0;
            }
            puVar8 = PTR_PTR_100a01f4;
            if (-1 < *(int *)(param_1 + 0x160)) {
              *(undefined2 *)(param_1 + 0x110) = 0x96;
              *(undefined4 *)(param_1 + 0xb8) = 0;
              *(undefined **)(param_1 + 0x5c) = puVar8;
              *(undefined **)(param_1 + 0x1f8) = puVar6;
              *(int *)(param_1 + 0x24) =
                   ((int)*(short *)(param_1 + 0xc) - (int)*(short *)(param_1 + 0xc6)) * 0x100;
            }
          }
          else {
            bVar25 = true;
            if ((*(char *)(param_1 + 0xcd) == '\0') && (*(char *)(param_1 + 0xce) == '\0')) {
              bVar25 = false;
            }
            if (bVar25) {
              uVar16 = 0;
            }
            else {
              uVar16 = *(undefined4 *)(param_1 + 0x2c);
            }
            iVar15 = .debug::_PEDistance(*(undefined4 *)(param_1 + 0x24),uVar16);
            iVar15 = (iVar15 * 0x168) / 0x6900 + (iVar15 * 0x168 >> 0x1f);
            sVar17 = (short)iVar15 - (short)(iVar15 >> 0x1f);
            if (*(int *)(param_1 + 0x24) < 1) {
              *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + sVar17;
            }
            else {
              *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) - sVar17;
            }
            while (*(short *)(param_1 + 0x46) < 0) {
              *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 0x168;
            }
            while (0x167 < *(short *)(param_1 + 0x46)) {
              *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -0x168;
            }
            *(short *)(param_1 + 0x1aa) = *(short *)(param_1 + 0x46);
            *(undefined1 *)(param_1 + 0x88) = 0;
            *(undefined1 *)(param_1 + 0x89) = 1;
          }
          goto LAB_1006f948;
        }
      }
      else if (iVar19 < 0x43a) {
        if (0 < *(short *)(param_1 + 0x46)) {
          *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        }
        if (0xb < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 2;
        }
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(_DAT_100a0a10 + ((int)*(short *)(param_1 + 0x46) >> 1) * 4 + 4);
        if (0 < *(int *)(param_1 + 0x15c)) {
          *(int *)(param_1 + 0x15c) = *(int *)(param_1 + 0x15c) + -1;
          if (*(int *)(param_1 + 0x15c) < 0x10) {
            *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + 0x1e;
          }
          else {
            *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + -0x1e;
          }
          *(undefined4 *)(param_1 + 0x24) = 0;
          *(undefined4 *)(param_1 + 0x1f8) = 0;
        }
        if (*(int *)(param_1 + 0x15c) == 0) {
          *(undefined1 *)(param_1 + 0x185) = 1;
          *(undefined **)(param_1 + 0x1f8) = puVar6;
        }
        if (*(short *)(param_1 + 4) == 0x439) {
          .glue::SetRect(param_1 + 0x34,0x12,4,0x5b,0x12);
        }
        if (((*(char *)(param_1 + 0x186) != '\0') || (*(int *)(param_1 + 0x154) != 0)) &&
           (-1 < *(int *)(param_1 + 0x14c))) {
          *(undefined4 *)(param_1 + 0x154) = 1;
          *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + -1;
          if (*(int *)(param_1 + 0x14c) < 0) {
            *(undefined4 *)(param_1 + 0x14c) = 0;
          }
          if ((*(short *)(param_1 + 0xa6) < 1) && ((*_DAT_1009fd2c & 3) == 0)) {
            if (*(int *)(param_1 + 0x14c) < 0x5b) {
              *(undefined2 *)(param_1 + 0xa6) = 10;
            }
            else {
              *(undefined2 *)(param_1 + 0xa6) = 0x1e;
            }
            *(undefined4 *)(param_1 + 0x158) = 6;
            *(undefined4 *)(param_1 + 0xb8) = 0x10009;
            if (*(int *)(param_1 + 0x14c) == 0) {
              *(undefined1 *)(param_1 + 0xe9) = 1;
              .debug::_ExplodeFaceIntoParticles
                        (*(undefined4 *)(param_1 + 0xc0),*(undefined4 *)(param_1 + 10),1,2,4,100,100
                        );
            }
          }
          else {
            *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
            if (*(int *)(param_1 + 0x158) < 1) {
              *(int *)(param_1 + 0xb8) = *(int *)(param_1 + 0x150) + 0x10000;
            }
            else {
              if (*(int *)(param_1 + 0x158) < 4) {
                *(undefined4 *)(param_1 + 0xb8) = 0x10008;
              }
              else {
                *(undefined4 *)(param_1 + 0xb8) = 0x10009;
              }
              *(int *)(param_1 + 0x158) = *(int *)(param_1 + 0x158) + -1;
            }
          }
        }
        iVar14 = *(int *)(param_1 + 0x24);
        iVar15 = iVar14;
        if (iVar14 < 1) {
          iVar15 = -iVar14;
        }
        if (iVar15 < 0x81) {
          *(undefined4 *)(param_1 + 0x24) = 0;
        }
        else if (iVar14 < 1) {
          *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + 0x80;
        }
        else {
          *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + -0x80;
        }
        if (*(int *)(param_1 + 0x15c) < 1) {
          uStack_60 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x2c) ^ 0x80000000);
          iVar15 = (int)((uStack_60 - _DAT_100a1af0) * dRam100a1ae8);
          uStack_68 = (double)(longlong)iVar15;
          *(int *)(param_1 + 0x2c) = iVar15;
        }
        goto LAB_1006f948;
      }
    }
    else if (iVar19 < 0x5ae) {
      if (iVar19 == 0x5a5) {
LAB_1006df20:
        uVar23 = *_DAT_1009fd98;
        uVar13 = *(int *)(param_1 + 0x158) + *(int *)(param_1 + 0x15c) + 1;
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (7 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)
              (_DAT_100a0a1c +
               (((int)*(short *)(param_1 + 0x46) >> 1) + *(int *)(param_1 + 0x14c) * 4) * 4 + 4);
        *(short *)(param_1 + 0xa6) = (short)uVar23 - (short)(uVar23 / uVar13) * (short)uVar13;
        if ((int)*(short *)(param_1 + 0xa6) < *(int *)(param_1 + 0x158)) {
          iVar14 = *(int *)(param_1 + 0x164);
          iVar15 = *(int *)(param_1 + 0x154);
          if ((*(short *)(param_1 + 0xa6) == 0) && (*(int *)(param_1 + 0xac) != -1)) {
            .debug::_CalcStereoVolume(auStack_a8,0x2a,*(undefined4 *)(param_1 + 0xe));
          }
          uStack_68 = (double)CONCAT44(0x43300000,iVar15 - iVar14 ^ 0x80000000);
          iVar15 = (int)(dRam100a1ae0 * (uStack_68 - _DAT_100a1af0));
          *(int *)(param_1 + 0x168) = iVar15;
          if (0x600 < *(int *)(param_1 + 0x168)) {
            *(undefined4 *)(param_1 + 0x168) = 0x600;
          }
          *(int *)(param_1 + 0x164) = *(int *)(param_1 + 0x164) + *(int *)(param_1 + 0x168);
          *(undefined4 *)(param_1 + 0xf4) = *(undefined4 *)(param_1 + 0x154);
        }
        else {
          uStack_68 = (double)CONCAT44(0x43300000,
                                       *(int *)(param_1 + 0x164) - *(int *)(param_1 + 0xf4) ^
                                       0x80000000);
          iVar15 = (int)(dRam100a1ae0 * (uStack_68 - _DAT_100a1af0));
          *(int *)(param_1 + 0x168) = iVar15;
          if (-0x100 < *(int *)(param_1 + 0x168)) {
            *(undefined4 *)(param_1 + 0x168) = 0xffffff00;
          }
          if (*(int *)(param_1 + 0x168) < -0x700) {
            *(undefined4 *)(param_1 + 0x168) = 0xfffff900;
          }
          *(int *)(param_1 + 0x164) = *(int *)(param_1 + 0x164) + *(int *)(param_1 + 0x168);
        }
        uStack_60 = (double)(longlong)iVar15;
        if (*(int *)(param_1 + 0x164) < 0) {
          *(undefined4 *)(param_1 + 0x164) = 0;
        }
        if ((*(short *)(param_1 + 4) == 0x5a5) &&
           ((int)*(short *)(param_1 + 0xa6) < *(int *)(param_1 + 0x158))) {
          sVar17 = 0;
          bVar25 = false;
          iVar15 = *(int *)(*(int *)(param_1 + 0x9c) + 0x40);
          bVar2 = false;
          bVar3 = false;
          if ((iVar15 != 0) &&
             ((*(char *)(iVar15 + 0x186) != '\0' && (*(int *)(iVar15 + 0xe0) != *piVar5)))) {
            *(undefined1 *)(iVar15 + 0x186) = 0;
            sVar17 = 1;
            bVar25 = true;
          }
          if ((((*(int *)(param_1 + 0x1d4) != 0) &&
               (iVar15 = *(int *)(*(int *)(*(int *)(param_1 + 0x1d4) + 0x9c) + 0x40), iVar15 != 0))
              && (*(char *)(iVar15 + 0x186) != '\0')) && (*(int *)(iVar15 + 0xe0) != *piVar5)) {
            *(undefined1 *)(iVar15 + 0x186) = 0;
            bVar2 = true;
            sVar17 = sVar17 + 1;
          }
          if (((*(int *)(param_1 + 0x1d8) != 0) &&
              (iVar15 = *(int *)(*(int *)(*(int *)(param_1 + 0x1d8) + 0x9c) + 0x40), iVar15 != 0))
             && ((*(char *)(iVar15 + 0x186) != '\0' && (*(int *)(iVar15 + 0xe0) != *piVar5)))) {
            *(undefined1 *)(iVar15 + 0x186) = 0;
            bVar3 = true;
            sVar17 = sVar17 + 1;
          }
          uVar13 = *(uint *)(param_1 + 0x16c);
          uStack_68 = (double)CONCAT44(0x43300000,uVar13 ^ 0x80000000);
          dVar26 = dRam100a1ad8 * (uStack_68 - _DAT_100a1af0);
          dVar27 = dRam100a1ad0;
          if (dRam100a1ad0 < dVar26) {
            dVar27 = dVar26;
          }
          iVar15 = (int)dVar27;
          uStack_68 = (double)(longlong)iVar15;
          iVar14 = uVar13 + (int)sVar17 * (uVar13 - iVar15);
          if (bVar25) {
            *(int *)(param_1 + 0x154) = iVar15;
          }
          else {
            *(int *)(param_1 + 0x154) = iVar14;
          }
          if (bVar2) {
            *(int *)(*(int *)(param_1 + 0x1d4) + 0x154) = iVar15;
          }
          else {
            *(int *)(*(int *)(param_1 + 0x1d4) + 0x154) = iVar14;
          }
          uStack_60 = uStack_68;
          if (bVar3) {
            *(int *)(*(int *)(param_1 + 0x1d8) + 0x154) = iVar15;
          }
          else {
            *(int *)(*(int *)(param_1 + 0x1d8) + 0x154) = iVar14;
          }
        }
        .debug::_HandleGeyserColumn(param_1);
        goto LAB_1006f948;
      }
      if (iVar19 < 0x5a5) {
        if (iVar19 == 0x5a0) goto LAB_1006df20;
      }
      else if (0x5a9 < iVar19) {
        if (0 < *(short *)(param_1 + 0xa6)) {
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
        }
        if (*(short *)(param_1 + 0xa6) == 0) {
          iVar15 = *(short *)(param_1 + 0x48) * 0x10;
          iVar14 = *(int *)*puVar7 + iVar15;
          iVar20 = *(int *)*puVar7 + 0xe;
          if ((*(short *)(iVar20 + *(short *)(iVar14 + 8) * 0x10) == 1) ||
             (*(short *)(iVar20 + *(short *)(iVar14 + 10) * 0x10) == 1)) {
            sVar17 = *(short *)(param_1 + 4);
            iVar15 = *(short *)(iVar20 + iVar15) + 0x6e1;
            if (sVar17 == 0x5ac) {
              iVar15 = .debug::_MTNewSprite
                                 (iVar15,(int)*(short *)(param_1 + 0xc),
                                  (int)*(short *)(param_1 + 10),*(int *)(param_1 + 0x80) + -1,
                                  0xffffffff,puVar8);
              if (iVar15 != 0) {
                sVar17 = .debug::_FastRand(600);
                *(int *)(iVar15 + 0x24) = sVar17 + 0xaf0;
                sVar17 = .debug::_FastRand(700);
                *(int *)(iVar15 + 0x2c) = -(sVar17 + 500);
              }
            }
            else if (sVar17 < 0x5ac) {
              if (sVar17 == 0x5aa) {
                iVar15 = .debug::_MTNewSprite
                                   (iVar15,(int)*(short *)(param_1 + 0xc),
                                    (int)*(short *)(param_1 + 10),*(int *)(param_1 + 0x80) + -1,
                                    0xffffffff,puVar8);
                if (iVar15 != 0) {
                  sVar17 = .debug::_FastRand(300);
                  *(int *)(iVar15 + 0x24) = sVar17 + -0x96;
                  sVar17 = .debug::_FastRand(400);
                  *(int *)(iVar15 + 0x2c) = (int)sVar17;
                }
              }
              else if ((0x5a9 < sVar17) &&
                      (iVar15 = .debug::_MTNewSprite
                                          (iVar15,(int)*(short *)(param_1 + 0xc),
                                           (int)*(short *)(param_1 + 10),
                                           *(int *)(param_1 + 0x80) + -1,0xffffffff,puVar8),
                      iVar15 != 0)) {
                sVar17 = .debug::_FastRand(300);
                *(int *)(iVar15 + 0x24) = sVar17 + -0x96;
                sVar17 = .debug::_FastRand(300);
                *(int *)(iVar15 + 0x2c) = -3000 - sVar17;
              }
            }
            else if ((sVar17 < 0x5ae) &&
                    (iVar15 = .debug::_MTNewSprite
                                        (iVar15,(int)*(short *)(param_1 + 0xc),
                                         (int)*(short *)(param_1 + 10),*(int *)(param_1 + 0x80) + -1
                                         ,0xffffffff,puVar8), iVar15 != 0)) {
              sVar17 = .debug::_FastRand(600);
              *(int *)(iVar15 + 0x24) = -(sVar17 + 0xaf0);
              sVar17 = .debug::_FastRand(700);
              *(int *)(iVar15 + 0x2c) = -(sVar17 + 500);
            }
            sVar17 = .debug::_FastRand(0x1e);
            *(short *)(param_1 + 0xa6) = sVar17 + 0x32;
          }
        }
        goto LAB_1006f948;
      }
    }
    else {
      if (iVar19 == 0x5be) {
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(_DAT_100a0a2c + *(short *)(param_1 + 0x46) * 4 + 4);
        if ((0 < *(short *)(param_1 + 0x46)) &&
           (*(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1,
           3 < *(short *)(param_1 + 0x46))) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        goto LAB_1006f948;
      }
      if (((iVar19 < 0x5be) && (iVar19 < 0x5bc)) && (0x5b3 < iVar19)) {
        switch(iVar19) {
        case 0x5b4:
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0a44 + 4);
          break;
        case 0x5b5:
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar14 + 4);
          break;
        case 0x5b6:
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar14 + 4);
          break;
        case 0x5b7:
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0a3c + 4);
          break;
        case 0x5b8:
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar15 + 4);
          break;
        case 0x5b9:
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar15 + 4);
          break;
        case 0x5ba:
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0a34 + 4);
          break;
        case 0x5bb:
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0a30 + 4);
        }
        goto LAB_1006f948;
      }
    }
  }
  else {
    if (iVar19 == 0xb74) {
      if (*(short *)(param_1 + 0x48) != -1) {
        uVar22 = *(ushort *)(param_1 + 0xa6);
        if (((short)uVar22 < 1) || (*(short *)(param_1 + 0xa4) < -0xf9)) {
          if (*(short *)(param_1 + 0xa4) < 1) {
            *(undefined2 *)(param_1 + 0x110) = 0xfa;
          }
        }
        else {
          sVar17 = ((short)uVar22 >> 2) + (ushort)((short)uVar22 < 0 && (uVar22 & 3) != 0);
          if (sVar17 < 1) {
            sVar17 = 1;
          }
          if ((uVar22 & 1) == 0) {
            *(int *)(param_1 + 0x14) = (*(int *)(param_1 + 0x154) - (int)sVar17) * 0x100;
          }
          else {
            *(int *)(param_1 + 0x14) = (*(int *)(param_1 + 0x154) + (int)sVar17) * 0x100;
          }
          *(short *)(param_1 + 0xc) = (short)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
        }
      }
      goto LAB_1006f948;
    }
    if (iVar19 < 0xb74) {
      if (iVar19 < 0xb5e) {
        if (iVar19 < 0x5d6) {
          if (0x5d1 < iVar19) {
            if (*(int *)(param_1 + 0x15c) == 0) {
              return;
            }
            *(undefined4 *)(param_1 + 0xc0) =
                 *(undefined4 *)(_DAT_100a0a74 + iVar19 * 0x10 + -0x5d1c);
            if (0 < *(short *)(param_1 + 0xa6)) {
              *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
            }
            if (((*(short *)(param_1 + 0xa6) < 1) && (*(int *)(param_1 + 0x1d4) == 0)) &&
               (*(int *)(param_1 + 0x15c) != 0)) {
              uVar18 = .debug::_Deviation((int)*(short *)(*(int *)*puVar7 +
                                                          *(short *)(param_1 + 0x48) * 0x10 + 10));
              *(undefined2 *)(param_1 + 0xa6) = uVar18;
              *(undefined4 *)(param_1 + 0x150) = 1;
              if (((*(int *)(param_1 + 0x15c) != 0) &&
                  (iVar15 = .debug::_GenerateSprite
                                      ((int)*(short *)(param_1 + 0xc),(int)*(short *)(param_1 + 10),
                                       (int)(short)*(int *)(param_1 + 0x15c),0x200,1,
                                       *(int *)(param_1 + 0x80) + 1), iVar15 != 0)) &&
                 (iVar14 = *(int *)(iVar15 + 0xc0), iVar14 != 0)) {
                sVar17 = *(short *)(iVar14 + 8);
                sVar1 = *(short *)(iVar14 + 0xc);
                uVar22 = *(short *)(iVar14 + 0xe) - *(short *)(iVar14 + 10);
                *(undefined1 *)(iVar15 + 0x1b2) = 1;
                uVar24 = sVar1 - sVar17;
                sVar17 = *(short *)(param_1 + 4);
                if (sVar17 == 0x5d2) {
                  *(ushort *)(iVar15 + 0xc) =
                       (*(short *)(param_1 + 0x10) -
                       (((short)uVar22 >> 1) + (ushort)((short)uVar22 < 0 && (uVar22 & 1) != 0))) -
                       *(short *)(*(int *)(iVar15 + 0xc0) + 10);
                  *(short *)(iVar15 + 10) = *(short *)(param_1 + 10) + 10;
                  *(int *)(param_1 + 0x154) = (int)*(short *)(iVar15 + 0x38) / 3 + 4;
                }
                else if (sVar17 == 0x5d3) {
                  *(ushort *)(iVar15 + 0xc) =
                       (*(short *)(param_1 + 0x10) -
                       (((short)uVar22 >> 1) + (ushort)((short)uVar22 < 0 && (uVar22 & 1) != 0))) -
                       *(short *)(*(int *)(iVar15 + 0xc0) + 10);
                  *(short *)(iVar15 + 10) =
                       (*(short *)(param_1 + 10) + 0x1c) - *(short *)(iVar15 + 0x38);
                  *(int *)(param_1 + 0x154) =
                       ((int)*(short *)(iVar15 + 0x38) - (int)*(short *)(iVar15 + 0x34)) / 3 + 4;
                }
                else if (sVar17 == 0x5d4) {
                  *(short *)(iVar15 + 0xc) =
                       (*(short *)(param_1 + 0xc) + 0x1c) -
                       *(short *)(*(int *)(iVar15 + 0xc0) + 0xe);
                  *(ushort *)(iVar15 + 10) =
                       (*(short *)(param_1 + 0xe) -
                       (((short)uVar24 >> 1) + (ushort)((short)uVar24 < 0 && (uVar24 & 1) != 0))) -
                       *(short *)(*(int *)(iVar15 + 0xc0) + 8);
                  *(int *)(param_1 + 0x154) =
                       ((int)*(short *)(iVar15 + 0x3a) - (int)*(short *)(iVar15 + 0x36)) / 3 + 4;
                }
                else if (sVar17 == 0x5d5) {
                  *(short *)(iVar15 + 0xc) = *(short *)(param_1 + 0xc) + 10;
                  *(ushort *)(iVar15 + 10) =
                       (*(short *)(param_1 + 0xe) -
                       (((short)uVar24 >> 1) + (ushort)((short)uVar24 < 0 && (uVar24 & 1) != 0))) -
                       *(short *)(*(int *)(iVar15 + 0xc0) + 8);
                  *(int *)(param_1 + 0x154) = (int)*(short *)(iVar15 + 0x3a) / 3 + 4;
                }
                *(int *)(param_1 + 0x1d4) = iVar15;
                *(int *)(*(int *)(param_1 + 0x1d4) + 0x14) =
                     (int)*(short *)(*(int *)(param_1 + 0x1d4) + 0xc) << 8;
                *(int *)(*(int *)(param_1 + 0x1d4) + 0x1c) =
                     (int)*(short *)(*(int *)(param_1 + 0x1d4) + 10) << 8;
              }
            }
            if (0 < *(int *)(param_1 + 0x150)) {
              *(int *)(param_1 + 0x150) = *(int *)(param_1 + 0x150) + 1;
              if (*(int *)(param_1 + 0x150) == 3) {
                .debug::_STPlay3DSoundRand(*_DAT_100a0364,1,0x100,*(undefined4 *)(param_1 + 0xe));
              }
              iVar15 = *(int *)(param_1 + 0x1d4);
              if (iVar15 == 0) {
                *(undefined4 *)(param_1 + 0x150) = 0;
              }
              else {
                sVar17 = *(short *)(param_1 + 4);
                if (sVar17 == 0x5d2) {
                  *(short *)(iVar15 + 10) = *(short *)(iVar15 + 10) + -3;
                  iVar15 = (*(short *)(param_1 + 10) + 7) -
                           (int)*(short *)(*(int *)(param_1 + 0x1d4) + 10);
                  if (iVar15 < 1) {
                    iVar15 = 0;
                  }
                  *(short *)(*(int *)(param_1 + 0x1d4) + 0x1ba) = (short)iVar15;
                }
                else if (sVar17 == 0x5d3) {
                  *(short *)(iVar15 + 10) = *(short *)(iVar15 + 10) + 3;
                  iVar15 = (*(short *)(param_1 + 10) + 0x1d) -
                           (int)*(short *)(*(int *)(param_1 + 0x1d4) + 10);
                  if (iVar15 < 1) {
                    iVar15 = 0;
                  }
                  *(short *)(*(int *)(param_1 + 0x1d4) + 0x1bc) = (short)iVar15;
                }
                else if (sVar17 == 0x5d4) {
                  *(short *)(iVar15 + 0xc) = *(short *)(iVar15 + 0xc) + 3;
                  iVar15 = (*(short *)(param_1 + 0xc) + 0x1d) -
                           (int)*(short *)(*(int *)(param_1 + 0x1d4) + 0xc);
                  if (iVar15 < 1) {
                    iVar15 = 0;
                  }
                  *(short *)(*(int *)(param_1 + 0x1d4) + 0x1b6) = (short)iVar15;
                }
                else if (sVar17 == 0x5d5) {
                  *(short *)(iVar15 + 0xc) = *(short *)(iVar15 + 0xc) + -3;
                  iVar15 = (*(short *)(param_1 + 0xc) + 7) -
                           (int)*(short *)(*(int *)(param_1 + 0x1d4) + 0xc);
                  if (iVar15 < 1) {
                    iVar15 = 0;
                  }
                  *(short *)(*(int *)(param_1 + 0x1d4) + 0x1b8) = (short)iVar15;
                }
                *(int *)(*(int *)(param_1 + 0x1d4) + 0x14) =
                     (int)*(short *)(*(int *)(param_1 + 0x1d4) + 0xc) << 8;
                *(int *)(*(int *)(param_1 + 0x1d4) + 0x1c) =
                     (int)*(short *)(*(int *)(param_1 + 0x1d4) + 10) << 8;
                if (*(int *)(param_1 + 0x154) < *(int *)(param_1 + 0x150)) {
                  *(int *)(*(int *)(param_1 + 0x1d4) + 0x14) =
                       (int)*(short *)(*(int *)(param_1 + 0x1d4) + 0xc) << 8;
                  *(int *)(*(int *)(param_1 + 0x1d4) + 0x1c) =
                       (int)*(short *)(*(int *)(param_1 + 0x1d4) + 10) << 8;
                  *(undefined1 *)(*(int *)(param_1 + 0x1d4) + 0x1b2) = 0;
                  *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0x1b8) = 32000;
                  *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0x1ba) = 32000;
                  *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0x1b6) = 0;
                  *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0x1bc) = 0;
                  *(undefined4 *)(param_1 + 0x150) = 0;
                }
              }
            }
            iVar15 = *(int *)(param_1 + 0x1d4);
            if ((iVar15 != 0) &&
               ((*(char *)(iVar15 + 0xe9) != '\0' || (*(char *)(iVar15 + 0xea) != '\0')))) {
              *(undefined4 *)(param_1 + 0x1d4) = 0;
              *(undefined4 *)(param_1 + 0x150) = 0;
              uVar18 = .debug::_Deviation((int)*(short *)(*(int *)*puVar7 +
                                                          *(short *)(param_1 + 0x48) * 0x10 + 10));
              *(undefined2 *)(param_1 + 0xa6) = uVar18;
            }
            goto LAB_1006f948;
          }
          if (iVar19 < 0x5c5) {
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar10 + 0x74);
            if (0 < *(short *)(param_1 + 0xa6)) {
              *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
            }
            puVar6 = PTR_DAT_1009fe78;
            if ((((*(int *)(param_1 + 0x14c) < 1) &&
                 (*(undefined4 *)(param_1 + 0x1f8) = 0,
                 *(short *)puVar6 + 0x1a0 < (int)*(short *)(param_1 + 10))) &&
                (0x5dc < *(int *)(param_1 + 0x2c))) && (*(char *)(param_1 + 0xe9) == '\0')) {
              *(undefined1 *)(param_1 + 0xe9) = 1;
            }
            goto LAB_1006f948;
          }
        }
        else if (iVar19 == 0xb5b) {
          if (0 < *(short *)(param_1 + 0xa6)) {
            *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
          }
          goto LAB_1006f948;
        }
      }
      else {
        if (iVar19 == 0xb71) {
          if (*(short *)(param_1 + 0x48) == -1) {
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar11 + 8);
          }
          else {
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar11 + 4);
          }
          goto LAB_1006f948;
        }
        if (iVar19 < 0xb71) {
          if (iVar19 < 0xb60) {
            iVar15 = (int)*(short *)(param_1 + 0x46);
            if (*(short *)(param_1 + 0x46) < 1) {
              iVar15 = -iVar15;
            }
            *(int *)(param_1 + 0xc0) = *_DAT_100a0a98 + (iVar15 >> 1) * 0x34;
            if (*(short *)(param_1 + 0x46) == 0) {
              sVar17 = *(short *)(*(int *)*puVar7 + *(short *)(param_1 + 0x48) * 0x10 + 8);
              if (sVar17 != 0) {
                iVar15 = (int)*psVar4 - (int)*(short *)(param_1 + 0x10);
                if (iVar15 < 1) {
                  iVar15 = -iVar15;
                }
                if (iVar15 < 0x4b) {
                  iVar15 = (int)*psVar21 - (int)*(short *)(param_1 + 0xe);
                  if (iVar15 < 1) {
                    iVar15 = -iVar15;
                  }
                  if (iVar15 < 0x4b) {
                    if (*(int *)(param_1 + 0x1d4) == 0) {
                      uStack_a2._2_2_ = (short)*(undefined4 *)(param_1 + 0xe);
                      uStack_a2._0_2_ = (short)((uint)*(undefined4 *)(param_1 + 0xe) >> 0x10);
                      if (*(char *)(param_1 + 0x17e) == '\0') {
                        uStack_a2._2_2_ = uStack_a2._2_2_ + -0x36;
                      }
                      else {
                        uStack_a2._2_2_ = uStack_a2._2_2_ + 6;
                      }
                      uStack_a2 = CONCAT22(uStack_a2._0_2_ + -0x3c,uStack_a2._2_2_);
                      if (sVar17 < 1) {
                        sVar17 = -sVar17;
                      }
                      .debug::_CreateBalloonSprite
                                (param_1,uStack_a2,*(char *)(param_1 + 0x17e),(int)sVar17);
                    }
                    goto LAB_1006f238;
                  }
                }
                if (*(int *)(param_1 + 0x1d4) != 0) {
                  .debug::_DestructBalloonSprite(param_1);
                }
              }
            }
            else if (*(short *)(param_1 + 0x46) != 0) {
              if (*(int *)(param_1 + 0x1d4) != 0) {
                .debug::_DestructBalloonSprite(param_1);
              }
              *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
              if (*(short *)(param_1 + 0x46) == 7) {
                .glue::SetRect(param_1 + 0x34,0,0,0,0);
              }
            }
LAB_1006f238:
            if (*(short *)(param_1 + 0x46) < 0xb) {
              if (*(short *)(*(int *)*puVar7 + *(short *)(param_1 + 0x48) * 0x10 + 0xe) == 1) {
                .glue::SetRect(param_1 + 0x34,0,0,0,0);
                *(undefined2 *)(param_1 + 0x46) = 10;
              }
            }
            else {
              *(undefined2 *)(param_1 + 0x46) = 10;
              .glue::SetRect(param_1 + 0x34,0,0,0,0);
              *(undefined2 *)(*(int *)*puVar7 + *(short *)(param_1 + 0x48) * 0x10 + 0xe) = 1;
            }
            goto LAB_1006f948;
          }
        }
        else if (iVar19 < 0xb73) {
          if (*(short *)(param_1 + 0x48) != -1) {
            sVar17 = -1;
            if ((*(char *)(param_1 + 0x186) != '\0') && (*(short *)(param_1 + 0x112) < 0xe)) {
              *(short *)(param_1 + 0x112) = *(short *)(param_1 + 0x112) + 1;
            }
            switch(*(undefined1 *)(param_1 + 0xce)) {
            case 3:
            case 4:
            case 7:
              sVar17 = 0;
              break;
            case 0xc:
            case 0x10:
            case 0x18:
              sVar17 = 2;
              break;
            case 0xf:
            case 0x17:
            case 0x1f:
              sVar17 = 5;
              break;
            case 0x20:
            case 0x21:
              sVar17 = 1;
              break;
            case 0x22:
            case 0x23:
              sVar17 = 4;
              break;
            case 0x2c:
            case 0x2d:
              sVar17 = 3;
              break;
            case 0x2e:
            case 0x2f:
              sVar17 = 6;
            }
            if (sVar17 != -1) {
              *(int *)(param_1 + 0x14c) = (int)sVar17;
            }
            *(undefined4 *)(param_1 + 0xc0) =
                 *(undefined4 *)(iVar20 + *(int *)(param_1 + 0x14c) * 4 + 4);
            *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0xc0) =
                 *(undefined4 *)(iVar20 + *(int *)(param_1 + 0x14c) * 4 + 0x20);
            if (sVar17 != -1) {
              *(int *)(*(int *)(param_1 + 0x1d8) + 0x14c) = (int)sVar17;
            }
            *(short *)(*(int *)(param_1 + 0x1d8) + 0x46) =
                 *(short *)(*(int *)(param_1 + 0x1d8) + 0x46) +
                 (short)(*(int *)(param_1 + 0x24) >> 9);
            while (psVar21 = (short *)(*(int *)(param_1 + 0x1d8) + 0x46),
                  0x17 < *(short *)(*(int *)(param_1 + 0x1d8) + 0x46)) {
              *psVar21 = *psVar21 + -0x18;
            }
            while( true ) {
              iVar15 = *(int *)(param_1 + 0x1d8);
              if (-1 < *(short *)(iVar15 + 0x46)) break;
              *(short *)(iVar15 + 0x46) = *(short *)(iVar15 + 0x46) + 0x18;
            }
            *(undefined4 *)(iVar15 + 0xc0) =
                 *(undefined4 *)
                  (_DAT_100a0a60 +
                   (*(int *)(iVar15 + 0x14c) + ((int)*(short *)(iVar15 + 0x46) >> 3) * 7) * 4 + 4);
          }
          goto LAB_1006f948;
        }
      }
    }
    else {
      if (iVar19 == 0xc08) {
        *(undefined4 *)(param_1 + 0x5c) = 0;
        *(undefined4 *)(param_1 + 0xc0) = 0;
        *(undefined4 *)(param_1 + 0x1f8) = 0;
        *(undefined2 *)(param_1 + 0x110) = 0;
        *(undefined1 *)(param_1 + 0x185) = 1;
        goto LAB_1006f948;
      }
      if (iVar19 < 0xc08) {
        if (iVar19 == 0xbfe) {
          bVar25 = true;
          uStack_68 = (double)CONCAT44(0x43300000,
                                       ((int)*(short *)(param_1 + 0x3a) -
                                       (int)*(short *)(param_1 + 0x36)) * 0x100 ^ 0x80000000);
          iVar15 = (int)((uStack_68 - _DAT_100a1af0) * dRam100a1ac8);
          uStack_60 = (double)(longlong)iVar15;
          if ((*(char *)(param_1 + 0xcd) == '\0') && (*(char *)(param_1 + 0xce) == '\0')) {
            bVar25 = false;
          }
          if (bVar25) {
            uVar16 = 0;
          }
          else {
            uVar16 = *(undefined4 *)(param_1 + 0x2c);
          }
          iVar14 = .debug::_PEDistance(*(undefined4 *)(param_1 + 0x24),uVar16);
          sVar17 = (short)((iVar14 * 0x168) / iVar15);
          if (*(int *)(param_1 + 0x24) < 1) {
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + sVar17;
          }
          else {
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) - sVar17;
          }
          iVar15 = *(int *)(param_1 + 0x24);
          if (iVar15 < 1) {
            iVar15 = -iVar15;
          }
          *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + (iVar15 >> 5);
          if (*(int *)(param_1 + 0x150) < *(int *)(param_1 + 0x14c)) {
            *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x150);
          }
          while (*(short *)(param_1 + 0x46) < 0) {
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 0x168;
          }
          while (0x167 < *(short *)(param_1 + 0x46)) {
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -0x168;
          }
          *(short *)(param_1 + 0x1aa) = *(short *)(param_1 + 0x46);
          uVar13 = (uint)(short)(*(int *)(param_1 + 0x14c) >> 9);
          uStack_68 = (double)CONCAT44(0x43300000,uVar13 ^ 0x80000000);
          iVar15 = (int)(dRam100a1ae8 * (uStack_68 - _DAT_100a1af0));
          uStack_60 = (double)(longlong)iVar15;
          sVar17 = (short)iVar15;
          iVar15 = (int)(short)(0x40 - sVar17);
          dVar27 = _DAT_100a1af0;
          .glue::SetRect(param_1 + 0x34,iVar15,iVar15,sVar17 + 0x40,uVar13 + 0x37);
          *(short *)(param_1 + 0x1ae) = (short)(*(int *)(param_1 + 0x14c) >> 7);
          if (*(short *)(param_1 + 0x1ae) < 0x81) {
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0a8c + 4);
            *(short *)(param_1 + 0x1ae) = *(short *)(param_1 + 0x1ae) << 1;
          }
          else if (*(short *)(param_1 + 0x1ae) < 0xc1) {
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0a88 + 4);
            uStack_68 = (double)CONCAT44(0x43300000,(int)*(short *)(param_1 + 0x1ae) ^ 0x80000000);
            iVar15 = (int)((uStack_68 - dVar27) * dRam100a1ac0);
            uStack_60 = (double)(longlong)iVar15;
            *(short *)(param_1 + 0x1ae) = (short)iVar15;
          }
          else {
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0a84 + 4);
          }
          *(undefined1 *)(param_1 + 0x88) = 0;
          *(undefined1 *)(param_1 + 0x89) = 1;
          goto LAB_1006f948;
        }
        if (((iVar19 < 0xbfe) && (iVar19 < 0xb7e)) && (0xb7b < iVar19)) {
          *(undefined1 *)(param_1 + 0x183) = 0;
          sVar17 = *(short *)(*(int *)*puVar7 + *(short *)(param_1 + 0x48) * 0x10 + 8);
          iVar15 = (int)sVar17;
          if (sVar17 < 0) {
            if (iVar15 == -1) {
              unaff_r19 = (uint)(*_DAT_1009fed0 == '\x01');
            }
            else if (iVar15 == -2) {
              unaff_r19 = (uint)(uRam100a5110 < 0xffffffed) -
                          ((int)~(uRam100a5110 ^ 0xffffffec) >> 0x1f) & 1;
            }
          }
          else {
            unaff_r19 = (uint)(*(short *)(*(int *)*puVar7 + iVar15 * 0x10 + 0xe) == 1);
          }
          if ((*(short *)(param_1 + 4) == 0xb7d) && (unaff_r19 = 0, *(short *)(param_1 + 0xa4) < 1))
          {
            .debug::_ExplodeFaceIntoParticles
                      (*(undefined4 *)(param_1 + 0xc0),*(undefined4 *)(param_1 + 10),2,2,2,0x32,100)
            ;
            *(undefined1 *)(param_1 + 0xe9) = 1;
            sVar17 = .debug::_FastRand(5000);
            .debug::_STPlay3DSoundPitched
                      (*_DAT_100a01e0,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar17 + 43000);
          }
          if ((unaff_r19 & 0xff) == 0) {
            if (0 < *(int *)(param_1 + 0x158) - (int)*(short *)(param_1 + 10)) {
              *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + 0x200;
              *(short *)(param_1 + 10) = (short)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
              if ((*(short *)(param_1 + 10) != *(short *)(param_1 + 0xc4)) &&
                 (sVar17 = FUN_100916dc(*puVar9), sVar17 == 0)) {
                .debug::_STPlay3DSoundRand(*puVar9,1,0x100,*(undefined4 *)(param_1 + 0xe));
              }
            }
          }
          else if (*(int *)(param_1 + 0x158) - (int)*(short *)(param_1 + 10) < 100) {
            *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + -0x200;
            *(short *)(param_1 + 10) = (short)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
            if ((*(short *)(param_1 + 10) != *(short *)(param_1 + 0xc4)) &&
               (sVar17 = FUN_100916dc(*puVar9), sVar17 == 0)) {
              .debug::_STPlay3DSoundRand(*puVar9,1,0x100,*(undefined4 *)(param_1 + 0xe));
            }
          }
          *(short *)(param_1 + 0x1bc) =
               ((short)*(undefined4 *)(param_1 + 0x158) - *(short *)(param_1 + 10)) + 7;
          if (*(short *)(*(int *)*puVar7 + *(short *)(param_1 + 0x48) * 0x10 + 10) != 0) {
            *(short *)(param_1 + 0x1bc) = *(short *)(param_1 + 0x1bc) + 0x20;
          }
          goto LAB_1006f948;
        }
      }
      else if (iVar19 < 0xc12) {
        if (iVar19 < 0xc0a) {
          *(undefined4 *)(param_1 + 0x5c) = 0;
          *(undefined4 *)(param_1 + 0xc0) = 0;
          *(undefined4 *)(param_1 + 0x1f8) = 0;
          *(undefined2 *)(param_1 + 0x110) = 0;
          *(undefined1 *)(param_1 + 0x185) = 0;
          goto LAB_1006f948;
        }
      }
      else if (iVar19 < 0xc15) {
        .debug::_MTChangeSpriteLayer
                  (param_1,(int)(short)-(*(short *)(param_1 + 10) * 2 + *(short *)(param_1 + 0xc)));
        if (*(short *)(param_1 + 0xa4) < 1) {
          .debug::_KillCrate(param_1);
        }
        goto LAB_1006f948;
      }
    }
  }
  if ((0x4e1 < iVar19) && (iVar19 < 0x500)) {
    sVar17 = *(short *)(param_1 + 0x48);
    bVar25 = false;
    if ((-1 < sVar17) && (sVar17 < 0x1ff)) {
      bVar25 = true;
    }
    if (bVar25) {
      iVar15 = *(int *)*puVar7 + sVar17 * 0x10;
      if (*(short *)(iVar15 + 8) == 2) {
        if (*(short *)(*(int *)*puVar7 + *(short *)(iVar15 + 10) * 0x10 + 0xe) == 1) {
          .glue::SetRect(param_1 + 0x34,1,1,0x23,0x23);
          piVar5 = _DAT_100a0a54;
          *(undefined1 *)(param_1 + 0x88) = 1;
          *(int *)(param_1 + 0xc0) = *piVar5 + (*(short *)(param_1 + 4) + -0x4e2) * 0x34;
        }
        else {
          .glue::SetRect(param_1 + 0x34,0,0,0,0);
          puVar9 = _DAT_100a0a50;
          *(undefined1 *)(param_1 + 0x88) = 0;
          *(undefined4 *)(param_1 + 0xc0) = *puVar9;
        }
      }
    }
    if (*(short *)(param_1 + 0xa4) < 1) {
      .debug::_KillBox(param_1);
    }
  }
  iVar15 = (int)*(short *)(param_1 + 4);
  if ((iVar15 < 0xaf5) || (0xb21 < iVar15)) {
    if ((iVar15 < 0xb22) || (0xb35 < iVar15)) {
      if ((iVar15 < 0xb36) || (0xb49 < iVar15)) {
        if ((iVar15 < 0xb68) || (0xb70 < iVar15)) {
          if ((0xb86 < iVar15) && (iVar15 < 0xb9a)) {
            if ((iVar15 == 0xb8d) &&
               (*(short *)(*(int *)*puVar7 + *(short *)(param_1 + 0x48) * 0x10 + 0xc) != 0)) {
              *(undefined1 *)(param_1 + 0x17e) = 1;
            }
            *(undefined4 *)(param_1 + 0xc0) =
                 *(undefined4 *)(_DAT_100a0a6c + *(short *)(param_1 + 4) * 0x10 + -0xb85c);
            *(undefined2 *)(param_1 + 0x46) = 0;
            *(undefined2 *)(param_1 + 0x110) = 0;
            *(undefined4 *)(param_1 + 0x80) = 0;
            uVar16 = *(undefined4 *)(*(int *)(param_1 + 0xc0) + 0xc);
            *(undefined4 *)(param_1 + 0x34) = *(undefined4 *)(*(int *)(param_1 + 0xc0) + 8);
            *(undefined4 *)(param_1 + 0x38) = uVar16;
            *(undefined1 *)(param_1 + 0x185) = 1;
          }
        }
        else {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0a04 + iVar15 * 0x10 + -0xb67c)
          ;
        }
      }
      else {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0a08 + iVar15 * 0x10 + -0xb35c);
      }
    }
    else {
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0a0c + iVar15 * 0x10 + -0xb21c);
    }
  }
  else {
    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar15 * 0x10 + 0x1009b500);
  }
LAB_1006f948:
  .debug::_ApplyFriction(param_1,(int)*(short *)(param_1 + 0x114));
  if (((*(short *)(param_1 + 4) != 0x438) && (*(short *)(param_1 + 4) != 0x439)) &&
     (*(char *)(param_1 + 0xcd) != '\0')) {
    .debug::_FootPressure(param_1);
  }
  .debug::_EnforceMaxSpeed(param_1,0x1838);
  *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + *(int *)(param_1 + 0x2c);
  *(undefined1 *)(param_1 + 0xcd) = *(undefined1 *)(param_1 + 0xce);
  if (((*(short *)(param_1 + 0x110) != 0) || (*(short *)(param_1 + 4) == 0x438)) ||
     (*(short *)(param_1 + 4) == 0x439)) {
    .debug::_ApplyGravityAndSeparateFromTiles(param_1);
  }
  if ((*(short *)(param_1 + 4) == 0xb72) && (*(short *)(param_1 + 0x48) != -1)) {
    *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 10) = *(undefined4 *)(param_1 + 10);
    *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0x11c) = *(undefined4 *)(param_1 + 0x11c);
    *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0x128) = *(undefined2 *)(param_1 + 0x128);
    *(undefined4 *)(*(int *)(param_1 + 0x1d8) + 10) = *(undefined4 *)(param_1 + 10);
    *(short *)(*(int *)(param_1 + 0x1d8) + 10) = *(short *)(*(int *)(param_1 + 0x1d8) + 10) + 0x26;
    *(undefined4 *)(*(int *)(param_1 + 0x1d8) + 0x11c) = *(undefined4 *)(param_1 + 0x11c);
    *(undefined2 *)(*(int *)(param_1 + 0x1d8) + 0x128) = *(undefined2 *)(param_1 + 0x128);
  }
  if (*(short *)(param_1 + 4) != 0) {
    .debug::_BoxCleanUp(param_1);
  }
  return;
}


// ==== .HitBoxSprite @ 10070024 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitBoxSprite(int param_1,int param_2)

{
  char cVar1;
  short sVar2;
  bool bVar3;
  bool bVar4;
  int iVar5;
  int iVar6;
  ushort uVar8;
  short sVar9;
  int iVar7;
  undefined *puVar10;
  int iVar11;
  undefined *puVar12;
  short sStack_16;
  short sStack_14;
  
  puVar12 = PTR_PTR_100a01f0;
  sVar9 = *(short *)(param_1 + 4);
  if ((((sVar9 < 0xb87) || (2999 < sVar9)) && ((sVar9 < 0x4e2 || (0x4ff < sVar9)))) &&
     ((((sVar9 != 0x5a0 && (sVar9 != 0x5a5)) && (sVar9 != 0x5a9)) ||
      (((sVar2 = *(short *)(param_2 + 4), sVar2 != 0x5a0 && (sVar2 != 0x5a5)) && (sVar2 != 0x5a9))))
     )) {
    if ((sVar9 == 0xb5e) || (sVar9 == 0xb5f)) {
      puVar12 = *(undefined **)(param_2 + 0x4c);
      if ((puVar12 != PTR_PTR_100a047c) &&
         (((puVar12 != PTR_PTR_100a04e8 && (puVar12 != PTR_PTR_100a0488)) &&
          (puVar12 != PTR_PTR_100a04f8)))) {
        *(undefined4 *)(param_1 + 0xa0) = 0;
      }
    }
    else {
      puVar10 = *(undefined **)(param_2 + 0x4c);
      if ((puVar10 == PTR_PTR_100a04e8) && (*(short *)(param_2 + 0xa6) == 0)) {
        if ((0xc11 < sVar9) && (sVar9 < 0xc1c)) {
          *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) - *(short *)(param_2 + 0xa4);
          if ((*(short *)(param_1 + 0xa4) < 1) && (*(char *)(param_1 + 0xea) == '\0')) {
            .debug::_KillCrate(param_1);
          }
          .debug::_KillPlayerShot(param_2,1,0);
        }
        if (*(short *)(param_1 + 4) == 0xb74) {
          sVar9 = *(short *)(param_2 + 0xa4);
          iVar6 = (int)sVar9 / 0x14 + ((int)sVar9 >> 0x1f);
          uVar8 = (short)iVar6 - (short)(iVar6 >> 0x1f);
          *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) - sVar9;
          sVar9 = .debug::_FastRand((int)(short)(((short)uVar8 >> 1) +
                                                (ushort)((short)uVar8 < 0 && (uVar8 & 1) != 0)));
          *(ushort *)(param_1 + 0xa6) = uVar8 + sVar9;
        }
      }
      else if ((puVar10 == PTR_PTR_100a0460) && (*(short *)(param_2 + 4) == 0x4b7)) {
        if ((0xc11 < sVar9) && (sVar9 < 0xc1c)) {
          *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -10;
          if ((*(short *)(param_1 + 0xa4) < 1) && (*(char *)(param_1 + 0xea) == '\0')) {
            .debug::_KillCrate(param_1);
          }
          .debug::_KillPlayerShot(param_2,1,0);
        }
      }
      else if (((puVar10 == PTR_PTR_100a01f8) || (puVar10 == PTR_PTR_100a0484)) ||
              (puVar10 == _DAT_100a0200)) {
        if ((((sVar9 != 0x433) || (puVar10 != _DAT_100a0200)) ||
            (*(short *)(param_2 + 0xb0) != 0x34)) && (*(char *)(param_1 + 0x182) == '\0')) {
          bVar3 = false;
          bVar4 = false;
          sStack_14 = *(short *)(param_1 + 0x36) +
                      (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1
                             );
          sStack_16 = *(short *)(param_1 + 0x34) +
                      (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1
                             );
          iVar6 = *(int *)(param_2 + 0x24);
          if (iVar6 < 1) {
            iVar6 = -iVar6;
          }
          iVar7 = *(int *)(param_1 + 0x24);
          if (iVar7 < 1) {
            iVar7 = -iVar7;
          }
          iVar11 = *(int *)(param_2 + 0x2c);
          if (iVar11 < 1) {
            iVar11 = -iVar11;
          }
          iVar5 = *(int *)(param_1 + 0x2c);
          if (iVar5 < 1) {
            iVar5 = -iVar5;
          }
          sVar9 = *(short *)(param_1 + 4);
          if ((sVar9 == 0x5a0) || (sVar9 == 0x5a5)) {
            bVar3 = true;
          }
          sVar2 = *(short *)(param_2 + 4);
          if ((sVar2 == 0x5a0) || (sVar2 == 0x5a5)) {
            bVar4 = true;
          }
          if (sVar9 == 0x5a9) {
            bVar3 = true;
          }
          if (sVar2 == 0x5a9) {
            bVar4 = true;
          }
          cVar1 = *(char *)(param_1 + 0xce);
          if (((cVar1 != '\0') && (*(char *)(param_2 + 0xce) == '\0')) || (bVar3)) {
            .debug::_PlatformBounce(param_2,param_1,&sStack_16,0,param_1 + 0x34,0);
            if (!bVar3) {
              .debug::_PlatformBounce(param_1,param_2,&sStack_16,0,param_1 + 0x34,0);
            }
          }
          else if (((*(char *)(param_2 + 0xce) != '\0') && (cVar1 == '\0')) || (bVar4)) {
            .debug::_PlatformBounce(param_1,param_2,&sStack_16,0,param_1 + 0x34,0);
            if (!bVar4) {
              .debug::_PlatformBounce(param_2,param_1,&sStack_16,0,param_1 + 0x34,0);
            }
          }
          else if ((*(char *)(param_2 + 0xce) == '\0') && (cVar1 == '\0')) {
            if (*(short *)(param_1 + 10) < *(short *)(param_2 + 10)) {
              .debug::_PlatformBounce(param_1,param_2,&sStack_16,0,param_1 + 0x34,0);
              .debug::_PlatformBounce(param_2,param_1,&sStack_16,0,param_1 + 0x34,0);
            }
            else {
              .debug::_PlatformBounce(param_2,param_1,&sStack_16,0,param_1 + 0x34,0);
              .debug::_PlatformBounce(param_1,param_2,&sStack_16,0,param_1 + 0x34,0);
            }
          }
          else if ((short)(((short)iVar7 - (short)iVar6) + ((short)iVar5 - (short)iVar11)) < 0) {
            .debug::_PlatformBounce(param_1,param_2,&sStack_16,0,param_1 + 0x34,0);
            .debug::_PlatformBounce(param_2,param_1,&sStack_16,0,param_1 + 0x34,0);
          }
          else {
            .debug::_PlatformBounce(param_2,param_1,&sStack_16,0,param_1 + 0x34,0);
            .debug::_PlatformBounce(param_1,param_2,&sStack_16,0,param_1 + 0x34,0);
          }
          *(undefined1 *)(param_2 + 0x182) = 1;
          *(undefined1 *)(param_1 + 0x182) = 1;
        }
      }
      else if ((puVar10 == PTR_PTR_100a052c) && (sVar9 == 0x438)) {
        *(undefined2 *)(param_1 + 0x46) = 2;
        *(undefined2 *)(param_1 + 4) = 0x439;
        *(undefined **)(param_1 + 0x1f8) = puVar12;
        *(undefined4 *)(param_1 + 0x15c) = 0x1e;
        *(undefined1 *)(param_1 + 0x185) = 0;
      }
    }
  }
  return;
}


// ==== .HitBoxTileSprite @ 10070718 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitBoxTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  short sVar1;
  bool bVar2;
  undefined4 *puVar3;
  undefined4 *puVar4;
  int iVar5;
  char cVar7;
  short sVar6;
  int iVar8;
  int iVar9;
  undefined4 uVar10;
  short sStack_38;
  short sStack_36;
  
  puVar4 = _DAT_100a041c;
  puVar3 = _DAT_100a03ac;
  sVar6 = 0;
  uVar10 = 0;
  sStack_36 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_38 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  if ((*_DAT_100a0064 == '\0') || (cVar7 = .debug::_IsPressed(0x32), cVar7 == '\0')) {
    iVar8 = (int)*(short *)(param_1 + 4);
    if ((0x42d < iVar8) && (iVar8 < 0x438)) {
      iVar5 = *(int *)(param_1 + 0x2c);
      if (iVar5 < 1) {
        iVar5 = -iVar5;
      }
      if (0x1ff < iVar5) {
        sVar6 = 1;
        uVar10 = 0x3c;
      }
    }
    if (param_4 == 1) {
      iVar9 = *(int *)(param_1 + 0x2c);
      bVar2 = false;
      iVar5 = iVar9;
      if (iVar9 < 1) {
        iVar5 = -iVar9;
      }
      if ((0x300 < iVar5) && (*(char *)(param_1 + 0xcd) == '\0')) {
        bVar2 = true;
      }
      if ((iVar8 - 0xc12U & 0xffff) < 3) {
        uVar10 = 0x60;
        sVar6 = 0x60;
      }
      if ((0x4b0 < iVar9) &&
         (*(short *)(*(int *)*_DAT_100a0058 + *(short *)(param_1 + 0x48) * 0x10 + 8) == 2)) {
        .debug::_KillCrate(param_1);
      }
      sVar1 = *(short *)(param_1 + 4);
      if (sVar1 == 0x5c3) {
        uVar10 = 0x40;
        sVar6 = 0x40;
      }
      if ((sVar1 != 0x5c4) || (0 < *(int *)(param_1 + 0x14c))) {
        if (sVar1 == 0x5c4) {
          uVar10 = 0x40;
          sVar6 = 0x40;
        }
        cVar7 = .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_38,uVar10,
                                    param_1 + 0x34,0,sVar6);
        if (cVar7 != '\0') {
          if (((0x42d < *(short *)(param_1 + 4)) && (*(short *)(param_1 + 4) < 0x438)) &&
             (sVar6 != 0)) {
            if (bVar2) {
              sVar6 = .debug::_FastRand(10000);
              .debug::_STPlay3DSoundPitched
                        (*puVar3,1,0x55,*(undefined4 *)(param_1 + 0xe),sVar6 + 48000);
            }
            if ((*(short *)(param_1 + 4) == 0x433) || (*(short *)(param_1 + 4) == 0x434)) {
              .debug::_KillBox(param_1);
            }
          }
          if (((*(short *)(param_1 + 4) == 0x5c4) || ((*(short *)(param_1 + 4) == 0x5c3 && (bVar2)))
              ) && (*(short *)(param_1 + 0xa6) < 1)) {
            sVar6 = .debug::_FastRand(10000);
            .debug::_STPlay3DSoundPitched
                      (*puVar4,1,0xab,*(undefined4 *)(param_1 + 0xe),sVar6 + 48000);
            *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + -1;
          }
        }
        iVar8 = *(int *)(param_1 + 0x2c);
        if (iVar8 < 1) {
          iVar8 = -iVar8;
        }
        if (iVar8 < 0x100) {
          *(undefined4 *)(param_1 + 0x2c) = 0;
        }
        if ((*(char *)(param_1 + 0xce) != '\0') && (*(short *)(param_1 + 4) == 0x2c9)) {
          *(undefined2 *)(param_1 + 4) = 0x2c8;
          *(undefined2 *)(param_1 + 0x110) = 0;
        }
      }
    }
    else if ((short)param_3 < 100) {
      iVar5 = *(int *)(param_1 + 0x2c);
      bVar2 = false;
      if (iVar5 < 1) {
        iVar5 = -iVar5;
      }
      if ((0x300 < iVar5) && (*(char *)(param_1 + 0xcd) == '\0')) {
        bVar2 = true;
      }
      if (iVar8 == 0x5c3) {
        uVar10 = 0x40;
        sVar6 = 0x40;
      }
      if ((iVar8 != 0x5c4) || (0 < *(int *)(param_1 + 0x14c))) {
        if (iVar8 == 0x5c4) {
          uVar10 = 0x40;
          sVar6 = 0x40;
        }
        cVar7 = .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_38,uVar10,
                                    param_1 + 0x34,0,sVar6);
        if ((cVar7 != '\0') &&
           (((*(short *)(param_1 + 4) == 0x5c4 || ((*(short *)(param_1 + 4) == 0x5c3 && (bVar2))))
            && (*(short *)(param_1 + 0xa6) < 1)))) {
          sVar6 = .debug::_FastRand(10000);
          .debug::_STPlay3DSoundPitched(*puVar4,1,0xab,*(undefined4 *)(param_1 + 0xe),sVar6 + 48000)
          ;
          *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + -1;
        }
      }
    }
    else if ((short)param_3 < 200) {
      iVar5 = *(int *)(param_1 + 0x2c);
      bVar2 = false;
      if (iVar5 < 1) {
        iVar5 = -iVar5;
      }
      if ((0x300 < iVar5) && (*(char *)(param_1 + 0xcd) == '\0')) {
        bVar2 = true;
      }
      if (((((iVar8 != 0x434) && (iVar8 != 0x5c3)) && (iVar8 != 0x5c4)) &&
          ((cVar7 = .debug::_WallBounceBG
                              (param_1,param_3 + -100,&stack0x0000001c,&sStack_38,uVar10,
                               param_1 + 0x34,0,sVar6), cVar7 != '\0' &&
           (0x42d < *(short *)(param_1 + 4))))) &&
         ((*(short *)(param_1 + 4) < 0x438 && ((sVar6 != 0 && (bVar2)))))) {
        sVar6 = .debug::_FastRand(10000);
        .debug::_STPlay3DSoundPitched(*puVar3,1,0x55,*(undefined4 *)(param_1 + 0xe),sVar6 + 48000);
      }
    }
    else {
      cVar7 = .debug::_IsWaterTile(param_3);
      if ((cVar7 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
        .debug::_HandleUnderWater(param_1,param_2);
      }
    }
  }
  return;
}


// ==== .SetupButtonSprite @ 10070d30 ====

void _SetupButtonSprite(int param_1)

{
  short sVar1;
  undefined *puVar2;
  undefined *puVar3;
  
  .debug::_InitSprite();
  puVar3 = PTR_PTR_100a0ac4;
  *(undefined2 *)(param_1 + 0x46) = 0;
  puVar2 = PTR_PTR_100a0ac0;
  *(undefined **)(param_1 + 0x4c) = puVar3;
  *(undefined **)(param_1 + 0x5c) = puVar2;
  *(undefined4 *)(param_1 + 0x1f8) = 0;
  *(undefined4 *)(param_1 + 0x80) = 1;
  *(undefined2 *)(param_1 + 0x46) = 0;
  sVar1 = *(short *)(param_1 + 4);
  if (sVar1 == 0x529) {
    .glue::SetRect(param_1 + 0x34,0xfffffffc,0,0x10,0xc);
  }
  else if (sVar1 < 0x529) {
    if (0x527 < sVar1) {
      .glue::SetRect(param_1 + 0x34,0,0xffffffec,0x14,0xc);
    }
  }
  else if (sVar1 < 0x52b) {
    .glue::SetRect(param_1 + 0x34,8,4,0x18,0x14);
  }
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
  *(undefined1 *)(param_1 + 0xe4) = 0;
  return;
}


// ==== .HandleButtonSprite @ 10070e60 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleButtonSprite(int param_1)

{
  short sVar1;
  undefined4 *puVar2;
  int iVar3;
  int iVar4;
  
  puVar2 = _DAT_100a0058;
  .debug::_StandardSpriteHandles();
  if ((*(char *)(param_1 + 0xe4) == '\0') &&
     (*(undefined1 *)(param_1 + 0xe4) = 1,
     *(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 0xe) != 0)) {
    *(undefined2 *)(param_1 + 0x46) = 10;
  }
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b2) == '\0')) {
    if ((*(short *)(param_1 + 0x46) < 9) ||
       (*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 8) != 1)) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1;
    }
    if (*(short *)(param_1 + 0x46) < 0) {
      *(undefined2 *)(param_1 + 0x46) = 0;
    }
    else if (0xb < *(short *)(param_1 + 0x46)) {
      *(undefined2 *)(param_1 + 0x46) = 0xb;
    }
    if (((int)*(short *)(param_1 + 0x46) < *(int *)(param_1 + 0xa0)) &&
       (*(int *)(param_1 + 0xa0) == 5)) {
      .debug::_STPlay3DSound(*_DAT_100a0260,10,0x100,*(undefined4 *)(param_1 + 0xe));
    }
    sVar1 = *(short *)(param_1 + 4);
    if (sVar1 == 0x529) {
      *(int *)(param_1 + 0xc0) = *_DAT_100a0acc + ((int)*(short *)(param_1 + 0x46) >> 1) * 0x34;
    }
    else if (sVar1 < 0x529) {
      if (0x527 < sVar1) {
        *(int *)(param_1 + 0xc0) = *_DAT_100a0ad0 + ((int)*(short *)(param_1 + 0x46) >> 1) * 0x34;
      }
    }
    else if (sVar1 < 0x52b) {
      if (9 < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 9;
      }
      iVar3 = *(short *)(param_1 + 0x46) + -2;
      iVar4 = iVar3;
      if (6 < iVar3) {
        iVar4 = 7;
      }
      if (iVar4 < 0) {
        iVar3 = 0;
      }
      else if (6 < iVar3) {
        iVar3 = 7;
      }
      *(int *)(param_1 + 0xc0) = *_DAT_100a0ac8 + iVar3 * 0x34;
    }
    iVar4 = (int)*(short *)(param_1 + 0x48);
    if ((-1 < *(short *)(param_1 + 0x48)) && (iVar4 < 0x200)) {
      if (*(short *)(param_1 + 0x46) < 9) {
        *(undefined2 *)(*(int *)*puVar2 + iVar4 * 0x10 + 0xe) = 0;
      }
      else {
        *(undefined2 *)(*(int *)*puVar2 + iVar4 * 0x10 + 0xe) = 1;
      }
    }
    .debug::_StandardSpriteCleanup(param_1);
    *(int *)(param_1 + 0xa0) = (int)*(short *)(param_1 + 0x46);
  }
  return;
}


// ==== .HitButtonSprite @ 100710e4 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitButtonSprite(int param_1,int param_2)

{
  undefined *puVar1;
  
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_2 + 0xe9) == '\0')) {
    puVar1 = *(undefined **)(param_2 + 0x4c);
    if ((puVar1 == PTR_PTR_100a052c) ||
       (((puVar1 == _DAT_100a0200 || (puVar1 == PTR_PTR_100a0484)) || (puVar1 == PTR_PTR_100a01f8)))
       ) {
      if (*(short *)(param_1 + 0x46) == 0) {
        .debug::_STPlay3DSound(*_DAT_100a0264,10,0x100,*(undefined4 *)(param_1 + 0xe));
      }
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 8;
    }
    else if ((puVar1 == PTR_PTR_100a0488) || (puVar1 == PTR_PTR_100a04e8)) {
      .debug::_STPlay3DSound(*_DAT_100a0264,10,0x100,*(undefined4 *)(param_1 + 0xe));
      *(undefined2 *)(param_1 + 0x46) = 0xb;
    }
  }
  return;
}


// ==== .SetupBackgroundSprite @ 10071710 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupBackgroundSprite(int param_1)

{
  short *psVar1;
  ushort uVar2;
  undefined4 *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  undefined *puVar6;
  int iVar7;
  int iVar8;
  int iVar9;
  int iVar10;
  int iVar11;
  int iVar12;
  int iVar13;
  int iVar14;
  int iVar15;
  int iVar16;
  int iVar17;
  undefined2 uVar18;
  int iVar19;
  char cVar22;
  int iVar20;
  short sVar21;
  int iVar23;
  undefined4 uVar24;
  
  iVar17 = _DAT_100a0b3c;
  iVar16 = _DAT_100a0b38;
  iVar15 = _DAT_100a0b34;
  iVar13 = _DAT_100a0b20;
  iVar12 = _DAT_100a0b1c;
  iVar11 = _DAT_100a0b18;
  iVar10 = _DAT_100a0b14;
  iVar9 = _DAT_100a0b00;
  iVar8 = _DAT_100a0af8;
  iVar20 = _DAT_100a0adc;
  iVar23 = _DAT_100a0ad8;
  uVar24 = uRam100a0ad4;
  puVar6 = PTR_DAT_100a09f4;
  puVar5 = PTR_PTR_100a0958;
  puVar3 = _DAT_100a0058;
  .debug::_InitSprite();
  puVar4 = PTR_PTR_100a0480;
  *(undefined2 *)(param_1 + 0x84) = 0;
  *(undefined2 *)(param_1 + 0x86) = 0;
  *(undefined4 *)(param_1 + 0x80) = 1;
  *(undefined **)(param_1 + 0x4c) = puVar4;
  *(undefined4 *)(param_1 + 0x5c) = 0;
  *(undefined4 *)(param_1 + 0x1f8) = 0;
  *(undefined2 *)(param_1 + 0xa6) = 3;
  *(undefined2 *)(param_1 + 0xa4) = 6;
  *(undefined1 *)(param_1 + 0x8a) = 0;
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  iVar14 = _DAT_100a0b2c;
  iVar7 = _DAT_100a0ae0;
  iVar19 = (int)*(short *)(param_1 + 4);
  if (iVar19 == 0x731) {
    *(undefined1 *)(param_1 + 0x188) = 1;
    *(undefined1 *)(iVar15 + 1) = 1;
    *(undefined1 *)(param_1 + 0x17e) = 1;
    *(int *)(param_1 + 0x14c) =
         (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 8);
    *(int *)(param_1 + 0x150) =
         (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 10);
    if (*(int *)(param_1 + 0x150) == 0) {
      *(undefined4 *)(param_1 + 0x150) = 32000;
    }
    *(int *)(param_1 + 0x154) =
         (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xc);
    *(undefined2 *)(param_1 + 0xa6) =
         *(undefined2 *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xe);
    if ((int)*(short *)(param_1 + 0xa6) < *(int *)(param_1 + 0x150)) {
      *(undefined2 *)(param_1 + 0x46) = 0;
    }
    else {
      *(undefined2 *)(param_1 + 0x46) = 0xb;
    }
    *(undefined2 *)(param_1 + 0xa4) = 500;
    if (*(char *)(*(int *)*puVar3 + 0x26cd) != '\0') {
      *(undefined4 *)(param_1 + 0xb8) = 0x10018;
    }
    .debug::_GetBGTile((int)(*(short *)(param_1 + 0xc) >> 5),
                       (int)(short)(*(short *)(param_1 + 10) + 0xc >> 5));
    .debug::_LookupBGTileKind();
    cVar22 = .debug::_IsWaterTile();
    if (cVar22 != '\0') {
      *(undefined4 *)(param_1 + 0xb8) = 0x90000;
    }
    goto LAB_10072efc;
  }
  if (iVar19 < 0x731) {
    if (iVar19 == 0x4b8) {
      *(undefined1 *)(_DAT_100a0afc + 1) = 1;
      *(undefined1 *)(iVar8 + 1) = 1;
      *(undefined4 *)(param_1 + 0x5c) = 0;
      .glue::SetRect(param_1 + 0x34,7,0x24,0x59,0x48);
      *(undefined2 *)(param_1 + 0x46) = 0;
      *(undefined1 *)(param_1 + 0x88) = 0;
      *(undefined2 *)(param_1 + 0xa4) = 0xe0;
      *(undefined4 *)(param_1 + 0x80) = 0xffff8300;
      *(int *)(param_1 + 0x14c) =
           (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 8);
      iVar23 = *(int *)(param_1 + 0x14c);
      if (iVar23 == 3) {
        *(undefined4 *)(param_1 + 0xb8) = 0x1000f;
      }
      else if (iVar23 < 3) {
        if (iVar23 == 1) {
          *(undefined4 *)(param_1 + 0xb8) = 0x10004;
        }
        else if (0 < iVar23) {
          *(undefined4 *)(param_1 + 0xb8) = 0x1000b;
        }
      }
      else if (iVar23 < 5) {
        *(undefined4 *)(param_1 + 0xb8) = 0x10017;
      }
      goto LAB_10072efc;
    }
    if (iVar19 < 0x4b8) {
      if (iVar19 == 0x47f) {
        *(undefined1 *)(_DAT_100a0b04 + 1) = 1;
        *(undefined4 *)(param_1 + 0x5c) = uVar24;
        *(undefined2 *)(param_1 + 0x1ba) = 32000;
        .glue::SetRect(param_1 + 0x34,4,0,0x38,0x32);
        if (*(char *)(*(int *)*puVar3 + 0x26cd) != '\0') {
          *(undefined4 *)(param_1 + 0xb8) = 0x10018;
        }
        goto LAB_10072efc;
      }
      if (iVar19 < 0x47f) {
        if (iVar19 < 1099) {
          if (0x441 < iVar19) {
            sVar21 = *(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 8);
            iVar23 = (int)sVar21;
            *(undefined1 *)(_DAT_100a0b10 + 1) = 1;
            *(short *)(param_1 + 0x46) = (*(short *)(param_1 + 4) + -0x442) * 4;
            *(undefined4 *)(param_1 + 0x80) = 1000;
            *(int *)(param_1 + 0x14c) = (int)*(short *)(param_1 + 0xc);
            *(int *)(param_1 + 0x150) = (int)*(short *)(param_1 + 10);
            *(undefined4 *)(param_1 + 0x154) = 0;
            if (sVar21 < 1) {
              *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
              *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
              if (sVar21 != 0) {
                *(undefined1 *)(param_1 + 0x188) = 1;
                .debug::_SetupProgrammedPath(param_1,0xffffffff,0);
              }
              iVar20 = iVar23;
              if (sVar21 < 1) {
                iVar20 = -iVar23;
              }
              if (iVar20 == 1) {
                iVar23 = *(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10;
                if (*(short *)(iVar23 + 0xe) == *(short *)(iVar23 + 10)) {
                  *(int *)(param_1 + 0xf8) = -*(int *)(param_1 + 0xf8);
                  *(int *)(param_1 + 0x24) = -*(int *)(param_1 + 0x24);
                  *(int *)(param_1 + 0x2c) = -*(int *)(param_1 + 0x2c);
                }
                *(int *)(param_1 + 0x1c) =
                     *(int *)(param_1 + 0x1c) +
                     *(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xe) * 0x100;
              }
              else {
                if (sVar21 < 1) {
                  iVar23 = -iVar23;
                }
                if (iVar23 == 2) {
                  iVar23 = *(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10;
                  if (*(short *)(iVar23 + 0xe) == *(short *)(iVar23 + 10)) {
                    *(int *)(param_1 + 0xf8) = -*(int *)(param_1 + 0xf8);
                    *(int *)(param_1 + 0x24) = -*(int *)(param_1 + 0x24);
                    *(int *)(param_1 + 0x2c) = -*(int *)(param_1 + 0x2c);
                  }
                  *(int *)(param_1 + 0x14) =
                       *(int *)(param_1 + 0x14) +
                       *(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xe) * 0x100
                  ;
                }
              }
              uVar18 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
              *(undefined2 *)(param_1 + 0xc) = uVar18;
              *(undefined2 *)(param_1 + 8) = uVar18;
              uVar18 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
              *(undefined2 *)(param_1 + 10) = uVar18;
              *(undefined2 *)(param_1 + 6) = uVar18;
              *(short *)(param_1 + 0x46) = (*(short *)(param_1 + 4) + -0x442) * 4;
              if (sVar21 == 0) {
                *(undefined4 *)(param_1 + 0x164) = 9000;
              }
              else {
                *(undefined4 *)(param_1 + 0x164) = 0x1fa4;
              }
            }
            else {
              *(undefined4 *)(param_1 + 0x158) = 4;
              if ((iVar23 == 0x69) ||
                 ((iVar23 == 0x6a &&
                  (*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 10) == 0)))) {
                *(undefined2 *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 10) = 4;
              }
              *(undefined2 *)(param_1 + 0xa6) =
                   *(undefined2 *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 10);
              sVar21 = *(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xc);
              if (sVar21 == 0) {
                *(undefined4 *)(param_1 + 0x158) = 4;
              }
              else if (sVar21 == 1) {
                *(undefined4 *)(param_1 + 0x158) = 8;
              }
              else if (sVar21 == 2) {
                *(undefined4 *)(param_1 + 0x158) = 0x10;
              }
              if (iVar23 == 0x65) {
                *(undefined4 *)(param_1 + 0x15c) = 1;
              }
              else if (iVar23 == 0x66) {
                *(undefined4 *)(param_1 + 0x15c) = 0xffffffff;
              }
              else if (iVar23 == 0x67) {
                *(undefined4 *)(param_1 + 0x15c) = 2;
              }
              else if (iVar23 == 0x68) {
                *(undefined4 *)(param_1 + 0x15c) = 0xfffffffe;
              }
              else {
                *(undefined4 *)(param_1 + 0x15c) = 0;
              }
              iVar23 = *(int *)(param_1 + 0x15c);
              if (iVar23 != 0) {
                if (iVar23 < 1) {
                  iVar23 = -iVar23;
                }
                *(int *)(param_1 + 0x158) = *(int *)(param_1 + 0x158) / iVar23;
              }
              *(undefined4 *)(param_1 + 0x160) = *(undefined4 *)(param_1 + 0x158);
              *(int *)(param_1 + 0x164) =
                   (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xe);
              if (*(int *)(param_1 + 0x164) == 0) {
                *(undefined4 *)(param_1 + 0x164) = 9000;
              }
              if (*(int *)(param_1 + 0x164) == 1) {
                *(undefined4 *)(param_1 + 0x164) = 0x1c20;
              }
            }
            .glue::SetRect(param_1 + 0x34,0x35,0x38,0x61,0x5b);
            *(undefined4 *)(param_1 + 0x5c) = uVar24;
            .debug::_GetBGTile((int)(*(short *)(param_1 + 0xc) >> 5),
                               (int)(*(short *)(param_1 + 10) >> 5));
            .debug::_LookupBGTileKind();
            cVar22 = .debug::_IsWaterTile();
            if (cVar22 == '\0') {
              *(undefined4 *)(param_1 + 0x16c) = 0;
            }
            else {
              *(undefined4 *)(param_1 + 0x16c) = 1;
            }
            goto LAB_10072efc;
          }
        }
        else if (0x47d < iVar19) {
          *(undefined1 *)(_DAT_100a0b08 + 1) = 1;
          *(undefined4 *)(param_1 + 0x5c) = uVar24;
          *(undefined2 *)(param_1 + 0x1ba) = 32000;
          .glue::SetRect(param_1 + 0x34,4,10,0x38,0x3c);
          if (*(char *)(*(int *)*puVar3 + 0x26cd) != '\0') {
            *(undefined4 *)(param_1 + 0xb8) = 0x10018;
          }
          goto LAB_10072efc;
        }
      }
      else {
        if (iVar19 == 0x481) {
          *(undefined1 *)(iVar9 + 1) = 1;
          *(undefined4 *)(param_1 + 0x5c) = uVar24;
          *(undefined2 *)(param_1 + 0x1ba) = 32000;
          .glue::SetRect(param_1 + 0x34,10,4,0x3c,0x2e);
          if (*(char *)(*(int *)*puVar3 + 0x26cd) != '\0') {
            *(undefined4 *)(param_1 + 0xb8) = 0x10018;
          }
          goto LAB_10072efc;
        }
        if (iVar19 < 0x481) {
          *(undefined1 *)(iVar9 + 1) = 1;
          *(undefined4 *)(param_1 + 0x5c) = uVar24;
          *(undefined2 *)(param_1 + 0x1ba) = 32000;
          .glue::SetRect(param_1 + 0x34,0,4,0x32,0x2e);
          if (*(char *)(*(int *)*puVar3 + 0x26cd) != '\0') {
            *(undefined4 *)(param_1 + 0xb8) = 0x10018;
          }
          goto LAB_10072efc;
        }
      }
    }
    else if (iVar19 < 0x5c8) {
      if (iVar19 == 0x4bd) {
        *(undefined1 *)(_DAT_100a0af0 + 1) = 1;
        *(undefined1 *)(iVar8 + 1) = 1;
        *(undefined4 *)(param_1 + 0x5c) = 0;
        .glue::SetRect(param_1 + 0x34,4,0,0x5c,0x20);
        *(undefined2 *)(param_1 + 0x46) = 0;
        *(undefined1 *)(param_1 + 0x88) = 0;
        *(undefined2 *)(param_1 + 0xa4) = 0xe0;
        *(undefined4 *)(param_1 + 0x80) = 32000;
        *(int *)(param_1 + 0x14c) =
             (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 8);
        iVar23 = *(int *)(param_1 + 0x14c);
        if (iVar23 == 3) {
          *(undefined4 *)(param_1 + 0xb8) = 0x1000f;
        }
        else if (iVar23 < 3) {
          if (iVar23 == 1) {
            *(undefined4 *)(param_1 + 0xb8) = 0x10004;
          }
          else if (0 < iVar23) {
            *(undefined4 *)(param_1 + 0xb8) = 0x1000b;
          }
        }
        else if (iVar23 < 5) {
          *(undefined4 *)(param_1 + 0xb8) = 0x10017;
        }
        goto LAB_10072efc;
      }
      if ((iVar19 < 0x4bd) && (0x4ba < iVar19)) {
        *(undefined1 *)(_DAT_100a0af4 + 1) = 1;
        *(undefined4 *)(param_1 + 0x5c) = 0;
        .glue::SetRect(param_1 + 0x34,0x20,4,0x48,0x5c);
        *(bool *)(param_1 + 0x17e) = *(short *)(param_1 + 4) == 0x4bc;
        *(undefined2 *)(param_1 + 0x46) = 0;
        *(undefined1 *)(param_1 + 0x88) = 0;
        *(undefined2 *)(param_1 + 0xa4) = 0xe0;
        *(undefined4 *)(param_1 + 0x80) = 32000;
        *(int *)(param_1 + 0x14c) =
             (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 8);
        iVar23 = *(int *)(param_1 + 0x14c);
        if (iVar23 == 3) {
          *(undefined4 *)(param_1 + 0xb8) = 0x1000f;
        }
        else if (iVar23 < 3) {
          if (iVar23 == 1) {
            *(undefined4 *)(param_1 + 0xb8) = 0x10004;
          }
          else if (0 < iVar23) {
            *(undefined4 *)(param_1 + 0xb8) = 0x1000b;
          }
        }
        else if (iVar23 < 5) {
          *(undefined4 *)(param_1 + 0xb8) = 0x10017;
        }
        goto LAB_10072efc;
      }
    }
    else {
      if (0x72f < iVar19) {
        *(undefined1 *)(param_1 + 0x188) = 1;
        *(undefined1 *)(iVar15 + 1) = 1;
        *(int *)(param_1 + 0x14c) =
             (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 8);
        *(int *)(param_1 + 0x150) =
             (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 10);
        if (*(int *)(param_1 + 0x150) == 0) {
          *(undefined4 *)(param_1 + 0x150) = 32000;
        }
        *(int *)(param_1 + 0x154) =
             (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xc);
        *(undefined2 *)(param_1 + 0xa6) =
             *(undefined2 *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xe);
        if ((int)*(short *)(param_1 + 0xa6) < *(int *)(param_1 + 0x150)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        else {
          *(undefined2 *)(param_1 + 0x46) = 0xb;
        }
        *(undefined2 *)(param_1 + 0xa4) = 500;
        if (*(char *)(*(int *)*puVar3 + 0x26cd) != '\0') {
          *(undefined4 *)(param_1 + 0xb8) = 0x10018;
        }
        .debug::_GetBGTile((int)(*(short *)(param_1 + 0xc) >> 5),
                           (int)(short)(*(short *)(param_1 + 10) + 0xc >> 5));
        .debug::_LookupBGTileKind();
        cVar22 = .debug::_IsWaterTile();
        if (cVar22 != '\0') {
          *(undefined4 *)(param_1 + 0xb8) = 0x90000;
        }
        goto LAB_10072efc;
      }
      if (iVar19 < 0x5d2) {
        *(undefined4 *)(param_1 + 0x5c) = 0;
        *(undefined4 *)(param_1 + 0x1f8) = 0;
        if (*(short *)(param_1 + 4) < 0x5cd) {
          .glue::SetRect(param_1 + 0x34,0x12,0x2c,0x6e,0x44);
        }
        else {
          .glue::SetRect(param_1 + 0x34,0x16,0x16,0x4e,0x4e);
        }
        puVar6[*(short *)(param_1 + 4) * 0x10 + -0x5c7f] = 1;
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(puVar6 + *(short *)(param_1 + 4) * 0x10 + -0x5c7c);
        *(undefined2 *)(param_1 + 0xb0) =
             *(undefined2 *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 8);
        if (*(short *)(param_1 + 0xb0) == 0) {
          *(undefined2 *)(param_1 + 0xb0) = 0xb;
        }
        psVar1 = (short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 10);
        if (*psVar1 == 0) {
          *psVar1 = 0x8c;
        }
        psVar1 = (short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xc);
        if (*psVar1 == 0) {
          *psVar1 = 0x1e;
        }
        sVar21 = *(short *)(param_1 + 0xb0);
        if (sVar21 < 10) {
          if ((sVar21 < 3) && (0 < sVar21)) {
            *(undefined4 *)(param_1 + 0x170) = 1;
            *(undefined1 *)(param_1 + 0x185) = 0;
            *(undefined1 *)(param_1 + 0x188) = 1;
            .debug::_SetupProgrammedPath(param_1,0xffffffff,0);
            if (*(short *)(param_1 + 0xb0) == 1) {
              *(int *)(param_1 + 0x1c) =
                   *(int *)(param_1 + 0x1c) +
                   *(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xe) * 0x100;
            }
            else if (*(short *)(param_1 + 0xb0) == 2) {
              *(int *)(param_1 + 0x14) =
                   *(int *)(param_1 + 0x14) +
                   *(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xe) * 0x100;
            }
            uVar18 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
            *(undefined2 *)(param_1 + 0xc) = uVar18;
            *(undefined2 *)(param_1 + 8) = uVar18;
            uVar18 = (undefined2)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
            *(undefined2 *)(param_1 + 10) = uVar18;
            *(undefined2 *)(param_1 + 6) = uVar18;
          }
        }
        else if (sVar21 < 0xf) {
          *(undefined1 *)(param_1 + 0x188) = 1;
          *(undefined1 *)(param_1 + 0x185) = 1;
          if (*(short *)(param_1 + 0x48) != -1) {
            iVar23 = (int)*(short *)(param_1 + 0xb0);
            if (iVar23 == 0xe) {
              uVar24 = 0x59c;
            }
            else {
              uVar24 = 0x59a;
            }
            iVar20 = 1;
            if ((1 < (iVar23 - 0xcU & 0xffff)) && (iVar23 != 0xe)) {
              iVar20 = 0;
            }
            if ((iVar23 - 0xcU & 0xffff) < 2) {
              iVar20 = 1;
            }
            else if (iVar23 == 0xe) {
              iVar20 = 2;
            }
            if (iVar20 != 0) {
              *(undefined1 *)(param_1 + 0x88) = 0;
            }
            *(undefined2 *)(param_1 + 0xa6) = 0;
            *(undefined4 *)(param_1 + 0x1f8) = 0;
            if ((*(short *)(param_1 + 0xb0) == 10) ||
               (((int)*(short *)(param_1 + 0xb0) - 0xdU & 0xffff) < 2)) {
              iVar23 = *(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10;
              .debug::_MakeRadial(param_1,*(short *)(param_1 + 0xc) + 0x32,
                                  *(short *)(param_1 + 10) + 0x32,(int)*(short *)(iVar23 + 10),
                                  (int)*(short *)(iVar23 + 0xc),(int)*(short *)(iVar23 + 0xe),0,0,0,
                                  iVar20);
            }
            else {
              iVar23 = *(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10;
              .debug::_MakeRadial(param_1,*(short *)(param_1 + 0xc) + 0x32,
                                  *(short *)(param_1 + 10) + 0x32,(int)*(short *)(iVar23 + 10),0,
                                  (int)*(short *)(iVar23 + 0xe),(int)*(short *)(iVar23 + 0xc),0,0,
                                  iVar20);
            }
            if (iVar20 == 0) {
              if (*(short *)(param_1 + 4) < 0x735) {
                uVar2 = *(ushort *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 10);
                .debug::_MakeRadiusSprites
                          (param_1,(int)(short)(((short)uVar2 >> 4) +
                                               (ushort)((short)uVar2 < 0 && (uVar2 & 0xf) != 0)),0,
                           uVar24,0x18,puVar5);
              }
              else {
                iVar23 = (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 10);
                iVar23 = iVar23 / 0x14 + (iVar23 >> 0x1f);
                .debug::_MakeRadiusSprites
                          (param_1,(int)(short)((short)iVar23 - (short)(iVar23 >> 0x1f)),0,uVar24,
                           0x18,puVar5);
              }
            }
            else {
              uVar2 = *(ushort *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 10);
              .debug::_MakeRadiusSprites
                        (param_1,(int)(short)(((short)uVar2 >> 4) +
                                             (ushort)((short)uVar2 < 0 && (uVar2 & 0xf) != 0)),0,
                         uVar24,0x18,puVar5);
            }
          }
        }
        goto LAB_10072efc;
      }
    }
  }
  else {
    if (iVar19 == 0xb54) {
      *(undefined1 *)(iVar17 + 1) = 1;
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar17 + 4);
      .glue::SetRect(param_1 + 0x34,0x20,0x28,0x24,0x57);
      goto LAB_10072efc;
    }
    if (iVar19 < 0xb54) {
      if (iVar19 == 0x740) {
        sVar21 = .debug::_FastRand(100);
        if (0x32 < sVar21) {
          *(undefined1 *)(param_1 + 0x17e) = 1;
        }
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0b24 + 4);
        .glue::SetRect(param_1 + 0x34,4,4,0x1e,0x18);
        goto LAB_10072efc;
      }
      if (iVar19 < 0x740) {
        if (0x73e < iVar19) {
          sVar21 = .debug::_FastRand(100);
          if (0x32 < sVar21) {
            *(undefined1 *)(param_1 + 0x17e) = 1;
          }
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0b28 + 4);
          .glue::SetRect(param_1 + 0x34,4,4,0x24,0x14);
          goto LAB_10072efc;
        }
        if (iVar19 < 0x734) {
          *(undefined1 *)(_DAT_100a0b30 + 1) = 1;
          *(undefined1 *)(iVar14 + 1) = 1;
          *(undefined1 *)(param_1 + 0x188) = 1;
          *(int *)(param_1 + 0x14c) =
               (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 8);
          *(int *)(param_1 + 0x150) =
               (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 10);
          if (*(int *)(param_1 + 0x150) == 0) {
            *(undefined4 *)(param_1 + 0x150) = 32000;
          }
          *(int *)(param_1 + 0x154) =
               (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xc);
          *(undefined2 *)(param_1 + 0xa6) =
               *(undefined2 *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xe);
          *(int *)(param_1 + 0x158) = (int)*(short *)(param_1 + 10);
          if ((int)*(short *)(param_1 + 0xa6) < *(int *)(param_1 + 0x150)) {
            *(undefined2 *)(param_1 + 0x46) = 0;
          }
          else {
            *(undefined2 *)(param_1 + 0x46) = 0xb;
          }
          *(undefined2 *)(param_1 + 0xa4) = 500;
          if (*(char *)(*(int *)*puVar3 + 0x26cd) != '\0') {
            *(undefined4 *)(param_1 + 0xb8) = 0x10018;
          }
          .debug::_GetBGTile((int)(*(short *)(param_1 + 0xc) >> 5),
                             (int)(short)(*(short *)(param_1 + 10) + 0xc >> 5));
          .debug::_LookupBGTileKind();
          cVar22 = .debug::_IsWaterTile();
          if (cVar22 != '\0') {
            *(undefined4 *)(param_1 + 0xb8) = 0x90000;
          }
          goto LAB_10072efc;
        }
      }
      else if (iVar19 < 0x770) {
        if (0x76b < iVar19) {
          if ((iVar19 - 0x76cU & 0xffff) < 2) {
            *(undefined1 *)(_DAT_100a0aec + 1) = 1;
          }
          else if (iVar19 == 0x76e) {
            *(undefined1 *)(_DAT_100a0ae8 + 1) = 1;
          }
          else if (iVar19 == 0x76f) {
            *(undefined1 *)(_DAT_100a0ae4 + 1) = 1;
          }
          *(undefined2 *)(param_1 + 0x46) = 0x10;
          psVar1 = (short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 8);
          if (*psVar1 == 0) {
            *psVar1 = 0x2d;
          }
          psVar1 = (short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 10);
          if (*psVar1 == 0) {
            *psVar1 = 0x32;
          }
          sVar21 = *(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 8);
          *(int *)(param_1 + 0x14c) = (int)sVar21;
          *(short *)(param_1 + 0xa6) = sVar21;
          *(int *)(param_1 + 0x150) =
               (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 10);
          .glue::SetRect(param_1 + 0x34,0x20,0x20,0x3c,0x3c);
          *(undefined4 *)(param_1 + 0x5c) = 0;
          *(undefined4 *)(param_1 + 0x1f8) = 0;
          goto LAB_10072efc;
        }
      }
      else if (0xb49 < iVar19) {
        *(undefined4 *)(param_1 + 0x5c) = 0;
        *(undefined4 *)(param_1 + 0x1f8) = 0;
        .glue::SetRect(param_1 + 0x34,0,0,0,0);
        sVar21 = *(short *)(param_1 + 4);
        if (sVar21 == 0xb4c) {
          *(undefined1 *)(iVar11 + 1) = 1;
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar11 + 4);
        }
        else if (sVar21 < 0xb4c) {
          if (sVar21 == 0xb4a) {
            *(undefined1 *)(iVar13 + 1) = 1;
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar13 + 4);
          }
          else if (0xb49 < sVar21) {
            *(undefined1 *)(iVar12 + 1) = 1;
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar12 + 4);
          }
        }
        else if (sVar21 < 0xb4e) {
          *(undefined1 *)(iVar10 + 1) = 1;
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar10 + 4);
        }
        *(undefined1 *)(param_1 + 0x88) = 0;
        *(undefined4 *)(param_1 + 0xb8) = 0xb0004;
        *(undefined4 *)(param_1 + 0x80) = 0x7ef4;
        *(int *)(param_1 + 0x14c) =
             (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 8);
        if (*(int *)(param_1 + 0x14c) == 0) {
          sVar21 = .debug::_FastRand(0x3c);
          *(int *)(param_1 + 0x14c) = sVar21 + 0x10e;
        }
        *(int *)(param_1 + 0x150) =
             (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 10);
        if (*(int *)(param_1 + 0x150) == 0) {
          *(undefined4 *)(param_1 + 0x150) = *(undefined4 *)(param_1 + 0x14c);
        }
        *(int *)(param_1 + 0x154) = (int)*(short *)(param_1 + 0xc) << 8;
        *(int *)(param_1 + 0x158) = (int)*(short *)(param_1 + 10) << 8;
        sVar21 = .debug::_FastRand(0x32);
        *(int *)(param_1 + 0x15c) = (int)sVar21;
        goto LAB_10072efc;
      }
    }
    else if (iVar19 < 0xc08) {
      if (iVar19 == 0xbf4) {
        *(undefined1 *)(_DAT_100a0b0c + 1) = 1;
        *(undefined2 *)(param_1 + 0x46) =
             *(undefined2 *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 10);
        *(int *)(param_1 + 0x150) =
             (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xc);
        if (*(int *)(param_1 + 0x150) == 0) {
          *(undefined4 *)(param_1 + 0x150) = 8;
        }
        .glue::SetRect(param_1 + 0x34,5,5,0xb5,0xb5);
        *(undefined4 *)(param_1 + 0x5c) = 0;
        *(undefined4 *)(param_1 + 0x1f8) = 0;
        goto LAB_10072efc;
      }
      if ((iVar19 < 0xbf4) && (iVar19 < 0xb56)) {
        *(undefined1 *)(iVar16 + 1) = 1;
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar16 + 4);
        .glue::SetRect(param_1 + 0x34,0x2c,0x28,0x2e,100);
        goto LAB_10072efc;
      }
    }
    else {
      if (iVar19 == 0xcb1) {
        *(undefined4 *)(param_1 + 0xc0) = 0;
        .glue::SetRect(param_1 + 0x34,0xc,0xc,0x54,0x54);
        goto LAB_10072efc;
      }
      if ((iVar19 < 0xcb1) && (iVar19 < 0xc10)) {
        *(undefined2 *)(param_1 + 0x1ca) = 0x80;
        *(undefined2 *)(param_1 + 0x1c8) = 0x80;
        *(undefined2 *)(param_1 + 0x1cc) = 0x80;
        *(undefined2 *)(param_1 + 0x1ce) = 0xa0;
        *(undefined1 *)(iVar7 + *(short *)(param_1 + 4) * 0x10 + -0xc07f) = 1;
        *(undefined1 *)(param_1 + 0x17c) = 0;
        *(undefined4 *)(param_1 + 0x80) = 30000;
        *(char *)(param_1 + 0x17e) =
             (char)*(undefined2 *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 8);
        *(undefined1 *)(param_1 + 0x88) = 0;
        *(undefined4 *)(param_1 + 0x5c) = 0;
        *(undefined4 *)(param_1 + 0x1f8) = 0;
        .glue::SetRect(param_1 + 0x34,0,0,0,0);
        if (*(short *)(param_1 + 4) == 0xc0f) {
          *(undefined4 *)(param_1 + 0x80) = 0xfffffff6;
        }
        goto LAB_10072efc;
      }
    }
  }
  if ((iVar19 < 0xa8c) || (0xaef < iVar19)) {
    if ((2999 < iVar19) && (iVar19 < 0xbc2)) {
      .glue::SetRect(param_1 + 0x34,0xfffffff8,0xfffffff6,(iVar19 + -3000) * 0x20 + 0x88,0x96);
      *(undefined4 *)(param_1 + 0x80) = 0;
      *(undefined1 *)(iVar20 + -0x10000 + *(short *)(param_1 + 4) * 0x10 + 0x4481) = 1;
      *(undefined4 *)(param_1 + 0xc0) =
           *(undefined4 *)(iVar20 + -0x10000 + *(short *)(param_1 + 4) * 0x10 + 0x4484);
      *(undefined4 *)(param_1 + 0x5c) = uVar24;
    }
  }
  else {
    *(undefined4 *)(param_1 + 0x5c) = 0;
    *(undefined4 *)(param_1 + 0x1f8) = 0;
    *(undefined4 *)(param_1 + 0x80) = 0xffffff9c;
    *(undefined1 *)(param_1 + 0x88) = 1;
    .glue::SetRect(param_1 + 0x34,0,0,0,0);
    *(undefined1 *)(iVar23 + -0x10000 + *(short *)(param_1 + 4) * 0x10 + 0x5741) = 1;
    *(undefined4 *)(param_1 + 0xc0) =
         *(undefined4 *)(iVar23 + -0x10000 + *(short *)(param_1 + 4) * 0x10 + 0x5744);
    *(undefined1 *)(param_1 + 0x185) = 1;
    switch(*(undefined2 *)(param_1 + 4)) {
    case 0xb0b:
      .glue::SetRect(param_1 + 0x34,0xf,0xd,0x32,0x28);
      *(undefined1 *)(param_1 + 0x185) = 0;
      break;
    case 0xb10:
      .glue::SetRect(param_1 + 0x34,0xe,4,0x27,0x45);
      break;
    case 0xb11:
      .glue::SetRect(param_1 + 0x34,5,4,0x3b,0x46);
      break;
    case 0xb12:
      .glue::SetRect(param_1 + 0x34,2,6,0x1c,0x23);
      break;
    case 0xb13:
      .glue::SetRect(param_1 + 0x34,10,4,0x1e,0x21);
      break;
    case 0xb14:
      .glue::SetRect(param_1 + 0x34,0,0xe,0x1f,0x24);
    }
    if (*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 8) != 0) {
      *(undefined1 *)(param_1 + 0x17e) = 1;
      .debug::_FlipHRect(param_1 + 0x34,(int)*(short *)(*(int *)(param_1 + 0xc0) + 6));
    }
    sVar21 = *(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 10);
    if (sVar21 != 0) {
      *(int *)(param_1 + 0xb8) = sVar21 + 0x10000;
    }
    if (*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xc) != 0) {
      *(undefined4 *)(param_1 + 0x80) = 10000;
    }
    *(undefined2 *)(param_1 + 0x110) = 0;
  }
LAB_10072efc:
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  return;
}


// ==== .HandleBackgroundSprite @ 10073afc ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleBackgroundSprite(int param_1)

{
  int iVar1;
  bool bVar2;
  bool bVar3;
  short *psVar4;
  short *psVar5;
  undefined *puVar6;
  undefined4 *puVar7;
  undefined4 *puVar8;
  undefined4 *puVar9;
  undefined4 *puVar10;
  int iVar11;
  double dVar12;
  double dVar13;
  double dVar14;
  int iVar15;
  short sVar18;
  uint uVar16;
  int iVar17;
  int iVar19;
  int unaff_r18;
  int unaff_r19;
  int iVar20;
  undefined8 uStack_70;
  undefined8 uStack_60;
  undefined8 uStack_58;
  undefined8 uStack_48;
  
  iVar11 = _DAT_100a0b10;
  iVar17 = _DAT_100a0b00;
  iVar1 = _DAT_100a0aec;
  iVar19 = _DAT_100a0ae8;
  iVar20 = _DAT_100a0ae4;
  puVar10 = _DAT_100a036c;
  puVar9 = _DAT_100a0368;
  puVar8 = _DAT_100a0308;
  puVar7 = _DAT_100a0058;
  puVar6 = PTR_DAT_1009fe78;
  psVar5 = _DAT_1009fd94;
  psVar4 = _DAT_1009fd90;
  if (*(char *)(param_1 + 0xe9) != '\0') {
    return;
  }
  if (*(char *)(param_1 + 0x1b2) != '\0') {
    return;
  }
  .debug::_StandardSpriteHandles(param_1);
  iVar15 = (int)*(short *)(param_1 + 4);
  if (iVar15 < 0x734) {
    if (iVar15 < 0x4bb) {
      if (iVar15 < 0x482) {
        if (iVar15 < 0x44c) {
          if (0x441 < iVar15) {
            sVar18 = *(short *)(*(int *)*puVar7 + *(short *)(param_1 + 0x48) * 0x10 + 8);
            if (*(int *)(param_1 + 0x16c) != 0) {
              *(undefined4 *)(param_1 + 0x120) = 1;
              *(undefined4 *)(param_1 + 0x11c) = 1;
            }
            dVar14 = dRam100a1b18;
            dVar13 = dRam100a1b10;
            dVar12 = dRam100a1b08;
            if (sVar18 < 0x65) {
              if (sVar18 == 0) {
                if (((int)*(short *)(param_1 + 0xc) != *(int *)(param_1 + 0x14c)) ||
                   ((int)*(short *)(param_1 + 10) != *(int *)(param_1 + 0x150))) {
                  uStack_70 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x14) ^ 0x80000000);
                  *(int *)(param_1 + 0x14) =
                       (int)(dRam100a1b18 * (uStack_70 - dRam100a1b08) +
                            dRam100a1b10 *
                            ((double)CONCAT44(0x43300000,*(int *)(param_1 + 0x14c) << 8 ^ 0x80000000
                                             ) - dRam100a1b08));
                  uStack_58 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x1c) ^ 0x80000000);
                  *(int *)(param_1 + 0x1c) =
                       (int)(dVar14 * (uStack_58 - dVar12) +
                            dVar13 * ((double)CONCAT44(0x43300000,
                                                       *(int *)(param_1 + 0x150) << 8 ^ 0x80000000)
                                     - dVar12));
                  *(short *)(param_1 + 0xc) = (short)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
                  *(short *)(param_1 + 10) = (short)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
                }
              }
              else {
LAB_10073f14:
                .debug::_HandleProgrammedPath(param_1);
                *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + *(int *)(param_1 + 0x24);
                *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + *(int *)(param_1 + 0x2c);
                *(short *)(param_1 + 0xc) = (short)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
                *(short *)(param_1 + 10) = (short)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
              }
            }
            else {
              if (0x6a < sVar18) goto LAB_10073f14;
              if (*(short *)(param_1 + 0xa6) == 0) {
                *(short *)(param_1 + 0x46) =
                     *(short *)(param_1 + 0x46) + (short)*(undefined4 *)(param_1 + 0x15c);
                *(int *)(param_1 + 0x160) = *(int *)(param_1 + 0x160) + -1;
                if (*(int *)(param_1 + 0x160) < 1) {
                  *(undefined4 *)(param_1 + 0x160) = *(undefined4 *)(param_1 + 0x158);
                  *(undefined2 *)(param_1 + 0xa6) =
                       *(undefined2 *)(*(int *)*puVar7 + *(short *)(param_1 + 0x48) * 0x10 + 10);
                }
              }
              else if ((((sVar18 != 0x69) && (sVar18 != 0x6a)) &&
                       (*(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1,
                       *(short *)(param_1 + 0xa6) == 0)) &&
                      (sVar18 = FUN_100916dc(*puVar8), sVar18 == 0)) {
                .debug::_STPlay3DSoundRand(*puVar8,1,0x41,*(undefined4 *)(param_1 + 0xe));
              }
              dVar14 = dRam100a1b18;
              dVar13 = dRam100a1b10;
              dVar12 = dRam100a1b08;
              if (((int)*(short *)(param_1 + 0xc) != *(int *)(param_1 + 0x14c)) ||
                 ((int)*(short *)(param_1 + 10) != *(int *)(param_1 + 0x150))) {
                uStack_48 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x14) ^ 0x80000000);
                *(int *)(param_1 + 0x14) =
                     (int)(dRam100a1b18 * (uStack_48 - dRam100a1b08) +
                          dRam100a1b10 *
                          ((double)CONCAT44(0x43300000,*(int *)(param_1 + 0x14c) << 8 ^ 0x80000000)
                          - dRam100a1b08));
                uStack_60 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x1c) ^ 0x80000000);
                *(int *)(param_1 + 0x1c) =
                     (int)(dVar14 * (uStack_60 - dVar12) +
                          dVar13 * ((double)CONCAT44(0x43300000,
                                                     *(int *)(param_1 + 0x150) << 8 ^ 0x80000000) -
                                   dVar12));
                *(short *)(param_1 + 0xc) = (short)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
                *(short *)(param_1 + 10) = (short)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
              }
            }
            while (*(short *)(param_1 + 0x46) < 0) {
              *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 0x20;
            }
            while (sVar18 = *(short *)(param_1 + 0x46), 0x1f < sVar18) {
              *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -0x20;
            }
            if (sVar18 < 0x12) {
              *(undefined1 *)(param_1 + 0x17e) = 0;
            }
            else {
              *(undefined1 *)(param_1 + 0x17e) = 1;
              sVar18 = 0x21 - sVar18;
            }
            if (sVar18 == 0) {
              *(undefined1 *)(param_1 + 0x17e) = 0;
            }
            sVar18 = *(short *)(param_1 + 0x46);
            if (sVar18 < 0) {
              sVar18 = sVar18 + 0x20;
            }
            uVar16 = (uint)sVar18;
            if (uVar16 == (((int)uVar16 >> 2) + (uint)((int)uVar16 < 0 && (uVar16 & 3) != 0)) * 4) {
              sVar18 = (short)((int)uVar16 >> 2) + (ushort)((int)uVar16 < 0 && (uVar16 & 3) != 0);
              if (sVar18 < 5) {
                *(undefined1 *)(param_1 + 0x17e) = 0;
              }
              else {
                *(undefined1 *)(param_1 + 0x17e) = 1;
                sVar18 = 8 - sVar18;
              }
              *(undefined2 *)(param_1 + 0x1aa) = 0;
              *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar11 + sVar18 * 4 + 4);
              *(undefined4 *)(param_1 + 0xb8) = 0;
            }
            else {
              uVar16 = (short)(0x20 - sVar18) * 0xb4;
              uVar16 = ((int)uVar16 >> 4) + (uint)((int)uVar16 < 0 && (uVar16 & 0xf) != 0);
              sVar18 = (short)((int)uVar16 >> 1) + (ushort)((int)uVar16 < 0 && (uVar16 & 1) != 0);
              *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar11 + 4);
              *(undefined1 *)(param_1 + 0x17e) = 0;
              if (0xb3 < sVar18) {
                sVar18 = sVar18 + -0xb4;
              }
              *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar11 + 4);
              *(short *)(param_1 + 0x1aa) = sVar18 << 1;
            }
            *(undefined1 *)(param_1 + 0x88) = 0;
            goto LAB_10074e14;
          }
        }
        else if (0x47d < iVar15) {
          *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1;
          if (*(short *)(param_1 + 0x46) < 0) {
            *(undefined2 *)(param_1 + 0x46) = 0;
          }
          if (3 < *(short *)(param_1 + 0x46)) {
            *(undefined2 *)(param_1 + 0x46) = 3;
          }
          sVar18 = *(short *)(param_1 + 4);
          if (sVar18 == 0x480) {
            *(undefined4 *)(param_1 + 0xc0) =
                 *(undefined4 *)(iVar17 + *(short *)(param_1 + 0x46) * 4 + 4);
          }
          else if (sVar18 < 0x480) {
            if (sVar18 == 0x47e) {
              *(undefined4 *)(param_1 + 0xc0) =
                   *(undefined4 *)(_DAT_100a0b08 + *(short *)(param_1 + 0x46) * 4 + 4);
            }
            else if (0x47d < sVar18) {
              *(undefined4 *)(param_1 + 0xc0) =
                   *(undefined4 *)(_DAT_100a0b04 + *(short *)(param_1 + 0x46) * 4 + 4);
            }
          }
          else if (sVar18 < 0x482) {
            *(undefined4 *)(param_1 + 0xc0) =
                 *(undefined4 *)(iVar17 + *(short *)(param_1 + 0x46) * 4 + 4);
            *(undefined1 *)(param_1 + 0x17e) = 1;
          }
          goto LAB_10074e14;
        }
      }
      else if (iVar15 == 0x4b8) {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (0x1f < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        iVar20 = (int)*(short *)(param_1 + 0x46) >> 1;
        if (((int)*(short *)(param_1 + 0x46) & 1U) == 0) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0afc + iVar20 * 4 + 4);
        }
        else {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0af8 + iVar20 * 4 + 4);
        }
        goto LAB_10074e14;
      }
    }
    else if (iVar15 < 0x5d2) {
      if (iVar15 == 0x4bd) {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (0xf < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(_DAT_100a0af0 + *(short *)(param_1 + 0x46) * 4 + 4);
        goto LAB_10074e14;
      }
      if (iVar15 < 0x4bd) {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (0xf < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(_DAT_100a0af4 + *(short *)(param_1 + 0x46) * 4 + 4);
        goto LAB_10074e14;
      }
      if (0x5c7 < iVar15) {
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(PTR_DAT_100a09f4 + iVar15 * 0x10 + -0x5c7c);
        sVar18 = *(short *)(param_1 + 0xb0);
        if (sVar18 < 10) {
          if ((sVar18 < 3) && (0 < sVar18)) {
            .debug::_HandleProgrammedPath(param_1);
            .debug::_ApplyGravityAndSeparateFromTiles(param_1);
          }
        }
        else if (sVar18 < 0xf) {
          if (*(short *)(param_1 + 0xa6) < 0) {
            *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
          }
          else {
            *(undefined2 *)(param_1 + 0xa6) = 0;
          }
          *(undefined4 *)(param_1 + 0x2c) = 0;
          *(undefined4 *)(param_1 + 0x24) = 0;
          if (*(short *)(param_1 + 4) < 0x5cd) {
            *(short *)(param_1 + 0x10) = *(short *)(param_1 + 0xc) + 0x40;
            *(short *)(param_1 + 0xe) = *(short *)(param_1 + 10) + 0x32;
          }
          .debug::_UpdateRadialPos(param_1);
          .debug::_UpdateRadiusSprites(param_1,0,0);
          *(undefined4 *)(param_1 + 0x194) = 0;
          if ((*(short *)(param_1 + 0xb0) == 10) || (*(short *)(param_1 + 0xb0) == 0xb)) {
            *(undefined4 *)(param_1 + 0x170) = 1;
            *(short *)(param_1 + 0x1aa) =
                 (short)((uint)*(undefined4 *)(*(int *)(param_1 + 0x198) + 0x18) >> 8) + 0x5a;
            if (0x167 < *(short *)(param_1 + 0x1aa)) {
              *(short *)(param_1 + 0x1aa) = *(short *)(param_1 + 0x1aa) + -0x168;
            }
            *(undefined1 *)(param_1 + 0x88) = 0;
            *(undefined1 *)(param_1 + 0x89) = 1;
          }
          else {
            iVar20 = *(int *)(param_1 + 0x198);
            if (*(short *)(iVar20 + 0x40) < 0x80) {
              .debug::_MTChangeSpriteLayer(param_1,0x7ef4);
              *(undefined4 *)(param_1 + 0x170) = 1;
              if ((*(short *)(param_1 + 0xb0) == 0xc) && (*(short *)(iVar20 + 0x40) < 0x60)) {
                *(undefined4 *)(param_1 + 0x170) = 0;
              }
            }
            else {
              .debug::_MTChangeSpriteLayer(param_1,0xfffffed4);
              *(undefined4 *)(param_1 + 0x170) = 0;
            }
          }
        }
        goto LAB_10074e14;
      }
    }
    else {
      if (0x731 < iVar15) {
        *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
        if (*(int *)(param_1 + 0x150) + *(int *)(param_1 + 0x154) < (int)*(short *)(param_1 + 0xa6))
        {
          *(undefined2 *)(param_1 + 0xa6) = 0;
        }
        if ((int)*(short *)(param_1 + 0xa6) < *(int *)(param_1 + 0x150)) {
          if ((*(short *)(param_1 + 0x46) == 0xb) && (sVar18 = FUN_100916dc(*puVar10), sVar18 == 0))
          {
            .debug::_STPlay3DSoundRand(*puVar10,1,0x41,*(undefined4 *)(param_1 + 0xe));
          }
          if (0 < *(short *)(param_1 + 0x46)) {
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1;
          }
        }
        else {
          if ((*(short *)(param_1 + 0x46) == 0) && (sVar18 = FUN_100916dc(*puVar9), sVar18 == 0)) {
            .debug::_STPlay3DSoundRand(*puVar9,1,0x41,*(undefined4 *)(param_1 + 0xe));
          }
          if (*(short *)(param_1 + 0x46) < 0xb) {
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
          }
        }
        if (*(short *)(param_1 + 4) == 0x732) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0b30 + 4);
          *(short *)(param_1 + 10) =
               (short)*(undefined4 *)(param_1 + 0x158) + *(short *)(param_1 + 0x46) * 2;
          iVar20 = *(short *)(param_1 + 0x46) * -2 + 0x14;
          if (iVar20 < 1) {
            iVar20 = 0;
          }
          *(short *)(param_1 + 0x1ba) = (short)iVar20;
        }
        else if (*(short *)(param_1 + 4) == 0x733) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0b2c + 4);
          *(short *)(param_1 + 10) =
               (short)*(undefined4 *)(param_1 + 0x158) + *(short *)(param_1 + 0x46) * -2;
          *(short *)(param_1 + 0x1bc) =
               (short)*(undefined4 *)(param_1 + 0x158) - *(short *)(param_1 + 10);
        }
        if (*(short *)(param_1 + 0x46) < 2) {
          .glue::SetRect(param_1 + 0x34,0,0,0x80,0x20);
        }
        else {
          .glue::SetRect(param_1 + 0x34,0,0,0,0);
        }
        goto LAB_10074e14;
      }
      if (0x72f < iVar15) {
        *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
        if (*(int *)(param_1 + 0x150) + *(int *)(param_1 + 0x154) < (int)*(short *)(param_1 + 0xa6))
        {
          *(undefined2 *)(param_1 + 0xa6) = 0;
        }
        if ((int)*(short *)(param_1 + 0xa6) < *(int *)(param_1 + 0x150)) {
          if ((*(short *)(param_1 + 0x46) == 0xb) && (sVar18 = FUN_100916dc(*puVar10), sVar18 == 0))
          {
            .debug::_STPlay3DSoundRand(*puVar10,1,0x97,*(undefined4 *)(param_1 + 0xe));
          }
          if (0 < *(short *)(param_1 + 0x46)) {
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1;
          }
        }
        else {
          if ((*(short *)(param_1 + 0x46) == 0) && (sVar18 = FUN_100916dc(*puVar9), sVar18 == 0)) {
            .debug::_STPlay3DSoundRand(*puVar9,1,0x97,*(undefined4 *)(param_1 + 0xe));
          }
          if (*(short *)(param_1 + 0x46) < 0xb) {
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
          }
        }
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(_DAT_100a0b34 + *(short *)(param_1 + 0x46) * 4 + 4);
        if (*(short *)(param_1 + 0x46) < 2) {
          if (*(char *)(param_1 + 0x17e) == '\0') {
            .glue::SetRect(param_1 + 0x34,0,0xc,0x13,0x74);
          }
          else {
            .glue::SetRect(param_1 + 0x34,7,0xc,0x20,0x74);
          }
        }
        else {
          .glue::SetRect(param_1 + 0x34,0,0,0,0);
        }
        goto LAB_10074e14;
      }
    }
  }
  else {
    if (iVar15 == 0xb54) {
      if (*(short *)(*(int *)*puVar7 + *(short *)(param_1 + 0x48) * 0x10 + 0xc) == 0) {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0b3c + 4);
      }
      else {
        *(undefined4 *)(param_1 + 0xc0) = 0;
      }
      goto LAB_10074e14;
    }
    if (iVar15 < 0xb54) {
      if (iVar15 < 0x76c) {
        if ((iVar15 < 0x741) && (0x73e < iVar15)) {
          if (iVar15 == 0x73f) {
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0b28 + 4);
          }
          else if (iVar15 == 0x740) {
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0b24 + 4);
          }
          *(undefined4 *)(param_1 + 0x11c) = 1;
          goto LAB_10074e14;
        }
      }
      else {
        if (0xb49 < iVar15) {
          iVar20 = *(int *)(param_1 + 0x14c);
          iVar19 = *(int *)(param_1 + 0x150);
          if (iVar15 == 0xb4c) {
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0b18 + 4);
          }
          else if (iVar15 < 0xb4c) {
            if (iVar15 == 0xb4a) {
              *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0b20 + 4);
            }
            else if (0xb49 < iVar15) {
              *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0b1c + 4);
            }
          }
          else if (iVar15 < 0xb4e) {
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0b14 + 4);
          }
          if (iVar20 < 1) {
            if (iVar20 == 0) {
              *(undefined4 *)(param_1 + 0x14) = *(undefined4 *)(param_1 + 0x154);
            }
          }
          else {
            iVar1 = *(short *)(puVar6 + 2) * 0x100;
            *(int *)(param_1 + 0x14) = iVar1 + (*(int *)(param_1 + 0x154) - (iVar1 * iVar20 >> 8));
          }
          if (iVar19 < 1) {
            if (iVar19 == 0) {
              *(undefined4 *)(param_1 + 0x1c) = *(undefined4 *)(param_1 + 0x158);
            }
          }
          else {
            iVar20 = *(short *)puVar6 * 0x100;
            *(int *)(param_1 + 0x1c) = (iVar20 + *(int *)(param_1 + 0x158)) - (iVar20 * iVar19 >> 8)
            ;
          }
          *(short *)(param_1 + 0xc) = (short)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
          *(short *)(param_1 + 10) = (short)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
          goto LAB_10074e14;
        }
        if (iVar15 < 0x770) {
          iVar17 = (int)*(short *)(param_1 + 0x46);
          if (iVar17 < 0x11) {
            iVar17 = iVar17 >> 2;
            if (iVar15 == 0x76e) {
              *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar19 + iVar17 * 4 + 4);
            }
            else if (iVar15 < 0x76e) {
              if (iVar15 == 0x76c) {
                *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar1 + iVar17 * 4 + 4);
              }
              else if (0x76b < iVar15) {
                *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar1 + iVar17 * 4 + 4);
                *(undefined1 *)(param_1 + 0x17e) = 1;
              }
            }
            else if (iVar15 < 0x770) {
              *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar20 + iVar17 * 4 + 4);
            }
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
          }
          else if (iVar17 == 0x11) {
            if (0 < *(short *)(param_1 + 0xa6)) {
              *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
            }
            if (*(short *)(param_1 + 0xa6) < 1) {
              sVar18 = *(short *)(param_1 + 4);
              bVar3 = false;
              iVar17 = (int)(short)*(undefined4 *)(param_1 + 0x150);
              if (sVar18 == 0x76e) {
                bVar3 = false;
                bVar2 = false;
                if ((*(short *)(param_1 + 0x10) - iVar17 < (int)*psVar5) &&
                   ((int)*psVar5 < *(short *)(param_1 + 0x10) + iVar17)) {
                  bVar2 = true;
                }
                if ((bVar2) && ((int)*psVar4 <= *(short *)(param_1 + 0xe) + 0x23)) {
                  bVar3 = true;
                }
              }
              else if (sVar18 < 0x76e) {
                if (sVar18 == 0x76c) {
                  bVar3 = false;
                  bVar2 = false;
                  if ((*(short *)(param_1 + 0xe) - iVar17 < (int)*psVar4) &&
                     ((int)*psVar4 < *(short *)(param_1 + 0xe) + iVar17)) {
                    bVar2 = true;
                  }
                  if ((bVar2) && (*(short *)(param_1 + 0x10) < *psVar5)) {
                    bVar3 = true;
                  }
                }
                else if (0x76b < sVar18) {
                  bVar3 = false;
                  bVar2 = false;
                  if ((*(short *)(param_1 + 0xe) - iVar17 < (int)*psVar4) &&
                     ((int)*psVar4 < *(short *)(param_1 + 0xe) + iVar17)) {
                    bVar2 = true;
                  }
                  if ((bVar2) && (*psVar5 < *(short *)(param_1 + 0x10))) {
                    bVar3 = true;
                  }
                }
              }
              else if (sVar18 < 0x770) {
                bVar3 = false;
                bVar2 = false;
                if ((*(short *)(param_1 + 0x10) - iVar17 < (int)*psVar5) &&
                   ((int)*psVar5 < *(short *)(param_1 + 0x10) + iVar17)) {
                  bVar2 = true;
                }
                if ((bVar2) && (*(short *)(param_1 + 0xe) < *psVar4)) {
                  bVar3 = true;
                }
              }
              if (bVar3) {
                *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
                *(undefined2 *)(param_1 + 0xa6) = 8;
                sVar18 = *(short *)(param_1 + 4);
                if (sVar18 == 0x76e) {
                  *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar19 + 0x18);
                }
                else if (sVar18 < 0x76e) {
                  if (sVar18 == 0x76c) {
                    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar1 + 0x18);
                  }
                  else if (0x76b < sVar18) {
                    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar1 + 0x18);
                    *(undefined1 *)(param_1 + 0x17e) = 1;
                  }
                }
                else if (sVar18 < 0x770) {
                  *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar20 + 0x18);
                }
              }
            }
          }
          else if (iVar17 == 0x12) {
            .debug::_STPlay3DSound(*_DAT_100a02e0,1,0xab,*(undefined4 *)(param_1 + 0xe));
            iVar17 = (int)*(short *)(param_1 + 4);
            if (iVar17 == 0x76c) {
              unaff_r19 = 0x20;
              unaff_r18 = 0x2a;
            }
            else if (iVar17 == 0x76d) {
              unaff_r19 = -0x20;
              unaff_r18 = 0x2a;
            }
            else if (iVar17 == 0x76e) {
              unaff_r19 = 0x2a;
              unaff_r18 = -0x20;
            }
            else if (iVar17 == 0x76f) {
              unaff_r19 = 0x2a;
              unaff_r18 = 0x20;
            }
            iVar17 = .debug::_MTNewSprite
                               (iVar17 + 5,*(short *)(param_1 + 0xc) + unaff_r19,
                                *(short *)(param_1 + 10) + unaff_r18,0xb,0xffffffff,PTR_PTR_100a0830
                               );
            sVar18 = *(short *)(param_1 + 4);
            if (sVar18 == 0x76c) {
              *(undefined4 *)(iVar17 + 0x24) = 0x1000;
              *(undefined4 *)(iVar17 + 0x2c) = 0;
            }
            else if (sVar18 == 0x76d) {
              *(undefined4 *)(iVar17 + 0x24) = 0xfffff000;
              *(undefined4 *)(iVar17 + 0x2c) = 0;
            }
            else if (sVar18 == 0x76e) {
              *(undefined4 *)(iVar17 + 0x24) = 0;
              *(undefined4 *)(iVar17 + 0x2c) = 0xfffff000;
            }
            else if (sVar18 == 0x76f) {
              *(undefined4 *)(iVar17 + 0x24) = 0;
              *(undefined4 *)(iVar17 + 0x2c) = 0x1000;
            }
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
            sVar18 = *(short *)(param_1 + 4);
            if (sVar18 == 0x76e) {
              *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar19 + 4);
            }
            else if (sVar18 < 0x76e) {
              if (sVar18 == 0x76c) {
                *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar1 + 4);
              }
              else if (0x76b < sVar18) {
                *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar1 + 4);
                *(undefined1 *)(param_1 + 0x17e) = 1;
              }
            }
            else if (sVar18 < 0x770) {
              *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar20 + 4);
            }
          }
          else {
            *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
            if (*(short *)(param_1 + 0xa6) < 1) {
              *(undefined2 *)(param_1 + 0x46) = 0;
              *(short *)(param_1 + 0xa6) = (short)*(undefined4 *)(param_1 + 0x14c);
            }
          }
          goto LAB_10074e14;
        }
      }
    }
    else {
      if (iVar15 == 0xbf4) {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0b0c + 4);
        *(short *)(param_1 + 0x46) =
             *(short *)(param_1 + 0x46) + (short)*(undefined4 *)(param_1 + 0x150);
        sVar18 = *(short *)(param_1 + 0x46);
        if (sVar18 < 0x168) {
          if (sVar18 < 0) {
            *(short *)(param_1 + 0x46) = sVar18 + 0x168;
          }
        }
        else {
          *(short *)(param_1 + 0x46) = sVar18 + -0x168;
        }
        *(undefined2 *)(param_1 + 0x1aa) = *(undefined2 *)(param_1 + 0x46);
        *(undefined1 *)(param_1 + 0x88) = 0;
        *(undefined1 *)(param_1 + 0x89) = 1;
        if (*(short *)(*(int *)*puVar7 + *(short *)(param_1 + 0x48) * 0x10 + 0xe) == 0) {
          *(undefined2 *)(param_1 + 0x1ba) = 0x5e;
        }
        goto LAB_10074e14;
      }
      if (iVar15 < 0xbf4) {
        if (iVar15 < 0xb56) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0b38 + 4);
          goto LAB_10074e14;
        }
      }
      else if ((iVar15 < 0xc10) && (0xc07 < iVar15)) {
        if (*(char *)(param_1 + 0x17c) == '\0') {
          .debug::_SetupTree(param_1);
        }
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(_DAT_100a0ae0 + *(short *)(param_1 + 4) * 0x10 + -0xc07c);
        *(char *)(param_1 + 0x17e) =
             (char)*(undefined2 *)(*(int *)*puVar7 + *(short *)(param_1 + 0x48) * 0x10 + 8);
        goto LAB_10074e14;
      }
    }
  }
  if ((iVar15 < 0xa8c) || (0xaef < iVar15)) {
    if ((2999 < iVar15) && (iVar15 < 0xbc2)) {
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0adc + iVar15 * 0x10 + -0xbb7c);
    }
  }
  else {
    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0ad8 + iVar15 * 0x10 + -0xa8bc);
  }
LAB_10074e14:
  .debug::_StandardSpriteCleanup(param_1);
  return;
}


// ==== .HitBackgroundSprite @ 10075044 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitBackgroundSprite(int param_1,int param_2)

{
  short sVar1;
  undefined4 *puVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  
  puVar4 = PTR_PTR_100a0488;
  puVar3 = PTR_PTR_100a0480;
  puVar5 = PTR_PTR_100a0460;
  puVar2 = _DAT_100a0058;
  sVar1 = *(short *)(param_1 + 4);
  if ((sVar1 < 3000) || (0xbc1 < sVar1)) {
    if ((sVar1 < 0x47e) || (0x487 < sVar1)) {
      if (((((0x441 < sVar1) && (sVar1 < 0x44c)) &&
           (puVar5 = *(undefined **)(param_2 + 0x4c), puVar5 != PTR_PTR_100a0480)) &&
          (((puVar5 != PTR_PTR_100a01f8 && (puVar5 != PTR_PTR_100a045c)) &&
           (puVar5 != PTR_PTR_100a0ac4)))) &&
         ((((puVar5 != PTR_PTR_100a0488 && (puVar5 != PTR_PTR_100a0460)) &&
           ((((sVar1 = *(short *)(param_2 + 4), sVar1 != 0x41f &&
              (((sVar1 != 0x434 && (sVar1 != 0x771)) && (sVar1 != 0x772)))) &&
             ((sVar1 != 0xb7c && (sVar1 != 0x5c3)))) && (sVar1 != 0x5c4)))) &&
          (-1 < *(int *)(param_2 + 0x130))))) {
        if ((puVar5 == PTR_PTR_100a04e8) &&
           ((sVar1 = *(short *)(*(int *)*_DAT_100a0058 + *(short *)(param_1 + 0x48) * 0x10 + 8),
            sVar1 == 0x69 || (sVar1 == 0x6a)))) {
          .debug::_KillPlayerShot(param_2,0,1);
          .debug::_STPlay3DSoundRand(*_DAT_100a041c,1,0xab,*(undefined4 *)(param_1 + 0xe));
          if (*(short *)(param_1 + 0xa6) != 0) {
            if (*(int *)(param_2 + 0x24) < 0) {
              if (((0x18 < *(short *)(param_1 + 0x46)) || (*(short *)(param_1 + 0x46) < 0xc)) ||
                 (*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 8) == 0x6a)) {
                *(undefined4 *)(param_1 + 0x15c) = 0xffffffff;
                *(undefined4 *)(param_1 + 0x160) = *(undefined4 *)(param_1 + 0x158);
                *(undefined2 *)(param_1 + 0xa6) = 0;
              }
            }
            else if (((0x17 < *(short *)(param_1 + 0x46)) || (*(short *)(param_1 + 0x46) < 8)) ||
                    (*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 8) == 0x6a)) {
              *(undefined4 *)(param_1 + 0x15c) = 1;
              *(undefined4 *)(param_1 + 0x160) = *(undefined4 *)(param_1 + 0x158);
              *(undefined2 *)(param_1 + 0xa6) = 0;
            }
          }
        }
        else {
          .debug::_TurnIntoCannoned(param_2,param_1);
          *(undefined4 *)(param_1 + 0x154) = 6;
        }
      }
    }
    else {
      if (*(undefined **)(param_2 + 0x4c) == PTR_PTR_100a04e8) {
        .debug::_KillPlayerShot(param_2,1,1);
      }
      if (*(undefined **)(param_2 + 0x4c) == puVar4) {
        .debug::_KillEnemyShot(param_2);
      }
      if ((((*(undefined **)(param_2 + 0x4c) != puVar3) || (*(short *)(param_2 + 4) < 0x47e)) ||
          (0x487 < *(short *)(param_2 + 4))) &&
         (((*(short *)(param_1 + 0x46) == 0 && (*(char *)(param_2 + 0xe9) == '\0')) &&
          (*(undefined **)(param_2 + 0x4c) != puVar5)))) {
        *(undefined2 *)(param_1 + 0x46) = 4;
        .debug::_SuperSpring(param_1,param_2);
      }
    }
  }
  else if (*(undefined **)(param_2 + 0x4c) != PTR_PTR_100a0480) {
    *(short *)(param_2 + 0x1be) =
         *(short *)(param_1 + 0x36) + (short)((uint)*(undefined4 *)(param_1 + 0x14) >> 8) + 0x2e;
    *(short *)(param_2 + 0x1c0) =
         *(short *)(param_1 + 0x3a) + (short)((uint)*(undefined4 *)(param_1 + 0x14) >> 8) + -0x2f;
    *(short *)(param_2 + 0x1c4) =
         *(short *)(param_1 + 0x34) + (short)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8) + -0x2c;
    *(short *)(param_2 + 0x1c2) =
         *(short *)(param_1 + 0x38) + (short)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8) + 0x27;
  }
  return;
}


// ==== .DrawGreyOutline @ 100757b8 ====

void _DrawGreyOutline(undefined4 param_1,undefined4 param_2)

{
  undefined2 uStack_28;
  undefined2 uStack_26;
  undefined2 uStack_24;
  undefined1 auStack_22 [6];
  undefined4 uStack_1c;
  undefined4 uStack_18;
  undefined1 auStack_14 [2];
  undefined1 auStack_12 [10];
  
  .glue::GetPort(&uStack_1c);
  .glue::SetPort(param_1);
  .glue::GetDialogItem(param_1,param_2,auStack_14,&uStack_18,auStack_12);
  .glue::GetForeColor(auStack_22);
  uStack_28 = 0xffff;
  uStack_26 = 0xffff;
  uStack_24 = 0xffff;
  .glue::RGBForeColor(&uStack_28);
  .glue::FrameRect(auStack_12);
  uStack_28 = 0x5000;
  uStack_26 = 0x5000;
  uStack_24 = 0x5000;
  .glue::RGBForeColor(&uStack_28);
  .glue::OffsetRect(auStack_12,0xffffffff,0xffffffff);
  .glue::FrameRect(auStack_12);
  .glue::RGBForeColor(auStack_22);
  .glue::SetPort(uStack_1c);
  .glue::GetDialogItem(param_1,3,auStack_14,&uStack_18,auStack_12);
  .glue::Draw1Control(uStack_18);
  return;
}


// ==== .PrefDialogFilter @ 10075990 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 _PrefDialogFilter(int param_1,ushort *param_2,short *param_3)

{
  ushort uVar1;
  undefined *puVar2;
  undefined *puVar3;
  short sVar4;
  undefined4 uVar5;
  short sVar6;
  char cVar7;
  int iVar8;
  short sStack_46;
  undefined4 uStack_44;
  undefined4 uStack_40;
  undefined1 auStack_3c [8];
  undefined4 uStack_34;
  undefined1 auStack_30 [8];
  undefined4 uStack_28;
  undefined1 auStack_24 [16];
  
  puVar3 = PTR_DAT_100a0b6c;
  puVar2 = PTR_DAT_100a0b64;
  .debug::_MusicAIFFTickle();
  uVar1 = *param_2;
  if (uVar1 == 3) {
    if (_DAT_100a694c != 2) {
      cVar7 = (char)*(undefined4 *)(param_2 + 1);
      if ((((param_2[7] & 0x100) != 0) && (cVar7 == '.')) || (cVar7 == '\x1b')) {
        *param_3 = 2;
        .glue::GetDialogItem(param_1,2,auStack_24,&uStack_28,auStack_30);
        .glue::HiliteControl(uStack_28,1);
        return 1;
      }
      if ((cVar7 == '\r') || (cVar7 == '\x03')) {
        *param_3 = 1;
        .glue::GetDialogItem(param_1,1,auStack_24,&uStack_28,auStack_30);
        .glue::HiliteControl(uStack_28,1);
        return 1;
      }
    }
    if (*(short *)(param_1 + 0xa4) < 0) {
      sVar4 = -1;
    }
    else {
      sVar4 = *(short *)(param_1 + 0xa4) + 1;
    }
    iVar8 = (int)sVar4;
    if (iVar8 < 1) {
      uVar5 = 0;
    }
    else {
      cVar7 = .debug::_AlreadyUsingKey
                        ((ushort)((uint)*(undefined4 *)(param_2 + 1) >> 8) & 0xff,iVar8 + -7);
      if (cVar7 == '\0') {
        *(ushort *)(puVar3 + iVar8 * 2 + 4) =
             (ushort)((uint)*(undefined4 *)(param_2 + 1) >> 8) & 0xff;
        .debug::_ConvertKeyName((int)*(short *)(puVar3 + iVar8 * 2 + 4),param_1,(int)sVar4);
        if (iVar8 < 0xf) {
          sVar4 = sVar4 + 1;
        }
        else {
          sVar4 = 7;
        }
        .glue::SelectDialogItemText(param_1,(int)sVar4,0,0x7fff);
      }
      else {
        .glue::GetPort(&uStack_34);
        .debug::_ReportDialog(&DAT_100a694e);
        .glue::SetPort(uStack_34);
      }
      uVar5 = 1;
    }
    return uVar5;
  }
  if (uVar1 < 3) {
    if (uVar1 == 1) {
      uStack_40 = *(undefined4 *)(param_2 + 5);
      .glue::GlobalToLocal(&uStack_40);
      iVar8 = .glue::CountDITL(param_1);
      do {
        sVar4 = (short)iVar8;
        if (sVar4 < 0) {
          return 0;
        }
        .glue::GetDialogItem(param_1,iVar8,&sStack_46,&uStack_44,auStack_3c);
        cVar7 = .glue::PtInRect(uStack_40,auStack_3c);
        if (cVar7 != '\0') {
          if (sStack_46 == 7) {
            sVar6 = .glue::TrackControl(uStack_44,uStack_40,0xffffffff);
            if (sVar6 != 0) {
              *param_3 = sVar4;
            }
            return 1;
          }
          if (sStack_46 < 7) {
            if (sStack_46 == 5) {
              sVar6 = .glue::TrackControl(uStack_44,uStack_40,0);
              if (sVar6 != 0) {
                *param_3 = sVar4;
              }
              return 1;
            }
            if (4 < sStack_46) {
              sVar6 = .glue::TrackControl(uStack_44,uStack_40,0);
              if (sVar6 != 0) {
                *param_3 = sVar4;
              }
              return 1;
            }
            if (3 < sStack_46) {
              sVar6 = .glue::TrackControl(uStack_44,uStack_40,0);
              if (sVar6 != 0) {
                *param_3 = sVar4;
              }
              return 1;
            }
          }
          else if (sStack_46 == 0x10) {
            .glue::SelectDialogItemText(param_1,iVar8,0,0x7fff);
            return 1;
          }
        }
        iVar8 = iVar8 + -1;
      } while( true );
    }
  }
  else if (uVar1 == 5) {
    return 1;
  }
  uVar1 = param_2[7];
  if ((uVar1 & 0xff00) == 0) {
    *(undefined2 *)puVar2 = 0;
    return 0;
  }
  if (*(short *)(param_1 + 0xa4) < 0) {
    sVar4 = -1;
  }
  else {
    sVar4 = *(short *)(param_1 + 0xa4) + 1;
  }
  iVar8 = (int)sVar4;
  if (0 < iVar8) {
    if ((uVar1 & 0x100) == 0) {
      if ((uVar1 & 0x200) == 0) {
        if ((uVar1 & 0x800) == 0) {
          if ((uVar1 & 0x1000) == 0) {
            *(undefined2 *)puVar2 = 0;
          }
          else if ((*(short *)puVar2 != 0x3b) &&
                  (cVar7 = .debug::_AlreadyUsingKey(0x3b,iVar8 + -7), cVar7 == '\0')) {
            *(undefined2 *)(puVar3 + iVar8 * 2 + 4) = 0x3b;
            *(undefined2 *)puVar2 = 0x3b;
            .debug::_ConvertKeyName((int)*(short *)(puVar3 + iVar8 * 2 + 4),param_1,(int)sVar4);
            if (iVar8 < 0xf) {
              sVar4 = sVar4 + 1;
            }
            else {
              sVar4 = 7;
            }
            .glue::SelectDialogItemText(param_1,(int)sVar4,0,0x7fff);
          }
        }
        else if ((*(short *)puVar2 != 0x3a) &&
                (cVar7 = .debug::_AlreadyUsingKey(0x3a,iVar8 + -7), cVar7 == '\0')) {
          *(undefined2 *)(puVar3 + iVar8 * 2 + 4) = 0x3a;
          *(undefined2 *)puVar2 = 0x3a;
          .debug::_ConvertKeyName((int)*(short *)(puVar3 + iVar8 * 2 + 4),param_1,(int)sVar4);
          if (iVar8 < 0xf) {
            sVar4 = sVar4 + 1;
          }
          else {
            sVar4 = 7;
          }
          .glue::SelectDialogItemText(param_1,(int)sVar4,0,0x7fff);
        }
      }
      else if ((*(short *)puVar2 != 0x38) &&
              (cVar7 = .debug::_AlreadyUsingKey(0x38,iVar8 + -7), cVar7 == '\0')) {
        *(undefined2 *)(puVar3 + iVar8 * 2 + 4) = 0x38;
        *(undefined2 *)puVar2 = 0x38;
        .debug::_ConvertKeyName((int)*(short *)(puVar3 + iVar8 * 2 + 4),param_1,(int)sVar4);
        if (iVar8 < 0xf) {
          sVar4 = sVar4 + 1;
        }
        else {
          sVar4 = 7;
        }
        .glue::SelectDialogItemText(param_1,(int)sVar4,0,0x7fff);
      }
    }
    else if ((*(short *)puVar2 != 0x37) &&
            (cVar7 = .debug::_AlreadyUsingKey(0x37,iVar8 + -7), cVar7 == '\0')) {
      *(undefined2 *)(puVar3 + iVar8 * 2 + 4) = 0x37;
      *(undefined2 *)puVar2 = 0x37;
      .debug::_ConvertKeyName((int)*(short *)(puVar3 + iVar8 * 2 + 4),param_1,(int)sVar4);
      if (iVar8 < 0xf) {
        sVar4 = sVar4 + 1;
      }
      else {
        sVar4 = 7;
      }
      .glue::SelectDialogItemText(param_1,(int)sVar4,0,0x7fff);
    }
    return 0;
  }
  return 0;
}


// ==== .SetupRoachSprite @ 10077914 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupRoachSprite(int param_1)

{
  short *psVar1;
  char *pcVar2;
  int *piVar3;
  undefined4 *puVar4;
  undefined *puVar5;
  undefined *puVar6;
  undefined *puVar7;
  int iVar8;
  int iVar9;
  
  iVar9 = _DAT_100a0b7c;
  .debug::_InitSprite();
  puVar5 = PTR_PTR_100a04a0;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar7 = PTR_PTR_100a0b74;
  *(undefined2 *)(param_1 + 0x86) = 0;
  puVar6 = PTR_PTR_100a0b70;
  *(undefined4 *)(param_1 + 0x80) = 0xb;
  *(undefined **)(param_1 + 0x4c) = puVar5;
  iVar8 = _DAT_100a0b78;
  *(undefined **)(param_1 + 0x5c) = puVar7;
  *(undefined **)(param_1 + 0x1f8) = puVar6;
  *(undefined2 *)(param_1 + 0xa6) = 3;
  *(undefined2 *)(param_1 + 0xb0) = 2;
  *(undefined2 *)(param_1 + 0x110) = 0x151;
  *(undefined1 *)(iVar9 + 1) = 1;
  *(undefined1 *)(iVar8 + 1) = 1;
  *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar9 + 4);
  *(undefined2 *)(param_1 + 0xa4) = 200;
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  .glue::SetRect(param_1 + 0x34,0x23,0x1b,0x44,0x2d);
  puVar4 = _DAT_100a0058;
  *(undefined4 *)(param_1 + 0x150) = 0xffffffff;
  psVar1 = (short *)(*(int *)*puVar4 + *(short *)(param_1 + 0x48) * 0x10 + 0xc);
  if (*psVar1 == 0) {
    *psVar1 = 0xaa;
  }
  pcVar2 = _DAT_1009fe8c;
  *(int *)(param_1 + 0x154) = (int)*(short *)(param_1 + 8);
  *(undefined4 *)(param_1 + 0x24) = 0x4b0;
  piVar3 = _DAT_1009ffb4;
  if (*pcVar2 != '\0') {
    *(undefined1 *)(param_1 + 0x1b5) = 1;
    *piVar3 = *piVar3 + 1;
  }
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  return;
}


// ==== .HandleRoachSprite @ 10077a88 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleRoachSprite(int param_1)

{
  short *psVar1;
  undefined4 uVar2;
  undefined4 *puVar3;
  uint uVar4;
  short sVar5;
  short sVar8;
  short sVar9;
  int iVar6;
  int iVar7;
  bool bVar10;
  undefined4 uStack_28;
  
  uVar2 = _DAT_1009ff38;
  psVar1 = _DAT_1009fd94;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b2) == '\0')) {
    .debug::_StandardSpriteHandles(param_1);
    *(undefined4 *)(param_1 + 0x80) = 0xb;
    if (*(short *)(param_1 + 0xb0) != 1) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (0xb < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0;
      }
      *(undefined4 *)(param_1 + 0xc0) =
           *(undefined4 *)(_DAT_100a0b7c + ((int)*(short *)(param_1 + 0x46) >> 1) * 4 + 4);
    }
    sVar8 = *(short *)(param_1 + 0xb0);
    if (sVar8 == 3) {
      *(undefined2 *)(param_1 + 0x110) = 0x151;
      if ((*(short *)(param_1 + 0xa6) == 0) && (*(char *)(param_1 + 0xce) != '\0')) {
        iVar6 = .debug::_FastRand(400);
        .debug::_SetSpriteSpeed(param_1,0,-900 - iVar6);
        iVar6 = .debug::_FastRand(800);
        .debug::_AccelerateBasedOnSlope(param_1,-0x6a4 - iVar6,2000);
        *(undefined4 *)(param_1 + 0x14c) = *(undefined4 *)(param_1 + 0x24);
        if (*psVar1 < *(short *)(param_1 + 0x10)) {
          iVar6 = *(int *)(param_1 + 0x24);
          *(int *)(param_1 + 0x24) = -iVar6;
          *(int *)(param_1 + 0x14c) = -iVar6;
        }
        sVar8 = .debug::_FastRand(0x1e);
        *(short *)(param_1 + 0xa6) = sVar8 + 0x14;
      }
      if (*(char *)(param_1 + 0xce) == '\0') {
        *(undefined4 *)(param_1 + 0x24) = *(undefined4 *)(param_1 + 0x14c);
      }
      else {
        sVar8 = *psVar1;
        if ((*(short *)(param_1 + 0x10) < sVar8) &&
           (uVar4 = *(uint *)(param_1 + 0x24), (int)uVar4 < 0)) {
          *(uint *)(param_1 + 0x24) = ((int)uVar4 >> 1) + (uint)((int)uVar4 < 0 && (uVar4 & 1) != 0)
          ;
        }
        else if ((sVar8 < *(short *)(param_1 + 0x10)) &&
                (uVar4 = *(uint *)(param_1 + 0x24), 300 < (int)uVar4)) {
          *(uint *)(param_1 + 0x24) = ((int)uVar4 >> 1) + (uint)((int)uVar4 < 0 && (uVar4 & 1) != 0)
          ;
        }
        else {
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
        }
        if (*(short *)(param_1 + 0xa4) < 3) {
          *(undefined2 *)(param_1 + 0xb0) = 3;
        }
      }
    }
    else if (sVar8 < 3) {
      if ((1 < sVar8) &&
         (*(undefined2 *)(param_1 + 0x110) = 0x151, *(char *)(param_1 + 0xce) != '\0')) {
        bVar10 = false;
        uVar4 = (uint)*(short *)(*(int *)*_DAT_100a0058 + *(short *)(param_1 + 0x48) * 0x10 + 0xc);
        iVar6 = ((int)uVar4 >> 1) + (uint)((int)uVar4 < 0 && (uVar4 & 1) != 0);
        if ((int)*(short *)(param_1 + 0x10) < *(int *)(param_1 + 0x154) - iVar6) {
          .debug::_AccelerateBasedOnSlope(param_1,100,0x4b0);
          *(undefined1 *)(param_1 + 0x17e) = 1;
          bVar10 = true;
        }
        else if (*(int *)(param_1 + 0x154) + iVar6 < (int)*(short *)(param_1 + 0x10)) {
          .debug::_AccelerateBasedOnSlope(param_1,0xffffff9c,0x4b0);
          *(undefined1 *)(param_1 + 0x17e) = 0;
          bVar10 = true;
        }
        if (!bVar10) {
          if ((*(char *)(param_1 + 0x17e) == '\0') && (-0x4b0 < *(int *)(param_1 + 0x24))) {
            .debug::_AccelerateBasedOnSlope(param_1,0xffffff9c,0x4b0);
          }
          else if ((*(char *)(param_1 + 0x17e) != '\0') && (0x4b0 < *(int *)(param_1 + 0x24))) {
            .debug::_AccelerateBasedOnSlope(param_1,100,0x4b0);
          }
        }
        if (0 < *(short *)(param_1 + 0xa6)) {
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
        }
      }
    }
    else if (sVar8 < 5) {
      *(undefined2 *)(param_1 + 0x110) = 0x151;
    }
    if (*(short *)(param_1 + 0xa4) < 1) {
      *(undefined2 *)(param_1 + 0xb0) = 4;
    }
    if (*(short *)(param_1 + 0xb0) == 4) {
      sVar8 = .debug::_FastRand(3);
      *(undefined4 *)(param_1 + 0x5c) = 0;
      if (*(int *)(param_1 + 0x150) == -1) {
        *(undefined4 *)(param_1 + 0x150) = 1;
      }
      if (0 < *(int *)(param_1 + 0x150)) {
        *(int *)(param_1 + 0x150) = *(int *)(param_1 + 0x150) + 1;
        sVar5 = (short)(*(int *)(param_1 + 0x150) + -2 >> 1);
        if (5 < sVar5) {
          sVar5 = 5;
        }
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0b78 + sVar5 * 4 + 4);
        if (0x15 < *(int *)(param_1 + 0x150)) {
          .debug::_STPlay3DSound(*_DAT_100a026c,1,0x100,*(undefined4 *)(param_1 + 0xe));
          *(undefined4 *)(param_1 + 0xc0) = 0;
          .debug::_KillRoach(param_1);
          *_DAT_1009ffc0 = *_DAT_1009ffc0 + 500;
          for (sVar5 = 0; sVar5 < (short)(sVar8 + 2); sVar5 = sVar5 + 1) {
            iVar6 = .debug::_MTNewSprite
                              (0x516,*(short *)(param_1 + 0x10) + -4,*(short *)(param_1 + 0xe) + -4,
                               2,0xffffffff,uVar2);
            sVar9 = .debug::_FastRand(0x640);
            *(int *)(iVar6 + 0x2c) = -0x578 - sVar9;
            sVar9 = .debug::_FastRand(1000);
            *(int *)(iVar6 + 0x24) = sVar9 + -500;
          }
          for (sVar8 = 0; sVar8 < 100; sVar8 = sVar8 + 1) {
            uStack_28 = CONCAT22(*(short *)(param_1 + 0xe) + 6,*(short *)(param_1 + 0x10) + -1);
            iVar6 = .debug::_FastRand(700);
            iVar7 = .debug::_FastRand(600);
            .debug::_NewParticle(2,0x50,uStack_28,4,iVar7 + -300,-0x15e - iVar6,0,1);
          }
        }
      }
    }
    .debug::_ApplyGravityAndSeparateFromTiles(param_1);
    puVar3 = _DAT_100a0274;
    if (((*(int *)(param_1 + 0x11c) != 0) &&
        (((*(int *)(param_1 + 0x11c) == 1 && (*(short *)(param_1 + 0x128) == 0)) ||
         (0 < *(short *)(param_1 + 0x128))))) && (*(short *)(param_1 + 0x116) == 0)) {
      *(undefined2 *)(param_1 + 0x116) = 0x13;
      *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -100;
      *(undefined2 *)(param_1 + 0xaa) = 0x11;
      .debug::_STPlay3DSound(*puVar3,1,0x55,*(undefined4 *)(param_1 + 0xe));
    }
    .debug::_StandardSpriteCleanup(param_1);
  }
  return;
}


// ==== .HitRoachSprite @ 1007801c ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitRoachSprite(int param_1,int param_2)

{
  undefined4 *puVar1;
  undefined4 *puVar2;
  char cVar4;
  short sVar3;
  undefined *puVar5;
  short sStack_18;
  short sStack_16;
  
  puVar2 = _DAT_100a0274;
  puVar1 = _DAT_100a0270;
  puVar5 = *(undefined **)(param_2 + 0x4c);
  if ((puVar5 != PTR_PTR_100a04e8) || (*(short *)(param_2 + 0xa6) != 0)) {
    if ((puVar5 == PTR_PTR_100a01f8) || (puVar5 == PTR_PTR_100a0484)) {
      sStack_16 = *(short *)(param_1 + 0x36) +
                  (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
      sStack_18 = *(short *)(param_1 + 0x34) +
                  (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
      sVar3 = .debug::_PlatformBounce(param_1,param_2,&sStack_18,0,param_1 + 0x34,0);
      if (sVar3 != 2) {
        return;
      }
      if ((*(int *)(param_2 + 0x2c) < 1) && (*(char *)(param_1 + 0xce) == '\0')) {
        return;
      }
      *(undefined2 *)(param_1 + 0xa4) = 0;
      *(undefined4 *)(param_1 + 0x150) = 0x16;
      return;
    }
    if (((puVar5 != PTR_PTR_100a0460) || (*(short *)(param_2 + 4) != 0x4b7)) ||
       (7 < *(short *)(param_2 + 0x46))) {
      if (*(short *)(param_2 + 4) != 0x5a0) {
        return;
      }
      if ((*(int *)(param_2 + 0x14c) != 1) && (*(int *)(param_2 + 0x14c) != 2)) {
        return;
      }
    }
    cVar4 = .debug::_HurtSprite(param_1,100,(int)(short)(*(int *)(param_2 + 0x24) >> 1),0xfffffc18,4
                                ,8);
    if (cVar4 != '\0') {
      .debug::_BloodSpray(param_1,param_2,0x28,400,0x96,2);
      if (*(short *)(param_1 + 0xa4) < 3) {
        .debug::_STPlay3DSound(*puVar1,1,0x100,*(undefined4 *)(param_1 + 0xe));
      }
      else if (0 < *(short *)(param_1 + 0xa4)) {
        .debug::_STPlay3DSound(*puVar2,1,0x100,*(undefined4 *)(param_1 + 0xe));
      }
    }
    return;
  }
  .debug::_KillPlayerShot(param_2,0,0);
  if (*(short *)(param_2 + 4) == 1) {
    .debug::_TurnIntoStatue(param_1);
    return;
  }
  cVar4 = .debug::_HurtSprite(param_1,(int)*(short *)(param_2 + 0xa4),
                              (int)(short)(*(int *)(param_2 + 0x24) >> 1),0xfffffc18,4,8);
  if (cVar4 == '\0') {
    return;
  }
  .debug::_BloodSpray(param_1,param_2,0x28,400,0x96,2);
  if (*(short *)(param_1 + 0xa4) < 3) {
    .debug::_STPlay3DSound(*puVar1,1,0x100,*(undefined4 *)(param_1 + 0xe));
    return;
  }
  if (*(short *)(param_1 + 0xa4) < 1) {
    return;
  }
  .debug::_STPlay3DSound(*puVar2,1,0x100,*(undefined4 *)(param_1 + 0xe));
  return;
}


// ==== .HitRoachTileSprite @ 10078384 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitRoachTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  char cVar1;
  short sStack_48;
  short sStack_46;
  undefined1 auStack_28 [28];
  
  sStack_46 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_48 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  if ((*_DAT_100a0064 != '\0') && (cVar1 = .debug::_IsPressed(0x32), cVar1 != '\0')) {
    return;
  }
  .glue::SetRect(auStack_28,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                 (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
  if (param_4 == 1) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 100) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 200) {
    .debug::_WallBounceBG(param_1,param_3 + -100,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else {
    cVar1 = .debug::_IsWaterTile(param_3);
    if ((cVar1 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
      .debug::_HandleUnderWater(param_1,param_2);
    }
  }
  return;
}


// ==== .SetupBlobSprite @ 1007cdb0 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupBlobSprite(int param_1)

{
  short sVar1;
  char *pcVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  undefined *puVar6;
  
  puVar6 = PTR_DAT_100a0c64;
  .debug::_InitSprite();
  puVar3 = PTR_PTR_100a04c0;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar5 = PTR_PTR_100a0c60;
  *(undefined2 *)(param_1 + 0x86) = 0;
  puVar4 = PTR_PTR_100a0c5c;
  *(undefined4 *)(param_1 + 0x80) = 8;
  *(undefined **)(param_1 + 0x4c) = puVar3;
  *(undefined **)(param_1 + 0x5c) = puVar5;
  *(undefined **)(param_1 + 0x1f8) = puVar4;
  *(undefined2 *)(param_1 + 0x110) = 0xfa;
  *(undefined4 *)(param_1 + 0xc0) = 0;
  sVar1 = *(short *)(param_1 + 4);
  if (sVar1 == 0x6c4) {
    *(undefined2 *)(param_1 + 0xa4) = 0x5dc;
    *(undefined4 *)(param_1 + 0xb8) = 0x1000c;
  }
  else if (sVar1 < 0x6c4) {
    if (sVar1 == 0x6c2) {
      *(undefined2 *)(param_1 + 0xa4) = 700;
      *(undefined4 *)(param_1 + 0xb8) = 0;
    }
    else if (0x6c1 < sVar1) {
      *(undefined2 *)(param_1 + 0xa4) = 0x44c;
      *(undefined4 *)(param_1 + 0xb8) = 0x10004;
    }
  }
  else if (sVar1 < 0x6c6) {
    *(undefined2 *)(param_1 + 0xa4) = 2000;
    *(undefined4 *)(param_1 + 0xb8) = 0x1000f;
  }
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  .glue::SetRect(param_1 + 0x34,0xe,0xc,0x2f,0x21);
  pcVar2 = _DAT_1009fe8c;
  *(undefined4 *)(param_1 + 0x150) = 0xffffffff;
  *(undefined2 *)(param_1 + 0xb0) = 6;
  *(undefined2 *)(param_1 + 0xb2) = 0;
  *(undefined2 *)(param_1 + 0x46) = 2;
  *(undefined4 *)(param_1 + 0x14c) = 0;
  puVar6[1] = 1;
  *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar6 + 4);
  if (*pcVar2 != '\0') {
    *(undefined1 *)(param_1 + 0x1b5) = 1;
    *_DAT_1009ffb4 = *_DAT_1009ffb4 + 1;
  }
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  return;
}


// ==== .HandleDeadBlobSprite @ 1007cf64 ====

void _HandleDeadBlobSprite(int param_1)

{
  *(int *)(param_1 + 0x15c) = *(int *)(param_1 + 0x15c) + 1;
  *(undefined2 *)(param_1 + 0xaa) = 0;
  *(undefined1 *)(param_1 + 0xea) = 1;
  if (0x3c < *(int *)(param_1 + 0x15c)) {
    *(undefined1 *)(param_1 + 0x88) = 0;
  }
  if (0x42 < *(int *)(param_1 + 0x15c)) {
    *(undefined4 *)(param_1 + 0xb8) = 0xb0001;
  }
  if (0x48 < *(int *)(param_1 + 0x15c)) {
    *(undefined4 *)(param_1 + 0xb8) = 0xb0000;
  }
  if (0x4e < *(int *)(param_1 + 0x15c)) {
    *(undefined4 *)(param_1 + 0xb8) = 0xb0002;
  }
  if (0x54 < *(int *)(param_1 + 0x15c)) {
    .debug::_KillBlob(param_1);
    *(undefined4 *)(param_1 + 0xc0) = 0;
  }
  return;
}


// ==== .HandleBlobSprite @ 1007d044 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleBlobSprite(int param_1)

{
  ushort uVar1;
  ushort uVar2;
  bool bVar3;
  uint uVar4;
  ushort *puVar5;
  int *piVar6;
  undefined4 *puVar7;
  undefined *puVar8;
  int iVar9;
  short sVar10;
  undefined2 uVar11;
  short sVar12;
  undefined8 uStack_28;
  undefined8 uStack_20;
  
  puVar8 = PTR_DAT_100a0c64;
  puVar5 = _DAT_1009fd94;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b2) == '\0')) {
    .debug::_StandardSpriteHandles(param_1);
    if (*(short *)(param_1 + 0x10) < (short)*puVar5) {
      *(undefined1 *)(param_1 + 0x17e) = 1;
    }
    else if ((short)*puVar5 < *(short *)(param_1 + 0x10)) {
      *(undefined1 *)(param_1 + 0x17e) = 0;
    }
    piVar6 = _DAT_1009ffc0;
    sVar12 = *(short *)(param_1 + 0xb0);
    if (sVar12 == 4) {
      if (*(int *)(param_1 + 0x14c) == -1) {
        bVar3 = false;
        *(undefined2 *)(param_1 + 0x46) = 0;
        puVar7 = _DAT_100a026c;
        *piVar6 = *piVar6 + 200;
        .debug::_STPlay3DSound(*puVar7,1,0x100,*(undefined4 *)(param_1 + 0xe));
        sVar12 = *(short *)(param_1 + 0x48);
        if ((-1 < sVar12) && (sVar12 < 0x1ff)) {
          bVar3 = true;
        }
        if (bVar3) {
          *(undefined1 *)(*(int *)*_DAT_100a0058 + sVar12 * 0x10 + 4) = 0;
        }
      }
      *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + 1;
      uStack_28 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
      *(int *)(param_1 + 0x24) = (int)((uStack_28 - dRam100a1b70) * dRam100a1b78);
      iVar9 = *(int *)(param_1 + 0x24);
      if (iVar9 < 1) {
        iVar9 = -iVar9;
      }
      if (iVar9 < 200) {
        *(undefined4 *)(param_1 + 0x24) = 0;
      }
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (0x13 < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0x14;
        if ((*(int *)(param_1 + 0x2c) == 0) || (*(char *)(param_1 + 0xcd) != '\0')) {
          *(undefined **)(param_1 + 0x4c) = PTR_PTR_100a0c58;
        }
        *(undefined4 *)(param_1 + 0x5c) = 0;
      }
    }
    else if (sVar12 < 4) {
      if (sVar12 == 2) {
        uVar1 = *puVar5;
        uVar2 = *(ushort *)(param_1 + 0x10);
        iVar9 = -(~(int)(short)(uVar1 ^ uVar2) >> 0x1f);
        uVar4 = iVar9 + (uint)(uVar1 <= uVar2) & 1;
        if ((((iVar9 + (uint)(uVar1 <= uVar2) & 1) != *(uint *)(param_1 + 0x14c)) ||
            ((uVar4 != 0 && (*(int *)(param_1 + 0x24) < 0)))) ||
           ((uVar4 == 0 && (0 < *(int *)(param_1 + 0x24))))) {
          *(undefined2 *)(param_1 + 0xb0) = 5;
        }
        *(uint *)(param_1 + 0x14c) = uVar4;
        if (*(short *)(param_1 + 0xa6) == 0) {
          if (*(short *)(param_1 + 0x10) < (short)*puVar5) {
            sVar12 = 400;
          }
          else {
            sVar12 = -400;
          }
          if (*(short *)(param_1 + 0x46) < 0x14) {
            if (*(short *)(param_1 + 0x46) == 4) {
              sVar10 = .debug::_FastRand(30000);
              .debug::_STPlay3DSoundPitched
                        (*_DAT_100a02ac,1,0x55,*(undefined4 *)(param_1 + 0xe),sVar10 + 50000);
            }
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
          }
          sVar10 = *(short *)(param_1 + 0x46);
          if ((sVar10 < 8) || (0xd < sVar10)) {
            if ((0xd < sVar10) && (sVar10 < 0x14)) {
              *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) - (int)sVar12;
            }
          }
          else {
            *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + (int)sVar12;
          }
          if (*(short *)(param_1 + 0x46) == 0x14) {
            *(undefined2 *)(param_1 + 0x46) = 0;
            uVar11 = .debug::_FastRand(0x14);
            *(undefined2 *)(param_1 + 0xa6) = uVar11;
            sVar12 = .debug::_FastRand(100);
            if (0x5c < sVar12) {
              *(undefined2 *)(param_1 + 0xb0) = 6;
            }
          }
        }
        else {
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
        }
      }
    }
    else if (sVar12 == 6) {
      *(undefined1 *)(param_1 + 0x17e) = 0;
      if (0 < *(short *)(param_1 + 0xa6)) {
        *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
      }
      if (*(short *)(param_1 + 0xb2) == 1) {
        if (*(short *)(param_1 + 0xa6) == 1) {
          *(undefined2 *)(param_1 + 0xb2) = 0;
        }
        else if ((*(short *)(param_1 + 0xa6) == 0) &&
                (*(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1,
                *(short *)(param_1 + 0x46) < 3)) {
          *(undefined2 *)(param_1 + 0x46) = 2;
          sVar12 = .debug::_FastRand(0xe);
          *(short *)(param_1 + 0xa6) = sVar12 + 2;
        }
      }
      else {
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (8 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 9;
          *(undefined2 *)(param_1 + 0xb2) = 1;
        }
      }
      iVar9 = (int)(short)*puVar5 - (int)*(short *)(param_1 + 0x10);
      if (iVar9 < 1) {
        iVar9 = -iVar9;
      }
      if (iVar9 < 200) {
        iVar9 = (int)*_DAT_1009fd90 - (int)*(short *)(param_1 + 0xe);
        if (iVar9 < 1) {
          iVar9 = -iVar9;
        }
        if (((iVar9 < 0xdc) && (*(short *)(param_1 + 0xe) + -0x80 < (int)*_DAT_1009fd90)) &&
           (*(short *)(param_1 + 0xa6) == 1)) {
          *(undefined2 *)(param_1 + 0xa6) = 0;
          *(undefined2 *)(param_1 + 0xb0) = 2;
        }
      }
      uStack_20 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
      *(int *)(param_1 + 0x24) = (int)((uStack_20 - dRam100a1b70) * dRam100a1b78);
      if (*(int *)(param_1 + 0x24) < 100) {
        *(undefined4 *)(param_1 + 0x24) = 0;
      }
    }
    else if (sVar12 < 6) {
      uStack_28 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
      *(int *)(param_1 + 0x24) = (int)((uStack_28 - dRam100a1b70) * dRam100a1b78);
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (0x13 < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0;
      }
      iVar9 = *(int *)(param_1 + 0x24);
      if (iVar9 < 1) {
        iVar9 = -iVar9;
      }
      if (iVar9 < 200) {
        *(undefined4 *)(param_1 + 0x24) = 0;
        *(undefined2 *)(param_1 + 0xb0) = 2;
      }
    }
    if (*(short *)(param_1 + 0xa4) < 1) {
      *(undefined2 *)(param_1 + 0xb0) = 4;
    }
    .debug::_ApplyGravityAndSeparateFromTiles(param_1);
    puVar7 = _DAT_100a0274;
    if ((*(int *)(param_1 + 0x11c) != 0) &&
       (((*(int *)(param_1 + 0x11c) == 1 && (*(short *)(param_1 + 0x128) == 0)) ||
        (0 < *(short *)(param_1 + 0x128))))) {
      sVar12 = *(short *)(param_1 + 0x128);
      if (sVar12 == 3) {
        if (*(short *)(param_1 + 0xa4) < 500) {
          *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + 4;
        }
      }
      else if (((sVar12 < 3) && (1 < sVar12)) && (*(short *)(param_1 + 0x116) == 0)) {
        *(undefined2 *)(param_1 + 0x116) = 0x13;
        *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -100;
        *(undefined2 *)(param_1 + 0xaa) = 0x11;
        .debug::_STPlay3DSound(*puVar7,1,0x55,*(undefined4 *)(param_1 + 0xe));
      }
    }
    if (*(short *)(param_1 + 0xb0) == 4) {
      *(undefined4 *)(param_1 + 0xc0) =
           *(undefined4 *)(puVar8 + ((int)*(short *)(param_1 + 0x46) >> 2) * 4 + 0x2c);
    }
    else {
      *(undefined4 *)(param_1 + 0xc0) =
           *(undefined4 *)(puVar8 + ((int)*(short *)(param_1 + 0x46) >> 1) * 4 + 4);
    }
    .debug::_StandardSpriteCleanup(param_1);
  }
  return;
}


// ==== .HitBlobSprite @ 1007d6e0 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitBlobSprite(int param_1,int param_2)

{
  char cVar2;
  short sVar1;
  undefined *puVar3;
  short sStack_18;
  short sStack_16;
  
  puVar3 = *(undefined **)(param_2 + 0x4c);
  if (((puVar3 == PTR_PTR_100a04e8) && (*(short *)(param_2 + 0xa6) == 0)) &&
     (0 < *(short *)(param_1 + 0xa4))) {
    .debug::_KillPlayerShot(param_2,0,0);
    if (*(short *)(param_2 + 4) == 1) {
      .debug::_TurnIntoStatue(param_1);
    }
    else {
      cVar2 = .debug::_HurtSprite(param_1,(int)*(short *)(param_2 + 0xa4),
                                  (int)(short)(*(int *)(param_2 + 0x24) >> 1),0xfffffc18,2,8);
      if (cVar2 != '\0') {
        *(undefined2 *)(param_1 + 0xb0) = 5;
        .debug::_BloodSpray(param_1,param_2,0x28,400,0x96,0xc9);
        if (*(short *)(param_1 + 0xa4) < 0xc9) {
          .debug::_STPlay3DSound(*_DAT_100a0270,1,0x100,*(undefined4 *)(param_1 + 0xe));
        }
        else if (0 < *(short *)(param_1 + 0xa4)) {
          .debug::_STPlay3DSound(*_DAT_100a0274,1,0x100,*(undefined4 *)(param_1 + 0xe));
        }
      }
    }
  }
  else if ((puVar3 == PTR_PTR_100a01f8) || (puVar3 == PTR_PTR_100a0484)) {
    sStack_16 = *(short *)(param_1 + 0x36) +
                (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
    sStack_18 = *(short *)(param_1 + 0x34) +
                (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
    sVar1 = .debug::_PlatformBounce(param_1,param_2,&sStack_18,0,param_1 + 0x34,0);
    if ((sVar1 == 2) && ((0 < *(int *)(param_2 + 0x2c) || (*(char *)(param_1 + 0xce) != '\0')))) {
      *(undefined2 *)(param_1 + 0xa4) = 0;
      *(undefined4 *)(param_1 + 0x150) = 0x16;
    }
  }
  return;
}


// ==== .HitBlobTileSprite @ 1007d968 ====

void _HitBlobTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  char cVar1;
  short sStack_48;
  short sStack_46;
  undefined1 auStack_28 [28];
  
  sStack_46 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_48 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  .glue::SetRect(auStack_28,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                 (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
  if (param_4 == 1) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 100) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 200) {
    .debug::_WallBounceBG(param_1,param_3 + -100,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else {
    cVar1 = .debug::_IsWaterTile(param_3);
    if ((cVar1 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
      .debug::_HandleUnderWater(param_1,param_2);
    }
  }
  return;
}


// ==== .SetupBatSprite @ 1007dc30 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupBatSprite(int param_1)

{
  short sVar1;
  int *piVar2;
  char *pcVar3;
  int *piVar4;
  undefined4 *puVar5;
  undefined *puVar6;
  undefined *puVar7;
  undefined *puVar8;
  undefined *puVar9;
  short sVar10;
  short sVar14;
  undefined4 uVar11;
  int iVar12;
  int iVar13;
  int iVar15;
  short sVar16;
  int iVar17;
  uint uVar18;
  
  iVar17 = _DAT_100a0c8c;
  puVar7 = PTR_PTR_100a0c74;
  puVar5 = _DAT_100a0058;
  piVar4 = _DAT_1009ffb4;
  pcVar3 = _DAT_1009fe8c;
  .debug::_InitSprite();
  puVar6 = PTR_PTR_100a04c4;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar9 = PTR_PTR_100a0c7c;
  *(undefined2 *)(param_1 + 0x86) = 0;
  puVar8 = PTR_PTR_100a0c78;
  *(undefined4 *)(param_1 + 0x80) = 0xb;
  *(undefined **)(param_1 + 0x4c) = puVar6;
  *(undefined **)(param_1 + 0x5c) = puVar9;
  *(undefined **)(param_1 + 0x1f8) = puVar8;
  *(undefined2 *)(param_1 + 0x110) = 0;
  *(undefined4 *)(param_1 + 0xc0) = 0;
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  *(undefined4 *)(param_1 + 0x150) = 0xffffffff;
  sVar14 = *(short *)(param_1 + 4);
  if ((sVar14 < 0x6cc) || (0x6d5 < sVar14)) {
    if ((sVar14 < 0x73a) || (0x743 < sVar14)) {
      if (sVar14 == 0x74d) {
        *(undefined1 *)(_DAT_100a0c88 + 1) = 1;
        *(short *)(param_1 + 0xc) = *(short *)(param_1 + 0xc) + 0x40;
        *(short *)(param_1 + 10) = *(short *)(param_1 + 10) + 0x40;
        uVar11 = .debug::_AllocateGameMem(0x54);
        *(undefined4 *)(param_1 + 0x9c) = uVar11;
        if (*(int *)(param_1 + 0x9c) == 0) {
          .debug::_ReportError(&DAT_100a6db2,0);
          .glue::ExitToShell();
        }
        iVar15 = *(int *)*puVar5;
        iVar17 = *(short *)(param_1 + 0x48) * 0x10;
        sVar14 = *(short *)(iVar15 + iVar17 + 8);
        iVar12 = (int)sVar14;
        if (sVar14 == 0) {
          iVar12 = 0x74c;
        }
        sVar14 = *(short *)(iVar15 + iVar17 + 10);
        if (sVar14 == 0) {
          sVar14 = 8;
        }
        sVar10 = *(short *)(iVar15 + iVar17 + 0xc);
        if (sVar10 == 0) {
          sVar10 = 0x4b;
        }
        uVar18 = (uint)sVar10;
        *(uint *)(param_1 + 0x154) = uVar18;
        iVar17 = 0;
        *(short *)(*(int *)(param_1 + 0x9c) + 0x50) = sVar14;
        *(short *)(*(int *)(param_1 + 0x9c) + 0x52) = sVar14;
        *(undefined2 *)(param_1 + 0xa4) = 100;
        *(undefined4 *)(param_1 + 0x5c) = 0;
        .glue::SetRect(param_1 + 0x34,0,0,0,0);
        sVar10 = (short)(uVar18 << 1);
        for (sVar16 = 0; sVar16 < sVar14; sVar16 = sVar16 + 1) {
          iVar15 = .debug::_FastRand((int)sVar10);
          sVar1 = *(short *)(param_1 + 10);
          iVar13 = .debug::_FastRand((int)sVar10);
          uVar11 = .debug::_MTNewSprite
                             (iVar12,(*(short *)(param_1 + 0xc) + iVar13) - uVar18,
                              (sVar1 + iVar15) - uVar18,*(int *)(param_1 + 0x80) + -1,0x200,puVar7);
          *(undefined4 *)(*(int *)(param_1 + 0x9c) + iVar17) = uVar11;
          *(int *)(*(int *)(*(int *)(param_1 + 0x9c) + iVar17) + 0x14c) =
               (int)*(short *)(param_1 + 0xc);
          piVar2 = (int *)(*(int *)(param_1 + 0x9c) + iVar17);
          iVar17 = iVar17 + 4;
          *(int *)(*piVar2 + 0x150) = (int)*(short *)(param_1 + 10);
        }
        if (*(short *)(*(int *)(param_1 + 0x9c) + 0x50) < 1) {
          *(undefined1 *)(param_1 + 0xe9) = 1;
        }
        sVar14 = (short)((int)uVar18 >> 1) + (ushort)((int)uVar18 < 0 && (uVar18 & 1) != 0);
        .glue::SetRect(param_1 + 0x34,(int)-sVar14,(int)-sVar14,(int)sVar14,(int)sVar14);
        if (*pcVar3 != '\0') {
          *(undefined1 *)(param_1 + 0x1b5) = 1;
          *piVar4 = *piVar4 + 1;
        }
      }
      else if ((0x743 < sVar14) && (sVar14 < 0x74e)) {
        .glue::SetRect(param_1 + 0x34,6,6,0x2a,0x26);
        puVar6 = PTR_PTR_100a0c70;
        *(undefined1 *)(iVar17 + 1) = 1;
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar17 + 0x10);
        *(undefined2 *)(param_1 + 0xa4) = 200;
        *(undefined2 *)(param_1 + 0xb0) = 7;
        *(undefined2 *)(param_1 + 0xa6) = 3;
        *(undefined2 *)(param_1 + 0x46) = 3;
        *(undefined4 *)(param_1 + 0xb8) = 0xb0004;
        *(undefined4 *)(param_1 + 0x158) = 0x28;
        *(undefined4 *)(param_1 + 0x15c) = 0;
        *(undefined1 *)(param_1 + 0x88) = 0;
        uVar11 = .debug::_MTNewSprite
                           ((int)*(short *)(param_1 + 4),(int)*(short *)(param_1 + 0xc),
                            (int)*(short *)(param_1 + 10),*(int *)(param_1 + 0x80) + -1,0x200,puVar6
                           );
        *(undefined4 *)(param_1 + 0x1d4) = uVar11;
        *(undefined **)(*(int *)(param_1 + 0x1d4) + 0x4c) = PTR_PTR_100a0c6c;
        if (*pcVar3 != '\0') {
          *(undefined1 *)(param_1 + 0x1b5) = 1;
          *piVar4 = *piVar4 + 1;
        }
      }
    }
    else {
      *(undefined1 *)(_DAT_100a0c84 + 1) = 1;
      *(undefined1 *)(param_1 + 0x188) = 1;
      *(undefined2 *)(param_1 + 0xa4) = 100;
      .glue::SetRect(param_1 + 0x34,0x10,0x1e,0x30,0x32);
      if (*(short *)(param_1 + 4) == 0x73c) {
        *(undefined1 *)(param_1 + 0x188) = 1;
        *(undefined2 *)(param_1 + 4) = 0x73b;
        *(undefined4 *)(param_1 + 0x14c) = 1;
        *(undefined4 *)(param_1 + 0xb8) = 0x1000c;
        sVar14 = .debug::_FastRand(0x50);
        *(int *)(param_1 + 0x154) = sVar14 + 0x32;
      }
      if (*(short *)(param_1 + 4) == 0x73a) {
        *(undefined2 *)(param_1 + 0xa6) = 0;
      }
      else if (*(short *)(param_1 + 4) == 0x73b) {
        *(undefined2 *)(param_1 + 0xa6) = 1;
        *(undefined2 *)(param_1 + 0x110) = 0;
        .debug::_SetupProgrammedPath(param_1,0xffffffff,0);
      }
      *(undefined4 *)(param_1 + 0x158) = 0x1e;
      *(undefined4 *)(param_1 + 0x15c) = 0;
      iVar17 = _DAT_100a0c80;
      if (*(short *)(*(int *)*puVar5 + *(short *)(param_1 + 0x48) * 0x10 + 8) < 0) {
        *(undefined4 *)(param_1 + 0x80) = 8;
        *(undefined4 *)(param_1 + 0x160) = 1;
        *(undefined1 *)(iVar17 + 1) = 1;
      }
      else {
        *(undefined4 *)(param_1 + 0x160) = 0;
        if (*pcVar3 != '\0') {
          *(undefined1 *)(param_1 + 0x1b5) = 1;
          *piVar4 = *piVar4 + 1;
        }
      }
      *(undefined2 *)(param_1 + 0xb0) = 7;
    }
  }
  else {
    *(undefined2 *)(param_1 + 0xa4) = 500;
    .glue::SetRect(param_1 + 0x34,0xc,0xf,0x2b,0x2f);
    if (*pcVar3 != '\0') {
      *(undefined1 *)(param_1 + 0x1b5) = 1;
      *piVar4 = *piVar4 + 1;
    }
    PTR_DAT_100a0c90[1] = 1;
    if (*(short *)(param_1 + 4) == 0x6ce) {
      *(undefined1 *)(param_1 + 0x188) = 1;
      *(undefined2 *)(param_1 + 4) = 0x6cd;
      *(undefined4 *)(param_1 + 0x14c) = 1;
      *(undefined4 *)(param_1 + 0xb8) = 0x1000c;
      sVar14 = .debug::_FastRand(0x50);
      *(int *)(param_1 + 0x154) = sVar14 + 0x32;
    }
    sVar14 = *(short *)(param_1 + 4);
    if (sVar14 == 0x6cc) {
      *(undefined2 *)(param_1 + 0xa6) = 0;
    }
    else if (sVar14 == 0x6cd) {
      *(undefined1 *)(param_1 + 0x188) = 1;
      *(undefined2 *)(param_1 + 0xa6) = 1;
      *(undefined2 *)(param_1 + 0x110) = 0;
      .debug::_SetupProgrammedPath(param_1,0xffffffff,0);
    }
    else if (sVar14 == 0x6d1) {
      *(undefined2 *)(param_1 + 0xa6) = 1;
    }
    *(undefined4 *)(param_1 + 0x158) = 0x1e;
    *(undefined4 *)(param_1 + 0x15c) = 0;
    *(undefined2 *)(param_1 + 0xb0) = 7;
  }
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  return;
}


// ==== .SetupSwarmMemberSprite @ 1007e220 ====

void _SetupSwarmMemberSprite(int param_1)

{
  undefined2 uVar1;
  
  .debug::_InitSprite();
  *(undefined **)(param_1 + 0x4c) = PTR_PTR_100a0470;
  uVar1 = .debug::_FastRand(7);
  *(undefined2 *)(param_1 + 0x46) = uVar1;
  .glue::SetRect(param_1 + 0x34,0,0,0x18,0x16);
  *(undefined **)(param_1 + 0x5c) = PTR_PTR_100a0c68;
  *(undefined2 *)(param_1 + 0xa4) = 100;
  *(undefined1 *)(param_1 + 0x184) = 1;
  return;
}


// ==== .HandleSwarmMemberSprite @ 1007e2c8 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleSwarmMemberSprite(int param_1)

{
  short *psVar1;
  undefined *puVar2;
  undefined4 uVar3;
  short sVar5;
  int iVar4;
  double dVar6;
  double dVar7;
  undefined4 uStack_48;
  undefined8 uStack_40;
  undefined8 uStack_38;
  
  uVar3 = uRam100a1b80;
  .debug::_StandardSpriteHandles();
  *(short *)(param_1 + 0xc) = *(short *)(param_1 + 0xc) - (short)*(undefined4 *)(param_1 + 0x14c);
  *(short *)(param_1 + 10) = *(short *)(param_1 + 10) - (short)*(undefined4 *)(param_1 + 0x150);
  *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + *(int *)(param_1 + 0x14c) * -0x100;
  *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + *(int *)(param_1 + 0x150) * -0x100;
  uStack_48._2_2_ = (short)*(undefined4 *)(param_1 + 10);
  uStack_48._0_2_ = (short)((uint)*(undefined4 *)(param_1 + 10) >> 0x10);
  uStack_48 = CONCAT22(uStack_48._0_2_ + 0xc,uStack_48._2_2_ + 0xc);
  *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
  if (7 < *(short *)(param_1 + 0x46)) {
    *(undefined2 *)(param_1 + 0x46) = 0;
  }
  *(undefined4 *)(param_1 + 0xc0) =
       *(undefined4 *)(_DAT_100a0c88 + *(short *)(param_1 + 0x46) * 4 + 4);
  if (*(short *)(param_1 + 0xa4) < 1) {
    uStack_40 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
    *(int *)(param_1 + 0x24) = (int)((uStack_40 - dRam100a1b88) * dRam100a1b90);
    if (*(int *)(param_1 + 0x2c) < 0) {
      *(undefined4 *)(param_1 + 0x2c) = 0;
    }
    puVar2 = PTR_PTR_100a0c78;
    *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + 0x32;
    *(undefined **)(param_1 + 0x1f8) = puVar2;
  }
  else {
    uVar3 = .debug::_FindDesiredDirectionGeneric(uVar3,uStack_48);
    sVar5 = .debug::_FastRand(0x96);
    FUN_1003f218(param_1,uVar3,sVar5 + 0x172);
    .debug::_EnforceMaxSpeed(param_1,0xa8c);
    iVar4 = (int)*(short *)(param_1 + 0xc);
    if (*(short *)(param_1 + 0xc) < 1) {
      iVar4 = -iVar4;
    }
    if (iVar4 < 8) {
      iVar4 = (int)*(short *)(param_1 + 10);
      if (*(short *)(param_1 + 10) < 1) {
        iVar4 = -iVar4;
      }
      if (iVar4 < 8) {
        iVar4 = *(int *)(param_1 + 0x24);
        if (iVar4 < 1) {
          iVar4 = -iVar4;
        }
        if (iVar4 < 0x578) {
          iVar4 = *(int *)(param_1 + 0x2c);
          if (iVar4 < 1) {
            iVar4 = -iVar4;
          }
          if (iVar4 < 0x578) {
            sVar5 = .debug::_FastRand(0x12fc);
            dVar7 = dRam100a1b98;
            dVar6 = dRam100a1b88;
            *(int *)(param_1 + 0x24) =
                 (int)(((double)CONCAT44(0x43300000,(int)sVar5 ^ 0x80000000) - dRam100a1b88) -
                      dRam100a1b98);
            sVar5 = .debug::_FastRand(0x12fc);
            uStack_38 = (double)CONCAT44(0x43300000,(int)sVar5 ^ 0x80000000);
            *(int *)(param_1 + 0x2c) = (int)((uStack_38 - dVar6) - dVar7);
          }
        }
      }
    }
    sVar5 = .debug::_FastRand(400);
    *(int *)(param_1 + 0x24) = (int)sVar5 + *(int *)(param_1 + 0x24) + -200;
    sVar5 = .debug::_FastRand(400);
    *(int *)(param_1 + 0x2c) = (int)sVar5 + *(int *)(param_1 + 0x2c) + -200;
  }
  psVar1 = _DAT_1009fd94;
  *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + *(int *)(param_1 + 0x24);
  *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + *(int *)(param_1 + 0x2c);
  *(short *)(param_1 + 0xc) = (short)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
  *(short *)(param_1 + 10) = (short)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
  *(short *)(param_1 + 0xc) = *(short *)(param_1 + 0xc) + (short)*(undefined4 *)(param_1 + 0x14c);
  *(short *)(param_1 + 10) = *(short *)(param_1 + 10) + (short)*(undefined4 *)(param_1 + 0x150);
  *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + *(int *)(param_1 + 0x14c) * 0x100;
  *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + *(int *)(param_1 + 0x150) * 0x100;
  if (*(short *)(param_1 + 0xc) + 0xc < (int)*psVar1) {
    *(undefined1 *)(param_1 + 0x17e) = 1;
  }
  else {
    *(undefined1 *)(param_1 + 0x17e) = 0;
  }
  if ((*(short *)(param_1 + 0xa4) < 1) && (*(short *)(param_1 + 0x1a2) < 1)) {
    *(undefined2 *)(param_1 + 0x1a2) = 1;
    *(undefined4 *)(param_1 + 0x2c) = 0;
  }
  .debug::_StandardSpriteCleanup(param_1);
  return;
}


// ==== .HandleBatSprite @ 1007e6b0 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleBatSprite(int param_1)

{
  short *psVar1;
  short *psVar2;
  undefined4 uVar3;
  undefined4 *puVar4;
  int iVar5;
  short sVar6;
  int iVar7;
  undefined2 uVar11;
  undefined4 uVar8;
  short sVar12;
  short sVar13;
  short sVar14;
  int iVar9;
  int iVar10;
  int *piVar15;
  short sVar16;
  undefined4 uStack_46;
  undefined4 uStack_42;
  undefined4 uStack_3e;
  undefined4 uStack_3a;
  undefined4 uStack_32;
  undefined4 uStack_2c;
  
  iVar5 = _DAT_100a0c8c;
  uVar3 = _DAT_1009ff38;
  psVar2 = _DAT_1009fd94;
  psVar1 = _DAT_1009fd90;
  sVar12 = *(short *)(param_1 + 4);
  if (((0x743 < sVar12) && (sVar12 < 0x74e)) && (iVar7 = *(int *)(param_1 + 0x1d4), iVar7 != 0)) {
    if (sVar12 == 0x745) {
      *(undefined4 *)(iVar7 + 0xc0) = *(undefined4 *)(_DAT_100a0c8c + 0x24);
    }
    else if (sVar12 < 0x745) {
      if (0x743 < sVar12) {
        *(undefined4 *)(iVar7 + 0xc0) = *(undefined4 *)(_DAT_100a0c8c + 0x24);
      }
    }
    else if (sVar12 < 0x747) {
      *(undefined4 *)(iVar7 + 0xc0) = *(undefined4 *)(_DAT_100a0c8c + 0x24);
    }
    *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 10) = *(undefined4 *)(param_1 + 10);
    *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0x11c) = *(undefined4 *)(param_1 + 0x11c);
    *(undefined1 *)(*(int *)(param_1 + 0x1d4) + 0x17e) = *(undefined1 *)(param_1 + 0x17e);
    *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0x1ba) = *(undefined2 *)(param_1 + 0x1ba);
  }
  if (*(char *)(param_1 + 0xe9) != '\0') {
    return;
  }
  if (*(char *)(param_1 + 0x1b2) != '\0') {
    return;
  }
  .debug::_StandardSpriteHandles(param_1);
  sVar12 = *(short *)(param_1 + 4);
  if (((sVar12 == 0x6cc) || (sVar12 == 0x6d1)) || ((sVar12 == 0x73a || (sVar12 == 0x744)))) {
    if (0 < *(short *)(param_1 + 0xa6)) {
      if (sVar12 == 0x6cc) {
        *(undefined2 *)(param_1 + 4) = 0x6d1;
      }
      if (*(short *)(param_1 + 0x10) < *psVar2) {
        *(undefined1 *)(param_1 + 0x17e) = 1;
        if ((*(int *)(param_1 + 0x24) < -0x100) &&
           ((int)*(short *)(param_1 + 0x10) < *psVar2 + -0x28)) {
          *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + 0x48;
        }
      }
      else if (*psVar2 < *(short *)(param_1 + 0x10)) {
        *(undefined1 *)(param_1 + 0x17e) = 0;
        if ((0x100 < *(int *)(param_1 + 0x24)) && (*psVar2 + 0x28 < (int)*(short *)(param_1 + 0x10))
           ) {
          *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + -0x48;
        }
      }
    }
    if (*(int *)(param_1 + 0x120) != 0) {
      if (-800 < *(int *)(param_1 + 0x2c)) {
        *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + -100;
      }
      puVar4 = _DAT_100a0274;
      if ((((*(int *)(param_1 + 0x120) == 1) && (*(short *)(param_1 + 0x128) == 0)) ||
          ((0 < *(short *)(param_1 + 0x128) && (*(short *)(param_1 + 0x128) != 3)))) &&
         (*(short *)(param_1 + 0x116) == 0)) {
        *(undefined2 *)(param_1 + 0x116) = 0x13;
        *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -100;
        *(undefined2 *)(param_1 + 0xaa) = 0x11;
        .debug::_STPlay3DSound(*puVar4,1,0x55,*(undefined4 *)(param_1 + 0xe));
      }
    }
    if (*(short *)(param_1 + 0xa6) < 1) {
      iVar7 = (int)*(short *)(param_1 + 0x10) - (int)*psVar2;
      if (iVar7 < 1) {
        iVar7 = -iVar7;
      }
      if (iVar7 < 0x9c) {
        if (((int)*psVar1 - (int)*(short *)(param_1 + 0xe) < 200) &&
           (*(short *)(param_1 + 0xe) + 0x20 < (int)*psVar1)) {
          .debug::_STPlay3DSoundRand(*_DAT_100a02a8,1,0xab,*(undefined4 *)(param_1 + 0xe));
          *(undefined2 *)(param_1 + 0xa6) = 0x14;
        }
      }
    }
    else {
      sVar12 = *(short *)(param_1 + 0xb0);
      if (sVar12 == 7) {
        uStack_32 = CONCAT22(*psVar1 + -0xf,*psVar2);
        sVar12 = .debug::_FindDesiredDirectionGeneric(uStack_32,*(undefined4 *)(param_1 + 0xe));
        iVar9 = (int)*(short *)(param_1 + 0x46);
        iVar7 = (int)sVar12;
        if (iVar7 == iVar9) {
          *(undefined2 *)(param_1 + 0xb0) = 8;
        }
        else {
          if ((iVar9 < iVar7) && (iVar7 - iVar9 < 0x12)) {
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
          }
          else {
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1;
          }
          if (*(short *)(param_1 + 0x46) < 0x24) {
            if (*(short *)(param_1 + 0x46) < 0) {
              *(undefined2 *)(param_1 + 0x46) = 0x23;
            }
          }
          else {
            *(undefined2 *)(param_1 + 0x46) = 0;
          }
        }
      }
      else if (sVar12 < 7) {
        if (sVar12 == 5) {
          uStack_2c = CONCAT22(*psVar1 + -0xf,*psVar2);
          uVar11 = .debug::_FindDesiredDirectionGeneric(uStack_2c,*(undefined4 *)(param_1 + 0xe));
          *(undefined2 *)(param_1 + 0x46) = uVar11;
        }
        else if (4 < sVar12) {
          iVar7 = (int)*(short *)(param_1 + 0x86);
          if (*(short *)(param_1 + 0x86) < 1) {
            iVar7 = -iVar7;
          }
          if (iVar7 < 0x9c) {
            iVar7 = (int)*(short *)(param_1 + 0x84);
            if (*(short *)(param_1 + 0x84) < 1) {
              iVar7 = -iVar7;
            }
            if (iVar7 < 0x9c) {
              *(undefined2 *)(param_1 + 0xb0) = 7;
              *(undefined2 *)(param_1 + 0x84) = 0;
              *(undefined2 *)(param_1 + 0x86) = 0;
              goto LAB_1007ee44;
            }
          }
          *(short *)(param_1 + 0x86) =
               *(short *)(param_1 + 0x86) * (short)*(undefined4 *)(param_1 + 0x15c);
          *(short *)(param_1 + 0x84) =
               *(short *)(param_1 + 0x84) * (short)*(undefined4 *)(param_1 + 0x15c);
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
        }
      }
      else if (sVar12 < 9) {
        uStack_3a = CONCAT22(*psVar1 + -0xf,*psVar2);
        sVar12 = .debug::_FindDesiredDirectionGeneric(uStack_3a,*(undefined4 *)(param_1 + 0xe));
        iVar9 = (int)*(short *)(param_1 + 0x46);
        iVar10 = (int)sVar12;
        iVar7 = iVar10 - iVar9;
        if (iVar7 < 1) {
          iVar7 = -iVar7;
        }
        if (2 < iVar7) {
          iVar7 = (iVar10 + 0x24) - iVar9;
          if (iVar7 < 1) {
            iVar7 = -iVar7;
          }
          if (2 < iVar7) {
            iVar9 = (iVar10 + -0x24) - iVar9;
            if (iVar9 < 1) {
              iVar9 = -iVar9;
            }
            if (2 < iVar9) {
              *(undefined2 *)(param_1 + 0xb0) = 6;
              goto LAB_1007ee44;
            }
          }
        }
        *(undefined2 *)(param_1 + 0xb0) = 8;
        sVar12 = *(short *)(param_1 + 4);
        if ((sVar12 < 0x6cc) || (0x6d5 < sVar12)) {
          if ((sVar12 < 0x73a) || (0x743 < sVar12)) {
            iVar7 = *(int *)(param_1 + 0x24);
            if (iVar7 < 1) {
              iVar7 = -iVar7;
            }
            if (0x1c1 < iVar7) {
              iVar7 = *(int *)(param_1 + 0x2c);
              if (iVar7 < 1) {
                iVar7 = -iVar7;
              }
              if (0x1c1 < iVar7) goto LAB_1007ee44;
            }
            FUN_1003f218(param_1,(int)*(short *)(param_1 + 0x46),*(undefined4 *)(param_1 + 0x158));
          }
          else {
            iVar7 = (int)*(short *)(param_1 + 0x86);
            if (*(short *)(param_1 + 0x86) < 1) {
              iVar7 = -iVar7;
            }
            if (0x4f < iVar7) {
              iVar7 = (int)*(short *)(param_1 + 0x84);
              if (*(short *)(param_1 + 0x84) < 1) {
                iVar7 = -iVar7;
              }
              if (0x4f < iVar7) goto LAB_1007ee44;
            }
            FUN_1003f218(param_1,(int)*(short *)(param_1 + 0x46),*(undefined4 *)(param_1 + 0x158));
          }
        }
        else {
          iVar7 = (int)*(short *)(param_1 + 0x86);
          if (*(short *)(param_1 + 0x86) < 1) {
            iVar7 = -iVar7;
          }
          if (0xb3 < iVar7) {
            iVar7 = (int)*(short *)(param_1 + 0x84);
            if (*(short *)(param_1 + 0x84) < 1) {
              iVar7 = -iVar7;
            }
            if (0xb3 < iVar7) goto LAB_1007ee44;
          }
          FUN_1003f218(param_1,(int)*(short *)(param_1 + 0x46),*(undefined4 *)(param_1 + 0x158));
        }
      }
    }
  }
  else if (sVar12 == 0x74d) {
    .debug::_StandardSpriteHandles(param_1);
    uStack_3e = CONCAT22(*psVar1,*psVar2);
    uVar8 = .debug::_FindDesiredDirectionGeneric(uStack_3e,*(undefined4 *)(param_1 + 10));
    sVar12 = .debug::_FastRand(6);
    FUN_1003f218(param_1,uVar8,sVar12 + 0x14);
    .debug::_EnforceMaxSpeed(param_1,400);
    *(undefined4 *)(param_1 + 0xb8) = 0x10009;
    iVar7 = 0;
    for (sVar12 = 0; sVar12 < *(short *)(*(int *)(param_1 + 0x9c) + 0x52); sVar12 = sVar12 + 1) {
      iVar9 = *(int *)(*(int *)(param_1 + 0x9c) + iVar7);
      if (iVar9 != 0) {
        *(int *)(iVar9 + 0x14c) = (int)*(short *)(param_1 + 0xc);
        *(int *)(*(int *)(*(int *)(param_1 + 0x9c) + iVar7) + 0x150) = (int)*(short *)(param_1 + 10)
        ;
        piVar15 = (int *)(*(int *)(param_1 + 0x9c) + iVar7);
        if (*(char *)(*piVar15 + 0xe9) != '\0') {
          *piVar15 = 0;
          *(short *)(*(int *)(param_1 + 0x9c) + 0x50) =
               *(short *)(*(int *)(param_1 + 0x9c) + 0x50) + -1;
          if (*(short *)(*(int *)(param_1 + 0x9c) + 0x50) < 1) {
            *(undefined1 *)(param_1 + 0xe9) = 1;
          }
        }
      }
      iVar7 = iVar7 + 4;
    }
  }
  else {
    *(undefined1 *)(param_1 + 0x8a) = 0;
    if (*(int *)(param_1 + 0xf0) == 2) {
      iVar9 = *(int *)(param_1 + 0x2c);
      iVar7 = iVar9;
      if (iVar9 < 1) {
        iVar7 = -iVar9;
      }
      if (iVar7 < 0x101) {
        if (iVar9 < 1) {
          iVar7 = -*(int *)(param_1 + 0x2c);
        }
        else {
          iVar7 = *(int *)(param_1 + 0x2c);
        }
        if (iVar7 != 0) {
          *(undefined4 *)(param_1 + 0x2c) = 0;
        }
      }
      else {
        if (iVar9 < 0) {
          iVar7 = -1;
        }
        else {
          iVar7 = 1;
        }
        *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + iVar7 * -0x100;
      }
      if (*(int *)(param_1 + 0x24) < 1) {
        *(undefined1 *)(param_1 + 0x17e) = 0;
      }
      else {
        *(undefined1 *)(param_1 + 0x17e) = 1;
      }
    }
    else if (*(short *)(param_1 + 0x10) < *psVar2) {
      *(undefined1 *)(param_1 + 0x17e) = 1;
    }
    else if (*psVar2 < *(short *)(param_1 + 0x10)) {
      *(undefined1 *)(param_1 + 0x17e) = 0;
    }
    .debug::_HandleProgrammedPath(param_1);
  }
LAB_1007ee44:
  if (0 < *(int *)(param_1 + 0x154)) {
    *(int *)(param_1 + 0x154) = *(int *)(param_1 + 0x154) + -1;
  }
  if ((*(int *)(param_1 + 0x14c) == 1) && (*(int *)(param_1 + 0x154) == 0)) {
    iVar7 = (int)*psVar1 - (int)*(short *)(param_1 + 0xe);
    if (iVar7 < 1) {
      iVar7 = -iVar7;
    }
    if (iVar7 < 0x1e) {
      iVar7 = .debug::_MTNewSprite
                        (0x712,*(short *)(param_1 + 0x10) + -0xc,*(short *)(param_1 + 0xe) + -7,
                         *(int *)(param_1 + 0x80) + 1,0xffffffff,PTR_PTR_100a0830);
      if (*(char *)(param_1 + 0x17e) == '\0') {
        *(undefined4 *)(iVar7 + 0x24) = 0xfffff8f8;
      }
      else {
        *(undefined4 *)(iVar7 + 0x24) = 0x708;
      }
      *(short *)(iVar7 + 0xc) = *(short *)(iVar7 + 0xc) + (short)*(undefined4 *)(iVar7 + 0x24);
      *(short *)(iVar7 + 10) = *(short *)(iVar7 + 10) + (short)*(undefined4 *)(param_1 + 0x2c);
      *(int *)(iVar7 + 0x2c) = *(int *)(param_1 + 0x2c) >> 2;
      sVar12 = .debug::_FastRand(0x4b);
      *(int *)(param_1 + 0x154) = sVar12 + 0x3c;
    }
  }
  if (*(short *)(param_1 + 0xb0) == 4) {
    sVar12 = .debug::_FastRand(3);
    puVar4 = _DAT_100a026c;
    if (*(short *)(_DAT_1009fe44 + 6) == 1) {
      sVar6 = 0xaa;
    }
    else {
      sVar6 = 100;
    }
    *(undefined4 *)(param_1 + 0x5c) = 0;
    .debug::_STPlay3DSound(*puVar4,1,0x100,*(undefined4 *)(param_1 + 0xe));
    *(undefined4 *)(param_1 + 0xc0) = 0;
    .debug::_KillBat(param_1);
    *_DAT_1009ffc0 = *_DAT_1009ffc0 + 500;
    for (sVar16 = 0; sVar16 < (short)(sVar12 + 1); sVar16 = sVar16 + 1) {
      iVar7 = .debug::_MTNewSprite
                        (0x516,*(short *)(param_1 + 0x10) + -4,*(short *)(param_1 + 0xe) + -4,2,
                         0xffffffff,uVar3);
      sVar13 = .debug::_FastRand(0x640);
      *(int *)(iVar7 + 0x2c) = -0x578 - sVar13;
      sVar13 = .debug::_FastRand(1000);
      *(int *)(iVar7 + 0x24) = sVar13 + -500;
    }
    for (sVar12 = 0; sVar12 < sVar6; sVar12 = sVar12 + 1) {
      sVar13 = .debug::_FastRand(6);
      sVar16 = *(short *)(param_1 + 0x10);
      sVar14 = .debug::_FastRand(6);
      uStack_42 = CONCAT22(*(short *)(param_1 + 0xe) + sVar14 + -3,sVar16 + sVar13 + -3);
      iVar7 = .debug::_FastRand(700);
      iVar9 = .debug::_FastRand(200);
      iVar10 = .debug::_FastRand(0x28a);
      .debug::_NewParticle(2,0x78,uStack_42,4,iVar10 + -0x145,(-0x352 - iVar7) - iVar9,0,1);
    }
    for (sVar12 = 0; sVar12 < sVar6 >> 3; sVar12 = sVar12 + 1) {
      sVar13 = .debug::_FastRand(6);
      sVar16 = *(short *)(param_1 + 0x10);
      sVar14 = .debug::_FastRand(6);
      uStack_46 = CONCAT22(*(short *)(param_1 + 0xe) + sVar14 + -3,sVar16 + sVar13 + -3);
      iVar7 = .debug::_FastRand(900);
      iVar9 = .debug::_FastRand(300);
      iVar10 = .debug::_FastRand(900);
      .debug::_NewParticle(2,0x78,uStack_46,4,iVar10 + -0x1c2,(-0x352 - iVar7) - iVar9,0,1);
    }
  }
  if ((0x6cb < *(short *)(param_1 + 4)) && (*(short *)(param_1 + 4) < 0x6d6)) {
    if (0 < *(short *)(param_1 + 0xa6)) {
      *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
    }
    if (0x15 < *(short *)(param_1 + 0xa6)) {
      *(undefined2 *)(param_1 + 0xa6) = 2;
    }
    *(undefined4 *)(param_1 + 0xc0) =
         *(undefined4 *)(PTR_DAT_100a0c90 + ((int)*(short *)(param_1 + 0xa6) >> 1) * 4 + 4);
  }
  iVar7 = (int)*(short *)(param_1 + 4);
  if ((iVar7 < 0x73a) || (0x743 < iVar7)) {
    if ((iVar7 - 0x744U & 0xffff) < 2) {
      if (0 < *(short *)(param_1 + 0xa6)) {
        *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
      }
      if (8 < *(short *)(param_1 + 0xa6)) {
        *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -8;
      }
      if (8 < *(short *)(param_1 + 0xa6)) {
        *(undefined2 *)(param_1 + 0xa6) = 8;
      }
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar5 + *(short *)(param_1 + 0xa6) * 4);
    }
  }
  else if (*(int *)(param_1 + 0x160) == 0) {
    *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
    if (0x12 < *(short *)(param_1 + 0xa6)) {
      *(undefined2 *)(param_1 + 0xa6) = 0;
    }
    *(undefined4 *)(param_1 + 0xc0) =
         *(undefined4 *)(_DAT_100a0c84 + ((int)*(short *)(param_1 + 0xa6) >> 1) * 4 + 4);
  }
  else {
    *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
    if (0x12 < *(short *)(param_1 + 0xa6)) {
      *(undefined2 *)(param_1 + 0xa6) = 0;
    }
    *(undefined4 *)(param_1 + 0xc0) =
         *(undefined4 *)(_DAT_100a0c80 + ((int)*(short *)(param_1 + 0xa6) >> 1) * 4 + 4);
  }
  if (*(short *)(param_1 + 0xa4) < 1) {
    *(undefined2 *)(param_1 + 0xb0) = 4;
  }
  *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + *(int *)(param_1 + 0x24);
  *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + *(int *)(param_1 + 0x2c);
  .debug::_ApplyGravityAndSeparateFromTiles(param_1);
  if ((0x739 < *(short *)(param_1 + 4)) && (*(short *)(param_1 + 4) < 0x744)) {
    if (*(int *)(param_1 + 0x11c) != 1) {
      *(int *)(param_1 + 0x164) = (int)*(short *)(param_1 + 10);
    }
    if ((int)*(short *)(param_1 + 10) < *(int *)(param_1 + 0x164)) {
      *(short *)(param_1 + 10) = (short)*(int *)(param_1 + 0x164);
      *(undefined4 *)(param_1 + 0x2c) = 0;
    }
  }
  if (*(int *)(param_1 + 0xc0) == *_DAT_100a007c) {
    *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 0x45;
  }
  .debug::_StandardSpriteCleanup(param_1);
  sVar12 = *(short *)(param_1 + 4);
  if (((0x743 < sVar12) && (sVar12 < 0x74e)) && (iVar7 = *(int *)(param_1 + 0x1d4), iVar7 != 0)) {
    if (sVar12 == 0x745) {
      *(undefined4 *)(iVar7 + 0xc0) = *(undefined4 *)(iVar5 + 0x24);
    }
    else if (sVar12 < 0x745) {
      if (0x743 < sVar12) {
        *(undefined4 *)(iVar7 + 0xc0) = *(undefined4 *)(iVar5 + 0x24);
      }
    }
    else if (sVar12 < 0x747) {
      *(undefined4 *)(iVar7 + 0xc0) = *(undefined4 *)(iVar5 + 0x24);
    }
    *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 10) = *(undefined4 *)(param_1 + 10);
    *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0x11c) = *(undefined4 *)(param_1 + 0x11c);
    *(undefined1 *)(*(int *)(param_1 + 0x1d4) + 0x17e) = *(undefined1 *)(param_1 + 0x17e);
    *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0x1ba) = *(undefined2 *)(param_1 + 0x1ba);
  }
  return;
}


// ==== .SetupInsectBodySprite @ 1007f440 ====

void _SetupInsectBodySprite(int param_1)

{
  .debug::_InitSprite();
  *(undefined **)(param_1 + 0x4c) = PTR_PTR_100a0c6c;
  return;
}


// ==== .HandleInsectBodySprite @ 1007f4a0 ====

void _HandleInsectBodySprite(undefined4 param_1)

{
  .debug::_StandardSpriteHandles();
  .debug::_StandardSpriteCleanup(param_1);
  return;
}


// ==== .HitBatSprite @ 1007f508 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitBatSprite(int param_1,int param_2)

{
  char cVar2;
  short sVar1;
  undefined *puVar3;
  short sStack_18;
  short sStack_16;
  
  puVar3 = *(undefined **)(param_2 + 0x4c);
  if ((puVar3 == PTR_PTR_100a04e8) && (*(short *)(param_2 + 0xa6) == 0)) {
    .debug::_KillPlayerShot(param_2,0,0);
    if (*(short *)(param_2 + 4) == 1) {
      .debug::_TurnIntoStatue(param_1);
    }
    else {
      cVar2 = .debug::_HurtSprite(param_1,(int)*(short *)(param_2 + 0xa4),
                                  (int)(short)(*(int *)(param_2 + 0x24) >> 3),
                                  (int)(short)(*(int *)(param_2 + 0x2c) >> 3),2,8);
      if (cVar2 != '\0') {
        .debug::_STPlay3DSoundRand(*_DAT_100a02a4,1,0xab,*(undefined4 *)(param_1 + 0xe));
        if (*(short *)(param_1 + 0xa6) < 2) {
          *(undefined2 *)(param_1 + 0xa6) = 0x15;
        }
        if (0 < *(short *)(param_1 + 0xa4)) {
          .debug::_BloodSpray(param_1,param_2,0x28,400,0x96,2);
        }
        if (*(short *)(param_1 + 0xa4) < 0xc9) {
          .debug::_STPlay3DSound(*_DAT_100a0270,1,0x100,*(undefined4 *)(param_1 + 0xe));
        }
        else if (0 < *(short *)(param_1 + 0xa4)) {
          .debug::_STPlay3DSound(*_DAT_100a0274,1,0x100,*(undefined4 *)(param_1 + 0xe));
        }
      }
    }
  }
  else if ((puVar3 == PTR_PTR_100a01f8) || (puVar3 == PTR_PTR_100a0484)) {
    sStack_16 = *(short *)(param_1 + 0x36) +
                (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
    sStack_18 = *(short *)(param_1 + 0x34) +
                (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
    sVar1 = .debug::_PlatformBounce(param_1,param_2,&sStack_18,0,param_1 + 0x34,0);
    if ((sVar1 == 2) && ((0 < *(int *)(param_2 + 0x2c) || (*(char *)(param_1 + 0xce) != '\0')))) {
      *(undefined2 *)(param_1 + 0xa4) = 0;
      *(undefined4 *)(param_1 + 0x150) = 0x16;
    }
  }
  return;
}


// ==== .HitSwarmMemberSprite @ 1007f734 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitSwarmMemberSprite(int param_1,int param_2)

{
  char cVar2;
  short sVar1;
  
  if ((*(short *)(param_2 + 4) != 0x74d) && (*(undefined **)(param_2 + 0x4c) == PTR_PTR_100a04e8)) {
    .debug::_KillPlayerShot(param_2,0,0);
    if (*(short *)(param_2 + 4) == 1) {
      .debug::_TurnIntoStatue(param_1);
    }
    else {
      cVar2 = .debug::_HurtSprite(param_1,(int)*(short *)(param_2 + 0xa4),
                                  (int)(short)(*(int *)(param_2 + 0x24) >> 3),
                                  (int)(short)(*(int *)(param_2 + 0x2c) >> 3),2,8);
      if (cVar2 != '\0') {
        if (0 < *(short *)(param_1 + 0xa4)) {
          .debug::_BloodSpray(param_1,param_2,0x28,400,0x96,2);
        }
        sVar1 = .debug::_FastRand(20000);
        .debug::_STPlay3DSoundPitched
                  (*_DAT_100a031c,1,0xab,*(undefined4 *)(param_1 + 0xe),sVar1 + 58000);
      }
    }
  }
  return;
}


// ==== .HitBatTileSprite @ 1007f91c ====

void _HitBatTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  char cVar1;
  short sStack_48;
  short sStack_46;
  undefined1 auStack_28 [28];
  
  sStack_46 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_48 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  .glue::SetRect(auStack_28,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                 (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
  if (param_4 == 1) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 100) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 200) {
    .debug::_WallBounceBG(param_1,param_3 + -100,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else {
    cVar1 = .debug::_IsWaterTile(param_3);
    if ((cVar1 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
      .debug::_HandleUnderWater(param_1,param_2);
    }
  }
  return;
}


// ==== .SetupGremlinSprite @ 1007fc88 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupGremlinSprite(int param_1)

{
  undefined4 uVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined *puVar4;
  int iVar5;
  int iVar6;
  
  uVar1 = _DAT_1009ff10;
  .debug::_InitSprite();
  puVar2 = PTR_PTR_100a04a4;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar4 = PTR_PTR_100a0c9c;
  *(undefined2 *)(param_1 + 0x86) = 0;
  puVar3 = PTR_PTR_100a0c98;
  *(undefined **)(param_1 + 0x4c) = puVar2;
  puVar2 = PTR_DAT_100a0cac;
  *(undefined **)(param_1 + 0x5c) = puVar4;
  iVar6 = _DAT_100a0ca8;
  *(undefined4 *)(param_1 + 0x1f8) = 0;
  iVar5 = _DAT_100a0ca4;
  *(undefined **)(param_1 + 0x50) = puVar3;
  puVar2[1] = 1;
  *(undefined1 *)(iVar6 + 1) = 1;
  *(undefined1 *)(iVar5 + 1) = 1;
  *(undefined2 *)(param_1 + 0x110) = 0;
  *(undefined4 *)(param_1 + 0xc0) = 0;
  *(undefined2 *)(param_1 + 0xa4) = 500;
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  .glue::SetRect(param_1 + 0x34,0x28,0x26,0x59,0x50);
  *(undefined4 *)(param_1 + 0x14c) = 0;
  *(undefined4 *)(param_1 + 0x150) = 0xffffffff;
  *(undefined2 *)(param_1 + 0xa6) = 0;
  *(undefined2 *)(param_1 + 0xb0) = 7;
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  .debug::_CalcCenterPos(param_1);
  if (*(short *)(param_1 + 0x48) == 0x1ff) {
    .glue::SetRect(param_1 + 0x34,0,0,0,0);
    *(undefined4 *)(param_1 + 0x5c) = 0;
    *(undefined1 *)(param_1 + 0x1b5) = 0;
    *(undefined1 *)(param_1 + 0x188) = 1;
  }
  else {
    *(undefined4 *)(param_1 + 0x80) = 10;
    *(undefined2 *)(param_1 + 0xec) = 0;
    iVar5 = .debug::_MTNewSprite
                      ((int)*(short *)(param_1 + 4),(int)*(short *)(param_1 + 0xc),
                       (int)*(short *)(param_1 + 10),*(int *)(param_1 + 0x80) + -1,0x1ff,uVar1);
    *(undefined2 *)(iVar5 + 0xec) = 1;
    iVar6 = .debug::_MTNewSprite
                      ((int)*(short *)(param_1 + 4),*(short *)(param_1 + 0xc) + 0x26,
                       *(short *)(param_1 + 10) + 0x1b,*(int *)(param_1 + 0x80) + 2,0x1ff,uVar1);
    *(undefined2 *)(iVar6 + 0xec) = 2;
    *(undefined4 *)(iVar5 + 0xb8) = 0xb0000;
    *(int *)(param_1 + 0x1d4) = iVar5;
    *(undefined1 *)(*(int *)(param_1 + 0x1d4) + 0x88) = 0;
    *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0x5c) = 0;
    *(int *)(param_1 + 0x1d8) = iVar6;
    *(int *)(*(int *)(param_1 + 0x1d8) + 0x1d4) = param_1;
    .glue::SetRect(*(int *)(param_1 + 0x1d8) + 0x34,6,3,0x1a,0x1b);
    puVar2 = PTR_PTR_100a0c94;
    *(short *)(*(int *)(param_1 + 0x1d8) + 0x38) = *(short *)(*(int *)(param_1 + 0x1d8) + 0x38) + -5
    ;
    *(undefined **)(*(int *)(param_1 + 0x1d8) + 0x1f8) = puVar2;
    *(undefined1 *)(param_1 + 0x188) = 1;
    .debug::_SetupProgrammedPath(param_1,0xffffffff,0);
    if (*_DAT_1009fe8c != '\0') {
      *(undefined1 *)(param_1 + 0x1b5) = 1;
      *_DAT_1009ffb4 = *_DAT_1009ffb4 + 1;
    }
  }
  *(undefined1 *)(param_1 + 0x188) = 1;
  return;
}


// ==== .HandleGremlinSprite @ 1007feec ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleGremlinSprite(int param_1)

{
  bool bVar1;
  short *psVar2;
  undefined *puVar3;
  undefined4 uVar4;
  int *piVar5;
  undefined4 *puVar6;
  short *psVar7;
  double dVar8;
  double dVar9;
  int iVar10;
  short sVar14;
  int iVar11;
  short sVar15;
  int iVar12;
  char cVar18;
  short sVar16;
  short sVar17;
  int iVar13;
  int iVar19;
  undefined4 uStack_64;
  undefined1 auStack_5a [10];
  undefined4 uStack_50;
  undefined4 uStack_4c;
  undefined8 uStack_48;
  undefined8 uStack_40;
  longlong lStack_38;
  undefined4 uStack_30;
  uint uStack_2c;
  
  iVar10 = _DAT_100a0ca4;
  psVar7 = _DAT_100a0ca0;
  iVar12 = _DAT_100a0320;
  piVar5 = _DAT_1009ffc0;
  uVar4 = _DAT_1009ff38;
  puVar3 = PTR_DAT_1009fe78;
  psVar2 = _DAT_1009fd94;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b2) == '\0')) {
    if (*(short *)(param_1 + 0xec) == 0) {
      if (*(int *)(param_1 + 0x1d8) != 0) {
        *(undefined4 *)(*(int *)(param_1 + 0x1d8) + 0x14c) = *(undefined4 *)(param_1 + 0x14c);
      }
      .debug::_StandardSpriteHandles(param_1);
      if (*(int *)(param_1 + 0x11c) != 0) {
        if (-800 < *(int *)(param_1 + 0x2c)) {
          *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + -100;
        }
        puVar6 = _DAT_100a0274;
        if ((((*(int *)(param_1 + 0x11c) == 1) && (*(short *)(param_1 + 0x128) == 0)) ||
            (0 < *(short *)(param_1 + 0x128))) && (*(short *)(param_1 + 0x116) == 0)) {
          *(undefined2 *)(param_1 + 0x116) = 0x13;
          *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -100;
          *(undefined2 *)(param_1 + 0xaa) = 0x11;
          .debug::_STPlay3DSoundRand(*puVar6,1,0x55,*(undefined4 *)(param_1 + 0xe));
          sVar15 = .debug::_FastRand(100);
          if (sVar15 < 0x12) {
            sVar15 = .debug::_FastRand(5000);
            sVar16 = .debug::_FastRand(2);
            .debug::_STPlay3DSoundPitched
                      (*(undefined4 *)(iVar12 + sVar16 * 4),1,0xab,*(undefined4 *)(param_1 + 0xe),
                       sVar15 + 84000);
          }
        }
      }
      .debug::_HandleProgrammedPath(param_1);
      if (*(short *)(param_1 + 0xb0) == 4) {
        sVar15 = .debug::_FastRand(3);
        puVar3 = PTR_PTR_100a0c94;
        *(undefined4 *)(param_1 + 0x5c) = 0;
        *(undefined4 *)(param_1 + 0xf0) = 0;
        uStack_48 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
        iVar10 = (int)((uStack_48 - dRam100a1ba0) * dRam100a1bb0);
        uStack_40 = (double)(longlong)iVar10;
        *(int *)(param_1 + 0x24) = iVar10;
        *(undefined2 *)(param_1 + 0x110) = 0x5a;
        *(undefined **)(param_1 + 0x1f8) = puVar3;
        if (*(short *)(param_1 + 0x1a2) < 1) {
          *(undefined2 *)(param_1 + 0x1a2) = 1;
          *piVar5 = *piVar5 + 0x4b0;
          for (sVar16 = 0; sVar16 < (short)(sVar15 + 1); sVar16 = sVar16 + 1) {
            iVar10 = .debug::_MTNewSprite
                               (0x516,*(short *)(param_1 + 0x10) + -4,*(short *)(param_1 + 0xe) + -4
                                ,2,0xffffffff,uVar4);
            sVar14 = .debug::_FastRand(0x640);
            *(int *)(iVar10 + 0x2c) = -0x578 - sVar14;
            sVar14 = .debug::_FastRand(1000);
            *(int *)(iVar10 + 0x24) = sVar14 + -500;
          }
          *(undefined4 *)(param_1 + 0x2c) = 0;
          if (*(int *)(param_1 + 0x14c) == 0) {
            sVar15 = .debug::_FastRand(2);
            .debug::_STPlay3DSoundRand
                      (*(undefined4 *)(iVar12 + sVar15 * 4),1,0x100,*(undefined4 *)(param_1 + 0xe));
          }
        }
      }
      else if (*(int *)(param_1 + 0xf0) == 1) {
        if (*(int *)(param_1 + 0x2c) < *(int *)(param_1 + 0x30)) {
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
        }
        else if (*(short *)(param_1 + 0xa6) != 0) {
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
        }
        uStack_48 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
        iVar12 = (int)((uStack_48 - dRam100a1ba0) * dRam100a1bb0);
        uStack_40 = (double)(longlong)iVar12;
        *(int *)(param_1 + 0x24) = iVar12;
        if (*(short *)(param_1 + 0x10) < *psVar2) {
          *(undefined1 *)(param_1 + 0x17e) = 1;
        }
        else if (*psVar2 < *(short *)(param_1 + 0x10)) {
          *(undefined1 *)(param_1 + 0x17e) = 0;
        }
      }
      else {
        *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
        if (*(int *)(param_1 + 0xf0) == 2) {
          if (*(int *)(param_1 + 0x24) < 1) {
            *(undefined1 *)(param_1 + 0x17e) = 0;
          }
          else {
            *(undefined1 *)(param_1 + 0x17e) = 1;
          }
          uStack_48 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x2c) ^ 0x80000000);
          iVar12 = (int)((uStack_48 - dRam100a1ba0) * dRam100a1ba8);
          uStack_40 = (double)(longlong)iVar12;
          *(int *)(param_1 + 0x2c) = iVar12;
        }
        else if (*(short *)(param_1 + 0x10) < *psVar2) {
          *(undefined1 *)(param_1 + 0x17e) = 1;
        }
        else if (*psVar2 < *(short *)(param_1 + 0x10)) {
          *(undefined1 *)(param_1 + 0x17e) = 0;
        }
      }
      puVar6 = _DAT_100a02f4;
      if (*psVar7 <= *(short *)(param_1 + 0xa6)) {
        *(undefined2 *)(param_1 + 0xa6) = 0;
        .debug::_STPlay3DSoundRand(*puVar6,1,0x55,*(undefined4 *)(param_1 + 0xe));
      }
      *(undefined4 *)(param_1 + 0xc0) =
           *(undefined4 *)(PTR_DAT_100a0cac + psVar7[*(short *)(param_1 + 0xa6) + 1] * 4 + 4);
      if (*(short *)(param_1 + 0xa4) < 1) {
        *(undefined2 *)(param_1 + 0xb0) = 4;
      }
      *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + *(int *)(param_1 + 0x24);
      *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + *(int *)(param_1 + 0x2c);
      .debug::_ApplyGravityAndSeparateFromTiles(param_1);
      .debug::_StandardSpriteCleanup(param_1);
      iVar12 = _DAT_100a0ca8;
      *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0xc) = *(undefined2 *)(param_1 + 0xc);
      *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 10) = *(undefined2 *)(param_1 + 10);
      *(undefined1 *)(*(int *)(param_1 + 0x1d4) + 0x17e) = *(undefined1 *)(param_1 + 0x17e);
      *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0xc0) =
           *(undefined4 *)(iVar12 + psVar7[*(short *)(param_1 + 0xa6) + 1] * 4 + 4);
      *(undefined2 *)(*(int *)(param_1 + 0x1d4) + 0x1bc) = *(undefined2 *)(param_1 + 0x1bc);
      if ((*(int *)(param_1 + 0x14c) == 0) && (*(int *)(param_1 + 0x1d8) != 0)) {
        *(undefined1 *)(*(int *)(param_1 + 0x1d8) + 0x17e) = *(undefined1 *)(param_1 + 0x17e);
        *(undefined2 *)(*(int *)(param_1 + 0x1d8) + 0xaa) = *(undefined2 *)(param_1 + 0xaa);
        *(undefined4 *)(*(int *)(param_1 + 0x1d8) + 0xb8) = *(undefined4 *)(param_1 + 0xb8);
        if (0x1b < *(short *)(param_1 + 0x1bc)) {
          *(short *)(*(int *)(param_1 + 0x1d8) + 0x1bc) = *(short *)(param_1 + 0x1bc) + -0x1b;
        }
        if (*(char *)(param_1 + 0x17e) == '\0') {
          *(short *)(*(int *)(param_1 + 0x1d8) + 0xc) = *(short *)(param_1 + 0xc) + 0x26;
          *(short *)(*(int *)(param_1 + 0x1d8) + 10) = *(short *)(param_1 + 10) + 0x1b;
          *(int *)(*(int *)(param_1 + 0x1d8) + 0x14) =
               (int)*(short *)(*(int *)(param_1 + 0x1d8) + 0xc) << 8;
          *(int *)(*(int *)(param_1 + 0x1d8) + 0x1c) =
               (int)*(short *)(*(int *)(param_1 + 0x1d8) + 10) << 8;
        }
        else {
          *(short *)(*(int *)(param_1 + 0x1d8) + 0xc) = *(short *)(param_1 + 0xc) + 0x3e;
          *(short *)(*(int *)(param_1 + 0x1d8) + 10) = *(short *)(param_1 + 10) + 0x1b;
          *(int *)(*(int *)(param_1 + 0x1d8) + 0x14) =
               (int)*(short *)(*(int *)(param_1 + 0x1d8) + 0xc) << 8;
          *(int *)(*(int *)(param_1 + 0x1d8) + 0x1c) =
               (int)*(short *)(*(int *)(param_1 + 0x1d8) + 10) << 8;
        }
      }
      else {
        if (*(int *)(param_1 + 0x1d8) != 0) {
          *(undefined **)(*(int *)(param_1 + 0x1d8) + 0x5c) = PTR_PTR_100a0c9c;
        }
        if (0 < *(short *)(param_1 + 0xa4)) {
          sVar15 = .debug::_FastRand(5);
          iVar12 = 400;
          if (*(char *)(param_1 + 0x17e) == '\0') {
            sVar14 = .debug::_FastRand(3);
            sVar16 = *(short *)(param_1 + 0xc);
            sVar17 = .debug::_FastRand(3);
            uStack_64 = CONCAT22(*(short *)(param_1 + 10) + sVar17 + 0x2f,sVar16 + sVar14 + 0x3a);
          }
          else {
            sVar14 = .debug::_FastRand(3);
            sVar16 = *(short *)(param_1 + 0xc);
            sVar17 = .debug::_FastRand(3);
            uStack_64 = CONCAT22(*(short *)(param_1 + 10) + sVar17 + 0x2f,sVar16 + sVar14 + 0x4a);
          }
          if (*(char *)(param_1 + 0x17e) == '\0') {
            iVar12 = -400;
          }
          iVar10 = *(int *)(param_1 + 0x24);
          iVar19 = *(int *)(param_1 + 0x2c);
          for (iVar11 = 0; iVar11 < (short)(sVar15 + 8); iVar11 = iVar11 + 1) {
            iVar13 = .debug::_FastRand(3);
            if ((short)iVar13 == 0) {
              iVar13 = .debug::_FastRand(0x46);
              iVar13 = -0x32 - iVar13;
            }
            sVar16 = .debug::_FastRand(0x3c);
            sVar14 = .debug::_FastRand(0x3c);
            .debug::_NewParticle
                      (2,100,uStack_64,4,iVar12 + iVar10 + (int)sVar14 + -0x1e,
                       iVar19 + sVar16 + -0x1e0,iVar13,1);
          }
        }
      }
    }
    else if (*(short *)(param_1 + 0xec) == 2) {
      if (*(int *)(param_1 + 0x14c) != 0) {
        .debug::_StandardSpriteHandles(param_1);
        if ((int)*(short *)(*(int *)*_DAT_100a0058 + 0xb282) << 5 < (int)*(short *)(param_1 + 10)) {
          *(undefined2 *)(param_1 + 0xa4) = 0xffff;
        }
        if (*(short *)(param_1 + 0xa4) < 1) {
          if (*(short *)(_DAT_1009fe44 + 6) == 1) {
            sVar15 = 0xaa;
          }
          else {
            sVar15 = 100;
          }
          if (*(int *)(param_1 + 0x1d4) != 0) {
            *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0x14c) = 2;
            *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0x1d8) = 0;
          }
          .debug::_STPlay3DSound(*_DAT_100a026c,1,0x100,*(undefined4 *)(param_1 + 0xe));
          *(undefined4 *)(param_1 + 0xc0) = 0;
          *(undefined1 *)(param_1 + 0xe9) = 1;
          *piVar5 = *piVar5 + 500;
          for (sVar16 = 0; sVar16 < sVar15; sVar16 = sVar16 + 1) {
            sVar14 = .debug::_FastRand(6);
            uStack_4c = CONCAT22(uStack_4c._0_2_,*(short *)(param_1 + 0x10) + sVar14 + -3);
            sVar14 = .debug::_FastRand(6);
            uStack_4c = CONCAT22(*(short *)(param_1 + 0xe) + sVar14 + 0x10,uStack_4c._2_2_);
            iVar12 = .debug::_FastRand(700);
            iVar19 = .debug::_FastRand(200);
            iVar11 = .debug::_FastRand(0x28a);
            .debug::_NewParticle(2,0x78,uStack_4c,4,iVar11 + -0x145,(-0x352 - iVar12) - iVar19,0,1);
          }
          for (sVar16 = 0; sVar16 < sVar15 >> 3; sVar16 = sVar16 + 1) {
            sVar14 = .debug::_FastRand(6);
            uStack_50 = CONCAT22(uStack_50._0_2_,*(short *)(param_1 + 0x10) + sVar14 + -3);
            sVar14 = .debug::_FastRand(6);
            uStack_50 = CONCAT22(*(short *)(param_1 + 0xe) + sVar14 + 0x10,uStack_50._2_2_);
            iVar12 = .debug::_FastRand(900);
            iVar19 = .debug::_FastRand(300);
            iVar11 = .debug::_FastRand(900);
            .debug::_NewParticle(2,0x78,uStack_50,4,iVar11 + -0x1c2,(-0x352 - iVar12) - iVar19,0,1);
          }
        }
      }
      *(int *)(param_1 + 0x15c) = *(int *)(param_1 + 0x15c) + -1;
      if ((*(int *)(param_1 + 0x15c) < 1) &&
         (*(undefined4 *)(param_1 + 0x15c) = 0, *(short *)(param_1 + 0xb2) != 9)) {
        bVar1 = false;
        sVar15 = .debug::_FindDesiredDirectionGeneric
                           (*(undefined4 *)(param_1 + 0xe),*(undefined4 *)(*_DAT_1009fdd8 + 0xe));
        *(int *)(param_1 + 0x158) = (int)sVar15;
        if (*(char *)(param_1 + 0x17e) == '\0') {
          iVar12 = *(int *)(param_1 + 0x158);
          if ((iVar12 == 0x12) || (iVar12 - 0x10U < 2)) {
            *(undefined4 *)(param_1 + 0x158) = 0x12;
            bVar1 = true;
          }
          else if (iVar12 - 0x13U < 6) {
            *(undefined4 *)(param_1 + 0x158) = 0x16;
            bVar1 = true;
          }
          if ((*(int *)(param_1 + 0x14c) == 1) &&
             (*(undefined4 *)(param_1 + 0x158) = 0x12, *(short *)(param_1 + 0x10) < *psVar2)) {
            bVar1 = false;
          }
        }
        else {
          iVar12 = *(int *)(param_1 + 0x158);
          if ((iVar12 == 0) || (iVar12 - 1U < 2)) {
            *(undefined4 *)(param_1 + 0x158) = 0;
            bVar1 = true;
          }
          else if (iVar12 - 0x1eU < 6) {
            *(undefined4 *)(param_1 + 0x158) = 0x20;
            bVar1 = true;
          }
          if ((*(int *)(param_1 + 0x14c) == 1) &&
             (*(undefined4 *)(param_1 + 0x158) = 0, *psVar2 < *(short *)(param_1 + 0x10))) {
            bVar1 = false;
          }
        }
        iVar12 = *(int *)(param_1 + 0x1d4);
        if ((iVar12 == 0) || (0 < *(short *)(iVar12 + 0xa4))) {
          if (iVar12 != 0) {
            iVar19 = (int)*(short *)puVar3;
            iVar12 = (int)*(short *)(puVar3 + 2);
            .glue::SetRect(auStack_5a,iVar12 + -0x20,iVar19 + -0x20,iVar12 + 0x280,iVar19 + 0x1a0);
            cVar18 = .glue::PtInRect(*(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0xe),auStack_5a);
            if (cVar18 == '\0') {
              bVar1 = false;
            }
          }
        }
        else {
          bVar1 = false;
        }
        if ((bVar1) && (*(int *)(param_1 + 0x14c) != 2)) {
          iVar19 = *(int *)(param_1 + 0x158) + 0x12;
          iVar12 = iVar19 / 0x24 + (iVar19 >> 0x1f);
          *(int *)(param_1 + 0x158) = iVar19 + (iVar12 - (iVar12 >> 0x1f)) * -0x24;
          *(undefined4 *)(param_1 + 0x154) = 0;
          *(undefined2 *)(param_1 + 0xb2) = 9;
        }
        if ((*(int *)(param_1 + 0x1d8) != 0) && (*(int *)(param_1 + 0x14c) != 2)) {
          *(undefined4 *)(*(int *)(param_1 + 0x1d8) + 0xc0) = *(undefined4 *)(iVar10 + 4);
        }
      }
      dVar9 = dRam100a1bc0;
      dVar8 = dRam100a1ba0;
      if (*(short *)(param_1 + 0xb2) == 9) {
        iVar12 = *(int *)(param_1 + 0x1d4);
        if ((((iVar12 != 0) && (*(int *)(iVar12 + 0xf0) == 1)) && (*(int *)(param_1 + 0x14c) == 0))
           && (iVar12 != 0)) {
          uStack_2c = *(uint *)(iVar12 + 0x24) ^ 0x80000000;
          uStack_30 = 0x43300000;
          iVar19 = (int)(((double)CONCAT44(0x43300000,uStack_2c) - dRam100a1ba0) * dRam100a1bc0);
          lStack_38 = (longlong)iVar19;
          *(int *)(iVar12 + 0x24) = iVar19;
          uStack_40 = (double)CONCAT44(0x43300000,
                                       *(uint *)(*(int *)(param_1 + 0x1d4) + 0x2c) ^ 0x80000000);
          iVar12 = (int)((uStack_40 - dVar8) * dVar9);
          uStack_48 = (double)(longlong)iVar12;
          *(int *)(*(int *)(param_1 + 0x1d4) + 0x2c) = iVar12;
        }
        iVar12 = *(int *)(param_1 + 0x154) >> 1;
        if (*(int *)(param_1 + 0x154) < 8) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar10 + iVar12 * 4 + 4);
        }
        else {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar10 + (6 - iVar12) * 4 + 4);
        }
        if (*(int *)(param_1 + 0x154) == 1) {
          sVar15 = .debug::_FastRand(100);
          if (sVar15 < 0x33) {
            .debug::_STPlay3DSoundRand(*_DAT_100a02ec,1,0xab,*(undefined4 *)(param_1 + 0xe));
          }
          else {
            .debug::_STPlay3DSoundRand(*_DAT_100a02f0,1,0xab,*(undefined4 *)(param_1 + 0xe));
          }
        }
        if (*(int *)(param_1 + 0x154) == 7) {
          iVar12 = .debug::_MTNewSprite
                             (0x712,*(short *)(param_1 + 0xc) + 4,*(short *)(param_1 + 10) + 6,
                              *(int *)(param_1 + 0x80) + -1,0xffffffff,PTR_PTR_100a0830);
          FUN_1003f218(iVar12,(int)(short)*(undefined4 *)(param_1 + 0x158),0x708);
          if (*(int *)(param_1 + 0x1d4) != 0) {
            *(int *)(iVar12 + 0x24) =
                 *(int *)(iVar12 + 0x24) + *(int *)(*(int *)(param_1 + 0x1d4) + 0x24);
          }
          *(short *)(iVar12 + 0x38) = *(short *)(iVar12 + 0x38) + -3;
          if (*(int *)(param_1 + 0x158) == 4) {
            *(undefined1 *)(iVar12 + 0x17e) = 1;
            *(undefined2 *)(iVar12 + 0x1aa) = 0xdc;
          }
          if (*(int *)(param_1 + 0x158) == 0xe) {
            *(undefined2 *)(iVar12 + 0x1aa) = 0x140;
          }
        }
        if (0xb < *(int *)(param_1 + 0x154)) {
          *(undefined4 *)(param_1 + 0x154) = 0;
          *(undefined2 *)(param_1 + 0xb2) = 0;
          sVar15 = .debug::_FastRand(0x1e);
          *(int *)(param_1 + 0x15c) = sVar15 + 0x1e;
        }
        *(int *)(param_1 + 0x154) = *(int *)(param_1 + 0x154) + 1;
      }
      *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + *(int *)(param_1 + 0x24);
      *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + *(int *)(param_1 + 0x2c);
      .debug::_ApplyGravityAndSeparateFromTiles(param_1);
      if (*(char *)(param_1 + 0xce) != '\0') {
        uStack_48 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
        *(int *)(param_1 + 0x24) = (int)((uStack_48 - dRam100a1ba0) * dRam100a1bb8);
      }
    }
  }
  return;
}


// ==== .HitGremlinSprite @ 10080d34 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitGremlinSprite(int param_1,int param_2)

{
  undefined *puVar1;
  char cVar4;
  short sVar2;
  short sVar3;
  short sStack_18;
  short sStack_16;
  
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0xea) == '\0')) {
    puVar1 = *(undefined **)(param_2 + 0x4c);
    if ((puVar1 == PTR_PTR_100a04e8) && (*(short *)(param_2 + 0xa6) == 0)) {
      .debug::_KillPlayerShot(param_2,0,0);
      if (*(short *)(param_2 + 4) == 1) {
        .debug::_TurnIntoStatue(param_1);
      }
      else {
        cVar4 = .debug::_HurtSprite(param_1,(int)*(short *)(param_2 + 0xa4),
                                    (int)(short)(*(int *)(param_2 + 0x24) >> 3),
                                    (int)(short)(*(int *)(param_2 + 0x2c) >> 3),2,8);
        if (cVar4 != '\0') {
          if (*(short *)(param_1 + 0xa6) < 2) {
            *(undefined2 *)(param_1 + 0xa6) = 0x15;
          }
          if (0 < *(short *)(param_1 + 0xa4)) {
            .debug::_BloodSpray(param_1,param_2,0x28,400,0x96,2);
          }
          if ((*(short *)(param_1 + 0xa4) < 0xc9) &&
             ((*(int *)(param_1 + 0x14c) == 0 || (*(short *)(param_1 + 0xec) != 0)))) {
            .debug::_STPlay3DSound(*_DAT_100a0270,1,0x100,*(undefined4 *)(param_1 + 0xe));
          }
          else if (0 < *(short *)(param_1 + 0xa4)) {
            .debug::_STPlay3DSoundRand(*_DAT_100a0274,1,0x55,*(undefined4 *)(param_1 + 0xe));
            sVar3 = .debug::_FastRand(100);
            if ((sVar3 < 0x12) && (*(int *)(param_1 + 0x14c) == 0)) {
              sVar3 = .debug::_FastRand(5000);
              sVar2 = .debug::_FastRand(2);
              .debug::_STPlay3DSoundPitched
                        (*(undefined4 *)(_DAT_100a0320 + sVar2 * 4),1,0xab,
                         *(undefined4 *)(param_1 + 0xe),sVar3 + 84000);
            }
          }
          if ((((*(int *)(param_1 + 0x14c) == 0) && (*(short *)(param_1 + 0xec) == 0)) &&
              (*(int *)(param_1 + 0x1d8) != 0)) && (sVar3 = .debug::_FastRand(100), 0x50 < sVar3)) {
            .debug::_STPlay3DSoundRand(*_DAT_100a026c,1,0x55,*(undefined4 *)(param_1 + 0xe));
            *(undefined4 *)(param_1 + 0x14c) = 1;
            sVar3 = .debug::_FastRand(300);
            *(short *)(*(int *)(param_1 + 0x1d8) + 0xa4) = sVar3 + 300;
            if (*(char *)(param_1 + 0x17e) == '\0') {
              sVar3 = .debug::_FastRand(200);
              *(int *)(*(int *)(param_1 + 0x1d8) + 0x24) = -(sVar3 + 300);
            }
            else {
              sVar3 = .debug::_FastRand(200);
              *(int *)(*(int *)(param_1 + 0x1d8) + 0x24) = sVar3 + 300;
            }
            sVar3 = .debug::_FastRand(200);
            *(int *)(*(int *)(param_1 + 0x1d8) + 0x2c) = -0x226 - sVar3;
            *(undefined2 *)(*(int *)(param_1 + 0x1d8) + 0x110) = 0x96;
          }
        }
      }
    }
    else if ((puVar1 == PTR_PTR_100a01f8) || (puVar1 == PTR_PTR_100a0484)) {
      sStack_16 = *(short *)(param_1 + 0x36) +
                  (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
      sStack_18 = *(short *)(param_1 + 0x34) +
                  (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
      sVar3 = .debug::_PlatformBounce(param_1,param_2,&sStack_18,0,param_1 + 0x34,0);
      if ((sVar3 == 2) && ((0 < *(int *)(param_2 + 0x2c) || (*(char *)(param_1 + 0xce) != '\0')))) {
        *(undefined2 *)(param_1 + 0xa4) = 0;
        *(undefined4 *)(param_1 + 0x150) = 0x16;
      }
    }
  }
  return;
}


// ==== .KillGremlinSprite @ 100810d4 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _KillGremlinSprite(int param_1)

{
  short *psVar1;
  int *piVar2;
  
  piVar2 = _DAT_1009ffc0;
  psVar1 = _DAT_1009feac;
  if (*(char *)(param_1 + 0xe9) != '\0') {
    return;
  }
  if (*(char *)(param_1 + 0x1b5) != '\0') {
    *_DAT_1009ffb4 = *_DAT_1009ffb4 + -1;
    *(short *)((int)piVar2 + *psVar1 * 2 + 0x306) =
         *(short *)((int)piVar2 + *psVar1 * 2 + 0x306) + 1;
  }
  *piVar2 = *piVar2 + 2000;
  *(undefined1 *)(param_1 + 0xe9) = 1;
  *(undefined1 *)(param_1 + 0xea) = 1;
  if (*(int *)(param_1 + 0x1d4) != 0) {
    *(undefined1 *)(*(int *)(param_1 + 0x1d4) + 0xe9) = 1;
  }
  if ((*(int *)(param_1 + 0x1d8) != 0) && (*(int *)(param_1 + 0x14c) == 0)) {
    *(undefined1 *)(*(int *)(param_1 + 0x1d8) + 0xe9) = 1;
  }
  if (*(int *)(param_1 + 0x1d8) != 0) {
    *(undefined4 *)(*(int *)(param_1 + 0x1d8) + 0x1d4) = 0;
    return;
  }
  return;
}


// ==== .HitGremlinTileSprite @ 100811a4 ====

void _HitGremlinTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  int iVar1;
  char cVar2;
  short sVar3;
  short sStack_58;
  short sStack_56;
  undefined1 auStack_38 [16];
  longlong lStack_28;
  undefined4 uStack_20;
  uint uStack_1c;
  
  sVar3 = 0;
  sStack_56 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_58 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  .glue::SetRect(auStack_38,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                 (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
  if ((*(short *)(param_1 + 0xb0) == 4) || (*(short *)(param_1 + 0xec) == 2)) {
    sVar3 = 0xa0;
    uStack_1c = *(uint *)(param_1 + 0x24) ^ 0x80000000;
    uStack_20 = 0x43300000;
    iVar1 = (int)(((double)CONCAT44(0x43300000,uStack_1c) - dRam100a1ba0) * dRam100a1bb0);
    lStack_28 = (longlong)iVar1;
    *(int *)(param_1 + 0x24) = iVar1;
  }
  if (param_4 == 1) {
    cVar2 = .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_58,sVar3,param_1 + 0x34,0,
                                (uint)((int)sVar3 == 0) - (~(int)sVar3 >> 0x1f) & 1);
    if (cVar2 != '\0') {
      iVar1 = *(int *)(param_1 + 0x2c);
      if (iVar1 < 1) {
        iVar1 = -iVar1;
      }
      if (iVar1 < 0x100) {
        *(undefined4 *)(param_1 + 0x2c) = 0;
      }
    }
  }
  else if ((short)param_3 < 100) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_58,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 200) {
    .debug::_WallBounceBG(param_1,param_3 + -100,&stack0x0000001c,&sStack_58,0,param_1 + 0x34,0,0);
  }
  else {
    cVar2 = .debug::_IsWaterTile(param_3);
    if ((cVar2 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
      .debug::_HandleUnderWater(param_1,param_2);
    }
  }
  return;
}


// ==== .SetupFloaterSprite @ 100814b8 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupFloaterSprite(int param_1)

{
  short sVar1;
  char *pcVar2;
  int *piVar3;
  undefined4 *puVar4;
  undefined *puVar5;
  undefined *puVar6;
  undefined *puVar7;
  int iVar8;
  
  puVar4 = _DAT_100a0058;
  .debug::_InitSprite();
  puVar5 = PTR_PTR_100a04ac;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar7 = PTR_PTR_100a0cb4;
  *(undefined2 *)(param_1 + 0x86) = 0;
  puVar6 = PTR_PTR_100a0cb0;
  *(undefined4 *)(param_1 + 0x80) = 0xb;
  *(undefined **)(param_1 + 0x4c) = puVar5;
  *(undefined **)(param_1 + 0x5c) = puVar7;
  *(undefined **)(param_1 + 0x1f8) = puVar6;
  *(undefined2 *)(param_1 + 0x110) = 0;
  *(undefined4 *)(param_1 + 0xc0) = 0;
  *(undefined2 *)(param_1 + 0xa4) = 500;
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  iVar8 = _DAT_100a0cb8;
  sVar1 = *(short *)(param_1 + 4);
  if ((sVar1 < 0x6f4) || (0x6fd < sVar1)) {
    if ((0x6fd < sVar1) && (sVar1 < 0x708)) {
      *(undefined1 *)(_DAT_100a0cbc + 1) = 1;
      *(undefined1 *)(iVar8 + 1) = 1;
      .glue::SetRect(param_1 + 0x34,0x17,2,0x38,0x5c);
    }
  }
  else {
    PTR_DAT_100a0cc0[1] = 1;
    .glue::SetRect(param_1 + 0x34,0x23,1,0x3e,0x4b);
    *(undefined4 *)(param_1 + 0x1f8) = 0;
    *(int *)(param_1 + 0x14c) =
         (int)*(short *)(*(int *)*puVar4 + *(short *)(param_1 + 0x48) * 0x10 + 8);
    if (*(int *)(param_1 + 0x14c) == 0) {
      *(undefined4 *)(param_1 + 0x14c) = 0x41;
    }
    *(undefined2 *)(param_1 + 0xa6) =
         *(undefined2 *)(*(int *)*puVar4 + *(short *)(param_1 + 0x48) * 0x10 + 10);
    *(int *)(param_1 + 0x154) =
         (int)*(short *)(*(int *)*puVar4 + *(short *)(param_1 + 0x48) * 0x10 + 0xc);
    if (*(int *)(param_1 + 0x154) == 0) {
      *(undefined4 *)(param_1 + 0x154) = 0x50;
    }
    *(int *)(param_1 + 0x158) = (int)*(short *)(param_1 + 0xc);
    *(int *)(param_1 + 0x15c) = (int)*(short *)(param_1 + 10);
    *(undefined2 *)(param_1 + 0x46) = 0;
    *(undefined2 *)(param_1 + 0x110) = 0;
    *(undefined1 *)(param_1 + 0x88) = 0;
  }
  pcVar2 = _DAT_1009fe8c;
  *(undefined2 *)(param_1 + 0xb0) = 7;
  piVar3 = _DAT_1009ffb4;
  if (*pcVar2 != '\0') {
    *(undefined1 *)(param_1 + 0x1b5) = 1;
    *piVar3 = *piVar3 + 1;
  }
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  return;
}


// ==== .HandleFloaterSprite @ 100816d8 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleFloaterSprite(int param_1)

{
  ushort *puVar1;
  undefined *puVar2;
  short sVar4;
  int iVar3;
  uint uVar5;
  undefined4 uStack_28;
  undefined4 uStack_24;
  
  puVar2 = PTR_DAT_100a0cc0;
  puVar1 = _DAT_1009fd94;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b2) == '\0')) {
    .debug::_StandardSpriteHandles(param_1);
    sVar4 = *(short *)(param_1 + 0xa6);
    if (sVar4 < 1) {
      if (sVar4 < 1) {
        sVar4 = *(short *)(param_1 + 0x46);
        if (sVar4 < 0xc) {
          if (sVar4 == 0) {
            sVar4 = .debug::_FastRand((int)(short)*(undefined4 *)(param_1 + 0x154));
            uVar5 = *(uint *)(param_1 + 0x154);
            *(ushort *)(param_1 + 0xc) =
                 ((short)*(undefined4 *)(param_1 + 0x158) -
                 ((short)((int)uVar5 >> 1) + (ushort)((int)uVar5 < 0 && (uVar5 & 1) != 0))) + sVar4;
            sVar4 = .debug::_FastRand((int)(short)*(undefined4 *)(param_1 + 0x154));
            uVar5 = *(uint *)(param_1 + 0x154);
            *(ushort *)(param_1 + 10) =
                 ((short)*(undefined4 *)(param_1 + 0x15c) -
                 ((short)((int)uVar5 >> 1) + (ushort)((int)uVar5 < 0 && (uVar5 & 1) != 0))) + sVar4;
            *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
            *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
            sVar4 = .debug::_FastRand(600);
            *(int *)(param_1 + 0x24) = sVar4 + -300;
            sVar4 = .debug::_FastRand(600);
            *(int *)(param_1 + 0x2c) = sVar4 + -300;
          }
          *(char *)(param_1 + 0x17e) =
               ((char)((short)*puVar1 >> 7) - (char)((short)*(ushort *)(param_1 + 0x10) >> 7)) +
               (*(ushort *)(param_1 + 0x10) <= *puVar1);
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar2 + 4);
          if (*(short *)(param_1 + 0x46) < 4) {
            *(undefined4 *)(param_1 + 0xb8) = 0xb0002;
          }
          else if (*(short *)(param_1 + 0x46) < 8) {
            *(undefined4 *)(param_1 + 0xb8) = 0xb0000;
          }
          else {
            *(undefined4 *)(param_1 + 0xb8) = 0xb0001;
          }
        }
        else if (sVar4 < 0x14) {
          *(char *)(param_1 + 0x17e) =
               ((char)((short)*puVar1 >> 7) - (char)((short)*(ushort *)(param_1 + 0x10) >> 7)) +
               (*(ushort *)(param_1 + 0x10) <= *puVar1);
          *(undefined4 *)(param_1 + 0xb8) = 0;
        }
        else if (sVar4 < 0x1d) {
          *(undefined4 *)(param_1 + 0xc0) =
               *(undefined4 *)(puVar2 + ((int)(short)(sVar4 + -0x12) >> 1) * 4 + 4);
        }
        else if (sVar4 == 0x1d) {
          if (*(char *)(param_1 + 0x17e) == '\0') {
            sVar4 = 6;
          }
          else {
            sVar4 = 0x5e;
          }
          iVar3 = .debug::_MTNewSprite
                            ((int)*(short *)(param_1 + 4),
                             (int)*(short *)(param_1 + 0xc) + sVar4 + -0xc,
                             *(short *)(param_1 + 10) + 10,0,0xffffffff,PTR_PTR_100a0830);
          uStack_24 = CONCAT22(*(short *)(param_1 + 10) + 0x16,*(short *)(param_1 + 0xc) + sVar4);
          uStack_28 = CONCAT22(*_DAT_1009fd90 + 8,*puVar1);
          .debug::_STPlay3DSound(*_DAT_100a02c8,1,0xab,uStack_24);
          sVar4 = .debug::_FindDesiredDirectionGeneric(uStack_28,uStack_24);
          *(int *)(iVar3 + 0x15c) = (int)sVar4;
        }
        else if (0x40 < sVar4) {
          if (sVar4 < 0x4b) {
            *(undefined4 *)(param_1 + 0xc0) =
                 *(undefined4 *)(puVar2 + ((int)(short)(10 - (sVar4 + -0x41)) >> 1) * 4 + 4);
          }
          else if (sVar4 < 0x57) {
            if (sVar4 < 0x4f) {
              *(undefined4 *)(param_1 + 0xb8) = 0xb0001;
            }
            else if (sVar4 < 0x53) {
              *(undefined4 *)(param_1 + 0xb8) = 0xb0000;
            }
            else {
              *(undefined4 *)(param_1 + 0xb8) = 0xb0002;
            }
            if (0 < *(short *)(param_1 + 0xaa)) {
              *(undefined2 *)(param_1 + 0x46) = 0x4a;
              *(undefined4 *)(param_1 + 0xb8) = 0;
            }
          }
          else {
            *(undefined4 *)(param_1 + 0xc0) = 0;
            *(undefined4 *)(param_1 + 0xb8) = 0;
            *(undefined2 *)(param_1 + 0x46) = 0xffff;
            *(short *)(param_1 + 0xa6) = (short)*(undefined4 *)(param_1 + 0x14c);
          }
        }
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      }
    }
    else {
      *(short *)(param_1 + 0xa6) = sVar4 + -1;
      *(undefined4 *)(param_1 + 0xc0) = 0;
    }
    .debug::_ApplyGravityAndSeparateFromTiles(param_1);
    .debug::_StandardSpriteCleanup(param_1);
  }
  return;
}


// ==== .HitFloaterSprite @ 10081aa4 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitFloaterSprite(int param_1,int param_2)

{
  short sVar1;
  undefined *puVar2;
  short sStack_18;
  short sStack_16;
  
  puVar2 = *(undefined **)(param_2 + 0x4c);
  if (((puVar2 == PTR_PTR_100a04e8) && (*(short *)(param_2 + 0xa6) == 0)) &&
     (*(int *)(param_1 + 0xc0) != 0)) {
    .debug::_KillPlayerShot(param_2,0,0);
    if (*(short *)(param_2 + 4) == 1) {
      .debug::_TurnIntoStatue(param_1);
    }
  }
  else if (((puVar2 == PTR_PTR_100a0488) && (*(short *)(param_2 + 4) == *(short *)(param_1 + 4))) &&
          (*(int *)(param_1 + 0xc0) != 0)) {
    .debug::_STPlay3DSound(*_DAT_100a0274,1,0x100,*(undefined4 *)(param_1 + 0xe));
    *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -100;
    *(undefined2 *)(param_1 + 0xaa) = 10;
    .debug::_KillEnemyShot(param_2);
  }
  else if ((puVar2 == PTR_PTR_100a01f8) || (puVar2 == PTR_PTR_100a0484)) {
    sStack_16 = *(short *)(param_1 + 0x36) +
                (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
    sStack_18 = *(short *)(param_1 + 0x34) +
                (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
    sVar1 = .debug::_PlatformBounce(param_1,param_2,&sStack_18,0,param_1 + 0x34,0);
    if ((sVar1 == 2) && ((0 < *(int *)(param_2 + 0x2c) || (*(char *)(param_1 + 0xce) != '\0')))) {
      *(undefined2 *)(param_1 + 0xa4) = 0;
      *(undefined4 *)(param_1 + 0x150) = 0x16;
    }
  }
  return;
}


// ==== .HitFloaterTileSprite @ 10081c60 ====

void _HitFloaterTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  char cVar1;
  short sStack_48;
  short sStack_46;
  undefined1 auStack_28 [28];
  
  sStack_46 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_48 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  .glue::SetRect(auStack_28,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                 (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
  if (param_4 == 1) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 100) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 200) {
    .debug::_WallBounceBG(param_1,param_3 + -100,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else {
    cVar1 = .debug::_IsWaterTile(param_3);
    if ((cVar1 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
      .debug::_HandleUnderWater(param_1,param_2);
    }
  }
  return;
}


// ==== .SetupFrogSprite @ 10081f14 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupFrogSprite(int param_1)

{
  char *pcVar1;
  undefined4 *puVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  undefined *puVar6;
  undefined *puVar7;
  int iVar8;
  short sVar9;
  
  puVar7 = PTR_DAT_100a0cd0;
  puVar2 = _DAT_100a0058;
  .debug::_InitSprite();
  puVar3 = PTR_PTR_100a04a8;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar6 = PTR_PTR_100a0ccc;
  *(undefined2 *)(param_1 + 0x86) = 0;
  puVar5 = PTR_PTR_100a0cc8;
  *(undefined4 *)(param_1 + 0x80) = 0xb;
  puVar4 = PTR_PTR_100a0cc4;
  *(undefined **)(param_1 + 0x4c) = puVar3;
  *(undefined **)(param_1 + 0x5c) = puVar6;
  *(undefined **)(param_1 + 0x1f8) = puVar5;
  *(undefined **)(param_1 + 0x50) = puVar4;
  *(undefined2 *)(param_1 + 0x110) = 0;
  *(undefined4 *)(param_1 + 0xc0) = 0;
  *(undefined2 *)(param_1 + 0xa4) = 500;
  *(undefined2 *)(param_1 + 0xb0) = 0xb;
  sVar9 = .debug::_FastRand(0x1e);
  *(int *)(param_1 + 0x14c) = -0x14 - sVar9;
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  .glue::SetRect(param_1 + 0x34,0xb,0x14,0x48,0x49);
  *(undefined4 *)(param_1 + 0x150) = 0xffffffff;
  *(undefined2 *)(param_1 + 0xa6) = 0;
  *(undefined2 *)(param_1 + 0x110) = 0x8c;
  *(int *)(param_1 + 0x15c) =
       (int)*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 8);
  sVar9 = .debug::_FastRand(0x5fff);
  *(int *)(param_1 + 0xf0) = sVar9 * 2 + 0xbfff;
  iVar8 = *(int *)(param_1 + 0x15c);
  if (iVar8 == 2) {
    *(undefined2 *)(param_1 + 0xa4) = 0x15e;
    *(undefined4 *)(param_1 + 0xb8) = 0x10017;
  }
  else if (iVar8 < 2) {
    if (iVar8 == 0) {
      *(undefined2 *)(param_1 + 0xa4) = 0x15e;
      *(undefined4 *)(param_1 + 0xb8) = 0;
    }
    else if (-1 < iVar8) {
      *(undefined2 *)(param_1 + 0xa4) = 500;
      *(undefined4 *)(param_1 + 0xb8) = 0x1000c;
    }
  }
  else if (iVar8 == 4) {
    *(undefined2 *)(param_1 + 0xa4) = 1000;
    *(undefined4 *)(param_1 + 0xb8) = 0x1000b;
  }
  else if (iVar8 < 4) {
    *(undefined2 *)(param_1 + 0xa4) = 0x5dc;
    *(undefined4 *)(param_1 + 0xb8) = 0x1000f;
  }
  if (*(char *)(*(int *)*puVar2 + 0x26cd) != '\0') {
    *(undefined1 *)(param_1 + 0x8e) = 1;
  }
  pcVar1 = _DAT_1009fe8c;
  puVar7[1] = 1;
  *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar7 + 4);
  if (*pcVar1 != '\0') {
    *(undefined1 *)(param_1 + 0x1b5) = 1;
    *_DAT_1009ffb4 = *_DAT_1009ffb4 + 1;
  }
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  return;
}


// ==== .HandleFrogSprite @ 1008214c ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleFrogSprite(int param_1)

{
  ushort *puVar1;
  undefined4 *puVar2;
  undefined *puVar3;
  double dVar4;
  double dVar5;
  int iVar6;
  int iVar7;
  short sVar8;
  undefined8 uStack_30;
  undefined8 uStack_28;
  
  puVar3 = PTR_DAT_100a0cd0;
  puVar1 = _DAT_1009fd94;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b2) == '\0')) {
    .debug::_StandardSpriteHandles(param_1);
    if (*(int *)(param_1 + 0x11c) != 0) {
      if (-800 < *(int *)(param_1 + 0x2c)) {
        *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + -100;
      }
      puVar2 = _DAT_100a0274;
      if (((*(int *)(param_1 + 0x11c) == 1) && (*(short *)(param_1 + 0x128) == 0)) ||
         (0 < *(short *)(param_1 + 0x128))) {
        sVar8 = *(short *)(param_1 + 0x128);
        if (sVar8 == 3) {
          if (*(short *)(param_1 + 0xa4) < 500) {
            *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + 2;
          }
        }
        else if (((sVar8 < 3) && (1 < sVar8)) && (*(short *)(param_1 + 0x116) == 0)) {
          *(undefined2 *)(param_1 + 0x116) = 0x13;
          *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -100;
          *(undefined2 *)(param_1 + 0xaa) = 0x11;
          .debug::_STPlay3DSound(*puVar2,1,0x55,*(undefined4 *)(param_1 + 0xe));
        }
      }
    }
    if (*(char *)(param_1 + 0xce) == '\0') {
      .debug::_ApplyGravityAndSeparateFromTiles(param_1);
    }
    switch(*(undefined2 *)(param_1 + 0xb0)) {
    case 2:
      sVar8 = *(short *)(param_1 + 0x46);
      sVar8 = (short)((ulonglong)((longlong)(int)sVar8 * 0x55555556) >> 0x20) -
              ((short)((short)((int)sVar8 / 0x30000) + (sVar8 >> 0xf)) >> 0xf);
      *(undefined4 *)(param_1 + 0x24) = 0;
      if (sVar8 < 5) {
        if (2 < sVar8) {
          sVar8 = 4 - sVar8;
        }
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar3 + sVar8 * 4 + 0x18);
        if (*(short *)(param_1 + 0x46) == 6) {
          iVar6 = .debug::_MTNewSprite
                            (0x709,(int)*(short *)(param_1 + 0x10) +
                                   (uint)*(byte *)(param_1 + 0x17e) * 0x5a + -0x2d,
                             *(short *)(param_1 + 0xe) + -0x14,*(int *)(param_1 + 0x80) + 1,
                             0xffffffff,PTR_PTR_100a0830);
          if (*(char *)(param_1 + 0x17e) == '\0') {
            *(undefined4 *)(iVar6 + 0x24) = 0xfffff830;
          }
          else {
            *(undefined4 *)(iVar6 + 0x24) = 2000;
          }
          iVar7 = *(int *)(param_1 + 0x15c);
          if (iVar7 == 3) {
            *(undefined4 *)(iVar6 + 0xb8) = 0x1000f;
            *(short *)(iVar6 + 0xa4) = *(short *)(iVar6 + 0xa4) << 2;
          }
          else if (iVar7 < 3) {
            if (iVar7 == 1) {
              *(short *)(iVar6 + 0xa4) = *(short *)(iVar6 + 0xa4) << 1;
              *(undefined4 *)(iVar6 + 0xb8) = 0x1000c;
            }
            else if (0 < iVar7) {
              *(undefined4 *)(iVar6 + 0xb8) = 0x10017;
            }
          }
          else if (iVar7 < 5) {
            *(undefined4 *)(iVar6 + 0xb8) = 0x1000b;
            *(short *)(iVar6 + 0xa4) = *(short *)(iVar6 + 0xa4) * 3;
          }
        }
      }
      else {
        sVar8 = .debug::_FastRand(10);
        *(int *)(param_1 + 0x14c) = -10 - sVar8;
        *(undefined2 *)(param_1 + 0xb0) = 0xb;
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar3 + 4);
      }
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      break;
    case 4:
      uStack_30 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
      *(int *)(param_1 + 0x24) = (int)((uStack_30 - dRam100a1bc8) * dRam100a1bd0);
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar3 + 0x14);
      if (*(short *)(param_1 + 0x1a2) < 1) {
        *(undefined2 *)(param_1 + 0x1a2) = 1;
      }
      break;
    case 9:
      iVar6 = (int)*(short *)(param_1 + 0x46) / 3;
      if (1 < iVar6) {
        iVar6 = 2;
      }
      *(undefined4 *)(param_1 + 0x24) = 0;
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar3 + (short)iVar6 * 4 + 4);
      if (7 < *(short *)(param_1 + 0x46)) {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar3 + 0x10);
        *(undefined2 *)(param_1 + 0xb0) = 10;
        sVar8 = .debug::_FastRand(100);
        if (0x37 < sVar8) {
          .debug::_STPlay3DSoundRandFrog
                    (param_1,*_DAT_100a0294,1,0x80,*(undefined4 *)(param_1 + 0xe));
        }
        *(undefined1 *)(param_1 + 0xce) = 0;
        sVar8 = .debug::_FastRand(200);
        *(int *)(param_1 + 0x24) = -0x28a - sVar8;
        sVar8 = .debug::_FastRand(400);
        *(int *)(param_1 + 0x2c) = -0x514 - sVar8;
        if (*(int *)(param_1 + 0x154) < 0) {
          *(int *)(param_1 + 0x154) = *(int *)(param_1 + 0x154) + 1;
          *(undefined4 *)(param_1 + 0x14c) = 0;
        }
        else {
          sVar8 = .debug::_FastRand(10);
          *(int *)(param_1 + 0x14c) = -10 - sVar8;
        }
        dVar5 = dRam100a1bd8;
        dVar4 = dRam100a1bc8;
        if ((int)(short)*puVar1 < *(short *)(param_1 + 0xe) + -0x28) {
          sVar8 = .debug::_FastRand(0x96);
          *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) - (sVar8 + 200);
        }
        else {
          iVar6 = (int)*(short *)(param_1 + 0x10) - (int)(short)*puVar1;
          if (iVar6 < 1) {
            iVar6 = -iVar6;
          }
          if (iVar6 < 0xfb) {
            sVar8 = .debug::_FastRand(100);
            if (0x50 < sVar8) {
              *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + -0x15e;
              *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + -200;
            }
          }
          else {
            *(int *)(param_1 + 0x24) =
                 (int)(((double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000) -
                       dRam100a1bc8) * dRam100a1bd8);
            uStack_28 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x2c) ^ 0x80000000);
            *(int *)(param_1 + 0x2c) = (int)((uStack_28 - dVar4) * dVar5);
            sVar8 = .debug::_FastRand(4);
            *(int *)(param_1 + 0x14c) = -4 - sVar8;
          }
        }
        *(undefined2 *)(param_1 + 0x110) = 0x5a;
        if (*(char *)(param_1 + 0x17e) != '\0') {
          *(int *)(param_1 + 0x24) = -*(int *)(param_1 + 0x24);
        }
        *(undefined4 *)(param_1 + 0x158) = *(undefined4 *)(param_1 + 0x24);
      }
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      break;
    case 10:
      if (*(int *)(param_1 + 0x2c) < 0) {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar3 + 0x10);
      }
      else {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar3 + 0x14);
      }
      *(undefined4 *)(param_1 + 0x24) = *(undefined4 *)(param_1 + 0x158);
      *(undefined2 *)(param_1 + 0x110) = 0x5a;
      if (*(char *)(param_1 + 0xce) != '\0') {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar3 + 0x18);
        *(undefined2 *)(param_1 + 0xb0) = 0xb;
      }
      break;
    case 0xb:
      *(undefined4 *)(param_1 + 0x24) = 0;
      *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + 1;
      *(byte *)(param_1 + 0x17e) =
           (*puVar1 <= *(ushort *)(param_1 + 0x10)) -
           ((char)~(byte)((short)(*puVar1 ^ *(ushort *)(param_1 + 0x10)) >> 0xf) >> 7) & 1;
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar3 + 4);
      if (-1 < *(int *)(param_1 + 0x14c)) {
        iVar6 = (int)*(short *)(param_1 + 0x10) - (int)(short)*puVar1;
        if (iVar6 < 1) {
          iVar6 = -iVar6;
        }
        if (iVar6 < 0xfa) {
          sVar8 = .debug::_FastRand(100);
          if (((10 < sVar8) && (sVar8 < 0x47)) &&
             ((int)*_DAT_1009fd90 < *(short *)(param_1 + 0xe) + -0x32)) {
            sVar8 = 100;
          }
          if ((sVar8 < 0x47) && (-1 < *(int *)(param_1 + 0x154))) {
            if (sVar8 < 8) {
              *(undefined2 *)(param_1 + 0xb0) = 9;
              sVar8 = .debug::_FastRand(3);
              *(int *)(param_1 + 0x154) = -3 - sVar8;
              *(undefined2 *)(param_1 + 0x46) = 0;
            }
            else {
              *(undefined2 *)(param_1 + 0x46) = 0;
              *(undefined2 *)(param_1 + 0xb0) = 2;
            }
          }
          else {
            *(undefined2 *)(param_1 + 0xb0) = 9;
            *(undefined2 *)(param_1 + 0x46) = 0;
          }
        }
        else {
          *(undefined2 *)(param_1 + 0x46) = 0;
          *(undefined2 *)(param_1 + 0xb0) = 9;
        }
      }
    }
    puVar2 = _DAT_100a028c;
    if ((*(short *)(param_1 + 0xa4) < 1) && (*(short *)(param_1 + 0xb0) != 4)) {
      *(undefined2 *)(param_1 + 0x46) = 0;
      *(undefined2 *)(param_1 + 0xb0) = 4;
      .debug::_STPlay3DSoundRandFrog(param_1,*puVar2,1,0x100,*(undefined4 *)(param_1 + 0xe));
    }
    *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + *(int *)(param_1 + 0x24);
    *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + *(int *)(param_1 + 0x2c);
    .debug::_ApplyGravityAndSeparateFromTiles(param_1);
    .debug::_StandardSpriteCleanup(param_1);
  }
  return;
}


// ==== .HitFrogSprite @ 100828cc ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitFrogSprite(int param_1,int param_2)

{
  undefined4 *puVar1;
  undefined *puVar2;
  char cVar4;
  short sVar3;
  short sStack_18;
  short sStack_16;
  
  puVar1 = _DAT_100a0274;
  if (*(short *)(param_1 + 0xb0) == 4) {
    return;
  }
  puVar2 = *(undefined **)(param_2 + 0x4c);
  if ((puVar2 == PTR_PTR_100a04e8) && (*(short *)(param_2 + 0xa6) == 0)) {
    .debug::_KillPlayerShot(param_2,0,0);
    if (*(short *)(param_2 + 4) == 1) {
      .debug::_TurnIntoStatue(param_1);
      return;
    }
    cVar4 = .debug::_HurtSprite(param_1,(int)*(short *)(param_2 + 0xa4),
                                (int)(short)(*(int *)(param_2 + 0x24) >> 3),
                                (int)(short)(*(int *)(param_2 + 0x2c) >> 3),8,8);
    if (cVar4 == '\0') {
      return;
    }
    sVar3 = .debug::_FastRand(100);
    if (sVar3 < 0x2e) {
      .debug::_STPlay3DSoundRandFrog(param_1,*puVar1,1,0x100,*(undefined4 *)(param_1 + 0xe));
    }
    else {
      .debug::_STPlay3DSoundRandFrog(param_1,*_DAT_100a0290,1,0x100,*(undefined4 *)(param_1 + 0xe));
    }
    if (*(short *)(param_1 + 0xb0) != 10) {
      *(undefined2 *)(param_1 + 0xb0) = 9;
    }
    *(undefined2 *)(param_1 + 0x46) = 3;
    if (*(short *)(param_1 + 0xa4) < 1) {
      return;
    }
    .debug::_BloodSpray(param_1,param_2,0x28,400,0x96,2);
    return;
  }
  if ((puVar2 != PTR_PTR_100a01f8) && (puVar2 != PTR_PTR_100a0484)) {
    if (((puVar2 != PTR_PTR_100a0460) || (*(short *)(param_2 + 4) != 0x4b7)) ||
       (7 < *(short *)(param_2 + 0x46))) {
      if (*(short *)(param_2 + 4) != 0x5a0) {
        return;
      }
      if ((*(int *)(param_2 + 0x14c) != 1) && (*(int *)(param_2 + 0x150) != 2)) {
        return;
      }
    }
    cVar4 = .debug::_HurtSprite(param_1,100,(int)(short)(*(int *)(param_2 + 0x24) >> 3),
                                (int)(short)(*(int *)(param_2 + 0x2c) >> 3),8,8);
    if (cVar4 != '\0') {
      if (*(short *)(param_1 + 0xb0) != 10) {
        *(undefined2 *)(param_1 + 0xb0) = 9;
      }
      *(undefined2 *)(param_1 + 0x46) = 3;
      if (0 < *(short *)(param_1 + 0xa4)) {
        .debug::_BloodSpray(param_1,param_2,0x28,400,0x96,2);
      }
      if (*(short *)(param_1 + 0xa4) < 0xc9) {
        .debug::_STPlay3DSound(*_DAT_100a0270,1,0x100,*(undefined4 *)(param_1 + 0xe));
      }
      else if (0 < *(short *)(param_1 + 0xa4)) {
        .debug::_STPlay3DSound(*puVar1,1,0x100,*(undefined4 *)(param_1 + 0xe));
      }
    }
    return;
  }
  sStack_16 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_18 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  sVar3 = .debug::_PlatformBounce(param_1,param_2,&sStack_18,0,param_1 + 0x34,0);
  if (sVar3 != 2) {
    return;
  }
  if ((*(int *)(param_2 + 0x2c) < 1) && (*(char *)(param_1 + 0xce) == '\0')) {
    return;
  }
  *(undefined2 *)(param_1 + 0xa4) = 0;
  *(undefined4 *)(param_1 + 0x150) = 0x16;
  return;
}


// ==== .KillFrog @ 10082c14 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _KillFrog(int param_1)

{
  short *psVar1;
  int *piVar2;
  int iVar3;
  
  piVar2 = _DAT_1009ffc0;
  psVar1 = _DAT_1009feac;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b5) != '\0')) {
    *_DAT_1009ffb4 = *_DAT_1009ffb4 + -1;
    *(short *)((int)piVar2 + *psVar1 * 2 + 0x306) =
         *(short *)((int)piVar2 + *psVar1 * 2 + 0x306) + 1;
  }
  *(undefined1 *)(param_1 + 0xe9) = 1;
  *(undefined1 *)(param_1 + 0xea) = 1;
  iVar3 = *(int *)(param_1 + 0x15c);
  if (iVar3 == 2) {
    *piVar2 = *piVar2 + 600;
    return;
  }
  if (iVar3 < 2) {
    if (iVar3 == 0) {
      *piVar2 = *piVar2 + 500;
      return;
    }
    if (iVar3 < 0) {
      return;
    }
    *piVar2 = *piVar2 + 600;
    return;
  }
  if (iVar3 == 4) {
    *piVar2 = *piVar2 + 1000;
    return;
  }
  if (3 < iVar3) {
    return;
  }
  *piVar2 = *piVar2 + 2000;
  return;
}


// ==== .HitFrogTileSprite @ 10082d04 ====

void _HitFrogTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  char cVar1;
  short sStack_48;
  short sStack_46;
  undefined1 auStack_28 [28];
  
  sStack_46 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_48 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  .glue::SetRect(auStack_28,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                 (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
  if (param_4 == 1) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
    if (*(char *)(param_1 + 0xce) != '\0') {
      *(undefined2 *)(param_1 + 0x110) = 400;
    }
  }
  else if ((short)param_3 < 100) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 200) {
    .debug::_WallBounceBG(param_1,param_3 + -100,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else {
    cVar1 = .debug::_IsWaterTile(param_3);
    if ((cVar1 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
      .debug::_HandleUnderWater(param_1,param_2);
    }
  }
  return;
}


// ==== .SetupSalamanderSprite @ 10082f20 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupSalamanderSprite(int param_1)

{
  char *pcVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined *puVar4;
  int iVar5;
  short sVar6;
  
  .debug::_InitSprite();
  puVar2 = PTR_PTR_100a049c;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar4 = PTR_PTR_100a0cdc;
  *(undefined2 *)(param_1 + 0x86) = 0;
  puVar3 = PTR_PTR_100a0cd8;
  *(undefined4 *)(param_1 + 0x80) = 0xb;
  iVar5 = _DAT_100a0ce0;
  *(undefined **)(param_1 + 0x4c) = puVar2;
  *(undefined **)(param_1 + 0x5c) = puVar4;
  *(undefined **)(param_1 + 0x1f8) = puVar3;
  *(undefined2 *)(param_1 + 0x110) = 0;
  *(undefined1 *)(iVar5 + 1) = 1;
  *(undefined4 *)(param_1 + 0xc0) = 0;
  *(undefined2 *)(param_1 + 0xa4) = 500;
  *(undefined2 *)(param_1 + 0xb0) = 0xc;
  sVar6 = .debug::_FastRand(0x1e);
  *(int *)(param_1 + 0x14c) = -0x14 - sVar6;
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  .glue::SetRect(param_1 + 0x34,0xe,0x14,0x42,0x49);
  puVar2 = PTR_PTR_100a0cd4;
  *(undefined4 *)(param_1 + 0x150) = 0xffffffff;
  pcVar1 = _DAT_1009fe8c;
  *(undefined2 *)(param_1 + 0xa6) = 0;
  *(undefined2 *)(param_1 + 0x110) = 0x8c;
  *(undefined **)(param_1 + 0x50) = puVar2;
  if (*pcVar1 != '\0') {
    *(undefined1 *)(param_1 + 0x1b5) = 1;
    *_DAT_1009ffb4 = *_DAT_1009ffb4 + 1;
  }
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  return;
}


// ==== .HandleSalamanderSprite @ 10083074 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleSalamanderSprite(int param_1)

{
  ushort *puVar1;
  undefined4 *puVar2;
  int iVar3;
  short sVar5;
  int iVar4;
  
  iVar4 = _DAT_100a0ce0;
  puVar1 = _DAT_1009fd94;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b2) == '\0')) {
    .debug::_StandardSpriteHandles(param_1);
    if (*(int *)(param_1 + 0x11c) != 0) {
      if (-800 < *(int *)(param_1 + 0x2c)) {
        *(int *)(param_1 + 0x2c) = *(int *)(param_1 + 0x2c) + -100;
      }
      puVar2 = _DAT_100a0274;
      if ((((*(int *)(param_1 + 0x11c) == 1) && (*(short *)(param_1 + 0x128) == 0)) ||
          (0 < *(short *)(param_1 + 0x128))) && (*(short *)(param_1 + 0x116) == 0)) {
        *(undefined2 *)(param_1 + 0x116) = 0x13;
        *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -100;
        *(undefined2 *)(param_1 + 0xaa) = 0x11;
        .debug::_STPlay3DSound(*puVar2,1,0x55,*(undefined4 *)(param_1 + 0xe));
      }
    }
    .debug::_ApplyGravityAndSeparateFromTiles(param_1);
    *(undefined4 *)(param_1 + 0x24) = 0;
    switch(*(undefined2 *)(param_1 + 0xb0)) {
    case 2:
      sVar5 = *(short *)(param_1 + 0x46);
      *(undefined4 *)(param_1 + 0x24) = 0;
      *(byte *)(param_1 + 0x17e) =
           (*puVar1 <= *(ushort *)(param_1 + 0x10)) -
           ((char)~(byte)((short)(*puVar1 ^ *(ushort *)(param_1 + 0x10)) >> 0xf) >> 7) & 1;
      iVar3 = (int)(short)((short)((ulonglong)((longlong)(int)sVar5 * 0x55555556) >> 0x20) -
                          ((short)((short)((int)sVar5 / 0x30000) + (sVar5 >> 0xf)) >> 0xf));
      if (*(int *)(param_1 + 0x14c) < 0) {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar4 + 4);
        *(undefined2 *)(param_1 + 0x46) = 0;
        *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + 1;
      }
      else {
        if (iVar3 < 6) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar4 + iVar3 * 4 + 0x10);
          if (*(short *)(param_1 + 0x46) == 0xc) {
            iVar4 = .debug::_MTNewSprite
                              (0x712,(int)*(short *)(param_1 + 0x10) +
                                     (uint)*(byte *)(param_1 + 0x17e) * 0x3c + -0x2d,
                               *(short *)(param_1 + 0xe) + -0x19,*(int *)(param_1 + 0x80) + 1,
                               0xffffffff,PTR_PTR_100a0830);
            if (*(char *)(param_1 + 0x17e) == '\0') {
              *(undefined4 *)(iVar4 + 0x24) = 0xfffff830;
            }
            else {
              *(undefined4 *)(iVar4 + 0x24) = 2000;
            }
          }
        }
        else {
          sVar5 = .debug::_FastRand(10);
          if (sVar5 < 7) {
            *(undefined2 *)(param_1 + 0x46) = 0;
            sVar5 = .debug::_FastRand(10);
            *(int *)(param_1 + 0x14c) = -10 - sVar5;
          }
          else {
            sVar5 = .debug::_FastRand(10);
            *(int *)(param_1 + 0x14c) = -10 - sVar5;
            *(undefined2 *)(param_1 + 0xb0) = 0xb;
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar4 + 8);
            sVar5 = .debug::_FastRand(600);
            *(int *)(param_1 + 0x2c) = -0x708 - sVar5;
          }
        }
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      }
      break;
    case 4:
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar4 + 0x18);
      if (*(short *)(param_1 + 0x1a2) < 1) {
        *(undefined2 *)(param_1 + 0x1a2) = 1;
      }
      break;
    case 10:
      if (*(int *)(param_1 + 0x2c) < 0) {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar4 + 0xc);
      }
      else {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar4 + 8);
      }
      *(undefined2 *)(param_1 + 0x110) = 0xaa;
      if (*(char *)(param_1 + 0xce) != '\0') {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar4 + 4);
        if ((*(int *)(param_1 + 0x11c) == 0) || (1 < *(int *)(param_1 + 0x11c))) {
          *(undefined2 *)(param_1 + 0xb0) = 2;
        }
        else {
          *(undefined2 *)(param_1 + 0xb0) = 0xc;
          sVar5 = .debug::_FastRand(0x1e);
          *(int *)(param_1 + 0x14c) = -0x14 - sVar5;
        }
      }
      break;
    case 0xb:
      if (*(int *)(param_1 + 0x2c) < 0) {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar4 + 0xc);
      }
      else {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar4 + 8);
      }
      *(undefined2 *)(param_1 + 0x110) = 0xd2;
      if (*(char *)(param_1 + 0xce) != '\0') {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar4 + 4);
        *(undefined2 *)(param_1 + 0xb0) = 0xc;
      }
      break;
    case 0xc:
      *(undefined4 *)(param_1 + 0x24) = 0;
      *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + 1;
      *(byte *)(param_1 + 0x17e) =
           (*puVar1 <= *(ushort *)(param_1 + 0x10)) -
           ((char)~(byte)((short)(*puVar1 ^ *(ushort *)(param_1 + 0x10)) >> 0xf) >> 7) & 1;
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar4 + 4);
      if (-1 < *(int *)(param_1 + 0x14c)) {
        iVar3 = (int)*(short *)(param_1 + 0x10) - (int)(short)*puVar1;
        if (iVar3 < 1) {
          iVar3 = -iVar3;
        }
        if (iVar3 < 0xfa) {
          *(undefined2 *)(param_1 + 0x46) = 0;
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar4 + 8);
          *(undefined2 *)(param_1 + 0xb0) = 10;
          sVar5 = .debug::_FastRand(700);
          *(int *)(param_1 + 0x2c) = -0xc80 - sVar5;
        }
      }
    }
    if ((*(short *)(param_1 + 0xa4) < 1) && (*(short *)(param_1 + 0xb0) != 4)) {
      *(undefined2 *)(param_1 + 0x46) = 0;
      *(undefined2 *)(param_1 + 0xb0) = 4;
    }
    *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + *(int *)(param_1 + 0x24);
    *(int *)(param_1 + 0x1c) = *(int *)(param_1 + 0x1c) + *(int *)(param_1 + 0x2c);
    .debug::_StandardSpriteCleanup(param_1);
  }
  return;
}


// ==== .HitSalamanderSprite @ 1008350c ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitSalamanderSprite(int param_1,int param_2)

{
  char cVar2;
  short sVar1;
  undefined *puVar3;
  short sStack_18;
  short sStack_16;
  
  puVar3 = *(undefined **)(param_2 + 0x4c);
  if ((puVar3 == PTR_PTR_100a04e8) && (*(short *)(param_2 + 0xa6) == 0)) {
    .debug::_KillPlayerShot(param_2,0,0);
    if (*(short *)(param_2 + 4) == 1) {
      .debug::_TurnIntoStatue(param_1);
    }
    else {
      cVar2 = .debug::_HurtSprite(param_1,(int)*(short *)(param_2 + 0xa4),
                                  (int)(short)(*(int *)(param_2 + 0x24) >> 5),
                                  (int)(short)(*(int *)(param_2 + 0x2c) >> 3),2,8);
      if (cVar2 != '\0') {
        if (*(short *)(param_1 + 0xa6) < 2) {
          *(undefined2 *)(param_1 + 0xa6) = 0x15;
        }
        if (0 < *(short *)(param_1 + 0xa4)) {
          .debug::_BloodSpray(param_1,param_2,0x28,400,0x96,2);
        }
        if (*(short *)(param_1 + 0xa4) < 0xc9) {
          .debug::_STPlay3DSound(*_DAT_100a0270,1,0x100,*(undefined4 *)(param_1 + 0xe));
        }
        else if (0 < *(short *)(param_1 + 0xa4)) {
          .debug::_STPlay3DSound(*_DAT_100a0274,1,0x100,*(undefined4 *)(param_1 + 0xe));
        }
      }
    }
  }
  else if ((puVar3 == PTR_PTR_100a01f8) || (puVar3 == PTR_PTR_100a0484)) {
    sStack_16 = *(short *)(param_1 + 0x36) +
                (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
    sStack_18 = *(short *)(param_1 + 0x34) +
                (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
    sVar1 = .debug::_PlatformBounce(param_1,param_2,&sStack_18,0,param_1 + 0x34,0);
    if ((sVar1 == 2) && ((0 < *(int *)(param_2 + 0x2c) || (*(char *)(param_1 + 0xce) != '\0')))) {
      *(undefined2 *)(param_1 + 0xa4) = 0;
      *(undefined4 *)(param_1 + 0x150) = 0x16;
    }
  }
  return;
}


// ==== .KillSalamander @ 10083724 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _KillSalamander(int param_1)

{
  short *psVar1;
  int *piVar2;
  
  piVar2 = _DAT_1009ffc0;
  psVar1 = _DAT_1009feac;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b5) != '\0')) {
    *_DAT_1009ffb4 = *_DAT_1009ffb4 + -1;
    *(short *)((int)piVar2 + *psVar1 * 2 + 0x306) =
         *(short *)((int)piVar2 + *psVar1 * 2 + 0x306) + 1;
  }
  if (*(char *)(param_1 + 0xe9) == '\0') {
    *piVar2 = *piVar2 + 400;
  }
  *(undefined1 *)(param_1 + 0xe9) = 1;
  *(undefined1 *)(param_1 + 0xea) = 1;
  return;
}


// ==== .HitSalamanderTileSprite @ 100837b8 ====

void _HitSalamanderTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  char cVar1;
  short sStack_48;
  short sStack_46;
  undefined1 auStack_28 [28];
  
  sStack_46 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_48 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  .glue::SetRect(auStack_28,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                 (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
  if (param_4 == 1) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else if (((short)param_3 < 100) && (*(short *)(param_1 + 0xb0) != 0xb)) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
  }
  else {
    if ((short)param_3 < 200) {
      if (*(short *)(param_1 + 0xb0) != 0xb) {
        .debug::_WallBounceBG
                  (param_1,param_3 + -100,&stack0x0000001c,&sStack_48,0,param_1 + 0x34,0,0);
        goto LAB_10083924;
      }
    }
    cVar1 = .debug::_IsWaterTile(param_3);
    if ((cVar1 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
      .debug::_HandleUnderWater(param_1,param_2);
    }
  }
LAB_10083924:
  if (*(char *)(param_1 + 0xce) != '\0') {
    *(undefined2 *)(param_1 + 0x110) = 0x15e;
  }
  return;
}


// ==== .SetupRopeSprite @ 10083f20 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupRopeSprite(int param_1)

{
  undefined4 *puVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined *puVar4;
  int iVar5;
  ushort uVar6;
  short sVar7;
  
  .debug::_InitSprite();
  puVar2 = PTR_PTR_100a04f0;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar1 = _DAT_100a0058;
  *(undefined2 *)(param_1 + 0x86) = 0;
  puVar4 = PTR_PTR_100a0d00;
  *(undefined4 *)(param_1 + 0x80) = 1;
  puVar3 = PTR_PTR_100a0cfc;
  *(undefined **)(param_1 + 0x4c) = puVar2;
  *(undefined4 *)(param_1 + 0x5c) = 0;
  *(undefined4 *)(param_1 + 0x1f8) = 0;
  *(undefined2 *)(param_1 + 0xa6) = 3;
  *(undefined2 *)(param_1 + 0xa4) = 6;
  *(undefined1 *)(param_1 + 0x8a) = 0;
  *(undefined1 *)(param_1 + 0x188) = 1;
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  *(undefined2 *)(param_1 + 0x46) = 0;
  *(undefined2 *)(param_1 + 0xa6) = 4;
  iVar5 = *(int *)*puVar1 + *(short *)(param_1 + 0x48) * 0x10;
  uVar6 = *(short *)(iVar5 + 0xc) - *(short *)(iVar5 + 8);
  sVar7 = ((short)uVar6 >> 1) + (ushort)((short)uVar6 < 0 && (uVar6 & 1) != 0);
  *(short *)(param_1 + 0x1c8) = sVar7;
  *(short *)(param_1 + 0x1ca) = sVar7;
  *(undefined2 *)(param_1 + 0x1ce) = 0x40;
  *(undefined2 *)(param_1 + 0x1d0) = 0x3c;
  *(undefined **)(param_1 + 0x54) = puVar4;
  *(undefined **)(param_1 + 0x58) = puVar3;
  *(undefined1 *)(param_1 + 0x17c) = 0;
  return;
}


// ==== .SetupRopeSegSprite @ 10084044 ====

void _SetupRopeSegSprite(int param_1)

{
  .debug::_InitSprite();
  *(undefined **)(param_1 + 0x4c) = PTR_PTR_100a0cf8;
  *(undefined2 *)(param_1 + 0xa4) = 400;
  *(undefined1 *)(param_1 + 0x188) = 1;
  return;
}


// ==== .HandleRopeSegSprite @ 100840b4 ====

void _HandleRopeSegSprite(undefined4 param_1)

{
  .debug::_StandardSpriteHandles();
  .debug::_StandardSpriteCleanup(param_1);
  return;
}


// ==== .GetRopeHeight @ 10084264 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

int _GetRopeHeight(int param_1,short param_2)

{
  float fVar1;
  short sVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  uint uVar6;
  int iVar7;
  
  iVar5 = *(int *)(param_1 + 0x9c);
  uVar6 = (uint)*(short *)(iVar5 + 0x410c);
  if (param_2 < 1) {
    param_2 = 0;
  }
  iVar3 = *(int *)(param_1 + 0x14c) + -1;
  if (iVar3 <= param_2) {
    param_2 = (short)iVar3;
  }
  iVar4 = (int)param_2;
  iVar3 = (iVar4 / (int)uVar6) * uVar6;
  if (iVar4 == iVar3) {
    iVar5 = iVar5 + iVar4 * 4;
    sVar2 = (short)((uint)(*(int *)(iVar5 + 0x2108) + *(int *)(iVar5 + 0x108)) >> 8);
  }
  else {
    iVar7 = iVar5 + ((int)(uVar6 + iVar4 + -1) / (int)uVar6) * uVar6 * 4;
    iVar5 = iVar5 + iVar3 * 4;
    fVar1 = (float)((double)CONCAT44(0x43300000,iVar4 - iVar3 ^ 0x80000000) - _DAT_100a1bf0) /
            (float)((double)CONCAT44(0x43300000,uVar6 ^ 0x80000000) - _DAT_100a1bf0);
    sVar2 = (short)((uint)(int)((float)((double)CONCAT44(0x43300000,
                                                         *(int *)(iVar5 + 0x2108) +
                                                         *(int *)(iVar5 + 0x108) ^ 0x80000000) -
                                       _DAT_100a1bf0) * (_DAT_100a1bf8 - fVar1) +
                               (float)((double)CONCAT44(0x43300000,
                                                        *(int *)(iVar7 + 0x2108) +
                                                        *(int *)(iVar7 + 0x108) ^ 0x80000000) -
                                      _DAT_100a1bf0) * fVar1) >> 8);
  }
  return (int)sVar2;
}


// ==== .RopeIdleize @ 10084b00 ====

void _RopeIdleize(int param_1)

{
  int *piVar1;
  int *piVar2;
  short sVar3;
  
  piVar1 = *(int **)(param_1 + 0x9c);
  if (*(char *)(param_1 + 0x17c) == '\0') {
    return;
  }
  if (piVar1 == (int *)0x0) {
    return;
  }
  piVar2 = piVar1;
  for (sVar3 = 0; (int)sVar3 < *(int *)(param_1 + 0x150); sVar3 = sVar3 + 1) {
    if (*piVar2 != 0) {
      *(undefined1 *)(*piVar2 + 0xe9) = 1;
    }
    piVar2 = piVar2 + 1;
  }
  if (piVar1[0x40] != 0) {
    *(undefined1 *)(piVar1[0x40] + 0xe9) = 1;
  }
  if (piVar1[0x41] != 0) {
    *(undefined1 *)(piVar1[0x41] + 0xe9) = 1;
  }
  *(undefined4 *)(param_1 + 0x170) = 0;
  return;
}


// ==== .RopeDeIdleize @ 10084ba8 ====

void _RopeDeIdleize(int param_1)

{
  if ((*(char *)(param_1 + 0x17c) != '\0') && (*(int *)(param_1 + 0x9c) != 0)) {
    .debug::_MakeRopeSegSprites(param_1);
    *(undefined1 *)(param_1 + 0x186) = 1;
    *(undefined4 *)(param_1 + 0x170) = 1;
  }
  return;
}


// ==== .HandleRopeSprite @ 10084c1c ====

/* WARNING: Removing unreachable block (ram,0x10085204) */
/* WARNING: Removing unreachable block (ram,0x1008520c) */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleRopeSprite(int param_1)

{
  int iVar1;
  int iVar2;
  uint uVar3;
  int iVar4;
  int iVar5;
  uint *puVar6;
  int iVar7;
  int iVar8;
  int iVar9;
  int iVar10;
  int iVar11;
  int iVar12;
  short sVar13;
  int iVar14;
  short sVar15;
  uint uVar16;
  uint uVar17;
  int iVar18;
  double dVar19;
  double dVar20;
  double dVar21;
  undefined8 uStack_60;
  undefined8 uStack_58;
  undefined8 uStack_50;
  undefined8 uStack_48;
  
  iVar2 = _DAT_100a0d08;
  iVar1 = _DAT_100a0d04;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b2) == '\0')) {
    .debug::_StandardSpriteHandles(param_1);
    if (*(char *)(param_1 + 0x17c) == '\0') {
      .debug::_SetupRopeSegArray(param_1);
    }
    dVar21 = _DAT_100a1bf0;
    if (*(int *)(param_1 + 0x170) != 0) {
      uVar3 = *(uint *)(param_1 + 0x14c);
      iVar5 = *(int *)(param_1 + 0x9c);
      iVar7 = ((int)uVar3 >> 1) + (uint)((int)uVar3 < 0 && (uVar3 & 1) != 0);
      iVar18 = (int)*(short *)(iVar5 + 0x410c);
      if (*(char *)(param_1 + 0x186) == '\0') {
        iVar5 = 0;
        for (iVar7 = 0; iVar7 < *(int *)(param_1 + 0x14c); iVar7 = iVar7 + 1) {
          if (iVar7 == (iVar7 / iVar18) * iVar18) {
            puVar6 = (uint *)(*(int *)(param_1 + 0x9c) + iVar5 + 0x2108);
            uVar3 = *puVar6;
            uStack_48 = (double)CONCAT44(0x43300000,uVar3 ^ 0x80000000);
            *puVar6 = (int)((float)(uStack_48 - dVar21) *
                           *(float *)(*(int *)(param_1 + 0x9c) + 0x4120));
            puVar6 = (uint *)(*(int *)(param_1 + 0x9c) + iVar5 + 0x2108);
            if (uVar3 == *puVar6) {
              *puVar6 = 0;
            }
          }
          iVar5 = iVar5 + 4;
        }
        uStack_50 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x154) ^ 0x80000000);
        *(int *)(param_1 + 0x154) =
             (int)((float)(uStack_50 - _DAT_100a1bf0) *
                  *(float *)(*(int *)(param_1 + 0x9c) + 0x4120));
      }
      else {
        iVar4 = (int)*(short *)(param_1 + 0x46);
        if (iVar7 - iVar4 < 1) {
          iVar9 = -(iVar7 - iVar4);
          iVar4 = -(iVar7 - iVar4);
        }
        else {
          iVar9 = iVar7 - iVar4;
          iVar4 = iVar7 - iVar4;
        }
        uVar3 = *(uint *)(param_1 + 0x154);
        iVar7 = (*(int *)(iVar5 + 0x4118) * (iVar7 * iVar7 - iVar4 * iVar9)) / (iVar7 * iVar7);
        if ((int)uVar3 < iVar7) {
          uStack_50 = (double)CONCAT44(0x43300000,iVar7 - uVar3 ^ 0x80000000);
          uStack_48 = (double)CONCAT44(0x43300000,uVar3 ^ 0x80000000);
          *(int *)(param_1 + 0x154) =
               (int)((float)(uStack_50 - _DAT_100a1bf0) * *(float *)(iVar5 + 0x4124) +
                    (float)(uStack_48 - _DAT_100a1bf0));
          iVar5 = *(int *)(param_1 + 0x154);
          if (iVar5 - iVar7 < 1) {
            iVar5 = -(iVar5 - iVar7);
          }
          else {
            iVar5 = iVar5 - iVar7;
          }
          if (iVar5 < 0x100) {
            *(int *)(param_1 + 0x154) = iVar7;
          }
        }
        uVar3 = *(uint *)(param_1 + 0x154);
        if (iVar7 < (int)uVar3) {
          uStack_58 = (double)CONCAT44(0x43300000,uVar3 - iVar7 ^ 0x80000000);
          uStack_50 = (double)CONCAT44(0x43300000,uVar3 ^ 0x80000000);
          *(int *)(param_1 + 0x154) =
               (int)-((float)(uStack_58 - _DAT_100a1bf0) *
                      *(float *)(*(int *)(param_1 + 0x9c) + 0x4124) -
                     (float)(uStack_50 - _DAT_100a1bf0));
          iVar5 = *(int *)(param_1 + 0x154);
          if (iVar5 - iVar7 < 1) {
            iVar5 = -(iVar5 - iVar7);
          }
          else {
            iVar5 = iVar5 - iVar7;
          }
          if (iVar5 < 0x100) {
            *(int *)(param_1 + 0x154) = iVar7;
          }
        }
        uVar17 = (uint)*(short *)(param_1 + 0x46);
        iVar4 = 0;
        uVar3 = (uint)(short)*(undefined4 *)(param_1 + 0x154);
        iVar5 = (int)(short)*(undefined4 *)(param_1 + 0x14c);
        *(uint *)(*(int *)(param_1 + 0x9c) + uVar17 * 4 + 0x2108) = uVar3;
        dVar20 = (double)_DAT_100a1bf8;
        dVar21 = _DAT_100a1bf0;
        for (iVar7 = 0; iVar7 < (int)uVar17; iVar7 = iVar7 + 1) {
          if (iVar7 == (iVar7 / iVar18) * iVar18) {
            uStack_58 = (double)CONCAT44(0x43300000,uVar17 - iVar7 ^ 0x80000000);
            uStack_50 = (double)CONCAT44(0x43300000,uVar17 ^ 0x80000000);
            dVar19 = (double)((float)(uStack_58 - dVar21) / (float)(uStack_50 - dVar21));
            .glue::pow();
            uStack_48 = (double)CONCAT44(0x43300000,uVar3 ^ 0x80000000);
            *(int *)(*(int *)(param_1 + 0x9c) + iVar4 + 0x2108) =
                 (int)((float)(uStack_48 - dVar21) * (float)(dVar20 - (double)(float)dVar19));
          }
          iVar4 = iVar4 + 4;
        }
        dVar20 = (double)_DAT_100a1bf8;
        iVar7 = uVar17 << 2;
        dVar21 = _DAT_100a1bf0;
        for (uVar16 = uVar17; (int)uVar16 < iVar5; uVar16 = uVar16 + 1) {
          if (uVar16 == ((int)uVar16 / iVar18) * iVar18) {
            uStack_60 = (double)CONCAT44(0x43300000,uVar16 - uVar17 ^ 0x80000000);
            uStack_58 = (double)CONCAT44(0x43300000,iVar5 - uVar17 ^ 0x80000000);
            dVar19 = (double)((float)(uStack_60 - dVar21) / (float)(uStack_58 - dVar21));
            .glue::pow();
            uStack_50 = (double)CONCAT44(0x43300000,uVar3 ^ 0x80000000);
            *(int *)(*(int *)(param_1 + 0x9c) + iVar7 + 0x2108) =
                 (int)((float)(uStack_50 - dVar21) * (float)(dVar20 - (double)(float)dVar19));
          }
          iVar7 = iVar7 + 4;
        }
        iVar9 = iVar5 + iVar18 + 1;
        iVar4 = (iVar9 + 1) - iVar5;
        iVar7 = iVar5 << 2;
        if (iVar5 <= iVar9) {
          do {
            if (iVar5 == (iVar5 / iVar18) * iVar18) {
              *(undefined4 *)(*(int *)(param_1 + 0x9c) + iVar7 + 0x2108) = 0;
            }
            iVar7 = iVar7 + 4;
            iVar5 = iVar5 + 1;
            iVar4 = iVar4 + -1;
          } while (iVar4 != 0);
        }
      }
      iVar10 = (int)*(short *)(param_1 + 0xc);
      iVar11 = *(int *)(*(int *)(param_1 + 0x9c) + 0x2108) +
               *(int *)(*(int *)(param_1 + 0x9c) + 0x108) + *(short *)(param_1 + 10) * 0x100;
      iVar7 = 0;
      iVar4 = 0;
      iVar12 = 0;
      iVar5 = iVar18;
      for (iVar9 = 0; iVar9 < *(int *)(param_1 + 0x150); iVar9 = iVar9 + 1) {
        iVar8 = *(int *)(param_1 + 0x9c);
        iVar14 = iVar8 + iVar5 * 4;
        sVar15 = (short)(((short)*(undefined4 *)(iVar14 + 0x2108) -
                         (short)*(undefined4 *)(iVar8 + iVar7 + 0x2108)) +
                        ((short)*(undefined4 *)(iVar14 + 0x108) -
                        (short)*(undefined4 *)(iVar8 + iVar7 + 0x108))) >> 8;
        sVar13 = sVar15;
        if (sVar15 < -0xe) {
          sVar13 = -0xe;
        }
        if (0xe < sVar13) {
          sVar13 = 0xe;
        }
        if (sVar13 < 1) {
          iVar14 = -(int)sVar13;
        }
        else {
          iVar14 = (int)sVar13;
        }
        if (iVar14 < 0xf) {
          if (sVar13 < 0) {
            if (sVar13 < 1) {
              sVar13 = -sVar13;
            }
            sVar13 = sVar13 + 0xe;
            if (0x1d < sVar13) {
              sVar13 = 0x1d;
            }
          }
          else if (0xe < sVar13) {
            sVar13 = 0xe;
          }
          iVar12 = (int)sVar13;
          if (iVar12 < 0xf) {
            iVar12 = -(int)*(short *)(iVar2 + iVar12 * 2);
          }
          else {
            iVar12 = *(short *)(iVar1 + iVar12 * 2) + -0x1e00;
          }
          *(int *)(*(int *)(iVar8 + iVar4) + 0xc0) = *(int *)(iVar8 + 0x4128) + sVar13 * 0x34;
          if (0xe < sVar15) {
            iVar12 = iVar12 + (short)(sVar15 + -0xe) * 0x100;
          }
        }
        iVar7 = iVar7 + iVar18 * 4;
        iVar5 = iVar5 + iVar18;
        *(short *)(*(int *)(*(int *)(param_1 + 0x9c) + iVar4) + 0xc) = (short)iVar10;
        iVar10 = iVar10 + iVar18;
        *(int *)(*(int *)(*(int *)(param_1 + 0x9c) + iVar4) + 0x1c) = iVar11 + iVar12;
        iVar11 = *(int *)(*(int *)(param_1 + 0x9c) + iVar4);
        *(int *)(iVar11 + 0x14) = (int)*(short *)(iVar11 + 0xc) << 8;
        iVar11 = *(int *)(*(int *)(param_1 + 0x9c) + iVar4);
        iVar4 = iVar4 + 4;
        *(short *)(iVar11 + 10) = (short)((uint)*(undefined4 *)(iVar11 + 0x1c) >> 8);
        iVar11 = *(int *)(param_1 + 0x9c) + iVar7;
        iVar11 = *(short *)(param_1 + 10) * 0x100 +
                 *(int *)(iVar11 + 0x2108) + *(int *)(iVar11 + 0x108);
      }
    }
    *(undefined1 *)(param_1 + 0x186) = 0;
    .debug::_StandardSpriteCleanup(param_1);
  }
  return;
}


// ==== .SetupDilloSprite @ 1008622c ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupDilloSprite(int param_1)

{
  short *psVar1;
  char *pcVar2;
  int *piVar3;
  undefined4 *puVar4;
  undefined *puVar5;
  undefined *puVar6;
  undefined *puVar7;
  undefined *puVar8;
  int iVar9;
  int iVar10;
  int iVar11;
  undefined2 uVar12;
  ushort uVar13;
  
  puVar4 = _DAT_100a0058;
  .debug::_InitSprite();
  puVar5 = PTR_PTR_100a04b4;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar8 = PTR_PTR_100a0d28;
  *(undefined2 *)(param_1 + 0x86) = 0;
  puVar7 = PTR_PTR_100a0d24;
  *(undefined4 *)(param_1 + 0x80) = 8;
  puVar6 = PTR_PTR_100a0d20;
  *(undefined **)(param_1 + 0x4c) = puVar5;
  iVar9 = _DAT_100a0d2c;
  *(undefined **)(param_1 + 0x5c) = puVar8;
  iVar10 = _DAT_100a0d30;
  *(undefined **)(param_1 + 0x1f8) = puVar7;
  iVar11 = _DAT_100a0d34;
  *(undefined **)(param_1 + 0x50) = puVar6;
  puVar5 = PTR_DAT_100a0d38;
  *(undefined2 *)(param_1 + 0x110) = 0x122;
  *(undefined1 *)(iVar9 + 1) = 1;
  *(undefined1 *)(iVar10 + 1) = 1;
  *(undefined1 *)(iVar11 + 1) = 1;
  puVar5[1] = 1;
  *(undefined4 *)(param_1 + 0xc0) = 0;
  if (*(short *)(param_1 + 4) == 0x74e) {
    *(undefined2 *)(param_1 + 0xa4) = 500;
  }
  else if (*(short *)(param_1 + 4) == 0x74f) {
    *(undefined2 *)(param_1 + 0xa4) = 0x44c;
    *(undefined4 *)(param_1 + 0xb8) = 0x1000b;
  }
  *(int *)(param_1 + 0x168) = (int)*(short *)(param_1 + 0xa4);
  *(undefined1 *)(param_1 + 0x188) = 1;
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  .glue::SetRect(param_1 + 0x34,0x1a,0x17,0x4a,0x3a);
  *(undefined4 *)(param_1 + 0x150) = 0xffffffff;
  *(undefined2 *)(param_1 + 0xb0) = 6;
  *(undefined2 *)(param_1 + 0xb2) = 0;
  *(undefined2 *)(param_1 + 0x46) = 2;
  *(undefined4 *)(param_1 + 0x14c) = 0;
  uVar12 = .debug::_FastRand(10);
  *(undefined2 *)(param_1 + 0xa6) = uVar12;
  psVar1 = (short *)(*(int *)*puVar4 + *(short *)(param_1 + 0x48) * 0x10 + 10);
  if (*psVar1 == 0) {
    *psVar1 = 0x96;
  }
  *(int *)(param_1 + 0x15c) =
       (int)*(short *)(param_1 + 0xc) -
       ((int)*(short *)(*(int *)*puVar4 + *(short *)(param_1 + 0x48) * 0x10 + 10) >> 1);
  *(int *)(param_1 + 0x160) =
       (int)*(short *)(param_1 + 0xc) +
       ((int)*(short *)(*(int *)*puVar4 + *(short *)(param_1 + 0x48) * 0x10 + 10) >> 1);
  *(undefined4 *)(param_1 + 0x164) = 0;
  uVar13 = .debug::_FastRand(100);
  puVar5 = PTR_DAT_100a0d1c;
  pcVar2 = _DAT_1009fe8c;
  *(byte *)(param_1 + 0x17e) = (uVar13 < 0x33) - ((char)~(byte)((short)uVar13 >> 0xf) >> 7) & 1;
  *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)puVar5;
  piVar3 = _DAT_1009ffb4;
  if (*pcVar2 != '\0') {
    *(undefined1 *)(param_1 + 0x1b5) = 1;
    *piVar3 = *piVar3 + 1;
  }
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  return;
}


// ==== .HandleDilloSprite @ 1008697c ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleDilloSprite(int param_1)

{
  undefined4 *puVar1;
  undefined *puVar2;
  int iVar3;
  undefined *puVar4;
  int iVar5;
  short sVar6;
  short sVar7;
  short sVar8;
  int iVar9;
  undefined8 uStack_30;
  undefined8 uStack_28;
  
  puVar4 = PTR_DAT_100a0d38;
  iVar3 = _DAT_100a0d34;
  iVar9 = _DAT_100a0d2c;
  puVar2 = PTR_DAT_100a0d1c;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b2) == '\0')) {
    .debug::_StandardSpriteHandles(param_1);
    *(undefined4 *)puVar2 = *(undefined4 *)(puVar4 + 4);
    iVar5 = _DAT_100a0d30;
    sVar7 = *(short *)(param_1 + 0xb0);
    if (sVar7 == 6) {
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)puVar2;
      if (0 < *(short *)(param_1 + 0xa6)) {
        *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
      }
      if (*(short *)(param_1 + 0xa6) < 1) {
        sVar6 = .debug::_FastRand(100);
        sVar7 = *(short *)(param_1 + 0xa4);
        iVar9 = *(int *)(param_1 + 0x168);
        sVar8 = .debug::_FastRand(0x10);
        iVar9 = (int)(short)((sVar8 - (short)((sVar7 * 100) / iVar9)) + 0x5c);
        if (iVar9 < sVar6) {
          *(undefined2 *)(param_1 + 0xb0) = 7;
          *(undefined2 *)(param_1 + 0x46) = 1;
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar4 + 4);
          sVar7 = .debug::_FastRand(3);
          *(short *)(param_1 + 0xa6) = sVar7 + 2;
          sVar7 = .debug::_FastRand(100);
          if (100 - iVar9 < (int)sVar7) {
            *(undefined4 *)(param_1 + 0x14c) = 1;
          }
          else {
            *(undefined4 *)(param_1 + 0x14c) = 0;
            sVar7 = .debug::_FastRand(100);
            if (0x50 < sVar7) {
              .debug::_DilloLayEgg(param_1);
            }
          }
          if (*(int *)(param_1 + 0x160) < (int)*(short *)(param_1 + 0xc)) {
            *(undefined1 *)(param_1 + 0x17e) = 0;
          }
          else if ((int)*(short *)(param_1 + 0xc) < *(int *)(param_1 + 0x15c)) {
            *(undefined1 *)(param_1 + 0x17e) = 1;
          }
        }
        else {
          .debug::_RandomDilloAttack(param_1);
        }
      }
      uStack_28 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
      *(int *)(param_1 + 0x24) = (int)((uStack_28 - _DAT_100a1c18) * dRam100a1c10);
    }
    else if (sVar7 < 6) {
      if (sVar7 == 4) {
        uStack_30 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
        *(int *)(param_1 + 0x24) = (int)((uStack_30 - _DAT_100a1c18) * dRam100a1c00);
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(iVar5 + ((int)*(short *)(param_1 + 0x46) / 3) * 4 + 4);
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (0xe < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0xe;
        }
        *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
        if (*(short *)(param_1 + 0xa6) == 0x2d) {
          *(undefined2 *)(param_1 + 0x1a2) = 1;
        }
      }
    }
    else if (sVar7 == 8) {
      uStack_30 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
      *(int *)(param_1 + 0x24) = (int)((uStack_30 - _DAT_100a1c18) * dRam100a1c10);
      sVar7 = *(short *)(param_1 + 0xb2);
      if (sVar7 == 2) {
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(iVar3 + ((int)*(short *)(param_1 + 0x46) >> 1) * 4 + 4);
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1;
        *(undefined4 *)(param_1 + 0x164) = 0;
        *(undefined2 *)(param_1 + 0x1aa) = 0;
        if (*(short *)(param_1 + 0x46) < 0) {
          *(undefined2 *)(param_1 + 0xb0) = 6;
          if (*(int *)(param_1 + 0x14c) == 2) {
            sVar7 = .debug::_FastRand(0xc);
            *(short *)(param_1 + 0xa6) = sVar7 + 6;
          }
          else {
            sVar7 = .debug::_FastRand(0x1e);
            *(short *)(param_1 + 0xa6) = sVar7 + 0xc;
          }
        }
      }
      else if (sVar7 < 2) {
        if (sVar7 == 0) {
          *(undefined4 *)(param_1 + 0xc0) =
               *(undefined4 *)(iVar3 + ((int)*(short *)(param_1 + 0x46) >> 1) * 4 + 4);
          *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
          if (8 < *(short *)(param_1 + 0x46)) {
            *(undefined2 *)(param_1 + 0x46) = 9;
            *(undefined2 *)(param_1 + 0xb2) = 1;
            *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + 1;
          }
        }
        else if (-1 < sVar7) {
          if (*(short *)(param_1 + 0xa6) < 0x10) {
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar3 + 0x14);
          }
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
          if (*(short *)(param_1 + 0xa6) < 1) {
            if (1 < *(int *)(param_1 + 0x14c)) {
              iVar5 = *(int *)(param_1 + 0x154);
              if (iVar5 == 2) {
                if (*(char *)(param_1 + 0x17e) == '\0') {
                  sVar6 = 0x200;
                  sVar7 = *(short *)(param_1 + 0xe);
                  iVar9 = (int)*(short *)(param_1 + 0xc) +
                          *(short *)(*(int *)(param_1 + 0xc0) + 0xe) + -0x17;
                }
                else {
                  sVar6 = -0x200;
                  sVar7 = *(short *)(param_1 + 0xe);
                  iVar9 = (int)*(short *)(param_1 + 0xc) +
                          *(short *)(*(int *)(param_1 + 0xc0) + 10) + 5;
                }
                sVar8 = .debug::_FastRand(4000);
                .debug::_STPlay3DSoundPitched
                          (*_DAT_100a02e4,0x14,0x100,*(undefined4 *)(param_1 + 0xe),sVar8 + 63000);
                puVar2 = PTR_PTR_100a0830;
                *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar3 + 0x10);
                *(undefined2 *)(param_1 + 0xa6) = 0x10;
                *(undefined4 *)(param_1 + 0x14c) = 0;
                iVar9 = .debug::_MTNewSprite(0x753,iVar9,sVar7 + -8,0,0xffffffff,puVar2);
                .debug::_MTChangeSpriteLayer(iVar9,*(int *)(param_1 + 0x80) + -1);
                *(int *)(iVar9 + 0x24) = (int)sVar6;
                *(undefined4 *)(iVar9 + 0x2c) = 0xfffffce0;
                if (*(short *)(param_1 + 4) == 0x74e) {
                  *(undefined2 *)(iVar9 + 0xa4) = 0xe0;
                }
                else {
                  *(undefined2 *)(iVar9 + 0xa4) = 0x1c0;
                  *(undefined4 *)(iVar9 + 0xb8) = 0x1000b;
                }
              }
              else if (iVar5 < 2) {
                if (iVar5 == 0) {
                  *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar3 + 0x10);
                  *(undefined2 *)(param_1 + 0xa6) = 0x10;
                  .debug::_ShootSpines(param_1,0);
                }
                else if (-1 < iVar5) {
                  *(undefined2 *)(param_1 + 0xa6) = 0x10;
                  *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar9 + 8);
                  *(undefined2 *)(param_1 + 0xb2) = 3;
                  *(undefined4 *)(param_1 + 0x2c) = 0xfffff128;
                  *(undefined1 *)(param_1 + 0xce) = 0;
                  sVar7 = .debug::_FastRand(4000);
                  .debug::_STPlay3DSoundPitched
                            (*_DAT_100a03f8,0x14,0xab,*(undefined4 *)(param_1 + 0xe),sVar7 + 75000);
                }
              }
              else if (iVar5 < 4) {
                *(undefined4 *)(param_1 + 0x164) = 0xf;
                uStack_30 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x164) ^ 0x80000000);
                *(int *)(param_1 + 0x24) = (int)(dRam100a1c08 * (uStack_30 - _DAT_100a1c18));
                if (*(char *)(param_1 + 0x17e) == '\0') {
                  *(int *)(param_1 + 0x24) = -*(int *)(param_1 + 0x24);
                }
                if (*(char *)(param_1 + 0x17e) == '\0') {
                  *(short *)(param_1 + 0x1aa) =
                       *(short *)(param_1 + 0x1aa) + (short)*(undefined4 *)(param_1 + 0x164);
                  if (*(short *)(param_1 + 0x1aa) < 0x168) {
                    *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + 1;
                  }
                  else {
                    *(short *)(param_1 + 0x1aa) = *(short *)(param_1 + 0x1aa) + -0x168;
                  }
                }
                else {
                  *(short *)(param_1 + 0x1aa) =
                       *(short *)(param_1 + 0x1aa) - (short)*(undefined4 *)(param_1 + 0x164);
                  if (*(short *)(param_1 + 0x1aa) < 0) {
                    *(short *)(param_1 + 0x1aa) = *(short *)(param_1 + 0x1aa) + 0x168;
                  }
                  else {
                    *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + 1;
                  }
                }
              }
            }
            *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + -1;
            if (*(int *)(param_1 + 0x14c) < 1) {
              *(undefined2 *)(param_1 + 0xb2) = 2;
            }
          }
        }
      }
      else if (sVar7 < 4) {
        if (*(int *)(param_1 + 0x2c) < 0) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar9 + 8);
        }
        else {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar9 + 4);
        }
        if ((-1 < *(int *)(param_1 + 0x2c) + (int)*(short *)(param_1 + 0x110)) &&
           (*(int *)(param_1 + 0x2c) < 0)) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar9 + 8);
          .debug::_ShootSpines(param_1,1);
        }
        if (*(char *)(param_1 + 0xce) != '\0') {
          *(undefined2 *)(param_1 + 0xb2) = 1;
        }
      }
    }
    else if (sVar7 < 8) {
      if (*(int *)(param_1 + 0x14c) == 0) {
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(puVar4 + ((int)*(short *)(param_1 + 0x46) >> 1) * 4 + 4);
        if (10 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
          if ((*(int *)(param_1 + 0x160) < (int)*(short *)(param_1 + 0xc)) ||
             ((int)*(short *)(param_1 + 0xc) < *(int *)(param_1 + 0x15c))) {
            *(undefined2 *)(param_1 + 0xa6) = 0;
          }
          if (*(short *)(param_1 + 0xa6) == 0) {
            *(undefined2 *)(param_1 + 0xb0) = 6;
            sVar7 = .debug::_FastRand(0x14);
            *(short *)(param_1 + 0xa6) = sVar7 + 8;
          }
        }
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (*(char *)(param_1 + 0x17e) == '\0') {
          *(undefined4 *)(param_1 + 0x24) = 0xfffffc00;
        }
        else {
          *(undefined4 *)(param_1 + 0x24) = 0x400;
        }
      }
      else {
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(puVar4 + *(short *)(param_1 + 0x46) * 4 + 4);
        if (4 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
          if ((*(int *)(param_1 + 0x160) < (int)*(short *)(param_1 + 0xc)) ||
             ((int)*(short *)(param_1 + 0xc) < *(int *)(param_1 + 0x15c))) {
            *(undefined2 *)(param_1 + 0xa6) = 0;
          }
          if (*(short *)(param_1 + 0xa6) == 0) {
            *(undefined2 *)(param_1 + 0xb0) = 6;
            sVar7 = .debug::_FastRand(0x14);
            *(short *)(param_1 + 0xa6) = sVar7 + 8;
          }
        }
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (*(char *)(param_1 + 0x17e) == '\0') {
          *(undefined4 *)(param_1 + 0x24) = 0xfffff800;
        }
        else {
          *(undefined4 *)(param_1 + 0x24) = 0x800;
        }
      }
    }
    puVar1 = _DAT_100a026c;
    if ((*(short *)(param_1 + 0xa4) < 1) && (*(short *)(param_1 + 0xb0) != 4)) {
      *(undefined2 *)(param_1 + 0xb0) = 4;
      *(undefined2 *)(param_1 + 0x46) = 0;
      *(undefined2 *)(param_1 + 0xa6) = 0;
      .debug::_STPlay3DSound(*puVar1,1,0x100,*(undefined4 *)(param_1 + 0xe));
    }
    .debug::_ApplyGravityAndSeparateFromTiles(param_1);
    puVar1 = _DAT_100a0274;
    if ((*(int *)(param_1 + 0x11c) != 0) &&
       (((*(int *)(param_1 + 0x11c) == 1 && (*(short *)(param_1 + 0x128) == 0)) ||
        (0 < *(short *)(param_1 + 0x128))))) {
      sVar7 = *(short *)(param_1 + 0x128);
      if (sVar7 == 3) {
        if (*(short *)(param_1 + 0xa4) < 500) {
          *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + 4;
        }
      }
      else if (((sVar7 < 3) && (1 < sVar7)) && (*(short *)(param_1 + 0x116) == 0)) {
        *(undefined2 *)(param_1 + 0x116) = 0x13;
        *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -100;
        *(undefined2 *)(param_1 + 0xaa) = 0x11;
        .debug::_STPlay3DSound(*puVar1,1,0x55,*(undefined4 *)(param_1 + 0xe));
      }
    }
    .debug::_StandardSpriteCleanup(param_1);
  }
  return;
}


// ==== .HitDilloSprite @ 10087334 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitDilloSprite(int param_1,int param_2)

{
  bool bVar1;
  char cVar3;
  short sVar2;
  undefined *puVar4;
  short sStack_18;
  short sStack_16;
  
  puVar4 = *(undefined **)(param_2 + 0x4c);
  if (((puVar4 == PTR_PTR_100a04e8) && (*(short *)(param_2 + 0xa6) == 0)) &&
     (0 < *(short *)(param_1 + 0xa4))) {
    bVar1 = false;
    if ((*(short *)(param_1 + 0xb0) == 7) || (*(short *)(param_1 + 0xb0) == 6)) {
      if (((*(short *)(param_2 + 0x10) < *(short *)(param_1 + 0x10)) &&
          (*(char *)(param_1 + 0x17e) == '\0')) ||
         ((*(short *)(param_1 + 0x10) < *(short *)(param_2 + 0x10) &&
          (*(char *)(param_1 + 0x17e) != '\0')))) {
        bVar1 = true;
      }
    }
    if (bVar1) {
      .debug::_KillPlayerShot(param_2,0,0);
      if (*(short *)(param_2 + 4) == 1) {
        .debug::_TurnIntoStatue(param_1);
      }
      else {
        cVar3 = .debug::_HurtSprite(param_1,(int)*(short *)(param_2 + 0xa4),
                                    (int)(short)(*(int *)(param_2 + 0x24) >> 1),0xfffffc18,2,8);
        if (cVar3 != '\0') {
          .debug::_BloodSpray(param_1,param_2,0x28,400,0x96,2);
          if (*(short *)(param_1 + 0xa4) < 0xc9) {
            .debug::_STPlay3DSound(*_DAT_100a0270,1,0x100,*(undefined4 *)(param_1 + 0xe));
          }
          else if (0 < *(short *)(param_1 + 0xa4)) {
            .debug::_STPlay3DSound(*_DAT_100a0274,1,0x100,*(undefined4 *)(param_1 + 0xe));
          }
          .debug::_RandomDilloAttack(param_1);
        }
      }
    }
    else {
      .debug::_KillPlayerShot(param_2,0,1);
      .debug::_STPlay3DSound(*_DAT_100a041c,1,0x100,*(undefined4 *)(param_2 + 0xe));
    }
  }
  else if ((puVar4 == PTR_PTR_100a01f8) || (puVar4 == PTR_PTR_100a0484)) {
    sStack_16 = *(short *)(param_1 + 0x36) +
                (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
    sStack_18 = *(short *)(param_1 + 0x34) +
                (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
    sVar2 = .debug::_PlatformBounce(param_1,param_2,&sStack_18,0,param_1 + 0x34,0);
    if ((sVar2 == 2) && ((0 < *(int *)(param_2 + 0x2c) || (*(char *)(param_1 + 0xce) != '\0')))) {
      *(undefined2 *)(param_1 + 0xa4) = 0;
      *(undefined4 *)(param_1 + 0x150) = 0x16;
    }
  }
  return;
}


// ==== .KillDillo @ 100875bc ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _KillDillo(int param_1)

{
  short *psVar1;
  int *piVar2;
  
  piVar2 = _DAT_1009ffc0;
  psVar1 = _DAT_1009feac;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b5) != '\0')) {
    *_DAT_1009ffb4 = *_DAT_1009ffb4 + -1;
    *(short *)((int)piVar2 + *psVar1 * 2 + 0x306) =
         *(short *)((int)piVar2 + *psVar1 * 2 + 0x306) + 1;
  }
  *piVar2 = *piVar2 + 0x5dc;
  *(undefined1 *)(param_1 + 0xe9) = 1;
  *(undefined1 *)(param_1 + 0xea) = 1;
  return;
}


// ==== .HitDilloTileSprite @ 1008763c ====

void _HitDilloTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  char cVar1;
  short sStack_46;
  short sStack_44;
  undefined1 auStack_26 [26];
  
  sStack_44 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_46 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  .glue::SetRect(auStack_26,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                 (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
  if (param_4 == 1) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_46,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 100) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_46,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 200) {
    .debug::_WallBounceBG(param_1,param_3 + -100,&stack0x0000001c,&sStack_46,0,param_1 + 0x34,0,0);
  }
  else {
    cVar1 = .debug::_IsWaterTile(param_3);
    if ((cVar1 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
      .debug::_HandleUnderWater(param_1,param_2);
    }
  }
  return;
}


// ==== .SetupWarriorSprite @ 100878ac ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupWarriorSprite(int param_1)

{
  short *psVar1;
  char *pcVar2;
  undefined1 *puVar3;
  int *piVar4;
  undefined4 *puVar5;
  undefined *puVar6;
  undefined *puVar7;
  undefined *puVar8;
  undefined *puVar9;
  int iVar10;
  int iVar11;
  undefined *puVar12;
  undefined2 uVar13;
  ushort uVar14;
  
  puVar12 = PTR_DAT_100a0d50;
  puVar5 = _DAT_100a0058;
  .debug::_InitSprite();
  puVar6 = PTR_PTR_100a0494;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar9 = PTR_PTR_100a0d44;
  *(undefined2 *)(param_1 + 0x86) = 0;
  puVar8 = PTR_PTR_100a0d40;
  *(undefined4 *)(param_1 + 0x80) = 0xc;
  puVar7 = PTR_PTR_100a0d3c;
  *(undefined **)(param_1 + 0x4c) = puVar6;
  iVar11 = _DAT_100a0d4c;
  *(undefined **)(param_1 + 0x5c) = puVar9;
  iVar10 = _DAT_100a0d48;
  *(undefined **)(param_1 + 0x1f8) = puVar8;
  *(undefined **)(param_1 + 0x50) = puVar7;
  *(undefined1 *)(param_1 + 0x18a) = 1;
  puVar12[1] = 1;
  *(undefined1 *)(iVar11 + 1) = 1;
  *(undefined1 *)(iVar10 + 1) = 1;
  *(int *)(param_1 + 0x170) =
       (int)*(short *)(*(int *)*puVar5 + *(short *)(param_1 + 0x48) * 0x10 + 0xe);
  *(undefined2 *)(param_1 + 0x110) = 0x122;
  *(undefined4 *)(param_1 + 0xc0) = 0;
  puVar3 = _DAT_1009fed0;
  if (*(int *)(param_1 + 0x170) == 0) {
    *(undefined2 *)(param_1 + 0xa4) = 0x4b0;
  }
  else {
    *(undefined2 *)(param_1 + 0xa4) = 2000;
    *puVar3 = 0;
    *(undefined1 *)(param_1 + 0x88) = 0;
  }
  *(undefined1 *)(param_1 + 0x1b4) = 1;
  *(int *)(param_1 + 0x168) = (int)*(short *)(param_1 + 0xa4);
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  .glue::SetRect(param_1 + 0x34,0x1a,0x17,0x4a,0x3a);
  *(undefined4 *)(param_1 + 0x150) = 0xffffffff;
  *(undefined2 *)(param_1 + 0xb0) = 6;
  *(undefined2 *)(param_1 + 0xb2) = 0;
  *(undefined2 *)(param_1 + 0x46) = 2;
  *(undefined4 *)(param_1 + 0x14c) = 0;
  uVar13 = .debug::_FastRand(10);
  *(undefined2 *)(param_1 + 0xa6) = uVar13;
  psVar1 = (short *)(*(int *)*puVar5 + *(short *)(param_1 + 0x48) * 0x10 + 10);
  if (*psVar1 == 0) {
    *psVar1 = 0x96;
  }
  *(int *)(param_1 + 0x15c) = *(short *)(param_1 + 0xc) + -0x15e;
  *(int *)(param_1 + 0x160) = *(short *)(param_1 + 0xc) + 0x15e;
  *(int *)(param_1 + 0x168) = (int)*(short *)(param_1 + 0xc);
  *(undefined4 *)(param_1 + 0x164) = 0;
  uVar14 = .debug::_FastRand(100);
  pcVar2 = _DAT_1009fe8c;
  *(byte *)(param_1 + 0x17e) = (uVar14 < 0x33) - ((char)~(byte)((short)uVar14 >> 0xf) >> 7) & 1;
  *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar12 + 4);
  *(undefined4 *)(param_1 + 0xf0) = 0x1e;
  piVar4 = _DAT_1009ffb4;
  if (*pcVar2 != '\0') {
    *(undefined1 *)(param_1 + 0x1b5) = 1;
    *piVar4 = *piVar4 + 1;
  }
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  return;
}


// ==== .HandleWarriorSprite @ 10087c04 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleWarriorSprite(int param_1)

{
  ushort uVar1;
  ushort *puVar2;
  undefined4 *puVar3;
  undefined *puVar4;
  int iVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  short sVar8;
  short sVar9;
  undefined8 uStack_28;
  undefined8 uStack_20;
  
  puVar4 = PTR_DAT_100a0d50;
  uVar7 = _DAT_1009ff34;
  puVar2 = _DAT_1009fd94;
  if (*(char *)(param_1 + 0xe9) != '\0') {
    return;
  }
  if (*(char *)(param_1 + 0x1b2) != '\0') {
    return;
  }
  .debug::_StandardSpriteHandles(param_1);
  .glue::SetRect(param_1 + 0x34,0x2a,0x3c,0x89,0x88);
  if (*(char *)(param_1 + 0x17e) == '\0') {
    *(short *)(param_1 + 0x36) = *(short *)(param_1 + 0x36) + -10;
  }
  else {
    *(short *)(param_1 + 0x3a) = *(short *)(param_1 + 0x3a) + 10;
  }
  if (*(int *)(param_1 + 0x170) != 0) {
    if ((*(int *)(param_1 + 0x1d4) != 0) && (*(char *)(*(int *)(param_1 + 0x1d4) + 0xe9) != '\0')) {
      *(undefined4 *)(param_1 + 0x1d4) = 0;
    }
    if ((*(int *)(param_1 + 0x1d8) != 0) && (*(char *)(*(int *)(param_1 + 0x1d8) + 0xe9) != '\0')) {
      *(undefined4 *)(param_1 + 0x1d8) = 0;
    }
    if ((*(int *)(param_1 + 0x1dc) != 0) && (*(char *)(*(int *)(param_1 + 0x1dc) + 0xe9) != '\0')) {
      *(undefined4 *)(param_1 + 0x1dc) = 0;
    }
    if (((*(int *)(param_1 + 0x1d4) == 0) || (*(int *)(param_1 + 0x1d8) == 0)) ||
       (*(int *)(param_1 + 0x1dc) == 0)) {
      *(int *)(param_1 + 0x16c) = *(int *)(param_1 + 0x16c) + -1;
      if (*(int *)(param_1 + 0x16c) < 1) {
        if (*(int *)(param_1 + 0x1d4) == 0) {
          uVar6 = .debug::_MTNewSprite
                            (0x433,*(int *)(param_1 + 0x168) + -0xba,*(short *)(param_1 + 10) + -400
                             ,9,0xffffffff,uVar7);
          *(undefined4 *)(param_1 + 0x1d4) = uVar6;
        }
        if (*(int *)(param_1 + 0x1d8) == 0) {
          uVar6 = .debug::_MTNewSprite
                            (0x433,*(int *)(param_1 + 0x168) + 0x46,*(short *)(param_1 + 10) + -500,
                             9,0xffffffff,uVar7);
          *(undefined4 *)(param_1 + 0x1d8) = uVar6;
        }
        if (*(int *)(param_1 + 0x1dc) == 0) {
          uVar7 = .debug::_MTNewSprite
                            (0x433,*(int *)(param_1 + 0x168) + 0x146,*(short *)(param_1 + 10) + -400
                             ,9,0xffffffff,uVar7);
          *(undefined4 *)(param_1 + 0x1dc) = uVar7;
        }
      }
    }
    else {
      *(undefined4 *)(param_1 + 0x16c) = 0xf;
    }
    *(int *)(param_1 + 0xf0) = *(int *)(param_1 + 0xf0) + -1;
    iVar5 = *(int *)(param_1 + 0xf0);
    if (iVar5 < 4) {
      if (0 < iVar5) {
        if (*(short *)(param_1 + 0xa4) < 0x3e9) {
          *(undefined4 *)(param_1 + 0xb8) = 0x10008;
        }
        goto LAB_10087e90;
      }
    }
    else if (iVar5 < 7) {
      if (*(short *)(param_1 + 0xa4) < 0x3e9) {
        *(undefined4 *)(param_1 + 0xb8) = 0x10009;
      }
      goto LAB_10087e90;
    }
    if (*(int *)(param_1 + 0xf0) < 1) {
      if (*(short *)(param_1 + 0xa4) < 0x1f5) {
        *(undefined4 *)(param_1 + 0xf0) = 0xf;
      }
      else {
        *(undefined4 *)(param_1 + 0xf0) = 0x1e;
      }
      *(undefined4 *)(param_1 + 0xb8) = 0;
    }
  }
LAB_10087e90:
  iVar5 = _DAT_100a0d48;
  sVar8 = *(short *)(param_1 + 0xb0);
  if (sVar8 != 5) {
    if (sVar8 < 5) {
      if (sVar8 != 3) {
        if (sVar8 < 3) {
          if (1 < sVar8) {
            uStack_28 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
            *(int *)(param_1 + 0x24) = (int)((uStack_28 - dRam100a1c28) * dRam100a1c38);
            if (*(short *)(param_1 + 0x46) < 2) {
              *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar4 + 4);
              uVar1 = *puVar2;
              *(byte *)(param_1 + 0x17e) =
                   (uVar1 <= *(ushort *)(param_1 + 0x10)) -
                   ((char)~(byte)((short)(uVar1 ^ *(ushort *)(param_1 + 0x10)) >> 0xf) >> 7) & 1;
            }
            else {
              if (*(short *)(param_1 + 0x46) == 7) {
                sVar8 = .debug::_FastRand(6000);
                .debug::_STPlay3DSoundPitched
                          (*_DAT_100a0268,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar8 + 50000);
              }
              *(undefined4 *)(param_1 + 0xc0) =
                   *(undefined4 *)(_DAT_100a0d4c + ((int)*(short *)(param_1 + 0x46) >> 1) * 4);
              if (*(short *)(param_1 + 0x46) == 9) {
                if (*(char *)(param_1 + 0x17e) == '\0') {
                  iVar5 = -0x30;
                }
                else {
                  iVar5 = 0x30;
                }
                iVar5 = .debug::_MTNewSprite
                                  (0x71f,*(short *)(param_1 + 0x10) + iVar5 + -0x18,
                                   *(short *)(param_1 + 0xe) + -0x25,0,0xffffffff,PTR_PTR_100a0830);
                *(undefined4 *)(iVar5 + 0x24) = 0xb00;
                if (*(char *)(param_1 + 0x17e) == '\0') {
                  *(int *)(iVar5 + 0x24) = -*(int *)(iVar5 + 0x24);
                }
              }
              if (0x10 < *(short *)(param_1 + 0x46)) {
                *(undefined2 *)(param_1 + 0x46) = 0;
                *(int *)(param_1 + 0x14c) = *(int *)(param_1 + 0x14c) + -1;
                if (*(int *)(param_1 + 0x14c) < 1) {
                  *(undefined2 *)(param_1 + 0xb0) = 6;
                  sVar8 = .debug::_FastRand(9);
                  *(short *)(param_1 + 0xa6) = sVar8 + 4;
                }
              }
            }
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
          }
        }
        else {
          uStack_28 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
          *(int *)(param_1 + 0x24) = (int)((uStack_28 - dRam100a1c28) * dRam100a1c30);
          *(undefined4 *)(param_1 + 0xc0) =
               *(undefined4 *)(iVar5 + ((int)*(short *)(param_1 + 0x46) >> 2) * 4 + 4);
          *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
          if (0x17 < *(short *)(param_1 + 0x46)) {
            *(undefined2 *)(param_1 + 0x46) = 0x17;
          }
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
          if (*(short *)(param_1 + 0xa6) == 0x2d) {
            *(undefined2 *)(param_1 + 0x1a2) = 1;
          }
        }
      }
    }
    else if (sVar8 == 7) {
      if (*(int *)(param_1 + 0x14c) == 0) {
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(puVar4 + ((int)*(short *)(param_1 + 0x46) >> 1) * 4 + 4);
        if (0xe < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
          if ((*(int *)(param_1 + 0x160) < (int)*(short *)(param_1 + 0xc)) ||
             ((int)*(short *)(param_1 + 0xc) < *(int *)(param_1 + 0x15c))) {
            *(undefined2 *)(param_1 + 0xa6) = 0;
          }
          if (*(short *)(param_1 + 0xa6) == 0) {
            *(undefined2 *)(param_1 + 0xb0) = 6;
            sVar8 = .debug::_FastRand(9);
            *(short *)(param_1 + 0xa6) = sVar8 + 4;
          }
        }
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (*(char *)(param_1 + 0x17e) == '\0') {
          *(undefined4 *)(param_1 + 0x24) = 0xfffffa00;
        }
        else {
          *(undefined4 *)(param_1 + 0x24) = 0x600;
        }
      }
      else {
        *(undefined4 *)(param_1 + 0xc0) =
             *(undefined4 *)(puVar4 + *(short *)(param_1 + 0x46) * 4 + 4);
        if (6 < *(short *)(param_1 + 0x46)) {
          *(undefined2 *)(param_1 + 0x46) = 0;
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
          if ((*(int *)(param_1 + 0x160) < (int)*(short *)(param_1 + 0xc)) ||
             ((int)*(short *)(param_1 + 0xc) < *(int *)(param_1 + 0x15c))) {
            *(undefined2 *)(param_1 + 0xa6) = 0;
          }
          if (*(short *)(param_1 + 0xa6) == 0) {
            *(undefined2 *)(param_1 + 0xb0) = 6;
            sVar8 = .debug::_FastRand(9);
            *(short *)(param_1 + 0xa6) = sVar8 + 4;
          }
        }
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        if (*(char *)(param_1 + 0x17e) == '\0') {
          *(undefined4 *)(param_1 + 0x24) = 0xfffff400;
        }
        else {
          *(undefined4 *)(param_1 + 0x24) = 0xc00;
        }
      }
    }
    else if (sVar8 < 7) {
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar4 + 4);
      if (0 < *(short *)(param_1 + 0xa6)) {
        *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
      }
      if (*PTR_DAT_1009fed4 == '\0') {
        return;
      }
      if (*(short *)(param_1 + 0xa6) < 1) {
        sVar8 = .debug::_FastRand(100);
        iVar5 = (int)*_DAT_1009fd90 - (int)*(short *)(param_1 + 0xe);
        if (iVar5 < 1) {
          iVar5 = -iVar5;
        }
        if (iVar5 < 0x50) {
          uVar1 = *puVar2;
          sVar9 = 0x41;
          *(byte *)(param_1 + 0x17e) =
               (uVar1 <= *(ushort *)(param_1 + 0x10)) -
               ((char)~(byte)((short)(uVar1 ^ *(ushort *)(param_1 + 0x10)) >> 0xf) >> 7) & 1;
        }
        else {
          sVar9 = 0x13;
        }
        if (*_DAT_1009ffa8 != '\0') {
          sVar9 = -1;
        }
        if ((int)sVar9 < (int)sVar8) {
          *(undefined2 *)(param_1 + 0xb0) = 7;
          *(undefined2 *)(param_1 + 0x46) = 1;
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar4 + 4);
          sVar8 = .debug::_FastRand(3);
          *(short *)(param_1 + 0xa6) = sVar8 + 2;
          sVar8 = .debug::_FastRand(100);
          if (100 - sVar9 < (int)sVar8) {
            *(undefined4 *)(param_1 + 0x14c) = 1;
          }
          else {
            *(undefined4 *)(param_1 + 0x14c) = 0;
            sVar8 = .debug::_FastRand(100);
            if (0x50 < sVar8) {
              .debug::_WarriorLayEgg(param_1);
            }
          }
          if (*(int *)(param_1 + 0x160) < (int)*(short *)(param_1 + 0xc)) {
            *(undefined1 *)(param_1 + 0x17e) = 0;
          }
          else if ((int)*(short *)(param_1 + 0xc) < *(int *)(param_1 + 0x15c)) {
            *(undefined1 *)(param_1 + 0x17e) = 1;
          }
        }
        else {
          .debug::_RandomWarriorAttack(param_1);
        }
      }
      uStack_20 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
      *(int *)(param_1 + 0x24) = (int)((uStack_20 - dRam100a1c28) * dRam100a1c40);
    }
  }
  puVar3 = _DAT_100a026c;
  if ((*(short *)(param_1 + 0xa4) < 1) && (*(short *)(param_1 + 0xb0) != 4)) {
    *(undefined2 *)(param_1 + 0xb0) = 4;
    *(undefined2 *)(param_1 + 0x46) = 0;
    *(undefined2 *)(param_1 + 0xa6) = 0;
    .debug::_STPlay3DSound(*puVar3,1,0x100,*(undefined4 *)(param_1 + 0xe));
  }
  .debug::_ApplyGravityAndSeparateFromTiles(param_1);
  puVar3 = _DAT_100a0274;
  if ((*(int *)(param_1 + 0x11c) != 0) &&
     (((*(int *)(param_1 + 0x11c) == 1 && (*(short *)(param_1 + 0x128) == 0)) ||
      (0 < *(short *)(param_1 + 0x128))))) {
    sVar8 = *(short *)(param_1 + 0x128);
    if (sVar8 == 3) {
      if (*(short *)(param_1 + 0xa4) < 500) {
        *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + 4;
      }
    }
    else if (((sVar8 < 3) && (1 < sVar8)) && (*(short *)(param_1 + 0x116) == 0)) {
      *(undefined2 *)(param_1 + 0x116) = 0x13;
      *(short *)(param_1 + 0xa4) = *(short *)(param_1 + 0xa4) + -100;
      *(undefined2 *)(param_1 + 0xaa) = 0x11;
      .debug::_STPlay3DSound(*puVar3,1,0x55,*(undefined4 *)(param_1 + 0xe));
    }
  }
  .debug::_StandardSpriteCleanup(param_1);
  return;
}


// ==== .HitWarriorSprite @ 1008854c ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitWarriorSprite(int param_1,int param_2)

{
  short sVar1;
  short sVar2;
  undefined *puVar3;
  short sStack_12;
  short sStack_10;
  
  puVar3 = *(undefined **)(param_2 + 0x4c);
  if (((puVar3 == PTR_PTR_100a04e8) && (*(short *)(param_2 + 0xa6) == 0)) &&
     (0 < *(short *)(param_1 + 0xa4))) {
    .debug::_KillPlayerShot(param_2,0,1);
    .debug::_STPlay3DSound(*_DAT_100a041c,1,0x100,*(undefined4 *)(param_2 + 0xe));
  }
  else if ((puVar3 == PTR_PTR_100a01f8) || (puVar3 == PTR_PTR_100a0484)) {
    sStack_10 = *(short *)(param_1 + 0x36) +
                (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
    sStack_12 = *(short *)(param_1 + 0x34) +
                (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
    sVar1 = .debug::_PlatformBounce(param_1,param_2,&sStack_12,0,param_1 + 0x34,0);
    if ((sVar1 == 2) && ((0 < *(int *)(param_2 + 0x2c) || (*(char *)(param_1 + 0xce) != '\0')))) {
      .debug::_HurtSprite(param_1,200,(int)(short)(*(int *)(param_2 + 0x24) >> 1),0xfffffc18,2,8);
      *(undefined4 *)(param_1 + 0xf0) = 0;
      .debug::_KillBox(param_2);
      sVar1 = .debug::_FastRand(10000);
      .debug::_STPlay3DSoundPitched
                (*_DAT_100a0274,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar1 + 42000);
      sVar1 = .debug::_FastRand(10000);
      sVar2 = .debug::_FastRand(2);
      .debug::_STPlay3DSoundPitched
                (*(undefined4 *)(_DAT_100a0320 + sVar2 * 4),1,0x100,*(undefined4 *)(param_1 + 0xe),
                 sVar1 + 42000);
    }
  }
  return;
}


// ==== .KillWarrior @ 1008874c ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _KillWarrior(int param_1)

{
  short *psVar1;
  undefined1 *puVar2;
  undefined2 *puVar3;
  int iVar4;
  
  iVar4 = _DAT_1009ffc0;
  psVar1 = _DAT_1009feac;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b5) != '\0')) {
    *_DAT_1009ffb4 = *_DAT_1009ffb4 + -1;
    iVar4 = iVar4 + *psVar1 * 2;
    *(short *)(iVar4 + 0x306) = *(short *)(iVar4 + 0x306) + 1;
  }
  *(undefined1 *)(param_1 + 0xe9) = 1;
  *(undefined1 *)(param_1 + 0xea) = 1;
  if (*(int *)(param_1 + 0x170) != 0) {
    .debug::_STPlay3DSoundPitched(*_DAT_1009fd68,1,0x100,*(undefined4 *)(param_1 + 0xe),48000);
    puVar3 = _DAT_100a00fc;
    *_DAT_1009ffa0 = 0x1e;
    puVar2 = _DAT_1009fed0;
    *puVar3 = 3;
    *puVar2 = 1;
  }
  return;
}


// ==== .HitWarriorTileSprite @ 10088834 ====

void _HitWarriorTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  char cVar1;
  short sStack_46;
  short sStack_44;
  undefined1 auStack_26 [26];
  
  sStack_44 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_46 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  .glue::SetRect(auStack_26,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                 (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
  if (param_4 == 1) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_46,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 100) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_46,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 200) {
    .debug::_WallBounceBG(param_1,param_3 + -100,&stack0x0000001c,&sStack_46,0,param_1 + 0x34,0,0);
  }
  else {
    cVar1 = .debug::_IsWaterTile(param_3);
    if ((cVar1 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
      .debug::_HandleUnderWater(param_1,param_2);
    }
  }
  return;
}


// ==== .SetupCrabSprite @ 100894e4 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupCrabSprite(int param_1)

{
  undefined4 uVar1;
  undefined *puVar2;
  undefined *puVar3;
  short sVar4;
  char cVar7;
  undefined4 uVar5;
  int iVar6;
  int iVar8;
  
  uVar1 = _DAT_1009fef0;
  .debug::_InitSprite();
  puVar2 = PTR_PTR_100a046c;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar3 = PTR_PTR_100a0d58;
  *(undefined2 *)(param_1 + 0x86) = 0;
  *(undefined4 *)(param_1 + 0x80) = 8;
  *(undefined **)(param_1 + 0x4c) = puVar2;
  *(undefined **)(param_1 + 0x5c) = puVar3;
  *(undefined4 *)(param_1 + 0x1f8) = 0;
  *(undefined2 *)(param_1 + 0xa4) = 1000;
  *(undefined2 *)(param_1 + 0x110) = 0;
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  .glue::SetRect(param_1 + 0x34,0x18,0x18,0x4c,0x4c);
  puVar2 = PTR_DAT_100a0d60;
  *(undefined4 *)(param_1 + 0x150) = 0xffffffff;
  iVar6 = _DAT_100a0d5c;
  *(undefined2 *)(param_1 + 0xb0) = 0;
  *(undefined2 *)(param_1 + 0xb2) = 0;
  *(undefined2 *)(param_1 + 0x46) = 2;
  puVar2[1] = 1;
  *(undefined1 *)(iVar6 + 1) = 1;
  *(undefined4 *)(param_1 + 0xc0) = 0;
  .debug::_GetBGTile((int)(*(short *)(param_1 + 0xc) >> 5),(int)(*(short *)(param_1 + 10) >> 5));
  .debug::_LookupBGTileKind();
  cVar7 = .debug::_IsWaterTile();
  if (cVar7 == '\0') {
    *(undefined4 *)(param_1 + 0x16c) = 0;
  }
  else {
    *(undefined4 *)(param_1 + 0x16c) = 1;
  }
  if (0x766 < *(short *)(param_1 + 4)) {
    if (*(short *)(param_1 + 4) == 0x767) {
      .glue::SetRect(param_1 + 0x34,0,0,0,0);
      puVar2 = PTR_PTR_100a0d54;
      *(undefined4 *)(param_1 + 0x5c) = 0;
      *(undefined4 *)(param_1 + 0x1f8) = 0;
      *(undefined **)(param_1 + 0x4c) = puVar2;
    }
    goto LAB_100897d8;
  }
  *(int *)(param_1 + 0x14c) =
       (int)*(short *)(*(int *)*_DAT_100a0058 + *(short *)(param_1 + 0x48) * 0x10 + 8);
  if (*(int *)(param_1 + 0x14c) == 0) {
    *(undefined4 *)(param_1 + 0x14c) = 100;
  }
  *(int *)(param_1 + 0x150) = (int)*(short *)(param_1 + 0xc);
  *(int *)(param_1 + 0x154) = (int)*(short *)(param_1 + 10);
  uVar5 = .debug::_AllocateGameMem(0x34);
  *(undefined4 *)(param_1 + 0x9c) = uVar5;
  iVar6 = *(int *)(param_1 + 0x14c) + 0x17;
  iVar6 = iVar6 / 0x18 + (iVar6 >> 0x1f);
  if (iVar6 - (iVar6 >> 0x1f) < 0xc) {
    sVar4 = (short)iVar6 - (short)(iVar6 >> 0x1f);
  }
  else {
    sVar4 = 0xc;
  }
  *(short *)(*(int *)(param_1 + 0x9c) + 0x30) = sVar4;
  iVar6 = 0;
  for (sVar4 = 0; iVar8 = (int)*(short *)(*(int *)(param_1 + 0x9c) + 0x30), sVar4 < iVar8;
      sVar4 = sVar4 + 1) {
    uVar5 = .debug::_MTNewSprite
                      (0x767,*(short *)(param_1 + 0xc) + 0x1e,*(short *)(param_1 + 10) + 0x1e,
                       *(int *)(param_1 + 0x80) + -1,0x1ff,uVar1);
    *(undefined4 *)(*(int *)(param_1 + 0x9c) + iVar6) = uVar5;
    if (*(int *)(param_1 + 0x16c) != 0) {
      *(undefined4 *)(*(int *)(*(int *)(param_1 + 0x9c) + iVar6) + 0xb8) = 0x90000;
    }
    iVar6 = iVar6 + 4;
  }
  iVar6 = iVar8 << 2;
  for (; (short)iVar8 < 0xc; iVar8 = iVar8 + 1) {
    *(undefined4 *)(*(int *)(param_1 + 0x9c) + iVar6) = 0;
    iVar6 = iVar6 + 4;
  }
  if (*(int *)(param_1 + 0x16c) != 0) {
    *(undefined4 *)(param_1 + 0xb8) = 0x90000;
  }
  sVar4 = *(short *)(param_1 + 4);
  if (sVar4 == 0x764) {
LAB_1008977c:
    *(undefined2 *)(param_1 + 0x46) = 0x5a;
  }
  else if (sVar4 < 0x764) {
    if (sVar4 == 0x762) {
      *(undefined2 *)(param_1 + 0x46) = 0;
    }
    else if (0x761 < sVar4) {
      *(undefined2 *)(param_1 + 0x46) = 0xb4;
    }
  }
  else {
    if (sVar4 == 0x766) goto LAB_1008977c;
    if (sVar4 < 0x766) {
      *(undefined2 *)(param_1 + 0x46) = 0x10e;
    }
  }
  *(undefined2 *)(param_1 + 0xa6) = 0;
  *(undefined2 *)(param_1 + 0xb0) = 0;
  *(undefined4 *)(param_1 + 0x15c) = 0;
LAB_100897d8:
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  return;
}


// ==== .HandleCrabSprite @ 10089828 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleCrabSprite(int param_1)

{
  bool bVar1;
  undefined *puVar2;
  short sVar4;
  int iVar3;
  int iVar5;
  int iVar6;
  int *piVar7;
  short sVar8;
  int *piVar9;
  float fStack_38;
  float fStack_34;
  longlong lStack_30;
  longlong lStack_28;
  undefined4 uStack_20;
  uint uStack_1c;
  
  puVar2 = PTR_DAT_100a0d60;
  piVar9 = *(int **)(param_1 + 0x9c);
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b2) == '\0')) {
    .debug::_StandardSpriteHandles(param_1);
    sVar8 = *(short *)(param_1 + 0xb0);
    if (sVar8 == 1) {
      *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
      sVar8 = *(short *)(param_1 + 0xa6);
      iVar3 = (int)sVar8;
      if (iVar3 < 6) {
        if (4 < iVar3) {
          iVar3 = 5;
        }
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar2 + iVar3 * 4 + 4);
      }
      else {
        iVar3 = (int)(short)(sVar8 + -5);
        if (iVar3 == 1) {
          iVar6 = (int)*(short *)(param_1 + 0x46) / 10 + ((int)*(short *)(param_1 + 0x46) >> 0x1f);
          iVar5 = (iVar6 - (iVar6 >> 0x1f)) + 0x12;
          uStack_1c = *(uint *)(param_1 + 0x14c) ^ 0x80000000;
          iVar6 = iVar5 / 0x24 + (iVar5 >> 0x1f);
          uStack_20 = 0x43300000;
          FUN_100417bc((int)(short)((short)iVar5 + ((short)iVar6 - (short)(iVar6 >> 0x1f)) * -0x24),
                       iVar5,&fStack_34,&fStack_38);
          lStack_28 = (longlong)(int)fStack_34;
          *(int *)(param_1 + 0x16c) = (int)fStack_34;
          lStack_30 = (longlong)(int)fStack_38;
          *(int *)(param_1 + 0x170) = (int)fStack_38;
        }
        if (iVar3 < 0xd) {
          iVar5 = *(int *)(param_1 + 0x16c) * iVar3 * iVar3;
          iVar6 = *(int *)(param_1 + 0x170) * iVar3 * iVar3;
          iVar3 = iVar5 / 0x90 + (iVar5 >> 0x1f);
          *(short *)(param_1 + 0xc) =
               (short)*(undefined4 *)(param_1 + 0x150) + ((short)iVar3 - (short)(iVar3 >> 0x1f));
          iVar3 = iVar6 / 0x90 + (iVar6 >> 0x1f);
          *(short *)(param_1 + 10) =
               (short)*(undefined4 *)(param_1 + 0x154) + ((short)iVar3 - (short)(iVar3 >> 0x1f));
          *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
          *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
        }
        else if (iVar3 < 0x19) {
          iVar3 = 0x11 - iVar3;
          if (iVar3 < 1) {
            iVar3 = 0;
          }
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar2 + iVar3 * 4 + 4);
          iVar6 = 0x90 - (int)(short)(sVar8 + -0x11) * (int)(short)(sVar8 + -0x11);
          iVar3 = *(int *)(param_1 + 0x16c) * iVar6;
          iVar6 = *(int *)(param_1 + 0x170) * iVar6;
          iVar3 = iVar3 / 0x90 + (iVar3 >> 0x1f);
          *(short *)(param_1 + 0xc) =
               (short)*(undefined4 *)(param_1 + 0x150) + ((short)iVar3 - (short)(iVar3 >> 0x1f));
          iVar3 = iVar6 / 0x90 + (iVar6 >> 0x1f);
          *(short *)(param_1 + 10) =
               (short)*(undefined4 *)(param_1 + 0x154) + ((short)iVar3 - (short)(iVar3 >> 0x1f));
          *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
          *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
        }
        else {
          *(undefined2 *)(param_1 + 0xb0) = 0;
          *(undefined2 *)(param_1 + 0xa6) = 10;
        }
      }
    }
    else if ((sVar8 < 1) && (-1 < sVar8)) {
      bVar1 = false;
      sVar4 = .debug::_FindDesiredDirectionGeneric
                        (*(undefined4 *)(param_1 + 0xe),*(undefined4 *)(*_DAT_1009fdd8 + 0xe));
      sVar8 = *(short *)(param_1 + 4);
      if (sVar8 == 0x764) {
        bVar1 = false;
        if ((0 < sVar4) && (sVar4 < 0x12)) {
          bVar1 = true;
        }
      }
      else if (sVar8 < 0x764) {
        if (sVar8 == 0x762) {
          bVar1 = true;
          if ((8 < sVar4) && (sVar4 < 0x1c)) {
            bVar1 = false;
          }
        }
        else if (((0x761 < sVar8) && (bVar1 = false, 9 < sVar4)) && (sVar4 < 0x1b)) {
          bVar1 = true;
        }
      }
      else if (sVar8 == 0x766) {
        bVar1 = true;
      }
      else if (((sVar8 < 0x766) && (bVar1 = false, 0x12 < sVar4)) && (sVar4 < 0x24)) {
        bVar1 = true;
      }
      if (bVar1) {
        iVar6 = (int)*(short *)(param_1 + 0x46);
        iVar3 = (int)(short)(sVar4 * 10);
        if (iVar6 < iVar3) {
          iVar6 = iVar6 - iVar3;
          if (iVar6 < 1) {
            iVar6 = -iVar6;
          }
          if (iVar6 < 0xb4) {
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 5;
          }
          else {
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -5;
          }
        }
        else if (iVar3 < iVar6) {
          iVar6 = iVar6 - iVar3;
          if (iVar6 < 1) {
            iVar6 = -iVar6;
          }
          if (iVar6 < 0xb4) {
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -5;
          }
          else {
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 5;
          }
        }
        sVar8 = *(short *)(param_1 + 0x46);
        if (sVar8 < 0) {
          *(short *)(param_1 + 0x46) = sVar8 + 0x168;
        }
        else if (0x167 < sVar8) {
          *(short *)(param_1 + 0x46) = sVar8 + -0x168;
        }
      }
      if (*(short *)(param_1 + 4) == 0x763) {
        *(undefined1 *)(param_1 + 0x17e) = 1;
        iVar3 = *(short *)(param_1 + 0x46) + 0xb4;
        *(short *)(param_1 + 0x1aa) =
             (short)iVar3 +
             ((short)((ulonglong)((longlong)iVar3 * 0xb60b60b7) >> 0x28) -
             (short)(iVar3 / 0x168 + (iVar3 >> 0x1f) >> 0x1f)) * -0x168;
      }
      else {
        *(undefined2 *)(param_1 + 0x1aa) = *(undefined2 *)(param_1 + 0x46);
      }
      if (*(short *)(param_1 + 0xa6) < 1) {
        if ((*(short *)(param_1 + 0x46) == (short)(sVar4 * 10)) &&
           (iVar3 = .debug::_PEDistance((int)*_DAT_1009fd94 - (int)*(short *)(param_1 + 0x10),
                                        (int)*_DAT_1009fd90 - (int)*(short *)(param_1 + 0xe)),
           iVar3 <= *(int *)(param_1 + 0x14c) + 0x36)) {
          *(undefined2 *)(param_1 + 0xa6) = 0;
          *(undefined2 *)(param_1 + 0xb0) = 1;
        }
      }
      else {
        *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
      }
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar2 + 4);
    }
    piVar7 = piVar9;
    for (sVar8 = 0; iVar3 = (int)*(short *)(piVar9 + 0xc), sVar8 < iVar3; sVar8 = sVar8 + 1) {
      iVar3 = iVar3 + 1;
      iVar6 = *(int *)(param_1 + 0x154);
      sVar4 = *(short *)(param_1 + 10);
      *(short *)(*piVar7 + 0xc) =
           (short)*(int *)(param_1 + 0x150) +
           (short)((((int)*(short *)(param_1 + 0xc) - *(int *)(param_1 + 0x150)) * (int)sVar8) /
                  iVar3) + 0x1e;
      *(short *)(*piVar7 + 10) =
           (short)*(undefined4 *)(param_1 + 0x154) +
           (short)(((sVar4 - iVar6) * (int)sVar8) / iVar3) + 0x1e;
      piVar7 = piVar7 + 1;
    }
    if (*(short *)(param_1 + 0xa4) < 1) {
      *(undefined2 *)(param_1 + 0xb0) = 3;
    }
    .debug::_StandardSpriteCleanup(param_1);
  }
  return;
}


// ==== .HandleCrabSegSprite @ 10089dec ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleCrabSegSprite(int param_1)

{
  *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0d5c + 4);
  return;
}


// ==== .HitCrabSprite @ 10089e24 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitCrabSprite(int param_1,int param_2)

{
  if (((*(undefined **)(param_2 + 0x4c) == PTR_PTR_100a04e8) && (*(short *)(param_2 + 0xa6) == 0))
     && (0 < *(short *)(param_1 + 0xa4))) {
    .debug::_KillPlayerShot(param_2,1,1);
    .debug::_STPlay3DSound(*_DAT_100a041c,1,0xab,*(undefined4 *)(param_1 + 0xe));
  }
  return;
}


// ==== .SetupDemonSprite @ 1008a0ac ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupDemonSprite(int param_1)

{
  undefined1 *puVar1;
  undefined4 *puVar2;
  undefined *puVar3;
  int iVar4;
  int iVar5;
  undefined *puVar6;
  undefined *puVar7;
  int iVar8;
  int iVar9;
  int iVar10;
  undefined *puVar11;
  undefined2 uVar14;
  undefined4 uVar12;
  undefined4 uVar13;
  int iVar15;
  short sVar16;
  int *piVar17;
  int *piVar18;
  
  puVar2 = _DAT_100a0058;
  uVar13 = _DAT_1009fee8;
  .debug::_InitSprite();
  puVar3 = PTR_PTR_100a04b0;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar7 = PTR_PTR_100a0d6c;
  *(undefined2 *)(param_1 + 0x86) = 0;
  puVar6 = PTR_PTR_100a0d68;
  *(undefined4 *)(param_1 + 0x80) = 0xc;
  puVar11 = PTR_DAT_100a0d84;
  *(undefined **)(param_1 + 0x4c) = puVar3;
  iVar15 = _DAT_100a0d80;
  *(undefined **)(param_1 + 0x5c) = puVar7;
  iVar10 = _DAT_100a0d7c;
  *(undefined4 *)(param_1 + 0x1f8) = 0;
  iVar9 = _DAT_100a0d78;
  *(undefined **)(param_1 + 0x50) = puVar6;
  iVar8 = _DAT_100a0d74;
  *(undefined1 *)(param_1 + 0x18a) = 1;
  iVar5 = _DAT_100a0848;
  puVar11[1] = 1;
  iVar4 = _DAT_100a0844;
  *(undefined1 *)(iVar15 + 1) = 1;
  iVar15 = _DAT_100a0840;
  *(undefined1 *)(iVar10 + 1) = 1;
  *(undefined1 *)(iVar9 + 1) = 1;
  *(undefined1 *)(iVar8 + 1) = 1;
  *(undefined1 *)(iVar5 + 1) = 1;
  *(undefined1 *)(iVar4 + 1) = 1;
  *(undefined1 *)(iVar15 + 1) = 1;
  *(int *)(param_1 + 0x170) =
       (int)*(short *)(*(int *)*puVar2 + *(short *)(param_1 + 0x48) * 0x10 + 0xe);
  *(undefined2 *)(param_1 + 0x110) = 0;
  *(undefined4 *)(param_1 + 0xc0) = 0;
  puVar1 = _DAT_1009fed0;
  if (*(int *)(param_1 + 0x170) == 0) {
    *(undefined2 *)(param_1 + 0xa4) = 1000;
  }
  else {
    *(undefined2 *)(param_1 + 0xa4) = 2000;
    *puVar1 = 0;
  }
  *(undefined1 *)(param_1 + 0x1b4) = 1;
  *(int *)(param_1 + 0x168) = (int)*(short *)(param_1 + 0xa4);
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  .glue::SetRect(param_1 + 0x34,0x1a,0x17,0x4a,0x3a);
  *(undefined2 *)(param_1 + 0xb0) = 6;
  *(undefined2 *)(param_1 + 0xb2) = 0;
  *(undefined2 *)(param_1 + 0x46) = 2;
  uVar14 = .debug::_FastRand(10);
  *(undefined2 *)(param_1 + 0xa6) = uVar14;
  *(int *)(param_1 + 0x14c) = (int)*(short *)(param_1 + 0xc) << 8;
  *(int *)(param_1 + 0x150) = (int)*(short *)(param_1 + 10) << 8;
  *(undefined4 *)(param_1 + 0x154) = 0;
  *(undefined4 *)(param_1 + 0x158) = 0;
  *(undefined4 *)(param_1 + 0x15c) = 0;
  *(undefined4 *)(param_1 + 0x160) = 0;
  *(undefined4 *)(param_1 + 0x164) = 0x300;
  *(undefined4 *)(param_1 + 0x168) = 1;
  *(bool *)(param_1 + 0x17e) = *(short *)(param_1 + 4) == 0x781;
  *(undefined4 *)(param_1 + 0xf0) = 0x1e;
  if ((*(short *)(param_1 + 4) == 0x780) || (*(short *)(param_1 + 4) == 0x781)) {
    uVar12 = .debug::_AllocateGameMem(0x30);
    *(undefined4 *)(param_1 + 0x9c) = uVar12;
    piVar18 = *(int **)(param_1 + 0x9c);
    piVar17 = piVar18;
    for (sVar16 = 0; sVar16 < 8; sVar16 = sVar16 + 1) {
      iVar15 = .debug::_MTNewSprite
                         (0x785,*(short *)(param_1 + 0xc) + 0x1e,*(short *)(param_1 + 10) + 0x1e,
                          *(int *)(param_1 + 0x80) + -1,0x1ff,uVar13);
      *piVar17 = iVar15;
      if (sVar16 == 7) {
        *(undefined2 *)(*piVar17 + 0x46) = 1;
      }
      else {
        *(undefined2 *)(*piVar17 + 0x46) = 0;
      }
      piVar17 = piVar17 + 1;
    }
    piVar18[9] = 0;
    piVar18[8] = 0x10;
    piVar18[9] = 0;
    piVar18[10] = 0;
    if (*(short *)(param_1 + 4) == 0x780) {
      *_DAT_1009fecc = 2;
      iVar15 = (int)*(short *)(param_1 + 0x48);
      uVar13 = .debug::_MTNewSprite
                         (0x781,(int)*(short *)(param_1 + 0xc) +
                                *(short *)(*(int *)*puVar2 + iVar15 * 0x10 + 0xc) * -0x20,
                          (int)*(short *)(param_1 + 10),iVar15,iVar15,uVar13);
      *(undefined4 *)(param_1 + 0x1e0) = uVar13;
    }
  }
  else {
    *(undefined **)(param_1 + 0x4c) = PTR_PTR_100a0d64;
    *(undefined4 *)(param_1 + 0x5c) = 0;
    *(undefined4 *)(param_1 + 0x1f8) = 0;
    .glue::SetRect(param_1 + 0x34,0,0,0,0);
  }
  piVar17 = _DAT_1009ffb4;
  if (*_DAT_1009fe8c != '\0') {
    *(undefined1 *)(param_1 + 0x1b5) = 1;
    *piVar17 = *piVar17 + 1;
  }
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  return;
}


// ==== .HandleDemonSegSprite @ 1008a594 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleDemonSegSprite(int param_1)

{
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b2) == '\0')) {
    .debug::_StandardSpriteHandles(param_1);
    *(undefined4 *)(param_1 + 0xc0) =
         *(undefined4 *)(_DAT_100a0d74 + *(short *)(param_1 + 0x46) * 4 + 4);
    .debug::_StandardSpriteCleanup(param_1);
  }
  return;
}


// ==== .HandleDemonSprite @ 1008a630 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleDemonSprite(int param_1)

{
  int *piVar1;
  bool bVar2;
  short *psVar3;
  undefined4 *puVar4;
  undefined *puVar5;
  uint uVar6;
  int iVar7;
  int iVar8;
  char cVar13;
  short sVar10;
  undefined2 uVar11;
  undefined4 uVar9;
  short sVar12;
  int iVar14;
  undefined4 uStack_38;
  undefined8 uStack_30;
  undefined8 uStack_28;
  
  puVar5 = PTR_DAT_100a0d84;
  iVar8 = _DAT_100a0d7c;
  iVar7 = _DAT_100a0d78;
  psVar3 = _DAT_1009fd94;
  bVar2 = false;
  iVar14 = *(int *)(param_1 + 0x9c);
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b2) == '\0')) {
    .debug::_StandardSpriteHandles(param_1);
    .glue::SetRect(param_1 + 0x34,0x22,0x14,0x67,0x5e);
    *(int *)(iVar14 + 0x24) = *(int *)(iVar14 + 0x24) + *(int *)(iVar14 + 0x20);
    if (0x22f < *(int *)(iVar14 + 0x24)) {
      *(undefined4 *)(iVar14 + 0x24) = 0;
    }
    cVar13 = .debug::_IsPressed(0x77);
    if (cVar13 != '\0') {
      *(undefined2 *)(param_1 + 0xa4) = 0xffff;
    }
    if (*(short *)(param_1 + 4) == 0x780) {
      *(undefined2 *)(param_1 + 4) = 0x781;
      *(short *)(param_1 + 4) = *(short *)(param_1 + 4) + -1;
    }
    *(undefined **)(param_1 + 0x50) = PTR_PTR_100a0d68;
    switch(*(undefined2 *)(param_1 + 0xb0)) {
    case 2:
      bVar2 = true;
      uStack_30 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x164) ^ 0x80000000);
      *(int *)(param_1 + 0x164) = (int)((uStack_30 - _DAT_100a1c68) * dRam100a1c60);
      if (*(int *)(iVar14 + 0x20) < 1) {
        *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
        *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        sVar10 = *(short *)(param_1 + 0x46);
        if (sVar10 < 0xb) {
          if (sVar10 == 6) {
            if (*(int *)(param_1 + 0x1d4) != 0) {
              *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0xb8) = 0xb0001;
            }
          }
          else if (sVar10 < 6) {
            if (sVar10 == 4) {
              uVar9 = .debug::_MTNewSprite
                                (0x46a,(int)*(short *)(param_1 + 0xc) +
                                       (uint)*(byte *)(param_1 + 0x17e) * 0x60 + 8,
                                 *(short *)(param_1 + 10) + 0x28,*(int *)(param_1 + 0x80) + -1,
                                 0xffffffff,PTR_PTR_100a0830);
              *(undefined4 *)(param_1 + 0x1d4) = uVar9;
              if (*(int *)(param_1 + 0x1d4) != 0) {
                *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0xb8) = 0xb0002;
              }
            }
            else if ((3 < sVar10) && (*(int *)(param_1 + 0x1d4) != 0)) {
              *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0xb8) = 0xb0000;
            }
          }
          else if ((sVar10 < 8) && (*(int *)(param_1 + 0x1d4) != 0)) {
            *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0xb8) = 0;
          }
          if (sVar10 == 4) {
            uStack_38 = CONCAT22(*_DAT_1009fd90,*psVar3);
            .debug::_CalcCenterPos(*(undefined4 *)(param_1 + 0x1d4));
            uVar9 = .debug::_FindDesiredDirectionGeneric
                              (uStack_38,*(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0xe));
            FUN_1003f218(*(undefined4 *)(param_1 + 0x1d4),uVar9,0x708);
            sVar12 = .debug::_FastRand(12000);
            .debug::_STPlay3DSoundPitched
                      (*_DAT_100a0424,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar12 + 36000);
          }
          if (4 < sVar10) {
            sVar10 = 10 - sVar10;
          }
          iVar7 = (int)sVar10;
          if (3 < iVar7) {
            iVar7 = 4;
          }
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0d80 + iVar7 * 4 + 4);
        }
        else {
          *(undefined2 *)(param_1 + 0x46) = 0;
          *(undefined2 *)(param_1 + 0xa6) = 0;
          *(undefined2 *)(param_1 + 0xb0) = 6;
        }
      }
      else {
        *(int *)(iVar14 + 0x20) = *(int *)(iVar14 + 0x20) + -2;
        if (*(int *)(iVar14 + 0x20) < 0) {
          *(undefined4 *)(iVar14 + 0x20) = 0;
        }
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar5 + 4);
        *(undefined2 *)(param_1 + 0x46) = 0xffff;
      }
      break;
    case 4:
      bVar2 = false;
      if (0 < *(int *)(iVar14 + 0x20)) {
        *(int *)(iVar14 + 0x20) = *(int *)(iVar14 + 0x20) + -1;
      }
      uStack_30 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
      *(int *)(param_1 + 0x24) = (int)((uStack_30 - _DAT_100a1c68) * dRam100a1c58);
      iVar8 = (int)*(short *)(param_1 + 0x46) >> 2;
      if (2 < iVar8) {
        iVar8 = 3;
      }
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar7 + iVar8 * 4 + 4);
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (0xc < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0xc;
      }
      *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
      if (0xb < *(short *)(param_1 + 0xa6)) {
        if (*(short *)(param_1 + 0xa6) == 0xc) {
          *(undefined2 *)(param_1 + 0x1a2) = 1;
        }
        if (*(short *)(param_1 + 0xa6) < 0x14) {
          piVar1 = (int *)(iVar14 + *(short *)(param_1 + 0xa6) * 4 + -0x30);
          if (*(char *)(*piVar1 + 0xe9) != '\0') {
            *piVar1 = 0;
          }
          iVar7 = *(int *)(iVar14 + *(short *)(param_1 + 0xa6) * 4 + -0x30);
          if (iVar7 != 0) {
            *(undefined2 *)(iVar7 + 0x46) = 0;
            *(short *)(*(int *)(iVar14 + *(short *)(param_1 + 0xa6) * 4 + -0x30) + 0x1a2) =
                 (7 - (*(short *)(param_1 + 0xa6) + -0xc)) * -0x1e + -1;
          }
        }
      }
      break;
    case 6:
      if (*(int *)(iVar14 + 0x20) < *(int *)(iVar14 + 0x2c) + 0x10) {
        *(int *)(iVar14 + 0x20) = *(int *)(iVar14 + 0x20) + 2;
      }
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (9 < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0;
      }
      *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
      sVar10 = .debug::_FastRand(0x1e);
      if (((sVar10 + 0x1e < (int)*(short *)(param_1 + 0xa6)) && (0x577f < *(int *)(param_1 + 0x158))
          ) && (*(short *)(param_1 + 0x46) < 2)) {
        *(undefined2 *)(param_1 + 0x46) = 0;
        *(undefined2 *)(param_1 + 0xa6) = 0;
        if (*(int *)(param_1 + 0x160) == 0) {
          sVar10 = .debug::_FastRand(100);
          if (sVar10 < 0x2d) {
            *(undefined2 *)(param_1 + 0xb0) = 9;
          }
          else {
            *(undefined2 *)(param_1 + 0xb0) = 2;
          }
          if (((*(char *)(param_1 + 0x17e) == '\0') && (*(short *)(param_1 + 0x10) < *psVar3)) ||
             ((*(char *)(param_1 + 0x17e) != '\0' && (*psVar3 < *(short *)(param_1 + 0x10))))) {
            *(undefined2 *)(param_1 + 0xb0) = 6;
            *(undefined2 *)(param_1 + 0xa6) = 0;
          }
        }
        else {
          *(undefined4 *)(param_1 + 0x160) = 0;
          sVar10 = .debug::_FastRand(100);
          if (sVar10 < 0x15) {
            *(undefined2 *)(param_1 + 0xb0) = 9;
          }
          else {
            *(undefined2 *)(param_1 + 0xb0) = 2;
          }
          if (((*(char *)(param_1 + 0x17e) == '\0') && (*(short *)(param_1 + 0x10) < *psVar3)) ||
             ((*(char *)(param_1 + 0x17e) != '\0' && (*psVar3 < *(short *)(param_1 + 0x10))))) {
            *(undefined2 *)(param_1 + 0xb0) = 6;
            *(undefined2 *)(param_1 + 0xa6) = 0;
          }
        }
      }
      iVar7 = (int)*(short *)(param_1 + 0x46);
      if (iVar7 < 6) {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar5 + iVar7 * 4 + 4);
      }
      else {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar5 + (10 - iVar7) * 4 + 4);
      }
      bVar2 = true;
      *(int *)(param_1 + 0x15c) =
           *(int *)(param_1 + 0x158) * *(int *)(_DAT_100a0d70 + *(int *)(iVar14 + 0x24) * 4);
      iVar7 = *(int *)(param_1 + 0x15c) / 0xaf00 + (*(int *)(param_1 + 0x15c) >> 0x1f);
      *(int *)(param_1 + 0x15c) = iVar7 - (iVar7 >> 0x1f);
      break;
    case 8:
      if (*(short *)(param_1 + 0x46) == -1) {
        *(int *)(iVar14 + 0x2c) = *(int *)(iVar14 + 0x2c) + 1;
      }
      bVar2 = true;
      uStack_30 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x164) ^ 0x80000000);
      *(int *)(param_1 + 0x164) = (int)((uStack_30 - _DAT_100a1c68) * dRam100a1c60);
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
      iVar8 = (int)*(short *)(param_1 + 0x46);
      if (iVar8 < 4) {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar7 + iVar8 * 4 + 4);
      }
      else {
        iVar8 = 7 - iVar8;
        if (iVar8 < 1) {
          iVar8 = 0;
        }
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar7 + iVar8 * 4 + 4);
      }
      if (*(short *)(param_1 + 0x46) < 8) {
        *(undefined2 *)(*(int *)(iVar14 + (7 - *(short *)(param_1 + 0x46)) * 4) + 0xaa) = 8;
      }
      if (6 < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0xa6) = 0;
        *(undefined2 *)(param_1 + 0x46) = 0;
        *(undefined2 *)(param_1 + 0xb0) = 6;
      }
      break;
    case 9:
      bVar2 = true;
      uStack_28 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x164) ^ 0x80000000);
      *(int *)(param_1 + 0x164) = (int)((uStack_28 - _DAT_100a1c68) * dRam100a1c60);
      uVar6 = *(int *)(iVar14 + 0x2c) + 0x10;
      if ((int)(((int)uVar6 >> 1) + (uint)((int)uVar6 < 0 && (uVar6 & 1) != 0) + -2) <
          *(int *)(iVar14 + 0x20)) {
        *(int *)(iVar14 + 0x20) = *(int *)(iVar14 + 0x20) + -1;
      }
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      iVar7 = (int)(*(short *)(param_1 + 0x46) >> 1);
      if (iVar7 < 3) {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar8 + iVar7 * 4 + 4);
      }
      else {
        iVar7 = 0x18 - iVar7;
        if (1 < iVar7) {
          iVar7 = 2;
        }
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar8 + iVar7 * 4 + 4);
      }
      if (0x2f < *(short *)(param_1 + 0x46)) {
        uVar11 = .debug::_FastRand(0x1e);
        *(undefined2 *)(param_1 + 0xa6) = uVar11;
        *(undefined2 *)(param_1 + 0x46) = 0;
        *(undefined4 *)(param_1 + 0x160) = 1;
        *(undefined2 *)(param_1 + 0xb0) = 6;
      }
    }
    if (bVar2) {
      if (*(int *)(param_1 + 0x158) < 0x4c01) {
        *(undefined4 *)(param_1 + 0x168) = 1;
      }
      else if (0x9eff < *(int *)(param_1 + 0x158)) {
        *(undefined4 *)(param_1 + 0x168) = 0;
      }
      if (*(int *)(param_1 + 0x168) == 0) {
        *(undefined4 *)(iVar14 + 0x28) = 0;
        if (-0x400 < *(int *)(param_1 + 0x164)) {
          *(int *)(param_1 + 0x164) = *(int *)(param_1 + 0x164) + -0x80;
        }
      }
      else if ((*(int *)(param_1 + 0x164) < 0x400) &&
              ((*(int *)(iVar14 + 0x28) = *(int *)(iVar14 + 0x28) + 1,
               0x46 < *(int *)(iVar14 + 0x28) || (*(int *)(param_1 + 0x164) < 0)))) {
        *(int *)(param_1 + 0x164) = *(int *)(param_1 + 0x164) + 0x80;
      }
      *(int *)(param_1 + 0x158) = *(int *)(param_1 + 0x158) + *(int *)(param_1 + 0x164);
      if (*(int *)(param_1 + 0x158) < 0x2d00) {
        *(undefined4 *)(param_1 + 0x158) = 0x2d00;
      }
      if (0xaf00 < *(int *)(param_1 + 0x158)) {
        *(undefined4 *)(param_1 + 0x158) = 0xaf00;
      }
    }
    puVar4 = _DAT_100a026c;
    if ((*(short *)(param_1 + 0xa4) < 1) && (*(short *)(param_1 + 0xb0) != 4)) {
      *(undefined2 *)(param_1 + 0xb0) = 4;
      *(undefined2 *)(param_1 + 0x46) = 0;
      *(undefined2 *)(param_1 + 0xa6) = 0;
      .debug::_STPlay3DSound(*puVar4,1,0x100,*(undefined4 *)(param_1 + 0xe));
    }
    if ((*(short *)(param_1 + 4) == 0x780) || (*(short *)(param_1 + 4) == 0x781)) {
      .debug::_HandleDemonSegs(param_1);
      if (*(short *)(param_1 + 4) == 0x780) {
        *(int *)(param_1 + 0x15c) =
             -0xa00 - (*(int *)(param_1 + 0x150) -
                      *(int *)(*(int *)(*(int *)(param_1 + 0x9c) + 0x1c) + 0x1c));
      }
      else {
        *(int *)(param_1 + 0x15c) =
             -0xa00 - (*(int *)(param_1 + 0x150) -
                      *(int *)(*(int *)(*(int *)(param_1 + 0x9c) + 0x1c) + 0x1c));
      }
    }
    if (*(char *)(param_1 + 0x17e) == '\0') {
      *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14c) - *(int *)(param_1 + 0x158);
    }
    else {
      *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14c) + *(int *)(param_1 + 0x158);
    }
    *(int *)(param_1 + 0x1c) =
         *(int *)(param_1 + 0x150) + *(int *)(param_1 + 0x154) + *(int *)(param_1 + 0x15c);
    *(undefined4 *)(param_1 + 0x2c) = 0;
    *(undefined4 *)(param_1 + 0x24) = 0;
    *(short *)(param_1 + 0xc) = (short)((uint)*(undefined4 *)(param_1 + 0x14) >> 8);
    *(short *)(param_1 + 10) = (short)((uint)*(undefined4 *)(param_1 + 0x1c) >> 8);
    .debug::_StandardSpriteCleanup(param_1);
  }
  return;
}


// ==== .HitDemonSprite @ 1008b0b4 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitDemonSprite(int param_1,int param_2)

{
  bool bVar1;
  undefined4 *puVar2;
  char cVar5;
  short sVar3;
  short sVar4;
  
  puVar2 = _DAT_100a041c;
  if (((*(undefined **)(param_2 + 0x4c) == PTR_PTR_100a04e8) && (*(short *)(param_2 + 0xa6) == 0))
     && (0 < *(short *)(param_1 + 0xa4))) {
    bVar1 = false;
    if (*(short *)(param_1 + 0xb0) == 9) {
      if (4 < *(short *)(param_1 + 0x46)) {
        bVar1 = true;
      }
    }
    if (bVar1) {
      .debug::_KillPlayerShot(param_2,0,0);
      if (*(short *)(param_2 + 4) == 6) {
        .debug::_STPlay3DSound(*puVar2,1,0x100,*(undefined4 *)(param_2 + 0xe));
      }
      else {
        cVar5 = .debug::_HurtSprite(param_1,(int)*(short *)(param_2 + 0xa4),
                                    (int)(short)(*(int *)(param_2 + 0x24) >> 1),0xfffffc18,2,8);
        if (cVar5 != '\0') {
          if (*(short *)(param_1 + 0xa4) < 0xc9) {
            .debug::_STPlay3DSound(*_DAT_100a0270,1,0x100,*(undefined4 *)(param_1 + 0xe));
          }
          else if (0 < *(short *)(param_1 + 0xa4)) {
            .debug::_STPlay3DSound(*_DAT_100a0274,1,0x100,*(undefined4 *)(param_1 + 0xe));
          }
          sVar3 = .debug::_FastRand(100);
          if (sVar3 < 0x3c) {
            sVar3 = .debug::_FastRand(10000);
            sVar4 = .debug::_FastRand(2);
            .debug::_STPlay3DSoundPitched
                      (*(undefined4 *)(_DAT_100a0320 + sVar4 * 4),1,0x100,
                       *(undefined4 *)(param_1 + 0xe),sVar3 + 42000);
          }
          *(undefined2 *)(param_1 + 0xb0) = 8;
          *(undefined2 *)(param_1 + 0xa6) = 0xffff;
          *(undefined2 *)(param_1 + 0x46) = 0xffff;
          *(undefined4 *)(param_1 + 0x164) = 0xfffff800;
        }
      }
    }
    else {
      .debug::_KillPlayerShot(param_2,0,1);
      .debug::_STPlay3DSound(*puVar2,1,0x100,*(undefined4 *)(param_2 + 0xe));
    }
  }
  return;
}


// ==== .KillDemon @ 1008b2d0 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _KillDemon(int param_1)

{
  undefined4 *puVar1;
  short *psVar2;
  short *psVar3;
  int *piVar4;
  undefined2 *puVar5;
  
  piVar4 = _DAT_1009ffc0;
  psVar3 = _DAT_1009fecc;
  psVar2 = _DAT_1009feac;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b5) != '\0')) {
    *_DAT_1009ffb4 = *_DAT_1009ffb4 + -1;
    *(short *)((int)piVar4 + *psVar2 * 2 + 0x306) =
         *(short *)((int)piVar4 + *psVar2 * 2 + 0x306) + 1;
  }
  *piVar4 = *piVar4 + 1000;
  *(undefined1 *)(param_1 + 0xe9) = 1;
  *(undefined1 *)(param_1 + 0xea) = 1;
  puVar1 = _DAT_1009fd68;
  if (((*(short *)(param_1 + 4) == 0x780) || (*(short *)(param_1 + 4) == 0x781)) &&
     (*(int *)(param_1 + 0x170) != 0)) {
    *psVar3 = *psVar3 + -1;
    .debug::_STPlay3DSoundPitched(*puVar1,1,0x100,*(undefined4 *)(param_1 + 0xe),48000);
    puVar5 = _DAT_100a00fc;
    *_DAT_1009ffa0 = 0x1e;
    *puVar5 = 3;
    if (*psVar3 < 1) {
      *_DAT_1009fed0 = 1;
    }
  }
  return;
}


// ==== .SetupChiefSprite @ 1008b538 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupChiefSprite(int param_1)

{
  char *pcVar1;
  undefined1 *puVar2;
  undefined4 *puVar3;
  undefined *puVar4;
  int iVar5;
  undefined *puVar6;
  undefined *puVar7;
  undefined *puVar8;
  int iVar9;
  int iVar10;
  int iVar11;
  undefined2 uVar12;
  
  .debug::_InitSprite();
  puVar4 = PTR_PTR_100a04bc;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar8 = PTR_PTR_100a0d90;
  *(undefined2 *)(param_1 + 0x86) = 0;
  puVar7 = PTR_PTR_100a0d8c;
  *(undefined4 *)(param_1 + 0x80) = 0xc;
  puVar6 = PTR_PTR_100a0d88;
  *(undefined **)(param_1 + 0x4c) = puVar4;
  iVar5 = _DAT_100a0d94;
  *(undefined **)(param_1 + 0x5c) = puVar8;
  puVar4 = PTR_DAT_100a0da4;
  *(undefined **)(param_1 + 0x1f8) = puVar7;
  iVar11 = _DAT_100a0da0;
  *(undefined **)(param_1 + 0x50) = puVar6;
  iVar10 = _DAT_100a0d9c;
  *(undefined1 *)(iVar5 + 1) = 1;
  iVar9 = _DAT_100a0d98;
  puVar4[1] = 1;
  iVar5 = _DAT_100a083c;
  *(undefined1 *)(iVar11 + 1) = 1;
  puVar3 = _DAT_100a0058;
  *(undefined1 *)(iVar10 + 1) = 1;
  *(undefined1 *)(iVar9 + 1) = 1;
  *(undefined1 *)(iVar5 + 1) = 1;
  *(int *)(param_1 + 0x170) =
       (int)*(short *)(*(int *)*puVar3 + *(short *)(param_1 + 0x48) * 0x10 + 0xe);
  *(undefined2 *)(param_1 + 0x110) = 0x276;
  *(undefined4 *)(param_1 + 0xc0) = 0;
  *(undefined1 *)(param_1 + 0x8d) = 1;
  puVar2 = _DAT_1009fed0;
  if (*(int *)(param_1 + 0x170) == 0) {
    *(undefined2 *)(param_1 + 0xa4) = 0x4b0;
  }
  else {
    *(undefined2 *)(param_1 + 0xa4) = 2000;
    *puVar2 = 0;
    *(undefined1 *)(param_1 + 0x88) = 0;
  }
  *(int *)(param_1 + 0x168) = (int)*(short *)(param_1 + 0xa4);
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  .glue::SetRect(param_1 + 0x34,0x5e,0x55,0xa5,0xd4);
  *(undefined2 *)(param_1 + 0xb0) = 6;
  *(undefined2 *)(param_1 + 0xb2) = 0;
  *(undefined2 *)(param_1 + 0x46) = 2;
  *(undefined4 *)(param_1 + 0x14c) = 0;
  uVar12 = .debug::_FastRand(10);
  *(undefined2 *)(param_1 + 0xa6) = uVar12;
  pcVar1 = _DAT_1009fe8c;
  *(undefined4 *)(param_1 + 0x15c) = 2;
  *(undefined4 *)(param_1 + 0x164) = 0;
  *(undefined1 *)(param_1 + 0x17e) = 1;
  *(undefined4 *)(param_1 + 0xf0) = 0x1e;
  *(undefined2 *)(param_1 + 0x46) = 0;
  *(undefined2 *)(param_1 + 0xa6) = 0;
  *(undefined2 *)(param_1 + 0xa6) = 0xffd8;
  if (*pcVar1 != '\0') {
    *(undefined1 *)(param_1 + 0x1b5) = 1;
    *_DAT_1009ffb4 = *_DAT_1009ffb4 + 1;
  }
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  return;
}


// ==== .HandleChiefSprite @ 1008b878 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleChiefSprite(int param_1)

{
  ushort uVar1;
  ushort *puVar2;
  int *piVar3;
  undefined *puVar4;
  undefined *puVar5;
  int iVar6;
  int iVar7;
  int iVar8;
  short sVar10;
  int iVar9;
  short sVar11;
  undefined8 uStack_30;
  undefined8 uStack_28;
  
  puVar5 = PTR_DAT_100a0da4;
  iVar8 = _DAT_100a0d9c;
  iVar7 = _DAT_100a0d98;
  iVar6 = _DAT_100a0d94;
  puVar2 = _DAT_1009fd94;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b2) == '\0')) {
    .debug::_StandardSpriteHandles(param_1);
    .glue::SetRect(param_1 + 0x34,0x58,0x73,0xac,0xd2);
    puVar4 = PTR_DAT_1009fed4;
    sVar11 = *(short *)(param_1 + 0xb0);
    if (sVar11 == 4) {
      uStack_30 = (double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000);
      *(int *)(param_1 + 0x24) = (int)((uStack_30 - dRam100a1c80) * dRam100a1c88);
      iVar6 = (int)*(short *)(param_1 + 0x46) >> 2;
      if (2 < iVar6) {
        iVar6 = 3;
      }
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar7 + iVar6 * 4 + 4);
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (0x10 < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0x10;
      }
      *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
      if (*(short *)(param_1 + 0xa6) == 0x14) {
        *(undefined2 *)(param_1 + 0x1a2) = 1;
      }
    }
    else if (sVar11 < 4) {
      if (sVar11 == 2) {
        iVar7 = (int)(*(short *)(param_1 + 0x46) >> 1);
        if (iVar7 < 4) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar5 + iVar7 * 4 + 4);
        }
        else if (iVar7 < 8) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0da0 + iVar7 * 4 + -0xc);
        }
        else {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar6 + 4);
        }
        if (*(short *)(param_1 + 0x46) == 7) {
          if (*(char *)(param_1 + 0x17e) == '\0') {
            iVar7 = -0x11;
          }
          else {
            iVar7 = 0xa1;
          }
          sVar11 = .debug::_FastRand(8000);
          .debug::_STPlay3DSoundPitched
                    (*_DAT_100a0268,1,0x5f,*(undefined4 *)(param_1 + 0xe),sVar11 + 45000);
          iVar7 = .debug::_MTNewSprite
                            (0x77b,*(short *)(param_1 + 0xc) + iVar7,*(short *)(param_1 + 10) + 0x33
                             ,*(int *)(param_1 + 0x80) + -1,0xffffffff,PTR_PTR_100a0830);
          *(undefined1 *)(iVar7 + 0x17e) = *(undefined1 *)(param_1 + 0x17e);
          *(undefined2 *)(iVar7 + 0x46) = 0xf;
          if (*(short *)(iVar7 + 0x46) == 0x10) {
            *(undefined2 *)(iVar7 + 0x46) = 0;
          }
          sVar11 = .debug::_FastRand(500);
          *(int *)(iVar7 + 0x24) = sVar11 + 4000;
          sVar11 = .debug::_FastRand(0x96);
          *(int *)(iVar7 + 0x2c) = -0x4b0 - sVar11;
          iVar9 = (int)(short)*puVar2 - (int)*(short *)(param_1 + 0x10);
          iVar8 = iVar9;
          if (iVar9 < 1) {
            iVar8 = -iVar9;
          }
          if (iVar8 < 0xf0) {
            uStack_28 = (double)CONCAT44(0x43300000,*(uint *)(iVar7 + 0x24) ^ 0x80000000);
            *(int *)(iVar7 + 0x24) = (int)((uStack_28 - dRam100a1c80) * dRam100a1c98);
            *(undefined4 *)(iVar7 + 0x2c) = 2000;
          }
          else {
            if (iVar9 < 1) {
              iVar9 = -iVar9;
            }
            if (iVar9 < 0x9b) {
              uStack_30 = (double)CONCAT44(0x43300000,*(uint *)(iVar7 + 0x24) ^ 0x80000000);
              *(int *)(iVar7 + 0x24) = (int)((uStack_30 - dRam100a1c80) * dRam100a1c90);
              *(undefined4 *)(iVar7 + 0x2c) = 0xc80;
            }
          }
          if (*(char *)(param_1 + 0x17e) == '\0') {
            *(int *)(iVar7 + 0x24) = -*(int *)(iVar7 + 0x24);
          }
        }
        sVar11 = *(short *)(param_1 + 0x46);
        if (sVar11 == 0) {
          *(byte *)(param_1 + 0x17e) =
               (*puVar2 <= *(ushort *)(param_1 + 0x10)) -
               ((char)~(byte)((short)(*puVar2 ^ *(ushort *)(param_1 + 0x10)) >> 0xf) >> 7) & 1;
          *(int *)(param_1 + 0x158) = *(int *)(param_1 + 0x158) + -1;
          if (*(int *)(param_1 + 0x158) < 1) {
            *(undefined2 *)(param_1 + 0xa6) = 0;
            *(undefined2 *)(param_1 + 0x46) = 0;
            *(undefined2 *)(param_1 + 0xb0) = 6;
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar6 + 4);
          }
          else {
            *(undefined2 *)(param_1 + 0xb0) = 2;
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
          }
        }
        else if (sVar11 < 0x12) {
          *(short *)(param_1 + 0x46) = sVar11 + 1;
        }
        else {
          *(undefined2 *)(param_1 + 0xa6) = 0;
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
      }
      else if (sVar11 < 2) {
        if (0 < sVar11) {
          uVar1 = *(ushort *)(param_1 + 0x46);
          iVar6 = (int)(short)(((short)uVar1 >> 1) + (ushort)((short)uVar1 < 0 && (uVar1 & 1) != 0))
          ;
          *(ushort *)(param_1 + 0x46) = uVar1 + 1;
          if (1 < iVar6) {
            iVar6 = 2;
          }
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar8 + iVar6 * 4 + 4);
          if (*(short *)(param_1 + 0x46) == 3) {
            sVar11 = .debug::_FastRand(100);
            sVar10 = .debug::_FastRand(6000);
            .debug::_STPlay3DSoundPitched
                      (*_DAT_100a03f8,0x14,0xab,*(undefined4 *)(param_1 + 0xe),sVar10 + 35000);
            *(undefined4 *)(param_1 + 0x2c) = 0xffffd6fc;
            *(undefined1 *)(param_1 + 0xce) = 0;
            iVar6 = *(int *)(param_1 + 0x15c);
            if (iVar6 == 2) {
              if (sVar11 < 0x21) {
                *(undefined4 *)(param_1 + 0x24) = 0xfffff900;
                *(undefined4 *)(param_1 + 0x15c) = 1;
              }
              else if (sVar11 < 0x42) {
                *(undefined4 *)(param_1 + 0x24) = 0;
                *(undefined4 *)(param_1 + 0x15c) = 2;
              }
              else {
                *(undefined4 *)(param_1 + 0x24) = 0x700;
                *(undefined4 *)(param_1 + 0x15c) = 3;
              }
            }
            else if (iVar6 < 2) {
              if (0 < iVar6) {
                if (sVar11 < 0x21) {
                  *(undefined4 *)(param_1 + 0x24) = 0;
                  *(undefined4 *)(param_1 + 0x15c) = 1;
                }
                else if (sVar11 < 0x42) {
                  *(undefined4 *)(param_1 + 0x24) = 0x700;
                  *(undefined4 *)(param_1 + 0x15c) = 2;
                }
                else {
                  *(undefined4 *)(param_1 + 0x24) = 0xe00;
                  *(undefined4 *)(param_1 + 0x15c) = 3;
                }
              }
            }
            else if (iVar6 < 4) {
              if (sVar11 < 0x21) {
                *(undefined4 *)(param_1 + 0x24) = 0xfffff200;
                *(undefined4 *)(param_1 + 0x15c) = 1;
              }
              else if (sVar11 < 0x42) {
                *(undefined4 *)(param_1 + 0x24) = 0xfffff900;
                *(undefined4 *)(param_1 + 0x15c) = 2;
              }
              else {
                *(undefined4 *)(param_1 + 0x24) = 0;
                *(undefined4 *)(param_1 + 0x15c) = 3;
              }
            }
          }
          else if ((3 < *(short *)(param_1 + 0x46)) && (0 < *(int *)(param_1 + 0x2c))) {
            *(undefined2 *)(param_1 + 0xa6) = 0;
            *(undefined2 *)(param_1 + 0x46) = 0;
            *(undefined2 *)(param_1 + 0xb0) = 3;
          }
        }
      }
      else if (*(char *)(param_1 + 0xcd) == '\0') {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar8 + 0x10);
      }
      else {
        if (*(short *)(param_1 + 0x46) == 0) {
          sVar11 = .debug::_FastRand(12000);
          .debug::_STPlay3DSoundPitched
                    (*_DAT_1009fdec,1,0xab,*(undefined4 *)(param_1 + 0xe),sVar11 + 40000);
          piVar3 = _DAT_1009fdd8;
          *_DAT_1009ffa0 = 0x16;
          if ((*(char *)(*piVar3 + 0xce) != '\0') || (*(char *)(*piVar3 + 0xcd) != '\0')) {
            *_DAT_100a0570 = 0x18;
          }
          *(undefined4 *)(param_1 + 0x24) = 0;
          *(byte *)(param_1 + 0x17e) =
               (*puVar2 <= *(ushort *)(param_1 + 0x10)) -
               ((char)~(byte)((short)(*puVar2 ^ *(ushort *)(param_1 + 0x10)) >> 0xf) >> 7) & 1;
        }
        sVar11 = *(short *)(param_1 + 0x46);
        if (sVar11 < 5) {
          if (sVar11 < 2) {
            if (-1 < sVar11) {
              *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar6 + 4);
            }
          }
          else {
            *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar5 + 4);
          }
        }
        else if (sVar11 < 7) {
          *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar6 + 4);
        }
        if (*(short *)(param_1 + 0x46) < 6) {
          *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
        }
        else {
          sVar11 = .debug::_FastRand(2);
          *(int *)(param_1 + 0x158) = sVar11 + 2;
          *(undefined2 *)(param_1 + 0xb0) = 2;
          *(undefined2 *)(param_1 + 0x46) = 0;
          *(undefined2 *)(param_1 + 0xa6) = 0;
        }
      }
    }
    else if (sVar11 == 6) {
      *(undefined4 *)(param_1 + 0x24) = 0;
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar6 + 4);
      if (*puVar4 != '\0') {
        *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
      }
      if ((0xf < *(short *)(param_1 + 0xa6)) && (*(char *)(param_1 + 0xcd) != '\0')) {
        *(undefined2 *)(param_1 + 0x46) = 0;
        *(undefined2 *)(param_1 + 0xa6) = 0;
        *(undefined2 *)(param_1 + 0xb0) = 1;
      }
    }
    if (0 < *(short *)(param_1 + 0xb2)) {
      if (*(short *)(param_1 + 0xb2) < 5) {
        *(short *)(param_1 + 0xb2) = *(short *)(param_1 + 0xb2) + 1;
      }
      else {
        *(undefined2 *)(param_1 + 0xb2) = 0;
      }
    }
    if ((*(short *)(param_1 + 0xa4) < 1) && (*(short *)(param_1 + 0xb0) != 4)) {
      *(undefined2 *)(param_1 + 0xb0) = 4;
      *(undefined2 *)(param_1 + 0x46) = 0;
      *(undefined2 *)(param_1 + 0xa6) = 0;
      sVar11 = .debug::_FastRand(100);
      if (sVar11 < 0x3c) {
        .debug::_GoblinChiefRandomCry(param_1);
      }
      .debug::_STPlay3DSound(*_DAT_100a026c,1,0x100,*(undefined4 *)(param_1 + 0xe));
    }
    .debug::_ApplyGravityAndSeparateFromTiles(param_1);
    .debug::_StandardSpriteCleanup(param_1);
  }
  return;
}


// ==== .HitChiefSprite @ 1008c0e0 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitChiefSprite(int param_1,int param_2)

{
  undefined4 *puVar1;
  char cVar3;
  short sVar2;
  undefined *puVar4;
  short sStack_22;
  short sStack_20;
  
  puVar1 = _DAT_100a0274;
  puVar4 = *(undefined **)(param_2 + 0x4c);
  if (((puVar4 != PTR_PTR_100a04e8) || (*(short *)(param_2 + 0xa6) != 0)) ||
     (*(short *)(param_1 + 0xa4) < 1)) {
    if ((puVar4 == PTR_PTR_100a01f8) || (puVar4 == PTR_PTR_100a0484)) {
      sStack_20 = *(short *)(param_1 + 0x36) +
                  (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
      sStack_22 = *(short *)(param_1 + 0x34) +
                  (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
      sVar2 = .debug::_PlatformBounce(param_1,param_2,&sStack_22,0,param_1 + 0x34,0);
      if ((sVar2 == 2) && ((0 < *(int *)(param_2 + 0x2c) || (*(char *)(param_1 + 0xce) != '\0')))) {
        .debug::_HurtSprite(param_1,200,(int)(short)(*(int *)(param_2 + 0x24) >> 1),0xfffffc18,2,8);
        *(undefined4 *)(param_1 + 0xf0) = 0;
        .debug::_KillBox(param_2);
        sVar2 = .debug::_FastRand(10000);
        .debug::_STPlay3DSoundPitched(*puVar1,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar2 + 42000);
        .debug::_GoblinChiefRandomCry(param_1);
      }
    }
    return;
  }
  .debug::_KillPlayerShot(param_2,0,0);
  cVar3 = .debug::_HurtSprite(param_1,(int)*(short *)(param_2 + 0xa4),0,0,2,8);
  if (cVar3 == '\0') {
    return;
  }
  *(undefined2 *)(param_1 + 0x116) = 0xf;
  *(undefined2 *)(param_1 + 0xb2) = 1;
  .debug::_BloodSpray(param_1,param_2,0x28,400,0x96,2);
  if (*(short *)(param_1 + 0xa4) < 0xc9) {
    .debug::_STPlay3DSound(*_DAT_100a0270,1,0x100,*(undefined4 *)(param_1 + 0xe));
  }
  else if (0 < *(short *)(param_1 + 0xa4)) {
    .debug::_STPlay3DSound(*puVar1,1,0x100,*(undefined4 *)(param_1 + 0xe));
  }
  sVar2 = .debug::_FastRand(100);
  if (0x3b < sVar2) {
    return;
  }
  .debug::_GoblinChiefRandomCry(param_1);
  return;
}


// ==== .KillChief @ 1008c350 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _KillChief(int param_1)

{
  short *psVar1;
  undefined1 *puVar2;
  undefined2 *puVar3;
  int iVar4;
  
  iVar4 = _DAT_1009ffc0;
  psVar1 = _DAT_1009feac;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b5) != '\0')) {
    *_DAT_1009ffb4 = *_DAT_1009ffb4 + -1;
    iVar4 = iVar4 + *psVar1 * 2;
    *(short *)(iVar4 + 0x306) = *(short *)(iVar4 + 0x306) + 1;
  }
  *(undefined1 *)(param_1 + 0xe9) = 1;
  *(undefined1 *)(param_1 + 0xea) = 1;
  if (*(int *)(param_1 + 0x170) != 0) {
    .debug::_STPlay3DSoundPitched(*_DAT_1009fd68,1,0x100,*(undefined4 *)(param_1 + 0xe),48000);
    puVar3 = _DAT_100a00fc;
    *_DAT_1009ffa0 = 0x1e;
    puVar2 = _DAT_1009fed0;
    *puVar3 = 3;
    *puVar2 = 1;
  }
  return;
}


// ==== .HitChiefTileSprite @ 1008c434 ====

void _HitChiefTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  char cVar1;
  short sStack_46;
  short sStack_44;
  undefined1 auStack_26 [26];
  
  sStack_44 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_46 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  .glue::SetRect(auStack_26,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                 (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
  if (param_4 == 1) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_46,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 100) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_46,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 200) {
    .debug::_WallBounceBG(param_1,param_3 + -100,&stack0x0000001c,&sStack_46,0,param_1 + 0x34,0,0);
  }
  else {
    cVar1 = .debug::_IsWaterTile(param_3);
    if ((cVar1 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
      .debug::_HandleUnderWater(param_1,param_2);
    }
  }
  return;
}


// ==== .SetupWizardSprite @ 1008c6a8 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupWizardSprite(int param_1)

{
  short *psVar1;
  char *pcVar2;
  undefined1 *puVar3;
  int *piVar4;
  undefined4 *puVar5;
  undefined *puVar6;
  int iVar7;
  undefined *puVar8;
  undefined *puVar9;
  undefined *puVar10;
  int iVar11;
  int iVar12;
  undefined *puVar13;
  undefined2 uVar15;
  undefined4 uVar14;
  
  puVar13 = PTR_DAT_100a0dbc;
  puVar5 = _DAT_100a0058;
  .debug::_InitSprite();
  puVar6 = PTR_PTR_100a0490;
  *(undefined2 *)(param_1 + 0x84) = 0;
  puVar10 = PTR_PTR_100a0db0;
  *(undefined2 *)(param_1 + 0x86) = 0;
  puVar9 = PTR_PTR_100a0dac;
  *(undefined4 *)(param_1 + 0x80) = 1;
  puVar8 = PTR_PTR_100a0da8;
  *(undefined **)(param_1 + 0x4c) = puVar6;
  iVar12 = _DAT_100a0db8;
  *(undefined **)(param_1 + 0x5c) = puVar10;
  iVar11 = _DAT_100a0db4;
  *(undefined **)(param_1 + 0x1f8) = puVar9;
  iVar7 = _DAT_100a0848;
  *(undefined **)(param_1 + 0x50) = puVar8;
  *(undefined1 *)(param_1 + 0x18a) = 1;
  puVar13[1] = 1;
  *(undefined1 *)(iVar12 + 1) = 1;
  *(undefined1 *)(iVar11 + 1) = 1;
  *(undefined1 *)(iVar7 + 1) = 1;
  *(int *)(param_1 + 0x170) =
       (int)*(short *)(*(int *)*puVar5 + *(short *)(param_1 + 0x48) * 0x10 + 0xe);
  *(undefined2 *)(param_1 + 0x110) = 0x122;
  *(undefined4 *)(param_1 + 0xc0) = 0;
  puVar3 = _DAT_1009fed0;
  if (*(int *)(param_1 + 0x170) == 0) {
    *(undefined2 *)(param_1 + 0xa4) = 0x4b0;
  }
  else {
    *(undefined2 *)(param_1 + 0xa4) = 1000;
    *puVar3 = 0;
    *(undefined1 *)(param_1 + 0x88) = 0;
  }
  *(undefined1 *)(param_1 + 0x1b4) = 1;
  *(int *)(param_1 + 0x168) = (int)*(short *)(param_1 + 0xa4);
  *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
  *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
  .glue::SetRect(param_1 + 0x34,0x42,0x1e,0x7c,0x7e);
  *(undefined4 *)(param_1 + 0x150) = 0xffffffff;
  *(undefined2 *)(param_1 + 0xb0) = 6;
  *(undefined2 *)(param_1 + 0xb2) = 0;
  *(undefined2 *)(param_1 + 0x46) = 2;
  *(undefined4 *)(param_1 + 0x14c) = 0;
  uVar15 = .debug::_FastRand(10);
  *(undefined2 *)(param_1 + 0xa6) = uVar15;
  *(undefined4 *)(param_1 + 0xf0) = 0xf;
  psVar1 = (short *)(*(int *)*puVar5 + *(short *)(param_1 + 0x48) * 0x10 + 10);
  if (*psVar1 == 0) {
    *psVar1 = 0x96;
  }
  *(int *)(param_1 + 0x15c) = *(short *)(param_1 + 0xc) + -0x100;
  *(int *)(param_1 + 0x160) = *(short *)(param_1 + 0xc) + 0x100;
  *(int *)(param_1 + 0x168) = (int)*(short *)(param_1 + 0xc);
  *(undefined4 *)(param_1 + 0x164) = 0;
  *(undefined1 *)(param_1 + 0x17e) = 0;
  *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar13 + 4);
  uVar14 = .debug::_AllocateGameMem(0xe);
  *(undefined4 *)(param_1 + 0x9c) = uVar14;
  pcVar2 = _DAT_1009fe8c;
  *(undefined4 *)(param_1 + 0xf0) = 0x1e;
  piVar4 = _DAT_1009ffb4;
  if (*pcVar2 != '\0') {
    *(undefined1 *)(param_1 + 0x1b5) = 1;
    *piVar4 = *piVar4 + 1;
  }
  *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 8) << 8;
  *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 6) << 8;
  return;
}


// ==== .HandleWizardSprite @ 1008c8e8 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleWizardSprite(int param_1)

{
  double dVar1;
  bool bVar2;
  char *pcVar3;
  ushort *puVar4;
  undefined4 *puVar5;
  undefined *puVar6;
  undefined *puVar7;
  uint uVar8;
  int iVar9;
  short sVar10;
  short sVar13;
  int iVar11;
  undefined4 uVar12;
  int iVar14;
  short unaff_r25;
  short *psVar15;
  double dVar16;
  double dVar17;
  double dVar18;
  undefined8 uStack_38;
  
  puVar7 = PTR_DAT_100a0dbc;
  iVar11 = _DAT_100a0db8;
  iVar14 = _DAT_100a0db4;
  puVar6 = PTR_PTR_100a0830;
  puVar4 = _DAT_1009fd94;
  psVar15 = *(short **)(param_1 + 0x9c);
  if (*(char *)(param_1 + 0xe9) != '\0') {
    return;
  }
  if (*(char *)(param_1 + 0x1b2) != '\0') {
    return;
  }
  .debug::_StandardSpriteHandles(param_1);
  switch(*(undefined2 *)(param_1 + 0xb0)) {
  case 2:
    sVar10 = psVar15[3];
    bVar2 = false;
    if (sVar10 == 1) {
      iVar9 = (int)(*(short *)(param_1 + 0x46) >> 1);
      if (6 < iVar9) {
        iVar9 = 7;
      }
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar11 + iVar9 * 4 + 4);
      if (*(short *)(param_1 + 0x46) == 10) {
        uVar12 = .debug::_MTNewSprite
                           (0x434,*(short *)(param_1 + 0x10) + -0x10,
                            *(short *)(param_1 + 0xe) + -0x10,9,0xffffffff,_DAT_1009ff34);
        *(undefined4 *)(param_1 + 0x1d4) = uVar12;
        *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0x160) = 0xffffffcc;
        psVar15[5] = 0x34;
        *psVar15 = *psVar15 + -1;
      }
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (0xf < *(short *)(param_1 + 0x46)) {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar14 + 4);
        *(byte *)(param_1 + 0x17e) =
             (*puVar4 <= *(ushort *)(param_1 + 0x10)) -
             ((char)~(byte)((short)(*puVar4 ^ *(ushort *)(param_1 + 0x10)) >> 0xf) >> 7) & 1;
        if (*psVar15 == 0) {
          bVar2 = true;
        }
        else if (psVar15[5] < 1) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
      }
    }
    else if ((sVar10 < 1) && (-1 < sVar10)) {
      iVar9 = (int)(*(short *)(param_1 + 0x46) >> 1);
      if (6 < iVar9) {
        iVar9 = 7;
      }
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar11 + iVar9 * 4 + 4);
      pcVar3 = _DAT_1009fd30;
      if (*(short *)(param_1 + 0x46) == 7) {
        if (*(short *)(param_1 + 0xa6) < 1) {
          *(undefined2 *)(param_1 + 0xa6) = 0x14;
          *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1;
        }
        else {
          *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + -1;
          if (*pcVar3 == '\0') {
            *(undefined4 *)(param_1 + 0xb8) = 0;
          }
          else {
            *(undefined4 *)(param_1 + 0xb8) = 0x1000c;
          }
          if (*(short *)(param_1 + 0xa6) < 1) {
            *(undefined4 *)(param_1 + 0xb8) = 0;
          }
          else {
            *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1;
          }
          *(byte *)(param_1 + 0x17e) =
               (*puVar4 <= *(ushort *)(param_1 + 0x10)) -
               ((char)~(byte)((short)(*puVar4 ^ *(ushort *)(param_1 + 0x10)) >> 0xf) >> 7) & 1;
        }
      }
      if (*(short *)(param_1 + 0x46) == 8) {
        iVar11 = .debug::_MTNewSprite
                           (0x46a,*(short *)(param_1 + 0x10) + -0x18,
                            *(short *)(param_1 + 0xe) + -0x18,*(int *)(param_1 + 0x80) + 1,
                            0xffffffff,puVar6);
        *(undefined4 *)(iVar11 + 0x24) = 0x1194;
        *(undefined4 *)(iVar11 + 0x2c) = 0;
        if (*(char *)(param_1 + 0x17e) == '\0') {
          *(int *)(iVar11 + 0x24) = -*(int *)(iVar11 + 0x24);
        }
        iVar11 = .debug::_MTNewSprite
                           (0x46a,*(short *)(param_1 + 0x10) + -0x18,
                            *(short *)(param_1 + 0xe) + -0x18,*(int *)(param_1 + 0x80) + 1,
                            0xffffffff,puVar6);
        *(undefined4 *)(iVar11 + 0x24) = 0x1068;
        *(undefined4 *)(iVar11 + 0x2c) = 0xfffffa24;
        if (*(char *)(param_1 + 0x17e) == '\0') {
          *(int *)(iVar11 + 0x24) = -*(int *)(iVar11 + 0x24);
        }
        iVar11 = .debug::_MTNewSprite
                           (0x46a,*(short *)(param_1 + 0x10) + -0x18,
                            *(short *)(param_1 + 0xe) + -0x18,*(int *)(param_1 + 0x80) + 1,
                            0xffffffff,puVar6);
        *(undefined4 *)(iVar11 + 0x24) = 0xce4;
        *(undefined4 *)(iVar11 + 0x2c) = 0xfffff448;
        if (*(char *)(param_1 + 0x17e) == '\0') {
          *(int *)(iVar11 + 0x24) = -*(int *)(iVar11 + 0x24);
        }
        sVar10 = .debug::_FastRand(12000);
        .debug::_STPlay3DSoundPitched
                  (*_DAT_100a0424,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar10 + 36000);
        *psVar15 = *psVar15 + -1;
      }
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (0xf < *(short *)(param_1 + 0x46)) {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar14 + 4);
        *(byte *)(param_1 + 0x17e) =
             (*puVar4 <= *(ushort *)(param_1 + 0x10)) -
             ((char)~(byte)((short)(*puVar4 ^ *(ushort *)(param_1 + 0x10)) >> 0xf) >> 7) & 1;
        if (*psVar15 == 0) {
          bVar2 = true;
        }
        else if (psVar15[5] < 1) {
          *(undefined2 *)(param_1 + 0x46) = 0;
        }
      }
    }
    if (bVar2) {
      *(undefined2 *)(param_1 + 0xa6) = 0;
      *(undefined2 *)(param_1 + 0x46) = 0;
      *(short *)(param_1 + 0xb0) = psVar15[2];
    }
    break;
  case 4:
    *(int *)(param_1 + 0x24) =
         (int)(((double)CONCAT44(0x43300000,*(uint *)(param_1 + 0x24) ^ 0x80000000) - dRam100a1ca8)
              * dRam100a1cc0);
    *(undefined4 *)(param_1 + 0xc0) =
         *(undefined4 *)(iVar11 + ((int)*(short *)(param_1 + 0x46) >> 2) * 4 + 4);
    *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
    if (0x10 < *(short *)(param_1 + 0x46)) {
      *(undefined2 *)(param_1 + 0x46) = 0x10;
    }
    *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
    if (*(short *)(param_1 + 0xa6) == 0x14) {
      *(undefined2 *)(param_1 + 0x1a2) = 1;
    }
    break;
  case 6:
    if (*(short *)(param_1 + 0xa4) < 0x12d) {
      sVar10 = 10;
    }
    else if (*(short *)(param_1 + 0xa4) < 0x259) {
      sVar10 = 0x10;
    }
    else {
      sVar10 = 0x16;
    }
    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar14 + 4);
    *(undefined4 *)(param_1 + 0x24) = 0;
    *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
    sVar13 = .debug::_FastRand(10);
    if ((int)sVar10 + (int)sVar13 <= (int)*(short *)(param_1 + 0xa6)) {
      *(undefined2 *)(param_1 + 0xa6) = 0;
      *(undefined2 *)(param_1 + 0x46) = 0;
      *(undefined2 *)(param_1 + 0xb0) = 9;
    }
    *(byte *)(param_1 + 0x17e) =
         (*puVar4 <= *(ushort *)(param_1 + 0x10)) -
         ((char)~(byte)((short)(*puVar4 ^ *(ushort *)(param_1 + 0x10)) >> 0xf) >> 7) & 1;
    break;
  case 9:
    uVar8 = (uint)*(short *)(param_1 + 0x46);
    iVar11 = uVar8 + (((int)uVar8 >> 4) + (uint)((int)uVar8 < 0 && (uVar8 & 0xf) != 0)) * -0x10;
    if (iVar11 < 1) {
      iVar11 = 0;
    }
    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar7 + (short)(iVar11 >> 1) * 4 + 4);
    *(undefined4 *)(param_1 + 0x24) = 0x500;
    if (*(char *)(param_1 + 0x17e) == '\0') {
      *(int *)(param_1 + 0x24) = -*(int *)(param_1 + 0x24);
    }
    *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
    if (0x1f < *(short *)(param_1 + 0x46)) {
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar14 + 4);
      *(undefined4 *)(param_1 + 0x24) = 0;
    }
    if (0x23 < *(short *)(param_1 + 0x46)) {
      sVar10 = 0;
      if ((uint)*(byte *)(param_1 + 0x17e) !=
          ((uint)(*puVar4 <= *(ushort *)(param_1 + 0x10)) -
           (~(int)(short)(*puVar4 ^ *(ushort *)(param_1 + 0x10)) >> 0x1f) & 1)) {
        *(bool *)(param_1 + 0x17e) = *(byte *)(param_1 + 0x17e) == 0;
      }
      psVar15[2] = 0xc;
      *(undefined2 *)(param_1 + 0xa6) = 0;
      *(undefined2 *)(param_1 + 0x46) = 0;
      *(undefined2 *)(param_1 + 0xb0) = 2;
      if (*(short *)(param_1 + 0xa4) < 0x12d) {
        sVar10 = 0x14;
      }
      else if (*(short *)(param_1 + 0xa4) < 0x259) {
        sVar10 = 10;
      }
      sVar13 = .debug::_FastRand(100);
      if (((int)sVar13 < sVar10 + 0x28) && (psVar15[6] < 3)) {
        psVar15[6] = psVar15[6] + 1;
        psVar15[3] = 0;
        sVar10 = *(short *)(param_1 + 0xa4);
        if (600 < sVar10) {
          unaff_r25 = 0x16;
        }
        else if (600 < sVar10) {
          if (sVar10 < 0x12d) {
            unaff_r25 = 0x2d;
          }
        }
        else {
          unaff_r25 = 0x23;
        }
        sVar10 = .debug::_FastRand(100);
        if (unaff_r25 < sVar10) {
          *psVar15 = 1;
        }
        else {
          sVar10 = .debug::_FastRand(3);
          *psVar15 = sVar10 + 2;
        }
      }
      else {
        sVar10 = .debug::_FastRand(100);
        psVar15[6] = 0;
        psVar15[3] = 1;
        if (sVar10 < 0x5b) {
          if (sVar10 < 0x15) {
            sVar10 = .debug::_FastRand(2);
            *psVar15 = sVar10 + 3;
          }
          else {
            *psVar15 = 2;
          }
        }
        else {
          *psVar15 = 1;
        }
      }
      psVar15[4] = psVar15[4] + 1;
    }
    break;
  case 10:
    uVar8 = (uint)*(short *)(param_1 + 0x46);
    iVar11 = uVar8 + (((int)uVar8 >> 4) + (uint)((int)uVar8 < 0 && (uVar8 & 0xf) != 0)) * -0x10;
    if (iVar11 < 1) {
      iVar11 = 0;
    }
    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar7 + (7 - (short)(iVar11 >> 1)) * 4 + 4);
    *(undefined4 *)(param_1 + 0x24) = 0xfffffb00;
    if (*(char *)(param_1 + 0x17e) != '\0') {
      *(int *)(param_1 + 0x24) = -*(int *)(param_1 + 0x24);
    }
    *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
    if (0x1f < *(short *)(param_1 + 0x46)) {
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar14 + 4);
      *(undefined4 *)(param_1 + 0x24) = 0;
    }
    if (0x23 < *(short *)(param_1 + 0x46)) {
      *(undefined2 *)(param_1 + 0xa6) = 0;
      *(undefined2 *)(param_1 + 0x46) = 0;
      *(undefined2 *)(param_1 + 0xb0) = 6;
    }
    break;
  case 0xb:
    uVar8 = (uint)*(short *)(param_1 + 0x46);
    iVar11 = uVar8 + (((int)uVar8 >> 4) + (uint)((int)uVar8 < 0 && (uVar8 & 0xf) != 0)) * -0x10;
    if (iVar11 < 1) {
      iVar11 = 0;
    }
    *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(puVar7 + (7 - (short)(iVar11 >> 1)) * 4 + 4);
    *(undefined4 *)(param_1 + 0x24) = 0x500;
    if (*(char *)(param_1 + 0x17e) != '\0') {
      *(int *)(param_1 + 0x24) = -*(int *)(param_1 + 0x24);
    }
    *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
    if (0x1f < *(short *)(param_1 + 0x46)) {
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(iVar14 + 4);
      *(undefined4 *)(param_1 + 0x24) = 0;
    }
    if (0x23 < *(short *)(param_1 + 0x46)) {
      *(undefined2 *)(param_1 + 0xa6) = 0;
      *(undefined2 *)(param_1 + 0x46) = 0;
      *(undefined2 *)(param_1 + 0xb0) = 6;
    }
    break;
  case 0xc:
    *(byte *)(param_1 + 0x17e) =
         (*puVar4 <= *(ushort *)(param_1 + 0x10)) -
         ((char)~(byte)((short)(*puVar4 ^ *(ushort *)(param_1 + 0x10)) >> 0xf) >> 7) & 1;
    *(undefined2 *)(param_1 + 0xb0) = 10;
  }
  if (0 < psVar15[5]) {
    psVar15[5] = psVar15[5] + -1;
    iVar14 = *(int *)(param_1 + 0x1d4);
    if ((iVar14 == 0) || (*(char *)(iVar14 + 0xe9) != '\0')) {
      psVar15[5] = 0;
      *(undefined4 *)(param_1 + 0x1d4) = 0;
    }
    else if (iVar14 != 0) {
      sVar10 = psVar15[5] + -0x16;
      if (sVar10 < 0) {
        sVar10 = 0;
      }
      uStack_38 = (double)CONCAT44(0x43300000,(int)sVar10 ^ 0x80000000);
      dVar18 = (double)(float)((uStack_38 - dRam100a1ca8) / dRam100a1cb8);
      if (10 < psVar15[5]) {
        dVar17 = dRam100a1cb0 - dVar18;
        uStack_38 = (double)CONCAT44(0x43300000,(int)(short)(*puVar4 - 0x10) ^ 0x80000000);
        dVar1 = (double)CONCAT44(0x43300000,(int)*(short *)(iVar14 + 10) ^ 0x80000000) -
                dRam100a1ca8;
        dVar16 = (double)CONCAT44(0x43300000,(int)(short)(*_DAT_1009fd90 + -0x88) ^ 0x80000000) -
                 dRam100a1ca8;
        sVar10 = (short)(int)((uStack_38 - dRam100a1ca8) * dVar17 +
                             (double)(float)((double)(float)((double)CONCAT44(0x43300000,
                                                                              (int)*(short *)(iVar14
                                                                                             + 0xc)
                                                                              ^ 0x80000000) -
                                                            dRam100a1ca8) * dVar18));
        *(short *)(iVar14 + 0xc) = sVar10;
        sVar13 = (short)(int)(dVar16 * dVar17 + (double)(float)((double)(float)dVar1 * dVar18));
        *(short *)(*(int *)(param_1 + 0x1d4) + 10) = sVar13;
        *(int *)(*(int *)(param_1 + 0x1d4) + 0x14) = (int)sVar10 << 8;
        *(int *)(*(int *)(param_1 + 0x1d4) + 0x1c) = (int)sVar13 << 8;
      }
    }
  }
  puVar5 = _DAT_100a026c;
  if ((*(short *)(param_1 + 0xa4) < 1) && (*(short *)(param_1 + 0xb0) != 4)) {
    *(undefined2 *)(param_1 + 0xb0) = 4;
    *(undefined2 *)(param_1 + 0x46) = 0;
    *(undefined2 *)(param_1 + 0xa6) = 0;
    .debug::_STPlay3DSound(*puVar5,1,0x100,*(undefined4 *)(param_1 + 0xe));
  }
  else {
    *(int *)(param_1 + 0xf0) = *(int *)(param_1 + 0xf0) + -1;
    iVar14 = *(int *)(param_1 + 0xf0);
    if (iVar14 < 4) {
      if (0 < iVar14) {
        if ((*(short *)(param_1 + 0xa4) < 0x259) && (0 < *(short *)(param_1 + 0xa4))) {
          *(undefined4 *)(param_1 + 0xb8) = 0x10008;
        }
        goto LAB_1008d41c;
      }
    }
    else if (iVar14 < 7) {
      if ((*(short *)(param_1 + 0xa4) < 0x259) && (0 < *(short *)(param_1 + 0xa4))) {
        *(undefined4 *)(param_1 + 0xb8) = 0x10009;
      }
      goto LAB_1008d41c;
    }
    if (*(int *)(param_1 + 0xf0) < 1) {
      if (*(short *)(param_1 + 0xa4) < 0x12d) {
        *(undefined4 *)(param_1 + 0xf0) = 0xc;
      }
      else {
        *(undefined4 *)(param_1 + 0xf0) = 0x1e;
      }
      *(undefined4 *)(param_1 + 0xb8) = 0;
    }
  }
LAB_1008d41c:
  .debug::_ApplyGravityAndSeparateFromTiles(param_1);
  .debug::_StandardSpriteCleanup(param_1);
  return;
}


// ==== .HitWizardSprite @ 1008d470 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitWizardSprite(int param_1,int param_2)

{
  short sVar1;
  short sVar2;
  undefined *puVar3;
  short sStack_28;
  short sStack_26;
  
  puVar3 = *(undefined **)(param_2 + 0x4c);
  if (((puVar3 == PTR_PTR_100a04e8) && (*(short *)(param_2 + 0xa6) == 0)) &&
     (0 < *(short *)(param_1 + 0xa4))) {
    if (*(short *)(param_2 + 0x1a2) < 1) {
      *(int *)(param_2 + 0x24) =
           (int)(((double)CONCAT44(0x43300000,*(uint *)(param_2 + 0x24) ^ 0x80000000) - dRam100a1ca8
                 ) * dRam100a1ca0);
      *(undefined2 *)(param_2 + 0x1a2) = 1;
      *(undefined1 *)(param_2 + 0x8c) = 1;
    }
  }
  else if (((puVar3 == PTR_PTR_100a01f8) || (puVar3 == PTR_PTR_100a0484)) &&
          (-1 < *(int *)(param_2 + 0x160))) {
    sStack_26 = *(short *)(param_1 + 0x36) +
                (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
    sStack_28 = *(short *)(param_1 + 0x34) +
                (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
    sVar1 = .debug::_PlatformBounce(param_1,param_2,&sStack_28,0,param_1 + 0x34,0);
    if ((sVar1 == 2) && ((0 < *(int *)(param_2 + 0x2c) || (*(char *)(param_1 + 0xce) != '\0')))) {
      .debug::_HurtSprite(param_1,100,(int)(short)(*(int *)(param_2 + 0x24) >> 1),0xfffffc18,2,8);
      *(undefined4 *)(param_1 + 0xf0) = 0;
      .debug::_KillBox(param_2);
      sVar1 = .debug::_FastRand(10000);
      .debug::_STPlay3DSoundPitched
                (*_DAT_100a0274,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar1 + 42000);
      sVar1 = .debug::_FastRand(10000);
      sVar2 = .debug::_FastRand(2);
      .debug::_STPlay3DSoundPitched
                (*(undefined4 *)(_DAT_100a0320 + sVar2 * 4),1,0x100,*(undefined4 *)(param_1 + 0xe),
                 sVar1 + 42000);
    }
  }
  return;
}


// ==== .KillWizard @ 1008d69c ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _KillWizard(int param_1)

{
  short *psVar1;
  undefined1 *puVar2;
  undefined2 *puVar3;
  int iVar4;
  
  iVar4 = _DAT_1009ffc0;
  psVar1 = _DAT_1009feac;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b5) != '\0')) {
    *_DAT_1009ffb4 = *_DAT_1009ffb4 + -1;
    iVar4 = iVar4 + *psVar1 * 2;
    *(short *)(iVar4 + 0x306) = *(short *)(iVar4 + 0x306) + 1;
  }
  *(undefined1 *)(param_1 + 0xe9) = 1;
  *(undefined1 *)(param_1 + 0xea) = 1;
  if (*(int *)(param_1 + 0x170) != 0) {
    .debug::_STPlay3DSoundPitched(*_DAT_1009fd68,1,0x100,*(undefined4 *)(param_1 + 0xe),48000);
    puVar3 = _DAT_100a00fc;
    *_DAT_1009ffa0 = 0x1e;
    puVar2 = _DAT_1009fed0;
    *puVar3 = 3;
    *puVar2 = 1;
  }
  return;
}


// ==== .HitWizardTileSprite @ 1008d784 ====

void _HitWizardTileSprite(int param_1,undefined4 param_2,int param_3,short param_4)

{
  char cVar1;
  short sStack_46;
  short sStack_44;
  undefined1 auStack_26 [26];
  
  sStack_44 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_46 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  .glue::SetRect(auStack_26,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                 (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
  if (param_4 == 1) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_46,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 100) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_46,0,param_1 + 0x34,0,0);
  }
  else if ((short)param_3 < 200) {
    .debug::_WallBounceBG(param_1,param_3 + -100,&stack0x0000001c,&sStack_46,0,param_1 + 0x34,0,0);
  }
  else {
    cVar1 = .debug::_IsWaterTile(param_3);
    if ((cVar1 != '\0') && (*(char *)(param_1 + 0x140) == '\0')) {
      .debug::_HandleUnderWater(param_1,param_2);
    }
  }
  return;
}


// ==== .HandleXichraWingSprite @ 1008dc7c ====

void _HandleXichraWingSprite(undefined4 param_1)

{
  .debug::_StandardSpriteHandles();
  .debug::_StandardSpriteCleanup(param_1);
  return;
}


// ==== .SetupXichraSprite @ 1008dd44 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _SetupXichraSprite(int param_1)

{
  char *pcVar1;
  undefined1 *puVar2;
  int *piVar3;
  undefined *puVar4;
  int iVar5;
  int iVar6;
  int iVar7;
  undefined *puVar8;
  undefined *puVar9;
  undefined *puVar10;
  int iVar11;
  int iVar12;
  int iVar13;
  int iVar14;
  undefined2 uVar17;
  undefined4 uVar15;
  undefined4 uVar16;
  short sVar18;
  int iVar19;
  undefined4 *puVar20;
  undefined4 *puVar21;
  double dVar22;
  double dVar23;
  double dVar24;
  undefined8 uStack_48;
  undefined8 uStack_40;
  
  uVar16 = _DAT_1009ff30;
  .debug::_InitSprite();
  puVar4 = PTR_PTR_100a048c;
  if (*(short *)(param_1 + 0x48) == 0x1ff) {
    *(undefined **)(param_1 + 0x4c) = PTR_PTR_100a0dcc;
  }
  else {
    *(undefined1 *)(param_1 + 0x18a) = 1;
    puVar10 = PTR_PTR_100a0dc8;
    *(undefined2 *)(param_1 + 0x84) = 0;
    puVar9 = PTR_PTR_100a0dc4;
    *(undefined2 *)(param_1 + 0x86) = 0;
    puVar8 = PTR_PTR_100a0dc0;
    *(undefined4 *)(param_1 + 0x80) = 1;
    iVar14 = _DAT_100a0e04;
    *(undefined **)(param_1 + 0x4c) = puVar4;
    iVar7 = _DAT_100a0e08;
    *(undefined **)(param_1 + 0x5c) = puVar10;
    iVar12 = _DAT_100a0e0c;
    *(undefined **)(param_1 + 0x1f8) = puVar9;
    iVar5 = _DAT_100a0dfc;
    *(undefined **)(param_1 + 0x50) = puVar8;
    iVar11 = _DAT_100a0e00;
    *(undefined2 *)(param_1 + 0xa6) = 0;
    iVar19 = _DAT_100a0df0;
    *(undefined1 *)(iVar14 + 1) = 1;
    iVar6 = _DAT_100a0df4;
    *(undefined1 *)(iVar7 + 1) = 1;
    iVar7 = _DAT_100a0df8;
    *(undefined1 *)(iVar12 + 1) = 1;
    iVar14 = _DAT_100a0de4;
    *(undefined1 *)(iVar5 + 1) = 1;
    iVar5 = _DAT_100a0de8;
    *(undefined1 *)(iVar11 + 1) = 1;
    iVar13 = _DAT_100a0dec;
    *(undefined1 *)(iVar19 + 1) = 1;
    iVar19 = _DAT_100a0ddc;
    *(undefined1 *)(iVar6 + 1) = 1;
    iVar12 = _DAT_100a0de0;
    *(undefined1 *)(iVar7 + 1) = 1;
    iVar6 = _DAT_100a0dd0;
    *(undefined1 *)(iVar14 + 1) = 1;
    iVar7 = _DAT_100a0dd4;
    *(undefined1 *)(iVar5 + 1) = 1;
    iVar11 = _DAT_100a0dd8;
    *(undefined1 *)(iVar13 + 1) = 1;
    iVar5 = _DAT_100a0848;
    *(undefined1 *)(iVar19 + 1) = 1;
    iVar14 = _DAT_100a0840;
    *(undefined1 *)(iVar12 + 1) = 1;
    iVar19 = _DAT_100a083c;
    *(undefined1 *)(iVar6 + 1) = 1;
    puVar4 = PTR_DAT_100a09f4;
    *(undefined1 *)(iVar7 + 1) = 1;
    iVar7 = _DAT_100a09ec;
    *(undefined1 *)(iVar11 + 1) = 1;
    iVar6 = _DAT_100a09d0;
    *(undefined1 *)(iVar5 + 1) = 1;
    iVar5 = _DAT_100a09c8;
    *(undefined1 *)(iVar14 + 1) = 1;
    iVar14 = _DAT_100a09cc;
    *(undefined1 *)(iVar19 + 1) = 1;
    iVar19 = _DAT_100a09c4;
    puVar4[0x71] = 1;
    puVar2 = _DAT_1009fed0;
    *(undefined1 *)(iVar7 + 1) = 1;
    *(undefined1 *)(iVar6 + 1) = 1;
    *(undefined1 *)(iVar5 + 1) = 1;
    *(undefined1 *)(iVar14 + 1) = 1;
    *(undefined1 *)(iVar19 + 1) = 1;
    *(undefined2 *)(param_1 + 0x110) = 0;
    *(undefined4 *)(param_1 + 0xc0) = 0;
    *(undefined2 *)(param_1 + 0xa4) = 5000;
    *puVar2 = 0;
    *(undefined1 *)(param_1 + 0x88) = 0;
    *(undefined1 *)(param_1 + 0x1b4) = 0;
    *(int *)(param_1 + 0x168) = (int)*(short *)(param_1 + 0xa4);
    *(undefined2 *)(param_1 + 0xc) = *(undefined2 *)(param_1 + 8);
    *(undefined2 *)(param_1 + 10) = *(undefined2 *)(param_1 + 6);
    .glue::SetRect(param_1 + 0x34,0x5c,0x3a,0x93,0x90);
    *(undefined4 *)(param_1 + 0x150) = 0xffffffff;
    *(undefined2 *)(param_1 + 0xb0) = 0;
    *(undefined2 *)(param_1 + 0xb2) = 0;
    *(undefined2 *)(param_1 + 0x46) = 2;
    *(undefined4 *)(param_1 + 0x14c) = 0;
    uVar17 = .debug::_FastRand(10);
    *(undefined2 *)(param_1 + 0xa6) = uVar17;
    *(undefined4 *)(param_1 + 0xf0) = 0xf;
    *(undefined2 *)(param_1 + 0xc) = 0x145;
    *(undefined2 *)(param_1 + 10) = 0x48;
    *(int *)(param_1 + 0x15c) = *(short *)(param_1 + 0xc) + -0x100;
    *(int *)(param_1 + 0x160) = *(short *)(param_1 + 0xc) + 0x100;
    *(int *)(param_1 + 0x168) = (int)*(short *)(param_1 + 0xc);
    *(undefined4 *)(param_1 + 0x164) = 0;
    *(undefined1 *)(param_1 + 0x17e) = 0;
    uVar15 = .debug::_AllocateGameMem(0x374);
    *(undefined4 *)(param_1 + 0x9c) = uVar15;
    puVar21 = *(undefined4 **)(param_1 + 0x9c);
    uVar15 = .debug::_MTNewSprite(100,0,0,*(int *)(param_1 + 0x80) + -1,0x1ff,_DAT_1009fee4);
    *puVar21 = uVar15;
    *(undefined2 *)(puVar21 + 3) = *(undefined2 *)(param_1 + 0xc);
    *(undefined2 *)((int)puVar21 + 0xe) = *(undefined2 *)(param_1 + 10);
    uVar15 = .debug::_MTNewSprite(0x443,0xffffffe8,0x104,*(int *)(param_1 + 0x80) + -1,400,uVar16);
    puVar21[1] = uVar15;
    uVar16 = .debug::_MTNewSprite(0x449,0x30b,0x106,*(int *)(param_1 + 0x80) + -1,0x191,uVar16);
    puVar21[2] = uVar16;
    iVar19 = 0;
    dVar23 = (double)fRam100a1cdc;
    puVar20 = puVar21;
    dVar24 = dRam100a1cd0;
    for (sVar18 = 0; sVar18 < 0x14; sVar18 = sVar18 + 1) {
      iVar14 = iVar19 / 0x14 + (iVar19 >> 0x1f);
      uStack_40 = (double)CONCAT44(0x43300000,iVar14 - (iVar14 >> 0x1f) ^ 0x80000000);
      dVar22 = (double)(float)(uStack_40 - dVar24);
      .debug::_sinDegrees();
      iVar19 = iVar19 + 0x168;
      *(short *)(puVar20 + 0x1f) = (short)(int)(dVar22 * dVar23);
      puVar20 = (undefined4 *)((int)puVar20 + 2);
    }
    iVar19 = 0;
    dVar23 = (double)fRam100a1cd8;
    puVar20 = puVar21;
    dVar24 = dRam100a1cd0;
    for (sVar18 = 0; pcVar1 = _DAT_1009fe8c, sVar18 < 0x168; sVar18 = sVar18 + 1) {
      iVar14 = iVar19 / 0x168 + (iVar19 >> 0x1f);
      uStack_48 = (double)CONCAT44(0x43300000,iVar14 - (iVar14 >> 0x1f) ^ 0x80000000);
      dVar22 = (double)(float)(uStack_48 - dVar24);
      .debug::_sinDegrees();
      iVar19 = iVar19 + 0x168;
      *(short *)(puVar20 + 0x29) = (short)(int)(dVar22 * dVar23);
      puVar20 = (undefined4 *)((int)puVar20 + 2);
    }
    *(undefined2 *)(puVar21 + 7) = 3;
    *(undefined2 *)((int)puVar21 + 0x6a) = 0;
    *(undefined2 *)(param_1 + 0xa6) = 0;
    *(undefined2 *)(param_1 + 0xb0) = 0;
    puVar21[8] = 0xb4;
    *(undefined4 *)(param_1 + 0xf0) = 0x1e;
    piVar3 = _DAT_1009ffb4;
    if (*pcVar1 != '\0') {
      *(undefined1 *)(param_1 + 0x1b5) = 1;
      *piVar3 = *piVar3 + 1;
    }
    *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
    *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
  }
  return;
}


// ==== .HandleXichraSprite @ 1008e4ec ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HandleXichraSprite(int param_1)

{
  int *piVar1;
  undefined4 *puVar2;
  undefined *puVar3;
  undefined2 *puVar4;
  undefined4 *puVar5;
  undefined2 *puVar6;
  undefined4 *puVar7;
  undefined *puVar8;
  uint uVar9;
  int iVar10;
  int iVar11;
  char cVar16;
  short sVar14;
  short sVar15;
  undefined4 uVar12;
  undefined4 uVar13;
  int iVar17;
  int *piVar18;
  
  puVar8 = PTR_PTR_100a0830;
  puVar7 = _DAT_100a0344;
  iVar10 = _DAT_100a0320;
  puVar6 = _DAT_100a00fc;
  puVar5 = _DAT_100a0058;
  puVar4 = _DAT_1009ffa0;
  uVar12 = _DAT_1009ff34;
  uVar13 = _DAT_1009ff24;
  puVar3 = PTR_DAT_1009fe78;
  puVar2 = _DAT_1009fdec;
  piVar18 = *(int **)(param_1 + 0x9c);
  if ((*(short *)(param_1 + 0xb0) != 4) && (*(short *)(param_1 + 0xb0) != 5)) {
    *(short *)(param_1 + 10) =
         *(short *)(param_1 + 10) - *(short *)((int)piVar18 + *(short *)(piVar18 + 6) * 2 + 0x7c);
  }
  if (*(char *)(param_1 + 0xe9) != '\0') {
    return;
  }
  if (*(char *)(param_1 + 0x1b2) != '\0') {
    return;
  }
  .debug::_StandardSpriteHandles(param_1);
  if (((*_DAT_100a0064 != '\0') && (cVar16 = .debug::_IsPressed(0x79), cVar16 != '\0')) &&
     (*(short *)(param_1 + 0xb0) != 4)) {
    *(short *)(piVar18 + 7) = *(short *)(piVar18 + 7) + -1;
    *(undefined2 *)(param_1 + 0xaa) = 5;
    *(undefined2 *)(param_1 + 0x116) = 5;
    sVar14 = .debug::_FastRand(10000);
    sVar15 = .debug::_FastRand(2);
    .debug::_STPlay3DSoundPitched
              (*(undefined4 *)(iVar10 + sVar15 * 4),1,0x100,*(undefined4 *)(param_1 + 0xe),
               sVar14 + 78000);
    sVar14 = .debug::_FastRand(10000);
    sVar15 = .debug::_FastRand(2);
    .debug::_STPlay3DSoundPitched
              (*(undefined4 *)(iVar10 + sVar15 * 4),1,0x97,*(undefined4 *)(param_1 + 0xe),
               sVar14 + 58000);
    if (*(short *)((int)piVar18 + 0x1a) == 2) {
      *(undefined2 *)(param_1 + 0xb0) = 4;
      *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
      *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
      *(undefined2 *)(param_1 + 0x46) = 0;
      *(undefined4 *)(param_1 + 0x2c) = 0;
      *(undefined4 *)(param_1 + 0x24) = 0;
      piVar18[0xe] = 0;
      piVar18[0xf] = 0;
    }
  }
  switch(*(undefined2 *)((int)piVar18 + 0x6a)) {
  case 0:
    *(undefined2 *)((int)piVar18 + 0x1a) = 0;
    piVar18[0xb] = 0;
    *(undefined2 *)(*(int *)*puVar5 + 0x2730) = 3;
    break;
  case 1:
    *(undefined2 *)((int)piVar18 + 0x1a) = 0;
    if ((*(int *)(param_1 + 0x1d4) != 0) && (*(char *)(*(int *)(param_1 + 0x1d4) + 0xe9) != '\0')) {
      *(short *)(piVar18 + 0x1b) = *(short *)(piVar18 + 0x1b) + -1;
      *(undefined4 *)(param_1 + 0x1d4) = 0;
    }
    if ((*(int *)(param_1 + 0x1d8) != 0) && (*(char *)(*(int *)(param_1 + 0x1d8) + 0xe9) != '\0')) {
      *(short *)(piVar18 + 0x1b) = *(short *)(piVar18 + 0x1b) + -1;
      *(undefined4 *)(param_1 + 0x1d8) = 0;
    }
    if (*(short *)(piVar18 + 0x1b) < 1) {
      .debug::_Conversation(0xfb,(int)*(short *)(param_1 + 0x48),param_1);
      *(undefined2 *)((int)piVar18 + 0x6a) = 2;
    }
    break;
  case 2:
    *(undefined2 *)((int)piVar18 + 0x1a) = 0;
    *(undefined2 *)(*(int *)*puVar5 + 0x2730) = 3;
    piVar18[9] = 0x200;
    piVar18[0xd] = piVar18[0xd] + -1;
    if ((piVar18[0xd] < 1) && (*(char *)((int)piVar18 + 0x12) != '\0')) {
      sVar14 = *(short *)(param_1 + 0xb0);
      if (sVar14 == 0) {
        *(undefined2 *)(param_1 + 0xb0) = 1;
        *(undefined2 *)(param_1 + 0xb2) = 0;
      }
      else if (sVar14 == 1) {
        *(undefined2 *)(param_1 + 0xb0) = 2;
        *(undefined2 *)(param_1 + 0xb2) = 0;
      }
      else if (sVar14 == 2) {
        *(undefined2 *)(param_1 + 0xb0) = 0;
        sVar14 = .debug::_FastRand(0x3c);
        piVar18[0xd] = sVar14 + 0x5a;
      }
    }
    if (*(short *)(piVar18 + 7) < 1) {
      *(undefined2 *)((int)piVar18 + 0x6a) = 3;
      *(undefined2 *)(piVar18 + 7) = 4;
      *puVar6 = 5;
      sVar14 = .debug::_FastRand(12000);
      .debug::_STPlay3DSoundPitched(*puVar7,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar14 + 78000);
      .debug::_UpdateXichraCannons(param_1,1);
    }
    break;
  case 3:
    *(undefined2 *)((int)piVar18 + 0x1a) = 1;
    *(undefined2 *)(*(int *)*puVar5 + 0x2730) = 4;
    piVar18[9] = 0x300;
    piVar18[0xd] = piVar18[0xd] + -1;
    if ((piVar18[0xd] < 1) && (*(char *)((int)piVar18 + 0x12) != '\0')) {
      sVar14 = *(short *)(param_1 + 0xb0);
      if (sVar14 == 0) {
        *(undefined2 *)(param_1 + 0xb0) = 1;
        *(undefined2 *)(param_1 + 0xb2) = 0;
      }
      else if (sVar14 == 1) {
        *(undefined2 *)(param_1 + 0xb0) = 2;
        *(undefined2 *)(param_1 + 0xb2) = 0;
      }
      else if (sVar14 == 2) {
        *(undefined2 *)(param_1 + 0xb0) = 0;
        sVar14 = .debug::_FastRand(0x3c);
        piVar18[0xd] = sVar14 + 0x5a;
      }
    }
    if (*(short *)(piVar18 + 7) < 1) {
      *(undefined2 *)((int)piVar18 + 0x6a) = 4;
      *(undefined2 *)(piVar18 + 7) = 4;
      *puVar6 = 5;
      sVar14 = .debug::_FastRand(12000);
      .debug::_STPlay3DSoundPitched(*puVar7,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar14 + 78000);
      sVar14 = .debug::_FastRand(12000);
      .debug::_STPlay3DSoundPitched(*puVar7,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar14 + 90000);
    }
    break;
  case 4:
    *(undefined2 *)((int)piVar18 + 0x1a) = 2;
    *(undefined2 *)(*(int *)*puVar5 + 0x2730) = 5;
    piVar18[9] = 0x400;
    piVar18[0xd] = piVar18[0xd] + -1;
    if ((piVar18[0xd] < 1) && (*(char *)((int)piVar18 + 0x12) != '\0')) {
      sVar14 = *(short *)(param_1 + 0xb0);
      if (sVar14 == 0) {
        *(undefined2 *)(param_1 + 0xb0) = 1;
        *(undefined2 *)(param_1 + 0xb2) = 0;
      }
      else if (sVar14 == 1) {
        *(undefined2 *)(param_1 + 0xb0) = 2;
        *(undefined2 *)(param_1 + 0xb2) = 0;
      }
      else if (sVar14 == 2) {
        *(undefined2 *)(param_1 + 0xb0) = 0;
        sVar14 = .debug::_FastRand(0x3c);
        piVar18[0xd] = sVar14 + 0x5a;
      }
    }
    break;
  case 5:
    *(undefined2 *)((int)piVar18 + 0x1a) = 3;
    *(undefined2 *)(*(int *)*puVar5 + 0x2730) = 6;
    piVar18[9] = 0x600;
    piVar18[0xd] = piVar18[0xd] + -1;
    if ((piVar18[0xd] < 1) && (*(char *)((int)piVar18 + 0x12) != '\0')) {
      sVar14 = *(short *)(param_1 + 0xb0);
      if (sVar14 == 0) {
        *(undefined2 *)(param_1 + 0xb0) = 1;
        *(undefined2 *)(param_1 + 0xb2) = 0;
      }
      else if (sVar14 == 1) {
        *(undefined2 *)(param_1 + 0xb0) = 2;
        *(undefined2 *)(param_1 + 0xb2) = 0;
      }
      else if (sVar14 == 2) {
        *(undefined2 *)(param_1 + 0xb0) = 0;
        sVar14 = .debug::_FastRand(0x3c);
        piVar18[0xd] = sVar14 + 0x5a;
      }
    }
    if ((*(short *)(piVar18 + 7) < 1) &&
       ((*(short *)(param_1 + 0xb0) == 0 || ((ushort)(*(short *)(param_1 + 0xb0) - 1U) < 2)))) {
      *(undefined2 *)((int)piVar18 + 0x6a) = 6;
      *puVar6 = 7;
      *(undefined2 *)(param_1 + 0xa4) = 9999;
      *(undefined2 *)(param_1 + 0xb0) = 4;
      *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
      *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
      *(undefined2 *)(param_1 + 0x46) = 0;
      *(undefined4 *)(param_1 + 0x2c) = 0;
      *(undefined4 *)(param_1 + 0x24) = 0;
      piVar18[0xe] = 0;
      piVar18[0xf] = 0;
      sVar14 = .debug::_FastRand(12000);
      .debug::_STPlay3DSoundPitched(*puVar7,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar14 + 78000);
      sVar14 = .debug::_FastRand(12000);
      .debug::_STPlay3DSoundPitched(*puVar7,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar14 + 90000);
    }
    break;
  case 6:
    *(undefined2 *)((int)piVar18 + 0x1a) = 4;
    *(undefined2 *)(*(int *)*puVar5 + 0x2730) = 7;
    piVar18[9] = 0;
  }
  switch(*(undefined2 *)(param_1 + 0xb0)) {
  case 0:
    *(undefined1 *)((int)piVar18 + 0x12) = 0;
    .glue::SetRect(param_1 + 0x34,0x5c,0x3a,0x93,0x90);
    .debug::_StandardXichraFloat(param_1);
    if (piVar18[0xb] == piVar18[9]) {
      *(undefined1 *)((int)piVar18 + 0x12) = 1;
    }
    *(short *)(param_1 + 0xa6) = *(short *)(param_1 + 0xa6) + 1;
    if (*(short *)(param_1 + 0xa6) == 0x50) {
      .debug::_Conversation(0xfa,(int)*(short *)(param_1 + 0x48),param_1);
      *(undefined2 *)((int)piVar18 + 0x6a) = 1;
      *(undefined2 *)(*(int *)*puVar5 + 0x1f4c) = 4;
      *(undefined2 *)(piVar18 + 0x1b) = 2;
      uVar12 = .debug::_MTNewSprite
                         (0x6d6,*(short *)(param_1 + 0x10) + -0x12a,*(short *)puVar3 + -0x6e,0x14,
                          500,uVar13);
      *(undefined4 *)(param_1 + 0x1d4) = uVar12;
      *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0x100) = 1;
      uVar13 = .debug::_MTNewSprite
                         (0x6d6,*(short *)(param_1 + 0x10) + 0x52,*(short *)puVar3 + -0x6e,0x14,500,
                          uVar13);
      *(undefined4 *)(param_1 + 0x1d8) = uVar13;
      *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0x100) = 1;
    }
    break;
  case 1:
    *(undefined1 *)((int)piVar18 + 0x12) = 0;
    sVar14 = *(short *)(param_1 + 0xb2);
    if (sVar14 == 1) {
      piVar18[9] = 0;
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      *(undefined2 *)(piVar18 + 5) = 1;
      iVar10 = (int)*(short *)(param_1 + 0x46);
      if (iVar10 < 0xc) {
        *(short *)((int)piVar18 + 0x16) = (short)(iVar10 >> 1);
      }
      else {
        *(short *)((int)piVar18 + 0x16) = (short)(0x15 - iVar10 >> 1);
      }
      if (*(short *)(param_1 + 0x46) == 0xc) {
        .debug::_DoXichraShot(param_1,3);
      }
      if (0x14 < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0xb2) = 2;
      }
    }
    else if (sVar14 < 1) {
      if (-1 < sVar14) {
        .debug::_StandardXichraFloat(param_1);
        if (piVar18[9] != 0) {
          piVar18[10] = piVar18[9];
        }
        piVar18[9] = 0;
        if ((piVar18[0xb] == piVar18[9]) && (*(short *)((int)piVar18 + 0x16) == 0)) {
          *(undefined2 *)(param_1 + 0xb2) = 1;
        }
      }
    }
    else if (sVar14 < 3) {
      .debug::_StandardXichraFloat(param_1);
      if (piVar18[9] == 0) {
        piVar18[9] = piVar18[10];
      }
      if ((piVar18[0xb] == piVar18[9]) && (*(short *)((int)piVar18 + 0x16) == 0)) {
        *(undefined1 *)((int)piVar18 + 0x12) = 1;
      }
    }
    break;
  case 2:
    *(undefined1 *)((int)piVar18 + 0x12) = 0;
    sVar14 = *(short *)(param_1 + 0xb2);
    if (sVar14 == 1) {
      piVar18[9] = 0;
      piVar18[0x12] = piVar18[0x12] + -1;
      if (piVar18[0x12] < 1) {
        if (piVar18[0x18] == 1) {
          uVar9 = piVar18[0x13] & 1;
          if (piVar18[0x10] != 0) {
            uVar9 = (uint)(uVar9 == 0);
          }
          if (uVar9 == 0) {
            iVar10 = piVar18[0x15] - piVar18[0x11];
          }
          else {
            iVar10 = piVar18[0x11];
          }
          iVar11 = piVar18[0x15];
          if (uVar9 == 0) {
            uVar9 = 0x2c0 / iVar11;
            iVar17 = ((int)uVar9 >> 2) + (uint)((int)uVar9 < 0 && (uVar9 & 3) != 0);
          }
          else {
            uVar9 = 0x2c0 / iVar11;
            iVar17 = -(((int)uVar9 >> 2) + (uint)((int)uVar9 < 0 && (uVar9 & 3) != 0));
          }
          iVar17 = (iVar10 * 0x2c0) / iVar11 + 0x60 + iVar17;
          iVar10 = (int)*(short *)puVar3;
          if (piVar18[0x19] == 2) {
            iVar10 = .debug::_MTNewSprite(0x753,iVar17 + -0x2f,iVar10 + -0x3f,9,0xffffffff,puVar8);
          }
          else if (piVar18[0x19] == 1) {
            iVar10 = .debug::_MTNewSprite(0x5c4,iVar17 + -0x33,iVar10 + -0x43,9,0xffffffff,uVar12);
          }
          else {
            iVar10 = .debug::_MTNewSprite(0x434,iVar17 + -0x10,iVar10 + -0x20,9,0xffffffff,uVar12);
          }
        }
        else {
          sVar14 = 0x1a4 - (short)((piVar18[0x11] * 0xa0) / piVar18[0x15]);
          iVar10 = .debug::_MTNewSprite
                             (0x771,(int)(short)(*(short *)(puVar3 + 2) + -0x3c),(int)sVar14,9,
                              0xffffffff,puVar8);
          *(undefined2 *)(iVar10 + 0xa4) = 0x70;
          *(undefined4 *)(iVar10 + 0x16c) = 1;
          *(undefined4 *)(iVar10 + 0x24) = 0x1068;
          .debug::_MTChangeSpriteLayer(iVar10,0x4b0);
          iVar10 = .debug::_MTNewSprite
                             (0x772,(int)(short)(*(short *)(puVar3 + 2) + 0x260),(int)sVar14,9,
                              0xffffffff,puVar8);
          *(undefined2 *)(iVar10 + 0xa4) = 0x70;
          *(undefined4 *)(iVar10 + 0x16c) = 1;
          *(undefined4 *)(iVar10 + 0x24) = 0xffffef98;
          .debug::_MTChangeSpriteLayer(iVar10,0x4b0);
          *(undefined2 *)(iVar10 + 0x110) = 0;
          *(undefined4 *)(iVar10 + 0x2c) = 0;
        }
        .debug::_CalcCenterPos(iVar10);
        piVar18[0x11] = piVar18[0x11] + -1;
        if (piVar18[0x11] < 0) {
          piVar18[0x13] = piVar18[0x13] + -1;
          if (piVar18[0x13] < 1) {
            *(undefined2 *)(param_1 + 0xb2) = 2;
          }
          else {
            piVar18[0x12] = piVar18[0x17];
            piVar18[0x11] = piVar18[0x15];
          }
        }
        else {
          piVar18[0x12] = piVar18[0x16];
        }
      }
    }
    else if (sVar14 < 1) {
      if (-1 < sVar14) {
        .debug::_StandardXichraFloat(param_1);
        if (piVar18[9] != 0) {
          piVar18[10] = piVar18[9];
        }
        piVar18[9] = 0;
        *(short *)(piVar18 + 0x1a) = *(short *)(piVar18 + 0x1a) + 1;
        if (0x25 < *(short *)(piVar18 + 0x1a)) {
          *(undefined2 *)(piVar18 + 0x1a) = 0x25;
        }
        if (((piVar18[0xb] == piVar18[9]) && (*(short *)(piVar18 + 0x1a) == 0x25)) &&
           (*(short *)((int)piVar18 + 0x16) == 0)) {
          *(undefined2 *)(param_1 + 0xb2) = 1;
          sVar14 = *(short *)((int)piVar18 + 0x1a);
          if (sVar14 == 0) {
            piVar18[0x12] = 0;
            piVar18[0x15] = 8;
            piVar18[0x11] = 8;
            sVar14 = .debug::_FastRand(3);
            piVar18[0x13] = sVar14 + 2;
            sVar14 = .debug::_FastRand(100);
            piVar18[0x10] = ((int)sVar14 >> 0x1f) + (uint)(0x31 < (uint)(int)sVar14);
            piVar18[0x16] = 9;
            piVar18[0x17] = 0x15;
            piVar18[0x18] = 1;
          }
          else if (sVar14 == 1) {
            piVar18[0x12] = 0;
            piVar18[0x15] = 5;
            piVar18[0x11] = 5;
            piVar18[0x13] = 3;
            piVar18[0x16] = 10;
            piVar18[0x17] = 0x1e;
            piVar18[0x18] = 0;
          }
          else if (sVar14 == 2) {
            piVar18[0x12] = 0;
            piVar18[0x15] = 7;
            piVar18[0x11] = 7;
            sVar14 = .debug::_FastRand(4);
            piVar18[0x13] = sVar14 + 1;
            piVar18[0x16] = 8;
            piVar18[0x17] = 0x10;
            piVar18[0x18] = 1;
            piVar18[0x19] = 1;
            sVar14 = .debug::_FastRand(100);
            piVar18[0x10] = ((int)sVar14 >> 0x1f) + (uint)(0x31 < (uint)(int)sVar14);
          }
          else if (sVar14 == 3) {
            piVar18[0x12] = 0;
            piVar18[0x15] = 6;
            piVar18[0x11] = 6;
            sVar14 = .debug::_FastRand(2);
            piVar18[0x13] = sVar14 + 1;
            piVar18[0x16] = 8;
            piVar18[0x17] = 0x10;
            piVar18[0x18] = 1;
            piVar18[0x19] = 2;
            sVar14 = .debug::_FastRand(100);
            piVar18[0x10] = ((int)sVar14 >> 0x1f) + (uint)(0x31 < (uint)(int)sVar14);
          }
        }
      }
    }
    else if (sVar14 < 3) {
      .debug::_StandardXichraFloat(param_1);
      if (piVar18[9] == 0) {
        piVar18[9] = piVar18[10];
      }
      *(short *)(piVar18 + 0x1a) = *(short *)(piVar18 + 0x1a) + -1;
      if (*(short *)(piVar18 + 0x1a) < 0) {
        *(undefined2 *)(piVar18 + 0x1a) = 0;
      }
      if (((piVar18[0xb] == piVar18[9]) && (*(short *)(piVar18 + 0x1a) == 0)) &&
         (*(short *)((int)piVar18 + 0x16) == 0)) {
        *(undefined1 *)((int)piVar18 + 0x12) = 1;
      }
    }
    break;
  case 4:
    piVar18[9] = 0;
    *(undefined2 *)(piVar18 + 6) = 10;
    .glue::SetRect(param_1 + 0x34,0x5c,0x50,0x93,0xa2);
    *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
    *(undefined2 *)(param_1 + 0x110) = 0x15e;
    *(undefined2 *)(piVar18 + 5) = 2;
    if (*(char *)(param_1 + 0xcd) == '\0') {
      if (0x12 < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0x12;
      }
      sVar14 = *(short *)(param_1 + 0x46);
      *(short *)((int)piVar18 + 0x16) =
           (short)((ulonglong)((longlong)(int)sVar14 * 0x55555556) >> 0x20) -
           ((short)((short)((int)sVar14 / 0x30000) + (sVar14 >> 0xf)) >> 0xf);
    }
    else {
      if (piVar18[0xe] == 1) {
        sVar14 = .debug::_FastRand(500);
        .debug::_STPlay3DSoundPitched(*puVar2,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar14 + 50000)
        ;
        piVar1 = _DAT_1009fdd8;
        *puVar4 = 0x12;
        if ((*(char *)(*piVar1 + 0xce) != '\0') || (*(char *)(*piVar1 + 0xcd) != '\0')) {
          *_DAT_100a0570 = 0x14;
        }
      }
      if (0x12 < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0x12;
      }
      piVar18[0xe] = piVar18[0xe] + 1;
      sVar14 = *(short *)(param_1 + 0x46);
      *(short *)((int)piVar18 + 0x16) =
           (short)((ulonglong)((longlong)(int)sVar14 * 0x55555556) >> 0x20) -
           ((short)((short)((int)sVar14 / 0x30000) + (sVar14 >> 0xf)) >> 0xf);
      if ((6 < piVar18[0xe]) && (*(short *)(param_1 + 0x46) == 0x12)) {
        piVar18[0xe] = 0;
        *(undefined2 *)(param_1 + 0x46) = 0xc;
        *(undefined2 *)(piVar18 + 4) = *(undefined2 *)(param_1 + 10);
        if (*(short *)(param_1 + 0xa4) < 1) {
          if (*(short *)((int)piVar18 + 0x1a) == 2) {
            *(short *)((int)piVar18 + 0x6a) = *(short *)((int)piVar18 + 0x6a) + 1;
            *(undefined2 *)((int)piVar18 + 0x1a) = 3;
            *(undefined2 *)(param_1 + 0xb0) = 7;
            *(undefined2 *)(param_1 + 0x46) = 0x18;
            *(undefined2 *)(piVar18 + 7) = 3;
          }
          else {
            *(undefined2 *)(param_1 + 0xb0) = 5;
          }
        }
        else if (*(short *)(piVar18 + 7) < 1) {
          if (*(short *)((int)piVar18 + 0x1a) == 4) {
            *(undefined2 *)((int)piVar18 + 0x6a) = 6;
            *(undefined2 *)(param_1 + 0x46) = 0x18;
            *(undefined2 *)(param_1 + 0xb0) = 8;
          }
          else {
            *(undefined2 *)(param_1 + 0xb0) = 5;
          }
        }
        else {
          *(undefined2 *)(param_1 + 0xb0) = 5;
        }
      }
    }
    break;
  case 5:
    piVar18[9] = 0;
    *(undefined2 *)(piVar18 + 6) = 10;
    *(undefined2 *)(piVar18 + 5) = 2;
    piVar18[0xe] = piVar18[0xe] + 1;
    if ((0x1e < piVar18[0xe]) &&
       (*(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1, *(short *)(param_1 + 0x46) < 0
       )) {
      *(undefined2 *)(param_1 + 0x46) = 0;
      *(undefined2 *)(param_1 + 0xb0) = 6;
      piVar18[0xf] = 0;
    }
    *(short *)((int)piVar18 + 0x16) = *(short *)(param_1 + 0x46) >> 1;
    break;
  case 6:
    sVar14 = 0x1c;
    if (*(char *)((int)piVar18 + 0x13) != '\0') {
      sVar14 = 0xe;
    }
    piVar18[9] = 0;
    *(undefined2 *)(piVar18 + 0x1a) = 0;
    piVar18[0xf] = piVar18[0xf] + 1;
    .debug::_StandardXichraFloat(param_1);
    iVar10 = (int)sVar14;
    if ((iVar10 < piVar18[0xf]) && (*(short *)((int)piVar18 + 0x16) == 0)) {
      *(undefined2 *)(param_1 + 0xb0) = 0;
    }
    if (iVar10 < piVar18[0xf]) {
      piVar18[0xf] = (int)sVar14;
    }
    *(short *)(param_1 + 10) =
         (short)(((int)*(short *)((int)piVar18 + 0xe) * piVar18[0xf]) / iVar10) +
         (short)(((int)*(short *)(piVar18 + 4) * (iVar10 - piVar18[0xf])) / iVar10);
    *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
    break;
  case 7:
    piVar18[9] = 0;
    *(undefined2 *)(piVar18 + 6) = 10;
    *(undefined2 *)(piVar18 + 5) = 2;
    piVar18[0xe] = piVar18[0xe] + 1;
    if (piVar18[0xe] < 0x7e) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (0x2b < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0x2b;
      }
      *(short *)((int)piVar18 + 0x16) = *(short *)(param_1 + 0x46) >> 2;
      if (piVar18[0xe] == 0x7d) {
        .debug::_Conversation(0xfc,(int)*(short *)(param_1 + 0x48),param_1);
        *(undefined2 *)(param_1 + 0x46) = 0xb;
        *puVar6 = 3;
        sVar14 = .debug::_FastRand(10000);
        sVar15 = .debug::_FastRand(2);
        .debug::_STPlay3DSoundPitched
                  (*(undefined4 *)(iVar10 + sVar15 * 4),1,0x100,*(undefined4 *)(param_1 + 0xe),
                   sVar14 + 78000);
        sVar14 = .debug::_FastRand(10000);
        sVar15 = .debug::_FastRand(2);
        .debug::_STPlay3DSoundPitched
                  (*(undefined4 *)(iVar10 + sVar15 * 4),1,0x97,*(undefined4 *)(param_1 + 0xe),
                   sVar14 + 58000);
      }
    }
    else {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + -1;
      if (*(short *)(param_1 + 0x46) < 0) {
        *(undefined2 *)(param_1 + 0x46) = 0;
        *(undefined2 *)(param_1 + 0xb0) = 6;
        *(undefined1 *)((int)piVar18 + 0x13) = 1;
        piVar18[0xf] = 0;
      }
      *(undefined2 *)((int)piVar18 + 0x16) = *(undefined2 *)(param_1 + 0x46);
    }
    break;
  case 8:
    piVar18[9] = 0;
    *(undefined2 *)(piVar18 + 6) = 10;
    *(undefined2 *)(piVar18 + 5) = 2;
    piVar18[0xe] = piVar18[0xe] + 1;
    if (piVar18[0xe] < 0x3d) {
      *(short *)(param_1 + 0x46) = *(short *)(param_1 + 0x46) + 1;
      if (0x2b < *(short *)(param_1 + 0x46)) {
        *(undefined2 *)(param_1 + 0x46) = 0x2b;
      }
      *(short *)((int)piVar18 + 0x16) = *(short *)(param_1 + 0x46) >> 2;
      if (piVar18[0xe] == 0x7d) {
        *(undefined2 *)(param_1 + 0x46) = 0xb;
      }
    }
    else {
      iVar10 = (int)(short)((short)piVar18[0xe] + -0x3c);
      if (iVar10 < 0x8c) {
        iVar11 = iVar10 / 0xc + (iVar10 >> 0x1f);
        if (iVar10 == (iVar11 - (iVar11 >> 0x1f)) * 0xc) {
          .debug::_STPlay3DSoundRand(*puVar2,1,0x100,*(undefined4 *)(param_1 + 0xe));
          *puVar6 = 4;
          *puVar4 = 0x14;
          iVar10 = .debug::_FastRand(0x1e);
          sVar14 = *(short *)(param_1 + 0xe);
          iVar11 = .debug::_FastRand(0x41);
          .debug::_MTNewSprite
                    (0x4b7,*(short *)(param_1 + 0x10) + iVar11 + -0x4b,sVar14 + iVar10 + -0x1f,0xc,
                     0xffffffff,_DAT_1009fef8);
        }
      }
      else if (0x96 < iVar10) {
        DAT_100a5106 = 1;
        *_DAT_1009ffc4 = 1;
      }
      *(undefined2 *)((int)piVar18 + 0x16) = 10;
    }
  }
  if (*(short *)(param_1 + 0xb0) != 8) {
    *(int *)(param_1 + 0xf0) = *(int *)(param_1 + 0xf0) + -1;
    iVar10 = *(int *)(param_1 + 0xf0);
    if (iVar10 < 4) {
      if (0 < iVar10) {
        if ((*(short *)(param_1 + 0xa4) < 0x7d1) && (0 < *(short *)(param_1 + 0xa4))) {
          *(undefined4 *)(param_1 + 0xb8) = 0x10008;
        }
        goto LAB_1008f9a0;
      }
    }
    else if (iVar10 < 7) {
      if ((*(short *)(param_1 + 0xa4) < 0x7d1) && (0 < *(short *)(param_1 + 0xa4))) {
        *(undefined4 *)(param_1 + 0xb8) = 0x10009;
      }
      goto LAB_1008f9a0;
    }
    if (*(int *)(param_1 + 0xf0) < 1) {
      if (*(short *)(param_1 + 0xa4) < 0x12d) {
        *(undefined4 *)(param_1 + 0xf0) = 0xc;
      }
      else {
        *(undefined4 *)(param_1 + 0xf0) = 0x1e;
      }
      *(undefined4 *)(param_1 + 0xb8) = 0;
    }
  }
LAB_1008f9a0:
  sVar14 = *(short *)(param_1 + 0xb0);
  if (sVar14 == 4) {
    .debug::_ApplyGravityAndSeparateFromTiles(param_1);
  }
  else if ((((sVar14 != 5) && (sVar14 != 6)) && (sVar14 != 7)) && (sVar14 != 8)) {
    iVar10 = piVar18[0xb];
    if (iVar10 < piVar18[9]) {
      piVar18[0xb] = iVar10 + 0x30;
      if (piVar18[9] < piVar18[0xb]) {
        piVar18[0xb] = piVar18[9];
      }
    }
    else if (piVar18[9] < iVar10) {
      piVar18[0xb] = iVar10 + -0x30;
      if (piVar18[0xb] < piVar18[9]) {
        piVar18[0xb] = piVar18[9];
      }
    }
    piVar18[8] = piVar18[8] + piVar18[0xb];
    if (0x167ff < piVar18[8]) {
      piVar18[8] = piVar18[8] + -0x16800;
    }
    *(short *)(param_1 + 0xc) =
         *(short *)(piVar18 + 3) + *(short *)((int)piVar18 + (piVar18[8] >> 8) * 2 + 0xa4);
    *(short *)(param_1 + 10) = *(short *)((int)piVar18 + 0xe) + *(short *)(piVar18 + 0x1a) * -6;
    *(int *)(param_1 + 0x14) = (int)*(short *)(param_1 + 0xc) << 8;
    *(int *)(param_1 + 0x1c) = (int)*(short *)(param_1 + 10) << 8;
  }
  sVar14 = *(short *)(piVar18 + 5);
  if (sVar14 == 1) {
    iVar10 = (int)*(short *)((int)piVar18 + 0x16);
    if (iVar10 < 4) {
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0e00 + iVar10 * 4 + 4);
    }
    else if (iVar10 < 8) {
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0dfc + iVar10 * 4 + -0xc);
    }
  }
  else if (sVar14 < 1) {
    if (-1 < sVar14) {
      iVar10 = (int)*(short *)((int)piVar18 + 0x16);
      if (iVar10 < 4) {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0e0c + iVar10 * 4 + 4);
      }
      else if (iVar10 < 8) {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0e08 + iVar10 * 4 + -0xc);
      }
      else if (iVar10 < 0xc) {
        *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0e04 + iVar10 * 4 + -0x1c);
      }
    }
  }
  else if (sVar14 < 3) {
    iVar10 = (int)*(short *)((int)piVar18 + 0x16);
    if (iVar10 < 4) {
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0df8 + iVar10 * 4 + 4);
    }
    else if (iVar10 < 8) {
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0df4 + iVar10 * 4 + -0xc);
    }
    else if (iVar10 < 0xc) {
      *(undefined4 *)(param_1 + 0xc0) = *(undefined4 *)(_DAT_100a0df0 + iVar10 * 4 + -0x1c);
    }
  }
  iVar10 = *piVar18;
  if (iVar10 != 0) {
    sVar14 = *(short *)(piVar18 + 5);
    if (sVar14 == 1) {
      iVar11 = (int)*(short *)((int)piVar18 + 0x16);
      if (iVar11 < 4) {
        *(undefined4 *)(iVar10 + 0xc0) = *(undefined4 *)(_DAT_100a0de0 + iVar11 * 4 + 4);
      }
      else if (iVar11 < 8) {
        *(undefined4 *)(iVar10 + 0xc0) = *(undefined4 *)(_DAT_100a0ddc + iVar11 * 4 + -0xc);
      }
    }
    else if (sVar14 < 1) {
      if (-1 < sVar14) {
        iVar11 = (int)*(short *)((int)piVar18 + 0x16);
        if (iVar11 < 4) {
          *(undefined4 *)(iVar10 + 0xc0) = *(undefined4 *)(_DAT_100a0dec + iVar11 * 4 + 4);
        }
        else if (iVar11 < 8) {
          *(undefined4 *)(iVar10 + 0xc0) = *(undefined4 *)(_DAT_100a0de8 + iVar11 * 4 + -0xc);
        }
        else if (iVar11 < 0xc) {
          *(undefined4 *)(iVar10 + 0xc0) = *(undefined4 *)(_DAT_100a0de4 + iVar11 * 4 + -0x1c);
        }
      }
    }
    else if (sVar14 < 3) {
      iVar11 = (int)*(short *)((int)piVar18 + 0x16);
      if (iVar11 < 4) {
        *(undefined4 *)(iVar10 + 0xc0) = *(undefined4 *)(_DAT_100a0dd8 + iVar11 * 4 + 4);
      }
      else if (iVar11 < 8) {
        *(undefined4 *)(iVar10 + 0xc0) = *(undefined4 *)(_DAT_100a0dd4 + iVar11 * 4 + -0xc);
      }
      else if (iVar11 < 0xc) {
        *(undefined4 *)(iVar10 + 0xc0) = *(undefined4 *)(_DAT_100a0dd0 + iVar11 * 4 + -0x1c);
      }
    }
    *(undefined4 *)(*piVar18 + 10) = *(undefined4 *)(param_1 + 10);
    *(int *)(*piVar18 + 0x14) = (int)*(short *)(*piVar18 + 0xc) << 8;
    *(int *)(*piVar18 + 0x14) = (int)*(short *)(*piVar18 + 10) << 8;
    *(undefined1 *)(*piVar18 + 0x17e) = *(undefined1 *)(param_1 + 0x17e);
    *(undefined4 *)(*piVar18 + 0xb8) = 0xb0001;
  }
  .debug::_StandardSpriteCleanup(param_1);
  if ((*(short *)(param_1 + 0xb0) != 4) && (*(short *)(param_1 + 0xb0) != 5)) {
    *(short *)(piVar18 + 6) = *(short *)(piVar18 + 6) + 1;
    if (0x13 < *(short *)(piVar18 + 6)) {
      *(undefined2 *)(piVar18 + 6) = 0;
    }
    *(short *)(param_1 + 10) =
         *(short *)(param_1 + 10) + *(short *)((int)piVar18 + *(short *)(piVar18 + 6) * 2 + 0x7c);
  }
  return;
}


// ==== .HitXichraSprite @ 1008fdf4 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _HitXichraSprite(int param_1,int param_2)

{
  undefined4 *puVar1;
  int iVar2;
  char cVar5;
  short sVar3;
  short sVar4;
  undefined *puVar6;
  int iVar7;
  short sStack_38;
  short sStack_36;
  
  iVar2 = _DAT_100a0320;
  puVar1 = _DAT_100a0274;
  puVar6 = *(undefined **)(param_2 + 0x4c);
  iVar7 = *(int *)(param_1 + 0x9c);
  if ((puVar6 == PTR_PTR_100a04e8) && (*(short *)(param_2 + 0xa6) == 0)) {
    sVar3 = *(short *)(param_1 + 0xb0);
    if ((sVar3 == 5) && (*(int *)(iVar7 + 0x38) < 0x1f)) {
      cVar5 = .debug::_HurtSprite(param_1,(int)*(short *)(param_2 + 0xa4),0,0xfffffc18,10,10);
      if (cVar5 != '\0') {
        iVar7 = (int)*(short *)(param_2 + 0xa4) / 100 + ((int)*(short *)(param_2 + 0xa4) >> 0x1f);
        iVar7 = iVar7 - (iVar7 >> 0x1f);
        if (iVar7 < 2) {
          iVar7 = 1;
        }
        iVar7 = (int)(short)iVar7;
        sVar3 = .debug::_FastRand(10000);
        sVar4 = .debug::_FastRand(2);
        .debug::_STPlay3DSoundPitched
                  (*(undefined4 *)(iVar2 + sVar4 * 4),1,0xab,*(undefined4 *)(param_1 + 0xe),
                   sVar3 + 78000);
        sVar3 = .debug::_FastRand(10000);
        .debug::_STPlay3DSoundPitched(*puVar1,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar3 + 78000);
        .debug::_KillPlayerShot(param_2,0,0);
        .debug::_BloodSpray(param_1,param_2,iVar7 * 0x28,iVar7 * 0x32 + 0x15e,iVar7 * 0x96,2);
        if (0 < *(short *)(param_1 + 0xa4)) {
          .debug::_STPlay3DSound(*puVar1,1,0x55,*(undefined4 *)(param_1 + 0xe));
        }
      }
    }
    else if ((((sVar3 != 4) && (sVar3 != 6)) && (sVar3 != 5)) && ((sVar3 != 7 && (sVar3 != 8)))) {
      if ((*(short *)(param_2 + 4) == 0x5a) && (*(short *)(param_1 + 0x116) < 1)) {
        .debug::_KillPlayerShot(param_2,1,1);
        *(short *)(iVar7 + 0x1c) = *(short *)(iVar7 + 0x1c) + -1;
        *(undefined2 *)(param_1 + 0xaa) = 0x1a;
        *(undefined2 *)(param_1 + 0x116) = 0x3c;
        sVar3 = .debug::_FastRand(10000);
        sVar4 = .debug::_FastRand(2);
        .debug::_STPlay3DSoundPitched
                  (*(undefined4 *)(iVar2 + sVar4 * 4),1,0x100,*(undefined4 *)(param_1 + 0xe),
                   sVar3 + 78000);
        sVar3 = .debug::_FastRand(10000);
        sVar4 = .debug::_FastRand(2);
        .debug::_STPlay3DSoundPitched
                  (*(undefined4 *)(iVar2 + sVar4 * 4),1,0x97,*(undefined4 *)(param_1 + 0xe),
                   sVar3 + 58000);
        if (*(short *)(iVar7 + 0x1a) == 2) {
          *(undefined2 *)(param_1 + 0xaa) = 5;
          *(undefined2 *)(param_1 + 0x116) = 5;
          *(undefined2 *)(param_1 + 0xb0) = 4;
          *(undefined2 *)(param_1 + 0x46) = 0;
          *(undefined4 *)(param_1 + 0x2c) = 0;
          *(undefined4 *)(param_1 + 0x24) = 0;
          *(undefined4 *)(iVar7 + 0x38) = 0;
          *(undefined4 *)(iVar7 + 0x3c) = 0;
        }
      }
      else if (*(short *)(param_2 + 0x1a2) < 1) {
        .debug::_STPlay3DSound(*_DAT_100a041c,1,0xab,*(undefined4 *)(param_2 + 0xe));
        *(int *)(param_2 + 0x24) =
             (int)(((double)CONCAT44(0x43300000,*(uint *)(param_2 + 0x24) ^ 0x80000000) -
                   dRam100a1cd0) * dRam100a1cc8);
        *(undefined2 *)(param_2 + 0x1a2) = 1;
        *(undefined1 *)(param_2 + 0x8c) = 1;
      }
    }
  }
  else if (((puVar6 == PTR_PTR_100a01f8) || (puVar6 == PTR_PTR_100a0484)) &&
          (-1 < *(int *)(param_2 + 0x160))) {
    sStack_36 = *(short *)(param_1 + 0x36) +
                (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
    sStack_38 = *(short *)(param_1 + 0x34) +
                (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
    sVar3 = .debug::_PlatformBounce(param_1,param_2,&sStack_38,0,param_1 + 0x34,0);
    if ((sVar3 == 2) && ((0 < *(int *)(param_2 + 0x2c) || (*(char *)(param_1 + 0xce) != '\0')))) {
      .debug::_HurtSprite(param_1,100,(int)(short)(*(int *)(param_2 + 0x24) >> 1),0xfffffc18,2,8);
      *(undefined4 *)(param_1 + 0xf0) = 0;
      .debug::_KillBox(param_2);
      sVar3 = .debug::_FastRand(10000);
      .debug::_STPlay3DSoundPitched(*puVar1,1,0x100,*(undefined4 *)(param_1 + 0xe),sVar3 + 42000);
      sVar3 = .debug::_FastRand(10000);
      sVar4 = .debug::_FastRand(2);
      .debug::_STPlay3DSoundPitched
                (*(undefined4 *)(iVar2 + sVar4 * 4),1,0x100,*(undefined4 *)(param_1 + 0xe),
                 sVar3 + 42000);
    }
  }
  return;
}


// ==== .KillXichra @ 100902a4 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _KillXichra(int param_1)

{
  undefined4 *puVar1;
  short *psVar2;
  undefined1 *puVar3;
  undefined2 *puVar4;
  int iVar5;
  
  iVar5 = _DAT_1009ffc0;
  psVar2 = _DAT_1009feac;
  if ((*(char *)(param_1 + 0xe9) == '\0') && (*(char *)(param_1 + 0x1b5) != '\0')) {
    *_DAT_1009ffb4 = *_DAT_1009ffb4 + -1;
    iVar5 = iVar5 + *psVar2 * 2;
    *(short *)(iVar5 + 0x306) = *(short *)(iVar5 + 0x306) + 1;
  }
  puVar1 = _DAT_1009fd68;
  *(undefined1 *)(param_1 + 0xe9) = 1;
  *(undefined1 *)(param_1 + 0xea) = 1;
  .debug::_STPlay3DSoundPitched(*puVar1,1,0x100,*(undefined4 *)(param_1 + 0xe),48000);
  puVar4 = _DAT_100a00fc;
  *_DAT_1009ffa0 = 0x1e;
  puVar3 = _DAT_1009fed0;
  *puVar4 = 3;
  *puVar3 = 1;
  return;
}


// ==== .HitXichraTileSprite @ 10090384 ====

void _HitXichraTileSprite(int param_1,undefined4 param_2,undefined4 param_3,short param_4)

{
  short sStack_46;
  short sStack_44;
  undefined1 auStack_26 [26];
  
  sStack_44 = *(short *)(param_1 + 0x36) +
              (short)((int)*(short *)(param_1 + 0x3a) - (int)*(short *)(param_1 + 0x36) >> 1);
  sStack_46 = *(short *)(param_1 + 0x34) +
              (short)((int)*(short *)(param_1 + 0x38) - (int)*(short *)(param_1 + 0x34) >> 1);
  .glue::SetRect(auStack_26,(int)*(short *)(param_1 + 0x36),(int)*(short *)(param_1 + 0x34),
                 (int)*(short *)(param_1 + 0x3a),(int)*(short *)(param_1 + 0x38));
  if (param_4 == 1) {
    .debug::_WallBounce(param_1,param_3,&stack0x0000001c,&sStack_46,0,param_1 + 0x34,0,0);
  }
  return;
}


// ==== .MyDMIterator @ 100987ac ====

void _MyDMIterator(int param_1,int param_2,int param_3)

{
  uint uVar1;
  undefined4 uVar2;
  undefined4 *puVar3;
  int iVar4;
  int iVar5;
  uint uVar6;
  undefined1 auStack_128 [268];
  
  iVar5 = *(int *)(param_1 + 0x4c) + param_2 * 0x50;
  uVar1 = *(uint *)(*(int *)(param_3 + 0xc) + 0x10);
  .debug::_P2CStringCopy(auStack_128,*(undefined4 *)(param_3 + 0x18));
  .debug::_StringCopySafe(iVar5,auStack_128,0x20);
  *(undefined4 *)(iVar5 + 0x20) = *(undefined4 *)(*(int *)(param_3 + 8) + 8);
  *(undefined4 *)(iVar5 + 0x24) = *(undefined4 *)(*(int *)(param_3 + 8) + 0xc);
  uVar2 = .glue::Fix2Long(*(undefined4 *)(*(int *)(param_3 + 8) + 0x10));
  *(undefined4 *)(iVar5 + 0x28) = uVar2;
  *(undefined4 *)(iVar5 + 0x30) = 0x20;
  *(undefined4 *)(iVar5 + 0x34) = 1;
  *(bool *)(iVar5 + 0x38) = (uVar1 & 2) == 0;
  puVar3 = *(undefined4 **)(param_3 + 4);
  uVar2 = puVar3[1];
  *(undefined4 *)(iVar5 + 0x3a) = *puVar3;
  *(undefined4 *)(iVar5 + 0x3e) = uVar2;
  uVar2 = puVar3[3];
  *(undefined4 *)(iVar5 + 0x42) = puVar3[2];
  *(undefined4 *)(iVar5 + 0x46) = uVar2;
  *(undefined4 *)(iVar5 + 0x4c) = *(undefined4 *)(*(int *)(param_3 + 4) + 2);
  *(undefined4 *)(iVar5 + 0x30) = 0x20;
  *(undefined4 *)(iVar5 + 0x34) = 1;
  uVar1 = **(uint **)(param_3 + 0x10);
  iVar4 = *(int *)(*(int *)(*(int *)(param_3 + 0x10) + 4) + 4);
  for (uVar6 = 0; uVar6 < uVar1; uVar6 = uVar6 + 1) {
    *(uint *)(iVar5 + 0x2c) = *(uint *)(iVar5 + 0x2c) | (int)*(short *)(iVar4 + uVar6 * 0x2a + 0x20)
    ;
    if ((uint)(int)*(short *)(iVar4 + uVar6 * 0x2a + 0x20) < *(uint *)(iVar5 + 0x30)) {
      *(int *)(iVar5 + 0x30) = (int)*(short *)(iVar4 + uVar6 * 0x2a + 0x20);
    }
    if (*(uint *)(iVar5 + 0x34) < (uint)(int)*(short *)(iVar4 + uVar6 * 0x2a + 0x20)) {
      *(int *)(iVar5 + 0x34) = (int)*(short *)(iVar4 + uVar6 * 0x2a + 0x20);
    }
  }
  return;
}


// ==== ._MacOSE2SHook @ 1009b7c4 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __MacOSE2SHook(void)

{
  undefined *puVar1;
  undefined4 uVar2;
  
  puVar1 = PTR_DAT_100a1458;
  uVar2 = .glue::SetCurrentA5();
  if (cRam100a20a4 == '\0') {
    cRam100a20a4 = 1;
    *_DAT_100a0e68 = 0;
    while (_DAT_100a20ac != 0) {
      _DAT_100a20ac = _DAT_100a20ac + -1;
      if (*(int *)(puVar1 + _DAT_100a20ac * 4) != 0) {
        FUN_1009f80c();
      }
    }
    .debug::__MacOSE2SRemove();
    cRam100a20a4 = '\0';
  }
  .glue::SetA5(uVar2);
  return;
}


// ==== .ThreadsPostflight @ 1009c1ac ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _ThreadsPostflight(void)

{
  undefined *puVar1;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  char cVar6;
  int iVar5;
  
  uVar4 = _DAT_100a1520;
  uVar3 = _DAT_100a151c;
  uVar2 = _DAT_100a1518;
  puVar1 = PTR_DAT_100a0e9c;
  cVar6 = .debug::_AtomicMaskClear(PTR_DAT_100a0e9c,1);
  if ((cVar6 != '\0') && (cVar6 = .debug::_AtomicMaskApply(puVar1,2), cVar6 == '\0')) {
    .debug::__ThreadEnterCritical();
    .glue::RmvTime(_DAT_100a150c);
    .debug::_AtomicMaskClear(puVar1,0x1c);
    .debug::_MemoryClear(_DAT_100a150c,0x1c);
    .debug::_MemoryClear(_DAT_100a1508,0x14);
    while (iVar5 = .debug::_QueueRemove(uVar3), iVar5 != 0) {
      .debug::_ThreadDispose(*(undefined4 *)(iVar5 + 0x20));
    }
    while (iVar5 = .debug::_QueueRemove(uVar2), iVar5 != 0) {
      .debug::_ThreadDispose(*(undefined4 *)(iVar5 + 0x20));
    }
    while (iVar5 = .debug::_QueueRemove(uVar4), iVar5 != 0) {
      .debug::__ThreadDispose(iVar5);
    }
    while (iRam100a2150 != 0) {
      .debug::_MutexDispose(iRam100a2150);
    }
    .debug::_QueueDispose(uVar4);
    .debug::_QueueDispose(uVar3);
    .debug::_QueueDispose(uVar2);
    .debug::_QueueDispose(_DAT_100a1514);
    _DAT_100a2154 = 0;
    if (_DAT_100a2158 != 0) {
      .debug::_MemoryDeallocate(_DAT_100a2158);
      _DAT_100a2158 = 0;
    }
    .debug::__ThreadLeaveCritical();
    .debug::_AtomicMaskClear(puVar1,2);
  }
  return;
}


// ==== ._ThreadTimer @ 1009d830 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __ThreadTimer(void)

{
  .glue::DTInstall(_DAT_100a1508);
  return;
}


// ==== ._ThreadDefer @ 1009d880 ====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __ThreadDefer(void)

{
  undefined4 uVar1;
  undefined *puVar2;
  char cVar4;
  undefined4 uVar3;
  undefined4 uVar5;
  undefined4 in_r9;
  undefined4 in_r10;
  
  uVar3 = _DAT_100a1514;
  if (_DAT_100a2160 != (undefined *)0x0) {
    .debug::_Debug(s_Unexpected_operation_or_state_100a7858,0xffffe4a6,s_threads_c_100a7876,
                   &DAT_100a79a4,0,1,in_r9,in_r10,0);
  }
  .debug::_QueueTransfer(uVar3,_DAT_100a1518);
  uVar5 = 0x1e;
  cVar4 = .debug::_AtomicMaskTest(PTR_DAT_100a0e9c);
  if (cVar4 == '\0') {
    cVar4 = .debug::_QueueIsEmpty(uVar3);
    if (cVar4 == '\0') {
      .debug::_SLEnterInterrupt();
      uVar1 = uRam00000110;
      uRam00000110 = 0;
      _DAT_100a215c = .debug::_QueueGetCount(uVar3);
      if (0x14 < _DAT_100a215c) {
        _DAT_100a215c = 0x14;
      }
      uVar3 = .debug::_TimerGetMicroseconds();
      puVar2 = PTR_DAT_100a149c;
      *(undefined4 *)(PTR_DAT_100a149c + 4) = uVar5;
      *(undefined4 *)puVar2 = uVar3;
      puVar2 = PTR_DAT_100a14a0;
      *(undefined4 *)(PTR_DAT_100a14a0 + 4) = uVar5;
      *(undefined4 *)puVar2 = uVar3;
      _DAT_100a2160 = PTR_DAT_100a1524;
      .debug::_ThreadYield();
      puVar2 = PTR_DAT_100a14a0;
      _DAT_100a2160 = (undefined *)0x0;
      _DAT_100a215c = 0;
      *(undefined4 *)(PTR_DAT_100a14a0 + 4) = 0;
      *(undefined4 *)puVar2 = 0;
      puVar2 = PTR_DAT_100a149c;
      *(undefined4 *)(PTR_DAT_100a149c + 4) = 0;
      *(undefined4 *)puVar2 = 0;
      uRam00000110 = uVar1;
      .debug::_SLLeaveInterrupt();
    }
  }
  cVar4 = .debug::_AtomicMaskTest(PTR_DAT_100a0e9c,0x1e);
  if (cVar4 == '\0') {
    uVar3 = 10;
  }
  else {
    uVar3 = 3;
  }
  .glue::PrimeTime(_DAT_100a150c,uVar3);
  return;
}

