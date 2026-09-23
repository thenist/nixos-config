pragma Singleton

import QtQuick
import Quickshell

// Desktop shell translations (panel, lock screen, greeter). Keys are the
// English source strings used in the QML; a missing key (or an unknown
// language) falls back to the English source, so new strings never break the
// shell.
//
// The language is taken from the session locale with POSIX precedence
// (LC_ALL > LC_MESSAGES > LANG), the same order QLocale/the rest of the
// session uses. To add a language, add a catalog below keyed by its
// two-letter code.
QtObject {
  readonly property string locale: {
    const configured = Quickshell.env("LC_ALL") || Quickshell.env("LC_MESSAGES") || Quickshell.env("LANG") || "";
    return configured.split(".")[0].split("@")[0];
  }
  readonly property string language: locale.split("_")[0].toLowerCase()

  readonly property var catalogs: ({
    ko: {
      // Bar
      "muted": "음소거",
      "chg %1%": "충전 %1%",
      "bat %1%": "배터리 %1%",
      "full": "완충",
      // Date/time pattern for the clock (Qt pattern letters, names come from
      // the locale); Korean reads month/day/weekday rather than the English
      // weekday-first order.
      "ddd d MMM  HH:mm": "M월 d일 (ddd)  HH:mm",
      // On-screen display
      "Volume  %1%": "볼륨  %1%",
      "Brightness  %1%": "밝기  %1%",
      "Sound muted": "음소거됨",
      // Desktop state
      "Checking network…": "네트워크 확인 중…",
      "Connected · Internet available": "연결됨 · 인터넷 사용 가능",
      "Connected · Limited connectivity": "연결됨 · 제한된 연결",
      "Sign-in required": "로그인 필요",
      "Connecting…": "연결 중…",
      "Disconnected": "연결 안 됨",
      "Network status unavailable": "네트워크 상태를 확인할 수 없음",
      "Could not change brightness": "밝기를 변경할 수 없음",
      // Control center
      "Controls": "제어 센터",
      "Sound": "소리",
      "Brightness": "밝기",
      "Network": "네트워크",
      "Network settings ↗": "네트워크 설정 ↗",
      // Power menu
      "Power": "전원",
      "Esc cancels": "Esc로 취소",
      "Unsaved work will be lost.": "저장하지 않은 작업은 사라집니다.",
      "Lock": "잠금",
      "Suspend": "절전",
      "Restart": "재시작",
      "Shut down": "시스템 종료",
      "Confirm restart": "재시작 확인",
      "Confirm shutdown": "종료 확인",
      "Cancel": "취소",
      // Lock screen
      "Session locked": "세션 잠김",
      "Checking password": "비밀번호 확인 중",
      "Too many attempts": "시도 횟수 초과",
      "Authentication failed": "인증 실패",
      "Press Enter to unlock": "Enter 키를 눌러 잠금 해제",
      // Greeter
      "Sign in to %1": "%1에 로그인",
      "greetd socket unavailable": "greetd 소켓을 사용할 수 없음",
      "Starting %1": "%1 시작 중",
      "Authenticating": "인증 중",
      "Signing in": "로그인 중",
      "Sign in": "로그인",
      "Enter a user name": "사용자 이름을 입력하세요",
      "Enter a password": "비밀번호를 입력하세요",
      "User": "사용자",
      "Password": "비밀번호"
    }
  })

  function tr(source) {
    const catalog = catalogs[language];
    return catalog && catalog[source] !== undefined ? catalog[source] : source;
  }
}
