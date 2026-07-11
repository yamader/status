<?php $host = ($_SERVER['HTTPS'] ? 'https' : 'http').'://'.$_SERVER['HTTP_HOST'] ?>
<!DOCTYPE html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width">
  <title>YamaD status</title>
  <meta property="og:title" content="YamaD status">
  <meta property="og:type" content="website">
  <meta property="og:url" content="<?php echo $host.$_SERVER['REQUEST_URI'] ?>">
  <meta property="og:image" content="<?php echo $host.'/ogp.png' ?>">
  <style>
    main {
      font-family: serif;
      max-width: 48rem;
      padding: 2rem;
      margin: auto;
    }
    header {
      display: flex;
      align-items: baseline;
      justify-content: space-between;
      flex-wrap: wrap;
    }
    nav {
      margin: 1rem;
      font-weight: bold;
    }
    footer {
      text-align: center;
    }
    h2::before {
      content: "# ";
    }
    h3::before {
      content: "## ";
    }
    img {
      max-width: 100%;
      margin: auto;
    }
  </style>
</head>
<body>
  <main>
    <header>
      <h1>YamaD status</h1>
      <nav>
        <a href="https://load.dyama.net/">Machines</a>
      </nav>
    </header>
    <hr>
    <h2 id="myroom">myroom</h2>
    <h3 id="myroom-6h">6h</h3>
    <img src="plot_myroom_6h.png?<?php echo $_SERVER['REQUEST_TIME'] ?>" alt="myroom (6h)" class="live">
    <h3 id="myroom-1d">1d</h3>
    <img src="plot_myroom_1d.png?<?php echo $_SERVER['REQUEST_TIME'] ?>" alt="myroom (1d)" class="live">
    <h3 id="myroom-3d">3d</h3>
    <img src="plot_myroom_3d.png?<?php echo $_SERVER['REQUEST_TIME'] ?>" alt="myroom (3d)" class="live">
    <h2 id="mass">mass</h2>
    <img src="plot_mass.png?<?php echo $_SERVER['REQUEST_TIME'] ?>" alt="mass" class="hourly">
    <hr>
    <footer>
      <small>&copy; 2024-<?php echo date('Y') ?> YamaD</small>
    </footer>
  </main>
  <script>
    setInterval(() => {
      const ts = Date.now();
      document.querySelectorAll('img.live').forEach(e => {
        e.src = e.src.replace(/\?\d+$/, '?' + ts);
      });
    }, 60_000);
    setInterval(() => {
      const ts = Date.now();
      document.querySelectorAll('img.hourly').forEach(e => {
        e.src = e.src.replace(/\?\d+$/, '?' + ts);
      });
    }, 3600_000);
  </script>
</body>
