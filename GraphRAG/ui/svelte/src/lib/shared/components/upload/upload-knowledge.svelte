<!--
  Copyright (C) 2024 Intel Corporation
  SPDX-License-Identifier: Apache-2.0
-->

<script lang="ts">
	import { Fileupload, Label } from "flowbite-svelte";
	import { createEventDispatcher } from "svelte";

	const dispatch = createEventDispatcher();
	let value;

	function handleInput(event: Event) {
	  const file = (event.target as HTMLInputElement).files![0];

	  if (!file) return;

	  const reader = new FileReader();
	  reader.onloadend = () => {
		if (!reader.result) return;
		const src = reader.result.toString();
		dispatch("upload", { src: src, fileName: file.name });
	  };
	  reader.readAsDataURL(file);
	}
  </script>

  <div>
	<Label class="space-y-2 mb-2">
	  <Fileupload
		bind:value
		on:change={handleInput}
		class="focus:border-blue-700 focus:ring-0"
		data-testid="file-upload"
		accept=".txt,.pdf,.json,.md"
	  />
	</Label>
  </div>
