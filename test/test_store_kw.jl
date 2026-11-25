using Test
using ZarrDatasets
using ZarrDatasets: ZarrHTTP
using Zarr
using Sockets

# Serve the files in `dir`, but only to requests with the right Authorization header
function serve_with_auth(dir, auth)
    server = listen(Sockets.localhost, 0)
    @async while isopen(server)
        sock = try
            accept(server)
        catch
            break
        end
        request = String(readuntil(sock, "\r\n\r\n"))
        key = split(split(request)[2], '?')[1]
        path = joinpath(dir, lstrip(key, '/'))
        authorized = occursin("Authorization: $auth", request)
        status, body = !authorized ? ("401 Unauthorized", UInt8[]) :
            isfile(path) ? ("200 OK", read(path)) : ("404 Not Found", UInt8[])
        write(sock, "HTTP/1.1 $status\r\nContent-Length: $(length(body))\r\nConnection: close\r\n\r\n", body)
        close(sock)
    end
    return server, "http://127.0.0.1:$(getsockname(server)[2])"
end

@testset "store keywords" begin
    dir = mktempdir()
    zg = zgroup(dir)
    a = zcreate(Float64, zg, "a", 4; attrs = Dict("_ARRAY_DIMENSIONS" => ["x"]))
    a .= 1:4
    Zarr.consolidate_metadata(zg.storage, "")

    # Keywords reach the store constructor: DirectoryStore takes none
    @test_throws MethodError ZarrDataset(dir; not_a_store_keyword = 1)

    # HTTPStore `headers` are not released yet
    if hasfield(ZarrHTTP.HTTPStore, :headers)
        server, url = serve_with_auth(dir, "Bearer secret")
        try
            ds = ZarrDataset(url; consolidated = true, headers = ["Authorization" => "Bearer secret"])
            @test ds["a"][:] == 1:4
            @test_throws Exception ZarrDataset(url; consolidated = true)
        finally
            close(server)
        end
    end
end
