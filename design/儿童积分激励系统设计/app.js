/* 双娃积分 · 业务逻辑
 * 状态：localStorage 'kids-points:v1'
 * 路由：hash router (home / quick / history / shop / stats / me)
 * 设计系统：kami · 暖纸 + 墨蓝 · 单 weight serif · 无斜体
 */
'use strict';

/* ─────────────────────────────────────────────────────────────────
 * 常量与种子数据
 * ──────────────────────────────────────────────────────────────── */
const STORAGE_KEY = 'kids-points:v1';

const SEED = {
  kids: [
    { id: 'k1', name: '小明', age: 8, color: '#1b365d' },
    { id: 'k2', name: '小红', age: 10, color: '#4a6b3a' },
  ],
  items: [
    // 加分
    { id: 'i1', kind: 'add', title: '完成作业', delta: 5, icon: 'book', desc: '今天作业都完成了' },
    { id: 'i2', kind: 'add', title: '阅读 30 分', delta: 5, icon: 'page', desc: '专心读书半小时' },
    { id: 'i3', kind: 'add', title: '整理房间', delta: 3, icon: 'home', desc: '把玩具和衣服归位' },
    { id: 'i4', kind: 'add', title: '主动练琴', delta: 8, icon: 'note', desc: '自己主动练了乐器' },
    { id: 'i5', kind: 'add', title: '帮忙家务', delta: 3, icon: 'hand', desc: '洗碗/扫地/倒垃圾' },
    { id: 'i6', kind: 'add', title: '运动 30 分', delta: 6, icon: 'run', desc: '跑跳运动半小时' },
    { id: 'i7', kind: 'add', title: '刷牙早晚', delta: 2, icon: 'check', desc: '认真刷了两次牙' },
    // 扣分
    { id: 'd1', kind: 'deduct', title: '赖床迟到', delta: -3, icon: 'clock', desc: '早上赖着不肯起' },
    { id: 'd2', kind: 'deduct', title: '看电视超时', delta: -2, icon: 'screen', desc: '超过约定时间' },
    { id: 'd3', kind: 'deduct', title: '顶嘴发脾气', delta: -5, icon: 'bubble', desc: '对家人态度不好' },
    { id: 'd4', kind: 'deduct', title: '挑食', delta: -2, icon: 'spoon', desc: '吃饭挑三拣四' },
    { id: 'd5', kind: 'deduct', title: '忘带作业', delta: -5, icon: 'forget', desc: '作业落在家了' },
  ],
  products: [
    { id: 'p1', cat: 'toy', name: '乐高积木', cost: 200, icon: 'lego', desc: '小颗粒拼装玩具' },
    { id: 'p2', cat: 'book', name: '漫画书一本', cost: 80, icon: 'book', desc: '喜爱的系列最新一册' },
    { id: 'p3', cat: 'food', name: '冰淇淋', cost: 30, icon: 'icecream', desc: '周末的甜点' },
    { id: 'p4', cat: 'priv', name: '选电影特权', cost: 50, icon: 'film', desc: '今晚你决定看什么' },
    { id: 'p5', cat: 'priv', name: '晚睡 30 分', cost: 40, icon: 'moon', desc: '允许今晚晚睡半小时' },
    { id: 'p6', cat: 'out', name: '公园出游', cost: 150, icon: 'park', desc: '周末全家去公园' },
    { id: 'p7', cat: 'toy', name: '贴纸一包', cost: 25, icon: 'sticker', desc: '彩色奖励贴纸' },
    { id: 'p8', cat: 'food', name: '蛋糕一块', cost: 60, icon: 'cake', desc: '下午茶蛋糕' },
  ],
  history: [],          // 启动时种子化（生成近 14 天）
  redemptions: [],
  streak: { k1: { count: 0, lastDate: null }, k2: { count: 0, lastDate: null } },
};

const STREAK_BONUS = { daily: 0, weekly: 20, monthly: 100 };

const CATEGORY_LABEL = {
  toy: '玩具', book: '图书', food: '零食', priv: '特权', out: '外出',
};

/* ─────────────────────────────────────────────────────────────────
 * 状态：localStorage 读写
 * ──────────────────────────────────────────────────────────────── */
const Store = {
  load() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) return JSON.parse(raw);
    } catch (e) { console.warn('storage parse fail', e); }
    const fresh = JSON.parse(JSON.stringify(SEED));
    fresh.history = seedHistory(fresh.kids, fresh.items);
    save(fresh);
    return fresh;
  },
  save(state) { save(state); },
  reset() { localStorage.removeItem(STORAGE_KEY); },
};

function save(state) {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); }
  catch (e) { console.warn('save fail', e); }
}

/* 生成近 14 天种子记录：每天每孩 0–3 条加点，1 条扣点 */
function seedHistory(kids, items) {
  const now = new Date();
  const out = [];
  const adds = items.filter(i => i.kind === 'add');
  const deds = items.filter(i => i.kind === 'deduct');
  for (let d = 1; d <= 14; d++) {
    const date = new Date(now);
    date.setDate(now.getDate() - d);
    date.setHours(20, 0, 0, 0);
    kids.forEach((kid, idx) => {
      const n = 2 + (Math.abs(hashStr(kid.id + d)) % 3);
      for (let i = 0; i < n; i++) {
        const it = adds[(Math.abs(hashStr(kid.id + d + i)) % adds.length)];
        const ts = new Date(date);
        ts.setMinutes(ts.getMinutes() - i * 7);
        out.push({
          id: 'h' + kid.id + d + i,
          kidId: kid.id, itemId: it.id, title: it.title,
          delta: it.delta, ts: ts.toISOString(),
        });
      }
      const dIt = deds[(Math.abs(hashStr(kid.id + d + 99)) % deds.length)];
      if (d % 3 !== 0) {
        const ts = new Date(date);
        ts.setHours(19, 30);
        out.push({
          id: 'h' + kid.id + d + 'x',
          kidId: kid.id, itemId: dIt.id, title: dIt.title,
          delta: dIt.delta, ts: ts.toISOString(),
        });
      }
    });
  }
  return out.sort((a, b) => new Date(b.ts) - new Date(a.ts));
}
function hashStr(s) {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = ((h << 5) - h + s.charCodeAt(i)) | 0;
  return h;
}

/* 全局状态 */
let state = Store.load();

/* ─────────────────────────────────────────────────────────────────
 * 工具
 * ──────────────────────────────────────────────────────────────── */
const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

