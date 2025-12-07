<script setup>
import { RouterView } from 'vue-router'
import { Toaster } from 'vue-sonner'
import 'vue-sonner/style.css'
</script>

<template>
  <div>
    <Toaster position="bottom-right" richColors />
    <RouterView />
  </div>
</template>
