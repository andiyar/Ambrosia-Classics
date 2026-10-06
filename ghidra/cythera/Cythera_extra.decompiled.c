// CyDecompAt of Cythera_pef (37 addresses)

// ==== .ReadData__7TStreamFPce @ 10017990 ====
// CyDecompAt: created, body 10017990-10017ccf

undefined4 _ReadData__7TStreamFPce(undefined4 param_1,char *param_2)

{
  int *piVar1;
  char cVar2;
  int iVar3;
  char *pcVar4;
  undefined4 *puVar5;
  int *piVar6;
  undefined4 uVar7;
  int iStack_38;
  char acStack_34 [4];
  
  uVar7 = 0;
  piVar6 = (int *)&stack0x00000020;
  do {
    if (*param_2 == '\0') {
      return uVar7;
    }
    cVar2 = *param_2;
    if (cVar2 == 'a') {
      iVar3 = *piVar6;
      piVar1 = piVar6 + 1;
      piVar6 = piVar6 + 2;
      uVar7 = FUN_100c50e8(param_1,*piVar1,iVar3);
    }
    else if (cVar2 < 'a') {
      if (cVar2 == 'H') {
        puVar5 = (undefined4 *)*piVar6;
        piVar6 = piVar6 + 1;
        uVar7 = FUN_100c50e8(param_1,&iStack_38,4);
        if (((short)uVar7 == 0) && (iStack_38 != -1)) {
          uVar7 = .glue::NewHandle(iStack_38);
          *puVar5 = uVar7;
          .glue::HLock(*puVar5);
          uVar7 = FUN_100c50e8(param_1,*(undefined4 *)*puVar5,iStack_38);
          .glue::HUnlock(*puVar5);
        }
        else {
          *puVar5 = 0;
        }
      }
      else if (cVar2 < 'H') {
        if (cVar2 == ';') {
          FUN_100c50e8(param_1,4);
        }
        else if ((cVar2 < ';') && (cVar2 == ' ')) {
          FUN_100c50e8(param_1,2);
        }
      }
      else if (cVar2 == 'P') {
        pcVar4 = (char *)*piVar6;
        piVar6 = piVar6 + 1;
        uVar7 = FUN_100c50e8(param_1,pcVar4,1);
        if (((short)uVar7 == 0) && (*pcVar4 != '\0')) {
          uVar7 = FUN_100c50e8(param_1,pcVar4 + 1,*pcVar4);
        }
      }
    }
    else if (cVar2 == 'l') {
      iVar3 = *piVar6;
      piVar6 = piVar6 + 1;
      uVar7 = FUN_100c50e8(param_1,iVar3,4);
    }
    else if (cVar2 < 'l') {
      if (cVar2 == 'h') {
        iVar3 = *piVar6;
        piVar6 = piVar6 + 1;
        uVar7 = FUN_100c50e8(param_1,iVar3,2);
      }
      else if (cVar2 < 'h') {
        if (cVar2 < 'c') {
          iVar3 = *piVar6;
          piVar6 = piVar6 + 1;
          uVar7 = FUN_100c50e8(param_1,iVar3,1);
        }
      }
      else if (cVar2 < 'j') {
        iVar3 = *piVar6;
        piVar6 = piVar6 + 1;
        uVar7 = FUN_100c50e8(param_1,iVar3,4);
      }
    }
    else if (cVar2 == 's') {
      pcVar4 = (char *)*piVar6;
      piVar6 = piVar6 + 1;
      do {
        if ((short)uVar7 != 0) break;
        uVar7 = FUN_100c50e8(param_1,acStack_34,1);
        *pcVar4 = acStack_34[0];
        pcVar4 = pcVar4 + 1;
      } while (acStack_34[0] != '\0');
    }
    param_2 = param_2 + 1;
    if ((short)uVar7 != 0) {
      return uVar7;
    }
  } while( true );
}


// ==== .WriteData__7TStreamFPce @ 10017cfc ====
// CyDecompAt: created, body 10017cfc-1001804f

undefined4 _WriteData__7TStreamFPce(undefined4 param_1,char *param_2)

{
  int iVar1;
  char cVar2;
  byte *pbVar3;
  undefined4 *puVar4;
  undefined4 *puVar5;
  undefined4 uVar6;
  undefined4 uStack_48;
  undefined4 uStack_44;
  undefined4 uStack_40;
  undefined2 uStack_3c;
  undefined1 auStack_3a [2];
  undefined4 auStack_38 [5];
  
  uVar6 = 0;
  puVar5 = (undefined4 *)&stack0x00000020;
  do {
    if (*param_2 == '\0') {
      return uVar6;
    }
    cVar2 = *param_2;
    if (cVar2 == 'a') {
      uVar6 = *puVar5;
      puVar4 = puVar5 + 1;
      puVar5 = puVar5 + 2;
      uVar6 = FUN_100c50e8(param_1,*puVar4,uVar6);
    }
    else if (cVar2 < 'a') {
      if (cVar2 == 'H') {
        puVar4 = (undefined4 *)*puVar5;
        puVar5 = puVar5 + 1;
        if (puVar4 == (undefined4 *)0x0) {
          uStack_44 = 0xffffffff;
          uVar6 = FUN_100c50e8(param_1,&uStack_44,4);
        }
        else {
          uStack_48 = .glue::GetHandleSize(puVar4);
          uVar6 = FUN_100c50e8(param_1,&uStack_48,4);
          if ((short)uVar6 == 0) {
            cVar2 = .glue::HGetState(puVar4);
            .glue::HLock(puVar4);
            uVar6 = FUN_100c50e8(param_1,*puVar4,uStack_48);
            .glue::HSetState(puVar4,(int)cVar2);
          }
        }
      }
      else if (cVar2 < 'H') {
        if (cVar2 == ';') {
          FUN_100c50e8(param_1,4);
        }
        else if ((cVar2 < ';') && (cVar2 == ' ')) {
          FUN_100c50e8(param_1,2);
        }
      }
      else if (cVar2 == 'P') {
        pbVar3 = (byte *)*puVar5;
        puVar5 = puVar5 + 1;
        uVar6 = FUN_100c50e8(param_1,pbVar3,*pbVar3 + 1);
      }
    }
    else if (cVar2 == 'l') {
      uStack_40 = *puVar5;
      puVar5 = puVar5 + 1;
      uVar6 = FUN_100c50e8(param_1,&uStack_40,4);
    }
    else if (cVar2 < 'l') {
      if (cVar2 == 'h') {
        uStack_3c = (undefined2)*puVar5;
        puVar5 = puVar5 + 1;
        uVar6 = FUN_100c50e8(param_1,&uStack_3c,2);
      }
      else if (cVar2 < 'h') {
        if (cVar2 < 'c') {
          auStack_3a[0] = (undefined1)*puVar5;
          puVar5 = puVar5 + 1;
          uVar6 = FUN_100c50e8(param_1,auStack_3a,1);
        }
      }
      else if (cVar2 < 'j') {
        auStack_38[0] = *puVar5;
        puVar5 = puVar5 + 1;
        uVar6 = FUN_100c50e8(param_1,auStack_38,4);
      }
    }
    else if (cVar2 == 's') {
      uVar6 = *puVar5;
      puVar5 = puVar5 + 1;
      iVar1 = FUN_100b6ce8(uVar6);
      uVar6 = FUN_100c50e8(param_1,uVar6,iVar1 + 1);
    }
    param_2 = param_2 + 1;
  } while ((short)uVar6 == 0);
  return uVar6;
}


// ==== .Align__7TStreamFs @ 1001807c ====
// CyDecompAt: created, body 1001807c-10018083

undefined4 _Align__7TStreamFs(void)

{
  return 0;
}


// ==== .IsEOF__7TStreamFv @ 100180a8 ====
// CyDecompAt: created, body 100180a8-1001810f

int _IsEOF__7TStreamFv(undefined4 param_1)

{
  uint uVar1;
  uint uVar2;
  
  uVar1 = FUN_100c50e8();
  uVar2 = FUN_100c50e8(param_1);
  return (((int)uVar2 >> 0x1f) - ((int)uVar1 >> 0x1f)) + (uint)(uVar1 <= uVar2);
}


// ==== .BeginChunk__7TStreamFUl @ 10018134 ====
// CyDecompAt: created, body 10018134-100181b3

void _BeginChunk__7TStreamFUl(int param_1)

{
  undefined4 uVar1;
  undefined4 auStack_18 [5];
  
  FUN_100c50e8(param_1,&stack0x0000001c,4);
  uVar1 = FUN_100c50e8(param_1);
  *(undefined4 *)(param_1 + 4) = uVar1;
  auStack_18[0] = 0;
  FUN_100c50e8(param_1,auStack_18,4);
  return;
}


// ==== .EndChunk__7TStreamFv @ 100181e0 ====
// CyDecompAt: created, body 100181e0-1001827b

void _EndChunk__7TStreamFv(int param_1)

{
  int iVar1;
  int aiStack_18 [4];
  
  iVar1 = FUN_100c50e8();
  aiStack_18[0] = iVar1 - *(int *)(param_1 + 4);
  FUN_100c50e8(param_1,*(undefined4 *)(param_1 + 4));
  FUN_100c50e8(param_1,aiStack_18,4);
  FUN_100c50e8(param_1,iVar1);
  return;
}


// ==== .ReadChunk__7TStreamFUl @ 100182a4 ====
// CyDecompAt: created, body 100182a4-1001834f

undefined4 _ReadChunk__7TStreamFUl(int param_1,int param_2)

{
  undefined4 uVar1;
  int iVar2;
  int aiStack_18 [5];
  
  FUN_100c50e8(param_1,aiStack_18,4);
  if (aiStack_18[0] == param_2) {
    FUN_100c50e8(param_1,param_1 + 4,4);
    iVar2 = FUN_100c50e8(param_1);
    uVar1 = 0;
    *(int *)(param_1 + 4) = iVar2 + *(int *)(param_1 + 4) + -4;
  }
  else {
    *(undefined4 *)(param_1 + 4) = 0xffffffff;
    uVar1 = 0xffffffd5;
  }
  return uVar1;
}


// ==== .IsEOChunk__7TStreamFv @ 1001837c ====
// CyDecompAt: created, body 1001837c-100183c7

int _IsEOChunk__7TStreamFv(int param_1)

{
  uint uVar1;
  
  uVar1 = FUN_100c50e8();
  return (((int)uVar1 >> 0x1f) - ((int)*(uint *)(param_1 + 4) >> 0x1f)) +
         (uint)(*(uint *)(param_1 + 4) <= uVar1);
}