function fmtTime(ts) {
  const d = new Date(ts);
  const h = String(d.getHours()).padStart(2, '0');
  const m = String(d.getMinutes()).padStart(2, '0');
  return `${h}:${m}`;
}
function fmtDayLabel(ts) {
  const d = new Date(ts);
  const today = new Date(); today.setHours(0,0,0,0);
  const day = new Date(d); day.setHours(0,0,0,0);
  const diff = Math.round((today - day) / (24 * 3600 * 1000));
  if (diff === 0) return '今天';
  if (diff === 1) return '昨天';
  return `${d.getMonth() + 1}月${d.getDate()}日`;
}
function dayKey(ts) {
  const d = new Date(ts);
  // 用本地日期组件，避免 UTC 切片跨日
  return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
}
function todayKey() { return dayKey(new Date()); }
function shiftedDayKey(daysAgo) {
  const d = new Date();
  d.setDate(d.getDate() - daysAgo);
  return dayKey(d);
}

/* ─────────────────────────────────────────────────────────────────
 * 计算：积分 / streak / 趋势
 * ──────────────────────────────────────────────────────────────── */
function kidPoints(kidId) {
  let pts = 0;
  state.history.forEach(h => { if (h.kidId === kidId) pts += h.delta; });
  state.redemptions.forEach(r => { if (r.kidId === kidId) pts -= r.cost; });
  return pts;
}

function todayDelta(kidId) {
  const k = todayKey();
  let d = 0;
  state.history.forEach(h => {
    if (h.kidId === kidId && dayKey(h.ts) === k) d += h.delta;
  });
  return d;
}

function streakOf(kidId) {
  return state.streak[kidId] || { count: 0, lastDate: null };
}

/* 当某条 add 记录被记入时调用：如果该孩今天还没记录过加分，检查 streak */
function bumpStreak(kidId) {
  const s = state.streak[kidId] || { count: 0, lastDate: null };
  const today = todayKey();
  if (s.lastDate === today) return { streak: s.count, bonus: 0 };
  const yesterday = new Date(); yesterday.setDate(yesterday.getDate() - 1);
  const yKey = dayKey(yesterday);
  let count = 1;
  let bonus = 0;
  if (s.lastDate === yKey) {
    count = (s.count || 0) + 1;
  } else if (s.lastDate && s.lastDate !== today) {
    count = 1;
  }
  // bonus
  if (count === 7) bonus = STREAK_BONUS.weekly;
  if (count === 30) bonus += STREAK_BONUS.monthly;

  state.streak[kidId] = { count, lastDate: today };
  save(state);
  return { streak: count, bonus };
}

/* 近 14 天每日净积分 */
function buildTrend(kidId, days = 14) {
  const now = new Date();
  const buckets = [];
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(now.getDate() - i);
    d.setHours(0,0,0,0);
    const k = d.toISOString().slice(0, 10);
    let v = 0;
    state.history.forEach(h => {
      if (h.kidId === kidId && dayKey(h.ts) === k) v += h.delta;
    });
    state.redemptions.forEach(r => {
      if (r.kidId === kidId && dayKey(r.ts) === k) v -= r.cost;
    });
    buckets.push({ key: k, value: v });
  }
  return buckets;
}

/* 项目维度分布 */
function buildDist(kidId) {
  const tally = new Map();
  state.history.forEach(h => {
    if (h.kidId !== kidId) return;
    const cur = tally.get(h.title) || { add: 0, ded: 0 };
    if (h.delta > 0) cur.add += 1;
    else cur.ded += 1;
    tally.set(h.title, cur);
  });
  const out = [];
  tally.forEach((v, k) => out.push({ title: k, add: v.add, ded: v.ded }));
  return out.sort((a, b) => (b.add - b.ded) - (a.add - a.ded));
}

/* 最近 N 条自定义记录 —— 按 (title, delta) 聚类，保留每组最近一次的时间戳 */
function recentFreeforms(limit = 5) {
  const map = new Map();
  state.history.forEach(h => {
    const isFreeform = (h.itemId || '').startsWith('freeform-') || !state.items.some(it => it.id === h.itemId);
    if (!isFreeform) return;
    const ts = new Date(h.ts).getTime();
    const key = h.title + '||' + h.delta;
    const prev = map.get(key);
    if (!prev || ts > prev.ts) map.set(key, { title: h.title, delta: h.delta, ts });
  });
  return [...map.values()]
    .sort((a, b) => b.ts - a.ts)
    .slice(0, limit)
    .map(({ title, delta }) => ({ title, delta }));
}

