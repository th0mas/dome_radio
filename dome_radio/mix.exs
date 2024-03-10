defmodule DomeRadio.MixProject do
  use Mix.Project

  @nerves_rust_target_triple_mapping %{
    "armv6-nerves-linux-gnueabihf": "arm-unknown-linux-gnueabihf",
    "armv7-nerves-linux-gnueabihf": "armv7-unknown-linux-gnueabihf",
    "aarch64-nerves-linux-gnu": "aarch64-unknown-linux-gnu",
    "x86_64-nerves-linux-musl": "x86_64-unknown-linux-musl"
  }

  def project do
    if is_binary(System.get_env("NERVES_SDK_SYSROOT")) do
      components = System.get_env("CC")
        |> tap(&System.put_env("RUSTFLAGS", "-C linker=#{&1}"))
        |> Path.basename()
        |> String.split("-")

      target_triple =
        components
        |> Enum.slice(0, Enum.count(components) - 1)
        |> Enum.join("-")

      mapping = Map.get(@nerves_rust_target_triple_mapping, String.to_atom(target_triple))
      if is_binary(mapping) do
        System.put_env("RUSTLER_TARGET", mapping)
      end
    end

    [
      app: :dome_radio,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {DomeRadio.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:rustler, "~> 0.31.0", runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind dome_radio", "esbuild dome_radio"],
      "assets.deploy": [
        "tailwind dome_radio --minify",
        "esbuild dome_radio --minify",
        "phx.digest"
      ]
    ]
  end
end
