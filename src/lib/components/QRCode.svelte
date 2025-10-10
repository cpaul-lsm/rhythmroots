<script lang="ts">
	import { onMount } from 'svelte';
	import QRCode from 'qrcode';
	import { QrCode, Download, Copy } from 'lucide-svelte';

	interface Props {
		url: string;
		size?: number;
		showActions?: boolean;
	}

	let { url, size = 200, showActions = true }: Props = $props();

	let canvas: HTMLCanvasElement;
	let qrCodeDataUrl: string = '';
	let copied = $state(false);

	onMount(async () => {
		if (url) {
			await generateQRCode();
		}
	});

	async function generateQRCode() {
		try {
			if (canvas && url) {
				await QRCode.toCanvas(canvas, url, {
					width: size,
					margin: 2,
					color: {
						dark: '#000000',
						light: '#FFFFFF'
					}
				});
				qrCodeDataUrl = canvas.toDataURL();
			}
		} catch (error) {
			console.error('Error generating QR code:', error);
		}
	}

	async function downloadQRCode() {
		if (qrCodeDataUrl) {
			const link = document.createElement('a');
			link.download = `qr-code-${Date.now()}.png`;
			link.href = qrCodeDataUrl;
			link.click();
		}
	}

	async function copyToClipboard() {
		try {
			await navigator.clipboard.writeText(url);
			copied = true;
			setTimeout(() => {
				copied = false;
			}, 2000);
		} catch (error) {
			console.error('Error copying to clipboard:', error);
		}
	}

	// Regenerate QR code when URL changes
	$effect(() => {
		if (url) {
			generateQRCode();
		}
	});
</script>

<div class="flex flex-col items-center space-y-4">
	<div class="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
		<canvas bind:this={canvas} width={size} height={size}></canvas>
	</div>
	
	{#if showActions}
		<div class="flex space-x-2">
			<button
				onclick={downloadQRCode}
				class="inline-flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
				title="Download QR Code"
			>
				<Download class="h-4 w-4 mr-1" />
				Download
			</button>
			
			<button
				onclick={copyToClipboard}
				class="inline-flex items-center px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
				title="Copy URL to Clipboard"
			>
				<Copy class="h-4 w-4 mr-1" />
				{copied ? 'Copied!' : 'Copy URL'}
			</button>
		</div>
	{/if}
</div>
