const balanceList = document.getElementById("balance-list");

function clarifyAdvanceLabels() {
  if (!balanceList) return;
  for (const card of balanceList.querySelectorAll(".balance-card")) {
    const status = card.querySelector(".status");
    const amount = card.querySelector(":scope > strong");
    if (status?.textContent.trim() === "HORAS FALTANTES") {
      status.textContent = "HORAS ANTICIPADAS";
      if (amount) {
        amount.textContent = amount.textContent.replace(
          /faltantes$/,
          "anticipadas por recuperar",
        );
      }
    }
  }
}

if (balanceList) {
  new MutationObserver(clarifyAdvanceLabels).observe(balanceList, {
    childList: true,
    subtree: true,
  });
  clarifyAdvanceLabels();
}
