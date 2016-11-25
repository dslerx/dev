require "./RDSImageCreator.rb"

rdsCre = RDSImageCreator.new(900, 650, 100, 30)
rdsImg = rdsCre.create("./edge_depth_001.png")
rdsImg.write("./rds3.png")
