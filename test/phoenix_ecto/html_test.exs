defmodule PhoenixEcto.HTMLTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset
  import Phoenix.HTML
  import Phoenix.HTML.Form

  test "converts decimal to safe" do
    assert html_escape(Decimal.new("1.0")) == {:safe, "1.0"}
  end

  test "converts datetime to safe" do
    t = %Ecto.Time{hour: 0, min: 0, sec: 0}
    assert html_escape(t) == {:safe, "00:00:00"}

    d = %Ecto.Date{year: 2010, month: 4, day: 17}
    assert html_escape(d) == {:safe, "2010-04-17"}

    dt = %Ecto.DateTime{year: 2010, month: 4, day: 17, hour: 0, min: 0, sec: 0}
    assert html_escape(dt) == {:safe, "2010-04-17 00:00:00"}
  end

  test "form_for/4 with new changeset" do
    changeset = cast(%User{}, :empty, ~w(), ~w())
                |> validate_length(:name, min: 3)

    form = safe_to_string(form_for(changeset, "/", fn f ->
      assert f.id == "user"
      assert f.name == "user"
      assert f.impl == Phoenix.HTML.FormData.Ecto.Changeset
      assert f.source == changeset
      assert f.params == %{}
      assert f.hidden == []
      "FROM FORM"
    end))

    assert form =~ ~s(<form accept-charset="UTF-8" action="/" method="post">)
    assert form =~ "FROM FORM"
  end

  test "form_for/4 with loaded changeset" do
    changeset = cast(%User{__meta__: %{state: :loaded}, id: 13},
                     %{"foo" => "bar"}, ~w(), ~w())

    form = safe_to_string(form_for(changeset, "/", fn f ->
      assert f.id == "user"
      assert f.name == "user"
      assert f.source == changeset
      assert f.params == %{"foo" => "bar"}
      assert f.hidden == [id: 13]
      "FROM FORM"
    end))

    assert form =~ ~s(<form accept-charset="UTF-8" action="/" method="post">)
    assert form =~ ~s(<input name="_method" type="hidden" value="put">)
    assert form =~ "FROM FORM"
    refute form =~ ~s(<input id="user_id" name="user[id]" type="hidden" value="13">)
  end

  test "form_for/4 with custom options" do
    changeset = cast(%User{}, :empty, ~w(), ~w())

    form = safe_to_string(form_for(changeset, "/", [name: "another", multipart: true], fn f ->
      assert f.id == "another"
      assert f.name == "another"
      assert f.source == changeset
      "FROM FORM"
    end))

    assert form =~ ~s(<form accept-charset="UTF-8" action="/" enctype="multipart/form-data" method="post">)
    assert form =~ "FROM FORM"
  end

  test "form_for/4 with errors" do
    changeset =
      %User{}
      |> cast(%{"name" => "JV"}, ~w(name), ~w())
      |> validate_length(:name, min: 3)

    form = safe_to_string(form_for(changeset, "/", [name: "another", multipart: true], fn f ->
      assert f.errors == [name: "should be at least 3 characters"]
      "FROM FORM"
    end))

    assert form =~ ~s(<form accept-charset="UTF-8" action="/" enctype="multipart/form-data" method="post">)
    assert form =~ "FROM FORM"
  end

  ## inputs_for one

  test "one: inputs_for/4 without default" do
    changeset = cast(%User{}, :empty, ~w(), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, fn f ->
        assert f.impl == Phoenix.HTML.FormData.Ecto.Changeset
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text">)
  end

  test "one: inputs_for/4 with default" do
    changeset = cast(%User{}, :empty, ~w(), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, [default: %Permalink{url: "default"}], fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="default">)
  end

  test "one: inputs_for/4 without default and model is present" do
    changeset = cast(%User{permalink: %Permalink{url: "model"}},
                     :empty, ~w(permalink), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="model">)
  end

  test "one: inputs_for/4 with default and model is present" do
    changeset = cast(%User{permalink: %Permalink{url: "model"}},
                     :empty, ~w(permalink), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, [default: %Permalink{url: "default"}], fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="model">)
  end

  test "one: inputs_for/4 without default and params is present" do
    changeset = cast(%User{permalink: %Permalink{url: "model"}},
                     %{"permalink" => %{"url" => "ht"}}, ~w(permalink), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, fn f ->
        assert f.errors == [url: "should be at least 3 characters"]
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="ht">)
  end

  test "one: inputs_for/4 with default and params is present" do
    changeset = cast(%User{permalink: %Permalink{url: "model"}},
                     %{"permalink" => %{"url" => "ht"}}, ~w(permalink), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, [default: %Permalink{url: "default"}], fn f ->
        assert f.errors == [url: "should be at least 3 characters"]
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalink_url" name="user[permalink][url]" type="text" value="ht">)
  end

  test "one: inputs_for/4 with custom id and name" do
    changeset = cast(%User{permalink: %Permalink{url: "model"}},
                     %{"permalink" => %{"url" => "given"}}, ~w(permalink), ~w())

    contents =
      safe_inputs_for(changeset, :permalink, [name: "foo", id: "bar"], fn f ->
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="bar_url" name="foo[url]" type="text" value="given">)
  end

  ## inputs_for many

  test "many: inputs_for/4 without default" do
    changeset = cast(%User{}, :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, fn f ->
        assert f.impl == Phoenix.HTML.FormData.Ecto.Changeset
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents == ""
  end

  test "many: inputs_for/4 with default" do
    changeset = cast(%User{}, :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, [default: [%Permalink{url: "default"}]], fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
           ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="default">)
  end

  test "many: inputs_for/4 without default and model is present" do
    changeset = cast(%User{permalinks: [%Permalink{url: "model1"}, %Permalink{url: "model2"}]},
                     :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="model1">) <>
      ~s(<input id="user_permalinks_1_url" name="user[permalinks][1][url]" type="text" value="model2">)
  end

  test "many: inputs_for/4 with default and model is present" do
    changeset = cast(%User{permalinks: [%Permalink{url: "model1"}, %Permalink{url: "model2"}]},
                     :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, [default: [%Permalink{url: "default"}]], fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="model1">) <>
      ~s(<input id="user_permalinks_1_url" name="user[permalinks][1][url]" type="text" value="model2">)
  end

  test "many: inputs_for/4 with prepend, append and default" do
    default   = [%Permalink{url: "def1"}, %Permalink{url: "def2"}]
    changeset = cast(%User{}, :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, [default: default,
                        prepend: [%Permalink{url: "prepend"}],
                        append: [%Permalink{url: "append"}]], fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="prepend">) <>
      ~s(<input id="user_permalinks_1_url" name="user[permalinks][1][url]" type="text" value="def1">) <>
      ~s(<input id="user_permalinks_2_url" name="user[permalinks][2][url]" type="text" value="def2">) <>
      ~s(<input id="user_permalinks_3_url" name="user[permalinks][3][url]" type="text" value="append">)
  end

  test "many: inputs_for/4 with prepend and append with model" do
    permalinks = [%Permalink{id: "a", url: "model1"}, %Permalink{id: "b", url: "model2"}]
    changeset  = cast(%User{permalinks: permalinks}, :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks,
                      [prepend: [%Permalink{url: "prepend"}],
                       append: [%Permalink{url: "append"}]], fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="prepend">) <>
      ~s(<input id="user_permalinks_1_id" name="user[permalinks][1][id]" type="hidden" value="a">) <>
      ~s(<input id="user_permalinks_1_url" name="user[permalinks][1][url]" type="text" value="model1">) <>
      ~s(<input id="user_permalinks_2_id" name="user[permalinks][2][id]" type="hidden" value="b">) <>
      ~s(<input id="user_permalinks_2_url" name="user[permalinks][2][url]" type="text" value="model2">) <>
      ~s(<input id="user_permalinks_3_url" name="user[permalinks][3][url]" type="text" value="append">)
  end

  test "many: inputs_for/4 with prepend and append with params" do
    permalinks = [%Permalink{id: "a", url: "model1"}, %Permalink{id: "b", url: "model2"}]
    changeset  = cast(%User{permalinks: permalinks},
                      %{"permalinks" => [%{"id" => "a", "url" => "h1"},
                                         %{"id" => "b", "url" => "h2"}]},
                      ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks,
                      [prepend: [%Permalink{url: "prepend"}],
                       append: [%Permalink{url: "append"}]], fn f ->
        assert f.errors == [url: "should be at least 3 characters"]
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="user_permalinks_0_id" name="user[permalinks][0][id]" type="hidden" value="a">) <>
      ~s(<input id="user_permalinks_0_url" name="user[permalinks][0][url]" type="text" value="h1">) <>
      ~s(<input id="user_permalinks_1_id" name="user[permalinks][1][id]" type="hidden" value="b">) <>
      ~s(<input id="user_permalinks_1_url" name="user[permalinks][1][url]" type="text" value="h2">)
  end

  test "many: inputs_for/4 with custom id and name" do
    changeset = cast(%User{permalinks: [%Permalink{url: "model1"}, %Permalink{url: "model2"}]},
                     :empty, ~w(permalinks), ~w())

    contents =
      safe_inputs_for(changeset, :permalinks, [name: "foo", id: "bar"], fn f ->
        assert f.errors == []
        assert f.source.validations == [url: {:length, min: 3}]
        text_input f, :url
      end)

    assert contents ==
      ~s(<input id="bar_0_url" name="foo[0][url]" type="text" value="model1">) <>
      ~s(<input id="bar_1_url" name="foo[1][url]" type="text" value="model2">)
  end

  defp safe_inputs_for(changeset, field, opts \\ [], fun) do
    mark = "--PLACEHOLDER--"

    contents =
      safe_to_string form_for(changeset, "/", fn f ->
        html_escape [mark, inputs_for(f, field, opts, fun), mark]
      end)

    [_, inner, _] = String.split(contents, mark)
    inner
  end

  ## input type

  defmodule Custom do
    use Ecto.Schema

    schema "customs" do
      field :integer, :integer
      field :float, :float
      field :decimal, :decimal
      field :string,  :string
      field :boolean, :boolean
      field :date, Ecto.Date
      field :time, Ecto.Time
      field :datetime, Ecto.DateTime
    end
  end

  test "input types" do
    changeset = cast(%Custom{}, :empty, [], [])

    form_for(changeset, "/", fn f ->
      assert input_type(f, :integer) == :number_input
      assert input_type(f, :float) == :number_input
      assert input_type(f, :decimal) == :number_input
      assert input_type(f, :string) == :text_input
      assert input_type(f, :boolean) == :checkbox
      assert input_type(f, :date) == :date_select
      assert input_type(f, :time) == :time_select
      assert input_type(f, :datetime) == :datetime_select
      ""
    end)
  end

  test "input validations" do
    changeset =
      cast(%Custom{}, :empty, ~w(integer string), ~w())
      |> validate_number(:integer, greater_than: 0, less_than: 100)
      |> validate_number(:float, greater_than_or_equal_to: 0)
      |> validate_length(:string, min: 0, max: 100)

    form_for(changeset, "/", fn f ->
      assert input_validations(f, :integer) == [required: true, step: 1, min: 1, max: 99]
      assert input_validations(f, :float)   == [required: false, step: "any", min: 0]
      assert input_validations(f, :decimal) == [required: false]
      assert input_validations(f, :string)  == [required: true, maxlength: 100, minlength: 0]
      ""
    end)
  end
end
