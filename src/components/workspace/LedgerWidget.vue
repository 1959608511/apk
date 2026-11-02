<script setup lang="ts">
/** 工作台 · 记账窗口（当日收支流水 / 全部流水切换） */
import { computed } from 'vue';
import type { ISODate, LedgerCategory } from '../../types/schema';
import { useCrmStore } from '../../store/useCrmStore';
import { categoryLabel } from '../../services/dbService';
import WorkspaceCard from '../WorkspaceCard.vue';

const props = defineProps<{ selectedDate: ISODate }>();
const emit = defineEmits<{
  (e: 'create'): void;
  (e: 'edit', id: string): void;
}>();

const store = useCrmStore();

const isAll = computed(() => store.ledgerScope === 'all');

/** 当日流水：按录入时间倒序 */
const dayItems = computed(() =>
  store.ledger
    .filter((i) => i.date === props.selectedDate)
    .slice()
    .sort((a, b) => b.createdAt - a.createdAt),
);
/** 全部流水：按日期倒序，同日再按录入时间倒序 */
const allItems = computed(() =>
  store.ledger
    .slice()
    .sort((a, b) => (a.date === b.date ? b.createdAt - a.createdAt : a.date < b.date ? 1 : -1)),
);
const items = computed(() => (isAll.value ? allItems.value : dayItems.value));

const incomeTotal = computed(() => items.value.filter((i) => i.category === 'income').reduce((s, i) => s + i.amount, 0));
const expenseTotal = computed(() => items.value.filter((i) => i.category === 'expense').reduce((s, i) => s + i.amount, 0));
const ledgerMeta = computed(() => {
  if (!items.value.length) return '';
  return `+${incomeTotal.value} / -${expenseTotal.value}`;
});

function toggleScope(): void {
  store.setLedgerScope(isAll.value ? 'day' : 'all');
}
function categoryEmoji(c: LedgerCategory): string {
  if (c === 'income') return '💰';
  if (c === 'expense') return '💸';
  return '🤝';
}
function amountText(c: LedgerCategory, amount: number): string {
  if (c === 'income') return `+${amount}`;
  if (c === 'expense') return `-${amount}`;
  return `¥${amount}`;
}
</script>

<template>
  <WorkspaceCard
    title="记账"
    emoji="💳"
    :meta="ledgerMeta"
  >
    <template #actions>
      <button class="lw-act lw-act-amber" type="button" @click="emit('create')">+ 记一笔</button>
      <button class="lw-act" :class="{ 'lw-act-on': isAll }" type="button" @click="toggleScope">全部</button>
    </template>

    <template v-if="items.length">
      <button
        v-for="item in items"
        :key="item.id"
        class="lw-row"
        type="button"
        @click="emit('edit', item.id)"
      >
        <span class="lw-emoji">{{ categoryEmoji(item.category) }}</span>
        <span class="lw-main">
          <span class="lw-title">{{ item.remark || categoryLabel(item.category) }}</span>
          <span class="lw-sub">{{ item.contactName || categoryLabel(item.category) }}<template v-if="item.tempNote"> · {{ item.tempNote }}</template></span>
        </span>
        <span v-if="isAll" class="lw-date">{{ item.date.slice(5) }}</span>
        <span class="lw-amount" :class="`lw-amount-${item.category}`">{{ amountText(item.category, item.amount) }}</span>
      </button>
    </template>
    <p v-else class="lw-empty">{{ isAll ? '还没有任何收支流水' : '这天还没有收支流水' }}</p>
  </WorkspaceCard>
</template>

<style scoped>
/* 右上角胶囊按钮 */
.lw-act {
  border: 1px solid #e2e8f0; background: #f8fafc; color: #64748b;
  font-size: 10px; line-height: 1.4; padding: 3px 6px; border-radius: 999px;
  flex-shrink: 0; white-space: nowrap; -webkit-tap-highlight-color: transparent;
}
.lw-act-amber { background: #fffbeb; color: #d97706; border-color: #fde68a; }
.lw-act-on { background: #d97706; color: #fff; border-color: #d97706; }

.lw-row {
  width: 100%; display: flex; align-items: center; gap: 7px; padding: 5px 4px;
  border: 0; background: transparent; text-align: left; border-radius: 8px;
  -webkit-tap-highlight-color: transparent;
}
.lw-row:active { background: #f1f5f9; }
.lw-emoji { font-size: 13px; flex-shrink: 0; }
.lw-main { display: flex; flex-direction: column; min-width: 0; flex: 1; }
.lw-title { font-size: 12px; color: #1e293b; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.lw-sub { font-size: 10px; color: #94a3b8; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.lw-date {
  font-size: 9px; line-height: 13px; padding: 0 4px; border-radius: 4px;
  background: #f1f5f9; color: #94a3b8; flex-shrink: 0;
}
.lw-amount { font-size: 12px; font-weight: 600; flex-shrink: 0; }
.lw-amount-income { color: #059669; }
.lw-amount-expense { color: #e11d48; }
.lw-amount-other { color: #64748b; }
.lw-empty { font-size: 11px; color: #b6c2d2; padding: 8px 4px; }
</style>
