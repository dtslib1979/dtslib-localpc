#!/usr/bin/env python3
"""
Pending 플레이리스트 재시도 스크립트.
YouTube API 할당량 리셋(태평양 자정) 후 실행.
사용법: python3 tools/youtube/playlist-retry.py
"""
import json, urllib.request, urllib.parse, urllib.error, time
from pathlib import Path

BASE = Path(__file__).parent.parent.parent

def refresh_token(acc):
    with open(BASE / 'tools/youtube/client_secret.json') as f:
        cs = json.load(f)
    with open(BASE / f'tools/youtube/accounts/token_{acc}.json') as f:
        token = json.load(f)
    data = urllib.parse.urlencode({
        'client_id': cs['installed']['client_id'],
        'client_secret': cs['installed']['client_secret'],
        'refresh_token': token['refresh_token'],
        'grant_type': 'refresh_token'
    }).encode()
    req = urllib.request.Request('https://oauth2.googleapis.com/token', data=data)
    with urllib.request.urlopen(req) as resp:
        new = json.loads(resp.read())
    token['access_token'] = new['access_token']
    with open(BASE / f'tools/youtube/accounts/token_{acc}.json', 'w') as f:
        json.dump(token, f, indent=2)
    return new['access_token']

def create_playlist(access_token, title, description=""):
    url = "https://www.googleapis.com/youtube/v3/playlists?part=snippet,status"
    body = json.dumps({
        "snippet": {"title": title, "description": description, "defaultLanguage": "ko"},
        "status": {"privacyStatus": "public"}
    }).encode()
    req = urllib.request.Request(url, data=body, method='POST', headers={
        'Authorization': f'Bearer {access_token}',
        'Content-Type': 'application/json'
    })
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read())
            return data['id'], None
    except urllib.error.HTTPError as e:
        return None, f"ERROR {e.code}: {e.read().decode()[:80]}"

# 토큰 갱신
print("토큰 갱신 중...")
tokens = {acc: refresh_token(acc) for acc in ['a','b','c']}
print("갱신 완료.\n")

# pending 목록 로드
with open(BASE / 'hq/data/channel-playlists.json') as f:
    data = json.load(f)

pending = data.get('pending', [])
created = data.get('created', [])
still_pending = []
ok = 0

for item in pending:
    acc = item['account']
    pid, err = create_playlist(tokens[acc], item['title'])
    if pid:
        print(f"✅ {pid} | {item['title']}")
        item['playlist_id'] = pid
        created.append({'channel': item['channel'], 'title': item['title'], 'playlist_id': pid})
        ok += 1
    else:
        print(f"❌ {item['title']}: {err}")
        still_pending.append(item)
    time.sleep(2)

# 결과 저장
data['created'] = created
data['pending'] = still_pending
if not still_pending:
    data['status'] = f"COMPLETE — {len(created)}개 전수 생성 완료."
else:
    data['status'] = f"PARTIAL — {len(created)}개 완료, {len(still_pending)}개 pending."

with open(BASE / 'hq/data/channel-playlists.json', 'w') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"\n{ok}/{len(pending)}개 성공. 결과 저장 완료.")
if still_pending:
    print("남은 pending → 내일 다시 실행.")
