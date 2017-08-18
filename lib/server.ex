defmodule ChromeRemoteInterface.Server do
  defstruct [
    :host,
    :port
  ]

  @type t :: %__MODULE__{
    host: String.t,
    port: non_neg_integer() | String.t
  }
end