/* 轻量 HTML 转义，保护 chip 渲染不受自定义标题中的 < > & " 影响 */
function escapeHTML(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/* ─────────────────────────────────────────────────────────────────
 * 路由
 * ──────────────────────────────────────────────────────────────── */
const routes = ['home', 'quick', 'history', 'shop', 'stats', 'me'];
let currentTab = 'home';
let currentKid = state.kids[0].id;
let currentHistoryFilter = 'all';
let currentShopCat = 'all';

function goto(tab, opts = {}) {
  if (opts.kid) currentKid = opts.kid;
  currentTab = tab;
  $$('.tab').forEach(t => t.classList.toggle('is-active', t.dataset.tab === tab));
  $$('.page').forEach(p => p.classList.toggle('is-active', p.dataset.page === tab));
  // 顶栏标题
  const titleMap = { home: '00 · 双娃积分', quick: '01 · 加减分', history: '02 · 历程', shop: '03 · 商城', stats: '04 · 统计', me: '05 · 我的' };
  $('#topTitle').textContent = titleMap[tab] || '00 · 双娃积分';
  render(tab);
  // scroll to top
  const pc = $('.phone-content');
  if (pc) pc.scrollTop = 0;
}

function render(tab) {
  switch (tab) {
    case 'home':    renderHome(); break;
    case 'quick':   renderQuick(); break;
    case 'history': renderHistory(); break;
    case 'shop':    renderShop(); break;
    case 'stats':   renderStats(); break;
    case 'me':      renderMe(); break;
  }
}

/* ─────────────────────────────────────────────────────────────────
 * 首页
 * ──────────────────────────────────────────────────────────────── */
function renderHome() {
  $('#todayLabel').textContent = fmtDayLabel(Date.now()) + ' · ' + new Date().toLocaleDateString('zh-CN');

  // 两个孩子卡片
  const wrap = $('#kidCards');
  wrap.innerHTML = '';
  state.kids.forEach(kid => {
    const pts = kidPoints(kid.id);
    const today = todayDelta(kid.id);
    const sk = streakOf(kid.id);
    const card = document.createElement('button');
    card.className = 'card kid-card hover';
    card.type = 'button';
    card.innerHTML = `
      <div class="kid-head">
        <div class="avatar">${kid.name.slice(-2)}</div>
        <div class="kid-meta">
          <span class="kid-name">${kid.name}</span>
          <span class="kid-sub">${kid.age} 岁</span>
        </div>
      </div>
      <div class="kid-points">
        <span class="kid-points-num">${pts}</span>
        <span class="kid-points-unit">积分</span>
      </div>
      <div class="kid-stats">
        <div class="kid-stat">
          <span class="kid-stat-v ${today >= 0 ? '' : ''}" style="${today >= 0 ? 'color:var(--success)' : 'color:var(--danger)'}">
            ${today >= 0 ? '+' : ''}${today}
          </span>
          <span class="kid-stat-l">今日</span>
        </div>
        <div class="kid-stat">
          <span class="kid-stat-v">${sk.count}</span>
          <span class="kid-stat-l">连续天数</span>
        </div>
        <div class="kid-stat">
          <span class="kid-stat-v">${sk.count >= 7 ? '★' : '·'}</span>
          <span class="kid-stat-l">${sk.count >= 7 ? 'bonus 激活' : 'bonus 待解锁'}</span>
        </div>
      </div>
    `;
    card.addEventListener('click', () => { currentKid = kid.id; goto('quick', { kid: kid.id }); });
    wrap.appendChild(card);
  });

  // 商城推荐：取 4 个可达 / 总分最高的
  const grid = $('#homeShop');
  grid.innerHTML = '';
  const order = state.kids.map(k => ({ k, pts: kidPoints(k.id) }));
  const showcase = [...state.products]
    .map(p => ({ p, best: Math.max(...order.map(o => o.pts)) }))
    .sort((a, b) => b.best - a.best)
    .slice(0, 4);
  showcase.forEach(({ p, best }) => {
    grid.appendChild(renderProductCard(p, best));
  });
}

/* ─────────────────────────────────────────────────────────────────
 * 加减分
 * ──────────────────────────────────────────────────────────────── */
function renderQuick() {
  const tabs = $('#quickKidTabs');
  tabs.innerHTML = '';
  state.kids.forEach(kid => {
    const b = document.createElement('button');
    b.className = 'kid-tab' + (kid.id === currentKid ? ' is-active' : '');
    b.type = 'button';
    b.innerHTML = `<span class="avatar">${kid.name.slice(-2)}</span><span>${kid.name}</span>`;
    b.addEventListener('click', () => {
      currentKid = kid.id;
      render('quick');
    });
    tabs.appendChild(b);
  });

  const addItems = state.items.filter(i => i.kind === 'add');
  const dedItems = state.items.filter(i => i.kind === 'deduct');
  $('#quickAddCount').textContent = `共 ${addItems.length} 项`;
  $('#quickDeductCount').textContent = `共 ${dedItems.length} 项`;

  const addWrap = $('#quickAddList'); addWrap.innerHTML = '';
  addItems.forEach(it => addWrap.appendChild(renderItemRow(it, true)));
  const dedWrap = $('#quickDeductList'); dedWrap.innerHTML = '';
  dedItems.forEach(it => dedWrap.appendChild(renderItemRow(it, false)));
}

function renderItemRow(it, isAdd) {
  const btn = document.createElement('button');
  btn.className = 'item' + (isAdd ? ' add' : ' deduct');
  btn.type = 'button';
  btn.innerHTML = `
    <div class="item-icon${isAdd ? '' : ' deduct'}">${iconSVG(it.icon)}</div>
    <div class="item-body">
      <div class="item-title">${it.title}</div>
      <div class="item-sub">${it.desc}</div>
    </div>
    <div class="item-delta">${isAdd ? '+' : ''}${it.delta}</div>
  `;
  btn.addEventListener('click', () => {
    recordEvent(it);
  });
  return btn;
}

function recordEvent(it) {
  writeHistory({
    kidId: currentKid,
    title: it.title,
    delta: it.delta,
    itemId: it.id,
  });
}

/* 共享写入：预设项、自定义记录都通过这里
 * 入参：{ kidId, title, delta, itemId?, kind?: 'add'|'deduct' }
 * 不传 itemId 时按 delta 符号自动归类（影响 streak bonus 是否触发）
 */
function writeHistory({ kidId, title, delta, itemId, kind }) {
  const kid = state.kids.find(k => k.id === kidId) || state.kids[0];
  const rec = {
    id: 'h' + Date.now() + Math.floor(Math.random() * 9999),
    kidId: kid.id,
    itemId: itemId || ('freeform-' + Date.now()),
    title, delta, ts: new Date().toISOString(),
  };
  state.history.unshift(rec);
  save(state);

  // streak bonus：加分时检查
  const isAdd = kind ? (kind === 'add') : (delta > 0);
  let bonus = 0, streakCount = 0;
  if (isAdd) {
    const r = bumpStreak(kid.id);
    bonus = r.bonus; streakCount = r.streak;
    if (bonus > 0) {
      state.history.unshift({
        id: 'hB' + Date.now(),
        kidId: kid.id, itemId: 'streak-bonus',
        title: `连续 ${streakCount} 天 bonus`,
        delta: bonus, ts: new Date().toISOString(),
      });
      save(state);
    }
  }

  toast({
    kind: delta > 0 ? 'success' : 'danger',
    title: `${kid.name} · ${title}`,
    body: delta > 0
      ? `+${delta} 分 · 当前 ${kidPoints(kid.id)} 分`
      : `${delta} 分 · 当前 ${kidPoints(kid.id)} 分`,
  });

  if (bonus > 0) {
    setTimeout(() => toast({
      kind: 'success',
      title: `${kid.name} · Streak bonus!`,
      body: `连续 ${streakCount} 天 · +${bonus} 分`,
    }), 700);
  }

  // 路由级刷新
  if (currentTab === 'quick') renderQuick();
  else if (currentTab === 'home') renderHome();
  else if (currentTab === 'history') renderHistory();
  else if (currentTab === 'stats') renderStats();
}

function openCustomSheet() {
  const sheet = document.createElement('div');
  sheet.className = 'sheet-mask';
  sheet.innerHTML = `
    <div class="sheet" role="dialog" aria-modal="true">
      <div class="sheet-grab"></div>
      <div class="sheet-title">手动加减分</div>
      <p class="sheet-msg">记一笔临时事项：填写标题和分值，备注可选。不写入预设项。</p>

      <div>
        <div class="eyebrow" style="margin-bottom:6px;">最近 5 条自定义 · 点即再用</div>
        <div id="recentFreeforms" style="display:flex; flex-wrap:wrap; gap:6px;"></div>
      </div>

      <div class="kid-tabs" id="customKidTabs" style="background:var(--surface);"></div>

      <input id="customTitle" type="text" placeholder="这次是因为……（必填）" maxlength="16"
        style="padding:12px 14px; border-radius:var(--radius-md); border:1px solid var(--border); background:var(--surface); font: 500 14px/1.2 var(--font-display); min-height:44px;"/>

      <div style="display:grid; grid-template-columns: auto 1fr auto; gap:8px; align-items:center;">
        <button id="customSign" type="button" class="btn btn-secondary" style="min-height:44px; padding:10px 14px; flex:none;"
          aria-label="切换加减号">+</button>
        <input id="customDelta" type="number" placeholder="分值（整数）" value="5"
          style="padding:12px 14px; border-radius:var(--radius-md); border:1px solid var(--border); background:var(--surface); font: 500 14px/1.2 var(--font-display); min-height:44px; text-align:center;"/>
        <span class="body-meta" style="font: 500 14px/1 var(--font-display);">分</span>
      </div>

      <input id="customNote" type="text" placeholder="备注（可选，最多 32 字）" maxlength="32"
        style="padding:12px 14px; border-radius:var(--radius-md); border:1px solid var(--border); background:var(--surface); font: 500 14px/1.2 var(--font-display); min-height:44px;"/>

      <div class="sheet-actions">
        <button class="btn btn-secondary" type="button" data-act="cancel">取消</button>
        <button class="btn btn-primary" type="button" data-act="save">记录</button>
      </div>
    </div>
  `;
  $('#sheetRoot').appendChild(sheet);

  // 最近自定义（chip）—— 直接点击即写
  const rf = sheet.querySelector('#recentFreeforms');
  const recents = recentFreeforms(5);
  if (!recents.length) {
    rf.innerHTML = `<span class="body-meta" style="padding:4px 2px;">还没有自定义记录</span>`;
  } else {
    recents.forEach(r => {
      const isAdd = r.delta > 0;
      const chip = document.createElement('button');
      chip.type = 'button';
      chip.className = 'recent-chip';
      chip.style.cssText = [
        'display:inline-flex', 'align-items:center', 'gap:4px',
        'font: 500 12px/1 var(--font-display)',
        'padding:6px 10px',
        'border-radius:var(--radius-pill)',
        'cursor:pointer',
        'min-height:32px',
        'max-width:240px',
        'overflow:hidden',
        'white-space:nowrap',
        'text-overflow:ellipsis',
        'border:1px solid transparent',
        'transition:box-shadow var(--motion-base) var(--ease-standard)',
        isAdd
          ? 'background:#e6ede0;color:var(--success);border-color:#d6dec8'
          : 'background:#efe2df;color:var(--danger);border-color:#e5d3cd',
      ].join(';');
      chip.innerHTML = `<span style="font-variant-numeric:tabular-nums;">${isAdd ? '+' : ''}${r.delta}</span><span style="opacity:0.5;">·</span><span style="overflow:hidden;text-overflow:ellipsis;">${escapeHTML(r.title)}</span>`;
      chip.title = `${r.title} · ${isAdd ? '+' : ''}${r.delta} 分 · 点击再用`;
      chip.addEventListener('click', () => {
        writeHistory({ kidId: localKid, title: r.title, delta: r.delta });
        closeSheet();
      });
      rf.appendChild(chip);
    });
  }

  // 孩子选择
  const kt = sheet.querySelector('#customKidTabs');
  let localKid = currentKid;
  function renderKidTabs() {
    kt.innerHTML = '';
    state.kids.forEach(k => {
      const b = document.createElement('button');
      b.className = 'kid-tab' + (k.id === localKid ? ' is-active' : '');
      b.type = 'button';
      b.innerHTML = `<span class="avatar">${k.name.slice(-2)}</span><span>${k.name}</span>`;
      b.addEventListener('click', () => { localKid = k.id; renderKidTabs(); });
      kt.appendChild(b);
    });
  }
  renderKidTabs();

  // 加减号切换
  const signBtn = sheet.querySelector('#customSign');
  signBtn.addEventListener('click', () => {
    const inp = sheet.querySelector('#customDelta');
    const cur = parseInt(inp.value, 10);
    if (!isNaN(cur) && cur !== 0) {
      inp.value = String(Math.abs(cur));
      signBtn.textContent = signBtn.textContent === '+' ? '−' : '+';
    } else {
      signBtn.textContent = signBtn.textContent === '+' ? '−' : '+';
    }
  });

  sheet.querySelector('[data-act="cancel"]').addEventListener('click', closeSheet);
  sheet.addEventListener('click', (e) => { if (e.target === sheet) closeSheet(); });
  sheet.querySelector('[data-act="save"]').addEventListener('click', () => {
    const title = sheet.querySelector('#customTitle').value.trim();
    let n = parseInt(sheet.querySelector('#customDelta').value, 10);
    const note = sheet.querySelector('#customNote').value.trim();
    if (!title) { toast({ kind: 'danger', title: '请填标题' }); return; }
    if (isNaN(n) || n === 0) { toast({ kind: 'danger', title: '分值要为非零整数' }); return; }
    n = Math.abs(n);
    if (signBtn.textContent === '−') n = -n;
    const finalTitle = note ? `${title}（${note}）` : title;
    writeHistory({ kidId: localKid, title: finalTitle, delta: n });
    closeSheet();
  });

  setTimeout(() => sheet.querySelector('#customTitle').focus(), 50);
}

/* ─────────────────────────────────────────────────────────────────
 * 历程
 * ──────────────────────────────────────────────────────────────── */
function renderHistory() {
  const filter = $('#historyFilter');
  filter.innerHTML = '';
  const opts = [{ id: 'all', label: '全部' }, ...state.kids.map(k => ({ id: k.id, label: k.name }))];
  opts.forEach(o => {
    const b = document.createElement('button');
    b.className = 'kid-tab' + (o.id === currentHistoryFilter ? ' is-active' : '');
    b.type = 'button';
    b.dataset.id = o.id;
    b.innerHTML = `<span>${o.label}</span>`;
    b.style.minHeight = '40px';
    b.style.padding = '8px 14px';
    b.style.background = o.id === currentHistoryFilter ? 'var(--surface)' : 'var(--surface)';
    b.style.boxShadow = o.id === currentHistoryFilter ? 'var(--elev-ring-accent)' : 'var(--elev-ring)';
    b.style.color = o.id === currentHistoryFilter ? 'var(--accent)' : 'var(--muted)';
    b.style.borderRadius = 'var(--radius-md)';
    b.addEventListener('click', () => { currentHistoryFilter = o.id; renderHistory(); });
    filter.appendChild(b);
  });

  const list = state.history.filter(h => currentHistoryFilter === 'all' || h.kidId === currentHistoryFilter);
  const tl = $('#timeline'); tl.innerHTML = '';
  if (!list.length) {
    tl.innerHTML = `<div class="empty-state">还没有记录，去加减分页记一笔吧。</div>`;
    return;
  }
  // 按天分组
  const byDay = new Map();
  list.forEach(h => {
    const k = dayKey(h.ts);
    if (!byDay.has(k)) byDay.set(k, []);
    byDay.get(k).push(h);
  });
  byDay.forEach((entries, key) => {
    const day = document.createElement('div');
    day.className = 'timeline-day';
    const dayLabel = document.createElement('div');
    dayLabel.className = 'timeline-day-label';
    dayLabel.textContent = fmtDayLabel(entries[0].ts);
    day.appendChild(dayLabel);
    entries.forEach(h => {
      const kid = state.kids.find(k => k.id === h.kidId);
      const row = document.createElement('div');
      row.className = 'timeline-item ' + (h.delta > 0 ? 'add' : 'deduct');
      const sign = h.delta > 0 ? '+' : '';
      row.innerHTML = `
        <div class="timeline-body">
          <span class="timeline-title">${h.title}</span>
          <span class="timeline-sub">${kid ? kid.name : ''} · ${fmtTime(h.ts)}</span>
        </div>
        <span class="timeline-delta">${sign}${h.delta}</span>
      `;
      day.appendChild(row);
    });
    tl.appendChild(day);
  });
}

/* ─────────────────────────────────────────────────────────────────
 * 商城
 * ──────────────────────────────────────────────────────────────── */
function renderShop() {
  const cats = $('#shopCats');
  cats.innerHTML = '';
  const catsList = [{ id: 'all', label: '全部' }, ...Object.entries(CATEGORY_LABEL).map(([id, label]) => ({ id, label }))];
  catsList.forEach(c => {
    const b = document.createElement('button');
    b.className = 'tag';
    b.type = 'button';
    b.style.cursor = 'pointer';
    b.style.minHeight = '36px';
    b.style.padding = '8px 12px';
    if (c.id !== currentShopCat) {
      b.style.background = 'var(--surface)';
      b.style.boxShadow = 'var(--elev-ring)';
      b.style.color = 'var(--muted)';
    } else {
      b.style.background = 'var(--tag-bg-soft)';
      b.style.color = 'var(--accent)';
    }
    b.textContent = c.label;
    b.addEventListener('click', () => { currentShopCat = c.id; renderShop(); });
    cats.appendChild(b);
  });

  const all = state.products.filter(p => currentShopCat === 'all' || p.cat === currentShopCat);
  $('#shopCount').textContent = `共 ${all.length} 件`;
  const grid = $('#shopGrid'); grid.innerHTML = '';

  const sortedByBest = all.map(p => ({ p, best: Math.max(...state.kids.map(k => kidPoints(k.id))) }))
    .sort((a, b) => b.best - a.best);
  sortedByBest.forEach(({ p, best }) => grid.appendChild(renderProductCard(p, best)));

  // 兑换记录
  const rl = $('#redeemList'); rl.innerHTML = '';
  const reds = [...state.redemptions].sort((a, b) => new Date(b.ts) - new Date(a.ts)).slice(0, 10);
  if (!reds.length) {
    rl.innerHTML = `<div class="empty-state">还没有兑换记录。</div>`;
  } else {
    reds.forEach(r => {
      const kid = state.kids.find(k => k.id === r.kidId);
      const product = state.products.find(p => p.id === r.productId);
      const row = document.createElement('div');
      row.className = 'redeem-row';
      row.innerHTML = `
        <div class="redeem-icon">${product ? iconSVG(product.icon) : iconSVG('gift')}</div>
        <div class="redeem-body">
          <div class="redeem-title">${product ? product.name : r.title || '商品'}</div>
          <div class="redeem-sub">${kid ? kid.name : ''} · ${fmtDayLabel(r.ts)} ${fmtTime(r.ts)}</div>
        </div>
        <span class="redeem-cost">−${r.cost}</span>
      `;
      rl.appendChild(row);
    });
  }
}

function renderProductCard(p, best) {
  const affordable = best >= p.cost;
  const b = document.createElement('button');
  b.className = 'product' + (affordable ? ' affordable' : '');
  b.type = 'button';
  b.innerHTML = `
    <div class="product-media">${iconSVG(p.icon, 56)}</div>
    <div class="product-body">
      <div class="product-name od-keep">${p.name}</div>
      <div class="product-price">
        <span class="product-price-num">${p.cost}</span>
        <span class="product-price-unit">分</span>
      </div>
      ${affordable
        ? `<span class="tag success" style="font-size:10px; padding:2px 6px;">可兑换</span>`
        : `<span class="tag" style="font-size:10px; padding:2px 6px; color:var(--meta); background:var(--surface-warm);">还差 ${p.cost - best}</span>`
      }
    </div>
  `;
  b.addEventListener('click', () => openRedeemSheet(p));
  return b;
}

function openRedeemSheet(p) {
  const kidOpts = state.kids.map(k => {
    const pts = kidPoints(k.id);
    return `<option value="${k.id}" ${k.id === currentKid ? 'selected' : ''} ${pts < p.cost ? 'disabled' : ''}>${k.name} · ${pts} 分${pts < p.cost ? '（不足）' : ''}</option>`;
  }).join('');
  const sheet = document.createElement('div');
  sheet.className = 'sheet-mask';
  sheet.innerHTML = `
    <div class="sheet" role="dialog" aria-modal="true">
      <div class="sheet-grab"></div>
      <div class="sheet-title">${p.name}</div>
      <p class="sheet-msg">所需 <strong style="color:var(--accent); font-weight:500;">${p.cost}</strong> 分 ${p.desc}。</p>
      <select id="redeemKid" style="appearance:none; -webkit-appearance:none; padding: 12px 14px; border-radius: var(--radius-md); border: 1px solid var(--border); background: var(--surface); font: 500 14px/1 var(--font-display); color: var(--fg); min-height: 44px;">${kidOpts}</select>
      <div class="sheet-actions">
        <button class="btn btn-secondary" type="button" data-act="cancel">取消</button>
        <button class="btn btn-primary" type="button" data-act="confirm" ${state.kids.every(k => kidPoints(k.id) < p.cost) ? 'disabled style="opacity:0.5; cursor:not-allowed;"' : ''}>兑换</button>
      </div>
    </div>
  `;
  $('#sheetRoot').appendChild(sheet);
  sheet.querySelector('[data-act="cancel"]').addEventListener('click', closeSheet);
  sheet.addEventListener('click', (e) => { if (e.target === sheet) closeSheet(); });
  sheet.querySelector('[data-act="confirm"]').addEventListener('click', () => {
    const sel = sheet.querySelector('#redeemKid');
    const kidId = sel.value;
    if (kidPoints(kidId) < p.cost) {
      toast({ kind: 'danger', title: '积分不足', body: `${state.kids.find(k=>k.id===kidId).name} 的积分不够。` });
      return;
    }
    doRedeem(kidId, p);
    closeSheet();
  });
}
function closeSheet() {
  const root = $('#sheetRoot');
  root.innerHTML = '';
}

function doRedeem(kidId, p) {
  const rec = {
    id: 'r' + Date.now(),
    kidId, productId: p.id, title: p.name, cost: p.cost,
    ts: new Date().toISOString(),
  };
  state.redemptions.unshift(rec);
  save(state);
  const kid = state.kids.find(k => k.id === kidId);
  toast({
    kind: 'success',
    title: `${kid.name} 兑换了 ${p.name}`,
    body: `剩余 ${kidPoints(kidId)} 分`,
  });
  if (currentTab === 'shop') renderShop();
  else if (currentTab === 'home') renderHome();
  else if (currentTab === 'stats') renderStats();
  else if (currentTab === 'me') renderMe();
}

/* ─────────────────────────────────────────────────────────────────
 * 统计
 * ──────────────────────────────────────────────────────────────── */
function renderStats() {
  const kidId = currentKid;
  const kid = state.kids.find(k => k.id === kidId);
  const trend = buildTrend(kidId, 14);
  const sum = trend.reduce((acc, b) => acc + b.value, 0);
  const addCount = state.history.filter(h => h.kidId === kidId && h.delta > 0).length;
  const dedCount = state.history.filter(h => h.kidId === kidId && h.delta < 0).length;

  // 头部 3 个数值
  const sr = $('#statRow'); sr.innerHTML = '';
  sr.appendChild(statBlock(kidPoints(kidId), '当前积分'));
  sr.appendChild(statBlock(addCount, '加分次数'));
  sr.appendChild(statBlock(dedCount, '扣分次数'));

  // 折线图
  drawSpark($('#spark'), trend);

  // 顶部孩子切换
  const head = $$('#statsKidTabs .kid-tab');
  // 我们把切换放到 sr 之前 — 简化：在统计页用同一 currentKid，并在 sr 上方渲染两个 chip
  // 这里偷个巧：直接在 .stat-card 上方插入一个 segment
  if (!$('#statsKidSelect')) {
    const sel = document.createElement('div');
    sel.id = 'statsKidSelect';
    sel.className = 'kid-tabs';
    sel.style.marginBottom = '12px';
    sel.innerHTML = state.kids.map(k => `
      <button class="kid-tab${k.id === currentKid ? ' is-active' : ''}" type="button" data-kid="${k.id}">
        <span class="avatar">${k.name.slice(-2)}</span>
        <span>${k.name}</span>
      </button>
    `).join('');
    sel.querySelectorAll('button').forEach(btn => {
      btn.addEventListener('click', () => {
        currentKid = btn.dataset.kid;
        renderStats();
      });
    });
    sr.parentElement.parentElement.insertBefore(sel, sr.parentElement);
  } else {
    const sel = $('#statsKidSelect');
    sel.innerHTML = state.kids.map(k => `
      <button class="kid-tab${k.id === currentKid ? ' is-active' : ''}" type="button" data-kid="${k.id}">
        <span class="avatar">${k.name.slice(-2)}</span>
        <span>${k.name}</span>
      </button>
    `).join('');
    sel.querySelectorAll('button').forEach(btn => {
      btn.addEventListener('click', () => {
        currentKid = btn.dataset.kid;
        renderStats();
      });
    });
  }

  // 分布
  const dl = $('#distList'); dl.innerHTML = '';
  const dist = buildDist(kidId).slice(0, 8);
  if (!dist.length) {
    dl.innerHTML = `<div class="empty-state">还没有数据。</div>`;
  }
  dist.forEach(d => {
    const row = document.createElement('div');
    row.className = 'kid-edit';
    row.style.justifyContent = 'space-between';
    row.innerHTML = `
      <span style="font: 500 14px/1.2 var(--font-display); flex: 1;">${d.title}</span>
      <span class="body-meta"><span class="num" style="color:var(--success);">+${d.add}</span> · <span class="num" style="color:var(--danger);">−${d.ded}</span></span>
    `;
    dl.appendChild(row);
  });
}
function statBlock(v, l) {
  const d = document.createElement('div');
  d.className = 'stat-block';
  d.innerHTML = `<span class="stat-block-v">${v}</span><span class="stat-block-l">${l}</span>`;
  return d;
}
function drawSpark(svg, buckets) {
  if (!svg) return;
  const w = 300, h = 56;
  const pad = 4;
  const max = Math.max(1, ...buckets.map(b => b.value), 0);
  const min = Math.min(0, ...buckets.map(b => b.value));
  const range = Math.max(1, max - min);
  const stepX = (w - pad * 2) / Math.max(1, buckets.length - 1);
  const yFor = v => pad + (h - pad * 2) * (1 - (v - min) / range);
  const zeroY = yFor(0);

  const pts = buckets.map((b, i) => [pad + i * stepX, yFor(b.value)]);
  const linePath = pts.map((p, i) => `${i === 0 ? 'M' : 'L'}${p[0].toFixed(1)},${p[1].toFixed(1)}`).join(' ');
  const areaPath = `${linePath} L${pts[pts.length-1][0].toFixed(1)},${h} L${pts[0][0].toFixed(1)},${h} Z`;

  svg.innerHTML = `
    <line x1="0" y1="${zeroY.toFixed(1)}" x2="${w}" y2="${zeroY.toFixed(1)}" stroke="var(--border)" stroke-dasharray="2 3" stroke-width="1"/>
    <path d="${areaPath}" fill="var(--accent)" fill-opacity="0.1"/>
    <path d="${linePath}" fill="none" stroke="var(--accent)" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
    ${pts.map((p, i) => i % 4 === 0 || i === pts.length - 1 ? `<circle cx="${p[0].toFixed(1)}" cy="${p[1].toFixed(1)}" r="1.6" fill="var(--accent)"/>` : '').join('')}
  `;
}

/* ─────────────────────────────────────────────────────────────────
 * 我的
 * ──────────────────────────────────────────────────────────────── */
function renderMe() {
  // 孩子改名
  const mk = $('#meKids'); mk.innerHTML = '';
  state.kids.forEach(k => {
    const row = document.createElement('div');
    row.className = 'kid-edit';
    row.innerHTML = `
      <div class="avatar">${k.name.slice(-2)}</div>
      <input class="kid-edit-input" type="text" value="${k.name}" data-kid="${k.id}" maxlength="12" aria-label="孩子名字"/>
      <span class="body-meta" style="font-variant-numeric:tabular-nums;">${kidPoints(k.id)} 分</span>
    `;
    mk.appendChild(row);
  });
  mk.querySelectorAll('input').forEach(inp => {
    inp.addEventListener('change', () => {
      const kid = state.kids.find(k => k.id === inp.dataset.kid);
      kid.name = inp.value.trim() || kid.name;
      save(state);
      renderMe();
    });
  });

  // 项列表
  const a = $('#meAddItems'); a.innerHTML = '';
  state.items.filter(i => i.kind === 'add').forEach(it => a.appendChild(editItemRow(it)));
  const d = $('#meDeductItems'); d.innerHTML = '';
  state.items.filter(i => i.kind === 'deduct').forEach(it => d.appendChild(editItemRow(it)));
}
function editItemRow(it) {
  const row = document.createElement('div');
  row.className = 'item-edit ' + (it.kind === 'add' ? 'add' : 'deduct');
  row.innerHTML = `
    <div class="item-edit-title">${it.title}</div>
    <span class="item-edit-delta">${it.delta > 0 ? '+' : ''}${it.delta}</span>
    <button class="icon-button" type="button" aria-label="删除" data-del-item="${it.id}">
      <svg class="od-icon" viewBox="0 0 16 16" aria-hidden="true" style="--od-icon-size:16px"><path d="M3 5h10M6 5V3.5A.5.5 0 0 1 6.5 3h3a.5.5 0 0 1 .5.5V5M5 5l.6 8a1 1 0 0 0 1 1h2.8a1 1 0 0 0 1-1L11 5" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" fill="none"/></svg>
    </button>
  `;
  row.querySelector('[data-del-item]').addEventListener('click', () => {
    if (!confirm(`删除「${it.title}」？`)) return;
    state.items = state.items.filter(x => x.id !== it.id);
    save(state);
    renderMe();
  });
  return row;
}

/* ─────────────────────────────────────────────────────────────────
 * 添加项弹层
 * ──────────────────────────────────────────────────────────────── */
function openAddItemSheet(kind) {
  const isAdd = kind === 'add';
  const sheet = document.createElement('div');
  sheet.className = 'sheet-mask';
  sheet.innerHTML = `
    <div class="sheet" role="dialog">
      <div class="sheet-grab"></div>
      <div class="sheet-title">新增${isAdd ? '加分' : '扣分'}项</div>
      <input id="newItemTitle" type="text" placeholder="项目名称，如：刷牙早晚" maxlength="16"
        style="padding:12px 14px; border-radius:var(--radius-md); border:1px solid var(--border); background:var(--surface); font: 500 14px/1.2 var(--font-display); min-height:44px;"/>
      <input id="newItemDelta" type="number" placeholder="分值（整数）" value="${isAdd ? 5 : -3}"
        style="padding:12px 14px; border-radius:var(--radius-md); border:1px solid var(--border); background:var(--surface); font: 500 14px/1.2 var(--font-display); min-height:44px;"/>
      <input id="newItemDesc" type="text" placeholder="一句说明（可选）" maxlength="32"
        style="padding:12px 14px; border-radius:var(--radius-md); border:1px solid var(--border); background:var(--surface); font: 500 14px/1.2 var(--font-display); min-height:44px;"/>
      <div class="sheet-actions">
        <button class="btn btn-secondary" type="button" data-act="cancel">取消</button>
        <button class="btn btn-primary" type="button" data-act="save">保存</button>
      </div>
    </div>
  `;
  $('#sheetRoot').appendChild(sheet);
  sheet.querySelector('[data-act="cancel"]').addEventListener('click', closeSheet);
  sheet.addEventListener('click', (e) => { if (e.target === sheet) closeSheet(); });
  sheet.querySelector('[data-act="save"]').addEventListener('click', () => {
    const title = sheet.querySelector('#newItemTitle').value.trim();
    let delta = parseInt(sheet.querySelector('#newItemDelta').value, 10);
    const desc = sheet.querySelector('#newItemDesc').value.trim();
    if (!title) { toast({ title: '请填名称' }); return; }
    if (isNaN(delta) || delta === 0) { toast({ title: '分值要为非零整数' }); return; }
    if (isAdd && delta < 0) delta = -delta;
    if (!isAdd && delta > 0) delta = -delta;
    state.items.push({
      id: 'i' + Date.now(),
      kind, title, delta, desc: desc || (isAdd ? '一个好习惯' : '需要改进的小事'),
      icon: isAdd ? 'check' : 'warn',
    });
    save(state);
    closeSheet();
    toast({ kind: 'success', title: `已新增「${title}」`, body: `${delta > 0 ? '+' : ''}${delta} 分` });
    if (currentTab === 'me') renderMe();
    else if (currentTab === 'quick') renderQuick();
  });
}

/* ─────────────────────────────────────────────────────────────────
 * Toast
 * ──────────────────────────────────────────────────────────────── */
function toast({ kind = '', title, body }) {
  const wrap = $('#toastWrap');
  const el = document.createElement('div');
  el.className = 'toast ' + kind;
  const icon = kind === 'success' ? '✓' : kind === 'danger' ? '−' : 'i';
  el.innerHTML = `
    <div class="toast-icon">${kind === 'success' ? '<svg viewBox="0 0 16 16" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M3 8.5l3 3 7-7"/></svg>' : '<svg viewBox="0 0 16 16" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="8" cy="8" r="6"/><path d="M8 5v3.5M8 11h.01"/></svg>'}</div>
    <div class="toast-body"><strong>${title}</strong>${body || ''}</div>
  `;
  wrap.appendChild(el);
  setTimeout(() => {
    el.style.transition = 'opacity 200ms, transform 200ms';
    el.style.opacity = '0';
    el.style.transform = 'translateY(-4px)';
    setTimeout(() => el.remove(), 220);
  }, 2400);
}

/* ─────────────────────────────────────────────────────────────────
 * 图标：所有功能 SVG 集
 * ──────────────────────────────────────────────────────────────── */
function iconSVG(name, size = 18) {
  const px = `style="--od-icon-size:${size}px"`;
  const wrap = (svg) => `<svg class="od-icon" viewBox="0 0 16 16" aria-hidden="true" ${px}>${svg}</svg>`;
  const path = {
    book: '<path d="M3 3h7a2 2 0 0 1 2 2v8a2 2 0 0 0-2-2H3z M3 3v8h7" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round" fill="none"/><path d="M13 3h-1a2 2 0 0 0-2 2v8a2 2 0 0 1 2-2h1z" stroke="currentColor" stroke-width="1.3" stroke-linejoin="round" fill="none"/>',
    page: '<path d="M3 3h7l3 3v7H3z M5 7h4M5 9h6M5 11h4" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round" fill="none"/>',
    home: '<path d="M2.5 8 8 3.5 13.5 8V13a1 1 0 0 1-1 1h-3v-4H6.5v4h-3a1 1 0 0 1-1-1z" stroke="currentColor" stroke-width="1.3" stroke-linejoin="round" fill="none"/>',
    note: '<path d="M3 13V3l3 2 2-2 2 2 3-2v10z M3 13h10" stroke="currentColor" stroke-width="1.3" stroke-linejoin="round" fill="none"/>',
    hand: '<path d="M5 11V5a1 1 0 1 1 2 0v3M7 8V3.5a1 1 0 1 1 2 0V8M9 8V4.5a1 1 0 1 1 2 0V9M11 9V6.5a1 1 0 1 1 2 0V13a3 3 0 0 1-3 3H7a3 3 0 0 1-3-3v-2" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round" fill="none"/>',
    run: '<circle cx="6" cy="4" r="1.4" stroke="currentColor" stroke-width="1.3" fill="none"/><path d="M5 6l1 4-2 3M6 10l3 1 2 2M9 11l1.5-2-2-1.5L7 6" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round" fill="none"/>',
    check: '<path d="M3 8.5 6.5 12 13 5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>',
    clock: '<circle cx="8" cy="8" r="5.5" stroke="currentColor" stroke-width="1.3" fill="none"/><path d="M8 5v3l2 1.5" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" fill="none"/>',
    screen: '<rect x="2.5" y="3.5" width="11" height="7" rx="1" stroke="currentColor" stroke-width="1.3" fill="none"/><path d="M5 13h6M8 10v3" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" fill="none"/>',
    bubble: '<path d="M3 4h10a1 1 0 0 1 1 1v6a1 1 0 0 1-1 1H7l-3 2v-2H3a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1z" stroke="currentColor" stroke-width="1.3" stroke-linejoin="round" fill="none"/>',
    spoon: '<path d="M5 4a2 2 0 1 1 4 0v3a2 2 0 1 1-4 0z M7 9v4" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" fill="none"/>',
    forget: '<rect x="3" y="4" width="9" height="11" rx="1" stroke="currentColor" stroke-width="1.3" fill="none"/><path d="M6 7h3M6 9h3" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" fill="none"/>',
    lego: '<rect x="3" y="4" width="10" height="9" rx="1" stroke="currentColor" stroke-width="1.3" fill="none"/><circle cx="6" cy="7" r=".8" fill="currentColor"/><circle cx="10" cy="7" r=".8" fill="currentColor"/>',
    icecream: '<path d="M5 8 8 13l3-5z M5 8a3 3 0 1 1 6 0c0-1-1-2-3-2s-3 1-3 2z" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round" fill="none"/>',
    film: '<rect x="2.5" y="4" width="11" height="8" rx="1" stroke="currentColor" stroke-width="1.3" fill="none"/><path d="M2.5 6.5h11M2.5 9.5h11M5 4v8M11 4v8" stroke="currentColor" stroke-width="1.3" fill="none"/>',
    moon: '<path d="M13 9.5A5.5 5.5 0 1 1 6.5 3a4 4 0 0 0 6.5 6.5z" stroke="currentColor" stroke-width="1.3" stroke-linejoin="round" fill="none"/>',
    park: '<path d="M8 3 5 9h6z M5 9c-1.5 0-1.5 3 0 3M11 9c1.5 0 1.5 3 0 3M8 12v2" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round" fill="none"/>',
    sticker: '<path d="M3 13 13 3l-1 5 1 5-5-1z M3 13l1-4 3 3z" stroke="currentColor" stroke-width="1.3" stroke-linejoin="round" fill="none"/>',
    cake: '<path d="M3 13h10v-3H3z M5 10V8a3 3 0 0 1 6 0v2 M6 8h4" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round" fill="none"/>',
    gift: '<rect x="2.5" y="6" width="11" height="8" rx="1" stroke="currentColor" stroke-width="1.3" fill="none"/><path d="M2.5 9h11M5 6V4a3 3 0 0 1 6 0v2" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" fill="none"/>',
    warn: '<path d="M8 3 14 13H2z M8 7v3M8 12h.01" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>',
    flame: '<path d="M8 13c2.5 0 4-1.5 4-4 0-1.5-1-2.5-1.5-3.5C10 7 9 7 9 6c0-1.5 1-2.5 1-3.5C8 1 6 1.5 6 4.5S4 8 4 9.5c0 2 1.5 3.5 4 3.5z" stroke="currentColor" stroke-width="1.3" stroke-linejoin="round" fill="none"/>',
  }[name] || '<circle cx="8" cy="8" r="3" fill="currentColor"/>';
  return wrap(path);
}

/* ─────────────────────────────────────────────────────────────────
 * 启动
 * ──────────────────────────────────────────────────────────────── */
function bindEvents() {
  // tab bar
  $$('.tab').forEach(t => {
    t.addEventListener('click', () => goto(t.dataset.tab));
  });

  // top bar actions
  document.addEventListener('click', (e) => {
    const actBtn = e.target.closest('[data-action]');
    if (!actBtn) return;
    const a = actBtn.dataset.action;
    if (a === 'goto-stats') goto('stats');
    else if (a === 'goto-me') goto('me');
    else if (a === 'goto-shop') goto('shop');
    else if (a === 'quick-add') { goto('quick'); setTimeout(() => { $('#quickAddList').firstElementChild?.focus(); }, 100); }
    else if (a === 'quick-deduct') { goto('quick'); setTimeout(() => { $('#quickDeductList').firstElementChild?.focus(); }, 100); }
    else if (a === 'add-item') openAddItemSheet(actBtn.dataset.kind);
    else if (a === 'custom-record') openCustomSheet();
    else if (a === 'reset-data') {
      if (!confirm('重置全部数据？此操作不可撤销。')) return;
      Store.reset();
      state = Store.load();
      currentKid = state.kids[0].id;
      currentHistoryFilter = 'all';
      render(currentTab);
      toast({ kind: 'success', title: '已重置', body: '数据已恢复到初始。' });
    }
  });

  // hash routing
  window.addEventListener('hashchange', () => {
    const h = location.hash.replace('#/', '');
    if (routes.includes(h)) goto(h);
  });
}

function init() {
  bindEvents();
  // 默认进入 home
  const h = location.hash.replace('#/', '');
  if (routes.includes(h)) goto(h);
  else goto('home');
}

document.addEventListener('DOMContentLoaded', init);