// ==== .KeyRoutine__10TMapWindowFs @ 100437b8 ====
// CyDecompAt: created, body 100437b8-100446c7

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void _KeyRoutine__10TMapWindowFs(int param_1,uint param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  undefined *puVar3;
  undefined *puVar4;
  undefined *puVar5;
  undefined *puVar6;
  undefined *puVar7;
  undefined *puVar8;
  undefined *puVar9;
  char cVar14;
  short sVar13;
  undefined4 uVar10;
  undefined4 uVar11;
  int iVar12;
  undefined4 uVar15;
  short sVar16;
  undefined4 *puVar17;
  uint *puVar18;
  undefined4 uStack_8e;
  undefined4 uStack_8a;
  undefined4 uStack_84;
  ushort uStack_80;
  ushort uStack_7e;
  undefined4 uStack_7c;
  undefined4 uStack_78;
  undefined4 uStack_74;
  ushort uStack_70;
  ushort uStack_6e;
  ushort uStack_6c;
  ushort uStack_6a;
  short sStack_68;
  short sStack_66;
  short sStack_64;
  short sStack_62;
  char acStack_60 [2];
  short sStack_5e;
  char acStack_5c [2];
  short sStack_5a;
  undefined1 auStack_58 [6];
  undefined1 auStack_52 [6];
  undefined1 auStack_4c [2];
  undefined1 auStack_4a [2];
  undefined1 auStack_48 [2];
  short asStack_46 [3];
  
  puVar9 = PTR_DAT_100ce864;
  puVar8 = PTR_DAT_100ce860;
  puVar7 = PTR_DAT_100cde50;
  puVar6 = PTR_DAT_100cdd08;
  puVar5 = PTR_DAT_100cdbf0;
  puVar4 = PTR_DAT_100cdbec;
  puVar3 = PTR_DAT_100cdbb8;
  puVar2 = PTR_DAT_100cdb98;
  puVar1 = PTR_DAT_100cdb84;
  if (*PTR_DAT_100ce864 == '\0') {
    *(undefined4 *)PTR_DAT_100ce860 = 0;
    *puVar9 = 1;
  }
  *(uint *)puVar8 = *(int *)puVar8 << 8 | param_2 & 0xff;
  if ((*(int *)puVar8 == -0x56988d9f) && ((bRam100d3e23 & 1) != 0)) {
    *puVar7 = *puVar7 == '\0';
    *(undefined4 *)puVar8 = 0;
    if (*puVar7 == '\0') {
      .debug::_myprintf__13TStatusWindowFPce
                (*(undefined4 *)puVar2,PTR_s_Cheat_mode_deactivated__100ce858);
    }
    else {
      .debug::_myprintf__13TStatusWindowFPce
                (*(undefined4 *)puVar2,PTR_s_Cheat_mode_activated__100ce85c);
    }
  }
  sVar16 = (short)param_2;
  if ((*(short *)PTR_DAT_100cdd0c == 0) &&
     (cVar14 = FUN_100bf4fc(*(undefined4 *)puVar6), cVar14 != '\0')) {
    FUN_100bf8b0(*(undefined4 *)puVar6,asStack_46,auStack_48,auStack_4a,auStack_4c,auStack_52,
                 auStack_58);
    if ((*(int *)puVar8 == 0x706c6179) ||
       ((sVar16 == 0x110 && ((*(ushort *)(*(int *)puVar1 + 0x12) & 0x200) != 0)))) {
      FUN_100bfcf0(*(undefined4 *)puVar6,1);
    }
    else if ((*(int *)puVar8 == 0x73746f70) ||
            ((sVar16 == 0x113 && ((*(ushort *)(*(int *)puVar1 + 0x12) & 0x200) != 0)))) {
      FUN_100bfff0(*(undefined4 *)puVar6);
    }
    else if ((*(int *)puVar8 == 0x70617573) ||
            ((sVar16 == 0x10e && ((*(ushort *)(*(int *)puVar1 + 0x12) & 0x200) != 0)))) {
      FUN_100bff28(*(undefined4 *)puVar6,asStack_46[0] != 2);
    }
    else if ((*(int *)puVar8 == 0x6e657874) ||
            ((sVar16 == 0x111 && ((*(ushort *)(*(int *)puVar1 + 0x12) & 0x200) != 0)))) {
      FUN_100bfd88(*(undefined4 *)puVar6,1);
    }
    else if ((*(int *)puVar8 == 0x70726576) ||
            ((sVar16 == 0x114 && ((*(ushort *)(*(int *)puVar1 + 0x12) & 0x200) != 0)))) {
      FUN_100bfd88(*(undefined4 *)puVar6,0);
    }
    else if ((*(int *)puVar8 == 0x656a6563) ||
            ((sVar16 == 0x112 && ((*(ushort *)(*(int *)puVar1 + 0x12) & 0x200) != 0)))) {
      FUN_100bf768(*(undefined4 *)puVar6);
    }
    else if (sVar16 == 0x7b) {
      sVar13 = FUN_100bf52c(*(undefined4 *)puVar6,&sStack_5a,acStack_5c);
      if ((sVar13 == 0) && (acStack_5c[0] != '\0')) {
        sStack_5a = sStack_5a + -10;
        if (sStack_5a < 0) {
          sStack_5a = 0;
        }
        FUN_100bf61c(*(undefined4 *)puVar6,(int)sStack_5a);
      }
    }
    else if (((sVar16 == 0x7d) &&
             (sVar13 = FUN_100bf52c(*(undefined4 *)puVar6,&sStack_5e,acStack_60), sVar13 == 0)) &&
            (acStack_60[0] != '\0')) {
      sStack_5e = sStack_5e + 10;
      if (0xff < sStack_5e) {
        sStack_5e = 0xff;
      }
      FUN_100bf61c(*(undefined4 *)puVar6,(int)sStack_5e);
    }
  }
  puVar8 = PTR_DAT_100ce818;
  puVar6 = PTR_DAT_100cdd04;
  if (*PTR_DAT_100cdd00 != '\0') {
    FUN_100c50e8(*_DAT_100cde3c,param_2);
    return;
  }
  if (sVar16 == 0xbd) {
    if (*puVar7 == '\0') {
      return;
    }
    uVar15 = *(undefined4 *)(param_1 + 4);
    .glue::GetPort(&uStack_74);
    .glue::SetPort(uVar15);
    uStack_7c = *(undefined4 *)(PTR_DAT_100cdc48 + 6);
    uStack_78 = *(undefined4 *)(PTR_DAT_100cdc48 + 10);
    uStack_7e = (ushort)(*(uint *)(puVar5 + *(short *)puVar4 * 0x20) >> 0xc) & 0xfff;
    uStack_80 = (ushort)*(undefined4 *)(puVar5 + *(short *)puVar4 * 0x20) & 0xfff;
    .glue::OffsetRect(&uStack_7c,0xa0 - (short)uStack_7e,0xa0 - (short)uStack_80);
    .glue::CopyBits(PTR_DAT_100cdc48,*(int *)(param_1 + 4) + 2,PTR_DAT_100cdc48 + 6,&uStack_7c,0,0);
    do {
      cVar14 = .glue::Button();
    } while (cVar14 == '\0');
    .glue::SetPort(uStack_74);
    return;
  }
  if (sVar16 < 0xbd) {
    if (sVar16 == 0xa0) {
      if (*puVar7 == '\0') {
        return;
      }
      .debug::_DoTicks__11TGameViewerFlUc(*(undefined4 *)puVar3,0x400,0);
      .debug::_DrawRoutine__11TGameViewerFs(*(undefined4 *)puVar3,1);
      return;
    }
    if (sVar16 < 0xa0) {
      if (sVar16 != 0x3d) {
        if (sVar16 < 0x3d) {
          if (sVar16 < 0x39) {
            if (0x30 < sVar16) {
              sVar16 = sVar16 + -0x31;
              if (*(short *)PTR_DAT_100cdb9c <= sVar16) {
                return;
              }
              iVar12 = .debug::_FindInventory__16TInventoryWindowFs
                                 ((int)*(short *)(PTR_DAT_100cdbe4 + sVar16 * 2));
              if (iVar12 != 0) {
                FUN_100c50e8();
                return;
              }
              iVar12 = FUN_100be7c8(0x88);
              if (iVar12 == 0) {
                return;
              }
              .debug::___ct__16TCharacterWindowFs
                        (iVar12,(int)*(short *)(PTR_DAT_100cdbe4 + sVar16 * 2));
              return;
            }
          }
          else if (0x3b < sVar16) {
            if (*puVar7 == '\0') {
              return;
            }
            .debug::_DarkenLight__11TGameViewerFv(*(undefined4 *)puVar3);
            return;
          }
        }
        else {
          if (sVar16 == 0x5a) {
            .debug::_PrintZStats__Fv();
            return;
          }
          if ((sVar16 < 0x5a) && (sVar16 < 0x3f)) {
            if (*puVar7 == '\0') {
              return;
            }
            .debug::_BrightenLight__11TGameViewerFv(*(undefined4 *)puVar3);
            return;
          }
        }
      }
    }
    else if (sVar16 != 0xb6) {
      if (sVar16 < 0xb6) {
        if (sVar16 == 0xa8) {
LAB_10044490:
          if (*puVar7 == '\0') {
            return;
          }
          cVar14 = (char)-(*(ushort *)(puVar5 + *(short *)puVar4 * 0x20 + 6) & 0x10);
          if (cVar14 != (char)(cVar14 + -1 +
                              (-(*(ushort *)(puVar5 + *(short *)puVar4 * 0x20 + 6) & 0x10) == 0))) {
            .debug::_RemoveAbility__8TSpellFXFss((int)*(short *)puVar4,0xc);
            return;
          }
          .debug::_AddAbility__8TSpellFXFss((int)*(short *)puVar4,0xc);
          return;
        }
        if (sVar16 < 0xa8) {
          if (0xa6 < sVar16) {
            if (*puVar7 == '\0') {
              return;
            }
            .debug::_myprintf__13TStatusWindowFPce
                      (*(undefined4 *)puVar2,PTR_s_Spam_create_obj__100ce83c);
            sStack_64 = .debug::_mygetnum__13TStatusWindowFs(*(undefined4 *)puVar2,0x10);
            .debug::_myprintf__13TStatusWindowFPce
                      (*(undefined4 *)puVar2,PTR_DAT_100ce84c,(int)sStack_64);
            .debug::_myprintf__13TStatusWindowFPce(*(undefined4 *)puVar2,PTR_s_Data1__100ce838);
            sStack_66 = .debug::_mygetnum__13TStatusWindowFs(*(undefined4 *)puVar2,10);
            .debug::_myprintf__13TStatusWindowFPce
                      (*(undefined4 *)puVar2,PTR_DAT_100ce834,(int)sStack_66);
            .debug::_myprintf__13TStatusWindowFPce(*(undefined4 *)puVar2,PTR_s_Data2__100ce830);
            sStack_68 = .debug::_mygetnum__13TStatusWindowFs(*(undefined4 *)puVar2,0x10);
            .debug::_myprintf__13TStatusWindowFPce
                      (*(undefined4 *)puVar2,PTR_DAT_100ce834,(int)sStack_68);
            sVar16 = .debug::_NewProp__Fv();
            puVar18 = (uint *)(*(int *)PTR_DAT_100cdc44 + sVar16 * 0x10);
            *(undefined1 *)puVar18 = 0x10;
            *puVar18 = *puVar18 & 0xff0000 | 1 | *puVar18 & 0xff000000;
            *(char *)((int)puVar18 + 6) = (char)sStack_66;
            *(char *)((int)puVar18 + 7) = (char)sStack_68;
            *(short *)(puVar18 + 1) = sStack_64;
            .debug::_Invalidate__16TInventoryWindowFss(1,2);
            return;
          }
        }
        else if (0xb4 < sVar16) {
          if (*puVar7 == '\0') {
            return;
          }
          uVar15 = *(undefined4 *)(param_1 + 4);
          .glue::GetPort(&uStack_84);
          .glue::SetPort(uVar15);
          uStack_8e = *(undefined4 *)(PTR_DAT_100cdc4c + 6);
          uStack_8a = *(undefined4 *)(PTR_DAT_100cdc4c + 10);
          .glue::OffsetRect(&uStack_8e,
                            0xa0 - (short)((ushort)(*(uint *)(puVar5 + *(short *)puVar4 * 0x20) >>
                                                   0xc) & 0xfff),
                            0xa0 - (short)((ushort)*(undefined4 *)(puVar5 + *(short *)puVar4 * 0x20)
                                          & 0xfff));
          .glue::CopyBits(PTR_DAT_100cdc4c,*(int *)(param_1 + 4) + 2,PTR_DAT_100cdc4c + 6,&uStack_8e
                          ,0,0);
          do {
            cVar14 = .glue::Button();
          } while (cVar14 == '\0');
          .glue::SetPort(uStack_84);
          return;
        }
      }
      else {
        if (sVar16 == 0xb9) {
          if (*puVar7 != '\0') {
            .debug::_myprintf__13TStatusWindowFPce
                      (*(undefined4 *)puVar2,PTR_s_What_prop____0__x___100ce824,
                       (int)*(short *)PTR_DAT_100cdc3c);
            sVar16 = .debug::_mygetnum__13TStatusWindowFs(*(undefined4 *)puVar2,0x10);
            puVar17 = (undefined4 *)(*(int *)PTR_DAT_100cdc44 + sVar16 * 0x10);
            .debug::_myprintf__13TStatusWindowFPce
                      (*(undefined4 *)puVar2,PTR_s___d_____2x__d___3x_100ce820,(int)sVar16,
                       *(undefined1 *)puVar17,*(byte *)(puVar17 + 1) >> 2 & 0x1f,
                       *(ushort *)(puVar17 + 1) & 0x3ff);
            .debug::_myprintf__13TStatusWindowFPce
                      (*(undefined4 *)puVar2,PTR_s____3x___3x______3d___3d__100ce81c,
                       (int)(short)((short)((uint)*puVar17 >> 8) >> 4),
                       (int)((short)((ushort)((uint)((int)*(short *)((int)puVar17 + 2) << 0x14) >>
                                             0x10) |
                                    (ushort)(*(short *)((int)puVar17 + 2) >> 0xf) >> 0xc) >> 4),
                       *(undefined1 *)((int)puVar17 + 6),*(undefined1 *)((int)puVar17 + 7));
          }
          goto LAB_10044490;
        }
        if ((sVar16 < 0xb9) && (sVar16 < 0xb8)) {
          if (*puVar7 == '\0') {
            return;
          }
          *(bool *)(*(int *)puVar3 + 0x20c26) = *(char *)(*(int *)puVar3 + 0x20c26) == '\0';
          return;
        }
      }
    }
  }
  else {
    if (sVar16 == 0xca) {
      *PTR_DAT_100cdd04 = *PTR_DAT_100cdd04 == '\0';
      if (*puVar6 != '\0') {
        .debug::_myprintf__13TStatusWindowFPce
                  (*(undefined4 *)puVar2,PTR_s_Disabling_turn_based_movement__100ce810);
        return;
      }
      .debug::_myprintf__13TStatusWindowFPce
                (*(undefined4 *)puVar2,PTR_s_Enabling_turn_based_movement__100ce80c);
      return;
    }
    if (sVar16 < 0xca) {
      if (sVar16 == 0xc3) {
        if (*puVar7 == '\0') {
          return;
        }
        uStack_6e = (ushort)(*(uint *)(puVar5 + *(short *)puVar4 * 0x20) >> 0xc) & 0xfff;
        uStack_70 = (ushort)*(undefined4 *)(puVar5 + *(short *)puVar4 * 0x20) & 0xfff;
        .debug::_MakeZone__11TGameViewerFss(*(undefined4 *)puVar3,uStack_6e,uStack_70);
        .debug::_MagicMap__11TGameViewerFsss
                  (*(undefined4 *)puVar3,(int)(short)uStack_6e,(int)(short)uStack_70,2);
        do {
          cVar14 = .glue::Button();
        } while (cVar14 == '\0');
        return;
      }
      if (sVar16 < 0xc3) {
        if (sVar16 != 0xc1) {
          if (0xc0 < sVar16) {
            if (*PTR_DAT_100ce818 == '\0') {
              *PTR_DAT_100ce814 = 0;
              *puVar8 = 1;
            }
            if (*PTR_DAT_100ce814 == '\0') {
              .debug::_SLDisable();
            }
            else {
              .debug::_SLEnable();
            }
            *PTR_DAT_100ce814 = *PTR_DAT_100ce814 == '\0';
            return;
          }
          if (0xbf < sVar16) {
            if (*puVar7 == '\0') {
              return;
            }
            uStack_6a = (ushort)(*(uint *)(puVar5 + *(short *)puVar4 * 0x20) >> 0xc) & 0xfff;
            uStack_6c = (ushort)*(undefined4 *)(puVar5 + *(short *)puVar4 * 0x20) & 0xfff;
            .debug::_myprintf__13TStatusWindowFPce
                      (*(undefined4 *)puVar2,PTR_s___3x____3x_100ce82c,uStack_6a,uStack_6c);
            return;
          }
        }
      }
      else {
        if (sVar16 == 0xc6) {
          if (*puVar7 == '\0') {
            return;
          }
          .debug::_myprintf__13TStatusWindowFPce
                    (*(undefined4 *)puVar2,PTR_s_Jump_from___x__x__x___100ce854,
                     (ushort)(*(uint *)(puVar5 + *(short *)puVar4 * 0x20) >> 0xc) & 0xfff,
                     (ushort)*(undefined4 *)(puVar5 + *(short *)puVar4 * 0x20) & 0xfff,
                     (int)*(short *)(*(int *)puVar3 + 0x20c24));
          .debug::_myprintf__13TStatusWindowFPce(*(undefined4 *)puVar2,PTR_s_Level__100ce850);
          uVar15 = .debug::_mygetnum__13TStatusWindowFs(*(undefined4 *)puVar2,0x10);
          .debug::_myprintf__13TStatusWindowFPce
                    (*(undefined4 *)puVar2,PTR_DAT_100ce84c,(int)(short)uVar15);
          .debug::_myprintf__13TStatusWindowFPce(*(undefined4 *)puVar2,PTR_DAT_100ce848);
          uVar10 = .debug::_mygetnum__13TStatusWindowFs(*(undefined4 *)puVar2,0x10);
          .debug::_myprintf__13TStatusWindowFPce
                    (*(undefined4 *)puVar2,PTR_DAT_100ce84c,(int)(short)uVar10);
          .debug::_myprintf__13TStatusWindowFPce(*(undefined4 *)puVar2,PTR_DAT_100ce844);
          uVar11 = .debug::_mygetnum__13TStatusWindowFs(*(undefined4 *)puVar2,0x10);
          .debug::_myprintf__13TStatusWindowFPce
                    (*(undefined4 *)puVar2,PTR_DAT_100ce84c,(int)(short)uVar11);
          FUN_100c50e8(param_1);
          *(undefined2 *)(*(int *)puVar3 + 0x20c28) = 1;
          .debug::_GoToLocation__11TGameViewerFsss(*(undefined4 *)puVar3,uVar15,uVar10,uVar11);
          return;
        }
        if ((sVar16 < 0xc6) && (0xc4 < sVar16)) {
          if (*puVar7 == '\0') {
            return;
          }
          if ((puVar5[0x1a] & 0x80) != 0) {
            .debug::_RemoveAbility__8TSpellFXFss(0,0x1f);
            return;
          }
          .debug::_AddAbility__8TSpellFXFss(0,0x1f);
          return;
        }
      }
    }
    else {
      if (sVar16 == 0xfe) {
        if (*puVar7 == '\0') {
          return;
        }
        if ((*(ushort *)(puVar5 + *(short *)puVar4 * 0x20 + 6) & 0x400) != 0) {
          .debug::_RemoveAbility__8TSpellFXFss((int)*(short *)puVar4,0x12);
          return;
        }
        .debug::_AddAbility__8TSpellFXFss((int)*(short *)puVar4,0x12);
        return;
      }
      if (sVar16 < 0xfe) {
        if (sVar16 == 0xfa) {
          if (*puVar7 == '\0') {
            return;
          }
          *PTR_DAT_100cde4c = *PTR_DAT_100cde4c == '\0';
          return;
        }
        if ((sVar16 < 0xfa) && (sVar16 == 0xef)) {
          if (*puVar7 == '\0') {
            return;
          }
          .debug::_myprintf__13TStatusWindowFPce
                    (*(undefined4 *)puVar2,PTR_s_Take_teleporter__100ce840);
          sStack_62 = .debug::_mygetnum__13TStatusWindowFs(*(undefined4 *)puVar2,10);
          FUN_100c50e8(param_1);
          .debug::_TeleportTo__8TGameSysFsss(*_DAT_100cdcd0,1,(int)sStack_62,0);
          return;
        }
      }
      else if (sVar16 < 0x10a) {
        if (0xff < sVar16) {
          .debug::_PerformMacro__13TStatusWindowFs(*(undefined4 *)puVar2,param_2 - 0x100);
          return;
        }
        if (*puVar7 == '\0') {
          return;
        }
        .debug::_myprintf__13TStatusWindowFPce
                  (*(undefined4 *)puVar2,PTR_s_Current_time____8x__day__d_100ce828,_DAT_100d3e18,
                   (int)_DAT_100d3e1c);
        return;
      }
    }
  }
  if (((sVar16 == 0x20) ||
      (cVar14 = .debug::_PerformDoKey__13TStatusWindowFs(*(undefined4 *)puVar2,param_2),
      cVar14 == '\0')) && (*(short *)(*(int *)puVar1 + 4) == 3)) {
    .debug::_ScheduleKeyDown__11TTaskMasterFP16TDroppableWindows(param_1,param_2);
  }
  return;
}


