using System;
using Npgsql;

class Program
{
    public static void Main(string[] args)
    {
        string connString = "Host=localhost;Port=5432;Username=postgres;Password=admin;Database=gudang_db";

        using var conn = new NpgsqlConnection(connString);
        
        conn.Open();

        //Create in table gudang
        using (var command = new NpgsqlCommand("SELECT create_gudang(@p1, @p2, @p3)", conn))
        {
            command.Parameters.AddWithValue("p1", "Gudang Baru");
            command.Parameters.AddWithValue("p2", "Jl. Gudang baru no.17");
            command.Parameters.AddWithValue("p3", 500);
        
            int idNewGudang = (int)command.ExecuteScalar();
            Console.WriteLine($"Id Gudang Baru: {idNewGudang}");
        }
        
        //Update in table gudang
        using (var cmd = new NpgsqlCommand("SELECT update_gudang(@p_gudang_id, @p_nama_gudang, @p_alamat, @p_kapasitas_gudang)", conn))
        {
            cmd.Parameters.AddWithValue("p_gudang_id", 1);
            cmd.Parameters.AddWithValue("p_nama_gudang", "Gudang yang terupdate");
            cmd.Parameters.AddWithValue("p_alamat", "Alamat baru dari update");
            cmd.Parameters.AddWithValue("p_kapasitas_gudang", 1500);
        
            cmd.ExecuteNonQuery();
            Console.WriteLine("Gudang updated successfully");
        }
        
        //Delete in table gudang
        using (var cmd = new NpgsqlCommand("SELECT delete_gudang(@p_gudang_id)", conn))
        {
            cmd.Parameters.AddWithValue("p_gudang_id", 2); //id=2

            cmd.ExecuteNonQuery();
            Console.WriteLine("Gudang deleted successfully");
        }
        
        //Read in table gudang
        using (var cmd = new NpgsqlCommand("SELECT * FROM read_gudang()", conn))
        using (var reader = cmd.ExecuteReader())
        {
            while (reader.Read())
            {
                Console.WriteLine($"Gudang ID: {reader.GetInt32(0)}, Nama Gudang: {reader.GetString(1)}, Alamat: {reader.GetString(2)}, Kapasitas: {reader.GetInt32(3)}");
            }
        }

    }
}