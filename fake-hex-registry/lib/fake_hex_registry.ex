defmodule FakeHexRegistry do
  def dep(name, version) do
    [name, "~> #{version}", false, name]
  end

  def package(p) do
    deps = for d <- p["deps"], do: dep(d["name"], d["version"])

    [{p["name"], [[p["version"]]]},
     {{p["name"], p["version"]}, [deps, String.upcase(p["sha256"]), p["tools"]]}]
  end

  def main([out]) do
    packages = Jason.decode!(IO.read(:all))
    tab = :ets.new(:hex_registry, [:public])

    for p <- packages, do: :ets.insert(tab, package(p))
    :ok = :ets.tab2file(tab, String.to_charlist(out))
  end
end
