<script setup>
defineProps({
  name: { type: String, required: true },
});
</script>

<template>
  <svg
    class="app-icon"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="1.8"
    stroke-linecap="round"
    stroke-linejoin="round"
    aria-hidden="true"
  >
    <path
      v-if="name === 'dashboard'"
      d="M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h6v6h-6z"
    />
    <path
      v-else-if="name === 'categories'"
      d="M4 5.5h16M4 12h16M4 18.5h16M7 5.5v0M7 12v0M7 18.5v0"
    />
    <path v-else-if="name === 'word'" d="M5 4h14v16H5zM8 8h8M8 12h8M8 16h5" />
    <path
      v-else-if="name === 'question'"
      d="M12 4a8 8 0 1 0 0 16 8 8 0 0 0 0-16Zm0 12v.01M9.8 9a2.2 2.2 0 1 1 3.4 1.85c-.75.5-1.2.87-1.2 1.9"
    />
    <path v-else-if="name === 'logout'" d="M10 5H5v14h5M14 8l4 4-4 4M18 12H9" />
    <path v-else-if="name === 'arrow'" d="m9 18 6-6-6-6" />
    <path v-else d="M12 3v18M3 12h18" />
  </svg>
</template>
