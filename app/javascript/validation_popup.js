// Validation error popup functionality
document.addEventListener('DOMContentLoaded', function() {
  // Show validation popup if errors exist
  const errorContainer = document.querySelector('[data-validation-errors]');
  if (errorContainer) {
    showValidationPopup(errorContainer.dataset.validationErrors);
  }

  // Show flash message popup if exists
  const flashAlert = document.querySelector('[data-flash-alert]');
  if (flashAlert) {
    showValidationPopup(flashAlert.dataset.flashAlert);
  }
});

function showValidationPopup(message) {
  if (!message) return;

  // Create popup element
  const popup = document.createElement('div');
  popup.className = 'fixed top-4 right-4 z-50 max-w-sm bg-red-100 border-l-4 border-red-500 text-red-700 p-4 rounded-md shadow-lg animate-slide-in';
  popup.innerHTML = `
    <div class="flex items-start">
      <div class="flex-shrink-0">
        <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
        </svg>
      </div>
      <div class="ml-3 flex-1">
        <p class="text-sm font-medium">${message}</p>
      </div>
      <div class="ml-4 flex-shrink-0">
        <button type="button" class="text-red-400 hover:text-red-600 focus:outline-none" onclick="this.closest('[class*=fixed]').remove()">
          <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      </div>
    </div>
  `;

  document.body.appendChild(popup);

  // Auto-dismiss after 5 seconds
  setTimeout(() => {
    if (popup.parentNode) {
      popup.style.opacity = '0';
      popup.style.transform = 'translateX(100%)';
      setTimeout(() => popup.remove(), 300);
    }
  }, 5000);
}