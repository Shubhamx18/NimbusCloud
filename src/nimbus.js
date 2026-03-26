// Show deploy timestamp so you can verify fresh deployments
const footer = document.querySelector('footer p');
if (footer) {
  const now = new Date().toUTCString();
  footer.insertAdjacentHTML('beforeend', `<br/><span style="color:#334155;font-size:0.65rem;">Last deployed: ${now}</span>`);
}