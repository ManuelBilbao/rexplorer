defmodule RexplorerWeb.FallbackController do
  @moduledoc """
  Translates controller action results into HTTP responses.

  Controllers can return `{:error, :not_found}`, `{:error, :bad_request}`,
  or `{:error, changeset}` and this module handles the response.
  """

  use RexplorerWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(404)
    |> json(%{error: "not_found", message: "Resource not found"})
  end

  def call(conn, {:error, :bad_request, message}) do
    conn
    |> put_status(400)
    |> json(%{error: "bad_request", message: message})
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)

    conn
    |> put_status(422)
    |> json(%{error: "validation_error", message: "Validation failed", details: errors})
  end
end
