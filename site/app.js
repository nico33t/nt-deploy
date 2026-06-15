// nt-deploy landing — copy-to-clipboard buttons + toast
const toast = document.getElementById("toast");
let toastTimer;
function showToast(msg) {
  toast.textContent = msg;
  toast.classList.add("show");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove("show"), 1800);
}
document.querySelectorAll(".copy").forEach((btn) => {
  btn.addEventListener("click", async () => {
    const cmd = btn.dataset.cmd || "";
    try {
      await navigator.clipboard.writeText(cmd);
      showToast("copied ✓");
    } catch {
      // fallback for non-secure contexts
      const ta = document.createElement("textarea");
      ta.value = cmd; document.body.appendChild(ta); ta.select();
      try { document.execCommand("copy"); showToast("copied ✓"); }
      catch { showToast("copy failed — select manually"); }
      ta.remove();
    }
  });
});