// ==== .Save__13TCrawlMonsterFP7TStream @ 10045b64 ====
// CyDecompAt: created, body 10045b64-10045c0b

void _Save__13TCrawlMonsterFP7TStream(int param_1,undefined4 param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  uint uVar3;
  short sVar4;
  
  puVar2 = PTR_DAT_100ce900;
  puVar1 = PTR_DAT_100cdc44;
  .debug::_Save__14TActiveMonsterFP7TStream();
  FUN_100c50e8(param_2,puVar2,(int)*(short *)(param_1 + 0x58));
  for (sVar4 = 0; sVar4 < *(short *)(param_1 + 0x58); sVar4 = sVar4 + 1) {
    uVar3 = *(int *)(param_1 + sVar4 * 4 + 0x5c) - *(int *)puVar1;
    FUN_100c50e8(param_2,puVar2,((int)uVar3 >> 4) + (uint)((int)uVar3 < 0 && (uVar3 & 0xf) != 0));
  }
  return;
}


// ==== .Save__14TDragonMonsterFP7TStream @ 10045c40 ====
// CyDecompAt: created, body 10045c40-10045ceb

void _Save__14TDragonMonsterFP7TStream(int param_1,undefined4 param_2)

{
  undefined *puVar1;
  uint uVar2;
  uint uVar3;
  uint uVar4;
  uint uVar5;
  
  puVar1 = PTR_DAT_100cdc44;
  .debug::_Save__14TActiveMonsterFP7TStream();
  uVar4 = *(int *)(param_1 + 0x58) - *(int *)puVar1;
  uVar2 = *(int *)(param_1 + 0x5c) - *(int *)puVar1;
  uVar5 = *(int *)(param_1 + 0x60) - *(int *)puVar1;
  uVar3 = *(int *)(param_1 + 100) - *(int *)puVar1;
  FUN_100c50e8(param_2,PTR_DAT_100ce8f8,
               ((int)uVar4 >> 4) + (uint)((int)uVar4 < 0 && (uVar4 & 0xf) != 0),
               ((int)uVar2 >> 4) + (uint)((int)uVar2 < 0 && (uVar2 & 0xf) != 0),
               ((int)uVar5 >> 4) + (uint)((int)uVar5 < 0 && (uVar5 & 0xf) != 0),
               ((int)uVar3 >> 4) + (uint)((int)uVar3 < 0 && (uVar3 & 0xf) != 0));
  return;
}


// ==== .Save__12TOctoMonsterFP7TStream @ 10045d20 ====
// CyDecompAt: created, body 10045d20-10045da7

void _Save__12TOctoMonsterFP7TStream(int param_1,undefined4 param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  uint uVar3;
  short sVar4;
  
  puVar2 = PTR_DAT_100ce900;
  puVar1 = PTR_DAT_100cdc44;
  .debug::_Save__14TActiveMonsterFP7TStream();
  for (sVar4 = 0; sVar4 < 8; sVar4 = sVar4 + 1) {
    uVar3 = *(int *)(param_1 + sVar4 * 4 + 0x58) - *(int *)puVar1;
    FUN_100c50e8(param_2,puVar2,((int)uVar3 >> 4) + (uint)((int)uVar3 < 0 && (uVar3 & 0xf) != 0));
  }
  return;
}


// ==== .LeaveLevel__14TActiveMonsterFv @ 100465a4 ====
// CyDecompAt: created, body 100465a4-100466a7

void _LeaveLevel__14TActiveMonsterFv(int *param_1)

{
  char cVar1;
  
  if (*(short *)(param_1 + 2) < 0x100) {
    if ((*(ushort *)(*param_1 + 6) & 1) == 0) {
      *(undefined1 *)param_1[4] = 0xff;
    }
    else {
      *(undefined1 *)param_1[4] = 0x42;
    }
    if (*(char *)(param_1 + 0x13) != '\0') {
      cVar1 = .debug::_IsVisibleAbs__7TViewerFss
                        (*(undefined4 *)PTR_DAT_100cdbb8,(int)*(short *)((int)param_1 + 0x4e),
                         (int)*(short *)(param_1 + 0x14));
      if (cVar1 == '\0') {
        *(uint *)param_1[4] =
             ((int)*(short *)((int)param_1 + 0x4e) & 0xfffU) << 0xc |
             (int)*(short *)(param_1 + 0x14) & 0xfffU | *(uint *)param_1[4] & 0xff000000;
        *(uint *)*param_1 =
             (int)*(short *)(param_1 + 0x14) |
             *(uint *)*param_1 & 0xff000000 | (int)*(short *)((int)param_1 + 0x4e) << 0xc;
      }
    }
  }
  else {
    *(char *)(param_1[5] + 7) = *(char *)(param_1[5] + 7) + '\x01';
  }
  if (param_1 != (int *)0x0) {
    FUN_100c50e8(param_1,1);
  }
  return;
}


// ==== .__dt__13TCrawlMonsterFv @ 100466dc ====
// CyDecompAt: created, body 100466dc-10046797

int ___dt__13TCrawlMonsterFv(int param_1,short param_2)

