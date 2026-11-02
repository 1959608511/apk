<script setup lang="ts">
/** 日记新建 / 编辑表单（支持内嵌关联待办） */
import { computed, reactive, ref } from 'vue';
import type { DiaryItem, ISODate } from '../../types/schema';
import { useCrmStore } from '../../store/useCrmStore';
import { uid } from '../../services/dbService';

const props = defineProps<{ date: ISODate; editId?: string }>();
const emit = defineEmits<{ (e: 'close'): void }>();

const store = useCrmStore();
const diaryForm = reactive({ id: undefined as string | undefined, date: '', content: '' });
const draftTodos = ref<Array<{ text: string; isImportant: boolean }>>([]);
const inlineText = ref('');
const inlineImportant = ref(false);
const existingTodos = computed(() => (diaryForm.id ? store.todosOfDiary(diaryForm.id) : []));

function initDiary(): void {
  const d = props.editId
    ? store.diaries.find((x) => x.id === props.editId)
    : store.diaries.find((x) => x.date === props.date);
  Object.assign(diaryForm, { id: d?.id, date: d?.date ?? props.date, content: d?.content ?? '' });
  draftTodos.value = [];
  inlineText.value = '';
  inlineImportant.value = false;
}
function addInline(): void {
  const text = inlineText.value.trim();
  if (!text) return;
  draftTodos.value.push({ text, isImportant: inlineImportant.value });
  inlineText.value = '';
  inlineImportant.value = false;
}
function removeExistingTodo(id: string): void {
  store.removeTodo(id);
}
function saveDiary(): void {
  const content = diaryForm.content.trim();
  if (!content && draftTodos.value.length === 0 && !diaryForm.id) return;
  const existing = diaryForm.id ? store.diaries.find((d) => d.id === diaryForm.id) : undefined;
  const d: DiaryItem = {
    id: diaryForm.id ?? uid(), date: diaryForm.date || props.date, content,
    createdAt: existing?.createdAt ?? Date.now(),
  };
  store.upsertDiary(d);
  for (const t of draftTodos.value) store.addTodoForDiary(d.id, t.text, t.isImportant);
  emit('close');
}
function deleteDiary(): void {
  if (diaryForm.id) store.removeDiary(diaryForm.id);
  emit('close');
}

initDiary();
</script>

<template>
  <div class="as-body">
    <label class="as-label">日记内容</label>
    <textarea v-model="diaryForm.content" class="as-input as-textarea" rows="4" placeholder="自由记录今天…" />
    <label class="as-label">关联待办（保存后与待办面板实时同步）</label>
    <div v-for="t in existingTodos" :key="t.id" class="as-todo">
      <button class="as-check" :class="{ on: t.done }" type="button" @click="store.toggleTodo(t.id)">
        <span v-if="t.done">✓</span>
      </button>
      <span class="as-todo-text">{{ t.text }}</span>
      <span v-if="t.isImportant && !t.done" class="as-badge">重要</span>
      <button class="as-star" :class="{ on: t.isImportant }" type="button" @click="store.toggleImportant(t.id)">
        {{ t.isImportant ? '★' : '☆' }}
      </button>
      <button class="as-del-mini" type="button" @click="removeExistingTodo(t.id)">🗑</button>
    </div>
    <div v-for="(t, i) in draftTodos" :key="`d-${i}`" class="as-todo">
      <span class="as-draft-dot">•</span>
      <span class="as-todo-text">{{ t.text }}</span>
      <span v-if="t.isImportant" class="as-badge">重要</span>
      <button class="as-del-mini" type="button" @click="draftTodos.splice(i, 1)">🗑</button>
    </div>
    <div class="as-add">
      <input v-model="inlineText" class="as-input" placeholder="+ 随手添加关联待办" @keyup.enter="addInline" />
      <button class="as-flag" :class="{ on: inlineImportant }" type="button" @click="inlineImportant = !inlineImportant">
        重要
      </button>
      <button class="as-add-btn" type="button" @click="addInline">+</button>
    </div>
    <p class="as-hint">「重要」且未完成时，会跨日常驻置顶在所有日期的工作台</p>
    <div class="as-foot">
      <button v-if="diaryForm.id" class="as-danger" type="button" @click="deleteDiary">🗑 删除</button>
      <span class="as-spacer" />
      <button class="as-ghost" type="button" @click="emit('close')">取消</button>
      <button class="as-primary" type="button" @click="saveDiary">保存</button>
    </div>
  </div>
</template>

<style scoped>
.as-body { display: flex; flex-direction: column; gap: 4px; padding-bottom: 4px; }
.as-label { font-size: 11px; color: #94a3b8; margin-top: 8px; }
.as-input {
  width: 100%; box-sizing: border-box; border: 1px solid #e2e8f0; border-radius: 10px;
  padding: 9px 10px; font-size: 13px; color: #1e293b; background: #fff;
}
.as-input:focus { outline: none; border-color: #c7d2fe; }
.as-textarea { resize: none; line-height: 1.6; }
.as-todo { display: flex; align-items: center; gap: 7px; padding: 5px 0; }
.as-check {
  width: 16px; height: 16px; border-radius: 50%; border: 1.5px solid #cbd5e1;
  background: #fff; color: #fff; font-size: 10px; flex-shrink: 0; padding: 0;
}
.as-check.on { background: #6366f1; border-color: #6366f1; }
.as-todo-text {
  font-size: 13px; color: #334155; flex: 1; min-width: 0;
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
.as-badge { font-size: 10px; color: #d97706; background: #fffbeb; border-radius: 4px; padding: 0 5px; flex-shrink: 0; }
.as-star { border: 0; background: transparent; color: #cbd5e1; font-size: 13px; padding: 0 2px; flex-shrink: 0; }
.as-star.on { color: #f59e0b; }
.as-del-mini { border: 0; background: transparent; font-size: 12px; padding: 0 2px; flex-shrink: 0; }
.as-draft-dot { color: #a5b4fc; width: 16px; text-align: center; flex-shrink: 0; }
.as-add { display: flex; gap: 6px; align-items: center; margin-top: 8px; }
.as-flag {
  border: 1px solid #fde68a; background: #fff; color: #b45309;
  font-size: 11px; border-radius: 8px; padding: 7px 8px; flex-shrink: 0;
}
.as-flag.on { background: #f59e0b; border-color: #f59e0b; color: #fff; }
.as-add-btn {
  border: 0; background: #6366f1; color: #fff; border-radius: 9px;
  font-size: 15px; width: 42px; height: 38px; flex-shrink: 0;
}
.as-hint { font-size: 10px; color: #94a3b8; margin: 6px 0 0; }
.as-foot { display: flex; align-items: center; gap: 8px; margin-top: 14px; }
.as-spacer { flex: 1; }
.as-danger { border: 0; background: #fff1f2; color: #e11d48; font-size: 12px; border-radius: 9px; padding: 8px 10px; }
.as-ghost {
  border: 1px solid #e2e8f0; background: #fff; color: #64748b;
  font-size: 12px; border-radius: 9px; padding: 8px 14px;
}
.as-primary { border: 0; background: #4f46e5; color: #fff; font-size: 12px; border-radius: 9px; padding: 8px 18px; }
</style>
