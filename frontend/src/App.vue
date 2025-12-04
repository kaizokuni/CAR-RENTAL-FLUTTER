<script setup>
import { RouterView } from 'vue-router'
import { Toaster } from 'vue-sonner'
</script>

<template>
  <div>
    <Toaster position="top-right" richColors />
    <RouterView />
  </div>
</template>