{
  undefined *puVar1;
  uint uVar2;
  short sVar3;
  
  puVar1 = PTR_DAT_100cdc44;
  if (param_1 != 0) {
    *(undefined ***)(param_1 + 0x48) = &PTR_PTR_100d5b70;
    for (sVar3 = 0; sVar3 < *(short *)(param_1 + 0x58); sVar3 = sVar3 + 1) {
      uVar2 = *(int *)(param_1 + sVar3 * 4 + 0x5c) - *(int *)puVar1;
      .debug::_DeleteProp__Fs
                ((int)(short)((short)((int)uVar2 >> 4) +
                             (ushort)((int)uVar2 < 0 && (uVar2 & 0xf) != 0)));
    }
    .debug::___dt__14TActiveMonsterFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__14TDragonMonsterFv @ 100467c4 ====
// CyDecompAt: created, body 100467c4-100468af

int ___dt__14TDragonMonsterFv(int param_1,short param_2)

{
  undefined *puVar1;
  uint uVar2;
  
  puVar1 = PTR_DAT_100cdc44;
  if (param_1 != 0) {
    *(undefined ***)(param_1 + 0x48) = &PTR_PTR_100d5b20;
    uVar2 = *(int *)(param_1 + 0x58) - *(int *)puVar1;
    .debug::_DeleteProp__Fs
              ((int)(short)((short)((int)uVar2 >> 4) +
                           (ushort)((int)uVar2 < 0 && (uVar2 & 0xf) != 0)));
    uVar2 = *(int *)(param_1 + 0x5c) - *(int *)puVar1;
    .debug::_DeleteProp__Fs
              ((int)(short)((short)((int)uVar2 >> 4) +
                           (ushort)((int)uVar2 < 0 && (uVar2 & 0xf) != 0)));
    uVar2 = *(int *)(param_1 + 0x60) - *(int *)puVar1;
    .debug::_DeleteProp__Fs
              ((int)(short)((short)((int)uVar2 >> 4) +
                           (ushort)((int)uVar2 < 0 && (uVar2 & 0xf) != 0)));
    uVar2 = *(int *)(param_1 + 100) - *(int *)puVar1;
    .debug::_DeleteProp__Fs
              ((int)(short)((short)((int)uVar2 >> 4) +
                           (ushort)((int)uVar2 < 0 && (uVar2 & 0xf) != 0)));
    .debug::___dt__14TActiveMonsterFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .__dt__12TOctoMonsterFv @ 100468dc ====
// CyDecompAt: created, body 100468dc-10046993

int ___dt__12TOctoMonsterFv(int param_1,short param_2)

{
  undefined *puVar1;
  uint uVar2;
  short sVar3;
  
  puVar1 = PTR_DAT_100cdc44;
  if (param_1 != 0) {
    *(undefined ***)(param_1 + 0x48) = &PTR_PTR_100d5ad0;
    for (sVar3 = 0; sVar3 < 8; sVar3 = sVar3 + 1) {
      uVar2 = *(int *)(param_1 + sVar3 * 4 + 0x58) - *(int *)puVar1;
      .debug::_DeleteProp__Fs
                ((int)(short)((short)((int)uVar2 >> 4) +
                             (ushort)((int)uVar2 < 0 && (uVar2 & 0xf) != 0)));
    }
    .debug::___dt__14TActiveMonsterFv(param_1,0);
    if (0 < param_2) {
      FUN_100be848(param_1);
    }
  }
  return param_1;
}


// ==== .Die__14TActiveMonsterFv @ 100469c0 ====
// CyDecompAt: created, body 100469c0-100470d3

void _Die__14TActiveMonsterFv(int *param_1)

{
  ushort uVar1;
  undefined *puVar2;
  undefined *puVar3;
  short sVar4;
  uint uVar5;
  uint *puVar6;
  int iVar7;
  uint *puVar8;
  undefined4 uStack_58;
  undefined1 auStack_54 [4];
  undefined2 uStack_50;
  ushort uStack_4e;
  int iStack_4c;
  
  puVar3 = PTR_DAT_100cdc3c;
  uVar5 = *param_1 - (int)PTR_DAT_100cdbf0;
  .debug::___ct__5VAddrFcUsUs
            (&uStack_58,4,0x40,
             (short)((int)uVar5 >> 5) + (ushort)((int)uVar5 < 0 && (uVar5 & 0x1f) != 0));
  .debug::_DoInterp__7TInterpFs5VAddr(auStack_54,0x1d,uStack_58);
  if (*(char *)(*param_1 + 0xe) == '\0') {
    iStack_4c = .debug::_FindInventory__16TInventoryWindowFs((int)*(short *)(param_1 + 2));
    if (iStack_4c != 0) {
      FUN_100c50e8();
    }
    *(ushort *)(*param_1 + 6) = *(ushort *)(*param_1 + 6) & 0xfffe;
    if (*(short *)(param_1 + 2) < 0x100) {
      if ((*(byte *)(*param_1 + 8) & 0x40) != 0) {
        *(byte *)(*param_1 + 8) = *(byte *)(*param_1 + 8) & 0xbf;
        .debug::_RebuildParty__Fv();
      }
      uStack_4e = *(ushort *)(param_1[1] + 0xe);
      if (uStack_4e == 0) {
        puVar6 = (uint *)(*(int *)PTR_DAT_100cdc44 + 0x1000);
        for (iVar7 = 0x100; puVar2 = PTR_DAT_100cdbc8, (short)iVar7 < *(short *)puVar3;
            iVar7 = iVar7 + 1) {
          if ((((*(char *)puVar6 == '\x10') || (*(char *)puVar6 == '\x18')) ||
              (*(char *)puVar6 == '\t')) && ((int)*(short *)(param_1 + 2) == (*puVar6 & 0xffff))) {
            *(char *)puVar6 = '\x01';
            *puVar6 = ((int)(short)((short)((uint)*(undefined4 *)param_1[4] >> 8) >> 4) & 0xfffU) <<
                      0xc | (int)((int)*(short *)(param_1[4] + 2) << 0x14 |
                                 (uint)(int)*(short *)(param_1[4] + 2) >> 0xc) >> 0x14 & 0xfffU |
                      *puVar6 & 0xff000000;
          }
          else if ((*(char *)puVar6 == '\x1c') &&
                  ((int)*(short *)(param_1 + 2) == (*puVar6 & 0xffff))) {
            .debug::_DeleteProp__Fs(iVar7);
          }
          puVar6 = puVar6 + 4;
        }
        *(undefined1 *)param_1[4] = 0xff;
        .debug::_ForceReset__5THoodFv(puVar2);
      }
      else {
        sVar4 = .debug::_NewProp__Fv();
        puVar2 = PTR_DAT_100cdc44;
        puVar6 = (uint *)(*(int *)PTR_DAT_100cdc44 + sVar4 * 0x10);
        *(undefined1 *)puVar6 = 1;
        *(ushort *)(puVar6 + 1) = uStack_4e & 0x3ff | *(ushort *)(puVar6 + 1) & 0xfc00;
        *(byte *)(puVar6 + 1) =
             (byte)(((int)(short)uStack_4e >> 10 & 0xffU) << 2) & 0x7c |
             *(byte *)(puVar6 + 1) & 0x83;
        *(char *)((int)puVar6 + 6) = (char)*(undefined2 *)(param_1 + 2);
        *(undefined1 *)((int)puVar6 + 7) = 0;
        *puVar6 = ((int)(short)((short)((uint)*(undefined4 *)param_1[4] >> 8) >> 4) & 0xfffU) << 0xc
                  | (int)((short)((ushort)((uint)((int)*(short *)(param_1[4] + 2) << 0x14) >> 0x10)
                                 | (ushort)(*(short *)(param_1[4] + 2) >> 0xf) >> 0xc) >> 4) &
                    0xfffU | *puVar6 & 0xff000000;
        puVar8 = (uint *)(*(int *)puVar2 + 0x1000);
        for (sVar4 = 0x100; puVar2 = PTR_DAT_100cdc44, sVar4 < *(short *)puVar3; sVar4 = sVar4 + 1)
        {
          if ((((*(char *)puVar8 == '\x10') || (*(char *)puVar8 == '\x18')) ||
              (*(char *)puVar8 == '\t')) && ((int)*(short *)(param_1 + 2) == (*puVar8 & 0xffff))) {
            *(char *)puVar8 = '\t';
            uVar5 = (int)puVar6 - *(int *)puVar2;
            *puVar8 = *puVar8 & 0xff0000 |
                      ((int)uVar5 >> 4) + (uint)((int)uVar5 < 0 && (uVar5 & 0xf) != 0) & 0xffffff |
                      *puVar8 & 0xff000000;
          }
          puVar8 = puVar8 + 4;
        }
        *(undefined1 *)param_1[4] = 0xff;
        uVar5 = (int)puVar6 - *(int *)puVar2;
        .debug::_AddToHood__5THoodFs
                  (PTR_DAT_100cdbc8,
                   (int)(short)((short)((int)uVar5 >> 4) +
                               (ushort)((int)uVar5 < 0 && (uVar5 & 0xf) != 0)));
      }
      if (*(short *)(param_1 + 2) == *(short *)PTR_DAT_100cdbec) {
        *(undefined2 *)(param_1 + 2) = 1;
      }
      if ((PTR_DAT_100cdbf0[*(short *)(param_1 + 2) * 0x20 + 8] & 0x40) != 0) {
        .debug::_RebuildParty__Fv();
      }
      if (*(short *)(param_1 + 2) == 1) {
        *(undefined1 *)(*(int *)PTR_DAT_100cdb84 + 0x1c) = 1;
      }
    }
    else {
      if (((*(ushort *)(param_1[5] + 4) & 0x3ff) == (*(ushort *)(param_1[4] + 4) & 0x3ff)) &&
         ((*(byte *)(*(int *)PTR_DAT_100cdc44 + (*(uint *)param_1[5] & 0xffff) * 0x10 + 6) & 4) == 4
         )) {
        *(char *)(param_1[5] + 7) = *(char *)(param_1[5] + 7) + '\x01';
      }
      uVar1 = *(ushort *)(param_1[1] + 0xe);
      if (uVar1 == 0) {
        puVar6 = (uint *)(*(int *)PTR_DAT_100cdc44 + 0x1000);
        uStack_50 = 0;
        for (iVar7 = 0x100; puVar2 = PTR_DAT_100cdbc8, (short)iVar7 < *(short *)puVar3;
            iVar7 = iVar7 + 1) {
          if ((((*(char *)puVar6 == '\x10') || (*(char *)puVar6 == '\x18')) ||
              (*(char *)puVar6 == '\t')) && ((int)*(short *)(param_1 + 2) == (*puVar6 & 0xffff))) {
            *(char *)puVar6 = '\x01';
            *puVar6 = ((int)(short)((short)((uint)*(undefined4 *)param_1[4] >> 8) >> 4) & 0xfffU) <<
                      0xc | (int)((int)*(short *)(param_1[4] + 2) << 0x14 |
                                 (uint)(int)*(short *)(param_1[4] + 2) >> 0xc) >> 0x14 & 0xfffU |
                      *puVar6 & 0xff000000;
          }
          else if ((*(char *)puVar6 == '\x1c') &&
                  ((int)*(short *)(param_1 + 2) == (*puVar6 & 0xffff))) {
            .debug::_DeleteProp__Fs(iVar7);
          }
          puVar6 = puVar6 + 4;
        }
        *(undefined1 *)param_1[4] = 0xff;
        .debug::_ForceReset__5THoodFv(puVar2);
      }
      else {
        *(undefined1 *)param_1[4] = 0x21;
        puVar2 = PTR_DAT_100cdc44;
        *(ushort *)(param_1[4] + 4) = uVar1 & 0x3ff | *(ushort *)(param_1[4] + 4) & 0xfc00;
        *(byte *)(param_1[4] + 4) =
             (byte)(((int)(short)uVar1 >> 10 & 0xffU) << 2) & 0x7c |
             *(byte *)(param_1[4] + 4) & 0x83;
        *(undefined1 *)(param_1[4] + 6) = 0;
        *(undefined1 *)(param_1[4] + 7) = 0;
        puVar6 = (uint *)(*(int *)puVar2 + 0x1000);
        for (sVar4 = 0x100; sVar4 < *(short *)puVar3; sVar4 = sVar4 + 1) {
          if ((((*(char *)puVar6 == '\x10') || (*(char *)puVar6 == '\x18')) ||
              (*(char *)puVar6 == '\t')) && ((int)*(short *)(param_1 + 2) == (*puVar6 & 0xffff))) {
            *(char *)puVar6 = '\t';
          }
          puVar6 = puVar6 + 4;
        }
        *(undefined2 *)(param_1 + 2) = 0;
      }
    }
  }
  else {
    uVar5 = *param_1 - (int)PTR_DAT_100cdbf0;
    .debug::_RemoveStackedAbility__8TSpellFXFss
              ((int)(short)((short)((int)uVar5 >> 5) +
                           (ushort)((int)uVar5 < 0 && (uVar5 & 0x1f) != 0)),0xd);
    uVar5 = *param_1 - (int)PTR_DAT_100cdbf0;
    .debug::_RemoveStackedAbility__8TSpellFXFss
              ((int)(short)((short)((int)uVar5 >> 5) +
                           (ushort)((int)uVar5 < 0 && (uVar5 & 0x1f) != 0)),0xe);
    uVar5 = *param_1 - (int)PTR_DAT_100cdbf0;
    .debug::_RemoveStackedAbility__8TSpellFXFss
              ((int)(short)((short)((int)uVar5 >> 5) +
                           (ushort)((int)uVar5 < 0 && (uVar5 & 0x1f) != 0)),0x16);
    uVar5 = *param_1 - (int)PTR_DAT_100cdbf0;
    .debug::_RemoveStackedAbility__8TSpellFXFss
              ((int)(short)((short)((int)uVar5 >> 5) +
                           (ushort)((int)uVar5 < 0 && (uVar5 & 0x1f) != 0)),0x15);
    *(ushort *)(*param_1 + 6) = *(ushort *)(*param_1 + 6) | 1;
  }
  return;
}


// ==== .ClearMonstStage__13TCrawlMonsterFv @ 1004735c ====
// CyDecompAt: created, body 1004735c-100473f3

void _ClearMonstStage__13TCrawlMonsterFv(int param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  uint uVar3;
  short sVar4;
  
  puVar2 = PTR_DAT_100cdc44;
  puVar1 = PTR_DAT_100cdbb8;
  .debug::_ClearMonstStage__14TActiveMonsterFv();
  for (sVar4 = 0; sVar4 < *(short *)(param_1 + 0x58); sVar4 = sVar4 + 1) {
    uVar3 = *(int *)(param_1 + sVar4 * 4 + 0x5c) - *(int *)puVar2;
    .debug::_ClearMonstStage__7TViewerFs
              (*(undefined4 *)puVar1,
               (int)(short)((short)((int)uVar3 >> 4) +
                           (ushort)((int)uVar3 < 0 && (uVar3 & 0xf) != 0)));
  }
  return;
}


// ==== .SetMonstStage__13TCrawlMonsterFv @ 1004742c ====
// CyDecompAt: created, body 1004742c-100474c3

void _SetMonstStage__13TCrawlMonsterFv(int param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  uint uVar3;
  short sVar4;
  
  puVar2 = PTR_DAT_100cdc44;
  puVar1 = PTR_DAT_100cdbb8;
  .debug::_SetMonstStage__14TActiveMonsterFv();
  for (sVar4 = 0; sVar4 < *(short *)(param_1 + 0x58); sVar4 = sVar4 + 1) {
    uVar3 = *(int *)(param_1 + sVar4 * 4 + 0x5c) - *(int *)puVar2;
    .debug::_SetMonstStage__7TViewerFs
              (*(undefined4 *)puVar1,
               (int)(short)((short)((int)uVar3 >> 4) +
                           (ushort)((int)uVar3 < 0 && (uVar3 & 0xf) != 0)));
  }
  return;
}


// ==== .ClearMonstStage__12TOctoMonsterFv @ 100474f8 ====
// CyDecompAt: created, body 100474f8-1004758b

void _ClearMonstStage__12TOctoMonsterFv(int param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  uint uVar3;
  short sVar4;
  
  puVar2 = PTR_DAT_100cdc44;
  puVar1 = PTR_DAT_100cdbb8;
  .debug::_ClearMonstStage__14TActiveMonsterFv();
  for (sVar4 = 0; sVar4 < 8; sVar4 = sVar4 + 1) {
    uVar3 = *(int *)(param_1 + sVar4 * 4 + 0x58) - *(int *)puVar2;
    .debug::_ClearMonstStage__7TViewerFs
              (*(undefined4 *)puVar1,
               (int)(short)((short)((int)uVar3 >> 4) +
                           (ushort)((int)uVar3 < 0 && (uVar3 & 0xf) != 0)));
  }
  return;
}


// ==== .SetMonstStage__12TOctoMonsterFv @ 100475c0 ====
// CyDecompAt: created, body 100475c0-10047653

void _SetMonstStage__12TOctoMonsterFv(int param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  uint uVar3;
  short sVar4;
  
  puVar2 = PTR_DAT_100cdc44;
  puVar1 = PTR_DAT_100cdbb8;
  .debug::_SetMonstStage__14TActiveMonsterFv();
  for (sVar4 = 0; sVar4 < 8; sVar4 = sVar4 + 1) {
    uVar3 = *(int *)(param_1 + sVar4 * 4 + 0x58) - *(int *)puVar2;
    .debug::_SetMonstStage__7TViewerFs
              (*(undefined4 *)puVar1,
               (int)(short)((short)((int)uVar3 >> 4) +
                           (ushort)((int)uVar3 < 0 && (uVar3 & 0xf) != 0)));
  }
  return;
}


// ==== .ClearMonstStage__14TDragonMonsterFv @ 10047688 ====
// CyDecompAt: created, body 10047688-1004775b

void _ClearMonstStage__14TDragonMonsterFv(int param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  uint uVar3;
  
  puVar2 = PTR_DAT_100cdc44;
  puVar1 = PTR_DAT_100cdbb8;
  .debug::_ClearMonstStage__14TActiveMonsterFv();
  uVar3 = *(int *)(param_1 + 0x58) - *(int *)puVar2;
  .debug::_ClearMonstStage__7TViewerFs
            (*(undefined4 *)puVar1,
             (int)(short)((short)((int)uVar3 >> 4) + (ushort)((int)uVar3 < 0 && (uVar3 & 0xf) != 0))
            );
  uVar3 = *(int *)(param_1 + 0x5c) - *(int *)puVar2;
  .debug::_ClearMonstStage__7TViewerFs
            (*(undefined4 *)puVar1,
             (int)(short)((short)((int)uVar3 >> 4) + (ushort)((int)uVar3 < 0 && (uVar3 & 0xf) != 0))
            );
  uVar3 = *(int *)(param_1 + 0x60) - *(int *)puVar2;
  .debug::_ClearMonstStage__7TViewerFs
            (*(undefined4 *)puVar1,
             (int)(short)((short)((int)uVar3 >> 4) + (ushort)((int)uVar3 < 0 && (uVar3 & 0xf) != 0))
            );
  uVar3 = *(int *)(param_1 + 100) - *(int *)puVar2;
  .debug::_ClearMonstStage__7TViewerFs
            (*(undefined4 *)puVar1,
             (int)(short)((short)((int)uVar3 >> 4) + (ushort)((int)uVar3 < 0 && (uVar3 & 0xf) != 0))
            );
  return;
}


// ==== .SetMonstStage__14TDragonMonsterFv @ 10047794 ====
// CyDecompAt: created, body 10047794-10047867

void _SetMonstStage__14TDragonMonsterFv(int param_1)

{
  undefined *puVar1;
  undefined *puVar2;
  uint uVar3;
  
  puVar2 = PTR_DAT_100cdc44;
  puVar1 = PTR_DAT_100cdbb8;
  .debug::_SetMonstStage__14TActiveMonsterFv();
  uVar3 = *(int *)(param_1 + 0x58) - *(int *)puVar2;
  .debug::_SetMonstStage__7TViewerFs
            (*(undefined4 *)puVar1,
             (int)(short)((short)((int)uVar3 >> 4) + (ushort)((int)uVar3 < 0 && (uVar3 & 0xf) != 0))
            );
  uVar3 = *(int *)(param_1 + 0x5c) - *(int *)puVar2;
  .debug::_SetMonstStage__7TViewerFs
            (*(undefined4 *)puVar1,
             (int)(short)((short)((int)uVar3 >> 4) + (ushort)((int)uVar3 < 0 && (uVar3 & 0xf) != 0))
            );
  uVar3 = *(int *)(param_1 + 0x60) - *(int *)puVar2;
  .debug::_SetMonstStage__7TViewerFs
            (*(undefined4 *)puVar1,
             (int)(short)((short)((int)uVar3 >> 4) + (ushort)((int)uVar3 < 0 && (uVar3 & 0xf) != 0))
            );
  uVar3 = *(int *)(param_1 + 100) - *(int *)puVar2;
  .debug::_SetMonstStage__7TViewerFs
            (*(undefined4 *)puVar1,
             (int)(short)((short)((int)uVar3 >> 4) + (ushort)((int)uVar3 < 0 && (uVar3 & 0xf) != 0))
            );
  return;
}


// ==== .HandleSubMove__13TCrawlMonsterFv @ 10049228 ====
// CyDecompAt: created, body 10049228-1004935b

void _HandleSubMove__13TCrawlMonsterFv(int param_1)

{
  short sVar1;
  short sVar2;
  short sVar3;
  undefined4 uVar4;
  undefined4 uVar5;
  uint *puVar6;
  short sVar7;
  
  uVar5 = **(undefined4 **)(param_1 + 0x10);
  sVar1 = *(short *)(*(int *)(param_1 + 0x10) + 2);
  .debug::_HandleSubMove__14TActiveMonsterFv();
  uVar4 = **(undefined4 **)(param_1 + 0x10);
  sVar2 = *(short *)(*(int *)(param_1 + 0x10) + 2);
  for (sVar7 = 0; sVar7 < *(short *)(param_1 + 0x58); sVar7 = sVar7 + 1) {
    *(undefined1 *)(*(int *)(param_1 + sVar7 * 4 + 0x5c) + 6) =
         *(undefined1 *)(*(int *)(param_1 + 0x10) + 6);
    sVar3 = *(short *)(*(int *)(param_1 + sVar7 * 4 + 0x5c) + 2);
    puVar6 = *(uint **)(param_1 + sVar7 * 4 + 0x5c);
    *puVar6 = (((int)(short)((short)((uint)uVar4 >> 8) >> 4) +
               (int)(short)((short)((uint)**(undefined4 **)(param_1 + sVar7 * 4 + 0x5c) >> 8) >> 4))
              - (int)(short)((short)((uint)uVar5 >> 8) >> 4)) * 0x1000 & 0xfff000U |
              ((int)((short)((ushort)((uint)((int)sVar2 << 0x14) >> 0x10) |
                            (ushort)(sVar2 >> 0xf) >> 0xc) >> 4) +
              (int)((short)((ushort)((uint)((int)sVar3 << 0x14) >> 0x10) |
                           (ushort)(sVar3 >> 0xf) >> 0xc) >> 4)) -
              (int)((short)((ushort)((uint)((int)sVar1 << 0x14) >> 0x10) |
                           (ushort)(sVar1 >> 0xf) >> 0xc) >> 4) & 0xfffU | *puVar6 & 0xff000000;
  }
  return;
}


// ==== .HandleSubMove__14TDragonMonsterFv @ 10049390 ====
// CyDecompAt: created, body 10049390-100493fb

void _HandleSubMove__14TDragonMonsterFv(int param_1)

{
  .debug::_HandleSubMove__14TActiveMonsterFv();
  *(undefined1 *)(*(int *)(param_1 + 0x58) + 6) = *(undefined1 *)(*(int *)(param_1 + 0x10) + 6);
  *(undefined1 *)(*(int *)(param_1 + 0x5c) + 6) = *(undefined1 *)(*(int *)(param_1 + 0x10) + 6);
  *(undefined1 *)(*(int *)(param_1 + 0x60) + 6) = *(undefined1 *)(*(int *)(param_1 + 0x10) + 6);
  *(undefined1 *)(*(int *)(param_1 + 100) + 6) = *(undefined1 *)(*(int *)(param_1 + 0x10) + 6);
  return;
}


// ==== .HandleSubMove__12TOctoMonsterFv @ 10049430 ====
// CyDecompAt: created, body 10049430-1004955f

void _HandleSubMove__12TOctoMonsterFv(int param_1)

{
  short sVar1;
  short sVar2;
  short sVar3;
  undefined4 uVar4;
  undefined4 uVar5;
  uint *puVar6;
  short sVar7;
  
  uVar5 = **(undefined4 **)(param_1 + 0x10);
  sVar1 = *(short *)(*(int *)(param_1 + 0x10) + 2);
  .debug::_HandleSubMove__14TActiveMonsterFv();
  uVar4 = **(undefined4 **)(param_1 + 0x10);
  sVar2 = *(short *)(*(int *)(param_1 + 0x10) + 2);
  for (sVar7 = 0; sVar7 < 8; sVar7 = sVar7 + 1) {
    *(undefined1 *)(*(int *)(param_1 + sVar7 * 4 + 0x58) + 6) =
         *(undefined1 *)(*(int *)(param_1 + 0x10) + 6);
    sVar3 = *(short *)(*(int *)(param_1 + sVar7 * 4 + 0x58) + 2);
    puVar6 = *(uint **)(param_1 + sVar7 * 4 + 0x58);
    *puVar6 = (((int)(short)((short)((uint)uVar4 >> 8) >> 4) +
               (int)(short)((short)((uint)**(undefined4 **)(param_1 + sVar7 * 4 + 0x58) >> 8) >> 4))
              - (int)(short)((short)((uint)uVar5 >> 8) >> 4)) * 0x1000 & 0xfff000U |
              ((int)((short)((ushort)((uint)((int)sVar2 << 0x14) >> 0x10) |
                            (ushort)(sVar2 >> 0xf) >> 0xc) >> 4) +
              (int)((short)((ushort)((uint)((int)sVar3 << 0x14) >> 0x10) |
                           (ushort)(sVar3 >> 0xf) >> 0xc) >> 4)) -
              (int)((short)((ushort)((uint)((int)sVar1 << 0x14) >> 0x10) |
                           (ushort)(sVar1 >> 0xf) >> 0xc) >> 4) & 0xfffU | *puVar6 & 0xff000000;
  }
  return;
}


// ==== .HandleMove__12TOctoMonsterFsssss @ 10049684 ====
// CyDecompAt: created, body 10049684-100497db

void _HandleMove__12TOctoMonsterFsssss
               (int param_1,short param_2,short param_3,short param_4,short param_5,short param_6)

{
  short sVar1;
  short sVar2;
  short sVar3;
  undefined4 uVar4;
  undefined4 uVar5;
  uint *puVar6;
  short sVar7;
  
  uVar5 = **(undefined4 **)(param_1 + 0x10);
  sVar1 = *(short *)(*(int *)(param_1 + 0x10) + 2);
  .debug::_HandleMove__14TActiveMonsterFsssss
            (param_1,(int)param_2,(int)param_3,(int)param_4,(int)param_5,(int)param_6);
  uVar4 = **(undefined4 **)(param_1 + 0x10);
  sVar2 = *(short *)(*(int *)(param_1 + 0x10) + 2);
  for (sVar7 = 0; sVar7 < 8; sVar7 = sVar7 + 1) {
    sVar3 = *(short *)(*(int *)(param_1 + sVar7 * 4 + 0x58) + 2);
    puVar6 = *(uint **)(param_1 + sVar7 * 4 + 0x58);
    *puVar6 = (((int)(short)((short)((uint)uVar4 >> 8) >> 4) +
               (int)(short)((short)((uint)**(undefined4 **)(param_1 + sVar7 * 4 + 0x58) >> 8) >> 4))
              - (int)(short)((short)((uint)uVar5 >> 8) >> 4)) * 0x1000 & 0xfff000U |
              ((int)((short)((ushort)((uint)((int)sVar2 << 0x14) >> 0x10) |
                            (ushort)(sVar2 >> 0xf) >> 0xc) >> 4) +
              (int)((short)((ushort)((uint)((int)sVar3 << 0x14) >> 0x10) |
                           (ushort)(sVar3 >> 0xf) >> 0xc) >> 4)) -
              (int)((short)((ushort)((uint)((int)sVar1 << 0x14) >> 0x10) |
                           (ushort)(sVar1 >> 0xf) >> 0xc) >> 4) & 0xfffU | *puVar6 & 0xff000000;
    *(undefined1 *)(*(int *)(param_1 + sVar7 * 4 + 0x58) + 6) =
         *(undefined1 *)(*(int *)(param_1 + 0x10) + 6);
  }
  return;
}


// ==== .HandleMove__13TCrawlMonsterFsssss @ 10049810 ====
// CyDecompAt: created, body 10049810-10049ca7

void _HandleMove__13TCrawlMonsterFsssss
               (int param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,
               undefined4 param_5,undefined4 param_6)

{
  uint uVar1;
  short sVar2;
  int iVar3;
  uint *puVar4;
  short sVar5;
  undefined4 *puVar6;
  undefined4 *puVar7;
  
  if (*(short *)(param_1 + 0x58) == 1) {
    .debug::_HandleMove__14TActiveMonsterFsssss(param_1,param_2,param_3,param_4,param_5,param_6);
    if ((**(byte **)(param_1 + 0x14) & 0x40) == 0) {
      *(byte *)(*(int *)(param_1 + 0x5c) + 4) =
           ((*(byte *)(*(int *)(param_1 + 0x10) + 4) >> 2 & 0x1f) + 8) * '\x04' & 0x7c |
           *(byte *)(*(int *)(param_1 + 0x5c) + 4) & 0x83;
    }
    else {
      iVar3 = (*(byte *)(*(int *)(param_1 + 0x10) + 4) >> 2 & 0x1f) + 2;
      *(byte *)(*(int *)(param_1 + 0x5c) + 4) =
           ((char)iVar3 + (char)(iVar3 >> 2) * -4) * '\x04' & 0x7cU |
           *(byte *)(*(int *)(param_1 + 0x5c) + 4) & 0x83;
    }
    sVar5 = *(short *)(param_1 + 0xc);
    uVar1 = (uint)*(short *)(*(int *)(param_1 + 0x10) + 2);
    sVar2 = (short)((uint)**(undefined4 **)(param_1 + 0x10) >> 8) >> 4;
    uVar1 = (int)(uVar1 << 0x14 | uVar1 >> 0xc) >> 0x14;
    if (sVar5 == 2) {
      uVar1 = uVar1 - 1;
    }
    else if (sVar5 < 2) {
      if (sVar5 == 0) {
        uVar1 = uVar1 + 1;
      }
      else if (-1 < sVar5) {
        sVar2 = sVar2 + -1;
      }
    }
    else if (sVar5 < 4) {
      sVar2 = sVar2 + 1;
    }
    **(uint **)(param_1 + 0x5c) =
         ((int)sVar2 & 0xfffU) << 0xc | uVar1 & 0xfff | **(uint **)(param_1 + 0x5c) & 0xff000000;
    *(undefined1 *)(*(int *)(param_1 + 0x5c) + 6) = *(undefined1 *)(*(int *)(param_1 + 0x10) + 6);
  }
  else {
    sVar5 = *(short *)(param_1 + 0x58);
    while (sVar5 = sVar5 + -1, 0 < sVar5) {
      puVar4 = *(uint **)(param_1 + sVar5 * 4 + 0x5c);
      *puVar4 = **(uint **)(param_1 + (sVar5 + -1) * 4 + 0x5c) & 0xffffff | *puVar4 & 0xff000000;
      iVar3 = *(int *)(param_1 + sVar5 * 4 + 0x5c);
      *(byte *)(iVar3 + 4) =
           *(byte *)(*(int *)(param_1 + (sVar5 + -1) * 4 + 0x5c) + 4) & 0x7c |
           *(byte *)(iVar3 + 4) & 0x83;
      *(undefined1 *)(*(int *)(param_1 + sVar5 * 4 + 0x5c) + 6) =
           *(undefined1 *)(*(int *)(param_1 + 0x10) + 6);
    }
    sVar5 = (short)param_5;
    **(uint **)(param_1 + 0x5c) =
         **(uint **)(param_1 + 0x10) & 0xffffff | **(uint **)(param_1 + 0x5c) & 0xff000000;
    *(undefined1 *)(*(int *)(param_1 + 0x5c) + 6) = *(undefined1 *)(*(int *)(param_1 + 0x10) + 6);
    if ((sVar5 == 0) && ((*(short *)(param_1 + 0xc) == 1 || (*(short *)(param_1 + 0xc) == 3)))) {
      *(byte *)(*(int *)(param_1 + 0x5c) + 4) =
           *(byte *)(*(int *)(param_1 + 0x5c) + 4) & 0x83 | 0x24;
    }
    else {
      sVar2 = (short)param_4;
      if ((sVar2 == 0) && ((*(short *)(param_1 + 0xc) == 0 || (*(short *)(param_1 + 0xc) == 2)))) {
        *(byte *)(*(int *)(param_1 + 0x5c) + 4) =
             *(byte *)(*(int *)(param_1 + 0x5c) + 4) & 0x83 | 0x20;
      }
      else if (((*(short *)(param_1 + 0xc) == 2) && (sVar2 == 1)) ||
              ((*(short *)(param_1 + 0xc) == 3 && (sVar5 == -1)))) {
        *(byte *)(*(int *)(param_1 + 0x5c) + 4) =
             *(byte *)(*(int *)(param_1 + 0x5c) + 4) & 0x83 | 0x28;
      }
      else if (((*(short *)(param_1 + 0xc) == 0) && (sVar2 == 1)) ||
              ((*(short *)(param_1 + 0xc) == 3 && (sVar5 == 1)))) {
        *(byte *)(*(int *)(param_1 + 0x5c) + 4) =
             *(byte *)(*(int *)(param_1 + 0x5c) + 4) & 0x83 | 0x2c;
      }
      else if (((*(short *)(param_1 + 0xc) == 0) && (sVar2 == -1)) ||
              ((*(short *)(param_1 + 0xc) == 1 && (sVar5 == 1)))) {
        *(byte *)(*(int *)(param_1 + 0x5c) + 4) =
             *(byte *)(*(int *)(param_1 + 0x5c) + 4) & 0x83 | 0x30;
      }
      else {
        *(byte *)(*(int *)(param_1 + 0x5c) + 4) =
             *(byte *)(*(int *)(param_1 + 0x5c) + 4) & 0x83 | 0x34;
      }
    }
    puVar7 = *(undefined4 **)(param_1 + (*(short *)(param_1 + 0x58) + -1) * 4 + 0x5c);
    puVar6 = *(undefined4 **)(param_1 + (*(short *)(param_1 + 0x58) + -2) * 4 + 0x5c);
    sVar5 = (short)((ushort)((uint)((int)*(short *)((int)puVar7 + 2) << 0x14) >> 0x10) |
                   (ushort)(*(short *)((int)puVar7 + 2) >> 0xf) >> 0xc) >> 4;
    if (sVar5 + -1 ==
        (int)((short)((ushort)((uint)((int)*(short *)((int)puVar6 + 2) << 0x14) >> 0x10) |
                     (ushort)(*(short *)((int)puVar6 + 2) >> 0xf) >> 0xc) >> 4)) {
      *(byte *)(puVar7 + 1) = *(byte *)(puVar7 + 1) & 0x83 | 4;
    }
    else if (sVar5 + 1 ==
             (int)((short)((ushort)((uint)((int)*(short *)((int)puVar6 + 2) << 0x14) >> 0x10) |
                          (ushort)(*(short *)((int)puVar6 + 2) >> 0xf) >> 0xc) >> 4)) {
      *(byte *)(puVar7 + 1) = *(byte *)(puVar7 + 1) & 0x83 | 0x14;
    }
    else if ((short)((short)((uint)*puVar7 >> 8) >> 4) + 1 ==
             (int)(short)((short)((uint)*puVar6 >> 8) >> 4)) {
      *(byte *)(puVar7 + 1) = *(byte *)(puVar7 + 1) & 0x83 | 0xc;
    }
    else {
      *(byte *)(puVar7 + 1) = *(byte *)(puVar7 + 1) & 0x83 | 0x1c;
    }
    .debug::_HandleMove__14TActiveMonsterFsssss(param_1,param_2,param_3,param_4,param_5,param_6);
  }
  return;
}


// ==== .CanMove__13TCrawlMonsterFRsRsRsRs @ 1004a13c ====
// CyDecompAt: created, body 1004a13c-1004a323

undefined4
_CanMove__13TCrawlMonsterFRsRsRsRs
          (int param_1,short *param_2,short *param_3,short *param_4,short *param_5)

{
  bool bVar1;
  char cVar3;
  undefined4 uVar2;
  short sVar4;
  
  if ((*param_4 != 0) && (*param_5 != 0)) {
    *param_5 = 0;
  }
  bVar1 = false;
  sVar4 = 0;
  do {
    if (*(short *)(param_1 + 0x58) <= sVar4) {
LAB_1004a1e8:
      if (bVar1) {
        *param_2 = *param_2 + *param_4;
        *param_3 = *param_3 + *param_5;
      }
      else {
        cVar3 = .debug::_CanMove__14TActiveMonsterFRsRsRsRs(param_1,param_2,param_3,param_4,param_5)
        ;
        if (cVar3 == '\0') {
          return 0;
        }
      }
      if (*(short *)(param_1 + 0x58) == 1) {
        uVar2 = 1;
      }
      else {
        sVar4 = *(short *)(param_1 + 0xc);
        if (sVar4 == 2) {
          uVar2 = 0;
          if ((*param_4 != 0) || (*param_5 != -1)) {
            uVar2 = 1;
          }
        }
        else {
          if (sVar4 < 2) {
            if (sVar4 == 0) {
              if ((*param_4 == 0) && (*param_5 == 1)) {
                return 0;
              }
              return 1;
            }
            if (-1 < sVar4) {
              if ((*param_4 == -1) && (*param_5 == 0)) {
                return 0;
              }
              return 1;
            }
          }
          else if (sVar4 < 4) {
            if ((*param_4 == 1) && (*param_5 == 0)) {
              return 0;
            }
            return 1;
          }
          uVar2 = 0;
        }
      }
      return uVar2;
    }
    if ((**(uint **)(param_1 + sVar4 * 4 + 0x5c) & 0xffffff) ==
        (((int)*param_2 + (int)*param_4) * 0x1000 | (int)*param_3 + (int)*param_5)) {
      bVar1 = true;
      goto LAB_1004a1e8;
    }
    sVar4 = sVar4 + 1;
  } while( true );
}


// ==== .CanFace__14TActiveMonsterFQ28TGameSys10EDirection @ 1004a358 ====
// CyDecompAt: created, body 1004a358-1004a35f

undefined4 _CanFace__14TActiveMonsterFQ28TGameSys10EDirection(void)

{
  return 1;
}


// ==== .CanFace__13TCrawlMonsterFQ28TGameSys10EDirection @ 1004a3a4 ====
// CyDecompAt: created, body 1004a3a4-1004a3ab

undefined4 _CanFace__13TCrawlMonsterFQ28TGameSys10EDirection(void)

{
  return 0;
}


// ==== .AdjustAspect__14TActiveMonsterFss @ 1004acc8 ====
// CyDecompAt: created, body 1004acc8-1004aee7

void _AdjustAspect__14TActiveMonsterFss(int *param_1,ushort param_2,undefined2 param_3)

{
  undefined4 uStack_28;
  uint auStack_24 [4];
  
  *(undefined2 *)(param_1 + 3) = param_3;
  if (((char)DAT_100d3e20 < '\0') && ((DAT_100d3e20 >> 1 & 1) != 0)) {
    param_2 = *(byte *)(*param_1 + 0x18) + 1;
  }
  *(ushort *)(param_1[4] + 4) =
       *(ushort *)(*param_1 + 0x14) & 0x3ff | *(ushort *)(param_1[4] + 4) & 0xfc00;
  .debug::___ct__5VAddrFcUsUs(&uStack_28,4,0,*(undefined2 *)(param_1 + 2));
  .debug::_GetProperty__7TInterpFs5VAddrs(auStack_24,0x37,uStack_28,0);
  switch((int)(auStack_24[0] << 4 | auStack_24[0] >> 0x1c) >> 4) {
  case 0:
  case 1:
    *(ushort *)((int)param_1 + 10) = param_2 & 1;
    *(byte *)(param_1[4] + 4) =
         (((byte)*(undefined2 *)((int)param_1 + 10) & 1) + (char)((int)*(short *)(param_1 + 3) << 1)
         ) * '\x04' & 0x7c | *(byte *)(param_1[4] + 4) & 0x83;
    break;
  default:
    *(ushort *)((int)param_1 + 10) = param_2;
    *(byte *)(param_1[4] + 4) = *(byte *)(param_1[4] + 4) & 0x83;
    break;
  case 3:
    *(undefined2 *)((int)param_1 + 10) = 0;
    *(byte *)(param_1[4] + 4) =
         (byte)(((int)*(short *)(param_1 + 3) & 0xffU) << 2) & 0x7c |
         *(byte *)(param_1[4] + 4) & 0x83;
    break;
  case 4:
    *(ushort *)((int)param_1 + 10) = param_2 & 3;
    if (*(short *)((int)param_1 + 10) == 3) {
      *(byte *)(param_1[4] + 4) =
           ((char)((int)*(short *)(param_1 + 3) << 2) + '\x01') * '\x04' & 0x7cU |
           *(byte *)(param_1[4] + 4) & 0x83;
    }
    else {
      *(byte *)(param_1[4] + 4) =
           (((byte)*(undefined2 *)((int)param_1 + 10) & 3) +
           (char)((int)*(short *)(param_1 + 3) << 2)) * '\x04' & 0x7c |
           *(byte *)(param_1[4] + 4) & 0x83;
    }
    break;
  case 7:
    *(ushort *)((int)param_1 + 10) = param_2 & 1;
    *(byte *)(param_1[4] + 4) =
         (((byte)((int)*(short *)((int)param_1 + 10) << 2) & 4) +
         (char)((int)*(short *)(param_1 + 3) << 3) + '\x03') * '\x04' & 0x7c |
         *(byte *)(param_1[4] + 4) & 0x83;
    break;
  case 9:
    *(byte *)(param_1[4] + 4) =
         (byte)((int)*(short *)(param_1 + 3) << 3) & 0x7c | *(byte *)(param_1[4] + 4) & 0x83;
    break;
  case 10:
    *(ushort *)((int)param_1 + 10) = param_2 & 1;
    *(byte *)(param_1[4] + 4) =
         (((byte)*(undefined2 *)((int)param_1 + 10) & 1) + (char)((int)*(short *)(param_1 + 3) << 1)
         ) * '\x04' & 0x7c | *(byte *)(param_1[4] + 4) & 0x83;
  }
  return;
}


// ==== .DoMove__14TActiveMonsterFss @ 1004b8e8 ====
// CyDecompAt: created, body 1004b8e8-1004d6d3

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 _DoMove__14TActiveMonsterFss(int *param_1,short param_2,short param_3)

{
  undefined1 uVar1;
  byte bVar2;
  bool bVar3;
  undefined *puVar4;
  undefined *puVar5;
  undefined *puVar6;
  undefined4 *puVar7;
  int iVar8;
  short sVar9;
  short sVar10;
  char cVar11;
  uint uVar12;
  short sVar13;
  uint uVar14;
  undefined4 uVar15;
  short sVar16;
  int iVar17;
  undefined1 auStack_178 [4];
  int iStack_174;
  int iStack_170;
  int iStack_16c;
  undefined4 *puStack_168;
  undefined4 *puStack_164;
  short sStack_160;
  short sStack_15e;
  int iStack_15c;
  undefined4 *puStack_158;
  int iStack_154;
  int iStack_150;
  undefined4 *puStack_14c;
  int iStack_148;
  int iStack_138;
  undefined4 *puStack_134;
  int iStack_130;
  undefined4 *puStack_12c;
  int iStack_128;
  undefined4 *puStack_124;
  int iStack_120;
  undefined4 *puStack_11c;
  undefined1 auStack_118 [4];
  int iStack_114;
  undefined1 auStack_110 [4];
  int iStack_10c;
  undefined1 auStack_108 [4];
  int iStack_104;
  undefined2 uStack_100;
  undefined1 uStack_fe;
  undefined *puStack_fc;
  ushort uStack_f8;
  undefined *puStack_f4;
  ushort uStack_f0;
  undefined *puStack_ec;
  int *piStack_e8;
  int iStack_e4;
  undefined4 *puStack_e0;
  int iStack_dc;
  undefined4 *puStack_d8;
  int iStack_d4;
  undefined4 *puStack_d0;
  int iStack_cc;
  undefined4 *puStack_c8;
  int iStack_c4;
  undefined4 *puStack_c0;
  char cStack_bc;
  char cStack_bb;
  char cStack_ba;
  char cStack_b9;
  undefined4 uStack_b8;
  int iStack_b4;
  undefined4 uStack_b0;
  int iStack_ac;
  int *piStack_a8;
  int iStack_a4;
  int iStack_a0;
  undefined4 *puStack_9c;
  undefined4 *puStack_98;
  undefined4 uStack_94;
  short sStack_90;
  short sStack_8e;
  short sStack_8c;
  short sStack_8a;
  short sStack_88;
  short sStack_86;
  int iStack_84;
  int *piStack_80;
  char cStack_7c;
  char cStack_7b;
  char cStack_7a;
  ushort uStack_78;
  short sStack_76;
  short sStack_74;
  short sStack_72;
  short sStack_70;
  undefined4 *puStack_6c;
  undefined4 *puStack_68;
  char cStack_64;
  int iStack_60;
  short sStack_5c;
  short sStack_5a;
  short sStack_58;
  
  puVar5 = PTR_DAT_100cdbf0;
  puVar4 = PTR_DAT_100cdbe4;
  uVar15 = 0;
  uVar12 = *param_1 - (int)PTR_DAT_100cdbf0;
  sStack_58 = (short)((int)uVar12 >> 5) + (ushort)((int)uVar12 < 0 && (uVar12 & 0x1f) != 0);
  cStack_b9 = '\x01' - ((*(ushort *)(PTR_DAT_100cdbf0 + sStack_58 * 0x20 + 6) & 0x20) == 0);
  if (cStack_b9 != '\0') {
    uVar15 = .debug::_DoRetreat__14TActiveMonsterFv(param_1);
    return uVar15;
  }
  cStack_ba = '\x01' - ((*(ushort *)(PTR_DAT_100cdbf0 + sStack_58 * 0x20 + 6) & 0x40) == 0);
  if ((cStack_ba != '\0') ||
     (cStack_bb = '\x01' - ((*(ushort *)(PTR_DAT_100cdbf0 + sStack_58 * 0x20 + 6) & 0x4000) == 0),
     cStack_bb != '\0')) {
    *(undefined1 *)(*param_1 + 0x12) = 0x14;
    return 0;
  }
  cStack_bc = -(((*(ushort *)(PTR_DAT_100cdbf0 + sStack_58 * 0x20 + 6) & 0x2000) == 0) + -1);
  if ((cStack_bc != '\0') && (uVar12 = .glue::Random(), (uVar12 & 3) != 0)) {
    *(undefined1 *)(*param_1 + 0x12) = 0xc;
    puStack_c0 = (undefined4 *)param_1[4];
    iStack_c4 = param_1[4];
    sStack_5a = (short)((uint)*puStack_c0 >> 8) >> 4;
    sStack_5c = (short)((ushort)((uint)((int)*(short *)(iStack_c4 + 2) << 0x14) >> 0x10) |
                       (ushort)(*(short *)(iStack_c4 + 2) >> 0xf) >> 0xc) >> 4;
    uVar12 = .glue::Random();
    if ((uVar12 & 1) == 0) {
      sStack_5a = sStack_5a + 1;
    }
    else {
      sStack_5a = sStack_5a + -1;
    }
    uVar12 = .glue::Random();
    if ((uVar12 & 1) == 0) {
      sStack_5c = sStack_5c + 1;
    }
    else {
      sStack_5c = sStack_5c + -1;
    }
    uVar15 = .debug::_GoTowards__14TActiveMonsterFss(param_1,(int)sStack_5a,(int)sStack_5c);
    return uVar15;
  }
  if (param_1[0xb] != 0) {
    iStack_a4 = param_1[0xd];
    cStack_64 = '\0';
    iStack_60 = iStack_a4;
    switch(*(undefined1 *)(iStack_a4 + 8)) {
    case 0xa0:
      puStack_c8 = (undefined4 *)param_1[4];
      if ((*(short *)(iStack_a4 + 10) == (short)((short)((uint)*puStack_c8 >> 8) >> 4)) &&
         (iStack_cc = param_1[4],
         *(short *)(iStack_a4 + 0xc) ==
         (short)((ushort)((uint)((int)*(short *)(iStack_cc + 2) << 0x14) >> 0x10) |
                (ushort)(*(short *)(iStack_cc + 2) >> 0xf) >> 0xc) >> 4)) {
        cStack_64 = '\x01';
      }
      break;
    case 0xa1:
      puStack_d0 = (undefined4 *)param_1[4];
      puStack_68 = (undefined4 *)(*(int *)PTR_DAT_100cdc44 + *(short *)(iStack_a4 + 10) * 0x10);
      if (((short)((short)((uint)*puStack_68 >> 8) >> 4) ==
           (short)((short)((uint)*puStack_d0 >> 8) >> 4)) &&
         (iStack_d4 = param_1[4],
         (short)((ushort)((uint)((int)*(short *)((int)puStack_68 + 2) << 0x14) >> 0x10) |
                (ushort)(*(short *)((int)puStack_68 + 2) >> 0xf) >> 0xc) >> 4 ==
         (short)((ushort)((uint)((int)*(short *)(iStack_d4 + 2) << 0x14) >> 0x10) |
                (ushort)(*(short *)(iStack_d4 + 2) >> 0xf) >> 0xc) >> 4)) {
        cStack_64 = '\x01';
      }
      break;
    case 0xa2:
      puStack_d8 = (undefined4 *)param_1[4];
      puStack_6c = (undefined4 *)(*(int *)PTR_DAT_100cdc44 + *(short *)(iStack_a4 + 10) * 0x10);
      iStack_dc = param_1[4];
      sStack_72 = ((short)((ushort)((uint)((int)*(short *)((int)puStack_6c + 2) << 0x14) >> 0x10) |
                          (ushort)(*(short *)((int)puStack_6c + 2) >> 0xf) >> 0xc) >> 4) -
                  ((short)((ushort)((uint)((int)*(short *)(iStack_dc + 2) << 0x14) >> 0x10) |
                          (ushort)(*(short *)(iStack_dc + 2) >> 0xf) >> 0xc) >> 4);
      sStack_70 = ((short)((uint)*puStack_6c >> 8) >> 4) - ((short)((uint)*puStack_d8 >> 8) >> 4);
      if ((int)sStack_70 * (int)sStack_70 + (int)sStack_72 * (int)sStack_72 < 2) {
        *(undefined1 *)(param_1 + 0x13) = 0;
        cStack_64 = '\x01';
      }
      break;
    case 0xa3:
      puStack_e0 = (undefined4 *)param_1[4];
      iStack_e4 = param_1[4];
      sStack_74 = *(short *)(iStack_a4 + 10) - ((short)((uint)*puStack_e0 >> 8) >> 4);
      sStack_76 = *(short *)(iStack_a4 + 0xc) -
                  ((short)((ushort)((uint)((int)*(short *)(iStack_e4 + 2) << 0x14) >> 0x10) |
                          (ushort)(*(short *)(iStack_e4 + 2) >> 0xf) >> 0xc) >> 4);
      if ((int)sStack_74 * (int)sStack_74 + (int)sStack_76 * (int)sStack_76 < 2) {
        *(undefined1 *)(param_1 + 0x13) = 0;
        cStack_64 = '\x01';
      }
      break;
    case 0xa4:
      uVar12 = (uint)*(short *)(iStack_a4 + 10);
      if (((1 << ((int)*(short *)(iStack_a4 + 10) & 0x1fU) &
           *(uint *)(PTR_DAT_100cdbc0 +
                    (((int)uVar12 >> 5) + (uint)((int)uVar12 < 0 && (uVar12 & 0x1f) != 0)) * 4)) !=
           0) && (cStack_64 = '\x01', *(short *)(iStack_a4 + 0xc) == 0)) {
        uVar12 = (uint)*(short *)(iStack_a4 + 10);
        iVar8 = (((int)uVar12 >> 5) + (uint)((int)uVar12 < 0 && (uVar12 & 0x1f) != 0)) * 4;
        *(uint *)(PTR_DAT_100cdbc0 + iVar8) =
             *(uint *)(PTR_DAT_100cdbc0 + iVar8) & ~(1 << ((int)*(short *)(iStack_a4 + 10) & 0x1fU))
        ;
      }
      break;
    case 0xa5:
      if (*(short *)(iStack_a4 + 0xc) == 0) {
        uVar12 = (uint)*(short *)(iStack_a4 + 10);
        iVar8 = (((int)uVar12 >> 5) + (uint)((int)uVar12 < 0 && (uVar12 & 0x1f) != 0)) * 4;
        *(uint *)(PTR_DAT_100cdbc0 + iVar8) =
             *(uint *)(PTR_DAT_100cdbc0 + iVar8) & ~(1 << ((int)*(short *)(iStack_a4 + 10) & 0x1fU))
        ;
      }
      else {
        uVar12 = (uint)*(short *)(iStack_a4 + 10);
        iVar8 = (((int)uVar12 >> 5) + (uint)((int)uVar12 < 0 && (uVar12 & 0x1f) != 0)) * 4;
        *(uint *)(PTR_DAT_100cdbc0 + iVar8) =
             *(uint *)(PTR_DAT_100cdbc0 + iVar8) | 1 << ((int)*(short *)(iStack_a4 + 10) & 0x1fU);
      }
      cStack_64 = '\x01';
      break;
    case 0xa6:
      piStack_e8 = (int *)(iStack_a4 + 0x10);
      if (*piStack_e8 == *(int *)PTR_DAT_100cddec) {
        puStack_ec = puVar5 + *(short *)(iStack_a4 + 10) * 0x20;
        uStack_f0 = (ushort)(1 << ((int)*(short *)(iStack_a4 + 0xc) & 0x3fU));
        if (((byte)puStack_ec[8] & uStack_f0) != 0) {
          cStack_64 = '\x01';
        }
      }
      else {
        puStack_f4 = puVar5 + *(short *)(iStack_a4 + 10) * 0x20;
        uStack_f8 = (ushort)(1 << ((int)*(short *)(iStack_a4 + 0xc) & 0x3fU));
        if (((byte)puStack_f4[8] & uStack_f8) == 0) {
          cStack_64 = '\x01';
        }
      }
      break;
    case 0xa7:
      iVar8 = 1 << ((int)*(short *)(iStack_a4 + 0xc) & 0x3fU);
      uStack_100 = (undefined2)iVar8;
      cStack_64 = '\x01';
      uStack_fe = *(int *)PTR_DAT_100cddec == *(int *)(iStack_a4 + 0x10);
      puStack_fc = puVar5 + *(short *)(iStack_a4 + 10) * 0x20;
      bVar2 = (byte)iVar8;
      if ((bool)uStack_fe) {
        puStack_fc[8] = puStack_fc[8] | bVar2;
      }
      else {
        puStack_fc[8] = puStack_fc[8] & ~bVar2;
      }
      break;
    case 0xa8:
      for (sVar9 = *(short *)(iStack_a4 + 0xc); 0 < sVar9; sVar9 = sVar9 + -1) {
        iStack_104 = param_1[0xd];
        .debug::
        _erase__Q23std66list<18ActivityQueueEntry,Q23std31allocator<18ActivityQueueEntry>>FQ33std66list<18ActivityQueueEntry,Q23std31allocator<18ActivityQueueEntry>>8iterator
                  (auStack_108,param_1 + 0xb,iStack_104);
      }
      break;
    case 0xa9:
      cVar11 = .debug::_EvalCondition__FUcUc
                         ((uint)(int)*(short *)(iStack_a4 + 10) >> 8 & 0xff,
                          *(ushort *)(iStack_a4 + 10) & 0xff);
      if (cVar11 != '\0') {
        for (sVar9 = *(short *)(iStack_60 + 0xc); 0 < sVar9; sVar9 = sVar9 + -1) {
          iStack_10c = param_1[0xd];
          .debug::
          _erase__Q23std66list<18ActivityQueueEntry,Q23std31allocator<18ActivityQueueEntry>>FQ33std66list<18ActivityQueueEntry,Q23std31allocator<18ActivityQueueEntry>>8iterator
                    (auStack_110,param_1 + 0xb,iStack_10c);
        }
      }
      break;
    case 0xaa:
      cStack_64 = '\0';
    }
    if (cStack_64 != '\0') {
      iStack_114 = param_1[0xd];
      .debug::
      _erase__Q23std66list<18ActivityQueueEntry,Q23std31allocator<18ActivityQueueEntry>>FQ33std66list<18ActivityQueueEntry,Q23std31allocator<18ActivityQueueEntry>>8iterator
                (auStack_118,param_1 + 0xb,iStack_114);
    }
  }
  if (*(char *)(param_1 + 0x13) != '\0') {
    puStack_11c = (undefined4 *)param_1[4];
    if ((*(short *)((int)param_1 + 0x4e) == (short)((short)((uint)*puStack_11c >> 8) >> 4)) &&
       (iStack_120 = param_1[4],
       *(short *)(param_1 + 0x14) ==
       (short)((ushort)((uint)((int)*(short *)(iStack_120 + 2) << 0x14) >> 0x10) |
              (ushort)(*(short *)(iStack_120 + 2) >> 0xf) >> 0xc) >> 4)) {
      *(undefined1 *)(param_1 + 0x13) = 0;
    }
    else {
      cVar11 = .debug::_IsVisibleAbs__7TViewerFss
                         (*(undefined4 *)PTR_DAT_100cdbb8,(int)*(short *)((int)param_1 + 0x4e),
                          (int)*(short *)(param_1 + 0x14));
      if (cVar11 == '\0') {
        puStack_124 = (undefined4 *)param_1[4];
        iStack_128 = param_1[4];
        cVar11 = .debug::_IsVisibleAbs__7TViewerFss
                           (*(undefined4 *)PTR_DAT_100cdbb8,
                            (int)(short)((short)((uint)*puStack_124 >> 8) >> 4),
                            (int)((int)*(short *)(iStack_128 + 2) << 0x14 |
                                 (uint)(int)*(short *)(iStack_128 + 2) >> 0xc) >> 0x14);
        if (cVar11 == '\0') {
          *(uint *)param_1[4] =
               ((int)*(short *)((int)param_1 + 0x4e) & 0xfffU) << 0xc |
               (int)*(short *)(param_1 + 0x14) & 0xfffU | *(uint *)param_1[4] & 0xff000000;
          *(undefined1 *)(*param_1 + 0x12) = 0x14;
          *(undefined1 *)(param_1 + 0x13) = 0;
          return 1;
        }
      }
      puStack_12c = (undefined4 *)param_1[4];
      if ((*(short *)((int)param_1 + 0x52) == (short)((short)((uint)*puStack_12c >> 8) >> 4)) &&
         (iStack_130 = param_1[4],
         *(short *)(param_1 + 0x15) ==
         (short)((ushort)((uint)((int)*(short *)(iStack_130 + 2) << 0x14) >> 0x10) |
                (ushort)(*(short *)(iStack_130 + 2) >> 0xf) >> 0xc) >> 4)) {
        sVar9 = .debug::_FindWaypoint__11TPathFinderFP14TActiveMonsterssssRsRs
                          (param_1,(int)*(short *)((int)param_1 + 0x52),
                           (int)*(short *)(param_1 + 0x15),(int)*(short *)((int)param_1 + 0x4e),
                           (int)*(short *)(param_1 + 0x14),(int)param_1 + 0x52,param_1 + 0x15);
        *(char *)(param_1 + 0x13) = '\x01' - (sVar9 == 0x7fff);
        puStack_134 = (undefined4 *)param_1[4];
        if ((*(short *)((int)param_1 + 0x52) == (short)((short)((uint)*puStack_134 >> 8) >> 4)) &&
           (iStack_138 = param_1[4],
           *(short *)(param_1 + 0x15) ==
           (short)((ushort)((uint)((int)*(short *)(iStack_138 + 2) << 0x14) >> 0x10) |
                  (ushort)(*(short *)(iStack_138 + 2) >> 0xf) >> 0xc) >> 4)) {
          *(undefined1 *)(param_1 + 0x13) = 0;
        }
      }
      if (*(char *)(param_1 + 0x13) != '\0') {
        *(undefined1 *)(*param_1 + 0x12) = 8;
        uVar15 = .debug::_GoTowards__14TActiveMonsterFss
                           (param_1,(int)*(short *)((int)param_1 + 0x52),
                            (int)*(short *)(param_1 + 0x15));
        return uVar15;
      }
    }
  }
  cStack_7a = '\0';
  piStack_a8 = param_1 + 0xc;
  cStack_7b = '\0';
  uStack_78 = (ushort)*(byte *)(*param_1 + 0x16);
  cStack_7c = '\0';
  if (param_1[0xb] == 0) {
    uVar12 = *param_1 - (int)puVar5;
    piStack_80 = piStack_a8;
    .debug::___ct__5VAddrFcUsUs
              (&uStack_b0,4,0x40,
               (short)((int)uVar12 >> 5) + (ushort)((int)uVar12 < 0 && (uVar12 & 0x1f) != 0));
    .debug::_DoInterp__7TInterpFs5VAddr(&iStack_ac,0x20,uStack_b0);
    iStack_84 = iStack_ac;
    if (iStack_ac == *(int *)PTR_DAT_100cddec) {
      return 1;
    }
  }
  else {
    piStack_80 = (int *)param_1[0xd];
    cStack_7c = '\x01';
    uStack_78 = (ushort)*(byte *)(piStack_80 + 2);
  }
  puVar7 = _DAT_100cdcd0;
  puVar6 = PTR_DAT_100cdc44;
  switch(uStack_78) {
  case 0:
  case 0xc:
  case 0xe:
  case 0x70:
    *(undefined1 *)(*param_1 + 0x12) = 8;
    break;
  case 1:
  case 0x11:
    if ((*(short *)(param_1 + 2) != *(short *)PTR_DAT_100cdbec) && (*(int *)PTR_DAT_100cdbe8 == 1))
    {
      sStack_86 = 0;
      sVar9 = 0;
      while ((sVar9 < *(short *)PTR_DAT_100cdb9c &&
             (*(short *)(param_1 + 2) != *(short *)(puVar4 + sVar9 * 2)))) {
        if (*(short *)PTR_DAT_100cdbec != *(short *)(puVar4 + sVar9 * 2)) {
          sStack_86 = sStack_86 + 1;
        }
        sVar9 = sVar9 + 1;
      }
      sStack_88 = (short)((int)(*(byte *)(*(int *)PTR_DAT_100cdc44 +
                                         *(short *)PTR_DAT_100cdbec * 0x10 + 4) >> 2 & 0x1f) >> 2);
      iVar8 = .debug::_GetCharacter__14TActiveMonsterFs((int)*(short *)PTR_DAT_100cdbec);
      *(char *)(*param_1 + 0x12) = (char)*(undefined2 *)(iVar8 + 0x3e);
      puStack_14c = (undefined4 *)param_1[4];
      sStack_8a = (short)((uint)*puStack_14c >> 8) >> 4;
      iStack_150 = param_1[4];
      sStack_8c = (short)((ushort)((uint)((int)*(short *)(iStack_150 + 2) << 0x14) >> 0x10) |
                         (ushort)(*(short *)(iStack_150 + 2) >> 0xf) >> 0xc) >> 4;
      sVar9 = param_2 + (short)*(undefined4 *)(&DAT_100d565c + ((int)sStack_86 + sStack_88 * 8) * 4)
      ;
      sStack_8e = sVar9 - sStack_8a;
      sVar16 = param_3 + (short)*(undefined4 *)
                                 (&DAT_100d56dc + ((int)sStack_86 + sStack_88 * 8) * 4);
      sStack_90 = sVar16 - sStack_8c;
      if ((sStack_8e == 0) && (sStack_90 == 0)) {
        return 0;
      }
      if (((-2 < sStack_8e) && (((sStack_8e < 2 && (-2 < sStack_90)) && (sStack_90 < 2)))) &&
         (((cVar11 = FUN_100c50e8(param_1,&sStack_8a,&sStack_8c,&sStack_8e,&sStack_90),
           cVar11 != '\0' && (sStack_8a == sVar9)) && (sStack_8c == sVar16)))) {
        uVar15 = .debug::_DxDyToSubmove__14TActiveMonsterFss((int)sStack_8e,(int)sStack_90);
        FUN_100c50e8(param_1,(int)sStack_8a,(int)sStack_8c,(int)sStack_8e,(int)sStack_90,uVar15);
        return 1;
      }
      sStack_8e = (param_2 +
                  (short)*(undefined4 *)(&DAT_100d565c + ((int)sStack_86 + sStack_88 * 8) * 4)) -
                  sStack_8a;
      sStack_90 = (param_3 +
                  (short)*(undefined4 *)(&DAT_100d56dc + ((int)sStack_86 + sStack_88 * 8) * 4)) -
                  sStack_8c;
      if (((sStack_8e == 0) && ((sStack_90 == 1 || (sStack_90 == -1)))) ||
         ((sStack_90 == 0 && ((sStack_8e == 1 || (sStack_8e == -1)))))) {
        uVar15 = .debug::_DxDyToFace__14TActiveMonsterFss((int)sStack_8e,(int)sStack_90);
        FUN_100c50e8(param_1,1,uVar15);
        return 0;
      }
      sVar9 = 1;
      while ((sVar9 < 0x20 && (*(short *)(sVar9 * 4 + 0x100d54c2) != -1))) {
        sStack_8a = (short)((uint)*(undefined4 *)param_1[4] >> 8) >> 4;
        iStack_154 = param_1[4];
        sStack_8c = (short)((ushort)((uint)((int)*(short *)(iStack_154 + 2) << 0x14) >> 0x10) |
                           (ushort)(*(short *)(iStack_154 + 2) >> 0xf) >> 0xc) >> 4;
        sVar16 = *(short *)(sVar9 * 4 + 0x100d54c2);
        sStack_8e = sVar16 - sStack_8a;
        sVar10 = *(short *)(&DAT_100d54c0 + sVar9 * 4);
        sStack_90 = sVar10 - sStack_8c;
        uVar12 = (int)*(short *)(param_1 + 3) + 2;
        sVar13 = (short)uVar12 +
                 (short)(((int)uVar12 >> 2) + (uint)((int)uVar12 < 0 && (uVar12 & 3) != 0)) * -4;
        if (((sStack_8e == *(short *)(&DAT_100d575c + sVar13 * 2)) &&
            (sStack_90 == *(short *)(&DAT_100d5766 + sVar13 * 2))) ||
           ((sStack_8e == 0 && (sStack_90 == 0)))) break;
        if ((-2 < sStack_8e) &&
           (((((sStack_8e < 2 && (-2 < sStack_90)) && (sStack_90 < 2)) &&
             ((cVar11 = FUN_100c50e8(param_1,&sStack_8a,&sStack_8c,&sStack_8e,&sStack_90),
              cVar11 != '\0' && (sStack_8a == sVar16)))) && (sStack_8c == sVar10)))) {
          uVar15 = .debug::_DxDyToSubmove__14TActiveMonsterFss((int)sStack_8e,(int)sStack_90);
          FUN_100c50e8(param_1,(int)sStack_8a,(int)sStack_8c,(int)sStack_8e,(int)sStack_90,uVar15);
          return 1;
        }
        sVar9 = sVar9 + 1;
      }
      iVar8 = (int)param_2 + *(int *)(&DAT_100d565c + ((int)sStack_86 + sStack_88 * 8) * 4);
      sVar16 = (short)iVar8;
      iVar17 = (int)param_3 + *(int *)(&DAT_100d56dc + ((int)sStack_86 + sStack_88 * 8) * 4);
      sStack_8e = sVar16 - sStack_8a;
      sVar9 = (short)iVar17;
      sStack_90 = sVar9 - sStack_8c;
      puStack_158 = (undefined4 *)param_1[4];
      sStack_8a = (short)((uint)*puStack_158 >> 8) >> 4;
      iStack_15c = param_1[4];
      sStack_8c = (short)((ushort)((uint)((int)*(short *)(iStack_15c + 2) << 0x14) >> 0x10) |
                         (ushort)(*(short *)(iStack_15c + 2) >> 0xf) >> 0xc) >> 4;
      if (((sStack_8a == sVar16) && (sStack_8c == sVar9)) && (uStack_78 == 0x11)) {
        *(undefined1 *)(*param_1 + 0x16) = 1;
        uStack_78 = 1;
      }
      if (uStack_78 == 0x11) {
        sVar10 = .debug::_FindPath__11TPathFinderFP14TActiveMonsterssss
                           (PTR_DAT_100cdbb4,param_1,(int)sStack_8a,(int)sStack_8c,iVar8,iVar17);
        if (sVar10 == 0x7fff) {
          *(undefined1 *)(*param_1 + 0x16) = 1;
          uVar15 = .debug::_GoTowards__14TActiveMonsterFss(param_1,iVar8,iVar17);
          return uVar15;
        }
        .debug::_FindFirstStep__11TPathFinderFRsRs(PTR_DAT_100cdbb4,&sStack_8e,&sStack_90);
        cVar11 = FUN_100c50e8(param_1,&sStack_8a,&sStack_8c,&sStack_8e,&sStack_90);
        if (cVar11 != '\0') {
          uVar15 = .debug::_DxDyToSubmove__14TActiveMonsterFss((int)sStack_8e,(int)sStack_90);
          FUN_100c50e8(param_1,(int)sStack_8a,(int)sStack_8c,(int)sStack_8e,(int)sStack_90,uVar15);
          return 1;
        }
        *(undefined1 *)(*param_1 + 0x16) = 1;
        uVar15 = .debug::_DxDyToFace__14TActiveMonsterFss((int)sStack_8e,(int)sStack_90);
        FUN_100c50e8(param_1,1,uVar15);
      }
      if (sStack_8a == sVar16) {
        if (sStack_8c < sVar9) {
          uStack_94 = 4;
        }
        else {
          uStack_94 = 0;
        }
      }
      else if (sStack_8a < sVar16) {
        if (sStack_8c < sVar9) {
          uStack_94 = 3;
        }
        else if (sStack_8c == sVar9) {
          uStack_94 = 2;
        }
        else {
          uStack_94 = 1;
        }
      }
      else if (sStack_8c < sVar9) {
        uStack_94 = 5;
      }
      else if (sStack_8c == sVar9) {
        uStack_94 = 6;
      }
      else {
        uStack_94 = 7;
      }
      uVar15 = .debug::_GoTowards__14TActiveMonsterFss(param_1,iVar8,iVar17);
      return uVar15;
    }
    break;
  case 2:
  case 0xa5:
  case 0xa7:
  case 0xa8:
  case 0xa9:
    break;
  case 3:
    cVar11 = .debug::_PerformAI__FP14TActiveMonsters(param_1,0xd1);
    if (cVar11 == '\0') {
      iVar8 = .debug::_FindStrongest__14TActiveMonsterFUc(param_1,0);
      param_1[7] = iVar8;
      if (param_1[7] == 0) {
        iVar8 = .debug::_FindStrongest__14TActiveMonsterFUc(param_1,1);
        param_1[7] = iVar8;
      }
      uVar15 = .debug::_DoAttack__14TActiveMonsterFv(param_1);
    }
    break;
  case 4:
    cVar11 = .debug::_PerformAI__FP14TActiveMonsters(param_1,0xd4);
    if (cVar11 == '\0') {
      uVar15 = .debug::_DoDefend__14TActiveMonsterFv(param_1);
    }
    break;
  case 5:
    cVar11 = .debug::_PerformAI__FP14TActiveMonsters(param_1,0xd2);
    if (cVar11 == '\0') {
      iVar8 = .debug::_FindWeakest__14TActiveMonsterFUc(param_1,0);
      param_1[7] = iVar8;
      if (param_1[7] == 0) {
        iVar8 = .debug::_FindWeakest__14TActiveMonsterFUc(param_1,1);
        param_1[7] = iVar8;
      }
      uVar15 = .debug::_DoAttack__14TActiveMonsterFv(param_1);
    }
    break;
  case 6:
    cVar11 = .debug::_PerformAI__FP14TActiveMonsters(param_1,0xd3);
    if (cVar11 == '\0') {
      if (param_1[7] == 0) {
        iVar8 = .debug::_FindStrongest__14TActiveMonsterFUc(param_1,0);
        param_1[7] = iVar8;
        if (param_1[7] == 0) {
          iVar8 = .debug::_FindStrongest__14TActiveMonsterFUc(param_1,1);
          param_1[7] = iVar8;
        }
      }
      uVar15 = .debug::_DoAttack__14TActiveMonsterFv(param_1);
    }
    break;
  case 7:
    uVar15 = .debug::_DoRetreat__14TActiveMonsterFv(param_1);
    break;
  case 8:
    cVar11 = .debug::_PerformAI__FP14TActiveMonsters(param_1,0xd0);
    if (cVar11 == '\0') {
      iVar8 = .debug::_FindNearest__14TActiveMonsterFUc(param_1,1);
      param_1[7] = iVar8;
      uVar15 = .debug::_DoAttack__14TActiveMonsterFv(param_1);
    }
    break;
  case 9:
  case 10:
  case 0xb:
    *(undefined1 *)(*param_1 + 0x12) = 0x10;
    uVar15 = .debug::_DoRoam__14TActiveMonsterFv(param_1);
    break;
  case 0xd:
    if (param_1[7] == 0) {
      *(undefined1 *)(*param_1 + 0x16) = 0xc;
      *(undefined1 *)(*param_1 + 0x12) = 8;
    }
    else {
      uVar15 = .debug::_DoAttack__14TActiveMonsterFv(param_1);
    }
    break;
  case 0xf:
    *(undefined1 *)(*param_1 + 0x12) = 0xc;
    uVar15 = .debug::_PaceEW__14TActiveMonsterFv(param_1);
    cStack_7b = '\x01';
    break;
  case 0x10:
    *(undefined1 *)(*param_1 + 0x12) = 0xc;
    uVar15 = .debug::_PaceNS__14TActiveMonsterFv(param_1);
    cStack_7b = '\x01';
    break;
  default:
    if (cStack_7c == '\0') {
      if ((((short)uStack_78 < 0xb0) || (0xcf < (short)uStack_78)) &&
         (((short)uStack_78 < 0xd0 || (0xff < (short)uStack_78)))) {
        if (*(byte *)(*param_1 + 0x16) < 0x80) {
          .debug::_myprintf__13TStatusWindowFPce
                    (*(undefined4 *)PTR_DAT_100cdb98,PTR_s_Uknown_behavior_for_prop___d_____100ce8c0
                     ,(int)*(short *)(param_1 + 2),*(undefined1 *)(*param_1 + 0x16),
                     *(undefined1 *)(*param_1 + 0x16));
        }
        *(undefined1 *)(*param_1 + 0x12) = 0x14;
      }
      else {
        cVar11 = .debug::_PerformAI__FP14TActiveMonsters(param_1,(int)(short)uStack_78);
        if (cVar11 == '\0') {
          .debug::_myprintf__13TStatusWindowFPce
                    (*(undefined4 *)PTR_DAT_100cdb98,
                     PTR_s_Uknown_combat_AI_for_prop___d_____100ce8c4,(int)*(short *)(param_1 + 2),
                     *(undefined1 *)(*param_1 + 0x16),*(undefined1 *)(*param_1 + 0x16));
          *(undefined1 *)(*param_1 + 0x12) = 0x14;
        }
      }
    }
    else {
      iVar8 = piStack_80[4];
      uVar12 = *param_1 - (int)puVar5;
      sVar9 = *(short *)((int)piStack_80 + 10);
      sVar16 = *(short *)(piStack_80 + 3);
      uVar1 = *(undefined1 *)(piStack_80 + 2);
      .debug::___ct__5VAddrFcUsUs
                (&uStack_b8,4,0x40,
                 (short)((int)uVar12 >> 5) + (ushort)((int)uVar12 < 0 && (uVar12 & 0x1f) != 0));
      .debug::_DoInterp__7TInterpFs5VAddr5VAddr5VAddr5VAddr5VAddr
                (&iStack_b4,0x21,uStack_b8,uVar1,(int)sVar9 & 0xfffffff,(int)sVar16 & 0xfffffff,
                 iVar8);
      iStack_a0 = iStack_b4;
      if (iStack_b4 == *(int *)PTR_DAT_100cddec) {
        cStack_7a = '\x01';
      }
    }
    break;
  case 0x71:
    iStack_148 = *param_1;
    if ((*(byte *)(iStack_148 + 8) & 0x40) == 0) {
      if ((*(ushort *)(param_1[5] + 4) & 0x3ff) == (*(ushort *)(param_1[4] + 4) & 0x3ff)) {
        *(undefined1 *)(*param_1 + 0x16) = *(undefined1 *)(param_1[5] + 6);
      }
      else {
        .debug::_ScheduleOne__FssUc
                  ((int)*(short *)(param_1 + 2),(int)(short)(_DAT_100d3e18 >> 0xc),1);
      }
    }
    else {
      *(undefined1 *)(*param_1 + 0x16) = 1;
    }
  case 0x93:
    *(undefined1 *)(*param_1 + 0x1b) = 0x1e;
    *(undefined1 *)(*param_1 + 0x12) = 0x20;
    break;
  case 0x86:
    *(undefined1 *)(*param_1 + 0x12) = 0x14;
    cStack_7b = '\x01';
    FUN_100c50e8(param_1,1,0);
    break;
  case 0x87:
    *(undefined1 *)(*param_1 + 0x12) = 0x14;
    cStack_7b = '\x01';
    FUN_100c50e8(param_1,1,1);
    break;
  case 0x88:
    *(undefined1 *)(*param_1 + 0x12) = 0x14;
    cStack_7b = '\x01';
    FUN_100c50e8(param_1,1,2);
    break;
  case 0x89:
    *(undefined1 *)(*param_1 + 0x12) = 0x14;
    cStack_7b = '\x01';
    FUN_100c50e8(param_1,1,3);
    break;
  case 0x8a:
    *(undefined1 *)(*param_1 + 0x12) = 0xc;
    cStack_7b = '\x01';
    uVar15 = .debug::_PaceNS__14TActiveMonsterFv(param_1);
    break;
  case 0x8b:
    *(undefined1 *)(*param_1 + 0x12) = 0xc;
    cStack_7b = '\x01';
    uVar15 = .debug::_PaceEW__14TActiveMonsterFv(param_1);
    break;
  case 0x8c:
    *(undefined1 *)(*param_1 + 0x12) = 0x10;
    cStack_7b = '\x01';
    uVar15 = .debug::_PaceNS__14TActiveMonsterFv(param_1);
    break;
  case 0x8d:
    *(undefined1 *)(*param_1 + 0x12) = 0x10;
    cStack_7b = '\x01';
    uVar15 = .debug::_PaceEW__14TActiveMonsterFv(param_1);
    break;
  case 0x8f:
  case 0x97:
    *(undefined1 *)(*param_1 + 0x12) = 0xc;
    cStack_7b = '\x01';
    uVar15 = .debug::_DoRoam__14TActiveMonsterFv(param_1);
    break;
  case 0x90:
    *(undefined1 *)(*param_1 + 0x12) = 0x14;
    cStack_7b = '\x01';
    uVar15 = .debug::_DoRoam__14TActiveMonsterFv(param_1);
    break;
  case 0x94:
    *(undefined1 *)(*param_1 + 0x12) = 0x14;
    cStack_7b = '\x01';
    sVar9 = .glue::Random();
    if ((int)sVar9 % 3 == 0) {
      if (*(short *)(param_1 + 3) == 0) {
        cVar11 = FUN_100c50e8(param_1,4);
        if (cVar11 != '\0') {
          FUN_100c50e8(param_1,1,2);
        }
      }
      else {
        cVar11 = FUN_100c50e8(param_1,0);
        if (cVar11 != '\0') {
          FUN_100c50e8(param_1,1,0);
        }
      }
    }
    else {
      uVar15 = .debug::_PaceNS__14TActiveMonsterFv(param_1);
    }
    break;
  case 0x96:
    if (*(short *)PTR_DAT_100cdbec == 1) {
      bVar3 = false;
      iVar8 = *(int *)PTR_DAT_100cdbb8;
      sStack_15e = ((short)((uint)*(undefined4 *)param_1[4] >> 8) >> 4) - param_2;
      sStack_160 = ((short)((ushort)((uint)((int)*(short *)(param_1[4] + 2) << 0x14) >> 0x10) |
                           (ushort)(*(short *)(param_1[4] + 2) >> 0xf) >> 0xc) >> 4) - param_3;
      if ((((-(int)*(short *)(iVar8 + 2) <= (int)sStack_15e) &&
           (sStack_15e <= *(short *)(iVar8 + 2))) &&
          (-(int)*(short *)(iVar8 + 2) <= (int)sStack_160)) && (sStack_160 <= *(short *)(iVar8 + 2))
         ) {
        uVar14 = (uint)*(short *)(iVar8 + 4);
        uVar12 = (uint)*(short *)(iVar8 + 4);
        if ((*(byte *)((int)sStack_15e +
                      ((int)uVar14 >> 1) + (uint)((int)uVar14 < 0 && (uVar14 & 1) != 0) +
                      (int)*(short *)(iVar8 + 4) *
                      ((int)sStack_160 +
                      ((int)uVar12 >> 1) + (uint)((int)uVar12 < 0 && (uVar12 & 1) != 0)) + iVar8 +
                      0xc0c8) & 3) != 0) {
          bVar3 = true;
        }
      }
      if (bVar3) {
        puStack_164 = (undefined4 *)param_1[4];
        puStack_168 = (undefined4 *)param_1[4];
        iStack_16c = param_1[4];
        iStack_170 = param_1[4];
        if (((int)(short)((short)((uint)*puStack_164 >> 8) >> 4) - (int)param_2) *
            ((int)(short)((short)((uint)*puStack_168 >> 8) >> 4) - (int)param_2) +
            ((int)((short)((ushort)((uint)((int)*(short *)(iStack_16c + 2) << 0x14) >> 0x10) |
                          (ushort)(*(short *)(iStack_16c + 2) >> 0xf) >> 0xc) >> 4) - (int)param_3)
            * ((int)((short)((ushort)((uint)((int)*(short *)(iStack_170 + 2) << 0x14) >> 0x10) |
                            (ushort)(*(short *)(iStack_170 + 2) >> 0xf) >> 0xc) >> 4) - (int)param_3
              ) < 10) {
          *(undefined1 *)(*param_1 + 0x16) = 0x97;
          .debug::_TalkCommand__8TGameSysFs(*puVar7,(int)*(short *)(param_1 + 2));
          break;
        }
      }
    }
    uVar12 = *(uint *)(puVar5 + 0x20);
    uVar15 = *(undefined4 *)(puVar5 + 0x20);
    *(undefined1 *)(*param_1 + 0x12) = 8;
    uVar15 = .debug::_GoTowards__14TActiveMonsterFss
                       (param_1,(ushort)(uVar12 >> 0xc) & 0xfff,(ushort)uVar15 & 0xfff);
    break;
  case 0xa0:
  case 0xa3:
    if ((cStack_7c != '\0') && (*(char *)(param_1 + 0x13) == '\0')) {
      .debug::_SetWaypoint__14TActiveMonsterFss
                (param_1,(int)*(short *)((int)piStack_80 + 10),(int)*(short *)(piStack_80 + 3));
    }
    break;
  case 0xa1:
  case 0xa2:
    if ((cStack_7c != '\0') && (*(char *)(param_1 + 0x13) == '\0')) {
      puStack_98 = (undefined4 *)
                   (*(int *)PTR_DAT_100cdc44 + *(short *)((int)piStack_80 + 10) * 0x10);
      .debug::_SetWaypoint__14TActiveMonsterFss
                (param_1,(int)(short)((short)((uint)*puStack_98 >> 8) >> 4),
                 (int)((int)*(short *)((int)puStack_98 + 2) << 0x14 |
                      (uint)(int)*(short *)((int)puStack_98 + 2) >> 0xc) >> 0x14);
    }
    break;
  case 0xa4:
  case 0xa6:
    *(undefined1 *)(*param_1 + 0x12) = 8;
    break;
  case 0xaa:
    *(undefined1 *)(*param_1 + 0x12) = 8;
    puStack_9c = (undefined4 *)(*(int *)puVar6 + *(short *)((int)piStack_80 + 10) * 0x10);
    .debug::_GoTowards__14TActiveMonsterFss
              (param_1,(int)(short)((short)((uint)*puStack_9c >> 8) >> 4),
               (int)((int)*(short *)((int)puStack_9c + 2) << 0x14 |
                    (uint)(int)*(short *)((int)puStack_9c + 2) >> 0xc) >> 0x14);
    cStack_7a = '\x01';
  }
  if (((cStack_7c != '\0') && (cStack_7b != '\0')) &&
     (*(short *)((int)piStack_80 + 10) = *(short *)((int)piStack_80 + 10) + -1,
     *(short *)((int)piStack_80 + 10) < 1)) {
    cStack_7a = '\x01';
  }
  if (cStack_7a != '\0') {
    iStack_174 = param_1[0xd];
    .debug::
    _erase__Q23std66list<18ActivityQueueEntry,Q23std31allocator<18ActivityQueueEntry>>FQ33std66list<18ActivityQueueEntry,Q23std31allocator<18ActivityQueueEntry>>8iterator
              (auStack_178,param_1 + 0xb,iStack_174);
  }
  return uVar15;
}


// ==== .IsPartOfMonster__13TCrawlMonsterFs @ 1004d7fc ====
// CyDecompAt: created, body 1004d7fc-1004d89b

undefined4 _IsPartOfMonster__13TCrawlMonsterFs(int param_1,undefined4 param_2)

{
  undefined4 uVar1;
  short sVar2;
  
  sVar2 = 0;
  while( true ) {
    if (*(short *)(param_1 + 0x58) <= sVar2) {
      uVar1 = .debug::_IsPartOfMonster__14TActiveMonsterFs(param_1,param_2);
      return uVar1;
    }
    if (*(int *)(param_1 + sVar2 * 4 + 0x5c) == *(int *)PTR_DAT_100cdc44 + (short)param_2 * 0x10)
    break;
    sVar2 = sVar2 + 1;
  }
  return 1;
}


// ==== .IsPartOfMonster__12TOctoMonsterFs @ 1004d8d4 ====
// CyDecompAt: created, body 1004d8d4-1004d96f

undefined4 _IsPartOfMonster__12TOctoMonsterFs(int param_1,undefined4 param_2)

{
  undefined4 uVar1;
  short sVar2;
  
  sVar2 = 0;
  while( true ) {
    if (7 < sVar2) {
      uVar1 = .debug::_IsPartOfMonster__14TActiveMonsterFs(param_1,param_2);
      return uVar1;
    }
    if (*(int *)(param_1 + sVar2 * 4 + 0x58) == *(int *)PTR_DAT_100cdc44 + (short)param_2 * 0x10)
    break;
    sVar2 = sVar2 + 1;
  }
  return 1;
}


// ==== .IsPartOfMonster__14TDragonMonsterFs @ 1004d9a4 ====
// CyDecompAt: created, body 1004d9a4-1004da4b

undefined4 _IsPartOfMonster__14TDragonMonsterFs(int param_1,undefined4 param_2)

{
  char cVar1;
  int iVar2;
  
  iVar2 = *(int *)PTR_DAT_100cdc44 + (short)param_2 * 0x10;
  if ((((*(int *)(param_1 + 0x58) != iVar2) && (*(int *)(param_1 + 0x5c) != iVar2)) &&
      (*(int *)(param_1 + 0x60) != iVar2)) &&
     ((*(int *)(param_1 + 100) != iVar2 &&
      (cVar1 = .debug::_IsPartOfMonster__14TActiveMonsterFs(param_1,param_2), cVar1 == '\0')))) {
    return 0;
  }
  return 1;
}


// ==== .AddSound__7TViewerFssss @ 10066790 ====
// CyDecompAt: created, body 10066790-1006680f

void _AddSound__7TViewerFssss
               (int param_1,undefined2 param_2,undefined2 param_3,undefined2 param_4,
               undefined2 param_5)

{
  short sVar1;
  
  if (0x7f < *(short *)(param_1 + 0x1dc14)) {
    return;
  }
  *(undefined2 *)(param_1 + *(short *)(param_1 + 0x1dc14) * 8 + 0x1d814) = param_2;
  *(undefined2 *)(param_1 + *(short *)(param_1 + 0x1dc14) * 8 + 0x1d816) = param_3;
  *(undefined2 *)(param_1 + *(short *)(param_1 + 0x1dc14) * 8 + 0x1d81a) = param_5;
  sVar1 = *(short *)(param_1 + 0x1dc14);
  *(short *)(param_1 + 0x1dc14) = sVar1 + 1;
  *(undefined2 *)(param_1 + sVar1 * 8 + 0x1d818) = param_4;
  return;
}

