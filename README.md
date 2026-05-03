# circle-war

Flutter + Flame 클라이언트와 Node.js + Socket.IO 서버를 함께 관리하는 루트 저장소입니다.  
클라이언트는 서버에서 내려주는 snapshot을 렌더링하고, 전투 판정과 상태 변화는 서버가 authoritative하게 처리합니다.

## 저장소 구성

- `lib/`: Flutter 클라이언트 코드
- `server/`: Node.js + TypeScript 실시간 게임 서버
- `assets/`: 아이콘, 이미지 등 정적 리소스
- `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`: Flutter 플랫폼별 프로젝트

## 빠른 실행

### 1. 서버 실행

```bash
cd server
npm install
npm run dev
```

기본 실행 주소는 `http://localhost:3000`입니다.

### 2. Flutter 클라이언트 실행

프로젝트 루트에서:

```bash
flutter pub get
flutter run
```

앱에서 `PLAY`를 누르면 자동 난투 화면으로 이동합니다.

## 서버 주소 변경

Flutter 클라이언트 서버 주소는 [socket_service.dart](/Users/nomang/Documents/ma_neoreo/circle-game/lib/game/auto_battle/services/socket_service.dart) 의 `serverUrl`에서 변경합니다.

- Flutter desktop/web: `http://localhost:3000`
- Android Emulator: `http://10.0.2.2:3000`
- iOS Simulator: 보통 `localhost` 사용 가능
- 실제 기기: `http://<같은 네트워크의 개발 PC IP>:3000`

## 게임 규칙

- 2개의 공이 당구공처럼 자동으로 이동합니다.
- arena 안에 먹이가 계속 생성됩니다.
- 공이 먹이를 먹으면 골드를 얻습니다.
- 라운드 승자는 다음 라운드 전 업그레이드를 선택합니다.
- 증강은 무기 해금 대신 캐릭터, 기본 스탯, 장착 장비를 강화합니다.
- 생존 플레이어가 1명 이하가 되면 라운드가 끝나고 5초 뒤 재시작됩니다.

캐릭터 능력:

- `p1`: Poison, 이동 경로에 독 장판 생성
- `p2`: None, 캐릭터/장비 증강 가능

## 주요 파일

- [server/src/game/GameRoom.ts](/Users/nomang/Documents/ma_neoreo/circle-game/server/src/game/GameRoom.ts): 서버 authoritative 게임 루프와 라운드 처리
- [server/src/game/types.ts](/Users/nomang/Documents/ma_neoreo/circle-game/server/src/game/types.ts): snapshot 관련 타입
- [lib/game/auto_battle/auto_battle_game.dart](/Users/nomang/Documents/ma_neoreo/circle-game/lib/game/auto_battle/auto_battle_game.dart): Flame 렌더링 진입점
- [lib/game/auto_battle/models/game_snapshot.dart](/Users/nomang/Documents/ma_neoreo/circle-game/lib/game/auto_battle/models/game_snapshot.dart): 서버 snapshot 파싱
- [lib/game/auto_battle/ui/character_info_panel.dart](/Users/nomang/Documents/ma_neoreo/circle-game/lib/game/auto_battle/ui/character_info_panel.dart): 캐릭터 상태 UI

## 현재 구현된 기능

- 30FPS 서버 game loop
- 자동 이동, 벽 충돌, 공 충돌
- 먹이 최대 35개 유지
- 먹이 획득 기반 골드 수급
- 라운드 승자 업그레이드 선택
- 캐릭터/장비 중심 증강
- Poison 독 장판
- Gunner 총알
- Blade 근접 공격
- Miner 지뢰
- HP bar, 골드, 캐릭터 라벨
- 먹이, 총알, 독, 지뢰, 칼 이펙트 렌더링
- 라운드 종료 오버레이
- 5초 뒤 자동 라운드 리셋

## 메모

- 현재 저장소는 루트 기준으로 Git 관리 중입니다.
- 예전 `server` 단독 Git 메타데이터는 `server/.git.backup`으로 보존되어 있습니다.
# Rolling-Dungeon
