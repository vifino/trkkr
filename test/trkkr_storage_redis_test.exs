# Trkkr.Storage.Redis Tests.
# Since redis stores no type info, everything is a string.

defmodule TrkkrStorageRedisTest do
  use ExUnit.Case, async: true
  doctest Trkkr.Storage.Redis

  import Trkkr.Storage.Redis

  # Basics.
  test "store" do
    assert store("store_test", "testval")
  end
  test "exists?" do
    assert store("exists_test", "testval")
    assert exists? "exists_test"

    assert exists?("exists_test_nonexistant") == false
  end
  test "fetch" do
    assert store("fetch_test", "testval")
    assert fetch("fetch_test") == "testval"
  end
  test "delete" do
    assert store("delete_test", "testval")
    assert delete("delete_test") == :ok
    assert fetch("delete_test") == nil
  end
 
  # Sets.
  test "set_store" do
    assert set_store("set_store_test", ["1", "2", "3"])
  end
  test "set_fetch" do
    assert set_store("set_fetch_test", ["1", "2", "3"])
    assert set_fetch("set_fetch_test") == ["1", "2", "3"]
  end
  test "set_length?" do
    assert set_store("set_length_test", ["1", "2", "3"])
    assert set_length?("set_length_test") == 3
  end
  test "set_add" do
    assert set_store("set_add_test", ["1", "2"])
    assert set_add("set_add_test", "3")
    assert set_fetch("set_add_test") == ["1", "2", "3"]
  end
  test "set_remove" do
    assert set_store("set_remove_test", ["1", "2", "3"])
    assert set_remove("set_remove_test", "2")
    assert set_remove("set_remove_test", "2")
    assert set_fetch("set_remove_test") == ["1", "3"]
  
    assert set_store("set_remove_test2", [])
    assert set_remove("set_remove_test2", "1")
    assert set_fetch("set_remove_test2") == []
  end
  test "set_delete" do
    assert set_store("set_delete_test", ["1", "2", "3"])
    assert set_delete("set_delete_test")
    assert fetch("set_delete_test") == nil
  end
end
