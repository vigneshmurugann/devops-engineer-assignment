const message = document.getElementById("message");

fetch("/api/message")
  .then((response) => response.json())
  .then((data) => {
    message.textContent = `${data.message}. Database reachable: ${data.database}`;
  })
  .catch(() => {
    message.textContent = "API is not reachable.";
  });
